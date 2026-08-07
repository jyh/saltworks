/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib.Data.List.Sort
import SaltWorks.HDL.ISA
import SaltWorks.Tactic.AuditAxioms

/-!
# STACK-S1 — the sortedness / permutation spec over machine words

The application layer of the STACK campaign (`docs/stack-campaign-v0.md`) is a
Batcher sort running on Slice A. This file is S1: *what it means* for the
machine's words to be sorted, and to be a permutation of the input. S3 discharges
it; nothing here is about any particular sorting network.

## THE TRAP THIS FILE EXISTS TO CLOSE

Slice A's only comparator is `SLT`, and `SLT` is **signed**
(`SaltWorks/HDL/ISA.lean:124`, and `ISA.slt_is_signed` pins it). But `BitVec`
carries an `≤`/`<` order in core and **that order is UNSIGNED** — it is
`toNat`-based (`BitVec.ule_eq_decide : x.ule y = decide (x.toNat ≤ y.toNat)`).

So a spec written as `List.Pairwise (· ≤ ·)` over `BitVec 32` elaborates
perfectly, reads entirely reasonably, and **specifies the wrong relation**. The
mismatch would stay invisible until S3(b)'s refinement failed to close, with
nothing pointing at the cause.

Therefore the order here is `wle`/`wlt`, defined through `BitVec.toInt`, and the
disagreement with the unsigned order is pinned as a kernel certificate
(`wlt_neg_one_one`, `not_lt_neg_one_one`, `sortedW_signed_not_unsigned`). If
someone later "simplifies" `wle` to `(· ≤ ·)`, those three theorems break.

## The bridge lemma was FOUND, not proved

`BitVec.slt_iff_toInt_lt` and `BitVec.sle_iff_toInt_le` are **already in Lean
core** (`Init/Data/BitVec/Lemmas.lean:853` and `:849`), both by
`decide_eq_true_iff` off the definition `BitVec.slt x y := x.toInt < y.toInt`
(`Init/Data/BitVec/Basic.lean:388`). mathlib has nothing on `BitVec.slt` at all —
`grep -F slt` over `Mathlib/` returns only local hypothesis names.

So `slt_iff_wlt` / `sle_iff_wle` below are re-exports at the project's own names,
not reproofs. The lemma that *is* new here is `slt_get_eq_one_iff` — the bridge
from the spec's order to the **datapath**: what `step` actually writes into `rd`.

## Why a relation and not a `LinearOrder` instance

`BitVec 32` already has `LE`/`LT` instances (unsigned). Registering a competing
`LinearOrder` would put two orders behind one notation — exactly the confusion
this file exists to prevent. Instead `wle` is a named relation carrying
`Std.Refl` / `IsTrans` / `Std.Antisymm` / `Std.Total` / `IsLinearOrder`
instances, so mathlib's relation-generic sorting API applies to it while `≤` on
`BitVec 32` keeps meaning what core says it means.

## Fixed `n`, by force

Slice A has 32 registers and **no memory** — no load, no store, no memory model
at all. The data therefore lives in registers, `n ≤ ~24`, and the program is a
fully-unrolled fixed-`n` network. The `List` forms below are stated at general
length because nothing is cheaper that way; the `Vector` forms
(`SortedV`/`SortsToV`) carry the fixed `n` in the type, and `SortsRegs` states
the spec where the machine actually keeps its data.
-/

namespace SaltWorks.Stack

open SaltWorks.ISA

/-- A machine word: what a Slice A register holds. -/
abbrev Word := BitVec 32

/-! ## The signed order -/

/-- **The signed order on machine words**, `≤`. Defined through `BitVec.toInt`,
so it inherits `Int`'s linear order rather than reproving one, and so it agrees
with `SLT` by construction rather than by coincidence.

⚠️ This is deliberately NOT `(· ≤ ·)`: that notation on `BitVec 32` is the
UNSIGNED order. See `sortedW_signed_not_unsigned`. -/
def wle (a b : Word) : Prop := a.toInt ≤ b.toInt

/-- **The signed order on machine words**, `<` — the relation `SLT` computes. -/
def wlt (a b : Word) : Prop := a.toInt < b.toInt

instance (a b : Word) : Decidable (wle a b) := inferInstanceAs (Decidable (_ ≤ _))
instance (a b : Word) : Decidable (wlt a b) := inferInstanceAs (Decidable (_ < _))

theorem wle_def (a b : Word) : wle a b ↔ a.toInt ≤ b.toInt := Iff.rfl
theorem wlt_def (a b : Word) : wlt a b ↔ a.toInt < b.toInt := Iff.rfl

theorem wle_refl (a : Word) : wle a a := Int.le_refl _

theorem wle_trans {a b c : Word} (h₁ : wle a b) (h₂ : wle b c) : wle a c :=
  Int.le_trans h₁ h₂

/-- Antisymmetry is where `toInt` earns its keep: it is injective on `BitVec n`
(`BitVec.toInt_inj`), so `≤`-antisymmetry on `Int` transfers to *equality of
words*, not merely to equal integer images. Without this `SortsTo` would not pin
the output down (`SortsTo.unique`). -/
theorem wle_antisymm {a b : Word} (h₁ : wle a b) (h₂ : wle b a) : a = b :=
  BitVec.toInt_inj.mp (Int.le_antisymm h₁ h₂)

theorem wle_total (a b : Word) : wle a b ∨ wle b a := Int.le_total _ _

theorem wlt_iff_wle_and_ne {a b : Word} : wlt a b ↔ wle a b ∧ a ≠ b := by
  rw [wlt_def, wle_def, Int.lt_iff_le_and_ne]
  exact and_congr_right fun _ => not_congr BitVec.toInt_inj

theorem not_wlt {a b : Word} : ¬ wlt a b ↔ wle b a := Int.not_lt

instance : Std.Refl wle := ⟨wle_refl⟩
instance : IsTrans Word wle := ⟨fun _ _ _ => wle_trans⟩
instance : Std.Antisymm wle := ⟨fun _ _ => wle_antisymm⟩
instance : Std.Total wle := ⟨wle_total⟩
instance : IsPreorder Word wle where
instance : IsPartialOrder Word wle where
instance : IsLinearOrder Word wle where

/-! ## ⭐ The bridge to the ISA's comparator

Three rungs: the core lemmas re-exported at project names, then the disagreement
with the unsigned order pinned, then the datapath itself. -/

/-- ⭐ **THE BRIDGE.** `BitVec.slt` — the Bool that `step` branches on for `SLT` —
is exactly the spec's order.

**Located in Lean core, not proved here**: `BitVec.slt_iff_toInt_lt`
(`Init/Data/BitVec/Lemmas.lean:853`). It is `decide_eq_true_iff` applied to
`BitVec.slt x y := x.toInt < y.toInt`. -/
theorem slt_iff_wlt (a b : Word) : a.slt b = true ↔ wlt a b :=
  BitVec.slt_iff_toInt_lt

/-- The `sle` companion, likewise from core (`BitVec.sle_iff_toInt_le`). Slice A
has no `SLE` instruction, but a comparator network that swaps on `¬ slt` reasons
about this one. -/
theorem sle_iff_wle (a b : Word) : a.sle b = true ↔ wle a b :=
  BitVec.sle_iff_toInt_le

/-- The two are exchangeable: `sle` is the negation of the flipped `slt`, which
is how a compare-and-swap element gets read either way round. -/
theorem not_wlt_iff_wle (a b : Word) : ¬ wlt b a ↔ wle a b := not_wlt

/-- **THE TRAP, half one.** `-1 <ₛ 1` — signed. -/
theorem wlt_neg_one_one : wlt (-1 : Word) 1 := by decide +kernel

/-- **THE TRAP, half two.** The same pair under `BitVec`'s own `<` — the
UNSIGNED order — goes the other way, because `-1` is `0xFFFFFFFF`. These two
theorems together are why `wle` may never be "simplified" to `(· ≤ ·)`. -/
theorem not_lt_neg_one_one : ¬ ((-1 : Word) < (1 : Word)) := by decide +kernel

/-- `pc` advance does not disturb the register file. Local rather than in the
`ISA` namespace — `SaltWorks/HDL/**` is another seat's writer slot. -/
private theorem next_get (s : St) (r : Fin 32) : s.next.get r = s.get r := by
  simp [St.next, St.get]

/-- The `Bool → Word` step, done once: the word `SLT` selects, as a proposition
about the order. -/
private theorem ite_slt_eq_one_iff (a b : Word) :
    ((if a.slt b then (1 : Word) else 0) = 1) ↔ wlt a b := by
  rw [← slt_iff_wlt]
  split
  · rename_i h; exact iff_of_true rfl h
  · rename_i h; exact iff_of_false (by decide) h

private theorem ite_slt_eq_zero_iff (a b : Word) :
    ((if a.slt b then (1 : Word) else 0) = 0) ↔ wle b a := by
  rw [← not_wlt, ← slt_iff_wlt]
  · split
    · rename_i h; exact iff_of_false (by decide) (fun hn => hn h)
    · rename_i h; exact iff_of_true rfl h

/-- ⭐ **THE DATAPATH BRIDGE — the declaration S3(b) consumes.** What `SLT`
actually leaves in `rd`, tied to the spec's order.

This is the one lemma here that core could not supply: it is about `step`, not
about `BitVec`. It needs `rd ≠ 0` because a write to `x0` is discarded
(`ISA.St.set_zero`, the freeze's P5) — with `rd = 0` the read is `0 ≠ 1` and the
iff genuinely fails, so the hypothesis is load-bearing rather than defensive. -/
theorem slt_get_eq_one_iff (s : St) (rd a b : Fin 32) (hrd : rd ≠ 0) :
    (step s (.SLT rd a b)).get rd = 1 ↔ wlt (s.get a) (s.get b) := by
  rw [step, next_get, St.get_set_self _ _ _ hrd]
  exact ite_slt_eq_one_iff _ _

/-- The complement: `SLT` leaves `0` exactly when the order does not hold. Stated
separately so a refinement proof never has to argue "the word is a Bool". -/
theorem slt_get_eq_zero_iff (s : St) (rd a b : Fin 32) (hrd : rd ≠ 0) :
    (step s (.SLT rd a b)).get rd = 0 ↔ wle (s.get b) (s.get a) := by
  rw [step, next_get, St.get_set_self _ _ _ hrd]
  exact ite_slt_eq_zero_iff _ _

/-! ## Sortedness, permutation, and the combined spec -/

/-- **Sorted under the signed order.** `List.Pairwise` is the standard predicate
(mathlib's old `List.Sorted r` is gone in this toolchain — `Mathlib/Data/List/
Sort.lean` now states everything about `Pairwise r`, keeping `SortedLE`/`SortedLT`
only for orders that come from a `Preorder` instance, which is precisely the case
we must NOT use here). -/
def SortedW (l : List Word) : Prop := l.Pairwise wle

instance (l : List Word) : Decidable (SortedW l) :=
  inferInstanceAs (Decidable (List.Pairwise _ l))

/-- **A permutation of the input** — mathlib/core's `List.Perm`, unchanged. Named
so that S3's statements read in the vocabulary of the spec. -/
def PermW (l l' : List Word) : Prop := l.Perm l'

instance (l l' : List Word) : Decidable (PermW l l') :=
  inferInstanceAs (Decidable (List.Perm _ _))

/-- ⭐ **THE SPEC.** What a sorting procedure must meet: the output is sorted
under the signed order, and is a permutation of the input.

Shape note for S3: this is a bare `∧`, so `h.sorted` / `h.perm` project and
`⟨_, _⟩` constructs; there is no structure to unfold at the refinement boundary,
and `SortsTo.unique` makes it a *functional* specification — any two outputs
meeting it are equal, so a refinement may compare against any reference sorter it
likes. -/
def SortsTo (input output : List Word) : Prop :=
  SortedW output ∧ PermW input output

theorem SortsTo.sorted {i o : List Word} (h : SortsTo i o) : SortedW o := h.1
theorem SortsTo.perm {i o : List Word} (h : SortsTo i o) : PermW i o := h.2

/-- **The spec decides.** Every ingredient is decidable, so a concrete
input/output pair is a kernel-checkable certificate — the campaign's
"`step` is executable, so concrete runs are kernel-computable sanity checks",
available on the spec side too. -/
instance (i o : List Word) : Decidable (SortsTo i o) :=
  inferInstanceAs (Decidable (_ ∧ _))

/-- **The spec is functional.** Two sorted permutations of the same input are the
same list — antisymmetry of `wle` is exactly what buys this, and it is the
property that lets S3 refine against *a* sorter rather than *the* sorter. -/
theorem SortsTo.unique {i o o' : List Word} (h : SortsTo i o) (h' : SortsTo i o') :
    o = o' :=
  List.Perm.eq_of_pairwise (fun _ _ _ _ hab hba => wle_antisymm hab hba)
    h.sorted h'.sorted (h.perm.symm.trans h'.perm)

/-! ### Sanity lemmas -/

@[simp] theorem sortedW_nil : SortedW [] := List.Pairwise.nil

@[simp] theorem sortedW_singleton (a : Word) : SortedW [a] := by
  simp [SortedW]

theorem sortedW_pair {a b : Word} : SortedW [a, b] ↔ wle a b := by
  simp [SortedW]

@[simp] theorem sortsTo_nil : SortsTo [] [] := ⟨sortedW_nil, List.Perm.refl _⟩

@[simp] theorem sortsTo_singleton (a : Word) : SortsTo [a] [a] :=
  ⟨sortedW_singleton a, List.Perm.refl _⟩

theorem SortsTo.length_eq {i o : List Word} (h : SortsTo i o) : i.length = o.length :=
  h.perm.length_eq

theorem SortsTo.mem_iff {i o : List Word} (h : SortsTo i o) {a : Word} :
    a ∈ i ↔ a ∈ o := h.perm.mem_iff

/-- `Perm`-congruence on the input side: sorting is a property of the multiset,
so a reordered input has the same sorted outputs. -/
theorem SortsTo.of_perm_left {i i' o : List Word} (hp : PermW i i') (h : SortsTo i o) :
    SortsTo i' o := ⟨h.sorted, hp.symm.trans h.perm⟩

/-! ### THE TRAP, pinned over the spec itself

`[-1, 0, 1]` is sorted signed and *not* sorted unsigned, because `-1` is
`0xFFFFFFFF`. If `SortedW` ever silently becomes the unsigned order, this pair
of kernel certificates fails the build. -/

theorem sortedW_signed_not_unsigned :
    SortedW [(-1 : Word), 0, 1] ∧
      ¬ List.Pairwise (· ≤ · : Word → Word → Prop) [(-1 : Word), 0, 1] := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-! ## The fixed-`n` forms

Slice A has no memory, so `n` is bounded by the register file and every program
is a fully-unrolled network. These carry `n` in the type; the `List` forms above
are what the proofs actually manipulate. -/

/-- Sortedness of a fixed-length vector of words. -/
def SortedV {n : Nat} (v : Vector Word n) : Prop := SortedW v.toList

/-- ⭐ **The spec at fixed `n`** — the shape a `Vector`-indexed network
instantiates at `n = 8`. Both sides have the same type, so the length side
condition that a `List` spec would have to carry is discharged by the elaborator. -/
def SortsToV {n : Nat} (input output : Vector Word n) : Prop :=
  SortsTo input.toList output.toList

instance {n : Nat} (v : Vector Word n) : Decidable (SortedV v) :=
  inferInstanceAs (Decidable (SortedW _))

instance {n : Nat} (i o : Vector Word n) : Decidable (SortsToV i o) :=
  inferInstanceAs (Decidable (SortsTo _ _))

theorem SortsToV.sorted {n : Nat} {i o : Vector Word n} (h : SortsToV i o) : SortedV o := h.1

theorem SortsToV.perm {n : Nat} {i o : Vector Word n} (h : SortsToV i o) :
    PermW i.toList o.toList := h.2

/-- The fixed-`n` spec is functional too — via `Vector.toList` injectivity. -/
theorem SortsToV.unique {n : Nat} {i o o' : Vector Word n}
    (h : SortsToV i o) (h' : SortsToV i o') : o = o' :=
  Vector.toList_inj.mp (SortsTo.unique h h')

/-- **The spec is satisfiable at the campaign's `n`, kernel-checked.** The input
mixes negatives with positives so the witness would FAIL under the unsigned
order: unsigned, `-5 = 0xFFFFFFFB` is the largest element, not the smallest.

This is the anti-vacuity certificate for the whole file — `SortsToV` is not a
predicate that nothing meets, and what meets it is signed-sorted. -/
theorem sortsToV_witness_eight :
    SortsToV (n := 8)
      (⟨#[3, -1, 7, 0, -5, 2, 9, -2], by decide⟩ : Vector Word 8)
      (⟨#[-5, -2, -1, 0, 2, 3, 7, 9], by decide⟩ : Vector Word 8) := by
  decide +kernel

/-! ## The spec where the machine keeps its data

Slice A has no load and no store, so "the input" and "the output" are register
contents at two points in time. `SortsRegs` says: read the words at the register
addresses `rs` before and after, and the machine has sorted them. This is the
statement S3(b) discharges about a concrete program. -/

/-- **The register-level spec.** `rs` names the register addresses holding the
data (in place: read `rs` from `s`, read the same `rs` from `s'`). -/
def SortsRegs (rs : List (Fin 32)) (s s' : St) : Prop :=
  SortsTo (rs.map s.get) (rs.map s'.get)

instance (rs : List (Fin 32)) (s s' : St) : Decidable (SortsRegs rs s s') :=
  inferInstanceAs (Decidable (SortsTo _ _))

/-- Doing nothing sorts a one-register "array", and nothing longer. The base case
of any unrolled network, and a check that `SortsRegs` is not vacuous. -/
theorem sortsRegs_singleton (r : Fin 32) (s : St) : SortsRegs [r] s s :=
  sortsTo_singleton _

/-- The register-level spec is functional *on the named registers*: it pins the
words at `rs`, and says nothing about any other register — which is the honest
content, since a program is free to clobber scratch. -/
theorem SortsRegs.unique {rs : List (Fin 32)} {s s' s'' : St}
    (h : SortsRegs rs s s') (h' : SortsRegs rs s s'') :
    rs.map s'.get = rs.map s''.get := SortsTo.unique h h'

/-! ## Axiom audit — every definition and every theorem, per the iron rules -/

#audit_axioms wle
#audit_axioms wlt
#audit_axioms wle_def
#audit_axioms wlt_def
#audit_axioms wle_refl
#audit_axioms wle_trans
#audit_axioms wle_antisymm
#audit_axioms wle_total
#audit_axioms wlt_iff_wle_and_ne
#audit_axioms not_wlt
#audit_axioms slt_iff_wlt
#audit_axioms sle_iff_wle
#audit_axioms not_wlt_iff_wle
#audit_axioms wlt_neg_one_one
#audit_axioms not_lt_neg_one_one
#audit_axioms slt_get_eq_one_iff
#audit_axioms slt_get_eq_zero_iff
#audit_axioms SortedW
#audit_axioms PermW
#audit_axioms SortsTo
#audit_axioms SortsTo.sorted
#audit_axioms SortsTo.perm
#audit_axioms SortsTo.unique
#audit_axioms sortedW_nil
#audit_axioms sortedW_singleton
#audit_axioms sortedW_pair
#audit_axioms sortsTo_nil
#audit_axioms sortsTo_singleton
#audit_axioms SortsTo.length_eq
#audit_axioms SortsTo.mem_iff
#audit_axioms SortsTo.of_perm_left
#audit_axioms sortedW_signed_not_unsigned
#audit_axioms SortedV
#audit_axioms SortsToV
#audit_axioms SortsToV.sorted
#audit_axioms SortsToV.perm
#audit_axioms SortsToV.unique
#audit_axioms sortsToV_witness_eight
#audit_axioms SortsRegs
#audit_axioms sortsRegs_singleton
#audit_axioms SortsRegs.unique

end SaltWorks.Stack
