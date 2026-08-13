#!/usr/bin/env python3
"""incident_key — collapse candidate RECORDS into INCIDENTS. Identity only, never class.

Board item: LEDGER CONSTITUTION phase 2 (compiler seat, 2026-08-12).
Scope as assigned: "INCIDENT KEYING over the disclosed population, TAXONOMY-BLIND —
identity, never class; classification waits on the council ruling so the partition
cannot leak into the keying."

⛔ THIS TOOL NEVER ASSIGNS A CLASS. It has no class vocabulary, by construction, so a
taxonomy cannot leak into identity even by accident. Grep it: there is none.

────────────────────────────────────────────────────────────────────────────────
THE FINDING THIS TOOL EXISTS TO SURFACE: THE IDENTITY RULE IS NOT A DETAIL.
────────────────────────────────────────────────────────────────────────────────
One defect measured tonight — a provenance ratio stated with an RTL numerator over a
die denominator — has:

      1  root defect          (a single wrong predicate, authored once)
      7  carriers             (fence doc · draft prose · fig-preview · fig1-spine.mmd
                               · fig1-spine.svg · track block · a memory file)
     25  mentions on the bus  (finder, corrected seat, peers, folds, retractions)

***"ERRORS CAUGHT" IS 1, 7, OR 25 FOR THE SAME EVENT, AND NOTHING BUT THE IDENTITY
RULE DECIDES WHICH.*** A paper sentence reading "[N] design errors caught" is therefore
underdetermined until that rule is stated — and the rule is a PAPER-VOICE decision, not
a compiler one. This tool computes BOTH defensible rules and refuses to pick:

    ROOT     one DEFECT = one incident. Propagation into further artifacts is NOT a
             new incident. Answers "how many distinct mistakes were made?"
    CARRIER  each ARTIFACT carrying the defect = one incident. Answers "how many
             separate repairs did the fleet have to perform?"

Neither is wrong. They answer different questions, and the paper asks only one of them.
MENTIONS is reported too — as the number a naive sweep would produce, and as the
measured overstatement factor against each rule.
"""
import argparse
import json
import os
import sys


def load(path):
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, list):
        raise ValueError("seed must be a JSON list of incident objects")
    return data


def validate(rows):
    """Refuse to compute on a malformed seed. A keyer that silently drops rows
    produces a smaller, cleaner-looking number — the direction that flatters."""
    problems = []
    seen = {}
    for i, r in enumerate(rows):
        for field in ("key", "predicate", "carriers"):
            if field not in r:
                problems.append("row %d missing %r" % (i, field))
        k = r.get("key")
        if k in seen:
            problems.append("duplicate key %r (rows %d and %d)" % (k, seen[k], i))
        seen[k] = i
        if not isinstance(r.get("carriers", []), list) or not r.get("carriers"):
            problems.append("row %r has no carriers; a defect with no artifact is "
                            "not keyable" % k)
        if "class" in r or "category" in r or "taxonomy" in r:
            problems.append("row %r carries a CLASS field — this phase is "
                            "taxonomy-blind and must not record one" % k)
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("seed", help="hand-keyed incident seed (JSON)")
    ap.add_argument("--show", action="store_true", help="print every incident")
    args = ap.parse_args()

    if not os.path.isfile(args.seed):
        print("seed not found: %s" % args.seed, file=sys.stderr)
        return 2
    rows = load(args.seed)
    problems = validate(rows)
    if problems:
        print("⛔ SEED REJECTED — %d problem(s); no number computed:" % len(problems))
        for p in problems:
            print("   " + p)
        return 1

    root = len(rows)
    carrier = sum(len(r["carriers"]) for r in rows)
    mentions = sum(int(r.get("mentions") or 0) for r in rows)
    unknown_mentions = [r["key"] for r in rows if not r.get("mentions")]

    if args.show:
        for r in sorted(rows, key=lambda x: -len(x["carriers"])):
            print("%-34s carriers=%-3d mentions=%-4s %s"
                  % (r["key"], len(r["carriers"]),
                     r.get("mentions", "?"), r["predicate"][:58]))
        print()

    print("=" * 74)
    print("INCIDENT KEYING — TAXONOMY-BLIND (identity only; no class is recorded)")
    print("=" * 74)
    print("  seed rows (hand-keyed, adjudicated)      %d" % root)
    print()
    print("  ROOT rule     one DEFECT per incident    %d" % root)
    print("  CARRIER rule  one ARTIFACT per incident  %d" % carrier)
    print("  MENTIONS      what a naive sweep counts  %s%s"
          % (mentions, " (INCOMPLETE — see below)" if unknown_mentions else ""))
    print()
    print("  overstatement of MENTIONS over ROOT      %.1fx" % (mentions / root)
          if root else "")
    print("  overstatement of MENTIONS over CARRIER   %.1fx"
          % (mentions / carrier) if carrier else "")
    print("  spread between the two defensible rules  %.1fx" % (carrier / root)
          if root else "")
    if unknown_mentions:
        print("\n⚠️  %d row(s) carry NO mention count and contribute 0 to the MENTIONS"
              " total, which is therefore a FLOOR, not a measurement:"
              % len(unknown_mentions))
        for k in unknown_mentions:
            print("      " + k)
    print("""
⛔ NO CLASSIFICATION IS EMITTED and none is recorded in the seed — validated above.
⛔ NEITHER RULE IS ENDORSED. ROOT answers "how many distinct mistakes were made";
   CARRIER answers "how many separate repairs were required". A published sentence
   of the form "[N] design errors caught" must say WHICH, and that is a paper-voice
   ruling this seat does not make.
✅ The seed is a HAND-ADJUDICATED slice, not the whole population: it covers one
   seat's visible window. Its collapse factors are measured; extrapolating them to
   the full 8,262-record frame is NOT licensed by this run.""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
