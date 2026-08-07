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

---

## STACK-S3(a) — the 0-1 principle, and Batcher's network sorts
**2026-08-07 · Opus executor · `SaltWorks/Stack/ZeroOne.lean` (new module)**

### What landed

Both halves of the deliverable, at the sizes asked for. No fallback was taken.

**(i) The 0-1 principle, general `n`, general `LinearOrder`, arbitrary universe.**

```lean
theorem zeroOne_principle {n : ℕ} {net : Network n}
    (h : ∀ w : Fin n → Bool, IsSorted (runNet net w))
    {α : Type u} [LinearOrder α] (v : Fin n → α) :
    IsSorted (runNet net v)
```

with `IsSorted v := ∀ i j : Fin n, i ≤ j → v i ≤ v j`, `Sorts net α := ∀ v, IsSorted (runNet net v)`,
and `Iff` form `sorts_iff_sorts_bool : (∀ (α : Type) [LinearOrder α], Sorts net α) ↔ Sorts net Bool`.

**One specialisation, and it is only in the `Iff` and only in the universe.**
`zeroOne_principle` and `sorts_of_sorts_bool` quantify `α : Type u` for arbitrary
`u`, exactly as briefed. `sorts_iff_sorts_bool` is stated at `Type` (universe 0)
because `Bool : Type 0` has to appear on *both* sides of the equivalence, and
`∀ α : Type u` does not admit `Bool` for general `u`. The alternative was
`ULift Bool` on the right, which buys nothing and costs a reader. The
general-universe content is not in the `Iff`; the `Iff` is packaging.

**(ii) Batcher's bitonic network at `n = 8` — LANDED AT 8, not 4.**
`batcher8 : Network 8`, an explicit 24-comparator literal (6 layers × 4;
`k(k+1)/2 · 2^(k-1)` at `k = 3`), `batcher8_length : batcher8.length = 24 := rfl`.
`batcher8_sorts (α : Type u) [LinearOrder α] : Sorts batcher8 α`. `batcher4` (6
comparators) is also landed — as the natural first code-generation target, NOT as
a fallback.

**Non-vacuity controls, in the module rather than in scratch.** A `∀` over 256
cases is worth what its predicate is worth, so three mutilated networks are
proved *not* to sort: `batcher8_eraseIdx_20_not_sorts`,
`batcher8_eraseIdx_12_not_sorts`, `empty_not_sorts`. If `IsSorted`/`runNet`/`Sorts`
were accidentally trivial these would fail. They cost ~0 s on top of the positive
check. Out-of-band `#eval` sanity at a `Nat` carrier (not committed):
`[5,3,8,1,9,2,7,4] ↦ [1,2,3,4,5,7,8,9]`, `[9,2,7,4] ↦ [2,4,7,9]`.

### The carrier: `Fin n → α`, and the risk that had to be measured

Chosen over `Vector α n` for two reasons pulling the same way. **Mathematically**,
the principle is about post-composition with a monotone `f : α → β`; on `Fin n → α`
that is literally `f ∘ v`, so the central lemma `runNet_comp_monotone` is a
function equation by `funext` with no length bookkeeping — `Vector` would have put
a `size` proof under every rewrite for zero mathematical content.
**Operationally**, `∀ v : Fin 8 → Bool` is served by `Pi.fintype` and the kernel
does reduce it.

The real risk was NOT the case count, and it was checked rather than assumed:
`runNet` builds a **24-deep tower of closures**, and evaluating the result at one
index calls the previous layer *twice* (`min (w a) (w b)`), which is `2^24`
**without sharing**. The kernel's `whnf` cache is keyed structurally, so the
distinct subterms are the ~`24 × 8` (layer, index) pairs and the tower collapses.
That it collapses is the measured fact below. Had it not, the fix was a
`Vector`/`List` carrier — strict data at every layer — not a drop to `n = 4`.

### How the finite check went — MEASURED, both ways

| what | result |
|---|---|
| baseline (scratch importing the module, nothing else) | 1.46 s |
| plain `decide`, default `maxRecDepth` (512) | **FAILS: `maximum recursion depth has been reached`** |
| plain `decide`, `set_option maxRecDepth 100000` | 8.26 s → **~6.8 s** of check |
| `decide +kernel` | 4.95 s → **~3.5 s** of check |
| whole module, fresh (both networks + 3 controls + 8 audit lines) | **4.7 s** |

**`decide +kernel` is committed.** It needs no `maxRecDepth` override and is ~2×
faster. Read the failure correctly: the default-`decide` failure is an
**elaborator `whnf` depth** limit (walking the 24-deep closure tower), *not* a
memory event and *not* a kernel refusal. **Nothing here came near the `-M 20000`
backstop**; no `excessive memory consumption` diagnostic appeared at any point,
so the lakefile's M-2 differential test was never triggered and never needed.

`decide +kernel` is **not** `native_decide` and the distinction is not a
technicality: `+kernel` hands the `Decidable` instance to the *trusted kernel* to
reduce (`Lean/Elab/Tactic/Decide.lean:83,96-97` — "we let the kernel recompute it
during type checking"), picking up no reflection axiom. The audit below is the
proof of that claim, not a promise about it: `native_decide` would have put
`Lean.ofReduceBool` in the list and failed the build.

### What mathlib supplied — and what it did not

- **`Monotone.map_min` / `Monotone.map_max`** (`Mathlib/Order/MinMax.lean:150`,
  and the `to_dual`-generated `map_min`). This is the entire content of
  `applyComp_comp_monotone`, i.e. the first half of the principle. Worth
  ~15 lines of `rcases le_total` bookkeeping that did not have to be written.
- **`Bool.linearOrder`** (`Mathlib/Data/Bool/Basic.lean:142`) and
  **`Bool.le_iff_imp`** — the `false < true` order the threshold indicator has to
  be monotone into.
- **`Pi.fintype`** — the `Fintype (Fin 8 → Bool)` the finite check enumerates over.
- **`Decidable (p → q)`** is Lean core (`Init/Core.lean:1159`), not mathlib;
  checked before relying on the `i ≤ j → v i ≤ v j` shape of `IsSorted`.
- **Mathlib has NO sorting-network material whatsoever.** `grep -rniF` over
  `Mathlib/` for "sorting network", "0-1 principle", "batcher", "bitonic" returns
  **zero hits, all four**. `Comparator`, `Network`, `applyComp`, `runNet`,
  `IsSorted`, `Sorts`, `thresh`, and both theorems are new here. (Mathlib has
  `List.Sorted`/`List.Perm` and merge sort, but nothing about oblivious networks;
  S1's `Spec.lean` is where the `List.Sorted` vocabulary lives, and S3(a)
  deliberately does not import it — the principle is about arbitrary
  `LinearOrder`s and needs nothing from the `BitVec` spec.)

### Attempts, build, audit

- **Attempts: 3 build cycles, no proof attempted more than twice, no statement
  reshaped to make a proof go through.**
  - Cycle 1 — two mechanical failures. (a) `Bool.eq_false_or_eq_true` returns
    `b = true ∨ b = false`, i.e. the disjuncts in the *opposite* order to the one
    assumed; replaced by `cases hcase : thresh t (…)` with named `| false`/`| true`
    branches, which cannot be got backwards. (b) `failed to synthesize
    Decidable (Sorts batcher8 Bool)` — `Sorts` and `IsSorted` are `def`s, so
    instance search does not see through them. Fixed with two explicit instances
    (`decidableIsSorted`, `decidableSorts`), both `inferInstanceAs`, deliberately
    **not** `by unfold …; infer_instance`: `inferInstanceAs` is a definitional
    unfolding, so the kernel's reduction goes straight to
    `Fin.decidableForallFin` / `Fintype.decidableForallFintype` with no `Eq.mpr`
    in the path.
  - Cycle 2 — the `maxRecDepth` hit at `n = 8` above; resolved by `+kernel` after
    measuring both routes rather than guessing.
  - Cycle 3 — green.
  - The three commutation lemmas (`applyComp_comp_monotone`,
    `runNet_comp_monotone`, `monotone_thresh`) went through **first attempt**.
- **Network correctness was checked outside Lean before being encoded** — a
  20-line Python exhaustive pass over all 2^8 Boolean inputs plus 20 000 random
  `Nat` vectors, for both `batcher8` and `batcher4`, all clean. This is why cycle
  1 contained no "the network is wrong" failure: the literal was known-good
  before the kernel saw it. (The Python is a scratch artifact, not committed; the
  Lean theorems are the claim.)
- **Build:** `saltbuild.sh SaltWorks.Stack.ZeroOne` → `saltbuild EXIT=0`,
  675 jobs, **0 warnings** (fresh rebuild with the `.olean` deleted, grepped).
  Full `saltbuild.sh` from `saltworks` → `saltbuild EXIT=0`, 8614 jobs.
- **Axioms:** all 28 declarations audited two ways — `#audit_axioms` in-file (the
  build-failing assertion, repo convention per `HDL/Opt.lean`, `HDL/ISA.lean`),
  and an out-of-band `#print axioms` sweep in `ScratchMATHS3A.lean` (gitignored,
  not committed). They agree. Every declaration is a subset of
  `[propext, Classical.choice, Quot.sound]`; the definitions and the three
  commutation lemmas use strictly fewer (`zeroOne_principle` itself is
  `[propext, Quot.sound]` — it never touches choice). Only the `decide`-backed
  finite checks reach all three. No `sorry`, no `native_decide`, no new axioms.
- **Honest line count:** 352 lines total — **106 lines of definitions and
  proofs**, 7 lines of `#audit_axioms`, 239 lines of docstrings / module header /
  blanks. The header is long on purpose: it carries the carrier decision, the
  `2^24` sharing argument, and the `+kernel` ≠ `native_decide` distinction, all of
  which a reader will otherwise re-litigate.

### Left undetermined

- **`SaltWorks.Stack.ZeroOne` is NOT in `SaltWorks.lean`** — import owed to the
  maestro (in the commit message). Until swept, the module is not covered by the
  default full build and must be built targeted. Note the consequence: the
  `EXIT=0` full build above **did not compile this module**; the targeted build
  did.
- **The `2^24` collapse is measured, not proved.** The claim "the kernel's `whnf`
  cache is structural, so the tower collapses" is inference from Lean's C++ type
  checker plus a 3.5 s wall clock. If a future toolchain changes that cache, this
  file's `decide` will not fail *wrongly* — it will just stop terminating in
  reasonable time. The remedy is on record above (strict `Vector`/`List` carrier),
  not discovered under pressure.
- **`n = 16` was not attempted.** The cost curve here is one data point at
  `n = 8` (3.5 s, 256 cases, 24 comparators); `n = 16` is 65 536 cases and 80
  comparators, so a naive extrapolation is ~10^3× and almost certainly a genuine
  memory event. If a 16-wire sorter is ever wanted, the honest route is a
  *proof* of Batcher's construction by induction on `k`, not a bigger `decide` —
  and the 0-1 principle landed here is exactly the lemma that proof would consume.
- **No connection to `Spec.lean` (S1) was made**, deliberately and per brief. The
  bridge — `Sorts batcher8 Word` versus S1's `SortsTo`/`SortedW` — is real work
  and belongs to whoever composes S1 with S3(a). Two gaps to expect there: this
  module proves *sortedness of the output at each index*, and says nothing about
  **permutation** (a comparator network is obviously a permutation, but that is an
  unproved theorem in this file); and S1's `wle` is the **signed** `BitVec.toInt`
  order, so the `LinearOrder Word` instance handed to `batcher8_sorts` must be the
  signed one, not `BitVec`'s default unsigned `≤`. **That mismatch is the most
  likely way to compose these two modules incorrectly.**
- **`Sorts` takes `α` explicitly, `zeroOne_principle` takes it implicitly.** Not
  an oversight — `sorts_of_sorts_bool h α` reads better with the carrier named,
  and `zeroOne_principle h v` infers it from `v`. If S3(b) finds this irritating
  it is a free change.
