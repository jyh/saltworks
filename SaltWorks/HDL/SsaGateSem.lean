/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Per-gate semantics for an arbitrary SSA gate list

`run_of_flat_gates` (`Compose.lean`) is *named for what it requires*: `flatBelow`, every
fanin below the block's base. That rules out every mux-shaped block in this corpus — an
`or` over two `and`s reads its own predecessors — and `RegNext`'s 1,024 muxes are exactly
that shape. `run_snoc_frame` takes the non-flat step but wants the list handed to it
already split as `(pre ++ [g]) ++ suf`.

**This file does the splitting once, positionally, so any organ gets per-gate semantics
from its `ssa` certificate alone.**

⚠️ **WHY THIS FILE EXISTS AT ALL — a measurement, not a preference.** Every 32×32 fact in
`RegNext.lean` is a SAMPLE (`rnBit 0 true false` and two siblings); the exhaustive
certificates stop at 4×4 and 8×8. The generator is visibly uniform in `r` and `k`, and
that uniformity is asserted in a docstring and nowhere in the kernel. `run_ssa_gate` is
the first tool with which the uniform statement can be *proved* rather than sampled.
-/
import SaltWorks.HDL.Compose

namespace SaltWorks.HDL

/-- Dropping the head of an SSA list advances the base by one. -/
theorem ssaFrom_tail1 (l : List Gate) (b : Nat) (h : ssaFrom b l = true) :
    ssaFrom (b + 1) (l.drop 1) = true := by
  cases l with
  | nil => simp [ssaFrom]
  | cons g gs =>
    simp only [ssaFrom, Bool.and_eq_true] at h
    simpa using h.2

/-- Dropping `n` gates advances the base by `n`. -/
theorem ssaFrom_drop : ∀ (n : Nat) (gs : List Gate) (base : Nat),
    ssaFrom base gs = true → ssaFrom (base + n) (gs.drop n) = true := by
  intro n
  induction n with
  | zero => intro gs base h; simpa using h
  | succ m ih =>
    intro gs base h
    have h1 := ssaFrom_tail1 (gs.drop m) (base + m) (ih gs base h)
    have h2 : (gs.drop m).drop 1 = gs.drop (m + 1) := by
      rw [List.drop_drop]
    have h3 : base + m + 1 = base + (m + 1) := by omega
    rw [h2, h3] at h1
    exact h1

/-- ⭐⭐ **ONE GATE'S VALUE IN AN ARBITRARY SSA LIST** — no flatness. Gate `i` evaluates its
op on the environment produced by the gates *before* it, and everything after it is frame.

*This is the tool `run_of_flat_gates` is named to refuse: it is the mux-shaped case.* -/
theorem run_ssa_gate (E : Env) (gs : List Gate) (base i : Nat)
    (hssa : ssaFrom base gs = true) (hi : i < gs.length) :
    run E gs (gs.getD i default).out
      = (gs.getD i default).op.eval (run E (gs.take i)) := by
  have hg : gs.getD i default = gs[i] := List.getD_eq_getElem _ _ hi
  have hsplit : gs = (gs.take i ++ [gs[i]]) ++ gs.drop (i + 1) := by
    rw [List.append_assoc, List.singleton_append, ← List.drop_eq_getElem_cons hi,
        List.take_append_drop]
  have houti : (gs[i] : Gate).out = base + i := by
    rw [← hg]; exact ssaFrom_out gs base i hssa hi
  have hne : ∀ x ∈ gs.drop (i + 1), x.out ≠ (gs[i] : Gate).out := by
    intro x hx hEq
    have hge := ssaFrom_out_ge (gs.drop (i + 1)) (base + (i + 1))
      (ssaFrom_drop (i + 1) gs base hssa) x hx
    rw [hEq, houti] at hge
    -- ⚠️ Net-typed `≤`: supply the strict bound as a Nat TERM, never `by omega`.
    exact absurd hge (Nat.not_le.mpr (Nat.add_lt_add_left (Nat.lt_succ_self i) base))
  -- ⚠️ `rw [hsplit]` in place FAILS with "motive is not type correct": `gs[i]` carries a
  -- proof mentioning `gs`, so rewriting `gs` breaks its own index bound. Generalising the
  -- three pieces to opaque locals FIRST is what makes the rewrite legal.
  have key : ∀ (g : Gate) (pre suf : List Gate), gs = (pre ++ [g]) ++ suf →
      (∀ x ∈ suf, x.out ≠ g.out) → run E gs g.out = g.op.eval (run E pre) := by
    intro g pre suf hEq hxne
    rw [hEq]
    exact run_snoc_frame E pre g suf hxne
  rw [hg]
  exact key gs[i] (gs.take i) (gs.drop (i + 1)) hsplit hne

#audit_axioms ssaFrom_tail1 ssaFrom_drop
#audit_axioms run_ssa_gate

end SaltWorks.HDL
