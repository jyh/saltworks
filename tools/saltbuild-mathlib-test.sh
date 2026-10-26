#!/bin/bash
# saltbuild-mathlib-test.sh — A BUILD THAT WOULD COMPILE MATHLIB UNDER THE FLEET LOCK IS REFUSED UNLESS IT IS ASKED FOR (helm queue item, 2026-10-26 12:12).
#
# paper's builds compiled MATHLIB under the fleet lock twice on 2026-10-26 (06:3x, and ~20 min at 11:43), each time in a worktree with no .lake,
# and the one heavy slot is shared. Its own card said "copy .lake first" both times: a card did not stop it. THE WRAPPER NOW DOES.
#   Before the lock is taken, in a tree whose lake-manifest.json lists a package named `mathlib`, the built top module must exist at
#   <packagesDir>/mathlib/.lake/build/lib/lean/Mathlib.olean — packagesDir READ FROM THE MANIFEST (default .lake/packages), never assumed.
#   Absent: one refusing line, exit 77, NO lock taken, lake never started. `--cold` says "build it on purpose"; it is not passed on to lake.
#   ⛔ NOT `lake env` / `lake build --no-build` AS THE CHECK: measured 2026-10-26, `lake env printenv LEAN_PATH` in a tree with no .lake starts
#     `git clone https://github.com/leanprover-community/mathlib4` — the very cost this refuses.
#
# The arms (every lock and log under a scratch dir; a STUB lake under a scratch HOME — saltbuild calls ~/.elan/bin/lake by absolute path):
#   R1  no mathlib build            ⇒ rc 77, the refusing line, lake NEVER started, no lock file made   (red on the pre-check wrapper)
#   R2  the same with --cold        ⇒ proceeds, lake runs, and lake is NOT handed --cold
#   R3  a built tree                ⇒ proceeds untouched
#   R4  CONTROL: no lake-manifest.json at all (the lock tests' trees) ⇒ proceeds
#   R5  a custom packagesDir in the manifest: olean there ⇒ proceeds; olean only at the DEFAULT dir ⇒ refused (the path is derived, not guessed)
#   R6  the audit arm (X.lean) in a no-mathlib tree ⇒ refused too (`lake env lean` resolves the same workspace)
#   R7  a manifest that does not parse ⇒ proceeds, saying so (a doubt must not block a build; the limit is declared)
#   RM  MUTANT: the check removed from a copy ⇒ R1's case starts lake (R1 is load-bearing)
set -u
SB="${1:-$(cd "$(dirname "$0")" && pwd)/saltbuild.sh}"
# ⛔ A SKIP IS NOT A PASS: exit 3, so a caller that reads only the return code cannot take "nothing ran" for green (the helm's read of #125, LOW 1).
FLOCK="$(command -v flock)" || { echo "SKIP: no flock(1) on PATH — saltbuild itself refuses to run here (exit 3: NOT a pass)"; exit 3; }
TD="$(mktemp -d "${TMPDIR:-/tmp}/sb-mathlib.XXXXXX")"
pass=0; fail=0
ok(){ printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }
cleanup(){ rm -rf -- "${TD:?}"; }
trap cleanup EXIT
H="$TD/home"; mkdir -p "$H/.elan/bin"
# the stub lake: records its pid and argv, then exits with STUB_RC (default 0)
printf '#!/bin/bash\necho $$ > "%s/lake.pid"\nprintf "%%s\\n" "$*" > "%s/lake.args"\nexit "${STUB_RC:-0}"\n' "$TD" "$TD" > "$H/.elan/bin/lake"
chmod +x "$H/.elan/bin/lake"
manifest(){ # manifest <dir> [packagesDir]  — a lake-manifest.json naming mathlib (and one other package)
  mkdir -p "$1"
  if [ -n "${2:-}" ]; then
    printf '{"version":"1.1.0","packagesDir":"%s","packages":[{"name":"mathlib","type":"git"},{"name":"aesop","type":"git"}],"name":"salt","lakeDir":".lake"}\n' "$2" > "$1/lake-manifest.json"
  else
    printf '{"version":"1.1.0","packagesDir":".lake/packages","packages":[{"name":"mathlib","type":"git"},{"name":"aesop","type":"git"}],"name":"salt","lakeDir":".lake"}\n' > "$1/lake-manifest.json"
  fi
}
olean(){ mkdir -p "$1/$2/mathlib/.lake/build/lib/lean"; : > "$1/$2/mathlib/.lake/build/lib/lean/Mathlib.olean"; }
n=0
run(){ # run <repo-dir> [saltbuild args…] -> OUT (stdout+stderr), RC, and lake.pid/lake.args reset first
  local d="$1"; shift; n=$((n+1)); rm -f -- "${TD:?}/lake.pid" "${TD:?}/lake.args"
  LK="$TD/lock-$n"; LOG="$TD/lock-$n.log"
  OUT=$(cd "$d" && HOME="$H" SALTBUILD_LOCK="$LK" SALTBUILD_LOCKLOG="$LOG" SEAT=mathlibtest bash "${SBX:-$SB}" "$@" 2>&1); RC=$?
}
started(){ [ -s "$TD/lake.pid" ]; }

# R1 — no mathlib build
manifest "$TD/r1"; run "$TD/r1"
if [ "$RC" = 77 ] && printf '%s' "$OUT" | command grep -q 'this tree has no mathlib build' && ! started && [ ! -e "$LK.flk" ] && [ ! -d "$LK" ]; then
  ok "R1 no mathlib build ⇒ rc 77, the refusing line, lake never started, no lock taken"
else no "R1 refuse" "rc=$RC started=$(started && echo yes || echo no) lock=$([ -e "$LK.flk" ] && echo made || echo none) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi
printf '%s' "$OUT" | command grep -q -- '--cold' && ok "R1' the refusal names --cold and the copy remedy" || no "R1'" "the refusing line does not name --cold: $OUT"

# R2 — --cold proceeds, and is not handed to lake
run "$TD/r1" --cold Salt.Foo
if [ "$RC" = 0 ] && started && ! command grep -q -- '--cold' "$TD/lake.args" && command grep -q 'Salt.Foo' "$TD/lake.args"; then ok "R2 --cold proceeds, lake runs with the target and WITHOUT --cold ($(cat "$TD/lake.args"))"
else no "R2 cold" "rc=$RC started=$(started && echo yes || echo no) args=$(cat "$TD/lake.args" 2>/dev/null) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi

# R3 — a built tree
manifest "$TD/r3"; olean "$TD/r3" ".lake/packages"; run "$TD/r3" Salt.Foo
if [ "$RC" = 0 ] && started && command grep -q 'Salt.Foo' "$TD/lake.args"; then ok "R3 a built tree proceeds untouched"
else no "R3 built" "rc=$RC started=$(started && echo yes || echo no) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi

# R4 — control: no manifest at all
mkdir -p "$TD/r4"; run "$TD/r4" Salt.Foo
if [ "$RC" = 0 ] && started; then ok "R4 CONTROL: a tree with no lake-manifest.json proceeds"
else no "R4 control" "rc=$RC started=$(started && echo yes || echo no) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi

# R5 — packagesDir from the manifest
manifest "$TD/r5a" "vendor/pkgs"; olean "$TD/r5a" "vendor/pkgs"; run "$TD/r5a" Salt.Foo
if [ "$RC" = 0 ] && started; then ok "R5a a custom packagesDir with the olean THERE proceeds"
else no "R5a" "rc=$RC started=$(started && echo yes || echo no) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi
manifest "$TD/r5b" "vendor/pkgs"; olean "$TD/r5b" ".lake/packages"; run "$TD/r5b" Salt.Foo
if [ "$RC" = 77 ] && ! started; then ok "R5b a custom packagesDir with the olean only at the DEFAULT dir is refused (the path is derived, not guessed)"
else no "R5b" "rc=$RC started=$(started && echo yes || echo no)"; fi

# R6 — the audit arm
run "$TD/r1" Scratch.lean
if [ "$RC" = 77 ] && ! started; then ok "R6 the audit arm (X.lean) in a no-mathlib tree is refused too"
else no "R6 audit" "rc=$RC started=$(started && echo yes || echo no)"; fi
run "$TD/r1" --cap 100 --cold Scratch.lean
if [ "$RC" = 0 ] && started && ! command grep -q -- '--cold' "$TD/lake.args"; then ok "R6' --cold with --cap on the audit arm proceeds, not handed to lake"
else no "R6'" "rc=$RC started=$(started && echo yes || echo no) args=$(cat "$TD/lake.args" 2>/dev/null)"; fi

# R7 — a manifest that does not parse
mkdir -p "$TD/r7"; printf '{ this is not json\n' > "$TD/r7/lake-manifest.json"; run "$TD/r7" Salt.Foo
if [ "$RC" = 0 ] && started && printf '%s' "$OUT" | command grep -q -i 'manifest'; then ok "R7 an unparseable manifest proceeds and SAYS so (a doubt must not block a build)"
else no "R7 unparseable" "rc=$RC started=$(started && echo yes || echo no) :: $(printf '%s' "$OUT" | head -3 | tr '\n' '|')"; fi

# RM — the mutant: the check removed from a copy (the block between the two marker comments), R1's case must now START lake
MUT="$(dirname "$SB")/.saltbuild-mathlib-mutant.$$.sh"
awk '/# >>> NO-MATHLIB-BUILD CHECK/{skip=1} !skip{print} /# <<< NO-MATHLIB-BUILD CHECK/{skip=0}' "$SB" > "$MUT"
if ! cmp -s "$SB" "$MUT" && bash -n "$MUT" 2>/dev/null; then
  ok "RM0 the mutation landed and parses"
  SBX="$MUT" run "$TD/r1" Salt.Foo
  if [ "$RC" = 0 ] && started; then ok "RM1 with the check removed R1's case STARTS lake: R1 is load-bearing"
  else no "RM1 mutant" "rc=$RC started=$(started && echo yes || echo no) :: $(printf '%s' "$OUT" | tail -2 | tr '\n' '|')"; fi
else no "RM0" "the mutation did not land or does not parse — control VOID"; fi
rm -f -- "${MUT:?}"

echo "saltbuild-mathlib-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
