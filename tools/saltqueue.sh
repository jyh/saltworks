# saltqueue.sh — PRIORITY-AWARE BUILD QUEUE, ticket layer.  SOURCE THIS; do not execute it.
#
#   . saltqueue.sh
#   q_take P1|P2|P3 [seat]      write my ticket   (then: trap q_release EXIT INT TERM)
#   q_wait                      block until I am head of the queue
#   q_release                   remove my ticket
#   q_census                    print the queue: class · age · seat · pid
#
# silicon seat, 2026-08-27. Commissioned at the council (minute bc381f78); the recycled-pid
# amendment below is the helm's 12:0x amendment, filed under this seat's catch.
#
# ══ WHAT THIS IS, AND THE ONE SENTENCE THAT IS THE WHOLE ARCHITECTURE ═════════════════
# The ticket layer sits ABOVE `flock`+`mkdir` and TOUCHES NEITHER. Tickets decide who may
# ATTEMPT acquisition; the primitives still guarantee exclusion.
#
# ⭐ THE HEAD-OF-QUEUE TEST IS CHECK-THEN-ACT, AND THAT IS FINE, BECAUSE CORRECTNESS NEVER
#   DEPENDS ON TICKET ORDER. Between "I am head" and `flock`, a peer can acquire. `flock(2)`
#   still provides exclusion and the 43 GB memory law; the tickets buy only FAIRNESS. A lost
#   race costs ONE out-of-order acquisition, never two concurrent builds.
# ⛔ This is the one place silicon's banked law "check-then-act needs SERIALIZATION, never
#   re-verification" does NOT apply, and the distinction IS the design: that law is about a
#   race whose loss breaks a GUARANTEE. Here the guarantee is held by a different mechanism
#   and only a preference is racing. Do not "harden" this into a lock; it would buy nothing
#   and would touch the primitives the ruling says to leave alone.
#
# ⚠️ PARTIAL ADOPTION IS SAFE BY CONSTRUCTION, and it is why this is a SOURCED file:
#   a saltbuild copy that does not have this file beside it sources nothing, writes no
#   ticket and waits for none — it races exactly as it does today. FAIRNESS degrades;
#   exclusion and the memory law do not. That degradation is the one already ratified for
#   the 08/27 priority lane, so a half-deployed fleet is in a blessed state, not a novel one.
#
# ⛔⛔ WHY THE TICKET CARRIES A START TIME AND NOT JUST A PID — helm amendment 12:0x, and it
#   is load-bearing rather than belt-and-braces. The ruling says dead tickets are reaped by
#   pid and there is NO WAIT-TIMEOUT, which moves the whole anti-hostage duty INTO reaping.
#   `kill -0 <pid>` succeeds for ANY live process the invoking user owns. So a RECYCLED PID
#   makes a dead ticket look alive FOREVER — and with no timeout, that is precisely the
#   hostage the no-timeout rule assumed reaping made impossible. A ticket is therefore live
#   iff the pid is alive AND its process START TIME still matches the one stamped at
#   creation. `saltqueue_selftest.sh` FABRICATES that exact ticket (live pid, wrong start
#   time) and requires it to be reaped — a check only ever run on passing input has not been
#   shown to discriminate.
#
# ⚠️ NO AGING, BY RULING. A P2 behind a steady P1 stream can wait indefinitely BY DESIGN —
#   that is the planning property, not a defect. ripens-when = observed starvation hurting.
# ⚠️ NO WAIT-TIMEOUT, BY RULING. This REMOVES the old lane's MAXWAIT yield-break: today a
#   yielding build gives up after MAXWAIT and acquires; under the queue it waits for the
#   queue. Named here because it is a behaviour change to a running mechanism.

# ⛔ `=`, NOT `:=` (census D, D15, 2026-09-13): an EMPTY LOCK is a caller whose override failed, and `:=` pointed
#   its tickets at the FLEET queue. saltbuild.sh refuses an empty lock before sourcing this; a direct source must too.
: "${LOCK=/tmp/salt-fleet-build.lock}"
if [ -z "$LOCK" ]; then
  echo "saltqueue: LOCK is SET BUT EMPTY — refusing rather than ticketing into the FLEET queue" >&2
  return 76
fi
Q_TKT_GLOB="${LOCK}.tkt"
Q_TICKET=""

# Class → sort rank. Unknown classes sort LAST rather than crashing: a typo must not let a
# build jump the queue, and it must not wedge the fleet either.
q__rank() {
  case "$1" in
    P1) echo 1 ;;
    P2) echo 2 ;;
    P3) echo 3 ;;
    *)  echo 9 ;;
  esac
}

# The start-time stamp. Second resolution (`ps -o lstart=`) is ample: a pid recycled within
# the same second as its predecessor is not a case this defends against, and cannot be.
q__starttime() { ps -o lstart= -p "$1" 2>/dev/null | tr -s ' ' | sed 's/^ *//;s/ *$//'; }

q__now_ns() { /bin/date +%s%N; }

# A ticket is LIVE iff pid alive AND start time matches what was stamped. Anything else is
# reaped. Dead-ticket removal is the ONLY anti-hostage mechanism here (no timeout exists).
q__live() {
  local f="$1" pid st_now st_then
  pid="${f##*.}"
  [ -n "$pid" ] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  st_then="$(sed -n '1p' "$f" 2>/dev/null)"
  st_now="$(q__starttime "$pid")"
  # An unreadable/empty stamp is treated as DEAD. Failing toward reaping is right: a
  # spurious reap costs one out-of-order build; a spurious KEEP is the immortal ticket.
  [ -n "$st_then" ] && [ -n "$st_now" ] && [ "$st_then" = "$st_now" ]
}

q__reap() {
  local f
  for f in "${Q_TKT_GLOB}".*; do
    [ -e "$f" ] || continue
    q__live "$f" || rm -f "$f" 2>/dev/null
  done
  return 0
}

q_take() {
  local class="${1:-P2}" seat="${2:-${SELF:-${SEAT:-unknown}}}" ns
  ns="$(q__now_ns)"
  Q_TICKET="${Q_TKT_GLOB}.$(q__rank "$class").${ns}.$$"
  { q__starttime "$$"; echo "$class"; echo "$seat"; } > "$Q_TICKET" 2>/dev/null || {
    # A queue we cannot join must never block the build: degrade to today's race.
    echo "saltqueue: WARNING — could not write a ticket; proceeding UNQUEUED (exclusion unaffected)" >&2
    Q_TICKET=""; return 1; }
  echo "saltqueue: ticket $class seat=$seat pid=$$"
  # My own ticket exists now, so cancelling my seat's lease opens no gap (desk AGN).
  [ "$class" = P1 ] && q_lease_cancel "$seat"
  return 0
}

q_release() { [ -n "$Q_TICKET" ] && rm -f "$Q_TICKET" 2>/dev/null; Q_TICKET=""; return 0; }

# ══ THE P1 LEASE — desk AGN (systems, 2026-11-14) ═══════════════════════════════════════
# ⛔ MEASURED, NOT ARGUED: both P2 acquisitions over vir's P1 work on 11-13/14 (fleet lock log
#   23:39:20→23:39:44 and 00:28:10→00:29:29) fell in a GAP BETWEEN TWO P1 CALLS. A P1 campaign is
#   a CHAIN of saltbuild calls (build, audit, audit, edit or commit, again), each with its own
#   ticket, so between calls NO P1 ticket exists and a P2 polling q_wait wins any gap over ~5 s.
#   The queue was right about every ticket that existed; the class was simply not there.
# ⇒ A P1 that RELEASES leaves a LEASE: an ordinary rank-1 ticket whose pid is a detached `sleep TTL`
#   with fd 9 closed (it never holds the flock), class line `LEASE`. Because it IS a ticket, every
#   existing ticket reader honors it unchanged (a P2 here, and any reimplementation that treats a
#   live rank-1 ticket as ahead), and it dies by the ordinary reaper when the sleep ends.
#   A P1 caller SKIPS LEASE tickets (another seat's P1 never waits on one); the seat's next P1
#   cancels its own lease at q_take, after its own ticket exists, so there is no instant with neither.
# ⚠️ COST, stated: at a chain's END, P2/P3 idle up to TTL. Fairness only; exclusion is untouched.
Q_LEASE_CLASS=LEASE
Q_LEASE_MAX=600

q__class() { sed -n '2p' "$1" 2>/dev/null; }

# q_lease_cancel <seat>: kill and remove this seat's live LEASE tickets. The pid is killed only
# after q__live confirms pid AND start time, so a recycled pid is never signalled.
q_lease_cancel() {
  local seat="$1" f
  for f in "${Q_TKT_GLOB}".*; do
    [ -e "$f" ] || continue
    [ "$(q__class "$f")" = "$Q_LEASE_CLASS" ] || continue
    [ "$(sed -n '3p' "$f" 2>/dev/null)" = "$seat" ] || continue
    q__live "$f" && kill "${f##*.}" 2>/dev/null
    rm -f "$f" 2>/dev/null
  done
  return 0
}

# q_lease_write <seat> <ttl_s>: leave a rank-1 LEASE ticket for TTL seconds. Never fatal: any
# failure leaves no lease, which is today's behaviour. Prints Q_LEASE_PID on success.
Q_LEASE_PID=""
q_lease_write() {
  local seat="${1:-unknown}" ttl="${2:-0}" sp st f
  Q_LEASE_PID=""
  case "$ttl" in ''|*[!0-9]*) return 0 ;; esac
  [ "$ttl" -gt 0 ] || return 0
  [ "$ttl" -gt "$Q_LEASE_MAX" ] && ttl="$Q_LEASE_MAX"
  q_lease_cancel "$seat"
  # `exec` makes $! the sleeper itself (a bare subshell's $! is the subshell, not the job).
  ( exec sleep "$ttl" ) 9>&- </dev/null >/dev/null 2>&1 &
  sp=$!
  disown "$sp" 2>/dev/null || true   # not our job to reap or report: it outlives this shell by design
  st="$(q__starttime "$sp")"
  [ -n "$st" ] || { kill "$sp" 2>/dev/null; return 0; }
  f="${Q_TKT_GLOB}.1.$(q__now_ns).${sp}"
  { echo "$st"; echo "$Q_LEASE_CLASS"; echo "$seat"; } > "$f" 2>/dev/null || { kill "$sp" 2>/dev/null; return 0; }
  Q_LEASE_PID="$sp"
  return 0
}

# One line, the queue in order, EXCLUDING my own ticket: comma-separated CLASS:<name> pairs, or `-`. For the lock log.
q_order_line() {
  local f out=""
  for f in $(ls -1 "${Q_TKT_GLOB}".* 2>/dev/null | while read -r x; do printf '%s %s\n' "$(q__key "$x")" "$x"; done | sort | awk '{print $2}'); do
    [ -e "$f" ] || continue
    [ "$f" = "$Q_TICKET" ] && continue
    q__live "$f" || continue
    out="${out:+$out,}$(q__class "$f"):$(sed -n '3p' "$f" 2>/dev/null)"
  done
  printf '%s\n' "${out:--}"
}

# Is any LIVE ticket strictly ahead of mine? Total order: rank, then ns, then pid — so two
# waiters can never each believe the other is ahead. A P1 skips LEASE tickets (see above).
q__ahead() {
  local f mine_key other_key mine_rank
  [ -n "$Q_TICKET" ] || return 1
  mine_key="$(q__key "$Q_TICKET")"
  mine_rank="${mine_key%%|*}"
  for f in "${Q_TKT_GLOB}".*; do
    [ -e "$f" ] || continue
    [ "$f" = "$Q_TICKET" ] && continue
    q__live "$f" || { rm -f "$f" 2>/dev/null; continue; }
    [ "$mine_rank" = 1 ] && [ "$(q__class "$f")" = "$Q_LEASE_CLASS" ] && continue
    other_key="$(q__key "$f")"
    [ "$(printf '%s\n%s\n' "$mine_key" "$other_key" | sort | head -1)" = "$other_key" ] && return 0
  done
  return 1
}

# Zero-padded so a lexical sort IS the numeric order (ns is 19 digits, pid up to 10).
q__key() {
  local b="${1##*/}" rest rank ns pid
  rest="${b#*.tkt.}"
  rank="${rest%%.*}"; rest="${rest#*.}"
  ns="${rest%%.*}";   pid="${rest#*.}"
  printf '%s|%019d|%010d' "$rank" "$ns" "$pid"
}

# ⛔ AHEAD-OF-ME, not ALL-LIVE. `q_census_count` counts every live ticket INCLUDING THE
# CALLER'S OWN, so the queue message read "QUEUED behind 2 ticket(s)" with exactly ONE
# waiter ahead — measured 2026-08-27 13:47 in the run that first demonstrated ordering.
# The sentence says "behind N", so N must exclude self and everything sorting after me.
q__ahead_count() {
  local f n=0
  [ -n "$Q_TICKET" ] || { echo 0; return 0; }
  local mine; mine="$(q__key "$Q_TICKET")"
  for f in "${Q_TKT_GLOB}".*; do
    [ -e "$f" ] || continue
    [ "$f" = "$Q_TICKET" ] && continue
    q__live "$f" || continue
    [ "${mine%%|*}" = 1 ] && [ "$(q__class "$f")" = "$Q_LEASE_CLASS" ] && continue
    [ "$(printf '%s\n%s\n' "$mine" "$(q__key "$f")" | sort | head -1)" = "$(q__key "$f")" ] && n=$((n+1))
  done
  echo "$n"
}

q_wait() {
  local waited=0
  [ -n "$Q_TICKET" ] || return 0
  q__reap
  while q__ahead; do
    [ "$waited" = 0 ] && echo "saltqueue: QUEUED behind $(q__ahead_count) ticket(s) — waiting (no timeout, by ruling)"
    sleep 5; waited=$((waited+5))
    [ $((waited % 300)) -eq 0 ] && { echo "saltqueue: still queued (${waited}s) —"; q_census; }
  done
  [ "$waited" -gt 0 ] && echo "saltqueue: HEAD OF QUEUE after ${waited}s — attempting acquisition"
  return 0
}

q_census_count() {
  local f n=0
  for f in "${Q_TKT_GLOB}".*; do [ -e "$f" ] || continue; q__live "$f" && n=$((n+1)); done
  echo "$n"
}

# The legible build schedule. Reaps as it reads, so the census can never show a dead ticket.
q_census() {
  local f now age cls seat pid found=0
  now="$(q__now_ns)"
  printf '  %-6s %-10s %-12s %s\n' CLASS AGE SEAT PID
  for f in $(ls -1 "${Q_TKT_GLOB}".* 2>/dev/null | while read -r x; do printf '%s %s\n' "$(q__key "$x")" "$x"; done | sort | awk '{print $2}'); do
    [ -e "$f" ] || continue
    q__live "$f" || { rm -f "$f" 2>/dev/null; continue; }
    pid="${f##*.}"
    cls="$(sed -n '2p' "$f" 2>/dev/null)"; seat="$(sed -n '3p' "$f" 2>/dev/null)"
    age=$(( (now - $(q__key "$f" | cut -d'|' -f2 | sed 's/^0*//')) / 1000000000 ))
    printf '  %-6s %-10s %-12s %s\n' "${cls:-?}" "${age}s" "${seat:-?}" "$pid"
    found=1
  done
  [ "$found" = 0 ] && echo "  (queue empty)"
  return 0
}
