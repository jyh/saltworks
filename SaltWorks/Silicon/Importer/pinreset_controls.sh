#!/bin/bash
# PINRESET CONTROLS — the negative controls for the `--pin-reset` / dfrtp model,
# registered in docs/silicon-dfrtp-async-reset-prereg-0812.md and run for the
# record in its .RESULTS.md companion.
#
# ## Why this file exists
#
# The controls were run once by hand the night the mechanics were built. A
# control run once is a demonstration; a control that can be re-run is a fixture,
# and only the second kind survives the next change to the importer. Every row
# below plants a REAL defect and drives THE REAL COMMAND with the REAL flags —
# not a re-implementation of the check, which is the trap this seat fell into on
# 8/12 (a control that proved a pattern while missing four files, its own watcher
# among them).
#
# ⛔ A ROW THAT CANNOT RUN PRINTS A REFUSAL AND FAILS. A silent skip reads exactly
# like a pass, and this seat shipped that defect once already today.
#
# Usage:  ./pinreset_controls.sh
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
cd "$SELF/../../.." || exit 2
IMP=SaltWorks/Silicon/Importer/import_netlist.py
FX=SaltWorks/Silicon/Importer/fixtures
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0; n=0

# row <label> <fixture> <expect:PASS|RED> <inputs> [pin-reset-net]
row() {
  local label=$1 fx=$2 expect=$3 ins=$4 pin=${5:-}
  n=$((n+1))
  if [ ! -f "$FX/$fx" ]; then
    echo "  ⛔ $label — FIXTURE MISSING ($fx); refusing to count this as a pass"
    fail=1; return
  fi
  python3 "$IMP" "$FX/$fx" --top pinreset_fx --out "$TMP/out.lean" --name fxNL \
      --inputs "$ins" --outputs q0,q1 ${pin:+--pin-reset "$pin"} --check off \
      >"$TMP/log" 2>&1
  local rc=$?
  local got; [ $rc -eq 0 ] && got=PASS || got=RED
  if [ "$got" = "$expect" ]; then
    printf "  ✅ %-46s %s (exit %d)\n" "$label" "$got" "$rc"
  else
    printf "  ✗ %-46s expected %s, got %s (exit %d)\n" "$label" "$expect" "$got" "$rc"
    sed 's/^/        /' "$TMP/log" | head -3
    fail=1
  fi
}

echo "pinreset controls: planting defects and driving the real importer"

# C4 — the DEFAULT path. The refusal must survive every future change; it is what
# every caller gets who has not asked for the restriction.
row "C4  no --pin-reset: dfrtp must REFUSE"      pinreset_base.v  RED  "clk,rst_n,d0,d1"
# The positive arm. If this ever goes RED the controls below prove nothing,
# because a run that always fails satisfies every RED row for free.
row "C1  base + --pin-reset: must IMPORT"        pinreset_base.v  PASS "clk,d0,d1" rst_n
# C1's two blocking clauses, exercised separately — the first fixture trips the
# multi-net clause before it can reach the driven-net clause.
row "NC1  reset pins span two nets"              pinreset_nc1.v   RED  "clk,d0,d1" rst_n
row "NC1b single reset net, DRIVEN by a cell"    pinreset_nc1b.v  RED  "clk,d0,d1" n0
# C2 is DISCLOSURE and must never block — a row asserting exit 0 is the only way
# to notice if it silently becomes an error.
row "NC2  other consumer: report, do NOT block"  pinreset_nc2.v   PASS "clk,d0,d1" rst_n
row "NC2b live consumer reaching an output"      pinreset_nc2b.v  PASS "clk,d0,d1" rst_n
# C6 against the independent text scan.
row "NC6  commented-out flop: conservation RED"  pinreset_nc6b.v  RED  "clk,d0,d1" rst_n
# The flag must not be a silent no-op, in either direction.
row "NCx  pinned net also listed in --inputs"    pinreset_base.v  RED  "clk,rst_n,d0,d1" rst_n
row "NCy  --pin-reset on a flopless netlist"     pinreset_dfxtp.v RED  "clk,d0,d1" rst_n

# --- C3, the substantive claim: pinning yields the dfxtp reading GATE-FOR-GATE.
# Compared on the datum's CONTENT. The header differs by design (the scope marker
# is required by the helm ruling) and the flop table names the real cell, so those
# are stripped — and stripping them is exactly why C3 as literally registered is
# RED in the RESULTS companion. This row is the amended comparison, run for
# information; it does not discharge the registered criterion.
echo "pinreset controls: C3 content comparison (informational — see RESULTS §2)"
python3 "$IMP" "$FX/pinreset_base.v"  --top pinreset_fx --out "$TMP/p.lean" --name fxNL \
    --inputs clk,d0,d1 --outputs q0,q1 --pin-reset rst_n --check off >/dev/null 2>&1
python3 "$IMP" "$FX/pinreset_dfxtp.v" --top pinreset_fx --out "$TMP/x.lean" --name fxNL \
    --inputs clk,d0,d1 --outputs q0,q1 --check off >/dev/null 2>&1
if [ ! -s "$TMP/p.lean" ] || [ ! -s "$TMP/x.lean" ]; then
  echo "  ⛔ C3 — one or both arms produced nothing; refusing to report a comparison"
  fail=1
else
  strip() { grep -vE '^-- source:|^--$|^-- ⚠ RESTRICTED|^-- This models|^-- THROUGHOUT|^-- restriction:|^-- the Liberty|^-- about the|^-- clock interact|^-- COVERING|^-- must carry|^-- docs/' "$1" \
            | sed 's/, df[rx]tp_1)/, dfXtp_1)/'; }
  strip "$TMP/p.lean" >"$TMP/a"; strip "$TMP/x.lean" >"$TMP/b"
  if cmp -s "$TMP/a" "$TMP/b"; then
    echo "  ✅ C3  pinned datum is GATE-FOR-GATE the dfxtp reading"
  else
    echo "  ✗ C3  content differs — this is the substantive claim, investigate:"
    diff "$TMP/b" "$TMP/a" | head -12 | sed 's/^/        /'
    fail=1
  fi
fi

echo "pinreset controls: $n planted row(s), $( [ $fail -eq 0 ] && echo "ALL BEHAVED" || echo "FAILURES ABOVE" )"
exit $fail
