/-
  ⭐⭐⭐⭐ `core_sorts` — THE END-TO-END THEOREM, FIRING FOR THE FIRST TIME.

  `sorts_of_C4` has stood in this tree unable to fire for `core`, and the reason was never
  a missing proof: its premise is `C4Spec core`, which is FALSE. R10-3's scope replaces that
  premise with one that is TRUE, and the conclusion is unchanged. So:

    given an entry state, a memory-free trajectory, and a word stream that feeds
    `batcherSort`, the composed core's data registers hold the SORTED input.

  ⛔ EVERY SURVIVING HYPOTHESIS IS ONE `sorts_of_C4` ALREADY HAD. Nothing was added to buy
  this; one false premise was exchanged for a proved one.

  ⛔⛔ AND THE FENCE IS THE SAME ONE AS EVERYWHERE ELSE TODAY, so nobody may drop it here
  where the sentence is most quotable: the object is `CorePlace.core`, the LEAN-COMPOSED
  circuit. It is NOT `core32.v`, the hand-written RTL that was fabricated, and no theorem in
  this tree relates the two. **THE DIE IS NOT PROVED TO SORT. THE MODEL IS.**

  ⭐ THE SANITY CHECK NOBODY HAD RUN, and it is the one the whole scope idea rests on:
  R10-3 withdraws memory-touching words from the kernel-backed claim, and the obvious way
  for that to be a bad trade is if the machine's OWN WORKLOAD contains one. It does not —
  `batcherSort_touches_no_memory` is a `decide` over the whole 120-instruction program, and
  `batcherSortWords_memFree` carries it to the words. **The scope does not exclude the
  program the part exists to run.** Had this come out the other way, the scoped flagship
  would have been true and useless, and I would have owed the sitting that sentence instead.
-/
import SaltWorks.HDL.R9BNStep

namespace SaltWorks.HDL.CoreSorts

open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program
open SaltWorks.HDL.StallShape SaltWorks.HDL.MemFreeScope SaltWorks.HDL.R9BPositiveReduction
open SaltWorks.HDL.R9BPositiveHalf SaltWorks.HDL.R9BNStep
open SaltWorks.HDL.CorePlace

/-- The scoped mirror of `cycles_realise_steps_of_memFree`. -/
theorem cycles_realise_steps_of_memFree_scoped
    {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env} {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStallsOn (fun ins => memFreeB (wordAt ins)) cyc wordAt
      (fun _ => false))
    (n : Nat) (ins : SaltWorks.HDL.Env)
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins))) :
    SaltWorks.HDL.decQ (cycles cyc n ins)
      = runWords (fun k => wordAt (cycles cyc k ins)) n (SaltWorks.HDL.decQ ins) :=
  cycles_realise_steps_scoped h (fun k => wordAt (cycles cyc k ins)) ins
    (fun _ => rfl) hmf n

/-- ⭐⭐⭐ **`cycles_sort`, SCOPED AND IN T8's UNIT.** Same conclusion; two changes to what
sits above it. The cycle predicate is the SCOPED one, and **the bound is on ISA STEPS
REALISED** — `K ≤ stepsIn stalls cyc ins N`, never `K ≤ N` — as the R10 sitting of
2026-09-02 ruled under T8 (helm minute, bare filename `2026-09-02-R10-SITTING-minute.md`,
private record).

⚠️ **WHAT THE UNIT CHANGE BUYS, STATED SO NOBODY READS MORE INTO IT.** At this stall set
— `fun _ => false`, the core's OWN declaration under R10-2, single-cycle, every cycle
retires — `guard_reduces` makes the new guard **IFF** the old one. So this restatement
gains NO strength and proves NOTHING new: it fixes the UNIT, so that the day an arbitrating
core arrives only the `stalls` ARGUMENT changes and the statement shape survives. The clock
reading is still available and is now DERIVED, not asserted: `cycles_sort_scoped_clocks`
below is the original sentence, recovered from this one. `stepsIn_le` is why the unit
change cannot buy its own bound in the other direction — a clock realises at most one
step. -/
theorem cycles_sort_scoped {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStallsOn (fun ins => memFreeB (wordAt ins)) cyc wordAt
      (fun _ => false))
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ stepsIn (fun _ => false) cyc ins N →
      FeedsProgram batcherSort (fun k => wordAt (cycles cyc k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles cyc N ins)).get) := by
  obtain ⟨hpc, hreg⟩ := hentry
  obtain ⟨K, hK, _, hregs⟩ := exists_halting_count (SaltWorks.HDL.decQ ins) hpc
  refine ⟨K, hK, fun N hNsteps hfeed => ?_⟩
  have hN : K ≤ N := (guard_reduces cyc ins K N).mp hNsteps
  have hv : (fun j => (SaltWorks.HDL.decQ ins).get (dataReg j)) = v := funext hreg
  have key : (fun i : Fin 8 => (SaltWorks.HDL.decQ (cycles cyc N ins)).get (dataReg i))
      = runNetW batcher8 v := by
    funext i
    rw [cycles_realise_steps_of_memFree_scoped h N ins hmf,
      runWords_get_eq_runFor hfeed hN (dataReg i),
      hregs i, hv]
  rw [dataRegs_map_get, key]
  exact batcher8_sortsTo_word v

/-- ⭐⭐⭐⭐ **THE END-TO-END THEOREM FOR THE COMPOSED CORE — IT SORTS.** No predicate
hypothesis: `THE_POSITIVE_HALF` supplies it. The surviving hypotheses are exactly the ones
`sorts_of_C4` already had — the entry state and memory-freedom along the trajectory. -/
theorem core_sorts (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (seenWord (cycles (cycOfCirc core nextW pad) k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N,
      K ≤ stepsIn (fun _ => false) (cycOfCirc core nextW pad) ins N →
      FeedsProgram batcherSort
        (fun k => seenWord (cycles (cycOfCirc core nextW pad) k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles (cycOfCirc core nextW pad) N ins)).get) :=
  cycles_sort_scoped (THE_POSITIVE_HALF nextW pad) hentry hmf

/-! ### ⭐ THE CLOCK FORMS, **DERIVED** — R10-1's other half.

*"The bound is on ISA steps realised, never clocks; any clock guard DERIVED from the stall
declaration with its derivation theorem beside it."* These two are that clock guard. They
are the sentences this file stated before the sitting, recovered verbatim from the steps
forms above, so that a restatement is not silently a breaking change: **a consumer that
reads the old shape still gets the old shape, and gets it as a THEOREM rather than as a
second axiomatisation.** The derivation is `guard_reduces`, and it is derived from the
stall declaration `fun _ => false` — the core's own, under R10-2 — and from nothing else. -/

/-- The clock-guard reading of `cycles_sort_scoped`, DERIVED. -/
theorem cycles_sort_scoped_clocks {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word}
    (h : CycleRealisesStepOrStallsOn (fun ins => memFreeB (wordAt ins)) cyc wordAt
      (fun _ => false))
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort (fun k => wordAt (cycles cyc k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles cyc N ins)).get) := by
  obtain ⟨K, hK, hmain⟩ := cycles_sort_scoped h hentry hmf
  exact ⟨K, hK, fun N hN => hmain N ((guard_reduces cyc ins K N).mpr hN)⟩

/-- The clock-guard reading of `core_sorts`, DERIVED. -/
theorem core_sorts_clocks (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (seenWord (cycles (cycOfCirc core nextW pad) k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort
        (fun k => seenWord (cycles (cycOfCirc core nextW pad) k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles (cycOfCirc core nextW pad) N ins)).get) :=
  cycles_sort_scoped_clocks (THE_POSITIVE_HALF nextW pad) hentry hmf

/-! ### ⛔⛔ THE SANITY CHECK THE WHOLE SCOPE IDEA RESTS ON, AND NOBODY HAD RUN IT.

R10-3 withdraws the memory-touching words from the kernel-backed claim. **The obvious way
for that to be a bad trade is if the machine's OWN WORKLOAD contains one** — a scoped
flagship that excludes the program the part is built to run would be true and useless.
It does not: the sort program has no memory instruction in it, and here that is a theorem. -/

theorem batcherSort_touches_no_memory :
    ∀ i ∈ batcherSort, SaltWorks.ISA.touchesMem i = false := by
  decide

/-- ⭐ **AND THEREFORE EVERY WORD OF THE SORT PROGRAM IS IN R10-3's SCOPE.** -/
theorem batcherSortWords_memFree : ∀ w ∈ batcherSortWords, MemFree w := by
  intro w hw i hd
  obtain ⟨j, hj, hje⟩ := List.mem_map.mp hw
  have hdj : SaltWorks.ISA.decode w = some j := by rw [← hje]; exact decode_encode j
  have hji : j = i := Option.some.inj (hdj.symm.trans hd)
  subst hji
  exact batcherSort_touches_no_memory _ hj

#audit_axioms cycles_realise_steps_of_memFree_scoped cycles_sort_scoped core_sorts
#audit_axioms cycles_sort_scoped_clocks core_sorts_clocks
#audit_axioms batcherSort_touches_no_memory batcherSortWords_memFree

end SaltWorks.HDL.CoreSorts
