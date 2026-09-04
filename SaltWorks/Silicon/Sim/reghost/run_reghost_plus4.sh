#!/bin/sh
# run_reghost_plus4.sh — DRIVE §7's "+4" SECOND LOAD LOOP BOTH WAYS.
#
# Criteria and the bar are PRE-REGISTERED in
# docs/silicon-ndf-option2-plus4-prereg-0904.md §3-§5, written before the bench
# existed and before busadapt8.v was touched.
#
# ⛔ WHY THIS IS COMMITTED AND NOT A SCRATCH INVOCATION: a green bench is only
#    evidence if the same bench can go RED on the quantity in question. That pair
#    is the receipt, and a receipt whose PRODUCER lives in a terminal dies with the
#    terminal. Producer is code; the input is named by sha in the commit.
#
# ARM GREEN  as shipped              T_LOAD retires on `load_beat`  — option (2)
# ARM RED    mutation               T_LOAD retires on `1'b1`        — the one-loop LOAD
#                                    (both edits reverted together, so ARM RED IS the
#                                     pre-09/04 design and not a half-broken hybrid)
# ARM GAP    -DREGHOST_FETCH        the FETCH row registered too — NOT part of (2)
#
# ⭐ THE BAR, PRE-STATED: ARM RED must fail G3 AND G4. ARM GREEN must pass 6/6.
#   G2 (the store path, which needs no turnaround) must pass on BOTH — a control
#   that fails everywhere is measuring the harness, not the design.
set -e
HERE=$(cd "$(dirname "$0")" && pwd); RTL="$HERE/../../RTL"; TB="$HERE/tb_plane32bus_reghost.v"
T=${TMPDIR:-/tmp}/reghost_plus4.$$; mkdir -p "$T/mut"; trap 'rm -rf "$T"' EXIT
cp "$RTL/plane32bus.v" "$RTL/core32.v" "$T/mut/"
# ⛔ BLOCK COMMENTS, NOT `//`. A `//` marker here silently ATE THE REST OF A
#   ONE-LINE STATEMENT (`... rdata_r <= {pin_in, in_acc[23:0]};`) and the mutated
#   file would not parse — a control that dies in the compiler reports the same
#   nothing as a control that never applied.
sed -e "s|: (kind == T_LOAD)  ? load_beat|: (kind == T_LOAD)  ? 1'b1 /* MUTATED */|" \
    -e "s|if (kind == T_LOAD \&\& load_beat) rdata_r|if (kind == T_LOAD /* MUTATED */) rdata_r|" \
    "$RTL/busadapt8.v" > "$T/mut/busadapt8.v"

# ⛔ THE MUTATION MUST SURVIVE THE PIPELINE, OR THE "CONTROL" IS THEATRE. This seat
#   has shipped a control whose mutation never reached the compared text; assert it.
NMUT=$(grep -c 'MUTATED' "$T/mut/busadapt8.v" || true)
if [ "$NMUT" -ne 2 ]; then
  echo "REGHOST_PLUS4=FAIL (mutation did not apply: $NMUT/2 sites — the control is inert)"; exit 2
fi

iverilog -g2005 -o "$T/green.vvp" "$TB" "$RTL/plane32bus.v" "$RTL/core32.v" "$RTL/busadapt8.v"
# ⛔ AND THE MUTATED FILE MUST COMPILE. A control that dies in the compiler produces
#   zero `G-pass` lines, which reads EXACTLY like a control that went red for the
#   right reason. Refuse loudly instead.
if ! iverilog -g2005 -o "$T/red.vvp" "$TB" "$T/mut"/*.v 2>"$T/red.cc"; then
  echo "REGHOST_PLUS4=FAIL (the MUTATED arm does not compile — it is not a red, it is a crash)"
  head -5 "$T/red.cc"; exit 2
fi
iverilog -g2005 -DREGHOST_FETCH -o "$T/gap.vvp" "$TB" "$RTL/plane32bus.v" "$RTL/core32.v" "$RTL/busadapt8.v"
vvp "$T/green.vvp" > "$T/green.out" 2>&1 || true
vvp "$T/red.vvp"   > "$T/red.out"   2>&1 || true
vvp "$T/gap.vvp"   > "$T/gap.out"   2>&1 || true

G=$(grep -c 'G-FAIL' "$T/green.out" || true); R=$(grep -c 'G-FAIL' "$T/red.out" || true)
echo "ARM GREEN (option 2, as shipped)  G-FAIL count = $G"
grep -E 'loops:|ALL PASS|RED:' "$T/green.out" || true
echo "ARM RED   (one-loop LOAD, mutated) G-FAIL count = $R"
grep -E 'loops:|ALL PASS|RED:' "$T/red.out" || true
grep -o 'x3=[0-9a-fx]*' "$T/red.out" | head -1 | sed 's/^/ARM RED loaded register: /'

# the named criteria, not just a count — a count cannot say WHICH criterion moved
red_g3=$(grep -c 'G-FAIL  G3' "$T/red.out" || true)
red_g4=$(grep -c 'G-FAIL  G4' "$T/red.out" || true)
red_g2=$(grep -c 'G-pass  G2' "$T/red.out" || true)
grn_g2=$(grep -c 'G-pass  G2' "$T/green.out" || true)

echo "--- ARM GAP (fetch registered too — a MEASUREMENT, not part of option (2)) ---"
grep -E 'loops:|ALL PASS|RED:' "$T/gap.out" || true
gap_fails=$(grep -c 'G-FAIL' "$T/gap.out" || true)
if [ "$gap_fails" -eq 0 ]; then
  echo "⭐ ARM GAP IS GREEN — the FETCH row no longer needs an in-phase turnaround."
  echo "   That would be NEWS: re-read prereg §5, this script asserts nothing about it."
else
  echo "ARM GAP RED ($gap_fails/6) — the FETCH row still demands an in-phase turnaround."
  echo "   §7 relieved the LOAD row only. This is a SEPARATE row, not a defect in (2)."
fi

if [ "$G" -eq 0 ] && [ "$red_g3" -ge 1 ] && [ "$red_g4" -ge 1 ] \
   && [ "$red_g2" -ge 1 ] && [ "$grn_g2" -ge 1 ]; then
  echo "REGHOST_PLUS4=PASS (green 6/6; red fails G3+G4; G2 passes on BOTH arms)"; exit 0
else
  echo "REGHOST_PLUS4=FAIL (G=$G red_g3=$red_g3 red_g4=$red_g4 red_g2=$red_g2 grn_g2=$grn_g2)"; exit 1
fi
