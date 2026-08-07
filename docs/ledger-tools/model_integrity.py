#!/usr/bin/env python3
"""Which MODEL actually served each message? Read the field, never the seat.

WHY THIS EXISTS. On 2026-08-07 the maestro session ran ~90 minutes on
`claude-opus-4-8` without announcing it, and **no session can detect this about
itself**: a model does not know which weights answered the last turn, and asking
it produces a confident answer from the wrong instrument. The Captain's eye
caught it; the transcript's per-message `message.model` field proved it.

    ⇒ Self-introspection is not an instrument. The field is.

This is the same shape as the account check (`~/.claude.json` reads the MACHINE,
not the seat) and the stamp audit (comparing stamps to stamps finds disagreement,
never error). Three instruments in two days, all with the same lesson: **the
answer has to come from outside the thing being measured.**

    python3 docs/ledger-tools/model_integrity.py                  # today, all personal-lane
    python3 docs/ledger-tools/model_integrity.py --day 2026-08-06
    python3 docs/ledger-tools/model_integrity.py --session 6215b448   # one seat, e.g. at boot

⛔ THE FIREWALL IS IN CODE, NOT IN A FLAG. `loca` and `holl` are employer-lane and
their transcripts are never opened; the guard raises rather than skipping, because
a silent skip is how a firewall stops being one.

EXIT: 0 every session stable · 1 a model CHANGED mid-session · 2 could not read
(no transcripts, no assistant records) -- the three-way exit this directory uses
everywhere, because a green from a tool that read nothing is worse than a red.

⚠️ A CHANGE IS NOT AUTOMATICALLY A FAULT. A seat legitimately relights on a
different model, and `/model` is a human action. What the tool asserts is that the
change is VISIBLE. An undisclosed change is the finding; a disclosed one is a fact.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import sys
from datetime import datetime, timedelta, timezone

PDT = timezone(timedelta(hours=-7))
PROJECTS = os.path.expanduser("~/.claude/projects")
EMPLOYER_LANE = ("loca", "holl")

# Personal-lane project directories this tool is allowed to read.
PERSONAL = ("-Users-jyh-projects-claude-salt",
            "-Users-jyh-projects-claude-saltworks",
            "-Users-jyh-projects-claude-saltworks-SaltWorks-Silicon")


class Unreadable(Exception):
    """Anything that would otherwise produce a green from an empty read."""


def _guard(path: str) -> None:
    """Employer-lane transcripts are never opened. Raises; never skips silently."""
    base = os.path.basename(path.rstrip("/"))
    for lane in EMPLOYER_LANE:
        if f"claude-{lane}" in base:
            raise Unreadable(f"FIREWALL: refusing to read outside-lane path {base}")


def runs_for(path: str, day: str | None):
    """[(start, end, model, n)] for one transcript, collapsed into contiguous runs.

    Filtered by the MESSAGE's own date, never the file's mtime -- a session file
    spans days, and mtime-filtering silently mixes them. (It did, on the first
    run of this code: a multi-day session printed a run reading "11:22 -> 09:06",
    start after end, which is what a lost date looks like.)
    """
    seq = []
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            if rec.get("type") != "assistant":
                continue
            msg = rec.get("message") or {}
            model, ts = msg.get("model"), rec.get("timestamp")
            if not model or not ts or model == "<synthetic>":
                continue
            when = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(PDT)
            if day and when.strftime("%Y-%m-%d") != day:
                continue
            seq.append((when, model))
    seq.sort(key=lambda x: x[0])
    runs: list[list] = []
    for when, model in seq:
        if runs and runs[-1][2] == model:
            runs[-1][1] = when
            runs[-1][3] += 1
        else:
            runs.append([when, when, model, 1])
    return runs


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--day", default=datetime.now(PDT).strftime("%Y-%m-%d"),
                    help="YYYY-MM-DD in PDT (default: today). 'all' for every day.")
    ap.add_argument("--session", help="match a session id prefix (a seat's own check)")
    a = ap.parse_args()
    day = None if a.day == "all" else a.day

    try:
        if not os.path.isdir(PROJECTS):
            raise Unreadable(f"no project directory at {PROJECTS}")
        files = []
        for name in PERSONAL:
            d = os.path.join(PROJECTS, name)
            _guard(d)
            if os.path.isdir(d):
                files.extend(glob.glob(os.path.join(d, "*.jsonl")))
        if not files:
            raise Unreadable("no personal-lane transcripts found")

        rows = []
        for f in files:
            sid = os.path.basename(f)[:8]
            if a.session and not sid.startswith(a.session[:8]):
                continue
            runs = runs_for(f, day)
            if runs:
                proj = os.path.basename(os.path.dirname(f)).split("claude-")[-1]
                rows.append((sid, proj, runs))
        if not rows:
            raise Unreadable(f"no assistant records for {a.day}"
                             + (f" in session {a.session}" if a.session else ""))

        rows.sort(key=lambda r: -sum(x[3] for x in r[2]))
        print(f"PER-MESSAGE MODEL FIELD — personal lane, {a.day}, by MESSAGE timestamp\n")
        changed = 0
        for sid, proj, runs in rows:
            n = sum(x[3] for x in runs)
            flag = "⛔ CHANGED" if len(runs) > 1 else "✅ stable"
            changed += len(runs) > 1
            print(f"{sid}  {proj:22s} {n:5d} msgs  {flag}")
            for start, end, model, cnt in runs:
                mins = int((end - start).total_seconds() // 60)
                print(f"    {start:%m-%d %H:%M} → {end:%H:%M}  ({mins:5d} min, {cnt:4d} msgs)  {model}")
        print(f"\n{changed} of {len(rows)} session(s) changed model.")
        if changed:
            print("⚠️  A change is not automatically a fault — a relight or a /model is legitimate.")
            print("   What this asserts is that the change is VISIBLE. Undisclosed is the finding.")
        return 1 if changed else 0
    except Unreadable as e:
        print(f"⛔ COULD NOT CHECK: {e}", file=sys.stderr)
        print("   exit 2 — this is NOT a pass. Nothing was verified.", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
