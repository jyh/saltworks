#!/bin/sh
# drvgate.sh — REFUSE A SUBMISSION THAT DOES NOT MEET THE COUNCIL'S FANOUT WAIVER.
#
#   sh docs/silicon-tools/drvgate.sh <librelane-run-dir>
#   exit 0 = MEETS the waived object   1 = REFUSED   2 = usage / cannot measure
#
# ⛔ WHY THIS EXISTS, 2026-08-28 17:3x. Council item 3 (close 10:49) waived ONE datapath
#   net at fanout 11, and §11a of docs/silicon-ndf-pair-results-0827.md records the waived
#   object as a PROPERTY, not a name: "at most one datapath violator at fanout 11-12, zero
#   clock-leaf". It then says "CHECK AT SUBMISSION" — and the checker was A SENTENCE.
#   `harden_run.sh` PRINTS design__max_fanout_violation__count inside a loop and consumes
#   nothing; the freeze is 2026-09-07 13:00 PDT and the hand reading that printout on the
#   day is mine, in a hurry.
#   ⇒ ***A CORRECT CRITERION WHOSE EXIT STATUS NOTHING CONSUMES IS A PRINTOUT.***
#
# ⛔ AND WHY IT DOES NOT USE THE METRIC. design__max_fanout_violation__count IS A TOTAL and
#   the waiver is about a CLASSIFICATION: measured on the four archived runs, ndf-1d scores
#   111 and every one is a clock-tree leaf (REFUSE), while ndf-2a scores 1 and it is a
#   datapath net (ACCEPT). A gate keyed on the total gives the same number one verdict; the
#   two populations need opposite ones. CLASSIFY BEFORE YOU REPORT.
#
# 📌 The step directory is found by GLOB (*-openroad-stapostpnr), never by its index: the
#   step number is a layout constant of one flow config and moves between runs.
set -u

RUN="${1:-}"
[ -n "$RUN" ] || { echo "usage: drvgate.sh <librelane-run-dir>" >&2; exit 2; }
[ -d "$RUN" ] || { echo "drvgate: not a directory: $RUN" >&2; exit 2; }

STA=""
for d in "$RUN"/*-openroad-stapostpnr; do [ -d "$d" ] && STA="$d"; done
[ -n "$STA" ] || { echo "drvgate: no *-openroad-stapostpnr step under $RUN — CANNOT MEASURE (a blank is not a pass)" >&2; exit 2; }

python3 - "$STA" <<'PY'
import sys, glob, os

sta = sys.argv[1]
reports = sorted(glob.glob(os.path.join(sta, "*", "checks.rpt")))
if not reports:
    print("drvgate: 0 corner reports under %s — CANNOT MEASURE (a blank is not a pass)" % sta)
    sys.exit(2)

def is_clock(pin):
    # driven: 1d's 111 violators are all clkbuf_leaf_<n>_clk/X; 2a's single one is wire695/X
    return pin.startswith("clkbuf_") or "clknet" in pin

clock, data, parse_err = {}, {}, []
for f in reports:
    corner, inblk, seen = os.path.basename(os.path.dirname(f)), False, 0
    declared = None
    for line in open(f, errors="replace"):
        s = line.strip()
        if s == "max fanout":
            inblk = True; continue
        if inblk and s.startswith("max cap"):
            inblk = False; continue
        if inblk and s.endswith("(VIOLATED)"):
            p = s.split()
            try:
                pin, fo = p[0], int(p[2])
            except (IndexError, ValueError):
                parse_err.append("%s: unparsable row: %s" % (corner, s)); continue
            seen += 1
            (clock if is_clock(pin) else data).setdefault(pin, fo)
            if fo > (clock if is_clock(pin) else data)[pin]:
                (clock if is_clock(pin) else data)[pin] = fo
        if s.startswith("max fanout violation count"):
            declared = int(s.split()[-1])
    # CONTROL, and it can refuse: my parse must equal the tool's own summary line.
    if declared is None:
        parse_err.append("%s: no 'max fanout violation count' summary line" % corner)
    elif declared != seen:
        parse_err.append("%s: parsed %d violated rows, report declares %d" % (corner, seen, declared))

print("drvgate: %d corner reports read under %s" % (len(reports), os.path.basename(sta)))
if parse_err:
    print("⛔ REFUSED — THE INSTRUMENT DISAGREES WITH ITSELF, so no verdict is offered:")
    for e in parse_err: print("    " + e)
    sys.exit(2)

worst = max(data.values()) if data else 0
print("    clock-leaf violators : %d   %s" % (len(clock), sorted(clock)[:4] or ""))
print("    datapath violators   : %d   %s" % (len(data), sorted(data.items())))
print("    worst datapath fanout: %d" % worst)

fail = []
if clock:            fail.append("%d clock-leaf violator(s) — the waiver covers ZERO" % len(clock))
if len(data) > 1:    fail.append("%d datapath violators — the waiver covers AT MOST ONE" % len(data))
if worst > 12:       fail.append("datapath fanout %d — the waiver covers 11-12" % worst)

if fail:
    print("⛔ DRV GATE: REFUSED — the council waiver does NOT cover this run.")
    for f_ in fail: print("    " + f_)
    print("    (council item 3, 2026-08-28; waived object in docs/silicon-ndf-pair-results-0827.md §11a)")
    sys.exit(1)

print("✅ DRV GATE: MEETS THE WAIVED OBJECT — zero clock-leaf, %d datapath at fanout <=12." % len(data))
print("   ⚠️ This gate reads FANOUT ONLY. Slew, cap, antenna, DRC and LVS are other checks.")
sys.exit(0)
PY
