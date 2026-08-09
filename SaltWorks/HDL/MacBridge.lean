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

⇒ ***What rung 4 proves is that the fed sequence MEANS `b + W · sval` under the
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
`MacCell.stream_bit_never_enters_the_weight_register` (there is no port to reload
through). **A multi-input statement must therefore be per-input traces, never one
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

**That is the claim: the sequence the cell is fed MEANS `b + W · sval`, under the
no-overflow hypothesis.** Rungs 1–3 supply that the cell adds what it is fed; this
supplies what the feeding means. -/
theorem cell_state_toInt_eq_macAfter
    (W : ℤ) (b : BitVec 32) (Wsh : ℕ → BitVec 32) (x : ℕ → Bool) (n : ℕ)
    (hW : ∀ t, t < n → (Wsh t).toInt = W * 2 ^ t)
    (hno : noOverflowFrom b (addendTrace Wsh x n) = true) :
    (runTrace macSeq (MacCell.bitsOf b) ((addendTrace Wsh x n).map MacCell.bitsOf)).2
        = MacCell.bitsOf (b + (addendTrace Wsh x n).sum)
  ∧ (b + (addendTrace Wsh x n).sum).toInt = Mac.macAfter W b.toInt x (n + 1) := by
  refine ⟨macSeq_runTrace_state b (addendTrace Wsh x n), ?_⟩
  rw [sum_toInt_of_noOverflowFrom (addendTrace Wsh x n) b hno,
      addendTrace_toInt_sum W Wsh x n hW, Mac.mac_partial]

end SaltWorks.HDL.MacBridge
