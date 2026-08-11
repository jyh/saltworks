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
# ⛔ SECOND MIRROR ADDED 2026-08-10 18:0x, AND THE REASON IS WORTH MORE THAN THE LINE OF CODE.
# I wrote this script on 8/9 to kill exactly one instance of silicon's law. One day later I
# landed `RegMap.poolSize = 15` — my own docstring calls it "RTL-mirrored" — and did NOT extend
# the script, because that mirror had not hurt yet. Then `compileE` made it load-bearing: the
# ENTIRE L0 correctness stack (`RegsHold`, `PoolBelow`, `varReg`, `compileE_total`) quantifies
# over `Fin poolSize`. A widened `rf` would leave all of it green while describing a machine
# with more registers than the theorems know about.
#   THE LAW, now paid for twice: A FIX LANDS WHERE THE PAIN WAS FELT. The sibling surface is
#   invisible precisely because it has not hurt yet — so at every landing that MIRRORS someone
#   else's constant, ask what ELSE mirrors it, and extend the guard in the same step.
#
# WHAT IT DOES NOT DO: it does not check that the pool SEMANTICS still match (x0 handling, the
# bit-4 rejection). It checks ONE number against the TWO Lean declarations that mirror it.
# That scope is the whole claim; a THIRD mirror would be invisible to this tool exactly as the
# second one was, so the grep at the bottom is part of the check, not decoration.
#
# REFUSALS, per silicon's pattern — it never guesses:
#   exit 2  either side unparseable  (a missing file or a changed declaration form)
#   exit 1  parsed and MISMATCHED
#   exit 0  parsed and equal
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
RTL="$REPO/SaltWorks/Silicon/RTL/slicea16bma.v"
LEAN="$REPO/SaltWorks/HDL/TinyRustN0.lean"
LEAN2="$REPO/SaltWorks/HDL/RegMap.lean"

for f in "$RTL" "$LEAN" "$LEAN2"; do
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
lean2=$(grep -oE '^def poolSize : Nat := [0-9]+' "$LEAN2" | grep -oE '[0-9]+$')

if [ -z "$rtl" ]; then
  echo "pool_drift: REFUSING — could not parse 'rf [1:N]' in $RTL." >&2
  echo "  The declaration form changed. That is itself worth knowing: DO NOT assume the old N." >&2
  exit 2
fi
if [ -z "$lean" ]; then
  echo "pool_drift: REFUSING — could not parse 'slicea16bmaPool : Nat := N' in $LEAN." >&2
  exit 2
fi
if [ -z "$lean2" ]; then
  echo "pool_drift: REFUSING — could not parse 'def poolSize : Nat := N' in $LEAN2." >&2
  echo "  RegMap.poolSize is what the whole L0 correctness stack quantifies over. An" >&2
  echo "  unparseable second mirror is the case this arm was ADDED for; do not skip it." >&2
  exit 2
fi

echo "pool_drift: RTL rf [1:$rtl]  ·  TinyRustN0.slicea16bmaPool = $lean  ·  RegMap.poolSize = $lean2"

rc=0
if [ "$rtl" != "$lean" ]; then
  echo "pool_drift: ⛔ DRIFT — TinyRustN0.slicea16bmaPool no longer matches the RTL." >&2
  echo "  Every fitsAndTyped/poolDemand theorem at slicea16bmaPool is still GREEN and now" >&2
  echo "  describes a machine that does not exist. Update the Lean constant, or if the RTL" >&2
  echo "  shrank, expect programs that previously fitted to stop fitting." >&2
  rc=1
fi
if [ "$rtl" != "$lean2" ]; then
  echo "pool_drift: ⛔ DRIFT — RegMap.poolSize no longer matches the RTL." >&2
  echo "  This is the LOAD-BEARING one: RegsHold, PoolBelow, varReg and compileE_total all" >&2
  echo "  quantify over Fin poolSize, and every one of them stays GREEN while describing a" >&2
  echo "  register file that is not the one being built." >&2
  rc=1
fi
if [ "$lean" != "$lean2" ]; then
  echo "pool_drift: ⛔ THE TWO LEAN MIRRORS DISAGREE WITH EACH OTHER ($lean vs $lean2)." >&2
  echo "  Reported separately from the RTL comparison on purpose: this arm fires even when" >&2
  echo "  the RTL is unreachable or has changed shape, and it is the cheapest possible tell." >&2
  rc=1
fi

# THE THIRD-MIRROR ARM. This tool knows two declarations by name; a third would be invisible
# to it exactly as the second was for a day. Counting is not proving, so this WARNS and never
# fails: a new match may be a legitimate unrelated 15.
extra=$(grep -rn ': Nat := 15$' "$REPO/SaltWorks" --include='*.lean' 2>/dev/null \
        | grep -cv 'slicea16bmaPool\|RegMap.lean')
if [ "${extra:-0}" -gt 0 ]; then
  echo "pool_drift: ⚠️  $extra other Lean declaration(s) are literally 15. NOT a failure —" >&2
  echo "  but if any of them mirrors rf [1:N], this tool does not cover it. Name it here." >&2
fi

[ "$rc" = 0 ] && echo "pool_drift: OK — both mirrors hold (scope: this ONE number, TWO declarations, today)."
exit $rc
