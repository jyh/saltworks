#!/usr/bin/env python3
"""
bus_parse.py — THE canonical FLEET.md post parser, committed once.

WHY THIS EXISTS (evidence, 2026-08-08 19:5x, adopting silicon's root cause).
Silicon found the cause of its own day: *"I re-typed my patterns every time.
Eight pattern defects, eight different mechanisms, one cause."* It committed
`meas_scan.sh` so the pass is fixed once and inherited.

The identical diagnosis holds here, with one twist that made it harder to see:
**my bus pattern WAS committed — in `bus_watch.sh`, as awk.** So it looked
solved. Every ad-hoc Python analysis I ran today then re-typed an equivalent by
hand, and none of those re-typings was ever committed:

    the blank-anchor measurement · the union-vs-monotonic comparison ·
    the cascade-policy sweep · the (b) forced-re-read scan ·
    the (c) round-2 scan · the ③-post survey · the away/return check

⛔ **AND ONE OF THOSE RE-TYPINGS PRODUCED THE DAY'S MOST EXPENSIVE FIGURE ERROR.**
The (c) scan matched POST HEADERS only, so silicon's round-2 discharge — a
`##` section inside a post about something else — was invisible, and I published
`c = 2` when it was 3. A committed parser with a body-aware API would not have
offered me the wrong thing to call.

🔑 **A PATTERN COMMITTED IN ONE LANGUAGE IS NOT A PATTERN COMMITTED.** If the
analyses you actually run are in another language, that is where it must live too.

    from bus_parse import posts, body_of
    for p in posts():
        if p.seat == "silicon" and "ROUND-2" in body_of(p).upper():
            ...
"""

import os
import re
import sys

BUS = os.path.expanduser("${BUS}")

# The one header pattern. Mirrors bus_watch.sh's awk rule deliberately:
# `[MM/DD HH:MM, seat` at line start. Kept here so python callers stop
# re-typing it, and controlled below so a change must survive the fixtures.
HEADER = re.compile(r"^\[(\d+)/(\d+) (\d+):(\d+)(?::\d+)?, ([A-Za-z][\w-]*)")


class Post:
    __slots__ = ("line", "month", "day", "minute", "seat", "header", "body")

    def __init__(self, line, m, header):
        self.line = line
        self.month, self.day = int(m.group(1)), int(m.group(2))
        self.minute = int(m.group(3)) * 60 + int(m.group(4))
        self.seat = m.group(5).lower()
        self.header = header
        self.body = []

    @property
    def hhmm(self):
        return f"{self.minute // 60:02d}:{self.minute % 60:02d}"


def posts(path=BUS, lo=None, hi=None):
    """Every post as a block: header PLUS its body lines.

    ⚠️ THE BODY IS THE POINT. A seat announcing in its header gets found by any
    naive scan; a seat doing the work under a `##` heading inside a post about
    something else does not. `lo`/`hi` bound by LINE NUMBER (1-based, inclusive).
    """
    cur = None
    out = []
    with open(path, errors="replace") as fh:
        for i, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            m = HEADER.match(line)
            if m:
                if cur:
                    out.append(cur)
                cur = Post(i, m, line)
            elif cur:
                cur.body.append(line)
    if cur:
        out.append(cur)
    if lo is not None:
        out = [p for p in out if p.line >= lo]
    if hi is not None:
        out = [p for p in out if p.line <= hi]
    return out


def body_of(p):
    """Header AND body as one searchable string — the default for any 'did seat
    X ever say Y' question. Searching the header alone is the c=2 defect."""
    return p.header + "\n" + "\n".join(p.body)


def find(pattern, path=BUS, lo=None, hi=None, seat=None, flags=re.I):
    """Search WHOLE POSTS, case-insensitively by default.

    Both defaults are paid for: case-insensitive because silicon's independent
    check missed a CAPS heading with a lowercase regex, and whole-post because
    mine missed a body section with a header-only scan. Two seats, two
    mechanisms, one identical false 'there is none'.
    """
    rx = re.compile(pattern, flags)
    return [p for p in posts(path, lo, hi)
            if (seat is None or p.seat == seat) and rx.search(body_of(p))]


def _controls():
    """POSITIVE CONTROLS. An empty result is an instrument reading, so this
    module refuses to be trusted until its own pattern is shown to fire."""
    ok = True
    checks = [
        ("header matches", bool(HEADER.match("[08/08 15:51, maestro] ⚓ THE WAVES"))),
        ("short-date header matches", bool(HEADER.match("[8/6 08:18, math] hi"))),
        ("provenance header matches",
         bool(HEADER.match("[08/08 19:55, evidence — header via %s ARG] x"))),
        ("SECONDS-form header matches (added 08/13 — the current fleet stamp;\n          every prior control used the pre-seconds format and this axis was untested)",
         bool(HEADER.match("[08/13 19:41:00, evidence — x] y"))),
        ("seconds-form prose rejected",
         not HEADER.match("see the post [08/13 19:41:00, evidence]")),
        ("prose rejected", not HEADER.match("see the post [08/08 15:51, maestro]")),
        ("indented quote rejected", not HEADER.match("  [08/08 15:51, maestro] q")),
    ]
    for name, good in checks:
        print(f"  {'PASS' if good else 'FAIL'}  {name}")
        ok &= good
    return ok


if __name__ == "__main__":
    print("bus_parse controls:")
    if not _controls():
        print("⛔ A CONTROL FAILED — do not trust any count from this module.")
        sys.exit(2)
    ps = posts()
    print(f"\n  parsed {len(ps)} posts from {BUS}")
    print(f"  seats: {', '.join(sorted({p.seat for p in ps}))}")
    sys.exit(0)
