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
import os
import re
import time
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
BUILD_LOCK = Path("/tmp/salt-fleet-build.lock")

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


def machine_state() -> dict:
    """Lean/lake processes, the fleet build lock, RAM and swap.

    Written after the third OOM kill of 2026-08-06. The fleet was
    discovering violations by crashing; this finds them in one second,
    before the build starts. A Lean process running while the lock is
    unheld is a bare invocation — the thing the standing order forbids.
    """
    import subprocess

    state = {"procs": [], "lock_held": False, "lock_pid": None,
             "lock_orphaned": None, "lock_age_s": None,
             "ram_free_gb": None, "ram_inactive_gb": None,
             "swap_used_gb": None, "swap_free_gb": None}

    try:
        out = subprocess.run(["ps", "-eo", "pid,ppid,rss,etime,args"],
                             capture_output=True, text=True, timeout=20).stdout
        procs: dict[int, dict] = {}
        for line in out.splitlines()[1:]:
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            pid, ppid, rss, etime, args = parts
            procs[int(pid)] = {"pid": int(pid), "ppid": int(ppid),
                               "rss_gb": int(rss) / 1048576, "etime": etime,
                               "args": args}

        def under_wrapper(pid: int) -> bool:
            """Is any ancestor of this process a saltbuild.sh?

            Checking only "is the lock held" is not enough, and the third
            OOM of 2026-08-06 is why: 49 bare `lean` processes ran while a
            legitimate wrapper build also held the lock. Compliance is a
            property of each process's ancestry, not of the machine.
            """
            seen = set()
            cur = pid
            while cur > 1 and cur in procs and cur not in seen:
                seen.add(cur)
                if "saltbuild.sh" in procs[cur]["args"]:
                    return True
                cur = procs[cur]["ppid"]
            return False

        for p in procs.values():
            args = p["args"]
            base = args.split()[0].rsplit("/", 1)[-1] if args else ""
            # match the executables, not any path that happens to contain
            # the letters -- 'MobileSoftwareUpdate' is not a Lean build
            if base not in ("lean", "lake", "leanc"):
                continue
            if "saltbuild.sh" in args:
                continue
            # Lean's own memory cap, if this invocation carries one.
            # Whether -M actually binds a KERNEL reduction is an open
            # question on this fleet (math, FLEET.md 10:35): the cap is
            # enforced inside Lean, but a `decide +kernel` runaway lives
            # in kernel whnf, which may not sit on the checked allocation
            # path. If it does not bind, the wrapper's cap is cosmetic and
            # we are protected only in belief. Recording cap-vs-RSS on
            # every sample turns that question into a measurement: any
            # process whose RSS exceeds its own -M is a live proof that
            # -M does not bind THAT workload.
            cap_mb = None
            m = re.search(r"(?:-M|--memory=)\s*(\d+)", args)
            if m:
                cap_mb = int(m.group(1))
            state["procs"].append({
                "pid": p["pid"], "ppid_lake": p["ppid"], "rss_gb": p["rss_gb"],
                "etime": p["etime"],
                "args": args[:120], "wrapped": under_wrapper(p["pid"]),
                "cap_mb": cap_mb,
                "over_cap": bool(cap_mb and p["rss_gb"] * 1024 > cap_mb * 1.05),
            })
    except Exception:
        pass

    # --- the lock, and whether it is ORPHANED -----------------------------
    #
    # THE DEADLOCK THIS CATCHES (live on 2026-08-06 13:18, 70 minutes):
    # saltbuild.sh takes the lock with `mkdir` and THEN writes `pid` — two
    # operations. Anything that kills the holder in between leaves a lock
    # directory with NO pid file.
    #
    # THE OBSERVED TRIGGER WAS NOT A HARD KILL — the silicon seat corrected
    # their own first diagnosis at 13:31, and the real one is sharper:
    # **saltbuild.sh was EDITED IN PLACE while instances were running.**
    # bash reads a script incrementally by file offset, so an in-place edit
    # shifts the offsets under every running instance; they die mid-token
    # (`syntax error near unexpected token 'done'` is the signature), and a
    # dying instance never reaches `echo $$ > "$LOCK/pid"`. One had already
    # `mkdir`'d. So the `--cap` patch two seats had correctly asked for is
    # what took the fleet down, through no fault of its content.
    # Edit that file atomically (`cp` → edit → `bash -n` → `mv`) and this
    # trigger disappears; the check below remains as defence in depth. The wrapper's reaper is
    #     if [ -f "$LOCK/pid" ] && ! kill -0 "$(cat "$LOCK/pid")"; then rm -rf
    # so it reaps only when a pid file EXISTS and names a dead process.
    # **A pid-less lock is never reaped, by construction, and deadlocks the
    # entire fleet permanently.** Three fleet-wide kills today made it
    # certain.
    #
    # The legitimate pid-less window is MICROSECONDS. Anything longer is
    # the orphan state. Reporting "lock held" for it — which this detector
    # did until now — is indistinguishable from healthy, which is exactly
    # the failure mode this directory exists to catch.
    if BUILD_LOCK.is_dir():
        state["lock_held"] = True
        pid_file = BUILD_LOCK / "pid"
        if pid_file.is_file():
            try:
                state["lock_pid"] = int(pid_file.read_text().strip())
            except Exception:
                pass
            if state["lock_pid"]:
                try:
                    os.kill(state["lock_pid"], 0)
                except ProcessLookupError:
                    state["lock_orphaned"] = "pid %d is dead" % state["lock_pid"]
                except PermissionError:
                    pass
        else:
            try:
                age = time.time() - BUILD_LOCK.stat().st_mtime
            except Exception:
                age = 0.0
            state["lock_age_s"] = age
            if age > 5:
                state["lock_orphaned"] = (
                    "NO pid file, %.0f s old — the wrapper's reaper cannot "
                    "reap this, by construction" % age)

    try:
        import subprocess as sp
        vm = sp.run(["vm_stat"], capture_output=True, text=True, timeout=10).stdout
        page = 16384
        for line in vm.splitlines():
            if "page size of" in line:
                page = int(line.split("page size of")[1].split()[0])
            if line.startswith("Pages free:"):
                state["ram_free_gb"] = int(line.split()[2].strip(".")) * page / 1073741824
            # macOS "free" EXCLUDES inactive pages, which the kernel reclaims
            # on demand. Reporting free alone understates available memory —
            # measured 2026-08-06 14:02: free 0.07 GB while inactive held
            # 28.07 GB, i.e. the machine had ~28 GB available and my own
            # monitor was calling it an emergency. Same defect as everything
            # else in this directory: the instrument answered a narrower
            # question (how much is FREE) than the one that matters (how much
            # is AVAILABLE).
            if line.startswith("Pages inactive:"):
                state["ram_inactive_gb"] = int(line.split()[2].strip(".")) * page / 1073741824
        sw = sp.run(["sysctl", "-n", "vm.swapusage"], capture_output=True,
                    text=True, timeout=10).stdout
        for tok, key in (("used =", "swap_used_gb"), ("free =", "swap_free_gb")):
            if tok in sw:
                val = sw.split(tok)[1].split()[0]
                state[key] = float(val.rstrip("M")) / 1024 if val.endswith("M") else float(val.rstrip("G"))
    except Exception:
        pass
    return state


def machine_report(st: dict) -> list[str]:
    out = []
    procs = st["procs"]
    bare = [p for p in procs if not p.get("wrapped")]
    out.append("## Machine state — the build-etiquette detector")
    out.append("")
    out.append("| Check | Value |")
    out.append("|---|---|")
    out.append(f"| Lean/lake processes running | **{len(procs)}** "
               f"({len(procs) - len(bare)} under `saltbuild.sh`, "
               f"**{len(bare)} bare**) |")
    lock_cell = ("**⛔ ORPHANED — " + st["lock_orphaned"] + "**") if st.get("lock_orphaned") \
        else ("HELD by pid " + str(st["lock_pid"]) if st["lock_held"] else "not held")
    out.append(f"| Fleet build lock (`{BUILD_LOCK}`) | {lock_cell} |")
    if st["ram_free_gb"] is not None:
        inact = st.get("ram_inactive_gb") or 0.0
        out.append(f"| RAM free | {st['ram_free_gb']:.1f} GB |")
        out.append(f"| RAM inactive (**reclaimable**) | {inact:.1f} GB |")
        out.append(f"| **RAM available** (free + inactive — *the figure that "
                   f"matters on macOS*) | **{st['ram_free_gb'] + inact:.1f} GB** |")
    if st["swap_used_gb"] is not None:
        out.append(f"| Swap used / free | {st['swap_used_gb']:.1f} GB / "
                   f"{st['swap_free_gb']:.1f} GB |")
    out.append("")
    if st.get("lock_orphaned"):
        out.append(f"⛔⛔ **THE FLEET BUILD LOCK IS ORPHANED — EVERY QUEUED BUILD IS "
                   f"DEADLOCKED AND THE MACHINE MAY BE COMPLETELY IDLE.** "
                   f"{st['lock_orphaned']}. **The wrapper's reaper only reaps a lock "
                   f"whose `pid` file names a DEAD process — a lock with NO pid file "
                   f"is never reaped, by construction.** Verify no `lean`/`lake` is "
                   f"running, then `rmdir {BUILD_LOCK}`. *Clearing a stale runtime "
                   f"artifact is not editing the wrapper.*")
        out.append("")
        out.append("⚠️ **RE-CHECK IMMEDIATELY BEFORE YOU DELETE — NOT WHEN YOU "
                   "DECIDE TO.** The math seat came within three seconds of "
                   "reaping a lock that had just been legitimately re-acquired "
                   "(2026-08-06 13:21): their evidence was sound, their decision "
                   "was sound, and **the world moved between the decision and "
                   "the action**. This report is a snapshot; by the time you act "
                   "on it a real build may hold the lock. Re-run this check as "
                   "the last thing before `rmdir`, and abort if a pid file has "
                   "appeared or any `lean`/`lake` is running.")
        out.append("")

    if bare:
        out.append(f"⛔ **{len(bare)} BARE Lean/lake process(es) — no `saltbuild.sh` "
                   f"anywhere in their ancestry. This violates the standing order "
                   f"(FLEET.md, maestro, 8/6 09:22).**")
        out.append("")
        out.append("| PID | RSS | Elapsed | Command |")
        out.append("|---:|---:|---|---|")
        for p in sorted(bare, key=lambda p: -p["rss_gb"]):
            out.append(f"| {p['pid']} | {p['rss_gb']:.1f} GB | {p['etime']} | "
                       f"`{p['args']}` |")
        out.append("")
    elif procs:
        out.append(f"✅ {len(procs)} Lean process(es), **every one of them descended "
                   f"from `saltbuild.sh`** — compliant.")
        out.append("")

    # --- is Lean's own -M cap actually binding? -------------------------
    capped = [p for p in procs if p.get("cap_mb")]
    breached = [p for p in procs if p.get("over_cap")]
    if breached:
        out.append("⛔ **`-M` IS NOT BINDING THIS WORKLOAD — MEASURED, NOT INFERRED.** "
                   "A process is holding more RSS than its own Lean memory cap:")
        out.append("")
        out.append("| PID | `-M` cap | RSS | Verdict |")
        out.append("|---:|---:|---:|---|")
        for p in breached:
            out.append(f"| {p['pid']} | {p['cap_mb']} MB | "
                       f"**{p['rss_gb'] * 1024:.0f} MB** | cap exceeded |")
        out.append("")
        out.append("This is the outcome (b) the math seat asked about (FLEET.md "
                   "10:35): the wrapper's cap is **cosmetic for this shape of "
                   "work**, and the only real controls are the published "
                   "self-caps plus an OS bound Darwin does not provide. "
                   "**Post it to the bus.**")
        out.append("")
    elif capped:
        out.append(f"ℹ️ {len(capped)} process(es) carry a Lean `-M` cap "
                   f"({', '.join(str(p['cap_mb']) + ' MB' for p in capped)}) and "
                   f"none has exceeded it so far. **That is not yet proof the cap "
                   f"binds** — it is only proof this run has not tested it. The "
                   f"binding question is settled by a deliberate over-cap probe, "
                   f"not by observation of well-behaved runs.")
        out.append("")

    # --- per-build parallelism: the lock serialises BUILDS, not PROCESSES --
    if procs:
        by_parent: dict[int, list] = {}
        for p in procs:
            by_parent.setdefault(p.get("ppid_lake") or 0, []).append(p)
        heavy = sorted(procs, key=lambda p: -p["rss_gb"])[:4]
        total = sum(p["rss_gb"] for p in procs)
        out.append(f"**Concurrent Lean processes: {len(procs)}, "
                   f"{total:.1f} GB combined.** Largest: "
                   + ", ".join(f"{p['rss_gb']:.1f} GB" for p in heavy) + ".")
        out.append("")
        if len(procs) > 2 and total > 12:
            out.append("⚠️ **THE LOCK SERIALISES BUILDS, NOT PROCESSES.** One "
                       "compliant `saltbuild.sh` invocation can run several "
                       "`lean` children at once, and their memory ADDS. "
                       "`LEAN_NUM_THREADS` caps Lean's internal task pool — it "
                       "is not observed to cap how many `lean` processes lake "
                       "spawns. A single wrapped build is therefore not bounded "
                       "by one elaboration's cost.")
            out.append("")
    if st["swap_free_gb"] is not None and st["swap_free_gb"] < 2.0:
        out.append(f"⚠️ **Swap has only {st['swap_free_gb']:.1f} GB free** — RAM may "
                   f"read healthy while the machine is still fragile. macOS does not "
                   f"eagerly drain swap after a kill.")
        out.append("")
    return out


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

    st = machine_state() if not args.no_procs else None

    if args.brief:
        out = []
        if st is not None:
            n = len(st["procs"])
            nbare = sum(1 for p in st["procs"] if not p.get("wrapped"))
            if nbare:
                out.append(f"VIOLATION {nbare} BARE lean/lake proc(s) of {n} "
                           f"(no saltbuild.sh ancestor)")
            else:
                avail = (st["ram_free_gb"] or 0) + (st.get("ram_inactive_gb") or 0)
                lockstr = ("⛔ORPHANED" if st.get("lock_orphaned")
                           else ("held" if st["lock_held"] else "free"))
                out.append(f"machine   {n} lean proc(s), all wrapped · lock "
                           f"{lockstr} · RAM {avail:.0f}GB available "
                           f"(free {st['ram_free_gb']:.1f}) · "
                           f"swap {st['swap_free_gb']:.1f}GB free")
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
    w("")
    w("**Known blind spot:** this reads only `~/.claude/projects/` **for the "
      "user running it**. A seat driven from another account, another "
      "machine, or the web app is invisible here — it will never appear, "
      "stalled or otherwise. Absence from this table is not evidence a seat "
      "is down. (The maestro runs on a separate account and is expected to "
      "be absent.)")
    if st is not None:
        w("")
        out.extend(machine_report(st))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fleet", default=str(FLEET_MD))
    ap.add_argument("--project", action="append", default=None)
    ap.add_argument("--brief", action="store_true")
    ap.add_argument("--no-procs", action="store_true",
                    help="skip the machine-state / build-etiquette detector")
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
