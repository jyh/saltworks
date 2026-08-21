# THE HORN D SWAP — PRE-STAGED RUNBOOK

**Staged `2026-08-20T15:41:03-0700`, tree at `f13bb26`. The swap has NOT been performed.** Helm ordered the block routed
(math to make `Stack/Program.lean` width-agnostic) and this seat to pre-stage so the swap fires the
moment that lands. This file is that staging. It is written BEFORE the unblock so no step is
chosen to fit whatever math's repair turns out to look like.

## STEP 0 — THE GATE. Do not begin without it.

```
bash docs/ledger-tools/swap_ready.sh      # EXIT 1 = blocked (today) · 0 = trigger · 2 = cannot tell
```
Both arms driven at staging time: negative → 1, positive → 0. **It answers by RUNNING, not by
memory.** It is a TRIGGER, not a verdict — see STEP 1.

## STEP 1 — ARM 2, THE ONLY THING THAT IS A VERDICT

"math changed the file" and "the swap elaborates" are **different claims**, and only the second
licenses touching a worktree five seats share.

```
git worktree add /tmp/swapdry HEAD        # ISOLATED. Never dry-run in the shared tree.
```
Apply STEP 2 there, build, and READ THE FAILURES. Expect a full cold Lean build; budget for it and
run nothing else heavy alongside — this fleet produced SIGABRT/SIGTERM under load today.

## STEP 2 — THE EDIT (all inside `SaltWorks/HDL/**`, this seat's glob per `SEATS.md:8`)

`StateCodec.lean`: `stWidth`, `stBit`, `decQ` take the D layout. **Do not re-derive it** —
`StateCodecD.lean` already carries it PROVED, and the port is mechanical:

| today | after | source of truth |
|---|---|---|
| `stWidth = 1056` | `1313` | `StateCodecD.stWidthD_value` |
| `instrBase = 1056` | `1313` | `StateCodecD.renumbering_offsets` |
| `coreInWidth = 1088` | `1345` | same, `instrBaseD + 32` |
| `offTie = 1088` | `1345` | +257 |
| `offOb = 7242` | `7499` | +257 |
| `offEnc = offRw = 7955` | `8212` | +257 |
| `offPc = 8122` | `8379` | +257 |
| `offRegNext = 8382` | `8639` | +257 |
| chain end `11486` | `11743` | +257 |
| `core.outs.length = 1056` | `1313` | the flagship's own width |

### ⭐ MOST OF THAT TABLE UPDATES ITSELF — verified, and it changes the shape of the job

The `CorePlace` offset chain is **DERIVED, not hardcoded**:
```
instrBase   := stWidth            coreInWidth := stWidth + 32       offTie   := coreInWidth
off0        := instNext tieCells offTie          offOb    := instNext bitNot32 off5
offEnc      := instNext …sliceASelect offSel     offRw    := instNext …ruledEnc offEnc
offPc       := instNext regWrite offRw           offRegNext := instNext …pcAdd offPc
```
⇒ **Change `stWidth` and the entire running sum re-derives.** The right-hand column above is what
the new values WILL BE, not a list of edits to type. Do not hand-edit a derived offset.

⛔ **THE MANUAL WORK IS EXACTLY THREE CLASSES, and they are the ones a green build cannot find:**
1. **`CoreOffsets.off0 : Nat := 1088` — HARDCODED**, and it is a *different declaration* from
   `CorePlace.off0` (which is derived). ⚠️ **Two live `off0`s in one tree**: fix the hardcoded one
   and leave the derived one alone, and do not let the shared name make you edit the wrong file.
2. **DECIDED FACTS asserting literals** — `AccountMeasure.offsets_pinned`, `chain_end_is_11486`,
   `core.outs.length = 1056`. These re-prove at the new values once the literals are updated; the
   theorem NAMES carrying figures must move with them (`chain_end_is_11486` → `…_11743`, an
   obligation already registered in its own docstring).
3. **PROSE** — STEP 3.

*Grep for hardcoded twins before assuming any value updates itself; `CoreOffsets.off0` is the one
that proves the habit is worth keeping.*

### ⭐ STEP 2b — `StateCodec` ITSELF BREAKS FIRST, AND THE FIX IS MEASURED, NOT SKETCHED

**The first module the swap breaks is `StateCodec.lean` — four errors — and they are the two defect
classes math named in their own glob, verbatim:** the `stBit` two-branch walk, and the `and_true`
arity. *I hit them in the 16:3x attempt and again in the 19:4x isolated dry run, and in BOTH runs
the fix below made `StateCodec` elaborate CLEAN, moving every remaining failure downstream where it
is informative.*

⛔ **RECORDED HERE BECAUSE I NEARLY LOST IT.** Both times this fix existed only inside a scratch
worktree I then tore down. *Work that is not a durable artifact is not delivered* — and a peer was
about to re-derive it in my own glob because they could not see it.

**① `stBit`'s walk gains two branches, so every `rw [stBit, if_neg …]` needs its full chain:**
```
  regs :  if_pos (by omega)
  pc   :  if_neg (by omega), if_pos (by omega)
  mem  :  if_neg (by omega), if_neg (by omega), if_pos (by omega)
  trap :  rw [stBit]; simp
```
**② `and_true` stops firing and the anonymous constructor's ARITY changes.** `St.mk.injEq` yields
FOUR conjuncts under D, not two. So `simp only [decQ, St.mk.injEq, and_true]` + `refine ⟨?_, hpc⟩`
becomes `simp only [decQ, St.mk.injEq]` + `refine ⟨?_, hpc, ?_, htr⟩`. **Drop `and_true` from the
simp set** — under D it is an unused argument and the linter says so.

**③ AND THE STRUCTURAL MOVE THAT MAKES IT ALL LAND: prove the FULL round trip, then DERIVE THE TWO
PRE-D STATEMENTS BACK FROM IT.**
```
theorem decQ_encD (s : St) : decQ (fun j => (encD s).getD j false) = s
  -- port StateCodecD.decQD_encDD verbatim, renaming stWidthD/encDD/decQD/stBitD
theorem decQ_encD_proj … := by rw [decQ_encD s]; exact ⟨rfl, rfl⟩
theorem decQ_encD_of_clean (s) (_hm) (_ht) … := decQ_encD s   -- hypotheses now DEAD, kept so
                                                              -- no caller breaks
```
⚠️ **`decQtransposed` (the non-vacuity control) MUST KEEP its all-zero memory** — it tests the
REGISTER layout, and giving it real memory would silently retune the control. Its `mem :=
Vector.replicate 8 0` is NOT one of the anchors to change; the `decQ` one is distinguished by the
M1a comment directly above it.

## STEP 3 — THE SILENT CLASS: PROSE

Docstrings in `C4.lean`, `CorePlace.lean` and others cite `1056`/`1088` in **prose**. *Stale prose
builds green forever.* After the swap, re-grep every moving literal across `SaltWorks/HDL/**` and
fix the comments in the SAME commit — a green tree is not evidence the prose is right.

### ⛔ STEP 3b — THE SIX PROSE `34`s, ENUMERATED (owed by this seat, named by math 22:01)

`29f6128` split the iff and discharged all four conditions, so **the flagship's decomposition is
now 43, not 34** — and six docstrings in `SaltWorks/HDL/**` still say 34. *They compile forever.*
Counted, not taken on faith:
```
RegField0.lean:8      "splits C4Spec core into 34 obligations"
RegField0.lean:102    "THE FIRST OF THE THIRTY-FOUR"
CoreAssembly.lean:20  "splits C4Spec into THIRTY-FOUR"
PcFieldClosed.lean:12 "splits C4Spec core into 34"
RegFieldSchema.lean:8 "splits C4Spec core into 34 obligations"
C4Reduction.lean:8    "split C4Spec core into 34"
```
⚠️ **DO NOT BULK-REPLACE `34` → `43`.** Each line also enumerates the parts ("an output count,
thirty-two `RegField`s, `PcField`") and the enumeration must gain the eight `MemField`s and the
`TrapField` too — *a number corrected beside a list that still says three parts is a worse artifact
than the stale number,* because it reads as freshly checked. Fix the COUNT and the LIST together,
and re-run the grep afterward: `THIRTY-FOUR|34 obligations|into 34` over `SaltWorks/HDL/**`.

## STEP 4 — THE DIFFERENTIALS, from `docs/Q6-DIFFERENTIAL-PREREGISTRATION.md` (+ its amendment)

**Run `decQ_mem` FIRST.** It must FAIL to compile. *If it still proves, D connected nothing and
nothing downstream is informative — STOP.*

MUST BREAK: `decQ_mem` · `stepT_lw_writes_zero` · `lw_forces_false_whatever_the_enable_does` ·
`datapath_forces_zero_select_on_LW` · `no_enable_repairs_the_load` ·
`regDatapathOK_is_false_on_LW_either_way` · **`RegNextUniform.X0.on_target_case_is_false`** (added
by the amendment — it is the same refutation transported, and it landed at `b64722e`).

MUST SURVIVE, TEXT UNCHANGED: `step_lw_writes_zero` · `step_lw_trap_holds` (both hypothetical in
`hmem`) · **`RegNextUniform.X0.regDatapathOK_of_on_target`** (the reduction; says nothing about
memory) · every non-LW value/enable row landed at `b64722e`.

`c4Spec_core_is_false`: MUST BREAK **only after the load is repaired**. Breaking it earlier means a
refutation lost without a proof gained.

⛔ **AND THE BAR THAT VOIDS EVERYTHING ELSE:** any post-D verdict on an LW exhibit computed against
a witness whose loaded word is not **provably non-zero** is VOID. `sL`'s construction idiom is
structurally incapable of populating memory (measured: top bit 1087 for every `wL : BitVec 32`), so
**the witness must be RE-CHOSEN, not re-proved.** Do this against the D layout's memory home —
words at `1056 + 32*w + k` — which `StateCodecD` now pins.

## STEP 5 — LAND

`landcheck --arm`, bare `../saltbuild.sh`, `landcheck --check`, `-F` heredoc commit,
`checked_push.sh`, bus line, queue volatile fields in the same commit.

## What this runbook does NOT license

Editing `SaltWorks/Stack/**` (math's, read-only). Weakening any row to reach its pre-registered
verdict — that is a WALL, reported. And beginning at STEP 2 because STEP 0 "obviously" passes.
