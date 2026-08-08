# MEASUREMENT PRE-REGISTRATION — frozen 2026-08-06, Council I
# (before the data accumulates; amendments only by dated addendum)

## 1. Token accounting
Source: ~/.claude/projects/<project>/*.jsonl session + subagent
transcripts (usage blocks: input/output/cache_creation/cache_read +
model id). Tables: per-day × per-project × per-model-tier ×
per-wave (task attribution by timestamp-join against git commits).
Cache ALWAYS a separate column, never in a headline. Unit: TOKENS
(subscriptions make dollars a flat envelope — report both framings,
never blend). Per-ACCOUNT attribution: report only what the records
carry; if weak, say so in the table header.

## 2. Human-time accounting (four categories, counterfactual test)
- DIRECTING: rulings, councils, requirement-setting.
- REVIEWING: reading that GATES an artifact (freeze ratification,
  paper review).
- UNBLOCKING: logins, purchases, physical acts.
- WATCHING: curiosity — reading along, questions redirecting nothing.
THE CLAIM = DIRECTING + REVIEWING + UNBLOCKING only ("would the
artifact exist without this touch?"). WATCHING is reported as its
own proud line. Mechanism: session transcripts (every typed word
timestamped) + this rubric published beside every number + the
maestro tags at councils + JYH spot-audits tags. NO manual
time-tracking. Note the task-notification filtering methodology
(salt triple-campaign Amendment 2) applies to all silence-window
computations.

## ADDENDUM 1 — 2026-08-06, EVIDENCE seat (implementation + two
## corrections). The design above is unchanged; this records what
## implementing it exactly required, and two places where the frozen
## text was silent and a choice had to be made and declared.

Tools: `docs/ledger-tools/{ledger_common,silence_windows,token_meter,
human_time,selftest}.py`, `nightly.sh`. 67 self-test checks; the
silence figures reproduce the leg-1 harvest's independently-computed
20.9 h exhibit and 34-commit run exactly.

**A. Two injection classes Amendment 2 did not name.** Beyond
`task-notification`, the harness injects with `role: "user"`:
(1) **`/loop` timer ticks** (94 in the salt record) and (2) **cron
pings** (30). Both fire PRECISELY WHEN THE HUMAN IS AWAY, and the
cron pings carry JYH's own instruction text verbatim, so no string
filter can catch them. Classification is therefore by the record's
own provenance fields — `origin.kind`, `promptSource`, `isMeta` —
with string patterns only as a legacy fallback. Also rejected:
peer/coordinator seat messages, context-compaction summaries,
tool results, sidechain (subagent) prompts.

**B. Two classes counted AS human that leg 1 dropped.** Slash
commands (typing `/model` at 03:00 proves a hand on the keyboard;
leg 1 rejected 214) and `[Request interrupted by user]`. Both can
only SHORTEN a silence window — the honest direction.

**C. Presence is FLEET-WIDE by default (a genuine addition).** A
saltworks commit is not unattended if JYH was typing into salt. The
default measure unions human touches across all personal-lane seats;
the leg-1 single-seat measure prints beside it. Measured for
2026-07-23→08-05: 716 of 716 in-window touches were salt's, so the
two coincide and leg 1's "he may have been in another seat" caveat
is discharged for that window, within the personal lane.

**D. Three implementation facts §1 could not know.** (1) One API
response is written as SEVERAL assistant records, each repeating the
whole usage block — events are deduped by `requestId`; summing
records inflates every token figure ~3×. (2) Most tokens live in
SUBAGENT transcripts (salt: 71,115 subagent requests vs 11,350
top-level). (3) **Per-account attribution is UNAVAILABLE** — the
records carry no account, org or subscription identifier at all,
checked field by field. Reported as a gap, never estimated.

**E. Unobserved ≠ silent.** A commit predating the earliest readable
transcript is excluded from every share, not counted as silent. Open
windows are reported as lower bounds and marked.

**F. The firewall in code.** Outside-lane projects are never read
(`ledger_common.EMPLOYER_LANE`), not behind a flag. Consequence,
printed in every report: silence means "no human direction reached
the personal-lane fleet", never "the human was asleep".

**G. Human-time blocks are a FLOOR.** A block is a run of touches
with no >20 min gap; duration is last−first (60 s floor). Reading
before the first message leaves no trace, so the figure under-counts
and is published as a floor, never adjusted upward by estimate.
Untagged blocks are reported as UNTAGGED and folded into nothing.

## ADDENDUM 2 — 2026-08-06 evening, EVIDENCE seat. Two places the frozen
## design and ADDENDUM 1 were both silent, found by moving the fleet from
## the laptop to the Mac Mini. The design above is unchanged; these record
## what the move exposed and what was built in response.

**H. A HOLE IN THE MIDDLE OF THE RECORD.** §E ("unobserved ≠ silent")
models one direction only — a commit PREDATING the earliest readable
transcript is excluded from every share. The migration produced the other
direction. The runbook re-synced the repos and the seat kit before
cutover but **not `~/.claude/`**, so the transcript record stops at
**14:07:56** while git carries fleet work to **14:30:08**. Read naively,
that becomes the campaign's longest silence window (0.9856 h, 5 commits),
**82% of which is missing record rather than measured absence.**

The separating rule needs no new data: **a commit is made BY a session,
and a session writes records**, so a commit landing where no personal-lane
session wrote anything is proof of a hole. Implemented as §0 of every
silence report (`ledger_common.activity_trace` / `record_distances` /
`unrecorded_commits`). **Calibrated before it was shipped**, over 862
commits spanning the leg-1 harvest and the campaign: median **0.4 s** from
a commit to the nearest record, p99 **5.1 s**, largest normal **3.08 min**,
the hole **22.19 min** — so the 5-minute tolerance sits in a measured void,
and every run recomputes that separation rather than quoting this one.
It flags 1 commit while clearing all 715 leg-1 commits **in the same
pass**, which is what makes it non-vacuous.

Reported, per the house rule, with the narrower question it answers:
**it detects holes that SWALLOWED WORK, not holes as such.** A hole in a
stretch where nothing was committed is invisible to it. That is tolerable
only because the measure carrying the claim counts commits.

**I. UNBLOCKING IS THE CATEGORY THE INSTRUMENT IS BLINDEST TO, AND §2
NAMED IT WITHOUT NOTICING.** THE CLAIM = DIRECTING + REVIEWING +
UNBLOCKING, where UNBLOCKING is *"logins, purchases, physical acts."*
**A physical act leaves no transcript trace by definition.** The migration
is the clean instance: from **14:07:56 to 15:25:53** the human was moving
a five-seat fleet between machines — running rsyncs, enabling Remote
Login, completing five separate account logins — and the record shows
**one 0.9856 h silence window and one 29.4-minute gap, with no human time
at all.** The engaged-time figure is a floor (§G) for the reason §G
gives; **this is a second and larger reason, and it bites hardest on
exactly the category that most obviously would not have happened without
the human.**

No estimate is applied — the floor stays a floor. What changes is the
disclosure: **a silence window that coincides with an UNBLOCKING act is
evidence of the human WORKING, not of the human being away**, and the
report must not be quoted as though the two were the same. The
counterfactual test in §2 is unaffected and, if anything, sharper: nothing
in that hour would have happened without the human.

## ADDENDUM 3 — 2026-08-06 19:3x, EVIDENCE seat. A NEW INJECTION CLASS that
## no provenance field can catch, and a UNIT defect in §2's own instrument.
## Both found by adversarially attacking this seat's own tag proposals.

**J. `tmux send-keys` IS A HUMAN KEYSTROKE AS FAR AS THE RECORD IS
CONCERNED — AND ADDENDUM 1 §A's METHOD CANNOT SEE IT.** §A established
that injections are classified *by the record's own provenance fields* —
`origin.kind`, `promptSource`, `isMeta` — with string patterns only as a
legacy fallback. **That method fails outright on a class created at 17:07
on 2026-08-06**, when the maestro adopted pane-level nudging: composing a
message and injecting it into another seat's input box with
`tmux send-keys`.

Checked field by field on this seat's own transcript, the two nudges it
received carry:

    promptSource: "typed"   userType: "external"   origin.kind: "human"

**Identical to a human typing, because at the terminal layer it IS a
keystroke.** The harness has no way to know a machine produced it. No
provenance field distinguishes them and none ever will.

**MEASURED, 2026-08-06:** of **128** records classified human across the
personal lane that day, **4 are machine-authored** (12:59:54, 17:07:27,
17:07:45, 18:43:04) — **3.1%**. Three are pure `send-keys` with no hand on
any keyboard; the fourth is machine-authored text that JYH *pasted*, which
is a hand but not a decision.

**THE TWO BIASES RUN IN OPPOSITE DIRECTIONS AND BOTH MUST BE STATED.**
Counting a machine nudge as human **inflates human-time** (the dishonest
direction, since it pads THE CLAIM) and **shortens silence windows** (the
self-deprecating direction, since it makes the fleet look more attended
than it was).

**The only honest detector is cross-seat, not per-record:** a nudge exists
in the *sending* seat's transcript as a `tmux send-keys` tool call at the
same instant it appears as a "human" message in the *receiving* seat's.
**Provenance cannot see it; correlation can.** Not implemented; specified
here so the gap is on the record rather than in the numbers.

**K. THE BLOCK IS THE WRONG UNIT FOR §2's COUNTERFACTUAL TEST, AND IT
INFLATES THE CLAIM.** §2 tests each **touch** — *"would the artifact exist
without this touch?"* — but `human_time.py` assigns one category per
**block**, where a block is any run of touches with no >20 min gap. On
2026-08-06 that put THE CLAIM at **11h 13m of 11h 16m — 99.6%**.

**That number must not be published as "99.6% of the human time was
load-bearing."** No tag is wrong; the unit is. The adversarial pass showed
block `20260806T1243` is *mostly* watching-shaped — 11 of its 20 typed
messages redirect nothing, and its longest contiguous stretch, 10 of 60
typed minutes, is iTerm2 window-management — while **one irreducible order
inside it (create the private repo) drags the whole 1h 13m into THE
CLAIM.** The 3h 55m evening block has the same shape.

⇒ **Until tagging is per-touch or blocks are split at category changes,
THE CLAIM is a COARSE UPPER BOUND and must be quoted as one.** The floor —
WATCHING at 0h 02m — is equally obviously not the truth. *A measure whose
unit is coarser than its own decision rule reports the decision rule's
answer for the whole unit.*

**L. AND THE SEAT LABEL ON A BLOCK CAN BE SIMPLY WRONG.** Block
`20260806T1243` is labelled **saltworks**; **19 of its 20 typed messages
are in the salt seat.** The label comes from the block's first touch, not
from where its mass sits. Cosmetic for the totals, misleading in the
worksheet a human tags from — and it is the third instance today of an
instrument naming an adjacent object correctly and the intended one not at
all.

## ADDENDUM 4 — 2026-08-08 morning, EVIDENCE seat. THE OVERNIGHT OUTAGE.
## The design above is unchanged. This records a THIRD thing that a silence
## window can be, and a place where the bus is not the clock. Both were found
## by measuring a machine hang instead of narrating it.

**M. AN OUTAGE IS A THIRD THING, AND §0's DETECTOR IS BLIND TO IT BY
CONSTRUCTION — WHICH ADDENDUM 2 SAID IN ADVANCE.** §H shipped with its own
limit printed: *it detects holes that SWALLOWED WORK, not holes as such. A
hole in a stretch where nothing was committed is invisible to it.* The
2026-08-08 hang is that sentence's first instance at scale, and a clean one.

The sequence, every reading taken from the machine or the filesystem rather
than from any account of the night:

| Reading | Value | Instrument |
|---|---|---|
| Last commit | 2026-08-08 00:57 `f4825d7` | `git log` |
| Last bus post | 02:31 | `FLEET.md` |
| **Last file written** | **02:42:16** | `find -newermt` / `stat` |
| WindowServer error storm opens | 02:49 | maestro, 09:33 (see below) |
| Diagnostic cascade opens | 02:50 | `/Library/Logs/DiagnosticReports` |
| apfsd CPU resource event | 03:08–03:10 | same |
| Shutdown stalls | 07:44:29, 07:47:50 | same |
| Boot | **07:48:22** | `sysctl kern.boottime` |

**ADDED 09:3x — THE STORM HAS AN AUTHOR, AND THE ORDERING IS A CONSTRAINT ON
WHAT IT CAN BE.** *The maestro identified iStat Menus (bjango launch agents):
booting out both agents dropped the WindowServer invalid-window rate **4.8/s →
0.7/s**, held through a verified-dead window, and it had been running under both
users all night. **The maestro states cause-vs-symptom of the wedge itself stays
open, and this row does not close it** — it records one ordering:*

```
02:42:16   last observable work        ← the machine stops writing
02:49      error storm becomes visible ← ~7 minutes LATER
02:50      diagnostic cascade opens
```

⚠️ **THE CONSTRAINT IS WEAKER THAN IT LOOKS AND MUST NOT BE OVERSOLD.** *A
simple "the storm wedged the machine" story predicts the storm FIRST; observed,
work stops first. **But both terms are soft:** absence of file writes is not
absence of work (an executor can compute for minutes without writing), and
`02:49` is when a RATE crossed visibility, not when the condition began.* ⇒
***The ordering is consistent with symptom and does not exclude cause. It is a
constraint, not a verdict, and it is recorded as one.***

✅ **THE MEASUREMENT THAT WOULD ACTUALLY DISCRIMINATE, since the instrument
already exists:** *iStat ran all night, so `02:49` is a CHANGE in rate rather
than an onset of presence.* **Recover the invalid-window rate series for the
hours BEFORE 02:42:16.** *Elevated beforehand ⇒ the storm predates the stall and
cause stays live; flat until 02:49 ⇒ something else moved first and the storm
joins the symptom column.* **Neither this seat nor the record should pick between
them until that series is read.**

📌 **AND ONE INSTRUMENT NOTE FROM THE HUNT ITSELF, because it is this day's
recurring class:** *the maestro's FIRST kill ladder had a **launchd-respawn
hole** — it measured a process being ABSENT, not a process being DEAD, and
launchd put it back. The rerun added hold-dead verification and only then was
the 4.8 → 0.7 drop meaningful.* ⇒ ***A kill you did not verify held is an
absence, not an experiment.***

**The outage is 02:42:16 → 07:48:22 = 5 h 06 m, and ZERO commits landed
inside it.** Therefore §0 flags nothing (no commit, so no hole to detect) and
§2 — THE MEASURE THAT CARRIES THE CLAIM — is untouched in both numerator and
denominator. Confirmed in the 08-08 run: the `≥ 4 h` row reads 0 commits,
0.0%. **The outage is invisible to the claim, and that is correct.**

It must still be written down, because the failure mode runs the other way.
A reader who computes "hours the fleet ran unattended" from the SPAN of a
silence window would score 5 h 06 m of a dead machine as autonomous running.

⇒ **THREE DISTINCT THINGS NOW SHARE ONE MEASUREMENT, and only the first is
autonomy:**

1. silence with fleet work in it — **the claim**;
2. silence coinciding with a human physical act — **the human working**,
   unrecorded by construction (§I);
3. silence with neither — **the machine down**.

**A span is not autonomy unless something ran inside it.** §I taught that a
silence window is not evidence the human was away; M adds that it is not
evidence the FLEET was there.

**N. THE BUS IS NOT THE CLOCK, AND IT UNDER-REPORTS THE TAIL OF ANY
INTERRUPTED STRETCH.** The night's last bus post is 02:31, and that is the
timestamp an account of the crash naturally reaches for. The filesystem
disagrees: **five `Scratch*.lean` files, 111 KB, written 02:30:46 → 02:42:16**
— eleven minutes of real executor work after the last thing the bus knows,
and 1 h 45 m after the last commit. The hang onset therefore sits between
**02:42 and 02:50**, not "after 02:31."

A record whose granularity is *what got posted* cannot see work that was
still being written when the recorder stopped. The instrument that saw it was
`find -newermt` against the crash window — not the ledger, and not the bus.

**AND THOSE FILES ARE INVISIBLE TO `git status`** (`Scratch*.lean` is
gitignored, which is where executor proofs live). So **"nothing committed was
lost" is true, and it is not the same claim as "nothing was lost."** The
survey that separates them is mtime, and it must be run BEFORE any seat
re-dispatches an executor for work that is already sitting on disk.
