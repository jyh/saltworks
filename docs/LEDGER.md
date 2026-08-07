# saltworks — LEDGER (append-only, flags-style honesty)

Per `docs/SEATS.md`: one entry per landed node, written to be useful to whoever
has to distrust it later. Record what landed, attempt counts, what was FOUND vs
what was PROVED, and anything left undetermined.

---

## STACK-S1 — the sortedness / permutation spec over machine words (signed order)
**2026-08-07 · Opus executor · `SaltWorks/Stack/Spec.lean` (new module)**

### What landed

The S1 spec, over the signed order, with the ISA comparator bridged.

- `Word := BitVec 32` (abbrev).
- `wle a b := a.toInt ≤ b.toInt`, `wlt a b := a.toInt < b.toInt` — **the signed
  order**, via `BitVec.toInt`, so `Int`'s linear order transfers instead of being
  rebuilt. Carries `Std.Refl` / `IsTrans` / `Std.Antisymm` / `Std.Total` /
  `IsPreorder` / `IsPartialOrder` / `IsLinearOrder` instances plus
  `Decidable`, so mathlib's relation-generic sorting API applies to it.
- `SortedW l := l.Pairwise wle`; `PermW := List.Perm`;
  `SortsTo i o := SortedW o ∧ PermW i o`.
- `SortsTo.unique` — **the spec is functional**: two sorted permutations of the
  same input are equal. This is what lets S3 refine against *a* reference sorter
  rather than *the* one. It is the payoff from stating antisymmetry over words
  (`wle_antisymm`, via `BitVec.toInt_inj`) rather than over integer images.
- Fixed-`n` forms `SortedV` / `SortsToV` over `Vector Word n`, with
  `SortsToV.unique` via `Vector.toList_inj`.
- `SortsRegs rs s s'` — the spec where the machine actually keeps its data
  (Slice A has **no memory**): read the words at register addresses `rs` before
  and after. `SortsRegs.unique` is honestly weaker than `SortsToV.unique` — it
  pins the words at `rs` and says nothing about scratch registers, because a
  program is free to clobber them.
- Sanity: `sortedW_nil`, `sortedW_singleton`, `sortedW_pair`, `sortsTo_nil`,
  `sortsTo_singleton`, `SortsTo.length_eq`, `SortsTo.mem_iff`,
  `SortsTo.of_perm_left`, `sortsRegs_singleton`.

### THE BRIDGE LEMMA — **FOUND in Lean core, not proved**

`BitVec.slt_iff_toInt_lt : x.slt y ↔ x.toInt < y.toInt`
(`Init/Data/BitVec/Lemmas.lean:853`) and its companion
`BitVec.sle_iff_toInt_le` (`:849`). Both are `decide_eq_true_iff` off the
*definition* `BitVec.slt x y : Bool := x.toInt < y.toInt`
(`Init/Data/BitVec/Basic.lean:388`) — so the bridge is definitional, and the
signed order was never in doubt at the `BitVec` layer.

**mathlib has nothing on `BitVec.slt`.** `grep -F slt` over
`.lake/packages/mathlib/Mathlib/` returns three hits, all local hypothesis names
in `Topology/Category/Profinite/Nobeling/ZeroLimit.lean`. `Mathlib/Data/BitVec.lean`
is ring/cast material only and carries a "please do not extend this file" notice.

Re-exported here at project names as `slt_iff_wlt` / `sle_iff_wle`, plus
`not_wlt_iff_wle` for the compare-and-swap reading.

### THE LEMMA THAT WAS ACTUALLY NEW — the datapath bridge

Core bridges `BitVec.slt` to `Int`. Nothing bridged it to **`step`**, which is
what S3(b) consumes. Proved here:

- `slt_get_eq_one_iff (s rd a b) (hrd : rd ≠ 0) :
   (step s (.SLT rd a b)).get rd = 1 ↔ wlt (s.get a) (s.get b)`
- `slt_get_eq_zero_iff` — the `= 0` complement, so a refinement proof never has
  to argue "the word is a Bool".

`hrd : rd ≠ 0` is **load-bearing, not defensive**: a write to `x0` is discarded
(`ISA.St.set_zero`, the freeze's P5), so at `rd = 0` the read is `0` and the iff
genuinely fails. Both go through two private helpers (`next_get`,
`ite_slt_eq_one_iff` / `ite_slt_eq_zero_iff`) so the `Bool → Word` step is done
once.

### The trap, pinned three ways

The node's whole risk was writing `List.Pairwise (· ≤ ·)` over `BitVec 32`,
which elaborates and means the **unsigned** order. Three kernel certificates now
fail the build if `wle` ever drifts to `(· ≤ ·)`:

1. `wlt_neg_one_one : wlt (-1) 1` — signed.
2. `not_lt_neg_one_one : ¬ ((-1 : Word) < 1)` — the same pair under `BitVec`'s
   own `<`, which is `toNat`-based, goes the other way.
3. `sortedW_signed_not_unsigned : SortedW [-1, 0, 1] ∧ ¬ List.Pairwise (· ≤ ·) [-1, 0, 1]`.

Measured out-of-band in `ScratchMATHS1.lean` (not committed), all four as
expected: `SortedW [-1,0,1] = true`, `Pairwise (· ≤ ·) [-1,0,1] = false`,
`SortedW [0,1,-1] = false`, `Pairwise (· ≤ ·) [0,1,-1] = true`.

### Non-vacuity at the campaign's `n`

`sortsToV_witness_eight` — a kernel-checked `SortsToV` at `n = 8` on
`#[3,-1,7,0,-5,2,9,-2] → #[-5,-2,-1,0,2,3,7,9]`. The input mixes signs
deliberately: the *unsigned*-sorted rearrangement of the same multiset
(`#[0,2,3,7,9,-5,-2,-1]`) evaluates `SortsToV = false`, and so does a
signed-sorted **non**-permutation (`…,7,8`). So the predicate is neither empty
nor satisfied by the wrong order. Both negative checks were run in
`ScratchMATHS1.lean`; only the positive one is committed as a theorem.

`Decidable` instances are supplied for `SortedW`, `PermW`, `SortsTo`, `SortedV`,
`SortsToV`, `SortsRegs` — they are needed because the definitions are `def`s and
instance search does not unfold them, and they are what make concrete runs
kernel-checkable on the spec side (the campaign's stated sanity-check route).

### Design calls, stated so they can be overruled

- **No `LinearOrder` instance on `BitVec 32`.** `BitVec` already has `LE`/`LT`
  (unsigned). Registering a competing bundled order would put two orders behind
  one notation — exactly the confusion the node exists to prevent. `wle` is a
  named relation with unbundled order instances instead.
- **`SortsTo` is a bare `∧`**, not a structure: `⟨_,_⟩` constructs, `.sorted` /
  `.perm` project, nothing to unfold at the refinement boundary.
- **`List` at general length, `Vector` at fixed `n`.** Nothing was contorted for
  generality; the `List` forms are simply not cheaper when specialised.
- The module imports `SaltWorks.HDL.ISA` (read-only; `SaltWorks/HDL/**` is the
  HDL seat's writer slot) and `Mathlib.Data.List.Sort`.

### API note for whoever reads mathlib next

**`List.Sorted r` no longer exists in this toolchain.** `Mathlib/Data/List/Sort.lean`
now states everything about `List.Pairwise r`, keeping only `SortedLE` /
`SortedGE` / `SortedLT` / `SortedGT` for relations that come from a `Preorder`
instance — precisely the form S1 must NOT use. `List.Perm.eq_of_pairwise` is in
Lean core (`Init/Data/List/Perm.lean:499`, takes an antisymmetry hypothesis, no
typeclass); mathlib's `Perm.eq_of_pairwise'` is the `[Std.Antisymm r]` variant.
`SortsTo.unique` uses the core one.

### Attempts, build, audit

- **Attempts: 2 build cycles.** Cycle 1 landed 38 of 41 declarations; three
  failures, all mechanical: a `simpa using fun hn => …` whose elaboration order
  was wrong in `slt_get_eq_zero_iff` (fixed by factoring the `ite` out into
  `ite_slt_eq_{one,zero}_iff` and using `split` + `iff_of_true`/`iff_of_false`
  rather than `cases` + `simpa`), and `Vector.toList_injective` (mathlib's
  `Mathlib/Data/Vector/Basic.lean` name, wrong package — core's is
  `Vector.toList_inj`, an `Iff`). No statement was reshaped; no proof was
  attempted three times.
- **Build:** `saltbuild.sh SaltWorks.Stack.Spec` → `saltbuild EXIT=0`, no
  warnings. Full `saltbuild.sh` from `saltworks` → `saltbuild EXIT=0`,
  8614 jobs, `Built SaltWorks`.
- **Axioms:** all 41 audited declarations pass `#audit_axioms` in-file; the
  out-of-band `#print axioms` run agrees. Everything is a subset of
  `[propext, Classical.choice, Quot.sound]`; only `sortsToV_witness_eight`
  reaches all three. No `sorry`, no `native_decide`, no new axioms.
- **Honest line count:** 392 lines total — **120 lines of definitions and
  proofs**, 41 lines of `#audit_axioms`, 231 lines of docstrings, module
  comment, and blanks. The prose-to-code ratio is high on purpose: the module
  header exists to stop the next reader "simplifying" `wle` to `(· ≤ ·)`.

### Left undetermined

- **`SaltWorks.Stack.Spec` is NOT yet in `SaltWorks.lean`** — import owed to the
  maestro. Until it is swept, the module is not covered by the default full
  build; it must be built targeted.
- **`SortsRegs` fixes the register list `rs` and reads the same addresses before
  and after** (an in-place sort). If S2's Batcher writes its output to a
  *different* register block, S3 will want a two-list variant
  (`SortsTo (rsIn.map s.get) (rsOut.map s'.get)`). It is a one-liner, but it is
  a design call for S2/S3, not for S1, so it was not guessed at.
- **No `Batcher`/network vocabulary here at all** — no compare-exchange
  operator, no 0-1 principle. That is S3(a)'s lane and the sibling
  `SaltWorks/Stack/ZeroOne.lean`'s; S1 deliberately says only what "sorted"
  means.
- **Not checked:** whether `docs/LEDGER.md` was expected to exist already. It did
  not (`docs/SEATS.md` names it; no file was present at 2026-08-07 09:42), so
  this entry created it with a header. If another seat's entry was meant to be
  first, this file needs merging rather than trusting.
