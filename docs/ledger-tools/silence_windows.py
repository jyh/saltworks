#!/usr/bin/env python3
"""The silence-window ledger -- what landed while no human was directing.

    python3 docs/ledger-tools/silence_windows.py \
        --repo ~/projects/claude/salt \
        --since '2026-07-23 00:00' --out /tmp/ledger.md

Owner: the EVIDENCE seat. Charter: docs/measurement-preregistration.md.
Methodology: salt triple-campaign Amendment 2 (task-notification
filtering) as implemented in ledger_common.classify_user_record, plus
this repo's docs/measurement-preregistration.md ADDENDUM 1 (2026-08-06).

WHAT THIS MEASURES, EXACTLY
---------------------------
git says when work landed. It cannot say whether a person was present.
The other half comes from the session transcripts: every moment a human
typed into a seat, invoked a slash command, or interrupted a response.
A commit's SILENCE WINDOW is the stretch between the last human touch
before it and the first human touch after it. A commit "landed inside a
>=1h silence window" if that stretch is at least an hour long -- not if
it happens to be an hour since the last message, which is the weaker
per-commit view (both are reported; the per-commit view understates).

WHAT IT DOES NOT MEASURE
------------------------
Not "the human was asleep". Personal-lane seats only (the employer lane
is never read -- see ledger_common.EMPLOYER_LANE). Read every window as
"no human direction reached the personal-lane fleet".
"""

from __future__ import annotations

import argparse
from bisect import bisect_left, bisect_right
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

import ledger_common as lc
from ledger_common import (
    Commit,
    ParseStats,
    Touch,
    day_local,
    discover_personal_projects,
    fmt_dur_h,
    fmt_hours,
    fmt_int,
    git_commits,
    human_touches,
    iso_local,
    now_local,
    project_dir_for_repo,
    rejection_table,
)

THRESHOLDS_H = (1, 2, 4, 8, 12)
DEFAULT_TOP = 10


def parse_local(s: str) -> datetime:
    """'2026-08-06 09:30' or '2026-08-06' -> tz-aware local datetime."""
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=lc.TZ)
        except ValueError:
            continue
    raise ValueError(f"cannot parse local time: {s!r}")


@dataclass
class Enclosing:
    prev: datetime | None
    nxt: datetime | None
    length_s: float  # a LOWER bound when open_start or open_end
    open_start: bool
    open_end: bool
    observed: bool = True


def enclosing_window(
    when: datetime,
    times: list[datetime],
    horizon: datetime,
    corpus_start: datetime | None,
) -> Enclosing:
    """The silent stretch containing `when`, given sorted human touches.

    Three cases the naive version gets wrong, all handled here:

    * ``when`` predates every transcript we can read — nothing is observed,
      so the window is UNMEASURED, not long and not zero. ``observed`` is
      False and the caller must exclude it from a share.
    * no human touch before ``when``, but the transcripts do cover that
      moment — the stretch is left-open and its length is measured from
      the first record we have. That is a lower bound, and a lower bound
      above a threshold still clears the threshold honestly.
    * no human touch after ``when`` — right-open, bounded at report time,
      also a lower bound.
    """
    if corpus_start is None or when < corpus_start:
        return Enclosing(None, None, 0.0, True, True, observed=False)
    i = bisect_right(times, when)
    prev = times[i - 1] if i > 0 else None
    nxt = times[i] if i < len(times) else None
    lo = prev if prev is not None else corpus_start
    hi = nxt if nxt is not None else horizon
    return Enclosing(
        prev=prev,
        nxt=nxt,
        length_s=max(0.0, (hi - lo).total_seconds()),
        open_start=prev is None,
        open_end=nxt is None,
    )


def longest_run(commits: list[Commit], times: list[datetime]) -> tuple[int, int, float]:
    """Longest run of consecutive commits with no human touch in between.

    Returns (start_index, count, span_seconds). The touch must fall
    strictly between the first and last commit of the run -- a touch at
    the very moment of a commit does not split it, and a run of one is
    always admissible.
    """
    best = (0, 1, 0.0)
    n = len(commits)
    i = 0
    while i < n:
        j = i
        while j + 1 < n:
            a, b = commits[j].when, commits[j + 1].when
            # any human touch in (a, b] breaks the run
            lo = bisect_right(times, a)
            hi = bisect_right(times, b)
            if hi > lo:
                break
            j += 1
        count = j - i + 1
        span = (commits[j].when - commits[i].when).total_seconds()
        if count > best[1] or (count == best[1] and span > best[2]):
            best = (i, count, span)
        i = j + 1
    return best


def build(args) -> str:
    repo = Path(args.repo).expanduser().resolve()
    repo_name = repo.name
    seat_dir = project_dir_for_repo(repo)

    # --- presence: the whole personal-lane fleet, and this seat alone -----
    if args.seat_only:
        presence_dirs = [seat_dir]
    elif args.project:
        presence_dirs = [Path(p).expanduser() for p in args.project]
    else:
        presence_dirs = discover_personal_projects()
    presence_dirs = [p for p in presence_dirs if p.is_dir()]

    fleet_touches, fleet_stats = human_touches(presence_dirs)
    seat_touches: list[Touch] = []
    seat_stats = ParseStats()
    if seat_dir.is_dir():
        seat_touches, seat_stats = human_touches([seat_dir])

    fleet_times = [t.when for t in fleet_touches]
    seat_times = [t.when for t in seat_touches]

    commits = git_commits(repo, args.since, args.until, ext=args.ext)
    horizon = now_local() if not args.until else parse_local(args.until)
    corpus_start = fleet_stats.corpus_start
    seat_corpus_start = seat_stats.corpus_start

    def encl(c: Commit, times=None, cstart=None) -> Enclosing:
        return enclosing_window(
            c.when,
            fleet_times if times is None else times,
            horizon,
            corpus_start if cstart is None else cstart,
        )

    observed = [c for c in commits if encl(c).observed]
    unobserved = [c for c in commits if not encl(c).observed]

    total_ins = sum(c.ext_insertions for c in commits)
    total_all = sum(c.insertions for c in commits)

    out: list[str] = []
    w = out.append

    w(f"# SILENCE-WINDOW LEDGER — `{repo_name}`")
    w("")
    w(f"Generated {iso_local(now_local())} America/Los_Angeles by "
      f"`docs/ledger-tools/silence_windows.py` (saltworks, EVIDENCE seat).")
    w(f"Window: `{args.since}` → `{args.until or 'now'}` · repo `{repo}` · "
      f"tracked extension `{args.ext}`.")
    w("")
    w("> **What a silence window is.** The stretch between the last moment a "
      "human touched any personal-lane seat and the next such moment. A "
      "commit landing inside a stretch of length ≥ T is counted at threshold "
      "T. **This is not a claim about sleep** — see §5.")
    w("")

    # ---- 1. scale ---------------------------------------------------------
    w("## 1. The window")
    w("")
    w("| Quantity | Value |")
    w("|---|---:|")
    w(f"| Commits | **{fmt_int(len(commits))}** |")
    w(f"| `{args.ext}` lines inserted | **{fmt_int(total_ins)}** |")
    w(f"| All lines inserted | {fmt_int(total_all)} |")
    if commits:
        w(f"| First commit | {iso_local(commits[0].when)} `{commits[0].sha[:7]}` |")
        w(f"| Last commit | {iso_local(commits[-1].when)} `{commits[-1].sha[:7]}` |")
    w(f"| Human touches read, personal-lane fleet (whole transcript record) | "
      f"**{fmt_int(len(fleet_touches))}** |")
    w(f"| — of which into this seat (`{seat_dir.name}`) | {fmt_int(len(seat_touches))} |")
    w(f"| Seats read for presence | {len(presence_dirs)} |")
    w(f"| Transcripts observe from | "
      f"{iso_local(corpus_start) if corpus_start else '—'} |")
    if unobserved:
        w(f"| Commits BEFORE any readable transcript (excluded from shares) | "
          f"**{fmt_int(len(unobserved))}** |")
    w("")
    if args.name_seats:
        w("Seats contributing presence: "
          + ", ".join(f"`{p.name}`" for p in presence_dirs) + ".")
    else:
        others = [p for p in presence_dirs if p != seat_dir]
        w(f"Seats contributing presence: this repo's own seat "
          f"(`{seat_dir.name}`)"
          + (f" and {len(others)} other personal-lane seats "
             f"(names withheld — pass `--name-seats` to list them)."
             if others else "."))
    w("")
    if commits and not args.seat_only:
        lo, hi = commits[0].when, commits[-1].when
        in_win = [t for t in fleet_touches if lo <= t.when <= hi]
        mine = sum(1 for t in in_win if t.project == seat_dir.name)
        w(f"Inside the commit window itself, the fleet received "
          f"**{fmt_int(len(in_win))}** human touches: **{fmt_int(mine)}** into "
          f"this seat and **{fmt_int(len(in_win) - mine)}** into every other "
          f"personal-lane seat combined."
          + (" The two measures therefore coincide, and the leg-1 caveat "
             "*“he may have been directing another seat”* is "
             "discharged for this window — within the personal lane."
             if len(in_win) == mine else ""))
        w("")
    if unobserved:
        w(f"> **{len(unobserved)} commit(s) in this window predate the earliest "
          f"transcript that can be read.** Presence is unknowable for them, so "
          f"they are excluded from every share below rather than counted as "
          f"silent. They are: "
          + ", ".join(f"`{c.sha[:7]}`" for c in unobserved[:12])
          + ("…" if len(unobserved) > 12 else "") + ".")
        w("")

    if not commits:
        w("_No commits in the window; nothing further to report._")
        return "\n".join(out)
    if not observed:
        w("_No commit in this window falls inside the observable transcript "
          "record; no silence figure can be computed._")
        return "\n".join(out)

    # ---- 2. the headline: window containment ------------------------------
    w("## 2. Landings inside a silence window — THE MEASURE THAT CARRIES THE CLAIM")
    w("")
    obs_ins = sum(c.ext_insertions for c in observed)
    obs_all = sum(c.insertions for c in observed)
    w("| Silence containing the landing | Commits | Share | "
      f"`{args.ext}` lines | All lines |")
    w("|---|---:|---:|---:|---:|")
    for h in THRESHOLDS_H:
        sel = [c for c in observed if encl(c).length_s >= h * 3600]
        w(f"| ≥ {h} h | {fmt_int(len(sel))} | {100*len(sel)/len(observed):.1f}% | "
          f"{fmt_int(sum(c.ext_insertions for c in sel))} | "
          f"{fmt_int(sum(c.insertions for c in sel))} |")
    w(f"| (all observed commits) | {fmt_int(len(observed))} | 100% | "
      f"{fmt_int(obs_ins)} | {fmt_int(obs_all)} |")
    w("")

    if not args.seat_only and seat_times:
        seat_observed = [c for c in commits
                         if encl(c, seat_times, seat_corpus_start).observed]
        if seat_observed:
            w("The same table against **this seat's transcript alone** — the "
              "leg-1 harvest's unit, kept for comparison. It is the larger "
              "number and the weaker claim, because the human may have been "
              "directing another seat at the time:")
            w("")
            w(f"| Silence containing the landing | Commits | Share | `{args.ext}` lines |")
            w("|---|---:|---:|---:|")
            for h in THRESHOLDS_H:
                sel = [c for c in seat_observed
                       if encl(c, seat_times, seat_corpus_start).length_s >= h * 3600]
                w(f"| ≥ {h} h | {fmt_int(len(sel))} | "
                  f"{100*len(sel)/len(seat_observed):.1f}% | "
                  f"{fmt_int(sum(c.ext_insertions for c in sel))} |")
            w(f"| (observed by this seat) | {fmt_int(len(seat_observed))} | 100% | "
              f"{fmt_int(sum(c.ext_insertions for c in seat_observed))} |")
            w("")

    # ---- 3. per-commit gap (the understating view) ------------------------
    w("## 3. Per-commit gap since the last human word")
    w("")
    w("_This view understates: a commit landing at hour 19 of a silence sits "
      "in the same bucket as one landing at hour 1. It is reported because a "
      "skeptic will compute it._")
    w("")
    buckets = [("< 30 min", 0, 1800), ("30–60 min", 1800, 3600), ("1–2 h", 3600, 7200),
               ("2–4 h", 7200, 14400), ("4–8 h", 14400, 28800), ("> 8 h", 28800, 10**9)]
    gaps = []
    for c in observed:
        e = encl(c)
        gaps.append((c.when - e.prev).total_seconds() if e.prev
                    else (c.when - corpus_start).total_seconds())
    w("| Gap since last human touch | Commits | Share |")
    w("|---|---:|---:|")
    for label, lo, hi in buckets:
        n = sum(1 for g in gaps if lo <= g < hi)
        w(f"| {label} | {fmt_int(n)} | {100*n/len(observed):.1f}% |")
    w("")

    # ---- 4. top windows ---------------------------------------------------
    w(f"## 4. The top {args.top} silence windows that contained landings")
    w("")
    groups: dict[tuple, list[Commit]] = {}
    for c in observed:
        e = encl(c)
        key = (e.prev, e.nxt)
        groups.setdefault(key, []).append(c)
    rows = []
    for (prev, nxt), cs in groups.items():
        e = encl(cs[0])
        rows.append((e.length_s, prev, nxt, cs, e))
    rows.sort(key=lambda r: -r[0])
    w(f"| Silence | From (last human touch) | To (next human touch) | Commits | "
      f"`{args.ext}` lines |")
    w("|---:|---|---|---:|---:|")
    for length_s, prev, nxt, cs, e in rows[: args.top]:
        frm = (iso_local(prev) if prev
               else f"_(open — silent from {iso_local(corpus_start)}, "
                    f"the first readable record)_")
        to = iso_local(nxt) if nxt else f"_(open — still silent at {iso_local(horizon)})_"
        w(f"| **{fmt_dur_h(length_s)}** | {frm} | {to} | {fmt_int(len(cs))} | "
          f"{fmt_int(sum(c.ext_insertions for c in cs))} |")
    w("")
    if rows:
        best = max(rows, key=lambda r: (len(r[3]), r[0]))
        w(f"**Best exhibit by commits landed:** {fmt_hours(best[0])} of silence "
          f"({iso_local(best[1]) if best[1] else 'open'} → "
          f"{iso_local(best[2]) if best[2] else 'open'}) carrying "
          f"**{len(best[3])} commits** and "
          f"**{fmt_int(sum(c.ext_insertions for c in best[3]))} `{args.ext}` lines**.")
        w("")

    # ---- 5. longest unbroken run -----------------------------------------
    i, count, span = longest_run(observed, fleet_times)
    w("## 5. The longest unbroken run")
    w("")
    w(f"**{count} consecutive commits**, {iso_local(observed[i].when)} → "
      f"{iso_local(observed[i+count-1].when)}, span **{fmt_hours(span)}**, with "
      f"zero human touches to any personal-lane seat between the first and the "
      f"last.")
    w("")
    if count > 1 and args.run_detail:
        w("| Time | Commit | Subject |")
        w("|---|---|---|")
        for c in observed[i : i + count]:
            subj = c.subject.replace("|", "\\|")
            if len(subj) > 90:
                subj = subj[:87] + "…"
            w(f"| {c.when.strftime('%m-%d %H:%M')} | `{c.sha[:7]}` | {subj} |")
        w("")

    # ---- 6. per-day -------------------------------------------------------
    w("## 6. Per day")
    w("")
    days: dict[str, list[Commit]] = {}
    for c in commits:
        days.setdefault(day_local(c.when), []).append(c)
    touch_days: dict[str, list[Touch]] = {}
    for t in fleet_touches:
        touch_days.setdefault(day_local(t.when), []).append(t)
    w(f"| Date | Dow | Commits | `{args.ext}` lines | In ≥1h silence | "
      f"Human touches (fleet) | First | Last |")
    w("|---|---|---:|---:|---:|---:|---|---|")
    for d in sorted(days):
        cs = days[d]
        sil = sum(1 for c in cs if encl(c).observed and encl(c).length_s >= 3600)
        ts = touch_days.get(d, [])
        first = ts[0].when.strftime("%H:%M") if ts else "—"
        last = ts[-1].when.strftime("%H:%M") if ts else "—"
        dow = cs[0].when.strftime("%a")
        w(f"| {d} | {dow} | {len(cs)} | {fmt_int(sum(c.ext_insertions for c in cs))} | "
          f"{sil} | {len(ts)} | {first} | {last} |")
    w("")

    # ---- 7. the night column, with its warning ---------------------------
    night = sum(1 for c in commits if c.when.hour >= 21 or c.when.hour < 5)
    w("## 7. The night column — reported so it is never quoted")
    w("")
    w(f"Commits in 21:00–04:59 local: **{night} of {len(commits)} "
      f"({100*night/len(commits):.1f}%)**.")
    w("")
    w("> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS** (salt triple-campaign "
      "Amendment 2, Correction 1). The night share is thin and a skeptic "
      "running `git log` will find it in thirty seconds. The claim that is "
      "true, larger, and checkable is §2.")
    w("")

    # ---- 8. methodology ---------------------------------------------------
    w("## 8. Methodology — the filter, disclosed")
    w("")
    w("Records with `\"type\": \"user\"` in a Claude Code transcript are **not "
      "all human**. The harness injects agent-completion notices, loop-timer "
      "ticks, cron pings, peer-seat messages and context-compaction summaries "
      "with `role: \"user\"`. The leg-1 harvest measured what happens if you "
      "count them: **98.5% of commits appeared to land within 30 minutes of a "
      "\"human message\"**, and filtering moved the ≥1h figure from **0.3% to "
      "21.5%**.")
    w("")
    w("This tool classifies by the record's own provenance fields — "
      "`origin.kind`, `promptSource`, `isMeta` — and falls back to string "
      "patterns only for records written by clients that predate them. "
      "Everything it threw away, over the seats read for presence:")
    w("")
    w(rejection_table(fleet_stats))
    w("")
    w("Notes on specific classes:")
    w("")
    w("- `task-notification` — the Amendment-2 class: an agent finished, and "
      "the notice is injected as a user turn.")
    w("- `harness-injection` — `isMeta` + `promptSource: system`: **`/loop` "
      "timer ticks and cron pings**. These fire *while the human is away*, "
      "which is exactly when they do the most damage to a silence figure. "
      "Some carry the human's own prompt text verbatim and are "
      "indistinguishable from a typed message by string matching alone.")
    w("- `peer` / `coordinator` — one seat messaging another.")
    w("- `compaction-summary` — the harness re-injecting a summary of the "
      "conversation so far.")
    w("- `slash-command` — **counted as human**. Typing `/model` at 03:00 "
      "proves a hand on the keyboard. The leg-1 harvest rejected these "
      "(214 of them); counting them can only *shorten* silence windows, "
      "which is the honest direction.")
    w("- `interrupt` — `[Request interrupted by user]`, an ESC press. Also "
      "counted as human, for the same reason.")
    w("- `legacy-fallback` — a record with no provenance fields that matched "
      "no injection pattern. Counted as human. If this number is large "
      "relative to `typed`, the fallback is doing real work and the figure "
      "deserves a manual sample.")
    w("")
    if fleet_stats.queue_corrections:
        w(f"**Queue correction.** {fmt_int(fleet_stats.queue_corrections)} messages "
          f"were typed while the model was busy; the transcript writes them at "
          f"dequeue time. Their `queue-operation: enqueue` timestamps were used "
          f"instead. Largest correction applied: "
          f"{fleet_stats.queue_max_shift_s:.0f} s.")
        w("")
    w(f"**Parse totals.** {fmt_int(fleet_stats.records)} records over "
      f"{fmt_int(fleet_stats.files)} session files; "
      f"{fmt_int(fleet_stats.user_records)} carried `type: user`; "
      f"{fmt_int(fleet_stats.bad_json)} lines failed to parse.")
    w("")
    w("**Git.** `--since`/`--until` always carry an explicit time under "
      "`TZ=America/Los_Angeles` with `--date=format-local`. A bare date is "
      "parsed as UTC and silently drops commits — measured in the leg-1 "
      "harvest at 654 vs 712 over the same nominal window. Merges are "
      "excluded. Insertion counts come from `--numstat`.")
    w("")

    # ---- 9. what this does not show --------------------------------------
    w("## 9. What this does NOT show")
    w("")
    w("1. **Not sleep.** Only personal-lane seats are read; the employer lane "
      "is excluded in code, unconditionally. JYH may have been awake and "
      "working elsewhere. Every window means *no human direction reached the "
      "personal-lane fleet*, and that is the sentence to publish.")
    w("2. **Silence is not absence of thought.** A frozen, refuter-attacked "
      "design written before the silence began is human direction that "
      "predates the window. The claim is about the *execution* loop running "
      "unattended, not about work appearing from nowhere.")
    w("3. **An open trailing window** (no human touch after the last commit) "
      "is bounded at generation time, so it grows until someone types. Rows "
      "affected are marked `(open …)`.")
    w("4. **Presence is per-machine.** Only transcripts under "
      "`~/.claude/projects/` on this machine are visible; a seat driven from "
      "another machine or the web app would not appear here.")
    w("")

    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", required=True, help="git repo whose commits are the ledger")
    ap.add_argument("--since", required=True,
                    help="explicit local time, e.g. '2026-07-23 00:00' (NEVER a bare date)")
    ap.add_argument("--until", default=None, help="explicit local time")
    ap.add_argument("--ext", default=".lean", help="tracked file extension (default .lean)")
    ap.add_argument("--project", action="append", default=None,
                    help="presence seat (project dir under ~/.claude/projects); repeatable")
    ap.add_argument("--seat-only", action="store_true",
                    help="presence = this repo's own seat only (the leg-1 unit)")
    ap.add_argument("--top", type=int, default=DEFAULT_TOP)
    ap.add_argument("--name-seats", action="store_true",
                    help="list every presence seat by name (default: withhold "
                         "the names of seats other than this repo's own)")
    ap.add_argument("--run-detail", action="store_true",
                    help="print every commit of the longest unbroken run")
    ap.add_argument("--out", default=None, help="write markdown here instead of stdout")
    args = ap.parse_args()

    md = build(args)
    if args.out:
        Path(args.out).expanduser().write_text(md)
        print(f"wrote {args.out} ({len(md.splitlines())} lines)")
    else:
        print(md)


if __name__ == "__main__":
    main()
