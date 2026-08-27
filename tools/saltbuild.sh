#!/bin/bash
# FLEET BUILD/AUDIT WRAPPER — the ONLY sanctioned way to run lake OR lean.
#   ../saltbuild.sh                    # full build of the cwd repo
#   ../saltbuild.sh Salt.HB.Foo        # targeted build
#   ../saltbuild.sh ScratchX.lean      # audit run (lake env lean file)
#   ../saltbuild.sh --cap 100 X.lean   # audit run with a custom -M cap (MB)
# One heavy job fleet-wide (atomic lock, stale-reaped), threads capped.
# SELF-RECORDING (8/8, silicon's proposal, maestro-landed): every run
# appends one line to $AUDITLOG — timestamp, cwd, args, source sha
# (file mode), repo HEAD, EXIT. Logging is best-effort and can never
# change the exit code. The log is the replayable record that a given
# audit RAN on given bytes — green-exit-≠-verification's paper trail.
LOCK=/tmp/salt-fleet-build.lock
AUDITLOG=/Users/jyh/projects/claude/.saltbuild-audit.log
MAXWAIT=5400
# ══ THE LOCK: KERNEL-HELD, SO THERE IS NO CHECK-THEN-ACT WINDOW ANYWHERE ══════════
# ⛔ WHAT THIS REPLACES AND WHY. The previous design was `mkdir` + a REAPER that deleted
# a lock whose pid failed `kill -0`. Every version of that reaper is check-then-act: you
# READ the pid, JUDGE it dead, and only THEN remove — and the directory can be REPLACED
# in between. Measured 2026-08-25 over 150 trials each:
#     unguarded            6/150 clobbered a LIVE holder
#     re-verify guarded    1/150            <- a MITIGATION, not a fix
# Re-verification only moves the window from judge->act to reverify->act. It cannot close
# it, because "check the pid" and "remove the dir" are two acts. ONE surviving clobber is
# an existence proof and needs no statistics.
#
# ⭐ THE FIX IS NOT A BETTER CHECK — IT IS A PRIMITIVE THAT NEEDS NO CHECK.
# `flock(2)` is held by the KERNEL against an open file descriptor. Measured on this
# machine: a holder killed with SIGKILL — no trap, no cleanup, no code of ours able to
# run — had its lock released by the kernel and the next acquirer proceeded immediately.
#   ⇒ THERE IS NO SUCH THING AS A STALE flock. No stale lock ⇒ NO REAPER ⇒ no
#     check-then-act ⇒ the entire defect class is gone rather than narrowed.
# This also strictly improves the old failure mode: under the reaper, a SIGKILLed holder
# left a lock that survived until somebody judged it dead. Here it never exists.
#
# ⚠️ THE DIRECTORY STAYS, AND THAT IS DELIBERATE. Peers, and this seat's own probes, ask
# `[ -d /tmp/salt-fleet-build.lock ]` to see whether a build is running. Moving the lock
# to a file would leave every one of those probes reporting FREE forever — silently, and
# fleet-wide. So the DIRECTORY IS NOW A MARKER and the flock is the AUTHORITY.
#   ⇒ The marker is best-effort and its staleness is HARMLESS: it cannot cause a double
#     build, because the kernel decides. `rm -rf` on it below is safe precisely because
#     we already hold the flock, so no other builder can be in this region at all.
# ╔══ PRIORITY LANE — COUNCIL 2026-08-27 (item: PRIORITY LANE, mechanical) ═══════
# RULED: until Sept 7, tape-out-campaign builds SKIP THE QUEUE (acquire next).
#        ⛔ NO PREEMPTION — a holder always finishes.
#        Hold semantics and ACQUISITION PRIMITIVES UNTOUCHED.
#        EXPIRES Sept 8 BY ITS OWN TEXT; pure FIFO returns.
#
# HOW THIS OBEYS "PRIMITIVES UNTOUCHED": it adds NO lock, changes NO flock/mkdir call,
# and touches neither release() nor the hold. It is a PRE-ACQUISITION YIELD: a normal
# build waits, BEFORE it begins acquiring, while a live tape-out build is waiting. The
# acquisition sequence below is byte-identical to what it was.
#
# ⚠️⚠️ SCOPE OF WHAT THIS BUYS, STATED BECAUSE THE RULING SAYS "ACQUIRE NEXT" AND THIS
# DELIVERS SOMETHING WEAKER: a normal build ALREADY BLOCKED INSIDE `flock -w` cannot see
# the marker — flock blocks in the kernel — so it is not displaced and may take the next
# slot. This lane biases the queue AT ENTRY; it does not guarantee "next" against a
# builder already in line. ***THE STRICT GUARANTEE REQUIRES CHANGING THE ACQUISITION CALL
# (a polling flock), WHICH THE RULING FORBIDS.*** Registered, not built: if the helm wants
# strict "acquire next", that is the one-line change and it needs their word.
#
# ⚠️ AND THE BASELINE IS NOT FIFO. The ruling says "everything else remains FIFO behind
# the lane"; measured at the object, this lock is a RACE, not a queue — flock(2) wakes
# waiters in unspecified order and the interop-marker loop is a 5 s poll. Nothing here
# makes it worse, and nothing here makes it FIFO. Naming it so the word is not inherited.
#
# ⚠️ PARTIAL ADOPTION IS SAFE BY CONSTRUCTION: a copy that has not pulled this simply does
# not yield — it races as before. Priority degrades; exclusion and the 43 GB law do not.
LANE_EXPIRES=20260908                 # first day the lane is OFF, per the ruling's own text
LANE_ACTIVE=0
[ "$(date +%Y%m%d)" -lt "$LANE_EXPIRES" ] && LANE_ACTIVE=1
PRIO_GLOB="${LOCK}.prio"
prio_clear() { rm -f "${PRIO_GLOB}.$$" 2>/dev/null; return 0; }
# A live tape-out waiter = a prio file whose pid is alive. Dead ones are reaped, so a
# crashed tape-out build cannot hold the fleet hostage.
prio_live() {
  local f pid found=1
  for f in "${PRIO_GLOB}".*; do
    [ -e "$f" ] || continue
    pid="${f##*.}"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then found=0
    else rm -f "$f" 2>/dev/null; fi
  done
  return $found
}

if [ "${TAPEOUT:-0}" = "1" ] && [ "$LANE_ACTIVE" = "1" ]; then
  : > "${PRIO_GLOB}.$$" 2>/dev/null
  trap prio_clear EXIT INT TERM
  echo "saltbuild: PRIORITY LANE — tape-out build, normal builds will yield at entry (lane expires $LANE_EXPIRES)"
elif [ "${TAPEOUT:-0}" = "1" ]; then
  echo "saltbuild: PRIORITY LANE EXPIRED ($(date +%Y%m%d) >= $LANE_EXPIRES) — running as an ordinary build, pure FIFO"
elif [ "$LANE_ACTIVE" = "1" ]; then
  YIELDED=0
  while prio_live; do
    if [ "$YIELDED" -ge "$MAXWAIT" ]; then
      echo "saltbuild: yielded ${YIELDED}s to the priority lane and STOPPED YIELDING (MAXWAIT) — acquiring normally."
      break
    fi
    [ "$YIELDED" = 0 ] && echo "saltbuild: YIELDING at entry — a tape-out build is waiting (priority lane, council 08/27)"
    sleep 5; YIELDED=$((YIELDED+5))
    [ $((YIELDED % 300)) -eq 0 ] && echo "saltbuild: still yielding to the priority lane (${YIELDED}s)"
  done
fi
# ╚══ END PRIORITY LANE — the acquisition below is UNCHANGED ═════════════════════

LOCKFILE="${LOCK}.flk"
FLOCK="$(command -v flock 2>/dev/null || true)"
if [ -z "$FLOCK" ]; then
  # ⛔ REFUSE, never fall back. A fallback here would silently reinstate the exact
  # check-then-act reaper this design exists to delete, and it would do it on the one
  # box where nobody is looking. Loud beats subtly-unsafe.
  echo "saltbuild EXIT=76 (NO flock(1) ON PATH: the fleet lock cannot be held safely; refusing to fall back to the reaper form)" >&2
  exit 76
fi
exec 9>"$LOCKFILE" || { echo "saltbuild EXIT=76 (cannot open $LOCKFILE)" >&2; exit 76; }
if ! "$FLOCK" -w "$MAXWAIT" 9; then
  echo "saltbuild EXIT=75 (LOCK-WAIT ABORT: the build NEVER STARTED - this is NOT a build failure; RETRY the same command)"
  exit 75
fi
# ⛔⛔ WE NOW HOLD THE FLOCK, WHICH EXCLUDES EVERY *NEW* WRAPPER — AND NOTHING ELSE.
# A wrapper that has not been pulled yet acquires by `mkdir "$LOCK"` and has never heard
# of the flock. The two mechanisms DO NOT EXCLUDE EACH OTHER, so during the migration
# window a new wrapper must hold BOTH or it will build straight through a live old one.
# ⇒ MEASURED THE HARD WAY 2026-08-26 00:30: an earlier cut of this file took the flock,
#   `rm -rf`-ed the marker directory, and ran a build while math's 41-minute build was
#   live — deleting their lock on the way in. Restored by hand. THE `rm -rf` IS GONE.
#   A NEW MECHANISM DOES NOT REPLACE AN OLD ONE UNTIL EVERY PEER RUNS THE NEW ONE; until
#   then it is an ADDITIONAL mechanism, and interop is the feature, not an afterthought.
# No deadlock: an old wrapper never waits on the flock, so it always makes progress and
# always releases the directory; a new wrapper waits for the directory while holding the
# flock, and other new wrappers wait on the flock behind it.
WAITED=0
until mkdir "$LOCK" 2>/dev/null; do
  # A directory left by a CRASHED holder must still be reapable, or one dead old wrapper
  # wedges the fleet. This reap is by ATOMIC CLAIM, not re-verification: `rename(2)` is
  # atomic, so exactly one reaper can ever hold the corpse; the pid is then re-read INSIDE
  # the claim we exclusively own, and a directory that turns out LIVE is PUT BACK. That
  # restore is what defeats the objection to the atomic form in the evidence filing — the
  # naive version renames away a live lock and never gives it back.
  claim_reap() {
    local pid claim
    pid="$(cat "$LOCK/pid" 2>/dev/null)"
    # A live holder is refused outright: we never move a live lock in the common case.
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 1; fi
    claim="$LOCK.reaping.$$"
    rm -rf "$claim" 2>/dev/null
    mv "$LOCK" "$claim" 2>/dev/null || return 1
    pid="$(cat "$claim/pid" 2>/dev/null)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      mv "$claim" "$LOCK" 2>/dev/null || rm -rf "$claim"
      return 1
    fi
    rm -rf "$claim"
    echo "saltbuild: reaped a marker whose holder (pid ${pid:-none}) is dead"
    return 0
  }
  claim_reap && continue
  if [ $WAITED -ge $MAXWAIT ]; then
    echo "saltbuild EXIT=75 (LOCK-WAIT ABORT on the interop marker, holder pid $(cat "$LOCK/pid" 2>/dev/null || echo '?'): the build NEVER STARTED - RETRY the same command)"
    exit 75
  fi
  sleep 5; WAITED=$((WAITED+5))
  [ $((WAITED % 300)) -eq 0 ] && echo "saltbuild: waiting on the fleet lock (${WAITED}s)"
done
echo $$ > "$LOCK/pid"
prio_clear   # we hold; drop our lane marker before the release trap takes over
# The trap releases only the MARKER. The flock needs no trap: the kernel drops it when
# this process and every descendant holding fd 9 is gone. Ownership-guarded because a trap
# fires at signal-delivery AND again at exit (6/6 ate a new holder's marker unguarded).
release() { [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ] && rm -rf "$LOCK"; return 0; }
trap release EXIT INT TERM
export LEAN_NUM_THREADS=4
CAP=24000
if [ "$1" = "--cap" ]; then CAP="$2"; shift 2; fi
PRESHA=""
# THE TWO ARMS DIFFER IN MORE THAN THE CAP (both 08-08/09 retractions
# misread this; comment added 08-09 at the fleet's request):
#   audit arm (*.lean): lake env lean -M $CAP  — capped (default 24000 MB, raised from 12000 at the Captain 8/9 ruling),
#     ONE lean process.
#   build arm (*): lake build — cap from lakefile.toml weakLeanArgs
#     (-M 20000 PER PROCESS), and lake runs MULTIPLE workers.
# Any bound reasoned about one arm must be RE-DERIVED for the other:
# cap, concurrency, and memory licence all differ. Measured 08-09:
# fleet peak 43.08 GB at threads=4 on 64 GiB; THIS FILE'S LOCK is the
# machine-level guard, not either cap.
# PRE-RUN TREE STATE — DATA ONLY (compiler, 08/15, helm-authorized 15:07).
# WHY: five seats share one worktree, so a repo-wide green certifies a MIXTURE.
# The existing HEAD= below is read AFTER the run, so any run ENDING after a commit
# inherits that sha whatever it built — the log said WHICH ARM ran and could not say
# ON WHAT. These two readings make the mixture readable after the fact.
# ⛔ DATA, NOT A VERDICT, AND DELIBERATELY NOT AN ALARM: salt carried 155 dirty lines
# when this was calibrated, so a tree-moved ALARM would fire on most kernel runs, be
# correct every time, and be routed around within a day. No verdict is emitted here.
# ⛔ BEST-EFFORT, PER THIS FILE'S CHARTER (:10-11): every command below is guarded and
# runs BEFORE `lake`, so it cannot touch $? and cannot change the exit code.
PRE_HEAD=$(git rev-parse --short HEAD 2>/dev/null || echo n/a)
# ⛔ NO `|| echo '?'` HERE. On a CLEAN tree `grep -c .` prints `0` AND exits 1, so the
# fallback fires IN ADDITION and the capture becomes the TWO-LINE value $'0\n?', which
# splits the audit record and breaks its one-line invariant. The fallback is supplied
# AFTER capture, at the use site, via ${PRE_DIRTY:-?} (math's find, 2026-08-25).
PRE_DIRTY=$(git status --porcelain 2>/dev/null | command grep -c .)
START=$(date '+%H:%M:%S' 2>/dev/null || echo n/a)
case "$1" in
  *.lean) MODE=audit
          [ -f "$1" ] && PRESHA=$(shasum -a 256 "$1" 2>/dev/null | cut -c1-12)
          ~/.elan/bin/lake env lean -M "$CAP" "$@" ;;
  *)      MODE=build; ~/.elan/bin/lake build "$@" ;;
esac
EXIT=$?
{ SHA=""
  if [ "$MODE" = audit ] && [ -f "$1" ]; then
    POSTSHA=$(shasum -a 256 "$1" 2>/dev/null | cut -c1-12)
    if [ "$PRESHA" = "$POSTSHA" ]; then SHA=" sha256=$PRESHA"
    else SHA=" sha256=$PRESHA->$POSTSHA UNPINNED"; fi
  fi
  # New fields are APPENDED after EXIT= and distinctly named, so every existing
  # reader keeps working: the one known consumer (docs/ledger-tools/audit_coverage.sh:220)
  # matches the SUBSTRING "sha256=<sha>", not a field position or a line end — checked
  # before this change rather than assumed.
  # SAME DEFECT, SECOND SITE — and it fires INDEPENDENTLY of the first: a tree that is
  # DIRTY before and CLEAN after spills only here, leaving a LONE `?` line (measured:
  # audit log line 3038, 2026-08-23, record `dirty=7->0`). Fixing only site 1 leaves it.
  POST_DIRTY=$(git status --porcelain 2>/dev/null | command grep -c .)
  printf '%s | %s | %s | args=%s |%s HEAD=%s | cap=%s | EXIT=%s | start=%s | pre_head=%s | dirty=%s->%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$(pwd)" "$*" "$SHA" \
    "$(git rev-parse --short HEAD 2>/dev/null || echo n/a)" \
    "$([ "$MODE" = audit ] && echo "$CAP" || echo lakefile)" "$EXIT" \
    "${START:-n/a}" "${PRE_HEAD:-n/a}" "${PRE_DIRTY:-?}" \
    "${POST_DIRTY:-?}" >> "$AUDITLOG"
} 2>/dev/null || true
echo "saltbuild EXIT=$EXIT"
exit $EXIT
