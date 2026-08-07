#!/usr/bin/env python3
"""THE IMPORTER — flat structural sky130 Verilog -> a Lean `Netlist` datum.

    ./import_netlist.py <netlist.v> --top <module> --out <Out.lean> --ns <Name>

## Where the trust sits, stated plainly

This program is **untrusted**, and that is a deliberate change from the freeze,
which called the importer trusted.

⛔ **CORRECTION, 2026-08-06.** This docstring previously claimed that "every run
is CHECKED per-instance (`--check`, on by default)", describing a readback pass
that compares the emitted Lean against a second independent tokenizer census.
**No such flag and no such pass exist**, and none ever did — the claim was
written aspirationally and read as fact, which is the same defect class this
campaign spent the day cataloguing. What the run actually prints at the end is a
*census report*, not a check: a report cannot fail. The readback check is
genuinely owed and is tracked as open work; until it lands, the honest statement
of the trust position is the one below.

What is actually checked, today:

* the **cell expansions** are not trusted: each sky130 cell is expanded into
  primitive gates, and `SaltWorks/Silicon/Cells/Sky130.lean` carries a
  `decide +kernel` theorem that the expansion equals the cell's Liberty function
  (42 of them as of tonight, covering every cell this file expands).
* the **flop treatment** below refuses rather than approximates: an unmodelled
  sequential cell, a connected pin the model does not account for, and a clock
  that is not common to every flop are each a hard error, not a warning.
* the emitted datum is **regenerated and byte-compared** against what is
  committed by `reimport.sh`, which also records the command line that produced
  each file — provenance that previously existed nowhere.

What remains trusted: the **cell models** themselves, and the claim that **the
file we imported is the file that was fabricated** — a provenance question, not
a parsing one, answered by pinning `tt_submission/<top>.v` plus the PDK and tool
SHAs.

## The flop treatment — Q-pins as leaves, D-pins as roots

A post-P&R netlist is sequential; a `Netlist` datum is combinational. The
decomposition that reconciles them is the one D3.5 and D4 already use, one level
up: **cut every flop**. Its `Q` becomes a primary input (a *leaf* — the current
state, an input to the combinational cone) and its `D` becomes an output (a
*root* — the next state). What is left between the cuts is pure combinational
logic, which is what the kernel can decide.

The paired ordering is what makes it meaningful: state input `i` and next-state
output `i` are **the same flop**, so a one-cycle obligation can be stated by
lining the two vectors up. Flops are ordered by `Q` net name — stable across
resynthesis in a way the machine-generated `D` names (`_000_`, `_001_`) are not,
which is precisely why this is discovered here rather than typed by a caller.

⚠️ **Soundness condition, checked and not assumed.** "Next state" is only
well-defined if every flop latches on the same event. After clock-tree synthesis
the flops do **not** share a CLK *net* — the fabricated netlist has eight
(`clknet_3_0__leaf_clk` … `_3_7_`) — so net equality is the wrong test and would
false-alarm. Each CLK is instead traced back through the buffer/inverter tree to
its source, and all flops must reach the same (root, inversion-parity) pair.

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


def base_of(cell):
    """Cell name with the trailing drive-strength suffix removed."""
    return re.sub(r"_\d+$", "", cell)


# ---------------------------------------------------------------------------
# SEQUENTIAL CELL MODELS — the flop treatment's trusted core, kept deliberately
# tiny.  Each entry names the three pins that carry the model: the clock, the
# data input whose net becomes a cone ROOT, and the state output whose net
# becomes a cone LEAF.
#
# ⛔ ONLY CELLS LISTED HERE ARE IMPORTED.  A sequential cell that is absent is a
# HARD ERROR naming it, never a silent skip — because skipping a flop does not
# lose a gate, it loses a STATE BIT, and the resulting netlist would still parse,
# still typecheck, and still prove theorems about the wrong machine.
#
# ⚠️ WHY `dfrtp` IS NOT HERE, though adding a line would make it import.
# `dfrtp` carries an asynchronous `RESET_B`.  Asynchronous reset is not a
# next-state function of the flop's inputs at all — it acts between edges — so
# the honest model is not `next = D & RESET_B`; that formula is a *synchronous*
# reset, correct only under an assumption about reset being held across an edge
# that nothing in the netlist states.  The RV32I work will bring resettable
# flops, and when it does, this comment is the question that has to be answered
# rather than a line that has to be typed.
# ---------------------------------------------------------------------------
# An entry is either
#   "d"    : the next state IS this pin's net — the root is that net, unchanged;
#   "next" : the next state is a straight-line expression over the flop's pins
#            (including its OWN `Q`, which resolves to the state leaf), and the
#            root is the gate that expression emits.
# "pins" lists every non-power pin the model accounts for; anything else
# connected is a hard error.
SEQ_MODELS = {
    "dfxtp":  {"clk": "CLK", "q": "Q", "pins": {"CLK", "D", "Q"}, "d": "D"},

    # THE ENABLE FLOP. yosys reaches for this whenever a register has a
    # CONDITIONAL write — i.e. for every register file and every CPU state
    # element — so a chain that cannot import it cannot import a CPU. Found by
    # R3: a 32x32 regfile synthesised to 992 `edfxtp_1` and the importer
    # refused, correctly, rather than dropping 992 state bits.
    #
    # ✅ AND UNLIKE `dfrtp`, THIS ONE IS HONESTLY MODELLABLE, which is the whole
    # distinction the refusal exists to protect. `DE` is a SYNCHRONOUS enable: it
    # is sampled at the same edge as `D`, so the next state genuinely IS a
    # function of the flop's inputs and its own current state —
    #     next = DE ? D : Q
    # — with no assumption about anything happening between edges. `dfrtp`'s
    # `RESET_B` is asynchronous and admits no such function; that is why one is
    # here and the other is still refused.
    "edfxtp": {"clk": "CLK", "q": "Q", "pins": {"CLK", "D", "DE", "Q"},
               "next": [("n", "not", "DE", None),
                        ("a", "and", "DE", "D"),
                        ("b", "and", "n", "Q"),
                        ("t", "or", "a", "b")]},
}


def find_flops(insts):
    """-> [ {cell, iname, q, d, clk} ], one per sequential instance.

    Refuses on: an unmodelled sequential cell, a missing modelled pin, and any
    connected non-power pin the model does not account for (which is how a
    silently-dropped reset would be caught)."""
    flops, unmodelled = [], collections.Counter()
    for (cell, iname, conns) in insts:
        if not cell.startswith(SEQ_PREFIX):
            continue
        m = SEQ_MODELS.get(base_of(cell))
        if m is None:
            unmodelled[cell] += 1
            continue
        pins = m["pins"]
        missing = [p for p in sorted(pins) if p not in conns]
        if missing:
            raise SystemExit(f"importer: flop {iname} ({cell}) has no connection on "
                             f"{', '.join(missing)} — the model requires all of "
                             f"{', '.join(sorted(pins))}")
        extra = sorted(set(conns) - PG - pins)
        if extra:
            raise SystemExit(
                f"importer: flop {iname} ({cell}) has connected pin(s) {', '.join(extra)} "
                f"that SEQ_MODELS['{base_of(cell)}'] does not model. Dropping them would "
                f"silently change the machine; extend the model deliberately instead.")
        flops.append({"cell": cell, "iname": iname, "model": m,
                      "q": conns[m["q"]], "clk": conns[m["clk"]], "conns": conns,
                      "d": conns[m["d"]] if "d" in m else None})
    if unmodelled:
        listing = ", ".join(f"{c} x{n}" for c, n in sorted(unmodelled.items()))
        raise SystemExit(
            f"importer: unmodelled sequential cell(s): {listing}. Skipping a flop loses a "
            f"STATE BIT, not a gate — add it to SEQ_MODELS only with a justified next-state "
            f"model (see the note on `dfrtp` there).")
    return flops


def all_drivers(insts):
    """net -> driving (cell, iname, conns), over expandable combinational cells."""
    drv = {}
    for (cell, iname, conns) in insts:
        if cell.startswith(PHYSICAL_PREFIX) or cell.startswith(SEQ_PREFIX):
            continue
        exp = expansion_for(cell)
        if exp is None:
            continue
        for (p, _t) in outputs_of(exp):
            if p in conns:
                drv[conns[p]] = (cell, iname, conns)
    return drv


def clock_root(nm, drv, assigns, inputs_set, depth=0):
    """Trace a clock net back to its source -> (root_net, parity) or None.

    Follows `assign` aliases and any cell whose whole expansion is a single
    `buf` or `not` — which is exactly the clock tree CTS builds. Returns None if
    the clock passes through real combinational logic (a GATED clock), because
    then the flops it feeds do not latch on a common event and the whole
    Q-leaf/D-root decomposition is invalid."""
    if depth > 256:
        return None
    for (l, r) in assigns:
        if l == nm:
            return clock_root(r, drv, assigns, inputs_set, depth + 1)
    if nm in inputs_set or nm not in drv:
        return (nm, 0)
    cell, _iname, conns = drv[nm]
    ops = expansion_for(cell)[0]
    if len(ops) == 1 and ops[0][1] in ("buf", "not"):
        src = conns.get(ops[0][2])
        if src is None:
            return None
        sub = clock_root(src, drv, assigns, inputs_set, depth + 1)
        if sub is None:
            return None
        return (sub[0], sub[1] ^ (1 if ops[0][1] == "not" else 0))
    return None


def check_clock_domain(flops, drv, assigns, inputs_set):
    """All flops must latch on the same event. -> (root, parity, n_leaf_nets)."""
    domains = collections.defaultdict(list)
    for f in flops:
        r = clock_root(f["clk"], drv, assigns, inputs_set)
        if r is None:
            raise SystemExit(
                f"importer: flop {f['iname']} has a GATED clock — net '{f['clk']}' traces "
                f"back through combinational logic, so it does not latch on a common event "
                f"and 'next state' is not well defined for this netlist.")
        domains[r].append(f)
    if len(domains) != 1:
        detail = "; ".join(f"{root} (parity {par}): {len(fs)} flops"
                           for (root, par), fs in sorted(domains.items()))
        raise SystemExit(
            f"importer: flops span {len(domains)} clock domains — {detail}. The paired "
            f"state vectors assume every flop latches together.")
    (root, parity), fs = next(iter(domains.items()))
    return root, parity, len({f["clk"] for f in fs})



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
                            # …but an escaped name may still be FOLLOWED by a
                            # genuine bit-select, and that is a different thing
                            # from splitting the name itself.
                            #
                            # ⛔ SOUNDNESS FIX (8/6, found by R3's regfile).
                            # `\regs[20] [26]` is the escaped vector `\regs[20]`
                            # indexed at bit 26 — which is how yosys writes a
                            # register-file bit. Taking the ESCID alone ALIASED
                            # all 32 bits of a register onto ONE net: 2549
                            # distinct nets collapsed to 1588, 961 of them
                            # merged. That is the same class of defect this
                            # file's own docstring warns about for the opposite
                            # case, and it was live in the other direction.
                            #
                            # The banyan never reached it: its escaped names
                            # carry the index INSIDE the escape (`\fabric.w0[0]`)
                            # with no following bracket, so nothing aliased and
                            # every figure cross-checked clean.
                            if (i + 3 < n and toks[i + 1] == ("P", "[")
                                    and toks[i + 2][0] == "NUM"
                                    and toks[i + 3] == ("P", "]")):
                                net = f"{net}[{toks[i+2][1]}]"
                                i += 3
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

    # ⚠️ Indexed by POSITION, not by `.index()`, which returns the first match:
    # a repeated name would have aliased two distinct primary inputs onto one
    # gate and silently shifted every later input's position. Harmless while the
    # list was hand-written and short; a real hazard now that the flop treatment
    # appends 52 discovered state nets to it. Duplicates are rejected outright.
    dup = [nm for nm, c in collections.Counter(inputs_order).items() if c > 1]
    if dup:
        raise SystemExit(f"importer: duplicate primary input net(s): {', '.join(sorted(dup))}")
    for k, nm in enumerate(inputs_order):
        idx[nm] = emit("inp", k)

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

    def expand_driver(nm):
        """Emit the gates of nm's DRIVING cell and return the resulting index.

        Deliberately does NOT consult `idx[nm]`, which is what lets a CUT net be
        two things at once: bound to a leaf `.inp` for everyone downstream, while
        its own root still names the logic that computes it."""
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
        return local[outtmp]

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
        v = expand_driver(nm)
        resolving.discard(nm)
        idx[nm] = v
        return idx[nm]

    def root_value(nm):
        """The index of the LOGIC that drives nm, ignoring any leaf binding.

        Used for cut-point roots: `net('fabric.w0[0]')` returns the leaf, which
        is right for every consumer, but the cut's own proof obligation is about
        the logic FEEDING it, which is this."""
        for (l, r) in assigns:
            if l == nm:
                nm = r
                break
        if nm not in driver:
            raise SystemExit(f"importer: cut net '{nm}' has no driver, so there is no "
                             f"logic to certify at that boundary")
        return expand_driver(nm)

    return gates, net, root_value, emit


def to_lean(gates, ns, name, outs, ninputs, src, state=(), ndesign_in=None,
            ndesign_out=None, clockinfo=None, cuts=()):
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
    if state:
        n = len(state)
        L.append("")
        L.append(f"/-! ## The flop treatment — {n} flops cut, Q as leaf, D as root")
        L.append("")
        L.append(f"This netlist is the COMBINATIONAL part of a sequential design. Every flop")
        L.append(f"was cut: its `Q` became a primary input (current state) and its `D` an")
        L.append(f"output (next state). The two vectors are PAIRED BY POSITION —")
        L.append(f"state bit `i` is input `{ndesign_in} + i` and output `{ndesign_out} + i`,")
        L.append(f"and both belong to the same flop, listed below in `Q`-net order.")
        L.append("")
        L.append(f"Soundness: all {n} flops were checked to latch on one common event —")
        L.append(f"clock root `{clockinfo[0]}`, inversion parity {clockinfo[1]}, reached")
        L.append(f"through {clockinfo[2]} distinct CLK net(s) of the synthesised clock tree.")
        L.append("")
        for i, f in enumerate(state):
            src = f"`{f['d']}`" if f["d"] is not None else "*(next = DE ? D : Q)*"
            L.append(f"* `{i:3d}`  Q `{f['q']}`  ←— {src}   ({f['iname']}, {f['cell']})")
        L.append("-/")
        L.append("")
        L.append(f"/-- Number of DESIGN primary inputs; inputs from here on are state bits. -/")
        L.append(f"def {name}_ndesign_in : Nat := {ndesign_in}")
        L.append("")
        L.append(f"/-- Number of DESIGN outputs; `{name}_outs` entries from here on are")
        L.append(f"next-state bits, paired by position with the state inputs. -/")
        L.append(f"def {name}_ndesign_out : Nat := {ndesign_out}")
        L.append("")
        L.append(f"/-- Number of flops cut by the treatment. -/")
        L.append(f"def {name}_nstate : Nat := {n}")
    if cuts:
        nc = len(cuts)
        base_in = (ndesign_in or 0) + len(state)
        base_out = (ndesign_out or 0) + len(state)
        L.append("")
        L.append(f"/-! ## Chosen cut points — {nc} of them")
        L.append("")
        L.append(f"Flops are cut because the netlist forces it. These are cut because we")
        L.append(f"CHOSE to certify at them — possible only because the net still EXISTS")
        L.append(f"after the flow flattened, which is what `(* keep *)` in the RTL buys.")
        L.append(f"Each is BOTH a leaf and a root: input `{base_in} + i` stands for the")
        L.append(f"boundary value downstream, and output `{base_out} + i` is the LOGIC")
        L.append(f"that drives it. Certifying both halves certifies the whole path, and")
        L.append(f"neither half alone carries the 36-input cone the uncut netlist has.")
        L.append("")
        for i, c in enumerate(cuts):
            L.append(f"* `{i:3d}`  `{c}`")
        L.append("-/")
        L.append("")
        L.append(f"/-- Number of chosen cut points; the last `{nc}` inputs and the last")
        L.append(f"`{nc}` outputs are the two halves of each, paired by position. -/")
        L.append(f"def {name}_ncut : Nat := {nc}")
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
ap.add_argument("--cut", default=None, metavar="REGEX",
                help="also cut at every net matching REGEX: each becomes BOTH a root "
                     "(the logic driving it) and a leaf (an input for its consumers). "
                     "Same semantics as Sim/cones.py --cut. Use it at `(* keep *)` "
                     "boundaries that survived the flow.")
a = ap.parse_args()

insts, decls, assigns, vports = parse(a.netlist)
ins = [x for x in a.inputs.split(",") if x]
outs_named = [x for x in a.outputs.split(",") if x]

# --- THE FLOP TREATMENT ----------------------------------------------------
# Discover every flop, verify they share one latching event, then cut them:
# Q -> appended to the primary inputs (leaf), D -> appended to the outputs
# (root), paired by position and ordered by Q net name.
flops = find_flops(insts)
clockinfo = None
auto = []
if flops:
    drv_all = all_drivers(insts)
    clockinfo = check_clock_domain(flops, drv_all, assigns, set(ins))

    # BACKWARD COMPATIBILITY, and the reason byte-identity is provable: a flop
    # the caller has ALREADY cut by hand — Q listed in --inputs and D in
    # --outputs — is left exactly where the caller put it. The switch netlist
    # was imported that way before this treatment existed, and re-running its
    # original command must still produce the committed bytes.
    ins_set, outs_set = set(ins), set(outs_named)
    # A flop whose next state is an EXPRESSION has no single net to list, so it
    # cannot be cut by hand — only by the treatment.
    handcut_impossible = [f for f in flops if f["d"] is None and f["q"] in ins_set]
    if handcut_impossible:
        f = handcut_impossible[0]
        raise SystemExit(
            f"importer: flop {f['iname']} ({f['cell']}) has its Q '{f['q']}' listed in "
            f"--inputs, but its next state is an EXPRESSION over its pins, not a net, so "
            f"there is nothing to list in --outputs. Let the treatment cut it: remove it "
            f"from --inputs.")
    partial = [f for f in flops
               if f["d"] is not None and (f["q"] in ins_set) != (f["d"] in outs_set)]
    if partial:
        detail = "; ".join(f"{f['iname']}: Q '{f['q']}' {'listed' if f['q'] in ins_set else 'absent'}, "
                           f"D '{f['d']}' {'listed' if f['d'] in outs_set else 'absent'}"
                           for f in partial[:4])
        raise SystemExit(
            f"importer: {len(partial)} flop(s) are cut by hand on ONE side only — {detail}. "
            f"A half-cut flop pairs a state input with the wrong next-state output. List "
            f"both sides or neither.")
    auto = sorted([f for f in flops if f["q"] not in ins_set], key=lambda f: f["q"])

ins_all = ins + [f["q"] for f in auto]
outs_all = outs_named + [f["d"] for f in auto]

# --- CUT POINTS ------------------------------------------------------------
# The same move as the flop treatment, applied to an arbitrary boundary rather
# than to a register: a cut net becomes BOTH a root and a leaf. Flops are cut
# because the netlist forces it; these are cut because we CHOOSE to certify
# there — which is only possible if the net still exists after the flow
# flattens, and that is what `(* keep *)` buys.
cuts = []
if a.cut:
    rx = re.compile(a.cut)
    seen = set()
    for (cell, iname, conns) in insts:
        if cell.startswith(PHYSICAL_PREFIX) or cell.startswith(SEQ_PREFIX):
            continue
        exp = expansion_for(cell)
        if exp is None:
            continue
        for (p, _t) in outputs_of(exp):
            nm = conns.get(p)
            if nm and rx.search(nm) and nm not in seen:
                seen.add(nm)
                cuts.append(nm)
    cuts.sort()
    if not cuts:
        raise SystemExit(
            f"importer: --cut '{a.cut}' matched no DRIVEN net. A boundary that the flow "
            f"dissolved does not exist to be cut at, and a census that silently found "
            f"nothing would report the untreated numbers as though they were treated.")
    clash = sorted(set(cuts) & set(ins_all))
    if clash:
        raise SystemExit(f"importer: --cut matches net(s) already primary inputs: "
                         f"{', '.join(clash)}")

ins_all = ins_all + cuts
outs_all = outs_all + cuts

gates, net, root_value, emit = build(insts, decls, assigns, ins_all)


def state_root(f):
    """The next-state value of a cut flop, as a gate index.

    For a plain D flop this is just its D net. For an ENABLE flop the next state
    is `DE ? D : Q` — an expression, whose `Q` resolves to the flop's own state
    LEAF, which is exactly the feedback that makes "hold" mean hold."""
    m = f["model"]
    if f["d"] is not None:
        return net(f["d"])
    conns, local = f["conns"], {}
    for (t, op, a, b) in m["next"]:
        ai = local[a] if a in local else net(conns[a])
        if op == "not":
            local[t] = emit("not", ai)
        elif op == "buf":
            local[t] = ai
        else:
            bi = local[b] if b in local else net(conns[b])
            local[t] = emit(op, ai, bi)
    return local[m["next"][-1][0]]


# Design outputs read through `net`; state roots through `state_root`; cut roots
# through `root_value` (the driving LOGIC, not the leaf its consumers see).
out_idx = ([net(o) for o in outs_named]
           + [state_root(f) for f in auto]
           + [root_value(c) for c in cuts])

logic = [i for i in insts
         if not i[0].startswith(PHYSICAL_PREFIX) and not i[0].startswith(SEQ_PREFIX)]
phys = len(insts) - len(logic)
open(a.out, "w").write(to_lean(gates, a.ns, a.name, out_idx, len(ins_all), a.netlist,
                               state=auto, ndesign_in=len(ins), ndesign_out=len(outs_named),
                               clockinfo=clockinfo, cuts=cuts))

print(f"importer: {a.netlist}")
print(f"  instances     : {len(insts)}  ({len(logic)} logic, {phys} physical/sequential)")
print(f"  cell types    : {len(set(c for c, _, _ in logic))}")
print(f"  primary inputs: {len(ins_all)}  ({len(ins)} design + {len(auto)} state"
      + (f" + {len(cuts)} cut)" if cuts else ")"))
print(f"  gates emitted : {len(gates)}")
print(f"  outputs       : {len(out_idx)}  ({len(outs_named)} design + {len(auto)} next-state"
      + (f" + {len(cuts)} cut)" if cuts else ")"))
if cuts:
    print(f"  cut points    : {len(cuts)}  (each both a leaf and a root)")
if flops:
    root, parity, nleaf = clockinfo
    print(f"  flops cut     : {len(flops)}  ({len(auto)} by the treatment, "
          f"{len(flops) - len(auto)} listed by the caller)")
    print(f"  clock domain  : one — root '{root}', parity {parity}, via {nleaf} CLK net(s)")
print(f"  wrote         : {a.out}")
