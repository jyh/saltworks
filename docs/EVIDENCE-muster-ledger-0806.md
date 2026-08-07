# MUSTER — THE RESULTS LEDGER, day 1 (2026-08-06)

**Assembled by the EVIDENCE seat for the 07:00 muster**, per the maestro's
19:49 split: this file is the **results ledger**; the Captain-facing morning
brief is written on top of it by the maestro. Format is the maestro's 19:16
order — **results · honest negatives with mechanism · in flight · cost**.

**Every count and every table in §1 is GENERATED** (`landed.py`,
`token_meter.py`, `human_time.py`) rather than typed. Kernel verdicts and
measured numbers are quoted from the seat that produced them, **with that
seat named**, because this seat did not run their builds.

⚠️ **Two things this ledger is not.** It is **not** a claim that anything
*works* — a commit table knows only what was committed. And **seat
attribution in §1 is a path heuristic** from the writer-slot law, not a
claim about who typed what.

---

## 1. WHAT LANDED — generated

**213 commits across 2 repos on 2026-08-06.**

### `saltworks` — 151 commits, 23,128 lines, 4,008 `.lean`

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| evidence | 93 | 11,727 | 0 |
| silicon (leg 3) | 33 | 7,451 | 1,455 |
| compiler (leg 2) | 25 | 4,048 | 2,503 |
| maestro (hub + structure) | 6 | 168 | 50 |

⛔ **REGENERATE THIS SECTION BEFORE THE MUSTER — IT AGES.** Staged at
20:00 for the maestro's convenience, and *staging early means the counts
start aging immediately*: compiler went **23 → 25** in the six minutes
between the first generation and the first re-run. **A generated table is
only ungenerated the moment it is pasted into a document.** One command,
and it supersedes everything above:

```sh
python3 docs/ledger-tools/landed.py --since '2026-08-06 00:00' --summary-only
```

*This is resource lesson 5 turned on the tool built to fix resource lesson
5 — `landed.py` exists because a hand-maintained table ages, and its output
ages too the instant it stops being output and becomes text.*

✅ **ONE WINDOW FOR EVERY SEAT, verified by re-running rather than
asserted** — all four lanes above come from a **single** invocation, so no
seat's day-number sits beside another's night-number. *(Silicon asked for
exactly this and asked not to be given the flattering figure: their
night-window `.lean` is **+57**, their day-window is **1,455**; the ledger
uses the day, as it does for everyone.)*

### `salt` — 62 commits, 9,990 lines, 4,489 `.lean`

Dominated by `docs: blueprints` (14 commits, 2,641 `.lean`) and
`salt: HB` (6 commits, 1,441 `.lean`).

*Evidence's 89 commits carry **zero** `.lean` lines. That is the correct
shape for this seat — instruments and record, not proofs — and it is stated
so a commit count is not read as mathematical output.*

### ⭐ These figures were INDEPENDENTLY RECOMPUTED by the seats they describe

**Both leg seats checked their own numbers before this went to the Captain,
and both deltas are published rather than reconciled away.**

| Figure | This ledger | The seat's own recount | Δ | Cause |
|---|---:|---:|---:|---|
| compiler `.lean` lines | **2,503** | 2,503 | **0** | **Exact — the same integer**, same path set, same unit. |
| silicon `.lean` lines | **1,455** | 1,466 | ~~11~~ **0** | ⛔ **NOT "within noise" — and silicon's own generous reading of it was the wrong one.** Resolved at the bytes: `SaltWorks/Silicon` alone is **+1455 / −18**; `Silicon + Tactic` is **+1484 / −18**; `Tactic` alone is **+29**. So this ledger reports **additions on one path (1,455)** and silicon recounted **net on two paths (1,466)**. **The "11" is the residual of two exact differences that partially cancel: +29 (Tactic included) − 18 (deletions subtracted) = 11.** On like-for-like both are **exact**: additions/one path = 1,455 = 1,455; additions/two paths = 1,484 = 1,484. *Neither figure was noisy; the comparison was.* |
| compiler commits | **23** | 13 *(their muster file)* / 25 *(their recount)* | — | ⛔ **NOT a discrepancy — a MISSING WINDOW.** 25 commits touched compiler's slot **today**; **13** of those are in the **post-relight session**, 12 in the **pre-migration session**. This ledger counts the day; their file counted the session. **Neither was wrong; neither said which question it was answering.** |

⇒ **`A count without its window is the same defect as a countdown without
its date`** *(compiler, 19:53)* — the defect that produced tonight's
**"13 days"** against a true **31**, three seats deep. **Caught here before
two documents contradicted each other in front of the Captain.**

**The window for every count in this section is: `2026-08-06 00:00 → now`,
both repos, all seats.** Lane attribution is a path heuristic; the two
deltas above are its measured width, and neither is a defect.

---

## 2. THE GATES THAT MOVED

| Gate | State at muster | Evidence |
|---|---|---|
| **TinyTapeout submission gate** | 🟢 **OPEN** | GDS action green **all four jobs** on `main`, replicated at **two shas** — `8144b6ec` then `f14a4fa1` (run `31140274735`, confirmed as HEAD). `precheck` ✅ (blocking DRC/pin/power), `gl_test` ✅ **against the POWERED post-layout netlist over the same 255 destination sets the kernel proof quantifies over**, `viewer` ✅. Three reds beneath on the same branch/workflow are the control. *(silicon)* |
| **Ruling 4a — `(* keep *)` through TT CI** | ✅ **CLOSED YES**, on the fabricated netlist | Max cone input **36 → 21**, per-cone certifiable **87.5% → 100%**, inside the 24-bit kernel ceiling. Tooling equality checked first: `pdk.json` byte-identical, `resolved.json` zero differing keys. *(silicon; readout pre-registered by evidence)* |
| **Leg 2** | ✅ **COMPLETE** | T1–T5 + sequential + **T2 `emitN_sem`** (`8c4f8d7`), **9/9 `Built`, not `Replayed`**. `fabric3_ssa` puts the 72-gate 8×8 fabric inside the emission precondition. *(compiler)* |
| **Leg 1 — TAU-SHARP** | ✅ **631.58 → 86.23** | TS-1+TS-2, **82% of the entire `log(1/c)` prize for ~140 lines**. TS-3 **deferred** on demand-side evidence per a pre-registered rule. *(math)* |
| **Ruling 3 — does `-M` bind kernel reduction?** | ✅ **CLOSED: the cap is real** | Three-run design; the decisive third run is the same file at `--cap 12000` producing **no memory diagnostic at all**. *(compiler)* |
| **Ruling 3a — cap sizing** | ✅ **`E ≈ 0`; the threshold is peak RSS** | `C* ∈ (8400, 8410]` against RSS 8407 — a 10 MiB bracket on an 8.4 GiB run. *(silicon, refuting compiler's constant on compiler's own criterion)* |
| **Ruling 6 — hub imports** | ⚠️ **PAID, THEN RE-OPENED THE SAME EVENING — do not read "the default build covers all three legs" tonight** | The hub sweep landed and the default build is green at 8,602 jobs *(maestro)*. **But `SaltWorks.HDL.Renumber` is not in `SaltWorks.lean`:** the default build audits **89** HDL declarations, a targeted build of `Renumber` audits **120**, so **31 declarations — all five renumber obligations, the frame lemma, `opt_wf` — sit OUTSIDE the default build's closure.** ✅ They **are** kernel-checked (targeted build, this machine, `Built` not `Replayed`). ⛔ *"They are kernel-checked" and "the default build covers leg 2" are two different sentences and only the first is true tonight.* **`import owed: SaltWorks.HDL.Renumber`.** *(compiler, self-reported at 19:52 — and this is the SECOND time today the same gap was found from opposite sides: silicon caught `FabricRoutes` sitting outside compiler's green 8,590-job build this afternoon.)* |
| **The record itself** | ✅ **VERSIONED** | The bus had **no repo, no remote, one copy, 1,171 lines**. Now `${SEAT_DIR}/fleet/BUS-triple-campaign.md` on a **verified-private** remote, refreshed by one command with the lane check re-run every push. *(evidence)* |

**Two seats wrote their own muster lines as files, to this same format, with
every SHA resolved in its own repo and its subject read back:**

* **`docs/silicon-muster-0806.md`** (`6b7a0d7`) — leg 3
* **`docs/hdl-muster-0806.md`** (`4e40547`) — leg 2

**Take them verbatim; nothing of either seat's needs digging out of 770 KB
of bus.** *This is the visibility law arriving at its useful form: a muster
line that is a committed file cannot be mis-transcribed by the seat
assembling the ledger — which is exactly what I would otherwise have done
to compiler's coverage fact below, since I had already written the
opposite.*

---

## 3. HONEST NEGATIVES — results, with mechanism

**The maestro's format credits these as results. They are the more useful
half and they are not footnotes to the green gates.**

| Negative | Mechanism — *why*, not just *that* |
|---|---|
| **The stage-column picture is CLOSED NO** *(silicon)* | Obstructions did not fight the flow — they were accepted and simply do not produce columns, because **nothing ties a stage to a region once flattening destroys instance names**. `YosysUnmappedCells` hard-fails on the retained hierarchy that grouping would require: **the property enabling the picture is the property the flow rejects.** All four levers closed on measurement. |
| **A CI run failed on a truncated config** *(silicon)* | 18 keys cut to 2, past a validator **whose whitelist could not see deletion**. |
| **TS-3 deferred** *(math)* | Not a stall: the consumer's demand is quantitative in **`b`, not `log(1/c)`** — driving `log(1/c)` to **zero** moves the threshold **0.27%**; `b : 680 → 210` moves it **10.5×**. ⚠️ And math flagged unprompted that this arithmetic is a **hand derivation, not a kernel-checked composition** — *strong enough to defer a wave on, not strong enough to quote as a theorem.* |
| **The migration truncated the ledger's raw material** *(evidence)* | The runbook re-synced repos and kit before cutover but **not `~/.claude/`**; transcripts stop at **14:07:56** while git carries work to **14:30:08**. **82% of the campaign's longest silence window is missing record, not measured absence.** Detector shipped; **the hole is still open** pending one rsync from the laptop. |
| **`#audit_axioms` cannot see a theorem that does not exist** | ⛔ **RETRACTED.** Six broken theorems plus a control: every break yields `Unknown constant` or `sorryAx`. **Not one tick for a broken theorem.** *A true narrow claim was replaced by a false total one because the false one was more quotable — and evidence moved it into the README in 26 minutes.* |

---

## 4. IN FLIGHT AT MUSTER

- **H5–H8 — the human's clicks with a card**, ending in **"Submit a new revision" — the click that is NOT the payment.** Flagged at 09:01 and still the single most likely way this ends badly.
- **The week-2 codegen freeze** is written and **frozen pending an adversarial pass** — *not started, nothing built* — because the seat that wrote it would build it *(compiler)*.
- ⛔ **An OWNER-LESS DEPENDENCY, named here rather than left implied:** the codegen freeze and evidence's RISC-V datapath brief **meet at exactly one artifact — `step` — and nowhere else**, and `step` **must be landed and frozen before day 1, not sketched**. Two documents stop at the same word and neither owns it.
- **Three items sit with JYH:** the laptop transcript rsync (decaying), a three-line lane adjudication, and the human-time tag ratification.

---

## 5. COST — one line, and the unit stated

**Fleet, personal lane, 2026-08-06 15:25 → 19:49 (post-relight):
2,451 deduplicated requests · 1,863,628 OUTPUT tokens · cache read
695,230,950 (its own column, never in a headline).**

**This seat alone, same window: 466 requests · 310,665 output tokens**
(subagents 7,269 of that, 2%) · cache read 114,281,755.

⚠️ **A trap worth publishing rather than quietly avoiding:** the tagging
workflow reported **"507,808 subagent tokens"**, and the *output* share of
that is **7,269 — 1.4%**. The two are different units. **Quoting the large
number as cost would overstate output by ~70×**, which is exactly why the
charter puts cache in its own column and never in a headline.

⚠️ **Per-account attribution remains unavailable** — the records carry no
account, org or subscription identifier. Reported as a gap, never estimated.

---

## 6. WHAT THE HUMAN-TIME NUMBER IS, AND WHAT IT IS NOT

Tagged tonight at JYH's direction, adversarially challenged before
assignment — **one of this seat's own proposals was refuted and retagged
WATCHING**, which shrank the claim.

⛔ **THE CLAIM computes to 11h 13m of 11h 16m = 99.6%. DO NOT PUBLISH THAT
NUMBER.** No tag is wrong; **the unit is.** The charter tests each *touch*;
the tool tags each *block*, and a block containing one irreducible order
drags its whole duration into the claim — block `20260806T1243` is
*mostly* watching-shaped (11 of 20 typed messages redirect nothing; its
longest stretch is ten minutes of iTerm2 window-management) yet counts
entire. **Quote it as a coarse upper bound or not at all.**

⛔ **And a new injection class no provenance field can catch:**
`tmux send-keys` nudges arrive with `promptSource: "typed"`,
`userType: "external"`, `origin.kind: "human"` — **identical to a human,
because at the terminal layer it IS a keystroke.** **4 of 128 human-classified
records on 8/6 are machine-authored (3.1%).** It inflates human-time and
shortens silence windows — opposite directions, both stated. The only
possible detector is **cross-seat correlation**, not provenance. Specified
in `measurement-preregistration.md` ADDENDUM 3; not built.
