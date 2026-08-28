/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
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

/-- ⭐ **THE CROSSING, RUNG 1.** The MAC cell's own sum bit `k` is the `k`-th bit
of `acc + addend`.

Compiler's artifact half (`step_bit_is_adder_bit`) ∘ the arithmetic half, now
HOISTED to `Stack.Program.adder_run_is_sum_bit` (Captain's ruling 08-10) and
reached through this file's `open`. Still unconditional — the overflow question does not
arise until a rung states the value in `ℤ`. -/
theorem cell_sum_bit (acc addend : BitVec 32) (cin : Bool) (k : Nat) (hk : k < 32) :
    run (macSeq.env (MacCell.bitsOf addend ++ [cin]) (MacCell.bitsOf acc)) macCore.gates (maSum k)
      = (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin)).getLsbD k := by
  rw [step_bit_is_adder_bit acc addend cin k hk, adder_run_is_sum_bit acc addend cin k hk]

/-- **CONTROL — the rung is not vacuous and it computes.** A concrete cycle:
`1 + 1 = 2`, so bit 0 is `false` and bit 1 is `true`. If `cell_sum_bit` were an
identity on the wrong operand order or a tied-high carry, these would move. -/
theorem cell_sum_bit_witness :
    ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 = false
  ∧ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 1 = true := by decide

/-- **THE TWO CARRY-IN ARMS GENUINELY DIFFER.** With the carry-in high a cycle
computes `1 + 1 + 1 = 3`, whose bit 0 is `true`; with it low, `2`, whose bit 0 is
`false`.

⚠️ *Historical note, corrected at the (b) ruling: this was once framed as a MUTANT
excluded by `MacCell.carry_in_is_low`. **That control was DELIBERATELY RETIRED
when ruling (b) untied the carry-in and admitted it as a port — nothing excludes a
high carry-in any more, BY DESIGN, because the sign cycle needs it.** What the
statement below still earns is the arms' distinctness, which is what makes the
carry-in load-bearing rather than decorative.* -/
theorem mutant_carry_high_differs :
    ((1 : BitVec 32) + (1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0
      ≠ ((1 : BitVec 32) + (1 : BitVec 32)).getLsbD 0 := by decide


/-! ## RUNG 2 — the word-level cycle

Rung 1 is pointwise. `Seq` speaks in lists, so the induction of rung 3 needs the
whole cycle as one equation. `macCore.outs` is the sum list **twice** — `Seq`
reads `take nOut` as this cycle's output and `drop nOut` as the next state — so
both halves fall out of the same pointwise fact. -/

/-- The cell's output list for one cycle, as a word's bits. -/
theorem macSeq_cycle_bits (acc addend : BitVec 32) (cin : Bool) :
    (List.range 32).map (fun k =>
        run (macSeq.env (MacCell.bitsOf addend ++ [cin]) (MacCell.bitsOf acc))
          macCore.gates (maSum k))
      = MacCell.bitsOf (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin)) := by
  refine List.map_congr_left ?_
  intro k hk
  exact cell_sum_bit acc addend cin k (List.mem_range.mp hk)

/-- ⭐⭐ **RUNG 2 — ONE CYCLE, AT THE WORD.** Feeding the cell an accumulator and
an addend leaves `acc + addend` on **both** the output port and the next state.
Still no `ℤ`: this is `BitVec` addition, which is total. -/
theorem macSeq_step_word (acc addend : BitVec 32) (cin : Bool) :
    stepSeq macSeq (MacCell.bitsOf acc) (MacCell.bitsOf addend ++ [cin])
      = (MacCell.bitsOf (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin)),
         MacCell.bitsOf (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin))) := by
  -- ⚠️ `macCore` is kept OPAQUE: unfolding it expands `instGates adder32` (160 gates) and the
  -- kernel times out. Compiler documented this at `step_halves_agree`; the shape of `outs` is all
  -- either proof needs, and `macSeq`'s fields are PROJECTED by `rfl` rather than unfolded.
  have houts : macCore.outs = (List.range 32).map maSum ++ (List.range 32).map maSum := rfl
  have hcore : macSeq.core = macCore := rfl
  have hnout : macSeq.nOut = 32 := rfl
  have hmapped : ((List.range 32).map maSum).map
        (run (macSeq.env (MacCell.bitsOf addend ++ [cin]) (MacCell.bitsOf acc)) macCore.gates)
      = MacCell.bitsOf (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin)) := by
    simp only [List.map_map, Function.comp_def]
    exact macSeq_cycle_bits acc addend cin
  have hl : (MacCell.bitsOf (acc + addend + BitVec.setWidth 32 (BitVec.ofBool cin))).length = 32 :=
    MacCell.bitsOf_length _
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
      (runTrace macSeq (MacCell.bitsOf acc)
          (addends.map (fun a => MacCell.bitsOf a ++ [false]))).2
        = MacCell.bitsOf (acc + addends.sum)
  | [] => by simp [runTrace]
  | a :: as => by
      have h0 : BitVec.setWidth 32 (BitVec.ofBool false) = (0 : BitVec 32) := by decide
      have hstep := macSeq_step_word acc a false
      rw [h0, add_zero] at hstep
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

/-! ## RUNG 4 — THE ARITHMETIC READING, AND THE ONLY HYPOTHESIS IN THE CHAIN

### ⚠️ PRECONDITION PREAMBLE — validated against the live tree BEFORE anything was proved

**MATH'S SHAPE (bus, 2026-08-09 14:27), quoted rather than paraphrased:**

```
4a  the single-step join   (a+b).toInt = a.toInt + b.toInt  under ¬saddOverflow
                           — a re-export that NAMES the crossing point
4b  the fold-wise version  every PREFIX of the addend trace must not overflow;
                           the hypothesis is a list predicate, not a scalar
4c  the demo instance      demoBound (131,200 < 2^31) discharges 4b at demo
                           scale by decide
```

**ANCHORS CHECKED, NOT ASSUMED** (toolchain `leanprover/lean4:v4.32.0-rc1`):

* `BitVec.toInt_add_of_not_saddOverflow` — math posted it as *"Init/Data/BitVec,
  ~line 3711"*. It is at `Init/Data/BitVec/Lemmas.lean:3711`, statement
  `{x y : BitVec w} (h : ¬ saddOverflow x y) : (x + y).toInt = x.toInt + y.toInt`.
  **Exact line; the only drift is directory-vs-file in the citation.**
* `BitVec.saddOverflow` — `Init/Data/BitVec/Basic.lean:780`, core's own `bvsaddo`:
  `(x.toInt + y.toInt ≥ 2 ^ (w - 1)) || (x.toInt + y.toInt < - 2 ^ (w - 1))`.
* rung 3 = `macSeq_runTrace_state` above (`c754b29`, this file);
  `Mac.demoBound`, `Mac.demoBound_eq`, `Mac.psum`, `Mac.macAfter`,
  `Mac.mac_partial` — `MacInduction.lean` §1/§2/§5.

**NO STATEMENT WAS ALTERED.** The shape as posted is provable as posted.

### WHAT RUNG 4 CLAIMS, AT EXACTLY ITS SIZE

Rung 3 hands over a **word**: `(runTrace …).2 = MacCell.bitsOf (acc + addends.sum)`.
Rung 4's entire obligation is that word's `toInt`. **No `Seq`, no bits, no `env`,
and nothing from `MacCell` is unfolded** — `macSeq` occurs below only as the opaque
constant that rung 3's own statement carries. *(Unfolding `macCore` expands
`instGates adder32`, 160 gates, and the kernel times out; compiler documented that
at `step_halves_agree` and math re-flagged it before this rung opened. This rung
never goes near it.)*

⇒ ***What rung 4 proves is that the fed sequence MEANS `b + W · psum`, the
accumulation BEFORE the sign cycle, under the
no-overflow hypothesis.*** That the cell ADDS what it is fed is rungs 1–3, and is
unconditional. This rung adds the *reading*, and the reading is the part that
carries a hypothesis. **The claim is that size and no larger.**
-/

/-- ⭐ **RUNG 4a — THE SINGLE-STEP JOIN, NAMING THE CROSSING POINT.**

A specialization of `BitVec.toInt_add_of_not_saddOverflow` to width 32 — the width
of rung 3's word, which is the whole reason the re-export exists: the crossing from
the cell's `BitVec` arithmetic into `ℤ` happens at exactly one place, and that place
deserves a name here rather than a library citation repeated at every use site.

**The hypothesis is library-native.** `saddOverflow` is not a hand-rolled bound; it
is core's `bvsaddo`. So the no-wrap condition is stated in the library's own
vocabulary and `demoBound` discharges *that*, never a private surrogate that could
drift from it. -/
theorem step_toInt_of_not_saddOverflow (acc addend : BitVec 32)
    (h : ¬ acc.saddOverflow addend) :
    (acc + addend).toInt = acc.toInt + addend.toInt :=
  BitVec.toInt_add_of_not_saddOverflow h

/-- **4b'S HYPOTHESIS — A LIST PREDICATE, AND IT IS ABOUT PREFIXES.**

`noOverflowFrom acc l` says: adding `l`'s head to `acc` does not overflow, **and**
the same holds again from `acc + head` for the tail. Unfolded, that is exactly *"no
prefix sum overflows"* — the running accumulator is checked at **every** cycle, not
once at the end.

⛔ **THE TOTAL-ONLY READING IS A DIFFERENT AND WRONG THEOREM, AND IT WOULD PASS EVERY
TEST.** Two's-complement wrap is invertible, so a fold can overflow at an
intermediate cycle and come back: the *total* is then in range, the total-only
hypothesis is satisfied, and the `ℤ` reading is false anyway.
`mutant_total_only_hypothesis_holds` / `mutant_total_only_conclusion_is_false`
exhibit that trace. *A hypothesis no test ever violates is a hypothesis nobody
audits — which is why the weaker one is stated here only to be refuted.* -/
def noOverflowFrom (acc : BitVec 32) : List (BitVec 32) → Bool
  | []      => true
  | a :: as => !(acc.saddOverflow a) && noOverflowFrom (acc + a) as

/-- ⭐⭐ **RUNG 4b — THE FOLD-WISE JOIN.** Under the prefix predicate, the word rung 3
leaves in the accumulator reads in `ℤ` as the accumulator's initial value plus the
addends' `ℤ` values. This is the induction that carries the wave: 4a is applied once
per cycle, at the running accumulator, which is precisely what the prefix predicate
supplies and what a scalar hypothesis could not. -/
theorem sum_toInt_of_noOverflowFrom (addends : List (BitVec 32)) :
    ∀ acc : BitVec 32, noOverflowFrom acc addends = true →
      (acc + addends.sum).toInt = acc.toInt + (addends.map BitVec.toInt).sum := by
  induction addends with
  | nil => intro acc _; simp
  | cons a as ih =>
      intro acc h
      simp only [noOverflowFrom, Bool.and_eq_true, Bool.not_eq_true'] at h
      obtain ⟨h1, h2⟩ := h
      have hstep : (acc + a).toInt = acc.toInt + a.toInt :=
        step_toInt_of_not_saddOverflow acc a (by simp [h1])
      have hih := ih (acc + a) h2
      rw [List.sum_cons, ← add_assoc, hih, hstep, List.map_cons, List.sum_cons, add_assoc]

/-! ### RUNG 4c — THE DEMO INSTANCE

`Mac.demoBound = 131200`, and `Mac.demoBound_eq` states it as **data with its
derivation**: `4 * (2 * (128 * 128)) + 128` — four message terms of a
two-dimensional int8 dot product (`|W · h| ≤ 128 · 128` per product, eight products)
plus an int8 bias. `Mac.demoBound_lt_two_pow_31` is `131200 < 2^31`.

Two things are supplied below, and they answer different questions:

* **the gate** — a scalar sufficient condition, parametric in the bound `B`, so the
  margin is visible as arithmetic rather than asserted. It needs `2 * B < 2^31`,
  which `demoBound` clears by a factor of ≈ 8,000.
* **the instance** — a concrete demo-scale trace whose running sums reach
  `demoBound` **exactly**, discharging 4b's predicate by `decide`. It is the
  worst case at demo scale, not a comfortable one.
-/

/-- **THE GATE, PARAMETRIC IN THE BOUND.** Two operands within `±B` cannot overflow a
signed 32-bit add when `2 * B < 2^31`. Stated with `B` free on purpose: it is what
makes the false-bound mutant expressible as a *statement* rather than as a failed
tactic (`mutant_false_bound_gate_is_false`). -/
theorem not_saddOverflow_of_abs_le (B : ℤ) (hB : 2 * B < 2 ^ 31)
    (x y : BitVec 32) (hx : |x.toInt| ≤ B) (hy : |y.toInt| ≤ B) :
    ¬ x.saddOverflow y := by
  rw [abs_le] at hx hy
  have hpow : ((2 : ℤ) ^ (32 - 1)) = 2 ^ 31 := by norm_num
  simp only [BitVec.saddOverflow, hpow, Bool.or_eq_true, decide_eq_true_eq, not_or, not_le, not_lt]
  have h31 : ((2 : ℤ) ^ 31) = 2147483648 := by norm_num
  rw [h31] at hB ⊢
  omega

/-- **THE GATE AT `demoBound`** — the margin discharged, not assumed. -/
theorem not_saddOverflow_of_demoBound (x y : BitVec 32)
    (hx : |x.toInt| ≤ Mac.demoBound) (hy : |y.toInt| ≤ Mac.demoBound) :
    ¬ x.saddOverflow y :=
  not_saddOverflow_of_abs_le Mac.demoBound (by decide) x y hx hy

/-- The demo trace, realising `demoBound`'s derivation term for term: the streamed
int8 bias `128`, then the eight partial products of a 4-term, 2-dimensional int8 dot
product at full magnitude `128 · 128 = 16384`. Its running sums peak at exactly
`4 * (2 * (128 * 128)) + 128 = 131200`. -/
def demoTrace : List (BitVec 32) :=
  [128, 16384, 16384, 16384, 16384, 16384, 16384, 16384, 16384]

/-- ⭐⭐ **RUNG 4c — `demoBound` DISCHARGES 4b AT DEMO SCALE, BY `decide`.** -/
theorem demo_noOverflowFrom : noOverflowFrom 0 demoTrace = true := by decide

/-- **THE TRACE IS THE WORST CASE, NOT A COMFORTABLE ONE**: its total is `demoBound`
on the nose. Computed, not asserted. -/
theorem demoTrace_sum_is_demoBound :
    ((0 : BitVec 32) + demoTrace.sum).toInt = Mac.demoBound := by decide

/-- ⭐ **THE READING, AT DEMO SCALE.** 4c ∘ 4b: the word the cell is left holding has
the `ℤ` value of the addends it was fed. -/
theorem demo_reading :
    ((0 : BitVec 32) + demoTrace.sum).toInt
      = (0 : BitVec 32).toInt + (demoTrace.map BitVec.toInt).sum :=
  sum_toInt_of_noOverflowFrom demoTrace 0 demo_noOverflowFrom

/-! ### MUTATION CONTROLS — RUN, NOT CITED

All three share one witness, `2^30 = 1073741824`, whose double is `2^31` — one past
the int32 maximum `2^31 - 1`. Each mutated statement is shown **FALSE**, with the
witness in hand; unreachable-by-one-route is not a control. -/

/-- The witness overflows — so the mutants below are not failing for some unrelated
reason. -/
theorem mutant_witness_overflows :
    (1073741824 : BitVec 32).saddOverflow (1073741824 : BitVec 32) = true := by decide

/-- ⛔ **MUTANT (ii) — 4a WITH `¬saddOverflow` DROPPED IS FALSE.** At the witness the
word reads `-2^31` and the `ℤ` sum is `+2^31`. -/
theorem mutant_4a_dropped_hypothesis :
    ((1073741824 : BitVec 32) + (1073741824 : BitVec 32)).toInt
      ≠ (1073741824 : BitVec 32).toInt + (1073741824 : BitVec 32).toInt := by decide

/-- The trace whose *second prefix* overflows. -/
def badTrace : List (BitVec 32) := [1073741824, 1073741824]

/-- ⛔ **MUTANT (i) — THE FALSE BOUND.** 4c's `decide`, which returns `true` at demo
scale, returns `false` once a running sum reaches `2^31`. -/
theorem mutant_false_bound_decides_false : noOverflowFrom 0 badTrace = false := by decide

/-- ⛔ **MUTANT (i), AS A STATEMENT.** The gate with `B` pushed one step past its safe
threshold (`2 * B < 2^31` fails at `B = 2^30`) is FALSE, witnessed. -/
theorem mutant_false_bound_gate_is_false :
    ¬ (∀ x y : BitVec 32, |x.toInt| ≤ 2 ^ 30 → |y.toInt| ≤ 2 ^ 30 → ¬ x.saddOverflow y) := by
  intro h
  exact h 1073741824 1073741824 (by decide) (by decide) (by decide)

/-- ⛔ **MUTANT (iii), FIRST HALF — the total-only hypothesis HOLDS on `badTrace`.**
The wrap at cycle 2 is undone by nothing; the total simply lands back in range. -/
theorem mutant_total_only_hypothesis_holds :
    ¬ (0 : BitVec 32).saddOverflow badTrace.sum := by decide

/-- ⛔⛔ **MUTANT (iii), SECOND HALF — and the conclusion is FALSE there.** So the
total-only version of 4b is not a weaker true theorem; it is a false one. **This is
the control that justifies the prefix predicate**, and no test at demo scale would
ever have produced it. -/
theorem mutant_total_only_conclusion_is_false :
    ((0 : BitVec 32) + badTrace.sum).toInt
      ≠ (0 : BitVec 32).toInt + (badTrace.map BitVec.toInt).sum := by decide

/-! ### THE COMPOSED COROLLARY — the arithmetic reading reaching the cell

Rungs 1–3 (hardware, unconditional) ∘ 4a/4b (the `ℤ` reading, hypothesised) against
`MacInduction.macAfter`. The addend trace is the one `macAfter`'s recursion asks
for, presented cycle by cycle.

⚠️ **THE WEIGHT'S ARRIVAL IS LEFT ABSTRACT, DELIBERATELY.** `Wsh` is an indexed
family of words with `hW : (Wsh t).toInt = W * 2^t`, and **nothing here says how a
register comes to hold it.** The weight-shift organ's load path is silicon's open
board item; a statement that named a load mechanism would have to be restated when
that is ruled. This one survives either ruling.

⚠️ **ONE INPUT. `st₀` IS A MODELLING DEVICE, NOT A MECHANISM.** The corollary is a
single `runTrace` from a single initial accumulator state — one input's cycles.
Silicon's caution is binding on this paragraph: *a register does not acquire a value
because a theorem quantified over one*, so the initial state below is **a hypothesis
about hardware that does not exist yet**, not a description of hardware that does.

⛔ **AND THE COMPOSITION ACROSS INPUTS IS NOT CLAIMED, FOR A REASON THAT IS A
QUANTIFIER RATHER THAN A WIRE.** Compiler's 14:27 consequence: the two organs need
**opposite state discipline** — the accumulator's state PERSISTS across inputs (it is
accumulating), the weight register's RE-INITIALISES per input (`W_i` is new each
time). One `runTrace` from one initial state spanning two inputs typechecks and
places cleanly and is wrong either way: it freezes `W` (weight-stationary, the CNN
special case, not the ruled dual-stream mode) or it resets the accumulator
(destroying the dot product). The guards are already in the artifact and are cited
rather than duplicated: `MacCell.weight_state_moves_so_reload_is_required` (from
weight `1` the register holds `2`, then `4` — never `1` again) and
`MacCell.stream_enters_only_through_the_load_gate` (the reload port EXISTS since
load-path option A — b801003 — but is a gated, scheduled phase, not a mid-stream
path; prose updated 15:3x when the pre-A citation went stale: its predecessor
said "no port to reload through", true before A and false after).
**A multi-input statement must therefore be per-input traces, never one
trace spanning inputs — and this corollary is deliberately the per-input one.** -/

/-- The addend trace of one input's `n` accumulation cycles: `Wsh t` when the stream
bit is set, `0` when it is not. Term for term the `macAfter` summand
`if x t then W * 2^t else 0`. -/
def addendTrace (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (n : ℕ) : List (BitVec 32) :=
  (List.range n).map (fun t => if x t then Wsh t else 0)

/-- The trace's `ℤ` values sum to `Mac.psum` — the arithmetic file's partial sum. -/
theorem addendTrace_toInt_sum (W : ℤ) (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) :
    ∀ n : ℕ, (∀ t, t < n → (Wsh t).toInt = W * 2 ^ t) →
      ((addendTrace Wsh x n).map BitVec.toInt).sum = Mac.psum W x n := by
  intro n
  induction n with
  | zero => intro _; simp [addendTrace, Mac.psum]
  | succ m ih =>
      intro hW
      have hstep : addendTrace Wsh x (m + 1)
          = addendTrace Wsh x m ++ [if x m then Wsh m else 0] := by
        simp [addendTrace, List.range_succ]
      rw [hstep, List.map_append, List.sum_append,
          ih (fun t ht => hW t (Nat.lt_succ_of_lt ht))]
      rcases Bool.eq_false_or_eq_true (x m) with hx | hx
      · simp [Mac.psum, hx, hW m (Nat.lt_succ_self m)]
      · simp [Mac.psum, hx]

/-- ⭐⭐⭐ **THE COMPOSED COROLLARY — THE ARITHMETIC READING REACHES THE CELL.**

For one input: the cell's final state is the word `b + Σ addends` (rung 3,
unconditional), and — under 4b's prefix predicate — that word's `ℤ` value is
`Mac.macAfter W b.toInt x (n+1)`, the value `MacInduction` proves equals
`b + W · sval` once the sign cycle is composed (`Mac.mac_correct`).

**That is the claim: the sequence the cell is fed MEANS `b + W · psum` — the
accumulation BEFORE the sign cycle (math's review, 14:50: the signed reading
closes only when the sign cycle composes, a design decision on the board) — under the
no-overflow hypothesis.** Rungs 1–3 supply that the cell adds what it is fed; this
supplies what the feeding means. -/
theorem cell_state_toInt_eq_macAfter
    (W : ℤ) (b : BitVec 32) (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (n : ℕ)
    (hW : ∀ t, t < n → (Wsh t).toInt = W * 2 ^ t)
    (hno : noOverflowFrom b (addendTrace Wsh x n) = true) :
    (runTrace macSeq (MacCell.bitsOf b)
          ((addendTrace Wsh x n).map (fun a => MacCell.bitsOf a ++ [false]))).2
        = MacCell.bitsOf (b + (addendTrace Wsh x n).sum)
  ∧ (b + (addendTrace Wsh x n).sum).toInt = Mac.macAfter W b.toInt x (n + 1) := by
  refine ⟨macSeq_runTrace_state b (addendTrace Wsh x n), ?_⟩
  rw [sum_toInt_of_noOverflowFrom (addendTrace Wsh x n) b hno,
      addendTrace_toInt_sum W Wsh x n hW, Mac.mac_partial]

/-! ## THE hW-DISCHARGE — the weight-shift organ, composed

Rung 4's corollary assumes a schedule via `hW : (Wsh t).toInt = W * 2^t`. This
section replaces the assumption with the landed organ: `wshift_next_bit_zero`
and `wshift_next_bit_succ` give one cycle, and the trace induction gives
`W <<< t` after `t` cycles. -/

/-- One shift cycle with `load` low: the next state is the left shift by one.
`wsCore.outs` is the 32 AND-bits then the next state, so `drop 32` is the state
half — `wsLsb` (which is `ld && x`, here `false`) followed by bits `0…30`. -/
theorem wshift_step_word (w : BitVec 32) (x : Bool) :
    (stepSeq wshiftSeq (MacCell.bitsOf w) [x, false]).2 = MacCell.bitsOf (w <<< 1) := by
  have houts : wsCore.outs
      = (List.range 32).map wsAnd ++ (wsLsb :: (List.range 31).map wsW) := rfl
  have hcore : wshiftSeq.core = wsCore := rfl
  have hnout : wshiftSeq.nOut = 32 := rfl
  have hlenA : (((List.range 32).map wsAnd).map
      (run (wshiftSeq.env [x, false] (MacCell.bitsOf w)) wsCore.gates)).length = 32 := by simp
  simp only [stepSeq, sem, hcore, hnout, houts, List.map_append]
  rw [List.drop_left' hlenA]
  have hstate : (wsLsb :: (List.range 31).map wsW).map
        (run (wshiftSeq.env [x, false] (MacCell.bitsOf w)) wsCore.gates)
      = MacCell.bitsOf (w <<< 1) := by
    simp only [List.map_cons, List.map_map, Function.comp_def,
               wshift_next_bit_zero_when_not_loading x w]
    have : MacCell.bitsOf (w <<< 1)
        = false :: (List.range 31).map (fun k => w.getLsbD k) := by
      simp [MacCell.bitsOf, List.range_succ_eq_map, BitVec.getLsbD_shiftLeft]
    rw [this]
    refine congrArg (List.cons false) (List.map_congr_left ?_)
    intro k hk
    exact wshift_next_bit_succ x false w k (List.mem_range.mp hk)
  exact hstate

/-- ⭐⭐ **THE hW-DISCHARGE, TRACE FORM.** After `t` load-low cycles the weight
register holds `W <<< t` — the schedule `hW` assumed is now a theorem about the
landed organ. -/
theorem wshift_runTrace_state (W : BitVec 32) (x : Bool) :
    ∀ t : ℕ, (runTrace wshiftSeq (MacCell.bitsOf W) (List.replicate t [x, false])).2
      = MacCell.bitsOf (W <<< t)
  | 0 => by simp [runTrace]
  | t + 1 => by
      have hstep := wshift_step_word W x
      simp only [List.replicate_succ, runTrace]
      rw [show (stepSeq wshiftSeq (MacCell.bitsOf W) [x, false]).2
            = MacCell.bitsOf (W <<< 1) from hstep,
          wshift_runTrace_state (W <<< 1) x t]
      congr 1
      rw [← BitVec.shiftLeft_add]
      congr 1
      omega

/-! ## THE SIGN CYCLE — one further cycle, carry-in HIGH

`MacInduction.mac_sign_cycle` keeps the sign step OUT of the accumulation
recursion so the induction stays uniform. This is that discipline at the
artifact: rung 3 stands unchanged over the addend trace, and the sign cycle is
**one more `stepSeq`** — which is why the `(addend, carry)` pair form was not
needed. The carry-in exists because ruling (b) admitted it as a port. -/

/-- One cycle with carry-in HIGH: the cell computes `acc + c + 1`. -/
theorem cell_carry_cycle (acc c : BitVec 32) :
    (stepSeq macSeq (MacCell.bitsOf acc) (MacCell.bitsOf c ++ [true])).2
      = MacCell.bitsOf (acc + c + 1) := by
  have h1 : BitVec.setWidth 32 (BitVec.ofBool true) = (1 : BitVec 32) := by decide
  have h := macSeq_step_word acc c true
  rw [h1] at h
  rw [h]

/-- ⭐⭐ **THE SIGN CYCLE.** Feeding the COMPLEMENT of the top shifted weight with
the carry-in HIGH subtracts it — `acc + ~w + 1 = acc - w`, the landed subtraction
idiom (`CorePlace.subtraction_is_a_plus_not_b_plus_one`) running on the cell. -/
theorem cell_sign_cycle (acc w : BitVec 32) :
    (stepSeq macSeq (MacCell.bitsOf acc) (MacCell.bitsOf (~~~w) ++ [true])).2
      = MacCell.bitsOf (acc - w) := by
  rw [cell_carry_cycle acc (~~~w)]
  congr 1
  rw [sub_eq_add_neg, BitVec.neg_eq_not_add, ← add_assoc]
  rfl

/-- **CONTROL — it computes, and subtraction is what it computes.** -/
theorem cell_sign_cycle_witness :
    ((5 : BitVec 32) + (~~~(3 : BitVec 32)) + 1) = 2 := by decide

/-- ⛔ **MUTANT — CARRY-IN LOW IS OFF BY ONE, at the same witness.** With the
complement but no carry-in the cell computes `acc - w - 1`. This is precisely the
error `subtraction_is_a_plus_not_b_plus_one` names, and it is invisible to every
placement certificate. -/
theorem mutant_sign_cycle_without_carry_is_off_by_one :
    ((5 : BitVec 32) + (~~~(3 : BitVec 32))) ≠ ((5 : BitVec 32) - 3) := by decide

/-! ## THE JOIN — the cell computes `b + W · sval`, end to end

Every part was landed and none of them were composed. This is the composition:
`m` addend cycles (rung 3 → `macAfter`), then ONE sign cycle (the complement with
carry-in high → subtraction), read in `ℤ` under the two library-native
no-overflow hypotheses. Indexing at `m + 1` avoids `Nat` subtraction: the trace
carries bits `0…m-1` and the sign cycle carries bit `m`. -/

/-- The sign cycle's operand: the top shifted weight when its stream bit is set. -/
def signOperand (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (m : ℕ) : BitVec 32 :=
  if x m then Wsh m else 0

/-- ⭐⭐⭐ **THE CELL COMPUTES THE SIGNED MAC.** After `m` addend cycles and one
sign cycle, the state is a word whose `ℤ` value is `Mac.macFinal` — which
`Mac.mac_correct` reads as `b + W · sval x (m+1)`.

*This is the sentence "the cell is certified" is allowed to mean.* -/
theorem cell_full_mac
    (W : ℤ) (b : BitVec 32) (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (m : ℕ)
    (hW : ∀ t, t < m → (Wsh t).toInt = W * 2 ^ t)
    (hWm : (Wsh m).toInt = W * 2 ^ m)
    (hno : noOverflowFrom b (addendTrace Wsh x m) = true)
    (hsign : ¬ BitVec.ssubOverflow (b + (addendTrace Wsh x m).sum)
                (signOperand Wsh x m)) :
    (runTrace macSeq (MacCell.bitsOf b)
        ((addendTrace Wsh x m).map (fun a => MacCell.bitsOf a ++ [false])
          ++ [MacCell.bitsOf (~~~(signOperand Wsh x m)) ++ [true]])).2
      = MacCell.bitsOf ((b + (addendTrace Wsh x m).sum) - signOperand Wsh x m)
  ∧ ((b + (addendTrace Wsh x m).sum) - signOperand Wsh x m).toInt
      = Mac.macFinal W b.toInt x (m + 1) := by
  obtain ⟨hstate, hval⟩ := cell_state_toInt_eq_macAfter W b Wsh x m hW hno
  constructor
  · rw [runTrace_append, hstate]
    show (stepSeq macSeq (MacCell.bitsOf (b + (addendTrace Wsh x m).sum))
            (MacCell.bitsOf (~~~(signOperand Wsh x m)) ++ [true])).2 = _
    exact cell_sign_cycle _ _
  · rw [BitVec.toInt_sub_of_not_ssubOverflow hsign, hval, Mac.macFinal]
    simp only [Nat.add_sub_cancel, signOperand]
    by_cases hx : x m
    · simp [hx, hWm]
    · simp [hx]

/-- ⭐ **AND THE SENTENCE ITSELF**, with `Mac.mac_correct` composed: the cell's
final state reads as `b + W · sval`. -/
theorem cell_computes_signed_mac
    (W : ℤ) (b : BitVec 32) (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (m : ℕ)
    (hW : ∀ t, t < m → (Wsh t).toInt = W * 2 ^ t)
    (hWm : (Wsh m).toInt = W * 2 ^ m)
    (hno : noOverflowFrom b (addendTrace Wsh x m) = true)
    (hsign : ¬ BitVec.ssubOverflow (b + (addendTrace Wsh x m).sum)
                (signOperand Wsh x m)) :
    ((b + (addendTrace Wsh x m).sum) - signOperand Wsh x m).toInt
      = b.toInt + W * Mac.sval x (m + 1) := by
  rw [(cell_full_mac W b Wsh x m hW hWm hno hsign).2,
      Mac.mac_correct W b.toInt x (m + 1) (by omega)]

/-! ## THE TRACE INHERITANCE — the composed cell's trace, and what it inherits

### ⚠️ PRECONDITION PREAMBLE — quoted from the live tree, checked before anything was proved

**WHAT THIS SECTION CONSUMES, by name and exact statement** (toolchain
`leanprover/lean4:v4.32.0-rc1`, tree at `3c07566`):

* `MacCell.cell_sum_bit` (the composition theorem, `39af5fd`/`c253181`) — the **acc′ half**:
  `run (cellEnv x ld cin w acc) ccCore.gates (instMap macCore ccMSig ccMOff (maSum k))
   = run (mEnv x cin w acc) macCore.gates (maSum k)`, with
  `mEnv x cin w acc = macSeq.env (bitsOf (andWord x w) ++ [cin]) (bitsOf acc)`.
* `MacCell.cell_wsh_next` (`3c07566`) — the **wsh′ half**, which did not exist when this
  section was briefed: `run (cellEnv …) ccCore.gates (ccWshNext k)
  = run (wEnv x ld w) wsCore.gates ((wsCore.outs.drop 32).getD k 0)`. *Cited, not rebuilt.*
* `MacCell.wshift_next_bit_zero_when_not_loading` and `MacCell.wshift_next_bit_succ` — the
  weight organ's own two shift theorems, which turn that net-level equality into `w <<< 1`.
* `macSeq_cycle_bits` and ⭐ `macSeq_runTrace_state` (rung 3, this file) — the **precedent**
  this induction is the sibling of, one level up, and the theorem the inheritance cites.
* `cell_state_toInt_eq_macAfter` and `cell_computes_signed_mac` (this file) — **the join**.
  Cited whole; nothing in them is re-proved here.

**SHAPE CHECKED, NOT ASSUMED.** `cellSeq.nState = 64` and `ccCore.outs` is
`acc′(32) ++ wsh′(32) ++ acc′(32)`, so `stepSeq`'s `drop nOut` is `wsh′ ‖ acc′` **in that
order** (`MacCell.cell_state_layout` names those nets; the two lemmas above give their
VALUES, which is the difference this section had to close).

**TRAPS BANKED, AND OBSERVED.** `macCore`/`ccCore` are kept **opaque** throughout — the
193-gate list is never unfolded in `simp`; `macSeq`/`cellSeq` fields are projected by `rfl`.
`BitVec.shiftLeft_shiftLeft` does not exist; the real name is `BitVec.shiftLeft_add`, used
below exactly as `wshift_runTrace_state` uses it. No `bv_decide`.

**NO EXISTING STATEMENT WAS ALTERED.** Everything below is added beside.

### ⚠️ WHICH ARROWS ARE MINE AND WHICH ARE CITED

```
  mine    the wsh′ bit value        cell_wsh_next  ∘  the organ's two shift theorems
  mine    the two halves at the word, and the full-state step   cellSeq_step_word
  mine    THE TRACE INDUCTION                                   cellSeq_runTrace_state
  mine    the inheritance, i.e. rung 3's state read off the cell's own trace
  cited   the ℤ reading (macAfter, b + W·psum)     cell_state_toInt_eq_macAfter
  cited   the signed reading (b + W·sval)          cell_computes_signed_mac
```

⛔ **AND ONE ARROW IS NEITHER — IT IS A GAP, AND IT IS NAMED RATHER THAN IMPLIED.** The
landed sign cycle (`cell_sign_cycle`) needs the **complement** `~~~w` on the adder's
addend port. `cellSeq` has three primary inputs — stream, load, carry-in — and its addend is
`andWord x w`, i.e. `0` or `w` and nothing else. **So the sign cycle is not a `cellSeq`
cycle: the composed cell as built has no complement path**
(`cell_addend_cannot_present_the_sign_operand`, below, is that fact in the kernel).
*The signed sentence therefore remains a sentence about the WORD the cell leaves, and about
`macSeq`, and this section does not upgrade it to a sentence about the composed cell.*
-/

/-! ### The step, both halves -/

/-- The composed cell's next weight-register bit `k`, with `load` low: bit `k` of `w <<< 1`.

`MacCell.cell_wsh_next` carries the net across the composition; the weight organ's own two
theorems supply the value — `wsLsb` is `false` when not loading, and next-state bit `j+1` is
state bit `j`. The `k = 0` and `k = j+1` arms genuinely differ: the first net is a GATE, the
rest are INPUT nets. -/
theorem cell_wsh_next_bit (x cin : Bool) (w acc : BitVec 32) (k : Nat) (hk : k < 32) :
    run (MacCell.cellEnv x false cin w acc) ccCore.gates (ccWshNext k)
      = (w <<< 1).getLsbD k := by
  have hnet0 : (wsCore.outs.drop 32).getD 0 0 = wsLsb := by decide +kernel
  have hnetS : ∀ j, j < 31 → (wsCore.outs.drop 32).getD (j + 1) 0 = wsW j := by
    intro j hj; revert hj; revert j; decide +kernel
  rw [MacCell.cell_wsh_next x false cin w acc k hk]
  simp only [MacCell.wEnv]
  match k, hk with
  | 0, _ =>
      have hbit0 : (w <<< 1).getLsbD 0 = false := by
        rw [BitVec.getLsbD_shiftLeft]; simp
      rw [hnet0, MacCell.wshift_next_bit_zero_when_not_loading x w, hbit0]
  | (j + 1), hk =>
      have hj : j < 31 := by omega
      have h1 : j + 1 < 32 := by omega
      have h2 : ¬ (j + 1 < 1) := by omega
      have hbit : (w <<< 1).getLsbD (j + 1) = w.getLsbD j := by
        rw [BitVec.getLsbD_shiftLeft]; simp [h1, h2]
      rw [hnetS j hj, MacCell.wshift_next_bit_succ x false w j hj, hbit]

/-- The weight half of one cycle, as a word. -/
theorem cellSeq_cycle_wsh_bits (x cin : Bool) (w acc : BitVec 32) :
    (List.range 32).map
        (fun k => run (MacCell.cellEnv x false cin w acc) ccCore.gates (ccWshNext k))
      = MacCell.bitsOf (w <<< 1) := by
  show _ = (List.range 32).map (w <<< 1).getLsbD
  exact List.map_congr_left (fun k hk => cell_wsh_next_bit x cin w acc k (List.mem_range.mp hk))

/-- The accumulator half of one cycle, as a word: `MacCell.cell_sum_bit` (the composition
theorem) composed with `macSeq_cycle_bits` (rung 2's pointwise-to-word step), at the addend
`andWord x w` the weight organ makes. -/
theorem cellSeq_cycle_acc_bits (x ld cin : Bool) (w acc : BitVec 32) :
    (List.range 32).map
        (fun k => run (MacCell.cellEnv x ld cin w acc) ccCore.gates
                    (instMap macCore ccMSig ccMOff (maSum k)))
      = MacCell.bitsOf (acc + MacCell.andWord x w + BitVec.setWidth 32 (BitVec.ofBool cin)) := by
  have h : (List.range 32).map
        (fun k => run (MacCell.cellEnv x ld cin w acc) ccCore.gates
                    (instMap macCore ccMSig ccMOff (maSum k)))
      = (List.range 32).map
          (fun k => run (MacCell.mEnv x cin w acc) macCore.gates (maSum k)) :=
    List.map_congr_left
      (fun k hk => MacCell.cell_sum_bit x ld cin w acc k (List.mem_range.mp hk))
  rw [h]
  exact macSeq_cycle_bits acc (MacCell.andWord x w) cin

/-- ⭐⭐ **ONE CYCLE OF THE COMPOSED CELL, AT THE WORD, BOTH HALVES.** With `load` low, a
cycle on stream bit `x` and carry-in `cin` from the state `w ‖ acc` puts
`acc + (x ∧ w) + cin` on the output port and on the accumulator half of the next state, and
`w <<< 1` on the weight half.

**Both halves, because `cellSeq`'s state is 64 bits and an induction advances all of it.**
The accumulator half is the composition theorem; the weight half is `cell_wsh_next`. Still
`BitVec`, still unconditional, still no `ℤ`. -/
theorem cellSeq_step_word (x cin : Bool) (w acc : BitVec 32) :
    stepSeq cellSeq (MacCell.bitsOf w ++ MacCell.bitsOf acc) [x, false, cin]
      = (MacCell.bitsOf (acc + MacCell.andWord x w + BitVec.setWidth 32 (BitVec.ofBool cin)),
         MacCell.bitsOf (w <<< 1)
           ++ MacCell.bitsOf (acc + MacCell.andWord x w
                                + BitVec.setWidth 32 (BitVec.ofBool cin))) := by
  -- ⚠️ `ccCore` stays OPAQUE: its 193 gates expand `instGates adder32` and the kernel times
  -- out. `cellSeq`'s fields are PROJECTED by `rfl`; only `outs`' SHAPE is used.
  have hcore : cellSeq.core = ccCore := rfl
  have hnout : cellSeq.nOut = 32 := rfl
  have henv : cellSeq.env [x, false, cin] (MacCell.bitsOf w ++ MacCell.bitsOf acc)
      = MacCell.cellEnv x false cin w acc := rfl
  have houts : ccCore.outs
      = ((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k)))
        ++ (((List.range 32).map ccWshNext)
            ++ ((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k)))) := by
    show (((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k)))
          ++ ((List.range 32).map ccWshNext))
          ++ ((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k))) = _
    exact List.append_assoc _ _ _
  have hlen : (MacCell.bitsOf
      (acc + MacCell.andWord x w + BitVec.setWidth 32 (BitVec.ofBool cin))).length = 32 :=
    MacCell.bitsOf_length _
  simp only [stepSeq, sem, hcore, hnout, henv, houts, List.map_append, List.map_map,
             Function.comp_def, cellSeq_cycle_acc_bits, cellSeq_cycle_wsh_bits]
  rw [List.take_left' hlen, List.drop_left' hlen]

/-! ### THE TRACE INDUCTION

The sibling of rung 3 one level up: rung 3 inducted `macSeq` over `macSeq_step_word`; this
inducts `cellSeq` over `cellSeq_step_word`. The trace length is the cycle index, so no fuel
parameter appears here either.

⚠️ **PER-INPUT SHAPE, AND THE SHAPE IS THE RULING.** `cellInputs` is **one input's**
accumulation cycles — `load` LOW throughout, so no load phase is inside it. The two organs
have opposite state discipline (`MacCell`'s dual-stream paragraph): the accumulator PERSISTS
across inputs, the weight register RE-INITIALISES per input. A second input is therefore a
SECOND `runTrace` whose initial state carries the accumulator forward and the weight back to
`W₂` — never one trace spanning both. `cellSeq_mutant_no_reload_is_not_two_inputs` runs that
mistake on the real netlist and shows it lands somewhere else. -/

/-- One input's `n` accumulation cycles: the stream bit, `load` LOW, carry-in LOW.

`load` low is what makes these accumulation cycles rather than load cycles — the guards
`MacCell.weight_state_moves_so_reload_is_required` and
`MacCell.stream_enters_only_through_the_load_gate` are the reason the distinction has to be
in the definition and not in the prose. -/
def cellInputs (x : ℕ → Bool) (n : ℕ) : List (List Bool) :=
  (List.range n).map (fun t => [x t, false, false])

theorem cellInputs_succ (x : ℕ → Bool) (n : ℕ) :
    cellInputs x (n + 1) = [x 0, false, false] :: cellInputs (fun t => x (t + 1)) n := by
  simp [cellInputs, List.range_succ_eq_map, Function.comp_def]

/-- The addend trace, peeled at the head — the form the induction consumes. -/
theorem addendTrace_succ (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (n : ℕ) :
    addendTrace Wsh x (n + 1)
      = (if x 0 then Wsh 0 else 0)
          :: addendTrace (fun t => Wsh (t + 1)) (fun t => x (t + 1)) n := by
  simp [addendTrace, List.range_succ_eq_map, Function.comp_def]

/-- One shift then `t` more is `t+1` shifts. *`BitVec.shiftLeft_shiftLeft` does not exist;
`BitVec.shiftLeft_add` is the name, as `wshift_runTrace_state` already records.* -/
theorem shiftLeft_one_shiftLeft (W : BitVec 32) (t : ℕ) : (W <<< 1) <<< t = W <<< (t + 1) := by
  rw [← BitVec.shiftLeft_add]; congr 1; omega

/-- ⭐⭐⭐ **THE TRACE INHERITANCE, PART 1 — THE INDUCTION.** Running one input's `n`
accumulation cycles from the state `W ‖ b` leaves the weight register holding `W <<< n` and
the accumulator holding `b + Σ_{t<n} (if x t then W <<< t else 0)` — i.e. exactly
`b + (addendTrace (W <<< ·) x n).sum`.

**Both halves advance, which is the whole content**: the accumulator accumulates and the
weight register shifts, and the induction needs the second to state the first. Still
`BitVec`, still unconditional — no `ℤ`, no overflow hypothesis, no `hW`. -/
theorem cellSeq_runTrace_state :
    ∀ (n : ℕ) (W b : BitVec 32) (x : ℕ → Bool),
      (runTrace cellSeq (MacCell.bitsOf W ++ MacCell.bitsOf b) (cellInputs x n)).2
        = MacCell.bitsOf (W <<< n)
            ++ MacCell.bitsOf (b + (addendTrace (fun t => W <<< t) x n).sum)
  | 0, W, b, x => by simp [cellInputs, runTrace, addendTrace]
  | n + 1, W, b, x => by
      have h0 : BitVec.setWidth 32 (BitVec.ofBool false) = (0 : BitVec 32) := by decide
      have hstep := cellSeq_step_word (x 0) false W b
      rw [h0, add_zero] at hstep
      simp only [cellInputs_succ, runTrace, hstep]
      rw [cellSeq_runTrace_state n (W <<< 1) (b + MacCell.andWord (x 0) W) (fun t => x (t + 1)),
          shiftLeft_one_shiftLeft W n,
          show (fun t : ℕ => (W <<< 1) <<< t) = (fun t : ℕ => W <<< (t + 1)) from
            funext (fun t => shiftLeft_one_shiftLeft W t),
          addendTrace_succ (fun t => W <<< t) x n, List.sum_cons, ← add_assoc]
      simp [MacCell.andWord]

/-- ⭐⭐⭐ **THE TRACE INHERITANCE, PART 2 — THE INHERITANCE ITSELF.** The composed cell's
accumulator half after one input's `n` cycles **IS** the state rung 3
(`macSeq_runTrace_state`) leaves for the bare accumulator — over the addend trace the weight
organ manufactures, rather than over addends handed to it from outside.

*That is the arrow the join was waiting for: every sentence rung 4 and the join say about
`(runTrace macSeq …).2` is a sentence about the composed cell's accumulator, because the two
are the same list. The weight half is the shifted register and is carried alongside, not
discarded.* -/
theorem cellSeq_inherits_macSeq_state (n : ℕ) (W b : BitVec 32) (x : ℕ → Bool) :
    (runTrace cellSeq (MacCell.bitsOf W ++ MacCell.bitsOf b) (cellInputs x n)).2
      = MacCell.bitsOf (W <<< n)
        ++ (runTrace macSeq (MacCell.bitsOf b)
              ((addendTrace (fun t => W <<< t) x n).map
                 (fun a => MacCell.bitsOf a ++ [false]))).2 := by
  rw [cellSeq_runTrace_state n W b x,
      macSeq_runTrace_state b (addendTrace (fun t => W <<< t) x n)]

/-! ### THE JOIN, REACHED — cited, not re-proved

Nothing below re-derives an arithmetic step. The first conjunct of each is this section's
induction; the second is the landed join, applied at `Wsh := (W <<< ·)`. -/

/-- ⭐⭐ **THE COMPOSED CELL REACHES `macAfter`.** For one input, under the prefix
no-overflow predicate and the weight schedule `hW`: the cell's state is
`W <<< n ‖ b + Σ addends` (unconditional), and that accumulator word's `ℤ` value is
`Mac.macAfter W b.toInt x (n+1)` — the accumulation **before** the sign cycle, which
`MacInduction` reads as `b + W · psum`.

**That is the claim, at exactly that size.** The `hW` hypothesis is now about the register
this cell actually shifts (`Wreg <<< t`), which is what `MacCell.shiftSafe` /
`MacCell.hW_is_shiftSafe` price; it is still a hypothesis and it is still named. -/
theorem cellSeq_state_toInt_eq_macAfter
    (W : ℤ) (Wreg b : BitVec 32) (x : ℕ → Bool) (n : ℕ)
    (hW : ∀ t, t < n → ((Wreg <<< t) : BitVec 32).toInt = W * 2 ^ t)
    (hno : noOverflowFrom b (addendTrace (fun t => Wreg <<< t) x n) = true) :
    (runTrace cellSeq (MacCell.bitsOf Wreg ++ MacCell.bitsOf b) (cellInputs x n)).2
        = MacCell.bitsOf (Wreg <<< n)
          ++ MacCell.bitsOf (b + (addendTrace (fun t => Wreg <<< t) x n).sum)
  ∧ (b + (addendTrace (fun t => Wreg <<< t) x n).sum).toInt
      = Mac.macAfter W b.toInt x (n + 1) :=
  ⟨cellSeq_runTrace_state n Wreg b x,
   (cell_state_toInt_eq_macAfter W b (fun t => Wreg <<< t) x n hW hno).2⟩

/-- ⭐⭐ **AND THE SIGNED READING OF THE WORD IT LEAVES.** Under the join's three
hypotheses — `hW`/`hWm` (the schedule), the prefix no-overflow predicate, and
`¬ ssubOverflow` — the composed cell's state after one input's `m` cycles is
`Wreg <<< m ‖ b + Σ addends`, and **that word, minus the sign operand**, reads in `ℤ` as
`b.toInt + W · sval x (m+1)`: the signed dot product.

⛔ **THE SUBTRACTION IS NOT A CELL CYCLE, AND THIS THEOREM DOES NOT SAY IT IS.** The first
conjunct is about `runTrace cellSeq`; the second is `cell_computes_signed_mac`, an arithmetic
fact about the word — and `cell_sign_cycle`, which performs that subtraction, runs on
`macSeq` with the complement `~~~w` on its addend port. **`cellSeq` cannot present that
operand** (`cell_addend_cannot_present_the_sign_operand`). *So what the composed cell is
certified to do end to end is the ACCUMULATION; the sign step is certified on the
accumulator organ and the composed cell has no path to it.* -/
theorem cellSeq_state_word_signed_reading
    (W : ℤ) (Wreg b : BitVec 32) (x : ℕ → Bool) (m : ℕ)
    (hW : ∀ t, t < m → ((Wreg <<< t) : BitVec 32).toInt = W * 2 ^ t)
    (hWm : ((Wreg <<< m) : BitVec 32).toInt = W * 2 ^ m)
    (hno : noOverflowFrom b (addendTrace (fun t => Wreg <<< t) x m) = true)
    (hsign : ¬ BitVec.ssubOverflow (b + (addendTrace (fun t => Wreg <<< t) x m).sum)
                (signOperand (fun t => Wreg <<< t) x m)) :
    (runTrace cellSeq (MacCell.bitsOf Wreg ++ MacCell.bitsOf b) (cellInputs x m)).2
        = MacCell.bitsOf (Wreg <<< m)
          ++ MacCell.bitsOf (b + (addendTrace (fun t => Wreg <<< t) x m).sum)
  ∧ ((b + (addendTrace (fun t => Wreg <<< t) x m).sum)
        - signOperand (fun t => Wreg <<< t) x m).toInt
      = b.toInt + W * Mac.sval x (m + 1) :=
  ⟨cellSeq_runTrace_state m Wreg b x,
   cell_computes_signed_mac W b (fun t => Wreg <<< t) x m hW hWm hno hsign⟩

/-- ⛔⛔ **THE GAP, IN THE KERNEL RATHER THAN IN PROSE.** The composed cell's addend is
`andWord x w` — `0` or the weight register, and nothing else. The landed sign cycle needs
`~~~(signOperand …)`. At weight register `1`, **neither arm of the AND row equals either arm
of the complemented sign operand.** *So `cell_full_mac`'s trace is not a `cellSeq` trace, and
no amount of quantifying over initial states makes it one: the complement path is a wire that
does not exist.* -/
theorem cell_addend_cannot_present_the_sign_operand (x xm : Bool) :
    MacCell.andWord x (1 : BitVec 32)
      ≠ ~~~(signOperand (fun _ => (1 : BitVec 32)) (fun _ => xm) 0) := by
  cases x <;> cases xm <;> decide

/-! ### CONTROLS — RUN, NOT CITED, AND RUN ON THE REAL NETLIST

*The arithmetic mutants of rung 3 established that `+` notices its arguments. These are one
level lower: `decide +kernel` evaluates the actual 193-gate `ccCore` for three to eight
cycles, so a mis-stated induction that happened to be self-consistent would still be caught.
Cost measured, not guessed: the whole block is seconds.* -/

/-- **POSITIVE CONTROL — THE THEOREM DESCRIBES THE REAL MACHINE.** Weight `3`, accumulator
`0`, stream `1,0,1`: the cell itself, run in the kernel, lands on weight `3 <<< 3 = 24` and
accumulator `3 + 0 + 12 = 15` — which is what `cellSeq_runTrace_state` predicts.
**The stream is deliberately NOT all-ones**: a cell that ignored `x` and added every cycle
would pass an all-ones test. -/
theorem cellSeq_behavioural_witness :
    (runTrace cellSeq (MacCell.bitsOf 3 ++ MacCell.bitsOf 0)
        (cellInputs (fun t => !(t == 1)) 3)).2
      = MacCell.bitsOf 24 ++ MacCell.bitsOf 15 := by
  decide +kernel

/-- ⛔ **MUTANT — A DROPPED INPUT CHANGES THE STATE.** Two cycles of the same stream instead
of three: the induction is not silently ignoring its trace. On the netlist. -/
theorem cellSeq_mutant_dropped_input :
    (runTrace cellSeq (MacCell.bitsOf 3 ++ MacCell.bitsOf 0)
        (cellInputs (fun t => !(t == 1)) 2)).2
      ≠ (runTrace cellSeq (MacCell.bitsOf 3 ++ MacCell.bitsOf 0)
            (cellInputs (fun t => !(t == 1)) 3)).2 := by
  decide +kernel

/-- ⛔ **MUTANT — THE STREAM BIT IS LOAD-BEARING.** Flipping cycle 1's bit from `0` to `1`
moves the state, so the AND row is doing work and the addend is not the weight unconditionally. -/
theorem cellSeq_mutant_stream_bit_matters :
    (runTrace cellSeq (MacCell.bitsOf 3 ++ MacCell.bitsOf 0)
        (cellInputs (fun t => !(t == 1)) 3)).2
      ≠ (runTrace cellSeq (MacCell.bitsOf 3 ++ MacCell.bitsOf 0)
            (cellInputs (fun _ => true) 3)).2 := by
  decide +kernel

/-- ⛔⛔ **MUTANT — THE STATE DISCIPLINE. ONE TRACE SPANNING TWO INPUTS IS NOT TWO INPUTS.**

Weight `1`, four cycles per input, stream all-ones. Read the three conjuncts as one sentence:

```
   input 1 alone, fresh weight        (1 ‖ 0)   -4 cycles->   (16 ‖ 15)
   input 2, weight RELOADED to 1,
     accumulator carried forward      (1 ‖ 15)  -4 cycles->   (16 ‖ 30)   <- CORRECT
   one trace, eight cycles, no reload (1 ‖ 0)   -8 cycles->   NOT (256 ‖ 30)
```

**The third conjunct is the refutation**: without the reload the weight register keeps
climbing, so the second input's bits are weighted `2⁴…2⁷` instead of `2⁰…2³` and the
accumulator lands on `255`, not `30`. *No wire is wrong in that mistake — only which state
crosses which trace boundary, which is exactly what `MacCell`'s dual-stream paragraph warns
about and why `cellInputs` is per-input.* -/
theorem cellSeq_mutant_no_reload_is_not_two_inputs :
    (runTrace cellSeq (MacCell.bitsOf 1 ++ MacCell.bitsOf 0) (cellInputs (fun _ => true) 4)).2
      = MacCell.bitsOf 16 ++ MacCell.bitsOf 15
  ∧ (runTrace cellSeq (MacCell.bitsOf 1 ++ MacCell.bitsOf 15) (cellInputs (fun _ => true) 4)).2
      = MacCell.bitsOf 16 ++ MacCell.bitsOf 30
  ∧ (runTrace cellSeq (MacCell.bitsOf 1 ++ MacCell.bitsOf 0) (cellInputs (fun _ => true) 8)).2
      ≠ MacCell.bitsOf 256 ++ MacCell.bitsOf 30 :=
  ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-! ## ② THE SIGNED TRACE INHERITANCE — the subtraction becomes a CELL CYCLE

⭐ **This section is the answer to `cell_addend_cannot_present_the_sign_operand` above.** That
theorem is kernel-proved and stays true: the 193-gate `cellSeq` has no complement path, so
`cellSeq_state_word_signed_reading`'s second conjunct had to be arithmetic ABOUT the word
rather than a cycle OF the machine — true and inapplicable, the F5 shape.

`MacCell.scellSeq` (compiler's `7364548`, 225 gates) carries `scSign`, and `scSign` feeds BOTH
the XOR bank and `macCore`'s carry-in (`MacCell.sc_carry_is_the_sign`). So the sign step is
now a cycle of one machine, and the join below is the SAME arithmetic theorem
(`cell_computes_signed_mac`) applied to a trace `scellSeq` can actually present.

⚠️ **WHAT THIS DOES NOT CLOSE.** The trace carries `sign` high at exactly cycle `m`;
`scellSeq` permits it at ANY cycle, so the artifact is strictly MORE GENERAL than the
theorem. The supplier of "sign high only at cycle `m`" is a sequencer, and no sequencer is
emitted. **F5 clears on the DATAPATH here and keeps binding on the CONTROL.** -/

/-- The accumulator's next word, both sign arms in one object. -/
def scAccNext (s x : Bool) (w acc : BitVec 32) : BitVec 32 :=
  if s then acc - andWord x w else acc + andWord x w

/-- One cycle's accumulator bit, either sign — compiler's two arms joined. -/
theorem sc_acc_bit (x ld s : Bool) (w acc : BitVec 32) (k : Nat) (hk : k < 32) :
    run (cellEnv x ld s w acc) scCore.gates (instMap macCore scMSig scMOff (maSum k))
      = (scAccNext s x w acc).getLsbD k := by
  cases s with
  | false => simpa [scAccNext] using sc_accumulate_cycle_unchanged x ld w acc k hk
  | true  => simpa [scAccNext] using sc_sign_cycle_subtracts x ld w acc k hk

/-- The accumulator half of one cycle, as a word. -/
theorem scellSeq_cycle_acc_bits (x ld s : Bool) (w acc : BitVec 32) :
    (List.range 32).map
        (fun k => run (cellEnv x ld s w acc) scCore.gates
                    (instMap macCore scMSig scMOff (maSum k)))
      = MacCell.bitsOf (scAccNext s x w acc) := by
  show _ = (List.range 32).map (scAccNext s x w acc).getLsbD
  exact List.map_congr_left (fun k hk => sc_acc_bit x ld s w acc k (List.mem_range.mp hk))

/-- The weight register's next bit on the SIGNED netlist. `sc_wsh_next` lands on the same
right-hand side as the unsigned `cell_wsh_next`, so this mirrors `cell_wsh_next_bit`. -/
theorem sc_wsh_next_bit (x s : Bool) (w acc : BitVec 32) (k : Nat) (hk : k < 32) :
    run (cellEnv x false s w acc) scCore.gates (ccWshNext k) = (w <<< 1).getLsbD k := by
  have hnet0 : (wsCore.outs.drop 32).getD 0 0 = wsLsb := by decide +kernel
  have hnetS : ∀ j, j < 31 → (wsCore.outs.drop 32).getD (j + 1) 0 = wsW j := by
    intro j hj; revert hj; revert j; decide +kernel
  rw [sc_wsh_next x false s w acc k hk]
  simp only [wEnv]
  match k, hk with
  | 0, _ =>
      have hbit0 : (w <<< 1).getLsbD 0 = false := by
        rw [BitVec.getLsbD_shiftLeft]; simp
      rw [hnet0, wshift_next_bit_zero_when_not_loading x w, hbit0]
  | (j + 1), hk =>
      have hj : j < 31 := by omega
      have h1 : j + 1 < 32 := by omega
      have h2 : ¬ (j + 1 < 1) := by omega
      have hbit : (w <<< 1).getLsbD (j + 1) = w.getLsbD j := by
        rw [BitVec.getLsbD_shiftLeft]; simp [h1, h2]
      rw [hnetS j hj, wshift_next_bit_succ x false w j hj, hbit]

/-- The weight half of one cycle, as a word. -/
theorem scellSeq_cycle_wsh_bits (x s : Bool) (w acc : BitVec 32) :
    (List.range 32).map
        (fun k => run (cellEnv x false s w acc) scCore.gates (ccWshNext k))
      = MacCell.bitsOf (w <<< 1) := by
  show _ = (List.range 32).map (w <<< 1).getLsbD
  exact List.map_congr_left (fun k hk => sc_wsh_next_bit x s w acc k (List.mem_range.mp hk))

/-- ⭐⭐ **ONE CYCLE OF THE SIGNED COMPOSED CELL, AT THE WORD, BOTH HALVES, EITHER SIGN.**
This is the keystone ② rests on: at `s = false` it is the unsigned cell's step exactly, and
at `s = true` the accumulator SUBTRACTS — on the netlist, not in the arithmetic. -/
theorem scellSeq_step_word (x s : Bool) (w acc : BitVec 32) :
    stepSeq scellSeq (MacCell.bitsOf w ++ MacCell.bitsOf acc) [x, false, s]
      = (MacCell.bitsOf (scAccNext s x w acc),
         MacCell.bitsOf (w <<< 1) ++ MacCell.bitsOf (scAccNext s x w acc)) := by
  -- ⚠️ `scCore` stays OPAQUE: 225 gates expand `instGates adder32` and the kernel times out.
  have hcore : scellSeq.core = scCore := rfl
  have hnout : scellSeq.nOut = 32 := rfl
  have henv : scellSeq.env [x, false, s] (MacCell.bitsOf w ++ MacCell.bitsOf acc)
      = cellEnv x false s w acc := rfl
  have houts : scCore.outs
      = ((List.range 32).map (fun k => instMap macCore scMSig scMOff (maSum k)))
        ++ (((List.range 32).map ccWshNext)
            ++ ((List.range 32).map (fun k => instMap macCore scMSig scMOff (maSum k)))) := by
    show (((List.range 32).map (fun k => instMap macCore scMSig scMOff (maSum k)))
          ++ ((List.range 32).map ccWshNext))
          ++ ((List.range 32).map (fun k => instMap macCore scMSig scMOff (maSum k))) = _
    exact List.append_assoc _ _ _
  have hlen : (MacCell.bitsOf (scAccNext s x w acc)).length = 32 := MacCell.bitsOf_length _
  simp only [stepSeq, sem, hcore, hnout, henv, houts, List.map_append, List.map_map,
             Function.comp_def, scellSeq_cycle_acc_bits, scellSeq_cycle_wsh_bits]
  rw [List.take_left' hlen, List.drop_left' hlen]

/-! ### THE TRACE INDUCTION — accumulation cycles on the SIGNED cell

`cellInputs` is REUSED, not restated: its third entry is `false`, which on the unsigned cell
was carry-in-low and on the signed cell is sign-low. Same list, and reusing it is what makes
"the accumulation story is preserved" literal rather than argued. -/

/-- ⭐⭐⭐ **THE SIGNED CELL'S ACCUMULATION TRACE.** Identical conclusion to
`cellSeq_runTrace_state`, on the 225-gate netlist. Unconditional: no `ℤ`, no overflow
hypothesis, no `hW`. -/
theorem scellSeq_runTrace_state :
    ∀ (n : ℕ) (W b : BitVec 32) (x : ℕ → Bool),
      (runTrace scellSeq (MacCell.bitsOf W ++ MacCell.bitsOf b) (cellInputs x n)).2
        = MacCell.bitsOf (W <<< n)
            ++ MacCell.bitsOf (b + (addendTrace (fun t => W <<< t) x n).sum)
  | 0, W, b, x => by simp [cellInputs, runTrace, addendTrace]
  | n + 1, W, b, x => by
      have hstep := scellSeq_step_word (x 0) false W b
      simp only [scAccNext, if_neg (by simp : ¬ (false = true))] at hstep
      simp only [cellInputs_succ, runTrace, hstep]
      rw [scellSeq_runTrace_state n (W <<< 1) (b + MacCell.andWord (x 0) W) (fun t => x (t + 1)),
          shiftLeft_one_shiftLeft W n,
          show (fun t : ℕ => (W <<< 1) <<< t) = (fun t : ℕ => W <<< (t + 1)) from
            funext (fun t => shiftLeft_one_shiftLeft W t),
          addendTrace_succ (fun t => W <<< t) x n, List.sum_cons, ← add_assoc]
      simp [MacCell.andWord]

/-- The sign operand IS what the AND row presents at cycle `m`. Definitional, and it is the
hinge: the unsigned cell's kernel-proved gap
(`cell_addend_cannot_present_the_sign_operand`) was that no port could carry the COMPLEMENT
of this word. `scSign` carries it, so this equation is now usable. -/
theorem andWord_eq_signOperand (W : BitVec 32) (x : ℕ → Bool) (m : ℕ) :
    MacCell.andWord (x m) (W <<< m) = signOperand (fun t => W <<< t) x m := rfl

/-- ⭐⭐⭐ **② — THE SIGNED TRACE, AND THE SUBTRACTION IS A CELL CYCLE.** `m` accumulation
cycles then ONE sign cycle, all on `scellSeq`. The state's accumulator half is
`(b + Σ addends) − signOperand`, and the weight register has shifted `m+1` times.

⭐ **Compare `cellSeq_state_word_signed_reading`, whose second conjunct had to be arithmetic
because the unsigned cell had no complement path. Here the subtraction is performed BY THE
NETLIST — `sc_sign_cycle_subtracts` at `scSign = 1`.** -/
theorem scellSeq_signed_runTrace_state (W b : BitVec 32) (x : ℕ → Bool) (m : ℕ) :
    (runTrace scellSeq (MacCell.bitsOf W ++ MacCell.bitsOf b)
        (cellInputs x m ++ [[x m, false, true]])).2
      = MacCell.bitsOf (W <<< (m + 1))
        ++ MacCell.bitsOf ((b + (addendTrace (fun t => W <<< t) x m).sum)
                            - signOperand (fun t => W <<< t) x m) := by
  rw [runTrace_append, scellSeq_runTrace_state m W b x]
  have hstep := scellSeq_step_word (x m) true (W <<< m)
      (b + (addendTrace (fun t => W <<< t) x m).sum)
  simp only [runTrace, hstep, scAccNext, if_true, andWord_eq_signOperand,
             BitVec.shiftLeft_add]

/-- ⭐⭐⭐⭐ **② COMPLETE — THE COMPOSED SIGNED CELL COMPUTES THE SIGNED MAC.** Under the
join's four hypotheses, after `m` accumulation cycles and one sign cycle the signed cell's
accumulator reads in `ℤ` as `b + W · sval x (m+1)`.

**Every step is now a cycle of one machine.** `cell_computes_signed_mac` is applied
UNCHANGED — it never needed restatement, because it was always stated over the trace and the
trace is now one `scellSeq` can present.

⚠️ **STILL A HYPOTHESIS, AND F5 STILL BINDS ON IT: the trace carries `sign` high at exactly
cycle `m`. `scellSeq` permits it at any cycle — the artifact is MORE GENERAL than this
theorem. The supplier of "sign high only at cycle m" is a sequencer, and no sequencer is
emitted. F5 clears on the DATAPATH here; it keeps binding on the CONTROL.** -/
theorem scellSeq_computes_signed_mac
    (W : ℤ) (Wreg b : BitVec 32) (x : ℕ → Bool) (m : ℕ)
    (hW : ∀ t, t < m → ((Wreg <<< t) : BitVec 32).toInt = W * 2 ^ t)
    (hWm : ((Wreg <<< m) : BitVec 32).toInt = W * 2 ^ m)
    (hno : noOverflowFrom b (addendTrace (fun t => Wreg <<< t) x m) = true)
    (hsign : ¬ BitVec.ssubOverflow (b + (addendTrace (fun t => Wreg <<< t) x m).sum)
                (signOperand (fun t => Wreg <<< t) x m)) :
    (runTrace scellSeq (MacCell.bitsOf Wreg ++ MacCell.bitsOf b)
        (cellInputs x m ++ [[x m, false, true]])).2
        = MacCell.bitsOf (Wreg <<< (m + 1))
          ++ MacCell.bitsOf ((b + (addendTrace (fun t => Wreg <<< t) x m).sum)
                              - signOperand (fun t => Wreg <<< t) x m)
  ∧ ((b + (addendTrace (fun t => Wreg <<< t) x m).sum)
        - signOperand (fun t => Wreg <<< t) x m).toInt
      = b.toInt + W * Mac.sval x (m + 1) :=
  ⟨scellSeq_signed_runTrace_state Wreg b x m,
   cell_computes_signed_mac W b (fun t => Wreg <<< t) x m hW hWm hno hsign⟩

/-! ### The axiom audit for THIS SECTION

⚠️ **AND IT COVERS THIS SECTION ONLY.** `MacBridge` carried no `#audit_axioms` block before
this one, and adding a partial block must not read as a whole-file certificate:
`docs/hdl-tools/audit_completeness.py` at `3c07566` reports **204 unaudited theorems**
corpus-wide, of which **32 are this file's earlier declarations**. *`Sem.lean`'s note that
"The real number is zero" is STALE.* Those 32 are somebody's item; they are not silently
adopted here. -/

#audit_axioms cell_wsh_next_bit
#audit_axioms cellSeq_cycle_wsh_bits
#audit_axioms cellSeq_cycle_acc_bits
#audit_axioms cellSeq_step_word
#audit_axioms cellInputs_succ
#audit_axioms addendTrace_succ
#audit_axioms shiftLeft_one_shiftLeft
#audit_axioms cellSeq_runTrace_state
#audit_axioms cellSeq_inherits_macSeq_state
#audit_axioms cellSeq_state_toInt_eq_macAfter
#audit_axioms cellSeq_state_word_signed_reading
#audit_axioms cell_addend_cannot_present_the_sign_operand
#audit_axioms cellSeq_behavioural_witness
#audit_axioms cellSeq_mutant_dropped_input
#audit_axioms cellSeq_mutant_stream_bit_matters
#audit_axioms cellSeq_mutant_no_reload_is_not_two_inputs

#audit_axioms sc_acc_bit
#audit_axioms scellSeq_cycle_acc_bits
#audit_axioms sc_wsh_next_bit
#audit_axioms scellSeq_cycle_wsh_bits
#audit_axioms scellSeq_step_word
#audit_axioms scellSeq_runTrace_state
#audit_axioms andWord_eq_signOperand
#audit_axioms scellSeq_signed_runTrace_state
#audit_axioms scellSeq_computes_signed_mac


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.MacBridge.addendTrace_toInt_sum SaltWorks.HDL.MacBridge.cell_carry_cycle
#audit_axioms SaltWorks.HDL.MacBridge.cell_computes_signed_mac SaltWorks.HDL.MacBridge.cell_full_mac
#audit_axioms SaltWorks.HDL.MacBridge.cell_sign_cycle SaltWorks.HDL.MacBridge.cell_sign_cycle_witness
#audit_axioms SaltWorks.HDL.MacBridge.cell_state_toInt_eq_macAfter SaltWorks.HDL.MacBridge.cell_sum_bit
#audit_axioms SaltWorks.HDL.MacBridge.cell_sum_bit_witness SaltWorks.HDL.MacBridge.demoTrace_sum_is_demoBound
#audit_axioms SaltWorks.HDL.MacBridge.demo_noOverflowFrom SaltWorks.HDL.MacBridge.demo_reading
#audit_axioms SaltWorks.HDL.MacBridge.macSeq_cycle_bits SaltWorks.HDL.MacBridge.macSeq_runTrace_state
#audit_axioms SaltWorks.HDL.MacBridge.macSeq_step_word SaltWorks.HDL.MacBridge.mutant_4a_dropped_hypothesis
#audit_axioms SaltWorks.HDL.MacBridge.mutant_carry_high_differs SaltWorks.HDL.MacBridge.mutant_false_bound_decides_false
#audit_axioms SaltWorks.HDL.MacBridge.mutant_false_bound_gate_is_false SaltWorks.HDL.MacBridge.mutant_sign_cycle_without_carry_is_off_by_one
#audit_axioms SaltWorks.HDL.MacBridge.mutant_total_only_conclusion_is_false SaltWorks.HDL.MacBridge.mutant_total_only_hypothesis_holds
#audit_axioms SaltWorks.HDL.MacBridge.mutant_witness_overflows SaltWorks.HDL.MacBridge.not_saddOverflow_of_abs_le
#audit_axioms SaltWorks.HDL.MacBridge.not_saddOverflow_of_demoBound SaltWorks.HDL.MacBridge.runTrace_mutant_dropped_addend
#audit_axioms SaltWorks.HDL.MacBridge.runTrace_witness SaltWorks.HDL.MacBridge.step_toInt_of_not_saddOverflow
#audit_axioms SaltWorks.HDL.MacBridge.sum_toInt_of_noOverflowFrom SaltWorks.HDL.MacBridge.wshift_runTrace_state
#audit_axioms SaltWorks.HDL.MacBridge.wshift_step_word
end SaltWorks.HDL.MacBridge
