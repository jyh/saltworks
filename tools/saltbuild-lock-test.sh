#!/bin/bash
# saltbuild-lock-test.sh — ROW CK. Drives the REAL saltbuild.sh against a PRIVATE lock and a
# PRIVATE log, and asks the only question the row cares about: is contention now VISIBLE?
#
# ⛔⛔ NO ARM TOUCHES /tmp/salt-fleet-build.lock. Every arm sets SALTBUILD_LOCK to a path under
#   its own mktemp dir, and S0 PROVES the fleet lock was not the one used — a suite that can
#   wedge the fleet while testing the fleet's wedge-detector is the 08/26 defect this file's
#   own subject was written after (an earlier cut took the flock and rm -rf'd a live marker).
# ⭐ B IS THE ROW: a builder that WAITS AND THEN GIVES UP must leave a record. A log of
#   acquire/release alone is SURVIVORSHIP BIAS — it contains only the builds that won, and
#   omits exactly the events the 24.5-minute stall was. The abort arms are the whole point.
# ⭐ AND EVERY ABORT ARM ALSO ASSERTS THAT `ACQUIRED` IS ABSENT. "It logged an abort" and "it
#   did not also think it acquired the lock" are different claims, and only the pair is news.
set -u
HERE="$(cd "$(dirname "$0")" && pwd -P)"
SB="${1:-$HERE/saltbuild.sh}"
case "$(basename "$SB")" in saltbuild.sh) ;; *) SB="$HERE/saltbuild.sh" ;; esac
[ -r "$SB" ] || { echo "ABORT: no saltbuild.sh at $SB" >&2; exit 2; }
TD=$(mktemp -d "${TMPDIR:-/tmp}/sblock.XXXXXX") || exit 2
KEEP=""
cleanup(){ for p in $KEEP; do kill "$p" 2>/dev/null; done; rm -rf "$TD"; }
trap cleanup EXIT
pass=0; fail=0
ok(){ pass=$((pass+1)); printf '  ok   %s\n' "$1"; }
no(){ fail=$((fail+1)); printf '  FAIL %s\n' "$1"; }
LOG="$TD/lock.log"
LK="$TD/flock-under-test"
RUN(){ # RUN [maxwait]  — a build in a dir with NO lakefile: lake fails fast, the LOCK path runs whole
  ( cd "$TD" && SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" \
      SALTBUILD_MAXWAIT="${1:-5400}" SEAT=tseat bash "$SB" >/dev/null 2>&1 )
  return 0
}
ev(){ grep -c -F "	$1	" "$LOG" 2>/dev/null | tr -d ' '; }
field(){ grep -F "	$1	" "$LOG" 2>/dev/null | tail -1 | tr '\t' '\n' | grep -F "$2=" | tail -1; }

echo "== S — THE SUITE CANNOT TOUCH THE FLEET =="
FLEET=/tmp/salt-fleet-build.lock
before_fleet=$(ls -d "$FLEET" 2>/dev/null; ls "$FLEET.flk" 2>/dev/null)
RUN
after_fleet=$(ls -d "$FLEET" 2>/dev/null; ls "$FLEET.flk" 2>/dev/null)
[ "$before_fleet" = "$after_fleet" ] && ok "S0  the FLEET lock is untouched by a run under SALTBUILD_LOCK" \
                                     || no "S0  the fleet lock CHANGED: [$before_fleet] -> [$after_fleet]"
[ -e "$LK.flk" ] && ok "S0b ...and the PRIVATE lock is what was used" || no "S0b no private lockfile at $LK.flk"

echo "== A — THE UNCONTENDED RUN LEAVES A COMPLETE RECORD =="
[ "$(ev WAIT-START)" -ge 1 ] && ok "A1  WAIT-START is logged (the clock starts BEFORE the flock)" || no "A1  no WAIT-START"
[ "$(ev ACQUIRED)"  -ge 1 ] && ok "A2  ACQUIRED is logged" || no "A2  no ACQUIRED"
[ "$(ev RELEASED)"  -ge 1 ] && ok "A3  RELEASED is logged" || no "A3  no RELEASED"
case "$(field ACQUIRED waited)" in waited=*s) ok "A4  ACQUIRED carries waited=<n>s — contention is a DURATION" ;;
  *) no "A4  no waited= field: [$(field ACQUIRED waited)]" ;; esac
case "$(field RELEASED held)" in held=*s) ok "A5  RELEASED carries held=<n>s" ;; *) no "A5  no held= field" ;; esac
grep -F "	ACQUIRED	" "$LOG" | grep -F -q "pid=$$" && no "A6  the log says the TEST's pid, not the builder's" \
  || ok "A6  the line carries the BUILDER's pid, not the caller's"
# ⛔ SEAT=, not SB_SEAT=: SB_SEAT is DERIVED inside the script from $SEAT/$SELF (or the
#   script's own path) and OVERWRITES anything the caller set — my first cut set the derived
#   variable and the run logged seat=unknown. Set the INPUT, never the intermediate.
grep -F -q "seat=tseat" "$LOG" && ok "A7  the seat is named (a fleet lock's contenders are seats)" || no "A7  no seat: $(grep -F ACQUIRED "$LOG" | tail -1)"
[ "$(ev RELEASED)" -eq 1 ] && ok "A8  exactly ONE RELEASED per run — the trap fires twice and is latched" \
                           || no "A8  RELEASED appeared $(ev RELEASED) times for one run"

echo "== B — THE ROW: A BUILDER THAT WAITS AND GIVES UP MUST LEAVE A RECORD =="
: > "$LOG"
sleep 300 & HOLDER=$!; KEEP="$KEEP $HOLDER"
mkdir -p "$LK"; echo "$HOLDER" > "$LK/pid"          # a LIVE holder: the marker cannot be reaped
T0=$(date +%s); RUN 2; T1=$(date +%s)
[ "$(ev WAIT-ABORT)" -ge 1 ] && ok "B1  ⭐ a builder that gave up logged WAIT-ABORT" || no "B1  the give-up left NO record — the row's defect"
grep -F "	WAIT-ABORT	" "$LOG" | grep -F -q "stage=marker" && ok "B1b ...and NAMES the stage it died at (marker, not flock)" || no "B1b no stage=marker"
case "$(field WAIT-ABORT waited)" in waited=*s) ok "B2  ...carrying the waited= duration" ;; *) no "B2  no waited=" ;; esac
grep -F "	WAIT-ABORT	" "$LOG" | grep -F -q "holder=$HOLDER" && ok "B3  ...and WHO held it" || no "B3  no holder="
[ "$(ev ACQUIRED)" -eq 0 ] && ok "B4  ⭐ and it did NOT also log ACQUIRED (the discrimination)" || no "B4  it logged ACQUIRED while aborting"
[ "$(ev RELEASED)" -eq 0 ] && ok "B4b ...nor RELEASED for a lock it never held" || no "B4b it logged RELEASED"
kill "$HOLDER" 2>/dev/null; rm -rf "$LK"

echo "== C — THE OTHER ABORT PATH: the flock, held by somebody else =="
: > "$LOG"
FL=$(command -v flock 2>/dev/null || true)
if [ -n "$FL" ]; then
  ( "$FL" -x 8; sleep 30 ) 8>"$LK.flk" & FLH=$!; KEEP="$KEEP $FLH"
  sleep 0.5
  RUN 1
  [ "$(ev WAIT-ABORT)" -ge 1 ] && ok "C1  a builder blocked on the FLOCK logs WAIT-ABORT" || no "C1  no record of the flock wait"
  grep -F "	WAIT-ABORT	" "$LOG" | grep -F -q "stage=flock" && ok "C1b ...and names stage=flock, distinguishing the two waits" || no "C1b no stage=flock"
  [ "$(ev ACQUIRED)" -eq 0 ] && ok "C2  ...and did not claim ACQUIRED" || no "C2  claimed ACQUIRED"
  kill "$FLH" 2>/dev/null
else
  no "C1  no flock(1) on PATH — this arm cannot run, and a control that cannot run has NOT passed"
fi

echo "== D — LOGGING IS NEVER FATAL: an unwritable log must not break a build =="
: > "$LOG"; rm -rf "$LK"
mkdir -p "$TD/nolog"; chmod 500 "$TD/nolog"
( cd "$TD" && SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$TD/nolog/deep/x.log" \
    SEAT=tseat bash "$SB" >"$TD/d.out" 2>&1 )
drc=$?
chmod 700 "$TD/nolog"
[ "$drc" != 76 ] && [ "$drc" != 75 ] && ok "D1  an unwritable LOCKLOG does not turn into a lock refusal (rc=$drc)" \
                                     || no "D1  the build was refused because a LOG was unwritable (rc=$drc)"
grep -F -q "saltbuild EXIT=" "$TD/d.out" && ok "D1b ...and the run still reported its own exit line" || no "D1b no EXIT line"
# ROW LK: "never fatal" was true and "never disturbs the build" was not: the failed open printed to stderr.
grep -F -q "$TD/nolog/deep/x.log" "$TD/d.out" && no "D1c an unwritable LOCKLOG still PRINTS its open error: $(grep -F -m1 "$TD/nolog" "$TD/d.out")" \
  || ok "D1c ...and says NOTHING about the unwritable log (its open error does not leak to stderr)"

echo "== E — THE SEAMS REFUSE RATHER THAN FALL BACK ON THE FLEET =="
o=$( cd "$TD" && SALTBUILD_LOCK= bash "$SB" 2>&1 ); rc=$?
printf '%s' "$o" | grep -F -q "SET BUT EMPTY" && [ "$rc" = 76 ] \
  && ok "E1  ⭐ an EMPTY SALTBUILD_LOCK is REFUSED, not silently replaced by the fleet lock" \
  || no "E1  empty lock path gave rc=$rc: $o"
o=$( cd "$TD" && SALTBUILD_MAXWAIT=abc bash "$SB" 2>&1 ); rc=$?
[ "$rc" = 76 ] && ok "E2  a non-numeric SALTBUILD_MAXWAIT is refused" || no "E2  rc=$rc"

echo "== F — ROW LK: A BUILD THAT MAY NOT REAP A DEAD HOLDER MUST RELEASE THE FLOCK, NOT HOLD IT =="
# ⛔ The row: a sandboxed build could not rename a dead holder's marker, looped for the whole MAXWAIT holding
#   the flock, and every seat that COULD have reaped it blocked in flock -w, silently. "May not rename" is a
#   property of ONE PROCESS, so it is modelled per process: an `mv` on that process's PATH that refuses, with
#   the error text a sandbox gives. Every other builder runs the real mv.
# ⭐ F2 IS THE ROW. F1 alone could pass on a wrapper that exits on refusal and never lets anyone else in.
SHIM="$TD/shim"; mkdir -p "$SHIM"
printf '#!/bin/sh\necho "mv: rename $1 to $2: Operation not permitted" >&2\nexit 1\n' > "$SHIM/mv"; chmod +x "$SHIM/mv"
DEAD=$(bash -c 'echo $$')
mkmarker(){ rm -rf "$LK" "$LK".reaping.*; mkdir -p "$LK"; echo "$DEAD" > "$LK/pid"; }
kill -0 "$DEAD" 2>/dev/null && no "F0  FIXTURE: pid $DEAD is alive, so no F arm below means anything"
: > "$LOG"; mkmarker
T0=$(date +%s)
o=$( cd "$TD" && PATH="$SHIM:$PATH" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_MAXWAIT=20 SEAT=refused bash "$SB" 2>&1 ); rc=$?
dt=$(( $(date +%s) - T0 ))
[ "$rc" = 75 ] && [ "$dt" -lt 10 ] && ok "F1  a REFUSED claim on a dead holder exits 75 at once (${dt}s), not at MAXWAIT (20s)" \
  || no "F1  rc=$rc after ${dt}s — a refused reap waited out MAXWAIT holding the flock (the row's wedge)"
printf '%s' "$o" | grep -F -q "Operation not permitted" && printf '%s' "$o" | grep -F -q "pid $DEAD" \
  && ok "F1b ...and SAYS so, with the holder's pid and the rename's own error" || no "F1b the refusal is silent: $(printf '%s' "$o" | tail -2 | tr '\n' '|')"
grep -F "	WAIT-ABORT	" "$LOG" | grep -F -q "stage=reap-refused" && ok "F1c ...and LOGS WAIT-ABORT stage=reap-refused" || no "F1c no stage=reap-refused in the log"
[ "$(ev ACQUIRED)" -eq 0 ] && [ "$(cat "$LK/pid" 2>/dev/null)" = "$DEAD" ] \
  && ok "F1d ...claimed nothing, and left the dead holder's marker exactly as it found it" || no "F1d ACQUIRED=$(ev ACQUIRED) marker=[$(cat "$LK/pid" 2>/dev/null)]"
# F2: the refused builder takes the flock FIRST, a normal builder arrives 1 s later.
# ⛔ "THE REAPER GOT IN" IS NOT THE ASSERTION — "IT GOT IN BEFORE THE REFUSED BUILDER'S MAXWAIT" IS. The first cut
#   of this arm checked only that the reaper acquired and reaped, and it PASSED ON THE PRE-FIX WRAPPER: the reaper
#   queued behind the refused builder's ticket (the queue has no timeout, by ruling), waited the full 30 s, then got
#   in. Every one of its facts was true and the wedge was still there. Only the DURATION tells the two apart.
: > "$LOG"; mkmarker
( cd "$TD" && PATH="$SHIM:$PATH" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_MAXWAIT=30 SEAT=refused bash "$SB" >"$TD/f2a.out" 2>&1 ) & FA=$!; KEEP="$KEEP $FA"
sleep 1
T0=$(date +%s)
o=$( cd "$TD" && SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_MAXWAIT=10 SEAT=reaper bash "$SB" 2>&1 )
dt=$(( $(date +%s) - T0 ))
wait "$FA" 2>/dev/null
grep -F "	ACQUIRED	" "$LOG" | grep -F -q "seat=reaper" && printf '%s' "$o" | grep -F -q "reaped a marker whose holder (pid $DEAD)" && [ "$dt" -lt 15 ] \
  && ok "F2  ⭐ a builder that CAN reap gets in within ${dt}s and reaps the dead marker — the refused one did not hold it for its 30s" \
  || no "F2  the reaper took ${dt}s (the refused builder's MAXWAIT is 30s): $(grep -F 'seat=reaper' "$LOG" | cut -f2,6 | tr '\n' '|') :: $(printf '%s' "$o" | tail -1)"
# F3 CONTROL: a rename that fails because the marker is GONE (its holder released it) is NOT a refusal.
: > "$LOG"; mkmarker
printf '#!/bin/sh\nrm -rf "$1"\necho "mv: rename $1 to $2: No such file or directory" >&2\nexit 1\n' > "$SHIM/mv"
o=$( cd "$TD" && PATH="$SHIM:$PATH" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_MAXWAIT=20 SEAT=vanish bash "$SB" 2>&1 ); rc=$?
[ "$rc" != 75 ] && [ "$(ev ACQUIRED)" -ge 1 ] && ! grep -F -q "stage=reap-refused" "$LOG" \
  && ok "F3  CONTROL: a marker that VANISHED mid-claim is retried and acquired, never reported as a refusal" \
  || no "F3  rc=$rc ACQUIRED=$(ev ACQUIRED) :: $(printf '%s' "$o" | tail -1)"
# F4 CONTROL: a LIVE holder is still never touched, and its abort is still stage=marker.
: > "$LOG"; rm -rf "$LK"
sleep 60 & LIVE=$!; KEEP="$KEEP $LIVE"
mkdir -p "$LK"; echo "$LIVE" > "$LK/pid"
( cd "$TD" && SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_MAXWAIT=2 SEAT=live bash "$SB" >/dev/null 2>&1 )
grep -F "	WAIT-ABORT	" "$LOG" | grep -F -q "stage=marker" && [ "$(cat "$LK/pid" 2>/dev/null)" = "$LIVE" ] \
  && ok "F4  CONTROL: a LIVE holder's marker survives and the abort is stage=marker, not reap-refused" || no "F4  live holder: $(cut -f2,6 "$LOG" | tr '\n' '|')"
kill "$LIVE" 2>/dev/null; rm -rf "$LK"

echo
printf 'saltbuild-lock-test: %d/%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
