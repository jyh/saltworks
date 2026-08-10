#!/bin/sh
# equiv_spec.sh — LINK (2): does the EMITTED netlist compute the SPEC, exhaustively?
#
#   sh docs/ledger-tools/equiv_spec.sh <emitted.v> [top]
#   sh docs/ledger-tools/equiv_spec.sh --selftest <emitted.v> [top]
#
# EVIDENCE seat. Built 2026-08-09 19:4x, closing the link this seat had just
# named as its own weak one.
#
# THE CHAIN (compiler's, 19:30), and where this file sits:
#   (1) the DESIGN computes acc - v        exhaustive kernel proof     compiler
#   (2) the EMITTED artifact IS the design  <- THIS FILE. Was SAMPLED.
#   (3) the emitted SHAPE matches           criterion (d) + controls    evidence
#   (4) SYNTHESISED == EMITTED              exhaustive SAT miter        silicon
#
# ⛔ WHY IT EXISTS: at 19:34 this seat published f5_arith_check as the control for
# link (2) -- a 1,152-point SWEEP. That left the chain with two EXHAUSTIVE links
# (compiler's kernel proof, silicon's miter) and ONE SAMPLED link, and the sampled
# one was the instrument I had built. I named that publicly as the weak link. This
# removes it: same technique silicon used for (4), pointed at (2).
#
# ⚖️ SCOPE. The first version of this comment claimed a remainder TWICE its real
# size, and compiler halved it by measurement within a minute of the landing:
#   ⭐ outs[0..31] ARE THE SAME NETS as outs[64..95] -- the cell's readable outputs
#     and its accumulator next-state are one object emitted twice. Re-verified here
#     independently: 32/32 identical assigns, o0 = o64 = n133. So the acc arm is
#     LITERALLY a proof about the readable outputs, not a separate obligation.
#   * outs[32..63], the weight-shift half, then got its own arm from compiler's
#     landed kernel spec: wsh'[0] = load AND x, wsh'[k+1] = w[k].
# ⇒ ALL 96 OUTPUTS of the combinational core are now proved over ALL inputs.
#
# ⛔ WHAT IS STILL NOT PROVED, so the shrinkage does not read as closure: this is
# the COMBINATIONAL core. A CLOCKED cell does not exist (emitSeq, V7+V9), so
# "every output of the cell is proved" is a sentence about a machine nobody has
# emitted. The state elements, the sequencer and the pin wrapper remain hand RTL
# and stay EXCLUDED BY NAME from any fabbed-is-verified sentence.
#
# ⛔ SILICON'S TWO TRAPS, inherited deliberately rather than rediscovered:
#   * NEVER `yosys -q`: it produced an empty log and exit 0, which is
#     INDISTINGUISHABLE FROM A PROOF. This tool PRINTS the verdict line.
#   * `read_liberty -lib` imports cells as blackboxes with no function, and SAT
#     then refuses. Use -ignore_miss_func WITHOUT -lib.
#
# ⛔ AND MY OWN, which is why --selftest is not optional in spirit: A MITER THAT
# PROVES EVERYTHING IS A MITER THAT PROVES NOTHING. A misconfigured comparison --
# empty designs, a mis-wired tap, a spec that ignores its inputs -- prints exactly
# the same SUCCESS line. The selftest drops the `+ sign` carry from the spec (the
# precise off-by-one this evening is about) and REQUIRES `model found: FAIL!`.
# Measured when built: real spec SUCCESS at 4,120 vars / 10,720 clauses; carry
# dropped -> FAIL. Run the selftest before believing a green.
#
# EXIT 0 = equivalent (proof line shown) · 1 = NOT equivalent · 2 = could not run
set -u

PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
LIB="${LIB:-$HOME/.volare/volare/sky130/versions/$PDK_VER/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib}"

SELFTEST=0
if [ "${1:-}" = "--selftest" ]; then SELFTEST=1; shift; fi
EMITTED="${1:?usage: equiv_spec.sh [--selftest] <emitted.v> [top]}"
TOP="${2:-mac_cell_signed}"

[ -f "$LIB" ]     || { echo "equiv_spec: liberty not found: $LIB" >&2; exit 2; }
[ -f "$EMITTED" ] || { echo "equiv_spec: no such file: $EMITTED" >&2; exit 2; }
command -v yosys >/dev/null 2>&1 || { echo "equiv_spec: yosys absent" >&2; exit 2; }

TMP="${TMPDIR:-/tmp}/equiv_spec.$$"
mkdir -p "$TMP" || exit 2
trap 'rm -rf "$TMP"' EXIT

NIN=67
ACC_LO=64
WSH_LO=32
ARM="${ARM:-both}"        # acc | wsh | both

# ---- DUT: wrap the emitted netlist, tapping ONE 32-bit output window ---------
write_dut() {   # $1 = low output index of the window
  LO=$1
{
  printf 'module dut (input wire [%d:0] i, output wire [31:0] accn);\n' $((NIN - 1))
  printf '  wire [95:0] o;\n  %s u (\n' "$TOP"
  k=0; while [ $k -lt $NIN ]; do printf '    .i%d(i[%d]),\n' $k $k; k=$((k + 1)); done
  k=0; while [ $k -lt 96 ]; do
    if [ $k -eq 95 ]; then printf '    .o%d(o[%d])\n' $k $k
    else printf '    .o%d(o[%d]),\n' $k $k; fi
    k=$((k + 1))
  done
  printf '  );\n  assign accn = o[%d:%d];\nendmodule\n' $((LO + 31)) $LO
} > "$TMP/dut.v"
}

# ---- REF: the two's-complement identity, behaviourally ------------------------
# port map from MacCell.lean: ccX 0 · ccLoad 1 · scSign/ccCin 2 ·
#                             ccWsh k = 3+k · ccAcc k = 35+k
write_ref_wsh() {   # $1 = 1 to BREAK it (drop the load gate) for the selftest
  # compiler's spec, 19:48, from the kernel:
  #   wsh'[0]   = load AND x        (wshift_next_bit_zero — the vacated LSB)
  #   wsh'[k+1] = w[k], k < 31      (wshift_next_bit_succ — pure rewiring)
  lsb='x & load'
  [ "$1" = "1" ] && lsb="1'b0"
  cat > "$TMP/ref.v" <<WEOF
module dut (input wire [$((NIN - 1)):0] i, output wire [31:0] accn);
  wire        x    = i[0];
  wire        load = i[1];
  wire [31:0] w    = i[34:3];
  assign accn = {w[30:0], $lsb};
endmodule
WEOF
}

write_ref() {   # $1 = 1 to BREAK it (drop the carry) for the selftest
  carry='+ {31'"'"'b0, sign}'
  [ "$1" = "1" ] && carry=''
  cat > "$TMP/ref.v" <<REOF
module dut (input wire [$((NIN - 1)):0] i, output wire [31:0] accn);
  wire        x    = i[0];
  wire        sign = i[2];
  wire [31:0] w    = i[34:3];
  wire [31:0] acc  = i[66:35];
  wire [31:0] raw    = x ? w : 32'b0;
  wire [31:0] addend = raw ^ {32{sign}};
  assign accn = acc + addend $carry;
endmodule
REOF
}

run_miter() {   # $1 = label
  cat > "$TMP/m.ys" <<YEOF
read_liberty -ignore_miss_func $LIB
read_verilog $EMITTED $TMP/dut.v
hierarchy -top dut
flatten
rename dut gate
design -stash gate
read_verilog $TMP/ref.v
hierarchy -top dut
flatten
rename dut gold
design -stash gold
design -copy-from gate -as gate gate
design -copy-from gold -as gold gold
miter -equiv -flatten -make_outputs gold gate miter
hierarchy -top miter
sat -verify -prove trigger 0 miter
YEOF
  yosys -s "$TMP/m.ys" > "$TMP/$1.log" 2>&1
  rc=$?
  # THE VERDICT IS THE PRINTED LINE, NEVER THE EXIT CODE ALONE.
  line=$(grep -E 'model found' "$TMP/$1.log" | tail -1)
  vars=$(grep -E 'Solving problem with' "$TMP/$1.log" | tail -1)
  printf '  %-10s %s\n' "$1" "${line:-NO VERDICT LINE — the run did not reach SAT}"
  [ -n "$vars" ] && printf '  %-10s %s\n' '' "$vars"
  return $rc
}

echo "======================================================================"
echo "LINK (2) — the EMITTED netlist against the SPEC, exhaustively by SAT"
echo "======================================================================"
echo "ARTIFACT   $EMITTED  (top $TOP)"
echo "ARMS       acc  outs[64..95] = acc + (andWord x w XOR sign) + sign"
echo "           wsh  outs[32..63] = {w[30:0], x AND load}"
echo "⭐ outs[0..31] NEED NO ARM: they are the SAME NETS as outs[64..95]"
echo "   (compiler 19:48, re-verified here: 32/32 identical assigns, o0=o64=n133)."
echo "   So the acc arm is literally a proof about the readable outputs too."
echo "SCOPE      the COMBINATIONAL core. A clocked cell does not exist (emitSeq,"
echo "           V7+V9), so this is not a statement about a machine on a die."

do_arm() {   # $1 = arm name, $2 = low index, $3 = ref writer
  echo "--- ARM $1 ---"
  write_dut "$2"
  if [ "$SELFTEST" = "1" ]; then
    "$3" 1
    if run_miter "neg_$1"; then
      echo "⛔ SELFTEST FAILED ($1) — the BROKEN spec was proved equivalent."
      echo "   The miter does not discriminate; every green from it is worthless."
      exit 2
    fi
    grep -q 'model found: FAIL' "$TMP/neg_$1.log" || {
      echo "⛔ SELFTEST INCONCLUSIVE ($1) — no FAIL line; SAT was not reached."; exit 2; }
    echo "  ✅ discriminates"
  fi
  "$3" 0
  if run_miter "eq_$1"; then
    grep -q 'no model found: SUCCESS' "$TMP/eq_$1.log" || {
      echo "⛔ exit 0 but NO SUCCESS LINE — refusing to call that a proof."; exit 2; }
    echo "  ✅ $1 EQUIVALENT over ALL inputs"
    return 0
  fi
  echo "  ⛔ $1 NOT EQUIVALENT — a counterexample exists. This is a finding."
  return 1
}

rc=0
case "$ARM" in
  acc)  do_arm acc "$ACC_LO" write_ref     || rc=1 ;;
  wsh)  do_arm wsh "$WSH_LO" write_ref_wsh || rc=1 ;;
  both) do_arm acc "$ACC_LO" write_ref     || rc=1
        do_arm wsh "$WSH_LO" write_ref_wsh || rc=1 ;;
  *) echo "equiv_spec: unknown ARM=$ARM (acc|wsh|both)" >&2; exit 2 ;;
esac
[ "$rc" = "0" ] && echo "✅ ALL 96 OUTPUTS of the combinational core proved over ALL inputs."
exit $rc
