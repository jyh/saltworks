#!/usr/bin/env python3
"""Build the combinational check: the gold (flops cut open by `expose -evert-dff`) beside the Lean
model's combinational print (`model_comb`). Every alias of a flop's output net is tied to ONE state
input, and EVERY alias's next-state output must equal the model's. Refuses any `.q` port it cannot
place, so no flop is silently left out. usage: comb_wrap.py gold_exp.v model_module > chkbad.v  (`bad` is 1 iff some compared signal differs)"""
import re, sys
txt = open(sys.argv[1]).read(); gate = sys.argv[2]
ports = re.findall(r'^\s*(input|output)\s*(\[\d+:\d+\])?\s*(\\\S+|\w+)\s*;', txt, re.M)
ALIAS = {'u_core.pc_q': 'u_core.pc_r', 'u_bus.c_dmem_rdata': 'u_bus.rdata_r',
         'u_core.dmem_rdata': 'u_bus.rdata_r', 'u_core.ld_out': 'u_bus.rdata_r', 'c_dmem_rdata': 'u_bus.rdata_r'}
FLOPS = {'u_core.pc_r': 32, 'u_bus.phase': 2, 'u_bus.kind': 2, 'u_bus.store_beat': 1, 'u_bus.fetch_owed': 1,
         'u_bus.in_acc': 32, 'u_bus.instr_r': 32, 'u_bus.rdata_r': 32}
FLOPS.update({f'u_core.regs[{j}]': 32 for j in range(1, 32)})
def s_of(f): return 's_' + f.replace('.', '_').replace('[', '_').replace(']', '')
def n_of(f): return 'n_' + f.replace('.', '_').replace('[', '_').replace(']', '')
conn, checks, seen = [], [], set()
for d, w, nm in ports:
    base = nm.lstrip('\\')
    if base.endswith('.q') or base.endswith('.d') or base.endswith('.c'):
        f, kind = base[:-2], base[-1]
        canon = ALIAS.get(f, f)
        if canon not in FLOPS: sys.exit(f"REFUSED: cannot place flop port {base}")
        if kind == 'q': conn.append(f".\\{base} ({s_of(canon)})"); seen.add(canon)
        elif kind == 'c': pass  # the flop's clock, an OUTPUT of the cut-open module
        else:
            wn = 'g_' + base.replace('.', '_').replace('[', '_').replace(']', '')
            checks.append((wn, FLOPS[canon], n_of(canon))); conn.append(f".\\{base} ({wn})")
    elif nm in ('rst_n', 'sof', 'instr_byte'): conn.append(f".{nm}({nm})")
    elif nm == 'clk': conn.append(".clk(1'b0)")
missing = set(FLOPS) - seen
if missing: sys.exit(f"REFUSED: flops with no .q port in the gold: {sorted(missing)}")
L = ['module chkbad(input wire rst_n, input wire sof, input wire [7:0] instr_byte,']
L.append('  ' + ', '.join(f'input wire [{w-1}:0] {s_of(f)}' for f, w in FLOPS.items()) + ',')
L.append('  output wire bad);')
for wn, w, _ in checks: L.append(f'  wire [{w-1}:0] {wn};')
L.append('  wire [7:0] g_addr_byte, m_addr_byte; wire [1:0] g_phase_o, m_phase_o; wire g_retire, m_retire;')
for f, w in FLOPS.items(): L.append(f'  wire [{w-1}:0] {n_of(f)};')
L.append('  gold_exp g(' + ', '.join(conn) + ', .addr_byte(g_addr_byte), .phase_o(g_phase_o), .retire(g_retire));')
L.append(f'  {gate} m(.rst_n(rst_n), .sof(sof), .instr_byte(instr_byte), .addr_byte(m_addr_byte), .phase_o(m_phase_o), .retire(m_retire), '
         + ', '.join(f'.{s_of(f)}({s_of(f)}), .{n_of(f)}({n_of(f)})' for f in FLOPS) + ');')
eqs = ['g_addr_byte == m_addr_byte', 'g_phase_o == m_phase_o', 'g_retire == m_retire'] + [f'{wn} == {nn}' for wn, _, nn in checks]
L.append('  assign bad = !(' + ' && '.join(f'({e})' for e in eqs) + ');')
L.append('endmodule')
print('\n'.join(L))
print(f"// {len(checks)} next-state comparisons (aliases included) + 3 pin outputs; {len(FLOPS)} flops", file=sys.stderr)
