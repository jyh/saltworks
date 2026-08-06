# CAMPAIGN LEDGER — 2026-08-06

Nightly, from `docs/ledger-tools/nightly.sh`. Every table below is
regenerated from the git history and the session transcripts; nothing
here is typed by hand. The filter that decides what counts as a human
touch is disclosed inside each section, per
`docs/measurement-preregistration.md` and its ADDENDUM 1.

---

# SILENCE-WINDOW LEDGER — `saltworks`

Generated 2026-08-06 08:48 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/saltworks` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **5** |
| `.lean` lines inserted | **263** |
| All lines inserted | 566 |
| First commit | 2026-08-05 22:05 `4fa92be` |
| Last commit | 2026-08-06 07:58 `cb5ccb3` |
| Human touches read, personal-lane fleet (whole transcript record) | **1,933** |
| — of which into this seat (`-Users-jyh-projects-claude-saltworks`) | 12 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-saltworks`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **25** human touches: **0** into this seat and **25** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 5 | 100% | 263 | 566 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 5 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **0.2 h** | 2026-08-06 07:57 | 2026-08-06 08:09 | 1 | 0 |
| **0.2 h** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 262 |
| **0.1 h** | 2026-08-06 06:31 | 2026-08-06 06:35 | 2 | 1 |
| **0.0 h** | 2026-08-06 07:07 | 2026-08-06 07:09 | 1 | 0 |

**Best exhibit by commits landed:** 0h 03m of silence (2026-08-06 06:31 → 2026-08-06 06:35) carrying **2 commits** and **1 `.lean` lines**.

## 5. The longest unbroken run

**2 consecutive commits**, 2026-08-06 06:33 → 2026-08-06 06:33, span **0h 00m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-06 06:33 | `fe3401c` | saltworks: seat structure — HDL (leg 2) + Silicon (leg 3) subtrees, hub ownership, the … |
| 08-06 06:33 | `60f6d2f` | saltworks: the two governing design freezes (HDL leg-2, Silicon leg-3) — each seat's fi… |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 1 | 262 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 4 | 1 | 0 | 43 | 00:55 | 08:36 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **1 of 5 (20.0%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,753 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 35 |
| `interrupt` | **counted as human** | 15 |
| `tool-result` | rejected | 9,886 |
| `task-notification` | rejected | 1,466 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 140 |
| `compaction-summary` | rejected | 27 |
| `system-reminder` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 812 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 81,779 records over 12 session files; 13,715 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 08:48 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **6** |
| `.lean` lines inserted | **4** |
| All lines inserted | 996 |
| First commit | 2026-08-05 22:06 `db277c4` |
| Last commit | 2026-08-06 08:21 `ce1187d` |
| Human touches read, personal-lane fleet (whole transcript record) | **1,933** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 1,878 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **45** human touches: **33** into this seat and **12** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 6 | 100% | 4 | 996 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 |
| ≥ 2 h | 0 | 0.0% | 0 |
| ≥ 4 h | 0 | 0.0% | 0 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 6 | 100% | 4 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 6 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **0.3 h** | 2026-08-06 08:21 | 2026-08-06 08:36 | 2 | 4 |
| **0.2 h** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 0 |
| **0.1 h** | 2026-08-06 08:17 | 2026-08-06 08:21 | 1 | 0 |
| **0.0 h** | 2026-08-06 07:07 | 2026-08-06 07:09 | 1 | 0 |
| **0.0 h** | 2026-08-05 22:18 | 2026-08-05 22:19 | 1 | 0 |

**Best exhibit by commits landed:** 0h 15m of silence (2026-08-06 08:21 → 2026-08-06 08:36) carrying **2 commits** and **4 `.lean` lines**.

## 5. The longest unbroken run

**2 consecutive commits**, 2026-08-06 08:21 → 2026-08-06 08:21, span **0h 00m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-06 08:21 | `7a1a6a1` | play M: WEIL-TRIO W4-e — the QuadCharSum citation corrected (HB 1983 p.217, not the fou… |
| 08-06 08:21 | `ce1187d` | play M: WEIL-TRIO W4-e closed in the dossier (both doc defects fixed at 7a1a6a1) [skip ci] |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 2 | 0 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 4 | 4 | 0 | 43 | 00:55 | 08:36 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **2 of 6 (33.3%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,753 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 35 |
| `interrupt` | **counted as human** | 15 |
| `tool-result` | rejected | 9,886 |
| `task-notification` | rejected | 1,466 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 140 |
| `compaction-summary` | rejected | 27 |
| `system-reminder` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 812 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 81,780 records over 12 session files; 13,715 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 08:49 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-07-23 00:00` → `2026-08-06 00:00` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **715** |
| `.lean` lines inserted | **346,567** |
| All lines inserted | 379,060 |
| First commit | 2026-07-23 00:14 `3592f5c` |
| Last commit | 2026-08-05 22:19 `df72d8a` |
| Human touches read, personal-lane fleet (whole transcript record) | **1,933** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 1,878 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

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
| **20.9 h** | 2026-08-02 12:13 | 2026-08-03 09:09 | 26 | 12,310 |
| **14.4 h** | 2026-07-24 17:45 | 2026-07-25 08:11 | 3 | 2,591 |
| **13.4 h** | 2026-07-31 19:17 | 2026-08-01 08:39 | 2 | 0 |
| **13.3 h** | 2026-08-03 18:31 | 2026-08-04 07:47 | 13 | 5,754 |
| **12.4 h** | 2026-08-01 20:50 | 2026-08-02 09:12 | 3 | 1,955 |
| **12.0 h** | 2026-07-23 19:14 | 2026-07-24 07:15 | 1 | 0 |
| **11.3 h** | 2026-07-25 21:12 | 2026-07-26 08:28 | 9 | 3,995 |
| **10.8 h** | 2026-07-27 19:28 | 2026-07-28 06:13 | 11 | 491 |
| **10.6 h** | 2026-07-22 20:44 | 2026-07-23 07:22 | 3 | 0 |
| **10.6 h** | 2026-07-26 20:35 | 2026-07-27 07:09 | 5 | 4,652 |

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
| `typed` | **counted as human** | 1,753 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 35 |
| `interrupt` | **counted as human** | 15 |
| `tool-result` | rejected | 9,886 |
| `task-notification` | rejected | 1,466 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 140 |
| `compaction-summary` | rejected | 27 |
| `system-reminder` | rejected | 2 |
| `peer` | rejected | 1 |

Notes on specific classes:

- `task-notification` — the Amendment-2 class: an agent finished, and the notice is injected as a user turn.
- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` timer ticks and cron pings**. These fire *while the human is away*, which is exactly when they do the most damage to a silence figure. Some carry the human's own prompt text verbatim and are indistinguishable from a typed message by string matching alone.
- `peer` / `coordinator` — one seat messaging another.
- `compaction-summary` — the harness re-injecting a summary of the conversation so far.
- `slash-command` — **counted as human**. Typing `/model` at 03:00 proves a hand on the keyboard. The leg-1 harvest rejected these (214 of them); counting them can only *shorten* silence windows, which is the honest direction.
- `interrupt` — `[Request interrupted by user]`, an ESC press. Also counted as human, for the same reason.
- `legacy-fallback` — a record with no provenance fields that matched no injection pattern. Counted as human. If this number is large relative to `typed`, the fallback is doing real work and the figure deserves a manual sample.

**Queue correction.** 812 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 81,780 records over 12 session files; 13,715 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# TOKEN METER — the campaign ledger

Generated 2026-08-06 08:49 America/Los_Angeles by `docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per `docs/measurement-preregistration.md` §1.
Window: `2026-08-05 22:00` → `now` · 6 personal-lane projects · subagent transcripts INCLUDED.

> **Unit is TOKENS.** These records carry no prices and no account identifier, so no dollar figure and no per-account split is derivable from them. On a subscription, dollars are a flat envelope; the two framings are reported separately or not at all, never blended.
> **Cache is always its own column** and never enters a headline number.

## 1. Totals

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 1,223 |
| Input | 38,385 |
| **Output** | **410,959** |
| Cache created | 11,107,868 |
| Cache read | 125,515,884 |
| First request | 2026-08-05 22:02 |
| Last request | 2026-08-06 08:49 |

## 2. By project

| Project | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `-Users-jyh-projects-claude-saltworks` | 914 | 20,533 | **278,562** | 3,884,113 | 62,774,826 |
| `-Users-jyh-projects-claude-salt` | 309 | 17,852 | **132,397** | 7,223,755 | 62,741,058 |
| **TOTAL** | **1,223** | **38,385** | **410,959** | **11,107,868** | **125,515,884** |

## 3. By model tier

| Tier | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| Opus 5 | 1,169 | 26,967 | **351,090** | 8,297,821 | 93,210,438 |
| Fable 5 | 46 | 87 | **58,227** | 1,494,821 | 32,100,115 |
| Opus 4.8 | 2 | 4 | **1,632** | 1,248,389 | 26,022 |
| Haiku 4.5 | 6 | 11,327 | **10** | 66,837 | 179,309 |
| **TOTAL** | **1,223** | **38,385** | **410,959** | **11,107,868** | **125,515,884** |

## 4. By day

| Date | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| 2026-08-05 | 24 | 11,361 | **22,571** | 228,132 | 10,006,395 |
| 2026-08-06 | 1,199 | 27,024 | **388,388** | 10,879,736 | 115,509,489 |
| **TOTAL** | **1,223** | **38,385** | **410,959** | **11,107,868** | **125,515,884** |

## 5. Main loop vs subagents

| Where | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| main loop | 245 | 1,399 | **312,792** | 5,389,582 | 64,258,416 |
| subagents / workflow agents | 978 | 36,986 | **98,167** | 5,718,286 | 61,257,468 |
| **TOTAL** | **1,223** | **38,385** | **410,959** | **11,107,868** | **125,515,884** |

_The fleet's work is done by the agents, and the table shows it. A meter that reads only the session file misses most of the spend._

## 6. By wave — timestamp-join against git

| Wave (leading tag of the landing commit's subject) | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `WEIL-TRIO` | 86 | 167 | **48,538** | 2,505,618 | 19,600,412 |
| `COUNCIL` | 12 | 23 | **29,343** | 811,092 | 8,739,995 |
| `THE TRIPLE` | 22 | 11,357 | **22,407** | 226,318 | 8,703,407 |
| **TOTAL** | **120** | **11,547** | **100,288** | **3,543,028** | **37,043,814** |

Attribution rule: each request is charged to the **next commit in `salt` at or after its timestamp**, if that commit lands within 4.0 h; otherwise it is unattributed. Unattributed in this window: 189 requests / 32,109 output tokens. Only requests from this repo's own seat (`-Users-jyh-projects-claude-salt`) are joined.

> **This join is a heuristic, and the table is labelled as one.** A request that produced no commit (a scout, a refuter, a council) is charged to whatever landed next. Read it as *tokens spent in the run-up to a landing*, never as *tokens the landing cost*.

## 7. Methodology — what was counted and what was thrown away

| Fact | Value |
|---|---:|
| Transcript files read | 2,208 |
| JSONL records scanned | 352,202 |
| Duplicate assistant records dropped (same `requestId`) | 112,584 |
| `<synthetic>` records dropped (API errors, zero usage) | 106 |
| Unparseable lines | 0 |

**The dedup rule.** Claude Code writes one assistant record per content block of a response, and **every one of those records repeats the whole `usage` block of the single API call**. Measured here: 112,584 records were duplicates of a request already counted. Summing records instead of requests would inflate every number in this file by roughly a factor of three. Usage was verified byte-identical within each `requestId` group before the rule was adopted.

**Subagents.** Workflow and Task agents write their own transcripts under `<session>/subagents/**/agent-*.jsonl`. They are included by default (`--no-subagents` to exclude). They are the majority of the spend, and a meter that reads only the session file is wrong by an order of magnitude.

**Per-account attribution: UNAVAILABLE.** The transcripts carry no account, organisation or subscription identifier — checked field by field across every record type. The campaign runs five accounts; these files cannot say which one paid for a given request. Reported here as a gap rather than estimated.

**The firewall.** Outside-lane projects are excluded in code (`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure published from this tool is personal-lane only.


---

# HUMAN-TIME LEDGER — the four categories

Generated 2026-08-06 08:49 America/Los_Angeles by `docs/ledger-tools/human_time.py`, per `docs/measurement-preregistration.md` §2.
Window: `2026-08-05 22:00` → `now` · block gap 20 min · tags from `EVIDENCE-human-time-tags.tsv`.

**The rubric, published beside the number** — DIRECTING: rulings, councils, requirement-setting. REVIEWING: reading that *gates* an artifact. UNBLOCKING: logins, purchases, physical acts. WATCHING: curiosity — reading along, questions that redirect nothing. **The dependency claim = DIRECTING + REVIEWING + UNBLOCKING only**, by the counterfactual test *would the artifact exist without this touch?* WATCHING is reported as its own line, proudly: the joy is evidence, not overhead.

## 1. Totals

| Category | Blocks | Time | Share |
|---|---:|---:|---:|
| UNTAGGED | 4 | 2h 04m | 100.0% |
| **THE CLAIM** (D+R+U) | 0 | **0h 00m** | 0.0% |
| (all engaged time) | 4 | 2h 04m | 100% |

> **4 block(s), 2h 04m, are UNTAGGED.** They are counted in neither the claim nor WATCHING. Tag them in `EVIDENCE-human-time-tags.tsv` — one line per block id — and re-run. An untagged block is never silently folded into a category.

## 2. Per day

| Date | Blocks | Engaged time | Claim time (D+R+U) | Messages |
|---|---:|---:|---:|---:|
| 2026-08-05 | 1 | 0h 17m | 0h 00m | 4 |
| 2026-08-06 | 3 | 1h 47m | 0h 00m | 43 |

## 3. The blocks — the tagging worksheet

Copy a block id into the tag file with its category. The opening message is shown only so the block can be recognised.

| Block id | Seat | Start | End | Duration | Msgs | Category | Opens with |
|---|---|---|---|---:|---:|---|---|
| `20260805T2201` | salt | 08-05 22:01 | 22:19 | 0h 17m | 4 | **UNTAGGED** | typed (858 chars) |
| `20260806T0055` | salt | 08-06 00:55 | 00:56 | 0h 01m | 2 | **UNTAGGED** | typed (10 chars) |
| `20260806T0629` | salt | 08-06 06:29 | 07:36 | 1h 06m | 19 | **UNTAGGED** | slash-command,typed (162 chars) |
| `20260806T0757` | salt | 08-06 07:57 | 08:36 | 0h 38m | 22 | **UNTAGGED** | legacy-fallback,slash-command,typed (230 chars) |

## 4. Method notes

- A **block** is a run of human touches with no gap longer than 20 minutes. Its duration is last touch minus first touch, floored at 60 s for a single-touch block.
- **This under-counts, deliberately.** Reading and thinking before the first message of a block leave no trace in the transcript, so the figure is a *floor* on engaged time. It is published as a floor and never adjusted upward by estimate.
- **No manual time-tracking**, per the frozen design. Every timestamp comes from the transcript; the only human input is the category tag, and the rubric that assigns it is printed above the number.
- The touch filter is the one in `ledger_common.classify_user_record` — see `README.md`. Injected records (task notifications, loop ticks, cron pings, peer messages) are not human time.
- Touches read: 47 in window. Rejected as non-human across the whole record: 11,782.

