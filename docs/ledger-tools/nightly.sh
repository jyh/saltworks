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
FINAL="$DOCS/EVIDENCE-ledger-$DATE.md"
LATEST="$DOCS/EVIDENCE-ledger-latest.md"

# THE WRITE IDIOM FOLLOWS THE READER (fleet law, 2026-08-09). These ledgers are
# read by SNAPSHOT readers -- the maestro's rsync to seat/, and any council read
# -- which open by NAME at a point in time. So the file must never exist in a
# half-built state: we build into a temp and RENAME, which is atomic within a
# filesystem, so a reader gets the previous COMPLETE ledger or the new one.
#
# The old shape truncated the real ledger at the header and appended section by
# section for the whole run: for those minutes the published file was a partial
# that still LOOKED finished (header present, tables missing). Under `set -e` a
# mid-run failure also LEFT it that way. Both are closed by the rename.
OUT="$DOCS/.EVIDENCE-ledger-$DATE.md.partial"
trap 'rm -f "$OUT" "$LATEST.tmp.$$"' EXIT

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
echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

# The mechanically-knowable half of the scoreboard: what actually landed.
# Generated, never typed -- a commit hash does not age (resource lesson 5).
python3 landed.py --since "$SINCE" >> "$OUT"

echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

# The shuttle drain series -- appended, then cited. A projection needs a
# measured slope; this keeps the readings accumulating so the slope exists.
python3 tile_drain.py >> "$OUT" 2>&1 || \
  echo "_(tile_drain: reading could not be taken; series unchanged — a gap is honest.)_" >> "$OUT"


echo >> "$OUT"; echo '---' >> "$OUT"; echo >> "$OUT"

# ---- ROT SECTION, added 2026-08-10 --------------------------------------
# Three instruments built on 08/10 and wired in the SAME NIGHT, because an
# unwired tool is a tool that rots: the seat that built it remembers to run it
# and the successor never learns it exists. Each is non-fatal here -- a finding
# is a REPORT, not a reason to abort the ledger -- but each prints its own
# scope line, so a green in this file is never mistaken for "clean".
{
  echo "## Documentation rot — three sweeps"
  echo
  echo "Each tool below prints what it does NOT cover. A green is a green over"
  echo "a STATED scope and nothing more. Findings here are reports, not"
  echo "failures: the ledger continues past them by design."
  echo
  echo '### Drifted citations (`pin_check.py`)'
  echo '```'
} >> "$OUT"
python3 pin_check.py --quiet $(find "$SALTWORKS/docs" -name '*.md' | sort) >> "$OUT" 2>&1 || true
{
  echo '```'
  echo
  echo '### Stale absence claims (`prose_rot.py`) — direction (A) only'
  echo '```'
} >> "$OUT"
python3 prose_rot.py --quiet "$SALTWORKS/docs" >> "$OUT" 2>&1 || true
{
  echo '```'
  echo
  echo '### Claim fence over the published TT text (`claim_fence.py`)'
  echo '```'
} >> "$OUT"
if gh api repos/jyh/tt-neural-dataflow-fabric/contents/docs/info.md --jq '.content' 2>/dev/null      | base64 -d > "${TMPDIR:-/tmp}/ndf_info_$$.md" 2>/dev/null; then
  python3 claim_fence.py "${TMPDIR:-/tmp}/ndf_info_$$.md" >> "$OUT" 2>&1 || true
  rm -f "${TMPDIR:-/tmp}/ndf_info_$$.md"
else
  echo "(published text unreachable tonight — NOT a pass; the fence did not run.)" >> "$OUT"
fi
echo '```' >> "$OUT"

# Publish both by RENAME, never by truncating writes. `cp` onto LATEST would
# reintroduce exactly the window this run just avoided -- cp opens the
# destination for truncation and fills it, so a reader mid-copy sees a partial.
mv "$OUT" "$FINAL"
cp "$FINAL" "$LATEST.tmp.$$"
mv "$LATEST.tmp.$$" "$LATEST"
echo "wrote $FINAL and EVIDENCE-ledger-latest.md (both published by rename)"
