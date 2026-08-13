#!/usr/bin/env python3
"""THE IMPORTER — flat structural sky130 Verilog -> a Lean `Netlist` datum.

    ./import_netlist.py <netlist.v> --top <module> --out <Out.lean> --ns <Name>

## Where the trust sits, stated plainly

This program is **untrusted**, and that is a deliberate change from the freeze,
which called the importer trusted.

⛔ **CORRECTION, 2026-08-06 — and then the correction was DISCHARGED the same
night; both halves are recorded because the first half alone is now false.**

This docstring long claimed that "every run is CHECKED per-instance (`--check`,
on by default)", describing a readback pass. **For as long as it said so, no such
flag and no such pass existed** — the claim was written aspirationally and read
as fact, which is the defect class this campaign spent the day cataloguing. What
the run printed was a *census report*, and a report cannot fail.

✅ **`--check` now exists** (`Importer/readback.py`) and the sentence is true for
the first time. It does more than the original claim promised: rather than
comparing this program against a second parse of itself, it simulates the emitted
datum against **vendor Liberty semantics**, taking cell functions, output-pin
directions, flop identification and next-state from the `.lib` rather than from
any table in this file. Its own negative controls are recorded in that file.

⚠️ **Do not read the fix as retiring the lesson.** The claim was false for weeks
and nothing detected it, because a docstring is not executed. *The check is worth
having; the reason it was owed is worth remembering.*

What is checked, today:

* the **cell expansions** are not trusted: each sky130 cell is expanded into
  primitive gates, and `SaltWorks/Silicon/Cells/Sky130.lean` carries a
  `decide +kernel` theorem that the expansion equals the cell's Liberty function
  (44 theorems over 43 cells, covering every cell this file expands).
* the **emitted datum is simulated against the vendor Liberty** by `--check`,
  which is independent of `EXPAND`, `OUTPINS`, `SEQ_PREFIX` and `SEQ_MODELS` —
  corrupting any of them makes it fail, and that was measured, not assumed.
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
    "nand4_1":             ([("a", "and", "A", "B"), ("b", "and", "a", "C"),
                             ("c", "and", "b", "D"), ("t", "not", "c", None)], ("Y", "t")),
    # The rest of the 4-input family, keyed on the BASE name so every drive
    # strength resolves through the drive-stripped fallback. Proved against
    # Liberty in Sky130.lean; these nine open dmem16, dmem32 and the two
    # dmem_addr netlists (docs/silicon-cell-coverage-census-0812.md).
    "and4":                ([("a", "and", "A", "B"), ("b", "and", "a", "C"),
                             ("t", "and", "b", "D")], ("X", "t")),
    "or4":                 ([("a", "or", "A", "B"), ("b", "or", "a", "C"),
                             ("t", "or", "b", "D")], ("X", "t")),
    "nor4":                ([("a", "or", "A", "B"), ("b", "or", "a", "C"),
                             ("c", "or", "b", "D"), ("t", "not", "c", None)], ("Y", "t")),
    "and4b":               ([("a", "not", "A_N", None), ("b", "and", "a", "B"),
                             ("c", "and", "b", "C"), ("t", "and", "c", "D")], ("X", "t")),
    "nand4b":              ([("a", "not", "A_N", None), ("b", "and", "a", "B"),
                             ("c", "and", "b", "C"), ("d", "and", "c", "D"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "nand4bb":             ([("a", "not", "A_N", None), ("b", "not", "B_N", None),
                             ("c", "and", "a", "b"), ("d", "and", "c", "C"),
                             ("e", "and", "d", "D"), ("t", "not", "e", None)], ("Y", "t")),
    "nor4b":               ([("a", "not", "D_N", None), ("b", "or", "A", "B"),
                             ("c", "or", "b", "C"), ("d", "or", "c", "a"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "nor4bb":              ([("a", "not", "C_N", None), ("b", "not", "D_N", None),
                             ("c", "or", "A", "B"), ("d", "or", "c", "a"),
                             ("e", "or", "d", "b"), ("t", "not", "e", None)], ("Y", "t")),
    "a2111oi":             ([("a", "and", "A1", "A2"), ("b", "or", "a", "B1"),
                             ("c", "or", "b", "C1"), ("d", "or", "c", "D1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    # Batch 2 — chosen by crossing the cell census with the import sweep: these
    # serve netlists whose ONLY blocker is cells, so they buy a real import.
    "xnor2":               ([("a", "xor", "A", "B"),
                             ("t", "not", "a", None)], ("Y", "t")),
    "o211ai":              ([("a", "or", "A1", "A2"), ("b", "and", "a", "B1"),
                             ("c", "and", "b", "C1"),
                             ("t", "not", "c", None)], ("Y", "t")),
    "o221ai":              ([("a", "or", "A1", "A2"), ("b", "or", "B1", "B2"),
                             ("c", "and", "a", "b"), ("d", "and", "c", "C1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "a311oi":              ([("a", "and", "A1", "A2"), ("b", "and", "a", "A3"),
                             ("c", "or", "b", "B1"), ("d", "or", "c", "C1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "maj3":                ([("a", "and", "A", "B"), ("b", "and", "A", "C"),
                             ("c", "and", "B", "C"), ("d", "or", "a", "b"),
                             ("t", "or", "d", "c")], ("X", "t")),
    # Batch 3 — closes the cells-only class; after these every remaining
    # blocked netlist is gated by the grammar or by concatenation (math's call).
    "o2111ai":             ([("a", "or", "A1", "A2"), ("b", "and", "a", "B1"),
                             ("c", "and", "b", "C1"), ("d", "and", "c", "D1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "o311ai":              ([("a", "or", "A1", "A2"), ("b", "or", "a", "A3"),
                             ("c", "and", "b", "B1"), ("d", "and", "c", "C1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "a21bo":               ([("a", "and", "A1", "A2"), ("b", "not", "B1_N", None),
                             ("t", "or", "a", "b")], ("X", "t")),
    "a41o":                ([("a", "and", "A1", "A2"), ("b", "and", "a", "A3"),
                             ("c", "and", "b", "A4"),
                             ("t", "or", "c", "B1")], ("X", "t")),
    "a41oi":               ([("a", "and", "A1", "A2"), ("b", "and", "a", "A3"),
                             ("c", "and", "b", "A4"), ("d", "or", "c", "B1"),
                             ("t", "not", "d", None)], ("Y", "t")),
    "o2111a":              ([("a", "or", "A1", "A2"), ("b", "and", "a", "B1"),
                             ("c", "and", "b", "C1"),
                             ("t", "and", "c", "D1")], ("X", "t")),
    "o21ba":               ([("a", "or", "A1", "A2"), ("b", "not", "B1_N", None),
                             ("t", "and", "a", "b")], ("X", "t")),
    "o221a":               ([("a", "or", "A1", "A2"), ("b", "or", "B1", "B2"),
                             ("c", "and", "a", "b"),
                             ("t", "and", "c", "C1")], ("X", "t")),
    "o22a":                ([("a", "or", "A1", "A2"), ("b", "or", "B1", "B2"),
                             ("t", "and", "a", "b")], ("X", "t")),
    "o32a":                ([("a", "or", "A1", "A2"), ("b", "or", "a", "A3"),
                             ("c", "or", "B1", "B2"),
                             ("t", "and", "b", "c")], ("X", "t")),
    # S1 is the HIGH select bit, binary encoding — read from the vendor, not
    # assumed; see docs/silicon-cell-model-prereg-0812-batch2.txt risk (a).
    "mux4":                ([("n0", "not", "S0", None), ("n1", "not", "S1", None),
                             ("p0", "and", "A0", "n0"), ("q0", "and", "p0", "n1"),
                             ("p1", "and", "A1", "S0"), ("q1", "and", "p1", "n1"),
                             ("p2", "and", "A2", "n0"), ("q2", "and", "p2", "S1"),
                             ("p3", "and", "A3", "S0"), ("q3", "and", "p3", "S1"),
                             ("r0", "or", "q0", "q1"), ("r1", "or", "q2", "q3"),
                             ("t", "or", "r0", "r1")], ("X", "t")),
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
    # a2bb2oi: hand-derived as !((!A1_N & !A2_N) | (B1 & B2)), which distributes
    # to the vendor's four-term form (A1_N|A2_N) & (!B1|!B2). Derived BEFORE
    # reading Liberty, per the non-circularity rule; Liberty adjudicated it.
    "a2bb2oi":            ([('a', 'or', 'A1_N', 'A2_N'), ('b', 'not', 'B1', None),
                            ('c', 'not', 'B2', None), ('d', 'or', 'b', 'c'),
                            ('t', 'and', 'a', 'd')], ('Y', 't')),
    "dlygate4sd3":        ([('t', 'buf', 'A', None)], ('X', 't')),
    "clkdlybuf4s25":      ([('t', 'buf', 'A', None)], ('X', 't')),
    # --- added for BB-1 B2 (the 24-element bitonic network). Each derived BY
    # HAND from the naming convention, then adjudicated against the vendor
    # Liberty: 9 of 9 agreed. Models + theorems in Cells/Sky130.lean.
    "a221o":   ([('a','and','A1','A2'),('b','and','B1','B2'),('c','or','a','b'),
                 ('t','or','c','C1')], ('X','t')),
    "a22o":    ([('a','and','A1','A2'),('b','and','B1','B2'),('t','or','a','b')], ('X','t')),
    "nor2b":   ([('n','not','A',None),('t','and','n','B_N')], ('Y','t')),
    "o21bai":  ([('a','or','A1','A2'),('n','not','a',None),('t','or','n','B1_N')], ('Y','t')),
    "o31a":    ([('a','or','A1','A2'),('b','or','a','A3'),('t','and','b','B1')], ('X','t')),
    "o31ai":   ([('a','or','A1','A2'),('b','or','a','A3'),('c','and','b','B1'),
                 ('t','not','c',None)], ('Y','t')),
    "o41ai":   ([('a','or','A1','A2'),('b','or','a','A3'),('c','or','b','A4'),
                 ('d','and','c','B1'),('t','not','d',None)], ('Y','t')),
    "or3":     ([('a','or','A','B'),('t','or','a','C')], ('X','t')),
    "or4b":    ([('a','or','A','B'),('b','or','a','C'),('n','not','D_N',None),
                 ('t','or','b','n')], ('X','t')),

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
# ⚠️ WHY `dfrtp` IS PRESENT BUT **GATED** (8/12, helm-ruled 18:28).
# `dfrtp` carries an asynchronous `RESET_B`, and the tempting `next = D & RESET_B`
# is NOT merely an approximation — it is a category error, which the vendor's own
# file says more sharply than the behavioural argument does:
#
#     liberty ff group, sky130_fd_sc_hd__tt_025C_1v80.lib
#       dfxtp_1   clocked_on "CLK"   next_state "D"
#       dfrtp_1   clocked_on "CLK"   next_state "D"      clear : "!RESET_B"
#
# `next_state` and `clear` are SEPARATE FIELDS of the Liberty `ff` group, and
# `dfrtp_1`'s `next_state` is the string "D" — byte-identical to `dfxtp_1`'s.  The
# asynchronous reset therefore contributes EXACTLY ZERO to the next-state
# function; `next = D & RESET_B` merges two fields the standard keeps disjoint.
# (Corroborated twice more: the behavioural model wires `RESET_B` through `not0`
# into `udp_dff$PR`, whose port is distinct from CLK; and that UDP's table has the
# row `?  ?  1 : ? : 0  // async reset`, which fires with CLK as DON'T-CARE.)
#
# ⇒ The consequence runs the other way too: `{"d": "D"}` below is ALREADY the
# correct next-state model for `dfrtp`.  What `dfrtp` lacked was never a
# next-state model — it was a treatment for `clear`, which is not a next-state
# phenomenon at all.
#
# ⛔ SO THE MODEL IS GATED, NOT FREE.  Because the datum has no notion of the
# between-edge event `clear` describes, this cell imports ONLY under `--pin-reset`,
# which holds the reset net at its INACTIVE value.  Under `RESET_B ≡ 1`,
# `clear = !1 = 0` never asserts and the ff group reduces to `clocked_on CLK,
# next_state D` — *literally dfxtp_1's group, field for field*.  The equivalence is
# a syntactic identity in the vendor model, not an argument this importer makes.
# Without the flag `dfrtp` STILL REFUSES, exactly as before.
#
# ⚠️ THE RESTRICTION IS REAL AND RIDES THE WHOLE CHAIN: the emitted datum models
# the design only for traces where the reset is held inactive throughout, and it
# says NOTHING about the deassertion seam.  A theorem proved on a pinned datum
# MUST NOT be cited as covering reset or bring-up.  Pre-registration, checks, bar
# and the declared gap: docs/silicon-dfrtp-async-reset-prereg-0812.md.
# ---------------------------------------------------------------------------
# An entry is either
#   "d"    : the next state IS this pin's net — the root is that net, unchanged;
#   "next" : the next state is a straight-line expression over the flop's pins
#            (including its OWN `Q`, which resolves to the state leaf), and the
#            root is the gate that expression emits.
# "pins" lists every non-power pin the model accounts for; anything else
# connected is a hard error.
# "reset" : (PIN, INACTIVE_VALUE) — an ASYNCHRONOUS clear/preset this model can
#           only honour by PINNING.  Its presence makes the cell gated: it
#           imports under `--pin-reset` and refuses without it.  The inactive
#           value is declared HERE, per cell, and is never supplied by the
#           caller — otherwise the flag could be pointed at an active-high reset
#           and would pin it to the value that HOLDS the design in reset.
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

    # GATED — see the block above. `d: "D"` is the vendor's own `next_state`,
    # unchanged from dfxtp; `reset` is the `clear` field the datum cannot express
    # and therefore pins.  RESET_B is ACTIVE-LOW, so its inactive value is 1.
    "dfrtp":  {"clk": "CLK", "q": "Q", "pins": {"CLK", "D", "Q", "RESET_B"},
               "d": "D", "reset": ("RESET_B", 1)},
}


def find_flops(insts, pin_reset=None):
    """-> [ {cell, iname, q, d, clk} ], one per sequential instance.

    Refuses on: an unmodelled sequential cell, a missing modelled pin, any
    connected non-power pin the model does not account for (which is how a
    silently-dropped reset would be caught), and a GATED cell (one carrying an
    asynchronous `reset`) when `--pin-reset` was not given."""
    flops, unmodelled, gated = [], collections.Counter(), collections.Counter()
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
        # ⛔ C4 — THE GATE. A cell carrying an asynchronous `reset` imports only
        # under --pin-reset. This arm is the DEFAULT path for dfrtp, and it must
        # stay reachable: it is the behaviour every caller gets who has not asked
        # for the restriction, and the pre-registration bars landing without it.
        if "reset" in m and pin_reset is None:
            gated[cell] += 1
            continue
        rec = {"cell": cell, "iname": iname, "model": m,
               "q": conns[m["q"]], "clk": conns[m["clk"]], "conns": conns,
               "d": conns[m["d"]] if "d" in m else None}
        if "reset" in m:
            rec["reset_net"] = conns[m["reset"][0]]
            rec["reset_inactive"] = m["reset"][1]
        flops.append(rec)
    if gated:
        listing = ", ".join(f"{c} x{n}" for c, n in sorted(gated.items()))
        pins = sorted({SEQ_MODELS[base_of(c)]["reset"][0] for c in gated})
        raise SystemExit(
            f"importer: sequential cell(s) with an ASYNCHRONOUS reset: {listing}. Their "
            f"{'/'.join(pins)} is not a next-state function of the flop's inputs — the vendor "
            f"Liberty puts it in `clear`, a SEPARATE FIELD from `next_state`, and `next_state` "
            f"is plain \"D\". Importing them requires --pin-reset NET, which holds the reset "
            f"INACTIVE and restricts the datum to traces where it stays so. Refusing rather "
            f"than importing a machine whose reset behaviour the datum cannot express. "
            f"See docs/silicon-dfrtp-async-reset-prereg-0812.md.")
    if unmodelled:
        listing = ", ".join(f"{c} x{n}" for c, n in sorted(unmodelled.items()))
        raise SystemExit(
            f"importer: unmodelled sequential cell(s): {listing}. Skipping a flop loses a "
            f"STATE BIT, not a gate — add it to SEQ_MODELS only with a justified next-state "
            f"model (see the note on `dfrtp` there).")
    return flops


def check_pinned_reset(flops, pin_reset, insts, drv, inputs_set):
    """C1 + C2 of the pre-registration. -> (n_pinned, other_consumers).

    C1 (BLOCKING) every gated flop's reset pin is on the SAME net; that net is
       the one named by --pin-reset; and it is NOT DRIVEN by a cell, i.e. it is a
       primary input or a constant. A derived or gated reset is not pinnable:
       holding a WIRE inactive says nothing about the logic that drives it.
    C2 (DISCLOSURE, never blocking) every OTHER consumer of the pinned net is
       named. Pinning restricts the trace set, and where the net feeds real logic
       that restriction bites something besides the flops. Measured on the dmem
       family the count is 0 — but that is a property of THOSE artifacts, not of
       the technique, so it is reported per-run rather than assumed."""
    gatedf = [f for f in flops if "reset_net" in f]
    if not gatedf:
        raise SystemExit(
            f"importer: --pin-reset '{pin_reset}' was given but no imported cell has an "
            f"asynchronous reset to pin. A flag that restricts the datum must not be a no-op: "
            f"it would advertise a restriction nothing applied.")

    nets = sorted({f["reset_net"] for f in gatedf})
    if len(nets) > 1:
        raise SystemExit(
            f"importer: gated flops' reset pins span {len(nets)} nets ({', '.join(nets[:4])}). "
            f"--pin-reset holds ONE net inactive; pinning one of several would leave the others "
            f"live and unmodelled.")
    if nets[0] != pin_reset:
        raise SystemExit(
            f"importer: --pin-reset names '{pin_reset}' but every gated flop's reset pin is on "
            f"'{nets[0]}'. Refusing rather than pinning a net the flops do not use.")
    if pin_reset in drv:
        cell, iname, _ = drv[pin_reset]
        raise SystemExit(
            f"importer: --pin-reset '{pin_reset}' is DRIVEN by {iname} ({cell}), so it is a "
            f"derived reset, not a primary input or a constant. Holding a driven wire inactive "
            f"asserts nothing about the logic driving it, and the restriction would be "
            f"unverifiable. Refusing.")
    if pin_reset in inputs_set:
        raise SystemExit(
            f"importer: --pin-reset '{pin_reset}' is ALSO listed in --inputs. A pinned net is "
            f"held at a CONSTANT, so it is not an input of the resulting datum — leaving it in "
            f"--inputs would let a theorem drive the very net the restriction fixes, which is "
            f"precisely the trace class this datum does not model. Remove it from --inputs.")

    # C2 — disclosure. Every pin, on every instance, that is NOT one of the gated
    # flops' reset pins but sits on the pinned net.
    other = []
    for (cell, iname, conns) in insts:
        for p, nm in conns.items():
            if nm != pin_reset:
                continue
            m = SEQ_MODELS.get(base_of(cell))
            if m is not None and "reset" in m and p == m["reset"][0]:
                continue
            other.append(f"{iname}.{p} ({cell})")
    return len(gatedf), sorted(other)


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
    vector_ports = {}          # name -> (hi, lo) for every RANGED declaration
    while i < n:
        k, v = toks[i]
        if k == "ID" and v in ("input", "output", "wire", "inout"):
            decl, i = v, i + 1
            ranged = False
            # The BOUNDS are captured, not just the fact of being ranged: C-V1
            # (below, at the CLI) refuses a vector passed by BASE name, and a
            # refusal that cannot print the width the caller should have expanded
            # to is a symptom, not a diagnosis. That is the same defect this
            # seat registered against the whole-vector assign at 20:09.
            bounds = []
            if i < n and toks[i] == ("P", "["):
                ranged = True
                while i < n and toks[i] != ("P", "]"):
                    if toks[i][0] == "NUM":
                        bounds.append(int(toks[i][1]))
                    i += 1
                i += 1
            names = []
            while i < n and toks[i] != ("P", ";"):
                if toks[i][0] in ("ID", "ESCID"):
                    names.append(toks[i][1])
                i += 1
            decls[decl].update(names)
            if ranged:
                hi = max(bounds) if bounds else 0
                lo = min(bounds) if bounds else 0
                for nm_ in names:
                    vector_ports[nm_] = (hi, lo)
            i += 1
        elif k == "ID" and v == "assign":
            i += 1
            lhs, rhs, cur = None, None, []
            while i < n and toks[i] != ("P", ";"):
                if toks[i][0] in ("ID", "ESCID"):
                    base = toks[i][1]
                    if (toks[i][0] == "ID" and i + 1 < n and toks[i + 1] == ("P", "[")):
                        base = f"{base}[{toks[i+2][1]}]"
                        # RANGE IS NOT A BIT-SELECT. Taking the top bit silently is
                        # the soundness class this file already names at line 79
                        # ("it aliases distinct nets onto one"). MEASURED 8/12 on the
                        # ADOPTED D1b netlist: `assign word_index = byte_addr[4:2];`
                        # parsed as (word_index, byte_addr[4]) -- a THREE-BIT word
                        # address collapsed to its TOP BIT. The datum carried ONE net
                        # where three were required, RC=0, file written, nothing said.
                        # The grammar at line 83 models `<vector_port>[<i>] = <scalar>`
                        # and says nothing about a range. REFUSE rather than narrow an
                        # unmodelled form to one the parser happens to handle.
                        if i + 3 < n and toks[i + 3] == ("P", ":"):
                            hi = toks[i+2][1]
                            lo = toks[i+4][1] if i + 4 < n else "?"
                            raise SystemExit(
                                f"importer: assign uses a RANGE '{toks[i][1]}[{hi}:{lo}]' -- "
                                "the grammar models bit-selects and scalars only. "
                                "Refusing rather than collapsing the range to one bit. "
                                "Emit per-bit assigns, or extend the grammar and this "
                                "check together.")
                        i += 3
                    cur.append(base)
                elif toks[i] == ("P", "="):
                    lhs, cur = cur[0], []
                i += 1
            # `cur[0]` DISCARDS every later element: a concatenation
            # (`assign a = {b,c};`) is not modelled either, and taking the first
            # term is the same silent narrowing as the range above.
            if len(cur) > 1:
                raise SystemExit(
                    f"importer: assign right-hand side has {len(cur)} terms "
                    f"({', '.join(cur[:4])}) -- concatenations are not modelled. "
                    "Refusing rather than importing the first term.")
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
                                # ⛔ THERE WAS A CHECK HERE AND IT WAS A TAUTOLOGY:
                                # `assert base in vector_ports or True` is always
                                # true, so `vector_ports` was COMPUTED and consumed
                                # by nothing. It read like enforcement. Removed
                                # rather than enabled: whether a bit-selected net
                                # must be a DECLARED vector is a separate question
                                # (escaped register names reach here too), and it is
                                # not what the 20:1x control measured. The knowledge
                                # this set carries is now genuinely used, at C-V1.
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


def build(insts, decls, assigns, inputs_order, pinned=None):
    """-> (gates, netindex) with gates a list of ('inp'|op, args...)

    `pinned` maps net -> bool for nets held at a CONSTANT (see --pin-reset). The
    binding is seeded AFTER the primary inputs so input gate indices stay
    0..n-1, which is what keeps every unpinned datum byte-identical."""
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
        # A PINNED net binds to its constant ON FIRST READ, not eagerly.
        # Seeding it up front emitted a `.const` even when nothing read the net —
        # and when the reset feeds ONLY reset pins (which the flop treatment never
        # reads) that constant is DEAD, yet it still inflates the gate count and
        # shifts every later index. Pre-registered check C3 caught exactly that:
        # 8 gates against the dfxtp arm's 7. Lazily, a pinned reset with no other
        # consumer yields a datum GATE-FOR-GATE identical to the dfxtp reading —
        # which is what the vendor ff-group identity predicts, and the whole
        # substantive claim M1 rests on. Where the net does feed logic (the case
        # C2 discloses), the constant is emitted and genuinely used.
        if nm in (pinned or {}):
            idx[nm] = emit("const", bool(pinned[nm]))
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
            ndesign_out=None, clockinfo=None, cuts=(), pinned=None):
    L = [f"-- GENERATED by SaltWorks/Silicon/Importer/import_netlist.py",
         f"-- source: {os.path.basename(src)}",
         f"-- DO NOT EDIT. The generator is UNTRUSTED; this datum is checked",
         f"-- per-instance by the importer's round-trip census, and its cell",
         f"-- expansions are proved against Liberty in SaltWorks.Silicon.Cells.Sky130."]
    # ⛔ THE SCOPE MARKER RIDES THE DATUM (helm ruling 8/12 18:28, condition 2).
    # It is emitted FIRST, in the header a reader cannot scroll past, because the
    # restriction is a property of what this datum MEANS — not a footnote about
    # how it was made. The ruling extends it further than this file can reach:
    # every certificate that restates a theorem over this datum must carry the
    # restriction too, and a cert that drops it is a defect of the cert layer.
    if pinned:
        for nm, val in sorted(pinned.items()):
            L += ["--",
                  f"-- ⚠ RESTRICTED DATUM — '{nm}' IS PINNED TO {int(val)}.",
                  f"-- This models the design ONLY on traces where '{nm}' is held {int(val)}",
                  f"-- THROUGHOUT. Asynchronously-resettable flops were imported under that",
                  f"-- restriction: their vendor `clear` field is unasserted at {int(val)}, so",
                  f"-- the Liberty ff group reduces to dfxtp's field for field. It says NOTHING",
                  f"-- about the deassertion seam — the one cycle where the async path and the",
                  f"-- clock interact. A THEOREM PROVED ON THIS DATUM MUST NOT BE CITED AS",
                  f"-- COVERING RESET OR BRING-UP, and any certificate restating such a theorem",
                  f"-- must carry this restriction with it.",
                  f"-- docs/silicon-dfrtp-async-reset-prereg-0812.md"]
    L += ["import SaltWorks.Silicon.Equiv.BitSliced", "",
          f"namespace {ns}", ""]
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

    # ---- THE LIST-LITERAL DEPTH WALL, and why this is chunked -------------
    #
    # A Lean list literal desugars to a right-nested `List.cons` chain, and the
    # ELABORATOR recurses once per element. MEASURED on this toolchain
    # (2026-08-07, ladder in docs/silicon-c5-execution-plan-0807.md §2.1b):
    #
    #   flat literal, default maxRecDepth :  1,000 OK  ·  2,000 FAILS
    #     -> "maximum recursion depth has been reached"
    #
    # It is NOT specific to Gate or Netlist -- a plain `List Nat` of 2,000
    # elements fails identically. It is generic list-literal elaboration.
    #
    # Two fixes exist and the iterative one is strictly better:
    #   (a) `set_option maxRecDepth` -- works, but pushes the cost onto every
    #       consumer of the file and hides a structural problem behind a knob;
    #   (b) EMIT IN CHUNKS joined by `++` -- each chunk's literal is shallow,
    #       and the top-level `++` chain is only ceil(n/CHUNK) deep.
    #
    # (b) is what this does. MEASURED at DEFAULT maxRecDepth, chunk 500:
    #   4,000 gates OK 2s  ·  12,000 OK 7s  ·  24,000 OK 22s
    # and `decide +kernel` still reduces through the `++` chain (checked with a
    # length theorem at every rung). The core is projected at ~11,900 gates.
    #
    # Netlists at or below THRESHOLD are emitted EXACTLY as before, so every
    # file generated to date is byte-identical under this change.
    CHUNK, THRESHOLD = 500, 1000
    if len(body) <= THRESHOLD:
        L.append(f"/-- {name}: {len(gates)} gates, {ninputs} primary inputs. -/")
        L.append(f"def {name} : SaltWorks.Silicon.Netlist := [")
        L.append(",\n".join(body))
        L.append("]")
    else:
        parts = [body[i:i + CHUNK] for i in range(0, len(body), CHUNK)]
        L.append(f"/-! ### {name} is emitted in {len(parts)} chunks of ≤ {CHUNK}")
        L.append("")
        L.append(f"A flat literal of {len(body)} elements exceeds Lean's default")
        L.append(f"`maxRecDepth` during elaboration (measured wall: 1,000 OK, 2,000 not).")
        L.append(f"Chunking keeps every literal shallow and the `++` chain only")
        L.append(f"{len(parts)} deep, so this file needs NO `set_option` to elaborate.")
        L.append("-/")
        L.append("")
        for ci, part in enumerate(parts):
            L.append(f"def {name}__c{ci} : SaltWorks.Silicon.Netlist := [")
            L.append(",\n".join(part))
            L.append("]")
            L.append("")
        joined = " ++ ".join(f"{name}__c{ci}" for ci in range(len(parts)))
        L.append(f"/-- {name}: {len(gates)} gates, {ninputs} primary inputs. -/")
        L.append(f"def {name} : SaltWorks.Silicon.Netlist := {joined}")
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
ap.add_argument("--check", default="auto", choices=["auto", "require", "off"],
                help="readback: simulate the emitted datum against VENDOR LIBERTY "
                     "semantics (Importer/readback.py). 'auto' runs it when the PDK "
                     "is present and says loudly when it is not; 'require' makes an "
                     "unavailable check a hard error; 'off' must be asked for and is "
                     "printed. There is no silent skip — that is what this flag's "
                     "predecessor pretended to be.")
ap.add_argument("--cut", default=None, metavar="REGEX",
                help="also cut at every net matching REGEX: each becomes BOTH a root "
                     "(the logic driving it) and a leaf (an input for its consumers). "
                     "Same semantics as Sim/cones.py --cut. Use it at `(* keep *)` "
                     "boundaries that survived the flow.")
ap.add_argument("--pin-reset", default=None, metavar="NET",
                help="hold NET at the INACTIVE value declared by the cell model, making "
                     "asynchronously-resettable flops (dfrtp) importable. The datum is then "
                     "RESTRICTED to traces where that net stays inactive throughout, and says "
                     "nothing about the deassertion seam; a theorem proved on it must not be "
                     "cited as covering reset or bring-up. The inactive value comes from "
                     "SEQ_MODELS, never from the caller. See "
                     "docs/silicon-dfrtp-async-reset-prereg-0812.md")
a = ap.parse_args()

insts, decls, assigns, vports = parse(a.netlist)
ins = [x for x in a.inputs.split(",") if x]
outs_named = [x for x in a.outputs.split(",") if x]

# --- C-V1: THE PORT LIST MUST AGREE WITH THE NETLIST'S OWN DECLARATIONS -----
# ⛔ MEASURED 2026-08-12 20:1x, and it is a SOUNDNESS hole in the trusted
# component, not a convenience check. Netlist `wvE` declares `input [1:0] b`
# and one cell reads it. The SAME netlist, same importer:
#     --inputs a,b[0],b[1]  -> EXIT=1 "net 'b' has no driver and is not an input"
#     --inputs a,b          -> EXIT=0, datum WRITTEN with 2 primary inputs for a
#                              3-bit design port, and READBACK GREEN
# A whole 2-bit vector collapsed onto ONE input gate, RC=0, nothing said. This
# is the exact soundness class this file already names twice for ranges and
# concatenations ("it aliases distinct nets onto one") and it was live on a
# third route nobody had modelled.
#
# 🔑 THE REFUSAL THAT EXISTED WAS INCIDENTAL. Nothing here knew about vectors:
# the honest port list only refuses because the generic no-driver check happens
# to miss `b`, and it only gets that chance because import_sweep.py happens to
# bit-expand. A check that fires for a reason unrelated to the property it is
# credited with has not been shown to hold — it has been shown to be lucky.
#
# ⚠️ AND READBACK CANNOT COVER THIS. Readback re-simulates the EMITTED datum
# under the SAME port mapping that did the narrowing, so it agreed. A gate
# downstream of a binding cannot audit that binding.
# `--cut` is deliberately NOT checked here: it is a REGEX over net names, not a
# net list, so a base-name match against it would be a category error. The first
# draft of this line included it and, worse, its `if a.cut else []` bound to the
# WHOLE expression -- with no --cut given, C-V1 would have examined an EMPTY list
# and passed everything, silently. A check that skips is a check that reads green.
_cv1_names = ins + outs_named + ([a.pin_reset] if a.pin_reset else [])
_cv1 = [nm for nm in _cv1_names if nm in vports]
if _cv1:
    nm = _cv1[0]
    hi, lo = vports[nm]
    width = abs(hi - lo) + 1
    expanded = ",".join(f"{nm}[{i}]" for i in range(min(hi, lo), max(hi, lo) + 1))
    raise SystemExit(
        f"importer: port list names '{nm}' by its BASE name, but the netlist "
        f"declares it as the VECTOR [{hi}:{lo}] ({width} bits). Passing a vector "
        f"by base name binds ALL {width} bits to ONE net and the datum silently "
        f"loses {width - 1} bit(s) of input space -- readback does NOT catch this, "
        f"because it re-simulates the emitted datum under the same mapping. "
        f"Pass the bits: --inputs/--outputs ...,{expanded},... "
        f"({len(_cv1)} name(s) affected: {', '.join(_cv1)})")

# --- C-V2: WIDTH AGREEMENT IS A HARD ERROR (math docket call (4), 08/13 05:40)
# ⛔ THE RULING'S BINDING CONDITION, and its stated reason is why this is not a
# nicety: option (b) — the flow emits per-bit assigns and the TRUSTED IMPORTER
# KEEPS REFUSING — rests ENTIRELY on the refusal being right. "A refusal that is
# LUCKY rather than PRINCIPLED is not a foundation, it is a coincidence that has
# not failed yet."
#
# MEASURED 2026-08-13 16:1x, exits captured without a pipe:
#   d0 declared [1:0], netlist reads d0[7], NOT in --inputs -> EXIT=1, but the
#     message is "net 'd0[7]' has no driver and is not an input". A WIDTH fault
#     caught by a DRIVER check: it refuses for the wrong reason and misdiagnoses.
#   the SAME netlist with d0[7] LISTED in --inputs          -> EXIT=0, IMPORTED
#     CLEAN, "primary inputs: 4 (4 design)" for a module declaring three bits.
# ⇒ THE DATUM GAINED A PHANTOM INPUT BIT THE DESIGN NEVER DECLARED. Same family
# as C-V1 and the opposite direction: C-V1 LOSES bits by naming a vector by its
# base; this GAINS one that does not exist. Both produce a datum that parses,
# typechecks and proves theorems about the wrong machine.
#
# The check is narrow ON PURPOSE: it fires only when the base IS a declared
# vector. Escaped register names (`\regs[20] [26]`) reach the same syntax and are
# NOT declared vectors; whether those must be declared is a DIFFERENT question and
# is not this ruling's to answer here.
def _bit_ref(s):
    """'d0[7]' -> ('d0', 7); anything else -> (None, None). Escaped names, which
    carry their own brackets, are never split here — they are not in vports."""
    if s.endswith("]") and "[" in s:
        b, _, i = s[:-1].partition("[")
        if b and i.isdigit():
            return b, int(i)
    return None, None

# BOTH DOORS, because "everywhere" is the ruling's word: the caller-supplied port
# list AND every net the netlist itself names. Case C above enters through the
# port list, so the netlist scan alone would not have closed it.
#
# ⛔ SCANNED AFTER PARSE, NOT INLINE, AND THE REASON IS FAIL-OPEN: a bit-select
# encountered BEFORE its declaration would not yet be in vports, so an inline
# check would silently pass exactly the netlists whose declarations come last.
# A guard whose coverage depends on token order is a guard that reads green on
# the file that defeats it. Post-parse, vports is complete by construction.
_width_srcs = [(nm, "the port list") for nm in _cv1_names]
for _c, _in, _conns in insts:
    _width_srcs.extend((v, f"cell instance '{_in}'") for v in _conns.values())
for _lhs, _rhs in assigns:
    _width_srcs.extend([(_lhs, "an assign"), (_rhs, "an assign")])

# ⚠️ THE SOURCE IS CARRIED, NOT ASSUMED. A first draft named every offender "the
# port list" — and case A's offender is in the NETLIST. That would have shipped a
# width fix whose own diagnosis misdiagnosed, which is precisely the fault this
# check exists to remove (the no-driver refusal calling a width fault a missing
# driver). A refusal that names the wrong door sends the reader to the wrong file.
_cv2, _seen = [], set()
for _nm, _src in _width_srcs:
    if not isinstance(_nm, str) or _nm in _seen:
        continue
    _seen.add(_nm)
    _b, _i = _bit_ref(_nm)
    if _b in vports:
        _hi, _lo = vports[_b]
        if not (min(_hi, _lo) <= _i <= max(_hi, _lo)):
            _cv2.append((_nm, _b, _hi, _lo, _i, _src))
if _cv2:
    nm, b, hi, lo, idx, src = _cv2[0]
    raise SystemExit(
        f"importer: {src} names '{nm}', but the netlist declares '{b}' as "
        f"[{hi}:{lo}] and bit {idx} IS OUTSIDE THAT RANGE. Verilog would silently "
        f"zero-extend or truncate here; this importer refuses, because a datum "
        f"built on a bit the design does not have proves theorems about a "
        f"different machine. Note the generic no-driver check does NOT cover this "
        f"case -- listing the bit as an input gives it a driver and the import "
        f"then succeeds at EXIT=0. "
        f"({len(_cv2)} out-of-range bit(s): {', '.join(x[0] for x in _cv2)})")

# --- THE FLOP TREATMENT ----------------------------------------------------
# Discover every flop, verify they share one latching event, then cut them:
# Q -> appended to the primary inputs (leaf), D -> appended to the outputs
# (root), paired by position and ordered by Q net name.
flops = find_flops(insts, pin_reset=a.pin_reset)
clockinfo = None
auto = []
pinned = {}
reset_others = []
# Guarded BEFORE the treatment, and deliberately not as an `elif` on the block
# below: an `elif` here silently re-parents the whole backward-compatibility body
# that follows into its own branch, leaving `auto` empty and every flop uncut.
# (It did exactly that when first written; the fixture caught it in one run.)
if not flops and a.pin_reset:
    raise SystemExit(
        f"importer: --pin-reset '{a.pin_reset}' was given but this netlist has no flops at "
        f"all. A flag that restricts the datum must not be a silent no-op.")
if flops:
    drv_all = all_drivers(insts)
    clockinfo = check_clock_domain(flops, drv_all, assigns, set(ins))
    if a.pin_reset:
        # C1 (blocking) + C2 (disclosure) of the pre-registration.
        n_pinned, reset_others = check_pinned_reset(
            flops, a.pin_reset, insts, drv_all, set(ins))
        inactive = {f["reset_inactive"] for f in flops if "reset_net" in f}
        if len(inactive) != 1:
            raise SystemExit(f"importer: gated flops declare {len(inactive)} different "
                             f"inactive reset values; they cannot share one pin.")
        pinned[a.pin_reset] = bool(inactive.pop())

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

gates, net, root_value, emit = build(insts, decls, assigns, ins_all, pinned=pinned)


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
# ⛔ THE NAME CLAUSE — math's muster ruling 2026-08-13 05:20, refined 15:24:05:
# rst_n≡1 must ride in the datum's NAME, MECHANICALLY ENFORCED. Until this landed
# the restriction lived only in comment lines, and `--name`/`--ns` were free
# caller strings: a caller who said nothing got an unrestricted-LOOKING datum
# carrying a warning nobody has to read.
#
# ⭐ DERIVED, NEVER ACCEPTED FROM THE CALLER. The suffix is computed from the
# `pinned` map itself, so it cannot be omitted, misspelled, or opted out of by
# any invocation. That is what "mechanically enforced" has to mean — a naming
# rule a caller can decline is a naming convention, not a restriction.
if pinned:
    _sfx = "Restricted_" + "_".join(
        re.sub(r'[^A-Za-z0-9]', '_', f"{nm}_eq_{int(val)}")
        for nm, val in sorted(pinned.items()))
    a.ns = f"{a.ns}.{_sfx}"

open(a.out, "w").write(to_lean(gates, a.ns, a.name, out_idx, len(ins_all), a.netlist,
                               state=auto, ndesign_in=len(ins), ndesign_out=len(outs_named),
                               clockinfo=clockinfo, cuts=cuts, pinned=pinned))

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

if a.pin_reset:
    ngated = len([f for f in flops if "reset_net" in f])
    val = int(pinned[a.pin_reset])
    print(f"  ⚠ RESTRICTED  : '{a.pin_reset}' PINNED to {val} — {ngated} async-reset flop(s) "
          f"imported under it")
    print(f"                  this datum models ONLY traces with '{a.pin_reset}' ≡ {val}; it "
          f"says NOTHING about the deassertion seam")
    # C2 — DISCLOSURE, never blocking. Zero on the dmem family; a non-zero count
    # is not a failure, it is the restriction biting logic besides the flops, and
    # it must be visible in the run rather than inferred from the netlist.
    if reset_others:
        print(f"  ⚠ pin affects : {len(reset_others)} OTHER consumer(s) of '{a.pin_reset}', "
              f"now reading the constant:")
        for o in reset_others[:8]:
            print(f"                    {o}")
        if len(reset_others) > 8:
            print(f"                    … and {len(reset_others) - 8} more")
    else:
        print(f"  pin fan-out   : 0 other consumers — '{a.pin_reset}' feeds only reset pins")

# C6 — CONSERVATION, against an INDEPENDENT count.
#
# ⚠️ The first version of this check compared len(ins)+len(auto)+len(cuts) against
# len(ins_all) — and `ins_all` IS that sum, so the comparison was an identity that
# could not fail in any run. It read exactly like a check. The cure is the one
# `cones.py` already demonstrates for the cone census: measure the same quantity a
# SECOND way that shares no code with the first. Here the second way is a raw
# regex over the netlist TEXT, which never touches the tokenizer or the instance
# list, so a parser that silently dropped a sequential instance diverges here.
#
# ⚠️ KNOWN SENSITIVITY, recorded rather than hidden: the scan reads RAW text, so a
# COMMENTED-OUT sequential instance counts here and not in the parse, and the run
# fails. That is a FALSE POSITIVE — and it is the direction this file chooses on
# purpose. Refusing on a commented-out flop is noisy; missing a dropped one loses
# a state bit silently, and every doctrine in this importer prefers the noise.
# (It is also how the check was SHOWN to go red: planting a commented flop turns
# a green run into `text scan 3, parsed 2 ⛔ MISMATCH`, exit 1. A check never
# demonstrated failing has not been shown to discriminate.)
seq_in_text = len(re.findall(
    r"sky130_fd_sc_hd__(?:" + "|".join(SEQ_PREFIX) + r")\w*\s+\S+\s*\(",
    open(a.netlist).read()))
if flops or seq_in_text:
    dup_q = len(flops) - len({f["q"] for f in flops})
    ok6 = (seq_in_text == len(flops) and dup_q == 0)
    print(f"  conservation  : sequential instances — text scan {seq_in_text}, parsed "
          f"{len(flops)}, cut {len(auto)} + {len(flops) - len(auto)} caller-listed"
          + (f", DUPLICATE Q x{dup_q}" if dup_q else "")
          + f"  {'OK' if ok6 else '⛔ MISMATCH'}")
    if not ok6:
        raise SystemExit(
            "importer: state-bit conservation FAILED — an independent text scan of the "
            "netlist and the parsed instance list disagree on how many sequential cells "
            "there are. Skipping a flop loses a STATE BIT, not a gate.")
print(f"  wrote         : {a.out}")

# --- THE READBACK CHECK ----------------------------------------------------
if a.check == "off":
    print("  readback      : OFF by explicit request — this datum is UNCHECKED")
else:
    import readback
    ok, msg = readback.check(tokenize(open(a.netlist).read()), assigns, a.out,
                             a.name, ins_all, outs_named, auto, cuts)
    print(f"  {msg}")
    if ok is False:
        raise SystemExit(1)
    if ok is None and a.check == "require":
        raise SystemExit("importer: --check=require but the check could not run")
