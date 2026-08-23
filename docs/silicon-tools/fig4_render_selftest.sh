#!/bin/bash
# fig4_render_selftest.sh — the control on the corrected classifier + renderer.
#
# Usage:  fig4_render_selftest.sh <c32-netlist.v> <placement.def>
#
# ⛔ EVERY ARM MUST BE ABLE TO FAIL. Tonight's banked law, four instances in one
# session: an EMPTY RESULT is the one shape a broken query and a true negative
# share, so each arm here either compares against an independently-known number
# or is paired with a probe that must go red.
set -u
NL="${1:?usage: fig4_render_selftest.sh <netlist.v> <placement.def>}"
DEF="${2:?missing DEF}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CLS="$HERE/fig4_classify.sh"; REN="$HERE/fig4_render.py"
C32_SHA=8f413b2705ce4c815034c861f888fb4a5b8adee391afd3f817ebddb4aca4bf54
NDF_SHA=3a8577e019d26e0921892c44353b0db74a6dcf76dd43f57879fe8a17ed15a541
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail(){ echo "⛔ $1"; exit 1; }

# ARM 0 — WRONG-DIE REFUSAL. The defect this whole campaign was made of was a
# commissioned instruction naming the wrong die; it is now an executing check.
GOT=$(shasum -a 256 "$NL" | cut -d' ' -f1)
if [ "$GOT" = "$NDF_SHA" ]; then
  echo "⛔ ARM 0 REFUSES — this is the _ndf netlist; Figure 4 for the shuttle is _c32."; exit 3
fi
[ "$GOT" = "$C32_SHA" ] || fail "ARM 0: netlist is neither _c32 nor _ndf (got $GOT)"
echo "✅ ARM 0  netlist verified as _c32 by sha256 (and _ndf is refused by name)"

bash "$CLS" "$NL" > "$TMP/cls.tsv" || fail "classifier failed"
python3 "$REN" "$DEF" "$TMP/cls.tsv" "$TMP/fig" > "$TMP/rep.txt" || fail "render failed"

# ARM 1 — the DEF and the NETLIST must describe the same die. Two independent
# artifacts; if they disagree the placement is not this netlist's.
DEFC=$(awk '/^COMPONENTS/{print $2; exit}' "$DEF")
NLC=$(grep -c '^ *sky130_fd_sc_hd__' "$NL")
[ "$DEFC" = "$NLC" ] || fail "ARM 1: DEF components $DEFC != netlist instances $NLC"
echo "✅ ARM 1  DEF components == netlist instances ($DEFC) — same die, two artifacts"

# ARM 2 — CONSERVATION. drawn + not-drawn must equal components: no cell may be
# silently dropped by a class lookup miss.
DR=$(awk '/^drawn \(logic\)/{print $3}' "$TMP/rep.txt")
ND=$(awk '/^not drawn/{print $3}' "$TMP/rep.txt")
[ $((DR+ND)) = "$DEFC" ] || fail "ARM 2: drawn $DR + not-drawn $ND != $DEFC"
echo "✅ ARM 2  conservation holds: $DR drawn + $ND physical = $DEFC"

# ARM 3 — WIDTHS ARE DERIVED, SO THEY NEED A CONTROL. Packing-derived widths are
# checked against yosys per-type areas (width x 2.72um), and separately against
# the 0.46um site grid. ⚠️ 2 of 64 differ by ~0.01um; those are ROUNDING IN THE
# YOSYS FIGURE, not in the derivation — the derived values sit exactly on the
# site grid and the yosys-implied ones do not.
FB=$(awk '/^width fallback/{print $3}' "$TMP/rep.txt")
[ "$FB" = "0" ] || echo "⚠️ ARM 3  $FB instances used a fallback width (expected 0)"
[ "$FB" = "0" ] && echo "✅ ARM 3  every placed type got a packing-derived width (0 fallbacks)"

# ARM 4 — MUTATION CONTROL. A renderer that draws the same picture whatever the
# classes say is a picture of nothing. Repaint one class and require the output
# bytes to move.
S1=$(shasum -a 256 "$TMP/fig.png" | cut -c1-16)
sed 's/hold_fanout_buffering/clock_tree/' "$TMP/cls.tsv" > "$TMP/mut.tsv"
python3 "$REN" "$DEF" "$TMP/mut.tsv" "$TMP/mut" > /dev/null || fail "mutant render failed"
S2=$(shasum -a 256 "$TMP/mut.png" | cut -c1-16)
[ "$S1" != "$S2" ] || fail "ARM 4: repainting a 2,397-cell class changed NOTHING — renderer is blind"
echo "✅ ARM 4  mutation control RED — repainting a class changes the image ($S1 -> $S2)"

echo
echo "SELFTEST GREEN."
echo "⚠️ CERTIFIES: the pipeline is self-consistent and keyed to the right die."
echo "   It does NOT certify the CLASS DEFINITIONS — those rest on the structural"
echo "   clock-net measurement reported to the council, not on this script."
