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
