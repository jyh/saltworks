/-
  ⭐⭐ R10-3 IS ADOPTED, AND THIS MODULE IS NOW THE SCOPE'S **EVIDENCE**, NOT ITS HOME.

  The R10 sitting of 2026-09-02 (helm minute, bare filename
  `2026-09-02-R10-SITTING-minute.md`, private record) RATIFIED R10-3 and ruled that
  **adoption IS the move**: `CycleRealisesStepOrStallsOn`, in its Bool form, together with
  `memFreeB` and the pin that holds it to `MemFree`, now live in `HDL/StallShape.lean` §0.2,
  which this file's own header had named as their conditional home. The condition was met
  and the move was performed; nothing was copied, so there is exactly one definition.

  ⛔ WHAT STAYED, AND WHY IT IS A DEPENDENCY FACT AND NOT A LEFTOVER. The two controls below
  name `HDL.C4Refuted`, which sits DOWNSTREAM of `HDL/StallShape.lean`. Moving them would
  invert that edge, so they stay here. They are not decoration: `memFreeB_seenWord_insL_false`
  is why the scope DISPOSES of the LW row (the witness is outside it), and
  `memFreeB_seenWord_insI_true` is why the scope is not merely EMPTY (the ADDI witness is
  inside it). ***A SCOPE WITHOUT ITS NON-VACUITY CONTROL IS A SENTENCE THAT CLAIMS NOTHING
  AND READS EXACTLY LIKE ONE THAT CLAIMS SOMETHING*** — so §0.2 of `StallShape` points here
  by name, and this file states the edge that keeps them apart. Neither pointer is optional.

  ⛔ THE FENCE, WHICH TRAVELS WITH EVERY SENTENCE ABOUT THIS SCOPE: the object is
  `CorePlace.core`, the LEAN-COMPOSED circuit — NOT `core32.v`, the hand-written RTL that was
  fabricated — and no theorem in this tree relates the two. Rung 2.5: proven in Lean over the
  composed model, RESTRICTED; RTL correspondence OPEN. Ratification moved the modal status of
  the results resting on R10-3, and moved nothing else.

  📜 HISTORY, NOT ORDERS. Until the sitting sat, this header read *"THIS FILE DOES NOT RATIFY
  ANYTHING … the scoped definition belongs there IF AND ONLY IF the sitting adopts it"*, and
  the declarations were held here deliberately so that adoption would be an act somebody
  performed rather than a fact somebody inherited from a landing. That worked, and the
  sentence is now spent: a conditional left standing after its condition is discharged reads
  as an OPEN question and invites the work a second time.
-/
import SaltWorks.HDL.StallShape
import SaltWorks.HDL.C4Refuted

namespace SaltWorks.HDL.MemFreeScope

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program SaltWorks.HDL.StallShape

/-! ### §3 — THE SCOPE BITES, AND IT DOES NOT BITE EVERYWHERE.

R10-3's "why this is honest" paragraph rests on `insL` being outside the scope. That is
stated here as a kernel fact rather than left as a corollary a reader assembles. ⛔ And it
is stated BESIDE its non-vacuity control, because a scope that excluded everything would
make the scoped sentence vacuously true and R10-3 would claim nothing at all.
-/

/-- ⭐ **THE LANDED LW WITNESS IS OUTSIDE THE SCOPE.** -/
theorem memFreeB_seenWord_insL_false :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insL) = false := by
  rw [SaltWorks.Stack.Program.seenWord_eq_hdl]
  unfold memFreeB
  rw [SaltWorks.HDL.C4Refuted.dec_insL]
  rfl

/-- ⛔⛔ **THE NON-VACUITY CONTROL, ON THE SAME CHANNEL AND THE SAME REGISTER.** `insI` is
the landed ADDI witness; its word is IN the scope. Without this the whole scoped sentence
could hold because the scope is empty, and an empty scope passes every check R10-3 asks
for while claiming nothing. Same `seenWord`, same shape of environment, opposite verdict. -/
theorem memFreeB_seenWord_insI_true :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insI) = true := by
  rw [SaltWorks.Stack.Program.seenWord_eq_hdl]
  unfold memFreeB
  rw [SaltWorks.HDL.C4Refuted.dec_insI]
  rfl

/-- **The two together, as the discriminating pair R10-3 is entitled to cite.** -/
theorem scope_discriminates :
    memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insL) = false
      ∧ memFreeB (SaltWorks.Stack.Program.seenWord SaltWorks.HDL.C4Refuted.insI) = true :=
  ⟨memFreeB_seenWord_insL_false, memFreeB_seenWord_insI_true⟩

#audit_axioms memFreeB_seenWord_insL_false memFreeB_seenWord_insI_true
#audit_axioms scope_discriminates

end SaltWorks.HDL.MemFreeScope
