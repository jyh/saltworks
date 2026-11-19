#!/bin/bash
# saltbuild-fetch-test.sh — THE NEVER-BARE-LAKE LAW HAD NO COMPLIANT PATH FOR A FETCH (desk ACC, 2026-11-18).
#
# The wrapper's build arm runs `lake build "$@"` and its audit arm `lake env lean`, so `lake update` and
# `lake exe cache get` could only be run BARE: outside the fleet lock, with no thread cap and no audit line.
# A seat ran both bare on 2026-10-10 for a fetch-only step, declared, and the helm concurred for those two
# verbs only. A law with no compliant path for a needed act is a law the next seat breaks undeclared.
#   `saltbuild.sh --fetch update` runs `lake update`; `saltbuild.sh --fetch cache` runs `lake exe cache get`.
#   Both go through the SAME fleet lock, the same LEAN_NUM_THREADS cap, the same audit record and the same
#   `saltbuild EXIT=N` line as a build. Any other verb, or any further argument, is refused with exit 78
#   before the lock is taken and before lake starts. A fetch is exempt from the no-mathlib-build refusal
#   (exit 77): fetching the cache is that refusal's remedy, and neither verb elaborates the tree.
#
# The arms (every lock and log under a scratch dir; a STUB lake under a scratch HOME, as the mathlib test does):
#   F1  --fetch cache in a tree with NO mathlib build ⇒ proceeds (not 77), lake gets `exe cache get`, the lock is
#       ACQUIRED and RELEASED (lock log), the EXIT line is printed            (red on the pre-fetch wrapper)
#   F2  --fetch update ⇒ lake gets exactly `update`
#   F3  refusals: no verb · an unknown verb (`build`) · a further argument ⇒ rc 78, lake NEVER started, no lock
#   F4  lake's own exit code travels: stub rc 5 ⇒ `saltbuild EXIT=5`, rc 5
#   F5  the audit record names the mode (`fetch-cache`), as a build's names `build`
#   F6  the thread cap reaches lake (LEAN_NUM_THREADS=4 in lake's environment)
#   F7  CONTROL: a plain build in the same no-mathlib tree is still refused 77 (the exemption is the fetch's only)
#   FM  MUTANTS on a copy: (a) the 77 exemption (the fetch block's COLD=1) removed ⇒ F1 refused; (b) the verb check removed ⇒ F3's unknown
#       verb starts lake. Each must turn its arm red; a mutation that matches nothing is ROTTED and fails.
set -u
SB="${1:-$(cd "$(dirname "$0")" && pwd)/saltbuild.sh}"
# ⛔ A SKIP IS NOT A PASS: exit 3, as the mathlib test does.
FLOCK="$(command -v flock)" || { echo "SKIP: no flock(1) on PATH — saltbuild itself refuses to run here (exit 3: NOT a pass)"; exit 3; }
TD="$(mktemp -d "${TMPDIR:-/tmp}/sb-fetch.XXXXXX")"
pass=0; fail=0
ok(){ printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }
cleanup(){ rm -rf -- "${TD:?}"; }
trap cleanup EXIT
H="$TD/home"; mkdir -p "$H/.elan/bin"
# the stub lake: records its pid, argv and thread cap, then exits with STUB_RC (default 0)
printf '#!/bin/bash\necho $$ > "%s/lake.pid"\nprintf "%%s\\n" "$*" > "%s/lake.args"\necho "${LEAN_NUM_THREADS:-unset}" > "%s/lake.threads"\nexit "${STUB_RC:-0}"\n' "$TD" "$TD" "$TD" > "$H/.elan/bin/lake"
chmod +x "$H/.elan/bin/lake"
# a tree whose manifest names mathlib and which has NO mathlib build (the 77 case)
R="$TD/repo"; mkdir -p "$R"
printf '{"version":"1.1.0","packagesDir":".lake/packages","packages":[{"name":"mathlib","type":"git"}],"name":"salt","lakeDir":".lake"}\n' > "$R/lake-manifest.json"
n=0
run(){ # run [saltbuild args…] -> OUT, RC; lake.* reset first; LK/LOG/AUD per run
  n=$((n+1)); rm -f -- "${TD:?}/lake.pid" "${TD:?}/lake.args" "${TD:?}/lake.threads"
  LK="$TD/lock-$n"; LOG="$TD/lock-$n.log"; AUD="$TD/audit-$n.log"
  OUT=$(cd "$R" && HOME="$H" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_AUDITLOG="$AUD" SEAT=fetchtest bash "${SBX:-$SB}" "$@" 2>&1); RC=$?
}
started(){ [ -s "$TD/lake.pid" ]; }
nolock(){ [ ! -e "$LK.flk" ] && [ ! -d "$LK" ] && ! command grep -q 'ACQUIRED' "$LOG" 2>/dev/null; }

arms(){
# F1
run --fetch cache
if [ "$RC" = 0 ] && started && [ "$(cat "$TD/lake.args")" = "exe cache get" ] \
   && command grep -q 'ACQUIRED' "$LOG" 2>/dev/null && command grep -q 'RELEASED' "$LOG" 2>/dev/null \
   && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=0'; then
  ok "F1 --fetch cache in a no-mathlib tree: lake gets 'exe cache get', under the lock, EXIT line printed"
else no "F1 cache" "rc=$RC started=$(started && echo yes || echo no) args=[$(cat "$TD/lake.args" 2>/dev/null)] lock=[$(command grep -oE 'ACQUIRED|RELEASED' "$LOG" 2>/dev/null | tr '\n' ' ')] :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi
# F2
run --fetch update
if [ "$RC" = 0 ] && started && [ "$(cat "$TD/lake.args")" = "update" ]; then ok "F2 --fetch update: lake gets exactly 'update'"
else no "F2 update" "rc=$RC args=[$(cat "$TD/lake.args" 2>/dev/null)] :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi
# F3
for c in "--fetch" "--fetch build" "--fetch cache Salt.Foo" "--fetch update --cap 9"; do
  # shellcheck disable=SC2086
  run $c
  if [ "$RC" = 78 ] && ! started && nolock && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=78 (REFUSED'; then ok "F3 refused before the lock: '$c' ⇒ rc 78, lake never started"
  else no "F3 '$c'" "rc=$RC started=$(started && echo yes || echo no) lock=$(nolock && echo none || echo TAKEN) :: $(printf '%s' "$OUT" | tail -1)"; fi
done
# F4
STUB_RC=5 run --fetch cache
if [ "$RC" = 5 ] && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=5'; then ok "F4 lake's exit code travels (stub 5 ⇒ EXIT=5, rc 5)"
else no "F4 rc" "rc=$RC :: $(printf '%s' "$OUT" | tail -1)"; fi
# F5
run --fetch cache
if command grep -q '| fetch-cache |' "$AUD" 2>/dev/null && command grep -q 'EXIT=0' "$AUD"; then ok "F5 the audit record names the mode (fetch-cache) and its EXIT"
else no "F5 audit" "audit=[$(cat "$AUD" 2>/dev/null)]"; fi
# F6
if [ "$(cat "$TD/lake.threads" 2>/dev/null)" = 4 ]; then ok "F6 the thread cap reaches lake (LEAN_NUM_THREADS=4)"
else no "F6 threads" "lake saw LEAN_NUM_THREADS=[$(cat "$TD/lake.threads" 2>/dev/null)]"; fi
# F7
run Salt.Foo
if [ "$RC" = 77 ] && ! started; then ok "F7 CONTROL: a plain build in the same tree is still refused 77"
else no "F7 control" "rc=$RC started=$(started && echo yes || echo no)"; fi
}

if [ "${SBX:-}" = "" ] && [ "${2:-}" != "--no-mutants" ]; then
  echo "saltbuild-fetch-test: arms against $SB"
  arms
  # FM — mutants on copies; each must turn at least one arm red
  M="$TD/mut"; mkdir -p "$M"; cp "$(dirname "$SB")"/*.sh "$M/" 2>/dev/null
  mutant(){ # mutant <name> <python: old> <new>
    python3 - "$SB" "$M/saltbuild.sh" "$2" "$3" <<'PY' || return 9
import sys
src = open(sys.argv[1]).read(); old, new = sys.argv[3], sys.argv[4]
if src.count(old) != 1: sys.exit(1)
open(sys.argv[2], "w").write(src.replace(old, new, 1))
PY
    mo=$(SBX="$M/saltbuild.sh" bash "$0" "$SB" --no-mutants 2>&1); mf=$(printf '%s\n' "$mo" | command grep -c '^  FAIL')
    if [ "$mf" -gt 0 ]; then ok "FM $1: the mutant turns $mf arm(s) red"; else no "FM $1" "the mutant SURVIVED"; fi
  }
  mutant "no-77-exemption" 'if [ -n "$FETCH" ]; then COLD=1; fi' ':' \
    || no "FM no-77-exemption" "ROTTED: the target text is absent"
  mutant "no-verb-check" '    update|cache) FETCH="$2" ;;' '    *) FETCH="$2" ;;' \
    || no "FM no-verb-check" "ROTTED: the target text is absent"
else
  arms
fi
echo "saltbuild-fetch-test: $pass passed, $fail failed"
[ "$fail" = 0 ]
