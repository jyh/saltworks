# CAMPAIGN LEDGER — 2026-08-08

Nightly, from `docs/ledger-tools/nightly.sh`. Every table below is
regenerated from the git history and the session transcripts; nothing
here is typed by hand. The filter that decides what counts as a human
touch is disclosed inside each section, per
`docs/measurement-preregistration.md` and its ADDENDUM 1.

---

# SILENCE-WINDOW LEDGER — `saltworks`

Generated 2026-08-08 08:05 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/saltworks` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 390,012 liveness records at a **5-minute** tolerance.

**The tolerance, calibrated by this run rather than quoted from an earlier one** — a threshold is only honest while the data it separates stays separated:

| Calibration | Value |
|---|---:|
| Median commit → nearest record | **0.3 s** |
| p99 | 2.9 s |
| Worst commit still INSIDE the tolerance | **0.06 min** |
| Best commit OUTSIDE it (the nearest hole) | **22.19 min** |
| Separation | **378.8×** — **the threshold sits in an empty region** |

⛔ **1 of 526 commits landed in a stretch with NO transcript record.** Every silence figure below that contains one of these is a **lower bound on presence**: the human may have been directing and the evidence is missing, not absent. Do not publish a window containing these commits as unattended.

| Commit | Landed | Nearest transcript record | Subject |
|---|---|---:|---|
| `e3ea8f1` | 2026-08-06 14:30 | 22.2 min away | saltworks: third copy of the free-vs-available defect, a |

⚠️ **The narrower question this check actually answers:** *did work land inside a hole?* — not *is the record whole?* A hole in a stretch where nothing was committed leaves no trace here and is invisible to it. That is tolerable only because no published figure depends on such a stretch: the measure that carries the claim (§2) counts commits. It is stated rather than left to be discovered. **Known false-positive mode:** a commit made by hand from a terminal rather than by a seat would flag identically — measured at **0 occurrences in 862 commits on 2026-08-06** (a frozen figure, unlike the calibration table above, which this run computes), but the record cannot rule it out for a commit it has never seen.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **526** |
| `.lean` lines inserted | **30,347** |
| All lines inserted | 245,004 |
| First commit | 2026-08-05 22:05 `4fa92be` |
| Last commit | 2026-08-08 08:03 `c4c7507` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,460** |
| — of which into this seat (`-Users-jyh-projects-claude-saltworks`) | 235 |
| Seats read for presence | 5 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-saltworks`) and 4 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **574** human touches: **235** into this seat and **339** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 22 | 4.2% | 1,114 | 1,743 |
| ≥ 2 h | 22 | 4.2% | 1,114 | 1,743 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 526 | 100% | 30,347 | 245,004 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 84 | 16.1% | 4,978 |
| ≥ 2 h | 47 | 9.0% | 3,341 |
| ≥ 4 h | 47 | 9.0% | 3,341 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 521 | 100% | 30,084 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 505 | 96.0% |
| 30–60 min | 11 | 2.1% |
| 1–2 h | 9 | 1.7% |
| 2–4 h | 1 | 0.2% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **3h 02m** | 2026-08-07 22:46 | 2026-08-08 01:49 | 22 | 1,114 |
| **59 min** | 2026-08-06 13:57 | 2026-08-06 14:56 | 5 | 192 |
| **42 min** | 2026-08-07 20:52 | 2026-08-07 21:34 | 16 | 679 |
| **37 min** | 2026-08-07 21:34 | 2026-08-07 22:12 | 12 | 880 |
| **33 min** | 2026-08-07 22:12 | 2026-08-07 22:46 | 13 | 1,347 |
| **30 min** | 2026-08-06 21:31 | 2026-08-06 22:02 | 7 | 185 |
| **29 min** | 2026-08-07 15:34 | 2026-08-07 16:03 | 14 | 1,489 |
| **28 min** | 2026-08-07 13:36 | 2026-08-07 14:05 | 5 | 959 |
| **26 min** | 2026-08-06 22:33 | 2026-08-06 22:59 | 1 | 0 |
| **23 min** | 2026-08-06 12:20 | 2026-08-06 12:43 | 3 | 0 |

**Best exhibit by commits landed:** 3h 02m of silence (2026-08-07 22:46 → 2026-08-08 01:49) carrying **22 commits** and **1,114 `.lean` lines**.

## 5. The longest unbroken run

**22 consecutive commits**, 2026-08-07 22:47 → 2026-08-08 00:57, span **2h 10m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-07 22:47 | `dd16962` | docs: SEATS.md — ALUSEL-PARAM exception STRUCK on its landing (release posted 22:18); e… |
| 08-07 22:54 | `6d326fa` | saltworks: ⭐⭐ THE SEAM JOIN — ElemSortsAt DISCHARGED, and composed_switch_of_seam REACH… |
| 08-07 22:56 | `33a3c86` | saltworks: ⭐⭐⭐ THE SEAM IS CLOSED — composed_switch_of_bnC_driven, hseam discharged fro… |
| 08-07 23:01 | `10d1a58` | saltworks: muster §1a — the seam gate reads the DISCHARGE, and I corrected the proposed… |
| 08-07 23:04 | `25f73d3` | saltworks: muster gate — the BUILD LINE, run without a pipe, because the proposed form … |
| 08-07 23:06 | `85ca1e1` | saltworks: COMPILER NIGHT BANK — the seam closed, what I got wrong, and what this bank … |
| 08-07 23:06 | `93e1cb7` | saltworks: bank — closing the gap I had just written into it rather than confessing it |
| 08-07 23:14 | `924a44e` | hub sweep: the five seam modules enter the corpus — Cone, SeamElement, SeamJoinA/B/C (i… |
| 08-07 23:16 | `76c9522` | saltworks: bank — the sweep landed and B5 unblocked; striking two owed-items so the ban… |
| 08-07 23:17 | `50267ca` | saltworks: muster gate — recording math's NEGATIVE CONTROL, which is what makes the bui… |
| 08-07 23:17 | `7d7eefc` | saltworks: B5 brief section 3 — half the gate is measured, and it is the half that was … |
| 08-07 23:22 | `d567ca4` | saltworks: B4's evidence is TWO objects — the corpus tick is REPLAYED (cached text), th… |
| 08-07 23:46 | `27a1789` | saltworks: reach_census — DERIVE the outside-module set, and fix the headline that asse… |
| 08-07 23:59 | `b55824d` | saltworks: reach_census — PAY THE SUBTRACTION the header has owed since it was written.… |
| 08-08 00:00 | `1183526` | saltworks: bank — strike the reach_census owed-item, record the subtraction result and … |
| 08-08 00:03 | `6ecea1e` | saltworks: bank — SeamJoinC SEPARATED (7 unique / 7 redundant), and a duplicate declara… |
| 08-08 00:06 | `3801ee8` | saltworks: DELETE the duplicate bnCFrameAt_length from SeamJoinC — the hub's line order… |
| 08-08 00:11 | `267787d` | saltworks: dup_decls.py — assert the no-duplicate PROPERTY instead of hand-checking it |
| 08-08 00:15 | `e99c720` | saltworks: bank section 5(e) — silicon's own slot advanced by zero tonight, and I only … |
| 08-08 00:16 | `9a2ae82` | saltworks: bank — B4's scope sentence, verified at the source: it certifies DESTINATION… |
| 08-08 00:17 | `0c55706` | saltworks: bank — the harder version of my own ratio item, with three more hours of evi… |
| 08-08 00:57 | `f4825d7` | saltworks: bank — the second half of the night's error list, 23:00 to 01:00 |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 1 | 262 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 196 | 6,663 | 0 | 294 | 00:55 | 23:07 |
| 2026-08-07 | Fri | 319 | 23,410 | 14 | 260 | 01:45 | 22:46 |
| 2026-08-08 | Sat | 10 | 12 | 8 | 18 | 01:49 | 08:04 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **77 of 526 (14.6%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 2,183 |
| `slash-command` | **counted as human** | 163 |
| `legacy-fallback` | **counted as human** | 85 |
| `interrupt` | **counted as human** | 29 |
| `tool-result` | rejected | 17,855 |
| `task-notification` | rejected | 2,715 |
| `slash-command-echo` | rejected | 317 |
| `harness-injection` | rejected | 232 |
| `compaction-summary` | rejected | 33 |
| `system-reminder` | rejected | 3 |
| `bash-mode` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 880 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 133,359 records over 32 session files; 23,618 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-08 08:05 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 390,012 liveness records at a **5-minute** tolerance.

**The tolerance, calibrated by this run rather than quoted from an earlier one** — a threshold is only honest while the data it separates stays separated:

| Calibration | Value |
|---|---:|
| Median commit → nearest record | **0.2 s** |
| p99 | 1.0 s |
| Worst commit still INSIDE the tolerance | **0.02 min** |
| Best commit OUTSIDE it (the nearest hole) | _none — nothing is flagged_ |

✅ **Every one of the 70 commits in this window has a transcript record beside it.** The silences below are measured.

⚠️ **The narrower question this check actually answers:** *did work land inside a hole?* — not *is the record whole?* A hole in a stretch where nothing was committed leaves no trace here and is invisible to it. That is tolerable only because no published figure depends on such a stretch: the measure that carries the claim (§2) counts commits. It is stated rather than left to be discovered. **Known false-positive mode:** a commit made by hand from a terminal rather than by a seat would flag identically — measured at **0 occurrences in 862 commits on 2026-08-06** (a frozen figure, unlike the calibration table above, which this run computes), but the record cannot rule it out for a commit it has never seen.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **70** |
| `.lean` lines inserted | **4,761** |
| All lines inserted | 11,370 |
| First commit | 2026-08-05 22:06 `db277c4` |
| Last commit | 2026-08-07 09:18 `8b5998d` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,460** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 2,184 |
| Seats read for presence | 5 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 4 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **369** human touches: **216** into this seat and **153** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 70 | 100% | 4,761 | 11,370 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 3 | 4.3% | 0 |
| ≥ 2 h | 3 | 4.3% | 0 |
| ≥ 4 h | 3 | 4.3% | 0 |
| ≥ 8 h | 3 | 4.3% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 70 | 100% | 4,761 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 70 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **59 min** | 2026-08-06 13:57 | 2026-08-06 14:56 | 1 | 0 |
| **30 min** | 2026-08-06 21:31 | 2026-08-06 22:02 | 1 | 0 |
| **26 min** | 2026-08-06 22:33 | 2026-08-06 22:59 | 1 | 0 |
| **15 min** | 2026-08-06 17:42 | 2026-08-06 17:57 | 1 | 130 |
| **15 min** | 2026-08-06 08:21 | 2026-08-06 08:36 | 2 | 4 |
| **13 min** | 2026-08-06 17:28 | 2026-08-06 17:42 | 1 | 0 |
| **9 min** | 2026-08-06 10:06 | 2026-08-06 10:15 | 5 | 849 |
| **9 min** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 0 |
| **8 min** | 2026-08-06 10:27 | 2026-08-06 10:36 | 2 | 216 |
| **8 min** | 2026-08-06 11:48 | 2026-08-06 11:57 | 4 | 218 |

**Best exhibit by commits landed:** 0h 08m of silence (2026-08-06 09:54 → 2026-08-06 10:02) carrying **6 commits** and **580 `.lean` lines**.

## 5. The longest unbroken run

**6 consecutive commits**, 2026-08-06 09:54 → 2026-08-06 09:58, span **0h 03m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-06 09:54 | `993f84e` | play M: WEIL-TRIO D8 — W1 home (pre-flight PASS at the source, W2 stays dead; my e-2 br… |
| 08-06 09:55 | `1019c0e` | play M: N7-PREP DOSSIER — the consumption/supply/gap map for Lemma 10 + (7.5)-(7.8) (re… |
| 08-06 09:56 | `f2aba94` | play M: WEIL-TRIO-W4Q(W4-c0) — the :137 proof's hval exposed: quadraticChar_sum_two_for… |
| 08-06 09:56 | `49361e2` | play M: WEIL-TRIO-W4Q(W4-b + W4-c′ + W4-c + W4-d) — Salt/HB/RealPrimitive.lean (460 ln,… |
| 08-06 09:57 | `83770b4` | play M: WEIL-TRIO D9 — W4Q home 5/5 (p.217 at constant ONE in-kernel; the jacobiChar ex… |
| 08-06 09:58 | `a7fa34e` | play M: flags — W3's D3 exit is NOT (7.1), and W4-a is on its critical path (a math-sea… |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 2 | 0 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 65 | 4,489 | 0 | 294 | 00:55 | 23:07 |
| 2026-08-07 | Fri | 3 | 272 | 0 | 260 | 01:45 | 22:46 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **5 of 70 (7.1%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 2,183 |
| `slash-command` | **counted as human** | 163 |
| `legacy-fallback` | **counted as human** | 85 |
| `interrupt` | **counted as human** | 29 |
| `tool-result` | rejected | 17,860 |
| `task-notification` | rejected | 2,715 |
| `slash-command-echo` | rejected | 317 |
| `harness-injection` | rejected | 232 |
| `compaction-summary` | rejected | 33 |
| `system-reminder` | rejected | 3 |
| `bash-mode` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 880 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 133,385 records over 32 session files; 23,623 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-08 08:05 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-07-23 00:00` → `2026-08-06 00:00` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 390,020 liveness records at a **5-minute** tolerance.

**The tolerance, calibrated by this run rather than quoted from an earlier one** — a threshold is only honest while the data it separates stays separated:

| Calibration | Value |
|---|---:|
| Median commit → nearest record | **0.5 s** |
| p99 | 5.1 s |
| Worst commit still INSIDE the tolerance | **3.08 min** |
| Best commit OUTSIDE it (the nearest hole) | _none — nothing is flagged_ |

✅ **Every one of the 715 commits in this window has a transcript record beside it.** The silences below are measured.

⚠️ **The narrower question this check actually answers:** *did work land inside a hole?* — not *is the record whole?* A hole in a stretch where nothing was committed leaves no trace here and is invisible to it. That is tolerable only because no published figure depends on such a stretch: the measure that carries the claim (§2) counts commits. It is stated rather than left to be discovered. **Known false-positive mode:** a commit made by hand from a terminal rather than by a seat would flag identically — measured at **0 occurrences in 862 commits on 2026-08-06** (a frozen figure, unlike the calibration table above, which this run computes), but the record cannot rule it out for a commit it has never seen.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **715** |
| `.lean` lines inserted | **346,567** |
| All lines inserted | 379,060 |
| First commit | 2026-07-23 00:14 `3592f5c` |
| Last commit | 2026-08-05 22:19 `df72d8a` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,460** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 2,184 |
| Seats read for presence | 5 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 4 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **716** human touches: **716** into this seat and **0** into every other personal-lane seat combined. The two measures therefore coincide, and the leg-1 caveat *“he may have been directing another seat”* is discharged for this window — within the personal lane.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 344 | 48.1% | 198,208 | 214,476 |
| ≥ 2 h | 219 | 30.6% | 128,389 | 137,859 |
| ≥ 4 h | 125 | 17.5% | 52,652 | 58,954 |
| ≥ 8 h | 104 | 14.5% | 45,476 | 50,852 |
| ≥ 12 h | 48 | 6.7% | 22,610 | 25,174 |
| (all observed commits) | 715 | 100% | 346,567 | 379,060 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 344 | 48.1% | 198,208 |
| ≥ 2 h | 219 | 30.6% | 128,389 |
| ≥ 4 h | 125 | 17.5% | 52,652 |
| ≥ 8 h | 104 | 14.5% | 45,476 |
| ≥ 12 h | 48 | 6.7% | 22,610 |
| (observed by this seat) | 715 | 100% | 346,567 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 453 | 63.4% |
| 30–60 min | 92 | 12.9% |
| 1–2 h | 95 | 13.3% |
| 2–4 h | 55 | 7.7% |
| 4–8 h | 20 | 2.8% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **20h 56m** | 2026-08-02 12:13 | 2026-08-03 09:09 | 26 | 12,310 |
| **14h 25m** | 2026-07-24 17:45 | 2026-07-25 08:11 | 3 | 2,591 |
| **13h 22m** | 2026-07-31 19:17 | 2026-08-01 08:39 | 2 | 0 |
| **13h 16m** | 2026-08-03 18:31 | 2026-08-04 07:47 | 13 | 5,754 |
| **12h 21m** | 2026-08-01 20:50 | 2026-08-02 09:12 | 3 | 1,955 |
| **12h 01m** | 2026-07-23 19:14 | 2026-07-24 07:15 | 1 | 0 |
| **11h 16m** | 2026-07-25 21:12 | 2026-07-26 08:28 | 9 | 3,995 |
| **10h 45m** | 2026-07-27 19:28 | 2026-07-28 06:13 | 11 | 491 |
| **10h 38m** | 2026-07-22 20:44 | 2026-07-23 07:22 | 3 | 0 |
| **10h 33m** | 2026-07-26 20:35 | 2026-07-27 07:09 | 5 | 4,652 |

**Best exhibit by commits landed:** 3h 38m of silence (2026-08-05 14:21 → 2026-08-05 17:59) carrying **34 commits** and **6,308 `.lean` lines**.

## 5. The longest unbroken run

**34 consecutive commits**, 2026-08-05 14:32 → 2026-08-05 17:51, span **3h 19m**, with zero human touches to any personal-lane seat between the first and the last.

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-07-23 | Thu | 56 | 5,843 | 23 | 47 | 07:22 | 19:14 |
| 2026-07-24 | Fri | 36 | 10,255 | 3 | 55 | 07:15 | 17:45 |
| 2026-07-25 | Sat | 81 | 29,149 | 33 | 73 | 08:11 | 21:12 |
| 2026-07-26 | Sun | 67 | 27,296 | 22 | 59 | 08:28 | 20:35 |
| 2026-07-27 | Mon | 55 | 11,407 | 14 | 65 | 07:09 | 19:28 |
| 2026-07-28 | Tue | 58 | 37,617 | 33 | 45 | 06:13 | 21:09 |
| 2026-07-29 | Wed | 64 | 28,198 | 41 | 47 | 03:04 | 20:36 |
| 2026-07-30 | Thu | 82 | 45,739 | 48 | 42 | 05:54 | 20:45 |
| 2026-07-31 | Fri | 40 | 29,265 | 7 | 82 | 07:04 | 19:17 |
| 2026-08-01 | Sat | 23 | 82,136 | 20 | 15 | 08:39 | 20:50 |
| 2026-08-02 | Sun | 46 | 18,631 | 26 | 29 | 09:12 | 12:13 |
| 2026-08-03 | Mon | 42 | 10,350 | 30 | 22 | 09:09 | 18:31 |
| 2026-08-04 | Tue | 15 | 1,790 | 0 | 91 | 07:47 | 19:59 |
| 2026-08-05 | Wed | 50 | 8,891 | 44 | 45 | 07:06 | 22:19 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **80 of 715 (11.2%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 2,183 |
| `slash-command` | **counted as human** | 163 |
| `legacy-fallback` | **counted as human** | 85 |
| `interrupt` | **counted as human** | 29 |
| `tool-result` | rejected | 17,861 |
| `task-notification` | rejected | 2,715 |
| `slash-command-echo` | rejected | 317 |
| `harness-injection` | rejected | 232 |
| `compaction-summary` | rejected | 33 |
| `system-reminder` | rejected | 3 |
| `bash-mode` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 880 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 133,389 records over 32 session files; 23,624 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# TOKEN METER — the campaign ledger

Generated 2026-08-08 08:06 America/Los_Angeles by `docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per `docs/measurement-preregistration.md` §1.
Window: `2026-08-05 22:00` → `now` · 5 personal-lane projects · subagent transcripts INCLUDED.

> **Unit is TOKENS.** These records carry no prices and no account identifier, so no dollar figure and no per-account split is derivable from them. On a subscription, dollars are a flat envelope; the two framings are reported separately or not at all, never blended.
> **Cache is always its own column** and never enters a headline number.

## 1. Totals

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 17,397 |
| Input | 123,184 |
| **Output** | **11,658,638** |
| Cache created | 74,658,063 |
| Cache read | 5,208,634,086 |
| First request | 2026-08-05 22:02 |
| Last request | 2026-08-08 08:05 |

## 2. By project

| Project | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `-Users-jyh-projects-claude-saltworks` | 11,966 | 67,441 | **8,351,936** | 41,663,622 | 3,618,930,317 |
| `-Users-jyh-projects-claude-salt` | 5,431 | 55,743 | **3,306,702** | 32,994,441 | 1,589,703,769 |
| **TOTAL** | **17,397** | **123,184** | **11,658,638** | **74,658,063** | **5,208,634,086** |

## 3. By model tier

| Tier | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| Opus 5 | 16,018 | 108,616 | **10,390,023** | 63,461,934 | 4,533,174,483 |
| Fable 5 | 1,291 | 3,087 | **1,228,164** | 8,425,092 | 620,998,906 |
| Opus 4.8 | 82 | 154 | **40,441** | 2,704,200 | 54,281,388 |
| Haiku 4.5 | 6 | 11,327 | **10** | 66,837 | 179,309 |
| **TOTAL** | **17,397** | **123,184** | **11,658,638** | **74,658,063** | **5,208,634,086** |

## 4. By day

| Date | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| 2026-08-05 | 24 | 11,361 | **22,571** | 228,132 | 10,006,395 |
| 2026-08-06 | 9,223 | 79,183 | **5,029,793** | 40,273,619 | 2,204,518,061 |
| 2026-08-07 | 7,246 | 22,859 | **5,984,890** | 31,401,674 | 2,675,887,431 |
| 2026-08-08 | 904 | 9,781 | **621,384** | 2,754,638 | 318,222,199 |
| **TOTAL** | **17,397** | **123,184** | **11,658,638** | **74,658,063** | **5,208,634,086** |

## 5. Main loop vs subagents

| Where | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| main loop | 9,340 | 21,429 | **10,906,815** | 36,022,057 | 4,549,599,542 |
| subagents / workflow agents | 8,057 | 101,755 | **751,823** | 38,636,006 | 659,034,544 |
| **TOTAL** | **17,397** | **123,184** | **11,658,638** | **74,658,063** | **5,208,634,086** |

_In this window the subagents made **46% of the requests** and **6% of the output tokens** (main loop: 54% / 94%). Design and orchestration sat in the main loops; the agents were many but individually cheap._

## 6. By wave — timestamp-join against git

| Wave (leading tag of the landing commit's subject) | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `TAU-SHARP` | 646 | 7,834 | **429,089** | 3,687,676 | 102,336,755 |
| `MIGRATION-PROOF` | 186 | 354 | **146,414** | 1,194,960 | 77,830,330 |
| `OPERATIONS` | 144 | 272 | **130,738** | 1,643,655 | 72,602,936 |
| `N7-prep` | 153 | 294 | **113,016** | 1,105,430 | 68,140,310 |
| `WEIL-TRIO` | 159 | 309 | **85,167** | 2,672,942 | 42,134,402 |
| `HSIGMA-COMP` | 74 | 142 | **84,390** | 605,590 | 23,340,687 |
| `HB` | 201 | 395 | **82,899** | 1,256,065 | 66,558,120 |
| `the cap` | 90 | 169 | **61,481** | 83,166 | 34,011,172 |
| `WEIL-TRIO-W1` | 166 | 1,899 | **60,635** | 753,450 | 36,487,132 |
| `WEIL-TRIO-W4A` | 159 | 4,753 | **46,901** | 669,615 | 38,594,703 |
| `TS-1` | 32 | 61 | **44,359** | 77,855 | 17,045,305 |
| `(unlabelled)` | 47 | 89 | **38,624** | 182,111 | 19,643,623 |
| `TS-2` | 38 | 71 | **36,053** | 194,116 | 8,699,561 |
| `SILICON` | 78 | 152 | **34,430** | 783,630 | 18,722,293 |
| `N4` | 50 | 97 | **29,478** | 233,813 | 11,607,131 |
| `COUNCIL` | 12 | 23 | **29,343** | 811,092 | 8,739,995 |
| `WEIL-TRIO-W5` | 68 | 132 | **29,004** | 151,672 | 25,687,771 |
| `THE DOI` | 60 | 117 | **28,357** | 63,999 | 16,090,843 |
| `THE WITNESS` | 34 | 64 | **23,782** | 521,199 | 14,187,373 |
| `campaign` | 48 | 95 | **22,504** | 313,792 | 8,369,363 |
| `THE TRIPLE` | 22 | 11,357 | **22,407** | 226,318 | 8,703,407 |
| `memory` | 17 | 32 | **19,999** | 30,680 | 5,142,760 |
| `hb1983-notes` | 36 | 70 | **18,513** | 238,858 | 10,088,198 |
| `CHAR-TRIO` | 5 | 9 | **16,632** | 23,559 | 1,257,668 |
| `strike` | 31 | 58 | **16,493** | 24,087 | 13,124,676 |
| `the` | 12 | 22 | **12,227** | 13,213 | 5,743,013 |
| `copyright` | 8 | 16 | **8,121** | 18,090 | 2,711,463 |
| `flags` | 13 | 24 | **8,007** | 44,231 | 3,476,615 |
| `WEIL-TRIO-W3` | 13 | 12,225 | **6,903** | 67,374 | 1,626,611 |
| `N7-PREP` | 11 | 22 | **6,038** | 32,195 | 3,749,893 |
| `GUARD` | 4 | 6 | **3,753** | 8,236 | 578,863 |
| `WEIL-TRIO-W4Q` | 5 | 9 | **3,010** | 17,873 | 1,051,418 |
| `WEIL-CONS` | 4 | 8 | **2,585** | 7,261 | 1,004,095 |
| **TOTAL** | **2,626** | **41,180** | **1,701,352** | **17,757,803** | **769,088,485** |

Attribution rule: each request is charged to the **next commit in `salt` at or after its timestamp**, if that commit lands within 4.0 h; otherwise it is unattributed. Unattributed in this window: 2,805 requests / 1,605,350 output tokens. Only requests from this repo's own seat (`-Users-jyh-projects-claude-salt`) are joined.

> **This join is a heuristic, and the table is labelled as one.** A request that produced no commit (a scout, a refuter, a council) is charged to whatever landed next. Read it as *tokens spent in the run-up to a landing*, never as *tokens the landing cost*.

## 7. Methodology — what was counted and what was thrown away

| Fact | Value |
|---|---:|
| Transcript files read | 2,520 |
| JSONL records scanned | 430,559 |
| Duplicate assistant records dropped (same `requestId`) | 131,829 |
| `<synthetic>` records dropped (API errors, zero usage) | 107 |
| Unparseable lines | 0 |

**The dedup rule.** Claude Code writes one assistant record per content block of a response, and **every one of those records repeats the whole `usage` block of the single API call**. Measured here: 131,829 records were duplicates of a request already counted. Summing records instead of requests would inflate every number in this file by roughly a factor of three. Usage was verified byte-identical within each `requestId` group before the rule was adopted.

**Subagents.** Workflow and Task agents write their own transcripts under `<session>/subagents/**/agent-*.jsonl`. They are included by default (`--no-subagents` to exclude). In THIS window they are 46% of requests and 6% of output tokens. **Request share and token share differ sharply and can point opposite ways** — quote whichever you mean, and never the word 'majority' unattached to a unit.

**Per-account attribution: UNAVAILABLE.** The transcripts carry no account, organisation or subscription identifier — checked field by field across every record type. The campaign runs five accounts; these files cannot say which one paid for a given request. Reported here as a gap rather than estimated.

**The firewall.** Outside-lane projects are excluded in code (`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure published from this tool is personal-lane only.


---

# HUMAN-TIME LEDGER — the four categories

Generated 2026-08-08 08:06 America/Los_Angeles by `docs/ledger-tools/human_time.py`, per `docs/measurement-preregistration.md` §2.
Window: `2026-08-05 22:00` → `now` · block gap 20 min · tags from `EVIDENCE-human-time-tags.tsv`.

**The rubric, published beside the number** — DIRECTING: rulings, councils, requirement-setting. REVIEWING: reading that *gates* an artifact. UNBLOCKING: logins, purchases, physical acts. WATCHING: curiosity — reading along, questions that redirect nothing. **The dependency claim = DIRECTING + REVIEWING + UNBLOCKING only**, by the counterfactual test *would the artifact exist without this touch?* WATCHING is reported as its own line, proudly: the joy is evidence, not overhead.

## 1. Totals

| Category | Blocks | Time | Share |
|---|---:|---:|---:|
| **DIRECTING** | 4 | 7h 00m | 25.6% |
| **UNBLOCKING** | 1 | 6h 05m | 22.2% |
| WATCHING | 2 | 0h 02m | 0.2% |
| UNTAGGED | 15 | 14h 14m | 52.0% |
| **THE CLAIM** (D+R+U) | 5 | **13h 06m** | 47.8% |
| (all engaged time) | 22 | 27h 23m | 100% |

> **15 block(s), 14h 14m, are UNTAGGED.** They are counted in neither the claim nor WATCHING. Tag them in `EVIDENCE-human-time-tags.tsv` — one line per block id — and re-run. An untagged block is never silently folded into a category.

> ⛔ **2 TAG(S) MATCH NO BLOCK IN THIS WINDOW** and are contributing nothing: `20260805T1759`, `20260805T2039`. A block id is its first touch's timestamp, so changing `--since`, or one new message landing inside a former gap, merges blocks and detaches their tags. **Tags are matched by containment rather than by exact id precisely so this is visible instead of silent** — but a tag outside the window still needs re-pointing. Re-run the worksheet and re-tag.

## 2. Per day

| Date | Blocks | Engaged time | Claim time (D+R+U) | Messages |
|---|---:|---:|---:|---:|
| 2026-08-05 | 1 | 0h 17m | 0h 17m | 4 |
| 2026-08-06 | 8 | 13h 29m | 12h 48m | 294 |
| 2026-08-07 | 11 | 12h 54m | 0h 00m | 260 |
| 2026-08-08 | 2 | 0h 41m | 0h 00m | 18 |

## 3. The blocks — the tagging worksheet

Copy a block id into the tag file with its category. The opening message is shown only so the block can be recognised.

| Block id | Seat | Start | End | Duration | Msgs | Category | Opens with |
|---|---|---|---|---:|---:|---|---|
| `20260805T2201` | salt | 08-05 22:01 | 22:19 | 0h 17m | 4 | DIRECTING | typed (858 chars) |
| `20260806T0055` | salt | 08-06 00:55 | 00:56 | 0h 01m | 2 | WATCHING | typed (10 chars) |
| `20260806T0629` | salt | 08-06 06:29 | 07:36 | 1h 06m | 19 | DIRECTING | slash-command,typed (162 chars) |
| `20260806T0757` | salt | 08-06 07:57 | 12:20 | 4h 22m | 119 | DIRECTING | interrupt,legacy-fallback,slash-command,typed (230 chars) |
| `20260806T1243` | saltworks | 08-06 12:43 | 13:57 | 1h 13m | 34 | DIRECTING | legacy-fallback,typed (229 chars) |
| `20260806T1456` | salt | 08-06 14:56 | 14:56 | 0h 01m | 3 | WATCHING | slash-command  |
| `20260806T1525` | saltworks | 08-06 15:25 | 21:31 | 6h 05m | 109 | UNBLOCKING | interrupt,legacy-fallback,slash-command,typed (65 chars) |
| `20260806T2202` | saltworks | 08-06 22:02 | 22:33 | 0h 30m | 5 | **UNTAGGED** | typed (39 chars) |
| `20260806T2259` | saltworks | 08-06 22:59 | 23:07 | 0h 07m | 3 | **UNTAGGED** | typed (29 chars) |
| `20260807T0145` | saltworks | 08-07 01:45 | 01:45 | 0h 01m | 1 | **UNTAGGED** | typed (16 chars) |
| `20260807T0527` | salt | 08-07 05:27 | 05:31 | 0h 03m | 2 | **UNTAGGED** | typed (95 chars) |
| `20260807T0558` | salt | 08-07 05:58 | 08:36 | 2h 37m | 62 | **UNTAGGED** | legacy-fallback,slash-command,typed (58 chars) |
| `20260807T0903` | saltworks | 08-07 09:03 | 13:36 | 4h 33m | 84 | **UNTAGGED** | interrupt,legacy-fallback,slash-command,typed (383 chars) |
| `20260807T1405` | salt | 08-07 14:05 | 15:13 | 1h 07m | 20 | **UNTAGGED** | slash-command,typed (743 chars) |
| `20260807T1534` | saltworks | 08-07 15:34 | 15:34 | 0h 01m | 1 | **UNTAGGED** | typed (573 chars) |
| `20260807T1603` | salt | 08-07 16:03 | 16:12 | 0h 08m | 3 | **UNTAGGED** | typed (254 chars) |
| `20260807T1633` | salt | 08-07 16:33 | 20:52 | 4h 18m | 81 | **UNTAGGED** | interrupt,legacy-fallback,slash-command,typed (418 chars) |
| `20260807T2134` | saltworks | 08-07 21:34 | 21:34 | 0h 01m | 3 | **UNTAGGED** | slash-command,typed (484 chars) |
| `20260807T2212` | salt | 08-07 22:12 | 22:12 | 0h 01m | 1 | **UNTAGGED** | typed (483 chars) |
| `20260807T2246` | salt | 08-07 22:46 | 22:46 | 0h 01m | 2 | **UNTAGGED** | slash-command,typed (1593 chars) |
| `20260808T0149` | salt | 08-08 01:49 | 02:18 | 0h 28m | 9 | **UNTAGGED** | typed (14 chars) |
| `20260808T0752` | salt | 08-08 07:52 | 08:04 | 0h 12m | 9 | **UNTAGGED** | interrupt,slash-command,typed (7 chars) |

## 4. Method notes

- A **block** is a run of human touches with no gap longer than 20 minutes. Its duration is last touch minus first touch, floored at 60 s for a single-touch block.
- **This under-counts, deliberately.** Reading and thinking before the first message of a block leave no trace in the transcript, so the figure is a *floor* on engaged time. It is published as a floor and never adjusted upward by estimate.
- **No manual time-tracking**, per the frozen design. Every timestamp comes from the transcript; the only human input is the category tag, and the rubric that assigns it is printed above the number.
- The touch filter is the one in `ledger_common.classify_user_record` — see `README.md`. Injected records (task notifications, loop ticks, cron pings, peer messages) are not human time.
- Touches read: 576 in window. Rejected as non-human across the whole record: 21,166.


---

## LANDED — generated from `git log`, never typed

Generated 2026-08-08 08:06 America/Los_Angeles by `docs/ledger-tools/landed.py`. Window: `2026-08-05 22:00` → `now`.

> **This table is mechanical.** It reports what was committed — hash, time, lane, size. It knows nothing about whether a thing *works*, whether a proof is *meaningful*, or what anyone intends next; those stay hand-written and stay stamped with the time they were written. **A commit hash does not age, which is the entire reason this is generated** (resource lesson 5: a snapshot of another seat's live tree ages in minutes).
> Seat attribution is a **heuristic over file paths**, from the writer-slot law in `docs/SEATS.md`. It is not a claim about who typed what.

### `saltworks` — 526 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| compiler (leg 2) | 176 | 21,894 | 15,181 |
| evidence | 162 | 18,308 | 0 |
| silicon (leg 3) | 118 | 184,397 | 2,809 |
| docs (shared) | 38 | 13,746 | 8,141 |
| maestro (hub) | 23 | 3,729 | 1,423 |
| maestro | 5 | 429 | 292 |
| other | 4 | 2,501 | 2,501 |
| **total** | **526** | **245,004** | **30,347** |

| When | Commit | Lane | +lines | Subject |
|---|---|---|---:|---|
| 08-05 22:05 | `4fa92be` | maestro | 282 | saltworks: T0 — the Batcher-banyan self-routing theorem, parametric in k |
| 08-06 06:33 | `fe3401c` | maestro | 104 | saltworks: seat structure — HDL (leg 2) + Silicon (leg 3) subtrees, hub ownership, the writer-… |
| 08-06 06:33 | `60f6d2f` | compiler (leg 2) | 106 | saltworks: the two governing design freezes (HDL leg-2, Silicon leg-3) — each seat's first act… |
| 08-06 07:08 | `a94e122` | compiler (leg 2) | 38 | saltworks: Council I — measurement pre-registration frozen; HDL addendum (fungibility exhibit … |
| 08-06 07:58 | `cb5ccb3` | compiler (leg 2) | 36 | saltworks: BIT-SERIAL ruled (JYH, Council I) — the tapeout target is the 1988 serial represent… |
| 08-06 08:49 | `5d93a01` | evidence | 3,375 | saltworks: THE LEDGER TOOLING lands (evidence seat, deliverables 0+1) — token meter + silence-… |
| 08-06 08:55 | `bed5ed9` | evidence | 356 | saltworks: SLICE A — the RISC-V datapath scoping brief (evidence seat, deliverable 3) — five i… |
| 08-06 09:00 | `9caa090` | evidence | 505 | saltworks: THE TTSKY26c SUBMISSION DOSSIER (evidence seat, deliverable 2) — deadline is 13:00 … |
| 08-06 09:04 | `c4f8f00` | evidence | 358 | saltworks: TTSKY26c dossier — the critic pass folded in (power-gating kills state on deselect;… |
| 08-06 09:13 | `0e48fae` | evidence | 6 | saltworks: maestro tags the first six human-time blocks (5 DIRECTING, 1 WATCHING; 2h04m engage… |
| 08-06 09:28 | `6ac1d20` | evidence | 551 | saltworks: the build-etiquette DETECTOR — compliance is per-process ancestry, not "is the lock… |
| 08-06 09:30 | `3e41d10` | silicon (leg 3) | 95 | saltworks: SILICON REFUTER PASS — the kernel cost law does not transfer, and bit-slicing disso… |
| 08-06 09:33 | `62b1b25` | silicon (leg 3) | 669 | saltworks: D1 (Silicon) — real sky130 synthesis, reproducible, versions pinned; the Nix half s… |
| 08-06 09:35 | `ec2693f` | evidence | 234 | saltworks: DAY-1 LEDGER, dated and committed (evidence seat) — and it honestly shows near-zero… |
| 08-06 09:36 | `e6ee627` | evidence | 328 | saltworks: the public README SKELETON, drafted for ratification (evidence seat) — the 1988 cor… |
| 08-06 09:50 | `0baa9fd` | silicon (leg 3) | 208 | saltworks: D2a (Silicon) — the 13 sky130 cell models, each cross-checked in the kernel against… |
| 08-06 09:51 | `e21dd45` | evidence | 111 | saltworks: DAY-1 TOKEN REPORT (evidence seat) — 869,114 output tokens across the fleet since T… |
| 08-06 09:52 | `8968066` | evidence | 181 | saltworks: docs/EVIDENCE-campaign.md — the running scoreboard (evidence seat), with a promotio… |
| 08-06 09:54 | `1acaa66` | evidence | 38 | saltworks: scoreboard corrected — my ulimit proposal is a NO-OP on Darwin (math measured it), … |
| 08-06 09:55 | `de6322c` | silicon (leg 3) | 211 | saltworks: D2b (Silicon) — THE REFLECTION THEOREM: sliced evaluation IS pointwise evaluation |
| 08-06 10:00 | `a9a6c03` | evidence | 25 | saltworks: the scoreboard now states that it goes stale in minutes — because math measured exa… |
| 08-06 10:00 | `04a2ecc` | silicon (leg 3) | 121 | saltworks: D2c (Silicon) — the input columns, proved; reflection now stands on nothing unproved |
| 08-06 10:05 | `026f27f` | silicon (leg 3) | 290 | saltworks: SILICON REFUTER ADDENDUM — 58 findings from four re-dispatched lanes, five of which… |
| 08-06 10:08 | `01480f9` | evidence | 72 | saltworks: FOUR corrections to my own published artifacts, all from the Silicon seat's refuter… |
| 08-06 10:10 | `0e17ecf` | evidence | 28 | saltworks: the fleet found the same missing instrument three times in one hour, from three dir… |
| 08-06 10:12 | `d79d7dd` | evidence | 2 | saltworks: the 10:05 watchdog catch closed — the finding reached the seat and changed the arti… |
| 08-06 10:28 | `9e6f204` | evidence | 45 | saltworks: the convergent finding is now a MEASUREMENT — the instrument was built and run the … |
| 08-06 10:30 | `a02c956` | evidence | 55 | saltworks: exhaustive certificates must be priced by SEARCH SPACE, not wall time — the compile… |
| 08-06 10:32 | `5bb9de4` | evidence | 45 | saltworks: the -M cap is live and unverified — so the detector now measures whether it binds, … |
| 08-06 10:36 | `12c0835` | evidence | 104 | saltworks: the flow flattens — "equivalence per module" has no modules left to be per, and two… |
| 08-06 10:37 | `90192fa` | compiler (leg 2) | 238 | saltworks: LEG-2 REFUTER VERDICTS — the freeze prices the wrong axis, and the seam's landed co… |
| 08-06 10:39 | `62a7fbe` | evidence | 20 | saltworks: the first real design bug, and it is the sharpest instance yet of the day-1 princip… |
| 08-06 10:40 | `ad313e3` | compiler (leg 2) | 258 | saltworks: HDL Syntax + Sem — the corrected carrier, and the leg is Mathlib-free (4 jobs, 1.2s) |
| 08-06 10:43 | `0aad951` | compiler (leg 2) | 182 | saltworks: T1 — opt_sem, unconditional, by making the optimizer VALIDATED rather than proved-c… |
| 08-06 10:47 | `2a27c12` | compiler (leg 2) | 218 | saltworks: T3 + T5 — the certificate suite is BIT-SLICED, and the reflection theorem needs no … |
| 08-06 10:49 | `5ce377c` | evidence | 62 | saltworks: a correction to my own record — I logged only what #audit_axioms cannot do, which i… |
| 08-06 10:58 | `e01b13d` | evidence | 22 | [8/6 12:12, evidence] ⛔⛔ FOURTH RESOURCE FINDING, MEASURED LIVE, AND IT REFUTES THE ASSUMPTION… |
| 08-06 11:02 | `3891a2e` | evidence | 28 | saltworks: two claims in one sentence, and I impugned the true one — the -j correction, plus t… |
| 08-06 11:14 | `476a5f2` | evidence | 3 | saltworks: the routing bug closed as a DESIGN decision, not a patch — the second complete cros… |
| 08-06 11:17 | `19df872` | silicon (leg 3) | 207 | saltworks: SILICON — the routing bug is FIXED against the ruled frame format (activity bit) |
| 08-06 11:17 | `81eecc3` | evidence | 234 | saltworks: the LANDED table is now GENERATED from git — closing the TODO I filed against mysel… |
| 08-06 11:18 | `0620d5a` | evidence | 37 | saltworks: formalising a paper found two errors in the paper — errata recorded as their own ca… |
| 08-06 11:19 | `b28eb5e` | evidence | 26 | saltworks: I published a vindication that our own measurement reverses — the tile-sizing claim… |
| 08-06 11:22 | `6bffe74` | evidence | 21 | saltworks: an erratum changed behaviour, and one unresolved reading is recorded before it can … |
| 08-06 11:24 | `33f6e2d` | evidence | 31 | saltworks: my errata section recorded only the errors we found in someone else's work — one of… |
| 08-06 11:29 | `c34753e` | evidence | 7 | saltworks: tally now 2-2 — and the second defect of ours would have produced an UNPROVABLE lem… |
| 08-06 11:30 | `4977154` | evidence | 1 | saltworks: the declared `sem` is too narrow to state T4 — a fourth instance of the day-1 princ… |
| 08-06 11:32 | `2d68725` | evidence | 37 | saltworks: the tally reversed the headline — we are the LESS reliable party, and the seat that… |
| 08-06 11:37 | `218e4a5` | evidence | 595 | saltworks: my tagging instrument was silently dropping its own tags — the human-time claim was… |
| 08-06 11:38 | `236ccff` | compiler (leg 2) | 631 | saltworks: THE SERIAL FRAME PROTOCOL v1 — the activity-bit ruling made buildable, and the latc… |
| 08-06 11:38 | `2a0f1f0` | evidence | 11 | saltworks: source sweep complete — the two defects that would have cost a wave were both OURS,… |
| 08-06 11:40 | `7b0e99a` | silicon (leg 3) | 48 | saltworks: SILICON — reconciling the TWO v1 frame specs; option C kept, HDL's latch-timing con… |
| 08-06 11:42 | `a10a8e0` | evidence | 134 | saltworks: I audited my own docs and the worst finding is that every timestamp I published tod… |
| 08-06 11:42 | `c5f804b` | evidence | 474 | saltworks: THE CONE CENSUS (Silicon) — "equivalence per module" has no modules; measured what … |
| 08-06 11:44 | `fe79e8f` | evidence | 2 | saltworks: ruling 4b RESOLVED BY MEASUREMENT — the cone answer is a plan, not a hope |
| 08-06 11:46 | `3b3e707` | evidence | 22 | saltworks: README — per-module becomes per-cone, and the unit becomes INPUTS |
| 08-06 11:46 | `f09bb38` | evidence | 0 | saltworks: drop a duplicated line I introduced one commit ago |
| 08-06 11:47 | `eabc581` | evidence | 22 | saltworks: six more self-audit findings closed in my own docs |
| 08-06 11:48 | `143b32c` | evidence | 12 | saltworks: correct the INFERENCE in the brief's §1, not the measurements |
| 08-06 11:50 | `74035a9` | compiler (leg 2) | 141 | saltworks: EmitV — the untrusted backend, with its port contract pinned to an authority outsid… |
| 08-06 11:51 | `2e24205` | silicon (leg 3) | 700 | saltworks: D3 LANDS — real synthesis output proved equivalent to the design, in the kernel, al… |
| 08-06 11:52 | `0cbbc38` | evidence | 1 | saltworks: ruling 7 — both cheap routes to the kappa check are spent, recorded as a negative r… |
| 08-06 11:52 | `e62f00f` | evidence | 1 | saltworks: D3 LANDS — the chain closes at module scale, and the campaign's core claim is now d… |
| 08-06 11:56 | `1699de3` | evidence | 2 | saltworks: the p.214 erratum now rests on TWO independent derivations, and the clean blocks ar… |
| 08-06 11:56 | `33a28c2` | silicon (leg 3) | 52 | saltworks: the bit-slicing MEMORY law, measured — the correction I owed my own repair |
| 08-06 11:58 | `ea0f1aa` | evidence | 21 | saltworks: 9 PB against kilobytes — the decomposition is not optional, and it is now measured … |
| 08-06 11:59 | `26353d2` | compiler (leg 2) | 196 | saltworks: T4 — the Banyan fabric as a Circ, and the certificate caught me reproducing the bug… |
| 08-06 11:59 | `f092884` | evidence | 28 | saltworks: measured — the clock drift does NOT corrupt the deliverable, and the exact boundary… |
| 08-06 12:00 | `0f4c6d7` | silicon (leg 3) | 248 | saltworks: D3.5 LANDS — the SEQUENTIAL element refined, with the banned tactic removed |
| 08-06 12:01 | `ef1e4a7` | compiler (leg 2) | 146 | saltworks: the minimal sequential extension — ZERO new Circ constructors, and the combinationa… |
| 08-06 12:01 | `32458af` | evidence | 9 | saltworks: a FALSE theorem caught by an executable certificate on its author's own work — the … |
| 08-06 12:03 | `05ae340` | evidence | 4 | saltworks: leg 2's sequential extension lands with ZERO new constructors, EmitN unblocks itsel… |
| 08-06 12:17 | `3a9dad6` | evidence | 2 | saltworks: two records with a common ancestor agreeing is ONE record counted twice — a fifth i… |
| 08-06 12:20 | `361e606` | evidence | 1 | saltworks: the sum-cap sample is biased and the bias is mine — the heaviest known workload is … |
| 08-06 12:22 | `af43330` | evidence | 29 | saltworks: a second failure mode — the datum was public, on this bus, and the person who neede… |
| 08-06 12:42 | `002abc1` | silicon (leg 3) | 1,938 | saltworks: D4 fabric RTL + the finding that FLATTENING IS A FLOW SETTING, NOT A LAW |
| 08-06 12:43 | `03fc8e1` | evidence | 3 | saltworks: flattening is a FLOW SETTING, not a law — the constructive half of "the flow flatte… |
| 08-06 12:45 | `1c8ce8b` | silicon (leg 3) | 246 | saltworks: D5 scaffolding — the TinyTapeout submission, validated against the real schema |
| 08-06 12:47 | `2d92326` | evidence | 35 | saltworks: a document that describes a substring-gate by quoting the substring becomes a carri… |
| 08-06 12:53 | `6aff659` | evidence | 15 | saltworks: exit 75 is a lock timeout, not a build failure — my own brief would have produced a… |
| 08-06 13:07 | `63b556a` | maestro (hub) | 17 | saltworks: the hub imports ALL THREE LEGS — the default build now checks Banyan (2), HDL (7), … |
| 08-06 13:10 | `5efaf6c` | evidence | 20 | saltworks: three ways saltbuild.sh exits non-zero and only ONE means the proof is wrong — stat… |
| 08-06 13:13 | `20ba82c` | evidence | 4 | saltworks: a FALSE ZERO — the fourth exit, the dangerous one, and a superseded cap number in m… |
| 08-06 13:13 | `1d92cfa` | evidence | 29 | saltworks: the day-1 principle in its final form — ask what the instrument would say if the th… |
| 08-06 13:19 | `38067f1` | evidence | 39 | saltworks: the purge is a force-push and it dangles every salt SHA we cite — scope measured, a… |
| 08-06 13:22 | `832e220` | evidence | 50 | saltworks: the detector could not tell a held lock from a deadlocked one — fixed, and verified… |
| 08-06 13:22 | `a513489` | compiler (leg 2) | 101 | saltworks: dense SSA form — the precondition that makes emitN's net translation the IDENTITY, … |
| 08-06 13:23 | `679e60c` | silicon (leg 3) | 20 | saltworks: the seam module is MATHLIB-FREE — 8,581 jobs to 3 (compiler seat's unblock) |
| 08-06 13:24 | `5d66aaa` | evidence | 10 | saltworks: my detector told people to rmdir a lock — math nearly proved that advice dangerous … |
| 08-06 13:25 | `bb987de` | evidence | 33 | saltworks: the deadlock's real trigger was an in-place edit, not a hard kill — and the exit ta… |
| 08-06 13:58 | `cf05757` | evidence | 30 | saltworks: five README slots filled from landed artifacts — the chain diagram now cites commit… |
| 08-06 14:01 | `1bef849` | evidence | 16 | saltworks: my memory metric understated available RAM by 28 GB — free is not available on macOS |
| 08-06 14:06 | `70e1ca1` | silicon (leg 3) | 192 | saltworks: D4 — THE FABRIC ROUTES, kernel-checked, at PARTIAL LOAD |
| 08-06 14:07 | `08f7151` | evidence | 2 | saltworks: D4 lands — and a green tick from #audit_axioms is not evidence the theorem exists |
| 08-06 14:30 | `e3ea8f1` | evidence | 15 | saltworks: third copy of the free-vs-available defect, and the README now says the audit canno… |
| 08-06 15:50 | `aa2b75d` | evidence | 448 | saltworks: the Mini falsified my swap threshold in two minutes — free is space in a file macOS… |
| 08-06 15:57 | `52b963e` | evidence | 645 | saltworks: a commit is made BY a session — so a commit with no session near it is a hole in th… |
| 08-06 16:00 | `f63dea3` | evidence | 190 | saltworks: the (* keep *)-through-TT-CI experiment, pre-registered — the readout is the CONE C… |
| 08-06 16:04 | `6a2b695` | evidence | 315 | saltworks: two defects that each hid the other — a bus parser blind to 26% of posts, and a thr… |
| 08-06 16:08 | `8ebedf4` | silicon (leg 3) | 854 | saltworks: D5 — the TT tree is assembled, validated and SIMULATED, and the validator caught it… |
| 08-06 16:18 | `ff8e17d` | silicon (leg 3) | 230 | saltworks: the (* keep *) A/B is run — 100% per-cone certifiable — and the readout it was goin… |
| 08-06 16:23 | `2723c40` | silicon (leg 3) | 299 | saltworks: E1 refutes my own 14:04 claim — #audit_axioms is sound, and the README carries my e… |
| 08-06 16:26 | `7f56714` | silicon (leg 3) | 82 | saltworks: the gate-level path is exercised — 3/3, 255/255 against real sky130 cells, and it d… |
| 08-06 16:36 | `8c4f8d7` | compiler (leg 2) | 432 | saltworks: T2 lands — emitN_sem by a four-case induction, and every conjunct of the emission p… |
| 08-06 16:36 | `aa40fcc` | silicon (leg 3) | 25 | saltworks: the PDK-revision worry closes by measurement — 4,868 files differ, and none of them… |
| 08-06 16:50 | `c2993bf` | maestro (hub) | 2 | saltworks: hub sweep — the two owed imports land (Silicon.Equiv.FabricRoutes = D4, HDL.EmitN ⊃… |
| 08-06 16:52 | `b5bc1dd` | maestro (hub) | 1 | saltworks: hub — Dense made explicit (was transitive via EmitN; explicit per compiler's owed l… |
| 08-06 17:11 | `27d8867` | silicon (leg 3) | 52 | saltworks: D4 is chunked — 18.2 -> 13.9 GiB and the cap threshold drops a rung, but NOT to 12 … |
| 08-06 17:13 | `128956e` | evidence | 36 | saltworks: I pull the README's leading axiom-posture sentence — silicon refuted their own find… |
| 08-06 17:14 | `bfaa67c` | evidence | 242 | saltworks: ledger refresh — 109 commits, 3,407 .lean lines; the migration hole is still open a… |
| 08-06 17:17 | `1e08eeb` | evidence | 45 | saltworks: scoreboard sweep — LEG 2 IS COMPLETE (T2 lands), the hub debt is paid, the -M cap i… |
| 08-06 17:21 | `41a2dcd` | evidence | 81 | saltworks: the bus is in NO git repo, has NO remote and had ONE copy — 474,676 bytes of the ca… |
| 08-06 17:23 | `362e95e` | evidence | 51 | saltworks: pre-registration ADDENDUM 2 — a hole in the middle of the record, and UNBLOCKING is… |
| 08-06 17:32 | `c91faf3` | silicon (leg 3) | 34 | saltworks: the TT validator's mutation suite tested fewer things than it claimed — two mutants… |
| 08-06 18:00 | `c34c180` | compiler (leg 2) | 23 | saltworks: the 24-bit kernel ceiling is now MEASURED, not asserted — and it is inclusive at 1<… |
| 08-06 18:08 | `5c3a55f` | evidence | 71 | saltworks: bus archive into the private seat repo, with the lane check re-run every push — and… |
| 08-06 18:10 | `48e2e75` | evidence | 34 | saltworks: my lane gate blocked the post announcing my lane gate — and the fix tripped it agai… |
| 08-06 18:17 | `1b8f8de` | compiler (leg 2) | 89 | saltworks: the densifying renumber is scoped — and the reason it is unwritten is that the bit-… |
| 08-06 18:23 | `e1a1a3b` | silicon (leg 3) | 108 | saltworks: the first TT CI run failed on a pin 60 um outside the die, and the cause was sixtee… |
| 08-06 18:25 | `15b6c9e` | compiler (leg 2) | 10 | saltworks: #audit_axioms is a WHITELIST — one leg-2 theorem was never listed, and it was cover… |
| 08-06 18:30 | `2f302c0` | silicon (leg 3) | 5 | saltworks: every theorem in the Silicon leg is now named in an audit line — 31/41 before, 41/4… |
| 08-06 18:38 | `de689b8` | silicon (leg 3) | 76 | saltworks: ruling 4a closes YES on the fabricated artifact — (* keep *) survives TT's CI and t… |
| 08-06 18:43 | `2d5f747` | compiler (leg 2) | 23 | saltworks: three warnings I read past all day were pointing at two unnecessary hypotheses — pi… |
| 08-06 18:43 | `248f725` | silicon (leg 3) | 13 | saltworks: the datasheet carries the three rates, with hold slack as the one that matters |
| 08-06 18:45 | `a2155d5` | evidence | 290 | saltworks: post-wave ledger (124 commits) + compiler's marker taxonomy adopted in full — and w… |
| 08-06 18:47 | `406ea5a` | evidence | 34 | saltworks: a lane BASELINE, not an override — adjudicated hits stop re-flagging, new marker te… |
| 08-06 18:48 | `8b3246b` | evidence | 39 | saltworks: the day folded in — ruling 4a closes YES on the fabricated netlist, and the pre-reg… |
| 08-06 18:49 | `f4ebd20` | silicon (leg 3) | 116 | saltworks: the column experiment's acceptance-test instrument, and the finding that decides ho… |
| 08-06 18:50 | `030d72e` | evidence | 35 | saltworks: the README's epistemology section gains the two rules the day bought — fix the read… |
| 08-06 19:07 | `5be7db2` | maestro (hub) | 15 | saltworks: the build path finally has a memory backstop — and it is weakLeanArgs, not moreLean… |
| 08-06 19:07 | `325e255` | silicon (leg 3) | 17 | README: fix three claims that were false in this repo |
| 08-06 19:09 | `0a1e2ab` | evidence | 66 | saltworks: convergent finding #2 — two seats, same selector trap, 90 min apart; and ONE-WAY AC… |
| 08-06 19:15 | `33b2f0e` | evidence | 10 | saltworks: the submission gate is OPEN — GDS green on all four jobs; and the countdown comes o… |
| 08-06 19:16 | `9b205b3` | evidence | 1 | saltworks: the green REPLICATED on HEAD — two fully-green runs on main at two shas, both entir… |
| 08-06 19:19 | `5ff508b` | compiler (leg 2) | 378 | saltworks: the densifying renumber, obligations 1 and 4 — and the one I flagged as most likely… |
| 08-06 19:19 | `c3cf6fa` | evidence | 81 | saltworks: liveness scored against tonight — two signals 300x apart share one threshold, and t… |
| 08-06 19:20 | `2de8a1b` | silicon (leg 3) | 101 | saltworks: silicon's muster brief for 07:00 — results, honest negatives with mechanism, in fli… |
| 08-06 19:23 | `6ebcf45` | silicon (leg 3) | 26 | saltworks: the column picture is closed NO with its mechanism — muster brief updated, nothing … |
| 08-06 19:24 | `ae56c18` | silicon (leg 3) | 29 | saltworks: the local LibreLane config, and the honest note that this path was superseded |
| 08-06 19:24 | `10d12f8` | evidence | 16 | saltworks: a space-separated tag line was silently discarded — the very failure this file's co… |
| 08-06 19:25 | `1a36020` | evidence | 67 | saltworks: pre-registration paid off twice tonight — on a measurement and on a RULING; plus le… |
| 08-06 19:25 | `30794fa` | compiler (leg 2) | 206 | saltworks: the densifying renumber is COMPLETE — all five obligations, and the one predicted "… |
| 08-06 19:29 | `643bb07` | maestro | 29 | saltworks: E1's finding is now pinned in the build — #audit_axioms fails the build if it ever … |
| 08-06 19:31 | `65f00fd` | compiler (leg 2) | 68 | saltworks: wfGates_filter — the load-bearing half of "opt preserves wf", with the three mechan… |
| 08-06 19:33 | `6b7a0d7` | silicon (leg 3) | 40 | saltworks: the muster brief now prices the leg's remaining work against the fabricated netlist |
| 08-06 19:34 | `159f8f4` | compiler (leg 2) | 121 | saltworks: opt_wf lands — the three "mechanical" lemmas took one attempt, and emitPipeline'_se… |
| 08-06 19:34 | `1f42c23` | silicon (leg 3) | 99 | saltworks: the fabricated netlist's cell census and specification — with the rule that keeps t… |
| 08-06 19:41 | `6dbc33f` | evidence | 26 | saltworks: the three blocks tagged (JYH-directed) — one of my own proposals REFUTED, and the r… |
| 08-06 19:42 | `bddcadb` | compiler (leg 2) | 264 | saltworks: the week-2 codegen freeze — and it is FROZEN PENDING AN ADVERSARIAL PASS, because t… |
| 08-06 19:42 | `ff8fce3` | evidence | 68 | saltworks: ADDENDUM 3 — tmux send-keys is a human keystroke to the record and no provenance fi… |
| 08-06 19:43 | `38fc8e6` | compiler (leg 2) | 37 | saltworks: the freeze's own kill-check R4 had no referent — the compilation scheme is now writ… |
| 08-06 19:46 | `7c8e313` | evidence | 57 | saltworks: I patched one monitor defect three times because the bug was the MODEL, not the reg… |
| 08-06 19:51 | `9792baa` | evidence | 126 | saltworks: the muster RESULTS LEDGER — every count generated, every kernel verdict attributed … |
| 08-06 19:52 | `4e40547` | compiler (leg 2) | 96 | saltworks: the compiler seat's muster line as a FILE — including the coverage fact that makes … |
| 08-06 19:53 | `53c1936` | evidence | 13 | saltworks: my own muster ledger said the default build covers all three legs — compiler's cove… |
| 08-06 19:53 | `f86fbb0` | compiler (leg 2) | 10 | saltworks: my muster count had no window, and the Captain will read it beside a ledger that co… |
| 08-06 19:54 | `ae90e5a` | evidence | 19 | saltworks: two seats recomputed the numbers I attributed to them — both deltas published, and … |
| 08-06 19:55 | `05560cd` | evidence | 2 | saltworks: silicon's '11 lines of noise' is two exact differences that cancel — additions-on-o… |
| 08-06 19:56 | `739a60c` | evidence | 24 | saltworks: a generated table stops being generated the moment it is pasted — compiler went 23 … |
| 08-06 19:58 | `d14563e` | evidence | 61 | saltworks: the day's principle in the form that survived — a true reading of an ADJACENT objec… |
| 08-06 20:01 | `af7ab88` | evidence | 26 | saltworks: the tags are RATIFIED (JYH, 20:01) — with what was ratified, what was not, and the … |
| 08-06 20:08 | `fb3374f` | compiler (leg 2) | 40 | saltworks: the refuter pass found a fourth partiality I had not imagined and the x0 trap on th… |
| 08-06 20:10 | `380224d` | compiler (leg 2) | 8 | saltworks: the ISA manual advises against the exact trick §4.1 is built on — recorded as an id… |
| 08-06 20:22 | `1683194` | evidence | 338 | saltworks: nightly re-run after the attempted transcript sync — 163 commits, and §0 still flag… |
| 08-06 20:27 | `e54edf3` | silicon (leg 3) | 30 | saltworks: the importer stops keying on drive strength — 8 of the 32 missing cells were never … |
| 08-06 20:29 | `f980049` | evidence | 24 | saltworks: three identical 'Permission denied' strings, three unrelated causes — the adjacent-… |
| 08-06 20:31 | `a365a5d` | compiler (leg 2) | 452 | saltworks: the freeze's source language was over Int and the machine is BitVec 32 — C3 was sta… |
| 08-06 20:37 | `cad38dc` | silicon (leg 3) | 270 | saltworks: 30 cell models proved and audited, 21 expansions landed — and the real blocker was … |
| 08-06 20:39 | `f0ced92` | silicon (leg 3) | 29 | saltworks: muster brief carries the executed census spec and the refuter pass |
| 08-06 20:41 | `9aab66c` | evidence | 186 | saltworks: the 20:40 §0 verdict — 169 commits, hole STILL OPEN at e3ea8f1, and the transcript … |
| 08-06 20:44 | `b0a5152` | evidence | 159 | saltworks: the migration hole is now PROBABLY PERMANENT — a laptop-side push bypasses every au… |
| 08-06 20:45 | `a41ed3a` | compiler (leg 2) | 685 | saltworks: the freeze's far side EXISTS — Instr, St, step, encode, decode, and decode(encode i… |
| 08-06 20:49 | `83bf20b` | compiler (leg 2) | 109 | saltworks: '31 declarations outside the default build' was wrong — the number is 12, and the m… |
| 08-06 20:49 | `b9209ed` | compiler (leg 2) | 26 | saltworks: muster refreshed — the freeze's blocking reason changed twice tonight and §4 still … |
| 08-06 20:49 | `a69fee0` | docs (shared) | 98 | saltworks: THE VERIFIED CPU campaign freeze v0 — RV32I entire, on the proven chain; refuter pa… |
| 08-06 20:54 | `cc401c9` | maestro (hub) | 1,137 | saltworks: the flop treatment — Q-pins as leaves, D-pins as roots; the FABRICATED netlist now … |
| 08-06 20:56 | `1f14fe9` | compiler (leg 2) | 285 | saltworks: C3 IS STATEABLE — written out against the landed ISA, and the certificates caught m… |
| 08-06 20:58 | `8e19cfd` | evidence | 82 | saltworks: import-closure gets a three-way exit so the gate cannot open when it cannot read — … |
| 08-06 20:58 | `097b41e` | maestro (hub) | 2 | saltworks: hub sweep — ISA + Renumber into the closure (compiler's import-closure.py finding: … |
| 08-06 21:00 | `7e6262a` | evidence | 183 | saltworks: I retract 'probably permanent' — the laptop was asleep, so the push never ran, and … |
| 08-06 21:01 | `f5b6e83` | maestro (hub) | 837 | saltworks: --cut at the kept boundaries — every cone in the fabricated netlist is now inside t… |
| 08-06 21:02 | `46e4d14` | evidence | 23 | saltworks: two new axes in the final hour — TIME (reachability) and CUT SET (a treatment-insen… |
| 08-06 21:03 | `e153b23` | evidence | 118 | saltworks: close-of-board ledger — the state the muster reads |
| 08-06 21:08 | `17a7911` | maestro (hub) | 22 | saltworks: the memory cap was already installed — and re-verifying it broke the fleet's cap-hi… |
| 08-06 21:18 | `f184289` | evidence | 327 | saltworks: the send-keys detector ADDENDUM 3 owed — 32 of 2,171 human touches were machine-tra… |
| 08-06 21:34 | `58e68a8` | silicon (leg 3) | 7 | saltworks: muster correction — "42 liberty theorems" is not a count of anything; it is 44 over… |
| 08-06 21:40 | `d618178` | silicon (leg 3) | 153 | saltworks: C0 seam census, SILICON HALF — two findings on C4's headline, one of them measured |
| 08-06 21:51 | `6263b41` | docs (shared) | 29 | saltworks: campaign freeze v0.1 — C4 restated type-correct (silicon's F2: v0's headline did no… |
| 08-06 21:51 | `7e9f6a3` | silicon (leg 3) | 17,983 | saltworks: R3 answered — the regfile FAILS the per-cone law, and finding that out exposed two … |
| 08-06 21:55 | `28db1e5` | maestro (hub) | 1,626 | saltworks: R2 answered — the slice obligation is landed and proved; the SYNTHESISED netlist do… |
| 08-06 21:58 | `6c3fb56` | compiler (leg 2) | 217 | saltworks: my own cap-hit widening is REFUTED — M-2 ratified in its place, and the directive I… |
| 08-06 22:01 | `7090b9f` | silicon (leg 3) | 425 | saltworks: --check exists — the readback the docstring claimed for weeks, and it is not a mirr… |
| 08-06 22:03 | `058eda8` | silicon (leg 3) | 54 | saltworks: muster carries the night shift — six landings, three of them kill-checks |
| 08-06 22:06 | `cd28c67` | compiler (leg 2) | 45 | saltworks: my muster's commit count disagreed with its own table — 19 vs 18 rows vs 23 actual |
| 08-06 22:54 | `a4e13e1` | maestro (hub) | 25 | saltworks: -M is a checkpoint budget — verified, and the ALARMING half of my own claim is dead |
| 08-06 23:00 | `91e23d1` | compiler (leg 2) | 22 | saltworks: closing muster addendum — count regenerated 26 -> 29, section 4 closed |
| 08-06 23:04 | `15e4890` | compiler (leg 2) | 24 | saltworks: queue the concurrency measurement as the next session's first item |
| 08-07 06:00 | `82155b2` | silicon (leg 3) | 10 | saltworks: muster §4 corrected — the LibreLane run resolved, and the harness called a failure … |
| 08-07 06:29 | `d399a39` | silicon (leg 3) | 649 | saltworks: C3 probe, silicon's half — TT CI ACCEPTS structural gate-level input and the slice … |
| 08-07 06:43 | `d217eef` | silicon (leg 3) | 49,126 | saltworks: the read path attacked — solvable at full RV32I under option (A), every cone 11 inp… |
| 08-07 06:48 | `60f04b7` | silicon (leg 3) | 8,968 | saltworks: the emitter change PRICED — zero trust, zero proof, 40% of the read path, measured |
| 08-07 06:52 | `6de1833` | compiler (leg 2) | 132 | saltworks: the concurrency measurement JYH ordered — mechanism confirmed, alarming number dead |
| 08-07 06:55 | `811fe37` | compiler (leg 2) | 303 | saltworks: the mux2_1 peephole — implemented in emitS, not emitV, because the oracle is struct… |
| 08-07 06:56 | `32218ca` | silicon (leg 3) | 7,273 | saltworks: the writeback path measured — it needs NOTHING, and the read/write asymmetry is str… |
| 08-07 06:57 | `970ad6c` | compiler (leg 2) | 17 | saltworks: EmitS had ZERO audit sites — the iron rule says every definition, and I shipped it … |
| 08-07 07:01 | `2d5d063` | compiler (leg 2) | 170 | saltworks: C3 probe verdict — (A) PASSES, and the council's fallback does not exist |
| 08-07 07:03 | `5530a77` | silicon (leg 3) | 13,072 | saltworks: the RV32I ALU measured — 4 cut families, max cone 20, and flags need a tree the reg… |
| 08-07 07:08 | `55602bf` | silicon (leg 3) | 2,376 | saltworks: the control path measured, and the four-block survey yields a RULE for where option… |
| 08-07 07:10 | `7350e37` | compiler (leg 2) | 183 | saltworks: the read tree as a Circ — the emitter reproduces silicon's oracle EXACTLY, 2981 -> … |
| 08-07 07:13 | `6f60944` | silicon (leg 3) | 1,265 | saltworks: the memory interface REFUTED my own rule, and the corrected rule is quantitative |
| 08-07 07:13 | `4c1e946` | silicon (leg 3) | 10 | saltworks: survey doc made coherent after the fifth block — title, count (3 of 5), and the mem… |
| 08-07 07:18 | `f16d7ce` | silicon (leg 3) | 3,601 | saltworks: the fetch path — no new mechanism, the worst keep bypass yet, and a diagnostic erro… |
| 08-07 07:19 | `6965ee5` | compiler (leg 2) | 55 | saltworks: readTree x0 leaf fixed — 31 stored registers and a tie cell, cone 37 -> 36 |
| 08-07 07:22 | `ff003df` | silicon (leg 3) | 2,398 | saltworks: the branch path — no new mechanism, and a reduction that is TWICE as wide as the AL… |
| 08-07 07:23 | `2e89d77` | compiler (leg 2) | 203 | saltworks: emitter obligation 1 — adder and incrementer with named per-slice carries |
| 08-07 07:27 | `5dd0a41` | compiler (leg 2) | 156 | saltworks: emitter obligation 2 — barrel shifter as a LOG shifter, 6.2x cheaper than the assum… |
| 08-07 07:27 | `e4b3128` | silicon (leg 3) | 11,693 | saltworks: the CSR path priced for R5 — cheaper than an exclusion would suggest, and a fifth k… |
| 08-07 07:29 | `3de705c` | compiler (leg 2) | 210 | saltworks: emitter obligations 3 and 5 — op-select and flag reduction, both treed and named |
| 08-07 07:32 | `ac8a43e` | silicon (leg 3) | 654 | saltworks: the trap path priced for R5 — mostly free, one priority encoder, and a SIXTH keep b… |
| 08-07 07:35 | `16a58c4` | silicon (leg 3) | 1,206 | saltworks: pipeline hazards priced — cheap, no new mechanism, and C3 HAS NONE |
| 08-07 07:36 | `89dc864` | compiler (leg 2) | 190 | saltworks: the interrupt priority encoder — a chain plus a reduction, and I walked into the ru… |
| 08-07 08:26 | `61f375a` | maestro (hub) | 7 | saltworks: hub sweep — the seven emitter-harvest modules into the closure (Adder, Shifter, Pri… |
| 08-07 08:27 | `1831725` | silicon (leg 3) | 87 | saltworks: C3 PROBE — FORMAL VERDICT, silicon half: option (A) is VIABLE on the flow side |
| 08-07 08:29 | `466b224` | evidence | 51 | saltworks: provenance re-tag — the tagging ORDER was a bare maestro injection; the RATIFICATIO… |
| 08-07 08:30 | `0e3941c` | silicon (leg 3) | 34,358 | saltworks: THE CORE assembled at scale — 5,054 cells, and the RTL route does NOT close |
| 08-07 08:31 | `3538112` | compiler (leg 2) | 142 | saltworks: C2 vector-generator DESIGN — and the witness the ruling names does not exist on thi… |
| 08-07 08:32 | `387c8d5` | evidence | 120 | saltworks: META-TIME designed and NOT measured — the cited council ruling 7 does not exist in … |
| 08-07 09:04 | `e0c8e25` | evidence | 27 | saltworks: the META-TIME authority is REAL and stronger than my fallback — Captain-in-channel … |
| 08-07 09:07 | `04927b5` | docs (shared) | 67 | saltworks: THE STACK CAMPAIGN v0 — agent→verified code→verified compiler→[executive]→verified … |
| 08-07 09:09 | `0236c15` | compiler (leg 2) | 178 | saltworks: C2 vector consumer + the cost measurement the design demanded — and my first harnes… |
| 08-07 09:09 | `0ec9f4f` | evidence | 140 | saltworks: refuting stack-campaign-v0 — R2 is answered not suspected (St has no memory), the 1… |
| 08-07 09:11 | `faf361b` | silicon (leg 3) | 84 | saltworks: AT-SCALE boundary survival — structural emission HOLDS; 100% instance survival at 2… |
| 08-07 09:12 | `a9e425f` | evidence | 45 | saltworks: R1 does NOT survive — no branch-free select in Slice A, so the code is data-depende… |
| 08-07 09:13 | `1304352` | compiler (leg 2) | 29 | saltworks: manifestCuts — my .cuts manifest named EVERY gate, so silicon's cone census was tru… |
| 08-07 09:15 | `4e6cb69` | evidence | 28 | saltworks: the missing primitive is exactly ONE (AND) — my chain was a step too long and my co… |
| 08-07 09:24 | `eaa19e7` | docs (shared) | 110 | saltworks: THE STACK STORY — pre-registered narrative spine (claim as target, bracketed number… |
| 08-07 09:26 | `9022544` | evidence | 60 | saltworks: the [R]/[C] split folded in before data — an orthogonal axis, mechanically defined … |
| 08-07 09:28 | `1051049` | evidence | 31 | saltworks: [R] refined before data — a seat's self-deferral is not an ask; the test is who cou… |
| 08-07 09:32 | `2358ab8` | evidence | 2 | saltworks: two more axes — a throughput number that measured SHARING not checking, and 10 vect… |
| 08-07 09:34 | `768ce11` | silicon (leg 3) | 1,153 | saltworks: the structural monolith at ~5k cells — 100% of LIVE boundaries survive; my own last… |
| 08-07 09:35 | `73c99f9` | evidence | 59 | saltworks: the three uncovered tools gain coverage — dedup, category abort, lane totality; 91 … |
| 08-07 09:36 | `ba49551` | compiler (leg 2) | 6 | saltworks: inc32 emitted a dead top carry — one of silicon's four dropped cells was mine, not … |
| 08-07 09:40 | `e4a5174` | docs (shared) | 11 | saltworks: C3 FINALIZED — the campaign freeze goes v1: structural gate-level emission ratified… |
| 08-07 09:44 | `edc4a5f` | docs (shared) | 555 | saltworks: STACK-S1 — the sortedness/permutation spec over machine words (signed order) |
| 08-07 09:46 | `cc16f4c` | docs (shared) | 534 | saltworks: STACK-S3(a) — the 0-1 principle, and Batcher's network sorts |
| 08-07 09:57 | `a00b651` | compiler (leg 2) | 676 | saltworks: C2 has a real witness at last — step agrees with Spike on 120 kernel-checked vector… |
| 08-07 10:00 | `e71e9a3` | compiler (leg 2) | 32 | saltworks: the witness found the hole it was hired to find — XOR was the one Slice A instructi… |
| 08-07 10:07 | `9263e19` | compiler (leg 2) | 220 | saltworks: the C2 generator's design record, and the cost ceiling re-measured because the old … |
| 08-07 10:13 | `938b0e7` | maestro (hub) | 13 | saltworks: hub +4 (Vectors, SpikeVectors, Stack.Spec, Stack.ZeroOne — C2's witness and the STA… |
| 08-07 10:14 | `b2807a3` | silicon (leg 3) | 65 | saltworks: cone-width census on the 5,266-cell monolith — 151 obligations, max 24, median 3; a… |
| 08-07 10:17 | `f87e78e` | compiler (leg 2) | 196 | saltworks: ruling 3's second witness answers — SAIL agrees with all 120 landed vectors, and th… |
| 08-07 10:21 | `9b96faa` | compiler (leg 2) | 171 | saltworks: C4 composition-check — it elaborates, and the one seam that does not close is a spe… |
| 08-07 10:33 | `c6b3119` | docs (shared) | 70 | saltworks: BB-1 — THE COMPOSED SWITCH addendum (Batcher joins the banyan on one tile; the sort… |
| 08-07 10:38 | `8078ec8` | silicon (leg 3) | 242 | saltworks: BB-1 B0(b)+(c) — the seam composition-checked (a fourth obligation nobody priced) a… |
| 08-07 10:41 | `d762dbc` | compiler (leg 2) | 359 | saltworks: BB-1 B0(a) — the bit-serial compare-exchange element in Circ, and idle-sorts-high i… |
| 08-07 10:46 | `7838374` | evidence | 20 | saltworks: SUBMITTED — and the verb moves only half a step; submitted is not accepted, and thi… |
| 08-07 10:47 | `18a7ef6` | compiler (leg 2) | 265 | saltworks: C2's rejection arm — the gap I named as "not mine to close" was mine, and class B i… |
| 08-07 10:47 | `0e98030` | docs (shared) | 19 | saltworks: BB-1 addendum — KB1 closed by CROSSING refutations (evidence's two-conjunct read + … |
| 08-07 10:49 | `9f167e6` | maestro (hub) | 1 | saltworks: carrying the maestro's CompareExchange hub import, verified green before landing so… |
| 08-07 10:51 | `5c9b210` | evidence | 31 | saltworks: day 2 folded in — four campaign facts, each carrying whether this seat verified it … |
| 08-07 10:51 | `e30fb22` | docs (shared) | 634 | saltworks: STACK-S3(a)-2 — comparator networks permute (one proof, two lanes) |
| 08-07 10:56 | `a1d8c1e` | compiler (leg 2) | 83 | saltworks: C4's partiality fork priced — all three options elaborate, so the choice is a speci… |
| 08-07 11:07 | `e2e62ee` | evidence | 60 | saltworks: the META-TIME column instrumented with its definition FROZEN and pinned by tests — … |
| 08-07 11:07 | `07f6040` | compiler (leg 2) | 52 | saltworks: C4 §5 resolved — it should compose with emitPipeline'_sem, and route A talks about … |
| 08-07 11:20 | `945b1bc` | maestro (hub) | 1 | saltworks: freeze v1.1 — C4 adopts Route B (the theorem about the netlist that tapes out; wf b… |
| 08-07 11:21 | `a3d4471` | docs (shared) | 15 | saltworks: freeze v1.1 (repair) — C4 Route B adopted + the partiality draft ruling (option 1, … |
| 08-07 11:24 | `34b65dd` | compiler (leg 2) | 90 | saltworks: stepT lands against the v1.1 ruling — and defining it AS stepW-with-a-default makes… |
| 08-07 11:25 | `dfb7ef8` | evidence | 1 | saltworks: the fourteenth axis — DOMAIN OF THE CLAIM; total coverage is not conformance, and 9… |
| 08-07 11:31 | `1d62a71` | compiler (leg 2) | 165 | saltworks: C4's two missing coercions land — and fixing the layout FIRST is the point, not a s… |
| 08-07 11:41 | `db3e26a` | docs (shared) | 8 | saltworks: the partiality ruling is CAPTAIN-RATIFIED (option 1) with the claim fence at eviden… |
| 08-07 11:44 | `e85b7c1` | evidence | 10 | saltworks: shuttle dates read at source — close and delivery confirmed exactly, 2027-03-27 mar… |
| 08-07 11:45 | `c1f8c8e` | compiler (leg 2) | 207 | saltworks: core's decoder in Circ — and the certificate is small because the projection is sta… |
| 08-07 11:46 | `7b2cab4` | silicon (leg 3) | 390 | saltworks: BB-1 B1 — the compare-exchange element REFINED AT THE GATES, and B0(d) closed |
| 08-07 11:50 | `3a7037e` | compiler (leg 2) | 144 | saltworks: core's write-enable decoder — P5 stops being a theorem about St.set and becomes a g… |
| 08-07 11:53 | `9b5aeef` | evidence | 28 | saltworks: day-2 catches folded (the noun, authorship, convergent finding #3) + the MATH LANE … |
| 08-07 11:54 | `ae70384` | maestro (hub) | 4 | saltworks: hub +4 — the core's organs (Decoder, RegWrite, StateCodec) and the STACK's Bridge i… |
| 08-07 11:56 | `4f63118` | docs (shared) | 554 | saltworks: STACK-B2M — the StrictMonoOn bridge (sorted ∧ distinct ⇒ the banyan's hypothesis) |
| 08-07 11:56 | `0114e70` | compiler (leg 2) | 166 | saltworks: core's immediate extraction — the block with almost no gates and most of the risk, … |
| 08-07 11:57 | `0dbb854` | docs (shared) | 11 | saltworks: STACK-B2M addendum — the import is no longer owed (ae70384 landed the hub line), an… |
| 08-07 11:59 | `5e66a84` | silicon (leg 3) | 96 | saltworks: BB-1 B2 seam — the hardware bridge's mask machinery proved, the last step named, an… |
| 08-07 12:02 | `1e62916` | evidence | 22 | saltworks: the stale-board mode folded, verified at both time points — and it is a THIRD defec… |
| 08-07 12:04 | `22ea383` | compiler (leg 2) | 209 | saltworks: core's next-state array — and the finding is worth more than the block: a core-size… |
| 08-07 12:08 | `2ee6a9f` | evidence | 107 | saltworks: day-2 muster skeleton — structure only, every number a REGEN marker, because a gene… |
| 08-07 12:09 | `a9bcf08` | silicon (leg 3) | 2,997 | saltworks: BB-1 B2 network assembled at the gates — and my 11:21 area to the Captain was 27% L… |
| 08-07 12:10 | `c88d29a` | compiler (leg 2) | 151 | saltworks: core's assembly needs a combinator the tree does not have — instantiation lands, de… |
| 08-07 12:17 | `540894e` | docs (shared) | 7 | saltworks: BB-1 addendum — the network is BITONIC-24 (the landed batcher8, length kernel-pinne… |
| 08-07 12:18 | `0aa32ae` | compiler (leg 2) | 60 | saltworks: instOK needed ssa, not wf — the defect found by attempting the proof I said the pro… |
| 08-07 12:22 | `2fc95d8` | docs (shared) | 851 | saltworks: S0/R2 — the memory-model census (read-only; the fork priced) |
| 08-07 12:23 | `6783912` | compiler (leg 2) | 53 | saltworks: inst_sem attempted — the route is confirmed and the gap is bookkeeping, and I blew … |
| 08-07 12:25 | `8e4c044` | compiler (leg 2) | 21 | saltworks: math's time-bomb in my lane is real — and it is the good kind, but only because the… |
| 08-07 12:26 | `d422fd8` | maestro (hub) | 3 | saltworks: hub +3 — Immediate, RegNext, Compose (the core's assembly organs) into the closure |
| 08-07 12:29 | `5d44d4f` | compiler (leg 2) | 180 | saltworks: core's pc addend select — an addend mux, not a result mux, which keeps the unproved… |
| 08-07 12:31 | `cee189e` | silicon (leg 3) | 2,127 | saltworks: BB-1 B2 proof half — 10 cell models proved (10 of 10 hand-derivations correct), net… |
| 08-07 12:34 | `5f59399` | docs (shared) | 231 | saltworks: STACK-EQSORT — strictly-increasing lists with the same members are equal (silicon's… |
| 08-07 12:36 | `6e58707` | evidence | 193 | saltworks: the tile-drain series — append-only, refuses a slope below 4 readings, wired into t… |
| 08-07 12:40 | `6757d52` | compiler (leg 2) | 1,592 | saltworks: BB-1 B2 compiler half — the 8x8 network as a Seq, structurally emitted, with the el… |
| 08-07 12:41 | `ca8a7f3` | silicon (leg 3) | 4,221 | saltworks: BB-1 B2 — the network EMITTED STRUCTURALLY through compiler's emitSMux: 100% of LIV… |
| 08-07 12:46 | `b6d56ac` | compiler (leg 2) | 38 | saltworks: opt is NOT a constant folder — I built a design decision on a capability I never ch… |
| 08-07 12:50 | `a145016` | docs (shared) | 9 | saltworks: the memory ruling — census §3.5 adopted verbatim (register-resident S2 now; (A) on … |
| 08-07 12:53 | `e20270a` | docs (shared) | 395 | saltworks: C4STMT — the composed statement, elaborated (C1+C3's joint artifact) |
| 08-07 12:55 | `48d767c` | compiler (leg 2) | 172 | saltworks: instrBase pinned on math's C4STMT finding, and option C priced so silicon's open do… |
| 08-07 12:59 | `dfdb25f` | maestro (hub) | 4 | saltworks: hub +4 — BatcherNet(+Check), CompareExchangeC, PcNext into the closure |
| 08-07 12:59 | `1866571` | evidence | 1,158 | saltworks: banking the day-2 ledger run before context reboot — generated, not typed |
| 08-07 13:03 | `38ecaf4` | compiler (leg 2) | 36 | saltworks: inst_sem second run — route settled, one omega short, residue handed over as ordered |
| 08-07 13:04 | `bf2de34` | docs (shared) | 682 | saltworks: STACK-S2 — the program: agent-written bitonic sort in Slice A, register-resident |
| 08-07 13:07 | `a5d2ef7` | docs (shared) | 283 | saltworks: S2 PROVENANCE BUNDLE — the artifact ships with its birth record |
| 08-07 13:09 | `de00db3` | maestro (hub) | 1 | saltworks: hub — Stack.Program (S2, the agent-written sort) into the closure |
| 08-07 13:10 | `cacb172` | compiler (leg 2) | 55 | saltworks: ssa -> wf decomposed rather than attempted — the invariant is the expensive part an… |
| 08-07 13:21 | `574affe` | evidence | 614 | saltworks: the S2 bundle BINDS ITS CONTENTS — verified by replay, and three of its sentences a… |
| 08-07 13:23 | `b4ba3bd` | evidence | 1 | saltworks: drain reading 2 — 202/512, UNCHANGED across 48 minutes |
| 08-07 13:27 | `973a2f7` | docs (shared) | 799 | saltworks: STACK-S3(b) — RefinesNetwork is FALSE (refuted in kernel), and the refinement is PR… |
| 08-07 13:32 | `7012d3d` | silicon (leg 3) | 71 | saltworks: BB-1 B4 — the frame convention adjudicated at the bytes: CONVENTION C, rebuild the … |
| 08-07 13:44 | `f49b5a4` | compiler (leg 2) | 325 | saltworks: C4 ASSEMBLY GATE OPEN — inst_sem PROVED, and ssa -> wf with it |
| 08-07 13:47 | `ade604a` | docs (shared) | 429 | saltworks: STACK-LOADER — the entry point is a RESET, not a loader; the seam stated |
| 08-07 13:51 | `457af25` | compiler (leg 2) | 231 | saltworks: BB-1 — Convention C CERTIFIED, and the price this file quoted was wrong by a bit |
| 08-07 13:56 | `5868b9f` | compiler (leg 2) | 158 | saltworks: C4 — the `++` lemma. Two instances compose; the assembly is no longer gated on theo… |
| 08-07 13:56 | `ef458fb` | docs (shared) | 165 | saltworks: S2 PROVENANCE — three defects in my own bundle, corrected in the open |
| 08-07 14:06 | `2bc6d02` | compiler (leg 2) | 256 | saltworks: BB-1 B2(C) — the 8x8 network on the ratified convention, and the sorter is RUN for … |
| 08-07 14:07 | `f713c1f` | docs (shared) | 136 | saltworks: THE PROVENANCE MANIFEST — the bundle binding is now a MECHANISM, not a claim |
| 08-07 14:09 | `63a0c66` | evidence | 53 | saltworks: the drift I predicted at 13:32 arrived at 14:0x — and it proved my own anchoring wr… |
| 08-07 14:13 | `519f9e5` | compiler (leg 2) | 84 | saltworks: the O(n^2) wall is BROKEN for wf — regNext and readTree certified, measured on both… |
| 08-07 14:17 | `e2da25c` | compiler (leg 2) | 206 | saltworks: C4 — every organ certified instantiable, and aluSelect needs six blocks that do not… |
| 08-07 14:20 | `a97b658` | compiler (leg 2) | 212 | saltworks: C4 — the bitwise block. Four of aluSelect's six missing producers, built and certif… |
| 08-07 14:21 | `b0820b4` | silicon (leg 3) | 5,352 | saltworks: BB-1 B4 (silicon half) — the convention-C sorter hardened, re-imported, and the com… |
| 08-07 14:23 | `8d402bc` | compiler (leg 2) | 142 | saltworks: C4 — slt/sltu land. Every missing BUILD for `core` is now done; one decision remain… |
| 08-07 14:30 | `29d28bd` | silicon (leg 3) | 500 | saltworks: BB-1 B4 — the convention-C element REFINES AT THE GATES; silicon's half of the comp… |
| 08-07 14:35 | `17b20ff` | compiler (leg 2) | 139 | saltworks: BB-1 B4 link ① — the FABRICATED element is the element that was PROVED |
| 08-07 14:37 | `202dd11` | docs (shared) | 665 | saltworks: C5IND — the cycle induction over an abstract per-cycle step |
| 08-07 14:38 | `1e16916` | compiler (leg 2) | 105 | saltworks: BB-1 B4 link ② — two more routing certificates, and the decomposition (the expensiv… |
| 08-07 14:41 | `72ebb7a` | silicon (leg 3) | 75 | saltworks: BB-1 — THE COMPOSED SWITCH IS A THEOREM, conditional on exactly ONE seam |
| 08-07 14:43 | `3bd961c` | compiler (leg 2) | 29 | saltworks: BB-1 link ② — the target is now a Lean statement, and it corrects my own obligation… |
| 08-07 14:46 | `6d6ecb6` | compiler (leg 2) | 158 | saltworks: C4 — THE STATEMENT, written before the proof, with its obligations made falsifiable |
| 08-07 14:48 | `ea1a0dd` | evidence | 1 | saltworks: drain reading 3 — 202/512, third consecutive, and the gate is TIME not count |
| 08-07 14:53 | `af63235` | compiler (leg 2) | 73 | saltworks: the read path READS — a 2,982-gate organ that goes into `core` twice, certified for… |
| 08-07 14:58 | `fcd6a10` | compiler (leg 2) | 106 | saltworks: the behavioural census, closed — aluSelect SELECTS, shifter32 SHIFTS, regNext works… |
| 08-07 14:58 | `f2c56ad` | evidence | 121 | saltworks: REFUTATION — verify.sh returns BOUND from a manifest that checked nothing |
| 08-07 14:59 | `92ed3e7` | maestro (hub) | 1 | saltworks: hub — Silicon.Equiv.ComposedSwitch (BB-1's composed theorem, modulo one seam) into … |
| 08-07 15:01 | `2e6cd29` | compiler (leg 2) | 80 | saltworks: the audit whitelist is COMPLETE — the hole Sem.lean recorded is now checked, not ju… |
| 08-07 15:03 | `740b088` | docs (shared) | 504 | saltworks: C4BRIDGE -- the day C4 is proved, the end-to-end theorem fires with no further work |
| 08-07 15:04 | `8650d64` | evidence | 175 | saltworks: REFUTATION (2) — the crown's census is clean, its four controls are real, and one o… |
| 08-07 15:06 | `ac9fed9` | compiler (leg 2) | 96 | saltworks: two self-corrections — three of my four new modules were invisible to `lake build`,… |
| 08-07 15:08 | `1f19297` | compiler (leg 2) | 19 | saltworks: C4 — the length obligation is IMPLIED by the spec (math's correction to their own b… |
| 08-07 15:11 | `787bb7e` | compiler (leg 2) | 102 | saltworks: link ② is FULL LOAD and forced — obligation (a) restored, plus a model-integrity ch… |
| 08-07 15:12 | `75e8911` | evidence | 229 | saltworks: model_integrity.py — the maestro's downgrade window, independently measured, and th… |
| 08-07 15:12 | `f23a879` | evidence | 2 | saltworks: README — both counts regenerated rather than typed (14 files, 130 checks) |
| 08-07 15:14 | `e4407fb` | compiler (leg 2) | 39 | saltworks: retire my model checker in favour of evidence's — applying to myself the rule I gav… |
| 08-07 15:14 | `9788792` | silicon (leg 3) | 115 | saltworks: the sll/sra ruling — ROUTE 2, and the B4 precedent does NOT transfer |
| 08-07 15:21 | `fcea207` | compiler (leg 2) | 52 | saltworks: route ② accepted — the shifter-mode build brief, recorded where the build happens |
| 08-07 15:22 | `91a2045` | silicon (leg 3) | 96 | saltworks: B5 prep — the revision has TWO open gates, KB4 is answered, and the red job is a so… |
| 08-07 15:26 | `05030c4` | silicon (leg 3) | 81 | saltworks: partial load composition-checked — the banyan was ALWAYS partial-load-capable, and … |
| 08-07 15:40 | `483fa39` | compiler (leg 2) | 120 | saltworks: the reach census — a Lean-side instrument for "what is this theorem ABOUT", with it… |
| 08-07 15:41 | `29d7078` | silicon (leg 3) | 202 | saltworks: P1 CONCENTRATION IS PROVED — the actives are exactly Iio n, for all 256 activity pa… |
| 08-07 15:44 | `d855e9b` | compiler (leg 2) | 74 | saltworks: obligation (a) — the key the convention-C element orders by |
| 08-07 15:45 | `c21359f` | silicon (leg 3) | 144 | saltworks: PARTIAL LOAD CLOSES — the switch routes its actual operating range, with hypotheses… |
| 08-07 15:46 | `d52a9bb` | docs (shared) | 876 | saltworks: C4DECOMP -- the key order owned in math's lane, and C4Spec decomposed fieldwise |
| 08-07 15:47 | `99f170b` | docs (shared) | 26 | saltworks: C4DECOMP addendum -- the count is 61 not 60, and silicon's concurrently-landed cKey… |
| 08-07 15:50 | `1916c44` | compiler (leg 2) | 35 | saltworks: the key-order collision resolved by BRIDGING, not by a third order |
| 08-07 15:50 | `afb5e1f` | silicon (leg 3) | 72 | saltworks: partial load's controls — it BITES at bnCSparse's own pattern, five idle lines shar… |
| 08-07 15:53 | `d103617` | evidence | 120 | saltworks: the PROVEN-vs-BUILT census — the literal class is EMPTY, the behavioural class has … |
| 08-07 15:54 | `ca6c368` | compiler (leg 2) | 68 | saltworks: obligation (b) at the element — the hardware realises the key, and my SPEC was wrong |
| 08-07 15:54 | `c1b2681` | silicon (leg 3) | 24 | saltworks: the address bound VANISHES at the fabricated width — taking math's Dest 3 bridge in… |
| 08-07 15:56 | `b0cff25` | compiler (leg 2) | 31 | saltworks: link ② goes through the Dest 3 door — measured, not preferred |
| 08-07 15:59 | `add505a` | evidence | 31 | saltworks: import-closure counts the LIBRARY, not every tracked .lean — my own inflated number… |
| 08-07 16:00 | `a6d0261` | compiler (leg 2) | 8 | saltworks: the census tool declares itself a non-library metaprogram |
| 08-07 16:03 | `16d4007` | evidence | 32 | saltworks: census filter fix is PARTIAL — the deliverable is stable under all three filters, M… |
| 08-07 16:07 | `c55e6db` | compiler (leg 2) | 64 | saltworks: "No theorem says these circuits add" — now one does, and inc32 too |
| 08-07 16:13 | `b2d078c` | silicon (leg 3) | 48 | saltworks: B5 — the test gate is CLOSED, and both provenance pins are recorded (P8's second ha… |
| 08-07 16:13 | `c418ef3` | compiler (leg 2) | 9 | saltworks: correction — inc32 is UNREFERENCED, and I repeated "on every instruction's path" wi… |
| 08-07 16:14 | `f23cc69` | evidence | 99 | saltworks: THE PROOF-DEBT TABLE — the adder32 class is down to one member, and the debt is 106… |
| 08-07 16:16 | `e3dd724` | evidence | 10 | saltworks: proof-debt table — the largest structural-only block may be a RETIRED design |
| 08-07 16:20 | `aa18fcb` | silicon (leg 3) | 49 | saltworks: B5's CI gate is CLOSED, P8 landed, and a timing surprise that is real but is NOT a … |
| 08-07 16:21 | `d4fe922` | docs (shared) | 527 | saltworks: C4FIELDS — the XOR block bridged to its ISA field for ALL 2^64 pairs (structural, n… |
| 08-07 16:22 | `1c1a02e` | compiler (leg 2) | 33 | saltworks: seam ① is the last gate before the Captain's click — decomposition refreshed to wha… |
| 08-07 16:26 | `c2a2f41` | compiler (leg 2) | 50 | saltworks: the caveat now travels with the name — every sampled certificate is `_on_sample` |
| 08-07 16:35 | `ed3b0a4` | evidence | 12 | saltworks: RETRACTING one row of my own proof-debt table — a sampled certificate is not a proo… |
| 08-07 16:35 | `2ad42fe` | evidence | 14 | saltworks: proof-debt table — tier ①ᵇ (certified only on a sample) added, and inc32 is in it t… |
| 08-07 16:37 | `34927c7` | compiler (leg 2) | 20 | saltworks: the rename applied to the CLASS, not to the set math happened to flag |
| 08-07 16:39 | `139f6f2` | evidence | 31 | saltworks: tier ①ᵇ is the WHOLE DATAPATH, and the census's four positive controls were in it |
| 08-07 16:42 | `b1558ec` | evidence | 19 | saltworks: correcting my own tier ①ᵇ table — I overstated two of four rows, in the alarming di… |
| 08-07 16:44 | `d43c079` | silicon (leg 3) | 200 | saltworks: the README/datasheet arc — f_max from signoff STA, the sourced 1990 line, and the h… |
| 08-07 16:51 | `c8a5bf9` | evidence | 34 | saltworks: §5 — the sampled/exhaustive column is BLOCKED on infrastructure, and three designs … |
| 08-07 16:51 | `fdb4474` | silicon (leg 3) | 42 | saltworks: HALT on the die-pair IMAGE — the bellcore PDFs are GOOGLE-licensed, and item 3 woul… |
| 08-07 17:00 | `4151ac0` | evidence | 16 | saltworks: muster §3 — the firewall halt, and the blocked column, recorded before close |
| 08-07 17:01 | `752675c` | docs (shared) | 703 | saltworks: ADDER32 — sem_adder32 unconditional (all 2^64 pairs), and the SLT sample premises d… |
| 08-07 17:03 | `d49e219` | silicon (leg 3) | 146 | saltworks: the README blocks — heritage in WORDS ONLY per the maestro's ruling, the corrected … |
| 08-07 17:04 | `2367bf6` | evidence | 14 | saltworks: adder32 leaves tier ①ᵇ (verified), and my "inc32 is on every instruction's path" wa… |
| 08-07 17:05 | `6d3726f` | compiler (leg 2) | 58 | saltworks: sem_congr_on — a circuit depends only on what it READS |
| 08-07 17:09 | `7b76b39` | compiler (leg 2) | 49 | saltworks: the seam's fold machinery — and the obvious route times out where the generic one i… |
| 08-07 17:15 | `fe51338` | compiler (leg 2) | 82 | saltworks: seam step ① — the PER-ELEMENT FACTORISATION is proved |
| 08-07 17:20 | `22be176` | evidence | 21 | saltworks: tier ①ᵇ population is KNOWN — regNext8 is sampled and unrenamed, and my own count w… |
| 08-07 17:20 | `6ff6803` | silicon (leg 3) | 267 | saltworks: C5 EXECUTION PLAN, pre-registered — and the core is 22x the largest netlist this ha… |
| 08-07 17:23 | `b292435` | silicon (leg 3) | 47 | saltworks: the elaboration ladder is RUN — the "~1300 gates" law is about a DEFAULT, not a cap… |
| 08-07 17:24 | `20831ec` | compiler (leg 2) | 29 | saltworks: instOuts_range — where an instantiation's PORTS land, and a refinement to the omega… |
| 08-07 17:25 | `bdd197d` | maestro (hub) | 3 | saltworks: hub +4 — Bitwise, C4, SeamC, BatcherNetC into the closure |
| 08-07 17:38 | `530b041` | compiler (leg 2) | 59 | saltworks: seam step ② — hσ discharged, and the omega law gains a third tier |
| 08-07 17:39 | `24bf392` | silicon (leg 3) | 166 | saltworks: the elaboration wall is BROKEN BY RESTRUCTURE, not by the knob — and the harness no… |
| 08-07 17:43 | `ec103b3` | docs (shared) | 930 | saltworks: PCNEXT — sem_pcNext unconditional (all 2^97 inputs), the three pc-field bridges, an… |
| 08-07 17:48 | `2e6fd62` | silicon (leg 3) | 77 | saltworks: C5 plan COMPLETE — the wall data folded in, and it corrects the core's imported SIZ… |
| 08-07 17:49 | `79d107e` | compiler (leg 2) | 42 | saltworks: seam step ② — the dat invariant, and a green I nearly published over a broken file |
| 08-07 17:52 | `cefd93e` | silicon (leg 3) | 138 | saltworks: REFUTATION — nothing adds the PC. The core, as planned, would set pc := 4 every cyc… |
| 08-07 17:56 | `625009b` | compiler (leg 2) | 47 | saltworks: REFUTED — I retired inc32 on a theorem's NAME, and the plan sets pc := 4 forever |
| 08-07 18:00 | `68a67c4` | evidence | 1 | saltworks: drain evening reading — FOUR consecutive 202s, and the binding gate has changed |
| 08-07 18:01 | `89e8462` | compiler (leg 2) | 14 | saltworks: seam step ② is CLOSED — hin was never an obligation |
| 08-07 18:02 | `f4a7078` | silicon (leg 3) | 57 | saltworks: the pc-path correction fixed the ROUTE and broke the CONCLUSION — inc32 is dead for… |
| 08-07 18:04 | `9316ea4` | evidence | 21 | saltworks: inc32 — right conclusion, wrong route, and the bad route nearly reversed the conclu… |
| 08-07 18:06 | `c95b675` | compiler (leg 2) | 49 | saltworks: my correction overshot — inc32 IS dead, architecturally; plus step ③'s per-cycle ha… |
| 08-07 18:13 | `acd7a3f` | silicon (leg 3) | 60 | saltworks: math's pc fix is right about PROOF and wrong about GATES — and the two seats are pr… |
| 08-07 18:14 | `1399ed8` | compiler (leg 2) | 55 | saltworks: step ③'s state bookkeeping — the slices are contiguous, and that is what makes the … |
| 08-07 18:14 | `a5ec60e` | silicon (leg 3) | 21 | saltworks: C5 numbers amended for the pc adder — applying to myself, in the same hour, the cor… |
| 08-07 18:16 | `730bcd7` | silicon (leg 3) | 75 | saltworks: the seam proves bnCCore; the branch carries bnCore — B5's third gate is a RE-EMISSI… |
| 08-07 18:21 | `730f1d2` | compiler (leg 2) | 49 | saltworks: step ③'s vocabulary and the trace target — landed on the second try, after a silent… |
| 08-07 18:23 | `8e6dd5d` | silicon (leg 3) | 130 | saltworks: C5's M6 mutation control, run EARLY — readback refuses a one-gate corruption in the… |
| 08-07 18:33 | `dd0a7e1` | silicon (leg 3) | 58 | saltworks: the pc fix is DESCRIBED but not APPLIED — the assembly plan's section 4 still speci… |
| 08-07 18:34 | `749792d` | compiler (leg 2) | 23 | saltworks: the pc fix applied TO §4, not beside it — a builder following the plan no longer bu… |
| 08-07 18:37 | `cf31ca5` | maestro (hub) | 1 | saltworks: hub — BatcherNetC truly added (BatcherNetCheck's prefix fooled two substring checks… |
| 08-07 18:37 | `0fb2d39` | docs (shared) | 780 | saltworks: PCADD — the pc path ADDS, by composition; sem_pcAdd unconditional over 2^129, and t… |
| 08-07 18:38 | `4baf825` | docs (shared) | 203 | saltworks: PCADD ledger — the plan was fixed under me (organ 13 is pcAdd), and TWO things its … |
| 08-07 18:41 | `7a49446` | compiler (leg 2) | 99 | saltworks: BANKED — the trace induction is the single remaining act, stated where the successo… |
| 08-07 18:42 | `ec21bb5` | other | 743 | saltworks: ALUSEL — sem_aluSelect unconditional over all 2^324 inputs, and the certificate was… |
| 08-07 18:43 | `38c5e93` | docs (shared) | 5 | saltworks: ALUSEL ledger — the full-tree job count restated (8637 pre-PCADD, 8638 at HEAD); th… |
| 08-07 18:56 | `70d8e96` | silicon (leg 3) | 67 | saltworks: route 2 left aluSelect muxing TEN while ONE shifter feeds three of the slots — my o… |
| 08-07 18:56 | `d81801b` | compiler (leg 2) | 32 | saltworks: ALUSEL docstrings corrected AT the tripwires — the predicate is FALSE at 10..15, an… |
| 08-07 18:59 | `83100e5` | docs (shared) | 937 | saltworks: READTREE — sem_readTree unconditional over all 2^997 valuations AND all 32 output b… |
| 08-07 19:04 | `7de0cb8` | compiler (leg 2) | 28 | saltworks: the completeness auditor was itself scope-blind — it read 404 of the repo's 1093 th… |
| 08-07 19:06 | `55f7b22` | compiler (leg 2) | 32 | saltworks: the auditor's README quoted a cached result that was stale in its count AND its sco… |
| 08-07 19:06 | `6c6e1ba` | docs (shared) | 3 | saltworks: LEDGER — scoping three "every theorem is audited" claims that were true of a DIRECT… |
| 08-07 19:07 | `6d9163b` | evidence | 11 | saltworks: muster §3 — the 49 unaudited theorems, and the ruling they are waiting on |
| 08-07 19:09 | `94614fe` | compiler (leg 2) | 52 | saltworks: BACK-PROPAGATING my own AluSelect correction — the identical defect sat in ReadTree… |
| 08-07 19:10 | `4db0410` | silicon (leg 3) | 44 | saltworks: the convention-C critical path — 47 stages, and the combinational ruling's rational… |
| 08-07 19:12 | `500aa93` | compiler (leg 2) | 39 | saltworks: the frame-protocol ruling's two justifying figures are measured false — annotated b… |
| 08-07 19:16 | `aabcd81` | docs (shared) | 885 | saltworks: REGNEXT — the register write path unconditional over 2^1088, and P5 lives one block… |
| 08-07 19:18 | `3522b78` | evidence | 84 | saltworks: THE NIGHTLY — 2026-08-07 muster ledger, every figure regenerated at 19:15 |
| 08-07 19:21 | `df47e94` | compiler (leg 2) | 62 | saltworks: SEAM — the element-indexing induction, which my own bank did not name |
| 08-07 19:23 | `bc26cce` | silicon (leg 3) | 25 | saltworks: C5-5 gets measured content — the sigma-wiring certificate's seed set, from three or… |
| 08-07 19:26 | `cd0610a` | compiler (leg 2) | 89 | saltworks: SEAM — the gate split and the lifted data invariant, and a lesson about reading the… |
| 08-07 19:29 | `8d4d30b` | compiler (leg 2) | 57 | saltworks: SEAM — the low-net frame lemma, the data-net bound at the fold from 0, and the comp… |
| 08-07 19:32 | `50cc6c0` | compiler (leg 2) | 42 | saltworks: SEAM — "for a dense-SSA gate list, ONLY THE INPUT NETS MATTER", stated on its own |
| 08-07 19:42 | `42f6d44` | compiler (leg 2) | 139 | saltworks: SEAM — the two environments MEET; bnC_env_agree is green and it was the hardest glu… |
| 08-07 19:45 | `adaa7cc` | silicon (leg 3) | 134 | saltworks: the B5 checkout brief — H1-H8 are DONE, the click is one button, and the one unreso… |
| 08-07 19:48 | `e4890ce` | evidence | 20 | saltworks: the human-time zero — right conclusion, WRONG MECHANISM, corrected two hours before… |
| 08-07 19:50 | `bef5a46` | compiler (leg 2) | 173 | saltworks: ⭐ THE TRACE INDUCTION IS PROVED — bnC_trace_factors, over ANY initial state and ANY… |
| 08-07 19:51 | `8f9bbda` | maestro (hub) | 1 | saltworks: hub — SeamTrace into the closure |
| 08-07 19:52 | `203250f` | silicon (leg 3) | 90 | saltworks: a sigma with a catch-all else silently absorbs any input its organ later gains, and… |
| 08-07 19:52 | `4538e9e` | compiler (leg 2) | 42 | saltworks: SEAM — the discharge scoped AT THE BYTES before anyone attempts it, and it has two … |
| 08-07 20:01 | `744a120` | silicon (leg 3) | 54 | saltworks: my shifter ruling never asked whether the ISA HAS a shift — math is right, verified… |
| 08-07 20:04 | `b26718e` | compiler (leg 2) | 43 | saltworks: bnCSigma's catch-all is gone — the state inputs now map ARITHMETICALLY, so injectiv… |
| 08-07 20:05 | `6511dd6` | compiler (leg 2) | 45 | saltworks: the plan's "blocked on ONE SHIFTER DECISION" was wrong — slice A never selects the … |
| 08-07 20:08 | `2b40e44` | compiler (leg 2) | 71 | saltworks: my correction rewrote the sentence and carried its false clause through — TWO block… |
| 08-07 20:13 | `24e7a85` | compiler (leg 2) | 34 | saltworks: SEAM — the discharge needs a SECOND induction the size of the first, and my bank un… |
| 08-07 20:14 | `bf5b59f` | compiler (leg 2) | 37 | saltworks: the encoded ALU select bought cone width and posted the bill outside the organ — th… |
| 08-07 20:18 | `1a1570a` | compiler (leg 2) | 66 | saltworks: SEAM — the discharge's data-path skeleton, and the point where it STOPS being symme… |
| 08-07 20:20 | `fb3fa0a` | compiler (leg 2) | 32 | saltworks: regNext8_correct is a NINE-POINT sample at the wrong size, and its name says "corre… |
| 08-07 20:23 | `5adf42f` | compiler (leg 2) | 38 | saltworks: SEAM — the per-cycle DATA lemma, and bnCBuild_state_sem's name is narrower than its… |
| 08-07 20:25 | `a822b65` | compiler (leg 2) | 59 | saltworks: ⭐ SEAM — element e's whole OUTPUT FRAME in the network IS the standalone ceC's; bot… |
| 08-07 20:30 | `baa7e0f` | other | 471 | saltworks: IMM-UNCOND — both immediate extractors, unconditional over all 2^32 words |
| 08-07 20:34 | `b6776e9` | compiler (leg 2) | 71 | saltworks: SEAM — the fold's step from the BACK (bnCDatAt_succ), and the applyComp-shaped read… |
| 08-07 20:39 | `c1e5d7d` | evidence | 82 | saltworks: EVIDENCE night bank — the owed items with their owners, and how I was wrong today |
| 08-07 20:40 | `041cae9` | evidence | 1 | saltworks: bank — striking regNext8_correct from OWED, and pinning what "closed" means |
| 08-07 20:43 | `afcddbe` | compiler (leg 2) | 54 | saltworks: bnCDatStep_getD SOLVED on the fourth attempt — by a tactic finding math posted nine… |
| 08-07 20:46 | `0368c2c` | compiler (leg 2) | 28 | saltworks: the seam's factorisation never needed `st.length = 96` — a linter warning turned ou… |
| 08-07 20:49 | `e3ff06f` | compiler (leg 2) | 22 | saltworks: the seam module's own handoff had gone stale — three finished steps followed by tex… |
| 08-07 20:52 | `79bb72a` | silicon (leg 3) | 133 | saltworks: aluSelect's cost is a STEP FUNCTION on the doubling, not a per-source slope — the n… |
| 08-07 20:54 | `04c9db6` | compiler (leg 2) | 35 | saltworks: the aluSelect sizing is no longer unpriced — silicon measured it, and the quantity … |
| 08-07 20:55 | `f405524` | compiler (leg 2) | 28 | saltworks: SEAM — the network's EIGHT OUTPUT WIRES named, which is what hseam's `hw` reads |
| 08-07 20:56 | `3b3551b` | silicon (leg 3) | 122 | saltworks: PRE-REGISTERED refutation checks for DECODER-UNCOND, published before it lands |
| 08-07 20:58 | `f287785` | silicon (leg 3) | 23 | saltworks: C-D4 correction — 17 dead inverters, not 15, and the two I missed are dead for an I… |
| 08-07 21:03 | `190176e` | silicon (leg 3) | 170 | saltworks: REFUTATION VERDICT on IMM-UNCOND (baa7e0f) — NOT CLEAN, four findings, and not one … |
| 08-07 21:03 | `5aab9d4` | compiler (leg 2) | 43 | saltworks: the andChain empty-list hazard is now a THEOREM, and the invariant that closes it s… |
| 08-07 21:08 | `e43d0aa` | compiler (leg 2) | 1 | saltworks: my own auditor caught my own gap — bnCSigma_state and _injective were never on an #… |
| 08-07 21:08 | `81d34ba` | silicon (leg 3) | 102 | saltworks: the sigma catch-all fix went to the INSTANCE, not the PATTERN — three remain, and i… |
| 08-07 21:10 | `db1c6e5` | compiler (leg 2) | 29 | saltworks: the auditor read another seat's HALF-WRITTEN file and accused it of 544 unaudited t… |
| 08-07 21:12 | `a4a6a2b` | other | 607 | saltworks: DECODER-UNCOND — the decoder is correct on ALL 2^32 words, and the projection that … |
| 08-07 21:14 | `0336feb` | evidence | 18 | saltworks: bus_watch — the filter was mis-scoped in BOTH directions, and it cost me two posts … |
| 08-07 21:14 | `9d1ef13` | compiler (leg 2) | 39 | saltworks: every audit verdict now carries HEAD and the dirty files it read — math's fix, and … |
| 08-07 21:17 | `9fef1e6` | evidence | 13 | saltworks: STALENESS BANNER on the proof-debt table — 44 commits since it ran, and the decoder… |
| 08-07 21:18 | `8ed6c28` | evidence | 28 | saltworks: the blocked column's missing lemma is a CONE lemma, not a fanin congruence — my han… |
| 08-07 21:19 | `f61f023` | compiler (leg 2) | 19 | saltworks: block (2) may stop being a block — the operand-B mux IS aluSelect at n = 2, checked… |
| 08-07 21:37 | `9edb087` | silicon (leg 3) | 134 | saltworks: REFUTATION VERDICT on DECODER-UNCOND (a4a6a2b) — CLEAN against checks published bef… |
| 08-07 21:46 | `37ddd8b` | silicon (leg 3) | 95 | saltworks: the value-vs-question test, run on all thirteen watch items ON PURPOSE — two more r… |
| 08-07 21:54 | `10ec8f3` | silicon (leg 3) | 115 | saltworks: SILICON BANK, night cycle — written at a clean seam, in the repo rather than only o… |
| 08-07 21:56 | `165a5a2` | silicon (leg 3) | 24 | saltworks: bank annotation — my muster line was overstated and compiler's version supersedes it |
| 08-07 22:01 | `2f86b92` | compiler (leg 2) | 172 | saltworks: ALUSEL-PARAM stage 1 — genSelect n b, and aluSelect recovered as genSelect 10 4 |
| 08-07 22:04 | `4f140ea` | silicon (leg 3) | 27 | saltworks: bank — the Silicon/Equiv commitment made to compiler at 22:04, recorded so it survi… |
| 08-07 22:06 | `28aeba6` | silicon (leg 3) | 26 | saltworks: aluSelect pricing — the [n < pad] term is wrong, and my "two independent validation… |
| 08-07 22:06 | `c2d0ef6` | compiler (leg 2) | 16 | saltworks: the plan's n=2 row was 97 and the generator is 98 — and my own adoption is what mad… |
| 08-07 22:09 | `74fd26b` | silicon (leg 3) | 19 | saltworks: aluSelect pricing, second annotation — the n=2 row read as "97 was wrong" and 97 wa… |
| 08-07 22:10 | `9df0c65` | compiler (leg 2) | 28 | saltworks: ALUSEL-PARAM stage 1 addendum — the cited measurement now lands in the tree |
| 08-07 22:10 | `a1780b3` | other | 680 | saltworks: ALUSEL-PARAM stages 2-4 — sem_genSelect, and sem_aluSelect demoted to a corollary |
| 08-07 22:12 | `d3b96d9` | silicon (leg 3) | 22 | saltworks: bank — my Silicon/Equiv commitment needed a unilateral escape, found by math on its… |
| 08-07 22:12 | `3ec4a73` | maestro | 13 | docs: SEATS.md rewritten to boundaries-not-values — seat-keyed slots, accounts dropped (jason/… |
| 08-07 22:14 | `d44493f` | compiler (leg 2) | 20 | saltworks: my own one-gate finding travelled without what made it correct |
| 08-07 22:14 | `e938f3b` | silicon (leg 3) | 19 | saltworks: bank — the fence's release is now OBSERVABLE, not notified (compiler's form superse… |
| 08-07 22:16 | `e66b3d8` | silicon (leg 3) | 24 | saltworks: bank — RETRACTING the observable-release form I committed 90 seconds ago; it failed… |
| 08-07 22:19 | `2e31f20` | silicon (leg 3) | 17 | saltworks: aluSelect pricing section 4 is obsolete — the deadline is dead because math built t… |
| 08-07 22:19 | `3b52c6a` | compiler (leg 2) | 24 | saltworks: block (2) is no longer conditional — the operand-B organ theorem is LANDED, and sec… |
| 08-07 22:28 | `199504c` | compiler (leg 2) | 435 | saltworks: ⭐ THE CONE LEMMA — a circuit is independent of an input no output's cone reaches |
| 08-07 22:29 | `9b67f99` | compiler (leg 2) | 469 | saltworks: ⭐ THE FRAME LADDER — the network's eight output STREAMS are a fold over bnComps, an… |
| 08-07 22:30 | `cbd2679` | compiler (leg 2) | 1 | saltworks: hseam is FOUR binder sites, not eight — my grep count, mis-read as sites, and the w… |
| 08-07 22:32 | `e45fd09` | evidence | 14 | saltworks: the cone lemma LANDED — half my blocked column is unblocked, and the bank says whic… |
| 08-07 22:32 | `f1ba3b0` | silicon (leg 3) | 7 | saltworks: bank — hseam is 4 not 8, and the cone lemma and frame ladder have landed |
| 08-07 22:32 | `16efae8` | compiler (leg 2) | 362 | saltworks: ⭐ THE ELEMENT SORTS, FROM ANY STATE — ceC_pair_full_load_any_state, and two finding… |
| 08-07 22:34 | `0b1bcc6` | compiler (leg 2) | 60 | saltworks: SEAM — the JOIN specified where the next hand reads it; both halves landed, and the… |
| 08-07 22:47 | `dd16962` | maestro | 1 | docs: SEATS.md — ALUSEL-PARAM exception STRUCK on its landing (release posted 22:18); exceptio… |
| 08-07 22:54 | `6d326fa` | compiler (leg 2) | 912 | saltworks: ⭐⭐ THE SEAM JOIN — ElemSortsAt DISCHARGED, and composed_switch_of_seam REACHED. Thr… |
| 08-07 22:56 | `33a3c86` | compiler (leg 2) | 32 | saltworks: ⭐⭐⭐ THE SEAM IS CLOSED — composed_switch_of_bnC_driven, hseam discharged from the s… |
| 08-07 23:01 | `10d1a58` | evidence | 25 | saltworks: muster §1a — the seam gate reads the DISCHARGE, and I corrected the proposed check … |
| 08-07 23:04 | `25f73d3` | evidence | 19 | saltworks: muster gate — the BUILD LINE, run without a pipe, because the proposed form discard… |
| 08-07 23:06 | `85ca1e1` | compiler (leg 2) | 171 | saltworks: COMPILER NIGHT BANK — the seam closed, what I got wrong, and what this bank probabl… |
| 08-07 23:06 | `93e1cb7` | compiler (leg 2) | 7 | saltworks: bank — closing the gap I had just written into it rather than confessing it |
| 08-07 23:14 | `924a44e` | maestro (hub) | 5 | hub sweep: the five seam modules enter the corpus — Cone, SeamElement, SeamJoinA/B/C (import o… |
| 08-07 23:16 | `76c9522` | compiler (leg 2) | 14 | saltworks: bank — the sweep landed and B5 unblocked; striking two owed-items so the bank does … |
| 08-07 23:17 | `50267ca` | evidence | 6 | saltworks: muster gate — recording math's NEGATIVE CONTROL, which is what makes the build-line… |
| 08-07 23:17 | `7d7eefc` | silicon (leg 3) | 22 | saltworks: B5 brief section 3 — half the gate is measured, and it is the half that was "leanin… |
| 08-07 23:22 | `d567ca4` | compiler (leg 2) | 28 | saltworks: B4's evidence is TWO objects — the corpus tick is REPLAYED (cached text), the elabo… |
| 08-07 23:46 | `27a1789` | compiler (leg 2) | 89 | saltworks: reach_census — DERIVE the outside-module set, and fix the headline that asserted wh… |
| 08-07 23:59 | `b55824d` | compiler (leg 2) | 64 | saltworks: reach_census — PAY THE SUBTRACTION the header has owed since it was written. Residu… |
| 08-08 00:00 | `1183526` | compiler (leg 2) | 29 | saltworks: bank — strike the reach_census owed-item, record the subtraction result and its two… |
| 08-08 00:03 | `6ecea1e` | compiler (leg 2) | 28 | saltworks: bank — SeamJoinC SEPARATED (7 unique / 7 redundant), and a duplicate declaration th… |
| 08-08 00:06 | `3801ee8` | compiler (leg 2) | 12 | saltworks: DELETE the duplicate bnCFrameAt_length from SeamJoinC — the hub's line order was se… |
| 08-08 00:11 | `267787d` | compiler (leg 2) | 148 | saltworks: dup_decls.py — assert the no-duplicate PROPERTY instead of hand-checking it |
| 08-08 00:15 | `e99c720` | silicon (leg 3) | 46 | saltworks: bank section 5(e) — silicon's own slot advanced by zero tonight, and I only wrote t… |
| 08-08 00:16 | `9a2ae82` | compiler (leg 2) | 30 | saltworks: bank — B4's scope sentence, verified at the source: it certifies DESTINATION HEADER… |
| 08-08 00:17 | `0c55706` | compiler (leg 2) | 19 | saltworks: bank — the harder version of my own ratio item, with three more hours of evidence a… |
| 08-08 00:57 | `f4825d7` | compiler (leg 2) | 36 | saltworks: bank — the second half of the night's error list, 23:00 to 01:00 |
| 08-08 08:03 | `112353b` | evidence | 10 | saltworks: bus_watch — the filter was armed and answering the wrong question, all of 8/7 |
| 08-08 08:03 | `c4c7507` | evidence | 835 | saltworks: bank the 19:14 ledger run that survived the crash, unregenerated |

### `salt` — 70 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| docs: exploration | 37 | 4,485 | 4 |
| docs: blueprints | 15 | 4,401 | 2,913 |
| salt: HB (Heath-Brown) | 6 | 1,441 | 1,441 |
| maestro (hub) | 4 | 89 | 0 |
| docs (shared) | 3 | 72 | 0 |
| salt: Entropy/Chowla | 2 | 520 | 42 |
| salt: Weil | 1 | 361 | 361 |
| other | 1 | 0 | 0 |
| salt: papers | 1 | 1 | 0 |
| **total** | **70** | **11,370** | **4,761** |

| When | Commit | Lane | +lines | Subject |
|---|---|---|---:|---|
| 08-05 22:06 | `db277c4` | docs: exploration | 849 | play M: THE TRIPLE — both VLSI dossiers persisted (bv_decide adds a per-theorem native axiom, … |
| 08-05 22:19 | `df72d8a` | docs: exploration | 16 | play M: THE TRIPLE — the origin artifacts (IEEE paper + US4910730A, both public); THE DESIGN C… |
| 08-06 07:08 | `d9c3853` | docs: exploration | 52 | play M: COUNCIL I — THE SEAM DOCTRINE ratified (the compiler dissolves into the checked seam; … |
| 08-06 08:19 | `240b80e` | docs: exploration | 72 | play M: WEIL-TRIO DESIGN FREEZE v1 (ratifies the scout plan W0->W1\|\|W2\|\|W4\|\|W5->W3; the … |
| 08-06 08:21 | `7a1a6a1` | docs: exploration | 6 | play M: WEIL-TRIO W4-e — the QuadCharSum citation corrected (HB 1983 p.217, not the fourth-mom… |
| 08-06 08:21 | `ce1187d` | docs: exploration | 1 | play M: WEIL-TRIO W4-e closed in the dossier (both doc defects fixed at 7a1a6a1) [skip ci] |
| 08-06 08:55 | `435d73a` | docs: exploration | 433 | play M: TAU-SHARP TS-0 — the refuter pass lands (K1/K2/K4 REPAIR-THEN-FIRE, K3 HOLD) |
| 08-06 08:56 | `8779d40` | salt: HB (Heath-Brown) | 282 | play M: CHAR-TRIO — hchi01 + hchi0 DISCHARGED and hL1's product half landed (Salt/HB/CharTrio.… |
| 08-06 08:56 | `743cab5` | docs: blueprints | 83 | play M: CHAR-TRIO — the flags entry: hL1's residue PRICED at the s=1 boundary (mathlib's Euler… |
| 08-06 08:57 | `c9c2dc4` | docs: exploration | 103 | play M: WEIL-TRIO v2 post-refutation (theta<=1/50 — my 1/6 was 8x over, Salie stays class C w/… |
| 08-06 09:04 | `56af5c7` | docs: exploration | 14 | play M: campaign ledger — fleet resource lessons 1+2 (the every-door lock law; rule changes mu… |
| 08-06 09:28 | `b406014` | docs: blueprints | 153 | play M: SILICON BOUGHT — 4 tiles EUR280 on TTSKY26c + THE PRICE EXHIBIT (1988 VTI ~$150K vs 20… |
| 08-06 09:31 | `cdc960b` | docs: exploration | 187 | play M: TAU-SHARP TS-1/TS-2 briefs BANKED for the 20:00 resume (both waves held by the third-O… |
| 08-06 09:38 | `d1a5668` | salt: Weil | 361 | play M: WEIL-TRIO-W1(a,b,d) — GcdBranch lands: the loss-neutral gcd descent S(pA,pB;p^{f+1}) =… |
| 08-06 09:41 | `1de7dc3` | docs (shared) | 17 | play M: hb1983-notes erratum — S1 << x^{1/2}, not x^{1/4} (WEIL-TRIO v2 D6), + a residual flag… |
| 08-06 09:53 | `4a58e51` | docs: blueprints | 736 | play M: WEIL-TRIO-W1(c) — THE SHARP SALIE STONE lands: \|\|S(a,b;p^{2m+1})\|\| <= 2*p^m*sqrt(p… |
| 08-06 09:54 | `993f84e` | docs: exploration | 17 | play M: WEIL-TRIO D8 — W1 home (pre-flight PASS at the source, W2 stays dead; my e-2 brief err… |
| 08-06 09:55 | `1019c0e` | docs: exploration | 315 | play M: N7-PREP DOSSIER — the consumption/supply/gap map for Lemma 10 + (7.5)-(7.8) (read-only… |
| 08-06 09:56 | `f2aba94` | salt: HB (Heath-Brown) | 106 | play M: WEIL-TRIO-W4Q(W4-c0) — the :137 proof's hval exposed: quadraticChar_sum_two_forms_eq (… |
| 08-06 09:56 | `49361e2` | docs: blueprints | 557 | play M: WEIL-TRIO-W4Q(W4-b + W4-c′ + W4-c + W4-d) — Salt/HB/RealPrimitive.lean (460 ln, 20 dec… |
| 08-06 09:57 | `83770b4` | docs: exploration | 15 | play M: WEIL-TRIO D9 — W4Q home 5/5 (p.217 at constant ONE in-kernel; the jacobiChar exit shap… |
| 08-06 09:58 | `a7fa34e` | docs: blueprints | 67 | play M: flags — W3's D3 exit is NOT (7.1), and W4-a is on its critical path (a math-seat findi… |
| 08-06 10:08 | `fe2c41d` | salt: HB (Heath-Brown) | 639 | play M: WEIL-TRIO-W4A(S1) — the CRT character split: crtIn₁/₂ + crtFactor₁/₂ (DirichletCharact… |
| 08-06 10:08 | `f6e0c12` | other | 0 | play M: WEIL-TRIO-W3 — THE GLOBAL ESTERMANN ASSEMBLY lands: \|\|S(a,b;k)\|\| <= 2^{v2(k)/2}*d(… |
| 08-06 10:10 | `2b07e65` | salt: HB (Heath-Brown) | 99 | play M: WEIL-TRIO-W4A(S2) — primitivity is componentwise: crtFactor₁_isPrimitive / crtFactor₂_… |
| 08-06 10:10 | `f1eecd4` | docs: blueprints | 77 | play M: WEIL-TRIO-W3 — the caveat carried: docstrings + flags row state that the landed exit i… |
| 08-06 10:12 | `255128b` | salt: HB (Heath-Brown) | 84 | play M: WEIL-TRIO-W4A(S3) — the odd local classification: not_isPrimitive_of_odd_prime_pow (th… |
| 08-06 10:19 | `a3ad90f` | salt: HB (Heath-Brown) | 231 | play M: WEIL-TRIO-W4A(S4) — the 2-part classification COMPLETE: not_isPrimitive_two; exists_od… |
| 08-06 10:25 | `c4303b8` | docs: exploration | 253 | play M: WEIL-TRIO STATEMENT AUDIT — the landed W1/W4Q/W3 exits are CLEAN; one consumer constra… |
| 08-06 10:27 | `755a315` | docs: blueprints | 72 | play M: flags — the WEIL-TRIO statement audit's two actionable items, delivered by the ledger |
| 08-06 10:28 | `eb14498` | docs: blueprints | 272 | play M: WEIL-TRIO-W4A(S5) — THE STRUCTURE THEOREM LANDS, and with it the p.217 DISCHARGE: sum_… |
| 08-06 10:34 | `95c8902` | docs: exploration | 23 | play M: TS-1/TS-2 briefs — wire the -M cap check into the 20:00 wave so it produces the datum |
| 08-06 10:43 | `5004c4e` | docs: blueprints | 720 | play M: WEIL-TRIO-W5(S1+S3) — the sawtooth kit's two independent stones: (7.2) with the EXPLIC… |
| 08-06 11:17 | `b25d8aa` | docs (shared) | 46 | play M: HB 1983 p.214 — THE :611 RESIDUAL IS CLOSED AT THE SOURCE, and it is a PAPER erratum, … |
| 08-06 11:20 | `c470f52` | docs: exploration | 74 | play M: N7-prep ADDENDUM A — section 7 verified against the source pp.221-223 |
| 08-06 11:20 | `8e906ed` | docs: exploration | 7 | play M: N7-prep — mark the :611 residual CLOSED in situ (it was still listed as owed by N7) |
| 08-06 11:23 | `fab7a8a` | docs: exploration | 18 | play M: (5.14) restored from the source p.213 — the dropped index was Lemma 10's own summation… |
| 08-06 11:27 | `409e227` | docs: exploration | 92 | play M: N7-prep ADDENDUM B — section 6 verified at the source pp.215-221 (the bulk of N7, neve… |
| 08-06 11:31 | `6ee9f07` | docs: exploration | 35 | play M: (7.8) settled BY DERIVATION — the log is the FIRST power, and the missing intermediate… |
| 08-06 11:35 | `62eb4c3` | docs: exploration | 35 | play M: N7-prep ADDENDUM C — section 5's opening verified at the source pp.210-211: CLEAN |
| 08-06 11:36 | `a0fe087` | docs: exploration | 47 | play M: N7-prep ADDENDUM D — Lemma 5's STATEMENT verified at the source p.199: CLEAN (sweep co… |
| 08-06 11:38 | `e3513c4` | docs: exploration | 13 | play M: N7-prep — headline and epistemic posture updated for the completed source sweep |
| 08-06 11:39 | `c1985d8` | docs: exploration | 26 | play M: N7-prep D.1 — kappa's Lean rendering cross-checked; the partition bug I went looking f… |
| 08-06 11:48 | `36ea232` | salt: Entropy/Chowla | 485 | play M: THE WITNESS PAPER WRAPS — the full JYH review harvest in one seal [skip ci] |
| 08-06 11:49 | `b7f2456` | docs: blueprints | 261 | play M: WEIL-TRIO-W5(S2) — (7.3)/(7.4) PARTIAL: the (log K)/K arm lands with the L1 mass EXACT… |
| 08-06 11:50 | `030fb88` | docs: exploration | 22 | play M: N7-prep D.2 — the PDF text-layer route tried and recorded as a NEGATIVE result for kap… |
| 08-06 11:52 | `37693d1` | docs: exploration | 22 | play M: TS-2 gains a MUTATION CHECK — a green build does not prove the gamma-floors are load-b… |
| 08-06 11:58 | `89c23d0` | docs: exploration | 22 | play M: N7-prep ADDENDUM D.3 — kappa VERIFIED at the print (maestro page-image read); the swee… |
| 08-06 11:58 | `fb665b3` | docs: blueprints | 75 | play M: WEIL-CONS — the unit-twist consolidation (kloosterman_mul_of_coprime_unit_twist moved … |
| 08-06 12:00 | `cec5e5c` | docs: exploration | 3 | play M: N7-prep D.1 — correct my hbKappa citation :346 -> :348 (the maestro's D.3 caught it) |
| 08-06 12:01 | `a80f41e` | salt: Entropy/Chowla | 35 | play M: copyright headers on the 7 bare files (the Zenodo agent's polish item) — comment-only,… |
| 08-06 12:17 | `4aea409` | salt: papers | 1 | play M: THE DOI LANDS — 10.5281/zenodo.21828638 into Availability; the placeholder era ends; P… |
| 08-06 13:58 | `1328acf` | docs: exploration | 914 | play M: MIGRATION-PROOF the TS-1 wave artifacts (fleet moves laptop -> Mac Mini ~14:00 today) |
| 08-06 15:52 | `2a71ec3` | docs: exploration | 351 | play M: TAU-SHARP pre-gate — the γ-census is FOUR sites, not three (+ the TS-2 dispatch prompt… |
| 08-06 15:55 | `b43a6bd` | docs: exploration | 51 | play M: TAU-SHARP pre-gate — Amendment 5: S1's threading orphans hc_t1 (a "no new warnings" tr… |
| 08-06 16:09 | `67a2b97` | docs: exploration | 30 | play M: TAU-SHARP pre-gate — Amendment 6: the arm table recomputed; two "after" cells are pre-… |
| 08-06 16:11 | `d5ddc4e` | docs: exploration | 26 | play M: TAU-SHARP pre-gate — Amendment 7: S5(b) is NOT attempted tonight (it couples the two w… |
| 08-06 16:11 | `b8da427` | docs: exploration | 10 | play M: GUARD RESTATED in both TS dispatch prompts — cap-hit text corrected to the binary-veri… |
| 08-06 17:26 | `e8d975c` | docs: blueprints | 441 | play M: TAU-SHARP TS-1 — S1 + S5(a) + S6 land in BOTH towers (log(1/c) 631.58 -> 563.92) |
| 08-06 17:31 | `2d8a123` | docs: exploration | 39 | play M: TS-2 prompt re-coordinated to POST-TS-1 bytes (S5(a) shifted R8 by +51) |
| 08-06 17:57 | `158f266` | docs: blueprints | 334 | play M: TAU-SHARP TS-2 — the γ-honest arms land in BOTH towers (all FOUR sites; log(1/c) 563.9… |
| 08-06 19:03 | `3ae7ff8` | docs: blueprints | 168 | play M: TAU-SHARP TS-3-PREP — ray_pow_bound parametrized over (b, k) (a PURE refactor; nothing… |
| 08-06 19:08 | `3872cce` | maestro (hub) | 20 | salt: memory backstop on the build path — -M 20000 via weakLeanArgs, verified to bind and veri… |
| 08-06 19:23 | `a593646` | docs: exploration | 240 | play M: N4/N8 OBLIGATION TRACE — verdict (B), TS-3 DEFERRED by the pre-registered rule |
| 08-06 21:08 | `8bef548` | maestro (hub) | 22 | salt: the cap was already here — and the re-verification found the fleet's cap-hit rule return… |
| 08-06 21:58 | `1f6b7cf` | maestro (hub) | 22 | salt: strike my wrong cap-hit directive — it is refuted, and M-2 replaces it |
| 08-06 22:54 | `f2efbab` | maestro (hub) | 25 | saltworks: -M is a checkpoint budget — verified, and the ALARMING half of my own claim is dead |
| 08-07 08:23 | `d8d7acb` | docs (shared) | 9 | play M: OPERATIONS — the workflow-gate erased per JYH's INVERTED PURSE ruling (8/7): design bl… |
| 08-07 08:30 | `345c12b` | docs: exploration | 52 | play M: the (b,k)-wave brief drafted under the Inverted Purse — demand-trace first with pre-re… |
| 08-07 09:18 | `8b5998d` | docs: blueprints | 385 | play M: HSIGMA-COMP — the repulsion floor composed into hb_L1_one_sided's hσ'r, in the kernel |

**596 commits across 2 repo(s) in the window.**


---

tile_drain: appended 2026-08-08T08:06:07-0700  tiles 200/512  pcbs 0/80

## Shuttle drain — TTSKY26c

| Read at | Tiles available | PCBs available |
|---|---:|---:|
| 2026-08-07 12:35 | 202 | 0 |
| 2026-08-07 13:23 | 202 | 0 |
| 2026-08-07 14:48 | 202 | 0 |
| 2026-08-07 18:00 | 202 | 0 |
| 2026-08-07 19:14 | 202 | 0 |
| 2026-08-08 08:06 | 200 | 0 |

⛔ **NO SLOPE PRINTED — the series spans 19.5 h, need 36 h.** Readings close together measure the clock, not the shuttle.
