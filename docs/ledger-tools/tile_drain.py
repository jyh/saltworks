#!/usr/bin/env python3
"""The TTSKY26c tile-drain series — an append-only log, read at the site.

WHY THIS EXISTS. On 2026-08-07 this seat posted "tiles 222 -> 202, ~20/day",
the maestro correctly turned it into "naive exhaustion ~Aug 17", and it was
on its way to the Captain as a DATE. **The arithmetic was exact and the rate
had n = 1.** Two readings one day apart is a DIFFERENCE, not a rate; a rate
from one interval is not a forecast. At 20/day the shuttle exhausts Aug 17;
at 1/day it never exhausts before the close. Both live inside one
observation.

So: log the series, refuse the projection until the slope is measured.

    python3 docs/ledger-tools/tile_drain.py            # read + append + report
    python3 docs/ledger-tools/tile_drain.py --report   # report only, no fetch

APPEND-ONLY. The log is never rewritten. A reading that cannot be taken is
NOT appended -- a gap in the series is honest; an invented row is not.

⛔ AND THE MODEL IS DECLARED WRONG IN ADVANCE. Shuttle fill is NOT linear:
submissions cluster at the deadline, and both preceding sky130 shuttles
closed at 512/512. A linear slope UNDERSTATES time remaining early and
OVERSTATES it late -- the worst shape for a decision taken mid-window. The
projection below is therefore printed as a BOUND WITH ITS MODEL NAMED, never
as an expected date.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://app.tinytapeout.com/api/shuttles/ttsky26c"
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "EVIDENCE-tile-drain.tsv")
PDT = timezone(timedelta(hours=-7))

# a slope needs this much before it is printed at all
MIN_READINGS = 4
MIN_SPAN_HOURS = 36.0


def stamp() -> str:
    """From `date`, never composed — the fleet's timestamp law."""
    return subprocess.run(["date", "+%Y-%m-%dT%H:%M:%S%z"],
                          capture_output=True, text=True,
                          env=dict(os.environ, TZ="America/Los_Angeles")
                          ).stdout.strip()


def fetch() -> dict:
    """Via `curl`, and that is a measured choice rather than a preference.

    `urllib.request.urlopen` returns **HTTP 403 Forbidden** on this endpoint
    (measured 2026-08-07) while `curl` succeeds — the host rejects the
    default Python user-agent. Using the client that works, and recording
    why, so the next reader does not "simplify" it back to urllib and get a
    series full of honest gaps.
    """
    r = subprocess.run(["curl", "-sS", "--max-time", "20", API],
                       capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        raise RuntimeError(f"curl failed (rc={r.returncode}): "
                           f"{(r.stderr or '').strip()[:160]}")
    return json.loads(r.stdout)


def read_log() -> list[dict]:
    if not os.path.exists(LOG):
        return []
    out = []
    for line in open(LOG):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        p = line.split("\t")
        if len(p) < 4:
            continue
        try:
            out.append({"when": datetime.fromisoformat(p[0]),
                        "tiles": int(p[1]), "pcbs": int(p[2]), "note": p[3]})
        except Exception:
            continue
    return out


def main() -> int:
    report_only = "--report" in sys.argv
    rows = read_log()

    if not report_only:
        try:
            d = fetch()
            t, p = d["tiles"], d["pcbs"]
        except Exception as e:
            print(f"tile_drain: ⛔ COULD NOT READ THE SITE — {e}\n"
                  f"  NOTHING APPENDED. A gap in the series is honest; an "
                  f"invented row is not.", file=sys.stderr)
            return 2
        now = stamp()
        new = not os.path.exists(LOG)
        with open(LOG, "a") as fh:
            if new:
                fh.write("# TTSKY26c tile drain — APPEND-ONLY, read at the site.\n"
                         "# when\ttiles_available\tpcbs_available\tnote\n")
            fh.write(f"{now}\t{t['available']}\t{p['available']}\t"
                     f"tiles_total={t['total']} pcbs_total={p['total']}\n")
        print(f"tile_drain: appended {now}  tiles {t['available']}/{t['total']}  "
              f"pcbs {p['available']}/{p['total']}")
        rows = read_log()

    print()
    print("## Shuttle drain — TTSKY26c")
    print()
    print("| Read at | Tiles available | PCBs available |")
    print("|---|---:|---:|")
    for r in rows:
        print(f"| {r['when']:%Y-%m-%d %H:%M} | {r['tiles']} | {r['pcbs']} |")
    print()

    if len(rows) < MIN_READINGS:
        print(f"⛔ **NO SLOPE PRINTED — {len(rows)} reading(s), need "
              f"{MIN_READINGS}.** *A difference is not a rate, and a rate from "
              f"one interval is not a forecast.* **The honest line until then:** "
              f"`{rows[-1]['tiles'] if rows else '?'} of 512 tiles remain; both "
              f"preceding sky130 shuttles closed at 512/512; the fill rate is "
              f"not yet measured.**")
        return 0

    span = (rows[-1]["when"] - rows[0]["when"]).total_seconds() / 3600
    if span < MIN_SPAN_HOURS:
        print(f"⛔ **NO SLOPE PRINTED — the series spans {span:.1f} h, need "
              f"{MIN_SPAN_HOURS:.0f} h.** Readings close together measure the "
              f"clock, not the shuttle.")
        return 0

    drop = rows[0]["tiles"] - rows[-1]["tiles"]
    per_day = drop / (span / 24)
    print(f"**Measured over {span:.1f} h across {len(rows)} readings: "
          f"{drop} tiles, {per_day:.1f}/day.**")
    print()
    if per_day > 0:
        days = rows[-1]["tiles"] / per_day
        print(f"⚠️ **LINEAR exhaustion in {days:.1f} days — AND THE MODEL IS "
              f"DECLARED WRONG IN ADVANCE.** Shuttle fill is not linear: "
              f"submissions cluster at the deadline and both preceding sky130 "
              f"shuttles closed at 512/512, so a linear slope **understates "
              f"time remaining early and overstates it late** — the worst shape "
              f"for a mid-window decision. **Quote this as a bound with its "
              f"model named, never as an expected date.**")
    else:
        print("**No drain observed over the series.** Reported as measured; "
              "a flat stretch early in a shuttle's life is expected and is not "
              "evidence the shuttle will not fill.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
