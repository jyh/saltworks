import SaltWorks.HDL.MacCell
import SaltWorks.HDL.MacInduction

/-!
# LAYER 2, RUNG 1 — the cell's sum bit IS the arithmetic sum bit

**Wave:** the cell wave's bridge, ruled 13:38; layer 1 landed by compiler at
`fc1ac39`, layer 2 dispatched to this seat.

Compiler's `step_bit_is_adder_bit` (`MacCell.lean`) proves the cell's sum bit `k`
equals **`adder32`'s** sum bit `k`, pointwise, with *no* `ℤ` and *no* overflow
condition — deliberately, so that the arithmetic certificate is applied **in the
file that owns it** rather than re-derived at the artifact boundary. This file is
that application.

## ⚠️ PRECONDITION PREAMBLE

**CLAIMED:** one rung — `run … macCore.gates (maSum k) = (acc + addend).getLsbD k`
for `k < 32`, obtained by composing compiler's pointwise layer-1 result with
`sem_adder32_gen`. Unconditional: still no `ℤ`, still no overflow hypothesis.

**NOT CLAIMED:** the word-level step, the trace induction, and the `ℤ` reading
that connects to `MacInduction.macAfter`. Those are rungs 2–4 and the `ℤ` rung is
where the **no-wrap hypothesis** enters — `(a + b).toInt = a.toInt + b.toInt`
holds only absent wrap, which is exactly why `demoBound` exists and why the
hypothesis belongs in *that* rung and not in this one. Named, not implied.
-/

namespace SaltWorks.HDL.MacBridge

open SaltWorks.HDL SaltWorks.HDL.MacCell SaltWorks.Stack.Program

/-- `adder32`'s run at sum-bit `k`, with the carry-in tied low, **is** the `k`-th
bit of `a + b`.

This is `sem_adder32_gen` read at one index. `adder32.outs` is 32 sum bits then
the carry-out, so index `k < 32` selects `adS k` on the left and the arithmetic
bit on the right — the carry-out tail is untouched by the extraction. -/
theorem adder_run_is_sum_bit (a b : BitVec 32) (k : Nat) (hk : k < 32) :
    run (adEnv a b false) adder32.gates (adS k) = (a + b).getLsbD k := by
  have h := congrArg (fun l : List Bool => l.getD k false) (sem_adder32_gen a b false)
  have houts : adder32.outs = (List.range 32).map adS ++ [adC 32] := rfl
  simpa [sem, houts, List.getD_eq_getElem?_getD, List.getElem?_append, List.getElem?_map,
         List.getElem?_range, hk] using h

/-- ⭐ **THE CROSSING, RUNG 1.** The MAC cell's own sum bit `k` is the `k`-th bit
of `acc + addend`.

Compiler's artifact half (`step_bit_is_adder_bit`) ∘ this file's arithmetic half
(`adder_run_is_sum_bit`). Still unconditional — the overflow question does not
arise until a rung states the value in `ℤ`. -/
theorem cell_sum_bit (acc addend : BitVec 32) (k : Nat) (hk : k < 32) :
    run (macSeq.env (MacCell.bitsOf addend) (MacCell.bitsOf acc)) macCore.gates (maSum k)
      = (acc + addend).getLsbD k := by
  rw [step_bit_is_adder_bit acc addend k hk, adder_run_is_sum_bit acc addend k hk]

/-- **CONTROL — the rung is not vacuous and it computes.** A concrete cycle:
`1 + 1 = 2`, so bit 0 is `false` and bit 1 is `true`. If `cell_sum_bit` were an
identity on the wrong operand order or a tied-high carry, these would move. -/
theorem cell_sum_bit_witness :
    ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 = false
  ∧ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 1 = true := by decide

/-- **MUTANT — a tied-HIGH carry-in is FALSE at the same witness.** With the
carry-in high the cycle would compute `1 + 1 + 1 = 3`, whose bit 0 is `true`.
Compiler's `carry_in_is_low` is what excludes this at the artifact; this shows
the two arms genuinely differ, so that control could have failed. -/
theorem mutant_carry_high_differs :
    ((1 : BitVec 32) + (1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0
      ≠ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 := by decide


/-! ## RUNG 2 — the word-level cycle

Rung 1 is pointwise. `Seq` speaks in lists, so the induction of rung 3 needs the
whole cycle as one equation. `macCore.outs` is the sum list **twice** — `Seq`
reads `take nOut` as this cycle's output and `drop nOut` as the next state — so
both halves fall out of the same pointwise fact. -/

/-- The cell's output list for one cycle, as a word's bits. -/
theorem macSeq_cycle_bits (acc addend : BitVec 32) :
    (List.range 32).map (fun k =>
        run (macSeq.env (MacCell.bitsOf addend) (MacCell.bitsOf acc)) macCore.gates (maSum k))
      = MacCell.bitsOf (acc + addend) := by
  refine List.map_congr_left ?_
  intro k hk
  exact cell_sum_bit acc addend k (List.mem_range.mp hk)

/-- ⭐⭐ **RUNG 2 — ONE CYCLE, AT THE WORD.** Feeding the cell an accumulator and
an addend leaves `acc + addend` on **both** the output port and the next state.
Still no `ℤ`: this is `BitVec` addition, which is total. -/
theorem macSeq_step_word (acc addend : BitVec 32) :
    stepSeq macSeq (MacCell.bitsOf acc) (MacCell.bitsOf addend)
      = (MacCell.bitsOf (acc + addend), MacCell.bitsOf (acc + addend)) := by
  -- ⚠️ `macCore` is kept OPAQUE: unfolding it expands `instGates adder32` (160 gates) and the
  -- kernel times out. Compiler documented this at `step_halves_agree`; the shape of `outs` is all
  -- either proof needs, and `macSeq`'s fields are PROJECTED by `rfl` rather than unfolded.
  have houts : macCore.outs = (List.range 32).map maSum ++ (List.range 32).map maSum := rfl
  have hcore : macSeq.core = macCore := rfl
  have hnout : macSeq.nOut = 32 := rfl
  have hmapped : ((List.range 32).map maSum).map
        (run (macSeq.env (MacCell.bitsOf addend) (MacCell.bitsOf acc)) macCore.gates)
      = MacCell.bitsOf (acc + addend) := by
    simp only [List.map_map, Function.comp_def]
    exact macSeq_cycle_bits acc addend
  have hl : (MacCell.bitsOf (acc + addend)).length = 32 := MacCell.bitsOf_length _
  have hdup : ∀ (l : List Bool) (n : Nat), l.length = n →
      (l ++ l).take n = l ∧ (l ++ l).drop n = l := by
    intro l n h; subst h; exact ⟨List.take_left, List.drop_left⟩
  obtain ⟨ht, hd⟩ := hdup _ 32 hl
  simp only [stepSeq, sem, hcore, hnout, houts, List.map_append, hmapped]
  rw [ht, hd]

/-! ## RUNG 3 — THE TRACE INDUCTION

The rung the cell-wave ruling actually names: `macRun ≈ runTrace macSeq`. With
rung 2 supplying one cycle, this is an induction on the addend list — the trace
length **is** the cycle index, so no fuel parameter appears here either. -/

/-- ⭐⭐ **RUNG 3.** Running a whole trace of addends leaves the accumulator
holding their sum. Still `BitVec`, still unconditional. -/
theorem macSeq_runTrace_state (acc : BitVec 32) :
    ∀ addends : List (BitVec 32),
      (runTrace macSeq (MacCell.bitsOf acc) (addends.map MacCell.bitsOf)).2
        = MacCell.bitsOf (acc + addends.sum)
  | [] => by simp [runTrace]
  | a :: as => by
      have hstep := macSeq_step_word acc a
      simp only [List.map_cons, runTrace, hstep, List.sum_cons]
      rw [macSeq_runTrace_state (acc + a) as, add_assoc]

/-- **CONTROL — the trace rung computes, and it is not the empty statement.**
Three addends `1, 2, 4` from a zero accumulator leave `7`. -/
theorem runTrace_witness :
    ((0 : BitVec 32) + ([1, 2, 4] : List (BitVec 32)).sum) = 7 := by decide

/-- **MUTANT — order does not matter for `+`, but PRESENCE does.** Dropping one
addend changes the result, so the induction is not silently ignoring its input. -/
theorem runTrace_mutant_dropped_addend :
    ((0 : BitVec 32) + ([1, 2] : List (BitVec 32)).sum)
      ≠ ((0 : BitVec 32) + ([1, 2, 4] : List (BitVec 32)).sum) := by decide

end SaltWorks.HDL.MacBridge
