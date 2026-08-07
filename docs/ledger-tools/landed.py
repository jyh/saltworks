#!/usr/bin/env python3
"""The LANDED table, generated from git — because hand-maintenance is the bug.

    python3 docs/ledger-tools/landed.py                    # markdown to stdout
    python3 docs/ledger-tools/landed.py --since '2026-08-05 22:02'

Owner: the EVIDENCE seat. This closes the TODO filed against myself in
`docs/EVIDENCE-campaign.md` at `a9a6c03`.

WHY THIS EXISTS
---------------
Resource lesson 5, measured three separate times before noon on day 1:
**a snapshot of another seat's live tree ages in minutes.** The math seat
marked two rows `[IN FLIGHT]` that had already landed; three line
citations in the same document were off by 3; a file called untracked was
tracked. The campaign scoreboard inherits that hazard *by construction*,
because it quotes other seats' status.

More frequent hand-maintenance is not the fix. **A commit hash does not
age**, so the mechanically-knowable half of the scoreboard — what has
actually landed — should be derived from git and never typed.

WHAT IT DOES AND DOES NOT KNOW
------------------------------
It knows what was committed, by whom, when, and which seat's lane the
touched files belong to (from `docs/SEATS.md`'s writer-slot law). It does
**not** know whether a thing works, whether a proof is meaningful, or what
anyone intends to do next. Those stay hand-written and stay marked with
the time they were written — see the scoreboard's rule 2.

The seat attribution is a *heuristic over paths*, and it is labelled as
one wherever it is printed.
"""

from __future__ import annotations

import argparse
import re
import subprocess
from collections import defaultdict
from datetime import datetime
from pathlib import Path

import ledger_common as lc
from ledger_common import TZ, fmt_int, iso_local, now_local

# The writer-slot law, docs/SEATS.md. Path prefix -> owning seat.
# First match wins, so put the specific prefixes first.
LANES = [
    ("SaltWorks/HDL/", "compiler (leg 2)"),
    ("SaltWorks/Silicon/", "silicon (leg 3)"),
    ("SaltWorks/Banyan/", "maestro"),
    ("SaltWorks/Tactic/", "maestro"),
    ("SaltWorks.lean", "maestro (hub)"),
    ("lakefile.toml", "maestro (hub)"),
    ("lean-toolchain", "maestro (hub)"),
    ("docs/ledger-tools/", "evidence"),
    ("docs/EVIDENCE-", "evidence"),
    ("docs/measurement-preregistration", "evidence"),
    ("docs/tinytapeout-dossier", "evidence"),
    ("docs/silicon-", "silicon (leg 3)"),
    ("docs/hdl-", "compiler (leg 2)"),
    ("docs/SEATS.md", "maestro"),
    # salt-side lanes (leg 1). Salt/<Arc>/ is the unit of work there.
    ("Salt/HB/", "salt: HB (Heath-Brown)"),
    ("Salt/Weil/", "salt: Weil"),
    ("Salt/SW/", "salt: SW (Siegel-Walfisz)"),
    ("Salt/MR/", "salt: MR (Matomaki-Radziwill)"),
    ("Salt/Entropy/", "salt: Entropy/Chowla"),
    ("Salt/", "salt: other arc"),
    ("papers/", "salt: papers"),
    ("scripts/", "salt: scripts"),
    ("docs/exploration/", "docs: exploration"),
    ("docs/blueprints/", "docs: blueprints"),
    ("docs/reports/", "docs: reports"),
    ("docs/RESULTS.md", "docs: the registry"),
    ("docs/", "docs (shared)"),
]

# A commit subject that starts with one of these is ceremony, not a landing.
CEREMONY = ("wip", "typo", "fixup", "merge ")


def lane_of(path: str) -> str:
    for prefix, seat in LANES:
        if path.startswith(prefix):
            return seat
    return "other"


# --- META-TIME: the frozen classification (docs/EVIDENCE-metatime-design.md) --
#
# DESIGN = work that advances a DELIVERABLE (theorems, RTL, netlist, papers).
# META   = work on the APPARATUS (instruments, ledgers, protocols, provenance).
# AMBIG  = design docs that GATE a build (freezes, design-v1s) — reported as
#          its own column and NEVER silently split into one of the other two.
#
# ⚠️ THE TAG IS "WORK ON THE APPARATUS", NOT "NON-PRODUCTIVE". For leg 1 the
# apparatus IS the deliverable — the campaign's claim is "a ledger showing
# when each artifact landed and who was awake" — so a framing that lets a
# reader hear "overhead" is wrong, and the column header says so.
#
# ⛔ AND THE EVIDENCE SEAT IS ~100% META BY CONSTRUCTION (93 commits, 11,727
# lines, ZERO .lean on day 1). A fleet-wide fraction that includes it measures
# how busy this seat was, NOT method maturity — so the report prints per-lane
# and marks the evidence row as EXCLUDED from any aggregate.
#
# Frozen 2026-08-07, before any data was taken. Publishing a fraction needs
# >= 5 campaign days (design §4); this column exists so those days accumulate
# against a definition nobody chose after seeing the answer.

META_PREFIXES = (
    "docs/ledger-tools/", "docs/EVIDENCE-", "docs/measurement-preregistration",
    "docs/SEATS.md", "docs/reports/", "docs/RESULTS.md",
)
AMBIG_MARKERS = ("-design-v", "-freeze", "freeze-", "-protocol", "dossier")


def metatime_of(path: str) -> str:
    """DESIGN | META | AMBIGUOUS — frozen; see the note above."""
    if any(m in path for m in AMBIG_MARKERS):
        return "AMBIGUOUS"
    if path.startswith(META_PREFIXES):
        return "META"
    return "DESIGN"


def run(args, cwd) -> str:
    return subprocess.run(args, capture_output=True, text=True, cwd=cwd,
                          check=True).stdout


def collect(repo: Path, since: str | None, until: str | None):
    args = ["git", "log", "--numstat", "--no-merges",
            "--date=format-local:%Y-%m-%dT%H:%M:%S%z",
            "--format=@@%H|%h|%ad|%s"]
    if since:
        args.insert(2, f"--since={since}")
    if until:
        args.insert(2, f"--until={until}")
    import os
    env = dict(os.environ, TZ="America/Los_Angeles")
    out = subprocess.run(args, capture_output=True, text=True, cwd=str(repo),
                         env=env, check=True).stdout

    commits = []
    cur = None
    for line in out.splitlines():
        if line.startswith("@@"):
            full, short, ad, subject = line[2:].split("|", 3)
            cur = {"sha": full, "short": short,
                   "when": datetime.fromisoformat(ad).astimezone(TZ),
                   "subject": subject, "files": [], "ins": 0, "lean_ins": 0}
            commits.append(cur)
            continue
        if not line.strip() or cur is None:
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        added, _removed, path = parts
        cur["files"].append(path)
        if added != "-":
            cur["ins"] += int(added)
            if path.endswith(".lean"):
                cur["lean_ins"] += int(added)
    for c in commits:
        lanes = {lane_of(p) for p in c["files"]}
        c["lanes"] = sorted(lanes)
        c["lane"] = (sorted(lanes - {"docs (shared)", "other"})[0]
                     if lanes - {"docs (shared)", "other"} else
                     (sorted(lanes)[0] if lanes else "other"))
    commits.reverse()  # oldest first
    return commits


def build(args) -> str:
    repos = [Path(p).expanduser().resolve() for p in args.repo]
    out: list[str] = []
    w = out.append

    w("## LANDED — generated from `git log`, never typed")
    w("")
    w(f"Generated {iso_local(now_local())} America/Los_Angeles by "
      f"`docs/ledger-tools/landed.py`. Window: "
      f"`{args.since or 'all'}` → `{args.until or 'now'}`.")
    w("")
    w("> **This table is mechanical.** It reports what was committed — hash, "
      "time, lane, size. It knows nothing about whether a thing *works*, "
      "whether a proof is *meaningful*, or what anyone intends next; those "
      "stay hand-written and stay stamped with the time they were written. "
      "**A commit hash does not age, which is the entire reason this is "
      "generated** (resource lesson 5: a snapshot of another seat's live "
      "tree ages in minutes).")
    w("> Seat attribution is a **heuristic over file paths**, from the "
      "writer-slot law in `docs/SEATS.md`. It is not a claim about who typed "
      "what.")
    w("")

    grand = 0
    for repo in repos:
        commits = collect(repo, args.since, args.until)
        grand += len(commits)
        w(f"### `{repo.name}` — {len(commits)} commits")
        w("")
        if not commits:
            w("_No commits in the window._")
            w("")
            continue

        by_lane: dict[str, list] = defaultdict(list)
        for c in commits:
            by_lane[c["lane"]].append(c)
        w("| Lane | Commits | Lines added | `.lean` added |")
        w("|---|---:|---:|---:|")
        for lane in sorted(by_lane, key=lambda k: -len(by_lane[k])):
            cs = by_lane[lane]
            w(f"| {lane} | {len(cs)} | {fmt_int(sum(c['ins'] for c in cs))} | "
              f"{fmt_int(sum(c['lean_ins'] for c in cs))} |")
        w(f"| **total** | **{len(commits)}** | "
          f"**{fmt_int(sum(c['ins'] for c in commits))}** | "
          f"**{fmt_int(sum(c['lean_ins'] for c in commits))}** |")
        w("")

        if not args.summary_only:
            w("| When | Commit | Lane | +lines | Subject |")
            w("|---|---|---|---:|---|")
            for c in commits:
                subj = c["subject"].replace("|", "\\|")
                if len(subj) > args.subject_width:
                    subj = subj[: args.subject_width - 1] + "…"
                w(f"| {c['when'].strftime('%m-%d %H:%M')} | `{c['short']}` | "
                  f"{c['lane']} | {fmt_int(c['ins'])} | {subj} |")
            w("")

    w(f"**{fmt_int(grand)} commits across "
      f"{len(repos)} repo(s) in the window.**")
    w("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--repo", action="append",
                    default=None, help="repeatable; defaults to saltworks + salt")
    ap.add_argument("--since", default="2026-08-05 22:02",
                    help="explicit local time (campaign T0 by default)")
    ap.add_argument("--until", default=None)
    ap.add_argument("--summary-only", action="store_true")
    ap.add_argument("--subject-width", type=int, default=95)
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    if not args.repo:
        here = Path(__file__).resolve().parents[2]
        args.repo = [str(here), str(here.parent / "salt")]
    md = build(args)
    if args.out:
        Path(args.out).expanduser().write_text(md)
        print(f"wrote {args.out} ({len(md.splitlines())} lines)")
    else:
        print(md)


if __name__ == "__main__":
    main()
