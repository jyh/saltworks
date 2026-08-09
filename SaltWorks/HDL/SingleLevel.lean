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

## ✅ ALL FOUR BITWISE ORGANS NOW HAVE ∀-env SPECS — closed 21:5x

**When this file first landed, three of the four were still sampled-only and I published that as
an open item for the fleet.** It is closed. `bitXor32_sem`, `bitAnd32_sem` and `bitOr32_sem` are
here, each ∀ env with no side condition.

⛔ **BUT NOT THE WAY I FIRST TRIED, AND THE DIFFERENCE IS THE REUSABLE PART.** The generic
```
theorem bwCirc_sem (mk) (hfan : ∀ x y, (mk x y).fanin = [x, y]) (env) : …
```
**still does not elaborate** — deterministic `whnf` timeout at `maxHeartbeats 1000000`. [INFERENCE]
*Unfolding `sem` + `bwCirc` with a VARIABLE `mk` appears to diverge where concrete gates do not.*
⇒ ***So the three organs are covered by three CONCRETE INSTANCES of `run_level_map`, one per op —
the route named when the generalisation was deferred. The general lemma over an arbitrary `mk`
remains unproved and is not needed: `run_level_map` itself is the generalisation that matters, and
it takes the gate shape rather than the op constructor.***

📌 **The side condition is shared by all three (`bin_fanin_below`) and it needs BOTH omega cures:
`simp only [Net]` for the ascription and nothing for the defs here, since `64` is a literal.**

## THE ROWS, BY NAME

| row | says |
|---|---|
| ⭐ `run_level_map` | a single-level gate list computes each `f j` in the ORIGINAL env |
| `not_fanin_below` | `(Op.not k).fanin` lies below `32` — the side condition, discharged without `omega` |
| ⭐ `bitNot32_sem` | `sem bitNot32 env = map (!env ·)`, **∀ env, no side condition** |
| `bin_fanin_below` | the two-operand side condition, shared by the three below |
| ⭐ `bitXor32_sem` | `sem bitXor32 env = map (env k ^^ env (32+k))`, **∀ env** |
| ⭐ `bitAnd32_sem` | `sem bitAnd32 env = map (env k && env (32+k))`, **∀ env** |
| ⭐ `bitOr32_sem` | `sem bitOr32 env = map (env k \|\| env (32+k))`, **∀ env** |

## ⚠️ AND WHAT THIS DOES **NOT** DO

**This file does not itself assemble anything.** ✅ *`SubFragment`'s bar 4 WAS closed separately at
21:4x (`frag_subtraction`, `7f21fa2`) using `bitNot32_sem` — and the connection turned out not to
need `inst_sem` at all: the instantiated `bitNot32` is itself single-level, so `run_level_map`
applies directly (`SubFragment.notInst_shape`).*
⚠️ **And a `∀ env` spec is not a `∀ env` CORRECTNESS theorem.** These say what the organs COMPUTE,
in terms of their input nets. Whether that computation is the RIGHT function of a 32-bit word —
e.g. that `bitXor32` implements `BitVec.xor` — is a separate statement, and the corpus's
`*_correct_on_sample` certificates are still the only evidence for it.
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

theorem bin_fanin_below (k : Nat) (hk : k < 32) (op : Net → Net → Op)
    (hfan : (op k (32 + k)).fanin = [k, 32 + k]) :
    ∀ x ∈ (op k (32 + k)).fanin, x < 64 := by
  intro x hx
  rw [hfan] at hx
  simp at hx
  simp only [Net] at hk ⊢
  rcases hx with rfl | rfl
  · omega
  · omega

theorem bitXor32_sem (env : Env) :
    sem bitXor32 env = (List.range 32).map (fun k => xor (env k) (env (32 + k))) := by
  simp only [sem, bitXor32, bwCirc, List.map_map]
  apply List.map_congr_left
  intro k hk
  have h := run_level_map 64 32 (fun j => Op.xor j (32 + j)) env
              (fun j hj => bin_fanin_below j hj Op.xor rfl) k (List.mem_range.mp hk)
  simpa [Op.eval] using h

theorem bitAnd32_sem (env : Env) :
    sem bitAnd32 env = (List.range 32).map (fun k => (env k) && (env (32 + k))) := by
  simp only [sem, bitAnd32, bwCirc, List.map_map]
  apply List.map_congr_left
  intro k hk
  have h := run_level_map 64 32 (fun j => Op.and j (32 + j)) env
              (fun j hj => bin_fanin_below j hj Op.and rfl) k (List.mem_range.mp hk)
  simpa [Op.eval] using h

theorem bitOr32_sem (env : Env) :
    sem bitOr32 env = (List.range 32).map (fun k => (env k) || (env (32 + k))) := by
  simp only [sem, bitOr32, bwCirc, List.map_map]
  apply List.map_congr_left
  intro k hk
  have h := run_level_map 64 32 (fun j => Op.or j (32 + j)) env
              (fun j hj => bin_fanin_below j hj Op.or rfl) k (List.mem_range.mp hk)
  simpa [Op.eval] using h

#audit_axioms run_level_map
#audit_axioms not_fanin_below
#audit_axioms bitNot32_sem
#audit_axioms bin_fanin_below
#audit_axioms bitXor32_sem
#audit_axioms bitAnd32_sem
#audit_axioms bitOr32_sem

end SaltWorks.HDL
