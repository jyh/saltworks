/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The decoder transport — and the defect it exposes

This file lifts the decoder's landed correctness (`sem_decoder_eq_ctrlSpec`) onto the
placement, so `core`'s control reads become `ctrlSpec` bits of the instruction word. It was
written to CLOSE the enable arm. It closed it, and the closed form is wrong.

## ⛔⛔⛔ `core` NEVER WRITES A REGISTER ON `ADD`, `ADDI`, `XOR` OR `SLT`

`CorePlace.regWriteSig` feeds `regWrite`'s **`valid`** port from **`decOut 5`**.
`sem_decoder_eq_ctrlSpec` pins `decOut j` to `ctrlSpec` index `j`, and `ctrlSpec`'s row is

```
index    0      1      2      3      4      5      6     7     8
       isADD  isXOR  isSLT  isADDI isBEQ  isLW   isSW  req  valid
```

⇒ ***the assembled core write-enables on "this is a LOAD", not on "this instruction writes
a register".*** `core_never_writes_on_ADD` / `_XOR` / `_ADDI` prove it in the kernel, and
`core_does_write_on_LW` proves the wire is **live and aimed at the wrong bit** rather than
dead — which is why every organ certificate passes.

## ⚠️ WHY NOTHING CAUGHT IT, and the answer is uncomfortable

`regWrite_correct` is exhaustive over 128 control combinations — **of `regWrite`'s own
ports.** It cannot see what those ports are CONNECTED to. `decoder_correct` is likewise
about the decoder alone. `instOK` certifies that σ lands in range, not that it lands on the
right net. And `CorePlace`'s own control, `valid_and_isBEQ_are_distinct_and_ordered`, is
**named** for this exact hazard — its docstring says *"`valid` is output 5 and `isBEQ` is
output 4"* — but its STATEMENT proves only `regWriteSig 5 = decOut 5`, `regWriteSig 6 =
decOut 4`, and `decOut 4 ≠ decOut 5`: **the wiring and the distinctness, never the
identification.** A control whose docstring names the defect and whose statement cannot
express it.

*This seat's ledger already carries the shape — `instOK-certifies-in-time-not-right-wire`,
recorded after two placements fed `rs2` where `ADDI` needed the immediate. This is the third
instance, found the same way: by transporting an organ theorem and reading what came out.*

⛔ **CONSEQUENCE, stated plainly: `RegDatapathOK` is FALSE for `core` as assembled, and
therefore `C4Spec core` is false — not unproved, FALSE.** The structural reduction in
`C4Reduction` is unaffected and so is `RegField core 0` (x0 never writes under either
wiring). The repair is one index in `CorePlace.regWriteSig`; this file does not make it,
because `CorePlace` is not this seat's to edit unilaterally.
-/
import SaltWorks.HDL.EnableSpec

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

def coreThru2 : List Gate :=
  instGates tieCells id offTie ++ instGates decoder decoderSig off0

def coreRest11 : List Gate :=
  instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc

theorem coreThru13_split : coreThru13 = coreThru2 ++ coreRest11 := by
  simp only [coreThru13, coreThru2, coreRest11, List.append_assoc]

/-- Every gate of the eleven organs AFTER the decoder writes at or above `off1`. -/
theorem coreRest11_out_ge : ∀ g ∈ coreRest11, off1 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off1 ≤ off →
      ∀ g ∈ instGates c σ off, off1 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  -- ⚠️ the bullet after `rcases _ with hg | h` focuses the FIRST goal, where `h` is NOT
  -- bound. Flatten to a right-nested disjunction with `or_assoc` and take the cases in
  -- source order instead.
  simp only [coreRest11, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h|h|h|h|h|h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

theorem decOut_lt_off1 (j : Nat) (hj : j < 9) : decOut j < off1 := by revert j; decide +kernel
theorem decoder_outs_len : decoder.outs.length = 9 := by decide +kernel
theorem decoder_nIn_32 : decoder.nIn = 32 := by decide +kernel
theorem decoder_out_mem (j : Nat) (hj : j < 9) :
    (decoder.gates.map Gate.out).contains (decoder.outs.getD j 0) = true := by
  revert j; decide +kernel

theorem decoder_out_bound (j : Nat) (hj : j < 9) :
    decoder.outs.getD j 0 < decoder.nIn + decoder.gates.length := by revert j; decide +kernel

/-- A primary input survives the tie-cell block. -/
theorem tie_input_stable (ins : Env) (n : Net) (hn : n < offTie) :
    run ins (instGates tieCells id offTie) n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ (instGates_out_range tieCells id offTie tieCells_ssa g hg).1)
      (Nat.not_le.mpr hn))

theorem instrNet_lt (i : Nat) (hi : i < 32) : instrNet i < offTie := by revert i; decide +kernel

/-- ⭐⭐⭐ **THE DECODER'S OUTPUTS, INSIDE `core`, ARE `ctrlSpec` OF THE INSTRUCTION WORD.**
The organ's landed correctness (`sem_decoder_eq_ctrlSpec`) lifted onto the placement. -/
theorem core_decOut_spec (ins : Env) (j : Nat) (hj : j < 9) :
    run ins coreThru13 (decOut j) = (ctrlSpec (seenWord ins)).getD j false := by
  -- peel the eleven organs after the decoder
  rw [coreThru13_split, run_append,
      run_of_unwritten _ _ _ (fun g hg hEq => by
        have hge := coreRest11_out_ge g hg
        rw [hEq] at hge
        exact absurd hge (Nat.not_le.mpr (decOut_lt_off1 j hj)))]
  -- read the decoder's own output through the placement
  rw [decOut, instOuts, getD_map_lt _ _ _ (by rw [decoder_outs_len]; exact hj) 0 0,
      coreThru2, run_append,
      inst_sem decoder decoderSig off0 _
        (fun a => run ins (instGates tieCells id offTie) (decoderSig a))
        decoder_instOK (fun _ _ => rfl)
        (decoder.outs.getD j 0) (Or.inr (decoder_out_mem j hj))]
  -- swap that environment for the instruction word's bits, then use the organ theorem
  rw [show (ctrlSpec (seenWord ins)).getD j false
        = (sem decoder (fun i => (seenWord ins).getLsbD i)).getD j false from by
        rw [sem_decoder_eq_ctrlSpec], sem,
      getD_map_lt _ _ _ (by rw [decoder_outs_len]; exact hj) 0 false]
  refine run_agree_of_inputs_circ decoder decoder_ssa _ _ (fun a ha => ?_) _
    (decoder_out_bound j hj)
  rw [decoder_nIn_32] at ha
  rw [show decoderSig a = instrNet a from rfl, tie_input_stable ins _ (instrNet_lt a ha),
      seenWord, wordOf_getLsbD _ _ ha]

theorem validOf_spec (ins : Env) : validOf ins = (ctrlSpec (seenWord ins)).getD 5 false :=
  core_decOut_spec ins 5 (by omega)

theorem isBEQOf_spec (ins : Env) : isBEQOf ins = (ctrlSpec (seenWord ins)).getD 4 false :=
  core_decOut_spec ins 4 (by omega)

/-! ### ⛔⛔ WHAT THE TRANSPORT REVEALS -/

/-- ⛔⛔⛔ **`core` NEVER WRITES A REGISTER ON `ADD`.** `regWriteSig` feeds `regWrite`'s
`valid` port from `decOut 5`. `sem_decoder_eq_ctrlSpec` pins `decOut j` to `ctrlSpec` index
`j`, and index 5 is **`isLW`** — `valid` is index **8**. So the assembled core write-enables
on "this is a load", not on "this instruction writes a register". -/
theorem core_never_writes_on_ADD (ins : Env) (k : Nat) (hk : k < 32)
    (rd a b : Fin 32) (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, validOf_spec ins]
  simp [ctrlSpec, h]

/-- …and the same for `XOR`, `SLT`, `ADDI` — every arithmetic instruction in Slice A. -/
theorem core_never_writes_on_XOR (ins : Env) (k : Nat) (hk : k < 32)
    (rd a b : Fin 32) (h : decode (seenWord ins) = some (.XOR rd a b)) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, validOf_spec ins]
  simp [ctrlSpec, h]

theorem core_never_writes_on_ADDI (ins : Env) (k : Nat) (hk : k < 32)
    (rd a : Fin 32) (imm : BitVec 12) (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, validOf_spec ins]
  simp [ctrlSpec, h]

/-- **NON-VACUITY — the wire is LIVE, it is aimed at the wrong bit.** On a load the enable
does come up, which is exactly what `isLW` would do. *A dead enable would be a different
(and more visible) defect; this one passes every organ certificate.* -/
theorem core_does_write_on_LW (ins : Env) (rd a : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.LW rd a imm))
    (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), validOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

#audit_axioms coreThru13_split coreRest11_out_ge
#audit_axioms core_decOut_spec validOf_spec isBEQOf_spec
#audit_axioms core_never_writes_on_ADD core_never_writes_on_XOR core_never_writes_on_ADDI
#audit_axioms core_does_write_on_LW

end SaltWorks.HDL.RegNextUniform
