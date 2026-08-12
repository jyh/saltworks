#!/bin/bash
# D1t — RUN THE PRE-REGISTERED ACCEPTANCE BAR. Stage ③, silicon's lane.
#
#   ./run_bar.sh          # every arm, with the full per-arm report
#   ./run_bar.sh -q       # the verdict table only
#
# EXIT 0 only if EVERY arm behaves as REGISTERED — each REJECT arm rejects, the
# ACCEPT arm accepts. Any other outcome, including INCONCLUSIVE, exits nonzero.
#
# ⛔ THE EXIT STATUS IS THE POINT. [[printed-is-not-gated]]: a criterion whose
# result nothing consumes is a printout. This script's status is what a caller
# gates on — `./run_bar.sh && <land>` — and it is computed from every arm, not
# from the last one to run.
#
# ⭐ EVERY ARM REQUIRES A PLANTED FAILURE THAT IT CATCHES. A checker never shown
# to reject is not a checker ([[a-check-never-shown-to-fail]]), and precision
# reads exactly like strength. T5 alone is satisfied by a tool that accepts
# everything; T1-T4 and T6 alone by one that rejects everything. Both halves or
# the bar discriminates nothing.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RTL="$HERE/../../RTL"
CHECK="$HERE/d1t_check.sh"
QUIET=0; [ "${1:-}" = "-q" ] && QUIET=1

# arm | expectation | file | module | what it plants
ARMS=(
"T1 |REJECT|$RTL/dmem_addr16.v                    |dmem_addr16|the sibling, UNMODIFIED (16-word mask, correct code for another memory)"
"T1b|REJECT|$HERE/plants/T1b_bound16_correct_port.v|dmem_addr8 |the 16-word BOUND with the port already fixed — the real accident"
"T2 |REJECT|$HERE/plants/T2_we_ungated.v          |dmem_addr8 |trap raised, write NOT suppressed"
"T3 |REJECT|$HERE/plants/T3_oor_absent.v          |dmem_addr8 |out_of_range absent, misaligned correct"
"T4 |REJECT|$HERE/plants/T4_mis_absent.v          |dmem_addr8 |misaligned absent, out_of_range correct"
"T5 |ACCEPT|$RTL/dmem_addr8.v                     |dmem_addr8 |THE REAL MODULE — the only arm that must pass"
"T6 |REJECT|$HERE/plants/T6_port4.v               |dmem_addr8 |both assignments correct, port left [3:0]"
)

declare -a ROWS; FAILED=0
for spec in "${ARMS[@]}"; do
    IFS='|' read -r arm want file mod desc <<<"$spec"
    arm="${arm// /}"; file="${file// /}"; mod="${mod// /}"
    if [ "$QUIET" = 0 ]; then
        printf '\n══════ ARM %s — must %s ══════\n%s\n\n' "$arm" "$want" "$desc"
        "$CHECK" "$file" "$mod"; rc=$?
    else
        "$CHECK" "$file" "$mod" >/dev/null 2>&1; rc=$?
    fi
    case $rc in 0) got=ACCEPT ;; 1) got=REJECT ;; *) got=INCONCLUSIVE ;; esac
    if [ "$got" = "$want" ]; then res="as registered"; else res="⛔ BAR VIOLATED"; FAILED=1; fi
    ROWS+=("$(printf '  %-4s want %-6s got %-12s %s' "$arm" "$want" "$got" "$res")")
done

printf '\n══════════════════════════════════════════════════════════════\n'
echo "D1t ACCEPTANCE BAR — pre-registered 8/12 10:00 (T1-T5, S), T1b and T6"
echo "added 10:1x BEFORE the checker existed. No arm has been removed or"
echo "narrowed. Registration history: see README.md."
printf '══════════════════════════════════════════════════════════════\n'
printf '%s\n' "${ROWS[@]}"
printf '══════════════════════════════════════════════════════════════\n'
if [ "$FAILED" = 0 ]; then
    echo "D1t BAR: CLEARED — every arm behaved as registered."
    echo "  Discriminating pair present: T5 accepted AND T1/T1b/T2/T3/T4/T6 rejected,"
    echo "  so the bar is satisfied by neither an accept-all nor a reject-all tool."
    exit 0
else
    echo "D1t BAR: NOT CLEARED — at least one arm did not behave as registered."
    exit 1
fi
