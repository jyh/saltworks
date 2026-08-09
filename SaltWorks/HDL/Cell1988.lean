/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CompareExchangeC
import SaltWorks.HDL.Banyan

/-!
# ④ PIECE 2 + PIECE 5 — the 1988 rotating banyan cell, in `Seq`

`docs/heritage-1988-rotation-design-v1.md` §2, items **2** (cell denotation) and
**5** (the refinement bonus). Scope: **k = 3, 8 lines, the tapeout instance.**
No ∀-k, no ∀-P — every enumeration below runs over `List.range 8` destinations
and `List.range 3` stages, and that bound is in the statements, not in a comment.

## The mechanism, in one paragraph

The paper's banyan cell "routes on the first bit of the address, rotates the
first bit to the end of the address, and moves the rest up". The frame is
`[validity][address MSB-first][payload]`. So a cell reads its route bit from a
**fixed** position — the cycle right after the validity bit — and the address it
forwards is `rotate 1` of the address it received. Convention C (`ceC`,
`cFrame`) reaches the same bit by **timing** instead: stage `m`'s bit sits at
frame cycle `2s+1` where `s = k-1-m`, and nothing is rewritten.

## ⚠️ THE CAUSALITY FLOOR IS BUILT IN, NOT REDISCOVERED

`Seq.stepSeq` is strictly causal: cycle `t`'s output is a function of cycle
`t`'s input and cycle `t`'s state. And `List.rotate _ 1` moves the HEAD to the
TAIL, so the rotated stream's first bit is the ORIGINAL's second bit
(`ScratchR2ROT.lean`, kernel-checked, with a rotate-0 control). Therefore a
zero-delay bit-serial rotate-by-1 would have to emit a bit that has not
arrived.

⇒ **This cell's output frame is offset by EXACTLY ONE cycle from its input
frame, and the offset is written into every theorem** —
`cell88_rotates_with_one_cycle_offset` concludes
`out88 … = false :: rotFrame88 …`, with the leading `false` (both ports idle at
cycle 0) as the offset made visible rather than dropped by a `.drop 1`.

⇒ And the floor is proved as a **framework** theorem, not asserted about this
cell: `runTrace_prefix_causal` (any `Seq`, any initial state, any two traces
agreeing on a prefix ⇒ outputs agree on that prefix) and its corollary
`zero_offset_rotation_is_impossible` — **NO machine of ANY state width, from
ANY initial state, rotates at zero offset.** *That is the strongest form the
task's "show the zero-offset variant is false" admits: it is not a property of
my gates.*

## State width — what it is, and what I did NOT prove

`nState = 5`: three FSM bits, plus `prev` (the delayed bit) and `rt` (the
latched route bit, which **is** the wrapped bit — at rotate-1 the bit you hold
to wrap is exactly the bit you routed on, so one flop serves both).

⚠️ **The design block says "the 4 named FSM states PLUS storage for every
wrapped bit". At k = 3 the four names do not close: `route-latched` must count
out the remaining `k-1 = 2` address bits, and `locked-pass-with-rotation` has a
distinguished FIRST cycle (the one that emits the wrapped bit).** So the machine
below has **six** states — `IDLE, VSEEN, R1, R2, WRAP, LOCK` — mapping onto the
block's four names as `idle → IDLE`, `validity-seen → VSEEN`,
`route-latched → {R1,R2}`, `locked-pass → {WRAP,LOCK}`. **I did not prove six is
minimal** (that is a synthesis lower bound, not a `decide`), but
`cell88_rejects_early_wrap` shows the two-cycle pass window is load-bearing.

⚠️ **`ceC.nState = 4` vs `cell88.nState = 5` is NOT an apples-to-apples price.**
`ceC` is the 2-input compare-exchange element; `cell88` is ONE INPUT PORT'S
routing slice of a 2×2 banyan cell. The composed 2×2 cell is two slices —
10 state bits — and it is composed here at the semantic level
(`cell2x2`, the `Banyan.pick` claim-gated-OR structure), **not** as a single
`Circ`. Stated so no successor quotes "5 against 4" as a gate-level cost.

## What piece 5 could NOT be, and what it is

The design block first proposed stating piece 5 over `SaltWorks.Banyan.line`.
`line (m s d : ℕ) : ℕ := 2^m * (d / 2^m) + s % 2^m` is a **line-occupancy**
function: no route-bit argument, no route codomain. Not attempted. The ruled
re-founding is the **bit selector**, and `line`'s own arithmetic supplies the
bridge: `line m s d`'s bit `m` IS `d`'s bit `m`, because `s % 2^m < 2^m`
cannot reach bit `m` (`line_bit_m_is_dest_bit_m`, read-only — `Banyan/**`
untouched).

## ⭐ WHAT THIS FILE SETTLES, AND THE THREE PLACES IT CORRECTS THE DESIGN BLOCK

**④ pieces 2 and 5, at k = 3, in the existing `Seq` framework. Neither piece is
refuted: piece 2 is statable and true with the causality offset built in as exactly 1;
piece 5 is statable and true once re-founded over `Nat.testBit`.**

⛔ **(1) "FOUR NAMED FSM STATES" DOES NOT CLOSE AT k = 3 — it needs SIX.**
*`route-latched` must count out the remaining `k−1 = 2` address bits, and
`locked-pass` has a distinguished first cycle (the wrap emission). Six states, three
bits. `cell88_rejects_early_wrap` shows the two-cycle pass window is load-bearing.*

⛔ **(2) THE +1-CYCLE OFFSET **BUYS** THE ROUTING — it does not merely cost a cycle.**
*The validity bit leaves at cycle 1, in the same cycle its route bit `a₀` is on the
wire. A zero-offset cell would have to route the validity bit BEFORE its route bit
existed.* ⇒ ***So the price this block struck and I revived on causality grounds is not
a price at all: it is a REQUIREMENT of the design. `zero_offset_rotation_is_impossible`
proves it for EVERY `Seq` machine from EVERY initial state — a framework-level theorem,
strictly stronger than the `List.rotate` exhibits that motivated it.***

📌 **(3) AND MY OWN CAUSALITY-FLOOR CLAIM WAS ONE STEP TOO CRUDE.** *I required
`nState` sized for "the FSM states PLUS the wrapped bits". At rotate-1 the wrapped bit
IS the route bit, so ONE flop serves both — the storage is shared with the routing
latch, not additive to it.*

⚠️ **DO NOT QUOTE "5 AGAINST 4" AS A GATE-LEVEL PRICE.** *`cell88.nState = 5` is a
ONE-PORT SLICE; `ceC.nState = 4` is the two-input compare-exchange element. The composed
2×2 is ten bits. The comparison is not apples-to-apples and the file says so here rather
than letting a successor find the number and use it.*

⭐ **THE VACUITY GUARD IS THE METHODOLOGICAL POINT.** *`rotation_is_vacuous_at_d7`:
at `d = 7` the header is `[1,1,1]`, so `rotate 1` is the IDENTITY and a pure-delay cell
passes that fixture. A single-destination test would have proved nothing.
`rotation_is_real_at_d4` gives the teeth, and every statement here ranges over all eight
destinations for exactly that reason.*

⛔ **ONE THEOREM IN THE FIRST DRAFT WAS FALSE AND `decide` REFUTED IT** — a claim that a
back-to-back frame pair passes through unrotated. The audit caught the `sorryAx` in the
hole. The measured truth is sharper and is what landed: the FIRST frame rotates
correctly and only the SECOND degenerates, so the failure mode is per-frame rather than
global. *Both the error and the repair are left visible below.*
-/

namespace SaltWorks.HDL

/-! ## 1. THE CELL

Net layout of the core: `rst, inp` on `0,1`; state `s0,s1,s2,prev,rt` on `2…6`.
FSM value `v = s0 + 2·s1 + 4·s2`:

```
v=0 IDLE   out 0            ; inp=1 (validity) ⇒ VSEEN     prev' := inp
v=1 VSEEN  out = prev (=V)  ; ⇒ R1     rt' := inp  (the route bit, on the wire NOW)
v=2 R1     out = inp (a₁)   ; ⇒ R2
v=3 R2     out = inp (a₂)   ; ⇒ WRAP
v=4 WRAP   out = rt  (a₀)   ; ⇒ LOCK     -- the wrapped bit, one cycle late
v=5 LOCK   out = prev       ; ⇒ LOCK     -- payload, delayed by one
v=6,7      no indicator fires ⇒ out 0 and next state IDLE (self-healing)
```

📐 **Why the offset BUYS the routing rather than merely costing a cycle.** At
cycle 1 the cell emits the validity bit and the route bit `a₀` is on the input
wire *in that same cycle* — so `sel` is `inp` at VSEEN and the latched `rt`
afterwards. Without the one-cycle offset the validity bit would have to be
routed before its route bit existed. -/
def cell88core : Circ where
  nIn := 7
  gates :=
    [ ⟨7,  .not 0⟩        -- nr = ¬rst
    , ⟨8,  .and 2 7⟩      -- e0 = s0 ∧ nr   (rst forces the IDLE encoding)
    , ⟨9,  .and 3 7⟩      -- e1
    , ⟨10, .and 4 7⟩      -- e2
    , ⟨11, .not 8⟩        -- ¬e0
    , ⟨12, .not 9⟩        -- ¬e1
    , ⟨13, .not 10⟩       -- ¬e2
    , ⟨14, .and 12 13⟩    -- ¬e1 ∧ ¬e2
    , ⟨15, .and 11 14⟩    -- iIDLE   (v=0)
    , ⟨16, .and 8 14⟩     -- iVSEEN  (v=1)
    , ⟨17, .and 9 13⟩     -- e1 ∧ ¬e2
    , ⟨18, .and 11 17⟩    -- iR1     (v=2)
    , ⟨19, .and 8 17⟩     -- iR2     (v=3)
    , ⟨20, .and 12 10⟩    -- ¬e1 ∧ e2
    , ⟨21, .and 11 20⟩    -- iWRAP   (v=4)
    , ⟨22, .and 8 20⟩     -- iLOCK   (v=5)
    , ⟨23, .and 16 5⟩     -- iVSEEN ∧ prev
    , ⟨24, .or 18 19⟩     -- passWin = iR1 ∨ iR2
    , ⟨25, .and 24 1⟩     -- passWin ∧ inp        (the address bits, undelayed)
    , ⟨26, .and 21 6⟩     -- iWRAP ∧ rt           (⭐ THE WRAPPED BIT)
    , ⟨27, .and 22 5⟩     -- iLOCK ∧ prev
    , ⟨28, .or 23 25⟩
    , ⟨29, .or 28 26⟩
    , ⟨30, .or 29 27⟩     -- outVal
    , ⟨31, .not 16⟩       -- ¬iVSEEN
    , ⟨32, .and 16 1⟩     -- iVSEEN ∧ inp         (the route bit, live)
    , ⟨33, .and 31 6⟩     -- ¬iVSEEN ∧ rt         (the route bit, latched)
    , ⟨34, .or 32 33⟩     -- sel
    , ⟨35, .not 34⟩
    , ⟨36, .and 30 35⟩    -- outLo
    , ⟨37, .and 30 34⟩    -- outHi
    , ⟨38, .and 15 1⟩     -- iIDLE ∧ inp
    , ⟨39, .or 38 18⟩
    , ⟨40, .or 21 22⟩     -- iWRAP ∨ iLOCK
    , ⟨41, .or 39 40⟩     -- s0'
    , ⟨42, .or 16 18⟩     -- s1'
    , ⟨43, .or 19 40⟩     -- s2'
    , ⟨44, .and 6 7⟩      -- rt ∧ nr
    , ⟨45, .and 44 31⟩
    , ⟨46, .or 32 45⟩ ]   -- rt'
  outs := [36, 37, 41, 42, 43, 1, 46]   -- outLo, outHi, s0', s1', s2', prev', rt'

/-- **The 1988 rotating banyan cell, one input port's slice.** 2 primary inputs
(`rst`, `inp`), 2 primary outputs (low port, high port), 5 state bits. -/
def cell88 : Seq := { nIn := 2, nOut := 2, nState := 5, core := cell88core }

theorem cell88_wf : cell88.wf = true := by decide +kernel

theorem cell88_gate_count : cell88core.gates.length = 40 := by decide +kernel

/-- The declared widths. ⚠️ Read the header's warning before comparing with
`ceC.nState = 4`: `ceC` is a 2-input element, `cell88` is a 1-port slice. -/
theorem cell88_state_width : cell88.nState = 5 ∧ cell88.nIn = 2 ∧ cell88.nOut = 2 := by
  decide +kernel

/-! ## 2. THE FRAME LANGUAGE

`[validity][address MSB-first][payload]`, mirroring `cFrame`'s masking
discipline: the address bits are gated by validity (an idle line is silent
through the header), the payload is not. -/

/-- The address field, MSB first: `[bit 2, bit 1, bit 0]`. Masked by validity. -/
def addr88 (v : Bool) (d : Nat) : List Bool :=
  [v && d.testBit 2, v && d.testBit 1, v && d.testBit 0]

/-- The 1988 frame. -/
def frame88 (v : Bool) (d : Nat) (p : List Bool) : List Bool := (v :: addr88 v d) ++ p

/-- The frame a cell must FORWARD: validity and payload untouched, address
rotated head-to-tail. -/
def rotFrame88 (v : Bool) (d : Nat) (p : List Bool) : List Bool :=
  (v :: (addr88 v d).rotate 1) ++ p

/-- The all-zero initial state, used by the fixtures. `cell88_any_initial_state`
is what discharges the `∀ st₀` obligation. -/
def st88 : List Bool := [false, false, false, false, false]

/-- Drive the cell: the frame starts at cycle `o`, and `rst` pulses at cycle `o`
— the per-stage skewed strobe. -/
def drive88 (o : Nat) (f : List Bool) (len : Nat) : List (List Bool) :=
  (List.range len).map fun t => [t == o, f.getD t false]

/-- The forwarded stream: the content that leaves, on whichever port it leaves.
(Exactly one port is driven, so the `or` is a selection — the `Banyan.pick`
convention.) -/
def fwd88 (os : List (List Bool)) : List Bool :=
  os.map fun w => w.getD 0 false || w.getD 1 false

def raw88 (o : Nat) (f : List Bool) (len : Nat) : List (List Bool) :=
  (runTrace cell88 st88 (drive88 o f len)).1

def out88 (o : Nat) (f : List Bool) (len : Nat) : List Bool := fwd88 (raw88 o f len)

/-- The route decision, read AT THE PINS: the validity bit leaves at cycle
`o+1`; `true` iff it left on the high port. -/
def port88 (o : Nat) (f : List Bool) (len : Nat) : Bool :=
  ((raw88 o f len).getD (o + 1) []).getD 1 false

def pay88 : List Bool := [true, false]

/-! ## 3. THE ONE-CYCLE OBLIGATION — every state, every input

64 state/input configurations (5 state bits × 2 primary inputs). **No
reachability assumption**: the quantifier runs over all 32 states including the
two illegal FSM encodings. -/

/-- The word-level spec of one cycle, written from the FSM table rather than
from the gates. -/
def cell88SpecStep (s0 s1 s2 prev rt rst inp : Bool) : List Bool × List Bool :=
  let nr := !rst
  let e0 := s0 && nr
  let e1 := s1 && nr
  let e2 := s2 && nr
  let iIDLE  := !e0 && !e1 && !e2
  let iVSEEN :=  e0 && !e1 && !e2
  let iR1    := !e0 &&  e1 && !e2
  let iR2    :=  e0 &&  e1 && !e2
  let iWRAP  := !e0 && !e1 &&  e2
  let iLOCK  :=  e0 && !e1 &&  e2
  let outVal := (iVSEEN && prev) || ((iR1 || iR2) && inp) || (iWRAP && rt) || (iLOCK && prev)
  let sel    := (iVSEEN && inp) || (!iVSEEN && rt)
  ([outVal && !sel, outVal && sel],
   [ (iIDLE && inp) || iR1 || iWRAP || iLOCK
   , iVSEEN || iR1
   , iR2 || iWRAP || iLOCK
   , inp
   , (iVSEEN && inp) || ((rt && nr) && !iVSEEN) ])

def cell88StepOK : Bool :=
  bools.all fun s0 => bools.all fun s1 => bools.all fun s2 => bools.all fun prev =>
  bools.all fun rt => bools.all fun rst => bools.all fun inp =>
    stepSeq cell88 [s0, s1, s2, prev, rt] [rst, inp] == cell88SpecStep s0 s1 s2 prev rt rst inp

/-- ⭐ **ONE CYCLE, EVERY STATE, EVERY INPUT** — the obligation `ceC_step_eq`
carries for convention C, now carried for the 1988 cell. -/
theorem cell88_step_eq : cell88StepOK = true := by decide +kernel

/-! ## 4. ⭐ PIECE 2 — THE CELL ROTATES, AT AN OFFSET OF EXACTLY ONE CYCLE -/

/-- ⭐⭐ **PIECE 2, THE HEADLINE.** For every destination the 3-bit fabric can
carry: the forwarded stream is **one idle cycle followed by the rotated frame**.
Validity and payload verbatim, address `rotate 1`.

**The leading `false` IS the causality floor**, in the conclusion rather than a
comment: at cycle 0 the cell drives neither port, because the bit the rotated
frame wants at position 1 (`a₁`) has not arrived. -/
theorem cell88_rotates_with_one_cycle_offset :
    ((List.range 8).all fun d =>
      out88 0 (frame88 true d pay88) 7 == false :: rotFrame88 true d pay88) = true := by
  decide +kernel

/-- …and the offset is EXACTLY one, not merely at least one: cycle 0 is idle on
**both** ports (so nothing is hidden by `fwd88`'s `or`), and the frame is
complete by cycle 6. -/
theorem cell88_offset_is_exactly_one :
    ((List.range 8).all fun d =>
      ((raw88 0 (frame88 true d pay88) 7).getD 0 [] == [false, false])
        && ((out88 0 (frame88 true d pay88) 7).length == 7)) = true := by
  decide +kernel

/-- **The cell routes on the first address bit** — the bit in the FIXED position
right after validity, read off the pins. -/
theorem cell88_routes_on_first_address_bit :
    ((List.range 8).all fun d =>
      port88 0 (frame88 true d pay88) 7 == d.testBit 2) = true := by
  decide +kernel

/-- An invalid (idle) line is silent on both ports for the whole window — the
1988 analogue of `cFrame_idle_is_silent`. -/
theorem cell88_idle_is_silent :
    out88 0 (frame88 false 5 [false, false]) 7 = List.replicate 7 false := by
  decide +kernel

/-! ### `∀ st₀` — the power-gating quantifier, discharged

`Seq.lean`'s own doc: "a deselected TinyTapeout design is powered off, not merely
reset, so no flop state survives and `initial` is banned." -/

def stBits88 (i : Nat) : List Bool :=
  [i.testBit 0, i.testBit 1, i.testBit 2, i.testBit 3, i.testBit 4]

/-- ⭐ **ANY INITIAL STATE.** All 32 states × all 8 destinations: with one `rst`
pulse at the frame's first cycle, the forwarded stream is the rotated frame
regardless of what the flops held at power-up. -/
theorem cell88_any_initial_state :
    ((List.range 32).all fun i => (List.range 8).all fun d =>
      fwd88 (runTrace cell88 (stBits88 i) (drive88 0 (frame88 true d pay88) 7)).1
        == false :: rotFrame88 true d pay88) = true := by
  decide +kernel

/-! ### ⚠️ A LIMITATION, MEASURED RATHER THAN ASSERTED

The cell needs one `rst` pulse per frame — a frame boundary. The paper's own
control distribution is global strobes on a pipelined cell (§0; the
strobe-chain recollection is uncited and stays out), and the 2026 spec's frame
counter plays the same role. **Without a second pulse, a back-to-back second
frame is NOT rotated: the cell stays in `LOCK`, which is a pure one-cycle
delay.**

⛔ **THIS THEOREM'S FIRST FORM WAS FALSE AND `decide` SAID SO** — I wrote the
whole 12-bit stream as an unrotated pass-through, which understates the cell: the
FIRST frame is rotated correctly, and only the second degenerates. *Kept visible
because the corrected form is the sharper disclosure — the failure mode is
per-frame, not global.* -/
theorem cell88_second_frame_is_not_rotated_without_rst :
    out88 0 (frame88 true 5 pay88 ++ frame88 true 2 pay88) 13
      = false :: (rotFrame88 true 5 pay88 ++ frame88 true 2 pay88)
      ∧ rotFrame88 true 2 pay88 ≠ frame88 true 2 pay88 := by
  decide +kernel

/-! ## 5. NEGATIVE CONTROLS — MUTANTS

Each mutant is a gate-level patch of `cell88core`, its edit distance certified,
and each is REFUTED over the whole 8-destination range (not at one fixture). -/

/-- Replace the op driving net `n`. -/
def patchGate88 (n : Net) (o : Op) (c : Circ) : Circ :=
  { c with gates := c.gates.map fun h => if h.out == n then ⟨n, o⟩ else h }

/-! ### The vacuity control that must come FIRST -/

/-- ⛔ **A SINGLE FIXTURE AT `d = 7` WOULD PROVE NOTHING.** `rotate 1` is the
identity on `[1,1,1]`, so at `d = 7` the rotated frame IS the unrotated frame and
a pure-delay cell passes. *This is why every theorem above ranges over all eight
destinations, and it is the reason the `all` form is not decoration.* -/
theorem rotation_is_vacuous_at_d7 :
    rotFrame88 true 7 pay88 = frame88 true 7 pay88 := by decide +kernel

/-- …and it is genuinely non-trivial at `d = 4`, so the range statements have
teeth somewhere. -/
theorem rotation_is_real_at_d4 :
    rotFrame88 true 4 pay88 ≠ frame88 true 4 pay88 := by decide +kernel

/-! ### M1 — the wrapped bit is never re-emitted -/

def cell88NoWrapCore : Circ := patchGate88 26 (.and 21 5) cell88core
def cell88NoWrap : Seq := { cell88 with core := cell88NoWrapCore }

theorem cell88NoWrap_is_one_gate_from_cell88 :
    cell88NoWrapCore.gates.length = cell88core.gates.length
      ∧ (cell88NoWrapCore.gates.zip cell88core.gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

/-- ⛔ **REFUTED: emit `prev` instead of `rt` at WRAP and the rotation is wrong.**
One gate. *So the held bit is load-bearing — the cell is not "a delay that
happens to look rotated".* -/
theorem cell88_rejects_no_wrap :
    ((List.range 8).all fun d =>
      fwd88 (runTrace cell88NoWrap st88 (drive88 0 (frame88 true d pay88) 7)).1
        == false :: rotFrame88 true d pay88) = false := by
  decide +kernel

/-! ### M2 — rotation amount ZERO: the pure one-cycle delay -/

def cell88PureDelayCore : Circ :=
  patchGate88 25 (.and 24 5) (patchGate88 26 (.and 21 5) cell88core)
def cell88PureDelay : Seq := { cell88 with core := cell88PureDelayCore }

theorem cell88PureDelay_is_two_gates_from_cell88 :
    cell88PureDelayCore.gates.length = cell88core.gates.length
      ∧ (cell88PureDelayCore.gates.zip cell88core.gates).countP (fun p => p.1 != p.2) = 2 := by
  decide +kernel

/-- ⭐ **THE ROTATE-0 MUTANT, POSITIVELY CHARACTERISED.** Delay the address bits
too and the cell becomes a pure one-cycle pipeline: it forwards the frame
UNROTATED. *A positive characterisation is worth more than a bare `≠` — it says
exactly what the two gates buy: the rotation and nothing else.* -/
theorem cell88PureDelay_forwards_unrotated :
    ((List.range 8).all fun d =>
      fwd88 (runTrace cell88PureDelay st88 (drive88 0 (frame88 true d pay88) 7)).1
        == false :: frame88 true d pay88) = true := by
  decide +kernel

/-- ⛔ …and it therefore FAILS the rotation theorem. -/
theorem cell88_rejects_rotate_zero :
    ((List.range 8).all fun d =>
      fwd88 (runTrace cell88PureDelay st88 (drive88 0 (frame88 true d pay88) 7)).1
        == false :: rotFrame88 true d pay88) = false := by
  decide +kernel

/-! ### M3 — the wrapped bit emitted one cycle EARLY (a wrong rotation amount) -/

def cell88EarlyWrapCore : Circ :=
  patchGate88 24 (.or 18 18) (patchGate88 26 (.and 19 6) cell88core)
def cell88EarlyWrap : Seq := { cell88 with core := cell88EarlyWrapCore }

theorem cell88EarlyWrap_is_two_gates_from_cell88 :
    cell88EarlyWrapCore.gates.length = cell88core.gates.length
      ∧ (cell88EarlyWrapCore.gates.zip cell88core.gates).countP (fun p => p.1 != p.2) = 2 := by
  decide +kernel

/-- ⛔ **REFUTED: emit the held bit at the `k-1`th address slot instead of the
`k`th and the header is permuted but not rotated.** *This is the control on the
two-cycle pass window `{R1,R2}` — it is why the block's four named states do not
close at k = 3.* -/
theorem cell88_rejects_early_wrap :
    ((List.range 8).all fun d =>
      fwd88 (runTrace cell88EarlyWrap st88 (drive88 0 (frame88 true d pay88) 7)).1
        == false :: rotFrame88 true d pay88) = false := by
  decide +kernel

/-! ### M4 — the route bit read from the WRONG position (the piece-5 control) -/

def cell88SelR1Core : Circ := patchGate88 32 (.and 18 1) cell88core
def cell88SelR1 : Seq := { cell88 with core := cell88SelR1Core }

theorem cell88SelR1_is_one_gate_from_cell88 :
    (cell88SelR1Core.gates.zip cell88core.gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

/-- ⛔ **REFUTED: latch the route bit one cycle late and the routing decision is
wrong.** *The "fixed position right after the validity bit" is a real
constraint, not a description.* -/
theorem cell88_rejects_late_route_latch :
    ((List.range 8).all fun d =>
      (((runTrace cell88SelR1 st88 (drive88 0 (frame88 true d pay88) 7)).1).getD 1 []).getD 1 false
        == d.testBit 2) = false := by
  decide +kernel

/-! ### M5 — the delayed bit dropped -/

def cell88NoPrevCore : Circ := patchGate88 23 (.and 16 1) cell88core
def cell88NoPrev : Seq := { cell88 with core := cell88NoPrevCore }

theorem cell88NoPrev_is_one_gate_from_cell88 :
    (cell88NoPrevCore.gates.zip cell88core.gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

/-- ⛔ **REFUTED: emit `inp` instead of `prev` at VSEEN and the validity bit is
replaced by the route bit.** *Both stored bits are load-bearing; `nState = 5` is
not padding.* -/
theorem cell88_rejects_no_prev :
    ((List.range 8).all fun d =>
      fwd88 (runTrace cell88NoPrev st88 (drive88 0 (frame88 true d pay88) 7)).1
        == false :: rotFrame88 true d pay88) = false := by
  decide +kernel

/-! ## 6. ⭐ THE CAUSALITY FLOOR AS A FRAMEWORK THEOREM

Not a property of `cell88`. A property of `Seq`. -/

/-- ⭐ **STRICT CAUSALITY, PROVED IN THE FRAMEWORK.** Two input traces agreeing
on their first `n` cycles produce output traces agreeing on their first `n`
cycles — for **any** machine and **any** initial state. There is no lookahead in
`runTrace`, and this is the theorem that says so. -/
theorem runTrace_prefix_causal (m : Seq) (n : Nat) :
    ∀ (st : List Bool) (is js : List (List Bool)),
      is.take n = js.take n →
      (runTrace m st is).1.take n = (runTrace m st js).1.take n := by
  induction n with
  | zero => intro st is js _; simp
  | succ n ih =>
    intro st is js h
    match is, js with
    | [], [] => simp [runTrace]
    | [], _ :: _ => simp at h
    | _ :: _, [] => simp at h
    | i :: is, j :: js =>
      simp only [List.take_succ_cons, List.cons.injEq] at h
      obtain ⟨hij, h'⟩ := h
      subst hij
      have hb := ih (stepSeq m st i).2 is js h'
      simp only [runTrace, List.take_succ_cons, hb]

/-- ⭐⭐ **NO `Seq` MACHINE, OF ANY STATE WIDTH, FROM ANY INITIAL STATE, ROTATES
AT ZERO OFFSET.**

The witnesses are `d = 4` and `d = 6`: their frames agree on cycles 0–1 (both
`[V=1, a₀=1]`) and their *rotated* frames already differ at position 1
(`a₁ = 0` vs `1`). Strict causality forces equal outputs on cycles 0–1; a
zero-offset rotator would need them to differ. **The output lengths match the
rotated frames' lengths, so this refutes CONTENT, not arithmetic.**

⇒ *This is the causality floor `docs/heritage-1988-rotation-design-v1.md` piece 4
revived — restated so that it cannot be read as a defect of my gate choices.
`cell88` achieves offset exactly 1; this says 0 is unavailable to anyone.* -/
theorem zero_offset_rotation_is_impossible (m : Seq) (st : List Bool) :
    ¬ (fwd88 (runTrace m st (drive88 0 (frame88 true 4 []) 4)).1 = rotFrame88 true 4 []
     ∧ fwd88 (runTrace m st (drive88 0 (frame88 true 6 []) 4)).1 = rotFrame88 true 6 []) := by
  rintro ⟨h4, h6⟩
  have hd : (drive88 0 (frame88 true 4 []) 4).take 2
      = (drive88 0 (frame88 true 6 []) 4).take 2 := by decide
  have hc := runTrace_prefix_causal m 2 st _ _ hd
  have key : (rotFrame88 true 4 []).take 2 = (rotFrame88 true 6 []).take 2 := by
    rw [← h4, ← h6]
    simp only [fwd88, ← List.map_take, hc]
  exact absurd key (by decide)

/-! ## 7. THREE STAGES — THE HEADER HEALS, AND THE OFFSET ACCUMULATES

k = 3 stages, each strobed at its own frame-start cycle: the per-stage skew the
paper's 20-bit banyan traversal is about. Stage `s` is driven with `rst` at cycle
`s`, so the strobe chain is the skew. -/

/-- The chain of three cells, each fed the previous cell's forwarded stream. -/
def chain88 (f : List Bool) (len : Nat) : List Bool :=
  out88 2 (out88 1 (out88 0 f len) len) len

/-- ⭐⭐ **THE CAPTAIN'S THEOREM, AT THE ARTIFACT: after three stages the header
is RESTORED, and the frame is offset by exactly three cycles.** `rotate 1` applied
three times to a 3-bit address is the identity, and the *machines* exhibit it —
three real cells, gate by gate, for all eight destinations.

⚠️ **This is the k = 3 INSTANCE, not piece 1.** The general `rot^k = id` (three
ingredients incl. the address-length = k identification) is math's wave; nothing
here proves it. -/
theorem chain88_heals_with_three_cycle_offset :
    ((List.range 8).all fun d =>
      chain88 (frame88 true d pay88) 9
        == [false, false, false] ++ frame88 true d pay88) = true := by
  decide +kernel

/-- ⭐ **AND THE THREE ROUTE DECISIONS ARE THE ADDRESS, MSB FIRST** — read off the
pins of three distinct cells. Stage 0 routes on bit 2, stage 1 on bit 1, stage 2
on bit 0: the delta topology's `stage s consumes bit k-1-s`, realised. -/
theorem chain88_route_bits_are_msb_first :
    ((List.range 8).all fun d =>
      (port88 0 (frame88 true d pay88) 9 == d.testBit 2)
        && (port88 1 (out88 0 (frame88 true d pay88) 9) 9 == d.testBit 1)
        && (port88 2 (out88 1 (out88 0 (frame88 true d pay88) 9) 9) 9 == d.testBit 0)) = true := by
  decide +kernel

/-! ## 8. ⭐ PIECE 5 — THE TWO IMPLEMENTATIONS COMPUTE THE SAME BIT SELECTOR

`sel88At d s` is what the 1988 CELL decides when handed the header it would see
at traversal step `s` (`rotate s` of the address — the paper's own statement),
read off the machine's high-port pin. `selC d s` is the bit convention C's stage
reads by TIMING: frame cycle `2s+1` of `cFrame`, restated in
`CompareExchangeC.lean` from the bytes silicon's B4 adjudication quotes.

**Both equal `Nat.testBit d (2 - s)` = `Nat.testBit d m` at stage `m = k-1-s`,
which is the index convention `Banyan.claim` already uses (`(dest s).testBit m`
at stage `m`, stages descending `k-1 … 0`).** -/

/-- The header the 1988 cell receives at traversal step `s`. -/
def hdr88At (d s : Nat) : List Bool := true :: (addr88 true d).rotate s

/-- The 1988 cell's route decision at traversal step `s`, read at the pins. -/
def sel88At (d s : Nat) : Bool := port88 0 (hdr88At d s ++ [false, false]) 7

/-- Convention C's route bit for stage `m = 2 - s`: `cFrame` cycle `2s+1`. -/
def selC88 (d s : Nat) : Bool := (cFrame true d []).getD (2 * s + 1) false

/-- ⭐⭐ **PIECE 5.** For all eight destinations and all three stages: the 1988
cell's route decision, convention C's timed header bit, and `Nat.testBit d (2-s)`
are **one function of (destination, stage)**.

⇒ *Uniformity bought with data-mutation and uniformity bought with timing refine
the same mathematics — and the refinement is now a kernel fact about two
artifacts, not an analogy.* -/
theorem piece5_same_bit_selector :
    ((List.range 8).all fun d => (List.range 3).all fun s =>
      (sel88At d s == selC88 d s) && (sel88At d s == d.testBit (2 - s))) = true := by
  decide +kernel

/-- ⛔ **THE INDEX CONVENTION IS LOAD-BEARING.** `Nat.testBit d s` — the same
statement with the stage index NOT reflected — is FALSE. *So `2 - s` is content,
not notation, and piece 5 cannot be quoted as "both compute `testBit d s`".* -/
theorem piece5_index_convention_is_load_bearing :
    ((List.range 8).all fun d => (List.range 3).all fun s =>
      sel88At d s == d.testBit s) = false := by
  decide +kernel

/-- ⭐ **THE TIE TO `Banyan.line`, READ-ONLY.** `line m s d = 2^m·(d/2^m) + s%2^m`,
and `s % 2^m < 2^m` cannot reach bit `m` — so **bit `m` of the line number stage
`m` assigns IS bit `m` of the destination.** That is what "`line`'s own
arithmetic (`d / 2^m` keeping the high bits) encodes `testBit d m`" means,
checked over the whole k = 3 fabric (3 stages × 8 sources × 8 destinations).

⚠️ **NOT what the design block first asked for.** `line` has no route-bit
argument and no route codomain; a refinement OF `line` is not well-formed. This
is the bridge lemma the re-founding needs, and `SaltWorks/Banyan/**` is
untouched. -/
theorem line_bit_m_is_dest_bit_m :
    ((List.range 3).all fun m => (List.range 8).all fun s => (List.range 8).all fun d =>
      (SaltWorks.Banyan.line m s d).testBit m == d.testBit m) = true := by
  decide +kernel

/-! ## 9. THE COMPOSED 2×2 CELL — and the hypothesis B4 states in 1990

Two slices, per-port outputs OR-ed: the `Banyan.pick` claim-gated structure.
Composed at the SEMANTIC level, not as one `Circ` (disclosed in the header). -/

/-- Port `k` of the composed 2×2 cell. -/
def cell2x2 (k dA : Nat) (pA : List Bool) (dB : Nat) (pB : List Bool) : List Bool :=
  let a := (raw88 0 (frame88 true dA pA) 7).map fun w => w.getD k false
  let b := (raw88 0 (frame88 true dB pB) 7).map fun w => w.getD k false
  (List.range 7).map fun t => a.getD t false || b.getD t false

/-- ⭐ **THE 2×2 CELL ROUTES BOTH PACKETS** whenever their first address bits
differ — all 16 such destination pairs, both ports, rotated frames verbatim. -/
theorem cell2x2_routes_when_first_bits_differ :
    ((List.range 8).all fun dA => (List.range 8).all fun dB =>
      if !dA.testBit 2 && dB.testBit 2 then
        (cell2x2 0 dA pay88 dB [false, true] == false :: rotFrame88 true dA pay88)
          && (cell2x2 1 dA pay88 dB [false, true] == false :: rotFrame88 true dB [false, true])
      else true) = true := by
  decide +kernel

/-- ⛔ **AND IT COLLIDES WHEN THEY AGREE** — which is exactly why the 1990 chipset
puts a Batcher in front, and why the paper's regime is "internally non-blocking
for a **distinct** set of addresses". A concrete witness: `5` and `6` both want
the high port and the OR is neither frame. *The hypothesis is a hypothesis, and
here is the counterexample that makes it one.* -/
theorem cell2x2_collides_when_first_bits_agree :
    cell2x2 1 5 pay88 6 [false, true] ≠ false :: rotFrame88 true 5 pay88
      ∧ cell2x2 1 5 pay88 6 [false, true] ≠ false :: rotFrame88 true 6 [false, true] := by
  decide +kernel

/-! ## 10. WHAT IS NOT PROVED HERE — stated as unproved

* **Piece 1** (`rot^k = id` in general, with the address-length = k
  identification as a named premise): math's wave. `chain88_heals_with_three_cycle_offset`
  is the k = 3 instance only.
* **Piece 3** (the rotation invariant "header at stage m = rotate m (header at
  0)" under assumption A1): NOT proved. `hdr88At` *assumes* the rotated header as
  its input for the `sel88At` half of piece 5; the assumption-free half is
  `chain88_route_bits_are_msb_first`, where the headers come out of real cells.
  A1 (every traversed stage is a routing stage) is not needed here because
  `cell88` has no statically-passing mode — it is a network-level assumption.
* **Piece 4's ∀-D form**: only k = 3, offset 3, pinned at the tapeout instance.
  The symbolic-D statement is not attempted.
* **`∀ st₀` for the CHAIN**: proved for one cell over all 32 states
  (`cell88_any_initial_state`); the chain runs from `st88`. 32³ initial-state
  triples is not a `decide`, and there is no composition lemma here that lifts
  the single-cell result — so the chain theorems are all-zero-start.
* **Minimality of 6 FSM states / 5 state bits**: not proved. A synthesis lower
  bound, not an enumeration. `cell88_rejects_early_wrap` shows the pass window
  matters; it does not show no 4-state machine exists.
* **The 2×2 cell as a single `Circ`**, and its emission: composed semantically
  only.
* **Back-to-back frames without a per-frame `rst`**: NOT supported, and
  `cell88_second_frame_is_not_rotated_without_rst` measures the failure rather
  than hiding it.
* **Any timing number from the paper** (`d_N`, the 16/20 traversals): out of
  scope and deliberately absent. The offset here is a *causality* count in
  cycles of `stepSeq`, not a claim about 1.2μm silicon.
-/

#audit_axioms cell88core
#audit_axioms cell88
#audit_axioms cell88_wf
#audit_axioms cell88_gate_count
#audit_axioms cell88_state_width
#audit_axioms addr88
#audit_axioms frame88
#audit_axioms rotFrame88
#audit_axioms st88
#audit_axioms drive88
#audit_axioms fwd88
#audit_axioms raw88
#audit_axioms out88
#audit_axioms port88
#audit_axioms pay88
#audit_axioms cell88SpecStep
#audit_axioms cell88StepOK
#audit_axioms cell88_step_eq
#audit_axioms cell88_rotates_with_one_cycle_offset
#audit_axioms cell88_offset_is_exactly_one
#audit_axioms cell88_routes_on_first_address_bit
#audit_axioms cell88_idle_is_silent
#audit_axioms stBits88
#audit_axioms cell88_any_initial_state
#audit_axioms cell88_second_frame_is_not_rotated_without_rst
#audit_axioms patchGate88
#audit_axioms rotation_is_vacuous_at_d7
#audit_axioms rotation_is_real_at_d4
#audit_axioms cell88NoWrapCore
#audit_axioms cell88NoWrap
#audit_axioms cell88NoWrap_is_one_gate_from_cell88
#audit_axioms cell88_rejects_no_wrap
#audit_axioms cell88PureDelayCore
#audit_axioms cell88PureDelay
#audit_axioms cell88PureDelay_is_two_gates_from_cell88
#audit_axioms cell88PureDelay_forwards_unrotated
#audit_axioms cell88_rejects_rotate_zero
#audit_axioms cell88EarlyWrapCore
#audit_axioms cell88EarlyWrap
#audit_axioms cell88EarlyWrap_is_two_gates_from_cell88
#audit_axioms cell88_rejects_early_wrap
#audit_axioms cell88SelR1Core
#audit_axioms cell88SelR1
#audit_axioms cell88SelR1_is_one_gate_from_cell88
#audit_axioms cell88_rejects_late_route_latch
#audit_axioms cell88NoPrevCore
#audit_axioms cell88NoPrev
#audit_axioms cell88NoPrev_is_one_gate_from_cell88
#audit_axioms cell88_rejects_no_prev
#audit_axioms runTrace_prefix_causal
#audit_axioms zero_offset_rotation_is_impossible
#audit_axioms chain88
#audit_axioms chain88_heals_with_three_cycle_offset
#audit_axioms chain88_route_bits_are_msb_first
#audit_axioms hdr88At
#audit_axioms sel88At
#audit_axioms selC88
#audit_axioms piece5_same_bit_selector
#audit_axioms piece5_index_convention_is_load_bearing
#audit_axioms line_bit_m_is_dest_bit_m
#audit_axioms cell2x2
#audit_axioms cell2x2_routes_when_first_bits_differ
#audit_axioms cell2x2_collides_when_first_bits_agree

end SaltWorks.HDL
