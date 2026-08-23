#!/bin/sh
# meas_reach_selftest.sh — drives meas_since.sh's HUB-REACHABILITY predicate BOTH WAYS.
#
# ⛔ IT EXTRACTS THE HELPER OUT OF THE SHIPPED FILE AT RUN TIME rather than keeping
# a copy. A selftest holding its own copy of the logic tests the copy, and the copy
# is exactly what drifts — this seat has shipped that defect before. If the block
# markers below ever stop matching, this test ABORTS rather than silently testing
# nothing.
#
# WHY THE PREDICATE NEEDED A TEST AT ALL: its predecessor was a bare
# `grep "^import <mod>$" SaltWorks.lean` — DIRECT MEMBERSHIP — printing a COVERAGE
# claim. On the 2026-08-23 sweep that made 9 of its 10 warnings FALSE, because the
# hub reaches the cert modules through the `SaltWorks.Certs.All` aggregator.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/meas_since.sh"
[ -r "$SRC" ] || { echo "FATAL: meas_since.sh not readable at $SRC"; exit 2; }
cd "$HERE/../.." || exit 2          # repo root: the helper reads SaltWorks.lean relatively
[ -f SaltWorks.lean ] || { echo "FATAL: SaltWorks.lean not found from $(pwd)"; exit 2; }

TMP=$(mktemp) || exit 2
trap 'rm -f "$TMP"' EXIT
awk '/^# ── HUB REACHABILITY, computed ONCE/{f=1} /^rc=0$/{f=0} f' "$SRC" > "$TMP"
grep -q 'reach_hub()' "$TMP" || {
  echo "⛔ ABORT: could not extract the reach_hub helper from meas_since.sh."
  echo "   The block markers moved. This test would otherwise pass VACUOUSLY."
  exit 3; }

. "$TMP"

pass=0; fail=0
t() { got=$(reach_hub "$1")
      if [ "$got" = "$2" ]; then echo "  ✅ $3"; pass=$((pass+1))
      else echo "  ⛔ $3 — got '$got', expected '$2'"; fail=$((fail+1)); fi }

echo "meas_reach_selftest: predicate extracted from $SRC"
t SaltWorks.Certs.Compiler                     yes "POSITIVE transitive via the Certs.All aggregator"
t SaltWorks.Silicon.Imported.CompareExchangeC  yes "POSITIVE transitive via SeamC"
t SaltWorks.HDL.SeamC                          yes "POSITIVE direct import from the hub"
t docs.hdl-tools.reach_census                  no  "NEGATIVE genuinely unreachable (0 importers)"
t SaltWorks.NoSuchModuleAnywhere               no  "NEGATIVE nonexistent module"
echo "meas_reach_selftest: PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0
