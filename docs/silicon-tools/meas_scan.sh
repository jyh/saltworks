#!/bin/sh
# meas_scan.sh — the SILICON seat's MEAS structural pass, in one place.
#
#   sh docs/silicon-tools/meas_scan.sh <ref> <module-path>
#   sh docs/silicon-tools/meas_scan.sh origin/master SaltWorks/HDL/SortDemo.lean
#
# ⛔ WHY THIS FILE EXISTS, AND IT IS THE ROOT CAUSE OF A WHOLE DAY OF DEFECTS:
# I ran this pass eight times on 2026-08-08 and RE-WROTE THE PATTERNS EVERY TIME.
# Every pattern bug I shipped came from that, and each had a different mechanism:
#
#   name-not-content   grepped `needed|load_bearing` in NAMES; controls are named
#                      for WHAT THEY SHOW, so I counted 5 where 24 existed
#   `= false`          scored the campaign's SUMMIT theorem as a "refutation",
#                      because a reset condition is not a negation
#   CASE               `/round-2/` against a heading reading `ROUND-2`; I then
#                      published that a predecessor had not done work they HAD
#   column anchoring   `^theorem` misses `@[simp] theorem` — and the @[simp] ones
#                      are the ones you least want unaudited
#   number format      `[0-9.]+` for a yosys area column that prints `1.12E+04`;
#                      14 of 30 cell counts wrong, core32 by 3.1x
#   substring `admit`  fires on "the encoding ADMITS a value" — ordinary prose in
#                      a corpus that discusses admissibility constantly
#
# ⇒ A PATTERN RE-TYPED IS A PATTERN RE-INVENTED. The cure is not more care; it is
#   ONE committed copy that gets fixed once and inherited by every later run.
#
# ⚠️ AND NEVER PIPE THIS THROUGH `head`. On 8/8 19:34 I read `dup_props | head -3`
#   and published "residue still 1" three times when the tool had found 2. A
#   display cap is a silent filter you applied to YOURSELF, and it fails in the
#   flattering direction.

set -u
REF="${1:?usage: meas_scan.sh <ref> <path/to/Module.lean>}"
MOD="${2:?usage: meas_scan.sh <ref> <path/to/Module.lean>}"
HERE="$(cd "$(dirname "$0")" && pwd)"

SRC=$(git show "$REF:$MOD" 2>/dev/null) || { echo "⛔ meas_scan: cannot read $REF:$MOD"; exit 2; }
[ -n "$SRC" ] || { echo "⛔ meas_scan: $REF:$MOD is EMPTY — refusing to report clean"; exit 2; }

# declarations: attribute prefixes and lemma/theorem both, keyword NOT anchored at col 0
DECLS=$(printf '%s\n' "$SRC" | grep -oE "^[[:space:]]*(@\[[^]]*\][[:space:]]*)?(private |protected |noncomputable )*(theorem|lemma) [A-Za-z_0-9']+" | awk '{print $NF}' | sort -u)
AUD=$(printf '%s\n' "$SRC" | grep "^#audit_axioms" | sed 's/^#audit_axioms //' | tr ' ' '\n' | grep -vE '^$' | sort -u)
NDECL=$(printf '%s\n' "$DECLS" | grep -c .)
NAUD=$(printf '%s\n' "$AUD" | grep -c .)
# ⛔⛔ NO PROCESS SUBSTITUTION. The first version of this line used
#   comm -23 <(...) <(...)
# which is a BASH feature; this script runs under `sh`, so it was a SYNTAX ERROR
# — and the error went to stderr while MISS came back EMPTY, so the script
# printed "✅ UNAUDITED none" off a FAILED COMPUTATION. That is the exact defect
# this file's header warns about, committed inside the file that warns about it,
# and caught only because I ran a control instead of trusting the output.
# POSIX temp files, and the exit status of `comm` is CHECKED.
_d=$(mktemp) ; _a=$(mktemp)
trap 'rm -f "$_d" "$_a"' EXIT
printf '%s\n' "$DECLS" > "$_d"
printf '%s\n' "$AUD"   > "$_a"
if ! MISS=$(comm -23 "$_d" "$_a" | tr '\n' ' '); then
  echo "⛔ meas_scan: the coverage diff FAILED to run — refusing to report clean"
  exit 2
fi

# ⭐ ANCHORED, not substring: a real `sorry` is a PROOF TERM, so it follows `:=`
# or `by` or sits alone. "admits" in prose must not fire, or the check gets
# ignored by its own author inside a day — and an ignored sorry check is worse
# than no check.
SORRY=$(printf '%s\n' "$SRC" | grep -nE '(:=|by|<;>|;)[[:space:]]*sorry\b|^[[:space:]]*sorry\b|\badmit\b[[:space:]]*$' | head -20)

printf 'MEAS SCAN  %s  @ %s\n' "$MOD" "$REF"
printf '  declarations   %s\n' "$NDECL"
printf '  audited names  %s\n' "$NAUD"
if [ -n "$(printf '%s' "$MISS" | tr -d ' ')" ]; then
  printf '  ⛔ UNAUDITED   %s\n' "$MISS"
else
  printf '  ✅ UNAUDITED   none\n'
fi
if [ -n "$SORRY" ]; then
  printf '  ⛔ SORRY/ADMIT (anchored):\n%s\n' "$SORRY"
else
  printf '  ✅ sorry/admit none (anchored — prose "admits" does NOT fire)\n'
fi
printf '  — duplicate propositions are a CORPUS check, not a module one:\n'
printf '      sh %s/dup_props.sh %s "SaltWorks/HDL/*.lean"   # read it WHOLE\n' "$HERE" "$REF"
# ⛔ THIS PASS IS STRUCTURAL — it reads SOURCE TEXT at a ref and runs NO KERNEL.
# A green scan says the audits are PRESENT, never that they PASSED. Say so here,
# or the next reader (me) treats a clean scan as a checked module.
printf '  — ⛔ STRUCTURAL ONLY: no kernel ran. This says the audits are PRESENT,\n'
printf '       not that they PASS. For the independent kernel witness:\n'
printf '      sh %s/meas_build.sh %s   # PATH form; the module form only REPLAYS\n' "$HERE" "$MOD"
