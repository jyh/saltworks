#!/usr/bin/env python3
"""patch_variants.py <dir> <variant> — CONTROLS ONLY, never a design proposal. Rewrites the fabricated
sources in <dir> in place. Each replacement must match EXACTLY ONCE or the script refuses (rc 2), so a
drifted source cannot silently yield an unpatched 'control'.
  imm    OP-IMM alu_op carries funct7[5] for funct3=101 (SRAI decodes as SRAI, not SRLI)
  sra    the arithmetic shift is computed in its own signed-context wire, outside the ?: chain
  shift  imm + sra
  all    shift + c_dmem_rdata bypasses the in-flight word at the load loop's retiring edge
"""
import sys
d, v = sys.argv[1], sys.argv[2]
IMM = [("core32.v", "is_immop ? {1'b0,funct3}", "is_immop ? {f7 & (funct3==3'b101),funct3}")]
SRA = [("core32.v", "(alu_op==4'hd) ? $signed(rf1) >>> b_op[4:0] :", "(alu_op==4'hd) ? sra_y :"),
       ("core32.v", "    assign alu_y =", "    wire [31:0] sra_y = $signed(rf1) >>> b_op[4:0];\n    assign alu_y =")]
LW  = [("busadapt8.v", "    assign c_dmem_rdata = rdata_r;",
        "    assign c_dmem_rdata = (kind == T_LOAD && phase == 2'd3) ? {pin_in, in_acc[23:0]} : rdata_r;")]
plan = {"imm": IMM, "sra": SRA, "shift": IMM + SRA, "all": IMM + SRA + LW}[v]
for f, a, b in plan:
    p = f"{d}/{f}"; s = open(p).read()
    if s.count(a) != 1:
        print(f"REFUSE {v}: {f} has {s.count(a)} copies of {a!r}"); sys.exit(2)
    open(p, "w").write(s.replace(a, b))
print(f"patched {v}: {len(plan)} edits")
