#!/bin/sh
# slewcapgate.sh — CLASSIFY THE SLEW AND CAP VIOLATORS drvgate.sh DOES NOT READ.
#
#   sh docs/silicon-tools/slewcapgate.sh <librelane-run-dir>
#   exit 0 = zero clock-network violators   1 = clock-network violators present   2 = cannot measure
#
# ⛔ WHY THIS EXISTS, 2026-09-08. `drvgate.sh` ends by printing its own scope:
#   "This gate reads FANOUT ONLY. Slew, cap, antenna, DRC and LVS are other checks."
#   That sentence was true and nothing consumed it. The shipped chip reports 1051 slew and
#   13 cap violations at its worst corner and the fleet had no instrument that could say
#   WHERE they are — so the question "are they benign?" had no observable behind it.
#
# ⭐ THE CLAUSE THIS BORROWS, AND IT IS THE ONE THAT MATTERS: §11a of
#   docs/silicon-ndf-pair-results-0827.md calls ZERO CLOCK-LEAF the serious half of the
#   fanout waiver. The same split is the right one for slew and cap, for a reason that is
#   structural rather than by analogy:
#     · a DATAPATH slew violation makes data LATER. That spends SETUP margin (8.02 ns at the
#       worst corner, on a 55 ns period) and it BUYS hold margin.
#     · a CLOCK-NETWORK slew violation moves the sampling EDGE, which spends HOLD margin —
#       and hold is the tight one here (0.190 ns worst, and a slow period does not help it).
#   ⇒ THE TWO POPULATIONS NEED OPPOSITE VERDICTS FROM THE SAME COUNT. Classify before you
#     report; a total cannot answer this.
#
# ⛔⛔ THE CLASSIFIER IS WIDER THAN drvgate's ON PURPOSE, AND THAT IS THE FINDING.
#   drvgate keys on `clkbuf_` / `clknet`, correct for its DRIVEN population (ndf-1d's 111
#   violators were all clkbuf_leaf_*/X). A SLEW violator can also sit on a flop's own CLK
#   input pin, which carries NEITHER token. Inheriting that classifier unchanged would have
#   counted a clock violation as datapath and reported the benign answer.
#   ⇒ ***A CLASSIFIER IS VALID FOR THE POPULATION IT WAS DRIVEN ON, AND A NEW CHECK IS A
#     NEW POPULATION.***
#
# ✅ TWO CONTROLS, BOTH REQUIRED, BECAUSE "ZERO CLOCK VIOLATORS" AND "A CLASSIFIER THAT
#    MATCHES NOTHING" PRINT THE SAME ZERO:
#   (1) SELF-CONSISTENCY — parsed violated rows must equal the report's own declared count,
#       per corner, or NO VERDICT IS OFFERED (drvgate's pattern, kept).
#   (2) POSITIVE CONTROL — is_clock() must MATCH somewhere in this run's own reports. If the
#       design has no clock pins my classifier can see, a zero in the violator list means
#       nothing and this script REFUSES rather than reporting benign.
set -u
RUN="${1:-}"
[ -n "$RUN" ] || { echo "usage: slewcapgate.sh <librelane-run-dir>" >&2; exit 2; }
[ -d "$RUN" ] || { echo "slewcapgate: not a directory: $RUN" >&2; exit 2; }
STA=""
for d in "$RUN"/*-openroad-stapostpnr; do [ -d "$d" ] && STA="$d"; done
[ -n "$STA" ] || { echo "slewcapgate: no *-openroad-stapostpnr step under $RUN — CANNOT MEASURE (a blank is not a pass)" >&2; exit 2; }

python3 - "$STA" <<'PY'
import sys, glob, os, re
sta = sys.argv[1]
reports = sorted(glob.glob(os.path.join(sta, "*", "checks.rpt")))
if not reports:
    print("slewcapgate: 0 corner reports under %s — CANNOT MEASURE (a blank is not a pass)" % sta); sys.exit(2)

def is_clock(pin):
    return (pin.startswith("clkbuf_") or "clknet" in pin
            or pin.endswith("/CLK") or pin.endswith("/GCLK"))

def kind(p):
    if p.startswith("ANTENNA_"): return "antenna diode"
    if p.startswith("fanout"):   return "fanout buffer"
    if p.startswith("wire"):     return "wire buffer"
    if p.startswith("input"):    return "input port buffer"
    return "logic cell"

def block(path, name, ends):
    rows, declared, inblk = [], None, False
    key = "max cap" if name == "max capacitance" else name
    for line in open(path, errors="replace"):
        s = line.strip()
        if s == name: inblk = True; continue
        if inblk and any(s.startswith(e) for e in ends): inblk = False; continue
        if inblk and s.endswith("(VIOLATED)"):
            p = s.split()
            try: rows.append((p[0], float(p[3])))
            except (IndexError, ValueError): return None, None, "unparsable row: %s" % s
        m = re.match(r'^%s violation count (\d+)$' % re.escape(key), s)
        if m: declared = int(m.group(1))
    return rows, declared, None

errs, tot_cs, tot_cc, kinds = [], 0, 0, {}
print("slewcapgate: %d corner reports read under %s" % (len(reports), os.path.basename(sta)))
print("  %-22s %8s %8s %10s %8s %8s" % ("CORNER","SLEW","CLK-slew","worst-slack","CAP","CLK-cap"))
for f in reports:
    corner = os.path.basename(os.path.dirname(f))
    srows, sdecl, se = block(f, "max slew", ["max fanout", "max capacitance"])
    crows, cdecl, ce = block(f, "max capacitance", ["max slew", "max fanout", "==="])
    if se or ce: errs.append("%s: %s" % (corner, se or ce)); continue
    if sdecl is not None and sdecl != len(srows):
        errs.append("%s: parsed %d slew rows, report declares %d" % (corner, len(srows), sdecl))
    if cdecl is not None and cdecl != len(crows):
        errs.append("%s: parsed %d cap rows, report declares %d" % (corner, len(crows), cdecl))
    cs = [p for p, _ in srows if is_clock(p)]
    cc = [p for p, _ in crows if is_clock(p)]
    tot_cs += len(cs); tot_cc += len(cc)
    for p, _ in srows: kinds[kind(p)] = kinds.get(kind(p), 0) + 1
    ws = min([s for _, s in srows], default=0.0)
    print("  %-22s %8d %8d %10.3f %8d %8d" % (corner, len(srows), len(cs), ws, len(crows), len(cc)))

# CONTROL (2): the classifier must be able to say YES somewhere in this run.
pins = set()
for f in reports:
    d = os.path.dirname(f)
    for fn in ("checks.rpt", "clock.rpt", "max.rpt"):
        p = os.path.join(d, fn)
        if not os.path.exists(p): continue
        for line in open(p, errors="replace"):
            for m in re.finditer(r'\b([A-Za-z_][\w\.\[\]]*/[A-Za-z0-9_]+)\b', line):
                pins.add(m.group(1))
matches = sum(1 for p in pins if is_clock(p))

if errs:
    print("⛔ REFUSED — THE INSTRUMENT DISAGREES WITH ITSELF, so no verdict is offered:")
    for e in errs: print("    " + e)
    sys.exit(2)
if matches == 0:
    print("⛔ REFUSED — is_clock() matched NOTHING in this run's own reports (%d pins seen)." % len(pins))
    print("   A zero in the violator list is then a fact about the classifier, not the design.")
    sys.exit(2)

print("  positive control: is_clock() matches %d of %d distinct pins in this run — it CAN say yes." % (matches, len(pins)))
print("  slew violator population (all corners): " + ", ".join("%d %s" % (v, k) for k, v in sorted(kinds.items(), key=lambda x: -x[1])))
if tot_cs or tot_cc:
    print("⛔ CLOCK-NETWORK DRV VIOLATORS PRESENT: %d slew, %d cap. The serious half of the" % (tot_cs, tot_cc))
    print("   §11a split. A datapath violation spends setup margin; this spends HOLD margin.")
    sys.exit(1)
print("✅ ZERO clock-network slew and cap violators across all %d corners." % len(reports))
print("   ⚠️ This gate reads WHERE the violations are, never whether the margin is sufficient.")
print("      Setup/hold slack, DRC, LVS and antenna are other checks.")
sys.exit(0)
PY
