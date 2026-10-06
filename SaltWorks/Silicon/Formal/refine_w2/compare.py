#!/usr/bin/env python3
"""W2 comparator: Lean `exec` vectors (w2_vectors.txt) vs riscv-formal's insn models (w2_rvf.txt).
Classes: AGREE · SCOPE (the declared choice: misaligned LW/SW, out of scope in the Lean spec) ·
MISMATCH. Prints per-opcode counts and exits 1 on any MISMATCH, 2 if nothing was compared."""
import sys, collections
lv = [l.split() for l in open(sys.argv[1]) if l.strip()]
rv = [l.split() for l in open(sys.argv[2]) if l.strip()]
if len(lv) != len(rv): print(f"LENGTH {len(lv)} vs {len(rv)}"); sys.exit(2)
cls = collections.Counter(); bad = []
for a, b in zip(lv, rv):
    insn, rs1v, rs2v, pc, memr = (int(x, 16) for x in a[:5]); st = a[5]
    nv, trap, rrd = int(b[0]), int(b[1]), int(b[2])
    wd, pcw, ma, mw = (int(x, 16) for x in b[3:7]); rm, wm = int(b[7], 16), int(b[8], 16)
    opc, f3 = insn & 0x7f, (insn >> 12) & 7
    rvf_ok = nv == 1 and trap == 0
    if st == 'N':
        if not rvf_ok: cls['AGREE out-of-scope'] += 1; continue
        if opc in (0x03, 0x23) and f3 == 2:
            imm = (insn >> 20) if opc == 0x03 else (((insn >> 25) << 5) | ((insn >> 7) & 31))
            imm = imm - 4096 if imm & 0x800 else imm
            if (rs1v + imm) % 4 != 0: cls['SCOPE misaligned LW/SW'] += 1; continue
        bad.append(('lean N, rvf valid', a, b)); continue
    if not rvf_ok: bad.append(('lean S, rvf not valid/trap', a, b)); continue
    rd, rdv, pcn, kind, lma, lmw = int(a[6]), int(a[7], 16), int(a[8], 16), int(a[9]), int(a[10], 16), int(a[11], 16)
    ok = rd == rrd and rdv == wd and pcn == pcw
    if kind == 0: ok = ok and rm == 0 and wm == 0
    if kind == 1: ok = ok and lma == ma and rm == 0xf and wm == 0
    if kind == 2: ok = ok and lma == ma and lmw == mw and wm == 0xf and rm == 0
    if ok: cls[f'AGREE opc={opc:02x} f3={f3}'] += 1
    else: bad.append(('outputs differ', a, b))
agree = sum(v for k, v in cls.items() if k.startswith('AGREE'))
for k in sorted(cls): print(f"{cls[k]:6d}  {k}")
print(f"TOTAL {len(lv)}  AGREE {agree}  SCOPE {cls['SCOPE misaligned LW/SW']}  MISMATCH {len(bad)}")
for why, a, b in bad[:8]: print("MISMATCH", why, '|', ' '.join(a), '|', ' '.join(b))
sys.exit(1 if bad else (2 if agree == 0 else 0))
