# PROVEN-ABOUT vs MERELY-BUILT — the environment-level census

**Duty:** the maestro's 15:35 order — dispatch an executor for the Lean-side dependency
census; *"a `core` assembled from built-but-uncertified organs is the F2 pattern at
scale."* **Method:** a theorem's SUBJECT is the constants in its **statement type**,
unfolding only constants declared in the *same module* (compiler's technique, which is
the gap between statement-only scanning and unfold-everything). Executor-built,
**spot-checked at source by this seat before publication**.

---

## The headline is a correction to the question

⛔ **The literal `UNCERTIFIED-IN-DEFAULT-BUILD` class is EMPTY.** Only **17** in-closure
definitions are reached by any out-of-closure theorem, and **all 17 also have in-closure
theorems**. ⇒ ***The subtraction kills the entire reach set: 17 of 17 are false positives
for the only-outside question.*** **Compiler's own retraction of its header was exactly
right, and this quantifies it.**

🥇 **The class is real — but it is defined by BEHAVIOUR, not by presence. Exactly two
members:**

| def | declared | in-closure certificates | behavioural certificates live in |
|---|---|---|---|
| `adder32` | `HDL/Adder.lean` | `adder32_ssa`, `adder32_wf` — **both structural** | **`HDL/Bitwise.lean`** (outside): `sub_via_adder_correct`, `sltCirc_correct`, `sltuCirc_correct`, `slt_differs_from_sltu`, `cmp_blocks_are_distinct`, `cmp_upper_bits_are_zero` |
| `bnComps` | `HDL/BatcherNet.lean` | 10, all structural/counting (`bn_comps_count`, `bn_every_wire_used`, …) | **`HDL/BatcherNetC.lean`** (outside): `bnC_rotation_routes`, `bnC_concentrates_actives`, `bnC_identity_is_fixed`, `bnC_sorts_reversed_input` |

📌 **`bnComps` is NEW — nobody had it.** `adder32` was found by hand this afternoon;
this is its only sibling, and it sits under the Batcher network the whole switch story
rests on.

⭐ **AND `Adder.lean` DOCUMENTED ITS OWN GAP IN A DOCSTRING — line 53, verbatim: *"No
theorem says these circuits add."*** ***The finding was written down by its own author
and read by nobody as a finding for as long as the file has existed.*** *That is the
strongest argument in this report for a machine census over a careful reading.*

## The census

| class | count | isType |
|---|---:|---:|
| PROVEN-ABOUT | 494 | 35 |
| **UNCERTIFIED-IN-DEFAULT-BUILD** (literal) | **0** | 0 |
| MERELY-BUILT | 86 | 4 |
| **B-UNCERTIFIED** (behavioural) | **2** | 0 |

*722 in-closure theorems walked, 56 out-of-closure. Closure recomputed inside Lean from
the module graph and cross-checked against `import-closure.py` — 62 modules, 54 in,
8 out, exact agreement.*

## ⛔ MERELY-BUILT — 86 definitions no theorem anywhere mentions

The ones that matter for `core`:

- **`HDL.PriorityEnc` — the entire block, 21 defs.** `priorityEnc` and every helper.
- **`HDL.EmitS` (12) + `HDL.EmitV` (4)** — the emitters. `#eval`-checked only.
- **`HDL.Adder` (9)** — including **`inc32`, the `pc+4` incrementer, with ZERO theorems
  anywhere in the tree** *(verified independently: `inc32` appears in exactly one file
  and zero theorems)*.
- `Silicon.Imported.Fabric` (5), `FabricCut` (6), `AluSelect` helpers (11).

⚠️ **A further 101 in-closure defs are certified STRUCTURALLY ONLY** — theorems exist,
none behavioural. **~54 of those are Sky130 cells and are an instrument artefact**
(their semantics is direct `Bool` algebra with no named evaluator, so the behavioural
axis cannot see it); the real structural-only count is ~47, including all 13 `adder32`
net-index helpers and 16 `BatcherNet` helpers.

## 🎁 A finding nobody asked for

⛔ **Two of the eight out-of-closure modules — `Silicon.Equiv.CERefinement` and
`CERefinementC` — had NEVER BEEN BUILT in this worktree at all.** The executor's first
run failed on `object file … CERefinement.olean … does not exist`.

⇒ ***Their theorems were not merely outside the default build; they were in NOBODY'S
environment.*** ✅ **Built on demand in 14 s and 18 s, and both reported `Built`, not
`Replayed` — real kernel checks, 5 `#audit_axioms` ticks.** *So they are sound; they
were simply never being checked by anything.* 📌 **This is [[replayed-is-not-checked]]
one step further out: not a cache pretending to be a kernel, but a module absent from
every build anyone runs.**

## ✅ Validation — both directions, both halves

| probe | expected | got |
|---|---|---|
| `adder32` | UNCERTIFIED | ✅ **B-UNCERTIFIED** (literal PROVEN-ABOUT via 2 structural theorems — discrepancy pinned to exactly those two names) |
| `readTree`, `aluSelect`, `shifter32`, `regNext` | PROVEN | ✅ all PROVEN-ABOUT **and** B-PROVEN, behavioural theorems named |
| `decQ`, `encD`, `wordOf`, `stepT` | PROVEN — **the subtraction test** | ✅ all PROVEN + B-PROVEN, all hits IN-closure |
| `inc32` (free probe) | — | MERELY-BUILT, 0 hits |

⭐ **The four negative controls came from compiler's retracted header. Neither control
set was designed — both fell out of someone being wrong in public, and together they
test both halves of the instrument.**

## ⚠️ What the instrument cannot see — named, not implied

1. **The behavioural axis is a 24-name heuristic** (`sem`, `run*`, `step*`, `eval*`).
   Printed by the tool so it is auditable. Known miss: the 54 Sky130 cells. Known
   over-count: `Banyan.step` is routing arithmetic, not an evaluator.
2. **Cross-module harness defs are invisible** — unfolding stops at the module boundary
   by design. No such case among the probes; **not bounded**.
3. **`simp`/rewrite reachability is not modelled.** This answers *"is it in a
   statement"*, not *"does any proof depend on it"*.
4. **`partial def` bodies are opaque** (4 defs).
5. **Private theorems dropped** — 5 sites.
6. ⛔ **A residual generated-declaration leak, measured rather than assumed:** 113 Lean-
   generated declarations (`.casesOn`, `.recOn`, `.elim`, `deriving` instances) survived
   the in-elaboration filter and **inflated MERELY-BUILT from 86 to 182**. The numbers
   above are the cleaned ones. **The filter fix is named and must be applied before the
   tool lands** — this report quotes cleaned figures from a raw run, and that gap is
   stated rather than hidden.
7. **Structure projections are dropped, not labelled** (371 defs).

---

## Status

**Report: delivered. Tool: NOT YET LANDED.** The metaprogram is at
`ScratchEVIDENCEDEPS.lean` (gitignored, ~290 lines). It needs the §6 filter fix and a
re-run showing raw == cleaned before it goes into `docs/ledger-tools/`. **Landing it
with a known leak and post-hoc arithmetic would be exactly the defect this seat has
spent the day reporting in other people's tools.**
