# CAMPAIGN LEDGER — 2026-08-06

Nightly, from `docs/ledger-tools/nightly.sh`. Every table below is
regenerated from the git history and the session transcripts; nothing
here is typed by hand. The filter that decides what counts as a human
touch is disclosed inside each section, per
`docs/measurement-preregistration.md` and its ADDENDUM 1.

---

# SILENCE-WINDOW LEDGER — `saltworks`

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/saltworks` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **48** |
| `.lean` lines inserted | **1,464** |
| All lines inserted | 10,211 |
| First commit | 2026-08-05 22:05 `4fa92be` |
| Last commit | 2026-08-06 11:32 `2d68725` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,014** |
| — of which into this seat (`-Users-jyh-projects-claude-saltworks`) | 37 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-saltworks`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **121** human touches: **35** into this seat and **86** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 48 | 100% | 1,464 | 10,211 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 20 | 46.5% | 1,010 |
| ≥ 2 h | 0 | 0.0% | 0 |
| ≥ 4 h | 0 | 0.0% | 0 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 43 | 100% | 1,201 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 48 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **0.3 h** | 2026-08-06 08:36 | 2026-08-06 08:54 | 1 | 0 |
| **0.2 h** | 2026-08-06 07:57 | 2026-08-06 08:09 | 1 | 0 |
| **0.2 h** | 2026-08-06 10:06 | 2026-08-06 10:15 | 3 | 0 |
| **0.2 h** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 262 |
| **0.1 h** | 2026-08-06 10:27 | 2026-08-06 10:36 | 3 | 0 |
| **0.1 h** | 2026-08-06 09:04 | 2026-08-06 09:12 | 1 | 0 |
| **0.1 h** | 2026-08-06 09:54 | 2026-08-06 10:02 | 4 | 332 |
| **0.1 h** | 2026-08-06 10:40 | 2026-08-06 10:48 | 3 | 658 |
| **0.1 h** | 2026-08-06 09:12 | 2026-08-06 09:17 | 1 | 0 |
| **0.1 h** | 2026-08-06 11:28 | 2026-08-06 11:33 | 3 | 0 |

**Best exhibit by commits landed:** 0h 08m of silence (2026-08-06 09:54 → 2026-08-06 10:02) carrying **4 commits** and **332 `.lean` lines**.

## 5. The longest unbroken run

**4 consecutive commits**, 2026-08-06 09:54 → 2026-08-06 10:00, span **0h 06m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-06 09:54 | `1acaa66` | saltworks: scoreboard corrected — my ulimit proposal is a NO-OP on Darwin (math measure… |
| 08-06 09:55 | `de6322c` | saltworks: D2b (Silicon) — THE REFLECTION THEOREM: sliced evaluation IS pointwise evalu… |
| 08-06 10:00 | `a9a6c03` | saltworks: the scoreboard now states that it goes stale in minutes — because math measu… |
| 08-06 10:00 | `04a2ecc` | saltworks: D2c (Silicon) — the input columns, proved; reflection now stands on nothing … |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 1 | 262 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 47 | 1,202 | 0 | 124 | 00:55 | 11:35 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **1 of 48 (2.1%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,812 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 51 |
| `interrupt` | **counted as human** | 21 |
| `tool-result` | rejected | 10,631 |
| `task-notification` | rejected | 1,527 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 143 |
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

**Queue correction.** 818 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 86,668 records over 12 session files; 14,605 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **40** |
| `.lean` lines inserted | **3,810** |
| All lines inserted | 7,219 |
| First commit | 2026-08-05 22:06 `db277c4` |
| Last commit | 2026-08-06 11:35 `62eb4c3` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,014** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 1,935 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **126** human touches: **89** into this seat and **37** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 40 | 100% | 3,810 | 7,219 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 |
| ≥ 2 h | 0 | 0.0% | 0 |
| ≥ 4 h | 0 | 0.0% | 0 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 40 | 100% | 3,810 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 40 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **0.3 h** | 2026-08-06 08:21 | 2026-08-06 08:36 | 2 | 4 |
| **0.2 h** | 2026-08-06 10:06 | 2026-08-06 10:15 | 5 | 849 |
| **0.2 h** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 0 |
| **0.1 h** | 2026-08-06 10:27 | 2026-08-06 10:36 | 2 | 216 |
| **0.1 h** | 2026-08-06 09:04 | 2026-08-06 09:12 | 1 | 0 |
| **0.1 h** | 2026-08-06 09:54 | 2026-08-06 10:02 | 6 | 580 |
| **0.1 h** | 2026-08-06 10:40 | 2026-08-06 10:48 | 1 | 662 |
| **0.1 h** | 2026-08-06 10:15 | 2026-08-06 10:20 | 1 | 231 |
| **0.1 h** | 2026-08-06 11:28 | 2026-08-06 11:33 | 1 | 0 |
| **0.1 h** | 2026-08-06 08:55 | 2026-08-06 09:00 | 3 | 282 |

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
| 2026-08-06 | Thu | 38 | 3,810 | 0 | 124 | 00:55 | 11:35 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **2 of 40 (5.0%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,812 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 51 |
| `interrupt` | **counted as human** | 21 |
| `tool-result` | rejected | 10,631 |
| `task-notification` | rejected | 1,527 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 143 |
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

**Queue correction.** 818 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 86,669 records over 12 session files; 14,605 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
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
| Human touches read, personal-lane fleet (whole transcript record) | **2,015** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 1,935 |
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
| `typed` | **counted as human** | 1,813 |
| `slash-command` | **counted as human** | 130 |
| `legacy-fallback` | **counted as human** | 51 |
| `interrupt` | **counted as human** | 21 |
| `tool-result` | rejected | 10,631 |
| `task-notification` | rejected | 1,527 |
| `slash-command-echo` | rejected | 260 |
| `harness-injection` | rejected | 143 |
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

**Queue correction.** 818 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 86,688 records over 12 session files; 14,606 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# TOKEN METER — the campaign ledger

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per `docs/measurement-preregistration.md` §1.
Window: `2026-08-05 22:00` → `now` · 6 personal-lane projects · subagent transcripts INCLUDED.

> **Unit is TOKENS.** These records carry no prices and no account identifier, so no dollar figure and no per-account split is derivable from them. On a subscription, dollars are a flat envelope; the two framings are reported separately or not at all, never blended.
> **Cache is always its own column** and never enters a headline number.

## 1. Totals

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 4,435 |
| Input | 73,789 |
| **Output** | **1,601,367** |
| Cache created | 26,599,778 |
| Cache read | 739,897,878 |
| First request | 2026-08-05 22:02 |
| Last request | 2026-08-06 11:35 |

## 2. By project

| Project | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `-Users-jyh-projects-claude-saltworks` | 3,075 | 35,673 | **931,138** | 13,445,144 | 366,062,865 |
| `-Users-jyh-projects-claude-salt` | 1,360 | 38,116 | **670,229** | 13,154,634 | 373,835,013 |
| **TOTAL** | **4,435** | **73,789** | **1,601,367** | **26,599,778** | **739,897,878** |

## 3. By model tier

| Tier | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| Opus 5 | 4,235 | 62,096 | **1,348,786** | 23,506,707 | 584,782,574 |
| Fable 5 | 192 | 362 | **250,939** | 1,777,845 | 154,909,973 |
| Opus 4.8 | 2 | 4 | **1,632** | 1,248,389 | 26,022 |
| Haiku 4.5 | 6 | 11,327 | **10** | 66,837 | 179,309 |
| **TOTAL** | **4,435** | **73,789** | **1,601,367** | **26,599,778** | **739,897,878** |

## 4. By day

| Date | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| 2026-08-05 | 24 | 11,361 | **22,571** | 228,132 | 10,006,395 |
| 2026-08-06 | 4,411 | 62,428 | **1,578,796** | 26,371,646 | 729,891,483 |
| **TOTAL** | **4,435** | **73,789** | **1,601,367** | **26,599,778** | **739,897,878** |

## 5. Main loop vs subagents

| Where | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| main loop | 1,057 | 2,942 | **1,302,034** | 7,592,981 | 449,367,759 |
| subagents / workflow agents | 3,378 | 70,847 | **299,333** | 19,006,797 | 290,530,119 |
| **TOTAL** | **4,435** | **73,789** | **1,601,367** | **26,599,778** | **739,897,878** |

_In this window the subagents made **76% of the requests** and **19% of the output tokens** (main loop: 24% / 81%). Design and orchestration sat in the main loops; the agents were many but individually cheap._

## 6. By wave — timestamp-join against git

| Wave (leading tag of the landing commit's subject) | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `WEIL-TRIO` | 159 | 309 | **85,167** | 2,672,942 | 42,134,402 |
| `HB` | 201 | 395 | **82,899** | 1,256,065 | 66,558,120 |
| `TAU-SHARP` | 225 | 6,376 | **70,494** | 2,642,683 | 32,017,227 |
| `WEIL-TRIO-W1` | 166 | 1,899 | **60,635** | 753,450 | 36,487,132 |
| `N7-prep` | 76 | 147 | **53,081** | 575,317 | 36,050,242 |
| `WEIL-TRIO-W4A` | 159 | 4,753 | **46,901** | 669,615 | 38,594,703 |
| `TS-1` | 32 | 61 | **44,359** | 77,855 | 17,045,305 |
| `SILICON` | 78 | 152 | **34,430** | 783,630 | 18,722,293 |
| `(unlabelled)` | 31 | 59 | **29,928** | 167,958 | 12,482,271 |
| `COUNCIL` | 12 | 23 | **29,343** | 811,092 | 8,739,995 |
| `WEIL-TRIO-W5` | 58 | 112 | **25,924** | 142,968 | 23,216,731 |
| `campaign` | 48 | 95 | **22,504** | 313,792 | 8,369,363 |
| `THE TRIPLE` | 22 | 11,357 | **22,407** | 226,318 | 8,703,407 |
| `hb1983-notes` | 36 | 70 | **18,513** | 238,858 | 10,088,198 |
| `CHAR-TRIO` | 5 | 9 | **16,632** | 23,559 | 1,257,668 |
| `flags` | 13 | 24 | **8,007** | 44,231 | 3,476,615 |
| `WEIL-TRIO-W3` | 13 | 12,225 | **6,903** | 67,374 | 1,626,611 |
| `N7-PREP` | 11 | 22 | **6,038** | 32,195 | 3,749,893 |
| `WEIL-TRIO-W4Q` | 5 | 9 | **3,010** | 17,873 | 1,051,418 |
| **TOTAL** | **1,350** | **38,097** | **667,175** | **11,517,775** | **370,371,594** |

Attribution rule: each request is charged to the **next commit in `salt` at or after its timestamp**, if that commit lands within 4.0 h; otherwise it is unattributed. Unattributed in this window: 10 requests / 3,054 output tokens. Only requests from this repo's own seat (`-Users-jyh-projects-claude-salt`) are joined.

> **This join is a heuristic, and the table is labelled as one.** A request that produced no commit (a scout, a refuter, a council) is charged to whatever landed next. Read it as *tokens spent in the run-up to a landing*, never as *tokens the landing cost*.

## 7. Methodology — what was counted and what was thrown away

| Fact | Value |
|---|---:|
| Transcript files read | 2,306 |
| JSONL records scanned | 366,104 |
| Duplicate assistant records dropped (same `requestId`) | 116,455 |
| `<synthetic>` records dropped (API errors, zero usage) | 107 |
| Unparseable lines | 0 |

**The dedup rule.** Claude Code writes one assistant record per content block of a response, and **every one of those records repeats the whole `usage` block of the single API call**. Measured here: 116,455 records were duplicates of a request already counted. Summing records instead of requests would inflate every number in this file by roughly a factor of three. Usage was verified byte-identical within each `requestId` group before the rule was adopted.

**Subagents.** Workflow and Task agents write their own transcripts under `<session>/subagents/**/agent-*.jsonl`. They are included by default (`--no-subagents` to exclude). They are the majority of the spend, and a meter that reads only the session file is wrong by an order of magnitude.

**Per-account attribution: UNAVAILABLE.** The transcripts carry no account, organisation or subscription identifier — checked field by field across every record type. The campaign runs five accounts; these files cannot say which one paid for a given request. Reported here as a gap rather than estimated.

**The firewall.** Outside-lane projects are excluded in code (`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure published from this tool is personal-lane only.


---

# HUMAN-TIME LEDGER — the four categories

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/human_time.py`, per `docs/measurement-preregistration.md` §2.
Window: `2026-08-05 22:00` → `now` · block gap 20 min · tags from `EVIDENCE-human-time-tags.tsv`.

**The rubric, published beside the number** — DIRECTING: rulings, councils, requirement-setting. REVIEWING: reading that *gates* an artifact. UNBLOCKING: logins, purchases, physical acts. WATCHING: curiosity — reading along, questions that redirect nothing. **The dependency claim = DIRECTING + REVIEWING + UNBLOCKING only**, by the counterfactual test *would the artifact exist without this touch?* WATCHING is reported as its own line, proudly: the joy is evidence, not overhead.

## 1. Totals

| Category | Blocks | Time | Share |
|---|---:|---:|---:|
| **DIRECTING** | 3 | 5h 02m | 99.5% |
| WATCHING | 1 | 0h 01m | 0.5% |
| **THE CLAIM** (D+R+U) | 3 | **5h 02m** | 99.5% |
| (all engaged time) | 4 | 5h 03m | 100% |

## 2. Per day

| Date | Blocks | Engaged time | Claim time (D+R+U) | Messages |
|---|---:|---:|---:|---:|
| 2026-08-05 | 1 | 0h 17m | 0h 17m | 4 |
| 2026-08-06 | 3 | 4h 46m | 4h 44m | 125 |

## 3. The blocks — the tagging worksheet

Copy a block id into the tag file with its category. The opening message is shown only so the block can be recognised.

| Block id | Seat | Start | End | Duration | Msgs | Category | Opens with |
|---|---|---|---|---:|---:|---|---|
| `20260805T2201` | salt | 08-05 22:01 | 22:19 | 0h 17m | 4 | DIRECTING | typed (858 chars) |
| `20260806T0055` | salt | 08-06 00:55 | 00:56 | 0h 01m | 2 | WATCHING | typed (10 chars) |
| `20260806T0629` | salt | 08-06 06:29 | 07:36 | 1h 06m | 19 | DIRECTING | slash-command,typed (162 chars) |
| `20260806T0757` | salt | 08-06 07:57 | 11:35 | 3h 37m | 104 | DIRECTING | interrupt,legacy-fallback,slash-command,typed (230 chars) |

## 4. Method notes

- A **block** is a run of human touches with no gap longer than 20 minutes. Its duration is last touch minus first touch, floored at 60 s for a single-touch block.
- **This under-counts, deliberately.** Reading and thinking before the first message of a block leave no trace in the transcript, so the figure is a *floor* on engaged time. It is published as a floor and never adjusted upward by estimate.
- **No manual time-tracking**, per the frozen design. Every timestamp comes from the transcript; the only human input is the category tag, and the rubric that assigns it is printed above the number.
- The touch filter is the one in `ledger_common.classify_user_record` — see `README.md`. Injected records (task notifications, loop ticks, cron pings, peer messages) are not human time.
- Touches read: 129 in window. Rejected as non-human across the whole record: 12,591.


---

## LANDED — generated from `git log`, never typed

Generated 2026-08-06 11:35 America/Los_Angeles by `docs/ledger-tools/landed.py`. Window: `2026-08-05 22:00` → `now`.

> **This table is mechanical.** It reports what was committed — hash, time, lane, size. It knows nothing about whether a thing *works*, whether a proof is *meaningful*, or what anyone intends next; those stay hand-written and stay stamped with the time they were written. **A commit hash does not age, which is the entire reason this is generated** (resource lesson 5: a snapshot of another seat's live tree ages in minutes).
> Seat attribution is a **heuristic over file paths**, from the writer-slot law in `docs/SEATS.md`. It is not a claim about who typed what.

### `saltworks` — 48 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| evidence | 32 | 6,948 | 0 |
| compiler (leg 2) | 7 | 1,076 | 658 |
| silicon (leg 3) | 7 | 1,801 | 543 |
| maestro | 2 | 386 | 263 |
| **total** | **48** | **10,211** | **1,464** |

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

### `salt` — 40 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| docs: exploration | 21 | 2,617 | 4 |
| docs: blueprints | 9 | 2,737 | 2,004 |
| salt: HB (Heath-Brown) | 6 | 1,441 | 1,441 |
| docs (shared) | 2 | 63 | 0 |
| salt: Weil | 1 | 361 | 361 |
| other | 1 | 0 | 0 |
| **total** | **40** | **7,219** | **3,810** |

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

**88 commits across 2 repo(s) in the window.**

