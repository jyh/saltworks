/-
  ⭐⭐ R9b — THE n-STEP CONSEQUENCE, AND THE ANSWER TO THE OBJECTION R10-3 WILL MEET.

  THE OBJECTION: "a SCOPED flagship is a WEAKER flagship — what does the consumer lose?"

  THE ANSWER, kernel-checked below: NOTHING. `cycles_realise_steps_scoped` has the SAME
  hypothesis list as the landed `cycles_realise_steps_of_stalls` — the consumer ALREADY
  assumed `MemFree` at every cycle it steps through, and `MemFree` IS the scope
  (`memFreeB_iff`). ⇒ **R10-3's scope withdraws exactly the words the n-step consumer never
  had.** It is free at the point of use, and that is a fact about the tree, not a
  reassurance about it.

  ⛔ THE LIMIT. This holds at the EMPTY stall set, which is `core`'s own declaration under
  R10-2. A scoped predicate does NOT recover the STALL branch for an out-of-scope stalled
  cycle -- if a later core stalls while a memory word is presented, the scoped predicate
  says nothing there and this proof does not carry. Stated now, because the empty stall set
  is what makes the argument easy and it will not always be empty.

  ⛔ AND THE HYPOTHESES ARE DRIVEN, not admired: `control_nstep_is_not_vacuous` discharges
  both of them on a real landed environment with a DECODABLE REGISTER WRITER
  (`ADDI x1, x0, 1`), not an undecodable word that would make `MemFree` free.
-/
import SaltWorks.HDL.R9BPositiveHalf

namespace SaltWorks.HDL.R9BNStep

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program
open SaltWorks.HDL.MemFreeScope SaltWorks.HDL.R9BPositiveReduction
open SaltWorks.HDL.R9BPositiveHalf SaltWorks.HDL.StallShape
open SaltWorks.HDL.CorePlace

/-- The scoped mirror of `decQ_cyc_eq_of_step`. -/
theorem decQ_cyc_eq_of_step_scoped {scope : SaltWorks.HDL.Env → Bool}
    {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env} {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStallsOn scope cyc wordAt (fun _ => false))
    (e : SaltWorks.HDL.Env) (hsc : scope e = true) (hmf : MemFree (wordAt e)) :
    SaltWorks.HDL.decQ (cyc e) = stepT (SaltWorks.HDL.decQ e) (wordAt e) := by
  have he := h e
  simp only [hsc, if_true, Bool.false_eq_true, if_false] at he
  obtain ⟨hr, hp⟩ := he
  refine St_eq_of_fields hr hp ?_ ?_
  · rw [decQ_mem, stepT_mem_frame_of_not_touchesMem _ _ hmf, decQ_mem]
  · rw [decQ_trapped, stepT_trapped_frame_of_not_touchesMem _ _ hmf, decQ_trapped]

/-- ⭐⭐⭐ **THE n-STEP DELIVERABLE, SCOPED — AND THE SCOPE COSTS THE CONSUMER NOTHING.**
`n` clocks realise `n` ISA steps. ⭐ The consumer's hypothesis list is UNCHANGED from the
landed `cycles_realise_steps_of_stalls`: it already assumed `MemFree` at every cycle, and
`MemFree` IS the scope (`memFreeB_iff`). **So R10-3's scope is free at the point of use —
it withdraws exactly the words this consumer never had.** -/
theorem cycles_realise_steps_scoped {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStallsOn (fun ins => memFreeB (wordAt ins)) cyc wordAt
      (fun _ => false))
    (ws : Nat → Word) (ins : SaltWorks.HDL.Env)
    (halign : ∀ k, ws k = wordAt (cycles cyc k ins))
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins)))
    (n : Nat) :
    SaltWorks.HDL.decQ (cycles cyc n ins)
      = runWords ws n (SaltWorks.HDL.decQ ins) := by
  induction n with
  | zero => rfl
  | succ m ih =>
      rw [cycles_succ]
      have hsc : memFreeB (wordAt (cycles cyc m ins)) = true :=
        (memFreeB_iff _).mpr (hmf m)
      rw [decQ_cyc_eq_of_step_scoped h (cycles cyc m ins) hsc (hmf m), ih,
        runWords_succ, halign m]

/-- ⭐⭐ **AND FOR THE COMPOSED CORE, WITH NO PREDICATE HYPOTHESIS AT ALL** — `THE_POSITIVE_HALF`
supplies it. *This is the sentence the flagship exists to license: `n` clocks of the fabricated
core realise `n` ISA steps, on any memory-free trajectory.* -/
theorem core_cycles_realise_steps (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    (ws : Nat → Word) (ins : SaltWorks.HDL.Env)
    (halign : ∀ k, ws k = seenWord (cycles (cycOfCirc core nextW pad) k ins))
    (hmf : ∀ k, MemFree (seenWord (cycles (cycOfCirc core nextW pad) k ins)))
    (n : Nat) :
    SaltWorks.HDL.decQ (cycles (cycOfCirc core nextW pad) n ins)
      = runWords ws n (SaltWorks.HDL.decQ ins) :=
  cycles_realise_steps_scoped (THE_POSITIVE_HALF nextW pad) ws ins halign hmf n

/-! ### ⛔⛔ THE CONTROL THAT MATTERS MOST HERE — the hypotheses could be jointly
UNSATISFIABLE, and then the theorem above is beautiful and says nothing. It is DRIVEN,
on a real landed environment, with a real decodable instruction word. -/

/-- The constant-word policy: what the core sees is `seenWord insI` at every cycle. -/
theorem seen_is_constant (pad : SaltWorks.HDL.Env) (k : Nat) :
    seenWord (cycles (cycOfCirc core (fun _ => seenWord SaltWorks.HDL.C4Refuted.insI) pad)
        k SaltWorks.HDL.C4Refuted.insI)
      = seenWord SaltWorks.HDL.C4Refuted.insI := by
  cases k with
  | zero => rfl
  | succ m => rw [cycles_succ]; exact seenWord_cycOfCirc _ _ _ _

/-- ⭐ **BOTH HYPOTHESES DISCHARGED, AND THE CONCLUSION INSTANTIATED AT `n = 2`.** The word is
`ADDI x1, x0, 1` — DECODABLE and a REGISTER WRITER, not an undecodable NOP-advance that would
make `MemFree` free. ⇒ *the n-step theorem has non-empty traffic.* -/
theorem control_nstep_is_not_vacuous (pad : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycles (cycOfCirc core
        (fun _ => seenWord SaltWorks.HDL.C4Refuted.insI) pad) 2 SaltWorks.HDL.C4Refuted.insI)
      = runWords (fun _ => seenWord SaltWorks.HDL.C4Refuted.insI) 2
          (SaltWorks.HDL.decQ SaltWorks.HDL.C4Refuted.insI) :=
  core_cycles_realise_steps _ pad _ _
    (fun k => (seen_is_constant pad k).symm)
    (fun k => by
      rw [seen_is_constant pad k]
      exact (memFreeB_iff _).mp memFreeB_seenWord_insI_true)
    2

#audit_axioms decQ_cyc_eq_of_step_scoped cycles_realise_steps_scoped
#audit_axioms core_cycles_realise_steps
#audit_axioms seen_is_constant control_nstep_is_not_vacuous

end SaltWorks.HDL.R9BNStep
