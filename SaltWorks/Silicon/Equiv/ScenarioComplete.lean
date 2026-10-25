/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib

import SaltWorks.Silicon.Equiv.FabricRoutes
import SaltWorks.Stack.Perm
import SaltWorks.Tactic.AuditAxioms

/-!
# `allScenarios` COMPLETENESS — the HARDWARE bridge for BB-1

`fabric_routes` is enumerated over 255 concrete lists. To feed a sorter's output
into it, one needs: **any** sorted, distinct, bounded, non-empty destination list
is one of those 255.

⚠️ **Why this is a separate module, and what that costs.** `FabricRoutes.lean` is
deliberately **Mathlib-free** — its decomposition lemmas were chosen as core to
keep leg 2's seam clean, and it therefore has no `Sorted`/`Nodup` vocabulary at
all. Stating this bridge needs Mathlib. **The resolution is a new module that
imports both, not an edit to the Mathlib-free leg** — so the obligation I flagged
at 10:38 costs *a module*, not a leg property. *(Math's 11:43 correction is
right that the banyan LANE has an abstract predicate; my finding was true of
`FabricRoutes.lean` and I stated it too broadly.)*

## Which lane needs this

* **abstract lane** — `Stack.banyan_selfrouting_of_sorts_bool` composes directly
  from `Sorts net Bool`; **this lemma is not needed there.**
* **hardware lane** — `fabric_routes` is the only theorem that speaks about the
  **imported gate netlist** (bits on wires, with payloads). *`banyan_selfrouting`
  concludes about `Banyan.line`, and Bridge.lean says so itself: "nothing about
  payloads".* **A composed claim about the CHIP goes through here.**
-/

namespace SaltWorks.Silicon.Imported

/-- The bitmask of a destination list. -/
def maskOf (ds : List Nat) : Nat := ds.foldr (fun d a => a ||| 2 ^ d) 0

/-- A bit of the mask is set exactly for the members of the list. -/
theorem testBit_maskOf {ds : List Nat} {i : Nat} :
    (maskOf ds).testBit i = true ↔ i ∈ ds := by
  induction ds with
  | nil => simp [maskOf]
  | cons d t ih =>
      simp only [maskOf, List.foldr_cons, Nat.testBit_or, Bool.or_eq_true,
                 Nat.testBit_two_pow, decide_eq_true_eq, List.mem_cons] at *
      rw [ih]
      constructor
      · rintro (h | h)
        · exact Or.inr h
        · exact Or.inl h.symm
      · rintro (rfl | h)
        · exact Or.inr rfl
        · exact Or.inl h

theorem maskOf_lt {ds : List Nat} (hlt : ∀ d ∈ ds, d < 8) : maskOf ds < 256 := by
  induction ds with
  | nil => simp [maskOf]
  | cons d t ih =>
      have hd : d < 8 := hlt d (by simp)
      have ht : ∀ x ∈ t, x < 8 := fun x hx => hlt x (by simp [hx])
      have h1 : maskOf t < 2 ^ 8 := by simpa using ih ht
      have h2 : 2 ^ d < 2 ^ 8 := Nat.pow_lt_pow_right (by norm_num) hd
      have := Nat.or_lt_two_pow (n := 8) h1 h2
      simpa [maskOf] using this

/-! ## The bridge

Any strictly increasing, non-empty list of destinations below 8 is one of the 255
scenarios. Its mask `maskOf ds` is below 256 (`maskOf_lt`), and `testBit_maskOf`
gives `(List.range 8).filter (testBit (maskOf ds))` the same members as `ds`; two
strictly increasing lists with the same members are equal, which is
`SaltWorks.Stack.eq_filter_range_of_pairwise_lt` (`Stack/Perm.lean`).

The **abstract** lane (`banyan_selfrouting_of_sorts_bool`) does not need this. The
**hardware** lane does, because `fabric_routes` is the only theorem that speaks
about the imported gate netlist. -/

/-- **`allScenarios` is complete:** every strictly increasing, non-empty list of
destinations below 8 is one of its 255 members. -/
theorem mem_allScenarios {ds : List Nat}
    (hs : ds.Pairwise (· < ·)) (hne : ds ≠ []) (hlt : ∀ d ∈ ds, d < 8) :
    ds ∈ allScenarios := by
  have hds : ds = (List.range 8).filter (fun i => Nat.testBit (maskOf ds) i) :=
    SaltWorks.Stack.eq_filter_range_of_pairwise_lt hs fun i => by
      rw [testBit_maskOf]
      exact ⟨fun h => ⟨hlt i h, h⟩, fun h => h.2⟩
  unfold allScenarios
  rw [List.mem_filter, List.mem_map]
  exact ⟨⟨maskOf ds, List.mem_range.2 (maskOf_lt hlt), hds.symm⟩, by simpa using hne⟩

#audit_axioms testBit_maskOf maskOf_lt mem_allScenarios

end SaltWorks.Silicon.Imported
