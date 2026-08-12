#!/bin/sh
# netlist_check.sh — BOTH HALVES of an emitted-netlist check, in one committed copy.
#
#   sh docs/silicon-tools/netlist_check.sh <netlist.v> [expected_cells] [expected_flops]
#   sh docs/silicon-tools/netlist_check.sh --selftest <netlist.v>
#
# SILICON seat, 2026-08-10 06:4x. WHY THIS FILE EXISTS, and it is not tidiness:
#
# ⛔ THE FLEET SPENT 06:28-06:38 ESTABLISHING THAT COUNTS AND PROPERTIES ARE
#    COMPLEMENTARY -- and then every one of us ran the property half as a
#    HAND-ROLLED INLINE ONE-OFF. Compiler hand-rolled it three times, once per
#    organ. I hand-rolled it twice and THE SECOND ONE WAS BROKEN: I dropped the
#    line that counts `assign`-driven nets and it printed 0/64 on a netlist I had
#    already measured at 64/64. Caught only because 0/64 was implausible.
#    ⇒ A PATTERN RE-TYPED IS A PATTERN RE-INVENTED. The cure is not more care;
#      care is what we were all spending. It is ONE COMMITTED COPY.
#
# THE TWO HALVES, and NEITHER SUBSUMES THE OTHER (evidence's complement clause,
# math's generalisation, compiler's seed -- established on the bus 06:28-06:38):
#
#   COUNT half     catches OMISSION and ADDITION. An extra cell that drives
#                  nothing changes the total and NOTHING ELSE. This is the only
#                  half that sees ADDED HARDWARE -- the failure mode a fabbed
#                  artifact should fear most.
#   PROPERTY half  catches WRONGNESS. "Every flop D driven exactly once" cannot
#                  be satisfied by the right NUMBER of wrong cells; a count can.
#
# ⇒ RUN BOTH. The selftest builds a mutant for EACH and requires that the OTHER
#   half MISSES it -- because a check that has only ever run on passing input has
#   not been shown to discriminate, and a PAIR of checks has not been shown to be
#   complementary until each one catches something the other does not.
set -u

SELFTEST=0
if [ "${1:-}" = "--selftest" ]; then SELFTEST=1; shift; fi
if [ $# -lt 1 ]; then
  # ⛔ THIS MESSAGE EXISTS BECAUSE A CAREFUL READER NEARLY FILED A FALSE DEFECT.
  # Compiler ran `--selftest` alone at 06:41, got a bare usage line, and had
  # "silicon's selftest arm is broken" half-composed before re-reading it. The tool
  # was working. A refusal that does not say WHY invites a bug report against a
  # correct instrument -- so this one names the reason, not just the shape.
  echo "⛔ netlist_check: a netlist is REQUIRED, including with --selftest."
  echo "   --selftest is not standalone: it MUTATES A BASE NETLIST (an orphan cell"
  echo "   for the count half, a double-driven D for the property half), so it has"
  echo "   nothing to do without one."
  echo "   usage: netlist_check.sh [--selftest] <netlist.v> [expected_cells] [expected_flops]"
  exit 2
fi
NL="$1"
EXP_CELLS="${2:-}"
EXP_FLOPS="${3:-}"
[ -f "$NL" ] || { echo "⛔ netlist_check: no such file: $NL"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "⛔ netlist_check: python3 absent"; exit 2; }

python3 - "$NL" "$EXP_CELLS" "$EXP_FLOPS" "$SELFTEST" <<'PYEOF'
import re, sys, collections

path, exp_cells, exp_flops, selftest = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
src = open(path).read()

def cells(s):
    return len(re.findall(r'sky130_fd_sc_hd__', s))

def parse(s):
    """Return (driven counter, flop D list, flop Q list). The `assign` line below is
    NOT optional -- omitting it reports 0 flops-ok on a healthy netlist, which is the
    exact defect that produced this file."""
    insts = re.findall(r'(sky130_fd_sc_hd__\w+)\s+(\w+)\s*\(([^;]*)\);', s)
    driven, D, Q = collections.Counter(), [], []
    for typ, name, conns in insts:
        p = dict(re.findall(r'\.(\w+)\s*\(\s*([^)]*?)\s*\)', conns))
        out = p.get('X') or p.get('Q') or p.get('Y')
        if out:
            driven[out] += 1
        if 'dfxtp' in typ:
            D.append(p.get('D')); Q.append(p.get('Q'))
    for m in re.finditer(r'assign\s+([\w\[\]]+)\s*=', s):
        driven[m.group(1)] += 1          # <-- THE LINE. Do not drop it again.
    return driven, D, Q

def property_ok(s):
    driven, D, Q = parse(s)
    ok = sum(1 for d in D if driven[d] == 1)
    qdup = [q for q, c in collections.Counter(Q).items() if c > 1]
    return ok, len(D), qdup

def report(s, label):
    n = cells(s)
    flops = len(re.findall(r'dfxtp', s))
    ok, tot, qdup = property_ok(s)
    conb = len(re.findall(r'conb', s))
    d1 = len(re.findall(r'dfxtp_1', s))
    assigns = len(re.findall(r'^  assign', s, re.M))
    print(f"  {label}")
    print(f"    COUNT     cells {n} · flops {flops} · assigns {assigns} · conb {conb} · dfxtp_1 {d1}")
    print(f"    PROPERTY  D driven exactly once {ok}/{tot}" + ("  ✅" if ok == tot else "  ⛔")
          + f" · Q distinct {'✅' if not qdup else '⛔'}")
    return n, flops, ok, tot, qdup

rc = 0
if selftest:
    print("SELFTEST — each mutant must be caught by ONE half and MISSED by the other:")
    # (a) ADDED HARDWARE: an orphan cell driving nothing. COUNT catches, PROPERTY blind.
    mut_a = src.replace("endmodule", "  wire n_selftest_orphan;\n  sky130_fd_sc_hd__and2_1 gSELFTEST (.A(i0), .B(i1), .X(n_selftest_orphan));\nendmodule", 1)
    ca, cb = cells(src), cells(mut_a)
    pa, ta, _ = property_ok(src); pb, tb, _ = property_ok(mut_a)
    count_caught = ca != cb
    prop_blind = (pb == tb)
    print(f"  (a) ORPHAN CELL   COUNT {ca}->{cb} {'✅ CATCHES' if count_caught else '⛔ MISSES'}"
          f" · PROPERTY {pb}/{tb} {'✅ blind, as expected' if prop_blind else '⛔ unexpectedly caught'}")
    if not (count_caught and prop_blind):
        rc = 2
    # (b) WRONGNESS: double-drive a flop's D. PROPERTY catches, COUNT blind.
    m = re.search(r'(sky130_fd_sc_hd__dfxtp_2\s+\w+\s*\([^;]*\.D\(\s*([\w\[\]]+)\s*\)[^;]*\);)', src)
    if m:
        dnet = m.group(2)
        mut_b = src.replace("endmodule", f"  sky130_fd_sc_hd__and2_1 gSELFTEST2 (.A(i0), .B(i1), .X({dnet}));\n  sky130_fd_sc_hd__and2_1 gSELFTEST3 (.A(i0), .B(i1), .X(n_selftest_pad));\n  wire n_selftest_pad;\nendmodule", 1)
        # two cells added so the COUNT delta matches (a) and cannot be the discriminator
        pc, tc, _ = property_ok(mut_b)
        prop_caught = pc != tc
        print(f"  (b) DOUBLE-DRIVEN D ({dnet})   PROPERTY {pc}/{tc} {'✅ CATCHES' if prop_caught else '⛔ MISSES'}"
              f" · COUNT would need the expected total to see it at all")
        if not prop_caught:
            rc = 2
    else:
        print("  (b) ⛔ could not build the double-drive mutant (no dfxtp_2 with a .D found)")
        rc = 2
    # (c) MULTI-LINE INSTANTIATION — PINS THE NEWLINE-SPANNING PROPERTY.
    #     Added 8/12 at evidence's taxonomy: a tool is IMMUNE BY FIXTURE (a test
    #     goes red if the property is removed) or IMMUNE BY LUCK (it happens to
    #     hold and NOTHING asserts it must). `parse()`'s connection regex uses
    #     `[^;]*`, which INCLUDES newline, so it reads multi-line instances. That
    #     was LUCK — the class was chosen for its delimiter, not for line
    #     spanning. A future hand writing `[^;\n]*` would make every multi-line
    #     instance INVISIBLE, silently, and real netlists format one connection
    #     per line.
    #     ⚠️ DELIBERATELY INDEPENDENT OF (b): the first version of this arm was
    #     gated on the same `dfxtp_2` search and therefore DID NOT RUN on the
    #     netlist I tested it with — a fixture that silently skips is the very
    #     thing it exists to prevent. This one needs nothing from the netlist but
    #     an `endmodule`.
    probe = "n_selftest_multiline"
    mut_c = src.replace("endmodule",
        "  sky130_fd_sc_hd__and2_1 gSELFTEST4 (\n"
        "      .A(i0),\n"
        "      .B(i1),\n"
        f"      .X({probe})\n"
        f"  );\n  wire {probe};\nendmodule", 1)
    seen = parse(mut_c)[0].get(probe, 0) > 0
    base = parse(src)[0].get(probe, 0) == 0
    print(f"  (c) MULTI-LINE INSTANCE   parser sees it: {'✅ YES' if seen else '⛔ NO — the connection regex no longer spans newlines; multi-line instances are INVISIBLE'}"
          + (" · absent from base ✅" if base else " · ⛔ probe net already in base, arm is vacuous"))
    if not (seen and base):
        rc = 2
    print("  ⇒ COMPLEMENTARY: each half catches what the other cannot." if rc == 0
          else "  ⇒ ⛔ SELFTEST FAILED — do not trust a green from this tool.")
    print()

n, flops, ok, tot, qdup = report(src, path)
if exp_cells:
    good = (n == int(exp_cells))
    print(f"    vs expected cells {exp_cells}: {'✅' if good else '⛔ MISMATCH'}")
    if not good: rc = 1
if exp_flops:
    good = (flops == int(exp_flops))
    print(f"    vs expected flops {exp_flops}: {'✅' if good else '⛔ MISMATCH'}")
    if not good: rc = 1
if ok != tot or qdup:
    rc = 1
sys.exit(rc)
PYEOF
