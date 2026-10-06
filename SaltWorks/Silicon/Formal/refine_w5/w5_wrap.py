#!/usr/bin/env python3
"""W5 miter: the gold tile RTL (flops cut open) beside the signed-off netlist (flops cut open).
Every netlist flop bit is one state input; it is placed on the gold flop bit of the same name, or of a
named synthesis alias (ALIAS, each one checked by the miter itself). A gold flop bit that no netlist
flop takes stays a FREE input, so if it mattered the miter would be SAT. Compared: the tile's three
output buses, and the next state of EVERY netlist flop against its gold image (aliases included).
Refuses a netlist flop it cannot place. usage: w5_wrap.py gold_exp.v ff_map.tsv > w5bad.v (the gate is cut_netlist.py's gate_cut.v, as module gate_exp)"""
import re, sys, collections
PORT = re.compile(r'^\s*(input|output)\s*(?:\[(\d+):(\d+)\])?\s*(\\\S+|\w+)\s*;', re.M)
def ports(f):
    out = []
    for d, hi, lo, nm in PORT.findall(open(f).read()):
        out.append((d, (int(hi) - int(lo) + 1) if hi else 1, nm.lstrip('\\')))
    return out
gold = ports(sys.argv[1])
ffmap = [l.rstrip('\n').split('\t') for l in open(sys.argv[2]) if l.strip()]
gq = {n[:-2]: w for d, w, n in gold if n.endswith('.q')}
gd = {n[:-2]: w for d, w, n in gold if n.endswith('.d')}
# synthesis aliases of a flop's output net, by NAME (each gold alias is also a .q port of its own)
ALIAS = {'core.u_core.pc_plus_4': 'core.u_core.pc_q'}
BIT = re.compile(r'^(.*)\[(\d+)\]$')
place, missing = {}, []
for k, qnet, dnet, inst in ffmap:
    f = f'ffq_{k}'; m = BIT.match(qnet)
    base, b = (m.group(1), int(m.group(2))) if m else (qnet, 0)
    base = ALIAS.get(base, base)
    if base in gq and b < gq[base]: place[f] = (base, b)
    else: missing.append(qnet)
if missing: sys.exit(f"REFUSED: {len(missing)} netlist flops not placeable, e.g. {missing[:6]}")
# gold alias groups: names whose .q are the same flop are tied by the gold's own structure only if
# we tie them; tie every gold .q bit that a netlist flop names, and leave the rest free
taken = collections.defaultdict(dict)
for f, (base, b) in place.items(): taken[base][b] = f
fi = {}
# GOLD ALIAS GROUPS, derived from the gold's own pre-cut netlist (gold_pre.json), never typed:
# every public name that carries a flop's output bit is one alias of that bit
import json
J = json.load(open(sys.argv[3]))['modules']['tt_um_saltworks_ndf_c32']
qbits = set()
for c in J['cells'].values():
    if c['type'] in ('$dff', '$_DFF_P_', '$_DFF_N_'): qbits.update(b for b in c['connections']['Q'] if isinstance(b, int))
group = collections.defaultdict(list)
for nm, nn in J['netnames'].items():
    if nm.startswith('$'): continue
    for i, b in enumerate(nn['bits']):
        if b in qbits: group[b].append((nm, i))
alias_of = {}
for b, names in group.items():
    for x in names: alias_of[x] = b
def bitsrc(base, b):
    g = alias_of.get((base, b))
    for x in (group[g] if g is not None else [(base, b)]):
        if x[1] in taken.get(x[0], {}): return sid(taken[x[0]][x[1]])
    key = f'{base}[{b}]' if g is None else f'net{g}'
    if key not in fi: fi[key] = len(fi)
    return f'free_bits[{fi[key]}]'
def sid(f): return 's_' + re.sub(r'[^A-Za-z0-9_]', '_', f)
L = ['module w5bad(input wire ena, input wire rst_n, input wire [7:0] ui_in, input wire [7:0] uio_in,']
L.append('  ' + ', '.join(f'input wire {sid(f)}' for f in sorted(place)) + ',')
L.append('  FREE_BITS_PORT')
L.append('  output wire bad);')
gconn = []
for base, w in gq.items():
    gconn.append(f'.\\{base}.q ({{' + ', '.join(bitsrc(base, b) for b in reversed(range(w))) + '})')
eqs = []
for base, w in gd.items():
    L.append(f'  wire [{w-1}:0] gd_{sid(base)};'); gconn.append(f'.\\{base}.d (gd_{sid(base)})')
tconn = [f'.{f}({sid(f)})' for f in place]
for f, (base, b) in place.items():
    L.append(f'  wire td_{sid(f)};'); tconn.append(f'.ffd_{f[4:]}(td_{sid(f)})')
    eqs.append(f'td_{sid(f)} == gd_{sid(base)}[{b}]')
for o, w in (('uo_out', 8), ('uio_out', 8), ('uio_oe', 8)):
    L.append(f'  wire [{w-1}:0] g_{o}, t_{o};'); eqs.append(f'g_{o} == t_{o}')
io = '.ena(ena), .rst_n(rst_n), .ui_in(ui_in), .uio_in(uio_in), .clk(1\'b0)'
L.append(f'  gold_exp g({io}, .uo_out(g_uo_out), .uio_out(g_uio_out), .uio_oe(g_uio_oe), ' + ', '.join(gconn) + ');')
L.append(f'  gate_exp t({io}, .uo_out(t_uo_out), .uio_out(t_uio_out), .uio_oe(t_uio_oe), ' + ', '.join(tconn) + ');')
# one mismatch bit per comparison, OR-reduced (a single && over ~1,500 terms overflows yosys's simplifier)
L.append(f'  wire [{len(eqs)-1}:0] mm;')
for i, e in enumerate(eqs): L.append(f'  assign mm[{i}] = !({e});')
L.append('  assign bad = |mm;')
L.append('endmodule')
free = sorted(fi, key=fi.get)
L = [l.replace('  FREE_BITS_PORT', '  input wire [%d:0] free_bits,' % max(len(free) - 1, 0)) for l in L]
print('\n'.join(L))
print(f"// netlist flops placed {len(place)} · gold flop bits left FREE {len(free)}: "
      f"{sorted(collections.Counter(re.sub(r'\[\d+\]$', '', x) for x in free).items())}", file=sys.stderr)
