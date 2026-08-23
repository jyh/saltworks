#!/bin/bash
# fig4_join_selftest.sh — THE CONTROL THAT LICENSES fig4_join.sh.
#
# Usage:  fig4_join_selftest.sh <path to tt_um_saltworks_ndf.v>
#
# ⛔ WHY A REBUILT TOOL NEEDS THIS AT ALL: fig4_join.sh is a RECONSTRUCTION. The
# 2026-08-12 join shipped its OUTPUT and its METHOD DOC and NO CODE (8a169e9),
# and the code died with a session scratchpad. A reconstruction that has not been
# shown to reproduce the artifact it replaces is A GUESS WEARING THE ORIGINAL'S
# NAME — so this compares ROW BY ROW against the committed TSV, and then proves
# the comparison can FAIL.
#
# 📌 GETTING THE INPUT — it is NOT in this repo and must not be: it is 5.9 MB of
# post-P&R netlist. It is the durable original at the shuttle CI:
#     gh run download 31417665786 -R jyh/tt-neural-dataflow-fabric \
#        -n tt_submission -D /tmp/ndf
#     ./fig4_join_selftest.sh /tmp/ndf/tt_submission/tt_um_saltworks_ndf.v
# ⭐ THAT FETCH IS THE 0812 DOC'S OWN OFFER PAID OFF: it recorded the input sha256
# "so the census is reproducible against the CI copy, which is the durable
# original", and on 2026-08-22 the CI copy came back BYTE-EXACT ten days later.
# RECORDING THE INPUT'S HASH IS WHAT MADE A LOST TOOL RECOVERABLE.
set -u
NL="${1:?usage: fig4_join_selftest.sh <tt_um_saltworks_ndf.v>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
JOIN="$HERE/fig4_join.sh"
REPO="$(cd "$HERE/../.." && pwd)"
REF="$REPO/SaltWorks/Silicon/Flow/fig4_cell_coloring.tsv"
WANT_SHA=3a8577e019d26e0921892c44353b0db74a6dcf76dd43f57879fe8a17ed15a541

for f in "$NL" "$JOIN" "$REF"; do
  [ -f "$f" ] || { echo "⛔ missing: $f" >&2; exit 2; }
done

# ARM 0 — THE INPUT IS THE OBJECT THE FIGURE IS ABOUT, not merely a netlist.
# ⛔ Without this the whole selftest is a comparison against the wrong die and
# every row would differ for a reason that has nothing to do with the code:
# the _c32 netlist is a DIFFERENT CHIP (43,884 instances vs 53,160).
GOT_SHA=$(shasum -a 256 "$NL" | cut -d' ' -f1)
if [ "$GOT_SHA" != "$WANT_SHA" ]; then
  echo "⛔ REFUSING — this is not Figure 4's input."
  echo "   want $WANT_SHA"
  echo "   got  $GOT_SHA"
  echo "   (the _c32 die is a different chip; see docs/silicon-figure4-structural-join-0812.md)"
  exit 3
fi
echo "✅ ARM 0  input verified byte-exact against the sha the 0812 doc recorded"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
bash "$JOIN" "$NL" | sort > "$TMP/regen.sorted"
# ⛔ STRIP \r. The committed TSV is CRLF, so its LAST field carries a trailing
# carriage return; comparing without stripping fails on EVERY row for a reason
# that is invisible when you print the field, because \r only moves the cursor.
tr -d '\r' < "$REF" | sort > "$TMP/ref.sorted"

# ARM 1 — REPRODUCTION. Row-wise, not aggregate.
# ⛔ AGGREGATE TOTALS ARE NOT A CONTROL HERE, and that is not a style opinion: a
# backslash bug in an early draft repainted 1,443 named cells as anonymous and
# THE TOTALS STAYED INNOCENT, because they were computed by a different query.
# AN AGGREGATE THAT DID NOT MOVE IS NOT EVIDENCE THAT NOTHING MOVED.
if diff -q "$TMP/ref.sorted" "$TMP/regen.sorted" >/dev/null; then
  echo "✅ ARM 1  REPRODUCES the committed coloring exactly ($(( $(wc -l < "$TMP/regen.sorted") - 1 )) cells)"
else
  echo "⛔ ARM 1 FAILED — $(diff "$TMP/ref.sorted" "$TMP/regen.sorted" | grep -c '^[<>]') rows differ"
  diff "$TMP/ref.sorted" "$TMP/regen.sorted" | head -10
  exit 1
fi

# ARM 2 — THE NEGATIVE CONTROL. A comparison never shown to fail has not been
# shown to discriminate; precision reads exactly like strength.
sed '3000s/kernel_emitted/agent_written/' "$TMP/regen.sorted" | sort > "$TMP/mutant"
if diff -q "$TMP/ref.sorted" "$TMP/mutant" >/dev/null; then
  echo "⛔ ARM 2 FAILED — a flipped provenance field PASSED. The comparison is blind."
  exit 1
fi
echo "✅ ARM 2  mutation control RED — one flipped field is caught"

echo
echo "SELFTEST GREEN — fig4_join.sh reproduces 8a169e9's output and the check can fail."
echo "⚠️ THIS CERTIFIES FIDELITY TO THE ORIGINAL, NOT CORRECTNESS OF THE ORIGINAL."
echo "   The clock_tree class is KNOWN WRONG — see the DEFECT block in fig4_join.sh."
