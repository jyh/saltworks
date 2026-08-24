#!/bin/sh
# SELFTEST for capcheck.sh. Sibling of hookedit_selftest.sh and built from the
# same law: a criterion only ever run on passing input has not been shown to
# discriminate, and a check that cannot fail was never a check.
#
# ⛔ ARM 6 EXISTS BECAUSE capcheck WAS WRONG ON ITS FIRST REAL RUN: it applied a
#   TOKEN model to MEMORY.md, whose cap is ~24,986 BYTES, and printed ~39.3%
#   where the truth was 84.4% — halving the danger. The unit is now REQUIRED and
#   this arm proves the tool REFUSES without it.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; TOOL="$HERE/capcheck.sh"
PASS=0; FAIL=0
T=$(mktemp -d) || exit 2; trap 'rm -rf "$T"' EXIT
say(){ printf '  %s %s\n' "$1" "$2"; }
ck(){ if [ "$2" = "$3" ]; then PASS=$((PASS+1)); say "OK  " "$1 (rc=$3)"; else FAIL=$((FAIL+1)); say "FAIL" "$1 (expected $2, got $3)"; fi; }

# fixtures: a small file and a big one, sizes chosen so the bands are unambiguous
head -c 1000  /dev/zero | tr '\0' 'a' > "$T/small"
head -c 24000 /dev/zero | tr '\0' 'a' > "$T/big"

# ⛔ NO PIPES ANYWHERE BELOW: $? after a pipe is the LAST stage's status, and it
#   fails in the reassuring direction. (My own bank, learned the hard way.)
"$TOOL" "$T/small" --unit bytes --cap 24986 >/dev/null 2>&1; ck "ARM1 small/bytes inside band" 0 $?
"$TOOL" "$T/big"   --unit bytes --cap 24986 --refuse 90 >/dev/null 2>&1; ck "ARM2 big/bytes REFUSED at 90" 5 $?
"$TOOL" "$T/small" --unit tokens --cap 25000 >/dev/null 2>&1; ck "ARM3 small/tokens inside band" 0 $?
"$TOOL" "$T/big"   --unit tokens --cap 25000 --refuse 40 >/dev/null 2>&1; ck "ARM4 big/tokens REFUSED at 40" 5 $?
"$TOOL" /nope --unit bytes >/dev/null 2>&1; ck "ARM5 missing file refused" 2 $?
"$TOOL" "$T/small" >/dev/null 2>&1; ck "ARM6 MISSING --unit refused" 2 $?
"$TOOL" "$T/small" --unit furlongs >/dev/null 2>&1; ck "ARM7 bogus unit refused" 2 $?

# ARM 8 — THE UNITS MUST ACTUALLY DIFFER. If bytes and tokens produced the same
# verdict on the same file, --unit would be decoration and ARM6 would be theatre.
b=$("$TOOL" "$T/big" --unit bytes  --cap 24986 2>&1 | tr -d '\n')
t=$("$TOOL" "$T/big" --unit tokens --cap 24986 2>&1 | tr -d '\n')
if [ "$b" != "$t" ]; then PASS=$((PASS+1)); say "OK  " "ARM8 bytes and tokens give DIFFERENT readings"
else FAIL=$((FAIL+1)); say "FAIL" "ARM8 --unit changed nothing — it is decoration"; fi

# ARM 9 — the byte path must claim NO estimate; the token path MUST claim one.
case "$b" in *"MEASURED DIRECTLY"*) ok1=1 ;; *) ok1=0 ;; esac
case "$t" in *"ESTIMATE"*)          ok2=1 ;; *) ok2=0 ;; esac
if [ "$ok1$ok2" = "11" ]; then PASS=$((PASS+1)); say "OK  " "ARM9 byte path claims measurement, token path claims ESTIMATE"
else FAIL=$((FAIL+1)); say "FAIL" "ARM9 a path mislabels its own certainty (ok1=$ok1 ok2=$ok2)"; fi

# ARM 10 — NEGATIVE CONTROL ON THE HARNESS: drive ck wrong in a subshell and
#          require FAIL to appear, or every OK above proves nothing.
probe=$( PASS=0; FAIL=0; ck "probe" 99 0 2>&1 )
case "$probe" in *FAIL*) PASS=$((PASS+1)); say "OK  " "ARM10 harness DISCRIMINATES" ;;
                 *) FAIL=$((FAIL+1)); say "FAIL" "ARM10 harness reported [$probe]" ;; esac

echo "capcheck_selftest: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
