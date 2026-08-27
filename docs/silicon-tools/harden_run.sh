#!/bin/bash
# NDF 6x2 HARDEN — one arm per invocation.  usage: harden_run.sh <tag>  — tag matches a config in docs/silicon-runs-0827/ (config-<tag>.json)
# Ordered by the helm 11:5x: the clicked artifact is the paid 6x2 NDF, so the ①d knobs
# must be measured against the NDF's OWN baseline on a NAMED DIGEST — deltas against a
# provable toolchain only. Top module tt_um_saltworks_ndf_c32, per info.yaml at 7d2b275.
set -u
TAG="${1:?usage: harden_run.sh <tag>  — tag matches a config in docs/silicon-runs-0827/ (config-<tag>.json)}"
LOCK=/tmp/salt-fleet-build.lock
IMG=ghcr.io/librelane/librelane:3.0.5
WANT_DIGEST=sha256:ecabd075d0ddf6a2bd1cd4a32109c7dbb861ec007f7e4e423a9a081f8d23b8e2
PDKV=8afc8346a57fe1ab7934ba5a6056ea8b43078e71   # TT’s EXACT PDK for the submitted chip (pdk.json), NOT the (A) runs’ c6d73a35
W="${WORKDIR:?WORKDIR must be set — the run tree is machine-local and has no public default}"
say(){ printf '%s %s\n' "$(date +%H:%M:%S)" "$*"; }

[ -f "$W/config-$TAG.json" ] || { say "ABORT: no config-$TAG.json"; exit 2; }
[ -f "$W/tt_block_6x2_pg.def" ] || { say "ABORT: 6x2 power-grid DEF absent — this would silently be an ORDINARY run"; exit 2; }
[ -d "$HOME/.volare/volare/sky130/versions/$PDKV" ] || { say "ABORT: PDK $PDKV absent — this is TT's PDK for the submitted chip and the reproduction claim depends on it"; exit 2; }

# saltqueue lives in the repo's tools/ dir, NOT beside this script — it was `git mv`d there
# when the build queue was integrated, and this consumer's sibling-relative lookup broke
# silently. Derive it from the repo root so a future move breaks LOUDLY at the git level.
SQ="$(cd -P "$(dirname "$0")/../.." && pwd)/tools/saltqueue.sh"
# ⛔ THE CLASS BELONGS IN THE CALL, NOT IN THE TOOL — helm amendment 16:5x to ruling ③.
#   TAKING a ticket stays non-negotiable (an unticketed marker-holder makes the census a
#   lie). The CLASS does not ride along: P1 is for TAPE-OUT CAMPAIGN work, and this runner
#   is also used for self-checks, which are not that.
#   ⇒ ***A PRIORITY BAKED INTO A TOOL IS CLAIMED BY EVERY USE OF THE TOOL, INCLUDING THE
#      USES THAT DO NOT DESERVE IT.*** Measured 16:4x: a hardcoded P1 self-check outranked a
#      peer's helm-requested measurement for 36 minutes. Default P2; type PRIO=P1 for campaign runs.
if [ -r "$SQ" ]; then . "$SQ"; q_take "${PRIO:-P2}" "${SEAT:-${SELF:-silicon}}"; trap 'q_release' EXIT INT TERM; q_wait
else
  # ⛔ NAME THE PATH. Without it, "absent" and "resolved to the wrong place" are the SAME
  #   observable — which is how this runner ran unticketed after saltqueue.sh moved.
  say "saltqueue.sh NOT FOUND at ${SQ} — proceeding UNTICKETED (marker still excludes;
       the census will not show this run — helm ruling 12:0x ③)"
fi

WAITED=0
until mkdir "$LOCK" 2>/dev/null; do
  [ $WAITED -ge 5400 ] && { say "ABORT: marker not obtained in ${WAITED}s (holder $(cat $LOCK/pid 2>/dev/null))"; exit 75; }
  sleep 10; WAITED=$((WAITED+10))
done
echo $$ > "$LOCK/pid"
trap 'st=$?; [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ] && rm -rf "$LOCK"; command -v q_release >/dev/null 2>&1 && q_release; say "MARKER RELEASED (exit $st)"' EXIT INT TERM
say "MARKER TAKEN pid $$ after ${WAITED}s — held for the WHOLE window (43GB law)"

open -a Docker 2>/dev/null
n=0; until docker info >/dev/null 2>&1 || [ $n -ge 180 ]; do sleep 3; n=$((n+3)); done
docker info >/dev/null 2>&1 || { say "ABORT: NO DAEMON after ${n}s"; exit 1; }
GOT=$(docker image inspect $IMG --format '{{index .RepoDigests 0}}' 2>/dev/null)
say "daemon up (${n}s); image $GOT"
case "$GOT" in
  *"$WANT_DIGEST") say "DIGEST MATCHES the five (A) runs — the NDF pair is comparable to them AND to each other" ;;
  *) say "ABORT: DIGEST DIFFERS ($WANT_DIGEST expected). A toolchain change makes the delta meaningless."; exit 3 ;;
esac

say "FLOW START — $TAG  (top tt_um_saltworks_ndf_c32, 6x2 = 1030.40 x 225.76, TT power grid)"
docker run --rm -v "$W":/work -w /work -v "$HOME/.volare":/pdkroot "$IMG" \
  librelane --pdk-root /pdkroot/volare/sky130/versions/$PDKV \
  --run-tag "$TAG" "/work/config-$TAG.json" > "$W/$TAG-flow.log" 2>&1
RC=$?
say "docker rc=$RC   (⛔ NOT the verdict — the payload is metrics.json; --dockerized once exited 0 having run nothing)"
tail -4 "$W/$TAG-flow.log"

R="$W/runs/$TAG"
if [ -f "$R/final/metrics.json" ]; then
  cp "$R/final/metrics.json" "$W/$TAG-metrics.json"
  say "METRICS captured"
  # ⛔ VERIFY THE TREATMENT APPLIED — read the run's OWN resolved values, never the config I wrote.
  python3 - "$R" <<'PY'
import json, sys
r = json.load(open(sys.argv[1] + '/resolved.json'))
print("  treatment as RESOLVED BY THE FLOW:")
for k in ('DESIGN_NAME','CLOCK_PERIOD','RSZ_CORNERS','PL_RESIZER_HOLD_SLACK_MARGIN',
          'GRT_RESIZER_HOLD_SLACK_MARGIN','STA_CORNERS','DEFAULT_CORNER'):
    v = r.get(k)
    if k == 'STA_CORNERS' and isinstance(v, list): v = f'{len(v)} corners'
    if k == 'RSZ_CORNERS' and isinstance(v, list): v = f'{len(v)} corners'
    print(f"    {k:32s} {v}")
PY
  say "--- REPRODUCTION GATE: my resolved.json vs the SUBMITTED chip's ---"
  python3 "$(cd -P "$(dirname "$0")" && pwd)/resolved_diff.py" \
    "${TTREF:?TTREF must be set: path to the submitted run resolved.json}" "$R/resolved.json"
  say "resolved_diff rc=$?  (0 = configured exactly like the submitted run)"
  python3 - "$W/$TAG-metrics.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for k in ('design__max_slew_violation__count','design__max_cap_violation__count',
          'design__max_fanout_violation__count','timing__setup__ws','timing__hold__ws',
          'design__instance__area','design__instance__count__sequential',
          'magic__drc_error__count','klayout__drc_error__count','design__lvs_error__count',
          'antenna__violating__nets','design__die__area'):
    print(f"    {k:46s} {d.get(k)}")
PY
else
  say "NO metrics.json — A NULL IS A FINDING. inspect $W/$TAG-flow.log"
fi

say "--- daemon down + RSS check ('daemon down' is not 'memory returned' — 774MB lesson) ---"
osascript -e 'tell application "Docker Desktop" to quit' 2>/dev/null
n=0; until ! docker info >/dev/null 2>&1 || [ $n -ge 90 ]; do sleep 3; n=$((n+3)); done
for p in $(pgrep -f 'Docker Desktop|com.docker.build' 2>/dev/null); do
  [ "$p" != "918" ] && kill -TERM "$p" 2>/dev/null
done
sleep 5
say "residual docker RSS: $(ps -Ao rss,comm | grep -iE 'docker|vmnetd' | awk '{s+=$1} END {printf "%.0f MB", s/1024}')"
say "ARM $TAG DONE"
