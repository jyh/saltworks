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
# ⓘ THE HUB-GRAPH LINE, and it is an OBSERVATION not a verdict (see the block at
#   the loop). A module can be kernel-green and still be invisible to `lake build`
#   (`import-owed-means-unbuilt`), so this reads SaltWorks.lean and REPORTS the
#   fact per module — because the day it was omitted I asserted coverage that did
#   not exist, and the day it shouted I reversed a peer's deliberate design.
#   ⛔ THIS COMMENT ITSELF SAID "NOT DONE HERE" WHILE THE CHECK WAS DONE HERE,
#   twelve lines below. Written in one sitting, contradictory in the same file,
#   and found only when I grepped my own script for a warning glyph. Prose about
#   an instrument rots exactly like prose about a measurement.
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
  # ⛔⛔ THIS LINE IS AN OBSERVATION, NOT A VERDICT — and the demotion is MEASURED.
  # It used to print "⚠️ UNROOTED — invisible to `lake build`", i.e. it called every
  # unrooted module a defect. On 2026-08-09 13:46 that framing cost a peer their
  # design: `AccountMeasure` was unrooted ON PURPOSE (an #eval-only module prints on
  # every fleet build), compiler had SAID SO in core-account §1 two minutes earlier,
  # I flagged it anyway without opening the file, re-raised it, and it was rooted —
  # which then falsified §1's explaining sentence inside a live citation target.
  # 🔑 A CHECK WITH NO LEGITIMATE-NEGATIVE CASE DOES NOT DETECT A DEFECT. It detects
  #   a PROPERTY and calls it one. Whether "not in the hub graph" is wrong is the
  #   AUTHOR's call — this script reports the fact and takes no position.
  if [ -n "$root" ]; then
    echo "     in hub graph: SaltWorks.lean:${root%%:*}"
  else
    echo "     not in hub graph (a full build does not cover it; whether that is"
    echo "     intended is the module author's call — this gate takes no position)"
  fi
done
exit $rc
