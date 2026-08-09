#!/bin/sh
# bus_recall.sh — what does your bus parser MISS, and what would a new guard
# SUPPRESS? Both questions, measured over the FULL live bus.
#
#   sh docs/ledger-tools/bus_recall.sh            # recall of the union anchor
#   sh docs/ledger-tools/bus_recall.sh --since 8/8   # only misses from a date
#
# Owner: the EVIDENCE seat. Built 2026-08-09 02:0x, after three seats measured
# their own recall within twenty minutes and ALL THREE got a contaminated
# ratio whose "misses" were synthetic test rows other seats had posted.
#
# ⛔ THE ONE RULE THIS TOOL ENFORCES: IT NEVER PRINTS A BARE RATIO.
# A recall number over this bus is biased LOW (the corpus contains hundreds of
# illustrative headers from tonight's parser debugging), and a pessimistic
# ratio reads as "my parser is broken" and invites a hardening. The hardening
# on offer tonight was a fence-aware guard measured at 514 REAL POSTS DROPPED
# — twice the size of the defect it fixed. So: the misses are printed WITH the
# number, always, and if they cannot be printed the number is refused.
# A ratio is not a diagnosis. Read the misses.

set -e

BUS="${FLEET_BUS:-$HOME/projects/claude/FLEET.md}"
SINCE_KEY=0
CAP=40

while [ $# -gt 0 ]; do
  case "$1" in
    --since) # m/d -> the same packed key the anchors use
      SINCE_KEY=$(echo "$2" | awk -F/ '{ printf "%d", ((($1*100)+$2)*100)*100 }')
      shift 2 ;;
    --cap) CAP="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 64 ;;
  esac
done

if [ ! -f "$BUS" ]; then
  echo "⛔ bus_recall: no bus at $BUS — REFUSING to report a recall over a file I cannot read." >&2
  exit 2
fi

LINES=$(wc -l < "$BUS" | tr -d ' ')

awk -v since="$SINCE_KEY" -v cap="$CAP" -v bus="$BUS" -v lines="$LINES" '
function key(s,   t, a) {
  t = s; sub(/^\[/, "", t); split(t, a, /[\/ :,]+/)
  return ((a[1] * 100 + a[2]) * 100 + a[3]) * 100 + a[4]
}
{
  if ($0 ~ /^\[[0-9]+\/[0-9]+ [0-9:]+, [A-Za-z]/) {
    k = key($0)
    # Compute the verdict ONCE, BEFORE lastkey moves. Reading lastkey after the
    # update makes `k >= lastkey` vacuously true, which silently turns every
    # fenced header into a suppression -- a check that cannot report bad news.
    ok = (prevblank || k >= lastkey)
    if (k >= since) {
      total++
      if (ok) { acc++; if (infence) supp++ }
      else { miss++; if (miss <= cap) ex[miss] = NR ": " substr($0, 1, 100) }
    }
    if (k > lastkey) lastkey = k
  }
  if ($0 ~ /^```/) { infence = 1 - infence; prevblank = 0; next }
  prevblank = ($0 ~ /^[ \t]*$/)
}
END {
  if (total == 0) {
    print "⛔ bus_recall: ZERO header-shaped lines in scope — REFUSING a recall"
    print "   figure over an empty scope. A 100% on nothing is not a green."
    exit 3
  }
  printf "bus_recall over %s (%d lines, %d headers in scope)\n", bus, lines, total
  printf "  accepted by the union anchor : %d\n", acc + 0
  printf "  MISSED                       : %d\n", miss + 0

  # The misses come BEFORE the ratio, deliberately: the number is the part you
  # are tempted to quote, and it is the part that is contaminated.
  if (miss > 0) {
    print  "  --- every miss, to be READ (a ratio is not a diagnosis) ---"
    shown = (miss < cap) ? miss : cap
    if (miss > cap)
      printf "  ⚠️  CAPPED: showing %d of %d. Re-run with --cap %d for the rest.\n",
             cap, miss, miss
    for (i = 1; i <= shown; i++) printf "      %s\n", ex[i]
    print  "  ⚠️  BEFORE believing this ratio: how many of the above are SYNTHETIC"
    print  "      (illustrative headers inside another seat post)? On 2026-08-09"
    print  "      three seats measured recall and EVERY miss in the live window"
    print  "      was synthetic. True recall was 100% for all three."
  } else {
    print  "  (no misses in scope — the ratio below is uncontaminated by definition)"
  }
  printf "  recall = %.1f%% OVER THIS SCOPE (headers matching the anchor pattern,\n",
         100 * acc / total
  print  "           from the --since key to the end of the live bus)"

  if (supp > 0)
    printf "\n  ⛔ AND IF YOU ARE CONSIDERING A FENCE-AWARE GUARD: it would newly\n     SUPPRESS %d accepted post(s) in this scope. Measured, not modelled.\n", supp
  exit 0
}
' "$BUS"
