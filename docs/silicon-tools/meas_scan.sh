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

# ⛔⛔ SCAN THE CODE, NOT THE PROSE. This corpus is heavily commented in WRAPPED
# prose, which puts ordinary words at COLUMN 0 — so every column-anchored pattern
# below fires inside comments. Measured on ImmediateScope.lean @ 169eaf5: a
# docstring line reading "theorem was true and awkward" made this script report
# "⛔ UNAUDITED was" against a landing that is 4/4 clean. One more step and that
# is a FALSE ACCUSATION against a peer — my second of the day from a pattern
# defect. The stripper is a COMMITTED EXECUTABLE so it is fixed once, here and
# for any other seat that calls it, rather than re-typed per tool.
[ -f "$HERE/strip_lean_comments.awk" ] || { echo "⛔ meas_scan: strip_lean_comments.awk missing — refusing to scan prose as code"; exit 2; }
CODE=$(printf '%s\n' "$SRC" | awk -f "$HERE/strip_lean_comments.awk") || { echo "⛔ meas_scan: comment stripping FAILED — refusing to report clean"; exit 2; }
[ -n "$CODE" ] || { echo "⛔ meas_scan: stripped source is EMPTY — refusing to report clean"; exit 2; }

# declarations: attribute prefixes and lemma/theorem both, keyword NOT anchored at col 0
DECLS=$(printf '%s\n' "$CODE" | grep -oE "^[[:space:]]*(@\[[^]]*\][[:space:]]*)?(private |protected |noncomputable )*(theorem|lemma) [A-Za-z_0-9']+" | awk '{print $NF}' | sort -u)
AUD=$(printf '%s\n' "$CODE" | grep "^#audit_axioms" | sed 's/^#audit_axioms //' | tr ' ' '\n' | grep -vE '^$' | sort -u)
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
#
# ⛔⛔⛔ THIRD PASS ON THIS ONE LINE (2026-08-08 21:5x) — THE FIX ABOVE WAS ALSO
# BROKEN, AND THE CLAIM "the exit status of `comm` is CHECKED" WAS FALSE:
#     if ! MISS=$(comm -23 "$_d" "$_a" | tr '\n' ' '); then …
# `$?` of a PIPELINE is the LAST command's — `tr`'s — so `comm` failing was
# invisible and MISS came back EMPTY. The guard could not fire. Controlled:
#     comm -23 /nonexistent/a /nonexistent/b | tr '\n' ' '   -> guard SILENT
#     comm -23 /nonexistent/a /nonexistent/b                 -> guard FIRES
# That is [[exit-code-dies-in-a-pipe]] — MY OWN BANKED LAW — reintroduced by the
# fix for the process-substitution bug, in the guard whose comment boasts of
# catching exactly this. THREE mechanisms, one failure mode, same two lines:
#   ① bash process substitution under `sh`   -> syntax error, MISS empty
#   ② pipeline exit status                   -> comm's failure swallowed
#   ③ (the shape both share) an empty MISS reads as "nothing unaudited"
# ⇒ CAPTURE THE STATUS BEFORE ANY PIPE. Transform AFTER the check, never in it.
_d=$(mktemp) ; _a=$(mktemp)
trap 'rm -f "$_d" "$_a"' EXIT
printf '%s\n' "$DECLS" > "$_d"
printf '%s\n' "$AUD"   > "$_a"
if ! MISS_RAW=$(comm -23 "$_d" "$_a"); then
  echo "⛔ meas_scan: the coverage diff FAILED to run — refusing to report clean"
  exit 2
fi
MISS=$(printf '%s' "$MISS_RAW" | tr '\n' ' ')

# ⭐ ANCHORED, not substring: a real `sorry` is a PROOF TERM, so it follows `:=`
# or `by` or sits alone. "admits" in prose must not fire, or the check gets
# ignored by its own author inside a day — and an ignored sorry check is worse
# than no check.
# Scanned on $CODE: with comments gone, "the encoding admits a value" cannot fire
# at all, so the anchoring below is now belt-and-braces rather than the only guard.
SORRY=$(printf '%s\n' "$CODE" | grep -nE '(:=|by|<;>|;)[[:space:]]*sorry\b|^[[:space:]]*sorry\b|\badmit\b[[:space:]]*$')
# ⛔ COUNT BEFORE CAPPING. `| head -20` used to be part of the line above, which
# would have shown 20 of N and printed no N. On 8/8 I read `dup_props | head -3`
# and published a wrong residue three times; a display cap must never be able to
# hide the size of what it capped.
NSORRY=$(printf '%s\n' "$SORRY" | grep -c .)

printf 'MEAS SCAN  %s  @ %s\n' "$MOD" "$REF"
printf '  declarations   %s\n' "$NDECL"
printf '  audited names  %s\n' "$NAUD"
if [ -n "$(printf '%s' "$MISS" | tr -d ' ')" ]; then
  printf '  ⛔ UNAUDITED   %s\n' "$MISS"
else
  printf '  ✅ UNAUDITED   none\n'
fi
if [ -n "$SORRY" ]; then
  printf '  ⛔ SORRY/ADMIT — %s found (comments stripped, so these are CODE):\n' "$NSORRY"
  printf '%s\n' "$SORRY" | head -20
  [ "$NSORRY" -gt 20 ] && printf '     … %s more NOT shown — this is a DISPLAY cap; the count above is complete\n' "$((NSORRY - 20))"
else
  printf '  ✅ sorry/admit none — searched CODE ONLY (comments stripped first)\n'
fi
printf '  — duplicate propositions are a CORPUS check, not a module one:\n'
printf '      sh %s/dup_props.sh %s "SaltWorks/HDL/*.lean"   # read it WHOLE\n' "$HERE" "$REF"
# ⛔ THIS PASS IS STRUCTURAL — it reads SOURCE TEXT at a ref and runs NO KERNEL.
# A green scan says the audits are PRESENT, never that they PASSED. Say so here,
# or the next reader (me) treats a clean scan as a checked module.
printf '  — ⛔ STRUCTURAL ONLY: no kernel ran. This says the audits are PRESENT,\n'
printf '       not that they PASS. For the independent kernel witness:\n'
printf '      sh %s/meas_build.sh %s   # PATH form; the module form only REPLAYS\n' "$HERE" "$MOD"
