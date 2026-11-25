#!/bin/bash
# saltbuild-prebuild-test.sh — THE AUDIT ARM BUILDS THE SCRATCH'S IMPORTS FIRST (desk AHM, 2026-11-25).
#
# `saltbuild.sh X.lean` runs `lake env lean`, which loads the imports' .olean files as they are on disk. An import
# edited after its last build is audited STALE. The axiom receipt is a triple (salt CLAUDE.md, council 11-23 ask 4)
# and its term 1, the build line, was the seat's manual step. The wrapper now reads the scratch's header imports
# before the lock, and under the lock runs `lake build <imports>` before `lake env lean`; a red import build is the
# verdict and the audit does not run.
#
# The arms (every lock and log under a scratch dir; a STUB lake under a scratch HOME, as the fetch test does).
# The stub appends each call's argv to calls.log and exits BUILD_RC for `build`, AUDIT_RC for `env`.
#   P1  a scratch importing Salt.Foo, Mathlib.Tactic and Lean.Elab ⇒ lake gets `build Salt.Foo Mathlib.Tactic` (the
#       toolchain root dropped), THEN `env lean -M 24000 X.lean`, in that order, under ONE ACQUIRED/RELEASED pair
#                                                                                   (red on the pre-AHM wrapper)
#   P2  the import build fails (stub rc 3) ⇒ the audit never runs, `saltbuild EXIT=3`, rc 3     (red on the pre-AHM wrapper)
#   P3  header forms: nested block comments, line comments, `prelude`, `public import`, `import all`, a module
#       name on the next line; an `import` word AFTER the header (in a declaration's comment and a string) is
#       not taken; duplicates named once                                            (red on the pre-AHM wrapper)
#   P4  no imports but the toolchain's (`import Lean`) ⇒ no build call; the audit runs
#   P5  an unterminated block comment in the header ⇒ rc 79, lake never started, no lock taken
#   P6  the audit record carries `prebuild=0` (green), `prebuild=3` (red), `prebuild=none` (no imports)
#   P7  the thread cap reaches the import build (LEAN_NUM_THREADS=4)
#   P8  `--cap 100 X.lean` still builds the imports and passes the cap to the audit
#   P9  CONTROL: a plain build (`Salt.Foo`) is ONE `build Salt.Foo` call, unchanged
#   P10 a token after `import` that is not a module name (`-x`, `Salt.*`, a «…» name split by a space) ⇒ rc 79 before
#       the lock, lake never started (h2c's read of #139, LOW 1)
#   P11 a leading byte-order mark: the imports are still read and built (h2c's NOTE 1)
#   PM  MUTANTS on a copy: (a) the import build removed ⇒ P1 red; (b) the red-build gate removed (always audit) ⇒ P2
#       red; (c) the parser's refusal removed ⇒ P5 red; (d) the name-shape check removed ⇒ P10 red. A mutation that matches
#       nothing is ROTTED and fails.
set -u
SB="${1:-$(cd "$(dirname "$0")" && pwd)/saltbuild.sh}"
FLOCK="$(command -v flock)" || { echo "SKIP: no flock(1) on PATH — saltbuild itself refuses to run here (exit 3: NOT a pass)"; exit 3; }
command -v python3 >/dev/null || { echo "SKIP: no python3 — the wrapper refuses an audit without it (exit 3: NOT a pass)"; exit 3; }
TD="$(mktemp -d "${TMPDIR:-/tmp}/sb-prebuild.XXXXXX")"
pass=0; fail=0
ok(){ printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }
cleanup(){ rm -rf -- "${TD:?}"; }
trap cleanup EXIT
H="$TD/home"; mkdir -p "$H/.elan/bin"
cat > "$H/.elan/bin/lake" <<STUB
#!/bin/bash
printf '%s\n' "\$*" >> "$TD/calls.log"
echo "\$1 \${LEAN_NUM_THREADS:-unset}" >> "$TD/threads.log"
case "\$1" in
  build) exit "\${BUILD_RC:-0}" ;;
  env)   exit "\${AUDIT_RC:-0}" ;;
esac
exit 0
STUB
chmod +x "$H/.elan/bin/lake"
R="$TD/repo"; mkdir -p "$R"   # no lake-manifest.json: the no-mathlib-build check does not apply
cat > "$R/S1.lean" <<'EOF'
import Salt.Foo
import Mathlib.Tactic
import Lean.Elab
theorem t : True := trivial
#print axioms t
EOF
cat > "$R/S3.lean" <<'EOF'
/- a header comment /- nested -/ still a comment, import Not.This -/
-- import Nor.This
prelude
public import Salt.A -- trailing
import all
  Salt.B
import Salt.A
/-! module doc after the header: import Not.Taken -/
namespace X
-- import Not.Taken.Either
def s : String := "import Not.A.Module"
end X
EOF
printf 'import Lean\n#eval 1\n' > "$R/S4.lean"
printf '/- an unterminated header comment\nimport Salt.Foo\n' > "$R/S5.lean"
printf 'import -x\n' > "$R/B1.lean"; printf 'import Salt.*\n' > "$R/B2.lean"; printf 'import Salt.\302\253Foo Bar\302\273\n' > "$R/B3.lean"
printf '\357\273\277import Salt.Foo\n#eval 1\n' > "$R/S11.lean"
n=0
run(){ # run [saltbuild args…] -> OUT, RC; calls/threads reset; LK/LOG/AUD per run
  n=$((n+1)); rm -f -- "${TD:?}/calls.log" "${TD:?}/threads.log"
  LK="$TD/lock-$n"; LOG="$TD/lock-$n.log"; AUD="$TD/audit-$n.log"
  OUT=$(cd "$R" && HOME="$H" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SALTBUILD_AUDITLOG="$AUD" SEAT=prebuildtest bash "${SBX:-$SB}" "$@" 2>&1); RC=$?
}
calls(){ cat "$TD/calls.log" 2>/dev/null | tr '\n' '|'; }
nacq(){ if [ -f "$LOG" ]; then command grep -c 'ACQUIRED' "$LOG"; else echo 0; fi; }

arms(){
# P1
run S1.lean
if [ "$RC" = 0 ] && [ "$(calls)" = "build Salt.Foo Mathlib.Tactic|env lean -M 24000 S1.lean|" ] && [ "$(nacq)" = 1 ] \
   && command grep -q 'RELEASED' "$LOG" 2>/dev/null && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=0'; then
  ok "P1 imports built first (toolchain root dropped), then the audit, under one lock hold"
else no "P1 order" "rc=$RC calls=[$(calls)] acquired=$(nacq) :: $(printf '%s' "$OUT" | tail -1)"; fi
# P2
BUILD_RC=3 run S1.lean
if [ "$RC" = 3 ] && [ "$(calls)" = "build Salt.Foo Mathlib.Tactic|" ] && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=3'; then
  ok "P2 a red import build is the verdict: the audit never ran, EXIT=3, rc 3"
else no "P2 red build" "rc=$RC calls=[$(calls)] :: $(printf '%s' "$OUT" | tail -1)"; fi
P2AUD="$AUD"
# P3
run S3.lean
if [ "$RC" = 0 ] && [ "$(calls)" = "build Salt.A Salt.B|env lean -M 24000 S3.lean|" ]; then
  ok "P3 header forms read (comments, prelude, public, all, a name on the next line); body imports not taken; duplicates once"
else no "P3 header" "rc=$RC calls=[$(calls)]"; fi
# P4
run S4.lean
if [ "$RC" = 0 ] && [ "$(calls)" = "env lean -M 24000 S4.lean|" ]; then ok "P4 toolchain-only imports: no build call, the audit runs"
else no "P4 core only" "rc=$RC calls=[$(calls)]"; fi
P4AUD="$AUD"
# P5
run S5.lean
if [ "$RC" = 79 ] && [ ! -s "$TD/calls.log" ] && [ "$(nacq)" = 0 ] && printf '%s' "$OUT" | command grep -q 'saltbuild EXIT=79 (REFUSED'; then
  ok "P5 an unreadable header is refused before the lock: rc 79, lake never started"
else no "P5 refusal" "rc=$RC calls=[$(calls)] acquired=$(nacq) :: $(printf '%s' "$OUT" | tail -1)"; fi
# P6
run S1.lean
if command grep -q 'prebuild=0$' "$AUD" 2>/dev/null && command grep -q 'prebuild=3$' "$P2AUD" 2>/dev/null \
   && command grep -q 'prebuild=none$' "$P4AUD" 2>/dev/null; then ok "P6 the audit record names the import build: prebuild=0 · 3 · none"
else no "P6 record" "green=[$(cat "$AUD" 2>/dev/null)] red=[$(cat "$P2AUD" 2>/dev/null)] none=[$(cat "$P4AUD" 2>/dev/null)]"; fi
# P7
if command grep -qx 'build 4' "$TD/threads.log" 2>/dev/null; then ok "P7 the thread cap reaches the import build (LEAN_NUM_THREADS=4)"
else no "P7 threads" "calls and caps seen: [$(tr '\n' '|' < "$TD/threads.log" 2>/dev/null)]"; fi
# P8
run --cap 100 S1.lean
if [ "$RC" = 0 ] && [ "$(calls)" = "build Salt.Foo Mathlib.Tactic|env lean -M 100 S1.lean|" ]; then ok "P8 --cap: the imports are built and the cap reaches the audit"
else no "P8 cap" "rc=$RC calls=[$(calls)]"; fi
# P9
run Salt.Foo
if [ "$RC" = 0 ] && [ "$(calls)" = "build Salt.Foo|" ]; then ok "P9 CONTROL: a plain build is one 'build Salt.Foo' call, unchanged"
else no "P9 control" "rc=$RC calls=[$(calls)]"; fi
# P10
for b in B1 B2 B3; do
  run $b.lean
  if [ "$RC" = 79 ] && [ ! -s "$TD/calls.log" ] && [ "$(nacq)" = 0 ]; then ok "P10 $b: a token that is not a module name is refused 79 before the lock"
  else no "P10 $b" "rc=$RC calls=[$(calls)] acquired=$(nacq) :: $(printf '%s' "$OUT" | tail -1)"; fi
done
# P11
run S11.lean
if [ "$RC" = 0 ] && [ "$(calls)" = "build Salt.Foo|env lean -M 24000 S11.lean|" ]; then ok "P11 a leading byte-order mark: the imports are read and built"
else no "P11 BOM" "rc=$RC calls=[$(calls)]"; fi
}

if [ "${SBX:-}" = "" ] && [ "${2:-}" != "--no-mutants" ]; then
  echo "saltbuild-prebuild-test: arms against $SB"
  arms
  M="$TD/mut"; mkdir -p "$M"; cp "$(dirname "$SB")"/*.sh "$M/" 2>/dev/null
  mutant(){ # mutant <name> <old> <new>
    python3 - "$SB" "$M/saltbuild.sh" "$2" "$3" <<'PY' || return 9
import sys
src = open(sys.argv[1]).read(); old, new = sys.argv[3], sys.argv[4]
if src.count(old) != 1: sys.exit(1)
open(sys.argv[2], "w").write(src.replace(old, new, 1))
PY
    mo=$(SBX="$M/saltbuild.sh" bash "$0" "$SB" --no-mutants 2>&1); mf=$(printf '%s\n' "$mo" | command grep -c '^  FAIL')
    if [ "$mf" -gt 0 ]; then ok "PM $1: the mutant turns $mf arm(s) red"; else no "PM $1" "the mutant SURVIVED"; fi
  }
  mutant "no-import-build" 'run_lake ~/.elan/bin/lake build $SB_IMPORTS; SB_PREBUILD=$?' 'SB_PREBUILD=0' \
    || no "PM no-import-build" "ROTTED: the target text is absent"
  mutant "audit-on-red-build" 'if [ "$SB_PREBUILD" = none ] || [ "$SB_PREBUILD" = 0 ]; then' 'if :; then' \
    || no "PM audit-on-red-build" "ROTTED: the target text is absent"
  mutant "no-parse-refusal" '        exit 79' '        :' \
    || no "PM no-parse-refusal" "ROTTED: the target text is absent"
  mutant "no-name-shape" 'print("NOT A MODULE NAME: " + tok[:60]); sys.exit(4)' 'pass' \
    || no "PM no-name-shape" "ROTTED: the target text is absent"
else
  arms
fi
echo "saltbuild-prebuild-test: $pass passed, $fail failed"
[ "$fail" = 0 ]
