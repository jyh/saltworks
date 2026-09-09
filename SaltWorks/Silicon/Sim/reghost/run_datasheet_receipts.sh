#!/bin/sh
# run_datasheet_receipts.sh — RECEIPTS FOR THE FOUR FIGURES THE SHIPPED DATASHEET ASSERTS
#
# silicon, 2026-09-08, on the council 09/08 ①b commission (FINISH-THEN-DARK).
# evidence, 09/06 bank §3: "receipts for 20/121, 0/121, 0/260 — figures in the SHIPPED
# datasheet whose ONLY PROVENANCE IS THE DOCUMENT ASSERTING THEM."
#
# THE CLAIM UNDER TEST, verbatim from docs/info.md at the FABRICATED sha 01e19f7:
#   "Measured on **this** design, sweeping one pulse per run across the steady-state
#    window: **20 of 121 arrival cycles re-issued a completed store before the repair,
#    0 of 121 after**. Over the whole run including bring-up the same comparison is
#    **36 of 260 before, 0 of 260 after**."
#
# ⛔⛔ WHY THIS IS A NEW FILE AND NOT A FLAG ON run_sof_reachability_sweep.sh.
# That script resolves its DUT as `$S/RTL/busadapt8.v` — SALTWORKS' RTL, which carries
# option (2) (the two-loop LOAD, landed 1916ea0c) that the FABRICATED DESIGN DOES NOT HAVE.
# The datasheet says "**this** design", and "this design" is the tape-out tree, not the
# lab tree. A sweep of the lab tree is a true number about the wrong object — the exact
# family that produced 16/121 in this seat's own record against the page's 20/121.
# ⇒ THE DUT IS NAMED BY REF IN THE TAPE-OUT REPO, AND THE REF IS PRINTED WITH ITS SHA.
#
# THE TWO OBJECTS, and neither is a checkout:
#   before  4226396:src/busadapt8.v   the pre-repair tape-out source (no fetch_owed)
#   after   01e19f7:src/busadapt8.v   THE FABRICATED DESIGN (fetch_owed x10)
# The surrounding RTL is held fixed and that is MEASURED here, not inherited: core32.v and
# plane32bus.v are byte-identical between the two shas and the lab tree, so busadapt8.v is
# the only variable.
#
# THE PREDICATE, stated because the figures differ by predicate and not by measurement:
#   "re-issued a completed store" == store_unaccounted != 0 at $finish.
# `lw_exec < baseline` ("instruction lost") is a DIFFERENT and STRICTLY NARROWER predicate
# and is counted separately. Reporting either as the other is how 16, 20, 36 and 72 all
# became "the number" in different documents.
#
# THE GATE — this script must be able to say NO:
#   (1) `before` MUST lack fetch_owed and `after` MUST carry it, else the arms are not
#       the arms they are named for: REFUSE.
#   (2) `before` MUST be NON-ZERO in at least one window. A repair verified only by an
#       all-green sweep is verified by a criterion never shown to fail.
#   (3) Each figure is compared to the datasheet's asserted value and reported
#       MATCH / MISMATCH. ⛔ A MISMATCH IS A FINDING, NOT A THING TO TUNE THE SWEEP UNTIL
#       IT AGREES. Nothing in here reads the datasheet to decide what to measure.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
S=$(cd "$HERE/../.." && pwd)                 # .../SaltWorks/Silicon
RTL="$S/RTL"
SRC="$S/Sim/wordonly/tb_plane32bus_lwsw.v"
TTDIR="${TTDIR:-$HOME/projects/claude/seats/silicon/tt-neural-dataflow-fabric}"
BEFORE_REF="${BEFORE_REF:-4226396}"
AFTER_REF="${AFTER_REF:-01e19f7}"

[ -f "$SRC" ] || { echo "⛔ tracked bench not found: $SRC"; exit 2; }
[ -d "$TTDIR/.git" ] || { echo "⛔ $TTDIR is not a git repository; cannot name a DUT by ref."; exit 2; }

T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT

# ---- materialise both DUTs from NAMED OBJECTS -------------------------------------
for pair in "before:$BEFORE_REF" "after:$AFTER_REF"; do
  lbl=${pair%%:*}; ref=${pair#*:}
  mkdir -p "$T/$lbl"
  ( cd "$TTDIR" && git show "$ref:src/busadapt8.v" ) > "$T/$lbl/busadapt8.v" 2>/dev/null || {
      echo "⛔ cannot materialise src/busadapt8.v at $ref — REFUSING rather than falling"
      echo "   back to a working tree, which is a checkout and therefore a variable."; exit 2; }
done

# GATE (1): the arms must be what their names claim.
if grep -q 'fetch_owed' "$T/before/busadapt8.v"; then
  echo "⛔ the 'before' DUT at $BEFORE_REF ALREADY CARRIES fetch_owed. It cannot demonstrate"
  echo "   the defect it exists to demonstrate. REFUSING."; exit 2; fi
if ! grep -q 'fetch_owed' "$T/after/busadapt8.v"; then
  echo "⛔ the 'after' DUT at $AFTER_REF does NOT carry fetch_owed — it is not the repaired"
  echo "   design. REFUSING."; exit 2; fi

# ---- the surrounding RTL is held fixed, and that is MEASURED here ------------------
echo "OBJECTS"
printf "  before .... %s:src/busadapt8.v  sha %s\n" "$BEFORE_REF" "$(cd "$TTDIR" && git rev-parse --short "$BEFORE_REF")"
printf "  after ..... %s:src/busadapt8.v  sha %s   <- THE FABRICATED DESIGN\n" "$AFTER_REF" "$(cd "$TTDIR" && git rev-parse --short "$AFTER_REF")"
printf "  bench ..... %s\n" "$SRC"
for f in core32.v plane32bus.v; do
  a=$(cd "$TTDIR" && git show "$BEFORE_REF:src/$f" | shasum -a 256 | cut -c1-16)
  b=$(cd "$TTDIR" && git show "$AFTER_REF:src/$f"  | shasum -a 256 | cut -c1-16)
  c=$(shasum -a 256 "$RTL/$f" | cut -c1-16)
  if [ "$a" = "$b" ] && [ "$b" = "$c" ]; then v="IDENTICAL across both shas and the lab tree"
  else v="⛔ DIFFERS ($a / $b / $c) — busadapt8.v is NOT the only variable"; fi
  printf "  %-13s %s\n" "$f" "$v"
done
echo

# ---- one instrumented bench, reused for every arm ---------------------------------
cp "$SRC" "$T/tb.v"
python3 - "$T/tb.v" <<'PY'
import io,sys
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
inj = r'''
  integer sofcyc = -1, cyccnt = 0, n_lw_exec = 0, n_sw_exec = 0;
  initial begin if (!$value$plusargs("sofcyc=%d", sofcyc)) sofcyc = -1; end
  always @(posedge clk) if (rst_n) begin
    cyccnt = cyccnt + 1;
    sof <= (sofcyc >= 0 && cyccnt == sofcyc) ? 1'b1 : 1'b0;
    if (retire_w) begin
      if (dut.u_bus.c_instr[6:0] == 7'b0000011) n_lw_exec = n_lw_exec + 1;
      if (dut.u_bus.c_instr[6:0] == 7'b0100011) n_sw_exec = n_sw_exec + 1;
    end
  end
'''
i = s.index('  initial begin')
s = s[:i] + inj + '\n' + s[i:]
extra = r'''    $display("SWEEP sofcyc=%0d unacc=%0d lw=%0d sw=%0d", sofcyc, store_unaccounted, n_lw_exec, n_sw_exec);
    $finish;'''
s = s.replace('    $finish;', extra, 1)
io.open(p,'w',encoding='utf-8').write(s)
PY

sweep() {   # sweep <label> <lo> <hi> -> prints "bad lost tot"
  lbl=$1; lo=$2; hi=$3
  base=$(vvp "$T/$lbl.vvp" | sed -n 's/.*SWEEP .*lw=\([0-9]*\) sw=\([0-9]*\)/\1 \2/p')
  bl=$(echo "$base" | cut -d' ' -f1)
  bad=0; lost=0; tot=0
  c=$lo
  while [ "$c" -le "$hi" ]; do
    out=$(vvp "$T/$lbl.vvp" +sofcyc=$c | grep '^SWEEP')
    u=$(echo "$out" | sed -n 's/.*unacc=\([0-9]*\).*/\1/p')
    l=$(echo "$out" | sed -n 's/.*lw=\([0-9]*\).*/\1/p')
    tot=$((tot+1))
    [ "$u" != 0 ] && bad=$((bad+1))
    [ "$l" -lt "$bl" ] && lost=$((lost+1))
    c=$((c+1))
  done
  echo "$bad $lost $tot"
}

for lbl in before after; do
  iverilog -g2005 -o "$T/$lbl.vvp" -s tb "$T/tb.v" \
      "$RTL/plane32bus.v" "$T/$lbl/busadapt8.v" "$RTL/core32.v"
done

echo "SWEEP — one sof pulse per run, predicate = store_unaccounted != 0 (\"re-issued a completed store\")"
printf "  %-8s %-22s %-28s %s\n" "ARM" "WINDOW" "RE-ISSUED (datasheet's)" "INSTRUCTION LOST (narrower)"
RES=""
for w in "steady:40:160" "full:1:260"; do
  wn=${w%%:*}; rest=${w#*:}; lo=${rest%%:*}; hi=${rest#*:}
  for lbl in before after; do
    set -- $(sweep "$lbl" "$lo" "$hi")
    bad=$1; lost=$2; tot=$3
    printf "  %-8s %-22s %-28s %s\n" "$lbl" "$wn ($lo..$hi, n=$tot)" "$bad of $tot" "$lost of $tot"
    RES="$RES $lbl:$wn:$bad:$tot"
  done
done
echo
echo "$RES" > "$T/res"

# ---- GATE (2): the criterion must be able to fail ---------------------------------
nz=0
for r in $RES; do
  case "$r" in before:*) v=$(echo "$r" | cut -d: -f3); [ "$v" -gt 0 ] && nz=1 ;; esac
done
if [ "$nz" -eq 0 ]; then
  echo "⛔ GATE (2) FAILED: the 'before' arm is ZERO in EVERY window. The repair's green is"
  echo "   then a fact about a test that cannot fail on this bench. REFUSING to report a receipt."
  exit 3; fi
echo "✅ GATE (2): the 'before' arm is non-zero — the criterion is shown to FAIL on this bench, today."

# ---- (3) compare against what the page asserts -------------------------------------
echo
# ⛔ THE ASSERTED VALUES ARE DERIVED FROM THE PAGE, NEVER TYPED HERE.
# A typed expectation is a wish that agrees with itself: if the page is later edited, a hardcoded
# 20 would keep reporting MATCH against a sentence that no longer says 20. The idiom law
# (ratified 08/13) is NO TYPED EXPECTATIONS — the expectation is derived from the artifact.
# The page is parsed for its own four numbers and REFUSES if it cannot find all four.
PAGE=$(cd "$TTDIR" && git show "$AFTER_REF:docs/info.md") || {
    echo "⛔ cannot read docs/info.md at $AFTER_REF — the claim under test is unavailable."; exit 2; }
A_BS=$(echo "$PAGE" | tr '\n' ' ' | sed -n 's/.*\*\*\([0-9][0-9]*\) of 121 arrival cycles re-issued.*/\1/p')
A_AS=$(echo "$PAGE" | tr '\n' ' ' | sed -n 's/.*re-issued a completed store before the repair, *\([0-9][0-9]*\) of 121 after.*/\1/p')
A_BF=$(echo "$PAGE" | tr '\n' ' ' | sed -n 's/.*same comparison is \*\*\([0-9][0-9]*\) of 260.*/\1/p')
A_AF=$(echo "$PAGE" | tr '\n' ' ' | sed -n 's/.*of 260 *before, *\([0-9][0-9]*\) of 260 after.*/\1/p')
for v in "$A_BS" "$A_AS" "$A_BF" "$A_AF"; do
  case "$v" in ''|*[!0-9]*)
    echo "⛔ could not DERIVE all four asserted figures from docs/info.md at $AFTER_REF."
    echo "   Parsed: before-steady='$A_BS' after-steady='$A_AS' before-full='$A_BF' after-full='$A_AF'"
    echo "   REFUSING rather than falling back to typed values — a receipt that types its own"
    echo "   expectation cannot notice that the page changed."; exit 2 ;;
  esac
done
echo "AGAINST THE SHIPPED PAGE (docs/info.md @ $AFTER_REF) — the page is READ HERE, never written"
echo "  asserted values DERIVED from the page: $A_BS of 121 / $A_AS of 121 / $A_BF of 260 / $A_AF of 260"
rc=0
check() {  # check <arm> <window> <asserted>
  got=""
  for r in $RES; do
    case "$r" in "$1:$2:"*) got=$(echo "$r" | cut -d: -f3); n=$(echo "$r" | cut -d: -f4) ;; esac
  done
  if [ "$got" = "$3" ]; then printf "  ✅ MATCH    %-7s %-7s asserted %s of %s, measured %s of %s\n" "$1" "$2" "$3" "$n" "$got" "$n"
  else printf "  ⛔ MISMATCH %-7s %-7s asserted %s, measured %s of %s\n" "$1" "$2" "$3" "$got" "$n"; rc=4; fi
}
check before steady "$A_BS"
check after  steady "$A_AS"
check before full   "$A_BF"
check after  full   "$A_AF"
echo
[ "$rc" = 0 ] && echo "VERDICT: all four figures REPRODUCE at the named objects." \
              || echo "⛔ VERDICT: at least one figure DOES NOT REPRODUCE. That is a FINDING about the page, reported not repaired."
exit $rc
