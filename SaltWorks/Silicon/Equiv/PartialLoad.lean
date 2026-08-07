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

⭐ **`P2` — `StrictMonoOn` on that prefix — IS PROVED** (`cSorted_strictMonoOn`),
from distinctness of the **actives'** destinations alone: `KB3` restricted to the
lines that carry packets, and **strictly weaker than the full-load `KB3`**, which
demanded it of all eight including the idles.

⭐⭐ **AND SO THE THEOREM CLOSES: `partial_load_selfrouting`.** Any activity
pattern; hypotheses on the **active lines only**; the banyan routes every active
packet without a single internal conflict. ***Both of the banyan's traffic
hypotheses are discharged by the sorter's ORDER*** — sortedness by
`zeroOne_principle`, concentration by `cSorted_concentrates`. **The idle lines
are constrained by nothing at all**, which is exactly what
`composed_switch_of_seam` could not offer and what `bnCSparse`'s five
byte-identical idle frames need.

⚠️ **What is NOT claimed: the seam to the fabricated element — that convention
C's order actually IS `(¬active, dest)` — is compiler's, exactly as `hseam` is.**
This module is about `cSorted`, the abstract product-order sort. **Nothing here
asserts that the silicon implements it.**
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

/-! ## P2 — strict monotonicity on the active prefix -/

/-- The destination carried on wire `i` after sorting. -/
def cDst (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i : Fin 8) : ℕ :=
  (ofLex (cSorted act dst i)).2

/-- **`KB3`, restricted to the lines that carry packets.** *Strictly weaker than
the full-load form*, which demanded distinctness of all eight destinations
including the idles' — the demand `bnCSparse` cannot meet. -/
def ActivesDistinct (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) : Prop :=
  ∀ i j : Fin 8, act i = true → act j = true → dst i = dst j → i = j

theorem cCount_le (act : Fin 8 → Bool) : cCount act ≤ 8 := by
  unfold cCount
  calc (Finset.univ.filter fun i => act i = true).card
      ≤ (Finset.univ : Finset (Fin 8)).card := Finset.card_filter_le _ _
    _ = 8 := by simp

/-- With equal activity bits, the sorted order is the destination order. -/
theorem cSorted_snd_le (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i j : Fin 8)
    (hij : i ≤ j) (hfst : (ofLex (cSorted act dst i)).1 = (ofLex (cSorted act dst j)).1) :
    cDst act dst i ≤ cDst act dst j := by
  have h := cSorted_isSorted act dst i j hij
  rcases Prod.Lex.le_iff.mp h with h1 | ⟨_, h2⟩
  · rw [hfst] at h1; exact absurd h1 (lt_irrefl _)
  · exact h2

/-- ⭐⭐ **P2 — STRICT MONOTONICITY ON THE ACTIVE PREFIX.** Given only that the
**active** lines carry distinct destinations, the sorted destinations are
strictly increasing across `Iio (cCount act)` — which is exactly
`banyan_selfrouting`'s `hdest`, at the partial-load `n`. -/
theorem cSorted_strictMonoOn (act : Fin 8 → Bool) (dst : Fin 8 → ℕ)
    (hd : ActivesDistinct act dst) :
    StrictMonoOn (extendIio 0 (cDst act dst)) (Set.Iio (cCount act)) := by
  obtain ⟨σ, hσ⟩ := runNet_perm batcher8 (cKey act dst)
  have hfst : ∀ k : Fin 8, (ofLex (cSorted act dst k)).1 = (!act (σ k)) := by
    intro k; show (ofLex (runNet batcher8 (cKey act dst) k)).1 = _; rw [hσ]; rfl
  have hsnd : ∀ k : Fin 8, cDst act dst k = dst (σ k) := by
    intro k; show (ofLex (runNet batcher8 (cKey act dst) k)).2 = _; rw [hσ]; rfl
  intro a ha b hb hab
  simp only [Set.mem_Iio] at ha hb
  have ha8 : a < 8 := lt_of_lt_of_le ha (cCount_le act)
  have hb8 : b < 8 := lt_of_lt_of_le hb (cCount_le act)
  rw [extendIio_apply _ _ ha8, extendIio_apply _ _ hb8]
  set i : Fin 8 := ⟨a, ha8⟩ with hi
  set j : Fin 8 := ⟨b, hb8⟩ with hj
  -- both wires are ACTIVE, by concentration
  have hai : (ofLex (cSorted act dst i)).1 = false :=
    (cSorted_concentrates act dst i).mpr ha
  have hbj : (ofLex (cSorted act dst j)).1 = false :=
    (cSorted_concentrates act dst j).mpr hb
  have hacti : act (σ i) = true := by
    have := hfst i; rw [hai] at this; simpa using this.symm
  have hactj : act (σ j) = true := by
    have := hfst j; rw [hbj] at this; simpa using this.symm
  -- ≤ from the sort, ≠ from distinctness of the actives
  have hle : cDst act dst i ≤ cDst act dst j :=
    cSorted_snd_le act dst i j (by simpa [hi, hj] using hab.le) (by rw [hai, hbj])
  have hne : cDst act dst i ≠ cDst act dst j := by
    rw [hsnd i, hsnd j]
    intro heq
    have := hd (σ i) (σ j) hacti hactj heq
    have hij : i = j := σ.injective this
    rw [hi, hj] at hij
    exact absurd (Fin.mk.inj_iff.mp hij) (Nat.ne_of_lt hab)
  exact lt_of_le_of_ne hle hne

/-! ## The partial-load theorem -/

/-- Every wire below the boundary carries a genuine active line's destination —
**the sorter cannot manufacture traffic.** -/
theorem cDst_of_active (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (i : Fin 8)
    (hi : (i : ℕ) < cCount act) : ∃ j, act j = true ∧ cDst act dst i = dst j := by
  obtain ⟨σ, hσ⟩ := runNet_perm batcher8 (cKey act dst)
  have hfst : (ofLex (cSorted act dst i)).1 = (!act (σ i)) := by
    show (ofLex (runNet batcher8 (cKey act dst) i)).1 = _; rw [hσ]; rfl
  have hsnd : cDst act dst i = dst (σ i) := by
    show (ofLex (runNet batcher8 (cKey act dst) i)).2 = _; rw [hσ]; rfl
  have hai : (ofLex (cSorted act dst i)).1 = false :=
    (cSorted_concentrates act dst i).mpr hi
  refine ⟨σ i, ?_, hsnd⟩
  rw [hai] at hfst
  simpa using hfst.symm

/-- The address bound, on the **active** lines only. -/
def ActivesBounded (act : Fin 8 → Bool) (dst : Fin 8 → ℕ) (k : ℕ) : Prop :=
  ∀ i, act i = true → dst i < 2 ^ k

/-- ⭐⭐⭐ **PARTIAL LOAD — THE SWITCH ROUTES ITS ACTUAL OPERATING RANGE.**

With **any** activity pattern, and hypotheses on the **active lines only** —
distinct destinations, each below the address bound — the banyan routes every
active packet without a single internal conflict, each reaching the line its
address names.

⇒ ***Both of the banyan's traffic hypotheses are discharged by the sorter's
ORDER: sortedness by `zeroOne_principle`, and concentration on `Set.Iio n` by
`cSorted_concentrates`.*** **The idle lines are constrained by nothing** — no
sentinel, no encoding, no distinctness — which is precisely what
`composed_switch_of_seam` could not offer and what `bnCSparse`'s five
byte-identical idle frames require.

⚠️ **This is about `cSorted`, the abstract product-order sort. Tying it to the
fabricated element — that convention C's order actually IS `(¬active, dest)` —
is the seam, and it is compiler's, exactly as `hseam` is.** -/
theorem partial_load_selfrouting {k : ℕ} (act : Fin 8 → Bool) (dst : Fin 8 → ℕ)
    (hn : cCount act ≤ 2 ^ k) (hd : ActivesDistinct act dst)
    (hb : ActivesBounded act dst k) :
    (∀ m ≤ k, Set.InjOn (fun s => Banyan.line m s (extendIio 0 (cDst act dst) s))
        (Set.Iio (cCount act))) ∧
      (∀ s < cCount act, Banyan.line k s (extendIio 0 (cDst act dst) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (cDst act dst) s)
        = extendIio 0 (cDst act dst) s) := by
  refine Banyan.banyan_selfrouting hn (cSorted_strictMonoOn act dst hd) ?_
  intro s hs
  have hs8 : s < 8 := lt_of_lt_of_le hs (cCount_le act)
  rw [extendIio_apply _ _ hs8]
  obtain ⟨j, hj, hdj⟩ := cDst_of_active act dst ⟨s, hs8⟩ hs
  rw [hdj]
  exact hb j hj

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
  SaltWorks.Silicon.cCount_le
#audit_axioms SaltWorks.Silicon.cSorted_snd_le
  SaltWorks.Silicon.cSorted_strictMonoOn
#audit_axioms SaltWorks.Silicon.cDst_of_active
  SaltWorks.Silicon.partial_load_selfrouting
end Audit
