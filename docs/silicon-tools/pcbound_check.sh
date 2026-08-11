#!/bin/sh
# pcbound_check.sh — PRE-REGISTERED CRITERION, silicon, 2026-08-11 01:2x.
#
#   sh docs/silicon-tools/pcbound_check.sh <file.lean> [theorem-name ...]
#
# ⚠️ WHY THIS EXISTS, and it is compiler's shape, not mine. Answering item 3 of
# my scoping of math's deferred pass, compiler measured that `whileFits`
# discharges the REPRESENTABILITY half of the branch obligations exactly and the
# pc-RANGE half NOT AT ALL — structurally, because the `hp` hypotheses mention
# `q`, the block's POSITION, and `compileS` has no position parameter. That
# absence is the very property that makes the offsets position-independent.
# The pc-range bound is therefore SUPPLIED BY THE CALLER, exactly as at L0/L1.
#
# ⛔ COMPILER NAMED THE FAILURE SHAPE THEY WANT NOBODY'S GREEN TO COVER:
#      "an emitter that silently ASSUMES `hp` instead of taking it as a
#       hypothesis — the shape that would let a 2^30-instruction program
#       compile to a lie."
#   That is NOT mathematics. It is a structural property of a theorem's binder
#   list, which puts it on the MEAS leg. Hence a criterion, published BEFORE the
#   emitter lands so it cannot be fitted to the artifact afterwards.
#
# THE BAR, fixed in advance:
#   For any theorem asserting where a compiled block's branches LAND, or the
#   correctness of emitted code AT A POSITION:
#     PASS  its binder region carries an explicit pc-range/length bound
#           (`< 2 ^ 32`) — i.e. the caller must supply it.
#     FAIL  no such binder, while the statement still ranges over an arbitrary
#           position or program length. The obligation has been ASSUMED.
#
# ⭐ THIS CRITERION HAS BEEN SHOWN TO FAIL. `--selftest` builds a mutant of a
#   real landed theorem with its `hp` binder deleted and requires the detector
#   to flag it. A criterion only ever run on passing input has not been shown to
#   discriminate — precision reads exactly like strength.
#
# Instrument notes, each paid for on 2026-08-11:
#   · theorem names are END-ANCHORED. `^theorem X` also matches `X_of_branchFree`
#     — the restatement-renames law makes every new name CONTAIN the old one.
#   · `\b` is NOT POSIX ERE and matches NOTHING under `grep -E`. Not used here.
#   · the binder region is the text from the theorem head to the FIRST `:= by`,
#     so a bound appearing only in the PROOF does not count as a hypothesis.

set -u
SELF=$(basename "$0")

# Extract the statement (head .. first ':= by' / ':=') of theorem $2 in file $1.
# ⛔ THE QUOTING HERE IS DELIBERATE AND WAS PAID FOR: the end-anchor character
# class must exclude the PRIME, because Lean names may carry it. Writing that
# class inline put a literal ' and " inside a single-quoted shell string holding
# an awk string, and awk died with "extra ]" on EVERY line — the extractor then
# returned NOT FOUND for every theorem, which is the FALSE-CLEAN direction.
# ⭐ THE SELFTEST CAUGHT IT AND REFUSED TO CERTIFY THE GATE (pos=1 neg=1). The
# positive control is what made a dead extractor distinguishable from a clean
# corpus. Build the class from a -v variable; keep quotes out of the program.
stmt() {
  awk -v n="$2" -v q="$(printf '\047')" '
    $0 ~ ("^theorem[ \t]+" n "([^A-Za-z0-9_" q "]|$)") { f=1 }
    f { print }
    f && /:= by[ \t]*$|:=[ \t]*$|:= by / { exit }
  ' "$1"
}

# ⛔ APPLICABILITY, ADDED AFTER THE TOOL FLAGGED `whileBack_msb` — MY OWN SCOPE
# ERROR, caught by running the gate on the landed set before publishing it.
# `whileBack_msb` is PURE ARITHMETIC about the immediate: no position, no `pc`,
# so it does not NEED a pc-range bound and its "FAIL" meant nothing.
# 🔑 A CRITERION THAT CANNOT TELL "DOES NOT NEED IT" FROM "IS MISSING IT" FIRES
# ON EVERY ARITHMETIC LEMMA IN THE FILE — and a gate that cries wolf on a duty
# that runs all day is how a REAL alarm gets ignored. Same reasoning that made
# meas_since.sh report deletions as RETIRED instead of feeding them to the gate.
# IN SCOPE iff the statement mentions a position-bearing object (`pc`/`codeAt`).
check_one() {   # file, name -> 0 pass/skip, 1 fail
  s=$(stmt "$1" "$2")
  if [ -z "$s" ]; then
    printf '  %-34s ⛔ NOT FOUND (name end-anchored; check spelling)\n' "$2"
    return 1
  fi
  if ! printf '%s\n' "$s" | grep -qE '(^|[^A-Za-z0-9_])(pc|codeAt)([^A-Za-z0-9_]|$)'; then
    printf '  %-34s ·  SKIP — no position in the statement, bound N/A\n' "$2"
    return 0
  fi
  if printf '%s\n' "$s" | grep -q '< *2 *\^ *32'; then
    printf '  %-34s ✅ PASS — pc-range bound is a HYPOTHESIS\n' "$2"
    return 0
  fi
  printf '  %-34s ⛔ FAIL — NO pc-range binder; the bound is ASSUMED\n' "$2"
  return 1
}

if [ "${1:-}" = "--selftest" ]; then
  SRC=${2:?usage: $SELF --selftest <file.lean> <theorem-with-hp>}
  NAME=${3:?usage: $SELF --selftest <file.lean> <theorem-with-hp>}
  TMP=$(mktemp -t pcbound); trap 'rm -f "$TMP"' EXIT
  echo "SELFTEST — the criterion must PASS the real theorem and FAIL its mutant."
  echo "POSITIVE CONTROL (real $NAME):"
  check_one "$SRC" "$NAME"; pos=$?
  # MUTANT: delete the pc-range binder line, leaving everything else intact.
  grep -v '< *2 *\^ *32' "$SRC" > "$TMP"
  echo "NEGATIVE CONTROL (same theorem, hp binder deleted):"
  check_one "$TMP" "$NAME"; neg=$?
  echo
  if [ "$pos" = 0 ] && [ "$neg" = 1 ]; then
    echo "✅ CRITERION DISCRIMINATES — passes the real, fails the mutant."; exit 0
  fi
  echo "⛔ CRITERION IS VACUOUS (pos=$pos neg=$neg) — DO NOT USE IT AS A GATE."; exit 1
fi

F=${1:?usage: $SELF <file.lean> [theorem-name ...]}
shift
[ -r "$F" ] || { echo "FATAL: cannot read $F"; exit 2; }
rc=0
echo "pc-range criterion over $F"
for n in "$@"; do check_one "$F" "$n" || rc=1; done
[ "$rc" = 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT — the bound is assumed somewhere"
exit $rc
