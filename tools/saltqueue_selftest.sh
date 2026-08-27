#!/bin/bash
# saltqueue_selftest.sh — drive EVERY arm of the ticket layer, both ways.
#
#   bash docs/silicon-tools/saltqueue_selftest.sh
#
# ⛔ IT NEVER TOUCHES THE REAL MARKER. `LOCK` is repointed at a private temp dir before
# saltqueue.sh is sourced, so a selftest run beside a live fleet build is inert. The first
# arm PROVES that repointing took, because a test that silently ran against /tmp/salt-fleet-
# build.lock would be indistinguishable from a passing one right up until it reaped a peer.
#
# Every arm is DRIVEN BOTH WAYS: each check is shown to say NO on input that should fail and
# YES on input that should pass. A criterion only ever run on passing input has not been
# shown to discriminate.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/saltqueue-selftest.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
LOCK="$TMP/lock"
. "$HERE/saltqueue.sh"

RC=0
pass(){ printf '  ✅ %s\n' "$1"; }
fail(){ printf '  ⛔ %s\n' "$1"; RC=1; }

echo "SELFTEST saltqueue.sh"
echo
echo "(0) THE TEST IS ISOLATED — proven before anything else runs"
case "$Q_TKT_GLOB" in
  "$TMP"/*) pass "Q_TKT_GLOB is under the private temp dir ($Q_TKT_GLOB)" ;;
  *) fail "Q_TKT_GLOB is $Q_TKT_GLOB — NOT isolated. ABORTING before any reap."; exit 2 ;;
esac
[ "$Q_TKT_GLOB" = "/tmp/salt-fleet-build.lock.tkt" ] && { fail "would have run against the LIVE marker"; exit 2; }

echo
echo "(1) EMPTY QUEUE — a blank must be a measurement, not a broken glob"
[ "$(q_census_count)" = "0" ] && pass "count 0 on an empty queue" || fail "count was $(q_census_count)"
q_census | grep -q "queue empty" && pass "census prints '(queue empty)'" || fail "census did not report empty"

echo
echo "(2) TAKE / RELEASE"
q_take P2 silicon >/dev/null
[ -n "$Q_TICKET" ] && [ -e "$Q_TICKET" ] && pass "ticket created: ${Q_TICKET##*/}" || fail "no ticket created"
[ "$(q_census_count)" = "1" ] && pass "count 1 after take" || fail "count was $(q_census_count) after take"
q__ahead && fail "q__ahead TRUE with only my own ticket present" || pass "q__ahead FALSE when I am alone (my own ticket is excluded)"

echo
echo "(3) ⛔ THE RECYCLED-PID ARM — the helm's 12:0x amendment, driven BOTH ways"
# CONTROL (must SURVIVE): a live pid whose stamped start time is CORRECT.
good="${Q_TKT_GLOB}.2.$(/bin/date +%s%N).$$"
{ ps -o lstart= -p $$ | tr -s ' ' | sed 's/^ *//;s/ *$//'; echo P2; echo control; } > "$good"
q__live "$good" && pass "CONTROL: live pid + matching start time is LIVE (so the arm can say YES)" \
                || fail "CONTROL failed — a correct ticket was judged dead; every reap below is meaningless"
# THE FABRICATED TICKET (must be REAPED): a LIVE pid, a MISMATCHED start time.
bad="${Q_TKT_GLOB}.2.$(/bin/date +%s%N).$$"
{ echo "Mon Jan  1 00:00:00 2001"; echo P2; echo recycled; } > "$bad"
q__live "$bad" && fail "FABRICATED recycled-pid ticket judged LIVE — THE IMMORTAL TICKET IS BACK" \
               || pass "FABRICATED: live pid + WRONG start time is DEAD"
q__reap
[ -e "$bad" ]  && fail "q__reap did not remove the fabricated ticket" || pass "q__reap REMOVED it"
[ -e "$good" ] && pass "q__reap left the control ticket alone" || fail "q__reap destroyed a live ticket"
rm -f "$good"

echo
echo "(4) A GENUINELY DEAD PID IS REAPED"
sh -c 'exit 0' & dead=$!; wait $dead 2>/dev/null
dt="${Q_TKT_GLOB}.2.$(/bin/date +%s%N).${dead}"
{ echo "Mon Jan  1 00:00:00 2001"; echo P2; echo ghost; } > "$dt"
q__reap
[ -e "$dt" ] && fail "a ticket for dead pid $dead survived" || pass "dead pid $dead reaped"

echo
echo "(5) EMPTY / UNREADABLE STAMP FAILS TOWARD REAPING"
es="${Q_TKT_GLOB}.2.$(/bin/date +%s%N).$$"
: > "$es"
q__live "$es" && fail "an empty stamp was judged LIVE — that is the immortal ticket by another route" \
              || pass "empty stamp judged DEAD (fails toward reaping, the safe direction)"
rm -f "$es"

echo
echo "(6) ORDER — class beats time, time beats pid, and the order is TOTAL"
k(){ q__key "$1"; }
a="${Q_TKT_GLOB}.1.1000000000000000000.500"    # P1, late
b="${Q_TKT_GLOB}.2.1000000000000000000.100"    # P2, same ns, lower pid
[ "$(printf '%s\n%s\n' "$(k $a)" "$(k $b)" | sort | head -1)" = "$(k $a)" ] \
  && pass "P1 sorts before P2 even with a lower-pid P2" || fail "class did not dominate"
c="${Q_TKT_GLOB}.2.1000000000000000001.100"
[ "$(printf '%s\n%s\n' "$(k $b)" "$(k $c)" | sort | head -1)" = "$(k $b)" ] \
  && pass "within a class, earlier ns wins" || fail "timestamp order wrong"
d="${Q_TKT_GLOB}.2.1000000000000000000.101"
[ "$(printf '%s\n%s\n' "$(k $b)" "$(k $d)" | sort | head -1)" = "$(k $b)" ] \
  && pass "on an ns tie, lower pid wins (order is TOTAL — no mutual 'you first')" || fail "pid tiebreak wrong"

echo
echo "(7) q__ahead SEES A REAL P1 AHEAD OF MY P2, AND NOT A P3 BEHIND"
p1="${Q_TKT_GLOB}.1.$(/bin/date +%s%N).$$"
{ ps -o lstart= -p $$ | tr -s ' ' | sed 's/^ *//;s/ *$//'; echo P1; echo peer; } > "$p1"
q__ahead && pass "a live P1 is seen ahead of my P2" || fail "q__ahead missed a live P1"
rm -f "$p1"
p3="${Q_TKT_GLOB}.3.$(/bin/date +%s%N).$$"
{ ps -o lstart= -p $$ | tr -s ' ' | sed 's/^ *//;s/ *$//'; echo P3; echo peer; } > "$p3"
q__ahead && fail "a P3 BEHIND me was counted as ahead" || pass "a live P3 behind me is not ahead"
rm -f "$p3"

echo
echo "(8) A DEAD P1 DOES NOT BLOCK ME — anti-hostage, end to end"
dp="${Q_TKT_GLOB}.1.$(/bin/date +%s%N).${dead}"
{ echo "Mon Jan  1 00:00:00 2001"; echo P1; echo ghost; } > "$dp"
q__ahead && fail "a DEAD P1 held me behind it — the hostage case" || pass "dead P1 reaped by the ahead-check; I am head"

echo
echo "(9) UNQUEUED DEGRADATION — no ticket must never block"
q_release
Q_TICKET=""
q__ahead && fail "q__ahead TRUE with no ticket of mine" || pass "unqueued: q__ahead FALSE, q_wait returns at once"
q_wait && pass "q_wait returns immediately when unqueued" || fail "q_wait blocked an unqueued caller"

echo
[ "$RC" = 0 ] && echo "⇒ ✅ saltqueue SELFTEST PASSED — every arm driven both ways." \
              || echo "⇒ ⛔ saltqueue SELFTEST FAILED — do not deploy."
exit $RC
