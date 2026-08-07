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
