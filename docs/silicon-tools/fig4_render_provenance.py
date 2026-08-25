#!/usr/bin/env python3
"""render_provenance.py — THE SECOND COLOURING the helm asked for.

⛔ WHAT THIS IS NOT: a fork of fig4_render.py. It IMPORTS the committed tool and
runs ITS `main()`. Every line of geometry, DEF parsing, packing-derived widths,
conservation accounting, die outline, SVG writer and PNG encoder is the SHIPPED
CODE, executed unmodified. Exactly four module globals are rebound:

    read_classes   -> reads column 5 (provenance_color) instead of column 4
    COLORS         -> the provenance palette, DERIVED (see below), not chosen
    LEGEND_GROUPS  -> the four provenance classes, one member each
    _F['_']        -> an underscore glyph, so the labels render VERBATIM
                      (the shipped 5x7 font has no '_', which would silently
                       print `AGENT WRITTEN` for `agent_written`)

⛔ NO TAXONOMY IS COINED. The four class names are emitted verbatim by the
committed `fig4_classify.sh` (its `pc =` assignments): agent_written,
kernel_emitted, tool_inserted_cts, tool_inserted_timing_repair.

✅ THE PALETTE IS DERIVED FROM THE DATA, NOT PICKED. Council ratified the
FUNCTION palette (hue = family, shade = member). Each provenance class here
takes the ratified colour of the function class that DOMINATES it, with the
dominant member computed from the TSV at run time — so the colours are a
measurement, not an aesthetic choice, and they move if the data moves.
"""
import sys, os, importlib.util
from collections import Counter, defaultdict

TOOL = "/Users/jyh/projects/claude/saltworks/docs/silicon-tools/fig4_render.py"
TOOL_SHA = "218314e8492dd25818d5416591660a2c97fc20e395740fc5389c0a06b3023dda"

import hashlib
h = hashlib.sha256(open(TOOL, "rb").read()).hexdigest()
if h != TOOL_SHA:
    sys.exit(f"⛔ REFUSING: fig4_render.py is not the pinned build\n   want {TOOL_SHA}\n   got  {h}")

spec = importlib.util.spec_from_file_location("fig4r", TOOL)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)          # __name__ == 'fig4r', so main() does NOT run

if len(sys.argv) != 4:
    sys.exit("usage: render_provenance.py <placement.def> <classes.tsv> <out-prefix>")
defp, tsvp, out = sys.argv[1:4]

# ── derive the palette from the TSV: dominant function member per provenance ──
pairs = Counter()
prov  = Counter()
with open(tsvp) as f:
    hdr = next(f).rstrip("\n").split("\t")
    assert hdr[3] == "function_color" and hdr[4] == "provenance_color", hdr
    for line in f:
        p = line.rstrip("\n").split("\t")
        if len(p) >= 5:
            pairs[(p[4], p[3])] += 1
            prov[p[4]] += 1

by_prov = defaultdict(list)
for (pc, fc), n in pairs.items():
    by_prov[pc].append((n, fc))

PAL, DERIV = {}, []
for pc, members in by_prov.items():
    members.sort(key=lambda t: (-t[0], t[1]))
    n, fc = members[0]
    PAL[pc] = m.COLORS[fc]
    DERIV.append((pc, prov[pc], fc, n, m.COLORS[fc], len(members)))

# ── rebind the four globals ──
m.COLORS = PAL
m.LEGEND_GROUPS = [(pc, [pc]) for pc in sorted(prov, key=lambda k: -prov[k])]
m._F['_'] = "00000000000000000000000000000011111"
def read_classes_provenance(path):
    cls = {}
    with open(path) as f:
        next(f)
        for line in f:
            p = line.rstrip("\n").split("\t")
            if len(p) >= 5:
                cls[p[0]] = p[4]
    return cls
m.read_classes = read_classes_provenance

print("PROVENANCE PALETTE — derived, one line per class:")
for pc, tot, fc, n, col, k in sorted(DERIV, key=lambda t: -t[1]):
    print(f"  {pc:<28} {tot:>6}  <- dominant function member {fc} ({n} of {k} members)"
          f"  rgb{col}  #{col[0]:02x}{col[1]:02x}{col[2]:02x}  L*={m._lum(col):.1f}")
L = sorted((m._lum(c), p) for p, c in PAL.items())
print("  luminance ladder (Rec.709), adjacent gaps:")
for i in range(len(L)):
    gap = f"  gap {L[i][0]-L[i-1][0]:.1f}" if i else ""
    print(f"    {L[i][0]:6.1f}  {L[i][1]}{gap}")
print()

sys.argv = ["fig4_render.py", defp, tsvp, out]
m.main()
