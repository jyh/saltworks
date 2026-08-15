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
WAITED=0; MAXWAIT=5400
while ! mkdir "$LOCK" 2>/dev/null; do
  if [ -f "$LOCK/pid" ]; then
    if ! kill -0 "$(cat "$LOCK/pid" 2>/dev/null)" 2>/dev/null; then rm -rf "$LOCK"; continue; fi
  elif [ -d "$LOCK" ] && [ $(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || date +%s) )) -ge 60 ]; then
    rm -rf "$LOCK"; continue   # pid-less lock >60s old: the mkdir->echo window died; reap it
  fi
  [ $WAITED -ge $MAXWAIT ] && { echo "saltbuild EXIT=75 (LOCK-WAIT ABORT: the build NEVER STARTED — this is NOT a build failure; RETRY the same command)"; exit 75; }
  sleep 15; WAITED=$((WAITED+15))
  [ $((WAITED % 300)) -eq 0 ] && echo "saltbuild: waiting on the fleet lock (${WAITED}s)"
done
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM
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
PRE_DIRTY=$(git status --porcelain 2>/dev/null | command grep -c . || echo '?')
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
  printf '%s | %s | %s | args=%s |%s HEAD=%s | cap=%s | EXIT=%s | start=%s | pre_head=%s | dirty=%s->%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$MODE" "$(pwd)" "$*" "$SHA" \
    "$(git rev-parse --short HEAD 2>/dev/null || echo n/a)" \
    "$([ "$MODE" = audit ] && echo "$CAP" || echo lakefile)" "$EXIT" \
    "${START:-n/a}" "${PRE_HEAD:-n/a}" "${PRE_DIRTY:-?}" \
    "$(git status --porcelain 2>/dev/null | command grep -c . || echo '?')" >> "$AUDITLOG"
} 2>/dev/null || true
echo "saltbuild EXIT=$EXIT"
exit $EXIT
