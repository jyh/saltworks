/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Bitwise

/-!
# SINGLE-LEVEL CIRCUITS — and the first ∀-env spec for a bitwise organ

⛔ **THIS FILE EXISTS BECAUSE `SubFragment.lean`'s PROBE NAMED ITS OWN BLOCKER.** That probe
instantiated `bitNot32` → `adder32` and got a `∀ env` composition theorem whose content was
thin, for one reason: **a `∀ env` subtraction theorem needs `bitNot32`'s semantics at EVERY
input, and this corpus had none.** `bitNot32_correct_on_sample` (`Bitwise.lean:142`) is a Bool
sweep over fixtures. ⇒ ***The sampled certificates became load-bearing the moment two organs
met, and that — not the composition machinery — is what blocks an assembled datapath spec.***

## ⭐ THE GENERAL LEMMA, `run_level_map`

A gate list of the shape `(List.range n).map (fun k => ⟨base + k, f k⟩)` is **single-level**
when every `f k` reads only nets **below** `base`: no gate reads another gate's output. For
such a list, ***running it and reading gate `j`'s output gives `f j` evaluated in the ORIGINAL
environment*** — the intermediate writes cannot be observed, because nothing reads them.

📌 **It uses the corpus's own `Op.eval_congr` (`Sem.lean:43`) rather than a fresh copy.** *I
had written a duplicate before finding it — a green build accepts duplicate declarations
silently, so the only thing that catches one is looking.*

## ✅ WHAT IT BUYS — `bitNot32_sem`

`sem bitNot32 env = (List.range 32).map (fun k => !(env k))`, **∀ env, no side condition.**
The first unconditional semantics for any bitwise organ in this corpus, and exactly the
premise `SubFragment`'s bar 4 was missing.

## ⛔ WHAT IS **DEFERRED**, WITH THE SYMPTOM SO IT IS A NAMED PIECE AND NOT AN OMISSION

`bwCirc mk` (`Bitwise.lean:58`) has the SAME single-level shape at `base = 64`, so
`bitXor32`, `bitAnd32` and `bitOr32` should follow from one generalisation. **I wrote it and it
did not land:**
```
theorem bwCirc_sem (mk) (hfan : ∀ x y, (mk x y).fanin = [x, y]) (env) : …
  → (deterministic) timeout at `whnf`, even at maxHeartbeats 1000000
```
[INFERENCE] *The unfold of `sem` + `bwCirc` with a VARIABLE `mk` appears to diverge where the
same shape with `bitNot32`'s concrete gates does not.* ⚠️ **And a second obstruction beside it:
`omega` could not prove `32 + k < 64` from `k < 32` in the fanin side condition** — the
counterexample carried `k`'s bound and never saw the goal, which is the documented tell for
`omega` against `Net`-typed arithmetic here (`Net` is an `abbrev` for `Nat`,
`Syntax.lean:46`).
⇒ ***So `bitXor32`, `bitAnd32` and `bitOr32` REMAIN SAMPLED-ONLY. Three of the four bitwise
organs are still where the probe found them, and the route is known: either specialise the
lemma per-op (concrete `mk`, which is what works for `bitNot32`) or fix the elaboration.***

## THE ROWS, BY NAME

| row | says |
|---|---|
| ⭐ `run_level_map` | a single-level gate list computes each `f j` in the ORIGINAL env |
| `not_fanin_below` | `(Op.not k).fanin` lies below `32` — the side condition, discharged without `omega` |
| ⭐ `bitNot32_sem` | `sem bitNot32 env = map (!env ·)`, **∀ env, no side condition** |

## ⚠️ AND WHAT THIS DOES **NOT** DO

**It does not upgrade `SubFragment`'s bar 4.** That upgrade needs `bitNot32_sem` composed
through `inst_sem` to relate the composite's nets to `!(env ·)`, and **that step is not taken
here.** *Bar 4 is now REACHABLE and is still PARTIAL; saying otherwise would be the
name-outruns-statement defect this seat has fixed four times tonight.*
-/

namespace SaltWorks.HDL

/-- ⭐ SINGLE-LEVEL RUN: a gate list that writes at/above `base` and reads only below it
computes each gate's op in the ORIGINAL env. Uses the corpus's own `Op.eval_congr`
(Sem.lean:43) rather than a fresh copy of it. -/
theorem run_level_map (base n : Nat) (f : Nat → Op) (env : Env)
    (hf : ∀ k, k < n → ∀ a ∈ (f k).fanin, a < base) :
    ∀ j, j < n →
      run env ((List.range n).map (fun k => (⟨base + k, f k⟩ : Gate))) (base + j)
        = (f j).eval env := by
  induction n with
  | zero => intro j hj; exact absurd hj (Nat.not_lt_zero j)
  | succ m ih =>
    intro j hj
    rw [List.range_succ, List.map_append, run_append]
    have hbelow : ∀ x, x < base →
        run env ((List.range m).map (fun k => (⟨base + k, f k⟩ : Gate))) x = env x := by
      intro x hx
      refine run_of_unwritten env _ x (fun g hg => ?_)
      obtain ⟨k, _, hgk⟩ := List.mem_map.mp hg
      subst hgk
      show base + k ≠ x
      intro hcon
      exact absurd (hcon ▸ hx) (Nat.not_lt.mpr (Nat.le_add_right base k))
    by_cases hjm : j < m
    · show upd _ (base + m) _ (base + j) = _
      rw [upd_of_ne _ (fun hEq => absurd (Nat.add_left_cancel hEq) (Nat.ne_of_lt hjm))]
      exact ih (fun k hk => hf k (Nat.lt_succ_of_lt hk)) j hjm
    · have hjeq : j = m := Nat.le_antisymm (Nat.lt_succ_iff.mp hj) (Nat.not_lt.mp hjm)
      subst hjeq
      show upd _ (base + j) _ (base + j) = _
      rw [upd_self]
      exact Op.eval_congr _ (fun a ha => hbelow a (hf j (Nat.lt_succ_self j) a ha))


/-! ## THE PAYOFF — ∀-env specs for organs that had only SAMPLED certificates -/

theorem not_fanin_below (k : Nat) (hk : k < 32) : ∀ a ∈ (Op.not k).fanin, a < 32 := by
  intro a ha
  simp only [Op.fanin, List.mem_singleton] at ha
  subst ha; exact hk

theorem bitNot32_sem (env : Env) :
    sem bitNot32 env = (List.range 32).map (fun k => !(env k)) := by
  simp only [sem, bitNot32, List.map_map]
  apply List.map_congr_left
  intro k hk
  have h := run_level_map 32 32 (fun j => Op.not j) env
              (fun j hj => not_fanin_below j hj) k (List.mem_range.mp hk)
  simpa [Op.eval] using h

#audit_axioms run_level_map
#audit_axioms not_fanin_below
#audit_axioms bitNot32_sem

end SaltWorks.HDL
