#!/bin/sh
# fallback_addr_test.sh — drive the index arm's ADDRESS-PROVENANCE branches on the SHIPPED bytes.
#
# ⛔ WHY PROVENANCE AND NOT REACH. evidence, 18:39, amending my own 18:3x law and correcting it one
#   step further than I had taken it: `COVERAGE-OK` proves an address REACHES; it does not prove the
#   address was DERIVED rather than REMEMBERED. And the tell is invisible BY CONSTRUCTION — the
#   env-captured branch answers first, so a derivation resolving to a path that does not exist is
#   never observed. ***A FALLBACK THAT SILENTLY SUCCEEDS CONVERTS A BROKEN ADDRESS INTO A WORKING
#   ONE AND DESTROYS THE EVIDENCE THAT IT BROKE.*** "I fell back" is the datum.
# ⚠️ The tag rides INSIDE the existing index field, never as its own line: a per-pass line nobody can
#   skip is another silence (evidence's transition rule, adopted the evening it was written).
# ⛔ EXTRACTED, NOT RESTATED: a copy of the logic in a test passes forever while the tool drifts.
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
SRC="$HERE/fallback-silicon.sh"
[ -r "$SRC" ] || { echo "fallback_addr_test: cannot read $SRC" >&2; exit 2; }
BLOCK=$(awk '/^  _idxderived=/{f=1} f{print} /^  idx="\$idx \| \$_prov"$/{if(f) exit}' "$SRC")
case "$BLOCK" in
  *_prov*) : ;;
  *) echo "⛔ REFUSED: provenance block not found in fallback-silicon.sh — the anchor moved." >&2
     echo "   This test is STALE, not passing." >&2; exit 2 ;;
esac

T="${TMPDIR:-/tmp}/fallback-addr.$$"; mkdir -p "$T/live/projects/-slug/memory" "$T/other/projects/-slug/memory" || exit 2
trap 'rm -rf "$T"' EXIT INT TERM
PASS=0; FAIL=0
run() { sh -c "idx=IDXBODY; _idxcfgsrc=env; IDX='$1'; CLAUDE_MEMORY_DIR='$2'; _idxcfg='$3'; _idxslug=-slug; $BLOCK; printf '%s' \"\$idx\""; }
arm() { name="$1"; want="$2"; got="$3"
  case "$got" in
    *"$want"*) PASS=$((PASS+1)); printf '  ✅ %-34s %s\n' "$name" "$want" ;;
    *) FAIL=$((FAIL+1)); printf '  ⛔ %-34s WANTED %s\n       got: %s\n' "$name" "$want" "$got" ;;
  esac; }

echo "index-arm address provenance, on the shipped block:"
arm "env-captured, derivation DEAD"    "deriv-DEAD"      "$(run "$T/live/projects/-slug/memory/MEMORY.md" "$T/live/projects/-slug/memory" "$T/nowhere")"
touch "$T/live/projects/-slug/memory/MEMORY.md"
arm "env-captured, derivation AGREES"  "deriv-AGREES"    "$(run "$T/live/projects/-slug/memory/MEMORY.md" "$T/live/projects/-slug/memory" "$T/live")"
touch "$T/other/projects/-slug/memory/MEMORY.md"
arm "derivation DISAGREES (2 live)"    "deriv-DISAGREES" "$(run "$T/live/projects/-slug/memory/MEMORY.md" "$T/live/projects/-slug/memory" "$T/other")"
arm "no env var: address is DERIVED"   "addr=derived"    "$(run "$T/live/projects/-slug/memory/MEMORY.md" "" "$T/live")"
# the tag must never REPLACE the measurement it annotates
arm "annotates, never replaces"        "IDXBODY"         "$(run "$T/live/projects/-slug/memory/MEMORY.md" "$T/live/projects/-slug/memory" "$T/live")"

echo "fallback_addr_test: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ] || exit 1
