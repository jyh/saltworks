/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Perm
import SaltWorks.Banyan.SelfRouting

/-!
# The seam: Batcher's sorter feeds the banyan's routing theorem

`Banyan/SelfRouting.lean`'s `banyan_selfrouting` is **abstract**: it takes an
arbitrary `dest : ℕ → ℕ` and one hypothesis about the traffic,
`StrictMonoOn dest (Set.Iio n)`. Nothing produced that hypothesis. This module
produces it from a sorting network and closes the seam:

```
banyan_selfrouting_of_sorts_bool :
  Sorts net Bool → n ≤ 2 ^ k → Function.Injective v → (∀ i, v i < 2 ^ k) →
    <the routing conclusion, at dest := extendIio 0 (runNet net v)>
```

so a caller who has **distinct destinations below the address bound** gets the
whole self-routing conclusion — conflict-freedom at every stage, the input
boundary, the output boundary — with no hypothesis about sortedness left to
discharge. The network discharges it.

## Where the content is, and where it is not

**All of the content is in `Stack/Perm.lean`**, in its Step 5. This module is the
application and nothing else: two theorems, each a single term. That split is
deliberate and the reason is an import, not taste — `Banyan/SelfRouting.lean`
opens with `import Mathlib`, the whole library. `Stack/Perm.lean` is the module
whose subject *is* instance hygiene (read its header on `letI` and the unsigned
order); importing a universe of instances into it to reach one theorem would put
that at risk for no mathematical gain. So the bridge lemmas live in the Stack
lane with its curated imports, the full-Mathlib dependency is confined here, and
`Stack/Perm.lean` — which the hub builds — carries everything but these two
applications.

## What is *not* claimed

The destinations are a `Fin n → ℕ` **vector of addresses**, and this module says
nothing about where they come from or about payloads travelling with them.
`banyan_selfrouting`'s conclusion is about the `line` function — which link each
source occupies at each stage — and that is exactly as much as is claimed here.
-/

namespace SaltWorks.Stack

variable {n : ℕ}

/-- ⭐ **THE COMPOSED THEOREM.** Any comparator network that passes
`ZeroOne.lean`'s Boolean check, run on **distinct** destinations all below
`2 ^ k`, produces a destination assignment the banyan routes without a single
internal conflict.

The three conjuncts are `banyan_selfrouting`'s, unchanged: every stage boundary
`m ≤ k` has distinct occupied lines; at the input boundary source `s` sits on
line `s`; at the output boundary it sits on its destination.

Note which hypotheses survive to the caller — `Function.Injective v` and the
address bound. **Sortedness is gone**, and that is the point of the node: it was
discharged by the network. -/
theorem banyan_selfrouting_of_sorts_bool {k : ℕ} {net : Network n} (hb : Sorts net Bool)
    (hn : n ≤ 2 ^ k) {v : Fin n → ℕ} (hi : Function.Injective v)
    (hlt : ∀ i, v i < 2 ^ k) :
    (∀ m ≤ k, Set.InjOn (fun s => Banyan.line m s (extendIio 0 (runNet net v) s)) (Set.Iio n)) ∧
      (∀ s < n, Banyan.line k s (extendIio 0 (runNet net v) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (runNet net v) s) = extendIio 0 (runNet net v) s) :=
  Banyan.banyan_selfrouting hn (banyanHyps_of_sorts_bool hb hi hlt).1
    (banyanHyps_of_sorts_bool hb hi hlt).2

/-- ⭐ **BATCHER'S 8-WIRE NETWORK ROUTES THE BANYAN.** The campaign's `n`, with
`hn : 8 ≤ 2 ^ k` the only remaining side condition (it holds from `k ≥ 3`, which
is the smallest banyan that has eight inputs at all). -/
theorem batcher8_banyan_selfrouting {k : ℕ} (hn : 8 ≤ 2 ^ k) {v : Fin 8 → ℕ}
    (hi : Function.Injective v) (hlt : ∀ i, v i < 2 ^ k) :
    (∀ m ≤ k,
        Set.InjOn (fun s => Banyan.line m s (extendIio 0 (runNet batcher8 v) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line k s (extendIio 0 (runNet batcher8 v) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (runNet batcher8 v) s)
        = extendIio 0 (runNet batcher8 v) s) :=
  banyan_selfrouting_of_sorts_bool batcher8_sorts_bool hn hi hlt

/-- The `Nodup` entry point, for a caller holding the list-side distinctness
statement (`runNet_ofFn_nodup`'s shape, and the BB-1 addendum's KB3). -/
theorem batcher8_banyan_selfrouting_of_nodup {k : ℕ} (hn : 8 ≤ 2 ^ k) {v : Fin 8 → ℕ}
    (hi : (List.ofFn v).Nodup) (hlt : ∀ i, v i < 2 ^ k) :
    (∀ m ≤ k,
        Set.InjOn (fun s => Banyan.line m s (extendIio 0 (runNet batcher8 v) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line k s (extendIio 0 (runNet batcher8 v) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (runNet batcher8 v) s)
        = extendIio 0 (runNet batcher8 v) s) :=
  batcher8_banyan_selfrouting hn (List.nodup_ofFn.mp hi) hlt

/-! ### Non-vacuity: the routing conclusion is not trivially true

`Stack/Perm.lean`'s controls show the *hypothesis* is not free. This one shows
the *conclusion* is not free either: `no_conflict`'s `Set.InjOn` fails outright
for a destination map with a repeat, so `banyan_selfrouting` is not a theorem
about a predicate that holds of everything.

The witness is the constant map at stage `m = 0`, where `line 0 s d = d`: two
distinct sources land on one line. -/
theorem banyan_conflict_of_const :
    ¬ Set.InjOn (fun s => Banyan.line 0 s ((fun _ => 0 : ℕ → ℕ) s)) (Set.Iio 2) := by
  intro h
  have := h (Set.mem_Iio.2 (by omega : (0 : ℕ) < 2)) (Set.mem_Iio.2 (by omega : (1 : ℕ) < 2))
    (by simp [Banyan.line])
  omega

/-! ## Axiom audit -/

section Audit
open Salt.Tactic

#audit_axioms banyan_selfrouting_of_sorts_bool batcher8_banyan_selfrouting
#audit_axioms batcher8_banyan_selfrouting_of_nodup banyan_conflict_of_const

end Audit

end SaltWorks.Stack
