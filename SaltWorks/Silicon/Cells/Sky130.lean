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
appear here; every cell in the library declares exactly those four, and the
importer discards exactly four per instance.
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

#audit_axioms clkinv_1_liberty nand2_1_liberty and2_0_liberty
#audit_axioms a22oi_1_liberty a31oi_1_liberty a222oi_1_liberty
#audit_axioms o22ai_1_liberty o2bb2ai_1_liberty
#audit_axioms mux2_1_liberty mux2i_1_liberty
#audit_axioms lpflow_inputiso1p_1_liberty lpflow_isobufsrc_1_liberty
#audit_axioms dfxtp_1_next_liberty

end SaltWorks.Silicon.Cells
