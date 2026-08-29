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
              "_05547_/X                                10     12        (VIOLATED)"; arm "count ALONE (2 datapath)" 1 "$T/a4"
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
  arm "ndf-2b    0 clk + 2 dp"             1 "$ARCH/ndf-2b"
else
  echo "⚠️ PRODUCTION ARMS SKIPPED — archive not mounted at $ARCH."
  echo "   The fixtures prove the MECHANISM; the archive arms prove it on the REAL reports."
  echo "   A skip is reported, never silent: mount the volume and re-run before the freeze."
fi

echo
echo "drvgate_selftest: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 1
