#!/bin/bash
# run.sh — the row-5 trap-gate fidelity harness, both arms, driven + priced. Exit 0 only if every
# simulation check holds in both arms AND the synth delta is measurable.
set -u
cd "$(dirname "$0")"
RTL=../../SaltWorks/Silicon/RTL/core32.v
LIB="${LIB:-$HOME/.volare/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib}"
rc=0
echo "== the gate is the ONLY diff (module rename + the reg_we block):"
diff <(sed 's/core32_gated/core32/' core32_gated.v | tail -n +4) "$RTL" | grep -E '^[<>]' ; echo "diff lines: $(diff <(sed 's/core32_gated/core32/' core32_gated.v | tail -n +4) "$RTL" | grep -cE '^[<>]')"
echo "== ARM baseline (core32.v as fabricated): expect rd WRITTEN on trapping loads"
iverilog -g2012 -DDUT=core32 -DEXP_MISALIGNED=32\'hdeadbeef -DEXP_OOR32=32\'hcafef00d -DEXP_OOR64=32\'hcafef00d -o /tmp/lwtrap_base.vvp tb_lwtrap.v "$RTL" || rc=1
vvp -n /tmp/lwtrap_base.vvp | grep -E '^(ok|FAIL|PASS)'; vvp -n /tmp/lwtrap_base.vvp | grep -q '^PASS' || rc=1
echo "== ARM gated (core32_gated.v): expect rd HELD on trapping loads"
GATED_DEFS="-DDUT=core32_gated -DEXP_MISALIGNED=32'h11111111 -DEXP_OOR32=32'h22222222 -DEXP_OOR64=32'h33333333"
iverilog -g2012 $GATED_DEFS -o /tmp/lwtrap_gated.vvp tb_lwtrap.v core32_gated.v || rc=1
vvp -n /tmp/lwtrap_gated.vvp | grep -E '^(ok|FAIL|PASS)'; vvp -n /tmp/lwtrap_gated.vvp | grep -q '^PASS' || rc=1
echo "== MUTATION CONTROL: a gate that fires on EVERY load must FAIL the positive control"
sed 's/wire ld_trap = .*/wire ld_trap = is_load_w;/' core32_gated.v > /tmp/core32_mut.v
iverilog -g2012 $GATED_DEFS -o /tmp/lwtrap_mut.vvp tb_lwtrap.v /tmp/core32_mut.v && vvp -n /tmp/lwtrap_mut.vvp | grep -q 'FAIL rd after aligned in-range' && echo "ok   mutant REFUSED by the positive control" || { echo "FAIL mutation control did not fire"; rc=1; }
echo "== PRICE (yosys, sky130_fd_sc_hd tt, same recipe both arms):"
[ -f "$LIB" ] || { echo "liberty absent: $LIB — CANNOT PRICE"; exit 2; }
price(){ yosys -p "read_verilog $1; synth -top $2; dfflibmap -liberty $LIB; abc -liberty $LIB; opt_clean; stat -liberty $LIB" 2>&1 | grep -E '^ *[0-9]+ .* cells$|Chip area for module' | tr -s ' ' | tr '\n' ' '; echo; }
B=$(price "$RTL" core32); G=$(price core32_gated.v core32_gated)
echo "baseline: $B"; echo "gated:    $G"
python3 - "$B" "$G" <<'PY'
import re,sys
def p(s):
    c=int(re.search(r'(\d+) \S+ cells',s).group(1)); a=float(re.search(r'Chip area for module[^:]*: ([\d.]+)',s).group(1)); return c,a
(bc,ba),(gc,ga)=p(sys.argv[1]),p(sys.argv[2])
print(f"DELTA: {gc-bc:+d} cells, {ga-ba:+.4f} um2, {100*(ga-ba)/ba:+.3f}%  (08/31 scratchpad figure: +40 cells, +160.15 um2, +0.282%)")
PY
echo "== THE GATE'S OWN LOGIC, standalone (upper bound on the added cells; immune to restructuring noise):"
T=$(price trapgate_only.v trapgate_only); echo "trapgate_only: $T"
echo "harness rc=$rc"; exit $rc
