#!/bin/sh
# drvgate_selftest.sh — drive EVERY limb of drvgate.sh, both verdicts, and say what it skipped.
#
#   sh docs/silicon-tools/drvgate_selftest.sh      exit 0 = all arms as expected
#
# ⛔ TWO RULES THIS HARNESS OBEYS, BOTH PAID FOR BY THIS SEAT:
#   (1) NEVER PIPE THE TOOL. Writing the first draft of these arms I ran the gate through
#       `| head -5` and read rc=0 off a REFUSAL — `$?` after a pipe is head's status, and it
#       failed in the flattering direction. Output goes to a FILE; rc is read directly.
#   (2) EVERY LIMB FIRES ALONE SOMEWHERE. A gate whose limbs only ever fire together has not
#       been shown to discriminate — clock-leaf, count and fanout each get an arm where it is
#       the ONLY reason for the refusal.
#
# ⚖️ AMENDED 2026-09-07 with the gate (council 09/07 A2 / row GR, evidence as saltworks lead).
#   The count clause moved 1 -> 3, so TWO arms INVERT (`a4` fixture, `ndf-2b` production) and
#   three are ADDED. ⛔ THE POINT OF THE ADDITIONS: moving a threshold without moving the arm
#   that tests it RETIRES the limb silently — the suite stays green while nothing checks the
#   count any more. `count ALONE (4 datapath)` re-establishes the limb at its new boundary,
#   `band ALONE (3 dp, one @13)` proves the band still refuses once the count is satisfied,
#   and `THE SHIPPED SHAPE` pins the arm to the part that was actually fabricated.
#   📌 DRIVEN RED FIRST: against the amended gate the OLD suite went 8/1 with `a4` the single
#   failure — one arm, exactly the limb that moved, which is what says the arm was live.
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
GATE="$HERE/drvgate.sh"
T="${TMPDIR:-/tmp}/drvgate-selftest.$$"
mkdir -p "$T" || exit 2
trap 'rm -rf "$T"' EXIT INT TERM
PASS=0; FAIL=0

# A corner report is synthesised from ROWS so a fixture cannot drift from the format:
# the summary count is written from the SAME list the rows come from.
mkfix() {  # mkfix <dir> <row>...
  d="$1/55-openroad-stapostpnr/max_ss_100C_1v60"; shift
  mkdir -p "$d"
  n=0
  { echo "max fanout"; echo; echo "Pin                                   Limit Fanout  Slack"
    echo "----------------------------------------------------------"
    for r in "$@"; do [ -n "$r" ] && { echo "$r"; n=$((n+1)); }; done
    echo; echo "max capacitance"; echo
    echo "max fanout violation count $n"
  } > "$d/checks.rpt"
}

arm() {  # arm <name> <expected-rc> <dir>
  name="$1"; want="$2"; dir="$3"
  sh "$GATE" "$dir" > "$T/out" 2>&1
  got=$?
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); printf '  ✅ %-34s rc=%s\n' "$name" "$got"
  else FAIL=$((FAIL+1)); printf '  ⛔ %-34s rc=%s WANTED %s\n' "$name" "$got" "$want"; sed 's/^/       /' "$T/out"; fi
}

echo "FIXTURE ARMS (portable — no archive volume needed)"
mkfix "$T/a1" ""                                                          ; arm "clean: no violators"          0 "$T/a1"
mkfix "$T/a2" "wire695/X                                10     11        (VIOLATED)"; arm "the WAIVED shape: 1 datapath @11" 0 "$T/a2"
mkfix "$T/a3" "clkbuf_leaf_2_clk/X                      10     15     -5 (VIOLATED)"; arm "clock-leaf ALONE"     1 "$T/a3"
mkfix "$T/a4" "wire695/X                                10     11        (VIOLATED)" \
              "_05547_/X                                10     12        (VIOLATED)"; arm "2 datapath: INSIDE amended band" 0 "$T/a4"
# ⚖️ THE SHIPPED CHIP'S OWN DRV SIGNATURE, kept as a permanent arm. These are the three nets
#   the tape-out actually carries (01e19f7, GDS run 34058427540, read from its nine corner
#   reports): zero clock-leaf, three datapath at 11, 12, 12. If this arm ever refuses, the
#   gate has drifted away from the part that was fabricated.
mkfix "$T/a4b" "fanout937/X                              10     11        (VIOLATED)" \
               "fanout939/X                              10     12        (VIOLATED)" \
               "wire754/X                                10     12        (VIOLATED)"; arm "THE SHIPPED SHAPE: 3 dp @11,12,12" 0 "$T/a4b"
# The count limb must still fire ALONE somewhere, or the amendment has retired the arm rather
# than moved it (harness rule 2). Its boundary is now FOUR.
mkfix "$T/a4c" "fanout937/X                              10     11        (VIOLATED)" \
               "fanout939/X                              10     12        (VIOLATED)" \
               "wire754/X                                10     12        (VIOLATED)" \
               "_05547_/X                                10     11        (VIOLATED)"; arm "count ALONE (4 datapath)" 1 "$T/a4c"
# And the BAND limb must fire alone with the count SATISFIED — three is legal, 13 is not.
mkfix "$T/a4d" "fanout937/X                              10     11        (VIOLATED)" \
               "fanout939/X                              10     12        (VIOLATED)" \
               "wire754/X                                10     13        (VIOLATED)"; arm "band ALONE (3 dp, one @13)" 1 "$T/a4d"
mkfix "$T/a5" "_09736_/X                                10     14        (VIOLATED)"; arm "fanout ALONE (1 @14)"  1 "$T/a5"
# NEGATIVE CONTROLS ON THE INSTRUMENT ITSELF
mkfix "$T/a6" "wire695/X                                10     11        (VIOLATED)"
  sed 's/max fanout violation count 1/max fanout violation count 3/' \
      "$T/a6/55-openroad-stapostpnr/max_ss_100C_1v60/checks.rpt" > "$T/x" \
      && mv "$T/x" "$T/a6/55-openroad-stapostpnr/max_ss_100C_1v60/checks.rpt"
  arm "parse != report's own count"      2 "$T/a6"
mkfix "$T/a7" "wire695/X                                10     11        (VIOLATED)"
  grep -v 'max fanout violation count' "$T/a7/55-openroad-stapostpnr/max_ss_100C_1v60/checks.rpt" > "$T/x" \
      && mv "$T/x" "$T/a7/55-openroad-stapostpnr/max_ss_100C_1v60/checks.rpt"
  arm "no summary line (cannot measure)" 2 "$T/a7"
mkdir -p "$T/a8"                                                          ; arm "empty dir: BLANK IS NOT A PASS" 2 "$T/a8"
mkdir -p "$T/a9/55-openroad-stapostpnr"                                   ; arm "step present, 0 corners"        2 "$T/a9"

echo
# The archived DRV runs live in the PRIVATE archive; its path is never written in a public tree
# (08/25 firewall-at-paths ruling). Export SALTWORKS_ARCHIVE_ROOT to the archive's `archives` dir.
ARCH="${SALTWORKS_ARCHIVE_ROOT:-}/silicon-ndf-drv-0827/ndf"
if [ -z "${SALTWORKS_ARCHIVE_ROOT:-}" ]; then
  echo "PRODUCTION ARMS SKIPPED: SALTWORKS_ARCHIVE_ROOT is unset (the archive path is private; export it to run them)"
elif [ -d "$ARCH" ]; then
  echo "PRODUCTION ARMS (the four archived DRV runs, 9 STA corners each)"
  arm "ndf-base  111 clk + 6 dp, worst 14" 1 "$ARCH/ndf-base"
  arm "ndf-1d    111 clk + 0 dp"           1 "$ARCH/ndf-1d"
  arm "ndf-2a    0 clk + 1 dp @11 (WAIVED)" 0 "$ARCH/ndf-2a"
  arm "ndf-2b    0 clk + 2 dp (now WAIVED)" 0 "$ARCH/ndf-2b"
else
  echo "⚠️ PRODUCTION ARMS SKIPPED — archive not mounted at $ARCH."
  echo "   The fixtures prove the MECHANISM; the archive arms prove it on the REAL reports."
  echo "   A skip is reported, never silent: mount the volume and re-run before the freeze."
fi

echo
echo "drvgate_selftest: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 1
