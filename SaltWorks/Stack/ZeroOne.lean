/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib.Order.MinMax
import Mathlib.Data.Bool.Basic
import Mathlib.Data.Fintype.Pi
import SaltWorks.Tactic.AuditAxioms

/-!
# Comparator networks, the 0-1 principle, and Batcher's bitonic sorter at `n = 8`

A **comparator network** is a fixed, data-independent list of two-wire compare-
exchange operations. It is the shape of sorter that this campaign's target ISA
can actually host: 32 registers, **no memory**, and an instruction set of
`ADD, ADDI, XOR, SLT, BEQ` — so there is no place to put a recursive sorter's
stack and no data-dependent addressing. A sorter for that machine is a
**fully-unrolled straight-line network at a fixed `n`**, which is exactly the
`Network n` literal defined here and exactly what the later refinement step
(program ↦ algorithm) will consume.

## What is proved

* `zeroOne_principle` — **the mathematics, and the reusable part.** For *every*
  `n`, *every* network, and *every* linearly-ordered carrier `α` in *any*
  universe: if the network sorts all `2 ^ n` **Boolean** inputs then it sorts
  every `α`-valued input. `sorts_iff_sorts_bool` packages this as an `Iff` at
  `Type` (the converse is immediate — `Bool` is one of the `α`s).
* `batcher8_sorts` — the 24-comparator bitonic network on 8 wires sorts every
  input over every `LinearOrder`. Given the principle, this reduces to a finite
  check over the 256 Boolean vectors, discharged by `decide` in the kernel.
  `batcher4_sorts` is the same statement for the 6-comparator network on 4
  wires (16 cases); it is kept because the 4-wire network is the natural first
  target for the code-generation step, not as a fallback — `n = 8` landed.
* `batcher8_eraseIdx_20_not_sorts`, `batcher8_eraseIdx_12_not_sorts`,
  `empty_not_sorts` — **non-vacuity controls.** Mutilated networks provably fail
  to sort, so the 256-case `∀` above is not true by accident of a trivial
  predicate.

No `native_decide` anywhere — it is banned in this repo, and the ban is enforced
rather than promised: the file's `#audit_axioms` block asserts that every
declaration rests on `propext`, `Classical.choice`, `Quot.sound` alone, and
`native_decide` would put `Lean.ofReduceBool` in that list and fail the build.
The finite checks use `decide +kernel`, which is the *trusted kernel* reducing
the `Decidable` instance — a different thing from compiled evaluation.

## The carrier

Inputs are `Fin n → α`. This was chosen over `Vector α n` for two reasons that
pull the same way. Mathematically, the 0-1 principle is a statement about
*post-composition* with a monotone `f : α → β`; on `Fin n → α` that is literally
`f ∘ v`, so the central commutation lemma `runNet_comp_monotone` is an equation
between functions provable by `funext` with no length bookkeeping. Operationally,
`∀ v : Fin 8 → Bool` is served by `Pi.fintype`, and the kernel does reduce it —
measured at ~3.5 s for the 256 cases, well inside budget, with no memory event
(details on the `batcher8_sorts_bool` docstring and in `docs/LEDGER.md`).

The one real risk of this carrier was checked rather than assumed: `runNet`
builds a 24-deep tower of closures, and evaluating the result at one index calls
the previous layer *twice*, which is `2 ^ 24` without sharing. The kernel's
`whnf` cache is keyed structurally, so the distinct subterms are the ~`24 × 8`
(layer, index) pairs and the tower collapses. That it collapses is the measured
fact above; had it not, a `Vector`/`List` carrier — strict data at every layer —
would have been the fix.

The register file's `Vector`-shaped state is a *refinement* concern and belongs
at the program layer, where a `Fin n → α` view of the registers is one
`fun i => regs[i]` away.

## What mathlib supplied

`Monotone.map_min` / `Monotone.map_max` (`Mathlib/Order/MinMax.lean`) — the
comparator-commutation identity, which is the whole content of the first half of
the proof. `Bool.linearOrder` and `Bool.le_iff_imp` (`Mathlib/Data/Bool/Basic`).
`Pi.fintype` for the finite check. Mathlib has **no** sorting-network material:
searches for "sorting network", "0-1 principle", "batcher", "bitonic" return
nothing, so the definitions and both theorems are new here.
-/

namespace SaltWorks.Stack

universe u v

/-- A **comparator**: an ordered pair of wire indices. Applying `(i, j)` writes
the `min` of the two wires to `i` and the `max` to `j`. The pair is ordered, not
a set, so a *descending* comparator on wires `a < b` is written `(b, a)` — which
is how the bitonic network's reversed half-cleaners are expressed below. `i = j`
is permitted and acts as the identity. -/
abbrev Comparator (n : ℕ) := Fin n × Fin n

/-- A **comparator network**: a straight-line list of comparators, applied left
to right. Data-independent by construction — there is no branching, so the
length of the computation is fixed by `n` alone. -/
abbrev Network (n : ℕ) := List (Comparator n)

variable {n : ℕ} {α : Type u} {β : Type v}

/-- One compare-exchange step: `min` to the low slot `c.1`, `max` to the high
slot `c.2`, every other wire untouched. -/
def applyComp [LinearOrder α] (c : Comparator n) (v : Fin n → α) : Fin n → α :=
  fun i =>
    if i = c.1 then min (v c.1) (v c.2)
    else if i = c.2 then max (v c.1) (v c.2)
    else v i

/-- Run a whole network: fold the comparators over the input, left to right. -/
def runNet [LinearOrder α] (net : Network n) (v : Fin n → α) : Fin n → α :=
  net.foldl (fun w c => applyComp c w) v

@[simp] theorem runNet_nil [LinearOrder α] (v : Fin n → α) :
    runNet ([] : Network n) v = v := rfl

@[simp] theorem runNet_cons [LinearOrder α] (c : Comparator n) (cs : Network n)
    (v : Fin n → α) : runNet (c :: cs) v = runNet cs (applyComp c v) := rfl

/-- A vector is **sorted** when it is monotone as a function `Fin n → α`. -/
def IsSorted [Preorder α] (v : Fin n → α) : Prop := ∀ i j : Fin n, i ≤ j → v i ≤ v j

/-- `net` **sorts** the carrier `α` when it takes every `α`-valued input to a
sorted one. -/
def Sorts (net : Network n) (α : Type u) [LinearOrder α] : Prop :=
  ∀ v : Fin n → α, IsSorted (runNet net v)

/-! ### Decidability of the two predicates

`IsSorted` and `Sorts` are `def`s, so instance search will not see through them
on its own. Both instances are `inferInstanceAs` — a definitional unfolding, not
a rewrite — so the kernel's `decide` reduction below goes straight through to
`Fin.decidableForallFin` and `Fintype.decidableForallFintype` with no `Eq.mpr` in
the way. -/

instance decidableIsSorted [LinearOrder α] (v : Fin n → α) : Decidable (IsSorted v) :=
  inferInstanceAs (Decidable (∀ i j : Fin n, i ≤ j → v i ≤ v j))

instance decidableSorts (net : Network n) (α : Type u) [LinearOrder α] [Fintype α]
    [DecidableEq α] : Decidable (Sorts net α) :=
  inferInstanceAs (Decidable (∀ v : Fin n → α, IsSorted (runNet net v)))

/-! ## Step 1 — comparators commute with monotone maps

The one algebraic fact behind the 0-1 principle: a monotone `f` cannot see the
difference between "compare-exchange, then relabel" and "relabel, then
compare-exchange", because it preserves `min` and `max`. -/

/-- A single comparator commutes with post-composition by a monotone map. -/
theorem applyComp_comp_monotone [LinearOrder α] [LinearOrder β] {f : α → β}
    (hf : Monotone f) (c : Comparator n) (v : Fin n → α) :
    applyComp c (f ∘ v) = f ∘ applyComp c v := by
  funext i
  simp only [applyComp, Function.comp_apply]
  split
  · exact (hf.map_min).symm
  · split
    · exact (hf.map_max).symm
    · rfl

/-- **The commutation lemma.** A whole network commutes with post-composition by
a monotone map: relabelling the values by any monotone `f` — in particular by a
threshold indicator into `Bool` — commutes with running the network. Induction on
the network, generalising over the input. -/
theorem runNet_comp_monotone [LinearOrder α] [LinearOrder β] {f : α → β}
    (hf : Monotone f) (net : Network n) (v : Fin n → α) :
    runNet net (f ∘ v) = f ∘ runNet net v := by
  induction net generalizing v with
  | nil => rfl
  | cons c cs ih => rw [runNet_cons, runNet_cons, applyComp_comp_monotone hf, ih]

/-! ## Step 2 — the threshold indicator

For a threshold `t : α`, `x ↦ (t ≤ x)` is a monotone map `α → Bool`, and it is
the only 0-1 input the proof ever needs to build. -/

/-- The **threshold indicator** at `t`: the monotone map `α → Bool` sending `x`
to `t ≤ x`. Note the `Bool` order is `false < true`, which is the direction that
makes this monotone rather than antitone. -/
def thresh [LinearOrder α] (t : α) : α → Bool := fun x => decide (t ≤ x)

theorem monotone_thresh [LinearOrder α] (t : α) : Monotone (thresh t) := by
  intro a b hab
  refine Bool.le_iff_imp.2 fun h => ?_
  simp only [thresh, decide_eq_true_eq] at h ⊢
  exact h.trans hab

@[simp] theorem thresh_self [LinearOrder α] (t : α) : thresh t t = true := by
  simp [thresh]

/-! ## Step 3 — the 0-1 principle -/

/-- **THE 0-1 PRINCIPLE.** *A comparator network that sorts every Boolean input
sorts every input over every linearly ordered type.*

Stated at general `n`, general `net`, and general `α : Type u` in an arbitrary
universe — nothing here is special to the 8-wire instance below, and nothing is
special to `ℕ`, to bit vectors, or to any particular element type. This is the
theorem that makes the finite 256-case check downstream legitimate mathematics
rather than a lucky enumeration, and it is the piece a second application (a
crypto core, a different `N`) reuses unchanged.

The proof is direct rather than by contradiction. To show
`runNet net v i ≤ runNet net v j` for `i ≤ j`, take the threshold at
`t := runNet net v i` and push it through the network with
`runNet_comp_monotone`: the hypothesis says the resulting Boolean vector is
sorted, its `i`-th entry is `thresh t t = true`, and `true ≤ b` forces `b`, which
is exactly `t ≤ runNet net v j`. -/
theorem zeroOne_principle {n : ℕ} {net : Network n}
    (h : ∀ w : Fin n → Bool, IsSorted (runNet net w))
    {α : Type u} [LinearOrder α] (v : Fin n → α) :
    IsSorted (runNet net v) := by
  intro i j hij
  set t : α := runNet net v i with ht
  -- Push the threshold indicator at `t` through the network.
  have key : runNet net (thresh t ∘ v) = thresh t ∘ runNet net v :=
    runNet_comp_monotone (monotone_thresh t) net v
  -- The Boolean image is sorted, by hypothesis, hence monotone at `i ≤ j`.
  have hb := h (thresh t ∘ v) i j hij
  rw [key] at hb
  simp only [Function.comp_apply, ← ht, thresh_self] at hb
  -- `true ≤ thresh t (runNet net v j)` forces the indicator to fire.
  have hfire : thresh t (runNet net v j) = true := by
    cases hcase : thresh t (runNet net v j) with
    | false => rw [hcase] at hb; exact absurd hb (by decide)
    | true => rfl
  simpa [thresh] using hfire

/-- The 0-1 principle in `Sorts` form: sorting `Bool` is sorting everything. -/
theorem sorts_of_sorts_bool {n : ℕ} {net : Network n} (h : Sorts net Bool)
    (α : Type u) [LinearOrder α] : Sorts net α :=
  fun v => zeroOne_principle h v

/-- **The 0-1 principle as an `Iff`**, at `Type` (universe 0) so that `Bool` can
appear on both sides of the equivalence. The forward direction is the trivial
one: `Bool` is itself a `LinearOrder`. -/
theorem sorts_iff_sorts_bool {n : ℕ} (net : Network n) :
    (∀ (α : Type) [LinearOrder α], Sorts net α) ↔ Sorts net Bool :=
  ⟨fun h => h Bool, fun h α _ => sorts_of_sorts_bool h α⟩

/-! ## Step 4 — Batcher's bitonic network at `n = 8`

Batcher's bitonic sorter on `2 ^ k` wires has `k (k + 1) / 2` layers of `2 ^ (k-1)`
comparators; at `k = 3` that is `6 · 4 = 24`. The literal below is that network,
written layer by layer. A pair `(a, b)` with `a > b` is a *descending*
comparator — the reversed half of each bitonic merge. -/

/-- **Batcher's bitonic sorting network on 8 wires**, 24 comparators in 6 layers
of 4. Layers 1–3 build a bitonic sequence out of the eight inputs (sort the low
half up, the high half down, at each of two scales); layers 4–6 are the bitonic
merge of the whole. Written as an explicit straight-line literal because that is
what a register machine with no memory can run and what the code-generation step
consumes. -/
def batcher8 : Network 8 :=
  [ -- layer 1: sort adjacent pairs, alternating direction
    (0, 1), (3, 2), (4, 5), (7, 6),
    -- layer 2: merge into 4-element bitonic runs (second half reversed)
    (0, 2), (1, 3), (6, 4), (7, 5),
    -- layer 3: clean the 4-runs
    (0, 1), (2, 3), (5, 4), (7, 6),
    -- layer 4: the global half-cleaner
    (0, 4), (1, 5), (2, 6), (3, 7),
    -- layer 5
    (0, 2), (1, 3), (4, 6), (5, 7),
    -- layer 6
    (0, 1), (2, 3), (4, 5), (6, 7) ]

/-- Batcher's bitonic network on 4 wires: 6 comparators in 3 layers of 2. -/
def batcher4 : Network 4 :=
  [ (0, 1), (3, 2),
    (0, 2), (1, 3),
    (0, 1), (2, 3) ]

theorem batcher8_length : batcher8.length = 24 := rfl
theorem batcher4_length : batcher4.length = 6 := rfl

/-- **The finite check at `n = 8`**: all `2 ^ 8 = 256` Boolean inputs.

`decide +kernel`, **not** `native_decide`. The two are not neighbours: `+kernel`
hands the `Decidable` instance to the *kernel* to reduce, so the reduction is the
one the trusted checker performs and the theorem picks up no reflection axiom
(the audit block at the foot of this file records `propext, Classical.choice,
Quot.sound` and nothing else — `native_decide` would show `Lean.ofReduceBool`
there).

Measured, because the brief asked whether 256 cases reduce at all: plain `decide`
**also** discharges this, but only with `set_option maxRecDepth 100000` — the
default 512 is exhausted by the elaborator's `whnf` walking 24 nested comparator
closures — and it costs ~6.8 s against `+kernel`'s ~3.5 s. Neither is a memory
event; nothing here came near the `-M 20000` backstop. `+kernel` is committed
because it needs no `maxRecDepth` override and is the faster of the two. -/
theorem batcher8_sorts_bool : Sorts batcher8 Bool := by decide +kernel

/-- The same finite check at `n = 4`: all 16 Boolean inputs. Plain `decide`
suffices here at the default recursion depth — the contrast with `batcher8` above
is exactly the elaborator-`whnf` depth, not the case count. -/
theorem batcher4_sorts_bool : Sorts batcher4 Bool := by decide

/-! ### Non-vacuity controls

A `∀`-statement over a finite domain is worth only as much as the predicate
inside it. These two say that mutilated networks **provably fail** to sort, which
is what rules out the failure mode where `IsSorted`, `runNet` or `Sorts` is
accidentally trivial and the 256-case check above is vacuous. They are kept in
the module, not in a scratch file, because they are the reason to believe the
theorem above. -/

/-- Deleting one comparator from Batcher's final layer breaks the sorter. -/
theorem batcher8_eraseIdx_20_not_sorts : ¬ Sorts (batcher8.eraseIdx 20) Bool := by
  decide +kernel

/-- Deleting one comparator from the global half-cleaner breaks it too. -/
theorem batcher8_eraseIdx_12_not_sorts : ¬ Sorts (batcher8.eraseIdx 12) Bool := by
  decide +kernel

/-- And the empty network on 8 wires sorts nothing. -/
theorem empty_not_sorts : ¬ Sorts ([] : Network 8) Bool := by decide +kernel

/-- **BATCHER'S NETWORK SORTS.** The 24-comparator bitonic network on 8 wires
takes every input over every linearly ordered type to a sorted output. The 256
Boolean cases were checked by the kernel; the 0-1 principle does the rest. -/
theorem batcher8_sorts (α : Type u) [LinearOrder α] : Sorts batcher8 α :=
  sorts_of_sorts_bool batcher8_sorts_bool α

/-- The 4-wire bitonic network sorts every linearly ordered carrier. -/
theorem batcher4_sorts (α : Type u) [LinearOrder α] : Sorts batcher4 α :=
  sorts_of_sorts_bool batcher4_sorts_bool α

/-- The 8-wire statement spelled out without the `Sorts` abbreviation, for
readers checking the headline claim against the definitions. -/
theorem batcher8_sorts' (α : Type u) [LinearOrder α] (v : Fin 8 → α) :
    ∀ i j : Fin 8, i ≤ j → runNet batcher8 v i ≤ runNet batcher8 v j :=
  batcher8_sorts α v

/-! ## Axiom audit

Every headline declaration must rest on `propext`, `Classical.choice`,
`Quot.sound` alone. In particular this is where a stray `native_decide` would be
caught: it would introduce `Lean.ofReduceBool` and fail the build here. -/

section Audit
open Salt.Tactic

#audit_axioms applyComp runNet IsSorted Sorts thresh
#audit_axioms applyComp_comp_monotone runNet_comp_monotone monotone_thresh
#audit_axioms zeroOne_principle sorts_of_sorts_bool sorts_iff_sorts_bool
#audit_axioms batcher8 batcher4 batcher8_sorts_bool batcher4_sorts_bool
#audit_axioms batcher8_sorts batcher8_sorts' batcher4_sorts
#audit_axioms batcher8_eraseIdx_20_not_sorts batcher8_eraseIdx_12_not_sorts
#audit_axioms empty_not_sorts

end Audit

end SaltWorks.Stack
