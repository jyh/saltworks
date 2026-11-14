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
echo "(10) THE P1 LEASE (desk AGN) — each arm states its direction; RED on the pre-lease file"
if ! command -v q_lease_write >/dev/null 2>&1; then
  fail "q_lease_write is not defined — this saltqueue.sh has no P1 lease"
else
  q_take P2 math >/dev/null
  q_lease_write vir 30
  lf="$(ls "${Q_TKT_GLOB}".1.* 2>/dev/null | head -1)"
  [ -n "$lf" ] && [ "$(sed -n 2p "$lf")" = LEASE ] && [ "${lf##*.}" = "$Q_LEASE_PID" ] \
    && pass "a lease is a rank-1 ticket, class LEASE, pid = its sleeper" || fail "no rank-1 LEASE ticket (got: ${lf:-none})"
  q__live "$lf" && pass "the lease ticket is LIVE by the ordinary pid+start-time test" || fail "the lease ticket is judged dead"
  q__ahead && pass "EXPECT ahead: a lease holds my P2 back" || fail "a P2 did NOT see the lease ahead — the gap stays open"
  [ "$(q_order_line)" = "LEASE:vir" ] && pass "q_order_line lists the lease and excludes my own ticket" || fail "q_order_line read '$(q_order_line)'"
  q_release
  q_take P1 mojave >/dev/null
  q__ahead && fail "another seat's P1 waited on vir's lease" || pass "EXPECT not ahead: another seat's P1 skips the lease"
  [ -e "$lf" ] && pass "...and mojave's q_take P1 did NOT cancel vir's lease" || fail "mojave's P1 cancelled vir's lease"
  q_release
  sp="${lf##*.}"
  q_take P1 vir >/dev/null
  [ -e "$lf" ] && fail "vir's next P1 left its own lease in place" || pass "EXPECT gone: vir's next P1 cancelled its own lease at q_take"
  sleep 0.3; kill -0 "$sp" 2>/dev/null && fail "the lease sleeper $sp is still alive after the cancel" || pass "...and its sleeper is dead"
  q_release
  q_lease_write vir 1; lf="$(ls "${Q_TKT_GLOB}".1.* 2>/dev/null | head -1)"
  q_take P2 math >/dev/null; sleep 2
  q__ahead && fail "an EXPIRED lease still held a P2 — a lease outliving its TTL" || pass "EXPECT not ahead: an expired lease (TTL 1 s) is reaped"
  q_release
  q_lease_write vir 0;  [ -z "$Q_LEASE_PID" ] && pass "TTL 0 writes no lease (the off switch)" || fail "TTL 0 wrote a lease"
  q_lease_write vir 2m; [ -z "$Q_LEASE_PID" ] && pass "a non-number writes no lease" || fail "TTL '2m' wrote a lease"
  q_lease_write vir 99999
  [ "$(ps -p "$Q_LEASE_PID" -o command= 2>/dev/null)" = "sleep $Q_LEASE_MAX" ] && pass "TTL is clamped to Q_LEASE_MAX ($Q_LEASE_MAX s)" \
    || fail "TTL not clamped: '$(ps -p "$Q_LEASE_PID" -o command= 2>/dev/null)'"
  q_lease_cancel vir
fi

echo
[ "$RC" = 0 ] && echo "⇒ ✅ saltqueue SELFTEST PASSED — every arm driven both ways." \
              || echo "⇒ ⛔ saltqueue SELFTEST FAILED — do not deploy."
exit $RC
