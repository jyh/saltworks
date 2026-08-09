#!/bin/sh
# pool_drift.sh — does the Lean pool constant still match the RTL it MIRRORS?
#
# WHY THIS EXISTS (compiler, 2026-08-09 12:0x, after silicon's fb73853)
# --------------------------------------------------------------------
# Silicon found that ruling (d) — the audit cap rising to 24000 — SILENTLY VOIDED their own
# gate's differential test, because their HICAP constant MIRRORED the wrapper's CAP constant.
# Their law: A CONSTANT THAT TRACKS SOMEONE ELSE'S CONSTANT IS A DEFECT WAITING FOR THEM TO
# EDIT IT. And it degrades in the worst direction — the test still ran, still passed, and no
# longer discriminated.
#
# I HAVE THE SAME DEFECT, ACROSS A LANGUAGE BOUNDARY. `TinyRustN0.slicea16bmaPool = 15`
# mirrors `slicea16bma.v`'s `reg [31:0] rf [1:15]`. Lean cannot read Verilog, so the literal
# CANNOT be replaced by a read — which makes the mirror unavoidable and the CHECK mandatory.
# Without this script, widening `rf` leaves every `fitsAndTyped slicea16bmaPool` theorem GREEN
# while describing a machine that no longer exists.
#
# WHAT IT DOES NOT DO: it does not check that the pool SEMANTICS still match (x0 handling, the
# bit-4 rejection). It checks ONE number against ONE declaration. That scope is the whole claim.
#
# REFUSALS, per silicon's pattern — it never guesses:
#   exit 2  either side unparseable  (a missing file or a changed declaration form)
#   exit 1  parsed and MISMATCHED
#   exit 0  parsed and equal
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
RTL="$REPO/SaltWorks/Silicon/RTL/slicea16bma.v"
LEAN="$REPO/SaltWorks/HDL/TinyRustN0.lean"

for f in "$RTL" "$LEAN"; do
  [ -f "$f" ] || { echo "pool_drift: REFUSING — no file at $f" >&2; exit 2; }
done

# NOT `head -1`: silicon's 12:11 residual. Taking the FIRST match would silently pick one of
# several register files, and a single-number check over an ambiguous source is meaningless.
# Count first, REFUSE on ambiguity — same discipline as the unparseable arm.
rtl_n=$(grep -cE 'rf *\[[0-9]+:[0-9]+\]' "$RTL")
if [ "$rtl_n" -gt 1 ]; then
  echo "pool_drift: REFUSING — $rtl_n register-file declarations in $RTL." >&2
  echo "  This tool compares ONE number. With more than one regfile, slicea16bmaPool cannot" >&2
  echo "  mean what it claims, and picking the first would hide that rather than report it." >&2
  exit 2
fi
rtl=$(grep -oE 'rf *\[1:[0-9]+\]' "$RTL" | grep -oE '[0-9]+\]$' | tr -d ']')
lean=$(grep -oE 'slicea16bmaPool : Nat := [0-9]+' "$LEAN" | grep -oE '[0-9]+$')

if [ -z "$rtl" ]; then
  echo "pool_drift: REFUSING — could not parse 'rf [1:N]' in $RTL." >&2
  echo "  The declaration form changed. That is itself worth knowing: DO NOT assume the old N." >&2
  exit 2
fi
if [ -z "$lean" ]; then
  echo "pool_drift: REFUSING — could not parse 'slicea16bmaPool : Nat := N' in $LEAN." >&2
  exit 2
fi

echo "pool_drift: RTL rf [1:$rtl]  ·  Lean slicea16bmaPool = $lean"
if [ "$rtl" = "$lean" ]; then
  echo "pool_drift: OK — the mirror holds (scope: this ONE number, today)."
  exit 0
fi
echo "pool_drift: ⛔ DRIFT — the Lean pool constant no longer matches the RTL." >&2
echo "  Every fitsAndTyped/poolDemand theorem at slicea16bmaPool is still GREEN and now" >&2
echo "  describes a machine that does not exist. Update the Lean constant, or if the RTL" >&2
echo "  shrank, expect programs that previously fitted to stop fitting." >&2
exit 1
