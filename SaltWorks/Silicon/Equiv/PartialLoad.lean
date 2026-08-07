/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Bridge

/-!
# PARTIAL LOAD — the range `composed_switch_of_seam` does not reach

`ComposedSwitch.lean` proves the composed switch at **full load**, and
`seam_hyps_force_full_load` shows that is not a choice: at the fabricated
fabric's `k = 3`, `Injective v` plus `v i < 8` over `Fin 8` exhaust `Iio 8`.
`repeated_code_refutes_no_conflict` shows the conclusion is *false* once two
lines share a code — which is the tile's real operating case, since `bnCSparse`
gives its five idle lines the byte-identical frame `cFrame false 0 […]`.

This module opens the partial-load range. The composition check
(`docs/silicon-partial-load-compcheck-0807.md`) established three things before
a line of this file was written:

* `banyan_selfrouting` takes an **arbitrary** `n ≤ 2 ^ k` and constrains only
  `s < n` — **it was always partial-load-capable**; the full-load restriction
  entered through the *bridge*, which instantiates `n := 8`;
* the convention-C product order `(¬active, dest)` is `Bool ×ₗ ℕ`, and
  `zeroOne_principle` lifts the landed **Boolean** sorting fact to it for free;
* `toLex (false, 7) < toLex (true, 0)` — an active line bound for the worst
  destination still sorts below any idle, so `!active` is the right polarity.

## What is proved here, and what is not

⭐ **`P1` — CONCENTRATION — IS PROVED** (`cSorted_concentrates`): the sorted
vector's active lines are **exactly** `Iio (cCount act)`. The banyan's
`Set.Iio n` conjunct is therefore discharged by the hardware's *order*, not
assumed of its traffic.

🔑 **And it is smaller than it looks: the proof never mentions `batcher8`.**
"The actives are the first `n` lines" is not a fact about sorting networks. It is
three facts — a monotone `Bool` function on `Fin N` is `false` exactly on a
prefix whose length is its count (`monotone_bool_false_prefix`); lexicographic
`≤` gives `≤` on first components (`cSorted_fst_mono`); a permutation preserves a
count (`card_filter_perm`). **`bnC_concentrates_actives` — three actives on lines
2, 5, 7 landing on wires 0, 1, 2 — is one of the 256 activity patterns this
covers.**

⛔ **Not proved:** `P2` — `StrictMonoOn` on that prefix, which needs distinctness
of the **actives'** destinations (`KB3` restricted to the lines that carry
packets). With `P2`, `banyan_selfrouting` applies at `n := cCount act` and the
partial-load theorem closes.

⚠️ **And the seam to the fabricated element — that convention C's order actually
IS `(¬active, dest)` — is compiler's, exactly as `hseam` is.** Nothing here
claims it.
-/

namespace SaltWorks.Silicon

open SaltWorks.Stack

/-! ## The reusable core of concentration -/

/-- ⭐ **A MONOTONE `Bool` FUNCTION IS `false` EXACTLY ON A PREFIX, AND THE
PREFIX LENGTH IS THE COUNT.** This is the whole of concentration once the sorted
vector is known to be monotone in its activity component: "the actives are the
first `n` lines" is not a fact about sorting networks at all. -/
theorem monotone_bool_false_prefix {N : ℕ} {f : Fin N → Bool}
    (hf : ∀ i j : Fin N, i ≤ j → f i ≤ f j) (i : Fin N) :
    f i = false ↔ (i : ℕ) < (Finset.univ.filter fun j => f j = false).card := by
  constructor
  · intro hi
    have hsub : Finset.Iic i ⊆ Finset.univ.filter (fun j => f j = false) := by
      intro j hj
      simp only [Finset.mem_Iic] at hj
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      have h := hf j i hj
      rw [hi] at h
      cases hfj : f j with
      | false => rfl
      | true => rw [hfj] at h; exact absurd h (by decide)
    have hc := Finset.card_le_card hsub
    rw [Fin.card_Iic] at hc
    omega
  · intro hlt
    by_contra hne
    have hi : f i = true := by simpa using hne
    have hsub : (Finset.univ.filter fun j => f j = false) ⊆ Finset.Iio i := by
      intro j hj
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hj
      simp only [Finset.mem_Iio]
      by_contra hji
      simp only [not_lt] at hji
      have h := hf i j hji
      rw [hi, hj] at h
      exact absurd h (by decide)
    have hc := Finset.card_le_card hsub
    rw [Fin.card_Iio] at hc
    omega

/-- **A count is carried across the sorting permutation.** The half of `P1` that
is pure combinatorics: relabelling by a bijection does not change how many
indices satisfy a predicate. -/
theorem card_filter_perm {N : ℕ} (σ : Equiv.Perm (Fin N)) (p : Fin N → Bool) :
    (Finset.univ.filter fun i => p (σ i) = false).card
      = (Finset.univ.filter fun i => p i = false).card := by
  refine Finset.card_bij (fun i _ => σ i) (fun a ha => ?_) (fun a _ b _ h => ?_)
    (fun b hb => ⟨σ.symm b, ?_, ?_⟩)
  · simpa using ha
  · exact σ.injective h
  · simpa using hb
  · simp

/-! ## The sort key, and its activity component -/

/-- The convention-C sort key: **active before idle, then ascending
destination.** `!act` rather than `act` because `false < true`, so an active
line sorts LOW — the polarity the concentration fixture needs. -/
def cKey (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i : Fin 8) : Bool ×ₗ ℕ :=
  toLex (!act i, dst i)

/-- The sorted key vector — the abstract stand-in for what the fabricated sorter
produces. Tying this to the netlist is the seam, and it is compiler's. -/
def cSorted (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) : Fin 8 → Bool ×ₗ ℕ :=
  runNet batcher8 (cKey act dst)

/-- The number of active lines — the `n` at which the banyan theorem is used. -/
def cCount (act : Fin 8 → Bool) : ℕ := (Finset.univ.filter fun i => act i = true).card

/-- **The sorted key vector is sorted at the PRODUCT order** — the landed
Boolean fact, lifted by the 0-1 principle at no cost. -/
theorem cSorted_isSorted (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) :
    IsSorted (cSorted act dst) :=
  zeroOne_principle batcher8_sorts_bool _

/-- ⭐ **THE ACTIVITY COMPONENT IS MONOTONE AFTER SORTING.** Lexicographic `≤`
gives `≤` on first components, so the sorted vector's activity bits are
non-decreasing — which, with `monotone_bool_false_prefix`, is concentration. -/
theorem cSorted_fst_mono (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i j : Fin 8)
    (hij : i ≤ j) :
    (ofLex (cSorted act dst i)).1 ≤ (ofLex (cSorted act dst j)).1 := by
  have h := cSorted_isSorted act dst i j hij
  rcases Prod.Lex.le_iff.mp h with h1 | ⟨h1, _⟩
  · exact le_of_lt h1
  · exact le_of_eq h1

/-- ⭐ **CONCENTRATION, MODULO THE COUNT.** The actives of the sorted vector are
exactly its first `c` lines, where `c` counts the sorted vector's own actives.
**`P1` is this together with `c = cCount act`**, which `card_filter_perm`
supplies once `runNet_perm`'s `σ` is named. -/
theorem cSorted_actives_are_a_prefix (act : Fin 8 → Bool) (dst : Fin 8 → ℕ)
    (i : Fin 8) :
    (ofLex (cSorted act dst i)).1 = false ↔
      (i : ℕ) < (Finset.univ.filter fun j => (ofLex (cSorted act dst j)).1 = false).card :=
  monotone_bool_false_prefix (cSorted_fst_mono act dst) i

/-- **The sorter neither creates nor destroys activity.** The count of actives
after sorting is the count that went in — the half of `P1` that rides on the
permutation rather than on the order. -/
theorem cSorted_active_count (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) :
    (Finset.univ.filter fun j => (ofLex (cSorted act dst j)).1 = false).card
      = cCount act := by
  obtain ⟨σ, hσ⟩ := runNet_perm batcher8 (cKey act dst)
  have hpt : ∀ j : Fin 8, (ofLex (cSorted act dst j)).1 = (!act (σ j)) := by
    intro j
    show (ofLex (runNet batcher8 (cKey act dst) j)).1 = _
    rw [hσ]
    rfl
  calc (Finset.univ.filter fun j => (ofLex (cSorted act dst j)).1 = false).card
      = (Finset.univ.filter fun j => (!act (σ j)) = false).card := by
        simp only [hpt]
    _ = (Finset.univ.filter fun j => (!act j) = false).card :=
        card_filter_perm σ (fun i => !act i)
    _ = cCount act := by
        unfold cCount
        congr 1
        ext j
        simp

/-- ⭐⭐ **P1 — CONCENTRATION, CLOSED.** *The sorted vector's active lines are
EXACTLY `Iio (cCount act)`.* The sorter drives every active packet down to the
low wires, contiguously from zero, and the boundary is the number of actives that
entered — **so the banyan's `Set.Iio n` conjunct is discharged by the hardware's
order rather than assumed of its traffic.**

This is `bnC_concentrates_actives` (three actives on lines 2, 5, 7 landing on
wires 0, 1, 2) as a theorem about all `2 ^ 8` activity patterns instead of one
fixture. -/
theorem cSorted_concentrates (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i : Fin 8) :
    (ofLex (cSorted act dst i)).1 = false ↔ (i : ℕ) < cCount act := by
  rw [cSorted_actives_are_a_prefix act dst i, cSorted_active_count act dst]

end SaltWorks.Silicon

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.monotone_bool_false_prefix
  SaltWorks.Silicon.card_filter_perm
#audit_axioms SaltWorks.Silicon.cSorted_isSorted
  SaltWorks.Silicon.cSorted_fst_mono
#audit_axioms SaltWorks.Silicon.cSorted_actives_are_a_prefix
  SaltWorks.Silicon.cSorted_active_count
#audit_axioms SaltWorks.Silicon.cSorted_concentrates
end Audit
