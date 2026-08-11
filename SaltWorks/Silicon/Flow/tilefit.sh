#!/bin/sh
# tilefit.sh — run a LibreLane hardening ON TINYTAPEOUT'S REAL POWER GRID.
#
#   sh SaltWorks/Silicon/Flow/tilefit.sh <config.json> <run-tag> <1x1|1x2|2x2|4x2|6x2|8x2>
#
# SILICON seat, 2026-08-10. This exists because of three things that cost me
# real time today, each recorded here so it costs nobody else any.
#
# ⛔ (1) THE DEF WAS NOT A FILE I OWNED, IT WAS A FILE I HAPPENED TO HAVE.
#   `tt_block_*_pg.def` sat in a SESSION scratchpad. The tile-fit results in
#   docs/ndf-account-priced-half.md rest on it, and a session end would have
#   left those numbers unreproducible with no error anywhere. The DEFs ship
#   PUBLICLY in TinyTapeout's tt-support-tools; this script FETCHES them.
#   ⇒ Bank the ACQUISITION, not the artifact.
#
# ⛔ (2) `librelane --dockerized` EXITED 0 AND RAN NOTHING.
#   It needs a TTY. Backgrounded, it printed "the input device is not a TTY"
#   and returned SUCCESS. I found it only because the metrics file was absent.
#   ⇒ This script drives docker itself, and its verdict is THE PAYLOAD
#     (metrics.json present and parseable), never the exit code.
#
# ⚠️ (3) A TILE-FIT IS A CONTROLLED PAIR OR IT IS NOTHING.
#   The comparison that matters is "same design, same knobs, LibreLane's PDN
#   vs TT's real grid" — ONE line of config differing (FP_DEF_TEMPLATE). Run
#   the baseline through THIS script too, not from memory of an older run:
#   otherwise a difference in the harness reads as a difference in the grid.
#
# 📌 AND WHAT A GREEN HERE IS NOT: TinyTapeout's CI verdict on the fabrication
#   path. This is a LOCAL run at our committed knobs. It can pass while TT's
#   own flow fails, and TT's result is theirs, not ours.
set -eu

CFG="${1:?usage: tilefit.sh <config.json> <run-tag> <tile>}"
TAG="${2:?usage: tilefit.sh <config.json> <run-tag> <tile>}"
TILE="${3:?usage: tilefit.sh <config.json> <run-tag> <tile>}"

IMAGE="${LIBRELANE_IMAGE:-ghcr.io/librelane/librelane:3.0.5}"
TTS="${TT_SUPPORT_TOOLS:-https://github.com/TinyTapeout/tt-support-tools}"
WORK="$(cd "$(dirname "$CFG")" && pwd)"
DEF="tt_block_${TILE}_pg.def"

# The PDK must be the PINNED one. Resolve the directory that actually CONTAINS
# sky130A rather than assuming volare's nesting, which differs between the host
# layout and the path LibreLane records inside the container.
PDK="${PDK_DIR:-}"
if [ -z "$PDK" ]; then
  PDK=$(find "$HOME/.volare" -maxdepth 6 -type d -name sky130A 2>/dev/null | head -1)
  PDK=${PDK%/sky130A}
fi
[ -n "$PDK" ] && [ -d "$PDK/sky130A" ] || { echo "⛔ no sky130A under \$HOME/.volare — set PDK_DIR"; exit 2; }

# (1) Fetch the DEF if we do not have it. Public repo; a sparse shallow clone.
if [ ! -f "$WORK/$DEF" ]; then
  echo "→ $DEF absent; fetching from tt-support-tools"
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  git clone --depth 1 --quiet "$TTS" "$TMP/tts"
  found=$(find "$TMP/tts" -name "$DEF" | head -1)
  [ -n "$found" ] || { echo "⛔ $DEF not found in tt-support-tools — check the tile name"; exit 2; }
  cp "$found" "$WORK/$DEF"
  echo "  fetched $(cd "$TMP/tts" && git rev-parse --short HEAD):$DEF"
fi

grep -q "FP_DEF_TEMPLATE" "$CFG" || {
  echo "⛔ $CFG sets no FP_DEF_TEMPLATE — this would silently be an ORDINARY run."
  echo "   Add: \"FP_DEF_TEMPLATE\": \"/work/$DEF\"   (the container sees $WORK as /work)"
  exit 2; }

docker run --rm -v "$WORK":/work -w /work -v "$PDK":/pdk "$IMAGE" \
  librelane --pdk-root /pdk --run-tag "$TAG" "/work/$(basename "$CFG")" \
  > "$WORK/$TAG.log" 2>&1 || true          # exit code is NOT the verdict — see (2)

# (2) THE VERDICT IS THE PAYLOAD.
M="$WORK/runs/$TAG/final/metrics.json"
[ -f "$M" ] || { echo "⛔ $TAG produced NO metrics.json — the run did not happen."
                 echo "   last lines of $TAG.log:"; tail -5 "$WORK/$TAG.log"; exit 1; }
python3 - "$M" "$TAG" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
g=lambda k: m.get(k)
print(f"✅ {sys.argv[2]} — metrics present")
for k,l in [("design__die__area","die um2"),("design__instance__area__stdcell","stdcell um2"),
            ("design__instance__count__sequential","flops"),("timing__setup__ws","setup ws ns"),
            ("timing__hold__ws","hold ws ns"),("design__max_slew_violation__count","max-slew"),
            ("magic__drc_error__count","magic DRC"),("klayout__drc_error__count","klayout DRC"),
            ("design__lvs_error__count","LVS"),("antenna__violating__nets","antenna nets")]:
    if g(k) is not None: print(f"   {l:<18} {g(k)}")
PY
