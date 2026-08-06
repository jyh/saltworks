#!/usr/bin/env python3
"""FLEET.md hygiene — which seats are alive, and which have gone quiet.

    python3 docs/ledger-tools/fleet_hygiene.py            # markdown report
    python3 docs/ledger-tools/fleet_hygiene.py --brief    # one line per seat

Owner: the EVIDENCE seat (charter item 4: "if a seat has not posted in 6h,
note it — the maestro reads your notes").

It distinguishes the two failure modes, which are NOT the same thing:

  SILENT    — the seat has not posted to FLEET.md in >6 h, but its
              transcript is still moving. It is working and not
              reporting. The bus is stale, the seat is not.
  STALLED   — the seat's transcript itself has not moved. Nobody is
              driving it. This is the one that needs a human.

Seat identity comes from the transcript's own `agent-name` record
(`agentName`), which is what `/agent-name` sets — the same string the seat
signs its FLEET.md posts with. No guessing from cwd or session id.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path

import ledger_common as lc
from ledger_common import (
    TZ,
    discover_personal_projects,
    fmt_hours,
    is_employer_lane,
    iso_local,
    now_local,
    parse_ts,
    session_files,
)

FLEET_MD = Path.home() / "projects" / "claude" / "FLEET.md"
QUIET_HOURS = 6.0

# "[8/6 09:20, evidence] ..."  /  "[8/6 morning, maestro] ..."
POST_RE = re.compile(r"^\[(\d{1,2})/(\d{1,2})\s+([^,\]]*?),\s*([A-Za-z][\w -]*)\]")


@dataclass
class Seat:
    name: str
    sessions: list[str] = field(default_factory=list)
    last_activity: datetime | None = None
    last_human: datetime | None = None
    project: str = ""

    def touch(self, when: datetime):
        if self.last_activity is None or when > self.last_activity:
            self.last_activity = when


def scan_seats(dirs) -> dict[str, Seat]:
    seats: dict[str, Seat] = {}
    for pdir in dirs:
        pdir = Path(pdir)
        if is_employer_lane(pdir.name):
            continue
        for path in session_files(pdir):
            name = None
            last = None
            last_human = None
            for line in open(path, errors="replace"):
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                if rec.get("type") == "agent-name" and rec.get("agentName"):
                    name = rec["agentName"]
                ts = rec.get("timestamp")
                if ts:
                    when = parse_ts(ts)
                    if last is None or when > last:
                        last = when
                    if rec.get("type") == "user":
                        verdict, _ = lc.classify_user_record(rec)
                        if verdict == "human" and (last_human is None or when > last_human):
                            last_human = when
            if last is None:
                continue
            key = name or f"(unnamed:{path.stem[:8]})"
            seat = seats.setdefault(key, Seat(name=key, project=pdir.name))
            seat.sessions.append(path.stem[:8])
            seat.touch(last)
            if last_human and (seat.last_human is None or last_human > seat.last_human):
                seat.last_human = last_human
    return seats


def scan_fleet_md(path: Path, year: int) -> dict[str, datetime]:
    """Last FLEET.md post per seat name (lower-cased)."""
    posts: dict[str, datetime] = {}
    if not path.is_file():
        return posts
    for line in path.read_text().splitlines():
        m = POST_RE.match(line.strip())
        if not m:
            continue
        month, day, timestr, seat = m.groups()
        hh, mm = 12, 0
        tm = re.match(r"^(\d{1,2}):(\d{2})", timestr.strip())
        if tm:
            hh, mm = int(tm.group(1)), int(tm.group(2))
        elif "morning" in timestr:
            hh = 8
        elif "night" in timestr or "evening" in timestr:
            hh = 21
        try:
            when = datetime(year, int(month), int(day), hh, mm, tzinfo=TZ)
        except ValueError:
            continue
        key = seat.strip().lower()
        if key not in posts or when > posts[key]:
            posts[key] = when
    return posts


def build(args) -> str:
    now = now_local()
    dirs = ([Path(p).expanduser() for p in args.project] if args.project
            else discover_personal_projects())
    seats = scan_seats([d for d in dirs if d.is_dir()])
    posts = scan_fleet_md(Path(args.fleet).expanduser(), now.year)

    rows = []
    for name, seat in seats.items():
        if seat.last_activity is None:
            continue
        idle_h = (now - seat.last_activity).total_seconds() / 3600
        if args.active_only and idle_h > args.active_hours:
            continue
        posted = posts.get(name.lower())
        post_h = (now - posted).total_seconds() / 3600 if posted else None
        rows.append((name, seat, idle_h, posted, post_h))
    rows.sort(key=lambda r: r[2])

    stalled = [r for r in rows if r[2] > QUIET_HOURS]
    silent = [r for r in rows if r[2] <= QUIET_HOURS and (r[4] is None or r[4] > QUIET_HOURS)]

    if args.brief:
        out = []
        for name, seat, idle_h, posted, post_h in rows:
            flag = "STALLED" if idle_h > QUIET_HOURS else (
                "SILENT" if (post_h is None or post_h > QUIET_HOURS) else "ok")
            out.append(f"{flag:8} {name:14} transcript {idle_h:5.1f}h ago · "
                       f"FLEET.md {'never' if post_h is None else f'{post_h:5.1f}h ago'}")
        return "\n".join(out)

    out: list[str] = []
    w = out.append
    w("## FLEET HYGIENE — seat liveness")
    w("")
    w(f"Checked {iso_local(now)} by `docs/ledger-tools/fleet_hygiene.py` "
      f"(evidence seat). Threshold: **{QUIET_HOURS:.0f} h**.")
    w("")
    w("| Seat | Repo | Last transcript activity | Last FLEET.md post | Last human touch | Verdict |")
    w("|---|---|---|---|---|---|")
    for name, seat, idle_h, posted, post_h in rows:
        verdict = ("⛔ **STALLED**" if idle_h > QUIET_HOURS else
                   ("⚠️ SILENT" if (post_h is None or post_h > QUIET_HOURS) else "✅ ok"))
        w(f"| `{name}` | {seat.project.replace('-Users-jyh-projects-claude-','')} | "
          f"{iso_local(seat.last_activity)} ({idle_h:.1f} h) | "
          f"{(iso_local(posted) + f' ({post_h:.1f} h)') if posted else '**never**'} | "
          f"{iso_local(seat.last_human) if seat.last_human else '—'} | {verdict} |")
    w("")
    w("**STALLED** = the transcript itself has not moved — nobody is driving "
      "the seat, and that is the one that needs a human. **SILENT** = the "
      "seat is working but has not posted to the bus; the bus is stale, the "
      "seat is not.")
    w("")
    if stalled:
        w(f"⛔ **{len(stalled)} stalled seat(s):** "
          + ", ".join(f"`{r[0]}` ({r[2]:.1f} h)" for r in stalled))
        w("")
    if silent:
        w(f"⚠️ **{len(silent)} seat(s) working but not reporting:** "
          + ", ".join(f"`{r[0]}`" for r in silent))
        w("")
    if not stalled and not silent:
        w("✅ Every seat is both alive and reporting.")
        w("")
    w("_Seat identity comes from each session's own `agent-name` record — "
      "the string the seat signs its posts with. Employer-lane projects are "
      "not scanned._")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fleet", default=str(FLEET_MD))
    ap.add_argument("--project", action="append", default=None)
    ap.add_argument("--brief", action="store_true")
    ap.add_argument("--active-only", action="store_true", default=True,
                    help="only seats seen recently (default on)")
    ap.add_argument("--all", dest="active_only", action="store_false")
    ap.add_argument("--active-hours", type=float, default=48.0)
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    md = build(args)
    if args.out:
        Path(args.out).expanduser().write_text(md)
        print(f"wrote {args.out}")
    else:
        print(md)


if __name__ == "__main__":
    main()
