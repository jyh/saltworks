/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Opt

/-!
# `emitV` — the Verilog printer

## ⚠️ THIS BACKEND IS UNTRUSTED, BY DESIGN

Nothing in this file is proved, and nothing in this file should ever be trusted.
There is no `emitV_sem` and there is not going to be one. A printer bug is caught
**downstream**: leg 3 synthesizes this output, imports the resulting gate
netlist, and checks it against `sem` of the original `Circ`. If the printer
mangles the circuit, the equivalence check fails — which is the point of the
seam doctrine, and the reason a printer is an acceptable place to have no proof.

**The hole in that argument, stated because it is real:** the round trip compares
the imported netlist against `sem` *through a port correspondence*. A
misconception shared by the printer and the importer — the same wrong idea about
which wire is which — passes the check. That is why §"The port contract" below is
pinned to an external, machine-checked authority rather than to our own
convention.

## The port contract, and why it is not ours to choose

Measured on three genuine TTSKY26c submissions:

* Source template port order is `ui_in, uo_out, uio_in, uio_out, uio_oe, ena,
  clk, rst_n`; every CI-built netlist declares
  `clk, ena, rst_n, VPWR, VGND, ui_in, uio_in, uio_oe, uio_out, uio_out` —
  **reordered, and with two `inout` power ports added to the top module.**
* Therefore **the equivalence must align ports by NAME. Aligning by position is
  wrong**, and it is wrong in the silent direction: a positional alignment
  produces a true theorem about the wrong circuit.

TinyTapeout's own validator enforces the top-level names, so for the tapeout
module the names are fixed by an authority outside this repo — which is exactly
what a shared-misconception hole needs.

## What the flow requires of this printer

From the same measurements and TT's published rules:

* `` `default_nettype none `` — every net must be declared explicitly.
* **No `initial`** — flops power up at random and reset is explicit.
* **Every output must be driven**; a floating output fails precheck.
* Module name must begin `tt_um_` and must not be `top`.
* Yosys deletes what is unused, so `opt`'s dead-net elimination must have run
  first or the emitted source and the synthesized netlist disagree structurally
  before any proof begins.
-/

namespace SaltWorks.HDL

/-- Net names. Primary inputs are `i0, i1, …`; internal nets are `n2, n3, …`
(numbered by the net they define, so the Verilog and the `Circ` use the same
numbering and a human can diff them). -/
def netName (nIn : Nat) (n : Net) : String :=
  if n < nIn then "i" ++ toString n else "n" ++ toString n

/-- A gate's right-hand side. -/
def opExpr (nIn : Nat) : Op → String
  | .const b => if b then "1'b1" else "1'b0"
  | .not a   => "~" ++ netName nIn a
  | .and a b => netName nIn a ++ " & " ++ netName nIn b
  | .or  a b => netName nIn a ++ " | " ++ netName nIn b
  | .xor a b => netName nIn a ++ " ^ " ++ netName nIn b

private def lines (ls : List String) : String := String.intercalate "\n" ls

/-- **A standalone module for a `Circ`.** Used for synthesizing and certifying a
single block; the tapeout top level is `emitTT` below. -/
def emitV (name : String) (c : Circ) : String :=
  let inPorts  := (List.range c.nIn).map fun i => "    input  wire " ++ netName c.nIn i
  let outPorts := (List.range c.outs.length).map fun k => "    output wire o" ++ toString k
  let decls    := c.gates.map fun g => "  wire " ++ netName c.nIn g.out ++ ";"
  let asgns    := c.gates.map fun g =>
    "  assign " ++ netName c.nIn g.out ++ " = " ++ opExpr c.nIn g.op ++ ";"
  let drives   := (List.range c.outs.length).map fun k =>
    "  assign o" ++ toString k ++ " = " ++ netName c.nIn (c.outs.getD k 0) ++ ";"
  "`default_nettype none\n\nmodule " ++ name ++ " (\n"
    ++ String.intercalate ",\n" (inPorts ++ outPorts) ++ "\n);\n"
    ++ lines decls ++ "\n" ++ lines asgns ++ "\n" ++ lines drives
    ++ "\nendmodule\n\n`default_nettype wire\n"

/-- **The TinyTapeout top level.** The eight-port signature is fixed and
machine-checked by TT's validator — any extra port is a hard error — so it is
written out literally rather than generated.

Unused inputs are sunk into `_unused` because a floating input is a lint error,
and `uio_out`/`uio_oe` are tied low because every output must be driven. -/
def emitTT (name : String) (c : Circ) : String :=
  let inWires  := (List.range c.nIn).map fun i =>
    "  wire " ++ netName c.nIn i ++ " = ui_in[" ++ toString i ++ "];"
  let decls    := c.gates.map fun g => "  wire " ++ netName c.nIn g.out ++ ";"
  let asgns    := c.gates.map fun g =>
    "  assign " ++ netName c.nIn g.out ++ " = " ++ opExpr c.nIn g.op ++ ";"
  let drives   := (List.range 8).map fun k =>
    if k < c.outs.length then
      "  assign uo_out[" ++ toString k ++ "] = " ++ netName c.nIn (c.outs.getD k 0) ++ ";"
    else "  assign uo_out[" ++ toString k ++ "] = 1'b0;"
  "`default_nettype none\n\nmodule " ++ name ++ " (\n"
    ++ "    input  wire [7:0] ui_in,\n    output wire [7:0] uo_out,\n"
    ++ "    input  wire [7:0] uio_in,\n    output wire [7:0] uio_out,\n"
    ++ "    output wire [7:0] uio_oe,\n    input  wire       ena,\n"
    ++ "    input  wire       clk,\n    input  wire       rst_n\n);\n"
    ++ lines inWires ++ "\n" ++ lines decls ++ "\n" ++ lines asgns ++ "\n"
    ++ lines drives ++ "\n"
    ++ "  assign uio_out = 8'b0;\n  assign uio_oe  = 8'b0;\n"
    ++ "  wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};\n"
    ++ "endmodule\n\n`default_nettype wire\n"

/-! ## Structural preconditions

The printer is untrusted, but it need not be *unchecked*. These are the
conditions under which its output can be legal at all; they are `Bool`, so a
concrete circuit discharges them by `decide +kernel`. They say nothing about
whether the Verilog means the right thing — only leg 3's round trip does that. -/

/-- Emittable as a TT top level: well-formed, and inside the pin budget. -/
def ttEmittable (c : Circ) : Bool :=
  c.wf && c.nIn ≤ 8 && c.outs.length ≤ 8

theorem halfAdder_ttEmittable : ttEmittable halfAdder = true := by decide +kernel

/-- Dead nets must be gone before emission, or the emitted source and the
synthesized netlist disagree structurally: Yosys deletes what is unused. -/
theorem withDead_needs_opt :
    ttEmittable withDead = true ∧ (opt withDead).gates.length < withDead.gates.length := by
  decide +kernel

-- Inspect the output. These are exhibits, not tests: the real check is leg 3's.
#eval IO.println (emitV "half_adder" halfAdder)
#eval IO.println (emitTT "tt_um_saltworks_halfadder" (opt halfAdder))

#audit_axioms halfAdder_ttEmittable withDead_needs_opt

end SaltWorks.HDL
