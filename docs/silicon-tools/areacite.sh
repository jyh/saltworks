#!/bin/bash
# areacite.sh — EMIT AN AREA FIGURE THAT CANNOT TRAVEL WITHOUT ITS SHA OR ITS FENCE.
#
#   areacite.sh <module> [<module> ...]
#   exit 0 = every figure emitted is true at the sha it names
#   exit 1 = at least one could not be quoted (stale stat, or uncommitted tree)
#
# ⛔⛔ WHY THIS EXISTS. On 2026-08-18 I published `79,526 µm² = 34.19%` at f27965d,
# then landed shape A (d3b1be4) and en-at-index-66 (ab54ce7). Both re-synthesised the
# top. The figure became 79,730.2176 µm² = 34.27%. I flagged the staleness myself at
# 14:25 and published the corrected number at 14:29 — **AND THE CORRECTION WAS ITSELF
# A BARE NUMBER WITH NO SHA.** Meanwhile the stale figure had already been quoted
# twice into a council pack.
# ⇒ ***AN AREA FIGURE IS ONLY TRUE AT A SHA. THE NUMBER AND THE COMMIT ARE ONE
#   OBJECT.*** (maestro's formulation, adopted whole.) Every RTL landing moves it, so
#   a bare figure is not a weaker claim — it is a claim about an unnamed object.
#
# ⭐ AND THIS IS THE ONE PLACE §A.0b's OPEN PROBLEM ADMITS A MECHANISM, WHICH IS WHY
# IT IS WORTH A TOOL. A.0b concluded that "is this headline overclaiming?" is a
# JUDGEMENT and therefore ungateable. TRUE — but *"does this figure carry its sha and
# its fence?"* is DECIDABLE, because the figure can be EMITTED with both attached.
# **The fix is not a gate on the judgement; it is removing the opportunity to state
# the number alone.** Same move as the receipt phrase bus_append emits: prose can
# imitate any string and cannot imitate an emitter.
#
# ⚠️ WHAT THIS FIGURE IS NOT, and the tool prints it every time rather than trusting
# the author to remember: SUMMED STANDARD-CELL AREA OVER THE DIE BOX. It is NOT a
# utilization, NOT a placed footprint, and NOT a fit signoff.
#   ⛔ THE CONFLATION THIS ALREADY CAUSED, 08/18: a reader asked how we "went DOWN"
#   from ~60% to 34%. The ~60% is the NATURE PAPER'S LAYOUT FIGURE — a GDS census of
#   the TAPED-OUT die, 5,722 logic cells, fill/decap not drawn. That is NEITHER of
#   these tops (_ndf is 4,282 cells, _c32 is 6,890) AND it is a PLACED FOOTPRINT:
#   placement spreads cells to a utilization target, so the drawn region is always
#   far larger than the sum of cell areas. **A placed footprint and a summed cell
#   area are different measurements of different objects and are never comparable as
#   percentages.**
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
FLOW="$ROOT/SaltWorks/Silicon/Flow"
RTL="$ROOT/SaltWorks/Silicon/RTL"
CFG="$FLOW/librelane/ndf_6x2_config.json"
[ "$#" -gt 0 ] || { echo "usage: areacite.sh <module> [...]"; exit 2; }

# The die box is READ, never typed: `tiles` is the only control for DIE_AREA on the
# TT path, and this config is where it lands.
[ -r "$CFG" ] || { echo "areacite: cannot read $CFG"; exit 2; }
BOX=$(python3 - "$CFG" <<'PY'
import json,sys,re
raw=open(sys.argv[1]).read()
raw=re.sub(r'^\s*"//".*$','',raw,flags=re.M)          # the config uses repeated "//" keys
d=json.loads(re.sub(r',(\s*[}\]])',r'\1',raw))
x0,y0,x1,y1=d["DIE_AREA"]
print(f"{(x1-x0)*(y1-y0):.4f}")
PY
) || { echo "areacite: could not read DIE_AREA from $CFG"; exit 2; }

SHA=$(cd "$ROOT" && git rev-parse --short HEAD 2>/dev/null || echo '')
[ -n "$SHA" ] || { echo "areacite: cannot read HEAD — refusing to emit an undated figure"; exit 2; }

RC=0
for m in "$@"; do
  V="$RTL/$m.v"; S="$FLOW/${m}_stat.txt"
  if [ ! -r "$S" ] || [ ! -r "$V" ]; then
    echo "⛔ $m: missing stat or RTL — NOT QUOTABLE"; RC=1; continue
  fi

  # ⛔ A FIGURE FROM AN UNCOMMITTED FILE HAS NO SHA TO BE TRUE AT. This is the whole
  # point: not "the tree is untidy" but "the object you would name does not exist in
  # any commit". Refuse rather than emit a figure attached to a sha it does not match.
  if ! (cd "$ROOT" && git diff --quiet HEAD -- "SaltWorks/Silicon/Flow/${m}_stat.txt" "SaltWorks/Silicon/RTL/$m.v" 2>/dev/null); then
    echo "⛔ $m: stat or RTL differs from HEAD — a figure quoted now would name $SHA and"
    echo "   NOT describe it. Commit first, then quote. REFUSING."
    RC=1; continue
  fi

  # Currency, the seqstat property: a committed file that no longer describes its RTL
  # is exactly the trap this whole family exists for.
  if ! "$HERE/seqstat.sh" "$m" >/dev/null 2>&1; then
    echo "⛔ $m: seqstat says the stat no longer describes its RTL — NOT QUOTABLE."
    RC=1; continue
  fi

  A=$(LC_ALL=C grep "Chip area for module" "$S" | tail -1 | awk '{print $NF}')
  C=$(LC_ALL=C grep -E '^[[:space:]]+[0-9]+[[:space:]]+[0-9.E+]+[[:space:]]+cells$' "$S" | tail -1 | awk '{print $1}')
  [ -n "${A:-}" ] || { echo "⛔ $m: no chip-area row in the stat — NOT QUOTABLE"; RC=1; continue; }

  python3 - "$m" "$A" "$C" "$BOX" "$SHA" <<'PY'
import sys
m,a,c,box,sha=sys.argv[1],float(sys.argv[2]),sys.argv[3],float(sys.argv[4]),sys.argv[5]
print(f"{a:,.1f} µm² ({c} cells) = {100*a/box:.2f}% of the {box:,.0f} µm² 6x2 die box, "
      f"AT {sha} — {m}")
print("   ⚠️ SUMMED STANDARD-CELL AREA OVER THE DIE BOX. NOT a utilization, NOT a")
print("      placed footprint, NOT a fit signoff. Only a layout run gives DRC/LVS/PDN,")
print("      and a placed footprint is never comparable to this as a percentage.")
PY
done

if [ "$RC" -ne 0 ]; then
  echo "areacite: ⛔ at least one figure is NOT QUOTABLE. Do not hand-type it instead."
  exit 1
fi
exit 0
