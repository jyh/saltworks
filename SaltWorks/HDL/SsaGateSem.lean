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

⛔ **A CORRECTION TO THIS FILE'S OWN ORIGINAL CLAIM, LEFT IN PLACE RATHER THAN QUIETLY
DELETED.** The header shipped at `71d877f` said the uniform 32×32 statement was *"asserted
in a docstring and nowhere in the kernel"* and that `run_ssa_gate` was *"the first tool with
which it can be proved"*. ***BOTH ARE FALSE.*** `SaltWorks.Stack.Program.run_regNextN`
(`Program.lean:7476`) proves exactly that statement — landed, audited, and reached by a
bespoke development (`rnArr`, `run_rnArr`, `run_pointwise`, plus a parallel re-definition
`rnInN`/`rnBaseN`/`rnPOp`/`rnQOp`). **I read `RegNext.lean`, found only samples there, and
reported an absence about the CORPUS from a search of one FILE.**

*What survives the correction, stated positively:* `run_pointwise` is general only for FLAT
map-generated blocks, so the non-flat gap it left was real; and nothing in the tree states a
gate's value as its op applied to the **final** environment, which is what `run_gate_val`
below adds. **The tool is new; the `RegNext` fact that motivated it was not.**
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

/-- A net below the base is untouched by an SSA block — or by any PREFIX of it. -/
theorem run_take_below_base (E : Env) (gs : List Gate) (base m n : Nat)
    (hssa : ssaFrom base gs = true) (hn : n < base) :
    run E (gs.take m) n = E n := by
  refine run_of_unwritten E _ n (fun g hg hEq => ?_)
  have hge := ssaFrom_out_ge gs base hssa g (List.mem_of_mem_take hg)
  rw [hEq] at hge
  exact absurd hge (Nat.not_le.mpr hn)

/-- A prefix long enough to have DEFINED net `n` already gives `n` its final value. -/
theorem run_take_stable (E : Env) (gs : List Gate) (base m n : Nat)
    (hssa : ssaFrom base gs = true) (hn : n < base + m) :
    run E (gs.take m) n = run E gs n := by
  conv_rhs => rw [← List.take_append_drop m gs]
  rw [run_append]
  refine (run_of_unwritten _ _ n (fun g hg hEq => ?_)).symm
  have hge := ssaFrom_out_ge (gs.drop m) (base + m) (ssaFrom_drop m gs base hssa) g hg
  rw [hEq] at hge
  exact absurd hge (Nat.not_le.mpr hn)

/-- ⭐ **`run_ssa_gate` BY MEMBERSHIP** — no positional index. This is what lets a
`flatMap`-generated block be read without a `flatMap` indexing lemma. -/
theorem run_ssa_gate_mem (E : Env) (gs : List Gate) (base : Nat)
    (hssa : ssaFrom base gs = true) {g : Gate} (hg : g ∈ gs) :
    run E gs g.out = g.op.eval (run E (gs.take (g.out - base))) := by
  obtain ⟨i, hi, hgi⟩ := List.mem_iff_getElem.mp hg
  have hd : gs.getD i default = g := by rw [List.getD_eq_getElem _ _ hi, hgi]
  have hout : g.out = base + i := by rw [← hd]; exact ssaFrom_out gs base i hssa hi
  have hsub : g.out - base = i := by rw [hout]; exact Nat.add_sub_cancel_left base i
  rw [hsub, ← hd]
  exact run_ssa_gate E gs base i hssa hi

/-- Every gate reads only nets strictly below its OWN output net. This is what `ssaFrom`'s
second conjunct says, pulled out by membership rather than by position. -/
theorem ssaFrom_fanin_lt : ∀ (gs : List Gate) (base : Nat), ssaFrom base gs = true →
    ∀ g ∈ gs, ∀ n ∈ g.op.fanin, n < g.out := by
  intro gs
  induction gs with
  | nil => intro base _ g hg; simp at hg
  | cons g' gs ih =>
    intro base hssa x hx n hn
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, hfan⟩, hrest⟩ := hssa
    rcases List.mem_cons.mp hx with rfl | h
    · rw [hout]
      exact of_decide_eq_true (List.all_eq_true.mp hfan n hn)
    · exact ih (base + 1) hrest x h n hn

/-- ⭐⭐⭐ **THE NETLIST COMPUTES WHAT IT SAYS.** In any SSA gate list, a gate's output net
holds its operation applied to the **final** environment — no prefix, no position, no
flatness. Every hypothesis is discharged from the `ssa` certificate the block already carries.

*This is the shape all organ-level reasoning wants: it makes a gate list readable as a set
of simultaneous equations rather than as a sequence.* -/
theorem run_gate_val (E : Env) (gs : List Gate) (base : Nat)
    (hssa : ssaFrom base gs = true) {g : Gate} (hg : g ∈ gs) :
    run E gs g.out = g.op.eval (run E gs) := by
  have hge := ssaFrom_out_ge gs base hssa g hg
  rw [run_ssa_gate_mem E gs base hssa hg]
  refine Op.eval_congr g.op (fun n hn => ?_)
  refine run_take_stable E gs base _ n hssa ?_
  have hlt : n < g.out := ssaFrom_fanin_lt gs base hssa g hg n hn
  have harith : base + (g.out - base) = g.out := Nat.add_sub_cancel' hge
  rw [harith]
  exact hlt

/-- A primary input keeps its value through the whole block. -/
theorem run_below_base (E : Env) (gs : List Gate) (base n : Nat)
    (hssa : ssaFrom base gs = true) (hn : n < base) : run E gs n = E n := by
  refine run_of_unwritten E _ n (fun g hg hEq => ?_)
  have hge := ssaFrom_out_ge gs base hssa g hg
  rw [hEq] at hge
  exact absurd hge (Nat.not_le.mpr hn)

#audit_axioms run_take_below_base run_take_stable run_ssa_gate_mem
#audit_axioms ssaFrom_fanin_lt run_gate_val run_below_base

end SaltWorks.HDL
