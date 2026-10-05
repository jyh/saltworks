#!/usr/bin/env python3
"""cex.py <trace.vcd> — print every RETIREMENT in a riscv-formal counterexample, as the wrapper's RVFI
reports it (pins for insn/pc/mem, taps for registers). Minimal VCD reader; no dependencies."""
import sys
want = ["rvfi_valid","rvfi_insn","rvfi_pc_rdata","rvfi_rs1_rdata","rvfi_rs2_rdata","rvfi_rd_addr","rvfi_rd_wdata",
        "rvfi_mem_addr","rvfi_mem_rmask","rvfi_mem_rdata","rvfi_mem_wmask","rvfi_mem_wdata","rvfi_trap"]
ids, scope, cur, rows, t = {}, [], {}, [], None
for line in open(sys.argv[1]):
    w = line.split()
    if not w: continue
    if w[0] == "$scope": scope.append(w[2])
    elif w[0] == "$upscope": scope.pop()
    elif w[0] == "$var" and w[4] in want and scope[-1] == "wrapper": ids[w[3]] = w[4]
    elif w[0].startswith("#"):
        if t is not None: rows.append((t, dict(cur)))
        t = int(w[0][1:])
    elif w[0][0] == "b" and len(w) == 2 and w[1] in ids: cur[ids[w[1]]] = int(w[0][1:].replace("x","0"), 2)
    elif w[0][0] in "01" and w[0][1:] in ids: cur[ids[w[0][1:]]] = int(w[0][0])
rows.append((t, dict(cur)))
assert ids, "no wrapper rvfi_* signals found"
step = 0
for t, v in rows:
    if v.get("rvfi_valid"):
        f = lambda k: "%08x" % v.get(k, 0)
        print(f"t={t:<4} insn={f('rvfi_insn')} pc={f('rvfi_pc_rdata')} rs1={f('rvfi_rs1_rdata')} rs2={f('rvfi_rs2_rdata')} rd=x{v.get('rvfi_rd_addr',0)}<-{f('rvfi_rd_wdata')}"
              f" mem@{f('rvfi_mem_addr')} r{v.get('rvfi_mem_rmask',0):x}={f('rvfi_mem_rdata')} w{v.get('rvfi_mem_wmask',0):x}={f('rvfi_mem_wdata')} trap={v.get('rvfi_trap',0)}")
