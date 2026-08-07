# CAMPAIGN LEDGER — 2026-08-06

Nightly, from `docs/ledger-tools/nightly.sh`. Every table below is
regenerated from the git history and the session transcripts; nothing
here is typed by hand. The filter that decides what counts as a human
touch is disclosed inside each section, per
`docs/measurement-preregistration.md` and its ADDENDUM 1.

---

# SILENCE-WINDOW LEDGER — `saltworks`

Generated 2026-08-06 20:21 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/saltworks` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 351,923 liveness records at a **5-minute** tolerance.

**The tolerance, calibrated by this run rather than quoted from an earlier one** — a threshold is only honest while the data it separates stays separated:

| Calibration | Value |
|---|---:|
| Median commit → nearest record | **0.3 s** |
| p99 | 0.9 s |
| Worst commit still INSIDE the tolerance | **0.03 min** |
| Best commit OUTSIDE it (the nearest hole) | **22.19 min** |
| Separation | **787.0×** — **the threshold sits in an empty region** |

⛔ **1 of 163 commits landed in a stretch with NO transcript record.** Every silence figure below that contains one of these is a **lower bound on presence**: the human may have been directing and the evidence is missing, not absent. Do not publish a window containing these commits as unattended.

| Commit | Landed | Nearest transcript record | Subject |
|---|---|---:|---|
| `e3ea8f1` | 2026-08-06 14:30 | 22.2 min away | saltworks: third copy of the free-vs-available defect, a |

⚠️ **The narrower question this check actually answers:** *did work land inside a hole?* — not *is the record whole?* A hole in a stretch where nothing was committed leaves no trace here and is invisible to it. That is tolerable only because no published figure depends on such a stretch: the measure that carries the claim (§2) counts commits. It is stated rather than left to be discovered. **Known false-positive mode:** a commit made by hand from a terminal rather than by a seat would flag identically — measured at **0 occurrences in 862 commits on 2026-08-06** (a frozen figure, unlike the calibration table above, which this run computes), but the record cannot rule it out for a commit it has never seen.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **163** |
| `.lean` lines inserted | **4,270** |
| All lines inserted | 23,835 |
| First commit | 2026-08-05 22:05 `4fa92be` |
| Last commit | 2026-08-06 20:10 `380224d` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,152** |
| — of which into this seat (`-Users-jyh-projects-claude-saltworks`) | 96 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-saltworks`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **261** human touches: **92** into this seat and **169** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 163 | 100% | 4,270 | 23,835 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 37 | 23.4% | 1,637 |
| ≥ 2 h | 0 | 0.0% | 0 |
| ≥ 4 h | 0 | 0.0% | 0 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 158 | 100% | 4,007 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 162 | 99.4% |
| 30–60 min | 1 | 0.6% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **59 min** | 2026-08-06 13:57 | 2026-08-06 14:56 | 5 | 192 |
| **23 min** | 2026-08-06 12:20 | 2026-08-06 12:43 | 3 | 0 |
| **18 min** | 2026-08-06 16:15 | 2026-08-06 16:34 | 3 | 0 |
| **18 min** | 2026-08-06 08:36 | 2026-08-06 08:54 | 1 | 0 |
| **14 min** | 2026-08-06 16:36 | 2026-08-06 16:51 | 3 | 434 |
| **13 min** | 2026-08-06 17:28 | 2026-08-06 17:42 | 1 | 0 |
| **12 min** | 2026-08-06 07:57 | 2026-08-06 08:09 | 1 | 0 |
| **11 min** | 2026-08-06 19:49 | 2026-08-06 20:00 | 8 | 0 |
| **11 min** | 2026-08-06 18:48 | 2026-08-06 18:59 | 3 | 0 |
| **11 min** | 2026-08-06 17:09 | 2026-08-06 17:20 | 4 | 52 |

**Best exhibit by commits landed:** 0h 11m of silence (2026-08-06 19:49 → 2026-08-06 20:00) carrying **8 commits** and **0 `.lean` lines**.

## 5. The longest unbroken run

**8 consecutive commits**, 2026-08-06 19:51 → 2026-08-06 19:58, span **0h 06m**, with zero human touches to any personal-lane seat between the first and the last.

| Time | Commit | Subject |
|---|---|---|
| 08-06 19:51 | `9792baa` | saltworks: the muster RESULTS LEDGER — every count generated, every kernel verdict attr… |
| 08-06 19:52 | `4e40547` | saltworks: the compiler seat's muster line as a FILE — including the coverage fact that… |
| 08-06 19:53 | `53c1936` | saltworks: my own muster ledger said the default build covers all three legs — compiler… |
| 08-06 19:53 | `f86fbb0` | saltworks: my muster count had no window, and the Captain will read it beside a ledger … |
| 08-06 19:54 | `ae90e5a` | saltworks: two seats recomputed the numbers I attributed to them — both deltas publishe… |
| 08-06 19:55 | `05560cd` | saltworks: silicon's '11 lines of noise' is two exact differences that cancel — additio… |
| 08-06 19:56 | `739a60c` | saltworks: a generated table stops being generated the moment it is pasted — compiler w… |
| 08-06 19:58 | `d14563e` | saltworks: the day's principle in the form that survived — a true reading of an ADJACEN… |

## 6. Per day

| Date | Dow | Commits | `.lean` lines | In ≥1h silence | Human touches (fleet) | First | Last |
|---|---|---:|---:|---:|---:|---|---|
| 2026-08-05 | Wed | 1 | 262 | 0 | 45 | 07:06 | 22:19 |
| 2026-08-06 | Thu | 162 | 4,008 | 0 | 262 | 00:55 | 20:20 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **1 of 163 (0.6%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,905 |
| `slash-command` | **counted as human** | 151 |
| `legacy-fallback` | **counted as human** | 74 |
| `interrupt` | **counted as human** | 22 |
| `tool-result` | rejected | 12,804 |
| `task-notification` | rejected | 1,805 |
| `slash-command-echo` | rejected | 302 |
| `harness-injection` | rejected | 153 |
| `compaction-summary` | rejected | 28 |
| `system-reminder` | rejected | 2 |
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

**Queue correction.** 833 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 100,668 records over 19 session files; 17,249 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 20:21 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-08-05 22:00` → `now` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 351,923 liveness records at a **5-minute** tolerance.

**The tolerance, calibrated by this run rather than quoted from an earlier one** — a threshold is only honest while the data it separates stays separated:

| Calibration | Value |
|---|---:|
| Median commit → nearest record | **0.2 s** |
| p99 | 0.9 s |
| Worst commit still INSIDE the tolerance | **0.02 min** |
| Best commit OUTSIDE it (the nearest hole) | _none — nothing is flagged_ |

✅ **Every one of the 64 commits in this window has a transcript record beside it.** The silences below are measured.

⚠️ **The narrower question this check actually answers:** *did work land inside a hole?* — not *is the record whole?* A hole in a stretch where nothing was committed leaves no trace here and is invisible to it. That is tolerable only because no published figure depends on such a stretch: the measure that carries the claim (§2) counts commits. It is stated rather than left to be discovered. **Known false-positive mode:** a commit made by hand from a terminal rather than by a seat would flag identically — measured at **0 occurrences in 862 commits on 2026-08-06** (a frozen figure, unlike the calibration table above, which this run computes), but the record cannot rule it out for a commit it has never seen.

## 1. The window

| Quantity | Value |
|---|---:|
| Commits | **64** |
| `.lean` lines inserted | **4,489** |
| All lines inserted | 10,855 |
| First commit | 2026-08-05 22:06 `db277c4` |
| Last commit | 2026-08-06 19:23 `a593646` |
| Human touches read, personal-lane fleet (whole transcript record) | **2,152** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 2,013 |
| Seats read for presence | 6 |
| Transcripts observe from | 2026-07-07 07:18 |

Seats contributing presence: this repo's own seat (`-Users-jyh-projects-claude-salt`) and 5 other personal-lane seats (names withheld — pass `--name-seats` to list them).

Inside the commit window itself, the fleet received **251** human touches: **167** into this seat and **84** into every other personal-lane seat combined.

## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 | 0 |
| ≥ 2 h | 0 | 0.0% | 0 | 0 |
| ≥ 4 h | 0 | 0.0% | 0 | 0 |
| ≥ 8 h | 0 | 0.0% | 0 | 0 |
| ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 64 | 100% | 4,489 | 10,855 |

The same table against **this seat's transcript alone** — the leg-1 harvest's unit, kept for comparison. It is the larger number and the weaker claim, because the human may have been directing another seat at the time:

| Silence containing the landing | Commits | Share | `.lean` lines |
|---|---:|---:|---:|
| ≥ 1 h | 0 | 0.0% | 0 |
| ≥ 2 h | 0 | 0.0% | 0 |
| ≥ 4 h | 0 | 0.0% | 0 |
| ≥ 8 h | 0 | 0.0% | 0 |
| ≥ 12 h | 0 | 0.0% | 0 |
| (observed by this seat) | 64 | 100% | 4,489 |

## 3. Per-commit gap since the last human word

_This view understates: a commit landing at hour 19 of a silence sits in the same bucket as one landing at hour 1. It is reported because a skeptic will compute it._

| Gap since last human touch | Commits | Share |
|---|---:|---:|
| < 30 min | 64 | 100.0% |
| 30–60 min | 0 | 0.0% |
| 1–2 h | 0 | 0.0% |
| 2–4 h | 0 | 0.0% |
| 4–8 h | 0 | 0.0% |
| > 8 h | 0 | 0.0% |

## 4. The top 10 silence windows that contained landings

| Silence | From (last human touch) | To (next human touch) | Commits | `.lean` lines |
|---:|---|---|---:|---:|
| **59 min** | 2026-08-06 13:57 | 2026-08-06 14:56 | 1 | 0 |
| **15 min** | 2026-08-06 17:42 | 2026-08-06 17:57 | 1 | 130 |
| **15 min** | 2026-08-06 08:21 | 2026-08-06 08:36 | 2 | 4 |
| **13 min** | 2026-08-06 17:28 | 2026-08-06 17:42 | 1 | 0 |
| **9 min** | 2026-08-06 10:06 | 2026-08-06 10:15 | 5 | 849 |
| **9 min** | 2026-08-05 22:01 | 2026-08-05 22:11 | 1 | 0 |
| **8 min** | 2026-08-06 10:27 | 2026-08-06 10:36 | 2 | 216 |
| **8 min** | 2026-08-06 11:48 | 2026-08-06 11:57 | 4 | 218 |
| **8 min** | 2026-08-06 09:04 | 2026-08-06 09:12 | 1 | 0 |
| **8 min** | 2026-08-06 17:20 | 2026-08-06 17:28 | 1 | 201 |

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
| 2026-08-06 | Thu | 62 | 4,489 | 0 | 262 | 00:55 | 20:20 |

## 7. The night column — reported so it is never quoted

Commits in 21:00–04:59 local: **2 of 64 (3.1%)**.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign Amendment 2, Correction 1). The night share is thin and a skeptic running `git log` will find it in thirty seconds. The claim that is true, larger, and checkable is §2.

## 8. Methodology — the filter, disclosed

Records with `"type": "user"` in a Claude Code transcript are **not all human**. The harness injects agent-completion notices, loop-timer ticks, cron pings, peer-seat messages and context-compaction summaries with `role: "user"`. The leg-1 harvest measured what happens if you count them: **98.5% of commits appeared to land within 30 minutes of a "human message"**, and filtering moved the ≥1h figure from **0.3% to 21.5%**.

This tool classifies by the record's own provenance fields — `origin.kind`, `promptSource`, `isMeta` — and falls back to string patterns only for records written by clients that predate them. Everything it threw away, over the seats read for presence:

| Record class | Verdict | Count |
|---|---|---:|
| `typed` | **counted as human** | 1,905 |
| `slash-command` | **counted as human** | 151 |
| `legacy-fallback` | **counted as human** | 74 |
| `interrupt` | **counted as human** | 22 |
| `tool-result` | rejected | 12,804 |
| `task-notification` | rejected | 1,805 |
| `slash-command-echo` | rejected | 302 |
| `harness-injection` | rejected | 153 |
| `compaction-summary` | rejected | 28 |
| `system-reminder` | rejected | 2 |
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

**Queue correction.** 833 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 100,671 records over 19 session files; 17,249 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# SILENCE-WINDOW LEDGER — `salt`

Generated 2026-08-06 20:21 America/Los_Angeles by `docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).
Window: `2026-07-23 00:00` → `2026-08-06 00:00` · repo `/Users/jyh/projects/claude/salt` · tracked extension `.lean`.

> **What a silence window is.** The stretch between the last moment a human touched any personal-lane seat and the next such moment. A commit landing inside a stretch of length ≥ T is counted at threshold T. **This is not a claim about sleep** — see §5.

## 0. Record coverage — is the silence MEASURED, or merely UNRECORDED?

A commit is made **by** a session, and a session writes records. So a commit landing where no personal-lane session wrote anything at all is **proof of a hole in the transcript record**, not evidence that nobody was directing. Checked against 351,923 liveness records at a **5-minute** tolerance.

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
| Human touches read, personal-lane fleet (whole transcript record) | **2,152** |
| — of which into this seat (`-Users-jyh-projects-claude-salt`) | 2,013 |
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
| `typed` | **counted as human** | 1,905 |
| `slash-command` | **counted as human** | 151 |
| `legacy-fallback` | **counted as human** | 74 |
| `interrupt` | **counted as human** | 22 |
| `tool-result` | rejected | 12,804 |
| `task-notification` | rejected | 1,805 |
| `slash-command-echo` | rejected | 302 |
| `harness-injection` | rejected | 153 |
| `compaction-summary` | rejected | 28 |
| `system-reminder` | rejected | 2 |
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

**Queue correction.** 833 messages were typed while the model was busy; the transcript writes them at dequeue time. Their `queue-operation: enqueue` timestamps were used instead. Largest correction applied: 464 s.

**Parse totals.** 100,671 records over 19 session files; 17,249 carried `type: user`; 0 lines failed to parse.

**Git.** `--since`/`--until` always carry an explicit time under `TZ=America/Los_Angeles` with `--date=format-local`. A bare date is parsed as UTC and silently drops commits — measured in the leg-1 harvest at 654 vs 712 over the same nominal window. Merges are excluded. Insertion counts come from `--numstat`.

## 9. What this does NOT show

1. **Not sleep.** Only personal-lane seats are read; the outside lane is excluded in code, unconditionally. JYH may have been awake and working elsewhere. Every window means *no human direction reached the personal-lane fleet*, and that is the sentence to publish.
2. **Silence is not absence of thought.** A frozen, refuter-attacked design written before the silence began is human direction that predates the window. The claim is about the *execution* loop running unattended, not about work appearing from nowhere.
3. **An open trailing window** (no human touch after the last commit) is bounded at generation time, so it grows until someone types. Rows affected are marked `(open …)`.
4. **Presence is per-machine.** Only transcripts under `~/.claude/projects/` on this machine are visible; a seat driven from another machine or the web app would not appear here.


---

# TOKEN METER — the campaign ledger

Generated 2026-08-06 20:21 America/Los_Angeles by `docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per `docs/measurement-preregistration.md` §1.
Window: `2026-08-05 22:00` → `now` · 6 personal-lane projects · subagent transcripts INCLUDED.

> **Unit is TOKENS.** These records carry no prices and no account identifier, so no dollar figure and no per-account split is derivable from them. On a subscription, dollars are a flat envelope; the two framings are reported separately or not at all, never blended.
> **Cache is always its own column** and never enters a headline number.

## 1. Totals

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 8,142 |
| Input | 88,480 |
| **Output** | **4,317,380** |
| Cache created | 36,567,896 |
| Cache read | 1,932,656,358 |
| First request | 2026-08-05 22:02 |
| Last request | 2026-08-06 20:21 |

## 2. By project

| Project | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `-Users-jyh-projects-claude-saltworks` | 5,829 | 47,892 | **2,897,377** | 19,841,133 | 1,299,355,224 |
| `-Users-jyh-projects-claude-salt` | 2,313 | 40,588 | **1,420,003** | 16,726,763 | 633,301,134 |
| **TOTAL** | **8,142** | **88,480** | **4,317,380** | **36,567,896** | **1,932,656,358** |

## 3. By model tier

| Tier | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| Opus 5 | 7,592 | 75,474 | **3,732,104** | 32,865,772 | 1,703,129,377 |
| Fable 5 | 542 | 1,675 | **583,634** | 2,386,898 | 229,321,650 |
| Opus 4.8 | 2 | 4 | **1,632** | 1,248,389 | 26,022 |
| Haiku 4.5 | 6 | 11,327 | **10** | 66,837 | 179,309 |
| **TOTAL** | **8,142** | **88,480** | **4,317,380** | **36,567,896** | **1,932,656,358** |

## 4. By day

| Date | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| 2026-08-05 | 24 | 11,361 | **22,571** | 228,132 | 10,006,395 |
| 2026-08-06 | 8,118 | 77,119 | **4,294,809** | 36,339,764 | 1,922,649,963 |
| **TOTAL** | **8,142** | **88,480** | **4,317,380** | **36,567,896** | **1,932,656,358** |

## 5. Main loop vs subagents

| Where | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| main loop | 3,416 | 10,365 | **3,937,414** | 11,900,147 | 1,559,881,742 |
| subagents / workflow agents | 4,726 | 78,115 | **379,966** | 24,667,749 | 372,774,616 |
| **TOTAL** | **8,142** | **88,480** | **4,317,380** | **36,567,896** | **1,932,656,358** |

_In this window the subagents made **58% of the requests** and **9% of the output tokens** (main loop: 42% / 91%). Design and orchestration sat in the main loops; the agents were many but individually cheap._

## 6. By wave — timestamp-join against git

| Wave (leading tag of the landing commit's subject) | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `TAU-SHARP` | 646 | 7,834 | **429,089** | 3,687,676 | 102,336,755 |
| `MIGRATION-PROOF` | 186 | 354 | **146,414** | 1,194,960 | 77,830,330 |
| `N7-prep` | 153 | 294 | **113,016** | 1,105,430 | 68,140,310 |
| `WEIL-TRIO` | 159 | 309 | **85,167** | 2,672,942 | 42,134,402 |
| `HB` | 201 | 395 | **82,899** | 1,256,065 | 66,558,120 |
| `WEIL-TRIO-W1` | 166 | 1,899 | **60,635** | 753,450 | 36,487,132 |
| `WEIL-TRIO-W4A` | 159 | 4,753 | **46,901** | 669,615 | 38,594,703 |
| `TS-1` | 32 | 61 | **44,359** | 77,855 | 17,045,305 |
| `TS-2` | 38 | 71 | **36,053** | 194,116 | 8,699,561 |
| `SILICON` | 78 | 152 | **34,430** | 783,630 | 18,722,293 |
| `(unlabelled)` | 31 | 59 | **29,928** | 167,958 | 12,482,271 |
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
| `copyright` | 8 | 16 | **8,121** | 18,090 | 2,711,463 |
| `flags` | 13 | 24 | **8,007** | 44,231 | 3,476,615 |
| `WEIL-TRIO-W3` | 13 | 12,225 | **6,903** | 67,374 | 1,626,611 |
| `N7-PREP` | 11 | 22 | **6,038** | 32,195 | 3,749,893 |
| `GUARD` | 4 | 6 | **3,753** | 8,236 | 578,863 |
| `WEIL-TRIO-W4Q` | 5 | 9 | **3,010** | 17,873 | 1,051,418 |
| `WEIL-CONS` | 4 | 8 | **2,585** | 7,261 | 1,004,095 |
| **TOTAL** | **2,259** | **40,487** | **1,387,327** | **15,373,939** | **613,104,649** |

Attribution rule: each request is charged to the **next commit in `salt` at or after its timestamp**, if that commit lands within 4.0 h; otherwise it is unattributed. Unattributed in this window: 54 requests / 32,676 output tokens. Only requests from this repo's own seat (`-Users-jyh-projects-claude-salt`) are joined.

> **This join is a heuristic, and the table is labelled as one.** A request that produced no commit (a scout, a refuter, a council) is charged to whatever landed next. Read it as *tokens spent in the run-up to a landing*, never as *tokens the landing cost*.

## 7. Methodology — what was counted and what was thrown away

| Fact | Value |
|---|---:|
| Transcript files read | 2,370 |
| JSONL records scanned | 385,671 |
| Duplicate assistant records dropped (same `requestId`) | 121,128 |
| `<synthetic>` records dropped (API errors, zero usage) | 107 |
| Unparseable lines | 0 |

**The dedup rule.** Claude Code writes one assistant record per content block of a response, and **every one of those records repeats the whole `usage` block of the single API call**. Measured here: 121,128 records were duplicates of a request already counted. Summing records instead of requests would inflate every number in this file by roughly a factor of three. Usage was verified byte-identical within each `requestId` group before the rule was adopted.

**Subagents.** Workflow and Task agents write their own transcripts under `<session>/subagents/**/agent-*.jsonl`. They are included by default (`--no-subagents` to exclude). In THIS window they are 58% of requests and 9% of output tokens. **Request share and token share differ sharply and can point opposite ways** — quote whichever you mean, and never the word 'majority' unattached to a unit.

**Per-account attribution: UNAVAILABLE.** The transcripts carry no account, organisation or subscription identifier — checked field by field across every record type. The campaign runs five accounts; these files cannot say which one paid for a given request. Reported here as a gap rather than estimated.

**The firewall.** Outside-lane projects are excluded in code (`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure published from this tool is personal-lane only.


---

# HUMAN-TIME LEDGER — the four categories

Generated 2026-08-06 20:22 America/Los_Angeles by `docs/ledger-tools/human_time.py`, per `docs/measurement-preregistration.md` §2.
Window: `2026-08-05 22:00` → `now` · block gap 20 min · tags from `EVIDENCE-human-time-tags.tsv`.

**The rubric, published beside the number** — DIRECTING: rulings, councils, requirement-setting. REVIEWING: reading that *gates* an artifact. UNBLOCKING: logins, purchases, physical acts. WATCHING: curiosity — reading along, questions that redirect nothing. **The dependency claim = DIRECTING + REVIEWING + UNBLOCKING only**, by the counterfactual test *would the artifact exist without this touch?* WATCHING is reported as its own line, proudly: the joy is evidence, not overhead.

## 1. Totals

| Category | Blocks | Time | Share |
|---|---:|---:|---:|
| **DIRECTING** | 4 | 7h 00m | 58.6% |
| **UNBLOCKING** | 1 | 4h 55m | 41.1% |
| WATCHING | 2 | 0h 02m | 0.4% |
| **THE CLAIM** (D+R+U) | 5 | **11h 55m** | 99.6% |
| (all engaged time) | 7 | 11h 58m | 100% |

> ⛔ **2 TAG(S) MATCH NO BLOCK IN THIS WINDOW** and are contributing nothing: `20260805T1759`, `20260805T2039`. A block id is its first touch's timestamp, so changing `--since`, or one new message landing inside a former gap, merges blocks and detaches their tags. **Tags are matched by containment rather than by exact id precisely so this is visible instead of silent** — but a tag outside the window still needs re-pointing. Re-run the worksheet and re-tag.

## 2. Per day

| Date | Blocks | Engaged time | Claim time (D+R+U) | Messages |
|---|---:|---:|---:|---:|
| 2026-08-05 | 1 | 0h 17m | 0h 17m | 4 |
| 2026-08-06 | 6 | 11h 40m | 11h 38m | 262 |

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
| `20260806T1525` | saltworks | 08-06 15:25 | 20:20 | 4h 55m | 85 | UNBLOCKING | legacy-fallback,slash-command,typed (65 chars) |

## 4. Method notes

- A **block** is a run of human touches with no gap longer than 20 minutes. Its duration is last touch minus first touch, floored at 60 s for a single-touch block.
- **This under-counts, deliberately.** Reading and thinking before the first message of a block leave no trace in the transcript, so the figure is a *floor* on engaged time. It is published as a floor and never adjusted upward by estimate.
- **No manual time-tracking**, per the frozen design. Every timestamp comes from the transcript; the only human input is the category tag, and the rubric that assigns it is printed above the number.
- The touch filter is the one in `ledger_common.classify_user_record` — see `README.md`. Injected records (task notifications, loop ticks, cron pings, peer messages) are not human time.
- Touches read: 266 in window. Rejected as non-human across the whole record: 15,097.


---

## LANDED — generated from `git log`, never typed

Generated 2026-08-06 20:22 America/Los_Angeles by `docs/ledger-tools/landed.py`. Window: `2026-08-05 22:00` → `now`.

> **This table is mechanical.** It reports what was committed — hash, time, lane, size. It knows nothing about whether a thing *works*, whether a proof is *meaningful*, or what anyone intends next; those stay hand-written and stay stamped with the time they were written. **A commit hash does not age, which is the entire reason this is generated** (resource lesson 5: a snapshot of another seat's live tree ages in minutes).
> Seat attribution is a **heuristic over file paths**, from the writer-slot law in `docs/SEATS.md`. It is not a claim about who typed what.

### `saltworks` — 163 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| evidence | 96 | 11,838 | 0 |
| silicon (leg 3) | 33 | 7,451 | 1,455 |
| compiler (leg 2) | 27 | 4,096 | 2,503 |
| maestro (hub) | 4 | 35 | 20 |
| maestro | 3 | 415 | 292 |
| **total** | **163** | **23,835** | **4,270** |

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

### `salt` — 64 commits

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| docs: exploration | 36 | 4,433 | 4 |
| docs: blueprints | 14 | 4,016 | 2,641 |
| salt: HB (Heath-Brown) | 6 | 1,441 | 1,441 |
| docs (shared) | 2 | 63 | 0 |
| salt: Entropy/Chowla | 2 | 520 | 42 |
| salt: Weil | 1 | 361 | 361 |
| other | 1 | 0 | 0 |
| salt: papers | 1 | 1 | 0 |
| maestro (hub) | 1 | 20 | 0 |
| **total** | **64** | **10,855** | **4,489** |

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

**227 commits across 2 repo(s) in the window.**

