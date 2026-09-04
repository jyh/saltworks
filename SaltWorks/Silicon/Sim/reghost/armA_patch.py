#!/usr/bin/env python3
"""armA_patch.py — derive the UNRATIFIED arm (A) variant of busadapt8.v.

⛔ THIS WRITES A TEMP FILE AND NOTHING ELSE. Arm (A) (a symmetric "+4" on §7's
FETCH row) is not ratified; keeping a patched copy of a ratified module in the
tree is how a dead twin is born, so the variant exists only during a run.

Arm (A) = a FETCH owns two loops (PC loop, then instruction loop), mirroring
what option (2) did for the LOAD row. Every edit is asserted to apply exactly
once: a patch that silently matches nothing produces a variant identical to the
original, and an "arm A" that is really the shipped design would score green and
mean nothing.
"""
import sys

EDITS = [
 ("    reg       load_beat;  // 0 = address loop, 1 = the LOAD's data loop  (option (2))",
  "    reg       load_beat;  // 0 = address loop, 1 = the LOAD's data loop  (option (2))\n"
  "    reg       fetch_beat; // ARM (A), UNRATIFIED: 0 = PC loop, 1 = the instruction loop"),
 ("        if (!rst_n) begin kind <= T_FETCH; store_beat <= 1'b0; load_beat <= 1'b0; end",
  "        if (!rst_n) begin kind <= T_FETCH; store_beat <= 1'b0; load_beat <= 1'b0; fetch_beat <= 1'b0; end"),
 ("            store_beat <= 1'b0;\n            load_beat  <= 1'b0;\n            kind <= c_dmem_req",
  "            store_beat <= 1'b0;\n            load_beat  <= 1'b0;\n            fetch_beat <= 1'b0;\n            kind <= c_dmem_req"),
 ("                kind       <= T_FETCH;\n                store_beat <= 1'b0;\n                load_beat  <= 1'b0;\n            end else if (kind == T_FETCH) begin",
  "                kind       <= T_FETCH;\n                store_beat <= 1'b0;\n                load_beat  <= 1'b0;\n                fetch_beat <= 1'b0;\n"
  "            end else if (kind == T_FETCH && !fetch_beat) begin\n"
  "                fetch_beat <= 1'b1;   // ARM (A): the instruction loop is next\n"
  "            end else if (kind == T_FETCH) begin"),
 ("                kind       <= c_dmem_we ? T_STORE : T_LOAD;\n                store_beat <= 1'b0;\n                load_beat  <= 1'b0;",
  "                kind       <= c_dmem_we ? T_STORE : T_LOAD;\n                store_beat <= 1'b0;\n                load_beat  <= 1'b0;\n                fetch_beat <= 1'b0;"),
 ("    assign retire = loop_end && ( (kind == T_FETCH) ? ~c_dmem_req",
  "    assign retire = loop_end && ( (kind == T_FETCH) ? (fetch_beat && ~c_dmem_req)"),
 ("                    if (kind == T_FETCH) instr_r <= {pin_in, in_acc[23:0]};",
  "                    if (kind == T_FETCH && fetch_beat) instr_r <= {pin_in, in_acc[23:0]};"),
 ("    assign c_instr      = (kind == T_FETCH && phase == 2'd3)",
  "    assign c_instr      = (kind == T_FETCH && fetch_beat && phase == 2'd3)"),
]

def main(src, dst):
    s = open(src).read()
    for i, (old, new) in enumerate(EDITS):
        n = s.count(old)
        if n != 1:
            sys.stderr.write(f"armA_patch: REFUSED — edit {i} matches {n} sites, expected exactly 1.\n"
                             f"  The shipped busadapt8.v has moved under this patch. A variant built from a\n"
                             f"  patch that did not apply IS THE SHIPPED DESIGN, and it would score green.\n")
            return 2
        s = s.replace(old, new, 1)
    open(dst, "w").write(s)
    print(f"armA_patch: {len(EDITS)}/{len(EDITS)} edits applied; {s.count('fetch_beat')} fetch_beat sites")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
