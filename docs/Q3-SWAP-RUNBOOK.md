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

## STEP 3 — THE SILENT CLASS: PROSE

Docstrings in `C4.lean`, `CorePlace.lean` and others cite `1056`/`1088` in **prose**. *Stale prose
builds green forever.* After the swap, re-grep every moving literal across `SaltWorks/HDL/**` and
fix the comments in the SAME commit — a green tree is not evidence the prose is right.

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
