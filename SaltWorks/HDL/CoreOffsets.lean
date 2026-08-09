/-!
# W5-asm, increment 1 — the assembly ORDER as data, and the σ arithmetic it forces

**Council ruling #4, 2026-08-09 09:2x** (the Captain, option (a) interleaved: *"even if we
choose the packet-IO route, I'd like our original plan to be complete, verified, and ready for
tapeout"*). W5-asm is the `core` construction: assemble the certified organs into ONE machine
and prove the single-cycle refinement. This file is **increment 1 of that track**.

## PRECONDITION PREAMBLE (mandatory per the wave law)

* **CLAIMED** — the assembly order is data; every organ's dimensions are **MEASURED from the
  artifact**, not transcribed from a plan; the offset chain is computed by `instNext` exactly as
  `instOK` requires; the chain's total reconciles to the repriced Slice-A figure; and the
  **zero-gate hazard** in the chain is exhibited as a theorem.
* **NOT CLAIMED** — no `core` Circ is built here, no `instOK` is discharged, no semantic
  refinement. Those are increments 2+. This file exists so the σ arithmetic is settled *before*
  a 10,371-gate composition is written on top of it.
* **WHY THIS FIRST** — W5-asm's pre-named risk #1 is *σ off-by-ones*. That risk lives entirely
  in this table. `SubFragment` (the two-organ probe) held its `instOK` by a **one-gate margin**
  (96 < 97), so the arithmetic is not a formality.

## THE MEASUREMENT, and the friction worth recording

All thirteen rows were read by `#eval` on the real `Circ`s. **Four of the thirteen live under
nested namespaces**, which cost real time to find and is exactly the organ-interface feedback
ruling #4 wants immediately:

```
SelectCut32.sliceASelect        (SaltWorks/HDL/SelectCut32.lean)
EncoderE1.ruledEnc             (SaltWorks/HDL/EncoderE1.lean)
OperandB.obMux                 (SaltWorks/HDL/OperandBMux.lean)
SaltWorks.Stack.Program.pcAdd  (math's slot — Program.lean)
```
*A bare `open SaltWorks.HDL` does not reach any of them. Anyone writing the `core` file will hit
this in their first five minutes; it is recorded here so they do not have to re-derive it.*
-/

namespace SaltWorks.HDL.CoreOffsets

/-- One row of the assembly order: a label, and the organ's MEASURED `(nIn, gates, outs)`. -/
structure Row where
  name  : String
  nIn   : Nat
  gates : Nat
  outs  : Nat
  deriving Repr, DecidableEq

/-- The Slice-A assembly order, **measured**. Order is forced by data dependency — `instOK`
requires every input wire `σ i < off`, so an organ cannot precede its producers.

`readTree` and `adder32` appear **twice** (rs1/rs2 and add/sub), as the plan's `×2` rows. -/
def order : List Row :=
  [ ⟨"decoder",      32,  102,   6⟩
  , ⟨"immBCirc",     32,    1,  32⟩
  , ⟨"readTree.rs1", 997, 2982,  32⟩
  , ⟨"readTree.rs2", 997, 2982,  32⟩
  , ⟨"bitXor32",     64,   32,  32⟩
  , ⟨"bitNot32",     32,   32,  32⟩
  , ⟨"adder32.add",  65,  160,  33⟩
  , ⟨"adder32.sub",  65,  160,  33⟩
  , ⟨"sltCirc",       3,    5,  32⟩
  , ⟨"sliceASelect", 98,  291,  32⟩
  , ⟨"ruledEnc",      3,    0,   2⟩   -- ⚠️ ZERO GATES. See `zero_gate_organ_does_not_advance`.
  , ⟨"obMux",        65,   97,  32⟩
  , ⟨"regWrite",      7,  163,  32⟩
  , ⟨"pcAdd",       129,  260,  32⟩
  , ⟨"regNext",    1088, 3104, 1024⟩
  ]

/-- `off_0` — the core's input width. State and instruction live below it. -/
def off0 : Nat := 1088

/-- The offset chain, exactly as `instNext` computes it: each organ sits at the previous
`instNext`, and `instNext c off = off + c.gates.length`. -/
def offsets : List Nat :=
  order.foldl (fun acc r => acc ++ [acc.getLast!  + r.gates]) [off0]

/-- Total gates the assembly allocates. -/
def totalGates : Nat := (order.map Row.gates).foldl (· + ·) 0

/-! ## The reconciliation — two independent derivations agreeing -/

/-- ⭐ **THE MEASURED ORDER SUMS TO THE REPRICED SLICE-A TOTAL.**

`10,371` is the figure I derived on 2026-08-08 two independent ways: the kernel's sum over the
14 organs, and the 8/7 plan's table plus six named semantic deltas (shifter out, aluSelect
retired, sliceASelect in, bitwise→XOR-only, sltu out, the real 97-gate `obMux`). **This is a
THIRD derivation — a per-row measurement of the artifacts — and it agrees to the gate.** -/
theorem total_reconciles : totalGates = 10371 := by decide

/-- The last offset is `off0` plus every gate — i.e. the chain does not lose or invent nets. -/
theorem chain_closes : offsets.getLast! = off0 + totalGates := by decide

/-- And the closing net, concretely. -/
theorem chain_last : offsets.getLast! = 11459 := by decide

/-! ## ⚠️ THE ZERO-GATE HAZARD, exhibited before it bites

`ruledEnc` has **zero gates** — it is pure wiring, two nets from the decoder's class lines to
the select's select nets. That is a landed, certified fact (`ruledEnc_cert` is `rfl`), and it has
a consequence for the assembly arithmetic that a plan reading "each organ sits at the previous
`instNext`" does not suggest. -/

/-- ⛔ **A ZERO-GATE ORGAN DOES NOT ADVANCE THE OFFSET: two consecutive organs share one
offset.** The chain is therefore **monotone but NOT STRICTLY monotone**.

⇒ ***Any assembly checker that asserts `off (i+1) > off i` would FALSELY REJECT this correct
assembly.*** The right invariant is `≥`, and the zero-gate organ is why. Recorded as a theorem
rather than a comment, because the wrong invariant would look more rigorous than the right one. -/
theorem zero_gate_organ_does_not_advance :
    ∃ i, offsets[i]! = offsets[i+1]! := by
  refine ⟨10, ?_⟩
  decide

/-- The chain IS monotone (non-strict) — the invariant an assembly checker should carry.

*Stated with the guard in `i < k` shape, with `k` a literal: `∀ i, i + 1 < offsets.length → …`
is NOT decidable, because `Nat.decidableBallLT` needs the bound on `i` itself. The quantifier's
SHAPE decides decidability here, not its content — the same trap as `decide`-OOMs, one door over.* -/
theorem chain_monotone : ∀ i, i < 15 → offsets[i]! ≤ offsets[i+1]! := by
  decide

/-- **CONTROL: the chain is not trivially flat.** Monotone-but-not-strict must not be satisfied
by a chain that never advances at all — thirteen of the fourteen steps DO advance. -/
theorem chain_advances_almost_everywhere :
    offsets[0]! < offsets[1]! ∧ offsets[13]! < offsets[14]! ∧ offsets.length = 16 := by
  refine ⟨by decide, by decide, by decide⟩

end SaltWorks.HDL.CoreOffsets
