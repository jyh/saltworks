#!/bin/sh
# The campaign ledger, run nightly. Writes docs/EVIDENCE-ledger-<date>.md
# and refreshes docs/EVIDENCE-ledger-latest.md.
#
#   sh docs/ledger-tools/nightly.sh              # since the campaign T0
#   CAMPAIGN_SINCE='2026-08-01 00:00' sh docs/ledger-tools/nightly.sh
#
# Owner: the EVIDENCE seat (saltworks). Charter:
# docs/measurement-preregistration.md. The self-test runs first and a
# failure aborts the run — a ledger from an unverified filter is worse
# than no ledger.

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
SALTWORKS=$(cd "$HERE/../.." && pwd)
SALT="$SALTWORKS/../salt"
DOCS="$SALTWORKS/docs"

# T0 of the triple campaign: 2026-08-05 22:02 PDT (FLEET.md).
SINCE=${CAMPAIGN_SINCE:-"2026-08-05 22:00"}
# The 14-day comparison window used by the leg-1 harvest.
HARVEST_SINCE=${HARVEST_SINCE:-"2026-07-23 00:00"}

DATE=$(TZ=America/Los_Angeles date +%Y-%m-%d)
OUT="$DOCS/EVIDENCE-ledger-$DATE.md"

cd "$HERE"
python3 selftest.py

{
  echo "# CAMPAIGN LEDGER — $DATE"
  echo
  echo "Nightly, from \`docs/ledger-tools/nightly.sh\`. Every table below is"
  echo "regenerated from the git history and the session transcripts; nothing"
  echo "here is typed by hand. The filter that decides what counts as a human"
  echo "touch is disclosed inside each section, per"
  echo "\`docs/measurement-preregistration.md\` and its ADDENDUM 1."
  echo
  echo "---"
  echo
} > "$OUT"

python3 silence_windows.py --repo "$SALTWORKS" --since "$SINCE" \
  --ext .lean --run-detail >> "$OUT"
echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

if [ -d "$SALT/.git" ]; then
  python3 silence_windows.py --repo "$SALT" --since "$SINCE" \
    --ext .lean --run-detail >> "$OUT"
  echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

  # the leg-1 comparison window, so the published figures stay checkable
  python3 silence_windows.py --repo "$SALT" --since "$HARVEST_SINCE" \
    --until "2026-08-06 00:00" --ext .lean >> "$OUT"
  echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"
fi

python3 token_meter.py --since "$SINCE" --repo "$SALT" >> "$OUT"
echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

python3 human_time.py --since "$SINCE" >> "$OUT"

cp "$OUT" "$DOCS/EVIDENCE-ledger-latest.md"
echo "wrote $OUT and EVIDENCE-ledger-latest.md"
