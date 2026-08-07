/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.Compose

/-!
# Adders and incrementers with NAMED per-slice carries

Emitter obligation ① of the silicon seat's survey: *name the carry chain, per
slice — adders **and incrementers**.*

## Why this is obligation ①, and why the incrementer is not an exemption

The silicon seat measured the same defeat four times, and its severity rose each
time: `(* keep *)` preserves the **net** and not the **dependency**.

| block | what survived | what happened |
|---|---|---|
| 32-bit ripple adder | all 33 carry nets | abc re-derived **every** carry as lookahead; `carry[12]` came back on 24 primary bits and **not** on `carry[11]` |
| register read | all 8 group nets | **one** bit routed around |
| ALU | all 10 op nets | **eight** bits routed around |
| fetch | four whole 32-bit vectors | the flop `D` pins read machine-named nets that **bypass all four** |

⇒ **RTL plus `keep` cannot deliver a carry decomposition.** Structural emission
can, because there is nothing left for the optimiser to re-derive — abc logs
`Extracted 0 gates` and cannot restructure through a blackboxed cell.

⚠️ **AND THE INCREMENTER IS NOT AN EXEMPTION — this is the refinement I would
have got wrong and the silicon seat measured instead of assuming.** `pc + 4`
came back at **max cone 30**, because `pc_plus_4[31]` depends on `pc[2..31]`:
***the carry ripples the whole way.*** An incrementer is a degenerate adder and
inherits the chain in full.

## The shape, and the number it must hit

One full-adder slice, five gates in the `Op` basis:

```
p = a ^ b            g = a & b
s = p ^ c            t = p & c            c' = g | t
```

**Cut at the carries, every cone is `{a[i], b[i], c[i]}` — three inputs**, which
is the silicon seat's measured `adder8s` figure of 3. Uncut, `sum[31]` depends on
the whole word and the cone is 65. *That gap is the entire value of naming the
chain, and both numbers are `#eval`-checked below rather than asserted.*

## What is NOT claimed here

**No theorem says these circuits add.** Correctness of the datapath against
`SaltWorks.ISA` belongs to the code generator's argument, not to a construction
file. *A generator producing the right cone shape and the wrong sum would pass
every check here — which is exactly how a 992-cell match to an oracle hid a
wrong leaf set this morning, and the lesson is cheaper to restate than to relearn.*
-/

namespace SaltWorks.HDL

/-! ## A 32-bit ripple-carry adder -/

/-- Word width. -/
def adW : Nat := 32

/-- `a` occupies nets `0 … 31`, `b` occupies `32 … 63`, `cin` is net `64`. -/
def adIn : Nat := 2 * adW + 1
def adA (i : Nat) : Net := i
def adB (i : Nat) : Net := adW + i
def adCin : Net := 2 * adW

/-- Five gates per slice, allocated from `adIn`. Slice `i` occupies
`adIn + 5*i … adIn + 5*i + 4`. -/
def adBase (i : Nat) : Nat := adIn + 5 * i
/-- `p = a ^ b`. -/
def adP (i : Nat) : Net := adBase i
/-- `s = p ^ c` — the sum bit. -/
def adS (i : Nat) : Net := adBase i + 1
/-- `g = a & b` — generate. -/
def adG (i : Nat) : Net := adBase i + 2
/-- `t = p & c` — propagate-and-carry. -/
def adT (i : Nat) : Net := adBase i + 3
/-- `c' = g | t` — **the named carry out of slice `i`**, and the net the cut
happens at. -/
def adC (i : Nat) : Net := if i == 0 then adCin else adBase (i - 1) + 4

/-- One full-adder slice. -/
def adSlice (i : Nat) : List Gate :=
  [⟨adP i, .xor (adA i) (adB i)⟩,
   ⟨adS i, .xor (adP i) (adC i)⟩,
   ⟨adG i, .and (adA i) (adB i)⟩,
   ⟨adT i, .and (adP i) (adC i)⟩,
   ⟨adBase i + 4, .or (adG i) (adT i)⟩]

/-- **A 32-bit ripple-carry adder.** Outputs are `sum[0..31]` then `cout`. -/
def adder32 : Circ :=
  { nIn := adIn
    gates := (List.range adW).flatMap adSlice
    outs := (List.range adW).map adS ++ [adC adW] }

/-- The carry nets — **the cut set**. This is the artifact the emitter owes: a
list of names the equivalence check can cut at, produced by construction rather
than recovered by pattern-matching a netlist. -/
def adder32Carries : List Net := (List.range adW).map fun i => adC (i + 1)

/-! ## A 32-bit incrementer — `pc + 4`

The silicon seat's refinement: this is **not** cheaper than an adder in cone
terms. `pc_plus_4[31]` depends on `pc[2..31]` because the carry ripples the whole
way, measured at **max 30**. Bits 0 and 1 are constant, which is why 30 and not
32, and the flow correctly turned them into tie cells. -/

/-- `pc` occupies nets `0 … 31`. -/
def incIn : Nat := adW
def incBase (i : Nat) : Nat := incIn + 2 * i
/-- `s = a ^ c`. -/
def incS (i : Nat) : Net := incBase i
/-- The carry out of slice `i`; slice 2 is where `+4` injects its one. -/
def incC (i : Nat) : Net := if i <= 2 then incBase 0 else incBase (i - 1) + 1

/-- Two gates per slice above bit 2; bits 0 and 1 pass through unchanged. -/
def incSlice (i : Nat) : List Gate :=
  if i < 2 then []
  else if i == 2 then
    -- carry-in to bit 2 is the constant 1, so sum = !a and carry = a
    [⟨incS i, .not i⟩, ⟨incBase i + 1, .and i i⟩]
  else if i + 1 == adW then
    -- TOP BIT: emit the sum only. The carry OUT of bit 31 is consumed by nothing
    -- (`inc32.outs` is bits 0..31), so emitting it produced a DEAD gate — which
    -- the silicon seat's 09:34 monolith run found as one of four dropped cells
    -- and generously attributed to its own wiring. It was mine.
    [⟨incS i, .xor i (incC i)⟩]
  else
    [⟨incS i, .xor i (incC i)⟩, ⟨incBase i + 1, .and i (incC i)⟩]

/-- **`pc + 4`.** Bits 0,1 are wired straight through. -/
def inc32 : Circ :=
  { nIn := incIn
    gates := (List.range adW).flatMap incSlice
    outs := [0, 1] ++ (List.range (adW - 2)).map fun k => incS (k + 2) }

/-! ## The measurements

`#eval`, not theorems, for the reason recorded in `ReadTree.lean`: these are
checks on a construction whose emitter is untrusted by design, and a kernel proof
about a cone count is not evidence about silicon. The evidence is that the flow
returns what was emitted. -/

/-- Transitive fanin over primary inputs, stopping at any net in `cut`. This is
the "sources per output bit" quantity in the silicon seat's corrected rule:
**a cone exceeds the ceiling iff (sources per output bit) + (select bits) > 24**. -/
partial def coneAt (c : Circ) (cut : List Net) (n : Net) : List Net :=
  let rec go (fuel : Nat) (seen : List Net) (todo : List Net) : List Net :=
    match fuel, todo with
    | 0, _ => seen
    | _, [] => seen
    | f + 1, x :: rest =>
        if seen.contains x then go f seen rest
        else if x < c.nIn || cut.contains x then go f (x :: seen) rest
        else match c.gates.find? (fun g => g.out == x) with
          | some g => go f seen (g.op.fanin ++ rest)
          | none   => go f seen rest
  go 100000 [] [n]

-- UNCUT: sum[31] depends on the whole word. Expect 65 = 32 a-bits + 32 b + cin.
#eval (coneAt adder32 [] (adS 31)).length

-- CUT AT THE CARRIES: every slice cone collapses to {a[i], b[i], c[i]} = 3,
-- which is the silicon seat's measured `adder8s` figure.  MEASURED: max 3.
#eval ((List.range adW).map fun i =>
        (coneAt adder32 adder32Carries (adS i)).length).foldl Nat.max 0

-- The carry cones themselves. ⚠️ The cut set must EXCLUDE the carry being
-- measured: rooting a cone AT a cut point makes the traversal stop on itself and
-- report 1. That is the silicon seat's `imem_addr` trap one level over — "the
-- cone of a register output is the register" — and my first version of this line
-- printed 1 for exactly that reason.  MEASURED: max 3.
#eval ((List.range adW).map fun i =>
        (coneAt adder32 (adder32Carries.filter (· != adC (i + 1))) (adC (i + 1))).length
      ).foldl Nat.max 0

-- THE INCREMENTER, UNCUT: pc_plus_4[31] on pc[2..31] = 30, the seat's figure.
#eval (coneAt inc32 [] (incS 31)).length

-- Gate counts: 5 per slice x 32 = 160; the incrementer 2 x 30 = 60.
#eval (adder32.gates.length, inc32.gates.length)


/-! ## Instantiability — the precondition for C4's assembly

*`instOK` requires `ssa`, not merely `wf`: under `wf` alone a circuit may have
sparse gate outputs and `instNext` under-reports the region it occupies
(`Compose.instNext_under_reports_without_ssa`). So `ssa` is what makes this organ
safe to embed in `core`, and `wf` then follows for free.* -/

theorem adder32_ssa : adder32.ssa = true := by decide +kernel

/-- **`wf` by the structural route** (160 gates). -/
theorem adder32_wf : adder32.wf = true := Circ.wf_of_ssa adder32_ssa

#audit_axioms adW
#audit_axioms adIn
#audit_axioms adA
#audit_axioms adB
#audit_axioms adCin
#audit_axioms adBase
#audit_axioms adP
#audit_axioms adS
#audit_axioms adG
#audit_axioms adT
#audit_axioms adC
#audit_axioms adSlice
#audit_axioms adder32
#audit_axioms adder32_ssa
#audit_axioms adder32_wf
#audit_axioms adder32Carries
#audit_axioms incIn
#audit_axioms incBase
#audit_axioms incS
#audit_axioms incC
#audit_axioms incSlice
#audit_axioms inc32

end SaltWorks.HDL
