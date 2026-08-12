#!/bin/bash
# D1t — THE ADDRESS CHECKER. Stage ③, silicon's lane.
#
#   ./d1t_check.sh <verilog-file> <module-name>
#
# Decides whether a candidate is a correct 8-word LW/SW address mask per the
# RULING (SaltWorks/HDL/ISA.lean:111-124 + docs/memory-design-v1.md:388-390).
#
# EXIT   0  ACCEPT        both arms ran and passed
#        1  REJECT        an arm found a defect
#        2  INCONCLUSIVE  a tool failed; NOTHING is claimed either way
#
# ⛔⛔ THREE OUTCOMES, NOT TWO, AND THE THIRD IS THE WHOLE REASON THIS SCRIPT IS
# NOT A ONE-LINER. Measured 8/12 while prototyping: yosys `miter -equiv` EXITS 1
# WITHOUT PROVING ANYTHING when the candidate's port widths differ from the
# reference — "ERROR: No matching port in gate module was found for \word_index!"
# Both the 16-word sibling AND the wrong-port variant produced that exit. A
# checker that read only the exit code would have called both REJECTED and been
# RIGHT BY ACCIDENT: a construction error and a refutation are the same status
# byte. [[right-conclusion-wrong-reason]] — and a later yosys that learned to
# zero-extend mismatched ports would silently flip those arms to ACCEPT.
# So the two arms are separated, each reports its own verdict, and a tool failure
# is never allowed to read as either answer.
#
# ⛔ AND AN UNREACHED ARM IS PRINTED AS UNREACHED. When arm [A] rejects on the
# port signature, arm [B] CANNOT BE BUILT — the miter needs matching ports. That
# is reported as NOT REACHED with the reason, never omitted. A silent skip reads
# exactly like a pass; that is the S line of the pre-registered bar.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REF="$HERE/ref_dmem_addr8.v"
REFMOD="ref_dmem_addr8"

CAND="${1:?usage: d1t_check.sh <verilog-file> <module-name>}"
MOD="${2:?usage: d1t_check.sh <verilog-file> <module-name>}"

[ -f "$CAND" ] || { echo "d1t: candidate not found: $CAND"; exit 2; }
[ -f "$REF"  ] || { echo "d1t: reference not found: $REF";  exit 2; }
command -v yosys >/dev/null || { echo "d1t: yosys not on PATH"; exit 2; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

echo "D1t — dmem_addr8 ADDRESS CHECKER"
echo "  candidate : $CAND"
echo "  module    : $MOD"
echo "  reference : ${REF#"$(dirname "$HERE")"/}  (the RULING, arithmetic form)"
echo "  yosys     : $(yosys -V 2>/dev/null | head -1)"
echo

# ---------------------------------------------------------------- arm [A]
# STRUCTURAL. The port record is read from yosys's own JSON, never from the
# source text: [[instrument-inside-the-system]] — a regex over Verilog would be a
# second, worse parser, and it is the exact instrument the defect hides from.
echo "  [A] STRUCTURAL — port record, read from yosys JSON (not from the source text)"
A_STATUS=inconclusive
if ! yosys -q -p "read_verilog $CAND; proc; opt; write_json $WORK/cand.json" >"$WORK/a.log" 2>&1; then
    echo "      TOOL FAILURE reading the candidate:"
    sed 's/^/        /' "$WORK/a.log" | head -10
else
    python3 - "$WORK/cand.json" "$MOD" >"$WORK/a.out" 2>&1 <<'PYEOF'
import json, sys
j = json.load(open(sys.argv[1])); mod = sys.argv[2]
# THE RULED INTERFACE. word_index is 3 BITS — ISA.lean:121 (addrClass_ok_lt
# proves ok -> a.toNat / 4 < 8) and memory-design-v1.md:390 ("3 bits").
EXPECT = {
    "byte_addr":    ("input",  32),
    "req":          ("input",   1),
    "we_in":        ("input",   1),
    "misaligned":   ("output",  1),
    "out_of_range": ("output",  1),
    "trap":         ("output",  1),
    "we_out":       ("output",  1),
    "word_index":   ("output",  3),
}
fail = []
if mod not in j.get("modules", {}):
    print(f"      module '{mod}' NOT FOUND. present: {sorted(j.get('modules', {}))}")
    print("VERDICT FAIL"); sys.exit(0)
m = j["modules"][mod]
ports = m.get("ports", {})
for name, (d, w) in EXPECT.items():
    if name not in ports:
        print(f"        {name:<13} ABSENT                    expected {d} [{w}]")
        fail.append(f"port {name} absent"); continue
    gd, gw = ports[name].get("direction"), len(ports[name].get("bits", []))
    ok = (gd == d and gw == w)
    print(f"        {name:<13} {gd:<7} [{gw:>2}]   expected {d} [{w}]   {'ok' if ok else '<-- WRONG'}")
    if not ok:
        fail.append(f"port {name}: {gd}[{gw}] != {d}[{w}]")
for extra in sorted(set(ports) - set(EXPECT)):
    print(f"        {extra:<13} UNEXPECTED PORT")
    fail.append(f"unexpected port {extra}")
# The mask is combinational by ruling (dmem_addr16_stat: sequential 0.00%), and
# arm [B]'s soundness depends on it: `sat` without temporal induction treats a
# flop's output as a free variable, so a STATEFUL candidate could be "proved"
# over one timestep. This check is what makes arm [B] mean what it says.
seq = sorted({c["type"] for c in m.get("cells", {}).values()
              if any(k in c["type"].lower() for k in ("dff", "latch", "$mem", "sr_"))})
if seq:
    print(f"        SEQUENTIAL ELEMENTS PRESENT: {seq}")
    print("        (the ruled mask is combinational; arm [B] would be UNSOUND here)")
    fail.append(f"sequential elements: {seq}")
else:
    print("        sequential elements   none            expected none   ok")
print("VERDICT " + ("FAIL: " + "; ".join(fail) if fail else "PASS"))
PYEOF
    grep -v '^VERDICT ' "$WORK/a.out"
    if grep -q '^VERDICT PASS' "$WORK/a.out"; then A_STATUS=pass
    elif grep -q '^VERDICT FAIL' "$WORK/a.out"; then A_STATUS=fail
    fi
fi
case "$A_STATUS" in
  pass) echo "      VERDICT: PASS — interface matches the ruled signature" ;;
  fail) echo "      VERDICT: FAIL — $(sed -n 's/^VERDICT FAIL: //p' "$WORK/a.out")" ;;
  *)    echo "      VERDICT: INCONCLUSIVE — the structural reader itself failed" ;;
esac
echo

# ---------------------------------------------------------------- arm [B]
# BEHAVIOURAL. Exhaustive: `sat -prove-asserts` over the miter covers ALL 2^34
# input assignments (byte_addr 32 + req 1 + we_in 1). This is a PROOF, not a
# testbench — no coverage claim is being made or needed.
echo "  [B] BEHAVIOURAL — miter -equiv + sat -prove-asserts vs the reference"
echo "      scope: ALL 2^34 input assignments (byte_addr[32] x req x we_in)"
B_STATUS=notreached
if [ "$A_STATUS" != pass ]; then
    echo "      VERDICT: NOT REACHED — arm [A] did not pass, so the miter cannot be"
    echo "               built (it requires matching port names and widths). This arm"
    echo "               is UNRUN, which is not a pass and not a failure."
else
    yosys -p "
        read_verilog -formal $CAND $REF
        proc; opt
        miter -equiv -make_assert $MOD $REFMOD mtr
        hierarchy -top mtr; flatten; opt
        sat -verify -prove-asserts -show-inputs -show-outputs mtr
    " >"$WORK/b.log" 2>&1
    if grep -q 'SAT proof finished - no model found: SUCCESS!' "$WORK/b.log"; then
        B_STATUS=proved
        echo "      VERDICT: PROVED EQUIVALENT to the reference on every input"
    elif grep -q 'SAT proof finished - model found: FAIL!' "$WORK/b.log"; then
        B_STATUS=refuted
        echo "      VERDICT: REFUTED — counterexample:"
        sed -n '/Signal Name/,/^$/p' "$WORK/b.log" | sed 's/^/        /' | head -14
    else
        B_STATUS=toolfail
        echo "      VERDICT: INCONCLUSIVE — the prover did not return a verdict:"
        grep -E 'ERROR|Warning' "$WORK/b.log" | sed 's/^/        /' | head -6
    fi
fi
echo

# ---------------------------------------------------------------- S — the scope line
echo "  SCOPE — examined, and NOT reached:"
echo "      EXAMINED   the port signature (names, directions, widths) and the"
echo "                 absence of state, from yosys's own module record; and, when"
echo "                 arm [B] ran, functional equality with the reference on all"
echo "                 2^34 inputs."
echo "      NOT REACHED  the F4 bridge: whether the RULING is what the kernel"
echo "                 means. This checker compares a candidate to a TRANSCRIPTION"
echo "                 of the ruling written by the same hand as the candidate."
echo "                 A mistranscription is invisible to it in both directions."
echo "      NOT REACHED  timing, area, power, and the fabbed netlist. This reads"
echo "                 RTL; the die is built by TinyTapeout CI from other bytes."
echo "      NOT REACHED  composition with dmem8. A correct mask wired to the wrong"
echo "                 organ port is outside this instrument."
if [ "$B_STATUS" = notreached ]; then
echo "      NOT REACHED  BEHAVIOUR — arm [B] never ran. See its verdict above."
fi
echo

# ---------------------------------------------------------------- the verdict
if [ "$A_STATUS" = pass ] && [ "$B_STATUS" = proved ]; then
    echo "  VERDICT: ACCEPT"; exit 0
elif [ "$A_STATUS" = fail ] || [ "$B_STATUS" = refuted ]; then
    echo "  VERDICT: REJECT"; exit 1
else
    echo "  VERDICT: INCONCLUSIVE — a tool failed. Nothing is claimed about this"
    echo "           candidate in either direction."; exit 2
fi
