#!/bin/bash
# check_fabricated_fixture.sh — CONFORMANCE of the vendored fabricated RTL against the EXTERNAL ref.
#
# ⛔⛔ WHY THIS EXISTS, AND WHY IT DOES NOT READ THE LOCAL SHUTTLE CLONE (evidence, lead, 09/07):
#   "A gate comparing an artifact to the source that PRODUCED it proves CUSTODY, never CONFORMANCE;
#    the external ref is the only authority here."
#   The fixture was produced FROM the local clone. Checking it against that clone re-asks the
#   question the copy already answered. The authority is github.com/jyh/tt-neural-dataflow-fabric.
#
# ⛔ ABSTAIN IS NOT A PASS. With no network / no gh / no auth this CANNOT reach the authority, and
#   it exits 3 saying so. A checker that silently passes when it cannot see its subject is worse
#   than absent: it converts "I did not look" into "I looked and it was fine".
#
# exit 0 CONFORM · 1 MISMATCH (or a pin the fixture fails locally) · 2 usage/setup · 3 ABSTAIN
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
DIR="${1:-$ROOT/SaltWorks/Silicon/Fabricated/01e19f7}"
PIN="$DIR/PIN.psv"
[ -f "$PIN" ] || { echo "⛔ SETUP: no PIN.psv at $PIN"; echo "check_fabricated_fixture EXIT=2"; exit 2; }

# '|' delimited ON PURPOSE: a TAB is IFS whitespace, so runs collapse and EMPTY FIELDS VANISH,
# landing a later column in an earlier variable. Fields are read with IFS='|' and nothing else.
REF=$(sed -n 's/^# ref|//p' "$PIN" | head -1)
# ⛔ THE DELIMITER BUG THIS LINE ALREADY HAD, KEPT AS A COMMENT BECAUSE IT IS THE LESSON:
#   this was written `sed -n 's|^# repo|https://github.com/||p'` — '|' as BOTH the sed delimiter
#   and a literal in the pattern. sed errored, REPO came back EMPTY, and a `${REPO:-<default>}`
#   fallback supplied the right answer anyway, so the gate PASSED and printed the correct repo.
#   ⇒ 🔑 A BROKEN EXTRACTION THAT LANDS ON A CORRECT DEFAULT IS INVISIBLE. The default is deleted:
#     an unparseable pin must REFUSE, because the one case that matters is a pin naming a repo
#     that is NOT the default -- exactly where the fallback would have checked the wrong object.
REPO=$(sed -n 's%^# repo|https://github.com/%%p' "$PIN" | head -1)
[ -n "$REPO" ] || { echo "⛔ SETUP: no parseable '# repo|https://github.com/<owner>/<name>' line in $PIN"; echo "check_fabricated_fixture EXIT=2"; exit 2; }
case "$REF" in
  [0-9a-f]*) [ ${#REF} -eq 40 ] || { echo "⛔ SETUP: ref is not a full 40-hex sha: '$REF'"; echo "check_fabricated_fixture EXIT=2"; exit 2; } ;;
  *) echo "⛔ SETUP: no '# ref|<sha>' line in $PIN"; echo "check_fabricated_fixture EXIT=2"; exit 2 ;;
esac
echo "FIXTURE  $DIR"
echo "PINNED   $REF   (repo $REPO)"
echo "⛔ THIS IS THE FABRICATED DESIGN, NOT HEAD — the pin is a SHA and never a branch."

# ---- ARM 1: LOCAL INTEGRITY (custody). Cheap, and it runs even when the authority is unreachable.
local_bad=0; n=0
while IFS='|' read -r f bytes blob csha; do
  case "$f" in ''|'#'*|file) continue ;; esac
  n=$((n+1)); p="$DIR/src/$f"
  [ -f "$p" ] || { echo "  ⛔ $f: ABSENT from the fixture"; local_bad=$((local_bad+1)); continue; }
  ab=$(git hash-object "$p")
  ac=$( (sha256sum "$p" 2>/dev/null || shasum -a 256 "$p") | cut -d' ' -f1 )
  if [ "$ab" != "$blob" ] || [ "$ac" != "$csha" ]; then
    echo "  ⛔ $f: LOCAL BYTES DO NOT MATCH THIS FIXTURE'S OWN PIN"; local_bad=$((local_bad+1))
  fi
done < "$PIN"
[ "$n" -gt 0 ] || { echo "⛔ SETUP: PIN.psv lists no files"; echo "check_fabricated_fixture EXIT=2"; exit 2; }
if [ "$local_bad" -gt 0 ]; then
  echo "⛔ REFUSED: $local_bad/$n file(s) fail the fixture's OWN pin — the copy is corrupt."
  echo "check_fabricated_fixture EXIT=1"; exit 1
fi
echo "ARM 1 custody   : $n/$n match the fixture's own pin"

# ---- ARM 2: CONFORMANCE against the EXTERNAL ref. This is the arm that matters.
command -v gh >/dev/null 2>&1 || { echo "⚠️ ABSTAIN: gh absent — the AUTHORITY WAS NOT CONSULTED."; echo "check_fabricated_fixture EXIT=3"; exit 3; }
if ! gh api "repos/$REPO/commits/$REF" --jq '.sha' >/dev/null 2>&1; then
  echo "⚠️ ABSTAIN: cannot reach $REPO@$REF (offline, unauthenticated, or repo moved)."
  echo "   ⛔ THIS IS NOT A PASS. Nothing was compared against the authority."
  echo "check_fabricated_fixture EXIT=3"; exit 3
fi
rem_bad=0
while IFS='|' read -r f bytes blob csha; do
  case "$f" in ''|'#'*|file) continue ;; esac
  rsha=$(gh api "repos/$REPO/contents/src/$f?ref=$REF" --jq '.sha' 2>/dev/null)
  if [ -z "$rsha" ]; then
    echo "  ⚠️ $f: the authority returned nothing for src/$f@$REF"; rem_bad=$((rem_bad+1)); continue
  fi
  if [ "$rsha" != "$blob" ]; then
    echo "  ⛔ $f: CONFORMANCE FAILURE — external blob $rsha, fixture pins $blob"; rem_bad=$((rem_bad+1))
  fi
done < "$PIN"
if [ "$rem_bad" -gt 0 ]; then
  echo "⛔ REFUSED: $rem_bad/$n file(s) DISAGREE WITH THE EXTERNAL REF."
  echo "   ⛔ DO NOT 'fix' this by re-copying: if the external ref moved, that is a NEW fixture"
  echo "      directory beside this one, never an edit to this one (condition 2)."
  echo "check_fabricated_fixture EXIT=1"; exit 1
fi
echo "ARM 2 conformance: $n/$n match $REPO@${REF:0:7} AT THE AUTHORITY"
echo "✅ CONFORM — the vendored bytes are the fabricated bytes."
echo "check_fabricated_fixture EXIT=0"
