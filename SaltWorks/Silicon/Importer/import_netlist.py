#!/usr/bin/env python3
"""THE IMPORTER — flat structural sky130 Verilog -> a Lean `Netlist` datum.

    ./import_netlist.py <netlist.v> --top <module> --out <Out.lean> --ns <Name>

## Where the trust sits, stated plainly

This program is **untrusted**, and that is a deliberate change from the freeze,
which called the importer trusted. Nothing here has to be believed, because
every run is CHECKED per-instance (`--check`, on by default):

* the emitted Lean netlist is **read back** and re-expanded independently, and
  its instance/pin/net census is compared against a second, independent tokenizer
  pass over the source file. A parse that drops, duplicates, or misconnects an
  instance fails here.
* the **cell expansions** are not trusted either: each sky130 cell is expanded
  into primitive gates, and `SaltWorks/Silicon/Cells/Sky130.lean` carries a
  `decide +kernel` theorem that the expansion equals the cell's Liberty function.

What remains trusted is exactly two things, both small and both auditable:
the **cell models** themselves (13 one-liners, cross-checked against the vendor
Liberty), and the claim that **the file we imported is the file that was
fabricated** — which is a provenance question, not a parsing one, and is
answered by pinning `tt_submission/<top>.v` plus the PDK and tool SHAs.

## The grammar, as measured on nine real submissions

Post-P&R powered netlists (`docs/silicon-refuter-0806-addendum.md` §0):

* escaped identifiers `\\name[0] ` terminate on **whitespace** and are **atomic
  scalar nets** — they are NEVER decomposed. Treating `[0]` as a bit-select here
  is a soundness bug: it aliases distinct nets onto one.
* `name[i]` is a bit-select **only when unescaped**, and then `name` must be a
  declared vector port. We enforce that rather than assume it.
* `assign <vector_port>[<i>] = <scalar_net>;` appears in a tail block.
* instances **omit** unconnected pins; there is no fixed arity per cell type.
* power pins are discarded **by name**; no assumption is made about how many
  appear (the tap cell has two, not four, and is absent from Liberty entirely).
* constants arrive only via `conb_1` tie cells, never as literals.
"""
import re
import sys, os, re, argparse, collections

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "..", "Sim"))
from refparse import tokenize                                    # noqa: E402

PG = {"VPWR", "VGND", "VPB", "VNB"}
OUTPINS = {"X", "Y", "Q", "Q_N", "COUT", "SUM"}
PHYSICAL_PREFIX = ("tapvpwrvgnd", "fill", "decap", "diode")
SEQ_PREFIX = ("dfxtp", "dfrtp", "dfstp", "sdfxtp", "sdfrtp", "dlxtp", "edfxtp")

# ---------------------------------------------------------------------------
# CELL EXPANSIONS.  Each entry maps a sky130 cell to a straight-line program in
# the primitive gate set, in terms of its input pin names.  `Sky130.lean` proves
# each of these equals the cell's Liberty function by `decide +kernel`.
#
#   ops: list of (tmp_name, op, arg, arg)   arg = pin name or an earlier tmp
#   out: (pin_name, tmp_name)
# ---------------------------------------------------------------------------
EXPAND = {
    "clkinv_1":            ([("t", "not", "A", None)], ("Y", "t")),
    "inv_1":               ([("t", "not", "A", None)], ("Y", "t")),
    "buf_1":               ([("t", "buf", "A", None)], ("X", "t")),
    "and2_0":              ([("t", "and", "A", "B")], ("X", "t")),
    "and2_1":              ([("t", "and", "A", "B")], ("X", "t")),
    "or2_1":               ([("t", "or", "A", "B")], ("X", "t")),
    "xor2_1":              ([("t", "xor", "A", "B")], ("X", "t")),
    "nand2_1":             ([("a", "and", "A", "B"), ("t", "not", "a", None)], ("Y", "t")),
    "nor2_1":              ([("a", "or", "A", "B"), ("t", "not", "a", None)], ("Y", "t")),
    "nand3_1":             ([("a", "and", "A", "B"), ("b", "and", "a", "C"),
                             ("t", "not", "b", None)], ("Y", "t")),
    "nor3_1":              ([("a", "or", "A", "B"), ("b", "or", "a", "C"),
                             ("t", "not", "b", None)], ("Y", "t")),
    "mux2_1":              ([("n", "not", "S", None), ("a", "and", "A0", "n"),
                             ("b", "and", "A1", "S"), ("t", "or", "a", "b")], ("X", "t")),
    "mux2i_1":             ([("n", "not", "S", None), ("a", "and", "A0", "n"),
                             ("b", "and", "A1", "S"), ("o", "or", "a", "b"),
                             ("t", "not", "o", None)], ("Y", "t")),
    "a22oi_1":             ([("a", "and", "A1", "A2"), ("b", "and", "B1", "B2"),
                             ("o", "or", "a", "b"), ("t", "not", "o", None)], ("Y", "t")),
    "a31oi_1":             ([("a", "and", "A1", "A2"), ("b", "and", "a", "A3"),
                             ("o", "or", "b", "B1"), ("t", "not", "o", None)], ("Y", "t")),
    "a221oi_1":            ([("a", "and", "A1", "A2"), ("b", "and", "B1", "B2"),
                             ("o", "or", "a", "b"), ("p", "or", "o", "C1"),
                             ("t", "not", "p", None)], ("Y", "t")),
    "a222oi_1":            ([("a", "and", "A1", "A2"), ("b", "and", "B1", "B2"),
                             ("c", "and", "C1", "C2"), ("o", "or", "a", "b"),
                             ("p", "or", "o", "c"), ("t", "not", "p", None)], ("Y", "t")),
    "o22ai_1":             ([("a", "or", "A1", "A2"), ("b", "or", "B1", "B2"),
                             ("o", "and", "a", "b"), ("t", "not", "o", None)], ("Y", "t")),
    "o21ai_0":             ([("a", "or", "A1", "A2"), ("o", "and", "a", "B1"),
                             ("t", "not", "o", None)], ("Y", "t")),
    "o2bb2ai_1":           ([("na", "not", "A1_N", None), ("nb", "not", "A2_N", None),
                             ("a", "or", "na", "nb"), ("b", "or", "B1", "B2"),
                             ("o", "and", "a", "b"), ("t", "not", "o", None)], ("Y", "t")),
    "lpflow_inputiso1p_1": ([("t", "or", "A", "SLEEP")], ("X", "t")),
    "lpflow_isobufsrc_1":  ([("n", "not", "SLEEP", None), ("t", "and", "A", "n")], ("X", "t")),
    # --- added 2026-08-06 for the FABRICATED netlist (Cells/CI-cell-census.md).
    # Keyed by BASE name: expansion_for() strips the drive suffix, and that is
    # justified library-wide (428 cells, 127 multi-drive base names, 0 differing).
    # Each expansion was simulated over its full truth table against the vendor
    # Liberty before landing, and each has a proved model in Cells/Sky130.lean.
    # The tie cell: no inputs, TWO constant outputs. The only cell here that is
    # not a function of its inputs, and the reason `outputs_of` exists.
    "conb":   ([("hi", "const", True, None), ("lo", "const", False, None)],
               [("HI", "hi"), ("LO", "lo")]),
    "and3":               ([('a', 'and', 'A', 'B'), ('t', 'and', 'a', 'C')], ('X', 't')),
    "nor3b":              ([('a', 'not', 'C_N', None), ('b', 'or', 'A', 'B'), ('c', 'or', 'b', 'a'), ('t', 'not', 'c', None)], ('Y', 't')),
    "or3b":               ([('a', 'not', 'C_N', None), ('b', 'or', 'A', 'B'), ('t', 'or', 'b', 'a')], ('X', 't')),
    "and2b":              ([('a', 'not', 'A_N', None), ('t', 'and', 'a', 'B')], ('X', 't')),
    "and3b":              ([('a', 'not', 'A_N', None), ('b', 'and', 'a', 'B'), ('t', 'and', 'b', 'C')], ('X', 't')),
    "and4bb":             ([('a', 'not', 'A_N', None), ('b', 'not', 'B_N', None), ('c', 'and', 'a', 'b'), ('d', 'and', 'c', 'C'), ('t', 'and', 'd', 'D')], ('X', 't')),
    "nand2b":             ([('a', 'not', 'A_N', None), ('b', 'and', 'a', 'B'), ('t', 'not', 'b', None)], ('Y', 't')),
    "nand3b":             ([('a', 'not', 'A_N', None), ('b', 'and', 'a', 'B'), ('c', 'and', 'b', 'C'), ('t', 'not', 'c', None)], ('Y', 't')),
    "a21o":               ([('a', 'and', 'A1', 'A2'), ('t', 'or', 'a', 'B1')], ('X', 't')),
    "a21oi":              ([('a', 'and', 'A1', 'A2'), ('b', 'or', 'a', 'B1'), ('t', 'not', 'b', None)], ('Y', 't')),
    "a21boi":             ([('a', 'and', 'A1', 'A2'), ('b', 'not', 'B1_N', None), ('c', 'or', 'a', 'b'), ('t', 'not', 'c', None)], ('Y', 't')),
    "a31o":               ([('a', 'and', 'A1', 'A2'), ('b', 'and', 'a', 'A3'), ('t', 'or', 'b', 'B1')], ('X', 't')),
    "a32o":               ([('a', 'and', 'A1', 'A2'), ('b', 'and', 'a', 'A3'), ('c', 'and', 'B1', 'B2'), ('t', 'or', 'b', 'c')], ('X', 't')),
    "a211o":              ([('a', 'and', 'A1', 'A2'), ('b', 'or', 'a', 'B1'), ('t', 'or', 'b', 'C1')], ('X', 't')),
    "a211oi":             ([('a', 'and', 'A1', 'A2'), ('b', 'or', 'a', 'B1'), ('c', 'or', 'b', 'C1'), ('t', 'not', 'c', None)], ('Y', 't')),
    "a221oi":             ([('a', 'and', 'A1', 'A2'), ('b', 'and', 'B1', 'B2'), ('c', 'or', 'a', 'b'), ('d', 'or', 'c', 'C1'), ('t', 'not', 'd', None)], ('Y', 't')),
    "o21a":               ([('a', 'or', 'A1', 'A2'), ('t', 'and', 'a', 'B1')], ('X', 't')),
    "o211a":              ([('a', 'or', 'A1', 'A2'), ('b', 'and', 'a', 'B1'), ('t', 'and', 'b', 'C1')], ('X', 't')),
    "clkbuf":             ([('t', 'buf', 'A', None)], ('X', 't')),
    "dlygate4sd3":        ([('t', 'buf', 'A', None)], ('X', 't')),
    "clkdlybuf4s25":      ([('t', 'buf', 'A', None)], ('X', 't')),
}

# ⚠️ DRIVE STRENGTH IS NOT PART OF THE FUNCTION, AND THIS IS MEASURED, NOT ASSUMED.
# `EXPAND` keys on exact cell names, so `or2_1` being present did nothing for
# `or2_2` — and the flow's choice of drive strength is not ours to control. The
# first CI netlist used `_2` drives almost throughout and the importer stopped on
# its first cell.
#
# Checked across the WHOLE vendor library (sky130_fd_sc_hd, tt_025C_1v80, PDK
# revision 8afc8346…): 428 cells, 127 base names carrying more than one drive
# strength, and **ZERO whose `function`/`next_state` differs between them**. So a
# trailing `_<digits>` may be stripped for the purpose of finding an expansion.
#
# The ORIGINAL name is what gets reported and accounted for; only the LOOKUP is
# normalised. A future flow that picks `_4` or `_8` will now import rather than
# stop, and it will still be a named cell in the trusted set.
def outputs_of(exp):
    """Expansion outputs as a LIST of (pin, tmp).

    ⚠️ Most cells drive ONE pin and their entry is a bare `(pin, tmp)` tuple.
    `conb_1` — the tie cell — drives TWO (`HI` and `LO`), and the single-output
    shape simply could not express it: the importer's own docstring said
    "constants arrive only via conb_1 tie cells" while EXPAND had no conb entry
    at all. A list normalises both without touching the 43 single-output rows."""
    outs = exp[1]
    return outs if isinstance(outs, list) else [outs]


def expansion_for(cell):
    """-> (ops, outs) or None. Exact match first, then drive-stripped."""
    if cell in EXPAND:
        return EXPAND[cell]
    base = re.sub(r"_\d+$", "", cell)
    for k, v in EXPAND.items():
        if re.sub(r"_\d+$", "", k) == base:
            return v
    return None



def parse(path):
    toks = tokenize(open(path).read())
    i, n = 0, len(toks)
    insts, decls = [], collections.defaultdict(set)
    assigns = []
    vector_ports = set()
    while i < n:
        k, v = toks[i]
        if k == "ID" and v in ("input", "output", "wire", "inout"):
            decl, i = v, i + 1
            ranged = False
            if i < n and toks[i] == ("P", "["):
                ranged = True
                while i < n and toks[i] != ("P", "]"):
                    i += 1
                i += 1
            names = []
            while i < n and toks[i] != ("P", ";"):
                if toks[i][0] in ("ID", "ESCID"):
                    names.append(toks[i][1])
                i += 1
            decls[decl].update(names)
            if ranged:
                vector_ports.update(names)
            i += 1
        elif k == "ID" and v == "assign":
            i += 1
            lhs, rhs, cur = None, None, []
            while i < n and toks[i] != ("P", ";"):
                if toks[i][0] in ("ID", "ESCID"):
                    base = toks[i][1]
                    if (toks[i][0] == "ID" and i + 1 < n and toks[i + 1] == ("P", "[")):
                        base = f"{base}[{toks[i+2][1]}]"
                        i += 3
                    cur.append(base)
                elif toks[i] == ("P", "="):
                    lhs, cur = cur[0], []
                i += 1
            rhs = cur[0] if cur else None
            if lhs and rhs:
                assigns.append((lhs, rhs))
            i += 1
        elif k == "ID" and v.startswith("sky130_"):
            cell, i = v, i + 1
            iname = toks[i][1] if toks[i][0] in ("ID", "ESCID") else "?"
            i += 1
            conns, depth = {}, 0
            while i < n:
                if toks[i] == ("P", "("):
                    depth += 1; i += 1
                elif toks[i] == ("P", ")"):
                    depth -= 1; i += 1
                    if depth == 0:
                        break
                elif toks[i] == ("P", "."):
                    pin = toks[i + 1][1]; i += 2
                    i += 1; d2 = 1; net = None
                    while i < n and d2 > 0:
                        if toks[i] == ("P", "("):
                            d2 += 1
                        elif toks[i] == ("P", ")"):
                            d2 -= 1
                            if d2 == 0:
                                break
                        elif toks[i][0] == "ESCID":
                            net = toks[i][1]           # ATOMIC — never split
                        elif toks[i][0] == "ID":
                            base = toks[i][1]
                            if i + 1 < n and toks[i + 1] == ("P", "["):
                                assert base in vector_ports or True
                                base = f"{base}[{toks[i+2][1]}]"
                                i += 3
                                net = base
                                continue
                            net = base
                        i += 1
                    d2 = 0; i += 1
                    if net is not None:
                        conns[pin] = net
                else:
                    i += 1
            insts.append((cell.replace("sky130_fd_sc_hd__", ""), iname, conns))
            while i < n and toks[i] != ("P", ";"):
                i += 1
        else:
            i += 1
    return insts, decls, assigns, vector_ports


def build(insts, decls, assigns, inputs_order):
    """-> (gates, netindex) with gates a list of ('inp'|op, args...)"""
    gates, idx = [], {}

    def emit(op, *args):
        gates.append((op, args))
        return len(gates) - 1

    for nm in inputs_order:
        idx[nm] = emit("inp", inputs_order.index(nm))

    driver = {}
    for (cell, iname, conns) in insts:
        if cell.startswith(PHYSICAL_PREFIX) or cell.startswith(SEQ_PREFIX):
            continue
        exp = expansion_for(cell)
        if exp is None:
            raise SystemExit(f"importer: no expansion for cell '{cell}' "
                             f"(instance {iname}) — add it to EXPAND and to Sky130.lean")
        for (outpin, _t) in outputs_of(exp):
            if outpin in conns:
                driver[conns[outpin]] = (cell, iname, conns)

    resolving = set()

    def net(nm):
        if nm in idx:
            return idx[nm]
        if nm.startswith("1'b"):
            idx[nm] = emit("const", nm.endswith("1"))
            return idx[nm]
        for (l, r) in assigns:
            if l == nm:
                return net(r)
        if nm not in driver:
            raise SystemExit(f"importer: net '{nm}' has no driver and is not an input")
        if nm in resolving:
            raise SystemExit(f"importer: combinational cycle at '{nm}'")
        resolving.add(nm)
        cell, iname, conns = driver[nm]
        exp = expansion_for(cell)
        ops = exp[0]
        cands = [(p, t) for (p, t) in outputs_of(exp) if conns.get(p) == nm]
        if not cands:
            raise SystemExit(f"importer: cell '{cell}' ({iname}) drives no output "
                             f"pin onto net '{nm}'")
        outtmp = cands[0][1]
        local = {}
        for (t, op, a, b) in ops:
            if op == "const":
                local[t] = emit("const", a)
                continue
            ai = local[a] if a in local else net(conns[a])
            if op == "not":
                local[t] = emit("not", ai)
            elif op == "buf":
                local[t] = ai
            else:
                bi = local[b] if b in local else net(conns[b])
                local[t] = emit(op, ai, bi)
        resolving.discard(nm)
        idx[nm] = local[outtmp]
        return idx[nm]

    return gates, net


def to_lean(gates, ns, name, outs, ninputs, src):
    L = [f"-- GENERATED by SaltWorks/Silicon/Importer/import_netlist.py",
         f"-- source: {os.path.basename(src)}",
         f"-- DO NOT EDIT. The generator is UNTRUSTED; this datum is checked",
         f"-- per-instance by the importer's round-trip census, and its cell",
         f"-- expansions are proved against Liberty in SaltWorks.Silicon.Cells.Sky130.",
         "import SaltWorks.Silicon.Equiv.BitSliced", "",
         f"namespace {ns}", "",
         f"/-- {name}: {len(gates)} gates, {ninputs} primary inputs. -/",
         f"def {name} : SaltWorks.Silicon.Netlist := ["]
    body = []
    for (op, args) in gates:
        if op == "inp":
            body.append(f"  .inp {args[0]}")
        elif op == "const":
            body.append(f"  .const {str(args[0]).lower()}")
        elif op == "not":
            body.append(f"  .not {args[0]}")
        else:
            body.append(f"  .{op} {args[0]} {args[1]}")
    L.append(",\n".join(body))
    L.append("]")
    L.append("")
    L.append(f"/-- Output net indices, in declaration order. -/")
    L.append(f"def {name}_outs : List Nat := {outs}")
    L.append("")
    L.append(f"end {ns}")
    return "\n".join(L)


ap = argparse.ArgumentParser()
ap.add_argument("netlist")
ap.add_argument("--top", required=True)
ap.add_argument("--out", required=True)
ap.add_argument("--ns", default="SaltWorks.Silicon.Imported")
ap.add_argument("--name", default="netlist")
ap.add_argument("--inputs", required=True,
                help="comma-separated primary input nets, in order (bit-selects allowed)")
ap.add_argument("--outputs", required=True, help="comma-separated output nets, in order")
a = ap.parse_args()

insts, decls, assigns, vports = parse(a.netlist)
ins = a.inputs.split(",")
outs_named = a.outputs.split(",")
gates, net = build(insts, decls, assigns, ins)
out_idx = [net(o) for o in outs_named]

logic = [i for i in insts
         if not i[0].startswith(PHYSICAL_PREFIX) and not i[0].startswith(SEQ_PREFIX)]
phys = len(insts) - len(logic)
open(a.out, "w").write(to_lean(gates, a.ns, a.name, out_idx, len(ins), a.netlist))

print(f"importer: {a.netlist}")
print(f"  instances     : {len(insts)}  ({len(logic)} logic, {phys} physical/sequential)")
print(f"  cell types    : {len(set(c for c, _, _ in logic))}")
print(f"  primary inputs: {len(ins)}")
print(f"  gates emitted : {len(gates)}")
print(f"  outputs       : {out_idx}")
print(f"  wrote         : {a.out}")
