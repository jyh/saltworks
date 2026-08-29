#!/bin/sh
# pincheck.sh — RE-CHECK THE TWO PINS BEFORE SUBMITTING. The executable form of an
# obligation this seat wrote in prose on 2026-08-07 and never gave an instrument.
#
#   sh docs/silicon-tools/pincheck.sh [<submitted-pdk.json>]
#   exit 0 = both pins as recorded   1 = A PIN MOVED   2 = could not measure (NOT a pass)
#
# ⛔ THE OBLIGATION, VERBATIM FROM `docs/silicon-b5-prep-0807.md` (search "RE-CHECK BOTH"):
#   "Pinning freezes the flow; freezing is only correct if someone looks again. If TinyTapeout
#    moves `ttsky26c` to fix something the shuttle requires, a pinned repo silently keeps the
#    old flow and can fail the shuttle's own re-run of precheck.py on the submitted .oas."
#   It has had NO INSTRUMENT for 21 days, and the freeze is 2026-09-07 13:00 PDT.
#
# ⛔⛔ AND THE CORRECTION THAT LINE NEEDS, MEASURED 08-28 18:0x AT THE OBJECT: **OUR SUBMITTED
#   WORKFLOW DOES NOT PIN A SHA — IT REFERENCES THE TAG** (`TinyTapeout/tt-gds-action@ttsky26c`,
#   four times in .github/workflows/gds.yaml at commit 7d2b2756). So the risk is the MIRROR of
#   the one I wrote down: we do not silently keep the OLD flow, we silently take the NEW one.
#   The sha in `pins.conf` is therefore a DATED OBSERVATION OF WHERE A MOVABLE TAG POINTED,
#   NOT AN ENFORCEMENT — and that distinction is the whole reason this check exists.
#   ⇒ ***A RECORDED PIN AND AN ENFORCED PIN READ IDENTICALLY IN A DOCUMENT AND BEHAVE
#      OPPOSITELY IN A RE-RUN.***
set -u
HERE="$(cd -P "$(dirname "$0")" && pwd)"
CONF="${PINS_CONF:-$HERE/pins.conf}"
[ -r "$CONF" ] || { echo "pincheck: cannot read $CONF — CANNOT MEASURE (not a pass)" >&2; exit 2; }
# shellcheck disable=SC1090
. "$CONF"
: "${FLOW_REPO:?}" "${FLOW_TAG:?}" "${FLOW_SHA:?}" "${PDK_SHA:?}"

RC=0
echo "pincheck: recorded FLOW $FLOW_REPO@$FLOW_TAG = $FLOW_SHA"
echo "          recorded PDK  $PDK_SHA"

# --- PIN 1: the movable tag, read LIVE -------------------------------------------------
LIVE=$(gh api "repos/$FLOW_REPO/git/ref/tags/$FLOW_TAG" --jq '.object.sha' 2>/dev/null)
case "$LIVE" in
  ????????????????????????????????????????) : ;;
  *) echo "  ⛔ CANNOT MEASURE — no answer from the tag API (network? auth? tag renamed?)."
     echo "     A silent network failure must never render as 'the pin is fine'."
     exit 2 ;;
esac
if [ "$LIVE" = "$FLOW_SHA" ]; then
  echo "  ✅ FLOW tag unmoved: $LIVE"
else
  echo "  ⛔ FLOW TAG HAS MOVED — recorded $FLOW_SHA · live $LIVE"
  echo "     Our workflow references the TAG, so the next run takes the NEW flow."
  echo "     Read TT's change before re-cutting a revision, and re-record with its date."
  RC=1
fi

# --- PIN 2: the PDK, from the SUBMITTED artifact --------------------------------------
# Default lives in the PRIVATE archive; export SALTWORKS_ARCHIVE_ROOT (its `archives` dir) or pass the path.
PDKJ="${1:-${SALTWORKS_ARCHIVE_ROOT:-/nonexistent-set-SALTWORKS_ARCHIVE_ROOT}/silicon-ndf-drv-0827/inputs/tt-submitted-reference/tt_submission/pdk.json}"
if [ -r "$PDKJ" ]; then
  GOT=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("PDK_VERSION",""))' "$PDKJ" 2>/dev/null)
  if [ -z "$GOT" ]; then
    echo "  ⛔ CANNOT MEASURE — no PDK_VERSION in $PDKJ"; [ "$RC" = 1 ] || RC=2
  elif [ "$GOT" = "$PDK_SHA" ]; then
    echo "  ✅ PDK as recorded in the submitted artifact: $GOT"
  else
    echo "  ⛔ PDK DIFFERS — recorded $PDK_SHA · artifact $GOT"; RC=1
  fi
else
  echo "  ⛔ CANNOT MEASURE — submitted pdk.json unreadable at: $PDKJ"
  echo "     (mount the archive volume, or pass the path). NOT a pass."
  [ "$RC" = 1 ] || RC=2
fi

case "$RC" in
  0) echo "  ✅ BOTH PINS AS RECORDED. Scope: the flow TAG and the PDK version only." ;;
  1) echo "  ⛔ PIN MOVED — do not re-cut a revision until this is understood." ;;
  *) echo "  ⛔ NOT MEASURED — this is not a pass." ;;
esac
exit "$RC"
