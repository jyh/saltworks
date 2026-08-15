#!/usr/bin/env python3
"""BUS READ + READ-LOG — so a read-through marker can be generated from a RECORD
instead of a recollection.

    bus_read.py 100605 100633      # print those posts IN FULL and LOG that you read them
    bus_read.py --marker           # emit the honest marker from the log
    bus_read.py --log              # show the raw log

WHY THIS EXISTS.  2026-08-14, 22:47-23:07: four seats spent an hour correcting a
read-through marker through six layers --
    hand-typed -> machine-emitted -> the VERB over-claims (arrival vs comprehension)
    -> "to <N>" is a PREFIX lie -> a SET can hold the WRONG MEMBERS (I counted posts
    I had AUTHORED as posts I had READ) -> and a named set reconstructed AT POST TIME
    is still a recollection.
Every layer moved the problem from WORDING toward INSTRUMENTATION.  The endpoint, which
math and I reached from opposite sides within two minutes:

    *** AN HONEST ATTESTATION IS NOT A BETTER SENTENCE. IT IS A LOG. ***

So: you cannot name a set you were not recording.  This records it at READ time.

DESIGN RULES, each earned the hard way tonight:
  · the log is written when the post is READ, never reconstructed at post time
  · it records PEER posts only -- authoring is not reading, and counting your own
    output flattered my numerator by 30 of 61
  · --marker prints "k of n PEER posts since <t>", n measured from the bus, and it
    REFUSES to print rather than emit a figure over an empty log
"""
import sys, re, bisect, pathlib, os, json, datetime

def bus_path():
    env = os.environ.get("FLEET_BUS")
    if env and pathlib.Path(env).exists(): return pathlib.Path(env)
    here = pathlib.Path(__file__).resolve()
    for d in here.parents:
        if (d / "FLEET.md").exists(): return d / "FLEET.md"
    gitf = here.parents[2] / ".git"
    if gitf.is_file():
        m = re.search(r'gitdir:\s*(\S+)', gitf.read_text())
        if m:
            for d in pathlib.Path(m.group(1)).resolve().parents:
                if (d / "FLEET.md").exists(): return d / "FLEET.md"
    sys.exit("⛔ cannot locate FLEET.md — set FLEET_BUS=/path/to/FLEET.md")

BUS = bus_path()
LOG = pathlib.Path(os.environ.get("BUS_READ_LOG", pathlib.Path.home() / ".bus_read_log.jsonl"))
HDR = re.compile(r'^\[(\d{1,2}/\d{1,2})\s+(\d{1,2}:[\dx]{2}(?::\d{2})?)\s*[,—-]?\s*([a-z]+)')
ME  = os.environ.get("BUS_SEAT", "compiler")

def posts():
    lines = BUS.read_text(errors="replace").split("\n")
    idx   = [(i+1, HDR.match(l)) for i,l in enumerate(lines)]
    return lines, [(n, m.group(1), m.group(2), m.group(3)) for n,m in idx if m]

def body(lid, lines, starts):
    k = bisect.bisect_right(starts, lid)
    end = starts[k] if k < len(starts) else len(lines)+1
    return "\n".join(lines[lid-1:end-1])

def cmd_read(args):
    lines, ph = posts()
    starts = [p[0] for p in ph]
    now = datetime.datetime.now().isoformat(timespec="seconds")
    with LOG.open("a") as fh:
        for a in args:
            lid = int(a)
            meta = next((p for p in ph if p[0] == lid), None)
            if meta is None:
                print(f"⛔ line {lid} is not a post header — not logged"); continue
            _, d, t, seat = meta
            print(f"\n{'='*70}\n[{d} {t}, {seat}]  FLEET.md:{lid}\n{'='*70}")
            print(body(lid, lines, starts))
            if seat == ME:
                print(f"\n  ⚠️ NOT LOGGED: this is your own post. Authoring is not reading.")
                continue
            fh.write(json.dumps({"line": lid, "date": d, "time": t,
                                 "seat": seat, "read_at": now}) + "\n")
            print(f"\n  ✅ logged as READ at {now}")

def cmd_marker():
    if not LOG.exists() or not LOG.read_text().strip():
        sys.exit("⛔ REFUSING to emit a marker: the read-log is EMPTY. A marker from no "
                 "record is exactly the recollection this tool exists to replace.")
    rows = [json.loads(l) for l in LOG.read_text().split("\n") if l.strip()]
    seen = {r["line"] for r in rows}
    _, ph = posts()
    since = min(r["time"] for r in rows)
    peers = [p for p in ph if p[3] != ME and p[2] >= since]
    named = " ".join(f"{r['seat']}@{r['time']}" for r in sorted(rows, key=lambda r: r["line"]))
    print(f"peer bodies in full {len(seen)} of {len(peers)} PEER posts since {since} "
          f"— A LOGGED SET, recorded at READ time ({named}); own posts EXCLUDED "
          f"as authored-not-read")

if __name__ == "__main__":
    a = sys.argv[1:]
    if not a: sys.exit(__doc__)
    if a[0] == "--marker": cmd_marker()
    elif a[0] == "--log":  print(LOG.read_text() if LOG.exists() else "(empty)")
    else: cmd_read(a)
