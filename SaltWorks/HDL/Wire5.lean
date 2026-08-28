/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Wire 5 transported — all five of `PcReads`' wires now have their structural half

```
immOf_bits : (immOf ins).getLsbD k = if k = 0 then false else ins (instrNet (immB k))
```

**Bit `k` of the immediate `core` feeds the pc adder is the instruction word's own bit
`immB k`, and bit 0 is the structural zero.**

⭐ **THE ROUTE WAS THE ONE `Wire4` PREDICTED, and it needed no `inst_sem` at all.** `immBCirc`
is one gate whose outputs are mostly input nets, so the split on `k` does the work: `k ≠ 0`
goes through `instMap`'s σ branch to a primary input and then `coreThru3_input_stable`;
`k = 0` is the single relocated constant, and `instGates immBCirc immBSig off1` reduces to
the literal `[⟨off1, Op.const false⟩]`.

⛔ **WHAT REMAINS OF `PcDatapathOK` IS NOW ENTIRELY SEMANTIC — no placement work is left.**
Every one of the five reads has been carried from `core` to a named object; what is not
proved is that those objects mean what the ISA says:

```
immOf   ⇒ needs = bOffset (the decoded imm)      immediate-decode correctness
rs1/rs2 ⇒ needs the address fields = decode's a, b
isBEQ   ⇒ needs ctrlSpec's bit ↔ decode w = BEQ
        ⇒ and an ISA-side lemma for (stepT q w).pc itself
```
*Four bridges, none of them a transport. This file is where the placement story for the pc
half ends.*

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.Wire4

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

theorem coreThruRw_split3' : coreThruRw = coreThru3 ++ coreRest11b := by
  simp only [coreThruRw, coreThru13, coreThru3, coreRest11b, List.append_assoc]

theorem immBCirc_out_k (k : Nat) (hk : k < 32) : immBCirc.outs.getD k 0 = immB k := by
  show ((List.range 32).map immB).getD k 0 = immB k
  rw [getD_map_lt _ _ _ (by simpa using hk) 0 0,
      show (List.range 32).getD k 0 = k from by simp [hk]]

/-- The placed immediate block is exactly one relocated constant gate. -/
theorem immB_block_eq : instGates immBCirc immBSig off1 = [(⟨off1, Op.const false⟩ : Gate)] := by
  simp only [instGates, immBCirc, List.map_cons, List.map_nil, instMap, Op.rename]
  norm_num [immBZero]

/-- Reading `immOut k` through `coreThruRw` is reading it through `coreThru3`. -/
theorem coreThruRw_immOut (ins : Env) (k : Nat) (hk : k < 32) :
    run ins coreThruRw (immOut k) = run ins coreThru3 (immOut k) := by
  rw [coreThruRw_split3', run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := coreRest11b_out_ge g hg
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (immOut_lt_off2 k hk)))

theorem immBCirc_outs_len : immBCirc.outs.length = 32 := by decide +kernel

theorem immOut_eq (k : Nat) (hk : k < 32) :
    immOut k = instMap immBCirc immBSig off1 (immBCirc.outs.getD k 0) := by
  rw [immOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [immBCirc_outs_len]; exact hk) 0 0

theorem immB_lt_coreInWidth (k : Nat) (hk : k < 32) (h0 : k ≠ 0) :
    instrNet (immB k) < coreInWidth := by
  -- ⚠️ `immB k < 32` is Net-born, so omega drops it (this seat's standing trap). Build the
  -- bound from a Nat TERM instead.
  have h : immB k < 32 := immB_lt_32_of_ne_zero h0
  have hstep : (instrBase : Nat) + immB k < instrBase + 32 := Nat.add_lt_add_left h instrBase
  have heq : (instrBase : Nat) + 32 = coreInWidth := by
    simp only [instrBase, coreInWidth, stWidth]
  show (instrBase + immB k : Nat) < coreInWidth
  exact heq ▸ hstep

/-- ⭐⭐⭐ **WIRE 5, TRANSPORTED.** Bit `k` of the immediate `core` feeds the pc adder is the
instruction word's own bit `immB k`, and bit 0 is the structural zero. -/
theorem immOf_bits (ins : Env) (k : Nat) (hk : k < 32) :
    (immOf ins).getLsbD k = (if k = 0 then false else ins (instrNet (immB k))) := by
  rw [immOf, wordOf_getLsbD _ _ hk, coreThruRw_immOut ins k hk, immOut_eq k hk,
      immBCirc_out_k k hk]
  by_cases h0 : k = 0
  · subst h0
    rw [if_pos rfl, show immB 0 = immBZero from rfl,
        show instMap immBCirc immBSig off1 immBZero = off1 from by
          simp only [instMap, immBCirc, immBZero]; norm_num,
        coreThru3, run_append, immB_block_eq, run_cons, run_nil]
    exact upd_self _ _ _
  · rw [if_neg h0,
        show instMap immBCirc immBSig off1 (immB k) = instrNet (immB k) from by
          simp only [instMap, immBCirc, immBSig, if_pos (immB_lt_32_of_ne_zero h0)],
        coreThru3_input_stable ins _ (immB_lt_coreInWidth k hk h0)]

#audit_axioms immBCirc_out_k immB_block_eq coreThruRw_immOut immOf_bits


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThruRw_split3' SaltWorks.HDL.RegNextUniform.immBCirc_outs_len
#audit_axioms SaltWorks.HDL.RegNextUniform.immB_lt_coreInWidth SaltWorks.HDL.RegNextUniform.immOut_eq
end SaltWorks.HDL.RegNextUniform
