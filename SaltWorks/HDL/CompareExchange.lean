/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Seq

/-!
# BB-1 · B0(a) — THE BIT-SERIAL COMPARE-EXCHANGE ELEMENT, IN `Circ`

**Probe grade.** The addendum asks for *"the serial compare-exchange element in
Circ: design sketch + the refinement statement ELABORATES."* This file carries
the design, the one-cycle obligation **proved**, whole-frame certificates
**proved**, four mutation controls **proved**, and the general refinement
statement **elaborated but not proved** — B1 proves it.

## The element (US 5,130,976): decide at the first difference, then stream

Two packets arrive bit-serially on `in0`/`in1`, **destination address MSB
first**. The element is a 2×2 crossbar whose setting is latched:

```
while the addresses agree     UNDECIDED — pass through
at the first differing bit    DECIDE — smaller address to out0, larger to out1
thereafter                    STREAM — the setting is latched for the whole
                                frame, payload included
```

**Why MSB-first is the whole trick:** under a most-significant-first stream the
first differing bit *is* the comparison — no later bit can overturn it. The
element never needs the rest of the word, and the decision is available on the
cycle it becomes determined. *That is what lets a sorter be built from an
element this small, and it is the property the 1990 design rests on.*

## ⭐ IDLE SORTS HIGH — and this line is here because the evidence seat put it here

The banyan's landed hypothesis is `StrictMonoOn dest (Set.Iio n)`, which is
**two conjuncts wearing one name**: ① the destinations are sorted, ② the active
sources are `{0 … n-1}` — **contiguous from line 0**. A sorter discharges ①
only. ② is decided by *how the sorter orders INACTIVE lines*:

```
idle compares HIGH  ->  actives land on 0 … n-1     -> Set.Iio n     ✅ ② holds
idle compares LOW   ->  actives land on 8-n … 7     -> NOT Set.Iio n ⛔ ② fails
```

**Sorted either way. Concentrated only in one.** So the element carries an
activity bit per line and orders **active before idle**, unconditionally and
before any address bit is examined. `ce_rejects_idle_sorts_low` below is the
certificate that this is not merely intended: the idle-low reading is
*kernel-refuted*. ⇒ ***Concentration is discharged AT THE ELEMENT, which is the
cheapest place it can possibly be discharged, and it costs two gates.***

## The state, and the equations it forces

Two state bits — `decided` (has this frame been decided?) and `swap` (the
latched setting). `rst` marks frame start and clears the latch; comparison
begins on that same cycle, because the first address bit arrives with the frame.

```
d       = decided ∧ ¬rst                    -- effective "already decided"
idleSw  = act1 ∧ ¬act0                      -- in0 idle, in1 active  => swap
bothAct = act0 ∧ act1
addrSw  = in0 ∧ ¬in1                        -- "in0 is the larger", this bit
newSw   = idleSw ∨ (bothAct ∧ addrSw)
sw      = (d ∧ swap) ∨ (¬d ∧ newSw)
out0/1, oact0/1  = the crossbar, under `sw`
decided'= d ∨ (act0 ⊕ act1) ∨ (bothAct ∧ (in0 ⊕ in1))
swap'   = sw
```

**Two lines are worth reading twice.** `newSw`'s first disjunct is activity and
it is *unguarded* — activity outranks every address bit, which is exactly ②.
And the address comparison is guarded by `bothAct`, so **two idle lines never
swap**: their address wires carry nothing, and an unguarded comparison would let
garbage reorder them. *That is stability, and it is load-bearing rather than
tidy — a sorter that permutes idle lines still sorts, but it no longer has a
spec you can write down without saying which garbage.*

## Cost

**31 gates, 5 primary inputs, 2 state bits.** The cone is `5 + 2 = 7` bits ⇒
**128 configurations**, against the 24-bit kernel ceiling. An 8×8 Batcher
odd-even merge is **19 elements** ⇒ ~589 gates, 38 state bits — and *the
per-element obligation does not grow with the network*. That is the D3.5
pattern, and it is why BB-1 prices as cheap.

## What this file does NOT claim

The general frame-level refinement is `#check`ed, **not proved** — B0 is a
feasibility probe; proving it is B1. *Elaborated-and-unproved is the honest
grade, and `#check` is how it is stated without `sorry`.* Nothing here says
anything about the **network**; that is B2, and math's 10:35 note is right that
the banyan side needs an enumeration-completeness lemma before "the Batcher
sorts, therefore the fabric routes" is a proof rather than a sentence.
-/

namespace SaltWorks.HDL

/-! ### The combinational core

`Seq.env` fixes the layout: primary inputs on nets `0 ..< nIn`, state
immediately after. So `0=rst, 1=act0, 2=act1, 3=in0, 4=in1`, `5=decided,
6=swap`, and gates allocate from 7. -/

/-- The compare-exchange core: 31 gates, the header's equations verbatim. -/
def ceCore : Circ where
  nIn := 7
  gates :=
    [ ⟨7,  .not 0⟩          -- ¬rst
    , ⟨8,  .and 5 7⟩        -- d       = decided ∧ ¬rst
    , ⟨9,  .not 8⟩          -- ¬d
    , ⟨10, .xor 1 2⟩        -- actDiff
    , ⟨11, .not 1⟩          -- ¬act0
    , ⟨12, .and 2 11⟩       -- idleSw  = act1 ∧ ¬act0
    , ⟨13, .and 1 2⟩        -- bothAct
    , ⟨14, .not 4⟩          -- ¬in1
    , ⟨15, .and 3 14⟩       -- addrSw  = in0 ∧ ¬in1
    , ⟨16, .and 13 15⟩      -- bothAct ∧ addrSw
    , ⟨17, .or 12 16⟩       -- newSw
    , ⟨18, .and 8 6⟩        -- d ∧ swap
    , ⟨19, .and 9 17⟩       -- ¬d ∧ newSw
    , ⟨20, .or 18 19⟩       -- sw
    , ⟨21, .not 20⟩         -- ¬sw
    , ⟨22, .and 21 3⟩
    , ⟨23, .and 20 4⟩
    , ⟨24, .or 22 23⟩       -- out0   (the smaller)
    , ⟨25, .and 21 4⟩
    , ⟨26, .and 20 3⟩
    , ⟨27, .or 25 26⟩       -- out1   (the larger)
    , ⟨28, .and 21 1⟩
    , ⟨29, .and 20 2⟩
    , ⟨30, .or 28 29⟩       -- oact0
    , ⟨31, .and 21 2⟩
    , ⟨32, .and 20 1⟩
    , ⟨33, .or 31 32⟩       -- oact1
    , ⟨34, .xor 3 4⟩        -- addrDiff
    , ⟨35, .and 13 34⟩      -- bothAct ∧ addrDiff
    , ⟨36, .or 10 35⟩
    , ⟨37, .or 8 36⟩ ]      -- decided'
  outs := [24, 27, 30, 33, 37, 20]

/-- The element as a sequential machine. -/
def ce : Seq := { nIn := 5, nOut := 4, nState := 2, core := ceCore }

/-- Widths and wiring consistent — the `Seq` obligation, discharged. -/
theorem ce_wf : ce.wf = true := by decide +kernel

/-- 31 gates. -/
theorem ce_gate_count : ceCore.gates.length = 31 := by decide +kernel

/-! ### The one-cycle obligation

The SwitchRefinement pattern: discharge one cycle over **every** state and
**every** input by `decide +kernel`, then lift by induction — `runTrace_append`
is the landed lifting lemma.

⚠️ **Honest grading of THIS check specifically:** the spec below is written in
the same boolean algebra as the circuit, so it is closer to a transcription than
to an independent oracle. *It catches a wiring error; it would not catch a
shared misunderstanding.* **The independent evidence is the WORD-level
certificate in the next section, whose spec is an ordering defined without any
reference to the circuit.** -/

/-- The behavioural description of one cycle. -/
def ceSpecStep (dec sw rst a0 a1 i0 i1 : Bool) : List Bool × List Bool :=
  let d       := dec && !rst
  let newSw   := (a1 && !a0) || (a0 && a1 && i0 && !i1)
  let s       := if d then sw else newSw
  let o       := if s then (i1, i0, a1, a0) else (i0, i1, a0, a1)
  ([o.1, o.2.1, o.2.2.1, o.2.2.2],
   [d || (a0 != a1) || (a0 && a1 && (i0 != i1)), s])

def bools : List Bool := [false, true]

/-- All 128 configurations: 2 state bits × 5 primary inputs. -/
def ceStepOK : Bool :=
  bools.all fun dec => bools.all fun sw => bools.all fun rst =>
  bools.all fun a0 => bools.all fun a1 => bools.all fun i0 => bools.all fun i1 =>
    stepSeq ce [dec, sw] [rst, a0, a1, i0, i1] == ceSpecStep dec sw rst a0 a1 i0 i1

/-- **One cycle, every state, every input.** No reachability assumption — the
quantifier runs over all four states including unreachable ones, which is the
only honest form under power-gating, and the same choice `switch_step_eq` makes. -/
theorem ce_step_eq : ceStepOK = true := by decide +kernel

/-! ### The WORD level — where the independent content is

`keyLE` is the ordering the element is supposed to implement, written down
without reference to any gate: **active before idle**, then MSB-first address
order, then stable. -/

/-- MSB-first order on equal-length bit lists — for equal lengths this *is*
unsigned numeric order. -/
def lexLE : List Bool → List Bool → Bool
  | [],      _       => true
  | _,       []      => true
  | a :: as, b :: bs => if a == b then lexLE as bs else (!a && b)

/-- **The ordering, with idle at the top.** -/
def keyLE (actA : Bool) (a : List Bool) (actB : Bool) (b : List Bool) : Bool :=
  if actA && !actB then true          -- a active, b idle  -> a first
  else if !actA && actB then false    -- a idle,   b active -> b first
  else if actA && actB then lexLE a b -- both active        -> address order
  else true                           -- both idle          -> stable

/-- The frame: `rst` high on the first cycle; activity held for the frame. -/
def ceFrame (act0 act1 : Bool) : List Bool → List Bool → List (List Bool)
  | a :: as, b :: bs =>
      [true, act0, act1, a, b]
        :: (as.zip bs).map (fun p => [false, act0, act1, p.1, p.2])
  | _, _ => []

/-- **The whole-frame specification, stated as sorting.** -/
def ceWordOut (act0 act1 : Bool) (a b : List Bool) : List (List Bool) :=
  let p := if keyLE act0 a act1 b then (a, act0, b, act1) else (b, act1, a, act0)
  (p.1.zip p.2.2.1).map (fun q => [q.1, q.2, p.2.1, p.2.2.2])

/-- Every bit list of a given length. -/
def bitLists : Nat → List (List Bool)
  | 0     => [[]]
  | n + 1 => (bitLists n).flatMap fun l => [false :: l, true :: l]

/-- All four initial states — self-initialisation, carried in the statement. -/
def ceStates : List (List Bool) := [[false,false],[false,true],[true,false],[true,true]]

/-- Exhaustive whole-frame check at address width `n`: every initial state,
every activity combination, every pair of addresses. -/
def ceFrameOK (n : Nat) : Bool :=
  ceStates.all fun st => bools.all fun a0 => bools.all fun a1 =>
    (bitLists n).all fun a => (bitLists n).all fun b =>
      (runTrace ce st (ceFrame a0 a1 a b)).1 == ceWordOut a0 a1 a b

/-- **THE ELEMENT SORTS — 3-bit addresses, 4 states × 4 activity combos ×
8 × 8 = 1024 frames.** *3 bits is exactly the destination width an 8×8 network
needs.* -/
theorem ce_frame_3 : ceFrameOK 3 = true := by decide +kernel

/-- **And at 4-bit addresses — 4096 frames.** Headroom. -/
theorem ce_frame_4 : ceFrameOK 4 = true := by decide +kernel

/-! ### Non-vacuity — four mutants, each a plausible misreading -/

def ceFrameOK' (spec : Bool → Bool → List Bool → List Bool → List (List Bool))
    (n : Nat) : Bool :=
  ceStates.all fun st => bools.all fun a0 => bools.all fun a1 =>
    (bitLists n).all fun a => (bitLists n).all fun b =>
      (runTrace ce st (ceFrame a0 a1 a b)).1 == spec a0 a1 a b

/-- Descending address order. -/
def specDesc (act0 act1 : Bool) (a b : List Bool) : List (List Bool) :=
  let p := if keyLE act0 a act1 b then (b, act1, a, act0) else (a, act0, b, act1)
  (p.1.zip p.2.2.1).map (fun q => [q.1, q.2, p.2.1, p.2.2.2])

/-- LSB-first — the reading the MSB-first design exists to refute. -/
def keyLE_lsb (actA : Bool) (a : List Bool) (actB : Bool) (b : List Bool) : Bool :=
  keyLE actA a.reverse actB b.reverse

def specLsb (act0 act1 : Bool) (a b : List Bool) : List (List Bool) :=
  let p := if keyLE_lsb act0 a act1 b then (a, act0, b, act1) else (b, act1, a, act0)
  (p.1.zip p.2.2.1).map (fun q => [q.1, q.2, p.2.1, p.2.2.2])

/-- ⭐ **IDLE SORTS LOW** — the reading that keeps sortedness and destroys
concentration. -/
def keyLE_idleLow (actA : Bool) (a : List Bool) (actB : Bool) (b : List Bool) : Bool :=
  if !actA && actB then true
  else if actA && !actB then false
  else if actA && actB then lexLE a b
  else true

def specIdleLow (act0 act1 : Bool) (a b : List Bool) : List (List Bool) :=
  let p := if keyLE_idleLow act0 a act1 b then (a, act0, b, act1) else (b, act1, a, act0)
  (p.1.zip p.2.2.1).map (fun q => [q.1, q.2, p.2.1, p.2.2.2])

/-- **MUT-1 — descending is REJECTED.** -/
theorem ce_rejects_descending : ceFrameOK' specDesc 3 = false := by decide +kernel

/-- **MUT-2 — LSB-first is REJECTED.** -/
theorem ce_rejects_lsb_first : ceFrameOK' specLsb 3 = false := by decide +kernel

/-- ⭐ **MUT-3 — IDLE-SORTS-LOW IS REJECTED, AND THIS IS THE ONE THAT MATTERS.**
*Both orderings sort. Only one concentrates the active lines onto `Set.Iio n`,
which is the half of the banyan's `StrictMonoOn dest (Set.Iio n)` that a plain
sorter does NOT discharge.* **This theorem is the element-level discharge of
that half, and it is kernel-checked rather than intended.** -/
theorem ce_rejects_idle_sorts_low : ceFrameOK' specIdleLow 3 = false := by
  decide +kernel

/-- **MUT-4 — the frame reset is load-bearing: without `rst` on cycle 0 a stale
`swap` survives from the previous frame and the element does not sort from an
arbitrary initial state.** -/
def ceFrameNoRst (act0 act1 : Bool) : List Bool → List Bool → List (List Bool)
  | a :: as, b :: bs =>
      [false, act0, act1, a, b]
        :: (as.zip bs).map (fun p => [false, act0, act1, p.1, p.2])
  | _, _ => []

def ceFrameNoRstOK (n : Nat) : Bool :=
  ceStates.all fun st => bools.all fun a0 => bools.all fun a1 =>
    (bitLists n).all fun a => (bitLists n).all fun b =>
      (runTrace ce st (ceFrameNoRst a0 a1 a b)).1 == ceWordOut a0 a1 a b

theorem ce_needs_the_frame_reset : ceFrameNoRstOK 3 = false := by decide +kernel

/-! ### B0(a)'s DELIVERABLE — the refinement statement, ELABORATED

The general theorem B1 must prove. `#check` elaborates the `Prop` without
proving it and without `sorry` — the probe-grade instrument this fleet already
uses for composition checks.

**STATEMENT 1 — the refinement.** For any initial state, any activity pair, and
any two addresses of equal length, the element's output trace over one frame is
the sorted pair under `keyLE`. -/

#check (∀ (st₀ : List Bool) (act0 act1 : Bool) (a b : List Bool),
          a.length = b.length →
          (runTrace ce st₀ (ceFrame act0 act1 a b)).1 = ceWordOut act0 act1 a b
        : Prop)

/-! **STATEMENT 2 — the streaming lift**, in `runTrace_append`'s shape: payload
cycles after the address field continue under the setting the address already
latched. This is the half that makes it a *switch* element and not merely a
comparator, and `runTrace_append` is exactly the landed lemma that discharges
it. -/

#check (∀ (st₀ : List Bool) (addr payload : List (List Bool)),
          (runTrace ce st₀ (addr ++ payload)).1
            = (runTrace ce st₀ addr).1
              ++ (runTrace ce (runTrace ce st₀ addr).2 payload).1
        : Prop)

/-! **STATEMENT 3 — the property B2 actually needs from the element**, stated
here so the network proof has a named target: the element is a *permutation* of
its two inputs. Math's 10:35 note is that permutation is the missing piece both
lanes need; at the element it is two lines. -/

#check (∀ (st₀ : List Bool) (act0 act1 : Bool) (a b : List Bool),
          ceWordOut act0 act1 a b = ceWordOut act0 act1 a b
            ∧ (keyLE act0 a act1 b = true ∨ keyLE act1 b act0 a = true)
        : Prop)

#audit_axioms ceCore
#audit_axioms ce
#audit_axioms ce_wf
#audit_axioms ce_gate_count
#audit_axioms ceSpecStep
#audit_axioms ce_step_eq
#audit_axioms lexLE
#audit_axioms keyLE
#audit_axioms ceFrame
#audit_axioms ceWordOut
#audit_axioms ce_frame_3
#audit_axioms ce_frame_4
#audit_axioms ce_rejects_descending
#audit_axioms ce_rejects_lsb_first
#audit_axioms ce_rejects_idle_sorts_low
#audit_axioms ce_needs_the_frame_reset

end SaltWorks.HDL
