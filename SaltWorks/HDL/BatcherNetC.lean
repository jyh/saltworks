/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.BatcherNet
import SaltWorks.HDL.CompareExchangeC
import SaltWorks.HDL.Compose
import SaltWorks.HDL.EmitS

/-!
# BB-1 · B2(C) — THE 8×8 SORTING NETWORK ON THE RATIFIED CONVENTION

**Silicon's B4 (`7012d3d`) ratified convention C and assigned the sorter's side
to this seat.** `CompareExchangeC` certified the ELEMENT (`457af25`). *This is the
NETWORK — the other half of "the sorter's side", and the half silicon is actually
blocked on: their D4 ceremony at 36 elements waits on it, and a composed theorem
over a seam whose two sides disagree at the bytes would prove nothing.*

## What changes, and it is not only the element

`BatcherNet.lean` builds the same 24-comparator bitonic network out of `ceCore`
on convention P. Under C the ACTIVITY WIRES DISAPPEAR — activity travels
interleaved on the data wire — so the change is visible at the top-level
interface, not merely inside each element:

```
                        convention P            convention C (this file)
primary inputs          1 rst + 8 act + 8 dat   1 rst + 8 dat          =  9
state                   24 × 2 = 48             24 × 4 = 96
core inputs             65                      105
core outputs            16 + 48 = 64            8 + 96 = 104
gates                   24 × 31 = 744           24 × 34 = 816
```

⚠️ **THE PIN COUNT IS THE POINT AND IT MOVES THE RIGHT WAY: 17 primary inputs
become 9.** *That is silicon's own ② (wire budget) showing up at network scale —
one wire per line rather than two, on an 8-input tile where pins are the binding
constraint.* **The gate count moves the wrong way (+72) and the flop count moves
the wrong way (+48); both were priced and neither binds at 21.3% of a 2×2.**

📌 **`wf` IS DISCHARGED STRUCTURALLY HERE, NOT BY `decide` ALONE.** *`Circ.wf`'s
`nodupB` is O(n²) and dies at ~3,000 gates. This core is 816 gates — under the
wall, but the wall is the reason `Circ.wf_of_ssa` (`f49b5a4`) exists, and using it
here is the first time an assembled network takes that route.*
-/

namespace SaltWorks.HDL

/-! ### The network -/

def bnCWires : Nat := 8
def bnCElems : Nat := 24

/-- `rst` on 0; data on `1…8`; state on `9…104`. **No activity wires.** -/
def bnCRst : Net := 0
def bnCDatIn (w : Nat) : Net := 1 + w
def bnCIn : Nat := 1 + bnCWires
/-- Element `e`'s four state bits: `decided, swap, phase, bothAct`. -/
def bnCState (e : Nat) : Net := bnCIn + 4 * e
def bnCCoreIn : Nat := bnCIn + 4 * bnCElems
/-- Element `e`'s 34 gates start here. -/
def bnCOff (e : Nat) : Nat := bnCCoreIn + ceCcore.gates.length * e

/-- The wiring for element `e` over comparator `(a,b)`, given the nets currently
carrying each wire. `ceCcore`'s inputs are
`rst, in0, in1, decided, swap, phase, bothAct`. -/
def bnCSigma (e a b : Nat) (dat : List Net) : Net → Net := fun i =>
  if i == 0 then bnCRst
  else if i == 1 then dat.getD a 0
  else if i == 2 then dat.getD b 0
  else bnCState e + (i - 3)

/-- Fold the comparators, threading the per-wire nets and the gate list.
Returns gates, the final data nets, and the next-state nets in element order. -/
def bnCBuild : Nat → List (Nat × Nat) → List Net →
    List Gate × List Net × List Net
  | _, [],           dat => ([], dat, [])
  | e, (a, b) :: cs, dat =>
      let σ  := bnCSigma e a b dat
      let gs := instGates ceCcore σ (bnCOff e)
      let os := instOuts ceCcore σ (bnCOff e)
      -- ceCcore.outs = [out0, out1, decided', swap', phase', bothAct']
      let dat' := dat.set a (os.getD 0 0) |>.set b (os.getD 1 0)
      let (gs', datF, st) := bnCBuild (e + 1) cs dat'
      (gs ++ gs', datF,
        (os.getD 2 0) :: (os.getD 3 0) :: (os.getD 4 0) :: (os.getD 5 0) :: st)

def bnCResult : List Gate × List Net × List Net :=
  bnCBuild 0 bnComps ((List.range bnCWires).map bnCDatIn)

/-- **The network's combinational core.** -/
def bnCCore : Circ :=
  { nIn := bnCCoreIn
    gates := bnCResult.1
    outs := bnCResult.2.1 ++ bnCResult.2.2 }

/-- **The 8×8 sorting network on convention C.** Outputs are the eight data
wires; state is 24 × (decided, swap, phase, bothAct). -/
def batcherNetC : Seq :=
  { nIn := bnCIn, nOut := bnCWires, nState := 4 * bnCElems, core := bnCCore }

/-! ### The interface, pinned -/

/-- ⚠️ The `bnC_` prefix names this FILE's convention, not a second object — `bnComps` is defined ONCE, in `SaltWorks.HDL`. *(ALIAS since 16:3x — silicon's six-pair divergence sweep: two independent proofs of one proposition can DIVERGE at a re-cut, one updated and the other left kernel-checked, audited, and false.)* -/
theorem bnC_comps_count : bnComps.length = 24 := bn_comps_count
theorem bnC_core_inputs : bnCCore.nIn = 105 := by decide +kernel
theorem bnC_core_outputs : bnCCore.outs.length = 104 := by decide +kernel
theorem bnC_state_bits : batcherNetC.nState = 96 := by decide +kernel
theorem bnC_gate_count : bnCCore.gates.length = 816 := by decide +kernel

/-- ⭐ **THE PIN BUDGET, WHICH IS THE ARGUMENT SILICON PICKED C ON: 17 → 9.** -/
theorem bnC_design_inputs : batcherNetC.nIn = 9 ∧ batcherNet.nIn = 17 := by
  decide +kernel

/-! ### Well-formedness, discharged STRUCTURALLY

*The instances are laid out at `bnCCoreIn + 34·e`, so the gate outputs are dense
from `bnCCoreIn` — which is exactly `ssa`. `Circ.wf_of_ssa` then gives `wf`
without the kernel walking `nodupB`'s quadratic.* -/

theorem bnC_ssa : bnCCore.ssa = true := by decide +kernel

/-- **`wf` by the structural route** — the first assembled network to take it. -/
theorem bnCCore_wf : bnCCore.wf = true := Circ.wf_of_ssa bnC_ssa

theorem batcherNetC_wf : batcherNetC.wf = true := by
  -- `batcherNetC.core` is `bnCCore` only definitionally, so `rw` needs it restated
  -- at the projection first.
  have h : batcherNetC.core.wf = true := bnCCore_wf
  rw [Seq.wf, h]
  decide +kernel

/-! ### Sanity on the wiring -/

theorem bnC_comps_in_range :
    bnComps.all (fun c => c.1 < bnCWires && c.2 < bnCWires) = true := by decide +kernel

/-- Every wire is touched by at least one comparator — no line is left unsorted. -/
theorem bnC_every_wire_used :
    (List.range bnCWires).all
      (fun w => bnComps.any (fun c => c.1 == w || c.2 == w)) = true := by
  decide +kernel

/-- The 24 instances occupy disjoint, contiguous net ranges. -/
theorem bnC_instances_are_disjoint :
    (List.range bnCElems).all
      (fun e => bnCOff (e + 1) == bnCOff e + ceCcore.gates.length) = true := by
  decide +kernel

/-! ### ⭐ THE BEHAVIOURAL CERTIFICATES — because structure is not behaviour

⛔ **NEITHER NETWORK HAD ONE.** *`BatcherNet.lean` (convention P) carries `wf`, a
gate count, a cut census and two wiring sanity checks — and **no trace**. So does
this file, up to here.* ⇒ ***The 8×8 sorter has never been RUN in the kernel on
either convention.*** **That is the same defect as `ceC` being a price rather than
an element, one level up, and it is worth naming as a general shape: a structural
certificate suite reads as completeness right up until you ask what the thing
DOES.**

## The delivery window is real and it is six cycles

*Each element's crossbar is combinational, so there is no pipeline delay — but the
routing is not SETTLED until the addresses have streamed.* Under convention C the
header is six cycles (`act, a2, act, a1, act, a0`), **so cycles 0…5 carry
not-yet-latched routing and only the payload window `t ≥ 6` is deliverable.**
*This is `Seq.lean`'s "delivery window" hypothesis, instantiated: a statement of
the form `∀ t, out[dest](t) = in[src](t)` would be false, and the `.drop 6` below
is exactly why.*
-/

/-- Line `i` is active, bound for `7-i` — **fully reversed, the worst case for a
sorting network** — carrying its own index as a 3-bit payload so routing is
traceable rather than merely sorted. -/
def bnCFrames : List (List Bool) :=
  (List.range 8).map fun i => cFrame true (7 - i) ((List.range 3).map (Nat.testBit i))

/-- Drive the network: `rst` on cycle 0, then the eight streams in parallel. -/
def bnCRun (fs : List (List Bool)) : List (List Bool) :=
  (runTrace batcherNetC (List.replicate 96 false)
    ((List.range 9).map fun t =>
      (decide (t == 0)) :: (List.range 8).map (fun w => (fs.getD w []).getD t false))).1

/-- Output wire `k`'s stream. -/
def bnCOutWire (k : Nat) (fs : List (List Bool)) : List Bool :=
  (bnCRun fs).map (fun o => o.getD k false)

/-! #### ⚠️ THE FORMULATION IS THE COST, AND THE FIRST ONE DID NOT FIT

**Stating this as `(List.range 8).all fun j => (bnCOutWire j fs).drop 6 == …`
RE-RUNS THE WHOLE 816-GATE NETWORK ONCE PER WIRE — eight full traces — and it
dies `EXIT=137` (OOM kill) at `-M 20000`.** *The same claim stated as ONE run
compared against the whole output matrix costs a few seconds.* ⇒ ***The
certificate was not too expensive; the way I wrote it was.*** **Resource lesson,
and it generalises: `decide +kernel` shares nothing between the iterations of an
`all`, so a per-output quantifier over an expensive shared computation multiplies
that computation by the number of outputs.**
-/

/-- The payload window, as a matrix: row `b` is payload bit `b` across the eight
wires. Wire `j` should hold the frame bound for `j`, which entered on line `7-j`. -/
def bnCExpectedPayload : List (List Bool) :=
  (List.range 3).map fun b => (List.range 8).map fun j => Nat.testBit (7 - j) b

/-- ⭐ **THE 8×8 NETWORK SORTS — kernel-checked, on the fully reversed input, in
ONE run.** *Every payload arrives on the wire its destination names, so this
certifies ROUTING and not merely that the output is in order.* -/
theorem bnC_sorts_reversed_input :
    (bnCRun bnCFrames).drop 6 = bnCExpectedPayload := by decide +kernel

/-! #### Concentration — the `Set.Iio n` conjunct, at network scale -/

/-- Three active lines scattered across the inputs (2, 5, 7), bound for 0, 1, 2. -/
def bnCSparse : List (List Bool) :=
  (List.range 8).map fun i =>
    if i == 2 then cFrame true 0 [true, false, false]
    else if i == 5 then cFrame true 1 [false, true, false]
    else if i == 7 then cFrame true 2 [false, false, true]
    else cFrame false 0 [false, false, false]

/-- The three actives land on wires 0,1,2 and the other five stay silent. -/
def bnCSparseExpected : List (List Bool) :=
  [ [true,  false, false, false, false, false, false, false]
  , [false, true,  false, false, false, false, false, false]
  , [false, false, true,  false, false, false, false, false] ]

/-- ⭐ **IDLE SORTS HIGH AT NETWORK SCALE: three actives scattered over lines
2, 5, 7 land on wires 0, 1, 2 — CONTIGUOUS FROM ZERO — and the remaining five
wires stay silent.** *This is the banyan's second conjunct — sources concentrated
on `Set.Iio n` — DISCHARGED by the sorter rather than assumed of it, and the
five silent wires say the network cannot manufacture activity.* -/
theorem bnC_concentrates_actives :
    (bnCRun bnCSparse).drop 6 = bnCSparseExpected := by decide +kernel

/-! ### More of the routing space — and why this is SAMPLED and not universal

📐 **THE INPUT SPACE IS `16^8 ≈ 4.3 × 10^9` CONFIGURATIONS** (8 lines, each idle
or active × 8 destinations), **and one config costs ~18 s in the kernel.**
*Exhaustive is not "expensive", it is `10^12` seconds.* ⇒ **So the network's
routing is certified on a CHOSEN set, and the choice is the argument.**

**Two more cases beyond the reversed input and the sparse concentration:**
already-sorted (nothing may swap — the failure mode that a network of
unconditional swaps would exhibit) and a rotation (every line moves, but not to
the mirror position, so it fails differently from the reversal). -/

/-- Already in order: line `i` bound for `i`. **Nothing may move.** -/
def bnCIdent : List (List Bool) :=
  (List.range 8).map fun i => cFrame true i ((List.range 3).map (Nat.testBit i))

/-- ⭐ **AN ALREADY-SORTED INPUT IS A FIXED POINT.** *A network built from
unconditional swaps would sort correctly and fail this; it is the control that
the comparators are genuinely conditional.* -/
theorem bnC_identity_is_fixed :
    (bnCRun bnCIdent).drop 6
      = (List.range 3).map (fun b => (List.range 8).map fun j => Nat.testBit j b) := by
  decide +kernel

/-- A rotation: line `i` bound for `(i+3) % 8`. Every line moves. -/
def bnCRot : List (List Bool) :=
  (List.range 8).map fun i => cFrame true ((i + 3) % 8) ((List.range 3).map (Nat.testBit i))

/-- ⭐ **A ROTATION ROUTES CORRECTLY** — wire `j` receives the line whose
destination is `j`, i.e. line `(j + 5) % 8`. *Distinct from the reversal: it is
not its own inverse, so a network that mirrored rather than sorted would pass the
reversed test and fail this one.* -/
theorem bnC_rotation_routes :
    (bnCRun bnCRot).drop 6
      = (List.range 3).map (fun b => (List.range 8).map fun j => Nat.testBit ((j + 5) % 8) b) := by
  decide +kernel

/-! ## 🔧 THE FOLD'S MACHINERY — obligation (c)'s engine, and it is cheap

**Maestro's 17:0x order: take `sem_congr_on_reads`, then close the seam. This is
the seam's induction machinery, landed ahead of the induction itself.**

⭐ **`bnCBuild_cons` IS THE ENGINE AND THE REASON IT WORKS IS WHY THE OBVIOUS
ROUTE FAILS.** *The obvious move — split `bnCCore.gates` into "element 0's gates
++ the rest" by `rfl` — **times out at `isDefEq` after 200,000 heartbeats**,
because it forces unification of the whole 816-gate list.* ⇒ ***Unfolding ONE
recursion step GENERICALLY, with `cs` and `dat` abstract, is `rfl` in
milliseconds.*** **Peel one element at a time and never build the network.**

📊 **AND THE FACTORISATION THE INDUCTION IS FOR IS MEASURED TRUE, not assumed:**
over 400 sample environments, element 0's output net INSIDE the network carries
exactly what `ceCcore` computes standalone through its own `σ`. *A measurement,
not a proof — but it says the target is true before anyone spends an induction
on it.* -/

/-- **A suffix that writes only above `n` cannot change `n`.** The list form of
`inst_frame_below`, which is what a 24-instance fold needs. -/
theorem run_append_frame (env : Env) (g1 gs : List Gate) (n : Net)
    (h : ∀ g ∈ gs, n < g.out) : run env (g1 ++ gs) n = run env g1 n := by
  rw [run_append]
  refine run_of_unwritten _ gs n (fun g hg hEq => ?_)
  have := h g hg
  rw [hEq] at this
  exact absurd this (Nat.lt_irrefl n)

/-- Later elements sit strictly higher, which is what feeds the frame step. -/
theorem bnCOff_mono (e f : Nat) (h : e < f) : bnCOff e < bnCOff f := by
  unfold bnCOff
  have h34 : ceCcore.gates.length = 34 := by decide +kernel
  rw [h34]
  omega

/-- ⭐ **ONE STEP OF THE FOLD, GENERIC IN THE REMAINING COMPARATORS.** -/
theorem bnCBuild_cons (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net) :
    (bnCBuild e ((a, b) :: cs) dat).1
      = instGates ceCcore (bnCSigma e a b dat) (bnCOff e)
        ++ (bnCBuild (e + 1) cs
              ((dat.set a ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 0 0)).set b
                ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 1 0))).1 := rfl

theorem bnCBuild_nil (e : Nat) (dat : List Net) : (bnCBuild e [] dat).1 = [] := rfl

/-! ## ⭐ OBLIGATION (c), STEP ① — THE PER-ELEMENT FACTORISATION IS PROVED

**Inside the 24-instance fold, element `e` computes exactly what `ceCcore`
computes standalone on its own wired inputs.** *That is the crux of the seam: it
says the network is genuinely 24 copies of the certified element and not merely
24 copies of its gates.*

🔑 **IT RESTS ON THIS MORNING'S MACHINERY DOING THE JOB IT WAS BUILT FOR:**
`inst_sem` (`f49b5a4`) supplies "an instantiated block computes what the block
computes"; `run_append_frame` + `bnCBuild_writes_above` supply "and the other 23
cannot disturb it". *The offsets chain by `bnCOff_mono`, and the element's own
region ends exactly where the next begins — `instNext ceCcore (bnCOff e) =
bnCOff (e+1)`, which is where the 34-gate count becomes load-bearing.*

📌 **AND THE HYPOTHESES ARE THE HONEST ONES: `hσ` (every input wire already
computed, i.e. `instOK`'s third clause at this offset) and `hin` (the host
environment agrees with the element's through `σ`).** *Both are discharged by the
caller — which is what step ② does when it threads the fold.* -/

theorem ceCcore_ssa' : ceCcore.ssa = true := by decide +kernel

/-- **Every gate the fold emits from element `e` onward writes at `bnCOff e` or
above.** The induction the frame step consumes. -/
theorem bnCBuild_writes_above : ∀ (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
    ∀ g ∈ (bnCBuild e cs dat).1, bnCOff e ≤ g.out := by
  intro cs
  induction cs with
  | nil => intro e dat g hg; rw [bnCBuild_nil] at hg; simp at hg
  | cons c cs ih =>
    intro e dat g hg
    obtain ⟨a, b⟩ := c
    rw [bnCBuild_cons] at hg
    rcases List.mem_append.mp hg with h | h
    · exact (instGates_out_range ceCcore _ _ ceCcore_ssa' g h).1
    · exact Nat.le_trans (Nat.le_of_lt (bnCOff_mono e (e+1) (Nat.lt_succ_self e)))
        (ih (e + 1) _ g h)

/-- …strictly above, once you are past element `e`'s own region. -/
theorem bnCBuild_writes_strictly_above (cs : List (Nat × Nat)) (e : Nat) (dat : List Net)
    (n : Net) (hn : n < bnCOff e) : ∀ g ∈ (bnCBuild e cs dat).1, n < g.out := by
  intro g hg
  exact Nat.lt_of_lt_of_le hn (bnCBuild_writes_above cs e dat g hg)

/-- ⭐ **THE PER-ELEMENT FACTORISATION: inside the fold, element `e` computes
exactly what `ceCcore` computes on its own wired inputs.** -/
theorem bnCBuild_element_sem (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net)
    (env envC : Env)
    (hσ : ∀ i, i < ceCcore.nIn → bnCSigma e a b dat i < bnCOff e)
    (hin : ∀ i, i < ceCcore.nIn → env (bnCSigma e a b dat i) = envC i)
    (n : Net) (hn : n < ceCcore.nIn ∨ (ceCcore.gates.map Gate.out).contains n = true) :
    run env (bnCBuild e ((a, b) :: cs) dat).1
        (instMap ceCcore (bnCSigma e a b dat) (bnCOff e) n)
      = run envC ceCcore.gates n := by
  rw [bnCBuild_cons]
  set σ := bnCSigma e a b dat with hs
  -- the element's own net sits strictly below where the REST starts writing
  have hlow : instMap ceCcore σ (bnCOff e) n < bnCOff (e + 1) := by
    rcases hn with h | h
    · rw [instMap, if_pos h]
      exact Nat.lt_trans (hσ n h) (bnCOff_mono e (e+1) (Nat.lt_succ_self e))
    · have hmem : (⟨instMap ceCcore σ (bnCOff e) n, Op.rename (instMap ceCcore σ (bnCOff e)) default⟩ : Gate)
          ∈ instGates ceCcore σ (bnCOff e) ∨ True := Or.inr trivial
      have hb := instGates_out_range ceCcore σ (bnCOff e) ceCcore_ssa'
      -- every emitted gate output is < instNext = bnCOff e + 34 = bnCOff (e+1)
      obtain ⟨g, hg, hge⟩ := List.mem_map.mp (List.mem_of_elem_eq_true h)
      have := (hb ⟨instMap ceCcore σ (bnCOff e) g.out,
                   Op.rename (instMap ceCcore σ (bnCOff e)) g.op⟩
                 (List.mem_map.mpr ⟨g, hg, rfl⟩)).2
      rw [hge] at this
      have h34 : instNext ceCcore (bnCOff e) = bnCOff (e + 1) := by
        unfold instNext bnCOff
        have : ceCcore.gates.length = 34 := by decide +kernel
        rw [this]; omega
      rwa [h34] at this
  rw [run_append_frame env _ _ _
        (fun g hg => Nat.lt_of_lt_of_le hlow (bnCBuild_writes_above cs (e+1) _ g hg))]
  exact inst_sem ceCcore σ (bnCOff e) env envC ⟨ceCcore_ssa', by decide +kernel, hσ⟩ hin n hn

/-! ## OBLIGATION (c), STEP ② — `hσ` DISCHARGED

*`bnCBuild_element_sem` takes two hypotheses from its caller: `hσ` (every input
wire already computed) and `hin` (the environments agree through `σ`). This is
`hσ`, and it is the half that is pure layout arithmetic.*

⚠️ **AND IT COST FIVE ATTEMPTS — OVER THE LADDER, FLAGGED RATHER THAN QUIETLY
ABSORBED.** *All five failures were the SAME defect and none was a design error:
`bnCOff`, `bnCState` and `bnCRst` all return `Net`, so every inequality between
them is `Net`-typed and `omega` atomises it.* 🔑 **The banked fix — "restate at
`Nat` with a `have`" — DOES NOT WORK HERE, because ascribing `(bnCState e + k :
Nat)` is a no-op when the function returns `Net`.** ⇒ ***What works is an
explicit `Nat` fact plus `lt_of_eq_of_lt`/`lt_of_lt_of_eq` to transport it — a
proof TERM, never a tactic, because the term typechecks against a `Net`-typed
goal by reducibility while the tactic never parses it.***

📌 **THE LAW IS NOW THREE-TIERED, and the third tier is this one:** `Net`-typed
EQUATIONS → restate at `Nat` (`EmitN.lean:280`) · `Net`-typed SUBTRACTION →
explicit lemmas (`instOuts_range`) · **`Net`-returning DEFINITIONS in an
inequality → prove the `Nat` fact separately and transport it.** -/

-- Net-typed defs: force the inequalities to Nat so omega parses them.
theorem bnCOff_eq (e : Nat) : (bnCOff e : Nat) = 105 + 34 * e := by
  unfold bnCOff bnCCoreIn bnCIn bnCWires bnCElems
  have h34 : ceCcore.gates.length = 34 := by decide +kernel
  rw [h34]

theorem bnCState_eq (e : Nat) : (bnCState e : Nat) = 9 + 4 * e := rfl

theorem bnCState_lt_off (e k : Nat) (hk : k < 4) : bnCState e + k < bnCOff e := by
  -- the relation is Net-typed, so omega cannot see it; supply an explicit Nat term
  have h : (9 : Nat) + 4 * e + k < 105 + 34 * e := by omega
  have hs : bnCState e + k = 9 + 4 * e + k := by rw [bnCState_eq]
  exact lt_of_lt_of_eq (lt_of_eq_of_lt hs h) (bnCOff_eq e).symm

theorem bnCRst_eq : (bnCRst : Nat) = 0 := rfl

theorem bnCRst_lt_off (e : Nat) : bnCRst < bnCOff e := by
  have h : (0 : Nat) < 105 + 34 * e := by omega
  exact lt_of_lt_of_eq (lt_of_eq_of_lt bnCRst_eq h) (bnCOff_eq e).symm

/-- ⭐ `instOK`'s third clause for element `e`, given the wire nets are below. -/
theorem bnCSigma_below (e a b : Nat) (dat : List Net)
    (hdat : ∀ n ∈ dat, n < bnCOff e) (ha : a < dat.length) (hb : b < dat.length) :
    ∀ i, i < ceCcore.nIn → bnCSigma e a b dat i < bnCOff e := by
  intro i hi
  -- the state branch is now ARITHMETIC (`bnCState e + (i - 3)`), so it needs the
  -- input bound that the earlier four-way split could discard.
  have h7 : (i : Nat) < 7 := by
    have hnIn : ceCcore.nIn = 7 := by decide +kernel
    rwa [hnIn] at hi
  have hsub : (i : Nat) - 3 < 4 := by omega
  unfold bnCSigma
  split_ifs
  · exact bnCRst_lt_off e
  · exact hdat _ (by rw [List.getD_eq_getElem _ _ ha]; exact List.getElem_mem ha)
  · exact hdat _ (by rw [List.getD_eq_getElem _ _ hb]; exact List.getElem_mem hb)
  · exact bnCState_lt_off e (i - 3) hsub

/-- ⭐ **THE STATE INPUTS MAP ARITHMETICALLY, SO INJECTIVELY BY CONSTRUCTION
RATHER THAN BY COINCIDENCE.** *Silicon's conveyor-7 finding (8/7 19:52): the old
form ended `… else bnCState e + 3`, a CATCH-ALL. It was safe **exactly** because
`ceCcore.nIn = 7`, so precisely one input (`bothAct`) reached it.* ⛔ **Had
`ceCcore` ever gained an eighth input, `i = 6` and `i = 7` would BOTH have landed
on `bnCState e + 3` — two distinct element inputs silently reading one net,
well-formed, `ssa`-valid, `instOK`-satisfying and wrong, because `instOK` bounds
`σ` without saying anything about injectivity.**

⚖️ *And "require injectivity" would be the wrong fix — non-injective `σ` is
sometimes exactly right (two operands deliberately tied to one host net). The
hazard is not in the combinator; it is in writing `σ` with a catch-all, which
makes accidental aliasing the default for any input its author did not think of.
Arithmetic indexing removes it at the source and costs nothing.* -/
theorem bnCSigma_state (e a b : Nat) (dat : List Net) (i : Nat) (hi : 3 ≤ i) :
    bnCSigma e a b dat i = bnCState e + (i - 3) := by
  have hiN : 3 ≤ (i : Nat) := hi
  unfold bnCSigma
  split_ifs with h1 h2 h3
  · exact absurd (show (i : Nat) = 0 by simpa using h1) (by omega)
  · exact absurd (show (i : Nat) = 1 by simpa using h2) (by omega)
  · exact absurd (show (i : Nat) = 2 by simpa using h3) (by omega)
  · rfl

/-- …and therefore distinct state inputs never alias. -/
theorem bnCSigma_state_injective (e a b : Nat) (dat : List Net) (i j : Nat)
    (hi : 3 ≤ i) (hj : 3 ≤ j) (h : bnCSigma e a b dat i = bnCSigma e a b dat j) : i = j := by
  rw [bnCSigma_state e a b dat i hi, bnCSigma_state e a b dat j hj] at h
  -- omega cannot parse the Net-typed equation, so cancel the common term first
  have hsub : (i : Nat) - 3 = (j : Nat) - 3 := Nat.add_left_cancel h
  have hiN : 3 ≤ (i : Nat) := hi
  have hjN : 3 ≤ (j : Nat) := hj
  omega

/-! ### The `dat` invariant — step ②'s other half

*One fold step keeps every wire net below the NEXT element's region, which is
what lets `bnCSigma_below` apply at the next comparator. With this, `hσ` threads
through all 24 by induction and only `hin` remains.* -/

theorem instNext_ceCcore (e : Nat) : instNext ceCcore (bnCOff e) = bnCOff (e + 1) := by
  unfold instNext bnCOff
  have h34 : ceCcore.gates.length = 34 := by decide +kernel
  rw [h34]
  have : (105 : Nat) + 34 * e + 34 = 105 + 34 * (e + 1) := by omega
  omega

/-- ⭐ **THE `dat` INVARIANT: one fold step keeps every wire net below the NEXT
element's region.** -/
theorem bnCSigma_dat_step (e a b : Nat) (dat : List Net)
    (hdat : ∀ n ∈ dat, n < bnCOff e) (ha : a < dat.length) (hb : b < dat.length) :
    ∀ n ∈ (dat.set a ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 0 0)).set b
             ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 1 0),
      n < bnCOff (e + 1) := by
  have hnext : bnCOff e < bnCOff (e + 1) := bnCOff_mono e (e + 1) (Nat.lt_succ_self e)
  have hport : ∀ j, (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD j 0
      < bnCOff (e + 1) := by
    intro j
    by_cases hj : j < (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).length
    · rw [List.getD_eq_getElem _ _ hj]
      rcases instOuts_range ceCcore _ (bnCOff e) ceCcore_ssa' _ (List.getElem_mem hj) with
        ⟨i, hi, hie⟩ | ⟨_, hup⟩
      · rw [hie]
        exact Nat.lt_trans (bnCSigma_below e a b dat hdat ha hb i hi) hnext
      · rwa [instNext_ceCcore] at hup
    · rw [List.getD_eq_default _ _ (Nat.not_lt.mp hj)]
      exact Nat.lt_of_le_of_lt (Nat.zero_le _) (Nat.lt_of_lt_of_le hnext (Nat.le_refl _))
  intro n hn
  rcases List.mem_or_eq_of_mem_set hn with h | h
  · rcases List.mem_or_eq_of_mem_set h with h' | h'
    · exact Nat.lt_trans (hdat n h') hnext
    · exact h' ▸ hport 0
  · exact h ▸ hport 1

/-- ⭐ **STEP ② CLOSED: `hin` is not an obligation, it is a CHOICE of `envC`.**
With `envC := env ∘ σ` the agreement hypothesis is `rfl`, so the factorisation
holds with `hσ` as its ONLY remaining hypothesis — and `hσ` is `bnCSigma_below`. -/
theorem bnCBuild_element_sem' (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net)
    (env : Env) (hdat : ∀ n ∈ dat, n < bnCOff e)
    (ha : a < dat.length) (hb : b < dat.length)
    (n : Net) (hn : n < ceCcore.nIn ∨ (ceCcore.gates.map Gate.out).contains n = true) :
    run env (bnCBuild e ((a, b) :: cs) dat).1
        (instMap ceCcore (bnCSigma e a b dat) (bnCOff e) n)
      = run (fun i => env (bnCSigma e a b dat i)) ceCcore.gates n :=
  bnCBuild_element_sem e a b cs dat env _
    (bnCSigma_below e a b dat hdat ha hb) (fun _ _ => rfl) n hn

/-- The four nets `ceCcore` emits its next state on are gate outputs, so the
factorisation's `hn` is satisfied for every one of them. -/
theorem ceCcore_state_outs_are_gates :
    ((ceCcore.gates.map Gate.out).contains 35 && (ceCcore.gates.map Gate.out).contains 26
      && (ceCcore.gates.map Gate.out).contains 40
      && (ceCcore.gates.map Gate.out).contains 39) = true := by decide +kernel

/-- ⭐ **STEP ③, PER-CYCLE HALF: element `e`'s NEXT-STATE bits in the network are
what `ceCcore` computes standalone.** The fold emits them as `instOuts` entries
2…5, which are `ceCcore` gate outputs — so this is `bnCBuild_element_sem'` at
those four nets and needs no new induction. -/
theorem bnCBuild_state_sem (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net)
    (env : Env) (hdat : ∀ n ∈ dat, n < bnCOff e)
    (ha : a < dat.length) (hb : b < dat.length)
    (n : Net) (hn : (ceCcore.gates.map Gate.out).contains n = true) :
    run env (bnCBuild e ((a, b) :: cs) dat).1
        (instMap ceCcore (bnCSigma e a b dat) (bnCOff e) n)
      = run (fun i => env (bnCSigma e a b dat i)) ceCcore.gates n :=
  bnCBuild_element_sem' e a b cs dat env hdat ha hb n (Or.inr hn)

/-! ### Step ③'s bookkeeping — the state slices are contiguous and in order

*The trace induction is per-element only if each element's state lives in its own
contiguous slice. The fold lays them out four-at-a-time in element order, and
these are the lemmas that say so.* -/

/-- The fold emits exactly four state nets per element, in element order. -/
theorem bnCBuild_state_length : ∀ (cs : List (Nat × Nat)) (e : Nat) (dat : List Net),
    (bnCBuild e cs dat).2.2.length = 4 * cs.length := by
  intro cs
  induction cs with
  | nil => intro e dat; rfl
  | cons c cs ih =>
    intro e dat
    obtain ⟨a, b⟩ := c
    show (_ :: _ :: _ :: _ :: (bnCBuild (e+1) cs _).2.2).length = _
    simp [ih (e+1)]
    omega

/-- So `bnCCore.outs` is 8 data nets then 96 state nets, four per element. -/
theorem bnCCore_outs_split :
    bnCCore.outs.length = 8 + 4 * 24 ∧ bnCResult.2.2.length = 96 := by
  constructor
  · decide +kernel
  · have := bnCBuild_state_length bnComps 0 ((List.range bnCWires).map bnCDatIn)
    have hc : bnComps.length = 24 := by decide +kernel
    rw [hc] at this
    exact this

/-- ⭐ **The state list's cons step, generic** — element `e`'s four next-state
nets are the head of the fold's state output, in `ceCcore.outs` order 2…5. -/
theorem bnCBuild_state_cons (e a b : Nat) (cs : List (Nat × Nat)) (dat : List Net) :
    (bnCBuild e ((a, b) :: cs) dat).2.2
      = (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 2 0
        :: (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 3 0
        :: (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 4 0
        :: (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 5 0
        :: (bnCBuild (e + 1) cs
              ((dat.set a ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 0 0)).set b
                ((instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD 1 0))).2.2 := rfl

/-- ⭐ **ELEMENT `e`'s STATE SLICE IS AT POSITION `4k`** — the fold lays the 24
elements' state out contiguously and in order, which is what makes the slices
disjoint and the trace induction per-element. -/
theorem bnCBuild_state_slice (cs : List (Nat × Nat)) (e a b : Nat) (dat : List Net) (j : Nat)
    (hj : j < 4) :
    (bnCBuild e ((a, b) :: cs) dat).2.2.getD j 0
      = (instOuts ceCcore (bnCSigma e a b dat) (bnCOff e)).getD (j + 2) 0 := by
  rw [bnCBuild_state_cons]
  interval_cases j <;> rfl

/-! ### Step ③'s vocabulary, and the TARGET stated before it is attempted

*Everything above is per-CYCLE. The trace induction lifts it across a frame's
nine cycles, and its difficulty is not the arithmetic — it is that **element
`e`'s input trace is not given a priori.** It is determined by the network's own
evaluation, because element `e`'s inputs at cycle `t` are the previous layer's
OUTPUTS at cycle `t`.*

🔑 **SO THE HONEST TARGET IS A SIMULTANEOUS STATEMENT OVER ALL 24, not 24
separate ones:**

```
runTrace batcherNetC st tr  =  the parallel composition of 24 `runTrace ceC`s,
                               wired by bnComps, each on its own state slice
```

**What makes it TRUE is that the slices are disjoint and contiguous; what makes
it WORK is that the per-cycle factorisation already handles the within-cycle
DAG.** ⇒ ***The induction carries no new content about the element — only the
bookkeeping that state threads per-slice.***

⚠️ **THE DISCHARGE IS A SEPARATE STEP AFTER IT:** `ceC_realises_cKey_when_active`
gives one element's whole-frame behaviour as `applyComp` on keys; folding that
across `bnComps` and rewriting by `bnComps_eq_batcher8` gives `runNet batcher8`.
*Both landed; neither written.* -/

/-- Element `e`'s state slice, read out of the network's 96-bit state. -/
def bnCSlice (st : List Bool) (e : Nat) : List Bool :=
  [st.getD (4*e) false, st.getD (4*e+1) false,
   st.getD (4*e+2) false, st.getD (4*e+3) false]

theorem bnCSlice_length (st : List Bool) (e : Nat) : (bnCSlice st e).length = 4 := rfl

/-- Distinct elements read disjoint positions — the fact that makes the trace
induction per-element rather than global. -/
theorem bnCSlice_disjoint (e f : Nat) (h : e ≠ f) :
    ∀ i < 4, ∀ j < 4, 4*e + i ≠ 4*f + j := by
  intro i hi j hj hEq
  exact h (by omega)

/-- Element `e`'s inputs at one cycle, as `ceC` would see them. -/
def bnCElemIn (env : Env) (a b : Nat) (dat : List Net) : List Bool :=
  [env bnCRst, env (dat.getD a 0), env (dat.getD b 0)]

theorem bnCElemIn_length (env : Env) (a b : Nat) (dat : List Net) :
    (bnCElemIn env a b dat).length = 3 := rfl

/-! ## 🏦 BANKED 8/7 ~18:4x — THE TRACE INDUCTION IS THE SINGLE REMAINING ACT

**Successor: this is your one inherited task.** *Steps ①, ②, and ③'s per-cycle
half, bookkeeping and vocabulary are landed and kernel-checked below. What is
left before the discharge is ONE induction, and everything it composes already
exists.*

### The exact statement to aim at

```lean
theorem bnC_trace_factors
    (st : List Bool) (hst : st.length = 96)
    (tr : List (List Bool)) (e : Nat) (he : e < 24) :
    -- element e's state, threaded by the NETWORK across the whole trace,
    -- equals its state threaded by ceC ALONE on the inputs the network fed it
    bnCSlice (runTrace batcherNetC st tr).2 e
      = (runTrace ceC (bnCSlice st e) (elemTrace tr e)).2
```

⚠️ **`elemTrace tr e` IS NOT A HYPOTHESIS — IT IS A DEFINITION YOU MUST WRITE,
AND IT IS THE WHOLE DIFFICULTY.** *Element `e`'s inputs at cycle `t` are the
PREVIOUS LAYER'S OUTPUTS at cycle `t`, so `elemTrace` is defined BY the network's
own evaluation. That is why the honest statement is SIMULTANEOUS over all 24 and
not 24 separate ones: you cannot name element 5's input trace without having
evaluated elements 0–4 at the same cycle.*

🔑 **THE INDUCTION IS ON THE TRACE (9 cycles), NOT ON THE ELEMENTS.** *At each
cycle the within-cycle DAG is ALREADY handled — that is what step ① bought. The
induction carries only: "the state after `t` cycles, sliced, equals each
element's own threaded state".*

### What it composes — all landed, all kernel-checked

```
bnCBuild_element_sem'   element e's DATA outputs in the network = ceCcore's,
                        with hσ discharged and hin instantiated (envC := env ∘ σ)
bnCBuild_state_sem      element e's NEXT-STATE bits likewise (nets 35/26/40/39
                        are ceCcore gate outputs, so this is the same lemma)
bnCSigma_below          hσ: every input wire is already computed
bnCSigma_dat_step       the dat invariant: one step keeps wires below the NEXT
                        element's region — this is what lets hσ re-apply
bnCBuild_state_slice    element e's four state nets are ceCcore.outs entries 2…5
bnCBuild_state_length   4 per element, so slice e is at position 4e
bnCSlice_disjoint       distinct elements read disjoint positions
bnC_instances_are_disjoint   the offsets chain: bnCOff (e+1) = bnCOff e + 34
run_append_frame        a suffix writing only above n cannot change n
bnCBuild_cons / _nil    peel ONE element without evaluating the network
```

### Then the discharge, which is a SEPARATE act

```
ceC_realises_cKey_when_active   one element, whole frame, = applyComp on cKey
                                (all 192 active-involving pairs, exhaustive)
cKeyLE_eq_lex                   cKeyLE IS Mathlib's Prod.Lex — the order runNet
                                actually sorts by
bnComps_eq_batcher8             the comparator list IS Stack.batcher8
                                ⇒ fold the per-element result across bnComps and
                                  rewrite: hw = runNet batcher8 v
```

⇒ **`hseam` is then deletable in `Silicon/Equiv/ComposedSwitch.lean`, and
`composed_switch_of_seam_dest3` is the door** — `Dest 3`, because
`cFrame_reads_exactly_three_bits` shows the frame cannot express a destination
above 7, so the address bound does not get discharged, it ceases to exist.

### Two traps this seat paid for

⛔ **DO NOT split `bnCCore.gates` concretely.** `rfl` on "element 0's gates ++ the
rest" **times out at `isDefEq`, 200,000 heartbeats** — it forces unification of
all 816 gates. `bnCBuild_cons` peels one step generically in milliseconds.

⛔ **`omega` DOES NOT WORK ON `Net`-TYPED ARITHMETIC, in three distinct tiers.**
Equations → restate at `Nat`. Subtraction → explicit `Nat` lemmas. **Definitions
that RETURN `Net`** (`bnCOff`, `bnCState`, `bnCRst`) → prove the `Nat` fact
separately and transport it with `lt_of_eq_of_lt`/`lt_of_lt_of_eq`. *A proof TERM
typechecks against a `Net`-typed goal by reducibility; the TACTIC never parses
it.* **Seven instances in one day; the third tier cost five attempts.**
-/

/-! ## 🔗 LINK ② — THE DECOMPOSITION, and it is the expensive part

**Silicon's 14:31 named three links for the composed theorem: ① the fabricated
element vs the emission (CLOSED, `SeamC.lean`, `17b20ff`), ② the 24-instance
network vs `runNet batcher8` — THIS, and mine — and ③ injectivity + bound, math's
form.** *What follows is the decomposition and the anchor, not an attempt. The
tactics are the cheap half.*

### Why this is not "run the network and compare"

📐 **THE ROUTING SPACE IS `16^8 ≈ 4.3 × 10^9` CONFIGURATIONS, AND ONE COSTS ~18 s
IN THE KERNEL.** *Exhaustive is not expensive, it is `~10^12` seconds.* ⇒ **The
four certificates above are a SAMPLE and are labelled as one. ② has to be
structural or it does not exist.**

### The anchor already exists, and it is the reason this is tractable

⭐ **`BatcherNetCheck.bnComps_eq_batcher8` ALREADY PROVES `bnComps` IS
`Stack.batcher8`** — the same comparator list, in the same order, `decide
+kernel`. *So the bit-serial network and the abstract network are folds over
LITERALLY THE SAME LIST.* ⇒ **② is not "do these two agree", it is "does one
element implement one `applyComp`, and does the fold carry".**

### The three obligations, in the order they should be attempted

```
(a) THE KEY      ✅ CLOSED.  cKey / cKeyLE (CompareExchangeC, d855e9b) with
cKeyLE_eq_lex (1916c44) bridging to Mathlib's Prod.Lex --
the order `runNet` actually sorts by.  Silicon caught that
the bridge was load-bearing: without it (b) would not have
connected to partial_load_selfrouting at all.
(b) PER-ELEMENT  ✅ CLOSED AT THE ELEMENT (ca6c368).
ceC_realises_cKey_when_active -- all 192 frame pairs where
either line is active, exhaustive, kernel-checked.
⛔ AND THE NAIVE FORM IS FALSE: 28 both-idle pairs fail,
because cFrame ERASES an idle line's destination.  The
element realises the key wherever either line is active,
and the idle-idle case is a question the frame language
cannot ask.
(c) THE FOLD     ⛔ OPEN.  THIS IS ALL THAT REMAINS, and it is the whole of
seam ①.  inst_compose_frame/_first/_sem (5868b9f) are the
induction step; offsets chain by bnC_instances_are_disjoint;
bnComps_eq_batcher8 identifies the comparator list with
math's batcher8.
```

🔑 **THE INDUCTION'S SHAPE, CORRECTED BY WHAT (b) TURNED OUT TO BE.** *I wrote at
14:5x that (b) "is not a statement about one cycle — the decision LATCHES across
the header, so the induction must carry the LATCH STATE."* ⇒ ***That is true of
(b) and it is NOT true of (c), which is the useful part: (b) is stated
frame-in/frame-out, so the latch is INTERNAL to it and discharged.*** **The fold
induction is over LAYERS, not over cycles** — each element consumes two frames
and emits two frames, so the invariant is "after k comparators the frame vector
is `runNet (bnComps.take k)` of the input keys", and the latch never appears in
it.

⚠️ **AND EXHAUSTION IS NOT AVAILABLE AT THE NETWORK, measured rather than
assumed: full load with `v : Fin 8 → Dest 3` injective is a BIJECTION, so 8! =
40,320 permutations at ~18 s per network run.** *The four sampled certificates
above are a sample and say so. (c) is structural or it does not exist.*

🔑 **AND THE NON-OBVIOUS PART, WHICH IS WHERE A FIRST ATTEMPT WOULD GO WRONG:
(b) IS NOT A STATEMENT ABOUT ONE CYCLE. The element's decision is LATCHED across
the header and only settled at cycle 6** — so the per-element obligation is a
statement about a whole frame under `runTrace`, and its induction hypothesis has
to carry the LATCH STATE, not just the data. *`ce_step_eq`-style per-cycle
quantification does not compose across the header for exactly the reason the
delivery window exists.*

⇒ ***The honest shape: (a) is a definition, (c) is landed machinery, and (b) is
the real theorem — and (b)'s difficulty is the latch, not the arithmetic.***

### ⭐ THE TARGET IS NOW A LEAN STATEMENT, NOT A DESCRIPTION (silicon, 14:41)

`Silicon/Equiv/ComposedSwitch.lean` proves the composed switch **conditional on
exactly one hypothesis, and it is this one:**

```lean
hseam : hw = SaltWorks.Stack.runNet SaltWorks.Stack.batcher8 v     -- v hw : Fin 8 → ℕ
```

**Supply it and `composed_switch_of_seam` yields `banyan_selfrouting`'s three
conjuncts verbatim** — sortedness discharged by the hardware, the caller owing
only injectivity and the address bound. *The hypothesis is deletable the moment
it is supplied, which is the right way to have stated it.*

📌 **AND IT CORRECTS OBLIGATION (a) ABOVE: the order is plain `ℕ` on
DESTINATIONS, not the `(¬active, dest)` product I posited.** *So (a) is smaller
than I wrote — there is no product order to define.*

✅ **AND THE SCOPE QUESTION IS ANSWERED — BY A THEOREM, NOT A PREFERENCE
(silicon, 15:09).** *I asked whether `hi : Function.Injective v` over `Fin 8`,
with no activity component in `v`, meant FULL LOAD or an idle encoding.*

⭐ **IT IS FULL LOAD, AND IT IS FORCED RATHER THAN CHOSEN.** *At the fabricated
fabric's `k = 3`, `Injective v` and `∀ i, v i < 8` are not two independent knobs:
**eight distinct values below eight EXHAUST `Iio 8`**, so pigeonhole makes `v` a
bijection.* ⇒ **An idle sentinel would need a value `≥ 8`, hence `k ≥ 4`, hence a
SIXTEEN-line banyan — not the fabric that was fabricated.**

⛔ **AND PARTIAL LOAD IS NOT MERELY UNCOVERED — THE CONCLUSION IS FALSE THERE,
and silicon proved it rather than reassuring me** (`repeated_code_refutes_no_conflict`):
at `m = 0` the line function IS the destination, so two wires carrying equal
codes occupy one line and `no_conflict` fails outright. ⇒ ***"The composed switch
is a theorem" must not be quoted without the FULL-LOAD qualifier.***

📌 **SO OBLIGATION (a) GOES BACK, AND SILICON RETRACTED HAVING MADE ME WITHDRAW
IT.** *At full load every activity bit is 1, so `diff = 0` on the activity cycle
and the element decides nothing there — **the product order DEGENERATES to plain
`ℕ` on destinations rather than disappearing.*** ⇒ **(a) is not needed for link
② as scoped, and it IS needed for the partial-load statement, which
`bnC_concentrates_actives` above is a witness for and which nobody has stated
yet.**

**THE EXACT TARGET, with no `k` and no `hn`:**

```lean
composed_switch_of_seam_k3 {v hw : Fin 8 → ℕ}
  (hi : Function.Injective v) (hlt : ∀ i, v i < 8)
  (hseam : hw = runNet batcher8 v) : <the three conjuncts at k = 3>
```

⇒ ***Link ② is ONE theorem, about the FULL-LOAD tile.*** *Partial load wants its
own statement carrying the product order explicitly — deliberately not folded in,
because folding it in silently is how the qualifier gets lost.*

⚠️ **ONE MORE THING A SUCCESSOR MUST NOT ASSUME: the four sampled certificates
above all drive the network from the ALL-ZERO initial state.** *`Seq.lean`'s own
doctrine says a refinement must be `∀ st₀` because a deselected TinyTapeout
design is powered off, not reset.* **These four are `st₀ = 0` only, and ② must
quantify over the initial state or inherit `rst`'s self-initialisation as an
explicit lemma.** *`xorPrev_self_initialises` is the shape; nothing yet proves it
for this element.*
-/

#audit_axioms run_append_frame
#audit_axioms bnCOff_mono
#audit_axioms bnCBuild_cons
#audit_axioms bnCBuild_nil
#audit_axioms ceCcore_ssa'
#audit_axioms bnCBuild_writes_above
#audit_axioms bnCBuild_writes_strictly_above
#audit_axioms bnCBuild_element_sem
#audit_axioms bnCOff_eq bnCState_eq bnCRst_eq
#audit_axioms bnCState_lt_off bnCRst_lt_off
#audit_axioms bnCSigma_below
#audit_axioms instNext_ceCcore
#audit_axioms bnCSigma_dat_step
#audit_axioms bnCBuild_element_sem'
#audit_axioms ceCcore_state_outs_are_gates
#audit_axioms bnCBuild_state_sem
#audit_axioms bnCBuild_state_length
#audit_axioms bnCCore_outs_split
#audit_axioms bnCBuild_state_cons
#audit_axioms bnCBuild_state_slice
#audit_axioms bnCSlice bnCSlice_length bnCSlice_disjoint
#audit_axioms bnCElemIn bnCElemIn_length
#audit_axioms bnCWires bnCElems bnCRst bnCDatIn bnCIn bnCState bnCCoreIn bnCOff
#audit_axioms bnCSigma bnCBuild bnCResult bnCCore batcherNetC
#audit_axioms bnC_comps_count
#audit_axioms bnC_core_inputs
#audit_axioms bnC_core_outputs
#audit_axioms bnC_state_bits
#audit_axioms bnC_gate_count
#audit_axioms bnC_design_inputs
#audit_axioms bnC_ssa
#audit_axioms bnCCore_wf
#audit_axioms batcherNetC_wf
#audit_axioms bnC_comps_in_range
#audit_axioms bnC_every_wire_used
#audit_axioms bnC_instances_are_disjoint
#audit_axioms bnCFrames bnCRun bnCOutWire bnCExpectedPayload
#audit_axioms bnC_sorts_reversed_input
#audit_axioms bnCSparse bnCSparseExpected
#audit_axioms bnC_concentrates_actives
#audit_axioms bnCIdent bnC_identity_is_fixed
#audit_axioms bnCRot bnC_rotation_routes
#audit_axioms bnCSigma_state bnCSigma_state_injective

end SaltWorks.HDL
