/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib.Logic.Equiv.Basic
import Mathlib.Data.List.FinRange
import Mathlib.Data.List.OfFn
import Mathlib.Data.Multiset.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Monotone.Defs
import Mathlib.Order.Interval.Set.Defs
import SaltWorks.Stack.ZeroOne
import SaltWorks.Stack.Spec

/-!
# Comparator networks PERMUTE — the other half of `SortsTo`

`SaltWorks/Stack/ZeroOne.lean` proves that Batcher's network **sorts** and says
nothing about **permutation**. Two consumers need the missing half and one proof
serves both:

* the software lane — `Stack/Spec.lean`'s `SortsTo i o := SortedW o ∧ PermW i o`,
  whose `Perm` conjunct was unreachable;
* the hardware lane (BB-1) — a hardware Batcher feeding the banyan tile, where
  "every payload arrives" *is* permutation of the destination multiset.

## The form that was chosen, and why

The core theorem is the **`Equiv.Perm` form**

```
runNet_perm : ∃ σ : Equiv.Perm (Fin n), runNet net v = v ∘ σ
```

and not the multiset or `List.Perm` form, for one reason: it is the only one of
the three that **composes**. `runNet` is a `foldl`, so the proof is an induction
in which the tail's conclusion must be applied to a *different* input — the
already-comparator'd `applyComp c v`. On the `Equiv` form that step is
`(v ∘ σ) ∘ τ = v ∘ (τ.trans σ)`, an equation between functions closed by `rfl`.
On a multiset or `List.Perm` form there is no such handle: `Perm (l ...) (l ...)`
gives back no rearrangement to compose with, and the induction stalls at exactly
the cons step. The weaker forms are all one line **downstream** of this one, so
nothing is lost by taking the strongest statement first.

`runNet_perm` also carries data the multiset form throws away, and BB-1 needs
that data: `σ` is the routing map, `runNet_injective` is distinctness of
destinations, and `runNet_ofFn_nodup` is the same fact on the list side.

## What mathlib supplied

* `Equiv.Perm.ofFn_comp_perm` (`Mathlib/Data/List/FinRange.lean:73`) —
  `ofFn (f ∘ σ) ~ ofFn f`. This is the entire `Equiv`-to-`List.Perm` bridge; it
  was found, not proved.
* `List.pairwise_ofFn` (`Mathlib/Data/List/OfFn.lean:119`) — the `IsSorted` ↔
  `List.Pairwise` bridge across the `Fin n → α` / `List` carrier boundary.
* `List.nodup_ofFn`, `List.Perm.nodup`, `Multiset.coe_eq_coe`, `Equiv.swap` and
  its three `apply` lemmas, `LinearOrder.lift'`.

mathlib still has **no** sorting-network material, so `applyComp_perm` and
`runNet_perm` are new here, as `zeroOne_principle` was.

## ⚠️ THE ORDER-INSTANCE FINDING (read before instantiating at `Word`)

`Stack/Spec.lean` deliberately registers **no** `LinearOrder Word`: `wle` is the
signed `BitVec.toInt` order carried as relation-explicit `IsLinearOrder` classes,
precisely so that `≤` on `BitVec 32` keeps meaning core's **unsigned** order.
But `runNet`, `IsSorted` and `Sorts` are all stated at `[LinearOrder α]` and use
that instance's `min`/`max`. So `Sorts batcher8 Word` **does not elaborate**, and
the two modules do not compose on their own.

They are made to compose here without weakening S1's fence:

* `wordSignedOrder : LinearOrder Word` is an `abbrev`, **not an `instance`**, and
  is never given `local instance` status either — so no `≤` anywhere, in this
  file or downstream, changes meaning. A consumer hands the bundle over
  explicitly, which is what S1's design asks for.
* `runNetW net v` is `@runNet _ Word wordSignedOrder net v`: the network run
  **with the signed comparator**, with the instance visible in the term.
* Nothing in the `Word` section is written with `≤` notation. The single place
  where the bundle's `≤` must be recognised as `wle` is `wordSignedOrder_le`, and
  it is `Iff.rfl` — `LinearOrder.lift'` sets `le := fun a b ↦ f a ≤ f b`, and
  `wle a b` is by definition `a.toInt ≤ b.toInt`.

### ⚠️ AND THE OBVIOUS SHORTCUT IS A SILENT WRONG ANSWER

The natural way to write this section is `letI := wordSignedOrder` and then plain
`≤` notation. **That does not do what it looks like.** Measured, not assumed:
with the bundle in scope as a local instance, `fun (a b : Word) => a ≤ b`
elaborates to

```
@LE.le Word (@instLEBitVec 32) a b
```

— core's **UNSIGNED** order. Typeclass search answers the `LE Word` goal from
`BitVec`'s own direct instance rather than walking down `LinearOrder Word →
PartialOrder → Preorder → LE` from the local one, so the local instance is simply
not consulted. The elaboration is silent and the resulting statement is wrong.
`letI_le_is_still_unsigned` below pins this as a kernel certificate; it is why
every `Word`-side statement here is written with an explicit instance argument
and no `≤`.

The bundle's `min`/`max` unfold to `if a.toInt ≤ b.toInt then a else b` and its
mirror — a select on the negation of `SLT`, which is what Slice A's datapath can
actually build. That is not a coincidence to be relied on silently, so it is
pinned by `wordSignedOrder_min` / `wordSignedOrder_max`.

**Verdict:** `SortsTo` for `batcher8` at S1's signed order is **reachable and
reached** — `batcher8_sortsTo_word`. What is *not* reachable, and should not be,
is `SortsTo` from `batcher8_sorts Word` with an inferred instance: there is no
instance to infer, and installing one would put the signed and unsigned orders
behind the same notation.

## ⭐ THE `StrictMonoOn` BRIDGE — why the two halves are one hypothesis

`Banyan/SelfRouting.lean`'s routing theorem takes exactly one hypothesis about
the traffic: `StrictMonoOn dest (Set.Iio n)`. That name hides **two** conjuncts,
and this campaign proves them in two different modules:

* **monotone** — `ZeroOne.lean`'s `IsSorted`, which is *non-strict*
  (`∀ i j, i ≤ j → v i ≤ v j`);
* **strict** — which cannot come from sortedness at all. It comes from
  `runNet_injective` above, i.e. from the permutation half.

So the bridge is not bookkeeping: it is the place where this module's theorem and
`ZeroOne.lean`'s theorem are *both* needed and neither suffices.
`dup_not_strictMonoOn` below is the proof that the second half is load-bearing —
a sorted vector with a repeat provably fails `StrictMonoOn`.

The second half of the bridge is a **carrier** change. `runNet` produces
`Fin n → α`; the routing theorem wants `ℕ → ℕ`. `extendIio d v` crosses that gap
by agreeing with `v` below `n` and returning the junk value `d` above it, and
`Set.Iio n` is precisely the region where the junk is not consulted. Both halves
are stated at general `n` and general `α`; nothing here is special to `ℕ`, which
enters only at the routing theorem's own carrier.

## Non-vacuity

`applyDup_sorts` / `applyDup_not_perm` are the controls, and they are the
argument for this node's existence: `applyDup` is `applyComp` with the `max`
changed to `min` — a network element that **still sorts** (its output is
constant) and **provably does not permute** (it duplicates one value and drops
the other). Sortedness alone therefore does not imply the permutation half, so
the theorems below are not restatements of `ZeroOne.lean`. `batcher8_word_run`
pins a concrete signed run against its literal output, and
`batcher8_word_run_not_unsigned` shows that output is *not* unsigned-sorted, so
the `Word` results are demonstrably about the signed order.
-/

namespace SaltWorks.Stack

universe u

variable {n : ℕ} {α : Type u}

/-! ## Step 1 — one comparator is a permutation

A comparator either leaves its two wires alone or swaps them; which of the two is
decided by the input, but *both* are permutations, so the existential below is
uniform in `v` even though the witness is not. -/

/-- **One compare-exchange step permutes the wires.** The witness is `Equiv.refl`
when the pair is already in order and `Equiv.swap c.1 c.2` when it is not.

`c.1 = c.2` needs no separate case: that comparator is the identity, and the
first branch is the one taken (`v c.1 ≤ v c.1` always holds). -/
theorem applyComp_perm [LinearOrder α] (c : Comparator n) (v : Fin n → α) :
    ∃ σ : Equiv.Perm (Fin n), applyComp c v = v ∘ σ := by
  rcases le_total (v c.1) (v c.2) with h | h
  · refine ⟨Equiv.refl _, ?_⟩
    funext i
    simp only [applyComp, Function.comp_apply, Equiv.refl_apply]
    split
    · rename_i hi; rw [hi, min_eq_left h]
    · split
      · rename_i hi; rw [hi, max_eq_right h]
      · rfl
  · refine ⟨Equiv.swap c.1 c.2, ?_⟩
    funext i
    simp only [applyComp, Function.comp_apply]
    split
    · rename_i hi; rw [hi, Equiv.swap_apply_left, min_eq_right h]
    · split
      · rename_i hi hj; rw [hj, Equiv.swap_apply_right, max_eq_left h]
      · rename_i hi hj; rw [Equiv.swap_apply_of_ne_of_ne hi hj]

/-- ⭐ **COMPARATOR NETWORKS PERMUTE.** Running any network on any input rewires
it by *some* permutation of `Fin n` — no value is created, duplicated or lost.

Stated at arbitrary `n`, arbitrary `net`, and arbitrary `α : Type u` in an
arbitrary universe, matching `zeroOne_principle` exactly; nothing here is special
to `Bool`, to `BitVec 32`, or to `Type 0`.

The induction generalises over the input because the tail of the network is run
on `applyComp c v`, not on `v`. The cons step is where the `Equiv` form earns its
place: `(v ∘ σ) ∘ τ = v ∘ (τ.trans σ)` by `rfl`. Note the order — `Equiv.trans`
applies its *first* argument first, and the head comparator's `σ` is applied to
the *result* of the tail's `τ`, so it is `τ.trans σ` and not `σ.trans τ`. -/
theorem runNet_perm [LinearOrder α] (net : Network n) (v : Fin n → α) :
    ∃ σ : Equiv.Perm (Fin n), runNet net v = v ∘ σ := by
  induction net generalizing v with
  | nil => exact ⟨Equiv.refl _, rfl⟩
  | cons c cs ih =>
      obtain ⟨σ, hσ⟩ := applyComp_perm c v
      obtain ⟨τ, hτ⟩ := ih (applyComp c v)
      refine ⟨τ.trans σ, ?_⟩
      rw [runNet_cons, hτ, hσ]
      rfl

/-! ## Step 2 — the corollaries the two lanes consume

`List.ofFn` is the bridge from the network's `Fin n → α` carrier to the `List`
carrier `Spec.lean` speaks. -/

/-- **The `List.Perm` form** — the output list is a permutation of the input
list. This is the shape `Spec.lean`'s `PermW` *is*. -/
theorem runNet_ofFn_perm [LinearOrder α] (net : Network n) (v : Fin n → α) :
    (List.ofFn (runNet net v)).Perm (List.ofFn v) := by
  obtain ⟨σ, hσ⟩ := runNet_perm net v
  rw [hσ]
  exact σ.ofFn_comp_perm v

/-- The same, oriented input-to-output — the direction `PermW input output`
wants. Both directions are kept because `List.Perm` is symmetric but `rw` is
not, and a consumer should never have to insert a `.symm` to meet the spec. -/
theorem ofFn_perm_runNet [LinearOrder α] (net : Network n) (v : Fin n → α) :
    (List.ofFn v).Perm (List.ofFn (runNet net v)) :=
  (runNet_ofFn_perm net v).symm

/-- **The multiset form** — the hardware lane's statement: the multiset of values
on the wires is unchanged, i.e. every payload arrives. -/
theorem runNet_ofFn_multiset [LinearOrder α] (net : Network n) (v : Fin n → α) :
    (↑(List.ofFn (runNet net v)) : Multiset α) = ↑(List.ofFn v) :=
  Multiset.coe_eq_coe.mpr (runNet_ofFn_perm net v)

/-- **`Nodup` preservation** — a permutation preserves distinctness, so the
output list is duplicate-free whenever the input list is.

This is half of the BB-1 addendum's **KB3** (distinct destinations), and it
settles *which* half: distinctness of the output is a theorem, not an extra
obligation, so the exclusion belongs on the **input**. -/
theorem runNet_ofFn_nodup [LinearOrder α] (net : Network n) (v : Fin n → α)
    (h : (List.ofFn v).Nodup) : (List.ofFn (runNet net v)).Nodup :=
  (ofFn_perm_runNet net v).nodup h

/-- The same fact on the function carrier: a network preserves injectivity of the
wire-to-value assignment. Stated separately because BB-1's destinations are a
function `Fin n → Fin n`, not a list. -/
theorem runNet_injective [LinearOrder α] (net : Network n) {v : Fin n → α}
    (h : Function.Injective v) : Function.Injective (runNet net v) := by
  obtain ⟨σ, hσ⟩ := runNet_perm net v
  rw [hσ]
  exact h.comp σ.injective

/-! ## Step 3 — the combined statement

`IsSorted` lives on `Fin n → α`; `SortedW` lives on `List Word`. One bridge
lemma crosses the carrier boundary and everything else is assembly. -/

/-- The carrier bridge: `IsSorted` on `Fin n → α` is `List.Pairwise (· ≤ ·)` on
`List.ofFn`. The two directions differ only in how the diagonal is handled —
`IsSorted` says `i ≤ j`, `Pairwise` says `i < j`, and reflexivity closes the
gap. -/
theorem isSorted_iff_pairwise_ofFn [Preorder α] (v : Fin n → α) :
    IsSorted v ↔ (List.ofFn v).Pairwise (· ≤ ·) := by
  rw [List.pairwise_ofFn]
  constructor
  · exact fun h _ _ hij => h _ _ hij.le
  · intro h i j hij
    rcases lt_or_eq_of_le hij with h' | h'
    · exact h h'
    · subst h'; exact le_refl _

/-- ⭐ **SORTED **AND** A PERMUTATION**, for any network that passes the Boolean
check, at any linearly ordered carrier in any universe. This is `SortsTo`'s shape
with `wle` generalised to the instance's `≤` and `List Word` to `List α`. -/
theorem sortsTo_ofFn_of_sorts_bool {net : Network n} (hb : Sorts net Bool)
    (α : Type u) [LinearOrder α] (v : Fin n → α) :
    (List.ofFn (runNet net v)).Pairwise (· ≤ ·) ∧
      (List.ofFn v).Perm (List.ofFn (runNet net v)) :=
  ⟨(isSorted_iff_pairwise_ofFn _).mp (zeroOne_principle hb v), ofFn_perm_runNet net v⟩

/-- Batcher's 8-wire network: sorted and a permutation, over every linear
order. -/
theorem batcher8_sorts_perm (α : Type u) [LinearOrder α] (v : Fin 8 → α) :
    (List.ofFn (runNet batcher8 v)).Pairwise (· ≤ ·) ∧
      (List.ofFn v).Perm (List.ofFn (runNet batcher8 v)) :=
  sortsTo_ofFn_of_sorts_bool batcher8_sorts_bool α v

/-- The 4-wire network, likewise. -/
theorem batcher4_sorts_perm (α : Type u) [LinearOrder α] (v : Fin 4 → α) :
    (List.ofFn (runNet batcher4 v)).Pairwise (· ≤ ·) ∧
      (List.ofFn v).Perm (List.ofFn (runNet batcher4 v)) :=
  sortsTo_ofFn_of_sorts_bool batcher4_sorts_bool α v

/-- A relation-generic repackaging of the sortedness half, used below to land on
`SortedW` (which is `Pairwise wle`, not `Pairwise (· ≤ ·)`) without ever writing
`≤` at `Word`. The hypothesis `hr` is where the caller certifies that the bundle
it handed over is the order it meant. -/
theorem pairwise_ofFn_runNet {net : Network n} (hb : Sorts net Bool)
    (α : Type u) [LinearOrder α] {r : α → α → Prop} (hr : ∀ {a b : α}, a ≤ b → r a b)
    (v : Fin n → α) : (List.ofFn (runNet net v)).Pairwise r :=
  List.pairwise_ofFn.mpr fun _ _ hij => hr (zeroOne_principle hb v _ _ hij.le)

/-! ## Step 4 — the signed order on machine words, handed over explicitly

Read the module header's order-instance finding before touching this section.
`wordSignedOrder` is a `def` and stays one: it is never an `instance`, not even a
`local` one, so `≤` on `BitVec 32` continues to mean core's unsigned order
everywhere, exactly as `Spec.lean` requires. -/

/-- **The signed order on `Word` as a `LinearOrder` bundle** — an `abbrev`
(Lean requires class-typed definitions to be reducible), and deliberately **not**
an `instance`. Reducible is not the same as registered: typeclass search never
returns this, so `≤` on `BitVec 32` is untouched.

`LinearOrder.lift'` pulls `Int`'s linear order back along `BitVec.toInt`, which
is injective (`BitVec.toInt_inj`), so the `≤` of this bundle is *definitionally*
`fun a b => a.toInt ≤ b.toInt`, i.e. `wle`. Nothing is reproved. -/
abbrev wordSignedOrder : LinearOrder Word :=
  LinearOrder.lift' BitVec.toInt fun _ _ h => BitVec.toInt_inj.mp h

/-- **The bundle's `≤` IS S1's `wle`**, by `Iff.rfl`. The instance is spelled out
through its projection chain rather than left to notation, for the reason the
next theorem pins. If someone rebuilds `wordSignedOrder` from a different `f`,
this breaks. -/
theorem wordSignedOrder_le (a b : Word) :
    @LE.le Word (@Preorder.toLE Word (@PartialOrder.toPreorder Word
      (@LinearOrder.toPartialOrder Word wordSignedOrder))) a b ↔ wle a b := Iff.rfl

/-- ⚠️ **THE SHORTCUT, PINNED AS FALSE.** `letI := wordSignedOrder` does **not**
make `≤` mean the signed order: typeclass search answers `LE Word` from
`instLEBitVec` directly and never consults the local bundle.

The certificate: signed, `-1 ≤ 1` **holds** (`Spec.wlt_neg_one_one`). This
theorem says the `≤` that a `letI` block actually elaborates rejects that pair —
so that `≤` is the unsigned one. If a future toolchain fixes the resolution
order, this theorem fails the build and the module header's warning is retired
deliberately rather than rotting. -/
theorem letI_le_is_still_unsigned :
    ¬ (letI := wordSignedOrder; ((-1 : Word) ≤ (1 : Word))) := by
  decide +kernel

/-- The bundle's `min` is a select on the negation of `SLT` — which is the only
comparison Slice A can build (`Spec.slt_get_eq_one_iff`). Pinned rather than
assumed, because S3(b)'s refinement will read the network's `min` as a datapath
and would otherwise be matching against an unexamined `LinearOrder.lift'`
field. -/
theorem wordSignedOrder_min (a b : Word) :
    @min Word (@LinearOrder.toMin Word wordSignedOrder) a b =
      if a.toInt ≤ b.toInt then a else b := rfl

/-- The `max` companion. -/
theorem wordSignedOrder_max (a b : Word) :
    @max Word (@LinearOrder.toMax Word wordSignedOrder) a b =
      if a.toInt ≤ b.toInt then b else a := rfl

/-- **A network run on machine words under the SIGNED comparator.** The instance
is applied by hand, so the order in force is visible in the term rather than
inferred — there is no `LinearOrder Word` to infer. -/
def runNetW (net : Network n) (v : Fin n → Word) : Fin n → Word :=
  @runNet n Word wordSignedOrder net v

/-- The sortedness half at `Word`, landing directly on `SortedW`. -/
theorem sortedW_ofFn_runNetW {net : Network n} (hb : Sorts net Bool) (v : Fin n → Word) :
    SortedW (List.ofFn (runNetW net v)) :=
  @pairwise_ofFn_runNet n net hb Word wordSignedOrder wle (fun h => h) v

/-- The permutation half at `Word`, landing directly on `PermW`. -/
theorem permW_ofFn_runNetW (net : Network n) (v : Fin n → Word) :
    PermW (List.ofFn v) (List.ofFn (runNetW net v)) :=
  @ofFn_perm_runNet n Word wordSignedOrder net v

/-- ⭐ **THE DELIVERABLE.** Any network that passes `ZeroOne.lean`'s Boolean
check meets S1's spec on machine words under the signed order. -/
theorem sortsTo_ofFn_runNetW {net : Network n} (hb : Sorts net Bool) (v : Fin n → Word) :
    SortsTo (List.ofFn v) (List.ofFn (runNetW net v)) :=
  ⟨sortedW_ofFn_runNetW hb v, permW_ofFn_runNetW net v⟩

/-- ⭐ **`SortsTo` FOR BATCHER'S 8-WIRE NETWORK AT S1'S SIGNED ORDER.** The gap
this node existed to close, closed: `Spec.lean`'s spec is met by
`ZeroOne.lean`'s network. -/
theorem batcher8_sortsTo_word (v : Fin 8 → Word) :
    SortsTo (List.ofFn v) (List.ofFn (runNetW batcher8 v)) :=
  sortsTo_ofFn_runNetW batcher8_sorts_bool v

/-- The 4-wire network, likewise — the first code-generation target. -/
theorem batcher4_sortsTo_word (v : Fin 4 → Word) :
    SortsTo (List.ofFn v) (List.ofFn (runNetW batcher4 v)) :=
  sortsTo_ofFn_runNetW batcher4_sorts_bool v

/-- The fixed-`n` (`Vector`) form, which is where the machine keeps its data.
`SortsToV` is `SortsTo` on `Vector.toList`, and `Vector.toList_ofFn` /
`Vector.ofFn_getElem` do the whole conversion. -/
theorem batcher8_sortsToV_word (v : Vector Word 8) :
    SortsToV v (Vector.ofFn (runNetW batcher8 fun i => v[i.val])) := by
  have hv : List.ofFn (fun i : Fin 8 => v[i.val]) = v.toList := by
    rw [← Vector.toList_ofFn, Vector.ofFn_getElem]
  show SortsTo v.toList _
  rw [Vector.toList_ofFn, ← hv]
  exact batcher8_sortsTo_word _

/-! ### Non-vacuity controls

The repo's rule: a green `∀` is not evidence until something adjacent is shown to
break. -/

/-- **The mutation.** `applyComp` with its `max` changed to `min`: a network
element that writes the *smaller* value to both slots. -/
def applyDup [LinearOrder α] (c : Comparator n) (v : Fin n → α) : Fin n → α :=
  fun i =>
    if i = c.1 then min (v c.1) (v c.2)
    else if i = c.2 then min (v c.1) (v c.2)
    else v i

/-- ⭐ **CONTROL, half one: the mutation still SORTS.** Its output is constant,
and a constant vector is sorted. So `ZeroOne.lean`'s conclusion survives the
mutation intact. -/
theorem applyDup_sorts : ∀ v : Fin 2 → Bool, IsSorted (applyDup ((0, 1) : Comparator 2) v) := by
  decide

/-- ⭐ **CONTROL, half two: the mutation provably does NOT permute.** It drops
`true` and duplicates `false`.

Together with `applyDup_sorts` this is the argument for this node: *sortedness
does not imply the permutation half*, so `runNet_perm` and everything downstream
of it is new content and not a repackaging of `batcher8_sorts`. -/
theorem applyDup_not_perm :
    ¬ (List.ofFn (applyDup ((0, 1) : Comparator 2) ![false, true])).Perm
        (List.ofFn (![false, true] : Fin 2 → Bool)) := by
  decide

/-- **CONTROL: the permutation is not the identity.** Batcher's network really
moves values, so `runNet_perm`'s witness is not trivially `Equiv.refl` and the
theorem is not a restatement of `runNet net v = v`. -/
theorem batcher8_perm_not_refl :
    runNet batcher8 ![true, false, false, false, false, false, false, false]
      ≠ (![true, false, false, false, false, false, false, false] : Fin 8 → Bool) := by
  decide +kernel

/-- **CONTROL: a concrete signed run, pinned against its literal output.** The
input mixes negatives with positives, so the output would be wrong under the
unsigned order — see the next theorem. Kernel-reduced, `decide +kernel`. -/
theorem batcher8_word_run :
    List.ofFn (runNetW batcher8 ![3, -1, 7, 0, -5, 2, 9, -2]) =
      [(-5 : Word), -2, -1, 0, 2, 3, 7, 9] := by
  decide +kernel

/-- **CONTROL: that output is NOT unsigned-sorted.** `-5` is `0xFFFFFFFB`, the
*largest* word unsigned. So `runNetW` demonstrably computes with the signed
comparator, and `batcher8_sortsTo_word` is a statement about `wle` rather than
about `BitVec`'s default `≤`. This is `Spec.sortedW_signed_not_unsigned` carried
onto an actual network run. -/
theorem batcher8_word_run_not_unsigned :
    ¬ List.Pairwise (· ≤ · : Word → Word → Prop)
        (List.ofFn (runNetW batcher8 ![3, -1, 7, 0, -5, 2, 9, -2])) := by
  decide +kernel

/-! ## Step 5 — the `StrictMonoOn` bridge

Sorted (`ZeroOne.lean`) **and** distinct (Step 2 above) ⇒ strictly monotone; then
across the carrier boundary `Fin n → α` ↝ `ℕ → α`, on `Set.Iio n`. That composite
is the single hypothesis `Banyan/SelfRouting.lean`'s routing theorem takes.

The module header explains why this is not bookkeeping. The short version: the
`≤` in `IsSorted` is non-strict by design — a comparator network sorts
multisets, and a repeated value stays repeated — so the `<` the router needs can
only come from injectivity, which is a *permutation* fact. -/

/-- **The carrier bridge, as data.** `extendIio d v` is the wire-indexed vector
`v` seen as a function on all of `ℕ`: it agrees with `v` below `n` and returns
the junk value `d` at and above `n`.

The junk is never consulted by anything downstream, because every statement about
this function is relativised to `Set.Iio n`. Stated with an explicit `d` rather
than an `Inhabited α` so that the caller can see which value it is handing over —
the routing lane passes `0`. -/
def extendIio (d : α) (v : Fin n → α) : ℕ → α :=
  fun s => if h : s < n then v ⟨s, h⟩ else d

/-- Below `n`, `extendIio` is `v`. -/
theorem extendIio_apply (d : α) (v : Fin n → α) {s : ℕ} (h : s < n) :
    extendIio d v s = v ⟨s, h⟩ := dif_pos h

/-- At and above `n`, `extendIio` is the junk value. Kept so that a consumer can
see the junk is reachable — this function is *not* secretly total. -/
theorem extendIio_of_le (d : α) (v : Fin n → α) {s : ℕ} (h : n ≤ s) :
    extendIio d v s = d := dif_neg (Nat.not_lt.mpr h)

/-- ⭐ **SORTED **AND** DISTINCT ⇒ STRICTLY MONOTONE**, on the network's own
carrier. This is the whole content of the bridge, and it is one mathlib lemma
wide: `IsSorted v` *is* `Monotone v` definitionally on `Fin n`, so
`Monotone.strictMono_of_injective` applies with nothing to prove.

`PartialOrder` and not `Preorder`, because `≤` plus `≠` gives `<` only when the
order is antisymmetric. -/
theorem strictMono_of_isSorted_of_injective [PartialOrder α] {v : Fin n → α}
    (hs : IsSorted v) (hi : Function.Injective v) : StrictMono v :=
  Monotone.strictMono_of_injective (fun _ _ h => hs _ _ h) hi

/-- The carrier half: a strictly monotone vector extends to a function on `ℕ`
that is strictly monotone **on the initial segment** `Set.Iio n`. Not on all of
`ℕ` — the junk value above `n` breaks that, and `Set.Iio n` is exactly the region
the routing theorem quantifies over. -/
theorem strictMonoOn_extendIio [Preorder α] {v : Fin n → α} (h : StrictMono v) (d : α) :
    StrictMonoOn (extendIio d v) (Set.Iio n) := by
  intro a ha b hb hab
  rw [extendIio_apply d v (Set.mem_Iio.mp ha), extendIio_apply d v (Set.mem_Iio.mp hb)]
  exact h (Fin.mk_lt_mk.mpr hab)

/-- The two halves composed: sorted + injective ⇒ `StrictMonoOn` on `Set.Iio n`.
Still at general `n` and general `α`. -/
theorem strictMonoOn_extendIio_of_isSorted [PartialOrder α] {v : Fin n → α}
    (hs : IsSorted v) (hi : Function.Injective v) (d : α) :
    StrictMonoOn (extendIio d v) (Set.Iio n) :=
  strictMonoOn_extendIio (strictMono_of_isSorted_of_injective hs hi) d

/-- **A network preserves every pointwise property of its wires.** The values on
the output wires are the values on the input wires, rearranged, so any `p` that
held of all of them still does. This is `runNet_perm` used as a transport lemma
rather than as a permutation statement; the routing lane consumes it at
`p := (· < 2 ^ k)`, which is the address-width side condition. -/
theorem runNet_forall [LinearOrder α] {p : α → Prop} (net : Network n) {v : Fin n → α}
    (h : ∀ i, p (v i)) (i : Fin n) : p (runNet net v i) := by
  obtain ⟨σ, hσ⟩ := runNet_perm net v
  rw [hσ]
  exact h (σ i)

/-- ⭐ **THE BRIDGE AT THE NETWORK.** Feed any network that passes `ZeroOne.lean`'s
Boolean check an input with **distinct** entries, and the extended output is
`StrictMonoOn` on `Set.Iio n` — the routing theorem's hypothesis, produced.

Both landed halves are consumed here and neither is optional: `zeroOne_principle`
for sortedness, `runNet_injective` for strictness. -/
theorem strictMonoOn_extendIio_runNet {net : Network n} (hb : Sorts net Bool)
    [LinearOrder α] {v : Fin n → α} (hi : Function.Injective v) (d : α) :
    StrictMonoOn (extendIio d (runNet net v)) (Set.Iio n) :=
  strictMonoOn_extendIio_of_isSorted (zeroOne_principle hb v) (runNet_injective net hi) d

/-- The same with the hypothesis in `Nodup` form, which is the shape
`runNet_ofFn_nodup` and the BB-1 addendum's KB3 speak. `List.nodup_ofFn` is the
translation and it is an `Iff`, so nothing is lost either way. -/
theorem strictMonoOn_extendIio_runNet_of_nodup {net : Network n} (hb : Sorts net Bool)
    [LinearOrder α] {v : Fin n → α} (hi : (List.ofFn v).Nodup) (d : α) :
    StrictMonoOn (extendIio d (runNet net v)) (Set.Iio n) :=
  strictMonoOn_extendIio_runNet hb (List.nodup_ofFn.mp hi) d

/-- ⭐ **EVERYTHING THE ROUTING THEOREM NEEDS EXCEPT `n ≤ 2 ^ k`.** Distinct
destinations, all below the address bound `B`, sorted by the network: the output
is strictly monotone on the initial segment and still below `B` there.

`B` is left general rather than fixed at `2 ^ k` — the bound plays no arithmetic
role on this side of the seam, and the router instantiates it. The junk value is
`0`, and `extendIio_of_le` says where it lives; the second conjunct is guarded by
`s < n` and never sees it. -/
theorem banyanHyps_of_sorts_bool {net : Network n} (hb : Sorts net Bool) {B : ℕ}
    {v : Fin n → ℕ} (hi : Function.Injective v) (hlt : ∀ i, v i < B) :
    StrictMonoOn (extendIio 0 (runNet net v)) (Set.Iio n) ∧
      ∀ s < n, extendIio 0 (runNet net v) s < B :=
  ⟨strictMonoOn_extendIio_runNet hb hi 0, fun s hs => by
    rw [extendIio_apply (0 : ℕ) _ hs]
    exact runNet_forall (p := fun x => x < B) net hlt _⟩

/-- Batcher's 8-wire network, the campaign's `n`: distinct destinations below `B`
in, the routing theorem's traffic hypothesis out. -/
theorem batcher8_banyanHyps {B : ℕ} {v : Fin 8 → ℕ} (hi : Function.Injective v)
    (hlt : ∀ i, v i < B) :
    StrictMonoOn (extendIio 0 (runNet batcher8 v)) (Set.Iio 8) ∧
      ∀ s < 8, extendIio 0 (runNet batcher8 v) s < B :=
  banyanHyps_of_sorts_bool batcher8_sorts_bool hi hlt

/-! ### Non-vacuity controls for the bridge

The repo's law, applied to a hypothesis rather than to a network: the mutated
input must make the goal **false**, not merely unreachable. Both controls below
are proofs of `¬ StrictMonoOn …`, so each names a pair that breaks it. -/

/-- **CONTROL, half one: the input really is sorted.** `![1, 1]` satisfies
`IsSorted` — so what fails next is not sortedness. -/
theorem dup_isSorted : IsSorted (![1, 1] : Fin 2 → ℕ) := by decide

/-- ⭐ **CONTROL, half two: and it provably FAILS `StrictMonoOn`.** Together with
`dup_isSorted` this is the argument that `Function.Injective` is load-bearing in
`strictMonoOn_extendIio_runNet` and not decoration: sortedness alone does not
give the router its hypothesis, so `ZeroOne.lean` on its own cannot reach it. -/
theorem dup_not_strictMonoOn :
    ¬ StrictMonoOn (extendIio 0 (![1, 1] : Fin 2 → ℕ)) (Set.Iio 2) := by
  intro h
  have h01 := h (Set.mem_Iio.2 (by omega : (0 : ℕ) < 2))
    (Set.mem_Iio.2 (by omega : (1 : ℕ) < 2)) (by omega)
  revert h01
  decide

/-- **CONTROL: the other hypothesis is load-bearing too.** `![1, 0]` is injective
and fails `StrictMonoOn` for want of sortedness — so neither half of the bridge
can be dropped. -/
theorem swap_injective : Function.Injective (![1, 0] : Fin 2 → ℕ) := by decide

theorem swap_not_strictMonoOn :
    ¬ StrictMonoOn (extendIio 0 (![1, 0] : Fin 2 → ℕ)) (Set.Iio 2) := by
  intro h
  have h01 := h (Set.mem_Iio.2 (by omega : (0 : ℕ) < 2))
    (Set.mem_Iio.2 (by omega : (1 : ℕ) < 2)) (by omega)
  revert h01
  decide

/-- ⭐ **CONTROL, and the sharpest one: running the network does not repair a
duplicate.** The input `![0, 0, 1, 2]` is already sorted, so Batcher's 4-wire
network returns it unchanged (pinned here against the literal), and the extended
output therefore fails `StrictMonoOn` at the pair `(0, 1)`.

This is the statement that `hi` cannot be dropped from
`strictMonoOn_extendIio_runNet` *at the network level* — not merely that some
abstract sorted vector can repeat. -/
theorem batcher4_dup_run : List.ofFn (runNet batcher4 ![0, 0, 1, 2]) = [0, 0, 1, 2] := by
  decide

theorem batcher4_dup_not_strictMonoOn :
    ¬ StrictMonoOn (extendIio 0 (runNet batcher4 ![0, 0, 1, 2])) (Set.Iio 4) := by
  intro h
  have h01 := h (Set.mem_Iio.2 (by omega : (0 : ℕ) < 4))
    (Set.mem_Iio.2 (by omega : (1 : ℕ) < 4)) (by omega)
  revert h01
  decide

/-- **CONTROL, the positive side: on a genuinely scrambled distinct input the
bridge fires.** The run is pinned against its literal output so that the
`StrictMonoOn` below is visibly about a vector the network had to move. -/
theorem batcher4_run : List.ofFn (runNet batcher4 ![3, 1, 2, 0]) = [0, 1, 2, 3] := by
  decide

theorem batcher4_strictMonoOn :
    StrictMonoOn (extendIio 0 (runNet batcher4 ![3, 1, 2, 0])) (Set.Iio 4) :=
  strictMonoOn_extendIio_runNet batcher4_sorts_bool (by decide) 0

/-! ## A strictly-increasing list is determined by its members

Requested by leg 3 (`Silicon/Equiv/ScenarioComplete.lean`): `fabric_routes` is
enumerated over the 255 concrete lists of `allScenarios`, so feeding a sorter's
output into it needs *any* strictly-increasing, bounded, non-empty destination
list to **be** one of those 255. The last step of that argument is pure list
mathematics with no silicon in it — hence this lane, not theirs.

### What Mathlib actually has at this pin (v4.32.0-rc1), because two seats guessed wrong

* **`List.Sorted` is gone.** It was replaced (deprecations dated 2025-11-27) by
  four order-specific predicates in `Mathlib/Data/List/Sort.lean:376-404` —
  `SortedLE`/`SortedGE`/`SortedLT`/`SortedGT`, *defined* as `Monotone l.get` /
  `StrictMono l.get` rather than as `Pairwise`. `sortedLT_iff_pairwise`
  (`:421`) is the bridge back.
* **`List.eq_of_perm_of_sorted` is gone too**, and is not a rename of one thing:
  `Perm.eq_of_sortedLE` (`:667`) is the order-flavoured heir,
  `Perm.eq_of_pairwise'` (`:307`) the relation-flavoured one.
* **`(· < ·)` IS antisymmetric here, vacuously, and it is registered.**
  `Mathlib/Order/RelClasses.lean:687` — `instance instAntisymmLt [Preorder α] :
  @Std.Antisymm α (· < ·)`. This is the fact that unblocks everything: the
  antisymm-flavoured lemmas *do* apply to a strict order, so no `≤`-detour is
  needed. (The `IsAntisymm`/`IsIrrefl` spellings are deprecated aliases of
  `Std.Antisymm`/`Std.Irrefl`.)

So both theorems below are one-liners against `Perm.eq_of_pairwise'` and
`Pairwise.eq_of_mem_iff` (`Sort.lean:321`, `[Std.Antisymm r] [Std.Irrefl r]`).
They are stated anyway, in the `Pairwise (· < ·)` vocabulary consumers actually
hold, because the name-hunt above is the expensive part and it should be paid
once. `Preorder` — not `LinearOrder` — is all either needs. -/

/-- **Two strictly-increasing lists that are permutations of each other are
equal.** Directly `List.Perm.eq_of_pairwise'` at `r := (· < ·)`, which typechecks
because of `instAntisymmLt`. -/
theorem eq_of_perm_of_pairwise_lt [Preorder α] {l₁ l₂ : List α}
    (hp : List.Perm l₁ l₂) (h₁ : l₁.Pairwise (· < ·)) (h₂ : l₂.Pairwise (· < ·)) :
    l₁ = l₂ :=
  hp.eq_of_pairwise' h₁ h₂

/-- ⭐ **Two strictly-increasing lists with the same members are equal** — the
form leg 3 asked for. Strictly weaker hypotheses than the `Perm` version above
(same members, not same multiset), and it is what an enumeration argument
actually produces. `List.Pairwise.eq_of_mem_iff` supplies the `Nodup` step from
`Std.Irrefl (· < ·)`. -/
theorem eq_of_mem_iff_of_pairwise_lt [Preorder α] {l₁ l₂ : List α}
    (h₁ : l₁.Pairwise (· < ·)) (h₂ : l₂.Pairwise (· < ·))
    (h : ∀ a : α, a ∈ l₁ ↔ a ∈ l₂) : l₁ = l₂ :=
  h₁.eq_of_mem_iff h₂ h

/-- The enumeration side of that argument: `(range n).filter p` is strictly
increasing, whatever `p` is. -/
theorem pairwise_lt_filter_range (p : ℕ → Bool) (n : ℕ) :
    ((List.range n).filter p).Pairwise (· < ·) :=
  (List.pairwise_lt_range (n := n)).filter p

/-- ⭐ **The composite, in the shape `mem_allScenarios` consumes it:** a strictly
increasing list of naturals *is* the filtered range its own membership predicate
picks out. `allScenarios` is `(range 256).map (fun m => (range 8).filter
(m.testBit ·))` filtered non-empty, so with `p := ((maskOf ds).testBit ·)` and
`n := 8` this closes the identification of `ds` with its mask's scenario, and
what remains on leg 3's side is `maskOf ds ∈ range 256` plus non-emptiness. -/
theorem eq_filter_range_of_pairwise_lt {l : List ℕ} {n : ℕ} {p : ℕ → Bool}
    (hl : l.Pairwise (· < ·)) (hmem : ∀ i, i ∈ l ↔ (i < n ∧ p i = true)) :
    l = (List.range n).filter p :=
  eq_of_mem_iff_of_pairwise_lt hl (pairwise_lt_filter_range p n) <| by
    intro a; simp [List.mem_filter, hmem a]

/-! ### Non-vacuity controls for the sortedness hypotheses

The repo's law: the mutated hypothesis must make the goal **FALSE**, not merely
unreachable. Each pair below is a counterexample to the theorem with one
`Pairwise (· < ·)` hypothesis deleted — the remaining hypotheses hold and the
conclusion `l₁ = l₂` is refuted. -/

/-- **CONTROL, half one — the permutation hypothesis is satisfied.** `[0, 1]` and
`[1, 0]` really are permutations, so what fails next is not `hp`. -/
theorem perm_zeroOne_oneZero : List.Perm ([0, 1] : List ℕ) [1, 0] := by decide

/-- **CONTROL, half two — and `[1, 0]` provably is not strictly increasing.** -/
theorem not_pairwise_lt_oneZero : ¬ ([1, 0] : List ℕ).Pairwise (· < ·) := by decide

/-- ⭐ **CONTROL, the refutation: with `h₂` dropped, `eq_of_perm_of_pairwise_lt`
is FALSE.** `[0, 1] ~ [1, 0]`, the first list is strictly increasing, and the two
are unequal — so `h₂` is load-bearing, not decoration. -/
theorem ne_zeroOne_oneZero : ([0, 1] : List ℕ) ≠ [1, 0] := by decide

/-- **CONTROL for the mem-iff form, half one: the membership hypothesis holds.**
`[0, 0]` and `[0]` have exactly the same members. -/
theorem mem_iff_dup_zero : ∀ a : ℕ, a ∈ ([0, 0] : List ℕ) ↔ a ∈ [0] := by
  intro a; simp

/-- **CONTROL, half two: `[0, 0]` is not strictly increasing** — irreflexivity of
`<` is exactly what it fails, which is the `Nodup` half `Std.Irrefl` supplies. -/
theorem not_pairwise_lt_dup_zero : ¬ ([0, 0] : List ℕ).Pairwise (· < ·) := by decide

/-- ⭐ **CONTROL, the refutation: with `h₁` dropped,
`eq_of_mem_iff_of_pairwise_lt` is FALSE.** Same members, second list strictly
increasing, lists unequal. Note this control kills a *weakening* too: replacing
`Pairwise (· < ·)` by `Pairwise (· ≤ ·)` leaves `[0, 0]` admissible, so the
`≤`-detour route would not have proved this theorem. -/
theorem ne_dup_zero : ([0, 0] : List ℕ) ≠ [0] := by decide

/-! ## ⭐ THE KEY ORDER — the order a hardware Batcher sorts DESTINATION FIELDS by

**Owned here on silicon's request (8/7):** *"the key order is the `LinearOrder`
your `runNet` is instantiated at. If you would rather own the definition than
have me write it in HDL, say so — it is one `def` and I would rather it live
where the network theory lives than be duplicated."* `batcher8_sorts` is already
stated at `∀ {α} [LinearOrder α]` in an arbitrary universe, so the *network* is
generic; what was missing is the **instantiation for addresses**, and duplicating
it in `SaltWorks/HDL/**` would put two definitions of one order in two lanes.

### ⚠️ IT IS THE **UNSIGNED** ORDER — the opposite of this file's other one

A destination field is an **address**. Addresses carry no sign bit, so the key
order is `BitVec.toNat`-based, whereas `Spec.lean`'s `wle` — the order `SLT`
computes, bundled above as `wordSignedOrder` — is `BitVec.toInt`-based. **At
`w = 32` both bundles live on literally the same type** (`Word = BitVec 32`), so
*nothing in a type signature separates them*: `destKeyOrder 32` and
`wordSignedOrder` are two `LinearOrder Word`s and a consumer that grabs the wrong
one gets a well-typed wrong answer. `dest_order_is_not_the_word_order` (one
concrete pair) and `batcher8_dest_run_ne_word_run` (a whole network run) are that
separation as kernel-checked facts.

### ⚠️ AND THE `letI` HAZARD HAS THE OPPOSITE SIGN HERE

`letI_le_is_still_unsigned` above is this file's certificate that
`letI := wordSignedOrder; a ≤ b` silently elaborates to `BitVec`'s own **unsigned**
`≤`. Read the other way round, that theorem says *which* order `≤` on `BitVec`
means: **the destination one.** `destKeyOrder_le_is_the_ambient_le` states it
positively, by `Iff.rfl`. ⇒ **A `letI := destKeyOrder w` block would be harmless
exactly where a `letI := wordSignedOrder` block is wrong.** *Neither is used:
every statement below carries its instance explicitly, exactly as the `Word`
section does, because "harmless today" is not a property a successor reads off
the source — and the two bundles sit on one type.*

### There is no ambient instance to collide with

`#synth LinearOrder (BitVec 3)` **fails** — measured on this pin (v4.32.0-rc1);
mathlib registers no order class on `BitVec` at all. So `Sorts batcher8 (Dest w)`
does not elaborate on its own and the bundle *must* be handed over by hand, which
is the discipline this file already runs at `Word`.

📌 **SILICON: `import SaltWorks.Stack.Perm` and use `destKeyOrder` / `runNetD`;
do not write a second key order in `SaltWorks/HDL/**`.** *`runNetD_toNat` is the
bridge to the `Fin 8 → ℕ` carrier `composed_switch_of_seam_k3` already takes, and
`dest3_toNat_lt_eight` discharges that theorem's `hlt` for free at the fabricated
`k = 3` width — so the ℕ-side statements you have landed compose with this
without any restatement.* -/

/-- **A destination field of width `w`** — the address a packet carries, in the
representation the frame carries it. A type *abbreviation* rather than a wrapper:
it must be the same type the frame's bits decode to, or the order below is an
order on something else. -/
abbrev Dest (w : ℕ) := BitVec w

/-- ⭐ **THE KEY ORDER, as a relation** — UNSIGNED, through `BitVec.toNat`.
Deliberately **not** `wle`; see the section header. -/
def dle {w : ℕ} (a b : Dest w) : Prop := a.toNat ≤ b.toNat

/-- The strict companion — the relation `banyan_selfrouting`'s `StrictMonoOn`
hypothesis is about once the carrier is a field rather than an `ℕ`. -/
def dlt {w : ℕ} (a b : Dest w) : Prop := a.toNat < b.toNat

instance {w : ℕ} (a b : Dest w) : Decidable (dle a b) := inferInstanceAs (Decidable (_ ≤ _))
instance {w : ℕ} (a b : Dest w) : Decidable (dlt a b) := inferInstanceAs (Decidable (_ < _))

/-- ⭐ **THE KEY ORDER AS A `LinearOrder` BUNDLE**, ready to hand to `runNet`. An
`abbrev` (Lean requires class-typed definitions to be reducible) and — following
`wordSignedOrder` — deliberately **not** an `instance`, not even a `local` one.
Reducible is not registered: typeclass search never returns this. -/
abbrev destKeyOrder (w : ℕ) : LinearOrder (Dest w) :=
  LinearOrder.lift' BitVec.toNat fun _ _ h => BitVec.toNat_inj.mp h

/-- **The bundle's `≤` IS `dle`**, by `Iff.rfl`, spelled through the projection
chain rather than left to notation — the same discipline as
`wordSignedOrder_le`. -/
theorem destKeyOrder_le {w : ℕ} (a b : Dest w) :
    @LE.le (Dest w) (@Preorder.toLE (Dest w) (@PartialOrder.toPreorder (Dest w)
      (@LinearOrder.toPartialOrder (Dest w) (destKeyOrder w)))) a b ↔ dle a b := Iff.rfl

/-- ⭐ **AND IT IS ALSO `BitVec`'s OWN `≤`** — the fact that makes this order the
*natural* one on a field and `wle` the imported one. `BitVec.le_def` is `Iff.rfl`
in core, so this whole statement is. **Contrast `letI_le_is_still_unsigned`: the
elaborator's silent answer is wrong for `wordSignedOrder` and right here, and the
only thing distinguishing the two cases is which order was meant.** -/
theorem destKeyOrder_le_is_the_ambient_le {w : ℕ} (a b : Dest w) :
    @LE.le (Dest w) (@Preorder.toLE (Dest w) (@PartialOrder.toPreorder (Dest w)
      (@LinearOrder.toPartialOrder (Dest w) (destKeyOrder w)))) a b ↔ a ≤ b := Iff.rfl

/-- `dle` is `BitVec`'s `≤`, spelled out for consumers who hold one and want the
other. -/
theorem dle_iff_le {w : ℕ} (a b : Dest w) : dle a b ↔ a ≤ b := Iff.rfl

/-- The bundle's `min` is a select on the negation of unsigned less-than — the
comparison a hardware compare-exchange element actually builds. Pinned rather
than assumed, for the same reason `wordSignedOrder_min` is. -/
theorem destKeyOrder_min {w : ℕ} (a b : Dest w) :
    @min (Dest w) (@LinearOrder.toMin (Dest w) (destKeyOrder w)) a b =
      if a.toNat ≤ b.toNat then a else b := rfl

/-- The `max` companion. -/
theorem destKeyOrder_max {w : ℕ} (a b : Dest w) :
    @max (Dest w) (@LinearOrder.toMax (Dest w) (destKeyOrder w)) a b =
      if a.toNat ≤ b.toNat then b else a := rfl

/-- **A network run on destination fields under the KEY (unsigned) comparator.**
The instance is applied by hand, so the order in force is visible in the term —
`runNetW`'s shape, at the other order. -/
def runNetD {w : ℕ} (net : Network n) (v : Fin n → Dest w) : Fin n → Dest w :=
  @runNet n (Dest w) (destKeyOrder w) net v

/-- Any network passing `ZeroOne.lean`'s Boolean check sorts destination fields
of any width. -/
theorem sortsD (w : ℕ) {net : Network n} (hb : Sorts net Bool) :
    @Sorts n net (Dest w) (destKeyOrder w) :=
  @sorts_of_sorts_bool n net hb (Dest w) (destKeyOrder w)

/-- The sortedness half, landing on the relation `dle` and never writing `≤` at a
`BitVec`. -/
theorem sortedD_ofFn_runNetD {net : Network n} (hb : Sorts net Bool) {w : ℕ}
    (v : Fin n → Dest w) : (List.ofFn (runNetD net v)).Pairwise dle :=
  @pairwise_ofFn_runNet n net hb (Dest w) (destKeyOrder w) dle (fun h => h) v

/-- The permutation half — "every payload arrives", at the field carrier. -/
theorem permD_ofFn_runNetD {w : ℕ} (net : Network n) (v : Fin n → Dest w) :
    (List.ofFn v).Perm (List.ofFn (runNetD net v)) :=
  @ofFn_perm_runNet n (Dest w) (destKeyOrder w) net v

/-- Distinct destinations in, distinct destinations out — the `KB3` half at the
field carrier. -/
theorem injective_runNetD {w : ℕ} (net : Network n) {v : Fin n → Dest w}
    (hv : Function.Injective v) : Function.Injective (runNetD net v) :=
  @runNet_injective n (Dest w) (destKeyOrder w) net v hv

/-- ⭐ **THE INSTANTIATION LEMMA — BATCHER'S 8-WIRE NETWORK SORTS DESTINATION
FIELDS**, at every field width, at the key order. *This is the theorem silicon
instantiates instead of restating.* -/
theorem batcher8_sortsD (w : ℕ) : @Sorts 8 batcher8 (Dest w) (destKeyOrder w) :=
  sortsD w batcher8_sorts_bool

/-- The same, in the `List` vocabulary, with both halves — sorted by the key
order **and** a permutation of the input. -/
theorem batcher8_sortsD_ofFn (w : ℕ) (v : Fin 8 → Dest w) :
    (List.ofFn (runNetD batcher8 v)).Pairwise dle ∧
      (List.ofFn v).Perm (List.ofFn (runNetD batcher8 v)) :=
  ⟨sortedD_ofFn_runNetD batcher8_sorts_bool v, permD_ofFn_runNetD batcher8 v⟩

/-! ### The bridge to the `ℕ` carrier silicon's landed statements already use

`composed_switch_of_seam_k3` takes `v hw : Fin 8 → ℕ`. That is the *same* order —
`toNat` is a monotone bijection onto `Iio (2 ^ w)` — so nothing needs restating;
`runNet_comp_monotone` carries the network across the carrier change in one
line. -/

/-- ⭐ **RUNNING ON FIELDS AND RUNNING ON THEIR VALUES ARE THE SAME RUN.** -/
theorem runNetD_toNat {w : ℕ} (net : Network n) (v : Fin n → Dest w) (i : Fin n) :
    (runNetD net v i).toNat = runNet net (fun j => (v j).toNat) i :=
  (congrFun (@runNet_comp_monotone n (Dest w) ℕ (destKeyOrder w) inferInstance
    BitVec.toNat (fun _ _ h => h) net v) i).symm

/-- Distinctness survives the carrier change, so `composed_switch_of_seam_k3`'s
`hi` is exactly injectivity of the field vector. -/
theorem toNat_injective_of_injective {w : ℕ} {v : Fin n → Dest w}
    (hv : Function.Injective v) : Function.Injective (fun i => (v i).toNat) :=
  fun _ _ h => hv (BitVec.toNat_inj.mp h)

/-- ⭐ **AND THE ADDRESS BOUND IS FREE AT THE FABRICATED WIDTH.** A 3-bit
destination field cannot name a line outside an 8-line fabric — so
`composed_switch_of_seam_k3`'s `hlt : ∀ i, v i < 8` is discharged by the *type*
once the carrier is `Dest 3` rather than `ℕ`. *That is the whole argument for
owning the order at the field type instead of at `ℕ`.* -/
theorem dest3_toNat_lt_eight (v : Fin 8 → Dest 3) (i : Fin 8) : (v i).toNat < 8 :=
  (v i).isLt

/-! ### ⛔ CONTROLS — the two orders must be visibly different

*A key order nobody can distinguish from `wle` is a key order that will be
confused with it. Both controls are `decide +kernel`.* -/

/-- ⛔ **THE TWO ORDERS DISAGREE, on the pair `Spec.lean` already uses.** `-1` is
`0xFFFFFFFF`: the *smallest* word signed and the *largest* unsigned. So
`destKeyOrder 32` and `wordSignedOrder` are genuinely different bundles on
genuinely the same type. -/
theorem dest_order_is_not_the_word_order :
    wle (-1 : Word) 1 ∧ ¬ dle (-1 : Dest 32) 1 := by decide +kernel

/-- **A concrete run at the key order**, pinned against its literal output —
ascending *unsigned*, so the negatives land at the top. -/
theorem batcher8_dest_run :
    List.ofFn (runNetD batcher8 (![3, -1, 7, 0, -5, 2, 9, -2] : Fin 8 → Dest 32))
      = [(0 : Dest 32), 2, 3, 7, 9, -5, -2, -1] := by decide +kernel

/-- ⛔ **AND THE TWO NETWORKS COMPUTE DIFFERENT THINGS ON THE SAME INPUT.** Same
24 comparators, same vector, different order, different answer
(`batcher8_word_run` is the other one). **So instantiating `runNet` at the wrong
bundle is not a stylistic slip — it changes the output.** -/
theorem batcher8_dest_run_ne_word_run :
    List.ofFn (runNetD batcher8 (![3, -1, 7, 0, -5, 2, 9, -2] : Fin 8 → Dest 32))
      ≠ List.ofFn (runNetW batcher8 ![3, -1, 7, 0, -5, 2, 9, -2]) := by decide +kernel

/-- ⛔ And the key order's output is **not** signed-sorted — the mirror of
`batcher8_word_run_not_unsigned`, so neither order is a special case of the
other. -/
theorem batcher8_dest_run_not_signed :
    ¬ SortedW (List.ofFn (runNetD batcher8
        (![3, -1, 7, 0, -5, 2, 9, -2] : Fin 8 → Dest 32))) := by decide +kernel

/-! ## Axiom audit -/

section Audit
open Salt.Tactic

#audit_axioms applyComp_perm runNet_perm
#audit_axioms runNet_ofFn_perm ofFn_perm_runNet runNet_ofFn_multiset
#audit_axioms runNet_ofFn_nodup runNet_injective
#audit_axioms isSorted_iff_pairwise_ofFn sortsTo_ofFn_of_sorts_bool
#audit_axioms batcher8_sorts_perm batcher4_sorts_perm pairwise_ofFn_runNet
#audit_axioms wordSignedOrder wordSignedOrder_le letI_le_is_still_unsigned
#audit_axioms wordSignedOrder_min wordSignedOrder_max
#audit_axioms runNetW sortedW_ofFn_runNetW permW_ofFn_runNetW sortsTo_ofFn_runNetW
#audit_axioms batcher8_sortsTo_word batcher4_sortsTo_word batcher8_sortsToV_word
#audit_axioms applyDup applyDup_sorts applyDup_not_perm batcher8_perm_not_refl
#audit_axioms batcher8_word_run batcher8_word_run_not_unsigned
#audit_axioms extendIio extendIio_apply extendIio_of_le
#audit_axioms strictMono_of_isSorted_of_injective strictMonoOn_extendIio
#audit_axioms strictMonoOn_extendIio_of_isSorted runNet_forall
#audit_axioms strictMonoOn_extendIio_runNet strictMonoOn_extendIio_runNet_of_nodup
#audit_axioms banyanHyps_of_sorts_bool batcher8_banyanHyps
#audit_axioms dup_isSorted dup_not_strictMonoOn swap_injective swap_not_strictMonoOn
#audit_axioms batcher4_dup_run batcher4_dup_not_strictMonoOn
#audit_axioms batcher4_run batcher4_strictMonoOn
#audit_axioms eq_of_perm_of_pairwise_lt eq_of_mem_iff_of_pairwise_lt
#audit_axioms pairwise_lt_filter_range eq_filter_range_of_pairwise_lt
#audit_axioms perm_zeroOne_oneZero not_pairwise_lt_oneZero ne_zeroOne_oneZero
#audit_axioms mem_iff_dup_zero not_pairwise_lt_dup_zero ne_dup_zero
#audit_axioms Dest dle dlt destKeyOrder
#audit_axioms destKeyOrder_le destKeyOrder_le_is_the_ambient_le dle_iff_le
#audit_axioms destKeyOrder_min destKeyOrder_max
#audit_axioms runNetD sortsD sortedD_ofFn_runNetD permD_ofFn_runNetD injective_runNetD
#audit_axioms batcher8_sortsD batcher8_sortsD_ofFn
#audit_axioms runNetD_toNat toNat_injective_of_injective dest3_toNat_lt_eight
#audit_axioms dest_order_is_not_the_word_order
#audit_axioms batcher8_dest_run batcher8_dest_run_ne_word_run
#audit_axioms batcher8_dest_run_not_signed

end Audit

end SaltWorks.Stack
