import Mathlib
namespace ProbeFacade
def line (m s d : ℕ) : ℕ := 2 ^ m * (d / 2 ^ m) + s % 2 ^ m

/-- THE FACADE: the div/mod carrier *is* "high bits from d, low bits from s",
bit by bit — the recognizable self-routing statement. -/
theorem testBit_line (m s d j : ℕ) :
    (line m s d).testBit j = if j < m then s.testBit j else d.testBit j := by
  rw [line, Nat.testBit_two_pow_mul_add _ (Nat.mod_lt _ (Nat.two_pow_pos m))]
  by_cases h : j < m
  · simp [h, Nat.testBit_mod_two_pow]
  · simp [h, Nat.testBit_div_two_pow, Nat.sub_add_cancel (Nat.not_lt.1 h)]

/-- And one stage flips exactly bit `m`. -/
theorem testBit_step (m s d j : ℕ) :
    (line m s d).testBit j =
      if j = m then d.testBit m else (line (m+1) s d).testBit j := by
  rw [testBit_line, testBit_line]
  rcases lt_trichotomy j m with h | h | h
  · simp [h, Nat.ne_of_lt h, Nat.lt_succ_of_lt h]
  · subst h; simp
  · simp [Nat.not_lt.2 h.le, Nat.ne_of_gt h, Nat.not_lt.2 h]
end ProbeFacade
