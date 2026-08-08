import SaltWorks.Banyan.SelfRouting

/-! # The bit-routing facade — over the REAL constant

Restated 2026-08-08 over `SaltWorks.Banyan.line` itself. The original
probe stated these about a byte-identical duplicate `ProbeFacade.line`
(the refuter addendum §0 finding: a bridge about a copy connects
nothing). The duplicate is deleted; these are the same proofs, now
about the constant the corpus routes with. `testBit_step` is the
frame-order resonance's Lean half: the transition `line (m+1) → line m`
consumes exactly destination bit `m`, so the first stage consumes the
MSB — the 1988 frame order and the proof index agree because a delta
network must resolve the coarsest partition first. -/

namespace SaltWorks.Banyan

theorem testBit_line (m s d j : ℕ) :
    (line m s d).testBit j = if j < m then s.testBit j else d.testBit j := by
  rw [line, Nat.testBit_two_pow_mul_add _ (Nat.mod_lt _ (Nat.two_pow_pos m))]
  by_cases h : j < m
  · simp [h, Nat.testBit_mod_two_pow]
  · simp [h, Nat.testBit_div_two_pow, Nat.sub_add_cancel (Nat.not_lt.1 h)]

/-- Stage transition: moving from `line (m+1)` to `line m` consumes exactly
destination bit `m`; every other bit is inherited. -/
theorem testBit_step (m s d j : ℕ) :
    (line m s d).testBit j =
      if j = m then d.testBit m else (line (m+1) s d).testBit j := by
  rw [testBit_line, testBit_line]
  rcases lt_trichotomy j m with h | rfl | h
  · simp [Nat.ne_of_lt h, h, Nat.lt_succ_of_lt h]
  · simp
  · have h1 : ¬ j < m := by omega
    have h2 : ¬ j < m + 1 := by omega
    have h3 : j ≠ m := by omega
    simp [h1, h2, h3]

end SaltWorks.Banyan
