#!/usr/bin/env python3
"""Check a TT submission artifact against the SIGNOFF CRITERION THAT GOVERNS.

⛔⛔ WHY THIS FILE EXISTS AND WHY IT IS IN THE REPO.
Its predecessor lived in a session scratchpad and encoded the PRE-AMENDMENT bar
(`max_fanout` and `max_cap` must not grow). On 2026-09-06 the Captain ruled "ship (B)" and
the count clause was amended; the script kept printing "DO NOT LAND" on an artifact that
MEETS the governing criterion, and its red looked identical before and after the criterion
moved.
⇒ ***AN INSTRUMENT THAT ENCODES A CRITERION KEEPS ENFORCING THE VERSION IT WAS WRITTEN
   AGAINST.*** A gate that is permanently red is indistinguishable from a working one, and
   this seat has a banked card saying exactly that.
⇒ And the scratchpad half: A TOOL THAT LIVES IN /tmp DIES WITH THE SESSION. If a criterion
   is worth gating, its gate belongs beside the design.

THE CRITERION, as amended 2026-09-06 and as published in the shipped
`tt-neural-dataflow-fabric:docs/info.md` §Signoff:
    at most THREE datapath violators, all within fanout 11–12, and ZERO clock-leaf.
The zero-clock-leaf clause is the one §Signoff calls the serious one; it was never amended.

⚠️ CLOCK-LEAF IS DECIDED BY CONNECTIVITY, NEVER BY THE DRIVER'S CELL NAME. Two of the three
violators in the shipped part are driven by `sky130_fd_sc_hd__clkdlybuf4s25_1` — a DELAY cell
used as a datapath repair buffer. Reading "clkdlybuf" as clock nearly killed a sound repair.
KEY ON THE ARTIFACT, NEVER ON THE LABEL: a net is clock-leaf iff it drives a flop `.CLK` pin.

⛔ metrics.csv is LONG format (Metric,Value). A reader built for WIDE format finds zero of
everything and prints an empty, clean-looking report. Rehearse on a historical artifact.
"""
import csv, io, json, os, re, sys
from collections import defaultdict

FANOUT_LIMIT   = 10
MAX_DATAPATH   = 3
BAND           = (11, 12)

def metrics(base):
    d = {}
    with io.open(os.path.join(base, 'stats/metrics.csv'), encoding='utf-8') as f:
        for r in csv.reader(f):
            if len(r) >= 2 and r[0] != 'Metric':
                d[r[0]] = r[1]
    return d

def resolved(base):
    with io.open(os.path.join(base, 'resolved.json'), encoding='utf-8') as f:
        return json.load(f)

def fanout_violators(netlist):
    """Per-net fanout from the gate-level netlist, and whether each is clock-leaf."""
    s = io.open(netlist, encoding='utf-8', errors='replace').read()
    drv, ld = {}, defaultdict(list)
    for m in re.finditer(r'(\w+)\s+(\\?\S+)\s*\(([^;]*?)\)\s*;', s, re.S):
        cell, body = m.group(1), m.group(3)
        if cell in ('module', 'endmodule', 'wire', 'input', 'output', 'assign'):
            continue
        for pm in re.finditer(r'\.(\w+)\s*\(\s*([^)]*?)\s*\)', body):
            pin, net = pm.group(1), pm.group(2).strip()
            if not net or net in ('VPWR', 'VGND'):
                continue
            if pin in ('X', 'Y', 'Q', 'Q_N'):
                drv[net] = cell
            else:
                ld[net].append((cell, pin))
    out = {}
    for n, loads in ld.items():
        if n in drv and len(loads) > FANOUT_LIMIT:
            out[n] = (len(loads), drv[n], any(p == 'CLK' for _, p in loads))
    return out

def f(x):
    try:    return float(x)
    except (TypeError, ValueError): return None

def main(art):
    nl = os.path.join(art, 'tt_um_saltworks_ndf_c32.v')
    m, rj = metrics(art), resolved(art)
    ok = True
    cp = f(rj.get('CLOCK_PERIOD'))
    print(f"CLOCK_PERIOD (resolved.json — what RAN, not info.yaml's clock_hz): {cp}")

    print("\n── TIMING (a violation is NEGATIVE slack; positive slack is met) ──")
    for k, label in (('timing__setup__ws', 'setup worst slack'),
                     ('timing__hold__ws',  'hold worst slack')):
        v = f(m.get(k))
        if v is None: print(f"  {label:20s} ABSENT — UNKNOWN, not pass"); ok = False; continue
        print(f"  {label:20s} {v:>12.6g}  {'✅' if v >= 0 else '⛔ NEGATIVE'}")
        ok &= v >= 0
    for k, label in (('timing__setup__tns', 'setup TNS'), ('timing__hold__tns', 'hold TNS')):
        v = f(m.get(k))
        if v is None: print(f"  {label:20s} ABSENT — UNKNOWN, not pass"); ok = False; continue
        print(f"  {label:20s} {v:>12.6g}  {'✅' if v == 0 else '⛔ NON-ZERO'}")
        ok &= v == 0
    ws = f(m.get('timing__setup__ws'))
    if ws is not None and cp is not None:
        if ws >= 0: print(f"  worst path = CLOCK_PERIOD − WS = {cp} − {ws:.6g} = {cp-ws:.4f} ns")
        else:       print(f"  worst path = CLOCK_PERIOD + |WNS| = {cp} + {abs(ws):.6g} = {cp+abs(ws):.4f} ns")

    print("\n── THE AMENDED SIGNOFF CRITERION (2026-09-06) ──")
    if not os.path.exists(nl):
        print("  ⛔ netlist absent — the criterion is scoped by CONNECTIVITY and cannot be"); return 2
    v = fanout_violators(nl)
    dp   = {n: t for n, t in v.items() if not t[2]}
    leaf = {n: t for n, t in v.items() if t[2]}
    for n, (fo, cell, isclk) in sorted(v.items(), key=lambda x: -x[1][0]):
        print(f"  {n:10s} fanout={fo:3d}  {cell:34s} {'CLOCK-LEAF' if isclk else 'datapath'}")
    band_ok = all(BAND[0] <= t[0] <= BAND[1] for t in dp.values())
    print(f"  at most {MAX_DATAPATH} datapath : {len(dp)}  {'✅' if len(dp) <= MAX_DATAPATH else '⛔ BREACHED'}")
    print(f"  all within {BAND[0]}–{BAND[1]}     : {'✅' if band_ok else '⛔ OUT OF BAND'}")
    print(f"  ZERO clock-leaf    : {len(leaf)}  {'✅' if not leaf else '⛔ BREACHED (the serious clause)'}")
    ok &= len(dp) <= MAX_DATAPATH and band_ok and not leaf

    print("\n" + ("✅ THE ARTIFACT MEETS THE GOVERNING CRITERION" if ok
                  else "⛔ AT LEAST ONE CLAUSE NOT MET — do not declare ready"))
    return 0 if ok else 1

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__); print("usage: check_submission_metrics.py <path-to-unpacked tt_submission>")
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
