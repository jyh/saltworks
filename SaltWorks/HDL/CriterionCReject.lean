/-
  THE CROSS-VERIFIER'S REJECT-DEMONSTRATION — LANDED AT LAST, AND THE REASON IT IS LATE
  IS THE FINDING.

  The ownership table's verifier clause: "the verifier must be able to say NO ... a
  cross-verifier who only reads is decoration. Each verifier owes at least one
  demonstration that their check CAN reject." I own rung zero's table row and I owed one.

  ⛔⛔ THE DEBT WAS PAID ON 2026-08-17 AND DELIVERED NOWHERE. The proof below was written
  that night into a `Scratch*.lean`, which `.gitignore` excludes — so it was green on my
  disk and absent from every clone, for sixteen days, while:
    · `docs/compiler-which-cycle-binding-BLOCK-0817.md:546` CITED
      `criterion_c_is_a_real_check` as though it were a landed theorem, in a PUBLIC block; and
    · this seat's own boot brief carried "R9/B2 cross-verify (mine, must be able to REJECT)"
      on its BLOCKED/OWED list the whole time, so every relit head re-inherited a debt that
      was, in substance, already discharged.
  ⇒ A CITATION IS A MEASUREMENT, AND A GITIGNORED PROOF IS NOT A PROOF ANYONE HAS. Both
    failures point the same way and neither was visible from inside: the prose built green
    forever because prose does not typecheck, and the brief read as careful because an
    unpaid-debt line is the safe-looking direction to be wrong in.

  WHAT CRITERION (c) ASSERTS: the stall set used in the restated C4 sentence is THE SAME
  OBJECT as A's. For that to be a CHECK rather than a courtesy it must be possible to FAIL
  it — the predicate must NOT be invariant under swapping the stall set. If it were
  invariant, "same object" would be free and (c) would be decoration.

  The port is mechanical: both dependencies (`mix_realises`, `mix_run_moves_the_state`)
  landed in `HDL/StallShape.lean` on 08/17, so nothing here needed re-proving. That is the
  shape of the whole finding — it was a delivery failure, never a proof failure.
-/
import SaltWorks.HDL.StallShape

namespace SaltWorks.HDL.CriterionCReject

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program SaltWorks.HDL.StallShape

/-- The initial decoded state has `x1 = 0`. -/
theorem mixIns_init_x1 :
    (SaltWorks.HDL.decQ (mixIns St.init)).get 1 = 0#32 := by
  show (SaltWorks.HDL.decQ (envWith St.init mixWordHold)).get 1 = 0#32
  rw [decQ_envWith_eq]
  decide +kernel

/-- An ALL-STALL predicate forces the decoded state to be constant along the trajectory. -/
theorem allStall_forces_hold {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStalls cyc wordAt (fun _ => true))
    (e : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cyc e) = SaltWorks.HDL.decQ e := by
  have he := h e
  simp only at he
  obtain ⟨hr, hp⟩ := he
  exact St_eq_of_fields hr hp (by rw [decQ_mem, decQ_mem])
    (by rw [decQ_trapped, decQ_trapped])

/-- ⭐⭐⭐ **THE REJECT-DEMONSTRATION.** The mixed machine SATISFIES the arm at `mixStalls`
(`mix_realises`) and is **REFUTED** at the all-stall set. *Same `cyc`, same `wordAt`, only
the stall set swapped.*

⇒ ***THE PREDICATE IS NOT INVARIANT UNDER THE STALL SET, so criterion (c) is a CHECK THAT
CAN FAIL rather than a courtesy: naming the wrong object is REFUTABLE, in the kernel.***

⛔ **AND THIS IS THE RTL SITUATION, NOT AN ABSTRACT ONE.** A hardware stall set derived from
a PHASE COUNTER is a different object from one derived from INSTRUCTION RETIRE. This theorem
is why that matters: get the object wrong and the sentence is FALSE, not merely unproved. -/
theorem criterion_c_can_reject (pad : SaltWorks.HDL.Env) :
    ¬ CycleRealisesStepOrStalls (mixCyc pad) Program.seenWord (fun _ => true) := by
  intro hbad
  have hold := allStall_forces_hold hbad
  have h2 : SaltWorks.HDL.decQ (cycles (mixCyc pad) 2 (mixIns St.init))
      = SaltWorks.HDL.decQ (mixIns St.init) := by
    rw [cycles_succ, cycles_succ, hold, hold]
    rfl
  have hmove := mix_run_moves_the_state pad
  rw [h2, mixIns_init_x1] at hmove
  exact absurd hmove (by decide)

/-- ⭐ **THE PAIR, IN ONE STATEMENT — this is what a cross-verifier owes.** One machine,
two stall sets, SATISFIED at one and REFUTED at the other. -/
theorem criterion_c_is_a_real_check (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStalls (mixCyc pad) Program.seenWord mixStalls
      ∧ ¬ CycleRealisesStepOrStalls (mixCyc pad) Program.seenWord (fun _ => true) :=
  ⟨mix_realises pad, criterion_c_can_reject pad⟩

#audit_axioms mixIns_init_x1 allStall_forces_hold
#audit_axioms criterion_c_can_reject criterion_c_is_a_real_check

end SaltWorks.HDL.CriterionCReject
