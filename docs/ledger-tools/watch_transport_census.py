#!/usr/bin/env python3
"""
watch_transport_census.py — EVIDENCE seat, 2026-08-08 15:0x

WHY THIS EXISTS
---------------
At 15:02 math diagnosed its watch as MUTE (not deaf): a background task
reports to its seat only when it EXITS, so an unending capture delivers
nothing. At 15:03 the maestro RATIFIED the diagnosis fleet-wide with the
fix "EXIT-ON-HIT then re-arm". At 15:04 silicon contested the SCOPE: its
own `while true` watch, armed as a MONITOR, had never exited and had
delivered continuously -- so exit-on-hit would convert a healthy
streaming watch into a single-shot one.

Both peers argued from the SHAPE of the script. Shape is the wrong
object. This measures the two things that actually decide it:

  (A) ARM CENSUS      -- which TRANSPORT each seat armed, from the
                         sending seat's own tool_use records.
  (B) DELIVERY CENSUS -- how many notifications actually REACHED each
                         seat, from the RECEIVING seat's own transcript.

(B) is the ground truth. A mute watch produces zero arrivals no matter
what its filter scores on capture. Delivery has been argued all day and,
as far as the bus shows, never counted.

THE 2x2 (pre-registered BEFORE the run, per [[pre-register-the-criterion]])
--------------------------------------------------------------------------
                    | unbounded cmd            | bounded cmd
  ------------------+--------------------------+--------------------------
  Monitor           | HEALTHY-STREAM           | ends after its condition
                    | (streams per line)       | (usually intended)
  Bash(background)  | MUTE  <-- math's defect  | HEALTHY-ONESHOT
                    | (captures, never posts)  | (fires on exit)

PASS/FAIL BAR, fixed before any number is read:
  * If any seat shows Bash(background)+unbounded, math's diagnosis is
    confirmed for that seat and exit-on-hit is the right repair THERE.
  * If any seat shows Monitor+unbounded WITH arrivals in (B), silicon's
    correction is confirmed and the ratified order must not be applied
    to that seat.
  * Both can be true at once. That is the predicted outcome, and it is
    the reason the fleet-wide phrasing of the order is the defect.

SCOPE AND LIMITS -- stated in the output, not in a comment nobody reads
----------------------------------------------------------------------
  * This reads ARM RECORDS. An arm that was later TaskStop'd is
    indistinguishable here from one still running. It measures WHAT WAS
    ARMED, never WHAT IS LIVE.  [[adjacent-object-principle]]
  * (B) counts arrivals, not usefulness. A delivered bare header is an
    arrival.  [[act-on-the-notification-alone]]
  * Seats are read from their own per-seat config dirs. A seat with no
    dir is reported as NOT SCANNED, never as zero.  [[a-count-is-not-a-scope]]
"""

import json
import os
import sys
import glob
import datetime as _dt
import re
from collections import defaultdict

# ⛔⛔ THE SEAT MAP WAS A HARDCODED ENUMERATION AND IT READ 1 SEAT OF 8.
# Measured 2026-08-23 (bank item 3, open since 08/16):
#   "compiler"/"evidence"/"math"/"silicon" all mapped to the LITERAL string
#   "${SEAT_CONFIG_DIR}" — and the consumer calls os.path.expanduser(), which does
#   NOT expand variables (that is expandvars). So the path never resolved, the dir
#   never existed, and four seats scored NOT SCANNED. maestro was the only seat read.
#     5 names → 2 distinct paths → 1 scannable directory.
# 🔑 AND THE TWO FAILURE MODES ARE NOT THE SAME:
#     compiler/evidence/math/silicon  → in the map, unresolvable → NOT SCANNED (LOUD)
#     horatio / jas / verso           → NOT IN THE MAP AT ALL    → INVISIBLE (SILENT)
#   [[an-instrument-must-disclose-its-frame]]: a MISS is printed, an EXCLUSION is not.
#   The loud four were survivable; the silent three were the real defect, and no
#   amount of staring at the output would have revealed them.
# ⇒ DISCOVER the homes; do not enumerate them. [[a-count-is-not-a-scope]] — every hand
#   enumeration is a sampler, and this one sampled 1 of 8 while looking like 5 of 5.
# Root is env-overridable so the selftest can drive OTHER fixtures through the SAME
# function — a selftest inherits the scope of its fixtures.
SEAT_HOME_ROOT = os.path.expanduser(os.environ.get("SEAT_HOME_ROOT", "~"))

def discover_seats(root=None):
    """Seat name -> config home, by DISCOVERY. maestro is ~/.claude; every other
    seat is ~/.claude-seat-<name>. Returns {} if the root holds none, which the
    caller must report LOUDLY rather than treat as 'no seats'."""
    base = root if root is not None else SEAT_HOME_ROOT
    found = {}
    m = os.path.join(base, ".claude")
    if os.path.isdir(m):
        found["maestro"] = m
    for path in sorted(glob.glob(os.path.join(base, ".claude-seat-*"))):
        if os.path.isdir(path):
            found[os.path.basename(path)[len(".claude-seat-"):]] = path
    return found

SEATS = discover_seats()

# ⛔ AN ENUMERATION THAT RETURNS ZERO MUST FAIL LOUD, NOT QUIETLY.
# The predecessor's failure was survivable only because it printed NOT SCANNED per
# seat. Discovery has no such per-seat row to print when it finds NOTHING — an empty
# map would walk zero directories and report "no watches", which is exactly what a
# healthy-and-quiet fleet looks like. A broken instrument must not be able to imitate
# a calm one. [[watch-transport-not-shape]]: silence is the universal symptom.
if not SEATS:
    sys.stderr.write(
        "⛔ watch_transport_census: DISCOVERED ZERO SEAT HOMES under "
        + SEAT_HOME_ROOT
        + " — refusing to report. This is an instrument failure, NOT an empty fleet.\n"
    )
    sys.exit(2)

# An "unbounded" command cannot terminate on its own.
#
# ⛔ THIS REGEX WAS WRONG TWICE ON ITS FIRST RUN, BOTH TIMES IN THE
# REASSURING DIRECTION (a MUTE watch scored as healthy):
#   (1) `tail -[fF]` missed `tail -n 0 -f` -- the maestro's actual watch --
#       because flags may sit between the command and the -f.
#   (2) it read the COMMAND STRING only, so every seat that armed a SCRIPT
#       FILE (`busmon-math-v9.sh`) scored bounded no matter what the script
#       does. That is exactly where the seats put their loops, so the
#       detector was blind precisely where the population lives.
# Both are [[a-count-is-not-a-scope]]: a true reading of the command line,
# which is not the object. `resolve_unbounded` now follows one level of
# script indirection and says so when it CANNOT read the script.
UNBOUNDED = re.compile(
    r"while\s+true|while\s+:|\btail\b[^|;&]*?\s-[a-zA-Z]*[fF]\b"
    r"|inotifywait\s+-m|for\s*\(\(\s*;\s*;\s*\)\)"
)

SCRIPT_PATH = re.compile(r"(/[^\s'\"]+\.sh)")

# ⛔ AND A THIRD CORRECTION, THE ONE THAT MATTERED MOST. The regex above
# scored math's v10 -- the REPAIRED watch, which math had just measured
# firing in production -- as MUTE, because it contains `while true`. It
# also contains `exit 0` on an order-bearing hit. A loop that CAN
# terminate is not an unbounded command, and "has a loop" is not the
# question. My instrument contradicted a peer's live measurement, and the
# instrument was wrong.  [[instrument-inside-the-system]]
#
# ⇒ The state is THREE-valued, not two:
#     NO-LOOP       runs once and exits
#     LOOP-EXIT     loops but exits on a condition   (math's v10)
#     LOOP-FOREVER  cannot terminate on its own      (math's v9)
LOOP_EXIT = re.compile(r"^\s*(exit|break)\b", re.M)


def loop_kind(cmd):
    """Return (kind, basis). Follows ONE level of script indirection.

    basis is reported so a verdict resting on an unreadable script is never
    silently identical to one resting on a script that was read."""
    cmd = cmd or ""

    def kind_of(body):
        if not UNBOUNDED.search(body):
            return "NO-LOOP"
        return "LOOP-EXIT" if LOOP_EXIT.search(body) else "LOOP-FOREVER"

    if UNBOUNDED.search(cmd):
        return kind_of(cmd), "command"
    for path in SCRIPT_PATH.findall(cmd):
        try:
            with open(path, errors="replace") as fh:
                body = fh.read()
        except OSError:
            return "UNREADABLE", "SCRIPT-UNREADABLE"   # cannot clear it; say so
        if UNBOUNDED.search(body):
            return kind_of(body), "script:" + os.path.basename(path)
    return "NO-LOOP", "command"

# ⛔⛔ THIS WAS A LITERAL: DAY = "2026-08-08". It sat here for 15 days and the census
# went on filtering every seat's arms to a fortnight-old date, printing that date in
# its own header where I read past it. My own provenance rule, on my own tool:
#     COPIED OUT OF THE OBJECT you are reading  → cannot go stale.  SAFE
#     TYPED FROM YOUR MODEL OF "NOW"            → stale the moment now moves.  DEFECT
# ⚠️ AND IT NEARLY SURVIVED ITS OWN REPAIR: I fixed the SEAT MAP first (1 seat → 8) and
#   the output became MORE AUTHORITATIVE WITHOUT BECOMING MORE CORRECT — eight seats
#   confidently tabulated against the wrong day. seats showing all-zero read as "no
#   arms" when they meant "no arms ON 08/08".
#   ⇒ A PARTIAL REPAIR THAT RAISES APPARENT CREDIBILITY IS WORSE THAN NO REPAIR, because
#     the remaining defect now travels inside a result people trust.
# Default = today, DERIVED. Pinnable via CENSUS_DAY for reproducing a past census —
# which is the only legitimate reason a date should ever be a constant here.
DAY = os.environ.get("CENSUS_DAY") or _dt.datetime.now().astimezone().strftime("%Y-%m-%d")


def records(path):
    try:
        with open(path, errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    yield json.loads(line)
                except Exception:
                    continue
    except OSError:
        return


# THE FULL TAXONOMY — transport x loop-kind. Six cells, and the two the
# fleet argued about at 15:02-15:04 are one row of it.
#
#                | NO-LOOP           | LOOP-EXIT             | LOOP-FOREVER
#  --------------+-------------------+-----------------------+---------------
#  Monitor       | MONITOR-ONESHOT   | ⚠️ STREAM-THEN-STOPS  | ✅ STREAM
#                | (intended)        | THE TRAP CELL         | (best watch)
#  Bash(bg)      | ✅ FIRES-ON-EXIT  | ✅ PUSH-ON-HIT        | ⛔ MUTE
#                | (intended)        | (math's v10)          | (math's v9)
#
# ⚠️ THE TRAP CELL IS THE POINT. The 15:03 ratified order ("EXIT-ON-HIT,
# fleet-wide") moves the Monitor row RIGHTWARD-to-LEFTWARD: a healthy
# streaming watch becomes one that delivers a single event and then stops
# watching, silently. That is silicon's 15:04 objection, and this is the
# cell it names.
TAXONOMY = {
    ("Monitor",  "NO-LOOP"):      "MONITOR-ONESHOT",
    ("Monitor",  "LOOP-EXIT"):    "STREAM-THEN-STOPS",
    ("Monitor",  "LOOP-FOREVER"): "HEALTHY-STREAM",
    ("Bash(bg)", "NO-LOOP"):      "FIRES-ON-EXIT",
    ("Bash(bg)", "LOOP-EXIT"):    "PUSH-ON-HIT",
    ("Bash(bg)", "LOOP-FOREVER"): "MUTE",
}


def classify(transport, cmd):
    kind, basis = loop_kind(cmd)
    if kind == "UNREADABLE":
        # The script is gone (scratchpad reaped). We cannot clear it and we
        # must not score it healthy by default -- that is the reassuring
        # direction this file has already fallen into once.
        return "UNKNOWN-SCRIPT", kind, basis
    return TAXONOMY[(transport, kind)], kind, basis


def scan():
    arms = defaultdict(list)
    arrivals = defaultdict(list)
    scanned = {}

    for seat, root in SEATS.items():
        base = os.path.expanduser(root)
        files = sorted(glob.glob(os.path.join(base, "projects", "*", "*.jsonl")))
        if not os.path.isdir(base):
            scanned[seat] = None          # NOT SCANNED, distinct from zero
            continue
        scanned[seat] = files

        for path in files:
            for d in records(path):
                ts = (d.get("timestamp") or "")
                msg = d.get("message") or {}
                content = msg.get("content")

                # (A) arms -- tool_use blocks in assistant records
                if isinstance(content, list):
                    for b in content:
                        if not (isinstance(b, dict) and b.get("type") == "tool_use"):
                            continue
                        name = b.get("name")
                        inp = b.get("input") or {}
                        if name == "Monitor":
                            cmd = inp.get("command") or ("<ws:" + str((inp.get("ws") or {}).get("url")) + ">")
                            verdict, unb, basis = classify("Monitor", cmd)
                            arms[seat].append((ts, "Monitor", verdict, unb,
                                               bool(inp.get("persistent")), cmd, basis))
                        elif name == "Bash" and inp.get("run_in_background"):
                            cmd = inp.get("command") or ""
                            verdict, unb, basis = classify("Bash(bg)", cmd)
                            arms[seat].append((ts, "Bash(bg)", verdict, unb, False, cmd, basis))

                # (B) arrivals -- task notifications land as text in the
                # RECEIVING seat's own record.
                text = ""
                if isinstance(content, str):
                    text = content
                elif isinstance(content, list):
                    text = " ".join(
                        b.get("text", "") for b in content
                        if isinstance(b, dict) and b.get("type") == "text"
                    )
                if "<task-notification>" in text:
                    kind = "monitor" if "Monitor event" in text else "other"
                    arrivals[seat].append((ts, kind, len(text)))

    # ⛔ DEFECT FOUND IN THIS FILE'S FIRST RUN, 15:1x: files are globbed in
    # NAME order, so `rows[0]`/`rows[-1]` printed the first and last records
    # of the last-named FILE, not of the DAY. compiler read "first 20:43:49
    # last 20:10:32" -- a first LATER than its last, which is the only reason
    # I caught it. An unsorted min/max is a true reading of an adjacent
    # object.  [[adjacent-object-principle]]
    for bucket in (arms, arrivals):
        for seat in bucket:
            bucket[seat].sort(key=lambda r: r[0])

    return arms, arrivals, scanned


def local(ts):
    """Records stamp UTC; the fleet speaks PDT. A census quoted in the wrong
    zone is off by seven hours and still looks plausible."""
    if not ts:
        return "--:--:--"
    try:
        from datetime import datetime, timezone
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return dt.astimezone().strftime("%H:%M:%S")
    except Exception:
        return ts[11:19] + "Z"


def local_date(ts):
    try:
        from datetime import datetime
        return datetime.fromisoformat((ts or "").replace("Z", "+00:00")) \
                       .astimezone().strftime("%Y-%m-%d")
    except Exception:
        return ""


# A bus watch is the only population the 15:02-15:04 dispute is about.
IS_WATCH = re.compile(r"FLEET\.md|bus_watch|busmon", re.I)


def main():
    arms, arrivals, scanned = scan()

    print("=" * 74)
    print("WATCH TRANSPORT CENSUS — evidence seat")
    print("=" * 74)

    print("\n--- SCOPE (files actually read; a seat with no dir says so) ---")
    for seat in SEATS:
        f = scanned.get(seat)
        if f is None:
            print(f"  {seat:9s} NOT SCANNED — no config dir")
        else:
            print(f"  {seat:9s} {len(f)} transcript file(s)")

    def today(rows):
        return [r for r in rows if local_date(r[0]) == DAY]

    print(f"\n--- (A) ARM CENSUS — all background/monitor arms, {DAY} PDT ---")
    print("    (arms, not liveness: a TaskStop'd arm looks identical here)")
    cols = ["MUTE", "STREAM-THEN-STOPS", "HEALTHY-STREAM", "PUSH-ON-HIT",
            "FIRES-ON-EXIT", "MONITOR-ONESHOT", "UNKNOWN-SCRIPT"]
    hdr = {"MUTE": "MUTE", "STREAM-THEN-STOPS": "TRAP", "HEALTHY-STREAM": "STREAM",
           "PUSH-ON-HIT": "ONHIT", "FIRES-ON-EXIT": "1SHOT",
           "MONITOR-ONESHOT": "M-1SHOT", "UNKNOWN-SCRIPT": "UNKNOWN"}
    print("    " + f"{'seat':9s}" + "".join(f"{hdr[k]:>8s}" for k in cols))
    for seat in SEATS:
        if scanned.get(seat) is None:
            continue
        c = defaultdict(int)
        for r in today(arms.get(seat, [])):
            c[r[2]] += 1
        print("    " + f"{seat:9s}" + "".join(f"{c[k]:8d}" for k in cols))

    print(f"\n--- (A2) THE BUS WATCHES ONLY — the population in dispute ---")
    print("    (a bus watch = command naming FLEET.md / bus_watch / busmon)")
    for seat in SEATS:
        if scanned.get(seat) is None:
            continue
        rows = [r for r in today(arms.get(seat, [])) if IS_WATCH.search(r[5] or "")]
        print(f"\n  {seat.upper()}  ({len(rows)} bus-watch arm(s))")
        if not rows:
            print("    (none on record — this seat armed no bus watch today,")
            print("     or armed it before the window scanned)")
        for ts, transport, verdict, unb, persistent, cmd, basis in rows:
            flag = {"MUTE": "⛔ MUTE           ",
                    "STREAM-THEN-STOPS": "⚠️  STREAM-THEN-STOP",
                    "HEALTHY-STREAM": "✅ STREAMS        ",
                    "PUSH-ON-HIT": "✅ PUSH-ON-HIT    ",
                    "FIRES-ON-EXIT": "✅ FIRES-ON-EXIT  ",
                    "MONITOR-ONESHOT": "✅ MONITOR/1shot  ",
                    "UNKNOWN-SCRIPT": "❓ UNKNOWN        "}[verdict]
            print(f"    {flag} {local(ts)}  {transport:10s} persist={str(persistent):5s}"
                  f" basis={basis}")
            print(f"         {' '.join((cmd or '').split())[:120]}")

    print(f"\n--- (B) DELIVERY CENSUS — notifications that ARRIVED, {DAY} PDT ---")
    print("    read from each RECEIVING seat's own transcript = ground truth.")
    print("    THIS IS THE MEASUREMENT THE DISPUTE NEEDED: a mute watch")
    print("    delivers zero no matter what its filter scores on capture.")
    zero_seats, live_seats = [], []
    for seat in SEATS:
        if scanned.get(seat) is None:
            continue
        rows = today(arrivals.get(seat, []))
        mon = [r for r in rows if r[1] == "monitor"]
        if rows:
            live_seats.append(seat)
            print(f"  {seat:9s} {len(rows):4d} arrival(s)  "
                  f"({len(mon):3d} monitor-event)  "
                  f"first {local(rows[0][0])}  last {local(rows[-1][0])}")
        else:
            zero_seats.append(seat)
            print(f"  {seat:9s} {0:4d} arrival(s)  ⛔ NOTHING EVER REACHED THIS SEAT")

    # ⛔⛔ AN EMPTY RESULT IS AN INSTRUMENT READING, NOT A FACT ABOUT THE WORLD.
    # Adopted from silicon, 2026-08-08 17:09, after TWO seats searched the same
    # post with two UNRELATED defects (mine: headers only; theirs: a lowercase
    # regex against a CAPS heading) and reached one identical false "there is
    # none". An empty result is the single output that looks the same whether or
    # not you asked correctly -- the shape of an armed-dead monitor and a quiet
    # bus, one layer up.
    # ⇒ THE POSITIVE CONTROL ON THE QUERY ITSELF: this scan claims to detect
    # arrivals. If it detects NONE ANYWHERE, the likeliest explanation is that the
    # detector is broken, not that five seats simultaneously went deaf -- and a
    # dramatic finding is exactly what a broken detector produces here.
    if not live_seats:
        print("\n  ⛔⛔ ZERO ARRIVALS ACROSS EVERY SEAT SCANNED.")
        print("      DO NOT REPORT THIS AS A FLEET-WIDE OUTAGE. With no seat")
        print("      showing a single arrival, the detector has not demonstrated")
        print("      it can detect anything, so 'none' and 'unasked' are the same")
        print("      reading. Verify the notification marker still matches the")
        print("      transcript format BEFORE drawing any conclusion.")
    else:
        # ⛔ FOUND 17:2x BY APPLYING SILICON'S 17:20 FLEET LAW TO THIS FILE:
        # "the instrument you build to catch a defect class very often exhibits
        # that class." This guard existed to stop an EMPTY result being read as a
        # fact — and it announced its own liveness ONLY when some seat read zero.
        # In the all-healthy case it said NOTHING about whether it can detect
        # anything, which is the same silence-carries-no-information defect it
        # was built to prevent, in the tool built to prevent it.
        # ⇒ The liveness line is now UNCONDITIONAL: a reader never has to infer
        # from silence that the detector worked.
        print(f"\n  ✅ DETECTOR DEMONSTRATED LIVE on {len(live_seats)} seat(s)"
              f" ({', '.join(live_seats)}).")
        if zero_seats:
            print(f"     ⇒ a zero for {', '.join(zero_seats)} is a finding about"
                  f" THAT SEAT, not about this scan.")
        else:
            print("     ⇒ no seat read zero, so no absence claim is being made"
                  " at all.")

    print("\n" + "=" * 74)


if __name__ == "__main__":
    main()
