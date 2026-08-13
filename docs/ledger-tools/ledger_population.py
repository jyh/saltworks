#!/usr/bin/env python3
"""ledger_population — disclose the ERROR-LEDGER population BEFORE anything counts it.

Board item: LEDGER CONSTITUTION phase 1 (compiler seat, 2026-08-12).
Scope, as assigned: *population disclosed before counting.* This tool therefore
enumerates the FRAME and REFUSES to emit an incident count. See --why-no-count.

WHY A FRAME AND NOT A COUNT (compiler's extractor design, 2a16a8c):
    The draft claims "an append-only ledger of [256+] design errors caught". No such
    corpus exists. LEDGER.md holds LANDED NODES (wrong noun); the memory banks hold
    curated LAWS (many-to-one with incidents, and not all are errors); the bus holds
    prose. The ledger must be CONSTITUTED, and constitution begins by saying exactly
    what is in the frame and what is not — with the exclusions PRINTED.

WHY COUNTING HERE WOULD BE WRONG, measured rather than asserted:
    A substring sweep of the bus returns CORRECTION 1156 / REFUTED 554 / RETRACT 488
    against a published [256+]. Those count MENTIONS. One incident tonight (the
    352/902 scope defect) produced ~8 posts across 3 seats, 1 commit, 2 file
    annotations and 1 memory entry. A mention-counter scores it 8-15; the ledger must
    score it 1. The unit rule (incident_key) is phase 2, and it is a judgement per
    row, not a regex.

THE RULES THIS TOOL OBEYS, all of them banked laws of this seat:
    * LET THE BUILD ENUMERATE THE POPULATION — never a hand-kept list.
    * PRINT WHAT WAS EXCLUDED, AND WHY. A sweep is not a finding until every member
      is classified; silent exclusion is how a completeness claim gets falsified.
      (Evidence's 19:00 case: a sweep read 670 of 709 files and reported neither.)
    * NO SILENT CAPS. If anything is truncated or sampled, it says so, loudly.
    * A ZERO NEEDS A POSITIVE CONTROL — every source prints one.
"""
import argparse
import os
import re
import subprocess
import sys

FLEET_BUS = "FLEET.md"
BUS_POST = re.compile(r"^\[(\d\d)/(\d\d) (\d\d):(\d\d)(?::(\d\d))?, ([a-z\-]+)", re.M)
LEDGER_NODE = re.compile(r"^## (?!#)(.+)$", re.M)


def sh(args, cwd=None):
    try:
        out = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=120)
        return out.stdout if out.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


class Source:
    """One member-producing source, with its rule, its units, and its exclusions."""

    def __init__(self, key, rule, unit):
        self.key, self.rule, self.unit = key, rule, unit
        self.members = []
        self.exclusions = []          # (count, reason)
        self.control = None           # (description, observed) -- the positive control
        self.note = None

    def exclude(self, count, reason):
        if count:
            self.exclusions.append((count, reason))

    @property
    def n(self):
        return len(self.members)


def src_bus(root):
    s = Source("BUS", "lines matching ^[MM/DD HH:MM(:SS), <seat> — …] in FLEET.md",
               "one bracket-stamped POST (not an incident)")
    path = os.path.join(root, FLEET_BUS)
    if not os.path.isfile(path):
        s.note = "⛔ FLEET.md NOT FOUND at %s — source is ABSENT, not empty" % path
        return s
    text = open(path, encoding="utf-8", errors="replace").read()
    total_lines = text.count("\n") + 1
    posts = BUS_POST.findall(text)
    s.members = ["%s/%s %s:%s %s" % (m[0], m[1], m[2], m[3], m[5]) for m in posts]
    s.exclude(total_lines - len(posts),
              "lines that are POST BODY, not post headers (the bus is prose; a body "
              "line is part of its post, never a separate member)")
    seats = {}
    for m in posts:
        seats[m[5]] = seats.get(m[5], 0) + 1
    s.note = "by seat: " + " · ".join("%s %d" % kv for kv in sorted(seats.items()))
    s.control = ("a known seat header appears", "compiler=%d" % seats.get("compiler", 0))
    return s


def src_memory(root):
    s = Source("MEMORY", "${SEAT_DIR}/memory-seats/<seat>/*.md, excluding each seat's index",
               "one curated LAW (MANY-TO-ONE with incidents; NOT all are errors)")
    base = os.path.join(root, "memory-seats")
    if not os.path.isdir(base):
        s.note = "⛔ memory-seats/ NOT FOUND — source ABSENT, not empty"
        return s
    idx = 0
    per = {}
    for seat in sorted(os.listdir(base)):
        d = os.path.join(base, seat)
        if not os.path.isdir(d):
            continue
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".md"):
                continue
            if fn == "MEMORY.md":
                idx += 1
                continue
            s.members.append("%s/%s" % (seat, fn))
            per[seat] = per.get(seat, 0) + 1
    s.exclude(idx, "per-seat MEMORY.md index files (pointers to members, not members)")
    s.note = "by seat: " + " · ".join("%s %d" % kv for kv in sorted(per.items()))
    s.control = ("a known seat mirror is non-empty", "compiler=%d" % per.get("compiler", 0))
    return s


def src_ledger(root):
    s = Source("LEDGER", "^## headings in saltworks/docs/LEDGER.md",
               "one LANDED NODE (⚠️ THE WRONG NOUN — these are landings, not errors)")
    path = os.path.join(root, "docs", "LEDGER.md")
    if not os.path.isfile(path):
        s.note = "⛔ docs/LEDGER.md NOT FOUND — source ABSENT, not empty"
        return s
    text = open(path, encoding="utf-8", errors="replace").read()
    s.members = LEDGER_NODE.findall(text)
    s.exclude(len(re.findall(r"^### ", text, re.M)),
              "### subsections inside a node (What landed / bridge lemma / …)")
    s.note = ("⚠️ INCLUDED FOR DISCLOSURE, NOT AS ERROR RECORDS: this file records what "
              "LANDED. Its per-node 'what was FOUND vs PROVED / left undetermined' "
              "sections may CONTAIN incidents; the file itself is not a list of them.")
    s.control = ("the file parses to >0 nodes", "%d" % len(s.members))
    return s


def src_commits(root, repos):
    s = Source("COMMITS", "git log --oneline across the named repos",
               "one COMMIT (a correction may be described in its message)")
    per = {}
    for r in repos:
        # NOTE the repos are siblings INSIDE the fleet root, not beside it. An earlier
        # `os.path.join(root, "..", r)` resolved to ~/projects/salt and every repo came
        # back "has no .git". It reported ZERO — and the zero was legible ONLY because
        # this tool prints its exclusions and a positive control. A silent enumerator
        # would have published a frame with the entire COMMITS source missing.
        rp = r if os.path.isabs(r) else os.path.join(root, r)
        rp = os.path.abspath(rp)
        if not os.path.isdir(os.path.join(rp, ".git")):
            s.exclude(1, "repo %r has no .git and was NOT read" % r)
            continue
        out = sh(["git", "log", "--format=%h %s"], cwd=rp)
        lines = [ln for ln in out.splitlines() if ln.strip()]
        per[r] = len(lines)
        s.members.extend("%s %s" % (r, ln) for ln in lines)
    s.note = "by repo: " + (" · ".join("%s %d" % kv for kv in sorted(per.items()))
                            or "none read")
    s.control = ("at least one repo yielded commits",
                 "max=%d" % (max(per.values()) if per else 0))
    return s


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fleet-root", default=os.path.expanduser("~/projects/claude"),
                    help="directory holding FLEET.md and the repos")
    ap.add_argument("--seat-root", default=None, help="the seat repo (memory mirrors)")
    ap.add_argument("--saltworks-root", default=None, help="the saltworks repo")
    ap.add_argument("--repos", default="salt,saltworks,seat",
                    help="comma-separated repos for the COMMITS source")
    ap.add_argument("--list", metavar="SOURCE",
                    help="print every member of one source (no truncation)")
    ap.add_argument("--why-no-count", action="store_true",
                    help="explain why this tool emits no incident count, and exit")
    args = ap.parse_args()

    if args.why_no_count:
        print(__doc__)
        return 0

    fleet = os.path.abspath(args.fleet_root)
    seat = os.path.abspath(args.seat_root or os.path.join(fleet, "seat"))
    salt = os.path.abspath(args.saltworks_root or os.path.join(fleet, "saltworks"))

    sources = [src_bus(fleet), src_memory(seat), src_ledger(salt),
               src_commits(fleet, [r for r in args.repos.split(",") if r])]

    if args.list:
        want = args.list.upper()
        for s in sources:
            if s.key == want:
                for m in s.members:
                    print(m)
                print("\n-- %d member(s); NOT truncated --" % s.n, file=sys.stderr)
                return 0
        print("no such source: %s" % args.list, file=sys.stderr)
        return 2

    print("=" * 78)
    print("ERROR-LEDGER POPULATION — PHASE 1 DISCLOSURE (no incident count is emitted)")
    print("=" * 78)
    for s in sources:
        print("\n[%s]  %d member(s)" % (s.key, s.n))
        print("  RULE      %s" % s.rule)
        print("  UNIT      %s" % s.unit)
        if s.note:
            print("  NOTE      %s" % s.note)
        if s.control:
            print("  CONTROL   %s → %s" % s.control)
        if s.exclusions:
            for c, why in s.exclusions:
                print("  EXCLUDED  %-8d %s" % (c, why))
        else:
            print("  EXCLUDED  0        (nothing excluded from this source)")

    total = sum(s.n for s in sources)
    print("\n" + "-" * 78)
    print("FRAME TOTAL: %d members across %d sources." % (total, len(sources)))
    print("-" * 78)
    print("""\
⏱  THE POPULATION IS LIVE. The bus is append-only and grew BY ONE POST between two
   runs of this tool while it was being written. A frame is therefore valid only AT
   ITS TIMESTAMP, and any count quoted from it must carry that stamp — otherwise two
   honest measurements disagree and someone hunts a defect that is not there.""")
    print("""\
⛔ THIS IS NOT AN ERROR COUNT AND MUST NOT BE QUOTED AS ONE.
   These are CANDIDATE RECORDS that may each contain zero, one, or several
   incidents, and the same incident appears in many of them. Collapsing members
   to incidents is PHASE 2 and requires the incident_key judgement per row.
   Run with --why-no-count for the measured reason.
✅ Every source above is ENUMERATED, not sampled; exclusions are printed with
   their reasons; --list <SOURCE> dumps any source in full with no truncation.""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
