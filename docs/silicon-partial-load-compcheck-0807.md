# PARTIAL LOAD — the composition check, before anyone builds it

### 2026-08-07 ~15:40, SILICON. B0(b) doctrine applied to the statement compiler
### listed at 15:11 as *"NEW, unowned, mine by default"*: **does it typecheck
### against the LANDED machinery before it is scoped?** Probe:
### `ScratchSILICONpartial.lean`, **EXIT=0, zero `sorry`.**

## VERDICT: **partial load needs NO new banyan theory and NO new sorting theory.
## It needs ONE bridge — and the product order it runs on lifts for free.**

---

## 1. What the probe established, item by item

| # | question | result |
|---|---|---|
| ① | does the product order `(¬active, dest)` exist as a `LinearOrder`? | ✅ `Prod.Lex.instLinearOrder Bool ℕ` |
| ② | does `runNet batcher8` accept it? | ✅ elaborates |
| ③ | does the **0-1 principle** lift the landed Boolean fact to it? | ✅ `zeroOne_principle batcher8_sorts_bool key : IsSorted (runNet batcher8 key)` — **free** |
| ④ | is `!active` the right polarity? | ✅ `toLex (false, 7) < toLex (true, 0)` by `decide` — *an active line with the WORST destination still sorts below any idle* |
| ⑤⑥ | is `banyan_selfrouting` hard-wired to full width? | ⛔ **NO — it takes an ARBITRARY `n ≤ 2 ^ k`** |
| ⑦ | do idle lines appear in its hypotheses at all? | ⛔ **NO — it never constrains `s ≥ n`** (checked with an agreement lemma: two destination maps agreeing only below `n` give the same conclusion) |

## 2. ⭐ The structural finding

`banyan_selfrouting` needs **exactly two** facts, and **both are restricted to
`Iio n`**:

```lean
(hn   : n ≤ 2 ^ k)
(hdest: StrictMonoOn dest (Set.Iio n))
(hlt  : ∀ s < n, dest s < 2 ^ k)
```

⇒ ***The banyan was ALWAYS partial-load-capable. The full-load restriction
entered entirely through the BRIDGE*** — `banyan_selfrouting_of_sorts_bool`
instantiates `n := 8` and demands `Function.Injective v` over **all** of
`Fin 8`, which at `k = 3` forces a permutation (`seam_hyps_force_full_load`).
**Nothing in the banyan asked for that. We narrowed it ourselves, one layer up.**

## 3. So what is actually owed — one bridge, two obligations

With `key i := toLex (!act i, dst i)` and `sk := runNet batcher8 key`,
`hw i := (ofLex (sk i)).2`, and `n := card {i | act i}`:

* **(P1) CONCENTRATION** — `∀ i, (ofLex (sk i)).1 = false ↔ (i : ℕ) < n`.
  *The actives occupy exactly the first `n` lines.* Needs a counting argument:
  the sort permutes, so the active count is preserved, and the key's first
  component puts every `false` before every `true`.
* **(P2) STRICT MONOTONICITY ON THE PREFIX** — `StrictMonoOn (extendIio 0 hw)
  (Set.Iio n)`. Follows from ③'s non-strict `IsSorted` **plus distinctness of the
  actives' destinations** — which is the partial-load analogue of `KB3`, and it
  is an obligation on the ACTIVE lines only.

📌 **Idle lines need no encoding, no sentinel, and no distinctness.** That is the
whole difference from `composed_switch_of_seam`, and it is why the five
byte-identical idle frames in `bnCSparse` are a problem for the *full-load*
statement and **not** for this one.

## 4. ⚠️ A false obstacle I nearly published

My first probe wrote `batcher8_sorts_bool _` for ③ and got
**`(deterministic) timeout at whnf, 200000 heartbeats`**. *I was one edit away
from reporting "the 0-1 principle does not instantiate at the lex order" as a
finding.* ⛔ **It was my own wrong term** — `batcher8_sorts_bool : Sorts batcher8
Bool` applied to a lex-valued vector, so Lean was trying to unify `Bool` with
`Bool ×ₗ ℕ` by unfolding the 19-comparator network. The correct term,
`zeroOne_principle batcher8_sorts_bool key`, elaborates instantly.
⇒ ***A timeout is a report about the TERM I wrote, not about the LIBRARY.***
*Same genre as the day's other adjacent-object readings: the instrument answered
truthfully about the wrong object.*

## 5. What this does NOT say

* It does **not** state the partial-load theorem, and it certainly does not prove
  it. **(P1) and (P2) are unproved**, and (P1) is the one with real content.
* It does **not** tie anything to the fabricated netlist. That seam — the
  convention-C element's order actually BEING `(¬active, dest)` — is
  **compiler's**, exactly as `hseam` is.
* It does **not** supersede `composed_switch_of_seam`. Full load stays the
  statement BB-1's ceremony rests on; this is the range around it.
