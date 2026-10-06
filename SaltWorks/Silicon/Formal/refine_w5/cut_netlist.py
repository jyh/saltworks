#!/usr/bin/env python3
"""Cut the signed-off netlist's flops open IN THE TEXT: each dfxtp instance is removed, its Q net
becomes the top-level input ffq_<k> and its D net the output ffd_<k>. ff_map.tsv records k, the Q
net and the D net, so the miter places flops by the netlist's OWN net names (no cell-internal
alias can be mistaken for one). It refuses a flop cell type it does not know.
usage: cut_netlist.py gate.v gate_cut.v ff_map.tsv"""
import re, sys
t = open(sys.argv[1]).read()
FF = re.compile(r'\n\s*(sky130_fd_sc_hd__(df[a-z0-9]*|sdf[a-z0-9]*|dlx[a-z0-9]*|dlr[a-z0-9]*|dlclkp)_\d+)\s+(\S+)\s*\((.*?)\);', re.S)
rows, kinds = [], set()
def cut(m):
    kinds.add(m.group(2))
    pins = dict(re.findall(r'\.(\w+)\s*\(\s*(.*?)\s*\)\s*(?:,|$)', m.group(4).strip(), re.S))
    k = len(rows); rows.append((k, pins['Q'], pins['D'], m.group(3)))
    # an escaped identifier ends at whitespace, so each net reference is followed by a space
    return f"\n assign {pins['Q']} = ffq_{k} ;\n assign ffd_{k} = {pins['D']} ;"
t = FF.sub(cut, t)
if kinds - {'dfxtp'}: sys.exit(f"REFUSED: flop/latch kinds other than dfxtp: {sorted(kinds)}")
hdr = re.search(r'module\s+tt_um_saltworks_ndf_c32\s*\((.*?)\);', t, re.S)
ports = ''.join(f', ffq_{k}, ffd_{k}' for k, *_ in rows)
t = t[:hdr.end(1)] + ports + t[hdr.end(1):]
decl = ''.join(f'\n input ffq_{k};\n output ffd_{k};' for k, *_ in rows)
i = t.find(';', hdr.end()) + 1
t = t[:i] + decl + t[i:]
open(sys.argv[2], 'w').write(t)
with open(sys.argv[3], 'w') as f:
    for k, q, d, inst in rows: f.write(f"{k}\t{q.lstrip(chr(92)).strip()}\t{d.lstrip(chr(92)).strip()}\t{inst}\n")
print(f"cut {len(rows)} flops (dfxtp only)", file=sys.stderr)
