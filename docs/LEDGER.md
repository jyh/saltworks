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

---

## STACK-S3(a)-2 — comparator networks PERMUTE (one proof, two lanes)
**2026-08-07 · Opus executor · `SaltWorks/Stack/Perm.lean` (new module)**

### What landed

The half of `SortsTo` that `ZeroOne.lean` did not prove. Twenty-nine
declarations, all sorry-free, all audited.

- **The core.** `runNet_perm : ∃ σ : Equiv.Perm (Fin n), runNet net v = v ∘ σ` —
  at arbitrary `n`, arbitrary `net`, arbitrary `α : Type u` in an arbitrary
  universe with `[LinearOrder α]`, matching `zeroOne_principle`'s generality
  exactly. Built on `applyComp_perm`, whose witness is `Equiv.refl` when the pair
  is already ordered and `Equiv.swap c.1 c.2` when it is not.
- **The consumers' forms.** `runNet_ofFn_perm` /`ofFn_perm_runNet`
  (`List.Perm`, both orientations), `runNet_ofFn_multiset` (multiset equality),
  `runNet_ofFn_nodup` and `runNet_injective` (KB3).
- **The carrier bridge.** `isSorted_iff_pairwise_ofFn` — `IsSorted` on
  `Fin n → α` is `List.Pairwise (· ≤ ·)` on `List.ofFn`.
- **The combined general statement.** `sortsTo_ofFn_of_sorts_bool`, and
  `batcher8_sorts_perm` / `batcher4_sorts_perm`.
- **⭐ The deliverable at S1's order.** `batcher8_sortsTo_word`,
  `batcher4_sortsTo_word`, `batcher8_sortsToV_word` — literally
  `SortsTo (List.ofFn v) (List.ofFn (runNetW batcher8 v))` and its `Vector` form.

### Why the `Equiv.Perm` form, and not the multiset or `List.Perm` form

The brief said to pick the form that COMPOSES. Only one of the three does.
`runNet` is a `foldl`, so the induction must apply the tail's conclusion to a
*different* input — the already-comparator'd `applyComp c v`. On the `Equiv` form
that step is `(v ∘ σ) ∘ τ = v ∘ (τ.trans σ)`, closed by `rfl`. On a multiset or
`List.Perm` form the induction hypothesis hands back a *relation*, not a
rearrangement, so there is nothing to compose with and the cons step stalls. The
weaker forms are each one line downstream of the strong one, so nothing was lost
by taking it first — and `σ` is exactly the data BB-1's routing story wants.

One order trap inside the core proof, found by the elaborator rather than by
thought: it is `τ.trans σ` and not `σ.trans τ`. `Equiv.trans` applies its FIRST
argument first, and the head comparator's `σ` acts on the result of the tail's
`τ`. Noted in the docstring so the next reader does not re-derive it.

### ⭐ THE ORDER-INTERFACE FINDING — and it is worse than the brief guessed

The brief asked whether the combined statement can be instantiated at S1's signed
order. Three facts, all measured:

1. **`Sorts batcher8 Word` does not elaborate.** There is no `LinearOrder Word`
   instance, by S1's deliberate design. Confirmed: mathlib's `Mathlib/Data/
   BitVec.lean` registers only `CommSemiring`/`CommRing`; `grep -F LinearOrder`
   over it returns nothing. So the two modules genuinely do not compose on
   their own.
2. **⚠️ The obvious fix is a SILENT WRONG ANSWER.** The natural move is
   `letI := wordSignedOrder` and then plain `≤`. That does not do what it looks
   like. Probed with `set_option pp.explicit`:
   `fun (a b : Word) => letI := wordSignedOrder; a ≤ b` elaborates to
   `@LE.le Word (@instLEBitVec 32) a b` — **core's UNSIGNED order**. Typeclass
   search answers the `LE Word` goal from `BitVec`'s own direct instance and
   never walks down `LinearOrder → PartialOrder → Preorder → LE` from the local
   bundle. The first attempt at `wordSignedOrder_le` was written this way and
   failed `Iff.rfl`; that failure is what exposed it. It is now pinned as a
   kernel certificate, `letI_le_is_still_unsigned`: signed, `-1 ≤ 1` holds, and
   the `≤` a `letI` block actually elaborates rejects that pair. If a toolchain
   ever changes the resolution order, that theorem fails the build and the
   warning gets retired deliberately instead of rotting.
3. **The composition works when the bundle is handed over by hand.**
   `wordSignedOrder : LinearOrder Word := LinearOrder.lift' BitVec.toInt _` is an
   `abbrev` (Lean requires class-typed definitions to be reducible) and is
   **never an `instance`, not even a `local` one**. `runNetW net v` is
   `@runNet _ Word wordSignedOrder net v`. No `≤` notation appears anywhere in
   the `Word` section. The one place the bundle's `≤` must be recognised as
   `wle` is `wordSignedOrder_le`, spelled through the full projection chain, and
   it is `Iff.rfl` — `LinearOrder.lift'` sets `le := fun a b ↦ f a ≤ f b` and
   `wle a b` is by definition `a.toInt ≤ b.toInt`.

**VERDICT: `SortsTo` for `batcher8` at S1's signed order is REACHABLE and
REACHED** — `batcher8_sortsTo_word`. Nothing was weakened to get there: no global
instance, no `local instance`, no second order behind `≤`. What remains
unreachable, and should, is `SortsTo` from an *inferred* instance.

A bonus for S3(b): the bundle's `min`/`max` unfold to
`if a.toInt ≤ b.toInt then a else b` and its mirror — a select on the negation of
`SLT`, i.e. the only comparison Slice A can build. Pinned as `wordSignedOrder_min`
/ `wordSignedOrder_max` (both `rfl`) rather than left to be rediscovered when a
refinement proof matches against an unexamined `LinearOrder.lift'` field.

### Non-vacuity — the control IS the argument for the node

`applyDup` is `applyComp` with the `max` changed to `min`: one character. Then

- `applyDup_sorts` — the mutation **still sorts** (its output is constant), so
  `ZeroOne.lean`'s conclusion survives it intact;
- `applyDup_not_perm` — the mutation **provably does not permute**: it drops
  `true` and duplicates `false`.

Together: sortedness does not imply the permutation half, so everything in this
module is new content and not a repackaging of `batcher8_sorts`. Three more
controls: `batcher8_perm_not_refl` (Batcher really moves values, so
`runNet_perm`'s witness is not trivially `Equiv.refl`), `batcher8_word_run` (a
concrete signed 8-word run pinned against its literal output, `decide +kernel`),
and `batcher8_word_run_not_unsigned` (that output is NOT unsigned-sorted, because
`-5` is `0xFFFFFFFB` — so `runNetW` demonstrably computes with the signed
comparator).

### What mathlib supplied — and what it did not

FOUND, not proved:

- `Equiv.Perm.ofFn_comp_perm` (`Mathlib/Data/List/FinRange.lean:73`) —
  `ofFn (f ∘ σ) ~ ofFn f`. The entire `Equiv`→`List.Perm` bridge, one line.
- `List.pairwise_ofFn` (`Mathlib/Data/List/OfFn.lean:119`) — the `IsSorted` /
  `List.Pairwise` carrier bridge.
- `LinearOrder.lift'` (`Mathlib/Order/Basic.lean:792`), `List.nodup_ofFn`,
  `List.Perm.nodup` (core `Init/Data/List/Perm.lean:527`), `Multiset.coe_eq_coe`,
  `Vector.toList_ofFn` / `Vector.ofFn_getElem` (core), `Equiv.swap` with
  `swap_apply_left` / `swap_apply_right` / `swap_apply_of_ne_of_ne`.

NOT supplied: mathlib still has nothing on sorting networks, so `applyComp_perm`
and `runNet_perm` are new here, as `zeroOne_principle` was.

### Where it went, and the import owed

**New module `SaltWorks/Stack/Perm.lean`, not an extension of `ZeroOne.lean`.**
The reason is the dependency direction, not taste: the `Word` half needs
`Stack.Spec`, which imports `HDL.ISA`. Putting that import into `ZeroOne.lean`
would drag the ISA into the 0-1 principle — the one module in this campaign that
is pure, reusable mathematics with no machine in it. `Perm.lean` takes the
dependency instead and `ZeroOne.lean` is untouched.

**`SaltWorks.Stack.Perm` is NOT in `SaltWorks.lean`** — import owed to the
maestro (in the commit message). Consequence, stated plainly: the `EXIT=0` full
build below **did not compile this module**; the targeted build did.

### Attempts, build, audit

- **`runNet_perm` and `applyComp_perm`: first attempt, both.** So were all seven
  corollaries, the carrier bridge, and every combined statement.
- **Three declarations needed a second pass, all three in the `Word` section and
  all three the same root cause** — the instance-resolution finding above:
  `wordSignedOrder` (missing `@[reducible]`, i.e. wanted to be an `abbrev`),
  `wordSignedOrder_le` (`letI` picked the unsigned instance), and
  `batcher8_sortsToV_word` (`simpa` could not see `v.toList` as
  `List.ofFn (v[·])`; fixed with `Vector.ofFn_getElem`). No third attempt
  anywhere; nothing flagged.
- **Build:** `saltbuild.sh SaltWorks.Stack.Perm` → `saltbuild EXIT=0`, 679 jobs,
  **0 warnings** (fresh rebuild with the `.olean` deleted, grepped). Full
  `saltbuild.sh` from `saltworks` → `saltbuild EXIT=0`, 8619 jobs; its one
  warning is pre-existing in `HDL/CompareExchange.lean:337`, a file this node
  did not touch.
- **Axioms:** all 29 declarations audited two ways — `#audit_axioms` in-file
  (build-failing) and an out-of-band `#print axioms` sweep in `ScratchMATHPERM.lean`
  (gitignored, not committed). They agree. Every declaration is a subset of
  `[propext, Classical.choice, Quot.sound]`; the `Word`-side results use only
  `[propext, Quot.sound]`, and `letI_le_is_still_unsigned` depends on **no axioms
  at all**. No `sorry`, no `native_decide`, no new axioms.
- **Honest line count:** 454 lines total — **149 lines of definitions and
  proofs**, 11 lines of `#audit_axioms`, 294 lines of docstrings / module header
  / blanks. The header is long for one reason: the instance-resolution finding is
  a trap that costs a wrong theorem if missed, and it belongs where the next
  reader of this module will hit it.

### Left undetermined

- **`SortsRegs` was not touched.** This node closes S1↔S3(a) at the `List`/
  `Vector` level. The register-level spec (`SortsRegs rs s s'`) is about `step`
  and belongs to S3(b)'s refinement, which is where `runNetW`'s `min`/`max` meet
  `SLT`.
- **`runNet_perm` gives `∃ σ`, never a *named* `σ`.** Nothing here computes the
  permutation Batcher's network induces on a given input, and nothing needs to.
  If BB-1 later wants the routing map as data rather than as an existential, the
  honest route is a `def` returning the `Equiv` by the same `foldl`, with
  `runNet_perm` re-derived from it — a rewrite of ~20 lines, not a new idea.
- **The general combined statement is a bare `∧`, not a `def`.** It could be
  packaged as a carrier-generic `SortsToFn`, but `Spec.lean` already owns the
  name `SortsTo` at `List Word` and a second spec-shaped definition in a second
  module is how two specs drift apart. Left as an `∧` deliberately.
- **`applyDup`'s controls are at `n = 2` over `Bool`.** That is enough to break
  the implication (one counterexample suffices), but it is not a claim about how
  a *whole* mutated network behaves. No such claim is made.

---

## STACK-B2M — the `StrictMonoOn` bridge (sorted ∧ distinct ⇒ the banyan's hypothesis)
**2026-08-07 · Opus executor · `SaltWorks/Stack/Perm.lean` (new Step 5) + `SaltWorks/Stack/Bridge.lean` (new module)**

### THE VERDICT FIRST — `banyan_selfrouting` APPLIES, END TO END

No blocker. `SaltWorks/Stack/Bridge.lean` calls
`SaltWorks.Banyan.banyan_selfrouting` on a Batcher-sorted destination vector and
lands its full conclusion:

```lean
theorem batcher8_banyan_selfrouting {k : ℕ} (hn : 8 ≤ 2 ^ k) {v : Fin 8 → ℕ}
    (hi : Function.Injective v) (hlt : ∀ i, v i < 2 ^ k) :
    (∀ m ≤ k,
        Set.InjOn (fun s => Banyan.line m s (extendIio 0 (runNet batcher8 v) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line k s (extendIio 0 (runNet batcher8 v) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (runNet batcher8 v) s)
        = extendIio 0 (runNet batcher8 v) s)
```

Read the surviving hypotheses, because that is the node: **`hdest` is gone.**
What the caller still owes is distinctness of the destinations, the address
bound, and `8 ≤ 2 ^ k`. Sortedness — the hypothesis nothing in the campaign
could previously discharge — is now discharged by the network itself.

### What landed, and where

**In `Stack/Perm.lean`, as Step 5 — the reusable part (19 declarations).**

- `extendIio (d : α) (v : Fin n → α) : ℕ → α` — the carrier bridge as data:
  `v` below `n`, the junk value `d` at and above it, with `extendIio_apply` /
  `extendIio_of_le` pinning both branches.
- `strictMono_of_isSorted_of_injective` — ⭐ the mathematical content, and it is
  one mathlib lemma wide (see below).
- `strictMonoOn_extendIio` — the carrier half: `StrictMono v` on `Fin n` ⇒
  `StrictMonoOn (extendIio d v) (Set.Iio n)`. Not on all of `ℕ`; the junk breaks
  that, and `Set.Iio n` is exactly the region the router quantifies over.
- `strictMonoOn_extendIio_of_isSorted` — the two composed, still generic.
- `runNet_forall` — a network preserves any pointwise property of its wires
  (`runNet_perm` used as a transport lemma). The router consumes it at
  `p := (· < 2 ^ k)`, i.e. the address-width side condition.
- `strictMonoOn_extendIio_runNet` — ⭐ **the bridge at the network**: a network
  passing `ZeroOne.lean`'s Boolean check, on a distinct input, produces the
  router's hypothesis. Both landed halves are consumed and neither is optional:
  `zeroOne_principle` for the `≤`, `runNet_injective` for the `≠`.
  `strictMonoOn_extendIio_runNet_of_nodup` is the same with the hypothesis in
  KB3's `Nodup` shape (`List.nodup_ofFn` is an `Iff`, so nothing is lost).
- `banyanHyps_of_sorts_bool` / `batcher8_banyanHyps` — ⭐ **everything
  `banyan_selfrouting` needs except `hn`**, as a bare `∧`, with the bound left
  general at `B` rather than fixed at `2 ^ k` (the bound plays no arithmetic role
  on this side of the seam).

**In `Stack/Bridge.lean`, the application (4 declarations):**
`banyan_selfrouting_of_sorts_bool`, `batcher8_banyan_selfrouting`,
`batcher8_banyan_selfrouting_of_nodup`, and one control.

### THE CARRIER DECISION — generic, and it was not contorted

**Route (a): stated generically, instantiated at `ℕ` only where the router
forces it.** Everything through `strictMonoOn_extendIio_runNet` is at general
`n` and general `α : Type u`: `extendIio` is carrier-polymorphic,
`strictMono_of_isSorted_of_injective` asks for `PartialOrder α`,
`strictMonoOn_extendIio` for `Preorder α`. `ℕ` enters exactly twice — at
`banyanHyps_of_sorts_bool`, because `banyan_selfrouting`'s `dest` is `ℕ → ℕ`,
and at the applications.

The reason it is not contorted: `StrictMonoOn f s` constrains only the *domain*
order (`ℕ`, fixed by the router) and the *codomain* order (free). So the
generality costs nothing — there was no point where `α := ℕ` would have made a
proof shorter.

**The junk value is explicit (`d`), not an `Inhabited α`.** A consumer should be
able to see which value it is handing over; the routing lane passes `0`.
`extendIio_of_le` is kept so nobody reads this function as secretly total.

### The two conjuncts, and which module owns which

The brief's framing held up exactly. `IsSorted` is **non-strict** by design —
a comparator network sorts *multisets*, and a repeated value stays repeated — so
`ZeroOne.lean` cannot reach `StrictMonoOn` on its own at any `n`. The `<` comes
from injectivity, which is a **permutation** fact and lives in `Perm.lean`. The
bridge is the first place in the campaign where both landed theorems are needed
and neither suffices.

### Non-vacuity — four controls, all of them `¬`

Each is a proof that the goal is **FALSE**, not unreachable.

- `dup_isSorted` + `dup_not_strictMonoOn` — ⭐ the pair that carries the
  argument. `![1, 1] : Fin 2 → ℕ` **is** `IsSorted`, and its extension
  **provably fails** `StrictMonoOn` at `(0, 1)`. So the `Function.Injective`
  hypothesis is load-bearing and `ZeroOne.lean` alone cannot reach the router.
- `swap_injective` + `swap_not_strictMonoOn` — the mirror: `![1, 0]` is
  injective and fails for want of sortedness. Neither half can be dropped.
- `batcher4_dup_run` + `batcher4_dup_not_strictMonoOn` — ⭐ the sharpest one,
  and the one that is about the *network* rather than about an abstract vector:
  `![0, 0, 1, 2]` is already sorted, so Batcher's 4-wire network returns it
  unchanged (pinned against the literal by `decide`), and the extended output
  fails `StrictMonoOn`. **Running the network does not repair a duplicate**, so
  `hi` cannot be dropped from `strictMonoOn_extendIio_runNet` itself.
- `batcher4_run` + `batcher4_strictMonoOn` — the positive side: a genuinely
  scrambled distinct input (`![3, 1, 2, 0]` ↦ `[0, 1, 2, 3]`, pinned), on which
  the bridge fires. The network had to move the values.
- `banyan_conflict_of_const` (in `Bridge.lean`) — the conclusion is not free
  either: `no_conflict`'s `Set.InjOn` fails outright for a constant destination
  map at stage `m = 0`, where `line 0 s d = d`.

### The software lane is untouched

`Spec.lean`'s `SortsTo := SortedW ∧ PermW` was not weakened, restated, or
re-derived, and `batcher8_sortsTo_word` is byte-identical. **No common parent
was introduced, and one should not be.** The two forms are not two views of one
statement: `SortsTo` is a relation between an input list and an output list and
is *permutation*-based; `StrictMonoOn` is a property of a single function on an
initial segment and is *injectivity*-based, which `SortsTo` deliberately does
not require (the software lane must sort inputs with repeats — that is the
normal case for a sorter). A parent would have to carry injectivity as an
optional field, which is a `∧` wearing a hat. Left as two statements.

### What mathlib supplied — and what it did not

FOUND, not proved:

- `Monotone.strictMono_of_injective` (`Mathlib/Order/Monotone/Defs.lean:232`) —
  **the entire mathematical content of the bridge.** `IsSorted v` is `Monotone v`
  *definitionally* on `Fin n` (both are `∀ i j, i ≤ j → v i ≤ v j`), so
  `strictMono_of_isSorted_of_injective` is one term with nothing to prove.
  `MonotoneOn.strictMonoOn_of_injOn` (`Order/Monotone/Basic.lean:237`) was found
  first and is the `On`-flavoured alternative; it was **not** used, because
  doing the strictness on `Fin n` and the carrier change afterwards keeps the
  two concerns in separate lemmas.
- `List.nodup_ofFn` (`Mathlib/Data/List/FinRange.lean:52`) — the `Nodup` ↔
  `Injective` translation, an `Iff`.
- `Fin.mk_lt_mk`, `Set.mem_Iio`, `dif_pos` / `dif_neg`, `Nat.not_lt`.

NOT supplied: nothing about sorting networks, as before. And nothing connects a
sorted-and-distinct vector to a routing hypothesis — that composition is this
node.

**Two narrow imports added to `Perm.lean`**: `Mathlib.Order.Monotone.Defs` and
`Mathlib.Order.Interval.Set.Defs`. Deliberately `Defs` and not `Basic` — the
`Basic` files were read and nothing in them is needed.

### Where it went, and why the node is split across two files

**`Stack/Bridge.lean` is a separate module and holds only the four application
theorems.** The reason is an import, not taste: `Banyan/SelfRouting.lean` opens
with `import Mathlib` — the whole library. `Stack/Perm.lean` is the module whose
subject *is* instance hygiene (its header is a warning about `letI` silently
electing the unsigned order on `BitVec`), and pulling a universe of instances
into it to reach one theorem is exactly the risk that header exists to name.

So the split is: **all the reusable content in `Perm.lean`**, which the hub
builds and the full build therefore checks; **the full-Mathlib dependency
confined to `Bridge.lean`**, which is four one-term theorems and a control.

**The import is owed** — but it was already anticipated. Another seat added
`import SaltWorks.Stack.Bridge` to `SaltWorks.lean` in the shared working tree
at 11:53 today (uncommitted, along with three `HDL` modules); this seat did not
touch the hub. Stated plainly: the full build recorded below ran **before** that
edit and therefore did **not** compile `Bridge.lean` — the targeted build did.

### Attempts, build, audit

- **19 of 23 declarations: first attempt.** The whole Step 5 chain and every
  control went through on the first serious pass.
- **One correction, one cause.** `banyanHyps_of_sorts_bool`'s second conjunct
  failed with an application type mismatch: `runNet_forall`'s predicate `p` is a
  higher-order metavariable and unification could not invent
  `fun x => x < B` from the goal. Fixed by naming it —
  `runNet_forall (p := fun x => x < B)`. Second attempt, green. Nothing else was
  retried and nothing was flagged.
- **The statement shape was not iterated at all** — one pass. The brief's
  decomposition (strictness on `Fin n`, carrier afterwards) was taken as written
  and did not need revising.
- **Build:** `saltbuild.sh SaltWorks.Stack.Bridge` → `saltbuild EXIT=0`, 8586
  jobs (this compiles `Perm.lean` too). Full `saltbuild.sh` from `saltworks` →
  `saltbuild EXIT=0`, 8620 jobs; **one** warning in the whole log, the
  pre-existing `HDL/CompareExchange.lean:337` (`st₀` not explicitly referenced),
  a file this node did not touch. Zero warnings in `Stack/Perm.lean` and
  `Stack/Bridge.lean`.
- **Axioms:** all 23 declarations audited two ways — `#audit_axioms` in-file
  (build-failing) and an out-of-band `#print axioms` sweep in `ScratchMATHB2M.lean`
  (gitignored, not committed). They agree. Every declaration is a subset of
  `[propext, Classical.choice, Quot.sound]`; `extendIio`, `extendIio_apply` and
  `extendIio_of_le` depend on **no axioms at all**, and the four `decide`-shaped
  controls come in at `[propext, Quot.sound]`. No `sorry`, no `native_decide`, no
  new axioms. The sweep also re-checked the three consumed results
  (`zeroOne_principle`, `runNet_injective`, `Banyan.banyan_selfrouting`).
- **Honest line count.** `Perm.lean` **+210 lines**: the Step 5 region is 177
  lines of which **73 are Lean** (statements and proofs, 19 declarations) and 75
  are docstrings; plus 2 imports, 8 `#audit_axioms` lines, and ~25 lines of
  module-header prose explaining why the two conjuncts live in two modules.
  `Bridge.lean` **123 lines**: **38 lines of Lean** (4 declarations), 60 lines of
  header and docstrings, 2 audit lines, 24 blank. So the node is **111 lines of
  Lean** in total, and the docstrings outweigh them — which is the right ratio
  for a seam whose whole difficulty is knowing which hypothesis comes from where.

### Left undetermined

- **No payload travels with the destinations.** `banyan_selfrouting`'s conclusion
  is about `line` — which link each source occupies at each stage — and that is
  all that is claimed. Nothing here says a *packet* arrives; that is the
  composed-switch statement in `docs/bb1-composed-switch-addendum.md`, and it
  needs the payload to be carried alongside the address by the same permutation.
  `runNet_perm`'s `σ` is the handle for that and it is still an existential.
- **The concentrated-input assumption is inherited, not discharged.** The router
  requires the active sources to be exactly `{0, …, n-1}`; the network is fed a
  total `v : Fin n → ℕ`, so this is satisfied by construction here, but a real
  switch with idle inputs needs a *concentrator* in front and this node does not
  build one.
- **`extendIio` is not the only carrier bridge one could want.** A consumer
  holding a `Vector` rather than a `Fin n → α` pays one `Vector.ofFn_getElem`
  hop, as `batcher8_sortsToV_word` already does. No `Vector` form was added
  because nothing asked for it.
- **The address bound is `∀ i, v i < B` on the *input*.** It transports to the
  output through `runNet_forall`. If a future caller has the bound only on the
  output, the same lemma runs the other way through `runNet_perm`, but that
  direction was not stated.

### Addendum, same session — the import is no longer owed, and the full build now covers it

Written minutes after the entry above and correcting it, because the shared tree
moved: another seat committed the hub line as **`ae70384`** ("hub +4"), so
`import SaltWorks.Stack.Bridge` is in `SaltWorks.lean` on `master` and the "owed"
note is settled. The full build was therefore re-run **with `Bridge.lean` inside
the hub closure**: `saltbuild EXIT=0`, **8624 jobs**, `Bridge.lean` present in the
log with its four `#audit_axioms` lines, and the same single pre-existing warning
(`HDL/CompareExchange.lean:337`) and no other. So every declaration of this node —
both modules, all 23 — is now checked by the plain full build.

---

## S0/R2 — THE MEMORY-MODEL CENSUS (read-only; the fork priced)
**2026-08-07 · Opus executor · `docs/s0-r2-memory-census-0807.md` (new doc)**

Read-only node by construction: **no `.lean` written, no build run, no existing
file changed.** Deliverable is one document plus this entry. Format was
pre-registered on the fleet bus before any answer existed — six sections, fixed
order — so the census could not be shaped to its conclusions.

### What I checked, and how

- **`grep -F` throughout**, and **every absence claim ran in a batch carrying a
  positive control in the same invocation**, with the control's non-zero count
  reported beside it. The negatives that matter: `def wS` → 0 files, `def
  compile` → 0, `def core` → 0, `Mem` → 0, `.LW`/`.SW` → 0; controls in the same
  batch `def step` → 4, `structure St` → 1, `BitVec 32` → 9. Two apparent hits
  were run down and are prose: `mem :` is 19 × `have hmem :` in `Renumber.lean`;
  `LOAD`/`STORE` are the phrases "LOAD-BEARING", "PARTIAL LOAD", "`x0` IS NOT
  STORED".
- **Every cited line re-located by name**, not carried from an earlier read —
  five seats commit here concurrently.
- **USE vs PROSE tagged on every §1 claim.** The distinction did real work twice:
  `run`'s bound (PROSE, and only PROSE) and the layout freeze in `StateCodec`.

### What was RE-VERIFIED (already on the bus, not rediscovered)

`SaltWorks.ISA.St` at `ISA.lean:72` is `regs : Vector (BitVec 32) 32` + `pc :
BitVec 32`, no memory field. `SaltWorks.ISA.Instr` at `:80` is exactly `ADD`,
`ADDI`, `XOR`, `SLT`, `BEQ`. Both confirmed at the bytes, both exactly as the
evidence seat reported (`docs/EVIDENCE-stack-refuter-0807.md` §1).

### What was FOUND (the census's own work)

1. **The machine is neither Harvard nor von Neumann — it has zero memories.**
   Data is 32 registers; **code is a Lean `List Instr` passed as an argument to
   `fetch` (`ISA.lean:131`) — a host-language value the machine's state cannot
   name.** So S2's "memory image" names a thing with no *type* anywhere in the
   tower, not a missing feature.
2. ⭐ **The register-resident path is not a fallback — it is already half-built.**
   `SaltWorks.Stack.SortsRegs` (`Stack/Spec.lean:329`) is landed, its file header
   (`:57–63`) already states "no memory ⇒ fully-unrolled fixed-`n`", and
   `batcher8_sortsToV_word` (`Stack/Perm.lean:396`) is S3(a) at `n = 8` over
   `Word`. ⇒ **S2 is unblocked today with zero changes to any landed theorem.**
3. ⛔ **A landed kernel theorem goes FALSE the day loads/stores are added:**
   `slice_a_excluded_rejected` (`SpikeVectors.lean:558`) asserts `decode` rejects
   all 22 words of `sliceAExcluded`, and four of them are `lw`/`sw`/`lb`/`sb`
   (`:536–539`). Fixing it means moving those rows into the witnessed suite with
   Spike-confirmed post-state **including memory** — which the `Vec` format
   (`Vectors.lean:43`) has no columns for. **The C2 differential harness, not the
   ISA, is on the critical path of any memory work.** Nobody was looking there.
4. **No single `St.mem` form serves both consumers.** `BitVec 32 → BitVec 8` is
   the ISA lane's best shape and is **unstateable for the core** — `encD :
   St → List Bool` (`StateCodec.lean:81`) is a finite bit list and a
   function-typed field has no finite encoding, so `decQ_encD` (`:97`) cannot even
   be stated. A port-shaped memory is the core's best shape and **dissolves every
   landed `Stack/**` spec**, all of which are stated over `St`.
5. **The forward-branch precondition is an ASSUMPTION, and the failure mode is
   silent.** Prose at `ISA.lean:149–152` and nowhere else; the machine can violate
   it (`beq_offset_can_be_negative`, `:281`); what discharges it today is the
   *source language* having no loop form (`CodegenSpec.lean:83,86`). For
   agent-written assembly nothing discharges it, and **a truncated `run` and a
   completed `run` are the same value** — `runFor` just returns the state it is
   in.
6. **Word-space arithmetic moves and four documents carry the old number.**
   *(ARITHMETIC, NOT KERNEL-CHECKED.)* Adding 5 loads + 3 stores adds 8 × 2^22
   decodable words: 8,486,912 → 42,041,344, so the ratified fence reads **99.02 %,
   not 99.80 %** (`ISA.lean:651,664–665`; `RegWrite.lean:35–36`;
   `hdl-c4-composition-check-0807.md`; `riscv-core-campaign-v0.md` §C4).
7. **`wI` is not reusable for loads as written** — it hardcodes opcode `0010011`
   **and** funct3 `0#3` (`ISA.lean:372`), and its field lemmas state the constants
   (`:487`, `:503`). "I-type is already covered" is false.

### The rulings the census recommends (recommendations, not rulings)

- **§3 fork: (0) no memory now; (A) data-memory-only when a consumer states an
  `N` registers cannot hold; NOT (B) unified.** (B) kills
  `run_halts_off_the_end` (`ISA.lean:301`), reintroduces the fuel parameter the
  refuter pass deliberately removed (`:137–138`), puts the 99.8 %-of-word-space
  NOP semantics inside the execution loop, and makes the core multi-cycle against
  the campaign's stated "single-cycle v1".
- **§4 form: F0 — no `St.mem` for v1.** If memory must land: `BitVec 32 →
  BitVec 8` for the ISA lane, a port for the core, and the bridging obligation
  written down **before** either is built.

### What I could NOT determine — honest, and §6 of the doc is longer than this

- **The core's memory-port requirements, because the core has no memory port and
  there is no `core`.** `compile`/`core` are zero declarations. §4's second
  consumer was judged against *constraints* — `encD`'s finiteness, `Seq`'s
  `nIn`/`nOut`, and TT's measured *"about 320 DFFs (40 bytes)"* per tile
  (`tinytapeout-dossier.md:207`) against a register file already at 992 flops —
  **not against a port. The hardware side is simply not there to census yet, and
  the constraint that will decide it is flops-per-tile, not proof shape.**
- **Whether `deriving DecidableEq` (`ISA.lean:75`) survives a `mem` field.**
  PREDICTED to break for a function type (no mathlib in `ISA.lean`'s imports;
  2^32 cases even with it) and to be fine for a `Vector`. **Both predictions,
  unverified — this node ran no build.** A three-line Scratch probe settles it.
- **Whether `decide +kernel` stays feasible on a memory-carrying state.**
  Unmeasured; the `[V-ME]` measurement is at 32 registers, and this tree has two
  measured O(n²) walls at core scale (`RegNext.lean:36–48`).
- **Whether my RV32I alignment/endianness statements are right** — I did not have
  `src/unpriv/rv32.adoc` open, and said so in the document rather than letting the
  claims pass as source-grounded. (The opcode/funct3 values I quote *are*
  in-tree-grounded, read off `SpikeVectors.lean:536–539`.)
- **The `N` for S2. No document contains one**, and the entire urgency of the fork
  rests on it.
- **The no-backward-branch predicate and `n ≥ code.length → runFor n = run`** —
  named as the missing object, not attempted; in particular I do not know whether
  the `pc`-increases argument survives `BitVec 32` wraparound.

### Process note

Two things nearly went in as findings and were caught by checking rather than by
review. First, "I-type encoding already exists" — true of the *name* `wI`, false
of the *definition*, which bakes in both discriminating fields. Second, "the
decoder's cone census would blow up with 8 more instructions" — false: the
projection argument at `Decoder.lean:40–56` already covers opcode + funct3, so the
silicon cost of loads/stores is *cheap* and the expensive part is somewhere else
entirely (the flops). **Both errors would have pointed the next seat at the wrong
file.**

---

## STACK-EQSORT — two strictly-increasing lists with the same members are equal

**Seat:** math-acct (math), Opus executor. **Node:** the last step of leg 3's
`mem_allScenarios` (`Silicon/Equiv/ScenarioComplete.lean`), which stopped rather
than guess Mathlib names at this pin. **Landed in:** `SaltWorks/Stack/Perm.lean`
(+106 lines, `git diff --stat`: 4 theorems, 6 controls, one doc block, 4 audit
lines — the doc block is the larger half, and deliberately so).

### What Mathlib ACTUALLY has at v4.32.0-rc1 — the half of this node with the value in it

Two seats have now been surprised by this API, so it is written down rather than
re-derived. All line numbers are `.lake/packages/mathlib/Mathlib/Data/List/Sort.lean`
unless stated.

- **`List.Sorted` genuinely does not exist.** It was replaced — deprecations dated
  2025-11-27 are still in the file — by **four order-specific predicates**,
  `SortedLE` / `SortedGE` / `SortedLT` / `SortedGT` (`:376–397`), and they are *not*
  `Pairwise` abbreviations: they are **defined** as `Monotone l.get` and
  `StrictMono l.get`. `sortedLT_iff_pairwise` (`:421`) is the bridge back to
  `Pairwise (· < ·)`, and it is a `@[grind =]` simp-normal-form lemma.
- **`List.eq_of_perm_of_sorted` does not exist either**, and it is not a single
  rename. It split: `Perm.eq_of_sortedLE` (`:667`, `[PartialOrder α]`) is the
  order-flavoured heir; `Perm.eq_of_pairwise'` (`:307`, `[Std.Antisymm r]`) is the
  relation-flavoured one; core's `List.eq_of_pairwise` is underneath both.
- **⭐ THE BLOCKER'S ACTUAL RESOLUTION, and it contradicts the brief's own
  hypothesis.** The brief warned that `(· < ·)` is not antisymmetric, so the
  antisymm-flavoured lemmas could not apply and a `≤`-detour would be needed.
  **That is false at this pin.** `Mathlib/Order/RelClasses.lean:687` registers
  `instance instAntisymmLt [Preorder α] : @Std.Antisymm α (· < ·)` — vacuously
  true, and *instance-available*. So the antisymm lemmas apply directly to a strict
  order and **no detour is needed.** (`IsAntisymm`/`IsIrrefl` are now deprecated
  aliases of `Std.Antisymm`/`Std.Irrefl`; searching for the old spellings is part
  of why the name-hunt failed.)
- **The exact statement leg 3 wanted is already in Mathlib, twice**, which is why
  no real mathematics was done here:
  - `List.Pairwise.eq_of_mem_iff` (`:321`, `[Std.Antisymm r] [Std.Irrefl r]`) —
    the general-relation form;
  - `List.SortedLT.eq_of_mem_iff` (`:680`, `[PartialOrder α]`) — the order form.

### Route taken: (b), not (a)

The brief offered (a) weaken to `≤` + `Nodup` + perm, or (b) find the strict-order
lemma under another name. **(b), and it is a one-liner** — `instAntisymmLt` makes
`Perm.eq_of_pairwise'` and `Pairwise.eq_of_mem_iff` fire at `r := (· < ·)`
directly. Route (a) was never entered.

And route (a) would have been *worse than slower*: the control `ne_dup_zero` kills
it outright. `[0, 0]` and `[0]` have the same members and are unequal, and `[0, 0]`
**is** `Pairwise (· ≤ ·)` — so the `≤`-only hypothesis does not prove the theorem,
and (a) must carry `Nodup` as a genuinely separate hypothesis. `Std.Irrefl (· < ·)`
supplies exactly that for free on route (b).

### Where it went, and why not a new module

`SaltWorks/Stack/Perm.lean`, appended before the audit block. Two reasons over a
fresh `Stack/SortedEq.lean`:

1. `SEATS.md:5` names this lane `sortedness/permutation`, and `Perm.lean` already
   owns the `List.Perm`/`Nodup` material — the new theorems sit beside
   `runNet_ofFn_nodup`, not in a new silo.
2. **A new module would be invisible to the full build.** `lakefile.toml` has
   `defaultTargets = ["SaltWorks"]` over a single-root `lean_lib`, so `lake build`
   checks only `SaltWorks.lean`'s import closure. A fresh module would be an orphan
   until the maestro swept it in — verified by targeted build only, and *nobody
   else's build would catch a later break in it*. `Perm.lean` is already in the
   closure, so **no `import owed:` line and no `SaltWorks.lean` edit.**

Cost to leg 3: one `import SaltWorks.Stack.Perm`, whose closure is
Mathlib + `HDL.ISA` + `Tactic.AuditAxioms` — no cycle (Stack reaches no Silicon
module), and negligible next to `ScenarioComplete.lean`'s existing `import Mathlib`.

### What landed

| name | shape |
|---|---|
| `eq_of_perm_of_pairwise_lt` | `[Preorder α]`, `Perm l₁ l₂` + both `Pairwise (· < ·)` ⇒ `l₁ = l₂` |
| ⭐ `eq_of_mem_iff_of_pairwise_lt` | `[Preorder α]`, `∀ a, a ∈ l₁ ↔ a ∈ l₂` + both `Pairwise (· < ·)` ⇒ `l₁ = l₂` — **the one leg 3 asked for** |
| `pairwise_lt_filter_range` | `((List.range n).filter p).Pairwise (· < ·)` |
| ⭐ `eq_filter_range_of_pairwise_lt` | ℕ composite: `Pairwise (· < ·) l` + `∀ i, i ∈ l ↔ (i < n ∧ p i)` ⇒ `l = (List.range n).filter p` — **the shape `allScenarios` consumes** |

`Preorder`, not the `LinearOrder` the brief proposed — `instAntisymmLt` is stated
at `Preorder` and nothing else is used, so the generality was free.

### Non-vacuity controls (6)

Both refutations make the conclusion **false**, not unreachable.

- `perm_zeroOne_oneZero` + `not_pairwise_lt_oneZero` + `ne_zeroOne_oneZero` —
  `[0,1] ~ [1,0]`, `[0,1]` is strictly increasing, `[1,0]` is not, and the two are
  unequal. **`h₂` is load-bearing in `eq_of_perm_of_pairwise_lt`.**
- `mem_iff_dup_zero` + `not_pairwise_lt_dup_zero` + `ne_dup_zero` — `[0,0]` and
  `[0]` have the same members, `[0]` is strictly increasing, `[0,0]` is not, and
  the two are unequal. **`h₁` is load-bearing in `eq_of_mem_iff_of_pairwise_lt`** —
  and, as noted above, this is simultaneously the refutation of the `≤`-weakening.

### Attempts, build, audit

**Two attempts, both on syntax rather than mathematics.** Attempt 1 failed on two
things and neither was a proof: `~` is *scoped* notation (`List.Perm` written out
avoids the `open`), and `List.pairwise_lt_range` takes `n` **implicitly** — the
`(n := n)` named argument is required. Attempt 2 was green on every declaration.
The proofs themselves are each a single term application; the expensive step was
the name-hunt recorded above.

- targeted `saltbuild.sh SaltWorks.Stack.Perm` → **EXIT=0**, no errors, no warnings;
- full `saltbuild.sh` → **EXIT=0**, 8627 jobs, no errors, no warnings;
- `#audit_axioms` on all 10 new declarations, in-file and build-failing:
  all `[propext, Classical.choice, Quot.sound]` or a subset (4 of the 6 controls
  are at **0 axioms**).

### The handoff, verified rather than asserted

`mem_allScenarios` was **proved end-to-end in a scratch probe** (`ScratchMATHEQ.lean`,
audited at 3 whitelisted axioms, **deleted, not committed, and leg 3's file was not
touched**) — so the unblock is measured, not predicted. It closes in 8 lines from
`eq_filter_range_of_pairwise_lt` plus the `testBit_maskOf` / `maskOf_lt` already in
`ScenarioComplete.lean`; the proof text went to leg 3 in the handoff report.

One incidental finding for the maestro, not acted on: **`SaltWorks/Silicon/Equiv/
ScenarioComplete.lean` is not imported from `SaltWorks.lean`** — an import is owed,
and until it is swept the module is outside the full build (the scratch probe hit
this as a missing `.olean` and had to build the target explicitly).

---

## C4STMT — the C4 statement, composition-checked (C1+C3's joint artifact)
**2026-08-07 · Opus executor · `docs/c4-statement-composition-check-0807.md` (new doc)**

### What landed

A document, not a module. **No `.lean` file in the tree was modified.** The work
was done in `ScratchC4STMT.lean`, which was **deleted and never committed**.

### What was FOUND vs what was PROVED

**FOUND (the verdict): the composed C4 statement ELABORATES.** Route B
(`SaltWorks.HDL.emitPipeline'_sem`, hypothesis `wf`, observation at the
normalized port list) × option 1 (`SaltWorks.ISA.stepT`, total on words), both
as ratified in `docs/riscv-core-campaign-v0.md:81–94`. `saltbuild EXIT=0`; the
only diagnostics were the two expected `declaration uses 'sorry'` warnings.
⇒ **The freeze's own precondition is met; C1 and C3 may freeze.**

**FOUND: the coercion the brief anticipated does not exist.** `encD : St →
List Bool` never has to become an `Env` on the ratified shape — both sides of
the equation are `List Bool`. And `Env`/`Net` are *reducible* abbrevs of
`Nat → Bool` / `Nat`, so `SaltWorks.HDL.decQ` and `SaltWorks.Silicon.runP`
share one type with no conversion at all.

**FOUND (the one real gap, and it is a layout decision, not a defect): the
instruction word has no input net.** `StateCodec`'s layout fixes `0 … 1055` for
the state and is silent about the fetched word, but option 1 makes `stepT` take
a `BitVec 32`. The statement therefore carries a posited `instrBase`.
Recommendation in the doc: pin `instrBase = stWidth` in `StateCodec`.
🔴 **With a live trap:** `SaltWorks.HDL.wordOf ins` **typechecks** (by
reducibility) and reads register `x0`. Lean cannot catch that one.

**PROVED (one line, kernel-checked, incidental):**
`(normalize (opt c)).outs.length = c.outs.length`, by
`simp [normalize, opt_outs]`. ⇒ Route B's normalized port list is the *same
list positionally*, renumbered — so *"`encD` indexes the NORMALIZED port list"*
costs `compile` nothing extra. **Route B's stated cost is smaller than the
ruling priced it.**

**NEGATIVE CONTROLS, both fired** (pass 1, `EXIT=1`): `sem` applied to a
`Netlist` (v0's own defect) and `encD (stepW …)` (`Option St` vs `St`). The
second is the ratification's receipt — swapping `stepW` for `stepT` is the
*only* edit between the failing probe and the elaborating theorem.

### Attempts

Three scratch passes, no dead ends: pass 1 (controls + negatives, `EXIT=1` by
design), pass 2 clean (`EXIT=0`), pass 3 (+ the length lemma and the `wordOf`
trap, `EXIT=0`). Two cosmetic parse errors in pass 1 — a `/-- -/` docstring
cannot precede a `variable` command.

### Left undetermined (§5 of the doc, in full there)

Whether the statement is **true** — no proof was attempted. Whether
`compile core` can be *given* 1056 outputs at core scale, given `RegNext.lean`'s
own `EXIT=134` finding that `Circ.wf` is quadratic. Whether `instrBase =
stWidth` survives assembly — `Compose.lean`'s `inst_sem` is `#check`ed and
**not proved**, so the input map is posited on top of an unproved combinator.
And whether the memory interface (C1 names one; `stWidth` covers regfile+PC
only) later changes `encD` and hence this statement.

## STACK-S2 — THE PROGRAM: an agent-written bitonic sort in Slice A
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` (new module)**
**`import owed: SaltWorks.Stack.Program`**

### ⭐ AUTHORSHIP RECORD

The campaign's claim is *"unverified agent → verified code → verified compiler →
verified silicon"*. The first link is a claim about **provenance**, so the
provenance is a deliverable. Recorded here and, at greater length, in the
module's own docstring — where it will stay attached to the code.

**Every line of `SaltWorks/Stack/Program.lean` was written by an AI agent**
(Claude, Opus tier, one session, 2026-08-07) working from a written brief. The
split between hand-written and derived:

- **BY HAND:** `cmpEx`, the five-instruction compare-exchange — the 3-XOR swap,
  the register allocation (`x1`–`x8` data, `x9` scratch, `x0` only ever the
  `BEQ` comparand), and the branch immediate. Also the module's prose.
- **DERIVED, NOT TRANSCRIBED:** the 24-comparator order. `batcherSort` is
  `batcher8.flatMap cmpEx` — emitted from *the same `SaltWorks.Stack.batcher8`
  literal* `batcher8_sorts_bool` proves sorts. **No comparator was typed by
  hand**, so the abstract-network ↔ program correspondence is structural, not a
  coincidence S3(b) must re-establish. `emit` is generic in the network.
- **NEITHER:** every numeric claim is kernel-checked, not agent-asserted.

### ⭐ WHAT THE AGENT GOT WRONG

**1. The branch immediate — the brief's number, and the agent's first draft.**
The brief specified `BEQ t, x0, +3`, *"skipping 3 instructions (12 bytes) needs
`imm = 6`"*. **Wrong.** `step`'s `BEQ` adds `bOffset imm = 2 * imm` to the pc
**of the branch itself**, so skipping the three `XOR`s needs `2 * imm = 16`,
i.e. **`imm = 8`**. `imm = 6` lands *on the third `XOR`*, which executes alone
and corrupts the pair. Caught by computing it from `step` rather than accepting
it — which the brief explicitly asked for (*"do not trust my arithmetic"*).

Both halves are committed as certificates rather than deleted:
`skip_immediate_is_eight`, `skip_immediate_six_is_wrong`, and
`offset_six_does_not_sort` — the `imm = 6` program **builds clean, runs to
completion, returns an ordinary state, and does not sort.** `run` is total, so
nothing but a certificate would ever have reported it.

**2. A near-miss of the agent's own making — the forwardness check was almost
vacuous.** The first draft of `branchIsForward` tested `0 < imm.toNat`. A
backward immediate has a large *positive* `toNat` (`-2` is `4094`), so that
check would have **passed every backward branch**. This is S1's signed/unsigned
trap recurring one layer up, in the file whose job is to prevent it. Pinned as
`forwardness_must_be_signed`; the shipped check reads `imm.toInt`.

**3. Two tooling misreadings**, no consequence: `fin_cases` is not in scope in
this import set (a redundant per-index lemma was dropped in favour of the
list-level one), and `decide` cannot close a `List.ofFn` goal containing a free
variable (`List.ofFn_succ` can).

### What landed

**120 instructions = 5 × 24**, and `emit_length` proves the 5 while
`batcher8_length` supplies the 24 — the count is a *fact about the network*, not
a number anyone counted. Assembled by `encode` to `batcherSortWords : List
(BitVec 32)`, 120 words; `decode_batcherSortWords` inverts the whole list
structurally from `decode_encode` (no 120-way enumeration).

**⭐ THE ONE THEOREM THAT DOES REAL WORK — the S3(b) reduction.**
`sortsAllInputs_of_refinesNetwork : RefinesNetwork → SortsAllInputs`, **proved**,
by composing with math's landed `batcher8_sortsTo_word`. Consequence: **S3(b)
never has to argue about `SortedW` or `PermW` at all.** It inherits both and is
left with a pure refinement question — *do 120 instructions under `step` compute
what `runNetW batcher8` computes?* The two lanes meet at the same network literal
precisely because the program was emitted from it. `SortsAllInputs` and
`RefinesNetwork` are committed as `Prop`s (sorry-free, axiom-clean) so S3(b) has
a named target rather than a statement to reinvent.

### The two constraints, settled

**Branchless is NOT EXPRESSIBLE, not merely less clean.** Verified by reading
`ISA.lean`'s constructor list, not assumed: Slice A is exactly five constructors
(`:82–93`) — no `AND`, no `OR`, no `SUB`, no shift. The only `<<<` in the file is
inside `bOffset`, the immediate's own scaling, which no program can execute. A
branchless compare-exchange builds a mask and *ands* it against a difference;
without `AND` the mask cannot be applied and without `SUB` there is no difference.
**So the compare-exchange branches by necessity.**

**Every branch is forward, proved structurally for EVERY network.**
`emit_branches_forward : ∀ i ∈ emit net, branchIsForward i = true` — for any
`net`, not just `batcher8`; `batcherSort_branches_forward` is the corollary. Plus
`beq_skipImm_advances`: taken `+16`, not taken `+4`, both forward, neither
data-dependent. This discharges, for this family of programs, the hypothesis
`run`'s `code.length` bound rests on — `ISA.lean:149` states it as **prose with
no predicate behind it** (S0/R2 confirmed; `beq_offset_can_be_negative` shows the
machine can violate it).

**Plus a semantic receipt.** Every concrete run asserts `pc = 480 = 4 × 120` —
the pc *off the end of the program*. That is the direct evidence the run was not
truncated, which is the failure a backward branch causes and which is otherwise
invisible (a truncated `run` and a completed `run` are the same kind of value).
`run_already_sorted` is the sharpest of these: nothing swaps, so **all 24
branches are taken**, and a single backward one would not reach 480.

### The concrete runs (checks, not the theorem)

Seven, all `decide +kernel`, all cheap — the whole file elaborates in **3.4 s**,
so the anticipated kernel-reduction cost of a 120-instruction `run` **did not
materialise** and is not a finding against the approach.

| certificate | input | why this one |
|---|---|---|
| `run_mixed` | `[3,-1,7,0,-5,2,9,-2]` | S1's own witness; mixed signs |
| `run_mixed_not_unsigned_sorted` | same | ⭐ output is **not** unsigned-sorted — the program demonstrably computes the signed order |
| `run_already_sorted` | `[-5,-2,-1,0,2,3,7,9]` | identity; **all 24 branches taken** |
| `run_reverse_sorted` | `[9,7,3,2,0,-1,-2,-5]` | the opposite branch pattern |
| `run_all_equal` | `[4×8]` | `¬(a <ₛ a)`; the 3-XOR path never runs |
| `run_duplicates` | `[2,1,2,1,2,1,2,1]` | where a value-dropping element would show |
| `run_extremes` | `INT_MIN`/`INT_MAX` with repeats | unsigned, `INT_MIN` sorts *above* `INT_MAX` |

Three of them are stated in the **stronger** form
`… = List.ofFn (runNetW batcher8 v)` (`run_*_matches_network`): not merely
"sorted" but *equal to the abstract network's output, element for element*.
That is `RefinesNetwork` at a point.

**Non-vacuity, committed as positive theorems:** `offset_six_does_not_sort` and
`flipped_comparand_does_not_sort` — two mutants, each one token from the real
thing, each building clean and running to the end, each **provably failing**
`SortsRegs`. So the positive certificates are not trivially true.
(Three further negative controls were run in scratch and all fired: a wrong
output literal, the `imm = 6` program, and the flipped-`SLT` program.)

### `SortsRegs`' in-place assumption — CONFIRMED, no mismatch

`SortsRegs` reads the same `rs` before and after. A register-resident network
sorts in place by construction: the 3-XOR swap writes back to the pair it read.
`dataRegs = [x1..x8]` before and after. `x9` is scratch and is clobbered — it is
deliberately outside `dataRegs`, and the spec says nothing about it, which is the
honest content. `x0` is never a data register and never a temporary.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**, no errors, no warnings in
the file. **41 declarations, all `#audit_axioms`-clean** at
`[propext, Classical.choice, Quot.sound]`; independently re-checked by
`#print axioms` in `ScratchMATHS2.lean` (audit run, EXIT=0, deleted, not
committed). No `native_decide`, no `sorry` in committed code.

The S3(b) statement **elaborates** — probed three ways in the scratch
(`SortsRegs` spelled out, via `SortsAllInputs`, and the reduction applied to a
`sorry`d `RefinesNetwork`); all three typecheck. The bodies were `sorry` and the
file is deleted.

⚠️ **Judged by TARGETED build only.** `lakefile.toml`'s `defaultTargets` is a
single-root lib, so a new module is invisible to the full build until the maestro
sweeps `import owed: SaltWorks.Stack.Program` into `SaltWorks.lean`.

⚠️ **Lane note:** `SaltWorks/Stack/**` is math's writer slot per `docs/SEATS.md:5`.
`Program.lean` was placed there on the maestro's explicit instruction because the
program is the campaign's artifact and must sit beside the network it is emitted
from. No existing file in the tree was modified.

### Left undetermined

Whether the program **sorts** — that is S3(b), and nothing here attempts it.
Whether `RefinesNetwork` is the *easiest* route to it (it is the one that reuses
the most landed work, which is not the same claim). Whether a `decide`-based
attack on `RefinesNetwork` is feasible at all — the input space is `2^256` and
the 0-1 principle does **not** transfer across the refinement boundary, since
`step` is not a comparator network. And the loader: `stOfFn` builds a state
directly rather than compiling to `ADDI`s, so nothing here says how the eight
words *arrive* in the registers — a real gap the moment S5 wants a whole-tile
story.

---

## STACK-S3(b) — the refinement: the obligation as committed is FALSE, and the repair is PROVED

*Opus executor, 2026-08-07. One file touched: `SaltWorks/Stack/Program.lean`,
**+599 / −3 lines** (564 of new material, plus the audit block and two docstring
corrections). Full hub build **EXIT=0**; **41 new declarations, every one
`#audit_axioms`-clean** at `[propext, Classical.choice, Quot.sound]`.*

### ⭐ THE HEADLINE — `RefinesNetwork` and `SortsAllInputs` are FALSE

Not hard, not open. **False**, and the refutation is now a committed kernel
certificate: `refinesNetwork_is_false`, `sortsAllInputs_is_false`.

Both are stated `∀ s : St`, and `St` carries a `pc`. **Nothing constrains it.**
At `s.pc = 480` — the pc *off the end of the program*, which is exactly where
every concrete certificate in the file proudly ends — `fetch` returns `none` on
the first tick, `runFor` returns `s` unchanged, and the obligation degenerates to
*"the eight data registers are already sorted"*. The witness is `offEndState`:
reverse-sorted data with `pc := 480`.

⚠️ **This is the file's own named failure mode, one layer up.** The authorship
record says *"`run` is total, so a wrong branch is silent."* The same totality
makes a **wrong starting pc** silent: `run` outside the code is not an error, it
is the identity, and the identity satisfies nothing. The statement inherited an
entry-point assumption from the concrete runs — every one of which starts from
`stOfFn v`, whose `pc` is `0` (`stOfFn_pc`) — and the assumption was never
written down because in the concrete runs it was never a variable.

**Both `def`s are left EXACTLY as committed**, per the iron rule. Repairing them
is a statement change and belongs to the seat that owns them. What is added is
(1) the refutation, so the falsity is a theorem rather than a note, and (2) the
content S3(b) was actually after, proved:

| landed | statement |
|---|---|
| ⭐ `refinesNetwork_of_pc_zero` | `s.pc = 0 → dataRegs.map (run batcherSort s).get = List.ofFn (runNetW batcher8 (fun i => s.get (dataReg i)))` |
| ⭐ `sortsRegs_of_pc_zero` | `s.pc = 0 → SortsRegs dataRegs s (run batcherSort s)` |

Read with `refinesNetwork_is_false`, the pair says precisely how much the entry
point was carrying: **everything**. `s.pc = 0` is the whole gap, it is
load-bearing rather than defensive, and both halves of that are theorems.

**Recommended repair (NOT applied — the maestro's call):** add `(hpc : s.pc = 0)`
to both `RefinesNetwork` and `SortsAllInputs`. `sortsAllInputs_of_refinesNetwork`
survives the change unedited, and `refinesNetwork_of_pc_zero` discharges the
repaired `RefinesNetwork` immediately.

### ⛔ THE CRUX, and it was not the per-comparator step

**There is no `run`/`runFor` decomposition lemma for the ISA anywhere in the
tower.** (`run_append` in `HDL/Sem.lean` is the *gate-level* `run` — a different
function with the same name.) Writing that algebra was the node.

⚠️ **THE STEP COUNT IS DATA-DEPENDENT.** Each comparator is five instructions,
but the `BEQ` skips the three `XOR`s: **ordered ⇒ 2 ticks, swap ⇒ 5**. Measured
over the file's own inputs:

| input | ticks to `pc = 480` |
|---|---|
| all equal `[4×8]` | **48** — the true minimum, all 24 branches taken |
| duplicates `[2,1,…]` | 66 |
| already sorted | **78** |
| mixed signs | 87 |
| reverse sorted | **90** |
| — | `run` always spends **120** |

So `runFor 120` does **not** align comparator-by-comparator, and no induction
assuming a fixed per-comparator budget can close. `step_count_data_dependent`
pins 48-suffices / 48-does-not / 90-suffices as one kernel certificate — the
control that the fuel algebra is load-bearing rather than decorative.

**What saves it is that the paths reconverge.** Taken lands at `base + 20` via
`bOffset skipImm = 16`; not-taken walks the three `XOR`s to the same `base + 20`.
A comparator is a **20-byte block with a single exit**.

### ⭐ THE TWO LEMMAS

**The fuel algebra** — five declarations, generic in `code`, nothing about
comparators:

```lean
theorem runFor_add (m n : Nat) (code : List Instr) (s : St) :
    runFor (m + n) code s = runFor n code (runFor m code s)
```

**Unconditional — no "enough fuel" side condition.** That surprised me and it is
the reason the decomposition came cheap: *halting is a fixed point*. Once `fetch`
returns `none` the state stops changing (`runFor_of_fetch_none`), so a run that
halts inside the first `m` ticks spends the remaining `n` on a state that
fetches `none`, which is the identity. `runFor_eq_of_halted` is the slack form
that transports a `k`-step result to `run`'s own `code.length` bound.

**The block lemma:**

```lean
theorem cmpEx_block (code : List Instr) (c : Comparator 8) (s : St)
    (h0 : fetch code s.pc        = some (.SLT tmpReg (dataReg c.2) (dataReg c.1)))
    (h1 : fetch code (s.pc + 4)  = some (.BEQ tmpReg 0 skipImm))
    (h2 : fetch code (s.pc + 8)  = some (.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)))
    (h3 : fetch code (s.pc + 12) = some (.XOR (dataReg c.2) (dataReg c.1) (dataReg c.2)))
    (h4 : fetch code (s.pc + 16) = some (.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2))) :
    ∃ k, k ≤ 5 ∧ (runFor k code s).pc = s.pc + 20 ∧
      ∀ i : Fin 8, (runFor k code s).get (dataReg i)
        = @applyComp 8 Word wordSignedOrder c (fun j => s.get (dataReg j)) i
```

The `∃ k` is the data-dependence, quarantined into one existential. **Three
hypotheses it turned out not to need**, each worth recording:

* **no `c.1 ≠ c.2`.** A self-comparator makes `SLT` compute `¬ (x <ₛ x)`, so the
  branch is always taken and the 3-XOR — which would *zero* the register — is
  unreachable. Abstract `applyComp` is the identity there too. They agree for
  free, so the emitter is safe on networks nobody has checked for
  self-comparators.
* **no distinctness of the two registers.** In the swapping branch `SLT` has
  already certified `v c.2 <ₛ v c.1`, hence `v c.1 ≠ v c.2`, hence
  `dataReg c.1 ≠ dataReg c.2`. **The 3-XOR's side condition is derived from the
  branch being taken, not assumed.**
* **nothing about `x9`.** `dataReg_ne_tmp` keeps scratch out of the data.

### The induction — an OFFSET, not a prefix

⚠️ **A prefix does not run in isolation**: `fetch code pc` indexes the *whole*
list by absolute `pc`. So the induction holds `code` fixed and moves an offset:

```lean
def EmbedsAt (code : List Instr) (net : Network 8) (off : Nat) : Prop :=
  ∀ j, j < 5 * net.length → code[off + j]? = (emit net)[j]?

theorem emit_runs (code : List Instr) : ∀ (net : Network 8) (off : Nat) (s : St),
    EmbedsAt code net off → s.pc.toNat = 4 * off →
    4 * off + 20 * net.length < 2 ^ 32 →
    ∃ k, k ≤ 5 * net.length ∧
      (runFor k code s).pc.toNat = 4 * off + 20 * net.length ∧
      ∀ i : Fin 8, (runFor k code s).get (dataReg i)
        = runNetW net (fun j => s.get (dataReg j)) i
```

**Generic in the network and in the enclosing program**, exactly as `emit` is —
a different network compiled by the same emitter inherits this unchanged, and a
program that embeds `emit net` inside more code inherits it too. The
non-wrapping hypothesis is real: `pc` is a `BitVec 32` and its addition wraps
(`toNat_add_of` carries the bound; `480 < 2^32` discharges it for `batcherSort`).

### Non-vacuity

* ⭐ **`refinesNetwork_is_false` + `refinesNetwork_of_pc_zero`** — the sharpest
  control available: the same statement is false without `s.pc = 0` and true
  with it, both kernel-checked. A green `∀` here is evidence, not a shape.
* `step_count_data_dependent` — 48 ticks finish one input and provably do not
  finish another.
* `cmpEx6_does_not_refine`, `cmpExFlip_does_not_refine` — both mutants enter at
  `pc = 0` like everything else, run to completion, and **fail the repaired
  statement**. So `refinesNetwork_of_pc_zero` is a claim a wrong program breaks.

### ⚠️ A FALSE DOCSTRING, CORRECTED

`run_already_sorted` claimed *"no comparator swaps, so **all 24 branches are
taken**"*. **That is false and is now refuted by a certificate in the same file**
(`already_sorted_input_still_swaps`): `batcher8` contains descending comparators
(`(3,2)`, `(7,6)`, `(5,4)`, …), for which an ascending input is out of order, so
**ten of the 24 comparators swap** and the run costs 78 ticks, not 48. The
all-taken input is `run_all_equal`. The table entry above in this ledger
("*identity; all 24 branches taken*") carries the same error and is superseded
here. Comment-only correction; no proof content touched.

### Attempt counts, against the split budget

* **Statement shape: 1 attempt.** The refutation was found by reading
  `RefinesNetwork`'s binder against `fetch`'s absolute indexing, and confirmed
  first try in scratch. Budget was 3–4.
* **Proofs: 1 attempt each, 3 mechanical repairs.** Fuel algebra clean first
  build. Register bookkeeping: one repair (`simp` recursion-depth on
  `dataReg_ne_zero` → `revert; decide +kernel`). Block lemma: one repair
  (`norm_num` is not in this import set → `omega`). Induction: two repairs (a
  stray `rw … at *`, and `(c :: cs).length` un-normalised in the goal). Budget
  was 2 attempts before flagging; none was reached.
* No `sorry` at any point in committed code. No `native_decide`. `bv_omega` is
  used for the pc arithmetic — omega-backed, audit-clean.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**. Full-tree `saltbuild.sh` →
**EXIT=0** (8632 jobs) — `Stack.Program` is now in the hub, so this is no longer
a targeted-only judgement. All 41 new declarations tick `#audit_axioms`;
independently re-checked with `#print axioms` in `ScratchMATHS3B.lean` (audit
run EXIT=0, deleted, not committed).

### Left undetermined

The **loader** is still the open seam: `stOfFn` builds a state directly rather
than compiling to `ADDI`s, so `s.pc = 0` is now discharged wherever `stOfFn` is
the entry (`stOfFn_pc`), but nothing says how the eight words *arrive* in the
registers on real silicon. S5's whole-tile story needs that.

Whether the two `def`s should be repaired in place or deprecated in favour of the
`_of_pc_zero` theorems — a statement call, deliberately not made here.

`emit_runs` is stated for `Network 8` only, because `cmpEx`/`dataReg` are. Nothing
in the proof uses `8`; generalising to `Network n` with `n + 1 < 32` is
mechanical and was not done.

## STACK-LOADER — the entry point is a RESET, not a loader; the seam stated

*Opus executor, 2026-08-07. One file touched: `SaltWorks/Stack/Program.lean`,
**+245 / −0 lines** (one new import, `SaltWorks.HDL.StateCodec`). Targeted build
**EXIT=0**; full hub build **EXIT=0** (8632 jobs, zero errors); **14 new
declarations, every one `#audit_axioms`-clean** at
`[propext, Classical.choice, Quot.sound]`, independently re-checked with
`#print axioms` in `ScratchMATHLDR.lean` (EXIT=0, deleted, never committed).*

### ⭐ THE DEMAND-TRACE VERDICT, in one line

**Option (a) — `stOfFn` as the sanctioned entry — and option (b), a compiled
`ADDI`-prelude, is not merely worse but IMPOSSIBLE; and (a) reinterpreted, because
`stOfFn` is not a loader in the program sense: it is an INITIALISATION, so the
obligation it discharges for free in software becomes a HARDWARE RESET obligation
at the silicon lane, which is what `EntryLoaded` now states.**

### ⛔ OPTION (b) IS DEAD — the byte evidence, checked rather than assumed

An `ADDI`-prelude would have to put an arbitrary `v : Fin 8 → Word` into
`x1`–`x8`. Slice A cannot:

| Fact | Where |
|---|---|
| `ADDI rd rs1 (imm : BitVec 12)`, and `step` applies `imm.signExtend 32` | `HDL/ISA.lean:85`, `:122` |
| ⇒ reachable constants are exactly `[−2048, 2047]` | consequence |
| `Instr` has exactly five constructors: `ADD ADDI XOR SLT BEQ` | `HDL/ISA.lean:80–94` |
| `grep -cE "\| (LW\|LB\|LUI\|AUIPC)" SaltWorks/HDL/ISA.lean` → **0** | measured |
| *"no loads, no stores, no `LUI`/`AUIPC` … no memory model at all"* | `HDL/ISA.lean:78` (the ISA's own exclusion list) |
| `decode_rejects_lui` — the decoder refuses `LUI` too | `HDL/ISA.lean:628` |
| no memory anywhere in the tower | `docs/s0-r2-memory-census-0807.md` |

⇒ **A prelude could only install eight assembly-time constants inside ±2047.**
That is not `∀ v : Fin 8 → Word` — it is a single small example. *Option (b) does
not weaken the theorem, it destroys it.* No prelude was attempted.

### ⭐ AND THE REINTERPRETATION IS THE NODE'S REAL CONTENT

`stOfFn` builds its state from `St.init` (`HDL/ISA.lean:156`), whose `pc` is
already `0`. **Nothing runs to establish `pc = 0`; the state simply has it.** So
`stOfFn_pc` is `rfl` — it was already landed in S3(b) and the "trivial half" of
this node was therefore already done. *The lemma was never the question.*

**The question was who owes it, and the answer changes lanes.** C4's composed
statement (`docs/c4-statement-composition-check-0807.md` §2) reads the machine
state as `SaltWorks.HDL.decQ ins` — decoded from the netlist's **primary inputs**,
the Q-leaves at the flop boundary. On silicon there is no `St.init` and no
`stOfFn`: the state at cycle 0 is whatever the flops hold **out of reset**. ⇒
*`pc = 0` and "the data is in the registers" are a hardware initialisation
obligation.* This is a confirmation of the brief's framing, read off `decQ` and
C4 rather than assumed from it.

### What landed

**The unconditional software theorem** — S2 + S3(b) closed with nothing dangling:

```lean
theorem stOfFn_sorts (v : Fin 8 → Word) :
    SortsTo (List.ofFn v) (dataRegs.map (run batcherSort (stOfFn v)).get)
```

*For every eight-word input, loading it and running the 120 instructions leaves
the data registers holding a signed-sorted permutation of the input.* **No `hpc`,
no `s`, no `pc`** — `v` appears on both sides, so there is no entry-point
assumption left to hide in. Its refinement half, `stOfFn_refines_network`, gives
the stronger `= List.ofFn (runNetW batcher8 v)`; `stOfFn_sortsRegs` is the same
claim in `Spec.lean`'s `SortsRegs` vocabulary. Supporting: `stOfFn_dataReg_eq`
(the eight registers of `stOfFn v` *are* `v`, as a function) and its pointwise
form `stOfFn_get_dataReg`, both derived through `dataRegs_map_stOfFn` and the
`rfl` lemma `dataRegs_map_get` rather than by unfolding eight `St.set`s.

**⭐ THE SEAM, stated and committed** (a `def … : Prop`, the way S2 stated
`RefinesNetwork` — not a `sorry`-ed theorem):

```lean
def EntryLoaded (ins : SaltWorks.HDL.Env) (v : Fin 8 → Word) : Prop :=
  (SaltWorks.HDL.decQ ins).pc = 0 ∧
    ∀ i : Fin 8, (SaltWorks.HDL.decQ ins).get (dataReg i) = v i
```

Phrased against `decQ` so the silicon lane consumes it with no translation step.
**Deliberately minimal** — nothing about `tmpReg`, nothing about the other 23
registers, strictly weaker than `decQ ins = stOfFn v`. `refinesNetwork_of_pc_zero`
uses the pc and the eight registers and nothing else, so asking hardware for more
would be asking for what the proof does not use. *A reset that leaves `x9` dirty
still satisfies it.*

Three theorems make it a contract rather than a wish:

* `sorts_of_entryLoaded` — **it is SUFFICIENT.** From the contract alone the
  program sorts from the decoded state. S5 may compose against `EntryLoaded` and
  never mention `stOfFn`, `St.init` or `pc` again.
* `entryLoaded_encD_stOfFn` — **it is SATISFIABLE.** Witness: `stOfFn v`'s own
  encoding, via the landed round trip `decQ_encD`.
* `not_entryLoaded_offEndEnv` + `offEndEnv_does_not_sort` — **it DISCRIMINATES.**

**⛔ A SECOND OBLIGATION THE TRACE EXPOSED, which was on nobody's list:**

```lean
def DeliversProgram (env : St → SaltWorks.HDL.Env) : Prop :=
  ∀ (s : St) (w : Word), fetchWord s.pc = some w →
      SaltWorks.HDL.wordOf (fun k => env s (SaltWorks.HDL.instrNet k)) = w
```

`run` takes `batcherSort : List Instr` as an **argument** — in the software model
the program is a parameter of the semantics. C4's `stepT : St → BitVec 32 → St`
takes a **fetched word**, delivered on `instrNet 0 … 31`. *A netlist that
satisfies `EntryLoaded` and then reads garbage on the instruction nets computes
garbage, and nothing stated before today notices.* `fetchWord` is the program word
at a byte address in `fetch`'s own convention (alignment included, so the two
cannot drift) and `fetchWord_decodes` is the bridge, structural from
`decode_encode`. Written `wordOf (fun k => env s (instrNet k))` and **not**
`wordOf (env s)` — the latter typechecks and reads register `x0`
(`StateCodec.word_at_zero_is_register_x0`).

### ⭐ WHO OWES WHAT, AND WHAT WOULD DISCHARGE IT

| Prop | Owner | What discharges it |
|---|---|---|
| `EntryLoaded` | **the silicon lane** — reset / power-on state. Not the compiler, not `Stack/Program.lean`. | A reset model pinning the flops' power-on values (**none exists in the tree today** — that is why this is stated and not proved), plus C4's already-listed input-map obligation (`docs/c4-statement-composition-check-0807.md` §4 row 3: *"primary inputs 0 … 1055 are the Q-leaves in `StateCodec`'s layout"*). Given those two, `EntryLoaded` follows exactly the way `entryLoaded_encD_stOfFn` does. |
| `DeliversProgram` | **the tile's assembly** — a ROM or hard-wired words — together with whatever `Compose.lean`'s input map turns out to be. Not C4: C4 is one cycle *given* a word and is silent on where the word came from. | A tile-level netlist carrying the 120 words of `batcherSortWords` indexed by the pc, plus a proof that its output lands on `instrNet`. ⚠️ **There is no memory to fetch from**, so this cannot be discharged by an instruction-memory model — it is a tile-level design decision nobody has made. **This is the larger of the two obligations.** |

### Non-vacuity — the controls

Per this file's standing practice, the positive results are paired with adjacent
things that provably fail.

* `not_entryLoaded_offEndEnv` — `offEndState`'s encoding is a perfectly good wire
  configuration, and the contract **rejects** it (`pc = 480`, not `0`).
* `offEndEnv_does_not_sort` — and the conclusion really is **false** there, not
  merely unproved: the machine fetches nothing, the registers keep their
  reverse-sorted contents, `SortsTo` fails. ⇒ *`sorts_of_entryLoaded`'s hypothesis
  is doing work, and a reset that got the pc wrong would be caught here rather
  than silently produce an unsorted chip.*
* The pre-existing `cmpEx6_does_not_refine` / `cmpExFlip_does_not_refine` already
  cover the wrong-program direction at `pc = 0`; nothing was added there.

### Attempt counts, against the budget

* **Statements: 1 attempt.** Three substantive ones (`stOfFn_sorts`,
  `EntryLoaded`, `DeliversProgram`) plus supporting lemmas and controls; budget
  was 3–4. The minimality choice for `EntryLoaded` (pc + eight registers, not
  `decQ ins = stOfFn v`) was made by reading what `refinesNetwork_of_pc_zero`
  consumes, not by preference.
* **Proofs: 1 attempt, zero repairs.** The whole block built clean on the first
  `saltbuild` of `ScratchMATHLDR.lean` — every proof is one to five lines over
  landed results (`refinesNetwork_of_pc_zero`, `batcher8_sortsTo_word`,
  `decQ_encD`, `decode_encode`). Budget was 2 before flagging; not reached.
  The one deliberate avoidance: `stOfFn_dataReg_eq` goes through `List.ofFn_inj`
  rather than `simp [stOfFn, St.set, St.get]`, because S3(b)'s ledger recorded a
  `simp` recursion-depth failure on exactly that shape.
* No `sorry` at any point. No `native_decide`. `decide +kernel` is used for the
  two controls only, on states whose `pc` is off the end (so `run` is the
  identity and the evaluation is cheap).
* ⛔ **`RefinesNetwork`, `SortsAllInputs` and `SortsRegs` were not touched.** The
  `(hpc : s.pc = 0)` repair remains the maestro's call; every result here is a
  new named declaration alongside them.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**. Full-tree `saltbuild.sh` →
**EXIT=0**, 8632 jobs, zero `error:` lines. All 14 new declarations tick
`#audit_axioms`; re-checked independently with `#print axioms` in
`ScratchMATHLDR.lean` (EXIT=0, deleted, not committed). The one structural change
outside the new block is the added import `SaltWorks.HDL.StateCodec` — no cycle
(StateCodec imports only `HDL.ISA` and `HDL.Sem`, neither of which reaches
`Stack/`), and `SaltWorks.lean` was not touched.

### Left undetermined

* **Whether `EntryLoaded` is TRUE of any real netlist.** It is stated and shown
  satisfiable; it is not discharged, and it should not be until a reset model
  exists. Reading `entryLoaded_encD_stOfFn` as "the seam is closed" would be
  exactly the entry-point assumption S3(b) was caught making.
* **Whether the reset should be modelled at all in v1**, or whether the tile
  should instead take `v` on primary inputs and skip the register-file
  initialisation. That is a tile-architecture call and it is not this node's.
* **`DeliversProgram`'s shape past one cycle.** It is written as a function of
  the machine state, which is the form C5's cycle induction will want, but no
  cycle induction exists yet to confirm that guess.
* **Whether `EntryLoaded` and `DeliversProgram` compose to an S5 statement.**
  They are the two entry-side obligations the trace found; nothing here claims
  they are the *only* ones. C4's §4 lists three more that are C3's.

---

## C5IND — the cycle induction, over an abstract per-cycle step
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` (+474 lines: **218
code**, 191 comment/docstring, 65 blank — counted, not estimated; 36 new
declarations)**

### Why the shape

C4 is *"one cycle of the emitted netlist equals one `ISA.stepT`"*. **It cannot be
stated against a real core today** — `grep -rnE "^(def|theorem|abbrev)
(core|compile)\b"` over `SaltWorks/` returns nothing, so `compile` and `core` do
not exist. This node built the layer *above* C4 that does not depend on it: given
one-cycle equivalence as a hypothesis, `n`-cycle equivalence, and then the whole
program. The netlist half of C4 (`Circ.wf_of_ssa` + `emitPipeline'_sem`) was NOT
rebuilt — it is already generic in `c` and is untouched here.

**Module choice: extended `Stack/Program.lean` rather than opening a new module**,
because a new file is invisible to the full build until the maestro sweeps it into
`SaltWorks.lean`, and `Program.lean` already carries `EntryLoaded` and
`DeliversProgram` — the two obligations this node's third one sits beside.
`SaltWorks.lean` was not touched; nothing outside `SaltWorks/Stack/**` and
`docs/` was written.

### ⛔ THE ANSWER TO THE ASSIGNED QUESTION: `stepT`-ITERATION AND `runFor` ARE **NOT** THE SAME OBJECT

They agree on a region and part company at its boundary, and the boundary is one
thing:

```
runFor  : fetch code s.pc = none  ⇒  HALT.  Halting is a FIXED POINT (runFor_of_fetch_none).
runWords: every cycle steps.  stepT is TOTAL.  There is NO halting word.
```

`runFor` takes the program as an argument and reads it by `pc`; `stepT` takes a
word handed to it on `instrNet` and, by the v1 ruling (`ISA.lean:636-676`), has a
defined NOP-advance on everything it cannot decode. So the netlist has no halt
state at all. Precisely:

* **Where they agree** — `runWords_eq_runFor`, and its hypothesis is the exact
  price: for **all** `k < n`, the fetch must succeed *and* the stream must carry
  that instruction's encoding. There is no version without the `k < n` binder.
* **Where they diverge** — `runFor_halts_where_runWords_runs_on`, kernel-checked
  at `offEndState`: `runFor n batcherSort offEndState = offEndState` for **every**
  `n`, while ten cycles of the wires move the pc from 480 to 520.

⚠️ **The boundary is the common case, not a corner case.** `step_count_data_dependent`
(landed earlier) pins that this program finishes in **48 to 90** steps depending
on the data while `run` spends 120. On a fixed-length silicon run the machine is
past the end of its own program for 30–72 cycles of *every* execution.

⇒ **THIS IS THE SAME `DeliversProgram` GAP, ONE LAYER DOWN, AND IT HAS A SECOND
HALF NOBODY HAD WRITTEN DOWN.** `DeliversProgram` is stated only where
`fetchWord` returns `some`. It is **silent** past the end of the program. A tile
that satisfies `EntryLoaded` and `DeliversProgram` and then presents live
instructions on the instruction nets computes garbage, and nothing stated before
today notices. `FeedsProgram`'s second conjunct is that obligation, named.

**And the obligation is cheap — that is a theorem, not a hope.**
`runWords_get_of_undecodable`: a word the decoder rejects touches no register at
all. `decode_zero`: the all-zero word is one. ⇒ **a ROM reading zero outside
`[0, 480)` discharges it.** `noisy_tail_overwrites` is the control: a tile that
instead re-presents a live instruction has the answer overwritten a little more
every cycle (`1` after one cycle, `4` after four).

### What landed

**The two n-step objects** (both left folds, so they compose index-by-index):

- `runWords (ws : Nat → Word) : Nat → St → St` — `n` `stepT`s driven by a word
  stream. With `runWords_succ`, `runWords_add` (the stream splits *with a shift*).
- `cycles (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env) : Nat → Env → Env`. With
  `cycles_succ`, `cycles_add`.
- 📌 Note the contrast with `runFor_add`: `cycles_add`/`runWords_add` are
  unconditional **trivially** (nothing halts); `runFor_add` is unconditional for
  a *substantive* reason (halting is a fixed point). Same shape, opposite content
  — the divergence again, seen from the algebra.

**The hypothesis and the induction:**

- `seenWord ins := wordOf (fun k => ins (instrNet k))` — the word the core sees.
  **Not `wordOf ins`**, which typechecks and reads register `x0`.
- `CycleRealisesStep cyc wordAt : Prop := ∀ ins, decQ (cyc ins) = stepT (decQ ins) (wordAt ins)`
  — parameterised in **both** the cycle map and the word source, so it commits to
  no core, no netlist and no fetch path.
- ⭐ `cycles_realise_steps` — **the deliverable**:
  `decQ (cycles cyc n ins) = runWords (fun k => wordAt (cycles cyc k ins)) n (decQ ins)`.
  The ISA side's stream is read off the cycle sequence itself, which is what lets
  the statement need no fetch model.

**The stream contract and the register agreement:**

- `FeedsProgram code ws s K` — two halves: the fetched instruction while `k < K`,
  a word the decoder **rejects** for `K ≤ k`.
- ⭐ `runWords_get_eq_runFor` — given the contract, the wires and the software
  model agree **at the registers** at **any** `N ≥ K`. Stated about `St.get` only,
  deliberately: the pc does *not* agree, it has run away, and saying so is the
  content.

**The bridge to the landed obligation:**

- `fetchWord_eq_encode` — every word this program's fetch produces is an `encode`,
  since `batcherSortWords = batcherSort.map encode`.
- ⭐ `feedsFst_of_deliversProgram` — **`DeliversProgram` IS `FeedsProgram`'s first
  half**, for a tile whose input map is a function of the machine state and whose
  pc stays in the program for `K` cycles. So this node adds exactly one obligation
  to the demand list, not two.

**The payoff:**

- `exists_halting_count` — **the cycle count, exposed.** `refinesNetwork_of_pc_zero`
  discards the `k` that `emit_runs` produces because `run`'s `code.length` bound is
  a software convenience; silicon has no such bound, so the `k` is the load-bearing
  quantity. ≤ 120, halted, registers holding the network's output.
- ⭐⭐ `cycles_sort` — **the C5 sentence, over C4 as a hypothesis**: given
  `CycleRealisesStep`, `EntryLoaded`, and `FeedsProgram`, the eight data registers
  read off the wires through `decQ` at **any** `N ≥ K` are a signed-sorted
  permutation of the input. Everything right of the turnstile is already in the
  kernel (`emit_runs`, `batcher8_sortsTo_word`).

### Non-vacuity — required, and delivered on both hypotheses

Precedent followed: `entryLoaded_encD_stOfFn` + `not_entryLoaded_offEndEnv`.

- **`CycleRealisesStep` is satisfiable** — `cycleRealisesStep_cycOf`. `cycOf` is a
  genuine one-cycle machine (decode the Q-leaves, read the instruction nets, step,
  write the state back and present the next word), built on `envWith` /
  `decQ_envWith` / `seenWord_envWith`, and generic in the next-word policy so it
  smuggles in no fetch model. *It is the trivial witness and is offered as one:
  it is `encD ∘ stepT ∘ decQ` and proves nothing about any netlist.*
- **CONTROL 1 — the stalled cycle FAILS** (`not_cycleRealisesStep_id`). A netlist
  whose flops do not change satisfies nothing.
- 🔴 **CONTROL 2 — the wrong 32 wires FAIL** (`not_cycleRealisesStep_wordOf`). The
  *same* machine `cycOf`, paired with `wordOf ins` instead of `seenWord ins`,
  is refuted: `wordOf ins` reads nets `0…31`, which are register `x0`, which is
  zero, which the decoder rejects — so the machine appears to NOP while the ISA
  executes. This is `StateCodec.word_at_zero_is_register_x0`'s trap converted from
  a warning into a refutation.
- **`FeedsProgram` is satisfiable** — `feedsProgram_addi`, both halves, on a real
  one-instruction program with a zero-filled tail; and `feedsProgram_addi_runs`
  runs the whole machinery end to end: for **any** `N ≥ 1` the register holds the
  answer, which is the shape a fixed-length silicon run has.
- **CONTROL 3 — the quiet half is doing work** (`noisy_tail_overwrites`).

### Attempt counts, against the split budget

* **Statements: 1 attempt each** (budget 3–4). The one design decision that took
  weighing was `FeedsProgram`'s shape: the alternative was to write the induction
  against `run`'s 120-step bound and let the tail be vacuous, which would have
  hidden the finding instead of stating it. The `∃ K ≤ 120` form was chosen
  because the real count is data-dependent (48–90) and hardware runs cycles, not
  `code.length`.
* **Proofs: 1 attempt, 3 line-level repairs** (budget 2 before flagging; not
  reached). All three were tactic mechanics, none a proof-design change:
  `congr 1` on `BitVec.getLsbD` blew `maxRecDepth` (replaced by a `have` + `rw`);
  a `show` did not see through a `def`-shaped stream (`unfold` instead);
  `Option.noConfusion` mis-elaborated at `some x = none` (`absurd … (by simp)`).
* No `sorry` at any point. No `native_decide`. `decide +kernel` is used for the
  divergence, the two `CycleRealisesStep` controls, and the small concrete runs.
* ⛔ **No landed statement was weakened, restated or repaired.** `EntryLoaded`,
  `DeliversProgram`, `RefinesNetwork`, `SortsAllInputs`, `refinesNetwork_of_pc_zero`
  are untouched; every result here is a new named declaration alongside them.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**. Full-tree `saltbuild.sh` →
**EXIT=0**, 8632 jobs, **zero** `error:` and zero `warning:` lines. All 36 new
declarations tick `#audit_axioms`, and were re-checked independently with
`#print axioms` in `ScratchMATHC5.lean` (EXIT=0; deleted, not committed) —
every one inside `[propext, Classical.choice, Quot.sound]`.

### Left undetermined

* **Whether `CycleRealisesStep` is true of any real netlist.** That is C4, and C4
  cannot be stated until `compile`/`core` exist. The hypothesis is shown
  satisfiable and discriminating; it is not discharged, and reading
  `cycleRealisesStep_cycOf` as "C4 is done" would be exactly the entry-point
  mistake S3(b) was caught making.
* **The coherence fact linking the two halves of `feedsFst_of_deliversProgram`:**
  that a tile's input map at cycle `k` really is the `k`-th iterate,
  `env (runFor k code s) = cycles cyc k ins`. That is a statement about a netlist,
  so it belongs with C4 and the tile assembly. It is named in the docstring and
  is **not** proved here.
* **Which tile-level mechanism meets `FeedsProgram`.** A zero-filled ROM
  discharges both halves on paper (`decode_zero` + `runWords_get_of_undecodable`),
  but no ROM exists in the tree and the tile-level decision (ROM vs hard-wired
  words) is still nobody's, exactly as the `DeliversProgram` note already said.
* **Whether three obligations is all of them.** `EntryLoaded`, `DeliversProgram`
  and now `FeedsProgram`'s tail are what the traces found. Nothing here claims the
  list is complete; C4's §4 lists three more that are C3's.

## C4BRIDGE — the missing link between `C4Spec` and `CycleRealisesStep`
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` (+329 lines: **147
code**, 154 comment/docstring, 28 blank — counted, not estimated; 26 new
declarations, 1 new import)**

### The gap this closed

The two lanes had written two halves of one sentence and **nothing joined them.**

* compiler's `HDL.C4Spec c` is about **`sem c ins` — a `List Bool`**, the
  circuit's output ports in port order;
* math's `CycleRealisesStep cyc wordAt` is about a **cycle function
  `cyc : Env → Env` on wires**.

⇒ *even with C4 proved, `cycles_sort` could not have consumed it*, because no
definition said which wires `sem c ins` lands on. `cycOfCirc` is that definition
— output port `j` drives state net `j`, the D→Q transfer in `StateCodec`'s own
layout — and `cycleRealisesStep_of_C4Spec` is the theorem that was missing.

### ⭐⭐ THE SURVIVING HYPOTHESES — the campaign's remaining debt, in one list

`sorts_of_C4` is unconditional in everything except **three** things, and each is
a named lane's:

1. **`SaltWorks.HDL.C4 c`** — the *compiler* lane. Unwitnessable today (`core`
   does not exist). Its `spec` field is all the bridge uses; its `conforms` field
   is owed elsewhere (below).
2. **`EntryLoaded ins v`** — the *reset*, the silicon lane. Satisfiable
   (`entryLoaded_encD_stOfFn`), discriminating (`not_entryLoaded_offEndEnv`).
3. **`FeedsProgram batcherSort (fun k => seenWord (cycles (cycOfCirc c nextW pad) k ins))
   (decQ ins) K`** — the *instruction path*, the tile lane. Satisfiable
   (`feedsProgram_addi`), discriminating (`noisy_tail_overwrites`). By
   `seenWord_cycOfCirc` the stream it constrains is literally `nextW` along the
   cycle sequence, so it is a demand on the tile's ROM and on nothing else.

**And nothing else.** `nextW` (the instruction-net policy) and `pad` (the
behaviour of undriven state flops) are **universally quantified**, so neither is
a hypothesis: the theorem holds for every policy and every undriven-wire
behaviour. No statement above `sorts_of_C4` was weakened, restated or repaired to
get there.

### ⚠️ THE FINDING — the bridge needs `C4Spec` and **not** `CoreConforms`

The brief expected `CoreConforms`'s `outs.length = stWidth` to be the fact that
makes the codec round trip legal. **It is that fact — but `C4Spec` already
implies it**, because `C4Spec` is an equality of *lists* and `encD`'s length is
`stWidth` unconditionally. `outs_length_of_C4Spec` is the derivation:
`C4Spec c → c.outs.length = stWidth`, one `congrArg List.length`.

⇒ the bridge is stated from the **`spec` field alone**, which is the stronger
theorem; `cycleRealisesStep_of_C4` supplies the `C4`-structure interface
compiler's own docstring tells callers to use, and `sorts_of_C4` takes the whole
structure. **Taking `CoreConforms` as a hypothesis of the bridge would have been
a fake dependency** and was rejected on those grounds. `CoreConforms` is still
owed — `ssa` feeds `Circ.wf_of_ssa` and the emission layer, `nIn = coreInWidth`
is the input-map obligation — but **neither of those is a debt of the round
trip.** ⛔ Nothing in `C4.lean` was touched, weakened or restated.

### The undriven-wire model, and why `envOfBits` carries a `pad`

A core with too few outputs leaves the remaining state flops **undriven**, and
defaulting them to `false` would be a fiction that makes C4.lean's 1055-vs-1056
hazard invisible on math's side. So `envOfBits bs pad w` takes an arbitrary
`pad : Env` for the state nets the output list does not reach, and every theorem
is quantified in it. That turns the length obligation into a pair of results
rather than a comment:

* ✅ `cycOfBits_pad_irrelevant` / `cycOfCirc_pad_irrelevant` — with the length
  right (and `C4Spec` supplies it) the pad is **invisible**;
* ⛔ `cycOfBits_shortBits_pad_dependent` — one output short and the two cycle maps
  **differ at net 1055, the pc's top bit, purely in the pad**. *What the tile
  computes would be decided by a wire the circuit does not drive.*

### What landed (26 declarations)

- **`envOfBits` / `envOfBits_of_length` / `envOfBits_encD` / `seenWord_envOfBits`** —
  the wire configuration a bit list induces, its pad-independence under the
  length obligation, its agreement with the existing `envWith` at a full state
  encoding, and the fidelity of the instruction half.
- **`cycOfBits` / `cycleRealisesStep_of_bits`** — the bridge at the level its
  proof works at: a bit function agreeing with `encD ∘ stepT ∘ decQ` induces a
  cycle map realising the step, for every `nextW` and every `pad`.
- ⭐ **`cycOfCirc`** — the cycle map a **circuit** induces. The definition that
  was missing.
- ⭐⭐ **`cycleRealisesStep_of_C4Spec`**, and **`cycleRealisesStep_of_C4`** through
  the structure. **THE BRIDGE.**
- ⭐⭐⭐ **`sorts_of_C4`** — `C4 c` → `CycleRealisesStep` → `cycles_realise_steps`
  → `cycles_sort`, chained. The end-to-end sentence, with the three hypotheses
  above and no others.
- **`seenWord_eq_hdl`** — `Stack.Program.seenWord = HDL.seenWord`, by `rfl`. The
  two seats are about the same 32 wires; stated rather than assumed, because the
  one thing a cross-lane bridge must not get wrong is which wires it is about
  (`not_cycleRealisesStep_wordOf` is what the wrong answer looks like).
- **`outs_length_of_C4Spec`**, **`seenWord_cycOfCirc`**, **`encD_length`** — the
  finding, the legibility lemma for hypothesis 3, and the length fact.

### Non-vacuity — required, and delivered where the proof consumes its hypothesis

⚠️ **The `Circ`-level premise is C4 itself and CANNOT be witnessed today**, and
this ledger says so rather than dressing something up as a witness. What the
bridge's proof actually consumes is the *bits* hypothesis, so the witnesses are
placed there — same code path, same conclusion:

- ✅ **`cycleRealisesStep_idealBits`** — `idealBits = encD ∘ stepT ∘ decQ` meets
  the hypothesis, for every `nextW` and every `pad`, and the conclusion comes out
  through `cycleRealisesStep_of_bits`.
- ⛔ **CONTROL 1 — `not_cycleRealisesStep_stalledBits`.** A core whose outputs
  re-present the state it was given fails, at `St.init` with `addi x1, x0, 1` on
  the instruction nets. `cycOfBits` is not a construction that makes anything
  realise a step.
- ⛔ **CONTROL 2 — `cycOfBits_shortBits_pad_dependent`**, with its positive half
  `cycOfBits_pad_irrelevant`. **C4.lean's 1055-against-1056 hazard, propagated
  through the bridge and refuted rather than warned about.**
- ⛔ **CONTROL 3 — `not_both_coreShaped_C4Spec`.** Compiler's two conforming
  circuits compute different things (`conformance_does_not_determine_semantics`),
  so **at most one of them can ever be bridged.** The strongest `Circ`-level
  statement available while `core` does not exist, and it is made.

### Attempt counts, against the split budget

* **Statements: 1 attempt each** (budget 3–4). Two design decisions were weighed
  rather than defaulted: (a) whether the bridge takes `CoreConforms` — resolved
  against, see the finding above, with `cycleRealisesStep_of_C4` added so callers
  still have the structure-shaped interface; (b) whether the undriven state nets
  default to `false` or carry an arbitrary `pad` — resolved for the pad, because
  `false` would have hidden the exact hazard `C4.lean` exists to make visible.
  A third, smaller: `nextW : Env → Word` rather than `St → Word` (the shape
  `cycOf` uses), because a ROM indexed by the *new* pc is also a function of the
  current wires and the more general type prejudges neither.
* **Proofs: 1 attempt, 1 line-level repair** (budget 2 before flagging; not
  reached). The repair: in `envOfBits_of_length`, `omega` did not pick up the
  `by_cases` hypothesis `hj : j < stWidth` (its counterexample listed only
  `bs.length` and `stWidth` as atoms) — replaced with the explicit
  `Nat.lt_of_lt_of_le hj hlen`. No proof-design change anywhere.
* No `sorry`. No `native_decide`. `decide +kernel` is used for CONTROL 1's
  arithmetic and for `1055 < 1056`.

### Build + audit, and one side effect worth flagging

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0** (10.6 s). Full-tree
`saltbuild.sh` → **EXIT=0**, **8634 jobs**, zero `error:` and zero `warning:`
lines. All 26 new declarations tick `#audit_axioms`, and eight were re-checked
independently with `#print axioms` in `ScratchMATHC4B.lean` (EXIT=0; deleted, not
committed) — every one inside `[propext, Classical.choice, Quot.sound]`.

**The import worked and no new module was needed.** `Stack/Program.lean` now
imports `SaltWorks.HDL.C4`; there is no cycle (nothing under `HDL/` imports
`Stack/`) and no heavy closure — C4's transitive dependencies
(`Compose → Renumber → EmitN → {Dense, Silicon.Equiv.BitSliced}`) were already in
the hub's closure and pre-built, so the full tree went from 8632 to 8634 jobs.
⚠️ **Side effect for the maestro and for compiler: `SaltWorks/HDL/C4.lean` was
not reachable from `SaltWorks.lean` before today** — nothing imported it — so
`lake build` was not checking it. It is in the default target now, via this
import. ⛔ No file under `HDL/` was edited; `SaltWorks.lean` was not touched.

### Left undetermined

* **Whether any `Circ` satisfies `C4Spec`.** That is C4, and it is still
  unprovable: `compile` and `core` do not exist. The bridge is what makes proving
  it *sufficient*; it does not make it easier.
* **The coherence fact** named in `feedsFst_of_deliversProgram`'s docstring —
  that a tile's input map at cycle `k` is the `k`-th iterate. `cycOfCirc` now
  fixes what the iterate *is*, which is half of what that statement needs; the
  other half is a claim about the tile's assembly and is still nobody's.
* **`CoreConforms`'s other two conjuncts have no consumer in this file.** `ssa`
  belongs to the emission layer (`Circ.wf_of_ssa`, `emitPipeline'_sem`) and
  `nIn = coreInWidth` to the input map. Neither is discharged and neither is
  used here; they are listed so nobody reads `sorts_of_C4`'s use of the `C4`
  structure as having consumed them.
* **Whether `pad` should exist at all in the final tile model.** It is the honest
  model of an undriven flop and it costs one universally-quantified argument, but
  a real tile will have a definite reset/hold behaviour, and when that is pinned
  the `pad` can be instantiated rather than quantified. Nothing here depends on
  which way that goes.

---

## C4DECOMP — the key order owned in math's lane, and `C4Spec` decomposed fieldwise
**2026-08-07 · Opus executor · `SaltWorks/Stack/Perm.lean` +215, `SaltWorks/Stack/Program.lean` +496 (711 lines, no new module)**

Two independent tasks. **No file outside `SaltWorks/Stack/**` and `docs/` was
touched; `SaltWorks.lean` was not touched and no `import owed:` is needed** —
both landed by extending modules already in the default target.

⚠️ **One brief deviation, deliberate.** The brief said to extend
`Stack/Program.lean` "unless a new module is clearly cleaner". Task 1 went into
`Stack/Perm.lean` instead — not a new module, but the one where `runNetW` /
`wordSignedOrder` already live, which is literally what silicon asked for
(*"where the network theory lives"*). Perm.lean is hub-visible (Program.lean
imports it), so the "invisible to the full build" hazard does not apply. Task 2
is in `Program.lean` as directed.

### TASK 1 — THE KEY ORDER (`Stack/Perm.lean`)

Silicon asked math to own the `LinearOrder` their hardware Batcher sorts
destination fields by, rather than duplicating it in HDL. Owned.

- `Dest w := BitVec w` — a destination field at its real width.
- `dle a b := a.toNat ≤ b.toNat` / `dlt` — **the UNSIGNED order**, with
  `Decidable` instances.
- `destKeyOrder (w) : LinearOrder (Dest w)` — `LinearOrder.lift' BitVec.toNat`,
  an `abbrev`, **never an `instance`**, exactly mirroring `wordSignedOrder`.
- `destKeyOrder_le` (it is `dle`) and `destKeyOrder_le_is_the_ambient_le` (it is
  also `BitVec`'s own `≤`) — both `Iff.rfl`; `destKeyOrder_min` / `_max` pin the
  comparator a hardware element builds.
- `runNetD` = `@runNet _ (Dest w) (destKeyOrder w)`, instance applied by hand.
- **The instantiation lemma: `batcher8_sortsD (w) : @Sorts 8 batcher8 (Dest w)
  (destKeyOrder w)`**, plus `batcher8_sortsD_ofFn` (sorted-by-`dle` **and** a
  permutation), `sortedD_ofFn_runNetD`, `permD_ofFn_runNetD`,
  `injective_runNetD`.
- **The ℕ bridge** (this is the piece that makes it drop-in for silicon):
  `runNetD_toNat` — running on fields and running on their `toNat` values is the
  same run, via `runNet_comp_monotone`; `toNat_injective_of_injective`; and
  `dest3_toNat_lt_eight`, which discharges `composed_switch_of_seam_k3`'s
  `hlt : ∀ i, v i < 8` **from the type** once the carrier is `Dest 3`.

⭐ **THE FINDING WORTH RECORDING.** `Word = BitVec 32`, so at `w = 32`
`destKeyOrder 32` and `wordSignedOrder` are **two `LinearOrder`s on literally the
same type** and nothing in a signature separates them. And S1's
`letI_le_is_still_unsigned` — the certificate that `letI := wordSignedOrder`
silently gives `BitVec`'s unsigned `≤` — **reads the other way round as a
statement about which order `≤` on `BitVec` IS: the destination one.** So the
`letI` hazard has the *opposite sign* for the two bundles: harmless for
`destKeyOrder`, wrong for `wordSignedOrder`. Both are still written with explicit
instances, because "harmless today" is not a property a successor reads off the
source.

**Measured, not assumed:** `#synth LinearOrder (BitVec 3)` **fails** on this pin
(v4.32.0-rc1) — mathlib registers no order class on `BitVec` at all. So the
bundle must be handed over by hand; there is no ambient instance to collide with.

**Controls (all `decide +kernel`):** `dest_order_is_not_the_word_order`
(`wle (-1) 1` holds, `dle (-1) 1` does not); `batcher8_dest_run` (the literal
unsigned-ascending output); `batcher8_dest_run_ne_word_run` — **the same 24
comparators on the same vector give different answers at the two orders**, so
picking the wrong bundle is not a stylistic slip; `batcher8_dest_run_not_signed`,
the mirror of `batcher8_word_run_not_unsigned`.

📌 **ON THE RECORD FOR SILICON: `import SaltWorks.Stack.Perm` and instantiate
`destKeyOrder` / `runNetD`; do not write a second key order in
`SaltWorks/HDL/**`.**

### TASK 2 — THE C4 PROOF SKELETON (`Stack/Program.lean`)

⛔ **C4 itself was not attempted and remains unprovable** —
`grep -rE "^(def|theorem|abbrev|noncomputable def) (core|compile)\b"` over
`SaltWorks/` still returns nothing. What landed is the decomposition that turns
C4 into an assembly.

- `outBit` / `outReg` / `outPc` — positional readers of `sem`.
- **`RegField c (r : Fin 32)`** and **`PcField c`** — the 33 obligations, each a
  `Prop` about `c` alone, each about 32 bits.
- `regField_iff_bits` / `pcField_iff_bits` — each field IS 32 independent bit
  equations, so "checkable on its own" is a theorem rather than a claim.
- `c4Spec_iff_bitwise` — the intermediate positional form (length + 1056 bit
  equations), where the `List.ext_getElem` reasoning lives.
- ⭐⭐ **`c4Spec_iff_fieldwise` — BOTH DIRECTIONS CLOSED:**
  `C4Spec c ↔ c.outs.length = stWidth ∧ (∀ r, RegField c r) ∧ PcField c`.
- **The assembly direction, which is the payoff:** `c4Spec_of_fieldwise`,
  `cycleRealisesStep_of_fieldwise`, and `sorts_of_fieldwise` — the end-to-end
  theorem with `C4Spec` replaced by the 33 field obligations (`CoreConforms`'s
  own `outs.length` conjunct supplies the count).
- **The isolation direction:** `not_C4Spec_of_not_regField` /
  `not_C4Spec_of_not_pcField`.

⚠️ **THE LENGTH IS ASYMMETRIC, and the brief was right to flag it.** Forward it
is **free** (`outs_length_of_C4Spec`, landed); reverse it must be **assumed**.
The refutation is `length_conjunct_is_necessary` and it is **unconditional**: for
any `c` of the right output count, `extendOut c m` (one extra output port)
satisfies **every one of the 33 fields** — they read `getD` below index 1056 and
cannot see the extra port — and **provably fails `C4Spec`**, whose list equality
forces length 1056. *So the fields alone do not imply `C4Spec`, and the length
conjunct is exactly the difference.*

⚠️ **A CONTROL I WROTE WRONG AND REPLACED.** My first version of that refutation
used a zero-output `coreEmpty` and claimed the fieldwise conjunction "cannot
exclude it". **That was over-claimed**: `coreEmpty`'s pc field fails, so it is
not a witness that all fields hold while the length does not. The honest version
is the `extendOut` one above, and it is stronger — it needs no witness core at
all, which is why it is provable today. The wrong version was deleted, not
weakened around.

**⭐ NON-VACUITY — the fields genuinely come apart.** `coreShaped_isolation`:
compiler's 1056-output pass-through **satisfies `RegField coreShaped 0`** (a
write to `x0` is discarded, so `x0` never changes — `stepT_regs_zero`, new here,
propagates `St.set_zero`/P5 through the *total* step, decodable word or not),
**fails `RegField coreShaped 1`** and **fails `PcField coreShaped`** under
`ADDI x1, x0, 1` from the entry state. *Three of the same circuit's 33
obligations, decided three different ways.*

⭐ **AND IT UPGRADES A LANDED RESULT.** `not_both_coreShaped_C4Spec` said *at
most one* of compiler's two conforming shapes can satisfy `C4Spec` — the
strongest thing sayable without the decomposition. `neither_coreShape_C4Spec`
now refutes **both, individually, each by a named field**. The landed statement
was not touched.

### Attempt counts, against the split budget

* **Task 1 — statements 1, proofs 1.** Built clean on the first `saltbuild`. One
  design decision weighed rather than defaulted: the carrier. `BitVec w` (the
  field) rather than `ℕ` (silicon's current landed carrier), *because* the width
  is what discharges the address bound — `dest3_toNat_lt_eight` — and
  `runNetD_toNat` makes the ℕ statements compose anyway. Nothing is lost and the
  bound becomes free.
* **Task 2 — statements 1, proofs 2 (budget 2, not exceeded).** Attempt 1 failed
  with four real errors: two missing `[i]'h` getElem proof terms in
  `c4Spec_iff_bitwise`, a `maxRecDepth` overflow on the 1056-element `outs` list
  (C4.lean carries the same `set_option` and it does not cross the module
  boundary), and two `rw`-auto-`rfl`s that did not fire. Attempt 2 clean. The
  `extendOut` control replacing `coreEmpty` built first time and is counted
  separately as a correction, not a proof attempt.
* No `sorry`. No `native_decide`. `decide +kernel` for every control.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Perm` → EXIT=0. `saltbuild.sh
SaltWorks.Stack.Program` → EXIT=0. Full tree `saltbuild.sh` → **EXIT=0, 8634
jobs, zero `error:` and zero `warning:`** (same job count as before — no new
module). All 60 new declarations tick `#audit_axioms`; fifteen were re-checked
independently with `#print axioms` in `ScratchMATHC4D.lean` (EXIT=0; deleted, not
committed) — every one inside `[propext, Classical.choice, Quot.sound]`.

### Left undetermined

* **Whether any `Circ` satisfies a single `RegField`/`PcField` non-trivially.**
  Field 0 is satisfied by the pass-through, but that is because `x0` never
  changes. Every other field needs datapath, i.e. needs `core`. **The
  decomposition makes C4 an assembly; it does not make any one field easier.**
* **The 33 fields are not equally sized in gates.** `PcField` is the adder and
  the branch; the 32 `RegField`s share one write port and a decoder. The
  decomposition is by *layout*, which is the right split for checking, and it may
  not be the right split for *proving* — a successor may want a further split of
  `PcField` by instruction class. Nothing here forecloses that.
* **`CoreConforms`'s `ssa` and `nIn` conjuncts still have no consumer here** —
  `sorts_of_fieldwise` takes the whole structure and uses only `.2.2`. Unchanged
  from `C4BRIDGE`.
* **Task 1 has no consumer yet.** `runNetD`/`destKeyOrder` are exported and
  proved; whether silicon's link ②(b) actually lands on `Dest 3` or stays at `ℕ`
  is their call, and `runNetD_toNat` is written so that either works.

### Addendum, same session — two corrections to the entry above

1. **The declaration count is 61, not 60.** Recounted off the `#audit_axioms`
   lists: 23 in `Perm.lean`, 38 in `Program.lean`. Plus two anonymous
   `Decidable (dle _ _)` / `Decidable (dlt _ _)` instances, which `#audit_axioms`
   cannot list by name — the same gap `Spec.lean`'s `Decidable wle` instances
   already have, and not a new one.
2. **Silicon landed a key object of their own in the same window
   (`d855e9b`, `HDL/CompareExchangeC.lean`), and it is NOT a duplicate of Task 1
   — checked rather than assumed.** Their `cKey (active) (dest) : Bool × Nat` and
   `cKeyLE : Bool × Nat → Bool × Nat → Bool` are the **partial-load PRODUCT key**
   (active-before-idle, then destination) as a decidable `Bool` comparison over
   the 3-bit range. Mine is the **full-load key as a `LinearOrder` bundle**, which
   is what `runNet`/`batcher8_sorts` are instantiated at and what a `Bool`-valued
   comparison cannot be. **The two meet at their own
   `cKey_degenerates_at_full_load`: at full load the product collapses to plain
   destination order, which is exactly `destKeyOrder`.** So they are
   complementary, and neither seat duplicated the other.

   ⚠️ **The residual this exposes: nobody has a `LinearOrder` on the PRODUCT.**
   `cKeyLE` is a `Bool` function, so the partial-load statement still cannot
   instantiate `runNet` at the product key — `BatcherNetC.lean`'s *"partial load
   wants its own statement carrying the product order explicitly"* remains
   unowned. mathlib's `Prod.Lex` would supply the bundle cheaply; it was outside
   this brief and is **not** claimed as done.

---

## C4FIELDS — the certified blocks linked to the field obligations, and what the certificates actually say
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` +342 (162 lines of Lean, 139 of prose, 41 blank); 15 declarations, no new module**

No file outside `SaltWorks/Stack/**` and `docs/` was touched. `SaltWorks.lean`
was not touched: the section extends `Stack/Program.lean`, which is already in
the default target, and the one structural change is a new
`import SaltWorks.HDL.Bitwise` at its head.

### ⭐ THE HEADLINE — `bwOK` and `sltOK` are SAMPLED, at 100 pairs of 2^64

The brief's first instruction was to read the predicates before assuming their
strength. Read:

```
bwOK c f  =  bwWords.all fun a => bwWords.all fun b => sem c (bwEnv a b) == …
sltOK     =  bwWords.all fun a => bwWords.all fun b => sltDrive a b == cmpWord …
sltuOK    =  (same shape)
subOK     =  (same shape)
```

**`bwWords` is a ten-word list** — `[0, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555,
0x0000FFFF, 0xFFFF0000, 0x12345678, 0xDEADBEEF, 1, 0x80000000]`. So each of
`bitXor32_correct`, `bitAnd32_correct`, `bitOr32_correct`, `sltCirc_correct`,
`sltuCirc_correct` and `sub_via_adder_correct` is a check on **100 ordered
operand pairs out of 2^64 ≈ 1.8 × 10^19 — a 5 × 10^-18 slice.**
`bwWords_sample_size` pins the count in the kernel rather than by reading the
literal.

⇒ ***`bitXor32_correct` does NOT establish that `bitXor32` computes `^^^`.***

**This is not a defect found, and it is not news to the seat that wrote it** —
`HDL/Bitwise.lean`'s own docstring says *"Sampled rather than exhaustive — 2^64
input pairs is not a proof obligation, it is a category error."* The finding is
that **the names do not carry the caveat and the consumers are one import away**:
`bitXor32_correct : bwOK bitXor32 (· ^^^ ·) = true` reads, at a call site, exactly
like a correctness theorem. So the caveat is now restated where the bridges are,
and — where it could be — removed rather than restated.

### ⭐⭐ WHERE IT COULD BE REMOVED: the XOR block, proved for all 2^64 pairs

**`bitXor32` is pointwise — 32 independent gates over disjoint bit pairs — so its
semantics is provable STRUCTURALLY, with no `decide` anywhere.**

* `run_xorGates` — induction over the gate list. The `k`-th gate writes net
  `64 + k`, which nothing reads, so `Sem.lean`'s `run_of_unwritten` keeps the
  operand nets `0 … 63` intact across the whole run.
* ⭐ `sem_bitXor32 (a b : Word) : sem bitXor32 (bwEnv a b) = (List.range
  32).map (fun k => (a ^^^ b).getLsbD k)` — **unconditional, all 2^64 pairs.**
  This *supersedes* the sampled certificate rather than consuming it.
* `sem_bitXor32_off_the_sample` — a pair (`0x0F0F0F0F`, `0x33333333`) with
  neither word in `bwWords`, so "for all 2^64" and "for the 100 checked" are
  distinguishable from outside.

`decide +kernel` over `BitVec 32` pairs was never attempted: 2^64 is not a kernel
computation, which is exactly why the structural route was the route.

### ⚠️ WHERE IT COULD NOT: the SLT bridge carries the sample in its type

**The gap is not in the comparator.** `sltCirc` has **three input bits**, so its
own semantics is exhaustively decidable:

* `sem_sltCirc (a31 b31 s31 : Bool)` — all 8 valuations by `decide +kernel`; the
  block computes exactly `s31 ⊕ ((a31 ⊕ b31) ∧ (a31 ⊕ s31))`.
* `sltDrive_eq_sign_formula (a b : Word)` — **unconditional, all 2^64 pairs**,
  with the adder's 31st output left opaque. *This isolates the residual to one
  sentence: everything between it and `BitVec.slt` is the claim that
  `(subOut a b).getD 31 false` is the sign bit of `a - b`.*

That claim is `sub_via_adder_correct`, at the same 100 pairs, **because `adder32`
has no semantic theorem at all — `ssa` and `wf` and nothing else.** So:

* `sltDrive_eq_of_mem {a b} (ha : a ∈ bwWords) (hb : b ∈ bwWords)` — the sampled
  certificate unpacked from its `List.all` into the statement it is.
* ⭐ `sltField_is_sltCirc … (hx : s.get x ∈ bwWords) (hy : s.get y ∈ bwWords)`.
  **The two membership premises ARE the sample.** They put the weakness in the
  type where a caller must discharge it, and they are exactly what an `adder32`
  theorem would delete.

### The two field bridges, stated

`RegField c r` asks that `outReg c ins r` equal
`(stepT (decQ ins) (seenWord ins)).regs[r]`. There is no `core`, so these state
**the other side of that equation** — the ISA target, met by the block:

```lean
theorem xorField_is_bitXor32 (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0) :
    (stepT (decQ (envWith s (encode (Instr.XOR rd x y))))
           (seenWord (envWith s (encode (Instr.XOR rd x y))))).regs[rd.val]
      = wordOf (fun k => (sem bitXor32 (bwEnv (s.get x) (s.get y))).getD k false)

theorem sltField_is_sltCirc (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0)
    (hx : s.get x ∈ bwWords) (hy : s.get y ∈ bwWords) :
    (stepT (decQ (envWith s (encode (Instr.SLT rd x y))))
           (seenWord (envWith s (encode (Instr.SLT rd x y))))).regs[rd.val]
      = wordOf (fun k => (sltDrive (s.get x) (s.get y)).getD k false)
```

The `wordOf ∘ getD` on the right is `outReg`'s own shape, so the assembly into a
`RegField` is whatever `core` supplies and nothing on the ISA side is left to
negotiate later. **The 1-bit → 32-bit widening is not glossed:** `wordOf_cmpWord`
is the theorem that `cmpWord r` denotes the word `if r then 1 else 0`, which is
what `SLT` writes.

### ⛔ Non-vacuity — the wrong block fails each bridge

* `bitAnd32_fails_the_xorField` — same constructor, same layout, one `Op` apart;
  refuted **at the field**, not only at the circuit.
* ⭐ `sltuCirc_fails_the_sltField` — **the signed/unsigned trap, arrived in the
  hardware lane.** On `(0x80000000, 1)` the ISA's signed `SLT` writes `1`;
  `sltuCirc`, a *landed and certified* circuit, answers `0`. The wrong block here
  is not a typo — it is a correct circuit differing only in signedness, and every
  test whose spread omits a sign-straddling pair accepts it.
* `control_states_exist` — both controls' operand hypotheses are satisfiable, so
  neither refutation is vacuous.

### ⛔ What remains blocked on the adder

**`ADD`, `ADDI` and `PcField` were not attempted and are not claimed.** All three
run through `adder32`, which has no semantic theorem, so there is nothing to
bridge them to. Not this seat's lane; already on the bus. **The SLT bridge's
membership premises are the same debt, visible in a type:** an `adder32` semantics
theorem deletes them and promotes `sltField_is_sltCirc` to the unconditional form
`xorField_is_bitXor32` already has.

### Attempt counts, against the split budget

* **Statements 4 groups (budget 3–4, met): the XOR block bridge, the XOR field
  bridge, the comparator/SLT field bridge, the controls.** 15 declarations.
* **Proofs: 5 scratch build cycles, over the budget of 2. Recorded rather than
  massaged.** The reason I did not stop at 2: **the mathematical content compiled
  unchanged from cycle 1 to cycle 5** — every failure was elaboration mechanics on
  the same proof, not a proof that was not going through, and each was diagnosed
  (`trace_state`) rather than guessed at. The four causes, in order:
  1. `omega` could not close `64 ≤ (⟨64 + i, …⟩ : Gate).out` — the structure
     projection does not reduce for it. Replaced by a `show` plus a term proof.
  2. **`a ^^ b = c` parses as `a ^^ (b = c)`** — `^^` is precedence 33, `=` is 50.
     A `show` written without parentheses is a different proposition.
  3. `by omega` **inside a `rw` argument** runs before unification fixes the
     rewrite's implicit arguments, so it sees a goal full of metavariables. Moved
     to standalone `have`s and named `rw [upd_of_ne (n := …) (m := …)]`.
  4. ⭐ **`omega` DOES NOT SEE THROUGH `HDL.Net`.** `Net` is `abbrev Net := Nat`,
     and a variable elaborated at `Net` (as `k` is, coming out of
     `List.map_congr_left` against a gate-net index) makes `omega` report *"No
     usable constraints found"* on a goal as trivial as `¬ 32 + k < 32` **and
     silently ignore every `Net`-typed hypothesis in context.** *This is worth the
     fleet's attention: the failure looks like a broken goal, not like a type
     issue, and the message names neither.* Worked around with `Nat.not_lt.mpr`
     and `Nat.add_sub_cancel_left`.
* `Stack/Program.lean` itself built **clean on the first try** once the scratch
  was green; the full tree likewise.
* No `sorry`. No `native_decide`. No new axioms. `decide +kernel` for every
  control and for the one exhaustive block check.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**. Full tree `saltbuild.sh` →
**EXIT=0, 8635 jobs** (one more than the previous entry's 8634 — the added
`SaltWorks.HDL.Bitwise` edge into `Stack.Program`), zero `error:`, zero
`warning:`. All 15 new declarations tick `#audit_axioms` (max 3 axioms) and all 15
were re-checked independently with `#print axioms` in `ScratchMATHC4F.lean`
(EXIT=0; deleted, not committed) — every one inside
`[propext, Classical.choice, Quot.sound]`, with `sem_sltCirc` and
`bwWords_sample_size` depending on none.

### Left undetermined

* **Whether the sign formula equals `BitVec.slt` in general.** `sem_sltCirc` and
  `sltDrive_eq_sign_formula` are unconditional; the step from
  `s31 ⊕ ((a31 ⊕ b31) ∧ (a31 ⊕ s31))` to `BitVec.slt a b` needs *both* an
  `adder32` semantics theorem *and* a `BitVec` lemma relating the overflow-
  corrected sign of `a - b` to signed comparison. Neither exists here; neither was
  attempted.
* **`bitAnd32` and `bitOr32` got no general bridge.** `run_xorGates` is written
  for `.xor` specifically. It generalises to any `mk : Net → Net → Op` whose
  fanin is `[k, 32 + k]`, which is all three — one parameterisation, not a new
  proof — but the ISA has no `AND`/`OR` instruction in Slice A, so there is no
  field for them to bridge to and nothing asked for it.
* **`bitNot32` is untouched.** It is not an ALU result (it is the subtractor's
  operand path), so it has no field either.
* **Nothing here says a `core` exists.** These are statements about a landed block
  and the ISA. The assembly into `RegField` remains exactly what
  `c4Spec_of_fieldwise` will consume, unchanged.


## ADDER32 — the unconditional semantics of `adder32`, and the sample premises deleted
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` +525 (313 lines of Lean, 126 of prose, 86 blank); 50 declarations, no new module**

No file outside `SaltWorks/Stack/**` and `docs/` was touched. `SaltWorks/HDL/**`
(compiler's slot), `SaltWorks/Silicon/**` (silicon's) and `SaltWorks.lean`
(maestro's) are untouched — the section extends `Stack/Program.lean`, which
already imports `HDL.C4` and `HDL.Bitwise`, so there is **no new import**.

### ⭐ THE HEADLINE

```lean
theorem sem_adder32 (a b : Word) :
    sem adder32 (bwEnv a b)
      = (List.range 32).map (fun k => (a + b).getLsbD k) ++ [BitVec.carry 32 a b false]
```

**All 2^64 operand pairs. No `decide`, no `native_decide`, no new axiom.** The
general form `sem_adder32_gen a b cin` carries the carry-in as a parameter and
targets `a + b + setWidth 32 (ofBool cin)`, because the same circuit is driven
with carry-in `1` by `subOut`.

Before this, `adder32` had `adder32_ssa` and `adder32_wf` and **no behavioural
theorem at all** — only `adder32_adds_on_sample` / `adder32_carry_out_on_sample`
(49 ordered pairs of `addWords`) and `sub_via_adder_correct` (100 pairs of
`bwWords`). `Adder.lean`'s own docstring names what those cannot catch: *"a
generator producing the right cone shape and the wrong sum would pass every
check here."*

### ⭐ THE INVARIANT — the actual node

`sem_bitXor32`'s method does **not** transfer. `bitXor32` is pointwise, so
`run_of_unwritten` frames every operand net across the whole gate list. **The
adder is a ripple chain: slice `i` READS `adC i`, which slice `i-1` WROTE**, so
there is no frame across slices and the induction needs a real invariant. It is
`run_adGates`, and it is three-part — for every `n ≤ 32`, after running the
first `n` slices:

1. **frame** — `∀ m < 65, run E (adGates n) m = E m` (the 65 primary-input nets
   survive; every gate writes at `adBase i = 65 + 5i` or above);
2. **the carry** — `run E (adGates n) (adC n) = BitVec.carry n a b cin`
   (⭐ *the circuit's NAMED carry net identified with core's carry function* —
   this is the whole node);
3. **the sums** — `∀ k < n, run E (adGates n) (adS k)
   = a.getLsbD k ^^ (b.getLsbD k ^^ BitVec.carry k a b cin)`.

The step runs one slice over the prefix environment: `run_adSlice_frame`
preserves (1) and the already-written sum bits, `run_adSlice_cout` plus
`BitVec.carry_succ` advances (2), `run_adSlice_sum` extends (3). The `n ≤ 32`
premise is load-bearing — it is what lets `E (adA n)` and `E (adB n)` be read as
`a.getLsbD n` and `b.getLsbD n`.

### What core supplied vs what was built here

**Core carried the ripple model, and it carried it completely.**
`Init.Data.BitVec.Bitblast` gave `carry`, `carry_zero`, `carry_succ`,
`getLsbD_add_add_bool`, `carry_width`, `ult_eq_not_carry` and `slt_eq_not_carry`;
`Bool.atLeastTwo` is core's majority function. **No carry recurrence was
hand-rolled and no arithmetic fact about `+`, `-`, `<ᵤ` or `<ₛ` was proved here.**

Built here: (a) `run_five`, the five-gate slice reduction, stated over four raw
`Nat` net names with only "the three read nets sit below the five written ones"
as hypotheses — one `simp` discharges all five `upd`s; (b) the identification of
`adC i` with `BitVec.carry i`; (c) three Bool identities of eight valuations each
(`atLeastTwo_eq`, `xor3`, `slt_bool`).

### ⛔ `slice_ok` was NOT importable, and the reason is structural

The brief pointed at `SaltWorks/Silicon/Equiv/AdderSlice.lean:70`. It is a real
theorem and it is the right mathematics, but it is stated over
`SaltWorks.Silicon.Netlist` / `runP` / `sliceNL_outs` — **a different carrier and
a different evaluator from `HDL.Circ` / `sem` / `run`.** Importing it would have
bought a carrier-bridging obligation rather than a lemma. Its content is the
majority function, which is `Bool.atLeastTwo`, and it is re-derived locally in
one `decide` over 8 valuations. *No Silicon import was added.*

### What this unblocks — and one place it does not

* ⭐ **`ADD`** — `addField_is_adder32`, unconditional in the operands.
* ⭐ **`ADDI`** — `addiField_is_adder32`, unconditional (the immediate is
  sign-extended by `stepT`; the block sees the extended word).
* ⭐ **the `∈ bwWords` premises** — `sltField_is_sltCirc_unconditional` is
  `sltField_is_sltCirc` with **both membership hypotheses gone**. The chain is
  `subOut_bits` (the subtraction path, all 2^64) → `subOut_sign_formula` →
  `slt_sign_formula` (core's `slt_eq_not_carry` + the 8-case identity) →
  `sltDrive_uncond`. ⚠️ **The landed `sltField_is_sltCirc` and
  `sltDrive_eq_of_mem` are left EXACTLY as they stand** — nothing was weakened,
  restated or repaired; the stronger theorem is additive and retiring the weaker
  one is another seat's call.
* ⭐ **`SLTU`** — `sltuDrive_uncond`, which is core's `ult_eq_not_carry` read off
  the adder's 33rd output. This was not asked for and fell out.
* ⭐ The previous entry (C4FIELDS) listed *"whether the sign formula equals
  `BitVec.slt` in general"* under **Left undetermined**, needing "both an
  `adder32` semantics theorem and a `BitVec` lemma relating the overflow-
  corrected sign of `a - b` to signed comparison." **Both now exist** — the first
  here, the second in core.
* ⛔ **`PcField` is NOT closed, and the brief's claim that it would be is wrong.**
  `PcField c` is a statement about a whole `core`'s output bits `1024…1055`, and
  **the pc path does not run through `adder32`**: `pcNext` implements the
  increment itself (`pcNext_not_beq_adds_four`), and `Adder.lean:241` records
  that `inc32` is *unreferenced* — `grep` finds it in its own file and nowhere
  else. `sem_adder32` gives `PcField` nothing. The debt there is `core`.

### ⛔ Non-vacuity

* `adder32Cut` — `adder32` with **one gate changed**: slice 16's carry-out is
  `and` rather than `or`, which makes that carry identically `false` (`a&&b` and
  `a^^b` are disjoint). It is still `ssa` (`adder32Cut_is_ssa`), still 160 gates,
  still the right cone shape. `adder32Cut_fails_the_adder` refutes it on
  `(0x00010000, 0x00010000)`, which generates a carry at exactly that slice.
* `bitXor32_fails_the_adder` — the carry-free "adder", refuted by `1 + 1`.
* `sem_adder32_off_the_sample` — `0xF0F0F0F0`, in **neither** `bwWords` nor
  `addWords`, with the carry-out `true`. *Without it, "for all 2^64" and "for the
  pairs someone listed" are indistinguishable from outside.*
* ⚠️ **Honest limit of the controls.** I looked for a mutation that **passes** the
  sampled certificates and **fails** the theorem — the sharpest possible control.
  There is no cheap one: `addWords` and `bwWords` both contain `0xFFFFFFFF` and
  `1`, and `0xFFFFFFFF + 1` ripples a carry through every slice, so **any**
  single-gate mutation of the carry chain or of a sum gate is caught by that one
  pair. ⇒ *The sample is a decent tripwire against single-gate damage. What it
  cannot be is a theorem, and that is the whole distinction this entry is about.*

### Attempt counts, against the split budget

* **Statements: 4 groups (budget 3–4, met)** — the adder itself
  (`sem_adder32_gen` / `sem_adder32`), the subtraction path, the two comparators,
  the ISA bridges + controls. 50 declarations.
* **Proofs: 5 scratch build cycles (budget 2).** Recorded, not massaged. As in the
  previous entry, **the mathematical content did not change after cycle 1** — the
  invariant, the induction and the core lemmas used were fixed from the first
  draft, and every cycle after that was elaboration mechanics, each diagnosed
  from the error text rather than guessed:
  1. ⭐ **`omega` does not see through `HDL.Net`** — again, and worse than the
     last entry recorded. It is not only `Net`-typed *hypotheses* that vanish: a
     **goal** whose `<` sits at `Net` (e.g. `adA n < adBase n`, since `adA`
     returns `Net` while `adBase` returns `Nat`) makes `omega` report *"No usable
     constraints found"* and try to derive `False` from context instead. Fixed by
     `show`ing every such goal into `Nat` first (`adA_lt`, `adB_lt`, `adC_lt`) and
     by binding `∀ m : Nat` rather than letting `m` be inferred at `Net` from
     `run E gs m`. **`adBase`/`adIn`/`adW` return `Nat` and are safe; `adA`,
     `adB`, `adC`, `adS`, `adP`, `adG`, `adT`, `adCin` return `Net` and are not.**
  2. `omega` also treats `adBase n` as an **atom**, so every bound needs
     `have : adBase n = 65 + 5 * n := adBase_eq n` in scope first.
  3. `set … with hR` then `rw [hR]` **un-abstracts** the very term the hypotheses
     are stated over. Dropped `set` entirely.
  4. `congr 1` on a `List` append blew `maxRecDepth`; replaced by two `have`s and
     one `rw`. **No `set_option maxRecDepth` was needed in the end** — the bump
     was a symptom of `congr`, not of the file.
  5. `atLeastTwo` is `Bool.atLeastTwo`, not `BitVec.atLeastTwo`; and `by decide`
     on a goal with free `Bool` variables needs them reverted (`∀ x y c : Bool`).
* `Stack/Program.lean` built **clean on the first try** once the scratch was
  green — no errors, no warnings.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**. Full tree `saltbuild.sh` →
**EXIT=0, 8635 jobs**, zero `error:`, zero `warning:`. All 50 new declarations
tick `#audit_axioms` (max 3 axioms, i.e. inside
`[propext, Classical.choice, Quot.sound]`; `adder32Cut` and `adder32Cut_is_ssa`
depend on none, `adder32Cut_fails_the_adder` on `propext` alone) and every
headline result was independently re-checked with `#print axioms` in
`ScratchMATHADD.lean` (EXIT=0; deleted, not committed).
`docs/hdl-tools/audit_completeness.py` → **every theorem is on an
`#audit_axioms` list** (35 files, 374 theorems). ⚠️ **SCOPE ADDED 8/7 19:0x: the 35 files are `SaltWorks/HDL` ONLY — the tool defaults to that root and had never read `SaltWorks/Stack/`. This sentence was true of a DIRECTORY and was read as true of the REPO. See the `audit_completeness` entry below.**

### Left undetermined

* **`inc32` still has no semantics.** It is the one non-`ssa` `Circ` in the tree
  and it is unreferenced; `inc32_adds_four_on_sample` remains its only statement.
  The method here transfers to it directly (it is a degenerate adder), but it
  closes a gap in a dead definition and nothing asked for it.
* **`bitAnd32` / `bitOr32` / `bitNot32`** still have only sampled certificates —
  unchanged from the previous entry, and still with no ISA field to bridge to.
* **`BEQ` is untouched.** It is a branch, not an ALU result; its field is the pc.
* **Nothing here says a `core` exists.** These are statements about a landed block
  and the ISA. The assembly into `RegField` / `PcField` remains exactly what
  `c4Spec_of_fieldwise` will consume, unchanged.

## PCNEXT — the pc addend select unconditionally, and three bitwise organs from one lemma
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` +740 (577 lines of Lean, 88 of prose, 75 blank); 65 declarations, no new module, ONE new import**

No file outside `SaltWorks/Stack/**` and `docs/` was touched. `SaltWorks/HDL/**`
(compiler's slot), `SaltWorks/Silicon/**` (silicon's) and `SaltWorks.lean`
(maestro's) are untouched. ⚠️ **`import SaltWorks.HDL.PcNext` was added to
`Stack/Program.lean`** — it was not in the closure (`Bitwise` reaches
`Adder`/`Compose`/`ISA`, none of which reach `PcNext` → `Immediate` →
`Decoder`/`EmitN`). **Measured job-count change: full tree 8635 → 8637, +2.**

### ⭐ THE FIRST DELIVERABLE — what the four standing `pcNext` theorems quantify over

The dispatch asked this be read before anything was proved, and the answer is
**all five existing statements are sampled; not one was reusable as a lemma.**

| theorem | binder | points |
|---|---|---|
| `pcNext_correct_on_sample` | `pcCases × pcOffs × [false,true]` | 100 |
| `pcNext_not_beq_adds_four` | `pcCases × pcOffs`, `isBEQ := false` | 50 |
| `pcNext_taken_adds_offset` | none — `pcRun 7 7 0x7FFFFFFC true` | 1 |
| `pcNext_compares_all_32_bits` | none — `pcRun 0x80000000 0 8 true` | 1 |
| `pcNext_compares_the_low_bit` | none — `pcRun 0xA5A5A5A5 0xA5A5A5A4 8 true` | 1 |

All five are `decide +kernel` over **fixed** operand lists (`pcCases` is ten
pairs, `pcOffs` five offsets). ⇒ **The three whose names read like universal
claims about the comparator's width are single points**, and
`..._not_beq_adds_four` binds `p` and `o` only over the listed values. The input
space is `2^97`. **None was competition and none was a step**; they are now
points of `sem_pcNext`.

### ⭐ THE HEADLINE — TASK 1

```lean
theorem sem_pcNext (rs1 rs2 off : Word) (isBEQ : Bool) :
    pcRun rs1 rs2 off isBEQ = pcSpec rs1 rs2 off isBEQ
```

**All 2^97 input valuations**, stated against the block's own landed driver and
its own landed specification, so it *supersedes* `pcNext_correct_on_sample`
rather than restating it. No `decide` in the proof, no `native_decide`, no new
axiom.

### The three shapes, and why the adder's machinery did NOT transfer

`pcNext` is **neither pointwise nor a ripple chain — it is three shapes in
series**, one lemma each:

1. **32 `xor` difference gates — POINTWISE.** `run_pointwise` (generic in the
   base net and the gate constructor) does it, and is also what closes all three
   bitwise organs below: **one lemma, four blocks.**
2. **A 31-gate OR tree — a CHAIN.** `run_of_unwritten` does not apply across it,
   so it gets its own induction, `run_orChain`. ⭐ **Proved over `Decoder.lean`'s
   `orChain` GENERICALLY**, by strong induction on a fuel parameter (`orChain` is
   well-founded on `ns.length`), not over the concrete 32-input instance — so any
   later block built from that chain inherits it.
3. **32 independent addend-mux blocks**, one of which (bit 2, the single set bit
   of the constant `4`) is two gates rather than one. Its induction carries a
   **disjointness** obligation the pointwise lemma does not have.

⛔ **`sem_adder32`'s carry machinery did not transfer, and that is the block's own
design decision rather than an accident.** `PcNext.lean:19` emits the *addend*
and leaves the addition to the assembly, exactly so the block never instantiates
`adder32`. **There is no carry chain in `pcNext`; `BitVec.carry` appears nowhere
in this entry.** What transferred is the *method* — frame lemma plus an induction
carrying an invariant — not a line of the adder's arithmetic. The dispatch's
warning that `inc32` is unreferenced and `pcNext` "implements its own increment"
was itself slightly off: **`pcNext` implements no increment at all.** It selects
between `bOffset imm` and the constant `4` and hands the sum to whoever
instantiates it.

⚠️ **AND THE `Net` TRAP FIRED AGAIN, on the goal, exactly as the ADDER32 entry
warned.** `omega` reported *"a possible counterexample may satisfy `0 ≤ k ≤ 1`"*
on the goal `163 + k = 163 + k` — it drops a goal whose head sits at `Net` and
then tries to refute the context. Fixed structurally rather than case by case:
**`pcOut : Nat → Nat`, a `Nat`-valued mirror of `pcAddendOut`**, with
`pcAddendOut_eq` the one bridge; every net-arithmetic obligation goes through it
or through a `show` into `Nat`.

### ⭐ THE ISA SIDE — the pc field, all three branches of `stepT`'s rule

```lean
pcField_is_pcNext_beq          (stepT … (BEQ x y imm)).pc = s.pc + wordOf (pcRun … true)
pcField_is_pcNext_add          (stepT … (ADD rd x y)).pc  = s.pc + wordOf (pcRun … false)
pcField_is_pcNext_undecodable  decode w = none → (stepT s w).pc = s.pc + wordOf (pcRun … false)
```

with `pcAddend_word : wordOf (pcRun rs1 rs2 off isBEQ) = if isBEQ && (rs1 == rs2)
then off else 4` underneath. The **addend** shape is why these are `s.pc + …`
rather than an equality with the block's output — the block does not compute the
pc, by design.

⛔ **`PcField` IS NOT CLOSED AND IS NOT CLAIMED TO BE.** It is a statement about
a whole `core`'s output bits `1024 … 1055`, and no `core` exists (`grep` for
`def core` over `SaltWorks/` still returns nothing). What lands is the
block-level theorem plus the three bridges a `core` assembly would apply —
exactly the service `addField_is_adder32` performs for `ADD`. **The debt is
`core`, not `pcNext`.**

### ⭐ TASK 2 — one generic lemma covered all three, so all three landed

```lean
sem_bwCirc mk f (fanin bound) (eval law) :  sem (bwCirc mk) (bwEnv a b) = map (f a[k] b[k])
sem_bitAnd32 / sem_bitOr32   : instances at `.and` / `.or`, three lines each
sem_bitNot32                 : the same `run_pointwise`, base 32, one operand
```

**The dispatching seat's scope correction is answered in the affirmative**: the
generic lemma is `run_pointwise`, the *same* lemma the pc difference block uses,
so `bitOr32` and `bitNot32` cost three lines apiece on top of work already done.
⚠️ **AND THE CORRECTION'S MEASUREMENT STANDS AND IS RECORDED HERE: before this
node, `bitOr32` and `bitNot32` were referenced by no file but their own
(`HDL/Bitwise.lean`); `bitAnd32` had one consumer.** They are proved because
they were free, not because anything consumes them — and the only file that now
names them is this one, which is not consumption.

📌 **`sem_bitXor32` (landed `d4fe922`) is now also an instance of `sem_bwCirc`,
and it was left exactly as it stands.** Collapsing `run_xorGates` + `sem_bitXor32`
(~60 lines) into two instantiations is a clean consolidation and it is **not**
taken here: the iron rule against touching landed statements was read
conservatively. *Flagged as available, not done.*

### ⛔ NON-VACUITY — and one control is stronger than the genre's usual

* **`pcNextCut`** — `pcNext` with **one gate** changed: difference bit 5 is tied
  to `.const false`. Still `ssa`, still 99 gates, still the right cone shape.
  ⭐ **`pcNextCut_passes_the_certificate : pcOKCut = true`** — the mutant satisfies
  the landed 100-point sample, because no pair in `pcCases` differs *only* at bit
  5 — **and `pcNextCut_fails_the_theorem` refutes it on `(0x20, 0)`.** *This is
  the first control in this campaign that separates the certificate from the
  theorem by exhibiting a circuit the certificate accepts.* (`adder32Cut` failed
  both; that is a weaker demonstration.)
* **`sem_pcNext_off_the_sample`** — `(0x20, 0)` and `(0x0F0F0F0F, 0x0F0F0F0F)`
  are not in `pcCases`, `0x12345678` is not in `pcOffs`, and the theorem gives
  both.
* **`bitAnd32Cut`** — bit 7's gate is `.or`, still `ssa`; refuted on
  `(0xFFFFFFFF, 0)`. **`sem_bitAnd32_off_the_sample`** — `0x0F0F0F0F` and
  `0x33333333` are in neither `bwWords`, for all three new organs.

### Attempt counts, against the split budget — content vs mechanics

The fleet asked these be separated. **The mathematics settled in cycle 1 for both
tasks; every later cycle was elaboration mechanics, each diagnosed from the error
text.**

* **Task 1 — statements: 3 groups (budget 3–4, met)** — the block theorem, the
  addend-as-a-word lemma, the three ISA bridges. **Proofs: 4 scratch cycles
  (budget 2 — over, recorded).** *Content changed in ZERO of them.* The decomposition
  (pointwise / chain / mux + the stage envs) was fixed before the first build and
  never revised. The four:
  1. A probe cycle, deliberate and not a failure: it established that
     `decide +kernel` **does** reduce `orChain` (so the layout numerals `pcNe =
     159 … pcMuxBase = 163` are available) while `rfl` does **not** — `orChain` is
     well-founded, so the elaborator will not unfold it but the kernel will.
     Also fixed `conv_lhs => rw [orChain]` as the unfolding idiom.
  2. `omega` on the `Net`-typed goal (above) → the `pcOut` mirror.
  3. `!x = y` parses as `!(x = y)` — the exact analogue of the recorded
     `a ^^ b = c` trap, and it cost a `show` in `sem_bitNot32`.
     `BitVec.getLsbD_and`/`_or` take **implicit** arguments and are not applicable
     as `lemma a b k`.
  4. `rw [if_pos h]` cannot reach an `if` under a `fun k =>` binder (motive
     failure, reported as "did not find an occurrence"); `simp only [if_pos h]`
     can. Same cycle: `cases h : e` already generalises the goal, so the `simp
     [h]` that follows is dead.
* **Task 2 — statements: 1 group (budget 3–4, under).** Three organs, one lemma.
  **Proofs: 0 dedicated cycles** — they rode task 1's `run_pointwise` and were
  green the first time it was.
* `Stack/Program.lean` built **clean on the first try** once the scratch was green.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**, 8605 jobs. Full tree
`saltbuild.sh` → **EXIT=0, 8637 jobs**, zero `error:`, zero `warning:`. All 65
new declarations tick `#audit_axioms` (max 3, i.e. inside
`[propext, Classical.choice, Quot.sound]`), and every headline result was
independently re-checked in `ScratchMATHPC.lean` (EXIT=0; deleted, not
committed). `docs/hdl-tools/audit_completeness.py` → **every theorem is on an
`#audit_axioms` list** (35 files, 392 theorems, up from 374). ⚠️ **SCOPE ADDED 8/7 19:0x — `SaltWorks/HDL` ONLY; see below.**

### Left undetermined

* **`PcField` and `RegField` are untouched.** Nothing here claims a `core`.
* **`inc32` still has no semantics** and is still unreferenced — and this node
  removes the last reason to want one: the pc path does not go through it, and
  `pcNext` does not increment.
* **`aluSelect` and `zeroTree`** are still sampled-only; `sll`/`sra` still have
  no producer at all.
* **The `sem_bitXor32` consolidation is available and not taken** (above).
* **`bitOr32` / `bitNot32` are proved but unconsumed.** If they stay unreferenced
  they are candidates for deletion, not for further work.

---

## PCADD — the pc increment restored BY COMPOSITION, and the defect committed as a theorem
**2026-08-07 · Opus executor · `SaltWorks/Stack/Program.lean` (extended)**

### What landed

**`sem_pcAdd` — the pc path computes `stepT`'s pc rule on all 2^129 inputs**, no
`decide`, no sample, no `native_decide`:

```lean
theorem sem_pcAdd (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    sem pcAdd (pcAddEnv pc rs1 rs2 off isBEQ)
      = (List.range 32).map
          (fun k => (pc + (if isBEQ && (rs1 == rs2) then off else 4 : Word)).getLsbD k)
```

`pcAdd` is **260 gates**: one `⟨129, .const false⟩` (the adder's carry-in), the
landed `pcNext` instantiated at 130 (99 gates), the landed `adder32` instantiated
at `instNext pcNext 130 = 229` (160 gates). Host inputs `pc 0…31`,
`rs1 32…63`, `rs2 64…95`, `off 96…127`, `isBEQ 128`. `ssa` structurally,
`wf` via `Circ.wf_of_ssa` (the O(n²) `nodupB` is never walked).

The two premises `PcNext.lean:23-28` gave for the addend-select —
*"instantiation's semantics theorem is owed, not proved"* and the absence of an
unconditional adder — are **both false as of today**, so the composition is the
fix the design's own objection was blocking.

⭐ **AND THIS IS THE THIRD `adder32` THE ASSEMBLY PLAN ASKS FOR**
(`hdl-c4-core-assembly-plan-0807.md:168-171`), reached by instantiating the
proved block rather than by standing up a new one. **`inc32` was not
resurrected** — `Adder.lean:115` gives it 32 inputs and no addend port, so it
cannot do the branch case, exactly as `docs/silicon-refute-pcpath-0807.md` §5
concluded.

⚠️ **THE REUSE IS AT THE DEFINITION LEVEL, NOT THE GATE LEVEL, AND THIS NODE
MEASURES IT.** `instGates` maps every gate into the host, so the carry chain is
duplicated in the netlist. **`pcAdd_gate_count = 260` = 1 + 99 + 160** — a
kernel-checked confirmation of the `+160` that silicon's §6.1(b) derived from
`instGates`/`instNext`, and of its `~12,081` corrected core total. *What is not
duplicated is the SOURCE: one `adder32`, one `sem_adder32`, nothing that can
drift — which is what `PcNext.lean:28` feared and is the whole saving.*

📌 **And the shape silicon priced as "a bigger change than it looks" is reached
without making it.** Its §3 put the alternative as *"`pcNext` needs the pc among
its inputs … `pcIn` goes 97 → 129 and the block stops being 99 gates."*
`pcAdd.nIn` **is** 129 — and `pcNext` is untouched, still 97 inputs, still 99
gates. **The width moved to the composite; the block did not.**

* **The three bridges**, the landed `pcField_is_pcNext_*` trio with the addition
  now inside the circuit: `pcField_is_pcAdd_beq` / `_add` / `_undecodable`.
  **Their right-hand sides no longer carry `s.pc + …`** — that is the whole
  observable difference, and it is the difference the node exists for.
* **The defect, as a theorem.** `addend_read_as_pc_is_four` — the addend on every
  non-branch is `4` and *does not mention the pc*;
  `addend_as_pc_is_wrong_unless_pc_zero` — so reading it as the next pc disagrees
  with `stepT` at every pc but zero (⇒ **a smoke test from reset would not have
  caught it**); `the_defect_and_the_fix` — 4 vs 0x1004 at one pc, side by side.
  Same service `offset_six_does_not_sort` performs for the branch immediate.
* **Two netlist witnesses** walked by the kernel rather than by the proof:
  `pcAdd_netlist_advances_the_pc` (0x1000 → 0x1004),
  `pcAdd_netlist_takes_the_branch` (0x1000 + 0x40).

### ⭐ `inst_sem`'s actual hypothesis, and whether it was discharged — YES, twice

The brief flagged this as the likely failure mode. Stated exactly:

```
instOK c σ off   :   c.ssa ∧ c.wf ∧ ∀ i < c.nIn, σ i < off
hin              :   ∀ a < c.nIn, envN (σ a) = envC a
```

* **The third `instOK` clause is what makes the whole thing work**, and it is why
  the host's inputs are laid out **pc first**: `σ₁ = (32 + ·)` is then a uniform
  shift, every wire lands below `130`, and `pcAddEnv_shift` — the host read
  through `σ₁` IS `pcEnvOf` — is four `if` branches. A layout interleaving the pc
  with `pcNext`'s ports would have satisfied nothing.
* **`hin` for `pcNext`**: `hin_pcNext`, three lines.
* ⭐ **For the SECOND instance the hypothesis MOVES**, and this is the part worth
  keeping. `inst_compose_sem` asks for agreement *after the first instance has
  run*: `run env (instGates c₁ σ₁ off) (σ₂ a) = envC₂ a`. `hin_adder` splits it
  three ways, one per port group, each paid by a different lemma — the `a` port
  (the pc) by the **frame** (`inst_frame_below`: `pcNext`'s instance leaves nets
  `0…31` alone), the `b` port by **`inst_sem` on `pcNext` itself**, the carry-in
  by the frame again at net `129`, which is below `130` for exactly the `instOK`
  reason. **No net-numbering collision and no width mismatch: the highest addend
  wire is 228 and the adder sits at 229, one net above it.**

### ⚠️ The `Net` trap, at its worst as predicted — and the fix was structural

Instantiation renumbers nets, so every wire in `σ₂` is arithmetic in `pcOut`.
**`addendNet : Nat → Nat` is the `Nat` mirror and `σ₂` is defined THROUGH it**;
`instMap_pcOut` proves once that the mirror is the real wire, and every bound
after that is plain `Nat`. *`pcOut` did this for `sem_pcNext`; this is the same
lesson one level up.* It also bit in the small: `n ≠ pcAddZero` defeats `omega`
because `pcAddZero` is an opaque `def` — omega parsed the hypothesis and not the
goal, the exact tell `Compose.lean:206` records. Fixed with `Nat.ne_of_lt`, no
`omega` at all.

### ⛔ Control bar — TWO mutants the certificates accept

The composite has two distinct defect surfaces, so there are two.

* **Mutant A — one wire.** `adSigmaCut`: the adder's carry-in reads `pcNext`'s
  TAKE flag (host net 194) instead of the constant-zero net 129. *The most
  available error in this node: "which net is the zero?"* Still `ssa`, still 260
  gates. **`pcAddCut_passes_the_certificate`: 36 driven points** — the
  not-taken suite, i.e. `pcNext_not_beq_adds_four`'s coverage lifted to the
  composite, the ratified behaviour on **99.80%** of the word space. The mutated
  carry-in is `false` on every one of them. **`pcAddCut_fails_the_theorem`**
  refutes it at one taken branch.
* **Mutant B — the organ.** `pcAddCutB`: the same composite around the landed
  `adder32Cut` (slice 16's carry-out `or` → `and`). ⭐ **This one survives BOTH
  branch directions** — `pcAddCutB_passes_the_certificate` drives taken and
  not-taken alike (18 points) and the mutation is visible only when a carry
  crosses bit 16, which realistic pcs and short branch offsets never do.
  Refuted at `0x0001FFFC + 4`.
* **`pcAdd_passes_the_certificate`** — the same 36-point suite on the REAL
  composite, so "the mutant passes" is distinguishable from "the suite is
  malformed". **`sem_pcAdd_off_the_sample`** — the theorem reaches where neither
  certificate does.

### Attempt counts, against the split budget — content vs mechanics

**Statements: 3 groups (budget 3–4, met)** — the composite plus its net-level
lemma; the word bridge plus the three ISA bridges; the defect-as-a-theorem plus
the two mutants. **Proofs: 2 scratch cycles (budget 2, met). Content changed in
ZERO of them.** The decomposition — host layout pc-first, one constant-zero gate,
`σ₁` a uniform shift, `σ₂` defined through a `Nat` mirror — was fixed before the
first build and never revised. Both cycles were elaboration mechanics, each
diagnosed from the error text:

1. Three mechanical faults in one build. (a) `instMap_pcOut` needed a trailing
   `rfl`. (b) The `Net`/opaque-`def` omega failure above. (c) ⭐ **the reusable
   one: `(kernel) deterministic timeout` on the constant-gate peel.** Stating it
   as a single `rfl` from `run E pcAdd.gates` to `run E₀ (G₁ ++ G₂)` puts a
   **cons on the left and an append on the right**; the kernel's argument-wise
   heuristic fails, it falls back to unfolding `run` on both sides, and it walks
   the whole 259-gate list symbolically. **Rewriting the gate list first
   (`pcAdd_gates_eq`, then `run_cons`) makes the two `run`s agree on their second
   argument syntactically and the check is instant.** *Recorded because every
   future `core` assembly step has this shape.*
2. **`excessive memory consumption detected at 'interpreter'`, EXIT=134** — a
   250-drive certificate (5 pcs × the 10 `pcCases` × the 5 `pcOffs`). Each drive
   re-reduces `instGates` for both instances and then does 32 lookups down a
   260-deep `upd` chain. Cut to 36 + 18 + 36 driven points; green in ~20 s.
   **Measured budget for a composite this size: ~90 kernel-driven `sem` points
   per file before the cap binds.**

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0, 8605 jobs**. **Job-count
delta from PCNEXT's 8605: ZERO** — no module and no import was added; `C4.lean`
already pulls `Compose.lean` into `Program.lean`'s closure, which is the reason
this node needed no import at all.

**65 new declarations, 576 lines.** All 65 are on `#audit_axioms` lists, and
`#audit_axioms` **fails elaboration** on any axiom outside
`[propext, Classical.choice, Quot.sound]` (and on any unknown name), so a green
build is the assertion rather than a report. Independently re-checked with
`#print axioms` in `ScratchMATHPCA.lean` — EXIT=0, exactly the three, on all 25
headline results (deleted, not committed).
`docs/hdl-tools/audit_completeness.py` → **every theorem is on an
`#audit_axioms` list** (35 files, 404 theorems, up from 392). ⚠️ **SCOPE ADDED 8/7 19:0x — `SaltWorks/HDL` ONLY; see below.**

⚠️ **SHARED-TREE HAZARD, RECORDED BECAUSE IT NEARLY COST THIS NODE.** The first
port of this block was written into `Stack/Program.lean` while the `aluSelect`
executor's in-flight `AluSelectSemantics` section was also sitting uncommitted in
the same working tree (that build read 8606 jobs). Both blocks were then wiped by
a third party's checkout before either was committed. **The block survived only
because it was kept in a scratch file outside the repo and the port was scripted
rather than hand-edited** — the port is `git show HEAD:…` + one deterministic
insertion, guarded by a `cmp` against `HEAD` so it refuses to run when a
sibling's edits are present. *Recommended for every seat sharing this checkout.*

### Left undetermined

* ⛔ **`PcField` IS NOT CLOSED and this node does not claim it.** `PcField` is
  about a whole `core`'s output bits `1024…1055`, and no `core` exists. What
  landed is the block-level theorem plus the three bridges a `core` assembly
  applies. **The debt is `core`, not the pc path** — and it is now the *only*
  debt on the pc path.
* **`pcNext` is unchanged.** Not one landed statement was weakened, restated or
  repaired; `run_pcNext_addend` reads the addend back OUT of `sem_pcNext`
  through `pcNext_outs_eq` rather than re-deriving anything.
* **`pcAdd` is not wired into anything.** It is a `Circ` with a theorem; the
  `core` that instantiates it is still owed, and `PcNext.lean`'s header still
  says the addition is left to the assembly. *Correcting that prose is a
  compiler-lane edit and was not mine to make.*
* ✅ **THE ASSEMBLY PLAN WAS FIXED WHILE THIS NODE WAS IN FLIGHT** (`749792d`,
  answering `docs/silicon-refute-pcpath-0807.md` §7): §4 now carries a **13th
  organ — "THE PC ADDER", `adder32`, 160 gates, instantiated via `inst_sem`** —
  `core.outs` takes **that** block's low 32, and the total is re-derived to
  `~12,081`. **`pcAdd` is that organ, built and proved.** *An earlier draft of
  this entry said the plan was stale; it was, for about an hour, and it is not
  now — corrected rather than left standing.*
* ⚠️ **TWO THINGS THE PLAN'S ORGAN 13 STILL DOES NOT ACCOUNT FOR, and this node
  measured both because it had to build them.**
  1. ⛔ **THE CARRY-IN HAS NO SOURCE.** `adder32.nIn = 65` and **net 64 is a real
     carry-in port** — an instantiated `adder32` needs a host net already holding
     `false`, and §4 allocates 160 gates and no zero. `pcAdd` spends **one
     `⟨129, .const false⟩` gate** on it. ⇒ **The core total is `~12,082`, not
     `~12,081`, unless the assembly finds a zero net elsewhere** (it cannot reuse
     an input: `encD`'s state nets are all live). *One gate on 12,000 is
     nothing; naming it is not, because the plan's discipline is that totals are
     derived and not carried.*
  2. **`pcNext`'s 33rd output — the take flag — is confirmed to go nowhere.** The
     plan says *"the flag nowhere yet"*; in `pcAdd` it is host net `194`,
     computed and unread. ⭐ *It is also live and `ssa`-valid, which is exactly
     what makes mutant A — carry-in wired to the take flag instead of the zero —
     a well-formed circuit rather than a rejected one. **The unallocated flag
     sitting one wire from the carry-in port is the hazard, and the mutant is
     that hazard as a theorem.***
* **`inc32` still has no semantics and is still unreferenced.** This node
  confirms it should stay that way: the pc path goes through `adder32`.
* **The carry-out is dropped.** `pcAdd.outs` is the 32 sum bits; `adC 32` is
  live in the netlist and unread. Correct — the pc wraps — but it leaves **3
  dead gates** in the top slice (`adG 31`, `adT 31`, and the carry-out `or`),
  which `opt`'s dead-net elimination would remove and which nobody has run.

## ALUSEL — `aluSelect` unconditional, and what its certificate was actually saying

### ⭐ FIRST DELIVERABLE — the certificate reading, measured

`AluSelect.lean:222-231`:

```
def asOneHot (m sel : Nat) : Env  -- result m all-ones, the other nine all-zero
def asBit0 (m sel : Nat) : Bool := (sem aluSelect (asOneHot m sel)).getD 0 false
def asSelectsOK (m : Nat) : Bool := (List.range 16).all fun sel => asBit0 m sel == decide (sel = m)
theorem aluSelect_selects_on_sample      : asSelectsOK 3 = true := by decide +kernel
theorem aluSelect_selects_on_sample_last : asSelectsOK 9 = true := by decide +kernel
```

The docstring says *"all sixteen select values, kernel-checked"*. **True about
`sel`; silent about everything else.** The axes, separated:

| axis | size | covered by the two theorems |
|---|---:|---|
| `sel`, the select value | 16 | ⭐ **UNIVERSAL — all 16, genuinely exhaustive** |
| `m`, which operand is live | unbounded | ⛔ **SAMPLED — two points, `m = 3` and `m = 9`** |
| the 320 operand-result bits | `2^320` | ⛔ **one pattern per `m`**; `asOneHot` cannot paint any other picture |
| the output | 32 bits | ⛔ **bit 0 only** (`asBit0` is `getD 0`) |

⇒ **The block has `2^324` input valuations and 32 output bits. The certificate
drives 32 of the valuations and reads one output bit.** *`sel` is the universal
argument, `m` is the sampled one, and the operand bits are not an axis of the
certificate at all — the one-hot driver collapses them to a single degree of
freedom.*

⛔ **AND `asSelectsOK` IS NOT A UNIVERSALLY TRUE STATEMENT ABOUT `m`** —
`asSelectsOK_fails_at_ten : asSelectsOK 10 = false`, derived (no kernel
evaluation) from the theorem: at the first PAD slot the tree correctly answers
`false` while `decide (10 = 10)` is `true`. The predicate holds exactly on
`m < 10 ∨ 16 ≤ m`; both proved points sit inside the first range. *So "the
certificate passes" is not a property `aluSelect` has for all `m`. It is a
property of the ten real operand slots — which is what `asSelectsOK_of_lt` now
proves outright.* The docstring's claim about "the six PADDING slots (10…15)" is
exercised as `sel` values and never as `m` values.

### What landed — one theorem, universal in every input

```
theorem sem_aluSelect (E : Env) :
    sem aluSelect E
      = (List.range 32).map fun k =>
          if asSelOf E < asOps then E (asRes (asSelOf E) k) else false
```

Arbitrary operand bits, arbitrary select bits, arbitrary garbage on the 1,445
internal nets; **all 32 outputs pinned.** Stated in the block's own vocabulary
(`asSelOf` = the four select nets as a number, LSB first; `asRes r k` = bit `k`
of result `r`; `asOps = 10`), so it says the thing the file's design decision
claims and nothing checked: **`aluSelect` is a 16:1 mux whose top six sources are
tied low.**

* **`asSelectsOK_of_lt (m) (hm : m < asOps) : asSelectsOK m = true`** — the
  sampled predicate, for **all ten** real operands, as a corollary. This
  supersedes `aluSelect_selects_on_sample`/`_last` rather than restating them.
* **`sem_aluSelect_drive`** — the block on the **general** driver `asDrive`
  (ten arbitrary 32-bit results + a select value). `asOneHot` is one line of it.
* **`aluSelect_word`** — the selected operand as a `Word`; the `pcAddend_word`
  analogue.
* **`aluField_is_aluSelect_add`** — the `rd` field through the select, for
  `ADD` in slot 0. ⛔ **NO `C4Spec` FIELD IS CLAIMED CLOSED. `core` does not
  exist**; this is the service the assembly would apply, in the shape
  `addField_is_adder32` performs for the adder.

### ⭐ WHICH LANDED MACHINERY TRANSFERRED — measured before proving

*Two briefs in a row were wrong about this, so it was checked first.*

* **`run_pointwise` — did NOT transfer.** `aluSelect` has no pointwise block.
  Apart from one `const` and four inverters, every gate belongs to a mux triple
  whose fanin is another gate's output.
* **`run_orChain` — did NOT transfer.** There is no `orChain` here. The
  reduction is a **tree**, not a chain; a tree's levels are blocks in series,
  not a fold, so the chain induction has nothing to bite on.
* **`sem_adder32`'s carry induction — no.** No carry, no arithmetic.
* **What transferred is the METHOD** — frame lemma plus an induction carrying an
  invariant — and `Sem.lean`'s `run_of_unwritten` / `run_append`.

⭐ **THE NEW GENERIC PIECE: `run_muxRow`** — a row of `n` two-to-one muxes, three
gates each (`and`/`and`/`or`), proved generically over the base net, both source
functions, both select nets and `n`. It is to selectors what `run_pointwise` is
to bitwise blocks. `aluSelect`'s 1,440 mux gates are **four instances of it**
(widths 8/4/2/1), and any later block emitting mux triples inherits it.

### The decomposition

```
1 gate     const false                          the shared pad source
4 gates    not sel[j]                           one inverter per select bit, shared
1440 gates 32 independent 4-level mux trees     45 gates per output bit, 15 muxes x 3
```

Bit `k`'s tree occupies nets `329 + 45k … 329 + 45k + 44` and reads only primary
inputs, the pad, and the four inverters — so the 32 trees are proved **once**,
generically in `k` (`run_asBit`), and composed by an induction whose frame is
`m < 329` (`run_asBody`).

### ⛔ NON-VACUITY — the control bar was raised, and it is met

* **`aluSelectCut`** — `aluSelect` with **exactly one gate** changed
  (`aluSelectCut_is_one_gate` proves the zip differs in one position): bit 0's
  level-0 mux at position 2 reads leaf **4** on both inputs, so `sel = 5` returns
  operand 4. Still `ssa`, still 1,445 gates.
  * ⭐ **`aluSelectCut_passes_the_certificate : asSelectsOKCut 3 = true ∧
    asSelectsOKCut 9 = true`** — the mutant satisfies **both** landed theorems,
    because with only operand 3 (or 9) live, the mutated mux sees `false` on both
    of its inputs and cannot tell them apart.
  * ⭐ **`aluSelectCut_fails_the_theorem : asSelectsOKCut 5 = false ∧
    asSelectsOK 5 = true`** — at `m = 5` the mutant answers wrong and the
    unconditional theorem proves the real block answers right. **A mutation
    invisible to the two proved `m` values does exist, and this is it.**
* **`sem_aluSelect_off_the_sample`** — `asOffEnv` has **two operand results live
  at once**, which no `asOneHot m sel` can produce (proved: nets `0` and `64`
  both `true` forces `m = 0` and `m = 2`), and the theorem gives its full
  32-bit answer.

### Attempt counts — content vs mechanics

**The mathematics settled in cycle 1 and never changed.** The decomposition
(`muxRow` row lemma → four levels in series → 32 trees in series → the pre-block)
was fixed before the first build and every later cycle was elaboration mechanics,
each diagnosed from the error text.

* **Statements: 4 groups (budget 3–4, met)** — the block theorem; the
  certificate-supersession pair (`asSelectsOK_of_lt` + `asSelectsOK_fails_at_ten`);
  the driver/word/ISA bridge; the controls.
* **Proofs: 5 scratch cycles (budget 2 — over, recorded). CONTENT CHANGED IN
  ZERO OF THEM.** The five, all mechanics:
  1. ⛔ **The `Net` trap, three times, and it is the whole story of this node.**
     `omega` reported "no usable constraints" for `320 + j < 320` because the
     goal was `Net`-typed. Fix: a `Nat` mirror (`asB`) for the net layout, and
     `Nat`-binder restatements (`asOneHot_eq`, `asDrive_eq`, `asOffEnv_eq`)
     whose entire content is moving a definition's own binder from `Net` to
     `Nat`. **The trap also eats `Net`-typed HYPOTHESES silently**, so
     `q i < base` had to be discharged by `Nat.lt_of_lt_of_le`, not `omega`.
  2. `refine ⟨?_, ?_⟩ <;> · <multi-line block>` does not parse; and
     `run_of_unwritten`'s `g.out ≠ n` obligations were replaced outright by a
     3-gate frame lemma (`run_three_frame`), which removed the `Gate.out`
     projection goals the trap was hiding behind.
  3. `rw` cannot use `asPrev_0_val : F (asPrev k 0 l) = asLeafOf F k l` — the
     pattern is metavariable-headed (`?F (asPrev ?k 0 ?l)`). Explicit
     instantiation, not `simp only`.
  4. ⛔ **`rfl` on `sem aluSelect …` blows `maxRecDepth`** — it forces
     `aluSelect.gates` (1,445 gates). Fix: never let a defeq check straddle the
     gate list; pull the `outs` equality out as its own `rfl` lemma
     (`aluSelect_outs_eq`) and close the rest with `Function.comp_def`.
  5. `List.append_nil` is not `rfl`, so `flatMap` over `List.range 4` needs one
     rewrite before the four levels line up.

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**, and the full tree
`saltbuild.sh` → **EXIT=0**, zero `error:`, zero `warning:` — **8637 jobs when
first measured (pre-`PCADD`), 8638 re-measured after this section was committed
on top of it.** *Both numbers stated because the first is what the proof was
checked against and the second is what HEAD reports; the load-bearing figure is
the targeted delta below.*
All 63 new declarations tick `#audit_axioms` at ≤ 3 axioms, i.e. inside
`[propext, Classical.choice, Quot.sound]`. No `native_decide`, no `sorry`.

**Job-count delta: +1.** `Stack/Program.lean` gained `import
SaltWorks.HDL.AluSelect`; targeted build went **8605 → 8606 jobs** (`AluSelect`'s
own two imports, `EmitS` and `Compose`, were already in the closure).
Independently re-checked in `ScratchMATHALU.lean` (EXIT=0; deleted, not
committed).

### Left undetermined

* **`zeroTree` is still sampled-only** — it has no behavioural theorem at all,
  and it is the other half of `AluSelect.lean`. It is an OR-tree, so
  `run_muxRow` does not apply, but the same level-in-series skeleton does.
* **`aluSelect`'s ten sources still do not all exist.** `sll` and `sra` have no
  producer; this theorem says what the block does with whatever is presented to
  it, which makes the missing producers *more* visible, not less.
* **`C4Spec` is untouched.** No `core`.
* **`asSelectsOK` is now redundant** as a claim (superseded at all ten real `m`)
  but is retained: it is the tripwire, and `aluSelectCut` shows exactly how far a
  tripwire can be walked past.

---

## READTREE — the register read port leaves the sampled tier (Opus executor, 2026-08-07)

**`sem_readTree_uncond`: `readTree` reads the register its address names, over
all `2^997` input valuations and at all 32 output bits.** The block whose own
file says *"the whole difficulty of the register file — verification and area —
lives on the read side"* now has a behavioural theorem with no driver in it.

### ⚠️ What `rtSelectsOK` and `readTree_x0_is_zero` ACTUALLY quantify over

*Measured off the definitions in `ReadTree.lean:293–325`, not assumed.* The shape
is `asSelectsOK`'s exactly — **exhaustive in one argument and silent about the
rest** — and there is a third axis neither of the earlier two nodes had:

```
readTree.nIn = 997                ⇒ 2^997 input valuations
readTree.outs.length = 32         ⇒ 32 output bits, one 32:1 tree each

rtSelectsOK m = (List.range 32).all fun a => rtBit0 m a == decide (a ≠ m ∧ a ≠ 0)
  a    THE ADDRESS    EXHAUSTIVE — all 32, and five address bits IS 32: total.
  m    THE CONTENTS   TWO POINTS (7, 19), each a ONE-COLD file (all-ones but x_m)
                      out of the 2^992 the 31 stored registers can hold.
  bit  THE PORT       rtBit0 = (sem …).getD 0.  OUTPUT BIT 0 AND NOTHING ELSE —
                      31 of the 32 trees are outside the certificate entirely.

readTree_x0_is_zero = rtBit0 7 0 = false ∧ rtBit0 19 0 = false
```

⛔ **YES — `readTree_x0_is_zero` IS TWO POINTS, and it is the one to say loudly.**
Address 0 fixed, two file contents, output bit 0. `St.get_zero` is a *total* ISA
law (`ISA.lean:165`, no hypothesis, every state, every bit); the circuit's
version was a two-point sample wearing its name. **The four standing certificates
between them drive 64 of `2^997` valuations and 1 of the 32 outputs.**

📌 **And the gap is not hypothetical: BOTH one-gate mutants below are ACCEPTED by
the certificate at both its sample points.**

### What landed

| theorem | quantifies over |
|---|---|
| `sem_readTree_uncond` | every `E : Env` — all 997 input nets, all 32 outputs |
| `sem_readTree` | every register file `regs`, every address `a < 32` |
| `sem_readTree_St` | **every `St`, every `Fin 32` — the port IS `St.get`** |
| `readTree_reads_x0_zero` | every state, all 32 bits (was: 2 files, 1 bit) |
| `rtWord_is_get` | the `wordOf` consumer bridge a `core` assembly applies |
| `rtSelectsOK_uncond` | **every `m ≥ 1`, not two** — the certificate as corollary |
| `sem_readTree_off_the_sample` | `rtSelectsOK 2` and `31`, proved with no `decide` |

⭐ **The supersession is real rather than a restatement.** `rtOneCold_eq` proves
the certificate's own one-cold driver IS `rtEnvOf` at the file
`fun i => if i = m then 0 else allOnes`, so `rtSelectsOK m = true` falls out of
the organ theorem for **all 31 stored registers**, not the two that were decided.

⛔ **No `C4Spec` field is closed.** A register-field claim is about a whole
`core`'s output bits and `core` does not exist. *The debt is `core`.*

### Machinery: what transferred, measured rather than guessed

⭐ **`run_pointwise` transferred EXACTLY ONCE and it was an exact fit** — the five
SHARED inverters are `(List.range 5).map fun j => ⟨998 + j, .not j⟩`, the
pointwise shape on the nose (`rtInvGates`).

⛔ **The brief's two candidates from `sem_pcNext` BOTH failed, and the reasons are
structural:**

* **No OR chain exists.** `readTree`'s 992 `or` gates are each the third gate of
  a mux, never a fold; `orChain` appears nowhere in `ReadTree.lean`, so
  `run_orChain` has nothing to apply to.
* **`run_pcAddGates` is the wrong shape for a tree.** `pcNext`'s mux array is 32
  INDEPENDENT one-gate selects off one shared control net — a frame over a flat
  list. `readTree` is a 5-deep TREE: level `n+1`'s outputs ARE level `n`'s
  inputs, so the induction must carry the input-NAMING FUNCTION forward
  (`run_rtLevels` is quantified over `f : Nat → Nat`) and re-establish that the
  new names lie below the new base. **That obligation does not exist in
  `pcNext`.**
* No adder, so no carry — as at `pcNext`, for the same reason.

⇒ ***What transferred is the METHOD plus `run_of_unwritten`, `run_append`,
`sem_congr` and `Op.eval_congr`. What is NEW and reusable is
`run_rtMux` / `run_rtLevel` / `run_rtLevels` — a MUX-TREE induction generic in
the leaf-naming function and the base net*** — which a crossbar or a barrel
shifter built the same way inherits. *Three briefs in a row have now guessed the
transfer wrong; reading the gates first cost ten minutes and saved a rewrite.*

⚠️ **`decide` was never an option and that is the design constraint**, not a
preference: `readTree` reads a 32×32 file, `2^1024` contents. The only
`decide +kernel` in the section is on the two mutants, where the circuits are
closed terms.

### ⛔ THE CONTROLS — one-gate mutants the certificate ACCEPTS

Both are `readTree.gates.map` with a single `out` rewritten, both still `ssa`:

| mutant | the one gate | certificate at 7 / 19 | the organ theorem |
|---|---|---|---|
| `readTreeCutA` | net 1007: `.and 69 0` → `.and 37 0`, so **address 3 reads `x2`** | **ACCEPTS both** | REFUTES at `m = 2, a = 3` |
| `readTreeCutB` | net 1188: the **root of output bit 1's tree**, tied `.const false` | **ACCEPTS both** | REFUTES at bit 1 |

*Cut A survives because at `m = 7` and `m = 19` registers 2 and 3 hold the same
word — a mutation on a path only some other index distinguishes, exactly the bar
`pcNextCut` set.* **Cut B survives because `rtBit0` reads output 0 and the
certificate never looks anywhere else.** ⇒ ***The second is the more damning of
the two: it is not a lucky alignment, it is a whole axis the certificate does not
have.***

### Cycles — SPLIT content vs mechanics

**The decomposition (mux → level → `2^n`-leaf tree → per-bit → 32 bits → the
`x0`-tie/inverter pre-block) was fixed before the first build and NEVER CHANGED.**

* **Statements: 4 groups (budget 3–4, met)** — the organ theorem; the
  driver/ISA/`wordOf` bridges; the certificate supersession (`rtOneCold_eq` →
  `rtSelectsOK_uncond`); the controls.
* **Proofs: 7 error cycles + 2 warning cycles (budget 2 — OVER, recorded).
  CONTENT CHANGED IN ZERO OF THEM.** All nine, as mechanics:
  1. ⛔ **The `Net` trap, three times.** `omega` DROPPED THE GOAL and reported a
     counterexample from the hypotheses alone — on `997 < 998` (head `rtZero`),
     on `rtNotSel jj < b`, and on a `List Net` element. Fix each time: `show` the
     goal at `Nat` with the constants spelled out.
  2. ⛔ **`omega` under a metavariable-headed expected type.** `congrArg₂ List.cons
     (by omega) …` and `upd_of_ne _ (by omega)` elaborate the tactic block BEFORE
     unification fixes the goal, so `omega` sees a metavariable and drops it. Fix:
     `refine … ?_ ?_` with bullets, and named implicits (`upd_of_ne (n := 997)`).
  3. ⛔ **`!x = y` parses as `!(x = y)`** — the recorded trap, hit verbatim in a
     `show`. Outer parens.
  4. ⛔ **`rfl` across the gate list blows the budget twice**: `rtBit_eq` as one
     tuple equation is a `whnf` timeout, and `Function.comp` in the final
     `List.map_congr_left` makes `isDefEq` try to `whnf` `run E readTree.gates`
     (2,982 gates) — `maxRecDepth`, then heartbeats. Fix: **three separate
     projection lemmas** (`rtBit_gates`/`_out`/`_next`) and
     `simp only [Function.comp_def]` BEFORE the congruence, so no defeq check
     ever straddles the gate list. *`aluSelect` recorded the same shape at 1,445
     gates; it is now twice-observed and belongs in any tree-block brief.*
  5. `conv_lhs => rw [rtLevel]` leaves the match-completeness side goal — `rfl`
     discharges the equation directly.
  6. `let`-bound RHS in an equation lemma is unusable by `rw`: the occurrence sits
     under a binder, so the pattern never matches. Fix: name the sub-term as a
     `def` (`rtLevAt`) and restate projection-wise.
  7. `set … with h` rewrote the goal but left the hypotheses displaying the
     unfolded body, so `rw [h]` failed. Dropped `set` entirely.
  8–9. Two warning cycles: unused `simp` arguments, and `run_rtMux`'s `x < b` /
     `ns < b` hypotheses turned out to be **unnecessary** (the first gate reads
     them before anything is written) — so they were deleted, which strengthens
     the lemma.

⚠️ **AND ONE INCIDENT THAT IS NEITHER**, recorded because it is a fleet hazard
rather than a proof fact: **a sibling executor's checkout of the shared
`Stack/Program.lean` deleted this section from the working tree after it had
built green** (source mtime one minute newer than the `.olean` that still
contained the declarations). It was reconstructed verbatim from the session
record and rebuilt clean — **no proof content changed** — but the shared-tree
rule needs the corollary that lands here: *an executor holding uncommitted work
in `Stack/Program.lean` should commit as soon as it is green, not at the end.*

### Build + audit

`saltbuild.sh SaltWorks.Stack.Program` → **EXIT=0**, zero `error:`, zero
`warning:`. All 62 new declarations tick `#audit_axioms` at ≤ 3 axioms
(`[propext, Classical.choice, Quot.sound]`; the four mutant theorems at
`[propext]` alone). No `native_decide`, no `sorry`. Independently re-checked with
`#print axioms` in `ScratchMATHRT.lean` (EXIT=0; not committed).

**Job-count delta: +1**, `8606 → 8607` on the targeted build. `Stack/Program.lean`
gained `import SaltWorks.HDL.ReadTree`; `ReadTree`'s own imports (`EmitS`,
`Compose`) were already in the closure. *A +2 was measured earlier in the same
session, `8605 → 8607`, before `ALUSEL` landed and put `EmitS` in the closure —
the load-bearing number is the +1 against the current baseline.* **747 lines
added** (101 prose, 626 proof, 15 audit; 62 declarations).

### Left undetermined

* **`readTree` has no `wf`/emission consequence stated here.** `readTree_ssa` and
  `readTree_wf` are landed in `ReadTree.lean`; nothing in this section touches the
  emission layer, which `emitPipeline'_sem` covers generically.
* **The write path is still unproved and is the cheap half** — `RegWrite.lean` is
  183 cells against the read path's 1,508, and the read side is now the proved
  one. The asymmetry has inverted.
* **`C4Spec` is untouched.** No `core`.
* ⚠️ **`docs/hdl-tools/audit_completeness.py` DEFAULTS TO `SaltWorks/HDL` AND HAS
  THEREFORE NEVER READ `SaltWorks/Stack/`.** Run with the explicit root it reports
  `563 theorems` and **two unaudited: `batcher4_length`, `batcher8_length` in
  `Stack/ZeroOne.lean`.** *Not repaired here — it is another file and this commit
  is kept surgical — but the tool's own thesis ("a whitelist cannot distinguish a
  correct set from an empty one") applies to its own default root.*
* **`rtSelectsOK` and `readTree_x0_is_zero` are retained** in `ReadTree.lean`,
  untouched. They are the tripwires, and the two mutants above are the measured
  statement of how far a tripwire can be walked past.
