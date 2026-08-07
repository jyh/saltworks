/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.Compose

/-!
# A 32-bit barrel shifter — a LOG shifter with named stage boundaries

Emitter obligation ② of the silicon seat's survey: *name the mux-tree levels
(register read, barrel shifts).*

## Why this is not `readTree`, and why that is the finding

The silicon seat's survey priced shifts through the register-read shape —
*"shifts as trees 11 (`readtree` — a barrel shifter is the SAME 32:1-select shape
as a register read)"*. **That is true of the FUNCTION and false of the best
STRUCTURE, and the difference is 6× in cells.**

A register read genuinely selects among 31 unrelated registers: bit `k` of the
output can come from bit `k` of any of them, and there is no relation between the
choices for different `k`. **A shift is not like that.** Every output bit takes
the *same* displacement, so the choice is shared across the whole word — which is
exactly what a **log shifter** exploits:

```
stage j :  out[i]  =  shamt[j] ? in[i + 2^j] : in[i]        (0 if out of range)
```

Five stages of 32 two-input muxes, and the shift amount's five bits each steer
one whole stage.

| shape | muxes | cells (primitive) | treated cone |
|---|---:|---:|---:|
| 32:1 select per bit, `readTree` shape | 992 | 2982 | 11 |
| **5-stage log shifter, this file** | **160** | **~485** | **measured below** |

⇒ **6.2× fewer muxes for the same function**, and the cut set is five stage
boundaries instead of a per-bit tree. *The silicon seat's rule still governs —
sources per output bit plus select bits — and a log stage has two sources and one
select bit, which is as small as a mux can be.*

## What must be named

The cut set is `bsStageOuts j` — **the 32 outputs of stage `j`**. Cutting there
makes every cone `{prev[i], prev[i + 2^j], shamt[j]}`. Uncut, output bit 0
reaches every input and the cone is 37 (32 data + 5 shift), which is over the
24-bit ceiling and is why the naming is required rather than merely tidy.

## What is NOT claimed

**No theorem says this shifts.** As in `Adder.lean` and `ReadTree.lean`, the
functional obligation belongs to the code generator's correctness argument. *This
file establishes the cone shape and the cell count and nothing else — and a
construction with the right cone shape and the wrong function passes every check
here.*
-/

namespace SaltWorks.HDL

/-- Word width and the five stages that address it. -/
def bsW : Nat := 32
def bsStages : Nat := 5

/-- `in` occupies nets `0 … 31`; `shamt` occupies `32 … 36`. -/
def bsIn : Nat := bsW + bsStages
def bsShamt (j : Nat) : Net := bsW + j

/-- The shared constant-zero shifted in at the top. One gate, as with `x0`. -/
def bsZero : Net := bsIn
/-- The inverter for stage `j`'s select bit — **one per stage, shared by all 32
muxes in it**, exactly as the read tree shares one per address bit. -/
def bsNot (j : Nat) : Net := bsIn + 1 + j

/-- Gates start above the tie cell and the five inverters. Stage `j` bit `i`
occupies three nets from `bsBase j i`. -/
def bsBase (j i : Nat) : Nat := bsIn + 1 + bsStages + (j * bsW + i) * 3
/-- The output of stage `j`, bit `i` — **the named boundary**. -/
def bsOut (j i : Nat) : Net := bsBase j i + 2

/-- What stage `j` reads for bit `i`: stage 0 reads the inputs, later stages read
the previous stage, and anything past the top reads the shared zero. -/
def bsPrev (j i : Nat) : Net :=
  if i ≥ bsW then bsZero
  else if j == 0 then i
  else bsOut (j - 1) i

/-- One mux of stage `j`, bit `i`: `shamt[j] ? prev[i + 2^j] : prev[i]`. -/
def bsMux (j i : Nat) : List Gate :=
  let lo := bsPrev j i
  let hi := bsPrev j (i + 2 ^ j)
  [⟨bsBase j i,     .and lo (bsNot j)⟩,
   ⟨bsBase j i + 1, .and hi (bsShamt j)⟩,
   ⟨bsOut j i,      .or (bsBase j i) (bsBase j i + 1)⟩]

/-- **A 32-bit logical right barrel shifter.** -/
def shifter32 : Circ :=
  { nIn := bsIn
    gates :=
      (⟨bsZero, .const false⟩ : Gate)
        :: (List.range bsStages).map (fun j => (⟨bsNot j, .not (bsShamt j)⟩ : Gate))
        ++ (List.range bsStages).flatMap (fun j => (List.range bsW).flatMap (bsMux j))
    outs := (List.range bsW).map (bsOut (bsStages - 1)) }

/-- The cut set: **every stage boundary**, produced by construction so the
equivalence check never has to guess where a boundary was intended. -/
def shifter32Cuts : List Net :=
  (List.range bsStages).flatMap fun j => (List.range bsW).map (bsOut j)

/-! ## The measurements -/

/-- Transitive fanin over primary inputs, stopping at `cut`. Same instrument as
`Adder.lean`. ⚠️ **A root that is itself in `cut` reports only itself** — the cut
point's cone is the cut point — so callers measuring a boundary must exclude it
from its own cut set. -/
partial def bsCone (c : Circ) (cut : List Net) (n : Net) : List Net :=
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

-- UNCUT: bit 0 reaches every input. Expect 37 = 32 data + 5 shift. OVER the ceiling.
#eval (bsCone shifter32 [] (bsOut 4 0)).length

-- CUT AT EVERY STAGE BOUNDARY, each boundary excluded from its own cut set.
-- Expect 3 = {prev[i], prev[i+2^j], shamt[j]}.  MEASURED: max 3.
#eval ((List.range bsStages).flatMap fun j =>
        (List.range bsW).map fun i =>
          (bsCone shifter32 (shifter32Cuts.filter (· != bsOut j i)) (bsOut j i)).length
      ).foldl Nat.max 0

-- Cells, against the readTree shape's 992 muxes / 2982 gates for the same function.
#eval (shifter32.gates.length, muxCount shifter32)


/-! ## Instantiability — the precondition for C4's assembly

*`instOK` requires `ssa`, not merely `wf`: under `wf` alone a circuit may have
sparse gate outputs and `instNext` under-reports the region it occupies
(`Compose.instNext_under_reports_without_ssa`). So `ssa` is what makes this organ
safe to embed in `core`, and `wf` then follows for free.* -/

theorem shifter32_ssa : shifter32.ssa = true := by decide +kernel

/-- **`wf` by the structural route** (486 gates). -/
theorem shifter32_wf : shifter32.wf = true := Circ.wf_of_ssa shifter32_ssa


/-! ## 🔨 OWED: ROUTE ② — this organ gains a MODE. Silicon's ruling, `9788792`.

**`sll`/`sra` had no producer; I asked silicon to rule and deliberately did not
act.** *They ruled **route ② — generalise this organ with a mode** — at 679 gates
against 1,458 for three separate organs, ONE certificate suite against three,
and **`sra` free**.* `docs/silicon-shifter-mode-ruling-0807.md`.

⛔ **AND THEY REFUTED MY PREMISE AT THE BYTES, WHICH IS WHY THE RULING WENT THE
OTHER WAY.** *I argued route ② "edits a landed certified block that may already
be fabricated."* **Both halves false, and both were one command away:**
`SaltWorks/Silicon/Imported/` holds no Shifter (only Comparator, CompareExchange,
CompareExchangeC, Fabric, FabricCut, RefComparator, Switch); the sole `shifter32`
under `Silicon/` is an RTL *instantiation*, not a hardened artifact; and TTSKY26c
closes 2026-09-07 with nothing submitted. ⇒ ***I hedged where I could have
checked, and a hedge is not caution when the fact is cheap — it is a way of not
looking.***

⭐ **THE MEASUREMENT THAT MAKES `sra` FREE, and it is the elegant part:** all
**31** sites where `bsPrev` falls through to the fill read **ONE distinct net** —
the shared tie cell. *So arithmetic fill replaces `⟨bsZero, .const false⟩` with
`⟨bsZero, .and sraMode in31⟩`, which is still constant zero when `sraMode` is
low.* ⇒ **`srl` is unchanged BY CONSTRUCTION rather than by proof, and the net
cell delta for `sra` is ZERO.**

### The six obligations — silicon's acceptance criteria, not my summary

```
1  shifter32Cuts and the cone measurement are INVALIDATED -- the reversal banks
   add two boundaries.  RE-MEASURE, do not re-assume.  The <=24 claim must be
   re-run, not inherited.
2  nIn 37 -> 39 moves every sigma offset downstream in the C4 assembly plan's
   section 4.  This seat owns that wiring.
3  the plan's line 8 and BOTH totals regenerate: 1,458 -> 679, subtotal
   11,038 -> 10,259, estimate ~12,700 -> ~11,921.
4  CERTIFY sll AGAINST BitVec's <<<, NEVER against a reversal identity.
5  Shifter.lean is IN the hub closure -- land it as ONE green write.
6  aluSelect drops from 10 sources to 8.  Silicon publishes NO number for it,
   having not measured the per-source cost.
```

🔴 **OBLIGATION 4 IS AIMED AT ME AND IT LANDS.** *A proof that
`reverse (srl (reverse w) s)` equals itself is a proof about the CONSTRUCTION,
not about shifting.* **That is precisely the hole this seat's 14:59 census was
about — organs never shown to DO anything — and the reversal encoding is the
shape most likely to reintroduce it.** ⇒ ***`bsOK` above is the template: check
against `BitVec`'s own operator, never against the implementation restated.***

📌 **AND OBLIGATION 6 IS SILICON DECLINING TO INVENT A COEFFICIENT** — they name
a real second-order saving and publish no number because they have not measured
`aluSelect`'s per-source cost. *The same refusal this seat made at 12:5x, handed
back.* -/

/-! ## ⭐ DOES IT SHIFT? — the behavioural certificate this file did not have

**Before today this file carried NO theorems.** *A 486-gate log shifter whose
docstring gives one equation, and nothing checked that the gates implement it.*

⚠️ **AND THE CERTIFICATE PINS THE FACT THAT MATTERS FOR `core`: THIS IS ONE
DIRECTION, LOGICAL.** `nIn = 37 = 32 data + 5 shamt` — **no mode bit.** *So
`aluSelect`'s `srl` slot is fed by this; its `sll` and `sra` slots have no
producer, which is the open decision in the C4 assembly plan.* -/

/-- Data on nets `0…31`, shift amount on `32…36`. -/
def bsEnv (w : BitVec 32) (s : Nat) : Env := fun n =>
  if n < bsW then w.getLsbD n else s.testBit (n - bsW)

/-- The shifter agrees with `BitVec`'s own `>>>` at every shift amount. -/
def bsOK (w : BitVec 32) : Bool :=
  (List.range 32).all fun s =>
    sem shifter32 (bsEnv w s) == (List.range 32).map (fun k => (w >>> s).getLsbD k)

/-- ⭐ **IT IS A LOGICAL RIGHT SHIFT — all 32 shift amounts, against `BitVec`'s
own operator.** -/
theorem shifter32_is_a_right_shift_on_sample : bsOK 0xDEADBEEF = true := by decide +kernel

/-- A second word, so the first is not passing on a pattern's symmetry. -/
theorem shifter32_second_word_on_sample : bsOK 0x0F0F1234 = true := by decide +kernel

#audit_axioms bsW
#audit_axioms bsStages
#audit_axioms bsIn
#audit_axioms bsShamt
#audit_axioms bsZero
#audit_axioms bsNot
#audit_axioms bsBase
#audit_axioms bsOut
#audit_axioms bsPrev
#audit_axioms bsMux
#audit_axioms shifter32
#audit_axioms shifter32_ssa
#audit_axioms shifter32_wf
#audit_axioms bsEnv bsOK
#audit_axioms shifter32_is_a_right_shift_on_sample
#audit_axioms shifter32_second_word_on_sample
#audit_axioms shifter32Cuts

end SaltWorks.HDL
