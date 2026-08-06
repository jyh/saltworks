/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib
import SaltWorks.Tactic.AuditAxioms
import SaltWorks.Silicon.Equiv.BitSliced

/-!
# The input columns — discharging `reflect`'s last hypothesis

`SaltWorks.Silicon.reflect` is deliberately ignorant of how input columns are
built: it assumes only `(cols i).testBit j = ins i`. This file builds them and
proves that property, so the bit-sliced equivalence machinery stands on nothing
unproved.

## What a column is

With `n` primary input bits there are `2 ^ n` configurations, so a slice is
`2 ^ n` bits wide. The column of input `i` is the number whose bit `j` says what
input `i` is under configuration `j` — that is, bit `i` of `j`.

## Why it is defined by recursion on `n` rather than in closed form

The obvious construction is a closed form (a periodic unit pattern times a
base-`2^p` repunit). It computes fine, but its correctness proof is unpleasant.
Doubling the width instead gives a definition that is *both* cheap to evaluate —
`n` big multiplications, not `2 ^ n` steps — and provable by a short induction:

* the low half of a `2^(n+1)`-wide column is the `2^n`-wide column, because
  adding `2 ^ n` to a configuration index only touches bit `n`;
* the top input bit `n` is the column that is zero on the low half and all ones
  on the high half.
-/

namespace SaltWorks.Silicon

open Salt.Tactic

/-- `col n i` — the truth-table column of input bit `i`, for `n` input bits
(slice width `2 ^ n` bits). Written in the `2 ^ w * a + b` shape that
`Nat.testBit_two_pow_mul_add` consumes. -/
def col : Nat → Nat → Nat
  | 0,     _ => 0
  | n + 1, i =>
      if i = n then 2 ^ 2 ^ n * (2 ^ 2 ^ n - 1)
      else 2 ^ 2 ^ n * col n i + col n i

/-- Widths double: a slice for `n+1` inputs is two `n`-input slices side by side. -/
theorem two_pow_width_succ (n : Nat) : 2 ^ 2 ^ (n + 1) = 2 ^ 2 ^ n * 2 ^ 2 ^ n := by
  rw [pow_succ, Nat.mul_two, pow_add]

/-- The high half of a full-width slice, stated additively so `omega` can use it. -/
private theorem ones_add (M : Nat) (hM : 0 < M) : M * (M - 1) + M = M * M := by
  calc M * (M - 1) + M = M * (M - 1) + M * 1 := by ring
    _ = M * (M - 1 + 1) := by ring
    _ = M * M := by rw [Nat.sub_add_cancel hM]

/-- A column fits in its slice. Needed so the two halves do not overlap. -/
theorem col_lt : ∀ n i, col n i < 2 ^ 2 ^ n := by
  intro n
  induction n with
  | zero => intro i; simp [col]
  | succ n ih =>
    intro i
    have hM : 0 < 2 ^ 2 ^ n := Nat.two_pow_pos _
    have key := ones_add (2 ^ 2 ^ n) hM
    rw [two_pow_width_succ]
    by_cases h : i = n
    · simp only [col, if_pos h]; omega
    · simp only [col, if_neg h]
      have hc := ih i
      have h1 : 2 ^ 2 ^ n * col n i ≤ 2 ^ 2 ^ n * (2 ^ 2 ^ n - 1) :=
        Nat.mul_le_mul_left _ (by omega)
      omega

/-- **The defining property.** Bit `j` of input `i`'s column is bit `i` of `j`. -/
theorem col_testBit : ∀ n i j, i < n → j < 2 ^ n → (col n i).testBit j = j.testBit i := by
  intro n
  induction n with
  | zero => intro i j hi _; omega
  | succ n ih =>
    intro i j hi hj
    rw [pow_succ, Nat.mul_two] at hj          -- j < 2 ^ n + 2 ^ n
    by_cases h : i = n
    · -- the top input bit: zero on the low half, all ones on the high half
      simp only [col, if_pos h]
      rw [← Nat.add_zero (2 ^ 2 ^ n * (2 ^ 2 ^ n - 1)),
          Nat.testBit_two_pow_mul_add _ (Nat.two_pow_pos (2 ^ n)), h]
      by_cases hlo : j < 2 ^ n
      · simp [hlo, Nat.testBit_lt_two_pow hlo]
      · have hhi : j - 2 ^ n < 2 ^ n := by omega
        have hdiv : j / 2 ^ n = 1 :=
          Nat.div_eq_of_lt_le (by omega) (by omega)
        -- mask lemma on the left, div/mod on the right: both are `true`
        rw [if_neg hlo, Nat.testBit_two_pow_sub_one,
            Nat.testBit_eq_decide_div_mod_eq, hdiv]
        simp [hhi]
    · -- a lower input bit: the same pattern, repeated in both halves
      have hi' : i < n := by omega
      simp only [col, if_neg h]
      rw [Nat.testBit_two_pow_mul_add _ (col_lt n i)]
      by_cases hlo : j < 2 ^ n
      · simpa [hlo] using ih i j hi' hlo
      · have hhi : j - 2 ^ n < 2 ^ n := by omega
        have hmod : j % 2 ^ n = j - 2 ^ n := by
          rw [Nat.mod_eq_sub_mod (Nat.le_of_not_lt hlo), Nat.mod_eq_of_lt hhi]
        have hbit := Nat.testBit_mod_two_pow j n i
        rw [hmod, decide_eq_true hi', Bool.true_and] at hbit
        simp only [if_neg hlo]
        rw [ih i (j - 2 ^ n) hi' hhi, hbit]

/-- The hypothesis `reflect` and `eq_of_sliced_eq` ask for, discharged. -/
theorem col_agrees (n j : Nat) (hj : j < 2 ^ n) :
    ∀ i, i < n → (col n i).testBit j = j.testBit i :=
  fun i hi => col_testBit n i j hi hj

#audit_axioms two_pow_width_succ col_lt col_testBit col_agrees

end SaltWorks.Silicon
