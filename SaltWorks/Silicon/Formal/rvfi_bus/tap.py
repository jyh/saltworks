#!/usr/bin/env python3
"""tap.py <srcdir> <outdir> — derive TAPPED copies of the fabricated core32.v and plane32bus.v.

Yosys (open source) cannot read a hierarchical reference — `u.inner` is silently declared as a NEW
wire (measured 2026-10-05) — so RVFI cannot reach the register file from outside the core. This
script ADDS output ports that read existing nets and changes nothing else: every original line is
kept, in order, byte for byte. run_aaj.sh then (1) checks that deleting the added lines gives back
the fabricated bytes, and (2) proves the tapped plane equivalent to the fabricated one on every
original output, so the taps cannot have changed the design under test.
"""
import sys, os
src, out = sys.argv[1], sys.argv[2]
TAPS = [("t_instr", 32, "instr"), ("t_rf1", 32, "rf1"), ("t_rf2", 32, "rf2"),
        ("t_pc_next", 32, "pc_next"), ("t_wb_val", 32, "wb_val"), ("t_reg_we", 1, "reg_we")]
names = ", ".join(t[0] for t in TAPS)

def once(text, old, new):
    assert text.count(old) == 1, (old, text.count(old))
    return text.replace(old, new)

def width(w): return "" if w == 1 else f"[{w-1}:0] "

c = open(os.path.join(src, "core32.v")).read()
c = once(c, "              dmem_req, dmem_we, imem_addr);",
            "              dmem_req, dmem_we, imem_addr,\n              " + names + "); // TAP: added ports")
decl = "".join(f"    output {width(w)}{n}; assign {n} = {s}; // TAP\n" for n, w, s in TAPS)
assert c.rstrip().endswith("endmodule")
k = c.rstrip().rfind("endmodule")
c = c[:k] + decl + c[k:]
open(os.path.join(out, "core32.v"), "w").write(c)

p = open(os.path.join(src, "plane32bus.v")).read()
p = once(p, "module plane32bus(clk, rst_n, sof, instr_byte, addr_byte, phase_o, retire);",
            "module plane32bus(clk, rst_n, sof, instr_byte, addr_byte, phase_o, retire,\n                  " + names + "); // TAP: added ports")
p = once(p, "        .imem_addr(c_imem_addr));",
            "        .imem_addr(c_imem_addr),\n        " + ", ".join(f".{n}({n})" for n, _, _ in TAPS) + "); // TAP")
pdecl = "".join(f"    output wire {width(w)}{n}; // TAP\n" for n, w, _ in TAPS)
i = p.index("    output wire       retire;"); j = p.index("\n", i) + 1   # after the WHOLE original line
assert p.count("    output wire       retire;") == 1
p = p[:j] + pdecl + p[j:]
# ---- busadapt8: the adapter state the LW SHAPE's induction needs (read-only, like the core's) ----
BTAPS = [("t_rdata_r", 32, "rdata_r"), ("t_instr_r", 32, "instr_r"), ("t_phase", 2, "phase"),
         ("t_kind", 2, "kind"), ("t_store_beat", 1, "store_beat")]
bnames = ", ".join(t[0] for t in BTAPS)
b = open(os.path.join(src, "busadapt8.v")).read()
b = once(b, "                 pin_in, pin_out, phase_pins, retire);",
            "                 pin_in, pin_out, phase_pins, retire,\n                 " + bnames + "); // TAP: added ports")
bdecl = "".join(f"    output {width(w)}{n}; assign {n} = {s}; // TAP\n" for n, w, s in BTAPS)
k = b.rstrip().rfind("endmodule"); assert b.rstrip().endswith("endmodule")
b = b[:k] + bdecl + b[k:]
open(os.path.join(out, "busadapt8.v"), "w").write(b)
p = once(p, "        .retire(retire));",
            "        .retire(retire),\n        " + ", ".join(f".{n}({n})" for n, _, _ in BTAPS) + "); // TAP")
p = once(p, "                  " + names + "); // TAP: added ports",
            "                  " + names + ",\n                  " + bnames + "); // TAP: added ports")
i = p.index("    output wire       retire;"); j = p.index("\n", i) + 1
p = p[:j] + "".join(f"    output wire {width(w)}{n}; // TAP\n" for n, w, _ in BTAPS) + p[j:]
open(os.path.join(out, "plane32bus.v"), "w").write(p)
print("tap.py: added", len(TAPS), "core taps and", len(BTAPS), "adapter taps (core32.v, busadapt8.v, plane32bus.v)")
