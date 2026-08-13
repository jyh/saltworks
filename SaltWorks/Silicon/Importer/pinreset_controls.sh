#!/bin/bash
# PINRESET CONTROLS — the negative controls for the `--pin-reset` / dfrtp model,
# registered in docs/silicon-dfrtp-async-reset-prereg-0812.md and run for the
# record in its .RESULTS.md companion.
#
# ## Why this file exists
#
# The controls were run once by hand the night the mechanics were built. A
# control run once is a demonstration; a control that can be re-run is a fixture,
# and only the second kind survives the next change to the importer. Every row
# below plants a REAL defect and drives THE REAL COMMAND with the REAL flags —
# not a re-implementation of the check, which is the trap this seat fell into on
# 8/12 (a control that proved a pattern while missing four files, its own watcher
# among them).
#
# ⛔ A ROW THAT CANNOT RUN PRINTS A REFUSAL AND FAILS. A silent skip reads exactly
# like a pass, and this seat shipped that defect once already today.
#
# Usage:  ./pinreset_controls.sh
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"
cd "$SELF/../../.." || exit 2
IMP=SaltWorks/Silicon/Importer/import_netlist.py
FX=SaltWorks/Silicon/Importer/fixtures
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0; n=0

# row <label> <fixture> <expect:PASS|RED> <inputs> [pin-reset-net]
row() {
  local label=$1 fx=$2 expect=$3 ins=$4 pin=${5:-}
  n=$((n+1))
  if [ ! -f "$FX/$fx" ]; then
    echo "  ⛔ $label — FIXTURE MISSING ($fx); refusing to count this as a pass"
    fail=1; return
  fi
  python3 "$IMP" "$FX/$fx" --top pinreset_fx --out "$TMP/out.lean" --name fxNL \
      --inputs "$ins" --outputs q0,q1 ${pin:+--pin-reset "$pin"} --check off \
      >"$TMP/log" 2>&1
  local rc=$?
  local got; [ $rc -eq 0 ] && got=PASS || got=RED
  if [ "$got" = "$expect" ]; then
    printf "  ✅ %-46s %s (exit %d)\n" "$label" "$got" "$rc"
  else
    printf "  ✗ %-46s expected %s, got %s (exit %d)\n" "$label" "$expect" "$got" "$rc"
    sed 's/^/        /' "$TMP/log" | head -3
    fail=1
  fi
}

echo "pinreset controls: planting defects and driving the real importer"

# C4 — the DEFAULT path. The refusal must survive every future change; it is what
# every caller gets who has not asked for the restriction.
row "C4  no --pin-reset: dfrtp must REFUSE"      pinreset_base.v  RED  "clk,rst_n,d0,d1"
# The positive arm. If this ever goes RED the controls below prove nothing,
# because a run that always fails satisfies every RED row for free.
row "C1  base + --pin-reset: must IMPORT"        pinreset_base.v  PASS "clk,d0,d1" rst_n
# C1's two blocking clauses, exercised separately — the first fixture trips the
# multi-net clause before it can reach the driven-net clause.
row "NC1  reset pins span two nets"              pinreset_nc1.v   RED  "clk,d0,d1" rst_n
row "NC1b single reset net, DRIVEN by a cell"    pinreset_nc1b.v  RED  "clk,d0,d1" n0
# C2 is DISCLOSURE and must never block — a row asserting exit 0 is the only way
# to notice if it silently becomes an error.
row "NC2  other consumer: report, do NOT block"  pinreset_nc2.v   PASS "clk,d0,d1" rst_n
row "NC2b live consumer reaching an output"      pinreset_nc2b.v  PASS "clk,d0,d1" rst_n
# C6 against the independent text scan.
row "NC6  commented-out flop: conservation RED"  pinreset_nc6b.v  RED  "clk,d0,d1" rst_n
# The flag must not be a silent no-op, in either direction.
row "NCx  pinned net also listed in --inputs"    pinreset_base.v  RED  "clk,rst_n,d0,d1" rst_n
row "NCy  --pin-reset on a flopless netlist"     pinreset_dfxtp.v RED  "clk,d0,d1" rst_n

# --- C3 AS AMENDED BY THE HELM, 2026-08-12 18:49 -------------------------------
# The registered C3 (full-file byte-identity) went RED because it demanded
# identity of a header THE RULING ITSELF REQUIRES TO DIFFER. The helm amended it
# to TWO assertions, and the amendment is STRONGER: the header difference is now
# ASSERTED rather than excluded.
#
#   A1  gate-for-gate identity of the emitted LOGIC
#   A2′ the file diff is EXACTLY the mandated scope marker PLUS the flop
#       table's cell-name column, each asserted in its REQUIRED direction
#       — including that the two arms' columns DIFFER (the independent
#       variable). DISCHARGING since the helm's 08/12 19:07:52 ruling.
#   A2  the older form: diff == marker and nothing else. SUPERSEDED and
#       now INFORMATIONAL — it is red by design, because it counts the
#       required cell-name difference as a residual. An exception list
#       was the wrong SHAPE; A2′ characterises the whole diff positively.
#
# ⭐ BOTH ARMS ARE GENERATED FROM ONE BASE NETLIST BY THE REGISTERED METHOD (a
# textual rewrite), into THE SAME BASENAME in two directories. The predecessor's
# harness compared two hand-maintained fixtures from different filenames, which
# (a) injected a `-- source:` difference that was an artifact of where the test
# put its files, not a property of the datum, and (b) let the comparison arm
# drift from the base. Verified at this landing: the committed
# `pinreset_dfxtp.v` IS byte-identical to the rewrite. It is kept for row NCy.
echo "pinreset controls: C3 under A2′ (A1 logic identity · A2′ marker + required cell-name column)"

GOLD=$FX/pinreset_scope_marker.txt
STRIP=docs/silicon-tools/strip_lean_comments.awk

# `logic` = comments stripped, then BLANK LINES DROPPED. The shared stripper
# preserves line NUMBERING by design (so grep -n offsets survive), which means a
# deleted comment leaves a blank line behind; comparing those blanks measures
# ALIGNMENT, not logic, and reports a false RED. Caught on this check's own
# first run — it failed in the alarming direction, which is the lucky one.
logic() { awk -f "$STRIP" "$1" | grep -v '^[[:space:]]*$'; }

# emit <tag> <src.v> <pin|nopin>
emit() {
  local tag=$1 src=$2 mode=$3 pin=""
  mkdir -p "$TMP/$tag"
  cp "$src" "$TMP/$tag/pinreset_fx.v"
  [ "$mode" = pin ] && pin="--pin-reset rst_n"
  python3 "$IMP" "$TMP/$tag/pinreset_fx.v" --top pinreset_fx --out "$TMP/$tag.lean" \
      --name fxNL --inputs clk,d0,d1 --outputs q0,q1 $pin --check off >/dev/null 2>&1
}

a1() { logic "$1" >"$TMP/l1"; logic "$2" >"$TMP/l2"; cmp -s "$TMP/l1" "$TMP/l2"; }
a2() { # diff must be EXACTLY the golden marker: no removals, additions == golden
  diff "$2" "$1" >"$TMP/d"
  grep '^< ' "$TMP/d" | sed 's/^< //' >"$TMP/rm"
  grep '^> ' "$TMP/d" | sed 's/^> //' >"$TMP/add"
  [ ! -s "$TMP/rm" ] || return 1
  cmp -s "$TMP/add" "$GOLD"
}

cellcol() { grep -E '^\* `' "$1" | sed 's/.*, \(df[rx]tp_1\))/\1/'; }

# a2p  — A2′, ADOPTED by the helm 08/12 19:07:52 and re-confirmed 19:15:19.
# Characterises the ENTIRE diff positively: the mandated scope marker PLUS the
# flop table's cell-name column, each asserted in its REQUIRED DIRECTION, nothing
# tolerated. The column clause is the experiment's INDEPENDENT VARIABLE and is
# asserted STRUCTURALLY (every pinned row names dfrtp_1, every rewrite row names
# dfxtp_1) — never as "pc != xc", which any difference would satisfy, including a
# wrong one. ⭐ THE VACUITY CLAUSE: if the two arms' columns MATCH, the arms were
# the same input and the comparison reports nothing — that is a RED, not a pass.
# ⛔ EXTRACTED INTO A FUNCTION ON PURPOSE: as straight-line code it could not be
# invoked on a planted input, so it could not be controlled. A criterion that
# cannot be handed a fixture cannot be shown to fail.
a2p() { # $1 = pinned datum, $2 = rewrite datum
  local npc nxc
  cat "$GOLD" >"$TMP/gold2"
  grep -E '^\* `' "$1" >>"$TMP/gold2"
  diff "$2" "$1" >"$TMP/d2"
  grep '^< ' "$TMP/d2" | sed 's/^< //' >"$TMP/rm2"
  grep '^> ' "$TMP/d2" | sed 's/^> //' >"$TMP/add2"
  grep -E '^\* `' "$2" >"$TMP/xcells"
  cellcol "$1" >"$TMP/pc"; cellcol "$2" >"$TMP/xc"
  npc=$(grep -c . "$TMP/pc"); nxc=$(grep -c . "$TMP/xc")
  [ "$npc" -gt 0 ] && [ "$npc" -eq "$nxc" ] \
    && [ "$(grep -c '^dfrtp_1$' "$TMP/pc")" -eq "$npc" ] \
    && [ "$(grep -c '^dfxtp_1$' "$TMP/xc")" -eq "$nxc" ] \
    && cmp -s "$TMP/rm2" "$TMP/xcells" && cmp -s "$TMP/add2" "$TMP/gold2"
}

# ⛔ A MISSING FIXTURE IS A REFUSAL, NEVER A PASS. An earlier draft of this block
# guarded each row with `[ -f "$GOLD" ] && a2 ...`; with the golden absent that
# short-circuits into the ELSE branch and PRINTS ✅. That is precisely the
# silent-skip-reads-as-a-pass defect written into this file's own header, shipped
# again one function lower. Guard by REFUSING up front, never inside a row.
if [ ! -f "$GOLD" ]; then
  echo "  ⛔ C3 — golden scope marker missing ($GOLD); refusing to report a comparison"
  fail=1
else
  cp "$FX/pinreset_base.v" "$TMP/base.v"
  sed 's/dfrtp_1/dfxtp_1/; s/, \.RESET_B(rst_n)//' "$TMP/base.v" >"$TMP/rewrite.v"
  cmp -s "$TMP/rewrite.v" "$FX/pinreset_dfxtp.v" \
    && echo "  ✅ C3  arm provenance: committed dfxtp fixture IS the registered rewrite" \
    || { echo "  ✗ C3  committed dfxtp fixture has DRIFTED from the rewrite"; fail=1; }
  emit p "$TMP/base.v" pin
  emit x "$TMP/rewrite.v" nopin
  if [ ! -s "$TMP/p.lean" ] || [ ! -s "$TMP/x.lean" ]; then
    echo "  ⛔ C3 — one or both arms produced nothing; refusing to report a comparison"
    fail=1
  else
    if a1 "$TMP/p.lean" "$TMP/x.lean"; then
      echo "  ✅ C3.A1 pinned datum is GATE-FOR-GATE the dfxtp reading"
    else
      echo "  ✗ C3.A1 emitted LOGIC differs — the substantive claim; investigate:"
      diff "$TMP/l2" "$TMP/l1" | head -12 | sed 's/^/        /'
      fail=1
    fi
    # --- C3.M  MARKER INTEGRITY, asserted INDEPENDENTLY of A2.
    # ⛔ Found by the instrument self-test 2026-08-12: while A2 is red (as it is,
    # by ruling), a CORRUPTED golden — as opposed to an absent one — changed
    # NOTHING that gates. A2 was already failing, NC3b and NC3c only require a2()
    # to fail, and the exit code was 1 either way. The golden could rot in place
    # and every discharging row would print exactly what it prints now.
    # The cure is a check that does not route through A2: the golden must appear
    # VERBATIM AND CONTIGUOUSLY in the emitted datum.
    if python3 -c 'import sys; g=open(sys.argv[1]).read(); d=open(sys.argv[2]).read(); sys.exit(0 if g and g in d else 1)' \
         "$GOLD" "$TMP/p.lean"; then
      echo "  ✅ C3.M  golden marker appears VERBATIM in the emitted datum"
    else
      echo "  ⛔ C3.M  MARKER INTEGRITY — the golden does not appear verbatim in"
      echo "     the emitted datum. Either the importer's marker changed or the"
      echo "     golden was edited; both are defects of the scope chain (helm"
      echo "     condition (2)) and neither is visible through A2 while A2 is red."
      diff <(sed -n '/RESTRICTED DATUM/,/prereg-0812.md/p' "$TMP/p.lean") "$GOLD" \
        | head -8 | sed 's/^/       /'
      fail=1
    fi
    # --- C3.A2, the SUPERSEDED criterion. ⓘ INFORMATIONAL as of the helm's
    # 08/12 19:07:52 ruling: it does not touch `fail`. It is RED BY DESIGN and
    # always will be — the flop table's cell-name column is the experiment's
    # INDEPENDENT VARIABLE, and A2 counts that required difference as a residual.
    # Kept, not deleted, because its red is the EVIDENCE for the amendment: an
    # exception list was the wrong SHAPE, which is what A2′ replaces.
    if a2 "$TMP/p.lean" "$TMP/x.lean"; then
      echo "  ⓘ  C3.A2 (SUPERSEDED, non-discharging) GREEN — diff is exactly the marker"
    else
      echo "  ⓘ  C3.A2 (SUPERSEDED, non-discharging) RED as expected — the diff carries"
      echo "      the cell-name column, which A2′ asserts positively instead of tolerating."
      [ -s "$TMP/rm" ] && { echo "      removed (must be none):"; sed 's/^/        /' "$TMP/rm"; }
    fi
    # --- C3.A2′ — DISCHARGING. Adopted by the helm 08/12 19:07:52, re-confirmed
    # 19:15:19, released to this seat 08/13 15:01:02. This is the criterion the
    # bar now closes on. Evidence prints IMMEDIATELY, before any control runs, so
    # a later control invocation cannot clobber the scratch it reads (risk R1 of
    # docs/silicon-a2prime-promotion-prereg-0813.txt).
    if a2p "$TMP/p.lean" "$TMP/x.lean"; then
      echo "  ✅ C3.A2′ diff is EXACTLY the marker PLUS the required cell-name column"
    else
      echo "  ⛔ C3.A2′ RED — the positive characterisation of the diff does not hold."
      echo "     PRINTING THE OBJECT BESIDE THE VERDICT (evidence's law, 8/12):"
      [ -s "$TMP/rm2" ] && { echo "     removed vs the rewrite arm's flop rows:";
                             diff "$TMP/xcells" "$TMP/rm2" | sed 's/^/       /'; }
      echo "     added vs marker+column:"; diff "$TMP/gold2" "$TMP/add2" | sed 's/^/       /'
      cmp -s "$TMP/pc" "$TMP/xc" && echo "     ⛔ cell-name column IDENTICAL — THE ARMS ARE NOT DISTINCT,"
      cmp -s "$TMP/pc" "$TMP/xc" && echo "        so this comparison reports that the treatment never applied."
      fail=1
    fi

    # --- the controls for the amended check. A1 and A2 must each be SHOWN able
    # to fail, on this run, or neither verdict above discriminates.
    sed 's/^  \.and 5 2$/  .or 5 2/' "$TMP/p.lean" >"$TMP/p_gate.lean"
    if cmp -s "$TMP/p.lean" "$TMP/p_gate.lean"; then
      echo "  ⛔ NC3a plant did not apply — control VOID"; fail=1
    elif a1 "$TMP/p_gate.lean" "$TMP/x.lean"; then
      echo "  ✗ NC3a A1 stayed GREEN on a perturbed gate"; fail=1
    else echo "  ✅ NC3a A1 goes RED on a perturbed gate"; fi

    # ⛔ NC3b/NC3c ARE RE-POINTED FROM a2 TO a2p AT THIS LANDING. A2 no longer
    # discharges, so a control that still tested it would be testing a MUTE row:
    # the promoted criterion would ship with no negative control at all. A control
    # must be aimed at the check that actually gates.
    sed 's/^-- DO NOT EDIT\..*/-- DO NOT EDIT. tampered/' "$TMP/p.lean" >"$TMP/p_cmt.lean"
    if cmp -s "$TMP/p.lean" "$TMP/p_cmt.lean"; then
      echo "  ⛔ NC3b plant did not apply — control VOID"; fail=1
    elif a2p "$TMP/p_cmt.lean" "$TMP/x.lean"; then
      echo "  ✗ NC3b A2′ stayed GREEN on an extra non-marker difference"; fail=1
    else echo "  ✅ NC3b A2′ goes RED on an extra non-marker difference"; fi

    # NC3c is the direct test of helm condition (2): the marker must RIDE.
    grep -v 'RESTRICTED DATUM\|traces where\|THROUGHOUT\|vendor .clear\|Liberty ff group\|deassertion seam\|clock interact\|COVERING RESET\|must carry this\|dfrtp-async-reset-prereg' \
        "$TMP/p.lean" >"$TMP/p_nomark.lean"
    if cmp -s "$TMP/p.lean" "$TMP/p_nomark.lean"; then
      echo "  ⛔ NC3c plant did not apply — control VOID"; fail=1
    elif a2p "$TMP/p_nomark.lean" "$TMP/x.lean"; then
      echo "  ✗ NC3c A2′ stayed GREEN with the mandated marker stripped"; fail=1
    else echo "  ✅ NC3c A2′ goes RED when the mandated marker is absent"; fi

    # --- NC3d  ⭐ THE VACUITY CONTROL. NEW AT THIS LANDING, AND IT HAD NEVER
    # EXISTED. A2′'s column clause asserts THE ARMS ARE DISTINCT; nothing had
    # ever shown that clause could fail, so its green was untested. The helm
    # called the vacuity sentence the night's deepest — "an equivalence check
    # that passes when the independent variable vanishes is not reporting
    # equivalence, it is reporting that the treatment never applied." A criterion
    # carrying that sentence with no control is the sentence unexercised.
    # The plant makes the PINNED arm name dfxtp_1, so both columns match.
    sed 's/, dfrtp_1)/, dfxtp_1)/' "$TMP/p.lean" >"$TMP/p_vac.lean"
    if cmp -s "$TMP/p.lean" "$TMP/p_vac.lean"; then
      echo "  ⛔ NC3d plant did not apply — control VOID"; fail=1
    elif a2p "$TMP/p_vac.lean" "$TMP/x.lean"; then
      echo "  ✗ NC3d A2′ stayed GREEN when the arms were NOT DISTINCT — the"
      echo "     vacuity clause does not discriminate; A2′ would pass a comparison"
      echo "     in which the treatment never applied"; fail=1
    else echo "  ✅ NC3d A2′ goes RED when the arms are NOT DISTINCT (vacuity clause fires)"; fi
  fi
fi

echo "pinreset controls: $n planted row(s), $( [ $fail -eq 0 ] && echo "ALL BEHAVED" || echo "FAILURES ABOVE" )"
exit $fail
