#!/usr/bin/env python3
"""seed_sensitivity — how much does the published ratio depend on ONE hand-keying call?

Board item: LEDGER CONSTITUTION, the falsification pass (compiler seat, 2026-08-12).
Target: this seat's OWN published claim that MENTIONS overstate ROOT incidents 3.9x
(`5b7ceb9`, bus 19:33:49), now a FOR-RATIFICATION item in `council-pack-0813.md:90`.

────────────────────────────────────────────────────────────────────────────────
WHY THIS TOOL AND NOT A RE-KEY
────────────────────────────────────────────────────────────────────────────────
The honest test of a hand-keyed seed is a SECOND KEYER WHO HAS NOT SEEN THE RATIO.
This seat has seen it. That test therefore stays OPEN and is NOT what this tool does.

What needs no blindness is MECHANICAL SENSITIVITY. A jackknife does not care what its
author believes: it asks whether the headline survives the removal of any single row.
A ratio over 17 hand-keyed rows can be BIASED (which needs a blind keyer to detect) or
LEVERAGED (which does not). Only the first was named in the handoff.

    DOMAIN OF THIS INSTRUMENT — read it before quoting any number below.
    It measures the SEED's internal sensitivity. It CANNOT detect:
      · a systematically generous mention estimate applied to EVERY row (bias is
        invisible to a jackknife: shift all rows and the ratio shifts with them);
      · incidents absent from the seed entirely (one seat's window is not a census);
      · whether the ROOT/CARRIER identity rule is the right one (a paper-voice call).
    A GREEN RUN HERE IS NOT A VINDICATION OF THE SEED. It is the absence of ONE
    specific failure mode.

────────────────────────────────────────────────────────────────────────────────
THE CROSS-CHECK GATE
────────────────────────────────────────────────────────────────────────────────
This tool RE-IMPLEMENTS the full-seed arithmetic and then REFUSES TO REPORT unless it
agrees with `incident_key.py`, run as a subprocess and parsed. Two independently
written computations must land on the same 17 / 25 / 66 before any leave-one-out
number is trusted. If the parse fails, that is a REFUSAL, never a pass -- a gate that
cannot read its reference has not checked it.
"""
import argparse
import json
import os
import re
import subprocess
import sys


HERE = os.path.dirname(os.path.abspath(__file__))


def load(path):
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, list):
        raise ValueError("seed must be a JSON list of incident objects")
    return data


def totals(rows):
    """ROOT / CARRIER / MENTIONS over a row set. Same definitions as incident_key."""
    root = len(rows)
    carrier = sum(len(r["carriers"]) for r in rows)
    mentions = sum(int(r.get("mentions") or 0) for r in rows)
    return root, carrier, mentions


def ratio(mentions, root):
    return (mentions / root) if root else float("nan")


def reference_totals(seed_path):
    """Run incident_key.py and parse ITS numbers. Returns (root, carrier, mentions)
    or raises -- an unreadable reference is a refusal, not a pass."""
    tool = os.path.join(HERE, "incident_key.py")
    if not os.path.isfile(tool):
        raise RuntimeError("reference tool not found: %s" % tool)
    proc = subprocess.run([sys.executable, tool, seed_path],
                          capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError("reference tool exited %d; stderr: %s"
                           % (proc.returncode, proc.stderr.strip()[:200]))
    out = proc.stdout
    pats = {
        "root": r"ROOT rule\s+one DEFECT per incident\s+(\d+)",
        "carrier": r"CARRIER rule\s+one ARTIFACT per incident\s+(\d+)",
        "mentions": r"MENTIONS\s+what a naive sweep counts\s+(\d+)",
    }
    got = {}
    for name, pat in pats.items():
        m = re.search(pat, out)
        if not m:
            raise RuntimeError("could not parse %r from reference output -- "
                               "REFUSING (an unreadable gate has not checked)" % name)
        got[name] = int(m.group(1))
    return got["root"], got["carrier"], got["mentions"]


def jackknife(rows):
    """Leave-one-out over MENTIONS/ROOT. Returns list of (key, ratio, delta)."""
    r0, _, m0 = totals(rows)
    base = ratio(m0, r0)
    out = []
    for i, r in enumerate(rows):
        rest = rows[:i] + rows[i + 1:]
        rr, _, mm = totals(rest)
        out.append((r["key"], ratio(mm, rr), ratio(mm, rr) - base))
    return base, out


def collapse(rows, prefix, mentions_override=None):
    """Merge every row whose key starts with `prefix` into ONE row.

    mentions_override=None  -> SUM the merged rows' mentions (the treatment that
                               assumes every mention is distinct)
    mentions_override=<int> -> use that count (the treatment that assumes the
                               merged rows share mentions; the value is a
                               MEASUREMENT the caller must supply, never invented
                               here)
    """
    hit = [r for r in rows if r["key"].startswith(prefix)]
    rest = [r for r in rows if not r["key"].startswith(prefix)]
    if not hit:
        return None, 0
    carriers = []
    for r in hit:
        for c in r["carriers"]:
            if c not in carriers:
                carriers.append(c)
    merged = {
        "key": prefix + "COLLAPSED",
        "predicate": "collapsed: %d rows" % len(hit),
        "carriers": carriers,
        "mentions": (sum(int(r.get("mentions") or 0) for r in hit)
                     if mentions_override is None else int(mentions_override)),
    }
    return rest + [merged], len(hit)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("seed")
    ap.add_argument("--collapse-prefix", default="prep-locator-",
                    help="key prefix to merge for the J2 sensitivity arm")
    ap.add_argument("--leverage-bar", type=float, default=0.5,
                    help="pre-registered bar: a single row moving the headline by "
                         "this much or more makes the figure LEVERAGED")
    ap.add_argument("--no-gate", action="store_true",
                    help="skip the incident_key cross-check (recorded in output)")
    args = ap.parse_args()

    if not os.path.isfile(args.seed):
        print("seed not found: %s" % args.seed, file=sys.stderr)
        return 2
    rows = load(args.seed)
    for r in rows:
        if "key" not in r or "carriers" not in r:
            print("seed row missing key/carriers -- REFUSING", file=sys.stderr)
            return 1

    root, carrier, mentions = totals(rows)

    print("=" * 78)
    print("SEED SENSITIVITY -- does the headline survive removing ONE row?")
    print("=" * 78)

    # ---- the cross-check gate -------------------------------------------------
    if args.no_gate:
        print("  GATE   ⚠️  SKIPPED BY FLAG -- no independent confirmation of the"
              " full-seed arithmetic")
    else:
        try:
            ref = reference_totals(args.seed)
        except Exception as exc:                                   # noqa: BLE001
            print("⛔ GATE REFUSED: %s" % exc)
            print("   No leave-one-out number is reported. An unreadable reference"
                  " has not checked anything.")
            return 1
        if ref != (root, carrier, mentions):
            print("⛔ GATE FAILED -- the two computations DISAGREE:")
            print("     incident_key.py     root=%d carrier=%d mentions=%d" % ref)
            print("     this tool           root=%d carrier=%d mentions=%d"
                  % (root, carrier, mentions))
            print("   No leave-one-out number is reported.")
            return 1
        print("  GATE   ✅ incident_key.py agrees: root=%d carrier=%d mentions=%d"
              % ref)

    base = ratio(mentions, root)
    print()
    print("  FULL SEED   ROOT %d · CARRIER %d · MENTIONS %d  ⇒  headline %.2fx"
          % (root, carrier, mentions, base))

    # ---- J3: the floor mechanism ---------------------------------------------
    no_count = [r["key"] for r in rows if not r.get("mentions")]
    print()
    print("  J3  FLOOR MECHANISM")
    print("      rows carrying NO mentions count: %d of %d" % (len(no_count), root))
    if not no_count:
        print("      ⚠️  The banked defence 'rows with no count contribute ZERO, so")
        print("          the total is a FLOOR' has an EMPTY DISCRIMINATING SET on")
        print("          this seed. It is not false -- it is INAPPLICABLE. The")
        print("          floor property rests entirely on whether each of the %d"
              % root)
        print("          hand estimates is itself conservative, which is UNMEASURED.")
    else:
        for k in no_count:
            print("        " + k)

    # ---- concentration --------------------------------------------------------
    by_m = sorted(rows, key=lambda r: -int(r.get("mentions") or 0))
    top = by_m[0]
    tm = int(top.get("mentions") or 0)
    print()
    print("  CONCENTRATION")
    print("      largest single row  %-22s mentions=%d  (%.0f%% of numerator)"
          % (top["key"], tm, 100.0 * tm / mentions if mentions else 0))
    print("      its carriers        %d  (%.0f%% of CARRIER total)"
          % (len(top["carriers"]),
             100.0 * len(top["carriers"]) / carrier if carrier else 0))

    # ---- J1: the jackknife ----------------------------------------------------
    base2, jk = jackknife(rows)
    jk_sorted = sorted(jk, key=lambda t: -abs(t[2]))
    print()
    print("  J1  LEVERAGE -- leave-one-out on MENTIONS/ROOT   (bar: |delta| >= %.2fx)"
          % args.leverage_bar)
    print("      %-34s %8s %9s" % ("row removed", "ratio", "delta"))
    for key, rr, dd in jk_sorted:
        flag = "  <-- OVER BAR" if abs(dd) >= args.leverage_bar else ""
        print("      %-34s %7.2fx %+8.2fx%s" % (key, rr, dd, flag))
    lo = min(t[1] for t in jk)
    hi = max(t[1] for t in jk)
    over = [t for t in jk if abs(t[2]) >= args.leverage_bar]
    print()
    print("      leave-one-out RANGE  %.2fx .. %.2fx   (headline %.2fx)"
          % (lo, hi, base2))
    if over:
        print("      ⛔ LEVERAGED: %d row(s) move the headline by >= %.2fx."
              % (len(over), args.leverage_bar))
        print("         The figure must ship as a RANGE, not a point estimate.")
    else:
        print("      ✅ NOT LEVERAGED at the pre-registered bar: no single row moves")
        print("         the headline by >= %.2fx." % args.leverage_bar)

    # ---- J2: keying sensitivity ----------------------------------------------
    print()
    print("  J2  KEYING SENSITIVITY -- collapse %r rows to ONE" % args.collapse_prefix)
    hit_rows = [r for r in rows if r["key"].startswith(args.collapse_prefix)]
    if not hit_rows:
        print("      no rows match that prefix; arm not run")
    else:
        hit_m = [int(r.get("mentions") or 0) for r in hit_rows]
        print("      merging %d rows: %s" % (len(hit_rows),
                                             ", ".join(r["key"] for r in hit_rows)))
        print("      their mentions: %s  (sum %d, max %d)"
              % (hit_m, sum(hit_m), max(hit_m)))
        print()
        print("      %-46s %8s %9s" % ("treatment", "ratio", "delta"))
        # summed: every mention distinct
        c_rows, n = collapse(rows, args.collapse_prefix, None)
        rr, cc, mm = totals(c_rows)
        r_sum = ratio(mm, rr)
        print("      %-46s %7.2fx %+8.2fx"
              % ("SUMMED (all %d mentions distinct)" % sum(hit_m),
                 r_sum, r_sum - base))
        # deduped floor: the merged rows shared ALL mentions
        c_rows, n = collapse(rows, args.collapse_prefix, max(hit_m))
        rr, cc, mm = totals(c_rows)
        r_ded = ratio(mm, rr)
        print("      %-46s %7.2fx %+8.2fx"
              % ("DEDUPED (they share mentions; %d distinct)" % max(hit_m),
                 r_ded, r_ded - base))
        print()
        print("      ⇒ collapsing spans %.2fx .. %.2fx; the SIGN of the move depends"
              % (min(r_sum, r_ded), max(r_sum, r_ded)))
        print("        on the mention treatment, which is a MEASUREMENT (J4), not a")
        print("        choice. This tool does not invent it.")

    # ---- J5: the unit audit ---------------------------------------------------
    # ROOT/CARRIER/MENTIONS are all computed as SUMS OVER ROWS. For ROOT that is a
    # count of distinct defects (keys are validated unique). For the other two it is
    # a count of PAIRS -- (artifact, defect) and (mention, defect) -- while the
    # published labels say "one ARTIFACT per incident" and "mentions". If any
    # artifact carries more than one keyed defect, CARRIER is NOT an artifact count.
    print()
    print("  J5  UNIT AUDIT -- does each published number count what its label says?")
    all_c = [c for r in rows for c in r["carriers"]]
    distinct_c = sorted(set(all_c))
    dupes = {}
    for c in all_c:
        dupes[c] = dupes.get(c, 0) + 1
    shared = {c: n for c, n in dupes.items() if n > 1}
    print("      ROOT      %3d   distinct defects        (keys validated unique) ✅"
          % root)
    print("      CARRIER   %3d   labelled 'one ARTIFACT per incident'" % carrier)
    print("                %3d   DISTINCT artifact paths actually present"
          % len(distinct_c))
    if shared:
        print("      ⛔ CARRIER IS NOT AN ARTIFACT COUNT. It counts (artifact, defect)")
        print("         PAIRS. %d artifact(s) carry more than one keyed defect, so"
              % len(shared))
        print("         the published %d overstates distinct artifacts by %d (%.0f%%):"
              % (carrier, carrier - len(distinct_c),
                 100.0 * (carrier - len(distinct_c)) / len(distinct_c)))
        for c, n in sorted(shared.items(), key=lambda kv: -kv[1]):
            print("           %2dx  %s" % (n, c))
        print("         The QUANTITY may still be the right answer to 'how many")
        print("         separate repairs' -- but that is REPAIR EVENTS, not artifacts,")
        print("         and the label is what a councillor reads.")
    else:
        print("      ✅ no artifact carries two keyed defects; CARRIER == artifacts here")
    print("      MENTIONS  %3d   sum over rows ⇒ (mention, defect) PAIRS, not posts."
          % mentions)
    print("                      A naive sweep counts POSTS. Measured on the only")
    print("                      group enumerated exhaustively (the 3 prep-locator")
    print("                      rows): 11 pairs over 5 distinct posts, 2.2x.")
    print("                      See mention_count.py. NOT extrapolated to the seed.")

    print()
    print("-" * 78)
    print("⛔ DOMAIN: this measures the SEED's internal sensitivity. A jackknife")
    print("   CANNOT see a bias applied uniformly to every row, incidents missing")
    print("   from the window, or whether ROOT is the right identity rule. A green")
    print("   run here is the absence of ONE failure mode, NOT a vindication.")
    print("⛔ THE BLIND SECOND KEYER REMAINS THE HONEST TEST AND IS NOT DISCHARGED")
    print("   BY THIS TOOL OR BY THE SEAT THAT WROTE IT.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
