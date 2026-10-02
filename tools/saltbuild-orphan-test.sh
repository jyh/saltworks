#!/bin/bash
# saltbuild-orphan-test.sh — THE WRAPPER DIES, THE LOCK MUST NOT STAY HELD (kent #311 r2, K2; routed 2026-10-02).
#
# A caller that bounds saltbuild with a timeout — Python's subprocess.run(timeout=…) is the common form, and it stops the
# child with SIGKILL — kills saltbuild's bash and NOTHING BELOW IT. lake is a grandchild of the caller, it inherited fd 9,
# and fd 9 is the fleet flock: the lock stays held for as long as lake runs, and a proof that never terminates wedges every
# seat's build. A TERM/EXIT trap cannot help, because SIGKILL runs no trap.
#
# The arms, every lock and log under a scratch dir (SALTBUILD_LOCK / SALTBUILD_LOCKLOG seams) and a STUB lake under a scratch
# HOME (saltbuild calls ~/.elan/bin/lake by absolute path), so nothing builds and nothing touches the fleet lock:
#   O1  SIGKILL the wrapper while lake runs: the lock is FREE within 5 s          (red on the pre-guard wrapper)
#   O2  ...and the stub lake is GONE within 5 s — no orphan build keeps running   (red on the pre-guard wrapper)
#   O3  SIGTERM the wrapper: same two properties                                  (a `timeout`-style caller)
#   O4  CONTROL: an ordinary run still returns lake's own exit code (rc 3 from the stub) and prints saltbuild EXIT=3
set -u
SB="${1:-$(cd "$(dirname "$0")" && pwd)/saltbuild.sh}"
FLOCK="$(command -v flock)" || { echo "SKIP: no flock(1) on PATH — saltbuild itself refuses to run here"; exit 0; }
TD="$(mktemp -d "${TMPDIR:-/tmp}/sb-orphan.XXXXXX")"
pass=0; fail=0; KEEP=""
ok(){ printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }
cleanup(){ for p in $KEEP; do kill -KILL "$p" 2>/dev/null; done; rm -rf -- "${TD:?}"; }
trap cleanup EXIT
H="$TD/home"; mkdir -p "$H/.elan/bin" "$TD/repo"
# the stub lake: records its pid, then sleeps (a "non-terminating proof"), or exits with STUB_RC when STUB_SLEEP=0
printf '#!/bin/bash\necho $$ > "%s/lake.pid"\n[ "${STUB_SLEEP:-60}" = 0 ] && exit "${STUB_RC:-0}"\nsleep "${STUB_SLEEP:-60}"\n' "$TD" > "$H/.elan/bin/lake"
chmod +x "$H/.elan/bin/lake"
LK="$TD/lock"; LOG="$TD/lock.log"
alive(){ [ -n "$1" ] && [ -n "$(ps -p "$1" -o pid= 2>&1 | tr -dc 0-9)" ]; }
lock_free_within(){ "$FLOCK" -w "$1" "$LK.flk" true; }
drive(){ # drive <signal> <label> — each drive on its OWN lock and queue, so a killed wrapper's ticket cannot hold the next drive
  rm -f -- "${TD:?}/lake.pid"; LK="$TD/lock-$2"; LOG="$TD/lock-$2.log"
  ( cd "$TD/repo" && HOME="$H" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SEAT=orphantest exec bash "$SB" ) > "$TD/$2.out" 2>&1 &
  local w=$! k=0; KEEP="$KEEP $w"
  while [ ! -s "$TD/lake.pid" ] && [ "$k" -lt 300 ]; do sleep 0.1; k=$((k+1)); done
  local lp; lp=$(cat "$TD/lake.pid" 2>/dev/null); KEEP="$KEEP $lp"
  [ -n "$lp" ] || { no "$2 fixture" "the stub lake never started: $(tail -2 "$TD/$2.out" | tr '\n' '|')"; return; }
  kill "-$1" "$w"
  if lock_free_within 5; then ok "$2 the lock is FREE within 5 s of SIG$1 to the wrapper"
  else no "$2 the lock is FREE within 5 s of SIG$1 to the wrapper" "still held (orphan lake pid $lp alive=$(alive "$lp" && echo yes || echo no))"; fi
  k=0; while alive "$lp" && [ "$k" -lt 50 ]; do sleep 0.1; k=$((k+1)); done
  alive "$lp" && no "$2' the stub lake is GONE within 5 s" "pid $lp still running — an orphan build" || ok "$2' the stub lake is GONE within 5 s"
  kill -KILL "$lp" 2>/dev/null
}
echo "════ saltbuild orphan guard — $SB ════"
drive KILL O1
drive TERM O3
LK="$TD/lock-O4"; LOG="$TD/lock-O4.log"
( cd "$TD/repo" && HOME="$H" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SEAT=orphantest STUB_SLEEP=0 STUB_RC=3 exec bash "$SB" ) > "$TD/O4.out" 2>&1 &
w=$!; KEEP="$KEEP $w"; k=0; while alive "$w" && [ "$k" -lt 200 ]; do sleep 0.1; k=$((k+1)); done   # BOUNDED: a hang is a FAIL
if alive "$w"; then kill -KILL "$w"; rc=HUNG; else wait "$w"; rc=$?; fi; o=$(cat "$TD/O4.out")
[ "$rc" = 3 ] && printf '%s' "$o" | grep -q 'saltbuild EXIT=3' && ok "O4 CONTROL an ordinary run returns lake's own rc (3) and prints saltbuild EXIT=3" \
  || no "O4 CONTROL an ordinary run returns lake's own rc" "rc=$rc :: $(printf '%s' "$o" | tail -2 | tr '\n' '|')"
echo "RESULT pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
