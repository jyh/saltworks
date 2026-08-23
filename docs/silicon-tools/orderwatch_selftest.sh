#!/bin/sh
# orderwatch_selftest.sh — DRIVES orderwatch.awk against REAL BUS LINES.
#
# ⛔ WHY REAL LINES AND NOT SYNTHETIC ONES: rev 2 exists because a fix I proposed
# from MEMORY ("widen to a header naming this seat") would have missed the very
# order that motivated it. Synthetic fixtures would have agreed with my memory.
# The regression fixture here is the ACTUAL missed header, pulled from the bus.
#
# ⛔ EVERY FIXTURE IS ADDRESSED BY LINE NUMBER **AND** VERIFIED BY A CONTENT STAMP.
# The bus is append-only so historical line numbers are stable — but "stable" is
# an assumption, and an assumption that silently fails would make every arm below
# test the WRONG LINE and still print green. If a stamp does not match, this test
# ABORTS rather than reporting.
#
# ⭐ ARM 6 ASSERTS A MISS ON PURPOSE. Bus line 15594 is a real fleet-wide order
# (`HOLD HEAVY WORK`) that this filter provably cannot catch. Recording the limit
# as an executable assertion is the only way a later "improvement" that quietly
# changes the coverage story has to argue with something.
set -u
BUS=${BUS:-/Users/jyh/projects/claude/FLEET.md}
AWKPROG=${AWKPROG:-$(dirname "$0")/orderwatch.awk}
[ -r "$BUS" ]     || { echo "FATAL: bus not readable at $BUS"; exit 2; }
[ -r "$AWKPROG" ] || { echo "FATAL: filter not readable at $AWKPROG"; exit 2; }
export LC_ALL=C   # ⛔ the bus is full of emoji; grep/cut die with "Illegal byte
                  # sequence" under a UTF-8 locale and rc=2 READS AS NO MATCH.
PASS=0; FAIL=0
line_at() { LC_ALL=C awk -v n="$1" 'NR==n{print; exit}' "$BUS"; }

# fixture: <line> <stamp that must appear in it> <label>
check_stamp() {
  _l=$1; _stamp=$2; _lab=$3
  _got=$(line_at "$_l")
  case "$_got" in
    *"$_stamp"*) : ;;
    *) echo "⛔ ABORT: fixture $_lab at line $_l does not carry stamp '$_stamp'"
       echo "   got: $(echo "$_got" | cut -c1-100)"
       echo "   the bus moved under this test; re-derive the fixtures before trusting ANY arm."
       exit 3 ;;
  esac
}
# run the filter over exactly one line, with start=0 so nothing is baseline-skipped
tag_of() { line_at "$1" | LC_ALL=C awk -v start=0 -f "$AWKPROG" | LC_ALL=C awk -F'\t' 'NR==1{print $1}'; }

arm() { # arm <label> <expected-tag-or-NONE> <actual>
  if [ "$2" = "$3" ]; then echo "  ✅ $1 -> ${3:-NONE}"; PASS=$((PASS+1))
  else echo "  ⛔ $1 -> expected '${2}', got '${3:-NONE}'"; FAIL=$((FAIL+1)); fi
}

echo "orderwatch_selftest: filter=$AWKPROG bus=$BUS"
check_stamp 159497 "SILICON ORDER:"                  "ARM1-token"
check_stamp 160140 "CRASH CHECK-INS DISPATCHED"      "ARM2-broadcast-REGRESSION"
check_stamp 160718 "NORMAL OPERATIONS RESUME"        "ARM3-named"
check_stamp 160048 "compiler"                        "ARM4-peer-negative"
check_stamp  18328 "maestro"                         "ARM5-maestro-negative"
check_stamp  15594 "HOLD HEAVY WORK"                 "ARM6-known-miss"
echo "  (all six fixture stamps verified — the arms below are reading the intended lines)"

echo "POSITIVE ARMS — each must deliver, and with the RIGHT tag:"
arm "ARM1 contract token (11:10:49)"                 "TOKEN"              "$(tag_of 159497)"
arm "ARM2 REGRESSION: the order that was missed"     "BROADCAST-no-token" "$(tag_of 160140)"
arm "ARM3 header names silicon (14:24:21)"           "NAMED-no-token"     "$(tag_of 160718)"

echo "NEGATIVE ARMS — each must stay DROPPED:"
arm "ARM4 PEER header naming silicon stays dark"     ""                   "$(tag_of 160048)"
arm "ARM5 maestro header, none of the three clauses" ""                   "$(tag_of 18328)"
arm "ARM6 KNOWN MISS, asserted: fleet HOLD at 15594" ""                   "$(tag_of 15594)"

echo "MUTATION ARM — the comparison must be able to go RED:"
# ⛔ THE FIRST VERSION OF THIS ARM FAILED, AND THE FILTER WAS INNOCENT. It replaced
# only "ALL SIX SEATS" and the line KEPT DELIVERING — because that header carries
# the broadcast shape THREE times ("all six seat" x2, "each seat"). A mutation that
# removes one of three redundant triggers proves nothing, and it fails in the
# direction that looks like a broken filter. So the mutation now removes the noun
# outright: every seat/seats -> panel, which cannot leave a survivor.
# ⭐ And the near-miss is itself the finding: this order class is REDUNDANTLY
# marked as a broadcast, so clause C catches it robustly rather than by luck.
MUT=$(line_at 160140 | LC_ALL=C sed 's/[Ss][Ee][Aa][Tt][Ss]*/panel/g' | LC_ALL=C awk -v start=0 -f "$AWKPROG" | LC_ALL=C awk -F'\t' 'NR==1{print $1}')
arm "ARM7 remove EVERY broadcast trigger -> stops firing" ""             "$MUT"

echo "BASELINE ARM — start= must suppress everything at or below it:"
B=$(line_at 159497 | LC_ALL=C awk -v start=1 -f "$AWKPROG" | LC_ALL=C awk -F'\t' 'NR==1{print $1}')
arm "ARM8 start=1 suppresses line 1 of the stream"   ""                   "$B"

echo "orderwatch_selftest: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
