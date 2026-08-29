/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Wire 4 closed, and why wire 5 is a different shape

```
isBEQOf'_spec : isBEQOf' ins = (ctrlSpec (seenWord ins)).getD 4 false
```

**FOUR of `PcReads`' five wires are now closed** — `pcOf`, `rs1Of`, `rs2Of`, `isBEQOf'`.
This one was a ONE-block peel: `coreThruRw = coreThru13 ++ regWriteBlock`, and `regWrite`
writes at or above `offRw`, so reading a decoder output through `coreThruRw` is reading it
through `coreThru13`, where `core_decOut_spec` already lives.

⛔ **WIRE 5 IS NOT ANOTHER TRANSPORT, AND THE HEADER SAYS SO RATHER THAN LEAVING IT TO BE
DISCOVERED TWICE MORE.** `immBCirc` is one gate whose thirty-two outputs are almost all
*input* nets; `inst_sem`'s gate-output branch is false for every `k ≠ 0`. The groundwork that
IS reusable is landed here — the eleven-block frame bound `coreRest11b_out_ge`, the split,
and `immOut_lt_off2` — together with the measured shape and the route the next attempt
should take.

⚠️ **AND WIRE 5 CARRIES A SEMANTIC OBLIGATION THE OTHER FOUR DID NOT.** Even transported, it
yields the immediate as *instruction bits*; the pc obligation needs it as the ISA's
`bOffset imm`. That is immediate-decode correctness, not a placement fact.

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.Rs2Close

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

theorem decOut_lt_offRw (j : Nat) (hj : j < 9) : decOut j < offRw := by revert j; decide +kernel

/-- Reading a decoder output through `coreThruRw` is reading it through `coreThru13`:
`regWrite` is the only block between them and it writes at or above `offRw`. -/
theorem coreThruRw_decOut (ins : Env) (j : Nat) (hj : j < 9) :
    run ins coreThruRw (decOut j) = run ins coreThru13 (decOut j) := by
  rw [coreThruRw, run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range regWrite regWriteSig offRw regWrite_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (decOut_lt_offRw j hj)))

/-- ⭐⭐ **WIRE 4: the branch control the pc adder sees IS `ctrlSpec`'s `isBEQ` bit.** -/
theorem isBEQOf'_spec (ins : Env) :
    isBEQOf' ins = (ctrlSpec (seenWord ins)).getD 4 false := by
  rw [isBEQOf', coreThruRw_decOut ins isBEQLine (by decide +kernel)]
  exact core_decOut_spec ins 4 (by omega)

/-! ### Groundwork for wire 5 — the immediate block -/

/-- The THIRTEEN organ blocks after the immediate block, through `regWrite`. -/
def coreRest11b : List Gate :=
  instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc
    ++ instGates regWrite regWriteSig offRw

theorem coreThruRw_split3 :
    coreThruRw = (coreThru2 ++ instGates immBCirc immBSig off1) ++ coreRest11b := by
  simp only [coreThruRw, coreThru13, coreThru2, coreRest11b, List.append_assoc]

theorem coreRest11b_out_ge : ∀ g ∈ coreRest11b, off2 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off2 ≤ off →
      ∀ g ∈ instGates c σ off, off2 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [coreRest11b, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h|h|h|h|h|h|h|h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ regWrite_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

theorem immOut_lt_off2 (k : Nat) (hk : k < 32) : immOut k < off2 := by revert k; decide +kernel

/-- ⛔ **THE SHAPE THAT DEFEATS THE USUAL TRANSPORT, MEASURED NOT GUESSED.** `immBCirc` is
`{ nIn := 32, gates := [⟨immBZero, .const false⟩], outs := (List.range 32).map immB }` — **ONE
gate**, and its thirty-two OUTPUTS are almost all *input* nets rather than gate outputs. So
`inst_sem`'s `Or.inr` (gate-output membership) is **false for every `k ≠ 0`**, and a transport
written like `rs1`'s or the decoder's does not typecheck: `decide` proved my
`immBCirc_out_mem` false outright, which is the instrument doing its job.

⇒ **THE NEXT ATTEMPT SHOULD SPLIT ON `k`:** `k ≠ 0` takes `Or.inl` (`immB k < 32 = nIn`) and
is then a bare primary-input read through `instMap`'s σ branch — ***no `inst_sem` needed at
all***; `k = 0` is the single const-false gate. *Recorded because I assumed the uniform organ
shape twice, and the file says otherwise in one line.* -/
theorem immBCirc_is_one_gate : immBCirc.gates.length = 1 := by decide +kernel

#audit_axioms decOut_lt_offRw coreThruRw_decOut isBEQOf'_spec
#audit_axioms coreRest11b_out_ge immOut_lt_off2 immBCirc_is_one_gate


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThruRw_split3
end SaltWorks.HDL.RegNextUniform
