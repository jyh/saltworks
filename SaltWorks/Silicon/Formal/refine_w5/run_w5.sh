#!/bin/sh
# run_w5.sh — desk AAU W5: the fabricated RTL (the whole tile, 01e19f7) equals the SIGNED-OFF NETLIST
# (gds run 34058427540, tt_submission, sha256 38a4686f…). Both sides' flops are cut open; every
# netlist flop bit is placed on the gold flop bit of its name (w5_wrap.py, which refuses one it cannot
# place); ABC decides the miter over all state, inputs and the gold's `x` bits. Cell functions come
# from the PDK's own liberty (sky130A 8afc8346, the run's pdk.json version). Power pins carry no logic
# and are stripped before reading. CONTROL: one netlist cell is mutated, and the miter must go SAT.
# env: OUT (scratch, required) · TTDIR (tape-out clone) · GLNL (netlist path; fetched if absent)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
TTDIR=${TTDIR:-$HOME/projects/claude/seats/silicon/tt-neural-dataflow-fabric}
OUT=${OUT:?set OUT to a scratch directory}; mkdir -p "$OUT/rtl"
REF=01e19f7; RUN=34058427540
GL_SHA256=38a4686f264fe8143f2a1e6939bd2058c14c28abd5d77a05f9f85fd3aede209c
PDKV=8afc8346a57fe1ab7934ba5a6056ea8b43078e71
SRCS="tt_um_saltworks_ndf_c32.v banyan_fabric.v bitserial_switch.v busadapt8.v core32.v mac_cell_signed_shell.v plane32bus.v ser_organ.v"
for f in $SRCS; do git -C "$TTDIR" show "$REF:src/$f" > "$OUT/rtl/$f"; done
GLNL=${GLNL:-$OUT/gl/tt_submission/tt_um_saltworks_ndf_c32.v}
[ -f "$GLNL" ] || gh run download "$RUN" -R jyh/tt-neural-dataflow-fabric -n tt_submission -D "$OUT/gl"
[ "$(shasum -a 256 "$GLNL" | cut -d' ' -f1)" = "$GL_SHA256" ] || { echo "⛔ netlist sha256 mismatch"; exit 2; }
LIB=$(find "$HOME/.volare" -path "*$PDKV/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib" 2>/dev/null | head -1)
[ -n "$LIB" ] || { echo "⛔ sky130A $PDKV liberty not found"; exit 2; }
echo "gold: RTL $REF ($(echo $SRCS | wc -w | tr -d ' ') files) · gate: netlist sha256 ${GL_SHA256%${GL_SHA256#????????????????}}… · lib $(shasum -a 256 "$LIB" | cut -c1-16)…"
# power pins: remove the two top-level ports and every .VPWR/.VGND/.VPB/.VNB connection
python3 - "$GLNL" "$OUT/gate.v" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
n0 = len(re.findall(r'\.(VPWR|VGND|VPB|VNB)\s*\(', t))
t = re.sub(r'\.(VPWR|VGND|VPB|VNB)\s*\([^)]*\)\s*,?', '', t)
t = re.sub(r',\s*\)\s*;', ');', t)
t = re.sub(r'\(\s*,', '(', t)
t = re.sub(r'\b(VPWR|VGND),\s*', '', t, count=2)
t = re.sub(r'^\s*inout\s+(VPWR|VGND)\s*;\s*$', '', t, flags=re.M)
open(sys.argv[2], 'w').write(t)
print(f"stripped {n0} power-pin connections", file=sys.stderr)
PY
R=$OUT/rtl
RD="read_liberty -ignore_miss_func $LIB; read_verilog -overwrite $HERE/dfxtp_model.v; read_verilog $(for f in $SRCS; do printf '%s ' "$R/$f"; done); hierarchy -top tt_um_saltworks_ndf_c32; proc; flatten"
# cell-pin wires of the structurally written blocks are aliases of real nets; hide them BY NAME
# (the last name component is an uppercase pin: A, B, X, Y, Q, D, CLK …) so a flop surfaces once
yosys -p "$RD; select -list w:*" > "$OUT/gold_wires.txt" 2>&1 || { echo "⛔ gold read failed"; exit 2; }
python3 - "$OUT/gold_wires.txt" "$OUT/hide.ys" <<'PY'
import re, sys
names = [l.strip().split('/', 1)[1] for l in open(sys.argv[1]) if l.startswith('tt_um_saltworks_ndf_c32/')]
hide = [n for n in names if re.search(r'\.[A-Z][A-Z0-9_]*$', n) and not re.search(r'[\[\]*?]', n)]
open(sys.argv[2], 'w').write(''.join(f'rename -hide w:{n}\n' for n in hide))
print(f"gold: {len(names)} wires, {len(hide)} cell-pin names hidden", file=sys.stderr)
PY
yosys -q -p "$RD; script $OUT/hide.ys; memory; opt_clean; async2sync; dffunmap; write_json $OUT/gold_pre.json; expose -evert-dff; opt_clean; rename tt_um_saltworks_ndf_c32 gold_exp; write_verilog -noattr $OUT/gold_exp.v" || { echo "⛔ gold cut-open failed"; exit 2; }
python3 "$HERE/cut_netlist.py" "$OUT/gate.v" "$OUT/gate_cut.v" "$OUT/ff_map.tsv" || exit 2
cut_gate() {  # $1 cut netlist, $2 output
  yosys -q -p "read_liberty -ignore_miss_func $LIB; read_verilog $1; hierarchy -top tt_um_saltworks_ndf_c32; flatten; opt_clean; rename tt_um_saltworks_ndf_c32 gate_exp; write_verilog -noattr $2"
}
cut_gate "$OUT/gate_cut.v" "$OUT/gate_exp.v" || { echo "⛔ gate read failed"; exit 2; }
python3 "$HERE/w5_wrap.py" "$OUT/gold_exp.v" "$OUT/ff_map.tsv" "$OUT/gold_pre.json" > "$OUT/w5bad.v" 2> "$OUT/wrap.log" || { cat "$OUT/wrap.log"; exit 2; }
echo "wrap: $(cat "$OUT/wrap.log")"
prove() {  # $1 gate_exp, $2 tag
  yosys -q -p "read_verilog $OUT/gold_exp.v; read_verilog $1; read_verilog $OUT/w5bad.v; hierarchy -top w5bad; proc; flatten; opt_clean; setundef -anyseq; techmap; opt -fast; aigmap; opt_clean; write_aiger -zinit $OUT/$2.aig" > "$OUT/$2.ys.log" 2>&1 || { echo "⛔ $2: AIG build failed"; tail -3 "$OUT/$2.ys.log"; exit 2; }
  yosys-abc -c "read $OUT/$2.aig; strash; print_stats; iprove" > "$OUT/$2.abc" 2>&1
  grep -E 'SATISFIABLE|UNSATISFIABLE|i/o' "$OUT/$2.abc" | sed 's/\x1b\[[0-9;]*m//g; s/^.*: i\/o/i\/o/'
}
v=$(prove "$OUT/gate_exp.v" w5); echo "$v" | sed 's/^/w5: /'
echo "$v" | grep -q '^UNSATISFIABLE' || { echo "⛔ RTL ≠ NETLIST (or not proved)"; exit 3; }
# THE FREED-BIT ACCOUNTING: every freed bit is a netlist flop's state, a used primary input bit, or one
# of the gold's two regs[0] read leaves (32 bits each; regs is [1:31], so that read is `x`, muxed away)
fr=$(grep -F 'Treating undriven bit' "$OUT/w5.ys.log" | grep -v -c -E 'w5bad\.\\?(s_ffq_[0-9]+|ui_in|uio_in|rst_n|ena) ' || true)
st=$(grep -F 'Treating undriven bit' "$OUT/w5.ys.log" | grep -c -E 'w5bad\.\\?s_ffq_[0-9]+ ' || true)
echo "freed bits: netlist-flop state $st · other than state/inputs $fr (expected 1469 · 64)"
[ "$st" = 1469 ] && [ "$fr" = 64 ] || { echo "⛔ freed-bit accounting does not close"; exit 6; }
# CONTROL: swap the first and2 that drives a core32 net for an or2 (same pins); the miter must go SAT
python3 - "$OUT/gate_cut.v" "$OUT/gate_cut_mut.v" <<'PY'
import re, sys
t = open(sys.argv[1]).read()
m = re.search(r'sky130_fd_sc_hd__and2_(\d+)(\s+\S+\s*\([^;]*?\.X\(\s*\\core\.u_core\.[^)]*\))', t, re.S)
if not m: sys.exit("⛔ no and2 driving a core32 net to mutate")
t = t[:m.start()] + 'sky130_fd_sc_hd__or2_' + m.group(1) + m.group(2) + t[m.end():]
open(sys.argv[2], 'w').write(t)
print("mutant: " + ' '.join(m.group(2).split())[:120], file=sys.stderr)
PY
cut_gate "$OUT/gate_cut_mut.v" "$OUT/gate_exp_mut.v" || { echo "⛔ mutant read failed"; exit 2; }
mv "$OUT/gate_exp.v" "$OUT/gate_exp.keep.v"; cp "$OUT/gate_exp_mut.v" "$OUT/gate_exp.v"
m=$(prove "$OUT/gate_exp.v" w5mut); mv "$OUT/gate_exp.keep.v" "$OUT/gate_exp.v"
echo "$m" | sed 's/^/mutant: /'
echo "$m" | grep -q '^SATISFIABLE' || { echo "⛔ MUTANT NOT REFUSED — the W5 miter cannot see a core cell"; exit 5; }
echo "W5 PROVEN; mutant control REFUSED"
