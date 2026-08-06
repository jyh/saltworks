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

Usage:  cones.py <netlist.v> [...]
"""
import sys, collections
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
                            if (i + 1 < n and toks[i + 1] == ("P", "[")
                                    and toks[i][0] == "ID"):
                                idx = nm(toks[i + 2])
                                base = f"{base}[{idx}]"
                                i += 3
                            net = base
                        elif toks[i][0] == "NUM":
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
                if p in ("D", "SCD", "SCE", "SET_B", "RESET_B") and p != "CLK":
                    roots.append((f"{iname}.{p}", nt))
    for o in moutputs:
        roots.append((f"out:{o}", o))
        # vector ports appear bit-wise in instances
    # also catch bit-selected output ports actually driven
    for nt in list(driver):
        if "[" in nt and nt.split("[")[0] in moutputs:
            roots.append((f"out:{nt}", nt))

    def cone(net):
        """-> (gates, inputs) walking back to flops / primary inputs / consts"""
        seen, leaves, stack, gates = set(), set(), [net], 0
        while stack:
            x = stack.pop()
            if x in seen:
                continue
            seen.add(x)
            if x in seq_out or x in minputs or x.startswith("1'b") \
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


print(f"{'design':34s} {'logic':>6s} {'phys':>6s} {'cones':>6s} "
      f"{'in:med':>7s} {'in:max':>7s} {'<=24':>7s} {'gates:max':>9s}")
print("-" * 92)
tot_ok = tot_all = 0
for path in sys.argv[1:]:
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
