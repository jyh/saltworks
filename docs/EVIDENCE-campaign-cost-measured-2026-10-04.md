# What the campaign took — model-hours, human hours, defects caught (measured 2026-10-04)

Measured by the saltworks lead for the talk's cost slide. Every figure carries its
window, the population it counts, which attribution it uses, and what it leaves out.
**A figure without its limits is not a figure from this file.**

**Window, all three:** campaign start **2026-08-05 22:02 PDT** (`docs/EVIDENCE-campaign.md`
14–15) to the shuttle submission merge **2026-09-07 17:15:30 UTC** (TT PR #361) —
**780.2 calendar hours** (32.5 days).

**Three attributions, never mixed:**

- **CHIP BY PATH** — work done in this repository and the chip repository
  (`tt-neural-dataflow-fabric`), by the project directory the session ran in. A **floor** for
  the chip: through 08-25 the coordinating session ran in another project's directory while
  working the chip, and none of that is counted here.
- **CHIP BY HIS WEIGHTING** — the Captain's stated split: 08-05 → 08-25 **100 %** chip, then
  **under 50 %**. Applied as 100 % and 50 %, so it is an **upper bound**.
- **WHOLE FLEET** — every personal-lane project. Employer-lane work is excluded throughout.

## The headline

| figure | chip by path (floor) | chip by his weighting (upper bound) | whole fleet |
|---|---|---|---|
| **model-hours** | **≈ 570–630** | ≈ 1,220–1,300 | **≈ 1,510–1,600** |
| **human hours** | not measurable this way (below) | **≈ 120–135** | **≈ 145–165** |
| **defects caught** | **≥ 15** distinct circuit defects (6 RTL, 9 core design/model) | — | not a like-for-like count (§3) |

**Suggested slide wording:** *≈ 600 model-hours in the chip's own repositories (≈ 1,550 across
the whole fleet) · ≈ 130 hours of human effort attributable to the chip (≈ 155 in all) ·
at least 15 circuit defects caught before tapeout.* Each is a measurement with the limits below; say "about".

## 1. Model-hours

**Definition.** Time an agent was working: in each session transcript (main sessions and
subagents separately), the gap from each record to the next is counted when the next record
is the agent's own output or a tool result, and **not** counted when the next record is a new
prompt (that gap is waiting). A single gap is capped at **10 minutes** — the longest a
foreground tool call can run — so a stalled dialog cannot count as work. Parallel agents add:
this is agent-time, the same kind of measure as the xv6 paper's "hours of Claude running
time", not wall-clock.

**Population.** Every surviving session transcript on the box, every config directory
including the default one (2,773 transcript files with records in the window, 517,721
records), plus the per-message census of **97 sessions whose transcripts were deleted on
2026-09-15**, preserved in the fleet's efficiency study. For those, only assistant timestamps
survive, so the assistant-only gap sum is divided by the ratio the two rules give on
comparable surviving sessions: **1.64–1.90** (seat sessions, measured); that ratio is the
whole of the ranges above.

| (hours, cap 10 min) | through 08-25 | after | total |
|---|---|---|---|
| chip by path | 463–520 | 104–108 | **567–628** |
| rest of the fleet | 458–484 | 486–489 | 945–973 |
| whole fleet | 921–1,004 | 590–597 | **1,511–1,601** |

Of the chip-by-path figure, **≈ 165 h is read directly** from surviving transcripts and the
rest comes through the calibration.

**Leaves out / limits.**
- The deleted sessions' subagent streams are merged per session, so parallel subagents inside
  them count once (an undercount; ≈ 15 h of the chip figure is in this class).
- Sensitivity to the cap is small where the full rule applies (surviving chip transcripts:
  86.6 h at 10 min vs 86.8 h at 30 min); it is not testable on the deleted sessions, whose
  calibration was taken at the 10-minute cap.
- A second measure, for scale: at least one personal-lane agent was working in **≈ 625 of the
  780** calendar hours (union of working intervals; an upper bound, because the deleted
  sessions' intervals use the assistant-only rule).
- The token meter of record (61,716,448 output tokens, 08-09 → 08-23, seven projects;
  `docs/midnight-to-silicon-story.md` 96) is a different unit and is **not** converted here.

## 2. Human hours

**Definition.** The Captain's typed turns — prompts with text in a main session, excluding
tool results, task notifications, slash commands, relight prompts, and prompts injected by the
fleet's own coordinator (recognised by their machine-written openings) — clustered across all
windows at once (he is one person, so two open windows do not double count): a gap of **20
minutes** or more starts a new sitting. A sitting's length is first turn to last turn
(**≈ 143 h**), or that plus 5 minutes per sitting for the reading before the first turn
(**≈ 164 h**). Councils were held in the coordinator's window, so their typed time is inside
this count already and is not added again.

**Population.** 2,369 typed turns in 253 sittings; 08-06 is the busiest day (195 turns).

| (hours, 20-min gap) | through 08-25 | after | total |
|---|---|---|---|
| whole fleet | 94–106 | 48–58 | **143–164** |
| chip by his weighting | 94–106 | ≤ 24–29 | **≤ 118–135** |

**Why not by path:** only ≈ 6 h of his typed time was in the chip's own windows; he worked the
chip from the coordinator's window. Path attribution would understate his chip time by an
order of magnitude, so this figure uses his weighting and says so.

**Leaves out / limits.** A **floor** for the time he spent: reading without typing, thinking,
the TT web flow, hardware and purchases are unseen. Turns typed directly into worker sessions
whose transcripts were deleted 09-15 are unseen (their prompt text did not survive).
Sensitivity to the sitting gap: 106 h (10 min) to 168 h (30 min), first-to-last.

## 3. Defects caught

**Definition.** A distinct defect in the chip's circuit — its RTL, or the core's design and the
Lean model it was verified against — found **before tapeout** by a test, a proof attempt, a
refuter pass or a peer, and fixed. Each defect is counted **once**, however many commits, CI
runs and bus posts it produced. Read commit by commit (all 279 chip-path commits whose
subject names a fix, defect or refutation, and the full bodies of the defect-bearing ones).

**At least 15**, chip by path:

- **6 in the chip's RTL** — they would have gone into the silicon or blocked the submission.
  Examples: the banyan switch silently dropped a packet when one port was idle (08-06,
  `db12648`); the shipping top served the *previous* instruction's memory transaction
  (08-18, `f18f7bd`); a declaration order that yosys accepted and the shuttle's simulator
  rejects (08-18, `424cb11`); a host resync pulse that re-issued a retired instruction — the
  fix went to fab (09-06, chip repo `f773278`).
- **9 in the core's design or its Lean model** — the circuit as planned or modelled did the
  wrong thing. Examples: nothing added the PC, so the core would set `pc := 4` every cycle
  (08-07, `feafce0`); a store write-enabled a register, kernel-proved (08-19, `eb13c88`);
  ADDI's immediate was wired to the branch displacement (08-19, `96442e6`). The 08-29 council
  ruling records that the 08-18/19 core defects were in the model, not the RTL.

| source | count in window | what it is |
|---|---|---|
| defect-bearing commits, read one by one | **15 distinct** | the headline; a floor |
| chip-path commits naming a fix/defect/refutation | 279 of 1,273 | an upper bound on *corrections* of every kind (proofs, tools, docs); one defect spans up to ~10 commits — **not a defect count** |
| red CI runs, this repo | 17 of 343 | all commit-hygiene; CI exists only from 08-23; Lean builds ran locally; **none is a circuit defect** |
| red CI runs, chip repo | 4 of 53 | all 08-10 setup; none a design defect |
| WHOLE FLEET: the Lean program's flags file | 59 entries, ≈ 10–12 refuted statements | number theory; none concerns the chip |

**Leaves out / limits.** A **floor**: a defect found and fixed inside a commit whose subject
does not name it is not counted, and neither are the many defects in specifications, proofs,
verification tools and documentation (the 279 bounds that wider class from above). It counts
what was **caught**; it is not a claim that nothing escaped to the die.

## Receipts

The scripts and their full outputs, and the per-record intermediate (517,721 rows, with its
SHA-256), are kept in the fleet's private record (seat-repo commit `1c4aa7cfe`); the public
figures above are reproduced from them exactly. The 09-15 deletion census is the efficiency
study's archived 09-14 cut.
