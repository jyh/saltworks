#!/bin/sh
# run_lwsw_bypass_control.sh — DRIVE THE INSTRUCTION BYPASS BOTH WAYS.
#
# ⛔ WHY THIS IS COMMITTED AND NOT A SCRATCH INVOCATION: a green bench is only
#    evidence if the same bench can go RED on the quantity in question. That pair
#    is the receipt, and a receipt whose PRODUCER lives in a terminal dies with
#    the terminal. Producer is code; the inputs are named by sha in the commit.
#
# ARM A (as shipped)   c_instr = (kind==T_FETCH && phase==3) ? {pin_in,in_acc} : instr_r
# ARM B (mutation)     c_instr = instr_r          <- the bypass DEFEATED
#
# ⭐ ARM B MUST REPRODUCE THE 08/18 DEFECT SIGNATURE RECORDED IN busadapt8.v:
#      dmem_wdata=0x00000000 · instr_r=0000a183 (the lw, rs2=x0) · regs[1]=0x40
#    If ARM B goes GREEN, this control is broken and ARM A's green means nothing.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"
T=${TMPDIR:-/tmp}/lwsw_ctl.$$; mkdir -p "$T/mut"; trap 'rm -rf "$T"' EXIT
cp "$RTL/plane32bus.v" "$RTL/core32.v" "$T/mut/"
sed -e "s|assign c_instr      = (kind == T_FETCH \&\& phase == 2'd3)|assign c_instr      = instr_r; // MUTATED\nwire [31:0] _unused_bypass = (kind == T_FETCH \&\& phase == 2'd3)|" \
    "$RTL/busadapt8.v" > "$T/mut/busadapt8.v"
iverilog -g2005 -o "$T/a.vvp" "$HERE/tb_plane32bus_lwsw.v" "$RTL/plane32bus.v" "$RTL/core32.v" "$RTL/busadapt8.v"
iverilog -g2005 -o "$T/b.vvp" "$HERE/tb_plane32bus_lwsw.v" "$T/mut"/*.v
vvp "$T/a.vvp" > "$T/a.out" 2>&1 || true
vvp "$T/b.vvp" > "$T/b.out" 2>&1 || true
A=$(grep -c 'L-FAIL' "$T/a.out" || true); B=$(grep -c 'L-FAIL' "$T/b.out" || true)
echo "ARM A (shipped)  L-FAIL count = $A"; grep -E 'ALL PASS|RED:' "$T/a.out" || true
echo "ARM B (mutated)  L-FAIL count = $B"; grep -E 'ALL PASS|RED:' "$T/b.out" || true
grep -o 'st_data=[0-9a-fx]*' "$T/b.out" | head -1 | sed 's/^/ARM B store data: /'
grep -o 'instr=[0-9a-fx]*'   "$T/b.out" | head -1 | sed 's/^/ARM B instr:      /'
if [ "$A" -eq 0 ] && [ "$B" -gt 0 ]; then
  echo "BYPASS_CONTROL=PASS (shipped green, mutation RED — the bench discriminates)"; exit 0
else
  echo "BYPASS_CONTROL=FAIL (A=$A B=$B — a green here would be meaningless)"; exit 1
fi
