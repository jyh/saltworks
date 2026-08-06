# ledger-tools — the campaign's measuring instruments

Owner: the **EVIDENCE seat**. Charter: `docs/measurement-preregistration.md`
(frozen 2026-08-06 at Council I) and its dated addenda. Amendments to the
measurement design go in that file, never here.

These four files produce every number the campaign publishes about **who was
present** and **what it cost**. They are committed, they run on any of our git
repos, and they emit markdown.

| File | What it is |
|---|---|
| `ledger_common.py` | the shared transcript + git parser. The single place that decides "a human typed this" vs "the harness injected this". |
| `silence_windows.py` | the silence-window ledger — what landed while no human was directing. |
| `token_meter.py` | tokens by day × project × model tier × wave, cache always its own column. |
| `selftest.py` | ~78 checks (72 fixed + one per discovered project, so the count is **machine-dependent**). ⚠️ It covers `ledger_common` and `silence_windows` **only** — `token_meter`, `human_time`, `fleet_hygiene` and `landed` have **no test coverage**. |
| `nightly.sh` | runs all of it, writes `docs/EVIDENCE-ledger-<date>.md`. |

## Run it

```sh
python3 docs/ledger-tools/selftest.py                      # always first

python3 docs/ledger-tools/silence_windows.py \
    --repo ~/projects/claude/salt \
    --since '2026-07-23 00:00' --until '2026-08-06 00:00' \
    --run-detail --out /tmp/salt-ledger.md

python3 docs/ledger-tools/token_meter.py \
    --since '2026-08-05 22:00' --repo ~/projects/claude/salt

sh docs/ledger-tools/nightly.sh                            # the whole thing
```

No dependencies beyond the Python **3.11+** standard library. (3.11 is a hard floor: `datetime.fromisoformat` cannot parse git's basic-format UTC offset `-0700` before it.) Runtime: about 13 s
over salt's 2 GB of transcripts, 2 s over saltworks.

## The one thing to understand before quoting a number

**A `"type": "user"` record in a Claude Code transcript is not necessarily a
human.** The harness injects agent-completion notices, `/loop` timer ticks,
cron pings, peer-seat messages and context-compaction summaries with
`role: "user"`. The leg-1 harvest measured the damage: counting them made it
look as though **98.5 % of commits landed within 30 minutes of a human
message**, and filtering moved the ≥1 h silence figure from **0.3 % to
21.5 %** (salt triple-campaign Amendment 2).

This code classifies by the record's own provenance fields — `origin.kind`,
`promptSource`, `isMeta` — and uses string patterns only for records written
by clients that predate those fields. Every rejection is counted and printed
in the output, so the filter can be audited from the published table without
re-reading the transcripts.

Two injection classes were found on 2026-08-06 that Amendment 2 did not name,
and they are the dangerous ones because they fire **precisely when the human
is away**:

* **`/loop` timer ticks** (`isMeta` + `promptSource: system`) — 94 in the salt
  record;
* **cron pings** — 30 more, and these carry *the human's own instruction text
  verbatim*, so no string filter can catch them.

Two classes are counted **as** human that the leg-1 harvest dropped:
**slash commands** (typing `/model` at 03:00 proves a hand on the keyboard)
and **`[Request interrupted by user]`** (an ESC press). Both can only shorten a
silence window, which is the honest direction.

## Design decisions worth knowing

**Presence is fleet-wide by default.** A commit in `saltworks` is not
unattended if JYH was typing into `salt` at that moment. The default measure
is the union of human touches across every personal-lane seat; the
single-seat measure (the leg-1 unit) is printed beside it for comparison.
Seat names other than the repo's own are withheld unless `--name-seats` is
passed, because some personal-lane repos are private.

**Outside-lane transcripts are never read.** `loca` and `holl` are blocked in
code (`ledger_common.EMPLOYER_LANE`), not behind a flag. The consequence is
stated in every report: silence means *no human direction reached the
personal-lane fleet*, never *the human was asleep*.

**Unobserved ≠ silent.** A commit that predates the earliest readable
transcript is excluded from every share rather than counted as silent. An
open-ended window is reported as a lower bound and marked.

**And a hole in the MIDDLE of the record is caught too, as of 2026-08-06** —
§0 of every silence report. The laptop→Mac-Mini migration re-synced the repos
and the kit before cutover but not `~/.claude/`, so the transcript record
stopped at 14:07:56 while git carried work to 14:30:08, and the ledger read
the difference as the campaign's longest silence window. **The rule that
separates the two needs no new data: a commit is made *by* a session, and a
session writes records, so a commit landing where no personal-lane session
wrote anything is proof of a hole rather than evidence of absence.** The
5-minute tolerance is not a guess — the median commit sits **0.4 s** from the
nearest record and the worst normal one ever measured is **3.08 min**, against
**22.19 min** for the hole; every run recomputes that separation and says so.

⭐ **The detector is non-vacuous, and the same run proves it:** it flags 1
commit in saltworks *and clears all 715 in the leg-1 harvest window*. A
coverage check that never fires certifies nothing — this one fires and clears
in one pass, so the 20.9 h exhibit is now certified **measured**, not merely
unrecorded.

**Queued messages are dated by when they were typed.** A message typed while
the model is working is written to the transcript at dequeue time; the
`queue-operation: enqueue` record carries the real moment and is preferred.
Measured effect: median 0 s, maximum **464 s** (was 318 s when written; the tool prints the current figure on every run) — it moves nothing at hour scale,
and is applied anyway.

**One API response = several records.** Claude Code writes one assistant
record per content block, each repeating the whole `usage` block. Token
events are deduplicated by `requestId` (usage verified byte-identical within
a group). Summing records would inflate every token figure by **~2.3×** (measured; earlier text said ~3×).

**Subagents are where the REQUESTS are** — in salt, 71,115 subagent requests
against 11,350 in the session files. ⚠️ **For OUTPUT TOKENS this reverses**,
and the earlier wording overstated it: measured on day 1, subagents made 81%
of requests and 24% of output tokens. A meter that reads only the session file
is wrong by an order of magnitude.

**Per-account attribution is not derivable.** The transcripts carry no
account, organisation or subscription identifier — checked field by field
across every record type. The campaign runs five accounts and these files
cannot say which one paid. Reported as a gap, never estimated.

**Git windows always carry an explicit time.** `--since='2026-07-23'` without
one is parsed as UTC and silently drops commits (654 vs 712 over the same
nominal window, measured in the leg-1 harvest). Every call uses
`TZ=America/Los_Angeles` with `--date=format-local`, and merges are excluded.

## Validation against the leg-1 harvest

`silence_windows.py --repo salt --since '2026-07-23 00:00' --until
'2026-08-06 00:00' --seat-only` reproduces the independently-computed leg-1
figures:

| Figure | leg-1 harvest (8/5 21:30) | this tool (8/6) |
|---|---|---|
| best silence window | 20.9 h, 26 commits, 12,310 ln | **20.9 h, 26 commits, 12,310 ln** |
| longest unbroken run | 34 commits, 3 h 20 m | **34 commits, 3 h 19 m** |
| ≥1 h silence | 334 commits (46.9 %) | 344 commits (48.1 %) |
| ≥12 h silence | 48 commits, 22,610 ln | **48 commits, 22,610 ln** |
| commits in window | 712 | 715 |

The differences are explained, not waved away: the harvest ran at 21:30 on
8/5 and three more commits landed that evening; and this filter rejects the
loop ticks and cron pings the harvest counted while accepting the slash
commands it dropped, which lengthens some windows and shortens others. The
two figures that depend on neither — the 20.9 h exhibit and the 34-commit run
— agree exactly.
