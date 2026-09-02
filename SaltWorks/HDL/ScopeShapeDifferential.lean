/-
  R9b — THE SCOPE-SHAPE DIFFERENTIAL. Written 2026-09-02 before R10's text exists,
  so the sitting rules on a build rather than on my reasoning.

  THE QUESTION. If R10 disposes the LW row by SCOPE, the scope has to be written into
  `CycleRealisesStepOrStalls` itself (the consumer-level `hmf` cannot help — the
  consumer still takes the universal predicate as a hypothesis and instantiates it at
  the witness). Two spellings of "add a scope argument" read equally well in prose:

    B  scope : Env -> Bool,  body `if scope ins then (today's body) else True`
    P  scope : Env -> Prop,  body `scope ins -> (today's body)`

  THE PROPERTY AT STAKE is `stallArm_reduces`, which closes by `Iff.rfl` — DEFINITIONAL.
  That is what let the twenty-declaration cone survive the restatement. This file asks
  the kernel which spelling keeps it.

  PRE-REGISTERED PREDICTION (written here before the build was run):
    B's reduction closes by `Iff.rfl`;  P's does NOT, and needs a tactic.

  OUTCOME, 2026-09-02, saltbuild EXIT=0, zero `sorryAx`: THE PREDICTION HELD, BOTH HALVES.
  `scopedB_reduces` closes by `Iff.rfl`. `Iff.rfl` at the P form is a TYPE MISMATCH, and the
  mismatch text is pinned below by `#guard_msgs`, so the negative arm is a checked artifact
  and not a remembered one. The honest size of the finding is in
  `scopedP_reduces_propositionally`: P does NOT lose the reduction, it loses the DEFEQ —
  the iff is still provable, by a tactic, and every consumer that leaned on `Iff.rfl`
  has to be re-read. That is a smaller claim than "P breaks the cone" and it is the true one.

  ⛔ WHAT THIS FILE DOES NOT DO. It does not inhabit anything for `core`, it does not
  choose a scope, and it takes no position on which spelling R10 should adopt. It measures
  one property of two candidate spellings so the sitting rules on a build.
-/
import SaltWorks.HDL.StallShape
import SaltWorks.HDL.LwNotStallShaped

namespace SaltWorks.HDL.ScopeShapeDifferential

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program SaltWorks.HDL.StallShape

/-! ### FORM B — a Bool-valued scope, `if … then … else True`. -/

def ScopedB (scope : SaltWorks.HDL.Env → Bool) (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) : Prop :=
  ∀ ins,
    if scope ins then
      (if stalls ins then
        (SaltWorks.HDL.decQ (cyc ins)).regs = (SaltWorks.HDL.decQ ins).regs
          ∧ (SaltWorks.HDL.decQ (cyc ins)).pc = (SaltWorks.HDL.decQ ins).pc
      else
        (SaltWorks.HDL.decQ (cyc ins)).regs
            = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
          ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
            = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc)
    else True

/-- **B's REDUCTION — the prediction, handed to the kernel.** -/
theorem scopedB_reduces (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) :
    ScopedB (fun _ => true) cyc wordAt stalls
      ↔ CycleRealisesStepOrStalls cyc wordAt stalls :=
  Iff.rfl

/-! ### FORM P — a Prop-valued scope and an implication. -/

def ScopedP (scope : SaltWorks.HDL.Env → Prop) (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) : Prop :=
  ∀ ins, scope ins →
    (if stalls ins then
      (SaltWorks.HDL.decQ (cyc ins)).regs = (SaltWorks.HDL.decQ ins).regs
        ∧ (SaltWorks.HDL.decQ (cyc ins)).pc = (SaltWorks.HDL.decQ ins).pc
    else
      (SaltWorks.HDL.decQ (cyc ins)).regs
          = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
        ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
          = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc)

/-! ⛔ **P's REDUCTION BY `Iff.rfl` — THE NEGATIVE ARM, captured as a checked message.**
If this ever starts succeeding, `#guard_msgs` fails the build and the finding retires
itself instead of rotting. ⚠️ The guard is text-exact, so it can also fail because Lean's
message text or metavariable numbering moved — read WHICH half changed before concluding
anything about the defeq. -/

/-- error: Type mismatch
  Iff.rfl
has type
  ?m.2 ↔ ?m.2
but is expected to have type
  ScopedP (fun x ↦ True) cyc wordAt stalls ↔ CycleRealisesStepOrStalls cyc wordAt stalls
-/
#guard_msgs in
example (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) :
    ScopedP (fun _ => True) cyc wordAt stalls
      ↔ CycleRealisesStepOrStalls cyc wordAt stalls :=
  Iff.rfl

/-- **P's reduction IS still provable — by a tactic, not for free.** The cone is not
lost under P; it stops being *definitional*, which is a different and smaller claim
than "P breaks it", and it is the honest one. -/
theorem scopedP_reduces_propositionally (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) :
    ScopedP (fun _ => True) cyc wordAt stalls
      ↔ CycleRealisesStepOrStalls cyc wordAt stalls :=
  ⟨fun h ins => h ins trivial, fun h ins _ => h ins⟩

/-! ### THE CONTROL. A differential with no failing arm is not a differential. -/

set_option maxHeartbeats 1000000 in
/-- **C — B's scope argument is NOT decoration: at a scope that EXCLUDES an
environment, `ScopedB` is satisfied by a cycle map the unscoped predicate REFUTES.**
Driven at the landed LW witness with the core itself. -/
theorem control_scope_actually_excludes (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) (stalls : SaltWorks.HDL.Env → Bool) :
    ScopedB (fun _ => false) (cycOfCirc SaltWorks.HDL.CorePlace.core nextW pad)
        Program.seenWord stalls
      ∧ ¬ CycleRealisesStepOrStalls (cycOfCirc SaltWorks.HDL.CorePlace.core nextW pad)
        Program.seenWord stalls :=
  ⟨fun _ => trivial,
   SaltWorks.HDL.LwNotStallShaped.core_refutes_every_stall_arm nextW pad stalls⟩

#audit_axioms scopedB_reduces
#audit_axioms scopedP_reduces_propositionally
#audit_axioms control_scope_actually_excludes

end SaltWorks.HDL.ScopeShapeDifferential
