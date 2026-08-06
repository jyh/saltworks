#!/usr/bin/env python3
"""The token meter — what the fleet spent, in tokens, by day/project/tier/wave.

    python3 docs/ledger-tools/token_meter.py \
        --since '2026-08-05 00:00' --repo ~/projects/claude/salt --out /tmp/tokens.md

Owner: the EVIDENCE seat. Charter: docs/measurement-preregistration.md §1,
frozen 2026-08-06 at Council I:

  Source: ~/.claude/projects/<project>/*.jsonl session + subagent
  transcripts (usage blocks: input/output/cache_creation/cache_read +
  model id). Tables: per-day x per-project x per-model-tier x per-wave
  (task attribution by timestamp-join against git commits). Cache ALWAYS
  a separate column, never in a headline. Unit: TOKENS (subscriptions
  make dollars a flat envelope — report both framings, never blend).
  Per-ACCOUNT attribution: report only what the records carry; if weak,
  say so in the table header.

Three implementation facts the pre-registration could not know, all
measured on this machine and disclosed in the output:

  1. One API response is written as SEVERAL assistant records (one per
     content block), each repeating the whole usage block. Events are
     deduplicated by requestId. Naive summation inflates by ~3x.
  2. The bulk of the fleet's tokens are in SUBAGENT transcripts
     (<session>/subagents/**/agent-*.jsonl), not the session file. In
     salt: 71,115 subagent requests against 11,350 top-level ones.
  3. The records carry NO account identifier of any kind. Per-account
     attribution is not derivable and the table header says so.
"""

from __future__ import annotations

import argparse
from bisect import bisect_left
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

import ledger_common as lc
from ledger_common import (
    day_local,
    discover_personal_projects,
    fmt_int,
    git_commits,
    iso_local,
    now_local,
    project_dir_for_repo,
    wave_label,
)

COLS = ("input", "output", "cache_creation", "cache_read")


def zero():
    return {"requests": 0, "input": 0, "output": 0, "cache_creation": 0, "cache_read": 0}


def add(acc, e):
    acc["requests"] += 1
    acc["input"] += e.input_tokens
    acc["output"] += e.output_tokens
    acc["cache_creation"] += e.cache_creation
    acc["cache_read"] += e.cache_read


def table(rows: dict, key_header: str, sort_key=None) -> list[str]:
    out = [
        f"| {key_header} | Requests | Input | Output | Cache created | Cache read |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    items = sorted(rows.items(), key=sort_key or (lambda kv: -kv[1]["output"]))
    tot = zero()
    for k, v in items:
        out.append(
            f"| {k} | {fmt_int(v['requests'])} | {fmt_int(v['input'])} | "
            f"**{fmt_int(v['output'])}** | {fmt_int(v['cache_creation'])} | "
            f"{fmt_int(v['cache_read'])} |"
        )
        for c in ("requests",) + COLS:
            tot[c] += v[c]
    out.append(
        f"| **TOTAL** | **{fmt_int(tot['requests'])}** | **{fmt_int(tot['input'])}** | "
        f"**{fmt_int(tot['output'])}** | **{fmt_int(tot['cache_creation'])}** | "
        f"**{fmt_int(tot['cache_read'])}** |"
    )
    return out


def build(args) -> str:
    since = None
    if args.since:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
            try:
                since = datetime.strptime(args.since, fmt).replace(tzinfo=lc.TZ)
                break
            except ValueError:
                continue
        if since is None:
            raise SystemExit(f"cannot parse --since {args.since!r}")
    until = None
    if args.until:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
            try:
                until = datetime.strptime(args.until, fmt).replace(tzinfo=lc.TZ)
                break
            except ValueError:
                continue

    if args.project:
        dirs = [Path(p).expanduser() for p in args.project]
    else:
        dirs = discover_personal_projects()
    dirs = [d for d in dirs if d.is_dir()]

    events, stats = lc.usage_events(dirs, include_subagents=not args.no_subagents)
    if since:
        events = [e for e in events if e.when >= since]
    if until:
        events = [e for e in events if e.when < until]

    out: list[str] = []
    w = out.append

    w("# TOKEN METER — the campaign ledger")
    w("")
    w(f"Generated {iso_local(now_local())} America/Los_Angeles by "
      f"`docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per "
      f"`docs/measurement-preregistration.md` §1.")
    w(f"Window: `{args.since or 'all'}` → `{args.until or 'now'}` · "
      f"{len(dirs)} personal-lane projects · subagent transcripts "
      f"{'EXCLUDED' if args.no_subagents else 'INCLUDED'}.")
    w("")
    w("> **Unit is TOKENS.** These records carry no prices and no account "
      "identifier, so no dollar figure and no per-account split is derivable "
      "from them. On a subscription, dollars are a flat envelope; the two "
      "framings are reported separately or not at all, never blended.")
    w("> **Cache is always its own column** and never enters a headline "
      "number.")
    w("")

    if not events:
        w("_No usage events in the window._")
        return "\n".join(out)

    grand = zero()
    for e in events:
        add(grand, e)

    w("## 1. Totals")
    w("")
    w("| Quantity | Tokens |")
    w("|---|---:|")
    w(f"| API requests (deduplicated) | {fmt_int(grand['requests'])} |")
    w(f"| Input | {fmt_int(grand['input'])} |")
    w(f"| **Output** | **{fmt_int(grand['output'])}** |")
    w(f"| Cache created | {fmt_int(grand['cache_creation'])} |")
    w(f"| Cache read | {fmt_int(grand['cache_read'])} |")
    w(f"| First request | {iso_local(events[0].when)} |")
    w(f"| Last request | {iso_local(events[-1].when)} |")
    w("")

    # --- by project --------------------------------------------------------
    w("## 2. By project")
    w("")
    rows = defaultdict(zero)
    for e in events:
        rows[f"`{e.project}`"] = rows[f"`{e.project}`"]
        add(rows[f"`{e.project}`"], e)
    out.extend(table(rows, "Project"))
    w("")

    # --- by model tier -----------------------------------------------------
    w("## 3. By model tier")
    w("")
    rows = defaultdict(zero)
    for e in events:
        add(rows[e.tier], e)
    out.extend(table(rows, "Tier"))
    w("")

    # --- by day ------------------------------------------------------------
    w("## 4. By day")
    w("")
    rows = defaultdict(zero)
    for e in events:
        add(rows[day_local(e.when)], e)
    out.extend(table(rows, "Date", sort_key=lambda kv: kv[0]))
    w("")

    # --- main vs subagent --------------------------------------------------
    if not args.no_subagents:
        w("## 5. Main loop vs subagents")
        w("")
        rows = defaultdict(zero)
        for e in events:
            add(rows["subagents / workflow agents" if e.subagent else "main loop"], e)
        out.extend(table(rows, "Where"))
        w("")
        w("_The fleet's work is done by the agents, and the table shows it. "
          "A meter that reads only the session file misses most of the spend._")
        w("")

    # --- by wave -----------------------------------------------------------
    if args.repo:
        repo = Path(args.repo).expanduser().resolve()
        commits = git_commits(repo, args.since or "2026-01-01 00:00", args.until, ext=args.ext)
        w("## 6. By wave — timestamp-join against git")
        w("")
        if not commits:
            w(f"_No commits in `{repo.name}` over the window; no wave attribution._")
            w("")
        else:
            times = [c.when for c in commits]
            rows = defaultdict(zero)
            lag = timedelta(hours=args.max_lag_h)
            unattributed = zero()
            seat_dir = project_dir_for_repo(repo)
            for e in events:
                if e.project != seat_dir.name:
                    continue
                i = bisect_left(times, e.when)
                if i < len(commits) and commits[i].when - e.when <= lag:
                    add(rows[f"`{wave_label(commits[i].subject)}`"], e)
                else:
                    add(unattributed, e)
            if rows:
                out.extend(table(rows, "Wave (leading tag of the landing commit's subject)"))
                w("")
            w(f"Attribution rule: each request is charged to the **next commit "
              f"in `{repo.name}` at or after its timestamp**, if that commit "
              f"lands within {args.max_lag_h} h; otherwise it is unattributed. "
              f"Unattributed in this window: {fmt_int(unattributed['requests'])} "
              f"requests / {fmt_int(unattributed['output'])} output tokens. "
              f"Only requests from this repo's own seat "
              f"(`{seat_dir.name}`) are joined.")
            w("")
            w("> **This join is a heuristic, and the table is labelled as one.** "
              "A request that produced no commit (a scout, a refuter, a council) "
              "is charged to whatever landed next. Read it as *tokens spent in "
              "the run-up to a landing*, never as *tokens the landing cost*.")
            w("")

    # --- methodology -------------------------------------------------------
    w("## 7. Methodology — what was counted and what was thrown away")
    w("")
    w("| Fact | Value |")
    w("|---|---:|")
    w(f"| Transcript files read | {fmt_int(stats.files)} |")
    w(f"| JSONL records scanned | {fmt_int(stats.records)} |")
    w(f"| Duplicate assistant records dropped (same `requestId`) | "
      f"{fmt_int(stats.dedup_dropped)} |")
    w(f"| `<synthetic>` records dropped (API errors, zero usage) | "
      f"{fmt_int(stats.synthetic_dropped)} |")
    w(f"| Unparseable lines | {fmt_int(stats.bad_json)} |")
    w("")
    w("**The dedup rule.** Claude Code writes one assistant record per "
      "content block of a response, and **every one of those records repeats "
      "the whole `usage` block of the single API call**. Measured here: "
      f"{fmt_int(stats.dedup_dropped)} records were duplicates of a request "
      "already counted. Summing records instead of requests would inflate "
      "every number in this file by roughly a factor of three. Usage was "
      "verified byte-identical within each `requestId` group before the rule "
      "was adopted.")
    w("")
    w("**Subagents.** Workflow and Task agents write their own transcripts "
      "under `<session>/subagents/**/agent-*.jsonl`. They are included by "
      "default (`--no-subagents` to exclude). They are the majority of the "
      "spend, and a meter that reads only the session file is wrong by an "
      "order of magnitude.")
    w("")
    w("**Per-account attribution: UNAVAILABLE.** The transcripts carry no "
      "account, organisation or subscription identifier — checked field by "
      "field across every record type. The campaign runs five accounts; "
      "these files cannot say which one paid for a given request. Reported "
      "here as a gap rather than estimated.")
    w("")
    w("**The firewall.** Outside-lane projects are excluded in code "
      "(`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure "
      "published from this tool is personal-lane only.")
    w("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--since", default=None, help="explicit local time, e.g. '2026-08-05 00:00'")
    ap.add_argument("--until", default=None)
    ap.add_argument("--project", action="append", default=None,
                    help="project dir under ~/.claude/projects; repeatable")
    ap.add_argument("--repo", default=None, help="repo for the per-wave timestamp join")
    ap.add_argument("--ext", default=".lean")
    ap.add_argument("--max-lag-h", type=float, default=4.0)
    ap.add_argument("--no-subagents", action="store_true")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    md = build(args)
    if args.out:
        Path(args.out).expanduser().write_text(md)
        print(f"wrote {args.out} ({len(md.splitlines())} lines)")
    else:
        print(md)


if __name__ == "__main__":
    main()
