#!/bin/bash
# harden.sh — SILICON seat: run the REAL LibreLane flow on one RTL module.
#
#   ./harden.sh slicea16bma            # 25 MHz default
#   CLOCK_PERIOD=20 ./harden.sh dmem16
#
# Companion to `synth.sh`. synth.sh answers "what does it cost in cells";
# THIS answers "does it place, route, close timing, and pass DRC/LVS" — and
# those two answers differ by about 1.55x in area, measured twice on 8/8.
#
# ⛔ WHY THIS FILE EXISTS: on 2026-08-08 I brought LibreLane up and HAND-WROTE
# the flow config instead of starting from the one already committed at
# Flow/librelane/config.json, and I omitted `MAX_FANOUT_CONSTRAINT: 10`.
#
# ⇒ "COMMIT AN EXECUTABLE, NOT A PATTERN" HAS A SIBLING: START FROM THE
#   COMMITTED CONFIG, DO NOT RETYPE IT. Every run through the committed
#   `synth.sh` was clean; the two through a config I typed fresh diverged from
#   the seat's own settings. The cure is to have nothing to type.
#
# ⚠️⚠️ BUT DO NOT BELIEVE THE OBVIOUS STORY — I TESTED IT AND IT IS FALSE.
# I suspected the omission had CAUSED the 1,678 max-slew violations and said so
# on the bus. A controlled pair (identical inputs, one line changed) came back
# BIT-IDENTICAL — same slew count, same area, same setup slack to 15 digits:
#
#     no constraint      slew 1678 · cap 39 · fanout 11 · 45205.9 µm²
#     MAX_FANOUT 10      slew 1678 · cap 39 · fanout 11 · 45205.9 µm²
#
# ⇒ ***THE DRV DEBT IS REAL AND IS THE DESIGN'S, NOT THE CONFIG'S.*** The
#   constraint is right to set — it is the seat's own value — but it fixes
#   nothing here.
#
# 🔑 AND THE DISCRIMINATING DATUM WAS ALREADY IN THE METRICS BEFORE I RAN THE
#   EXPERIMENT: `max_fanout_violation__count` is ELEVEN while slew is 1,678.
#   Fanout was already nearly clean, so a fanout constraint could never have
#   been the lever. I reasoned from "the netlist has 54-load nets" and never
#   read the counter that separates the two failure modes. Four minutes spent
#   answering a question the metrics had already answered.
#
# ⚠️ THE PDK MUST BE WRITABLE AND MUST NOT BE THE FLEET'S.
# LibreLane creates `ciel/` INSIDE the PDK directory, so a read-only mount fails
# with `Errno 30`. The fleet's pinned PDK at ~/.volare is SHARED — other seats
# synthesize against it — so this script mounts a COPY and never the original.
#
# ⚠️ SCOPE: this uses FP_CORE_UTIL sizing, NOT TinyTapeout's `FP_SIZING:
# absolute` at a fixed tile die. It yields trustworthy CELL AREA and timing; it
# is NOT a tile-fit test. For that, set the die to the real tile geometry.
set -e -u

TOP="${1:?usage: harden.sh <top-module>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../RTL"
IMAGE="${IMAGE:-ghcr.io/librelane/librelane:3.0.5}"
PDK_VER="${PDK_VER:-c6d73a35f524070e85faff4a6a9eef49553ebc2b}"
CLOCK_PERIOD="${CLOCK_PERIOD:-40}"
CORE_UTIL="${CORE_UTIL:-45}"

SRC="$RTL/$TOP.v"
[ -f "$SRC" ] || { echo "harden: no such RTL: $SRC"; exit 1; }

# Docker Desktop is NOT running by default on this machine.
if ! docker info >/dev/null 2>&1; then
  echo "harden: the docker daemon is not running."
  echo "  start it with:  open -a Docker      (then wait ~30s)"
  exit 1
fi
docker image inspect "$IMAGE" >/dev/null 2>&1 || {
  echo "harden: image absent. Pull it with:  docker pull $IMAGE"; exit 1; }

# The PDK COPY. Made once, reused; never the fleet's shared ~/.volare.
PDKCOPY="${PDKCOPY:-/tmp/silicon_pdk}"
if [ ! -d "$PDKCOPY/volare/sky130/versions/$PDK_VER" ]; then
  echo "harden: making a writable PDK copy at $PDKCOPY (2.1 GB, once)…"
  mkdir -p "$PDKCOPY/volare/sky130/versions"
  cp -R "$HOME/.volare/volare/sky130/versions/$PDK_VER" "$PDKCOPY/volare/sky130/versions/"
fi

WORK="${WORK:-/tmp/harden_$TOP}"
rm -rf "$WORK"; mkdir -p "$WORK/rtl"
cp "$SRC" "$WORK/rtl/"

# ⭐ MAX_FANOUT_CONSTRAINT is inherited from Flow/librelane/config.json — the
# committed value, not one I chose. If that file changes, change it there.
cat > "$WORK/config.json" <<EOF
{
  "DESIGN_NAME": "$TOP",
  "VERILOG_FILES": ["dir::rtl/$TOP.v"],
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": $CLOCK_PERIOD,
  "FP_CORE_UTIL": $CORE_UTIL,
  "PL_TARGET_DENSITY_PCT": 60,
  "RUN_KLAYOUT_XOR": false,
  "RUN_KLAYOUT_DRC": false,
  "PDK": "sky130A",
  "pdk::sky130A": {
    "MAX_FANOUT_CONSTRAINT": 10
  }
}
EOF

echo "harden: $TOP  clock ${CLOCK_PERIOD}ns  util ${CORE_UTIL}%  pdk ${PDK_VER:0:8}…"
docker run --rm -v "$WORK:/work" -v "$PDKCOPY:/pdkroot" "$IMAGE" \
  librelane --pdk-root "/pdkroot/volare/sky130/versions/$PDK_VER" /work/config.json \
  > "$WORK/harden.log" 2>&1 || true

# ⛔ Judge by the flow's OWN markers. Do NOT grep for the word "Error": step
# NAMES contain it ("Lint Errors Checker") and abc prints "Error: The network is
# combinational" informationally. On 8/8 that false-alarmed me into nearly
# retracting a true statement about a healthy run.
if ! grep -q "Flow complete" "$WORK/harden.log"; then
  echo "⛔ harden: flow did NOT complete. Transcript: $WORK/harden.log"
  grep -E "^\[[0-9:]+\] ERROR" "$WORK/harden.log" | head -5
  exit 1
fi

M=$(find "$WORK/runs" -name metrics.json | tail -1)
[ -n "$M" ] || { echo "⛔ harden: flow completed but no metrics.json — refusing a verdict"; exit 2; }

# ⛔ Report `stdcell`, NOT `design__instance__area`: the latter INCLUDES fill
# cells (25,466 µm² of padding in the 8/8 -b run) and I nearly published it as
# the design's footprint. The tell was that it equalled design__core__area.
python3 - "$M" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
g=lambda k: d.get(k)
print(f"  stdcell area   {g('design__instance__area__stdcell')} µm²   (fill EXCLUDED)")
print(f"  die area       {g('design__die__area')} µm²")
print(f"  DRC            {g('magic__drc_error__count')}   antenna {g('route__antenna_violation__count')}")
print(f"  setup slack    {g('timing__setup__ws')} ns    hold {g('timing__hold__ws')} ns")
print(f"  DRV  slew {g('design__max_slew_violation__count')}"
      f"  cap {g('design__max_cap_violation__count')}"
      f"  fanout {g('design__max_fanout_violation__count')}")
print(f"  flops          {g('design__instance__count__class:sequential_cell')}"
      "    <- compare against the RTL's expected total; a shortfall is DELETED STATE")
PY
echo "  transcript: $WORK/harden.log"
echo "  metrics:    $M"
