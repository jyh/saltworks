#!/bin/bash
# saltbuild-lease-test.sh — THE P1 LEASE, end to end (desk AGN, systems, 2026-11-14).
#
# THE MEASURED SHAPE (fleet lock log, 11-13 23:39:20→23:39:44 and 11-14 00:28:10→00:29:29): a P1 campaign is a CHAIN of
# saltbuild calls, and a P2 waiting in q_wait took the lock in the GAP between two of them, when no P1 ticket existed.
# Every lock, log, audit log and queue lives under a scratch dir (SALTBUILD_LOCK / _LOCKLOG / _AUDITLOG seams) and lake is a
# STUB under a scratch HOME (saltbuild calls ~/.elan/bin/lake by absolute path), so nothing builds and nothing touches the
# fleet lock. Stated direction for each arm FIRST; RED on the pre-lease wrapper where marked.
#   L1  the chain: holder H (P2), W1 and W2 (P2) queued, P1a, a GAP longer than q_wait's 5 s poll, then P1b.
#       Expected: P1b acquires before W1 and W2.                                          (RED on the pre-lease wrapper)
#   L2  the lock log carries a LEASE line for each P1 release, class= on WAIT-START, and queue= on RELEASED.   (RED pre-lease)
#   L3  a P1 of ANOTHER seat is not held by the lease: it acquires at once on a free lock.                    (control)
#   L4  the lease ENDS: with no further P1, a waiting P2 acquires within TTL + 7 s of the P1's release.        (control)
#   L5  SALTBUILD_P1_LEASE=0 writes no lease (the off switch), and a non-number is refused toward 0 and SAID.
#   L6  the sleeper never holds the flock: right after a P1 release the flock is free while the lease lives.
#   L7  a P1 stopped by SIGTERM leaves NO lease (a cancelled P1 is a seat stopping, not a chain continuing).
#   L8  a CRASHED P1 (SIGKILL) leaves no lease: a P2 behind it runs within seconds (the helm's WRONG-IF, 11-14 01:38).
#   L9  no lease outlives its cap: a huge SALTBUILD_P1_LEASE is clamped to Q_LEASE_MAX (600 s).
set -u
SB="${1:-$(cd "$(dirname "$0")" && pwd)/saltbuild.sh}"
FLOCK="$(command -v flock)" || { echo "SKIP: no flock(1) on PATH — saltbuild itself refuses to run here"; exit 3; }
TD="$(mktemp -d "${TMPDIR:-/tmp}/sb-lease.XXXXXX")"
pass=0; fail=0
ok(){ printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }
cleanup(){
  # kill only sleepers WE leased: each lease ticket under TD names its pid; verify the command is a sleep first
  for f in "$TD"/*/lock.tkt.*; do [ -e "$f" ] || continue; p="${f##*.}"
    case "$(ps -p "$p" -o command= 2>/dev/null)" in sleep*) kill "$p" 2>/dev/null ;; esac; done
  rm -rf -- "${TD:?}"
}
trap cleanup EXIT
H="$TD/home"; mkdir -p "$H/.elan/bin"
printf '#!/bin/bash\necho "$(date +%%s) START ${SEAT:-?} $$" >> "$STUB_ORDER"\nsleep "${STUB_SLEEP:-3}"\nexit 0\n' > "$H/.elan/bin/lake"
chmod +x "$H/.elan/bin/lake"
case "$TD" in /tmp/salt-fleet-build.lock*) echo "REFUSE: scratch dir is the fleet lock" >&2; exit 2 ;; esac

# go <dir> <seat> <class> <sleep> [env...] — one wrapper run in the foreground
go(){ local d="$1" seat="$2" cls="$3" sl="$4"; shift 4
  ( cd "$d/repo" && env HOME="$H" SALTBUILD_LOCK="$d/lock" SALTBUILD_LOCKLOG="$d/lock.log" \
      SALTBUILD_AUDITLOG="$d/audit.log" STUB_ORDER="$d/order" SEAT="$seat" PRIO="$cls" STUB_SLEEP="$sl" "$@" bash "$SB" ) \
      >> "$d/$seat.out" 2>&1; }
fresh(){ local d="$TD/$1"; mkdir -p "$d/repo"; : > "$d/order"; echo "$d"; }
order(){ sort -n "$1/order" | awk '{print $3}' | tr '\n' ' ' | sed 's/ $//'; }

echo "== L1 the chain — expect: H P1a P1b W1 W2"
d=$(fresh L1)
go "$d" H P2 8 & sleep 1
go "$d" W1 P2 2 & sleep 1
go "$d" W2 P2 2 & sleep 1
( go "$d" vir P1 2; sleep 8; go "$d" vir P1 2 ) &
wait
o="$(order "$d")"
[ "$o" = "H vir vir W1 W2" ] && ok "L1  P1b acquired before every waiting P2 (order: $o)" \
                              || no "L1  P1b acquired before every waiting P2" "order: $o"

echo "== L2 the lock log names it — expect: 2 LEASE lines, class= on every WAIT-START, queue= on every RELEASED"
nl=$(grep -c -F "	LEASE	" "$d/lock.log"); nw=$(grep -c -F "	WAIT-START	" "$d/lock.log")
nwc=$(grep -F "	WAIT-START	" "$d/lock.log" | grep -c -F "	class=")
nr=$(grep -c -F "	RELEASED	" "$d/lock.log"); nrq=$(grep -F "	RELEASED	" "$d/lock.log" | grep -c -F "	queue=")
[ "$nl" = 2 ] && ok "L2a two P1 releases logged two LEASE lines" || no "L2a two LEASE lines" "got $nl"
[ "$nw" -ge 5 ] && [ "$nwc" = "$nw" ] && ok "L2b class= on all $nw WAIT-START lines" || no "L2b class= on WAIT-START" "$nwc of $nw"
[ "$nr" = 5 ] && [ "$nrq" = 5 ] && ok "L2c queue= on all 5 RELEASED lines" || no "L2c queue= on RELEASED" "$nrq of $nr"
grep -F "	RELEASED	" "$d/lock.log" | grep -F "seat=H	" | grep -q -F "queue=P1:vir,P2:W1,P2:W2" \
  && ok "L2d H's release names the order it hands on: P1:vir,P2:W1,P2:W2" \
  || no "L2d H's release order" "$(grep -F "	RELEASED	" "$d/lock.log" | grep -F "seat=H	" | tr '\t' ' ')"

echo "== L3 another seat's P1 is not held by a lease — expect: acquires with waited=0s"
d=$(fresh L3)
go "$d" vir P1 1
go "$d" mojave P1 1
w=$(grep -F "	ACQUIRED	" "$d/lock.log" | grep -F "seat=mojave	" | tr '\t' '\n' | grep -F waited=)
case "$w" in waited=0s|waited=1s) ok "L3  mojave's P1 acquired at once under vir's lease ($w)" ;; *) no "L3  mojave's P1 at once" "$w" ;; esac

echo "== L4 the lease ends — expect: a P2 queued under a 6 s lease acquires within 6 + 7 s of the P1 release"
d=$(fresh L4)
go "$d" vir P1 1 SALTBUILD_P1_LEASE=6
t0=$(date +%s); go "$d" math P2 1; t1=$(date +%s)
[ $((t1 - t0)) -ge 4 ] && [ $((t1 - t0)) -le 15 ] && ok "L4  the P2 waited for the lease and then ran ($((t1 - t0)) s, incl. its 1 s build)" \
                                                 || no "L4  P2 bounded by TTL" "$((t1 - t0)) s"

echo "== L5 the off switch — expect: no LEASE line at 0, and a refusal line for a non-number"
d=$(fresh L5)
go "$d" vir P1 1 SALTBUILD_P1_LEASE=0
go "$d" vir P1 1 SALTBUILD_P1_LEASE=2m
[ "$(grep -c -F "	LEASE	" "$d/lock.log")" = 0 ] && ok "L5a SALTBUILD_P1_LEASE=0 and =2m leave no lease" || no "L5a no lease" "$(grep -c -F "	LEASE	" "$d/lock.log") LEASE lines"
grep -q -F "SALTBUILD_P1_LEASE='2m' is not a whole number" "$d/vir.out" && ok "L5b a non-number is SAID, not guessed" || no "L5b refusal line" "$(tail -3 "$d/vir.out")"

echo "== L6 the sleeper never holds the flock — expect: flock free at once while the lease is live"
d=$(fresh L6)
go "$d" vir P1 1 SALTBUILD_P1_LEASE=30
lt=$(ls "$d"/lock.tkt.1.* 2>/dev/null | head -1)
[ -n "$lt" ] && [ "$(sed -n 2p "$lt")" = LEASE ] && ok "L6a a live LEASE ticket exists after the release" || no "L6a LEASE ticket" "none"
"$FLOCK" -n "$d/lock.flk" true && ok "L6b the flock is FREE while the lease lives (fd 9 closed in the sleeper)" || no "L6b flock free" "held"

echo "== L7 a SIGTERM'd P1 leaves no lease"
d=$(fresh L7)
( cd "$d/repo" && exec env HOME="$H" SALTBUILD_LOCK="$d/lock" SALTBUILD_LOCKLOG="$d/lock.log" SALTBUILD_AUDITLOG="$d/audit.log" \
    STUB_ORDER="$d/order" SEAT=vir PRIO=P1 STUB_SLEEP=30 bash "$SB" ) > "$d/vir.out" 2>&1 &
wp=$!; k=0; while [ ! -s "$d/order" ] && [ "$k" -lt 100 ]; do sleep 0.1; k=$((k+1)); done
kill -TERM "$wp"; wait "$wp" 2>/dev/null
[ "$(grep -c -F "	RELEASED	" "$d/lock.log")" = 1 ] && [ "$(grep -c -F "	LEASE	" "$d/lock.log")" = 0 ] \
  && ok "L7  released, and NO lease after SIGTERM" || no "L7  no lease after SIGTERM" "$(cut -f2 "$d/lock.log" | tr '\n' ' ')"

echo "== L8 a CRASHED P1 (SIGKILL, no trap runs) leaves no lease — expect: a P2 behind it acquires within 7 s of the kill"
d=$(fresh L8)
( cd "$d/repo" && exec env HOME="$H" SALTBUILD_LOCK="$d/lock" SALTBUILD_LOCKLOG="$d/lock.log" SALTBUILD_AUDITLOG="$d/audit.log" \
    STUB_ORDER="$d/order" SEAT=vir PRIO=P1 STUB_SLEEP=30 bash "$SB" ) > "$d/vir.out" 2>&1 &
wp=$!; k=0; while [ ! -s "$d/order" ] && [ "$k" -lt 100 ]; do sleep 0.1; k=$((k+1)); done
go "$d" math P2 1 & mp=$!; sleep 1
t0=$(date +%s); kill -KILL "$wp"; wait "$mp"; t1=$(date +%s)
[ "$(grep -c -F "	LEASE	" "$d/lock.log")" = 0 ] && [ $((t1 - t0)) -le 9 ] && grep -q -F "START math" "$d/order" \
  && ok "L8  no lease after SIGKILL; the P2 ran $((t1 - t0)) s after the kill (incl. its 1 s build)" \
  || no "L8  crashed P1 frees the lock" "$((t1 - t0)) s, LEASE lines $(grep -c -F "	LEASE	" "$d/lock.log")"

echo "== L9 a lease cannot outlive its cap — expect: SALTBUILD_P1_LEASE=99999 leases a sleep of 600 s"
d=$(fresh L9)
go "$d" vir P1 1 SALTBUILD_P1_LEASE=99999
lt=$(ls "$d"/lock.tkt.1.* 2>/dev/null | head -1); sc="$( [ -n "$lt" ] && ps -p "${lt##*.}" -o command= 2>/dev/null)"
[ "$sc" = "sleep 600" ] && ok "L9  the sleeper is '$sc' (clamped)" || no "L9  clamp to 600" "sleeper command: '$sc'"

echo "RESULT pass=$pass fail=$fail"
[ "$fail" = 0 ]
