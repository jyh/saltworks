#!/usr/bin/env python3
"""STAGE MAP — colour a placed die by which pipeline stage each cell belongs to.

    ./stage_map.py <netlist.v> <placed.def> [out.svg]

This is the acceptance-test instrument for the column-layout experiment. The test
is not "does it look tidier" — the maestro's 18:44 find sharpened it to the right
one: the 1990 Batcher die (ISSCC'90 Fig. 6) is legible because you can **COUNT
the columns**. So the AFTER image passes if a reader can count THREE stage
stripes with channels between them, and fails if it is merely neater.

⚠️ ATTRIBUTION GOES THROUGH NETS, NOT INSTANCE NAMES, AND THAT IS NOT OPTIONAL.
After LibreLane flattens, every cell instance is renamed to `_170_`, `_171_`, …
— the hierarchy is GONE from instance names. What survives is the NET names:
`fabric.e00.act0` and friends. So a cell is attributed to a stage by the nets it
touches, and anything keyed on instance names (`MANUAL_GLOBAL_PLACEMENTS`, a
DEF GROUPS wildcard like `fabric.e0*/*`) cannot work on this design.

Measured on the first CI artifact: 20,122 instances, 327 of them logic, and
**161 attributable to a single stage** this way. The rest touch only
machine-named nets — interior logic whose every net was renamed — and are left
grey rather than guessed at.
"""

import collections
import json
import re
import sys

COL = {0: "#e4572e", 1: "#17bebb", 2: "#ffc914"}
LAB = {0: "stage 0 (MSB, pairs i,i^4)",
       1: "stage 1 (pairs i,i^2)",
       2: "stage 2 (LSB, pairs i,i^1)"}


def stage_by_connectivity(netlist_path):
    """instance -> stage, decided by the hierarchical nets the cell touches."""
    nl = open(netlist_path).read()
    inst_nets = collections.defaultdict(set)
    for m in re.finditer(r'sky130_fd_sc_hd__\S+\s+(\S+)\s*\(([^;]*?)\);', nl, re.S):
        inst = m.group(1).lstrip("\\").strip()
        for net in re.findall(r'\.\w+\(\s*(\\?[^\s,()]+)', m.group(2)):
            inst_nets[inst].add(net.lstrip("\\"))
    out = {}
    for inst, nets in inst_nets.items():
        seen = {int(mm.group(1)) for n in nets
                for mm in [re.match(r'fabric\.e(\d)\d', n)] if mm}
        if len(seen) == 1:
            out[inst] = seen.pop()
    return out, len(inst_nets)


def placements(def_path):
    txt = open(def_path).read()
    die = tuple(map(int, re.search(
        r'DIEAREA \( (\d+) (\d+) \) \( (\d+) (\d+) \)', txt).groups()))
    comp = re.search(r'COMPONENTS \d+ ;(.*?)END COMPONENTS', txt, re.S).group(1)
    return die, re.findall(
        r'^\s*-\s+(\S+)\s+(\S+)\s*\+\s*(?:SOURCE \w+\s*\+\s*)?'
        r'PLACED\s*\(\s*(-?\d+)\s+(-?\d+)\s*\)', comp, re.M)


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    netlist, defp = sys.argv[1], sys.argv[2]
    out = sys.argv[3] if len(sys.argv) > 3 else "stage-map.svg"

    stage_of, n_inst = stage_by_connectivity(netlist)
    (x0, y0, x1, y1), placed = placements(defp)

    pts = collections.defaultdict(list)
    for inst, _cell, x, y in placed:
        s = stage_of.get(inst.lstrip("\\"))
        if s is not None:
            pts[s].append((int(x), int(y)))

    W = 1200
    H = W * (y1 - y0) // (x1 - x0)
    sx = lambda v: (v - x0) * W / (x1 - x0)
    sy = lambda v: H - (v - y0) * H / (y1 - y0)

    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H+70}" '
         f'viewBox="0 0 {W} {H+70}">',
         f'<rect width="{W}" height="{H+70}" fill="#0d1b2a"/>',
         f'<rect x="0" y="0" width="{W}" height="{H}" fill="none" '
         f'stroke="#415a77" stroke-width="2"/>']
    for s in (0, 1, 2):
        for x, y in pts.get(s, []):
            o.append(f'<rect x="{sx(x):.1f}" y="{sy(y):.1f}" width="5" height="5" '
                     f'fill="{COL[s]}"/>')
    for i, s in enumerate((0, 1, 2)):
        o.append(f'<rect x="{20+i*370}" y="{H+18}" width="14" height="14" '
                 f'fill="{COL[s]}"/>')
        o.append(f'<text x="{40+i*370}" y="{H+30}" fill="#e0e1dd" '
                 f'font-family="monospace" font-size="15">'
                 f'{LAB[s]} — {len(pts.get(s, []))} cells</text>')
    o.append("</svg>")
    open(out, "w").write("\n".join(o))

    # PRINT WHAT WAS READ, per the instrument law: the counts that went into the
    # picture, not the counts the picture was supposed to have.
    print(f"instances in netlist : {n_inst}")
    print(f"attributed to a stage: {len(stage_of)}   plotted: {sum(len(v) for v in pts.values())}")
    for s in (0, 1, 2):
        p = pts.get(s, [])
        if p:
            xs = [q[0] / 1000 for q in p]
            ys = [q[1] / 1000 for q in p]
            print(f"  stage {s}: n={len(p):3d}  x {min(xs):6.1f}-{max(xs):6.1f} um"
                  f"   y {min(ys):6.1f}-{max(ys):6.1f} um")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
