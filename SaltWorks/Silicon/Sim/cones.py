#!/usr/bin/env python3
"""CONE CENSUS — does per-cone certification scale on a REAL TinyTapeout netlist?

The flow flattens: a submission has exactly one module, so "equivalence per
module" has no modules left to be per. The replacement is per-COMBINATIONAL-CONE:
every flop D-pin and every primary output roots a cone of pure combinational
logic, bounded by flop Q-pins, primary inputs and constants.

The decisive number is NOT the cone's gate count -- it is the cone's INPUT count,
because a bit-sliced certificate costs 2^inputs bits per net. Compiler measured a
hard kernel ceiling at 24 input bits (Nat.pow is GMP-accelerated only to exponent
1<<<24). So: what fraction of real cones have <= 24 inputs?

⚠️ THE DEFAULT CUT SET IS NOT THE ONLY ONE, AND THAT MATTERS (measured 8/6 16:2x).
Rooting cones only at flop D-pins and primary outputs answers "how big are the
cones this netlist happens to have". It does NOT answer "how big are the cones we
could certify", because a proof may cut anywhere it likes -- at any net that
still EXISTS. Marking the fabric's stage boundaries `(* keep *)` is exactly what
makes them still exist after the flow flattens, and cutting there takes the TT
top module from max 36 inputs / 86.9% to **max 16 inputs / 100%**.

Run WITHOUT --cut and the census is blind to that: it reports 86.9% whether or
not the boundaries survived. So a keep-vs-no-keep comparison run on the default
cut set is treatment-insensitive and must not be read as evidence about `keep`.

Usage:  cones.py [--cut REGEX] <netlist.v> [...]
        --cut REGEX   also treat every net whose name matches REGEX as a cone
                      boundary (both a root and a leaf) -- i.e. certify there.
"""
import sys, collections, re
sys.path.insert(0, __import__("os").path.dirname(__file__))
from refparse import tokenize

# Physical-only cells: no logic, not in Liberty, must not be treated as gates.
PHYSICAL = {"tapvpwrvgnd", "fill", "decap", "diode", "fill_diode"}
PG = {"VPWR", "VGND", "VPB", "VNB"}
# Sequential cells: their outputs are cone LEAVES, their D/inputs are cone ROOTS.
SEQ_PREFIX = ("dfxtp", "dfrtp", "dfstp", "dfbbn", "dfbbp", "dlxtp", "dlrtp",
              "sdfxtp", "sdfrtp", "sdfstp", "edfxtp", "dfxbp", "dfrbp")
# Output pin names in sky130_fd_sc_hd
OUTPINS = {"X", "Y", "Q", "Q_N", "COUT", "SUM", "HI", "LO"}


def parse(path):
    """-> (instances, module_inputs, module_outputs)
    instance = (celltype, instname, {pin: net})"""
    toks = tokenize(open(path).read())
    i, n = 0, len(toks)
    insts, minputs, moutputs = [], set(), set()

    def nm(t):
        return t[1]

    while i < n:
        k, v = toks[i]
        if k == "ID" and v in ("input", "output", "wire", "inout"):
            decl = v
            i += 1
            # optional range [a:b]
            if i < n and toks[i] == ("P", "["):
                while i < n and toks[i] != ("P", "]"):
                    i += 1
                i += 1
            names = []
            while i < n and toks[i] != ("P", ";"):
                if toks[i][0] in ("ID", "ESCID"):
                    names.append(nm(toks[i]))
                i += 1
            if decl == "input":
                minputs.update(names)
            elif decl == "output":
                moutputs.update(names)
            i += 1
        elif k == "ID" and v.startswith("sky130_"):
            cell = v
            i += 1
            iname = nm(toks[i]) if i < n and toks[i][0] in ("ID", "ESCID") else "?"
            i += 1
            conns = {}
            depth = 0
            while i < n:
                if toks[i] == ("P", "("):
                    depth += 1
                    i += 1
                elif toks[i] == ("P", ")"):
                    depth -= 1
                    i += 1
                    if depth == 0:
                        break
                elif toks[i] == ("P", "."):
                    pin = nm(toks[i + 1])
                    i += 2                       # . PIN
                    assert toks[i] == ("P", "(")
                    i += 1
                    depth += 1
                    net = None
                    d2 = 1
                    while i < n and d2 > 0:
                        if toks[i] == ("P", "("):
                            d2 += 1
                        elif toks[i] == ("P", ")"):
                            d2 -= 1
                            if d2 == 0:
                                break
                        elif toks[i][0] in ("ID", "ESCID"):
                            base = nm(toks[i])
                            # ⛔ SOUNDNESS FIX (8/6, found by R3's regfile). The
                            # bit-select used to be composed for `ID` ONLY. An
                            # ESCAPED vector net — `\regs[20] [26]`, which is how
                            # yosys writes a register-file bit — fell through
                            # with `base = "regs[20]"`, and then the `[`, `26`,
                            # `]` tokens were re-scanned by the loop: `26` hit
                            # the NUM branch below and OVERWROTE the net with the
                            # phantom constant `1'b26`.
                            #
                            # Effect: all 992 regfile bits became 32 fake
                            # constants, constants are leaves, and the census
                            # reported max 6 inputs for cones that genuinely have
                            # 36. It did not warn — it produced a CONFIDENT WRONG
                            # NUMBER, on the exact shape the CPU road is made of.
                            #
                            # Latent for the banyan, whose escaped nets carry the
                            # index INSIDE the escape (`\fabric.w0[0]`), so no
                            # `[` follows and nothing was corrupted — which is
                            # why every banyan figure cross-checked clean.
                            if (i + 1 < n and toks[i + 1] == ("P", "[")
                                    and i + 2 < n and toks[i + 2][0] == "NUM"
                                    and i + 3 < n and toks[i + 3] == ("P", "]")):
                                base = f"{base}[{nm(toks[i + 2])}]"
                                i += 3
                            net = base
                        elif toks[i][0] == "NUM":
                            # A bare NUM here is a literal (`1'b0`). A bit-select
                            # index can no longer reach this branch: it is
                            # consumed above, with its brackets.
                            net = "1'b" + toks[i][1]
                        i += 1
                    depth -= 1
                    i += 1
                    if net is not None:
                        conns[pin] = net
                else:
                    i += 1
            insts.append((cell, iname, conns))
            while i < n and toks[i] != ("P", ";"):
                i += 1
        else:
            i += 1
    return insts, minputs, moutputs


def short(cell):
    return cell.replace("sky130_fd_sc_hd__", "")


def analyse(path):
    insts, minputs, moutputs = parse(path)
    driver = {}          # net -> (cell, inst, conns)
    seq_out = set()      # nets driven by a flop  -> cone leaves
    roots = []           # (label, net) each rooting a cone
    logic = 0
    physical = 0
    for (cell, iname, conns) in insts:
        s = short(cell)
        if any(s.startswith(p) for p in PHYSICAL) or s.split("_")[0] in PHYSICAL:
            physical += 1
            continue
        logic += 1
        outs = [(p, nt) for p, nt in conns.items() if p in OUTPINS]
        is_seq = s.startswith(SEQ_PREFIX)
        for p, nt in outs:
            driver[nt] = (s, iname, conns)
            if is_seq:
                seq_out.add(nt)
        if is_seq:
            for p, nt in conns.items():
                # ⛔ `DE` ADDED 8/6 (found by R3). `edfxtp` is the ENABLE flop,
                # and yosys reaches for it whenever a register has a conditional
                # write — which is every register file and every CPU state
                # element. Its enable pin carries the ENTIRE write-decode cone
                # (address compare + we); its `D` is often wired straight to a
                # data input and roots a 1-input cone. Omitting `DE` therefore
                # hid the only interesting write cone in the design while
                # reporting the trivial one, and the census looked healthy.
                if p in ("D", "DE", "SCD", "SCE", "SET_B", "RESET_B") and p != "CLK":
                    roots.append((f"{iname}.{p}", nt))
    for o in moutputs:
        roots.append((f"out:{o}", o))
        # vector ports appear bit-wise in instances
    # also catch bit-selected output ports actually driven
    for nt in list(driver):
        if "[" in nt and nt.split("[")[0] in moutputs:
            roots.append((f"out:{nt}", nt))

    # Extra cut points: nets the proof chooses to certify at. They root their own
    # cone and terminate anyone else's, exactly like a flop Q.
    cutnets = {n for n in driver if CUT and CUT.search(n)}
    # ⛔ A --cut that matches NOTHING must not print the untreated numbers as
    # though they were treated. Added 8/7, after this exact blind spot occurred
    # inside the C3 probe: the RTL control arm has ZERO `carry` nets (synthesis
    # dissolved them), so `--cut 'carry\['` was a silent no-op and the run
    # printed the default census — numerically identical to an honest "cutting
    # here does not help", but a completely different fact.
    #
    # The importer got this guard last night; cones.py did not, and the docstring
    # above has warned since 16:2x that this instrument is treatment-INSENSITIVE
    # when the boundaries are absent. A warning in prose did not stop it being
    # relied on. Now it cannot be.
    if CUT and not cutnets:
        raise SystemExit(
            f"cones.py: --cut matched no DRIVEN net in {path}. The boundaries you asked "
            f"to certify at do not exist in this netlist — most likely the flow dissolved "
            f"them. Refusing to print the untreated census as a treated one.")
    for n in sorted(cutnets):
        roots.append((f"cut:{n}", n))

    def cone(net):
        """-> (gates, inputs) walking back to flops / primary inputs / consts /
        requested cut points"""
        seen, leaves, stack, gates = set(), set(), [net], 0
        while stack:
            x = stack.pop()
            if x in seen:
                continue
            seen.add(x)
            if (x != net and x in cutnets) or x in seq_out or x in minputs \
               or x.startswith("1'b") \
               or x.split("[")[0] in minputs or x not in driver:
                leaves.add(x)
                continue
            s, iname, conns = driver[x]
            gates += 1
            for p, nt in conns.items():
                if p in PG or p in OUTPINS:
                    continue
                stack.append(nt)
        return gates, len(leaves)

    sizes = []
    for label, net in roots:
        if net in driver or net in seq_out or net in minputs:
            g, inp = cone(net)
            if g > 0:
                sizes.append((g, inp, label))
    return logic, physical, len(insts), sizes


args = sys.argv[1:]
CUT = None
if args and args[0] == "--cut":
    CUT = re.compile(args[1])
    args = args[2:]

print(f"{'design':34s} {'logic':>6s} {'phys':>6s} {'cones':>6s} "
      f"{'in:med':>7s} {'in:max':>7s} {'<=24':>7s} {'gates:max':>9s}"
      + ("   [cut: " + CUT.pattern + "]" if CUT else ""))
print("-" * 92)
tot_ok = tot_all = 0
for path in args:
    try:
        logic, physical, allinst, sizes = analyse(path)
    except Exception as e:
        print(f"{path.split('/')[-1][:34]:34s}  ERROR {type(e).__name__}: {e}")
        continue
    if not sizes:
        print(f"{path.split('/')[-1][:34]:34s}  no cones found")
        continue
    ins = sorted(s[1] for s in sizes)
    gts = sorted(s[0] for s in sizes)
    med = ins[len(ins) // 2]
    ok = sum(1 for x in ins if x <= 24)
    tot_ok += ok
    tot_all += len(ins)
    print(f"{path.split('/')[-1][:34]:34s} {logic:6d} {physical:6d} {len(sizes):6d} "
          f"{med:7d} {ins[-1]:7d} {100.0*ok/len(ins):6.1f}% {gts[-1]:9d}")
print("-" * 92)
if tot_all:
    print(f"{'ALL':34s} {'':6s} {'':6s} {tot_all:6d} "
          f"{'':7s} {'':7s} {100.0*tot_ok/tot_all:6.1f}%")
