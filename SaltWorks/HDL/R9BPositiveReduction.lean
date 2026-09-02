/-
  R9b — THE POSITIVE HALF, REDUCED. Pre-registered in `docs/R9B-POSITIVE-PREREGISTRATION.md`
  at `76cdaf3`, BEFORE this file existed; the order is checkable in `git log`.

  ⛔ A REDUCTION IS NOT AN INHABITATION. Nothing here proves the core's datapath. What it
  proves is that ONE obligation stands between the scoped flagship and the kernel, and it
  names that obligation exactly.
-/
import SaltWorks.HDL.MemFreeScope
import SaltWorks.HDL.C4Reduction
import SaltWorks.HDL.PcFieldClosed
import SaltWorks.HDL.LwTrapRefuted

namespace SaltWorks.HDL.R9BPositiveReduction

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program
open SaltWorks.HDL.StallShape SaltWorks.HDL.MemFreeScope
open SaltWorks.HDL.CorePlace SaltWorks.HDL.RegNextUniform

set_option maxRecDepth 8000

/-! ### §1 — CLAIM P1 · THE SCOPED FORWARD BRIDGE

The scoped mirror of `cycleRealisesStepProj_of_bits`. Pre-registered PREDICTION: mechanical,
the existing proof carrying one extra hypothesis. **OUTCOME: it was.** *If it had NOT been,
that was the interesting result — it would have meant the bridge quietly used the
universality of its antecedent, and R10-3's shape would need re-examining before ratification.*
-/

theorem cycleRealisesStepOrStallsOn_of_bits {f : SaltWorks.HDL.Env → List Bool}
    (scope : SaltWorks.HDL.Env → Bool)
    (h : ∀ ins, scope ins = true
      → f ins = SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)))
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn scope (cycOfBits f nextW pad) seenWord (fun _ => false) := by
  intro ins
  cases hs : scope ins with
  | false => simp only [hs, Bool.false_eq_true, if_false]
  | true =>
      simp only [hs, if_true, Bool.false_eq_true, if_false]
      rw [cycOfBits, h ins hs, envOfBits_encD, decQ_envWith_eq]
      exact ⟨rfl, rfl⟩

/-- **THE SAME, FOR A CIRCUIT.** `cycOfCirc` is `cycOfBits (sem c)` by definition. -/
theorem cycleRealisesStepOrStallsOn_of_C4SpecOn {c : SaltWorks.HDL.Circ}
    (scope : SaltWorks.HDL.Env → Bool)
    (h : ∀ ins, scope ins = true
      → SaltWorks.HDL.sem c ins
        = SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)))
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn scope (cycOfCirc c nextW pad) seenWord (fun _ => false) :=
  cycleRealisesStepOrStallsOn_of_bits (f := SaltWorks.HDL.sem c) scope h nextW pad

/-- ⛔ **CONTROL C1 — AT THE EVERYWHERE-TRUE SCOPE, P1 GIVES BACK THE LANDED BRIDGE.**
If this failed, the scoped bridge would be about an object of my own invention rather than
a weakening of the tree's. -/
theorem control_C1_recovers_the_landed_bridge {c : SaltWorks.HDL.Circ}
    (h : SaltWorks.HDL.C4Spec c) (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord :=
  (scopedOn_reduces_all_the_way (cycOfCirc c nextW pad) seenWord).mp
    (cycleRealisesStepOrStallsOn_of_C4SpecOn (fun _ => true) (fun ins _ => h ins) nextW pad)

/-! ### §2 — THE SCOPED REGISTER OBLIGATION, AND THE POINTWISE ASSEMBLY -/

/-- **`RegDatapathOK`, RESTRICTED TO A SCOPE.** Identical to the landed obligation except
that it is only asked at environments the scope admits. -/
def RegDatapathOKOn (scope : SaltWorks.HDL.Env → Bool) : Prop :=
  ∀ ins : SaltWorks.HDL.Env, scope ins = true → ∀ (r : Fin 32) (k : Nat), k < 32 →
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[r.val]).getLsbD k

/-- **Every output bit of `core` is right, AT ONE IN-SCOPE ENVIRONMENT.** The register bits
come from the scoped obligation through `core_outBit_reg_reduced`; ⭐ **the pc bits come from
`pcField_core`, WHICH IS LANDED AND UNSCOPED** — the 33rd obligation was already discharged
over ALL environments, so the pc side needs no scope at all. -/
theorem outBits_core_of_scoped {scope : SaltWorks.HDL.Env → Bool}
    (h : RegDatapathOKOn scope) (ins : SaltWorks.HDL.Env) (hs : scope ins = true) :
    ∀ j < SaltWorks.HDL.stWidth,
      outBit core ins j
        = SaltWorks.HDL.stBit (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) j := by
  intro j hj
  have hj56 : j < 32 * 32 + 32 := hj
  by_cases h1 : j < 1024
  · have hlt : j / 32 < 32 := by omega
    have hk : j % 32 < 32 := by omega
    have hd : 32 * (j / 32) + j % 32 = j := by omega
    have hs' := stBit_reg (stepT (SaltWorks.HDL.decQ ins) (seenWord ins))
      ⟨j / 32, hlt⟩ (j % 32) hk
    have hb : outBit core ins (32 * (j / 32) + j % 32)
        = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[(⟨j / 32, hlt⟩ : Fin 32).val]).getLsbD (j % 32) := by
      rw [core_outBit_reg_reduced ins (j / 32) (j % 32) hlt hk]
      exact h ins hs ⟨j / 32, hlt⟩ (j % 32) hk
    rw [hd] at hs' hb
    exact hb.trans hs'.symm
  · have hk : j - 1024 < 32 := by omega
    have hd : 1024 + (j - 1024) = j := by omega
    have hs' := stBit_pc (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) (j - 1024) hk
    have hb := (pcField_iff_bits core).mp pcField_core ins (j - 1024) hk
    rw [hd] at hs' hb
    exact hb.trans hs'.symm

/-- **CLAIM P2 — the pointwise `C4Spec` at one in-scope environment.** The body is
`c4Spec_iff_bitwise`'s assembly direction with `ins` fixed; the length conjunct is the
LANDED `core_outs_length`, and it is indispensable — `getD` is total, so without it a short
core satisfies every bit equation by reading the default. -/
theorem c4SpecAt_core_of_scoped {scope : SaltWorks.HDL.Env → Bool}
    (h : RegDatapathOKOn scope) (ins : SaltWorks.HDL.Env) (hs : scope ins = true) :
    SaltWorks.HDL.sem core ins
      = SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) := by
  have hbits := outBits_core_of_scoped h ins hs
  apply List.ext_getElem
  · rw [SaltWorks.HDL.sem, List.length_map, core_outs_length, encD_length]
  · intro i hh1 hh2
    have hi : i < SaltWorks.HDL.stWidth := by rwa [encD_length] at hh2
    have hL : (SaltWorks.HDL.sem core ins)[i]'hh1 = outBit core ins i := by
      rw [outBit, List.getD_eq_getElem _ _ hh1]
    have hR : (SaltWorks.HDL.encD
          (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)))[i]'hh2
        = SaltWorks.HDL.stBit (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) i := by
      rw [← List.getD_eq_getElem _ false hh2, SaltWorks.HDL.encD_getD _ _ hi]
    rw [hL, hR]
    exact hbits i hi

/-! ### §3 — CLAIM P3 · THE DELIVERABLE -/

/-- ⭐⭐⭐ **THE REDUCTION. R9b's POSITIVE HALF IS `RegDatapathOK` RESTRICTED TO THE SCOPE,
AND NOTHING ELSE.** The output count is landed (`core_outs_length`); the pc field is landed
and needs no scope (`pcField_core`); the bridge is P1. One obligation remains. -/
theorem positive_half_of_scoped_datapath {scope : SaltWorks.HDL.Env → Bool}
    (h : RegDatapathOKOn scope) (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn scope (cycOfCirc core nextW pad) seenWord (fun _ => false) :=
  cycleRealisesStepOrStallsOn_of_C4SpecOn scope
    (fun ins hs => c4SpecAt_core_of_scoped h ins hs) nextW pad

/-- ⭐ **THE INSTANCE R10-3 IS ABOUT**, at the memory-free scope. -/
theorem positive_half_at_the_memory_free_scope
    (h : RegDatapathOKOn (fun ins => memFreeB (seenWord ins)))
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStallsOn (fun ins => memFreeB (seenWord ins))
      (cycOfCirc core nextW pad) seenWord (fun _ => false) :=
  positive_half_of_scoped_datapath h nextW pad

/-! ### §4 — THE CONTROLS THAT MAKE §3 A RESULT RATHER THAN A REARRANGEMENT -/

/-- ⛔⛔ **CONTROL C2 — THE SCOPE IS LOAD-BEARING, AND HERE IS THE PROOF THAT IT IS.**
The UNSCOPED antecedent is FALSE on master: `RegDatapathOK` is refuted at the landed LW
witness. **So a `positive_half_of_scoped_datapath` that failed to use its scope hypothesis
would be deriving the flagship from a false premise**, and the reduction would be worthless
while looking identical. Stated BESIDE the reduction so the two are read together. -/
theorem control_C2_the_unscoped_obligation_is_refuted :
    ¬ SaltWorks.HDL.RegNextUniform.RegDatapathOK :=
  SaltWorks.HDL.LwTrapRefuted.Addenda.regDatapathOK_is_false_at_the_LANDED_witness

/-- ⛔ **CONTROL C3 — THE SCOPE IS NOT EMPTY.** A scope admitting nothing makes the reduction
vacuous: `RegDatapathOKOn` would be trivially inhabited and the conclusion would claim nothing
about any environment. `insI`, the landed ADDI witness, is IN. -/
theorem control_C3_scope_is_inhabited :
    (fun ins => memFreeB (seenWord ins)) SaltWorks.HDL.C4Refuted.insI = true :=
  memFreeB_seenWord_insI_true

/-- ⛔ **AND THE WITNESS THAT MADE THE SCOPE NECESSARY IS OUT.** The pair, in one statement:
the reduction's scope excludes exactly the environment that refutes the unscoped obligation
and admits a real instruction environment beside it. -/
theorem the_scope_is_exactly_what_it_must_be :
    (fun ins => memFreeB (seenWord ins)) SaltWorks.HDL.C4Refuted.insL = false
      ∧ (fun ins => memFreeB (seenWord ins)) SaltWorks.HDL.C4Refuted.insI = true :=
  ⟨memFreeB_seenWord_insL_false, memFreeB_seenWord_insI_true⟩

#audit_axioms cycleRealisesStepOrStallsOn_of_bits cycleRealisesStepOrStallsOn_of_C4SpecOn
#audit_axioms control_C1_recovers_the_landed_bridge
#audit_axioms outBits_core_of_scoped c4SpecAt_core_of_scoped
#audit_axioms positive_half_of_scoped_datapath positive_half_at_the_memory_free_scope
#audit_axioms control_C2_the_unscoped_obligation_is_refuted control_C3_scope_is_inhabited
#audit_axioms the_scope_is_exactly_what_it_must_be

end SaltWorks.HDL.R9BPositiveReduction
