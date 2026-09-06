#!/bin/bash
# ============================================================================
# rtl_transcription_drift.sh — FAIL WHEN `busadapt8.v` MOVES UNDER ITS LEAN
# TRANSCRIPTION.
#
#   rtl_transcription_drift.sh            # check
#   rtl_transcription_drift.sh --selftest # drive all three gates, red-first
#   rtl_transcription_drift.sh --print    # print the watched region (auditable)
#   rtl_transcription_drift.sh --pin      # emit the pin line for BusFSM.lean
#
# WHY THIS EXISTS (evidence's order, 2026-09-06 06:38, and the file's own
# confession two days older). `SaltWorks/HDL/BusFSM.lean` says in bold:
#
#   "busadapt8.v changed and NOT ONE .lean FILE DID ... so the whole verified
#    surface stayed GREEN across a ratified change to the machine. Nothing here
#    is verified against the RTL; it is verified against THIS TRANSCRIPTION,
#    and a transcription cannot notice that its source moved."
#
# MEASURED, not quoted: over `9769fa1..035241f` the tree changed 19 files,
# `busadapt8.v` among them, with 13 NON-COMMENT delta lines in it and **0**
# `.lean` files. The control matters — the range is not empty; the .lean count
# is. ⇒ THE FAILURE HAS ALREADY HAPPENED ONCE, SILENTLY, and the only thing
# that caught it was a human re-reading the source by hand.
#
# ⛔ THE REMEDY WAS A DOCSTRING FOR TWO DAYS. A DOCSTRING CANNOT FAIL.
#   If your remedy is a sentence, you built nothing. This is the sentence
#   turned into a check that exits non-zero.
#
# ── THE KEY, AND WHY THIS ONE ───────────────────────────────────────────────
# The key is the WHOLE MODULE'S LOGIC: every line of busadapt8.v with comments
# stripped, blank lines dropped and whitespace normalised, hashed.
#
#   whole-file hash   REJECTED — OVER-FIRES. Measured 2026-09-06: silicon's
#                     `afa8a2e7` + `1cd4cc53` touched busadapt8.v with COMMENTS
#                     ONLY; the non-comment delta was EMPTY. A key that cries
#                     wolf on the commonest kind of RTL commit gets muted, and
#                     a muted arm is worth less than no arm.
#   line-range key    REJECTED — BRITTLE EXACTLY WHEN THE SOURCE MOVES, which
#                     is the one case it exists for, and it fails gate (iii)
#                     SILENTLY: a drifted range matches nothing and reports
#                     "0 drift", which is a fact about the matcher.
#   module logic      CHOSEN. Comment-insensitive, boundary-free, and it needs
#                     no agreement with silicon about markers in its file.
#
# ⛔⛔ v1 OF THIS SCRIPT OVER-FIRED ON THAT VERY COMMIT, AND THE KEY WAS NOT THE
#   DEFECT — THE IMPLEMENTATION WAS. A BSD-sed BRE bug (`\+` read as a literal
#   plus) meant whitespace was never normalised, so comment-stripped INDENTED
#   lines survived as whitespace-only lines and moved the hash. The key is
#   comment-insensitive; v1's extractor was not. evidence caught it by driving
#   the REAL range within four minutes of the landing, using this script's own
#   `--pin`. ⇒ A DESIGN CAN BE RIGHT AND ITS ONE-LINE IMPLEMENTATION WRONG, AND
#   A SELFTEST WRITTEN BY THE SAME HAND CAN AGREE WITH BOTH.
#
# ⚠️ THE COST I AM ACCEPTING, STATED SO IT IS NOT DISCOVERED: this over-fires on
#   a logic change ANYWHERE in busadapt8.v, including parts BusFSM.lean does not
#   transcribe (the phase counter, the output muxes). That is deliberate. The
#   transcriber should look at any logic change in the module it transcribes,
#   and the cost of a false fire is one re-read plus one re-pin, while the cost
#   of a missed fire is the silent green this arm exists to end.
#
# ⭐ FAILURE DIRECTION, DECLARED (evidence asked): **LOUD.** Every way this
#   script can be wrong exits NON-ZERO. It can refuse to answer; it cannot
#   quietly say "clean". The vacuous pass is the failure mode this whole class
#   dies of — see gate (iii).
#
# ⛔ KNOWN LIMIT, NOT PAPERED OVER: the comment stripper is textual (`//` to end
#   of line). It would also strip a `//` inside a string literal. busadapt8.v
#   has none — checked — but a future file with one would have its logic
#   silently altered BEFORE hashing, which changes the hash and therefore FIRES.
#   Loud, not silent, so the limit is safe in the direction that matters.
# ============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
RTL="${RTL_OVERRIDE:-$ROOT/SaltWorks/Silicon/RTL/busadapt8.v}"
LEAN="${LEAN_OVERRIDE:-$ROOT/SaltWorks/HDL/BusFSM.lean}"

# GATE (iii) THRESHOLDS. An arm must prove it watched a NON-EMPTY region.
# ⛔ RE-CALIBRATED 07:3x: 200 was measured off the BROKEN stripper's 286 lines. The
#   correct stripper yields 73, so the old floor would now REFUSE EVERYTHING — a
#   threshold is a fact about the instrument that produced it, and it does not
#   survive that instrument being fixed.
MIN_LINES=60
ANCHORS=('always @(posedge clk)' 'T_FETCH' 'loop_end' 'sof' 'retire')

extract() {
  # comments out, whitespace normalised, blanks out.
  # ⛔⛔ `sed -E` IS LOAD-BEARING AND WAS THE FIRST VERSION'S DEFECT. BSD sed's BRE
  #   treats `\+` as a LITERAL PLUS, so `s/[[:space:]]\+/ /g` matched NOTHING on
  #   this platform: comment-stripped lines kept their indentation, never emptied,
  #   never dropped, and 47 of silicon's INDENTED comment lines moved the hash.
  #   The arm over-fired on a comment-only commit — the exact thing its key exists
  #   to avoid — and the SELFTEST WAS GREEN, because my fixture appended a comment
  #   at COLUMN 0, which strips to the empty string. Real RTL comments are indented.
  #   ⇒ A NEGATIVE CONTROL BUILT FROM A SYNTHETIC FIXTURE CAN BE SATISFIABLE BY A
  #     FIXTURE THAT CANNOT FEEL THE DEFECT. The (i-control) arm below is now built
  #     from the REAL commit range instead, which is how evidence caught this.
  sed 's://.*::' "$1" \
    | sed -E 's/[[:space:]]+/ /g' \
    | sed -E 's/^ //; s/ $//' \
    | grep -v '^$'
}

# ── GATE (iii): THE ARM MUST BE SHOWN TO BE WATCHING A NON-EMPTY REGION ──────
# An arm keyed on something that has drifted matches nothing and reports
# "0 drift". That is not a pass; it is an instrument reading of a void. This
# refuses instead, and it refuses BEFORE any hash is compared.
guard_region() {
  local body="$1" n
  n=$(printf '%s\n' "$body" | grep -c . || true)
  if [ "$n" -lt "$MIN_LINES" ]; then
    echo "⛔ REFUSING — extracted region is $n lines, below the floor of $MIN_LINES." >&2
    echo "   The extractor matched (almost) nothing. A hash of nothing compares EQUAL to" >&2
    echo "   a stored hash of nothing and reports CLEAN. That is the vacuous pass this" >&2
    echo "   gate exists to refuse. Fix the extractor; do NOT re-pin." >&2
    return 3
  fi
  local a
  for a in "${ANCHORS[@]}"; do
    if ! printf '%s\n' "$body" | grep -qF -- "$a"; then
      echo "⛔ REFUSING — anchor absent from the extracted region: '$a'" >&2
      echo "   The region no longer contains a construct this transcription is ABOUT," >&2
      echo "   so the region is the wrong region even if it is large. Fix the extractor." >&2
      return 3
    fi
  done
  echo "   region: $n lines, all ${#ANCHORS[@]} anchors present (gate iii satisfied)"
  return 0
}

logic_sha() { printf '%s\n' "$1" | shasum -a 256 | cut -c1-16; }

read_pin() {
  grep -oE 'RTL-PIN busadapt8\.v logic-sha256/16 = [0-9a-f]{16}' "$LEAN" \
    | head -1 | grep -oE '[0-9a-f]{16}$'
}

# ── MODES ───────────────────────────────────────────────────────────────────
case "${1:-}" in
  --print)
    extract "$RTL"; exit 0 ;;
  --pin)
    BODY="$(extract "$RTL")"
    guard_region "$BODY" >/dev/null || exit 3
    echo "RTL-PIN busadapt8.v logic-sha256/16 = $(logic_sha "$BODY")"
    exit 0 ;;
  --selftest) ;;  # falls through below
  "") ;;
  *) echo "usage: rtl_transcription_drift.sh [--selftest|--print|--pin]" >&2; exit 2 ;;
esac

if [ "${1:-}" != "--selftest" ]; then
  # ── THE CHECK ─────────────────────────────────────────────────────────────
  [ -f "$RTL" ]  || { echo "⛔ REFUSING — RTL absent: $RTL" >&2; exit 4; }
  [ -f "$LEAN" ] || { echo "⛔ REFUSING — Lean absent: $LEAN" >&2; exit 4; }
  BODY="$(extract "$RTL")"
  guard_region "$BODY" || exit 3
  ACTUAL="$(logic_sha "$BODY")"
  PINNED="$(read_pin)"
  if [ -z "$PINNED" ]; then
    echo "⛔ REFUSING — no RTL-PIN line in $(basename "$LEAN")." >&2
    echo "   An ABSENT pin must never read as agreement. Run --pin and paste it in." >&2
    exit 5
  fi
  echo "   pinned in $(basename "$LEAN"): $PINNED"
  echo "   actual  from $(basename "$RTL"): $ACTUAL"
  if [ "$ACTUAL" = "$PINNED" ]; then
    echo "✅ transcription-drift: the RTL logic is UNCHANGED since the pin."
    echo "   ⚠️  This certifies the SOURCE has not moved. It does NOT certify that the"
    echo "      transcription was ever CORRECT — that reading is still the load-bearing"
    echo "      step, and no check in this repo carries it."
    exit 0
  fi
  echo "⛔ TRANSCRIPTION DRIFT — busadapt8.v's LOGIC changed and the pin did not." >&2
  echo "   BusFSM.lean is verified against a transcription of a file that has MOVED." >&2
  echo "   Re-read the source, update the transcription IF it moved, then re-pin." >&2
  echo "   ⛔ DO NOT re-pin first: the pin is the record that a human looked." >&2
  exit 1
fi

# ── SELFTEST: DRIVE ALL THREE GATES, RED-FIRST ──────────────────────────────
echo "── rtl_transcription_drift SELFTEST ─────────────────────────────────────"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAIL=0
ok() { echo "  $1  $2"; }
bad() { echo "  ⛔ $1  $2"; FAIL=1; }

# (ii) THE CURRENT TREE MUST PASS — else the rule is not satisfiable.
if out=$("$0" 2>&1); then ok "✅" "(ii) current tree PASSES        exit=0"
else bad "(ii) current tree FAILED — rule not satisfiable:"; echo "$out"; fi

# (i) A MUTATION OF THE TRANSCRIBED RTL MUST TRIP THE ARM.
cp "$RTL" "$TMP/mut.v"
# flip the store beat's set value: a one-token LOGIC change, no comment touched.
sed -i '' 's/if (kind == T_STORE) store_beat <= 1.b1;/if (kind == T_STORE) store_beat <= 1'"'"'b0;/' "$TMP/mut.v"
if cmp -s "$RTL" "$TMP/mut.v"; then
  bad "(i) MUTATION DID NOT APPLY — the fixture built no mutant, so a RED below"
  echo "        would accuse the code for the fixture's defect. ABORTING that arm."
else
  if RTL_OVERRIDE="$TMP/mut.v" "$0" >/dev/null 2>&1; then
    bad "(i) mutated RTL PASSED — the arm cannot fail, so its green is worthless"
  else ok "✅" "(i) mutated RTL TRIPS the arm   exit=1"; fi
fi

# (i-control) A COMMENT-ONLY CHANGE MUST **NOT** TRIP IT.
#   ⛔⛔ THIS ARM IS BUILT FROM A REAL COMMIT RANGE, AND THE FIRST VERSION WAS NOT.
#   v1 appended `// a comment...` at COLUMN 0 to the current file. That strips to
#   the empty string under ANY stripper, so it passed while the shipped stripper
#   was broken for INDENTED comments — which is every real comment in the RTL.
#   evidence drove the real range and the arm over-fired. ⇒ BUILD A NEGATIVE
#   CONTROL FROM A LANDED CHANGE, NEVER FROM A CONVENIENT ONE.
#   1916ea0 → afa8a2e is silicon's comment-only edit: 47-line raw diff, 0
#   non-comment delta. The two logic hashes MUST be equal.
if git -C "$ROOT" cat-file -e 1916ea0:SaltWorks/Silicon/RTL/busadapt8.v 2>/dev/null; then
  git -C "$ROOT" show 1916ea0:SaltWorks/Silicon/RTL/busadapt8.v > "$TMP/before.v"
  git -C "$ROOT" show afa8a2e:SaltWorks/Silicon/RTL/busadapt8.v  > "$TMP/after.v"
  if cmp -s "$TMP/before.v" "$TMP/after.v"; then
    bad "(i-control) FIXTURE IS DEGENERATE — the two revisions are identical, so the"
    echo "        control could not distinguish anything. ABORTING that arm."
  else
    H1=$(logic_sha "$(extract "$TMP/before.v")")
    H2=$(logic_sha "$(extract "$TMP/after.v")")
    if [ "$H1" = "$H2" ]; then
      ok "✅" "(i-control) REAL comment-only range does NOT move the key ($H1)"
    else
      bad "(i-control) REAL comment-only range MOVED the key: $H1 -> $H2 — over-fires"
    fi
  fi
else
  bad "(i-control) SKIPPED — revision 1916ea0 unreachable. A control that cannot run"
  echo "        is NOT a control that passed."
fi

# (i-real) AND THE MUST-TRIP HALF FROM REAL HISTORY TOO, so BOTH sides of the
#   discriminating set are landed commits rather than one landed and one synthetic.
#   9769fa1 → 035241f is option (2): 13 non-comment delta lines in busadapt8.v and
#   0 .lean files — the silent green this whole arm exists to end.
if git -C "$ROOT" cat-file -e 9769fa1:SaltWorks/Silicon/RTL/busadapt8.v 2>/dev/null; then
  git -C "$ROOT" show 9769fa1:SaltWorks/Silicon/RTL/busadapt8.v > "$TMP/opt1.v"
  git -C "$ROOT" show 035241f:SaltWorks/Silicon/RTL/busadapt8.v > "$TMP/opt2.v"
  H1=$(logic_sha "$(extract "$TMP/opt1.v")")
  H2=$(logic_sha "$(extract "$TMP/opt2.v")")
  if [ "$H1" != "$H2" ]; then
    ok "✅" "(i-real) REAL logic change MOVES the key   $H1 -> $H2"
  else
    bad "(i-real) REAL logic change did NOT move the key — the arm is blind to the"
    echo "        very event it was built for."
  fi
else
  bad "(i-real) SKIPPED — revision 9769fa1 unreachable. A control that cannot run"
  echo "        is NOT a control that passed."
fi

# (iii) A BROKEN EXTRACTOR MUST REFUSE, NOT PASS.
printf 'module x; endmodule\n' > "$TMP/tiny.v"
if RTL_OVERRIDE="$TMP/tiny.v" "$0" >/dev/null 2>&1; then
  bad "(iii) a 1-line RTL PASSED — the vacuous pass is live"
else
  rc=$(RTL_OVERRIDE="$TMP/tiny.v" "$0" >/dev/null 2>&1; echo $?)
  [ "$rc" = "3" ] && ok "✅" "(iii) undersized region REFUSED  exit=3" \
                  || bad "(iii) refused with exit=$rc, expected 3 (REFUSE, not DRIFT)"
fi

# (iii-b) A LARGE REGION MISSING AN ANCHOR MUST ALSO REFUSE.
#   Size alone is not evidence the region is the RIGHT region.
sed 's/always @(posedge clk)/always @(negedge NOPE)/' "$RTL" > "$TMP/noanchor.v"
rc=$(RTL_OVERRIDE="$TMP/noanchor.v" "$0" >/dev/null 2>&1; echo $?)
[ "$rc" = "3" ] && ok "✅" "(iii-b) anchor-less region REFUSED exit=3" \
                || bad "(iii-b) anchor-less region gave exit=$rc, expected 3"

# (iv) AN ABSENT PIN MUST REFUSE, NOT READ AS AGREEMENT.
grep -v 'RTL-PIN' "$LEAN" > "$TMP/nopin.lean"
rc=$(LEAN_OVERRIDE="$TMP/nopin.lean" "$0" >/dev/null 2>&1; echo $?)
[ "$rc" = "5" ] && ok "✅" "(iv) absent pin REFUSED          exit=5" \
                || bad "(iv) absent pin gave exit=$rc, expected 5"

echo "─────────────────────────────────────────────────────────────────────────"
[ "$FAIL" = "0" ] && { echo "✅ SELFTEST PASSED — all gates fired, including the two that must NOT."; exit 0; }
echo "⛔ SELFTEST FAILED — do not trust this arm until it is green." >&2; exit 1
