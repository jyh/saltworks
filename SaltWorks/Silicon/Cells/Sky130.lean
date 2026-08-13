/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib
import SaltWorks.Tactic.AuditAxioms

/-!
# sky130 standard-cell models — THE TRUSTED BASE

These definitions are **trusted**. Nothing checks them against the silicon; they
are the point at which our chain says "this is what a `sky130_fd_sc_hd__nand2_1`
*means*". A wrong model here would make every downstream equivalence proof
vacuous, so they are kept small, readable, and — crucially — **cross-checked
against the vendor's own machine-readable specification.**

## The cross-check, and why it is worth having

Each cell appears twice:

* a **readable model**, written in the form the cell's name describes
  (`a22oi` really is *and-and-or-invert*), and
* a `_liberty` theorem asserting that model equals the **verbatim Boolean
  expression from the PDK's Liberty file**, transcribed character for character
  and discharged by `decide +kernel`.

So a transcription slip has to be made *twice, consistently, in two different
notations* to survive. The Liberty strings were extracted mechanically by
`SaltWorks/Silicon/Cells/extract_liberty.py` from
`sky130_fd_sc_hd__tt_025C_1v80.lib`; re-run it to regenerate them.

This does **not** discharge the trust — Liberty itself could disagree with the
transistors, and the same Liberty drives synthesis, so an error there would move
both sides together. It discharges the *transcription*, which is the failure mode
we can actually do something about. The remaining check is differential: the
gate-level testbench TinyTapeout requires anyway (see `docs/tinytapeout-dossier.md`).

## Scope

These are the 13 cells that synthesis of our two designs actually selected, out
of the 428 in the library — see `SaltWorks/Silicon/Flow-docs/hardware-versions.md`.
This set is **not frozen**: it is a property of the flow configuration, and will
be re-derived against TinyTapeout's CI configuration with an explicit don't-use
list so the trusted set is small by construction rather than by luck.

Power pins (`VPWR`, `VGND`, `VPB`, `VNB`) carry no logical content and do not
appear here. The importer discards a connection **by pin name**, and asserts
nothing about how many appear.

⚠️ **A correction, recorded because the wrong rule was briefly committed.** An
earlier version of this file claimed every cell declares exactly those four, so
the importer could discard exactly four per instance. That is **false against
real netlists**: `sky130_fd_sc_hd__tapvpwrvgnd_1` carries exactly two
(`.VGND`, `.VPWR`) and appears 225–456 times in every real TinyTapeout netlist,
and 23 of the library's 428 cells break the four-pin rule. It is also **not in
the Liberty file at all** — which is why the Liberty survey that produced the
claim could not have falsified it. See `docs/silicon-refuter-0806-addendum.md` §0.

⚠️ **This cell set is largely the wrong one, and is kept only as the D1 record.**
Measured against 118 real TTSKY26c netlists: eight of the nine cells named below
are excluded by LibreLane's sky130A defaults (`no_synth.cells`, 185 entries) and
appear in none of them — `clkinv_1` among them. Conversely the shipped netlist
contains cells bare synthesis never emits (`clkbuf_*` from CTS, `clkdlybuf4s25_1`
and `dlygate4sd3_1` from hold repair, `diode_2` for antennas, `conb_1` tie cells)
and **the flop is `dfrtp_2` — asynchronous, active-low reset — not `dfxtp_1`.**
The shippable model set is re-derived against TT's own configuration in D2.
-/

namespace SaltWorks.Silicon.Cells

open Salt.Tactic

/-! ## Inverters and buffers -/

/-- `clkinv_1` — inverter. (Named for the clock tree; synthesis uses it for
data too, and did in our comparator: 9 instances.) -/
def clkinv_1 (A : Bool) : Bool := !A

theorem clkinv_1_liberty (A : Bool) : clkinv_1 A = (!A) := by decide +kernel +revert

/-! ## NAND / AOI / OAI — the inverting families abc actually reaches for -/

/-- `nand2_1` — 2-input NAND. -/
def nand2_1 (A B : Bool) : Bool := !(A && B)

theorem nand2_1_liberty (A B : Bool) : nand2_1 A B = ((!A) || (!B)) := by
  decide +kernel +revert

/-- `and2_0` — 2-input AND. -/
def and2_0 (A B : Bool) : Bool := A && B

theorem and2_0_liberty (A B : Bool) : and2_0 A B = (A && B) := by decide +kernel +revert

/-- `a22oi_1` — and-and-or-invert: `!((A1&A2) | (B1&B2))`. -/
def a22oi_1 (A1 A2 B1 B2 : Bool) : Bool := !((A1 && A2) || (B1 && B2))

theorem a22oi_1_liberty (A1 A2 B1 B2 : Bool) :
    a22oi_1 A1 A2 B1 B2 =
      ((!A1 && !B1) || (!A1 && !B2) || (!A2 && !B1) || (!A2 && !B2)) := by
  decide +kernel +revert

/-- `a31oi_1` — and3-or-invert: `!((A1&A2&A3) | B1)`. -/
def a31oi_1 (A1 A2 A3 B1 : Bool) : Bool := !((A1 && A2 && A3) || B1)

theorem a31oi_1_liberty (A1 A2 A3 B1 : Bool) :
    a31oi_1 A1 A2 A3 B1 = ((!A1 && !B1) || (!A2 && !B1) || (!A3 && !B1)) := by
  decide +kernel +revert

/-- `a222oi_1` — three ANDs into a NOR: `!((A1&A2) | (B1&B2) | (C1&C2))`. -/
def a222oi_1 (A1 A2 B1 B2 C1 C2 : Bool) : Bool :=
  !((A1 && A2) || (B1 && B2) || (C1 && C2))

theorem a222oi_1_liberty (A1 A2 B1 B2 C1 C2 : Bool) :
    a222oi_1 A1 A2 B1 B2 C1 C2 =
      ((!A1 && !B1 && !C1) || (!A1 && !B1 && !C2) || (!A1 && !B2 && !C1) ||
       (!A2 && !B1 && !C1) || (!A1 && !B2 && !C2) || (!A2 && !B1 && !C2) ||
       (!A2 && !B2 && !C1) || (!A2 && !B2 && !C2)) := by
  decide +kernel +revert

/-- `o22ai_1` — or-or-and-invert: `!((A1|A2) & (B1|B2))`. -/
def o22ai_1 (A1 A2 B1 B2 : Bool) : Bool := !((A1 || A2) && (B1 || B2))

theorem o22ai_1_liberty (A1 A2 B1 B2 : Bool) :
    o22ai_1 A1 A2 B1 B2 = ((!B1 && !B2) || (!A1 && !A2)) := by decide +kernel +revert

/-- `o2bb2ai_1` — the B-inputs arrive already inverted (`A1_N`, `A2_N`):
`!((!A1_N | !A2_N) & (B1|B2))`. Pin names are part of the contract: getting
`A1_N`'s polarity backwards is exactly the slip this cross-check exists for. -/
def o2bb2ai_1 (A1_N A2_N B1 B2 : Bool) : Bool :=
  !((!A1_N || !A2_N) && (B1 || B2))

theorem o2bb2ai_1_liberty (A1_N A2_N B1 B2 : Bool) :
    o2bb2ai_1 A1_N A2_N B1 B2 = ((!B1 && !B2) || (A1_N && A2_N)) := by
  decide +kernel +revert

/-! ## Multiplexers — the bit-serial switch element is mostly these -/

/-- `mux2_1` — `S` selects `A1`, else `A0`. -/
def mux2_1 (A0 A1 S : Bool) : Bool := if S then A1 else A0

theorem mux2_1_liberty (A0 A1 S : Bool) :
    mux2_1 A0 A1 S = ((A0 && !S) || (A1 && S)) := by decide +kernel +revert

/-- `mux2i_1` — inverting 2:1 multiplexer. -/
def mux2i_1 (A0 A1 S : Bool) : Bool := !(if S then A1 else A0)

theorem mux2i_1_liberty (A0 A1 S : Bool) :
    mux2i_1 A0 A1 S = ((!A0 && !S) || (!A1 && S)) := by decide +kernel +revert

/-! ## Low-power-flow cells

⚠️ These are **power-domain isolation** cells, and `abc` selected them as
ordinary datapath logic in our comparator — with `SLEEP` driven by real data
(`.SLEEP(a[7])`), not tied off. They are modelled here because they appeared,
not because they were wanted. LibreLane's sky130 flow normally excludes them;
the intent is to exclude them explicitly and delete these two models. -/

/-- `lpflow_inputiso1p_1` — isolation cell; as logic, an OR. -/
def lpflow_inputiso1p_1 (A SLEEP : Bool) : Bool := A || SLEEP

theorem lpflow_inputiso1p_1_liberty (A SLEEP : Bool) :
    lpflow_inputiso1p_1 A SLEEP = ((A) || (SLEEP)) := by decide +kernel +revert

/-- `lpflow_isobufsrc_1` — isolation buffer; as logic, `A ∧ ¬SLEEP`. -/
def lpflow_isobufsrc_1 (A SLEEP : Bool) : Bool := A && !SLEEP

theorem lpflow_isobufsrc_1_liberty (A SLEEP : Bool) :
    lpflow_isobufsrc_1 A SLEEP = (A && !SLEEP) := by decide +kernel +revert

/-! ## Sequential

`dfxtp_1` is a positive-edge D flip-flop with **no reset pin** — Liberty gives
`next_state = D`, `clocked_on = CLK`, `Q = IQ`. Synthesis chose it for our
bit-serial element and folded the synchronous reset into the D path.

A flop is not a combinational cell and is not modelled as one: the importer
partitions the netlist into (state bits, next-state function, output function)
and the flop contributes its `D` net as the next value of its `Q` net. This
definition records only that transfer function; the cycle semantics live with
the sequential importer.

Note the consequence recorded in `docs/silicon-refuter-0806.md`: TinyTapeout
power-gates unselected designs, so **no flop state survives deselection** and the
reset pulse width is undocumented. The FSM refinement must therefore
self-initialise from an arbitrary state — that is a hypothesis of the theorem,
not a comment. -/

/-- `dfxtp_1` — positive-edge D flip-flop, no reset. `Q` after the edge is `D`
before it. -/
def dfxtp_1_next (D : Bool) : Bool := D

theorem dfxtp_1_next_liberty (D : Bool) : dfxtp_1_next D = D := by decide +kernel +revert

/-! ## The audit

Every model above is asserted to depend on nothing outside
`{propext, Classical.choice, Quot.sound}`. This is a build-*failing* assertion:
if a proof ever acquires `sorryAx`, or a native axiom from `bv_decide`, the build
breaks here rather than at review time. -/

/-! ## THE FABRICATED NETLIST'S CELLS

Added 2026-08-06 after the first TinyTapeout CI run: the artifact that will be
fabricated uses **32 logic cell types** against the 13 modelled here, and the
importer stopped on its first one. See `Cells/CI-cell-census.md`.

⛔ **Every function below was derived BY HAND from the sky130 naming convention,
by contexts forbidden to read the Liberty, and only then checked against it.**
Generating these from the Liberty would make each `_liberty` theorem compare a
value with itself. **The method was not free and it was not decorative: two of
the 27 derivations came back WRONG** — `nor3b` and `or3b` — because the `b`
suffix marks a pre-inverted input but **which** input is not uniform:
`and*b`/`nand*b` bubble the FIRST pin (`A_N`), while `nor3b`/`or3b` bubble the
**LAST** (`C_N`). Nothing in the name says so. Both are written below with the
Liberty's pin positions.

Drive strength is omitted from these names deliberately: checked across the whole
vendor library — 428 cells, 127 base names carrying more than one drive strength
— **zero** have a differing `function`/`next_state`, so the model is a statement
about the function and the importer normalises the suffix when it looks one up. -/

/-- `inv` -/
def inv (A : Bool) : Bool := !A

theorem inv_liberty (A : Bool) :
    inv A = ((!A)) := by decide +kernel +revert

/-- `buf` -/
def buf (A : Bool) : Bool := A

theorem buf_liberty (A : Bool) :
    buf A = ((A)) := by decide +kernel +revert

/-- `clkbuf` -/
def clkbuf (A : Bool) : Bool := A

theorem clkbuf_liberty (A : Bool) :
    clkbuf A = ((A)) := by decide +kernel +revert

/-- `dlygate4sd3` -/
def dlygate4sd3 (A : Bool) : Bool := A

theorem dlygate4sd3_liberty (A : Bool) :
    dlygate4sd3 A = ((A)) := by decide +kernel +revert

/-- `clkdlybuf4s25` -/
def clkdlybuf4s25 (A : Bool) : Bool := A

theorem clkdlybuf4s25_liberty (A : Bool) :
    clkdlybuf4s25 A = ((A)) := by decide +kernel +revert

/-- `or2` -/
def or2 (A B : Bool) : Bool := A || B

theorem or2_liberty (A B : Bool) :
    or2 A B = ((A) || (B)) := by decide +kernel +revert

/-- `nor2` -/
def nor2 (A B : Bool) : Bool := !(A || B)

theorem nor2_liberty (A B : Bool) :
    nor2 A B = ((!A && !B)) := by decide +kernel +revert

/-- `and3` -/
def and3 (A B C : Bool) : Bool := A && B && C

theorem and3_liberty (A B C : Bool) :
    and3 A B C = ((A && B && C)) := by decide +kernel +revert

/-- `nand3` -/
def nand3 (A B C : Bool) : Bool := !(A && B && C)

theorem nand3_liberty (A B C : Bool) :
    nand3 A B C = ((!A) || (!B) || (!C)) := by decide +kernel +revert

/-- `nand4` -/
def nand4 (A B C D : Bool) : Bool := !(A && B && C && D)

theorem nand4_liberty (A B C D : Bool) :
    nand4 A B C D = ((!A) || (!B) || (!C) || (!D)) := by decide +kernel +revert

/-- `nor3` -/
def nor3 (A B C : Bool) : Bool := !(A || B || C)

theorem nor3_liberty (A B C : Bool) :
    nor3 A B C = ((!A && !B && !C)) := by decide +kernel +revert

/-- `xor2` -/
def xor2 (A B : Bool) : Bool := A != B

theorem xor2_liberty (A B : Bool) :
    xor2 A B = ((A && !B) || (!A && B)) := by decide +kernel +revert

/-- `and2b` -/
def and2b (A_N B : Bool) : Bool := (!A_N) && B

theorem and2b_liberty (A_N B : Bool) :
    and2b A_N B = ((!A_N && B)) := by decide +kernel +revert

/-- `and3b` -/
def and3b (A_N B C : Bool) : Bool := (!A_N) && B && C

theorem and3b_liberty (A_N B C : Bool) :
    and3b A_N B C = ((!A_N && B && C)) := by decide +kernel +revert

/-- `and4bb` -/
def and4bb (A_N B_N C D : Bool) : Bool := (!A_N) && (!B_N) && C && D

theorem and4bb_liberty (A_N B_N C D : Bool) :
    and4bb A_N B_N C D = ((!A_N && !B_N && C && D)) := by decide +kernel +revert

/-- `nand2b` -/
def nand2b (A_N B : Bool) : Bool := !((!A_N) && B)

theorem nand2b_liberty (A_N B : Bool) :
    nand2b A_N B = ((A_N) || (!B)) := by decide +kernel +revert

/-- `nand3b` -/
def nand3b (A_N B C : Bool) : Bool := !((!A_N) && B && C)

theorem nand3b_liberty (A_N B C : Bool) :
    nand3b A_N B C = ((A_N) || (!B) || (!C)) := by decide +kernel +revert

/-- `nor3b` -/
def nor3b (A B C_N : Bool) : Bool := !(A || B || (!C_N))

theorem nor3b_liberty (A B C_N : Bool) :
    nor3b A B C_N = ((!A && !B && C_N)) := by decide +kernel +revert

/-- `or3b` -/
def or3b (A B C_N : Bool) : Bool := A || B || (!C_N)

theorem or3b_liberty (A B C_N : Bool) :
    or3b A B C_N = ((A) || (B) || (!C_N)) := by decide +kernel +revert

/-- `a21o` -/
def a21o (A1 A2 B1 : Bool) : Bool := (A1 && A2) || B1

theorem a21o_liberty (A1 A2 B1 : Bool) :
    a21o A1 A2 B1 = ((A1 && A2) || (B1)) := by decide +kernel +revert

/-- `a21oi` -/
def a21oi (A1 A2 B1 : Bool) : Bool := !((A1 && A2) || B1)

theorem a21oi_liberty (A1 A2 B1 : Bool) :
    a21oi A1 A2 B1 = ((!A1 && !B1) || (!A2 && !B1)) := by decide +kernel +revert

/-- `a21boi` -/
def a21boi (A1 A2 B1_N : Bool) : Bool := !((A1 && A2) || (!B1_N))

theorem a21boi_liberty (A1 A2 B1_N : Bool) :
    a21boi A1 A2 B1_N = ((!A1 && B1_N) || (!A2 && B1_N)) := by decide +kernel +revert

/-- `a31o` -/
def a31o (A1 A2 A3 B1 : Bool) : Bool := (A1 && A2 && A3) || B1

theorem a31o_liberty (A1 A2 A3 B1 : Bool) :
    a31o A1 A2 A3 B1 = ((A1 && A2 && A3) || (B1)) := by decide +kernel +revert

/-- `a32o` -/
def a32o (A1 A2 A3 B1 B2 : Bool) : Bool := (A1 && A2 && A3) || (B1 && B2)

theorem a32o_liberty (A1 A2 A3 B1 B2 : Bool) :
    a32o A1 A2 A3 B1 B2 = ((A1 && A2 && A3) || (B1 && B2)) := by decide +kernel +revert

/-- `a211o` -/
def a211o (A1 A2 B1 C1 : Bool) : Bool := (A1 && A2) || B1 || C1

theorem a211o_liberty (A1 A2 B1 C1 : Bool) :
    a211o A1 A2 B1 C1 = ((A1 && A2) || (B1) || (C1)) := by decide +kernel +revert

/-- `a211oi` -/
def a211oi (A1 A2 B1 C1 : Bool) : Bool := !((A1 && A2) || B1 || C1)

theorem a211oi_liberty (A1 A2 B1 C1 : Bool) :
    a211oi A1 A2 B1 C1 = ((!A1 && !B1 && !C1) || (!A2 && !B1 && !C1)) := by decide +kernel +revert

/-- `a221oi` -/
def a221oi (A1 A2 B1 B2 C1 : Bool) : Bool := !((A1 && A2) || (B1 && B2) || C1)

theorem a221oi_liberty (A1 A2 B1 B2 C1 : Bool) :
    a221oi A1 A2 B1 B2 C1 = ((!A1 && !B1 && !C1) || (!A1 && !B2 && !C1) || (!A2 && !B1 && !C1) || (!A2 && !B2 && !C1)) := by decide +kernel +revert

/-- `o21a` -/
def o21a (A1 A2 B1 : Bool) : Bool := (A1 || A2) && B1

theorem o21a_liberty (A1 A2 B1 : Bool) :
    o21a A1 A2 B1 = ((A1 && B1) || (A2 && B1)) := by decide +kernel +revert

/-- `o21ai` -/
def o21ai (A1 A2 B1 : Bool) : Bool := !((A1 || A2) && B1)

theorem o21ai_liberty (A1 A2 B1 : Bool) :
    o21ai A1 A2 B1 = ((!A1 && !A2) || (!B1)) := by decide +kernel +revert

/-- `o211a` -/
def o211a (A1 A2 B1 C1 : Bool) : Bool := (A1 || A2) && B1 && C1

theorem o211a_liberty (A1 A2 B1 C1 : Bool) :
    o211a A1 A2 B1 C1 = ((A1 && B1 && C1) || (A2 && B1 && C1)) := by decide +kernel +revert

/-- `conb` — the tie cell. It is the ONE cell here that is not a function of its
inputs: it has none, and it drives two constant outputs. The existing model shape
`def f (args) : Bool` does not fit it, so it is two nullary definitions. -/
def conb_HI : Bool := true

/-- `conb`'s low output. -/
def conb_LO : Bool := false

theorem conb_HI_liberty : conb_HI = true := by decide +kernel
theorem conb_LO_liberty : conb_LO = false := by decide +kernel

#audit_axioms clkinv_1_liberty nand2_1_liberty and2_0_liberty
#audit_axioms a22oi_1_liberty a31oi_1_liberty a222oi_1_liberty
#audit_axioms o22ai_1_liberty o2bb2ai_1_liberty
#audit_axioms mux2_1_liberty mux2i_1_liberty
#audit_axioms lpflow_inputiso1p_1_liberty lpflow_isobufsrc_1_liberty
#audit_axioms dfxtp_1_next_liberty
#audit_axioms inv_liberty buf_liberty clkbuf_liberty dlygate4sd3_liberty
#audit_axioms clkdlybuf4s25_liberty or2_liberty nor2_liberty and3_liberty
#audit_axioms nand3_liberty nand4_liberty nor3_liberty xor2_liberty and2b_liberty
#audit_axioms and3b_liberty and4bb_liberty nand2b_liberty nand3b_liberty
#audit_axioms nor3b_liberty or3b_liberty a21o_liberty a21oi_liberty
#audit_axioms a21boi_liberty a31o_liberty a32o_liberty a211o_liberty
#audit_axioms a211oi_liberty a221oi_liberty o21a_liberty o21ai_liberty
#audit_axioms o211a_liberty

/-- `a2bb2oi` — AND-OR-INVERT with BOTH inputs of the first AND bubbled.
Hand-derived from the naming convention before the Liberty was read: `2bb` is a
2-input AND with both inputs bubbled, `2` a plain 2-input AND, `oi` OR-then-invert. -/
def a2bb2oi (A1_N A2_N B1 B2 : Bool) : Bool := !((!A1_N && !A2_N) || (B1 && B2))

/-- The vendor states it in the distributed four-term form; the two agree. -/
theorem a2bb2oi_liberty (A1_N A2_N B1 B2 : Bool) :
    a2bb2oi A1_N A2_N B1 B2
      = ((A1_N && !B1) || (A1_N && !B2) || (A2_N && !B1) || (A2_N && !B2)) := by
  decide +kernel +revert

#audit_axioms a2bb2oi_liberty

/-! ### BB-1 B2 cells — the 24-element bitonic network's remainder.
Each model was written from the naming convention BEFORE the Liberty was read;
all nine agreed with the vendor. -/

def a221o (A1 A2 B1 B2 C1 : Bool) : Bool := (A1 && A2) || (B1 && B2) || C1
theorem a221o_liberty (A1 A2 B1 B2 C1 : Bool) :
    a221o A1 A2 B1 B2 C1 = ((B1 && B2) || (A1 && A2) || C1) := by decide +kernel +revert

def a22o (A1 A2 B1 B2 : Bool) : Bool := (A1 && A2) || (B1 && B2)
theorem a22o_liberty (A1 A2 B1 B2 : Bool) :
    a22o A1 A2 B1 B2 = ((B1 && B2) || (A1 && A2)) := by decide +kernel +revert

def nor2b (A B_N : Bool) : Bool := !A && B_N
theorem nor2b_liberty (A B_N : Bool) : nor2b A B_N = (!A && B_N) := by decide +kernel +revert

def o21bai (A1 A2 B1_N : Bool) : Bool := !((A1 || A2) && !B1_N)
theorem o21bai_liberty (A1 A2 B1_N : Bool) :
    o21bai A1 A2 B1_N = ((!A1 && !A2) || B1_N) := by decide +kernel +revert

def o31a (A1 A2 A3 B1 : Bool) : Bool := (A1 || A2 || A3) && B1
theorem o31a_liberty (A1 A2 A3 B1 : Bool) :
    o31a A1 A2 A3 B1 = ((A1 && B1) || (A2 && B1) || (A3 && B1)) := by decide +kernel +revert

def o31ai (A1 A2 A3 B1 : Bool) : Bool := !((A1 || A2 || A3) && B1)
theorem o31ai_liberty (A1 A2 A3 B1 : Bool) :
    o31ai A1 A2 A3 B1 = ((!A1 && !A2 && !A3) || !B1) := by decide +kernel +revert

def o41ai (A1 A2 A3 A4 B1 : Bool) : Bool := !((A1 || A2 || A3 || A4) && B1)
theorem o41ai_liberty (A1 A2 A3 A4 B1 : Bool) :
    o41ai A1 A2 A3 A4 B1 = ((!A1 && !A2 && !A3 && !A4) || !B1) := by decide +kernel +revert

def or3 (A B C : Bool) : Bool := A || B || C
theorem or3_liberty (A B C : Bool) : or3 A B C = (A || B || C) := by decide +kernel +revert

def or4b (A B C D_N : Bool) : Bool := A || B || C || !D_N
theorem or4b_liberty (A B C D_N : Bool) :
    or4b A B C D_N = (A || B || C || !D_N) := by decide +kernel +revert

#audit_axioms a221o_liberty a22o_liberty nor2b_liberty o21bai_liberty
#audit_axioms o31a_liberty o31ai_liberty o41ai_liberty or3_liberty or4b_liberty

end SaltWorks.Silicon.Cells
