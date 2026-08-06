/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Tactic.AuditAxioms

/-!
# `Circ` — the source language of the verified circuit compiler

A combinational circuit is a **straight-line program over named nets**: a list of
gates, each of which names the net it defines and the nets it reads, plus a list
of primary outputs in port order.

## Why this carrier, and not the one the freeze named

`docs/hdl-design-v1.md:11-12` specified "let-bound nets (a DAG, not a tree)" with
"width-indexed buses as `Vector` of nets". The refuter pass
(`docs/hdl-refuter-0806.md`) changed two of those three choices and confirmed the
third:

* **A DAG, yes** — confirmed, and for the freeze's reason once it is corrected.
  Sharing is *not* needed to make kernel evaluation cheap (the kernel memoises
  `whnf`, so identical subterms are already shared); it is needed because a tree
  printer emits one assignment per *unfolding*, and because `opt` and the leg-3
  seam need something to *name*.
* **Gates name their own output net**, rather than being numbered by position.
  This is the change that makes dead-net elimination a `List.filter` — no
  renumbering, no index-shifting lemma, and no well-formedness hypothesis in the
  DCE theorem.
* **The environment is a total function `Net → Bool`**, never a list. The
  measured rule from the pass is *never an append-extended environment*: a
  `env ++ [v]` per gate is O(g²) and it is the single most expensive mistake
  available here.

Well-formedness is **extrinsic and decidable** (`Circ.wf`), not carried in the
type. Intrinsic well-formedness would put proofs inside the data, which the
kernel must then re-check on every certificate; a `Bool`-valued predicate with a
soundness lemma keeps the data small and the certificates cheap.
-/

namespace SaltWorks.HDL

/-- A net name. Nets `0 ..< nIn` are the primary inputs; every other net is
defined by exactly one gate. -/
abbrev Net := Nat

/-- A gate's operation, over the nets it reads. -/
inductive Op where
  | const (b : Bool)
  | not   (a : Net)
  | and   (a b : Net)
  | or    (a b : Net)
  | xor   (a b : Net)
  deriving Repr, DecidableEq, Inhabited

/-- The nets an operation reads. -/
def Op.fanin : Op → List Net
  | .const _ => []
  | .not a   => [a]
  | .and a b => [a, b]
  | .or  a b => [a, b]
  | .xor a b => [a, b]

/-- One gate: the net it defines, and how. -/
structure Gate where
  out : Net
  op  : Op
  deriving Repr, DecidableEq, Inhabited

/-- A combinational circuit: `nIn` primary inputs, a straight-line gate list, and
the primary outputs **in port order**.

Port order is part of the data, not a convention. The refuter pass found
port-order blindness to be one of three vacuity modes available to the
certificate suite — a certificate over a commutative module passes unchanged
with its input buses swapped — so the order a certificate pins must be the order
the emitted Verilog declares. -/
structure Circ where
  nIn   : Nat
  gates : List Gate
  outs  : List Net
  deriving Repr, DecidableEq, Inhabited

/-- The nets defined before any gate runs: the primary inputs. -/
def Circ.inputs (c : Circ) : List Net := List.range c.nIn

/-- Every net the circuit defines, inputs first. -/
def Circ.defined (c : Circ) : List Net :=
  c.gates.foldl (fun acc g => g.out :: acc) c.inputs

/-- `no net is defined twice`, as a `Bool`. -/
def nodupB : List Net → Bool
  | []      => true
  | n :: ns => !(ns.contains n) && nodupB ns

/-- Each gate reads only nets already defined. `defined` is threaded as a
**prepend**-list: the append-extension trap the refuter pass measured applies to
well-formedness checking exactly as it applies to evaluation. -/
def wfGates (defined : List Net) : List Gate → Bool
  | []      => true
  | g :: gs => g.op.fanin.all defined.contains && wfGates (g.out :: defined) gs

/-- A circuit is well-formed when every gate reads only already-defined nets,
every output net is defined, no net is defined twice, and no gate redefines a
primary input.

Decidable by construction — this is a `Bool`, so a concrete circuit's
well-formedness is discharged by `decide +kernel` rather than by a proof. -/
def Circ.wf (c : Circ) : Bool :=
  wfGates c.inputs c.gates
    && c.outs.all c.defined.contains
    && nodupB (c.gates.map Gate.out)
    && c.gates.all (fun g => c.nIn ≤ g.out)

/-! ## A worked example, kernel-checked

The smallest circuit that exercises every field: two inputs, a shared subterm
(net 2 is read twice — the DAG the doc's line 11 is about), and two outputs. -/

/-- Half adder: `sum = a ^^^ b`, `carry = a &&& b`. Net 2 is `a ^^^ b`; note it
is *not* recomputed for the second output. -/
def halfAdder : Circ where
  nIn   := 2
  gates := [⟨2, .xor 0 1⟩, ⟨3, .and 0 1⟩]
  outs  := [2, 3]

example : halfAdder.wf = true := by decide +kernel

#audit_axioms Op.fanin Circ.defined wfGates Circ.wf nodupB

end SaltWorks.HDL
