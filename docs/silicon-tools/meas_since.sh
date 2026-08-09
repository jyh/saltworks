#!/bin/sh
# meas_since.sh — run the MEAS gate over every HDL module touched since a BASELINE,
# and get the baseline question right.
#
#   sh docs/silicon-tools/meas_since.sh <baseline-sha>
#
# ⛔⛔ TWO DEFECTS THIS ENCODES, both MEASURED on 2026-08-09, both silent:
#
# (1) THE BASELINE IS THE LAST TIME THE DUTY RAN — NOT MY LAST COMMIT (10:08).
#     I had been diffing `<my last commit>..HEAD`. The moment I landed my own
#     work, my "since" marker jumped FORWARD over a peer's landing my gate had
#     never checked, and the loop printed `to MEAS: none` — which is exactly what
#     a genuinely clean check prints. A seat that both PERFORMS a gate and LANDS
#     its own commits will drift its own baseline every single time it pushes.
#     ⇒ pass the sha of the last MEAS VERDICT, and this script ECHOES the range
#       so the verdict can never be read without its baseline.
#
# (2) A DELETED MODULE IS NOT A MEAS OBLIGATION (12:1x). `git diff --name-only`
#     lists deletions, so retiring a module (council ruling (c) struck
#     `ImmediateScope.lean`) fed a dead path to the gate. `meas_build.sh` REFUSED
#     correctly — "no such file" — but a refusal in the loop reads as a FAILED
#     GATE, and a false alarm on a duty that fires all day is how a real alarm
#     gets ignored. Deletions are reported as RETIRED, separately, and do not
#     touch the exit status.
#
# ⚠️ NOT DONE HERE: the rooting check. A module can be kernel-green and still be
#   invisible to `lake build` (see `import-owed-means-unbuilt`). That check reads
#   SaltWorks.lean and is printed per-module below, because the day it was
#   omitted I asserted coverage that did not exist.
set -u

BASE="${1:?usage: meas_since.sh <baseline-sha — the sha of your LAST MEAS VERDICT>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
cd "$REPO" || exit 2

git rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || {
  echo "⛔ meas_since: '$BASE' is not a commit in this repo — refusing to guess a baseline"
  exit 2
}

HEAD_SHA=$(git rev-parse --short HEAD)
echo "MEAS range ${BASE}..${HEAD_SHA}   (baseline = last MEAS verdict, NOT last commit)"

changed=$(git diff --name-only "$BASE..HEAD" -- 'SaltWorks/HDL/*.lean' | sort -u)
[ -n "$changed" ] || { echo "  nothing touched in SaltWorks/HDL since $BASE"; exit 0; }

rc=0
for f in $changed; do
  if [ ! -f "$f" ]; then
    echo "  ⓘ RETIRED (deleted, not a gate obligation): $f"
    continue
  fi
  sh "$HERE/meas_build.sh" "$f" || rc=1
  b=$(basename "$f" .lean)
  root=$(grep -n "HDL\.$b\$" SaltWorks.lean 2>/dev/null | head -1)
  if [ -n "$root" ]; then
    echo "     rooted: SaltWorks.lean:${root%%:*}"
  else
    echo "     ⚠️ UNROOTED — invisible to \`lake build\`; a full-build green does NOT cover it"
  fi
done
exit $rc
