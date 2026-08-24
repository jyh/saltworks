#!/bin/sh
# SELFTEST for hookedit.sh — drives EVERY reachable verdict, not just the two
# the deferral named. A repair is an instrument and inherits
# [a-check-never-shown-to-fail]: a gate only ever run on passing input has not
# been shown to discriminate.
#
# ⭐ THE ARM THAT MATTERS MOST IS ARM 9: A REFUSAL MUST LEAVE THE FILE
#   BYTE-IDENTICAL. A gate that refuses AND mutates is worse than no gate — it
#   reports "REFUSED" while the damage is already on disk.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOL="$HERE/hookedit.sh"
PASS=0; FAIL=0
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT
export CLAUDE_MEMORY_DIR="$T"

mkfix() {  # build a fresh fixture index
  cat > "$T/MEMORY.md" <<'FIX'
# Memory index — fixture
- [Alpha card](alpha.md) — a hook of a known and deliberate length, padded here.
- [Beta card](beta.md) — second hook.
- [Gamma emoji](gamma.md) — hook with emoji so the tool is driven on real bytes.
FIX
}
say() { printf '  %s %s\n' "$1" "$2"; }
ck() { # ck <label> <expected-rc> <actual-rc>
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); say "OK  " "$1 (rc=$3)"
  else FAIL=$((FAIL+1)); say "FAIL" "$1 (expected rc=$2, got rc=$3)"; fi
}

# ARM 1 — shorter replacement PASSES
mkfix; printf -- '- [Alpha card](alpha.md) — short.\n' > "$T/r"
"$TOOL" alpha "$T/r" >/dev/null 2>&1; ck "ARM1 shorter replacement applies" 0 $?

# ARM 2 — longer replacement is REFUSED (the deferral's second arm)
mkfix; printf -- '- [Alpha card](alpha.md) — %s\n' "$(printf 'x%.0s' $(seq 1 300))" > "$T/r"
"$TOOL" alpha "$T/r" >/dev/null 2>&1; ck "ARM2 longer replacement REFUSED" 5 $?

# ARM 3 — longer replacement PASSES when growth is declared
mkfix; "$TOOL" alpha "$T/r" --grow "the reason" >/dev/null 2>&1
ck "ARM3 longer + --grow applies" 0 $?

# ARM 4 — unknown slug REFUSED
mkfix; printf -- '- [Nope](nope.md) — x\n' > "$T/r2"
"$TOOL" nosuchcard "$T/r2" >/dev/null 2>&1; ck "ARM4 unknown slug REFUSED" 3 $?

# ARM 5 — ambiguous slug REFUSED
mkfix; printf -- '- [Alpha dup](alpha.md) — duplicate hook.\n' >> "$T/MEMORY.md"
"$TOOL" alpha "$T/r" >/dev/null 2>&1; ck "ARM5 ambiguous slug REFUSED" 3 $?

# ARM 6 — empty replacement REFUSED
mkfix; : > "$T/empty"
"$TOOL" alpha "$T/empty" >/dev/null 2>&1; ck "ARM6 empty replacement REFUSED" 3 $?

# ARM 7 — over-cap REFUSED even though the hook itself SHRINKS
mkfix; printf -- '- [Alpha card](alpha.md) — tiny.\n' > "$T/r3"
IDXLIM=10 "$TOOL" alpha "$T/r3" >/dev/null 2>&1; ck "ARM7 over-cap REFUSED (hook shrank)" 4 $?

# ARM 8 — unset CLAUDE_MEMORY_DIR REFUSES rather than guessing
mkfix; ( unset CLAUDE_MEMORY_DIR; "$TOOL" alpha "$T/r" >/dev/null 2>&1 ); \
  [ $? -ne 0 ] && { PASS=$((PASS+1)); say "OK  " "ARM8 unset env REFUSES"; } \
              || { FAIL=$((FAIL+1)); say "FAIL" "ARM8 unset env did NOT refuse"; }

# ARM 9 — ⭐ A REFUSAL MUST NOT MUTATE. Byte-compare before and after.
mkfix; cp "$T/MEMORY.md" "$T/before"
printf -- '- [Alpha card](alpha.md) — %s\n' "$(printf 'y%.0s' $(seq 1 300))" > "$T/r4"
"$TOOL" alpha "$T/r4" >/dev/null 2>&1
if cmp -s "$T/before" "$T/MEMORY.md"; then PASS=$((PASS+1)); say "OK  " "ARM9 refusal left the file BYTE-IDENTICAL"
else FAIL=$((FAIL+1)); say "FAIL" "ARM9 refusal MUTATED the index"; fi

# ARM 10 — a PASS must actually change the file (treatment applied, not reported)
mkfix; cp "$T/MEMORY.md" "$T/before"
printf -- '- [Alpha card](alpha.md) — s.\n' > "$T/r5"
"$TOOL" alpha "$T/r5" >/dev/null 2>&1
if cmp -s "$T/before" "$T/MEMORY.md"; then FAIL=$((FAIL+1)); say "FAIL" "ARM10 pass did NOT change the file"
else PASS=$((PASS+1)); say "OK  " "ARM10 pass changed the file"; fi

# ARM 11 — emoji hook: the tool must handle real bytes, not just ASCII
mkfix; printf -- '- [Gamma emoji](gamma.md) - x\n' > "$T/r6"
"$TOOL" gamma "$T/r6" >/dev/null 2>&1; ck "ARM11 emoji-bearing hook edits cleanly" 0 $?

# ARM 12 — NEGATIVE CONTROL ON THE HARNESS ITSELF.
# ⛔ THE FIRST VERSION OF THIS ARM WAS VACUOUS: it asserted `rc != 99`, which no
#   real run can violate — a check that CANNOT FAIL was never a check, and it sat
#   at the bottom of a 12/12 board looking like coverage. Caught on the same day
#   it was written, by re-reading my own output instead of its total.
# ⇒ The real question is whether `ck` DISCRIMINATES. Drive it with a deliberately
#   wrong expectation in a SUBSHELL (so the live tally is untouched) and require
#   the word FAIL to appear.
probe=$( PASS=0; FAIL=0; ck "probe" 99 0 2>&1 )
case "$probe" in
  *FAIL*) PASS=$((PASS+1)); say "OK  " "ARM12 harness DISCRIMINATES (wrong expectation -> FAIL)" ;;
  *)      FAIL=$((FAIL+1)); say "FAIL" "ARM12 harness reported [$probe] for a wrong expectation" ;;
esac

echo "hookedit_selftest: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
