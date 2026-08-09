/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Syntax
import SaltWorks.Tactic.AuditAxioms

/-!
# `emitS` — STRUCTURAL emission: one sky130 cell per gate

Council ruling 1 (the Captain, 2026-08-07 06:08) made C3 a **measured probe of
(A) structural gate-level emission, synthesis-as-passthrough**, with (B)
algebraic per-cone proofs as the fallback. **This file is the compiler seat's
half of that probe.** The flow half is the silicon seat's and runs independently
— by agreement, neither of us reconciled designs first, so the two halves are a
genuine cross-check rather than one implementation checked twice.

## What this is, against `emitV`

`emitV` emits **behavioural** Verilog — `assign n5 = i0 & i1;` — and hands
yosys+abc a free hand. That freedom is exactly what the silicon seat measured on
2026-08-06: on a 32-bit ripple adder with every carry marked `(* keep *)`, the
nets survived and **the logic behind them did not** — `carry[12]` came back
depending on 24 primary bits and **not** on `carry[11]`, because abc re-derived
every carry as lookahead. ***`(* keep *)` preserves the NET, not the
DEPENDENCY.***

`emitS` emits **already-mapped** sky130 cell instances instead — one cell per
`Op` — so there is nothing left for synthesis to invent. The five-constructor
`Op` type maps one-to-one onto five library cells, and the silicon seat has
already proved all five as `_liberty` theorems.

## The prize, stated precisely so it is not overstated

**If the flow preserves this structure, per-cone equivalence stops being an
algebraic obligation and becomes bookkeeping**: each returned cone is one proved
cell, and the check is that the cells and their connections correspond, not that
two Boolean functions agree. That is the difference between a proof per cone and
a diff per cone, and at CPU scale it is the difference that decides C3.

⚠️ **AND THE THING THIS FILE DOES NOT DO.** `emitS` produces a `String`. **Verilog
is outside the kernel and always will be — `emitS` is UNTRUSTED exactly as
`emitV` is.** The trusted path remains `emitN : Circ → Silicon.Netlist`
(`emitN_sem`, 3 axioms). What structural emission buys is not trust in the
Verilog; it is that **the netlist coming BACK from the flow should stand in
one-to-one correspondence with the `Circ` we started from**, which is what makes
the re-import checkable mechanically. *Moving a proof obligation into a
mechanical check is a real gain; pretending the Verilog became trusted would
not be, and is not claimed here.*

## The cell mapping — read from the importer's own tables, not from memory

Port names taken from `SaltWorks/Silicon/Importer/import_netlist.py`'s `EXPAND`
table (lines 109-154), which is the same table the re-import trusts, and
cross-read against a real flow-produced netlist:

```
Op.const b   sky130_fd_sc_hd__conb_1    no inputs; TWO outputs, HI and LO
Op.not  a    sky130_fd_sc_hd__inv_1     A -> Y
Op.and  a b  sky130_fd_sc_hd__and2_1    A, B -> X
Op.or   a b  sky130_fd_sc_hd__or2_1     A, B -> X
Op.xor  a b  sky130_fd_sc_hd__xor2_1    A, B -> X
```

**`inv_1` is `A -> Y` while the other three are `-> X`, and that asymmetry is
real** — it is in the vendor library, not a typo, and an emitter that assumed a
uniform output pin would produce a netlist that reads as valid and is wired
wrong. *(The flow's own output uses `clkinv_1` rather than `inv_1`; that is the
flow resizing and retargeting, which is expected and is precisely what the probe
must be allowed to see without calling it a failure.)*

**`conb_1` is the one cell that is not a function of its inputs** — it has none.
It drives `HI` constant-true and `LO` constant-false. One instance per `const`
gate keeps the correspondence one-to-one, at the cost of a dangling companion
output per constant; sharing a single tie cell across all constants would be
smaller and would break the one-cell-per-gate property this whole file exists
to establish.
-/

namespace SaltWorks.HDL

/-! ### Drive strength is a PARAMETER, and that is a deliberate refusal to guess

The C3 probe found a contradiction here that two agents and a CI run could not
settle, and the verdict's instruction was explicit: **do not resolve it by
argument.**

* The pinned PDK's `libs.tech/openlane/sky130_fd_sc_hd/no_synth.cells` has **199
  entries and contains `inv_1`, `and2_1`, `or2_1`, `xor2_1` — four of the five
  cells below.** Against a liberty reduced by that list, `_1` emission
  **hard-errors before synthesis**: `ERROR: Module '\sky130_fd_sc_hd__or2_1' …
  is not part of the design`, rc=1. Re-emitted at `_2`: rc=0, `Extracted 0
  gates`, 24,320/24,320 instance-exact. ⇒ *pin `_2`.*
* But the silicon seat's **TT CI run `31182129057` ran green on all four jobs
  with `_1` cells, preserved exactly, no resizing.** ⇒ *`_1` is the only drive
  with a real-path green.*

**Both are real measurements and they cannot both describe the same operation** —
deleting cell blocks from a liberty is a stronger edit than an exclusion list
that constrains what abc may *choose* rather than what a designer may
*instantiate*. **The measurement that settles it is a LibreLane/TT-CI run of a
structural design at `_2`, and LibreLane 3.0.5 is not installed on this machine.**

⇒ **So `drive` is an argument.** Emitting either is one character; **choosing
between them without the measurement would be exactly the guess this campaign
keeps paying for.** `conb_1` is deliberately NOT parameterised — it is not on the
exclusion list, and it is OpenLane's own `SYNTH_TIEHI_PORT`/`SYNTH_TIELO_PORT`.
`mux2_1` is not on the list either, so the peephole cell is safe at any drive. -/

/-- The sky130 cell each `Op` maps to, at drive strength `drive` (`"1"`, `"2"`,
…). See the note above: the correct default is **unmeasured**, so the caller
must say. -/
def cellOf (drive : String) : Op → String
  | .const _ => "sky130_fd_sc_hd__conb_1"
  | .not _   => "sky130_fd_sc_hd__inv_" ++ drive
  | .and _ _ => "sky130_fd_sc_hd__and2_" ++ drive
  | .or  _ _ => "sky130_fd_sc_hd__or2_" ++ drive
  | .xor _ _ => "sky130_fd_sc_hd__xor2_" ++ drive

/-- Net names, shared with `emitV` so the two emitters' outputs can be diffed by
a human against the same `Circ`. -/
def sNet (nIn : Nat) (n : Net) : String :=
  if n < nIn then "i" ++ toString n else "n" ++ toString n

/-- The instance name for the gate defining net `n`. **Stable and derived from
the net number**, so the correspondence between a `Circ` gate and a netlist
instance is recoverable from the name alone — that is what makes the re-import
check mechanical rather than a matching problem. -/
def instName (n : Net) : String := "g" ++ toString n

/-- One cell instance, port-mapped. -/
def emitCell (drive : String) (nIn : Nat) (g : Gate) : String :=
  let inst := instName g.out
  let o    := sNet nIn g.out
  match g.op with
  | .const b =>
      -- The tie cell has no inputs and two outputs. The wanted polarity drives
      -- the gate's net; the other is parked on a per-instance dummy so nothing
      -- is left floating, which is a lint error in the flow.
      let dummy := "u_" ++ inst
      if b then
        "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.HI(" ++ o ++ "), .LO(" ++ dummy ++ "));"
      else
        "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.HI(" ++ dummy ++ "), .LO(" ++ o ++ "));"
  | .not a =>
      "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.A(" ++ sNet nIn a ++ "), .Y(" ++ o ++ "));"
  | .and a b =>
      "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.A(" ++ sNet nIn a ++ "), .B(" ++ sNet nIn b ++ "), .X(" ++ o ++ "));"
  | .or a b =>
      "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.A(" ++ sNet nIn a ++ "), .B(" ++ sNet nIn b ++ "), .X(" ++ o ++ "));"
  | .xor a b =>
      "  " ++ cellOf drive g.op ++ " " ++ inst ++ " (.A(" ++ sNet nIn a ++ "), .B(" ++ sNet nIn b ++ "), .X(" ++ o ++ "));"

/-- The dummy wire a `const` gate parks its unused tie output on. -/
def dummyDecl (g : Gate) : Option String :=
  match g.op with
  | .const _ => some ("  wire u_" ++ instName g.out ++ ";")
  | _        => none

private def slines (ls : List String) : String := String.intercalate "\n" ls

/-- **The structural module.** Flat, no hierarchy, every cell already mapped —
so `Checker.YosysUnmappedCells`, which fails TinyTapeout's CI on *un*mapped
instances, has nothing to fire on. -/
def emitS (drive : String) (name : String) (c : Circ) : String :=
  let inPorts  := (List.range c.nIn).map fun i => "    input  wire " ++ sNet c.nIn i
  let outPorts := (List.range c.outs.length).map fun k => "    output wire o" ++ toString k
  let decls    := c.gates.map fun g => "  wire " ++ sNet c.nIn g.out ++ ";"
  let dummies  := c.gates.filterMap dummyDecl
  let cells    := c.gates.map (emitCell drive c.nIn)
  let drives   := (List.range c.outs.length).map fun k =>
    "  assign o" ++ toString k ++ " = " ++ sNet c.nIn (c.outs.getD k 0) ++ ";"
  "`default_nettype none\n\nmodule " ++ name ++ " (\n"
    ++ String.intercalate ",\n" (inPorts ++ outPorts) ++ "\n);\n"
    ++ slines decls ++ "\n" ++ slines dummies ++ "\n"
    ++ slines cells ++ "\n" ++ slines drives
    ++ "\nendmodule\n\n`default_nettype wire\n"

/-! ## The `mux2_1` peephole — the Captain's work order, 2026-08-07

Relayed by the silicon seat at 06:51 with a measured price: on the RV32I read
path it is **3.0× fewer cells and 40% less area** (2981 → 992 cells,
18,637 → 11,171 um²) with **verifiability unchanged** — max cone stays 11, and
passthrough stays exact at 992 in → 992 out, 128/128 boundaries.

⚠️ **THE ORDER SAID `emitV`; IT IS IMPLEMENTED HERE, AND THE ORACLE IS WHY.**
⛔ **CORRECTED 2026-08-09 15:44 — THIS PARAGRAPH MISATTRIBUTED ITS OWN ORACLE.**
`RTL/readtree.v` (2981 cells, 0 assigns) and `RTL/readtreem.v` (992, 0) are
**NOT `emitS` output.** Measured: no `default_nettype`, **vector** ports
(`output [31:0] rdata`) where `emitS` emits scalar `o0…`, and **zero** output
drives where `emitS` emits one `assign` per output (line 172 below).
`readtree.v`'s own header says *"READ-PATH ATTACK, candidate 3 … NOT a
submission artifact."* Other RTL in that directory **is** `emitS`-shaped
(`banyan_element_s.v`, `batcher_c.v`, `ce_c.v`), which is what made the
mismatch visible.

⇒ **CONSEQUENCE, and it was live for a €280 run: an acceptance criterion of
"0 assign lines" taken from those files would FAIL a correct `emitS` emission**,
which drives every primary output. *And the "one-gate gap" (2,981 cells vs
`readTree`'s 2,982 kernel gates) was never an emitter property at all — it
compared a kernel `Circ` against a hand-shaped Verilog module of the same
function. There is no `emitS` defect and there never was.*

*The peephole argument below is unaffected: it is about `emitV` vs `emitS`
OUTPUT SHAPES, not about which file demonstrated them.* The historical claim
was: `emitV` emits `assign n5 = i0 & i1;` and produces **zero** cell
instances, so a peephole there cannot turn the first into the second: *it never
emits the input shape.* **The transform, the price and the safety argument are
all silicon's and all unchanged — only the file differs**, and it differs
because `emitS` is the emitter whose output the oracle describes.

✅ **The safety argument transfers verbatim.** `emitS`, like `emitV`, produces a
`String` and sits **outside `emitN_sem`**. `Gate`, `Netlist` and `emitN` are
untouched. ⇒ **A wrong peephole cannot make a false theorem. It makes a failing
proof** — and the importer expands `mux2_1` into *exactly* the four primitives a
`Circ` mux produces, so both Lean netlists still meet.

⛔ **THE SHARP EDGE, MEASURED BY SILICON AND OBEYED HERE: DO NOT CONSUME THE
`not`.** In their read tree the inverters are **SHARED — 5 of them across 992
muxes**, which is why the primitive tree is 2981 cells rather than 992×4.
**Only the two `and`s and the `or` are consumed, and only when each `and`'s
output is read exactly once.** *A peephole that ate a shared inverter would
corrupt every other mux using it.* The `not` becomes dead only if every one of
its users collapses, and that is `dce`'s job, not this one's. -/

/-- The op defining a net, if some gate defines it. -/
def opAt (c : Circ) (n : Net) : Option Op :=
  (c.gates.find? (fun g => g.out == n)).map Gate.op

/-- How many times a net is READ — by gate fanins and by the output list.
**The fanout guard depends on this counting outputs too**: a net driving a
module output is read even though no gate reads it. -/
def readCount (c : Circ) (n : Net) : Nat :=
  c.gates.foldl (fun acc g => acc + (g.op.fanin.filter (· == n)).length) 0
    + (c.outs.filter (· == n)).length

/-- A recognised 2:1 mux: `S` selects `a1`, else `a0`. `arm0`/`arm1` are the two
`and` outputs to be consumed. -/
structure MuxSite where
  a0 : Net
  a1 : Net
  sel : Net
  arm0 : Net
  arm1 : Net
  deriving Repr, DecidableEq

/-- Within one `and`, find the operand that is `not s` — trying BOTH orders —
and return the other operand as the data input. -/
private def armWithNot (c : Circ) (u v : Net) : Option (Net × Net) :=
  match opAt c v with
  | some (.not s) => some (u, s)
  | _ =>
    match opAt c u with
    | some (.not s) => some (v, s)
    | _ => none

/-- Within the other `and`, find the operand that IS `s`, both orders. -/
private def armWithSel (u v s : Net) : Option Net :=
  if u == s then some v else if v == s then some u else none

/-- `p` as the `S = 0` arm and `q` as the `S = 1` arm. -/
private def tryOrder (c : Circ) (p q : Net) : Option MuxSite :=
  match opAt c p, opAt c q with
  | some (.and pa pb), some (.and qa qb) =>
      match armWithNot c pa pb with
      | some (x, s) => (armWithSel qa qb s).map fun y => ⟨x, y, s, p, q⟩
      | none => none
  | _, _ => none

/-- **Recognise `or(and(x, not s), and(y, s))` as a mux.** All four commutation
orderings are covered: `armWithNot` and `armWithSel` each try both operands of
their `and`, and `tryOrder` is attempted in both directions of the `or`. -/
def muxAt (c : Circ) (g : Gate) : Option MuxSite :=
  match g.op with
  | .or p q =>
      if readCount c p == 1 && readCount c q == 1 then
        (tryOrder c p q).orElse fun _ => tryOrder c q p
      else none
  | _ => none

/-- **The structural module with the peephole applied.** Non-mux gates emit one
cell each exactly as `emitS`; a recognised site emits one `mux2_1` and its two
`and` gates are dropped. -/
def emitSMux (drive : String) (name : String) (c : Circ) : String :=
  let sites := c.gates.filterMap fun g => (muxAt c g).map fun m => (g.out, m)
  let cons  := sites.flatMap fun s => [s.2.arm0, s.2.arm1]
  let live  := c.gates.filter fun g => !(cons.contains g.out)
  let inPorts  := (List.range c.nIn).map fun i => "    input  wire " ++ sNet c.nIn i
  let outPorts := (List.range c.outs.length).map fun k => "    output wire o" ++ toString k
  let decls    := live.map fun g => "  wire " ++ sNet c.nIn g.out ++ ";"
  let dummies  := live.filterMap dummyDecl
  let body     := live.map fun g =>
    match sites.find? fun s => s.1 == g.out with
    | some (_, m) =>
        "  sky130_fd_sc_hd__mux2_1 " ++ instName g.out
          ++ " (.A0(" ++ sNet c.nIn m.a0 ++ "), .A1(" ++ sNet c.nIn m.a1
          ++ "), .S(" ++ sNet c.nIn m.sel ++ "), .X(" ++ sNet c.nIn g.out ++ "));"
    | none => emitCell drive c.nIn g
  let drives := (List.range c.outs.length).map fun k =>
    "  assign o" ++ toString k ++ " = " ++ sNet c.nIn (c.outs.getD k 0) ++ ";"
  "`default_nettype none\n\nmodule " ++ name ++ " (\n"
    ++ String.intercalate ",\n" (inPorts ++ outPorts) ++ "\n);\n"
    ++ slines decls ++ "\n" ++ slines dummies ++ "\n"
    ++ slines body ++ "\n" ++ slines drives
    ++ "\nendmodule\n\n`default_nettype wire\n"

/-- How many sites the peephole found — the number to compare against the
oracle's 2981 → 992. -/
def muxCount (c : Circ) : Nat := (c.gates.filterMap (muxAt c)).length

/-! ## The correspondence manifest — the artifact that makes the check mechanical

A structural netlist is only worth emitting if the thing that comes back can be
compared to the `Circ` **without** solving a graph-matching problem. This emits
the expected instance list: one line per gate, `<instance> <cell> <output-net>`.

⚠️ **It is an EXPECTATION, not a proof** — but the expectation is now MEASURED,
and it is stronger than I wrote here first.

**Silicon seat, 2026-08-07 06:30, TT CI run `31182129057`, all four jobs green:**
on a 40-cell structural 8-bit adder through the pinned flow, **all 49
instantiated cells came through EXACTLY — names, drives and counts** — and 8 of
9 named carry nets survived into the fabricated artifact (`carry[0]` was tied
low and correctly became a tie cell). Cutting at those nets gave **17 cones,
median 3, max 3, 100% inside the 24-bit ceiling**, against the RTL control's
**max 62 with no carry nets surviving at all**. The seat had *predicted* drive
resizing would destroy cell identity and reported that its own prediction was
wrong in the conservative direction.

⇒ **A manifest comparison may therefore be an EXACT diff at this scale**, not a
modulo-drive one. ⛔ **Do not carry that to CPU scale on this evidence.** 49
cells is not 5,000: drive resizing exists precisely for load, and a design with
real fanout may well see `_1` → `_2`. **The safe rule is: compare exactly, and
if it fails, check whether the difference is confined to drive suffixes before
concluding anything** — drive-strength invariance across the whole library was
measured the day before (428 cells, 127 multi-drive base names, **0** differing
functions), so a pure suffix difference is provably harmless.

📌 **What survives is what you NAME.** The silicon seat's finding is that named
nets are the certification boundary and they persist to the artifact — which is
why `sNet` and `instName` above are derived from the net number and nothing
else. **`(* keep *)` is not needed and does not help**: there is nothing for the
optimiser to re-derive, because the cells arrive already mapped and abc cannot
restructure through a blackbox. -/
def manifest (drive : String) (c : Circ) : String :=
  slines (c.gates.map fun g =>
    instName g.out ++ " " ++ cellOf drive g.op ++ " " ++ sNet c.nIn g.out)

/-- **The SEMANTIC cut manifest** — only the nets a design NAMES as boundaries.

⚠️ **`manifest` above lists EVERY gate, and the silicon seat measured why that is
useless as a cone test: with 159 cuts for 160 cells every cone is one gate deep,
so "max 2, 100%" is true BY CONSTRUCTION and tests nothing.** *That is a valid
decomposition — it reduces equivalence to gate-by-gate matching against the
cell-model theorems — but it is a DIFFERENT strategy from per-cone equivalence
and does not exercise the 24-bit ceiling at all.*

⇒ **This takes the design's own exported cut set** (`adder32Carries`,
`shifter32Cuts`, `aluSelectCuts`, `zeroTreeCuts`, `priorityEncCuts`, …) **and
emits only those**, so the cone census measures the decomposition the generator
actually intended. -/
def manifestCuts (drive : String) (c : Circ) (cuts : List Net) : String :=
  slines (cuts.filterMap fun n =>
    (c.gates.find? (fun g => g.out == n)).map fun g =>
      instName g.out ++ " " ++ cellOf drive g.op ++ " " ++ sNet c.nIn g.out)

/-! ## Axiom audit — every definition, per the iron rules -/

#audit_axioms cellOf
#audit_axioms sNet
#audit_axioms instName
#audit_axioms emitCell
#audit_axioms dummyDecl
#audit_axioms emitS
#audit_axioms opAt
#audit_axioms readCount
#audit_axioms MuxSite
#audit_axioms muxAt
#audit_axioms emitSMux
#audit_axioms muxCount
#audit_axioms manifest
#audit_axioms manifestCuts

end SaltWorks.HDL
