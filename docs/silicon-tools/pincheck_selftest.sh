#!/bin/sh
# pincheck_selftest.sh — drive every arm of pincheck.sh: both verdicts and all three exit classes.
#
# ⛔ THE ONE HONEST COMPLICATION: the FLOW arm reads a LIVE tag, so the pass arm needs network.
#   Offline, pincheck correctly returns 2 (cannot measure) — which is the RIGHT behaviour and would
#   look like a broken selftest. So this harness DETECTS that case and reports it as SKIPPED WITH A
#   REASON rather than either failing or quietly passing. A skip is announced, never silent.
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
T="${TMPDIR:-/tmp}/pincheck-selftest.$$"; mkdir -p "$T" || exit 2
trap 'rm -rf "$T"' EXIT INT TERM
CONF="$HERE/pins.conf"
PDKJ="${PDKJ:-/Volumes/Content HD/Saltworks/archives/silicon-ndf-drv-0827/inputs/tt-submitted-reference/tt_submission/pdk.json}"
PASS=0; FAIL=0; SKIP=0

sed 's/^FLOW_SHA=.*/FLOW_SHA=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef/' "$CONF" > "$T/tagmoved.conf"
sed 's/^PDK_SHA=.*/PDK_SHA=cafebabecafebabecafebabecafebabecafebabe/'   "$CONF" > "$T/pdk.conf"
sed 's|^FLOW_REPO=.*|FLOW_REPO=TinyTapeout/no-such-repo-silicon-probe|' "$CONF" > "$T/norepo.conf"

run() { PINS_CONF="$1" sh "$HERE/pincheck.sh" "$2" > "$T/out" 2>&1; echo $?; }
arm() { name="$1"; want="$2"; got="$3"
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); printf '  ✅ %-28s rc=%s\n' "$name" "$got"
  else FAIL=$((FAIL+1)); printf '  ⛔ %-28s rc=%s WANTED %s\n' "$name" "$got" "$want"; sed 's/^/       /' "$T/out"; fi; }

echo "pincheck arms:"
BASE=$(run "$CONF" "$PDKJ")
if [ "$BASE" = 2 ] && ! grep -q '✅ FLOW tag unmoved' "$T/out"; then
  SKIP=1
  echo "  ⚠️ SKIPPED the live-tag arms — the tag API did not answer (offline? auth?)."
  echo "     pincheck returning 2 here is CORRECT. Re-run with network before the freeze."
else
  arm "both pins as recorded" 0 "$BASE"
  arm "FLOW tag moved"        1 "$(run "$T/tagmoved.conf" "$PDKJ")"
  arm "PDK differs"           1 "$(run "$T/pdk.conf" "$PDKJ")"
fi
arm "tag API unanswerable"    2 "$(run "$T/norepo.conf" "$PDKJ")"
arm "pdk.json unreadable"     2 "$(run "$CONF" /nope/pdk.json)"
arm "pins.conf missing"       2 "$(run /nope/pins.conf "$PDKJ")"

echo "pincheck_selftest: $PASS passed, $FAIL failed$([ "$SKIP" = 1 ] && echo ', live-tag arms SKIPPED')"
[ "$FAIL" = 0 ] || exit 1
