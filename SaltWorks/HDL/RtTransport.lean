/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The rs1 read port's environment inside `core`

`PcReads` left the pc obligation as five named wires, two of which are the read trees. This
file proves the structural half for `rs1`:

```
rs1Env_agrees :  run ins coreThru3 (readTreeRs1Sig j)
                   = rtEnvOfSt (decQ ins) ⟨rs1AddrOf ins, _⟩ j
```

⭐ **AND IT IS EASIER THAN THE `regWrite` TRANSPORT, WHICH IS WORTH KNOWING BEFORE YOU START
THE REST.** `readTreeRs1Sig j = if j < 5 then rs1Bit j else j + 27` — **both halves land in
PRIMARY INPUTS**: the address from `instrNet`, the register file as a pure shift into the
state bits. So this needs input-stability only, with **no dependence on any earlier organ**
and no `inst_sem`-over-a-prefix. (`rs2` differs in the five address bits and nothing else.)

*The shift lines up because `rtEnvOf` stores registers from index 1 — x0 is not stored — and
`32*((j-5)/32 + 1) + (j-5)%32 = j + 27`. That is the same structural fact about x0 that made
`RegField core 0` free, showing up a third time.*

⛔ **WHAT IS NOT DONE, NAMED SO IT IS NOT MISTAKEN FOR THE PORT BEING CLOSED.** This connects
the *environment*, not `rs1Of`. `rs1Of` is stated over `coreThruRw`, and `readTree` sits at
`off2` — ten organ blocks earlier — so closing it needs a frame peel across those ten
(the same shape as `coreRest11_out_ge`) and then `sem_readTree_St`. **The organ theorem is
already the strong form** (`Program.lean:7063`, *"the port IS `St.get`"*, every state, every
register, every bit), so nothing about the read tree itself remains to prove.

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.PcReads

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

def coreThru3 : List Gate :=
  instGates tieCells id offTie ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1

theorem coreThru3_sub : coreThru3 ⊆ core.gates := by
  intro g hg
  refine coreThru13_sub ?_
  simp only [coreThru3, List.mem_append, or_assoc] at hg
  simp only [coreThru13, List.mem_append, or_assoc]
  tauto

theorem coreThru3_input_stable (ins : Env) (n : Net) (hn : n < coreInWidth) :
    run ins coreThru3 n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ core_gate_out_ge g (coreThru3_sub hg)) (Nat.not_le.mpr hn))

theorem readTree_nIn_997 : readTree.nIn = 997 := by decide +kernel

theorem rs1Bit_lt (j : Nat) (hj : j < 5) : rs1Bit j < coreInWidth := by revert j; decide +kernel

/-- The `rs1` address as the instruction word presents it — bits 15…19. -/
def rs1AddrOf (ins : Env) : Nat :=
  (if ins (instrNet 15) then 1 else 0) + (if ins (instrNet 16) then 2 else 0)
  + (if ins (instrNet 17) then 4 else 0) + (if ins (instrNet 18) then 8 else 0)
  + (if ins (instrNet 19) then 16 else 0)

theorem rs1AddrOf_lt (ins : Env) : rs1AddrOf ins < 32 := by
  cases h15 : ins (instrNet 15) <;> cases h16 : ins (instrNet 16) <;>
    cases h17 : ins (instrNet 17) <;> cases h18 : ins (instrNet 18) <;>
    cases h19 : ins (instrNet 19) <;> simp [rs1AddrOf, h15, h16, h17, h18, h19]

theorem rs1AddrOf_testBit (ins : Env) (j : Nat) (hj : j < 5) :
    (rs1AddrOf ins).testBit j = ins (instrNet (15 + j)) := by
  cases h15 : ins (instrNet 15) <;> cases h16 : ins (instrNet 16) <;>
    cases h17 : ins (instrNet 17) <;> cases h18 : ins (instrNet 18) <;>
    cases h19 : ins (instrNet 19) <;>
    interval_cases j <;> norm_num [rs1AddrOf, h15, h16, h17, h18, h19] <;> decide

/-- ⭐⭐ **THE rs1 READ PORT'S ENVIRONMENT INSIDE `core` IS `rtEnvOfSt` OF THE DECODED STATE.**
*Both halves of `readTreeRs1Sig` land in PRIMARY INPUTS — the address from `instrNet`, the
register file as the pure shift `j + 27` — so this needs input-stability only, with no
dependence on any earlier organ.* -/
theorem rs1Env_agrees (ins : Env) (j : Nat) (hj : j < readTree.nIn) :
    run ins coreThru3 (readTreeRs1Sig j)
      = rtEnvOfSt (decQ ins) ⟨rs1AddrOf ins, rs1AddrOf_lt ins⟩ j := by
  rw [readTree_nIn_997] at hj
  by_cases h5 : j < 5
  · rw [show readTreeRs1Sig j = rs1Bit j from by simp [readTreeRs1Sig, h5],
        coreThru3_input_stable ins _ (rs1Bit_lt j h5)]
    show ins (instrNet (15 + j)) = rtEnvOf _ _ j
    rw [rtEnvOf_addr _ _ j h5, rs1AddrOf_testBit ins j h5]
  · rw [show readTreeRs1Sig j = j + 27 from by simp [readTreeRs1Sig, h5],
        coreThru3_input_stable ins _ (by
          have : j + 27 < 1088 := by omega
          simpa only [coreInWidth, stWidth] using this)]
    have hr : (j - 5) / 32 + 1 < 32 := by omega
    have hmod : ((j - 5) / 32 + 1) % 32 = (j - 5) / 32 + 1 := Nat.mod_eq_of_lt hr
    have hne : ¬ ((⟨((j - 5) / 32 + 1) % 32, Nat.mod_lt _ (by norm_num)⟩ : Fin 32) = 0) := by
      intro hz
      have := congrArg Fin.val hz
      simp only [hmod] at this
      omega
    have hlt5 : ¬ (j < rtAddrBits) := by simp only [rtAddrBits]; omega
    simp only [rtEnvOfSt, rtEnvOf, rtAddrBits, rtWidth, St.get, if_neg hne]
    rw [if_neg h5]
    have harith : 32 * (((j - 5) / 32 + 1) % 32) + (j - 5) % 32 = j + 27 := by
      rw [hmod]
      have := Nat.div_add_mod (j - 5) 32
      omega
    rw [show ((decQ ins).regs[(((j - 5) / 32 + 1) % 32 : Nat)]).getLsbD ((j - 5) % 32)
          = ins (32 * (((j - 5) / 32 + 1) % 32) + (j - 5) % 32) from
        decQ_reg_bit ins ⟨((j - 5) / 32 + 1) % 32, Nat.mod_lt _ (by norm_num)⟩ _
          (Nat.mod_lt _ (by norm_num)), harith]

#audit_axioms coreThru3_input_stable rs1AddrOf_testBit rs1Env_agrees


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThru3_sub SaltWorks.HDL.RegNextUniform.readTree_nIn_997
#audit_axioms SaltWorks.HDL.RegNextUniform.rs1AddrOf_lt SaltWorks.HDL.RegNextUniform.rs1Bit_lt
end SaltWorks.HDL.RegNextUniform
