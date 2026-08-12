# ledger-tools — the campaign's measuring instruments

Owner: the **EVIDENCE seat**. Charter: `docs/measurement-preregistration.md`
(frozen 2026-08-06 at Council I) and its dated addenda. Amendments to the
measurement design go in that file, never here.

These files produce every number the campaign publishes about **who was
present** and **what it cost**. They are committed, they run on any of our git
repos, and they emit markdown.

> 📌 *"These **four** files" stood here until 8/7, when `ls docs/ledger-tools/*.py
> *.sh` returned **15**. A count written in prose is a count that stopped being
> regenerated — this directory's entire thesis, failing on its own front door.
> **And the seat that caught it typed "eleven" into the correction before
> counting, one line and thirty seconds later.** The reflex is not weaker in the
> person who just named it; only the `ls` is.*

## ⛔⛔ THE TABLE BELOW IS **PARTIAL** — measured 2026-08-11 20:2x: **it has rows for 13 of 34 tools**

**Regenerate this, never trust the sentence above it:**
```sh
cd docs/ledger-tools && for f in *.py *.sh *.awk; do
  grep -q "^| \`$f\`" README.md || echo "UNLISTED: $f"; done
```
⚠️ ***THE ANCHOR `^| \`` IS THE WHOLE CHECK, AND I SHIPPED IT WRONG FIRST.*** *My
first version of this loop grepped the filename ANYWHERE in the file, so a tool
merely CITED inside another tool's paragraph counted as inventoried — the row I
added minutes earlier mentions `pin_check.py`, and the loop promptly reported it
listed. **It measured MENTIONED, not INVENTORIED, and it over-reported in the
reassuring direction.*** *One tool at this size; on a page that cross-references
freely it would climb. **A completeness checker that counts prose mentions is
this directory's thesis failing on its own front door for the third time.***
⛔ ***AND THE PART THAT MATTERS MORE THAN THE NUMBER: the note directly above
this one has recorded this exact defect since 8/7, when the gap was 4-of-15. It
is now 9-of-34. **The confession stayed accurate and the table did not, and the
gap roughly doubled while its own description sat above it.***

🔑 ***A DOCUMENTED DEFECT IS NOT A FIXED DEFECT, AND THE DOCUMENTATION IS WHAT
MAKES IT INVISIBLE.*** *A reader meeting a candid self-correction about
miscounting concludes this page is careful about counting — so the confession
suppresses the very check it describes.* **It is [[a-repair-invites-gratitude]]
one step further along: a claim invites a check, a repair invites gratitude, and
a CONFESSION invites trust.** *The 8/7 note did not fail; it was never wired to
anything, so it aged into a decoration on an inventory that kept drifting.*

⚠️ **So: this table is a set of ANNOTATIONS on tools that earned a paragraph, not
an inventory. For the inventory, run the loop.** *The **21 rows owed as of
2026-08-11 20:2x** are absent, not deliberately excluded — no reading of this
file should treat an unlisted tool as unowned or disposable. **Re-run the loop
before quoting that 24; it is a reading, not a property.***

> 🔬 ***AND `prose_rot.py` — THIS SEAT'S OWN STALENESS SWEEP — WAS RUN AGAINST
> THIS FILE AT 20:1x AND DID NOT FIND THE DEFECT ABOVE.*** *It returned three (A)
> findings, all three pointing at sentences written twenty minutes earlier in
> this very banner, plus a 38-row (B) list whose entries include `2026`, `08` and
> `07` tokenized out of one date. **The stale thing was two days old and invisible;
> the fresh thing was flagged three times.***
> 🔑 ***THE REASON IS STRUCTURAL AND WORTH MORE THAN THE MISS: THIS DEFECT
> CONTAINS NO FALSE SENTENCE.*** *The 8/7 note is accurate history. Every table row
> is accurate. What was false is the COMPOSITION — an accurate confession above an
> accurate partial table implies a completeness that nothing states.* **A sweep
> that hunts false sentences cannot see a defect made of true ones, and no regex
> fixes that. Only REGENERATION does — which is why the loop is in the file and
> the count is dated.**

| File | What it is |
|---|---|
| `ledger_common.py` | the shared transcript + git parser. The single place that decides "a human typed this" vs "the harness injected this". |
| `silence_windows.py` | the silence-window ledger — what landed while no human was directing. |
| `token_meter.py` | tokens by day × project × model tier × wave, cache always its own column. |
| `import-closure.py` | which git-tracked modules sit **outside** the hub's transitive import closure, and how many `#audit_axioms` sites therefore **never fire in the default build**. Compiler seat's tool, this seat's directory. **Three-way exit: 0 covered · 1 something outside (the gate) · 2 could not read.** Exit 2 exists because the first version returned **exit 0 with `OUTSIDE: 0` when `git ls-files` failed** — a clean green from a tool that had read nothing, in a tool whose job is gating a commit. ✅ **Covered by `selftest.py`** (guards + a fixture with a known answer), and the checks are **mutation-verified**: disable all three guards and exactly two of them fail. |
| `selftest.py` | checks are **machine-dependent** (one per discovered project on top of the fixed set); **130 on this machine, 8/7 — and that number came from running it, which is the only way this file is allowed to quote one**. ⚠️ It covers `ledger_common`, `silence_windows` and **`fleet_hygiene`'s bus parser + threshold calibration** — `token_meter`, `human_time` and `landed` gained coverage on 2026-08-07 for the properties their own docstrings depend on — **requestId dedup** (the ~2.3x inflation), **the unknown-category abort**, **orphaned-tag loading**, and **lane totality** — all four **mutation-verified**: break them and exactly 6 checks fail. ⚠️ Still uncovered: the rest of `fleet_hygiene` (process detection, lock state, memory readout) and `nudge_detect`'s correlation window. **Both defects found on 2026-08-06 were in the uncovered region**, which is why the region is named rather than left implicit. ➕ **8/7: `provenance_replay` covered** — 12 checks, every one written as the red it prevents, plus a live `REPLAY-MANIFEST.tsv` integration row whose failure is a FINDING (the birth record no longer reproduces the artifact) rather than a broken test. |
| `provenance_replay.py` | **does a provenance bundle actually BIND the artifact it ships with?** Replays the executor transcript's `Write`/`Edit` calls and hashes the result against the committed blob. Driven by `docs/provenance/REPLAY-MANIFEST.tsv`, pinned to the artifact's **birth commit**. ⚠️ It was first anchored at `HEAD:…` on the reasoning that *"a pinned rev passes forever while the artifact drifts"* — **right for a frozen artifact, wrong for a live module.** Ninety minutes later math added 841 lines of S3(b) to `Program.lean` and the gate went permanently red on legitimate development. A birth record binds a BIRTH; whether HEAD has moved on is `docs/provenance/verify.sh`'s question, and it pins the current blob. **Three-way exit: 0 bound · 1 MISMATCH · 2 could not check** — the same lesson as `import-closure.py`. ✅ **Covered by `selftest.py`, mutation-verified** (each of three guards, disabled, fails exactly one check). ⚠️ It answers content-**BOUND**, never content-**VETTED**. |
| `model_integrity.py` | **which MODEL actually served each message** — read out of the transcript's per-message `message.model` field, because **no session can detect this about itself**. Built 8/7 after the maestro session ran ~90 min on `claude-opus-4-8` undisclosed; this seat's independent run measured the window at **13:31 → 15:03**. Filters on the MESSAGE's date, never the file's mtime (a session file spans days). ⛔ Employer lane refused **in code, by raising** — a silent skip is how a firewall stops being one. **Three-way exit: 0 stable · 1 CHANGED · 2 could not check.** ✅ Covered by `selftest.py`, mutation-verified. ⚠️ A change is not a fault; an **undisclosed** change is. |
| `f5_port_test.py` | **the F5 UNREACHABLE-HYPOTHESIS port test, mechanised** — does the EMITTED netlist have an XOR bank (criterion a), and is its sign net the carry-in port (criterion b)? Structural parse of emitS output; no Lean, no fleet lock. ⛔ It **refuses (c)** in its own output — hypotheses-to-ports needs the statement beside the netlist, so a green (a)+(b) does NOT clear F5. **Three-way exit: 0 met · 1 not met · 2 could not read**, and **exit 1 is the CORRECT answer before the complement path lands** — that is its negative control. ✅ Covered by `selftest.py`, **mutation-verified** (two mutants, each killing a different pair of rows). Expected post-landing reading pre-registered in the file: 225 cells, 96 xor2, bank net feeding **33** — not 32, because the carry-in already feeds one XOR. |
| `claim_fence.py` | **the claim fence F1–F7, made RUNNABLE against any text** — `claim_fence.py <file>…`, `--list`, `--selftest`. ⛔ **Built because this seat published "NINE PHRASES, ZERO HITS" four times on 8/10 — including in its most load-bearing post of the day, the submission clearance — while executing SEVEN.** The measurement was sound and the clearance stands; the COUNT was wrong because the canon lived in a seat's memory instead of an artifact. **The canon is now in-file and the count is `len(BANNED)`, so no hand types it again.** Patterns are **word-bounded**, and the fixture says why: the first version matched substrings, so `un|verified silicon` — *the exact qualified form this fence recommends* — tripped its own ban. A fence that rejects the language it prescribes trains people to ignore it. YAML comments are stripped **with the dropped-line count printed**, because a config's claim is its fields while its comments quote this fence's own wording. ⚠️ **It reads TEXT. A talk, a meeting and a sentence at dinner are unreachable, and they are where the banned phrases are actually born.** **Three-way exit: 0 clean · 1 findings · 2 could not run.** |
| `pin_check.py` | **drifted citations — does every `file:line` pin in a doc still name what it claims?** `pin_check.py <doc.md>… [--ref HEAD]`. Resolves the repo root via `git rev-parse --show-toplevel` and **REFUSES (exit 2) on a zero-file index**. ⛔ **Both guards are scar tissue: wired into `nightly.sh`, its `cd $HERE` made `git ls-tree -r HEAD` list one subdirectory — zero `.lean` files, every pin "EXTERNAL", and a cheerful `TOTALS 4/4 resolve` published in a ledger.** ⛔ **And it carries TWO matchers because the first lied about the corpus:** the strict form required the name immediately before the path, matched 55 of 205 citations, and this seat published **"coverage 26.8%"** — an indictment of everyone's citation discipline. **Measured: 109 of the 150 "bare" pins carried a name within 120 characters. The real figure was 80%**, and the math seat nearly published the same criterion against a flagship paper sitting at 98%. External-dependency pins are **classified, not failed**. **Three-way exit: 0 all resolve · 1 drift or absence · 2 could not run.** |
| `prose_rot.py` | **staleness, in the two directions it actually has** — `prose_rot.py <file\|dir>…`. **(A)** absence claims that ANNOUNCE THEIR TENSE (17 patterns, case-insensitive by construction, because four of this seat's errors were a case-sensitive grep returning a confident zero over a populated object) — ranked by **DATEDNESS**, since a dated line is narrative while an undated normative one gets OBEYED. **(B)** asserted numbers, emitted as a **WORK LIST explicitly NOT CHECKED and never summed with (A)** — this tool has no corpus and can verify none of them. Author-declared carrier regions (`prose_rot: ignore-start/end`) are honoured **with the excluded count printed**, because a miss prints itself and an exclusion does not. ⛔ **It once poisoned its own input: it emitted its own control marker, `nightly.sh` wrote the report into `docs/`, and the next run read its own output as an unterminated region — returning EXIT=2, which `\|\| true` swallowed.** The marker is no longer emitted and one bad file now skips rather than aborting the sweep. ⚠️ **Measured limit, 8/11: run against a file whose inventory had been stale for two days, it returned three findings — all three in sentences written twenty minutes earlier — and missed the real defect, correctly, by its own dated-narrative rule. It hunts FALSE SENTENCES; see the banner above on defects made of true ones.** **Three-way exit: 0 clean · 1 findings · 2 could not run.** |
| `pool_drift.sh` | **does the Lean pool constant still match the RTL it MIRRORS?** — `TinyRustN0.slicea16bmaPool` against `rf [1:N]` in `slicea16bma.v`. **Compiler seat's tool, this seat's directory** (added `37e7697` 08/09, edited `97e041f` 08/10) — the same cross-seat arrangement as `import-closure.py`, and the file names its own author and origin at line 4, which is the disclosure that matters. ⛔ **Its PATH is load-bearing: `SaltWorks/HDL/TinyRustN0.lean:443` and `CompileS.lean:230` both cite it by path in prose**, so a rename for tidiness would manufacture exactly the drifted-citation class `pin_check.py` exists to catch. ⚠️ **Measured 2026-08-11 20:0x: nothing INVOKES it** — absent from `nightly.sh`, no caller anywhere in the repo. *(Written first as `08-11` and flagged UNDATED by `prose_rot.py` — a year-less stamp does not register as a date, the same underspecified-timestamp family as a time-only `--date=format` merging two nights into one list.)* It is hand-run only, which makes it a guard whose firing depends on someone remembering it. *Compiler's call whether to wire it; recorded here so the next reader does not mistake "committed" for "running".* |
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
