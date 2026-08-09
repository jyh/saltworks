/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamJoinB
import SaltWorks.HDL.Banyan
import SaltWorks.Silicon.Equiv.FabricRoutes

/-!
# COMPILER's REFUTATION PASS on `docs/payload-delivery-design-v1.md` §6

TRACKED — promoted 17:1x. Two assignments:

* **(A)** L1/L2 (§3) against the sequential `Circ` semantics;
* **(B)** the trace shapes against B4 (`composed_switch_of_bnC_driven`,
  `SeamJoinB.lean:188`).

**VERDICTS**

| clause | verdict |
|---|---|
| L1 (§3, ceC/bnC) | **REFUTED AS WRITTEN** — true of the landed element, but only under a hypothesis §2 does not list; the repaired form is already landed |
| L2 (§3, banyan) | **REFUTED** — false in 14 of the 16 latched states of the element that has `sel_stb`, *including full-load states*; and there is no sequential banyan object in the Lean fleet for it to be about |
| B, "hypotheses extended over the full 14-cycle frame" | **CLEAN** — `n` and `L` are already free in B4; `n := 13, L := 8` instantiates it, exhibited below |
| B, "`StageOK`'s induction past the header window" | **CLEAN, on a false premise** — `StageOK`'s index is the COMPARATOR index, not a cycle; there is no header window in that induction |
| L3, "rides B4's own machinery (the hseam discharge)" | **REFUTED** — B4's conclusion factors through `cDestOf`, which is payload-blind by construction. The payload-carrying fold is a DIFFERENT landed theorem that B4 does not use |


## ⭐ WHY THIS FILE IS TRACKED — it was cited as evidence while UNSHAREABLE

**These are the ③ block's refutation exhibits, run 2026-08-08 12:28 by the compiler
seat's A/B pass. The design block cited five of them BY NAME as `kernel-exhibited` —
H3's entire justification, L2's "refuted TWICE", and L3's byte-level route refutation —
while they existed only in a GITIGNORED file.**

⛔ **Math found it at 16:09: the names resolved NOWHERE a reader could reach.** *The
mechanism is that `grep` on this machine is shimmed to a tool that obeys `.gitignore`,
so the file was invisible to the search — and I then compounded it by reporting the
file DELETED, having run `ls` in the wrong directory.*
🔑 ***Silicon's word is the one that stuck: the evidence was not MISSING, it was
UNSHAREABLE — and for every reader except the one machine it sits on, those are the
same thing.***

✅ **PROMOTED, NOT RECONSTRUCTED.** *The file builds UNCHANGED after phase 3 moved the
`as*` constants to the ruled pair — `saltbuild EXIT=0`, 32/32 ticks, verified before
promotion. Nothing here was re-derived, which is why the exhibits the doc cites are the
exhibits that ran.* 📌 *It survives the re-cut because it is about the banyan/`ceC`
seam, not the ALU select — a fact worth having measured rather than assumed.*

⚖️ **THE RULE THIS FILE EXISTS TO ENFORCE, and it now has five specimens behind it:
an evidentiary word — `kernel-exhibited` above all — MAY NOT POINT AT A GITIGNORED
FILE. Land it beside its subject, or write "measured in scratch, not preserved."**
-/

namespace PayloadRefut

open SaltWorks.HDL

/-! ## (A) L1 — "after its decide … a static 2-permutation … for every later
cycle of the frame"

### What is landed, and what it costs

The block asks "what makes the element STAY decided?" There **is** a landed
theorem, and it is `ceC_step_decided` (`SeamElement.lean:110`):

```
stepSeq ceC [true, s, ph, ba] [false, x, y]
  = ([if s then y else x, if s then x else y],
     [true, s, !ph, (!ph && (x && y)) || (ph && ba)])
```

Read the *next state*: `decided' = true`, `swap' = s`. That is the staying-power,
and it is proved, not assumed. `ceC_body_mux` (`SeamElement.lean:157`) lifts it
to a payload of any length, and `ceC_pair_full_load` (`SeamElement.lean:209`)
assembles header ++ payload. So the CONTENT of L1 is landed and is
payload-length-generic already.

### ⛔ BUT THE HYPOTHESIS IS `rst = false`, AND §2 DOES NOT LIST IT

`ceC_step_decided`'s primary-input triple is `[false, x, y]` — the leading
`false` is `rst`. It is not decoration. `ceCcore` gate ⟨8, .and 3 7⟩
(`CompareExchangeC.lean:62`) is `d = decided ∧ ¬rst`, and gate ⟨35, .or 8 34⟩
(`:89`) is `decided' = d ∨ (a decision this cycle)`. **A `rst` pulse anywhere in
the frame erases `decided` and the element re-decides from whatever bits are on
the wires that cycle** — which, mid-payload, are payload bits.

§2 of the block lists exactly two hypotheses, H1 (full load, distinct
destinations) and H2 (init: at/after the second act_stb, any register state).
Neither constrains `rst` after cycle 0, and §3's L1 clause states no hypothesis
at all. Under §2 as written, the trace below is admissible and L1 is FALSE.

*The hypothesis the block owes is exactly B4's `hrst`
(`SeamJoinB.lean:192`): `tr.map (fun i => i.getD 0 false) = true ::
List.replicate n false` — `rst` asserted on cycle 0 and LOW for every later
cycle of the frame.*
-/

/-- Line 0's payload. Bit 2 (cycle 8) is `false`. -/
def payA : List Bool := [true, true, false, true, false, false, false, false]

/-- Line 1's payload. Bit 2 (cycle 8) is `true`. -/
def payB : List Bool := [false, false, true, false, true, true, true, true]

/-- The 14-cycle frame pair: `d0 = 2`, `d1 = 5`, so `cKeyLE` says NO swap and the
element must pass both frames straight through. -/
def frA : List Bool := cFrame true 2 payA
def frB : List Bool := cFrame true 5 payB

/-- `rst` on cycle 0 only — B4's `hrst` discipline, at `n = 13`. -/
def trRstOnce : List (List Bool) :=
  (List.range 14).map fun t => [t == 0, frA.getD t false, frB.getD t false]

/-- `rst` on cycle 0 **and cycle 8** — mid-payload. Admissible under §2's H1/H2,
which say nothing about `rst`. -/
def trRstAgain : List (List Bool) :=
  (List.range 14).map fun t => [t == 0 || t == 8, frA.getD t false, frB.getD t false]

/-- The two stimuli differ in exactly one bit of one cycle: cycle 8's `rst`.
*A differential is only evidence if the mutant is one edit from the control.* -/
theorem l1_stimuli_differ_in_one_bit :
    (trRstOnce.zip trRstAgain).countP (fun p => p.1 != p.2) = 1 := by decide +kernel

/-- ✅ **CONTROL — under the `rst`-once discipline L1 holds**: the decided element
is the static identity permutation for all 14 cycles, so both frames come out
verbatim. (This is `ceC_pair_full_load` at `d0 = 2 < 5 = d1`, re-run here on the
literal 14-cycle stimulus so the refutation below is a differential and not a
broken fixture.) -/
theorem l1_holds_under_rst_once :
    (runTrace ceC [false, false, false, false] trRstOnce).1 = ceIL frA frB := by
  decide +kernel

/-- ⛔ **L1 IS FALSE AS §3 WRITES IT.** One extra `rst` cycle inside the payload
window and the element is no longer a static 2-permutation for "every later cycle
of the frame": it clears `decided`, re-decides on cycle 8 by the EVEN-phase
activity rule (`rst` forces the even phase — `ceCcore` gate ⟨10, .and 5 7⟩,
`CompareExchangeC.lean:65`), latches `swap = 1`, and swaps the two lines for
cycles 8…13. -/
theorem l1_fails_when_rst_returns :
    (runTrace ceC [false, false, false, false] trRstAgain).1 ≠ ceIL frA frB := by
  decide +kernel

/-- …and the damage is exactly a mid-frame permutation flip, not noise: cycles
0…7 are still correct and cycles 8…13 are the OTHER line's bits. *So the frame
that emerges is a well-formed `cFrame` for the right destination carrying the
wrong payload tail — invisible to any header-level invariant.* -/
theorem l1_failure_is_a_mid_frame_flip :
    (runTrace ceC [false, false, false, false] trRstAgain).1.take 8
        = (ceIL frA frB).take 8
      ∧ (runTrace ceC [false, false, false, false] trRstAgain).1.drop 8
        = (ceIL frB frA).drop 8 := by
  decide +kernel

/-!
### The second defect in L1's text: "Never-decided (two idles)"

L1 says never-decided is the two-idle case and cites the
`ce_rejects_idle_sorts_low` family. Two corrections, both from landed source:

1. **The enumeration is wrong.** There is a THIRD never-decided-inside-the-header
   case: two ACTIVE lines with the SAME destination. Their headers are
   bit-identical, no decision fires in `[0, 2k)`, and the element latches on
   payload bit 0 — `ceC_pair_tie_splices_the_payload` (`SeamElement.lean:307`),
   whose own docstring records that the result is "a spliced frame — one line's
   header with the other's payload — still a well-formed `cFrame` for the right
   destination, so the defect is invisible to any header-level invariant."
   H1 excludes it at the fabric input; the invariant that carries it to every
   INTERIOR comparator is `StageOK`'s distinctness clause (`SeamJoinA.lean:187`),
   which is a hypothesis of B4, not a consequence of H1 alone.
2. **The citation is to the wrong theorem.** `ceC_rejects_idle_sorts_low`
   (`CompareExchangeC.lean:249`) is a MUTATION CONTROL: it refutes the
   idle-sorts-LOW mutant. The straight-through statement for two idle lines is
   `ceC_frame_two_idle_stable` (`CompareExchangeC.lean:232`). Right conclusion,
   wrong reason.
-/

/-! ## (A) L2 — "after sel_stb (cycle 2s+1), the banyan element is a static
2-permutation for the rest of the frame — a locked element is a wire"

### ⛔ FIRST: THERE IS NO SEQUENTIAL BANYAN IN THE LEAN FLEET

The HDL lane's banyan is `fabric` (`Banyan.lean:132`), and it is a **`Circ`, not
a `Seq`** — it has no state field, no cycle index, and therefore no `sel_stb` to
be "after". Its 48 claim signals are PRIMARY INPUTS (`fabric3_shape`,
`Banyan.lean:141`: `nIn = 56` = 8 data + 48 claims), supplied in
`fabric3_routes` by the oracle `fabricEnv` (`Banyan.lean:166`), which computes
them from `SaltWorks.Banyan.line`/`srcAt` — from the ROUTING FUNCTION, never
from the header bits on the wire.

⚠️ *Method note, stated because fleet law bars name-grep for absence claims: I
enumerated `: Seq` / `Seq :=` across `SaltWorks/` and read the seven machines it
returned (`xorPrev`, `ce`, `ceC`, `ceCIdleLow`, `ceCUngated`, `batcherNet`,
`batcherNetC`); none is a banyan. **I did not prove this by removal.** The
positive, structural half — that `fabric` is a `Circ` whose claims are primary
inputs — is `fabric3_shape` and is proof.*

### SECOND: AGAINST THE ELEMENT THAT DOES HAVE `sel_stb`, L2 IS FALSE

That element is `bitserial_switch.v` → `switchSpec`
(`Silicon/Equiv/SwitchRefinement.lean:77-105`) → `elemOut`/`elemNext`
(`Silicon/Equiv/FabricRoutes.lean:59,66`), the three tied together by
`switch_step_eq` and `elem_matches_spec` (`FabricRoutes.lean:75`). Its
combinational output map, once `act_stb`/`sel_stb` have passed and the four
flops hold `(act0, act1, sel0, sel1)`, is

```
out0 = (act0 ∧ ¬sel0 ∧ in0) ∨ (act1 ∧ ¬sel1 ∧ in1)
out1 = (act0 ∧  sel0 ∧ in0) ∨ (act1 ∧  sel1 ∧ in1)
```

**That is a claim-gated OR, not a mux.** It is a 2-permutation of its two lines
in exactly 2 of the 16 latched states. In the other 14 it is either a MERGE (both
inputs OR'd onto one port, the other port constant 0) or a DROP (one input
passed, zero-fill on the other port). -/

/-- The landed element's output map, as a function of the four latched bits.
`SaltWorks.Silicon.Imported.elemOut`, `FabricRoutes.lean:59`. -/
def swOut (e : SaltWorks.Silicon.Imported.Elem) (i0 i1 : Bool) : Bool × Bool :=
  SaltWorks.Silicon.Imported.elemOut e i0 i1

def swIsIdent (e : SaltWorks.Silicon.Imported.Elem) : Bool :=
  bools.all fun a => bools.all fun b =>
    ((swOut e a b).1 == a) && ((swOut e a b).2 == b)

def swIsSwap (e : SaltWorks.Silicon.Imported.Elem) : Bool :=
  bools.all fun a => bools.all fun b =>
    ((swOut e a b).1 == b) && ((swOut e a b).2 == a)

/-- "A locked element is a wire" = "the locked map is a static 2-permutation". -/
def swIsWire (e : SaltWorks.Silicon.Imported.Elem) : Bool := swIsIdent e || swIsSwap e

/-- All 16 latched states `(act0, act1, sel0, sel1)`. -/
def lockedStates : List (Bool × Bool × Bool × Bool) :=
  bools.flatMap fun a0 => bools.flatMap fun a1 =>
  bools.flatMap fun s0 => bools.map fun s1 => (a0, a1, s0, s1)

theorem lockedStates_count : lockedStates.length = 16 := by decide +kernel

/-- ⛔⛔ **L2 IS FALSE IN 14 OF THE 16 LATCHED STATES.** -/
theorem l2_locked_is_a_wire_in_two_states :
    (lockedStates.filter swIsWire).length = 2 := by decide +kernel

/-- …and the two are exactly "both ports active, opposite select bits". *So the
hypothesis L2 omits is `act0 ∧ act1 ∧ (sel0 ≠ sel1)`.* -/
theorem l2_the_two_wire_states :
    lockedStates.filter swIsWire = [(true, true, false, true), (true, true, true, false)] := by
  decide +kernel

/-- ⛔ **AND THE MISSING HYPOTHESIS IS NOT COVERED BY §2's IDLE RIDER.** §2 waves
the non-permutation cases away as "idle non-interference (vacuous at full load)".
Here is a **FULL-LOAD** counterexample: both ports ACTIVE, both latched selects
`0`. The element ORs the two lines onto `out0` and drives `out1` to `0` — two
distinct input pairs map to one output pair, so it is not even injective, let
alone a permutation. *This is `banyan_selfrouting`'s `no_conflict`, and it is
nowhere in H1/H2.* -/
theorem l2_full_load_conflict_merges :
    swOut (true, true, false, false) true false = swOut (true, true, false, false) false true
      ∧ swOut (true, true, false, false) true false = (true, false) := by
  decide +kernel

/-- ⛔ …and the partial-load failure is a DROP, not a swap: with `act1 = 0` the
element passes `in0` and zero-fills the other port, discarding `in1` entirely.
*`bitserial_switch.v:81` calls this "idleness propagates correctly"; it is correct
behaviour and it is still not a 2-permutation.* -/
theorem l2_idle_partner_drops_the_line :
    swOut (true, false, false, true) false true = (false, false) := by decide +kernel

/-- ⛔ **AND L1/L2 ARE NOT "TWO OF ONE SHAPE" (§3's heading).** `ceC` decided is a
2-permutation in EVERY decided state — `ceC_step_decided` is unconditional in
`s`, `ph`, `ba` — while the banyan element is a 2-permutation in 2 of its 16
latched states. The two counts side by side, over the same 16-element list.

⚠️ **SCOPE, so `16` is not misread**: `ceC` has only **8** decided states
(`swap`, `phase`, `bothAct`); the second conjunct reuses `lockedStates` as a
`(swap, phase, bothAct, unused)` enumeration, so it checks each of the 8 twice.
The honest reading is "8 of 8 against 2 of 16", and the list lengths are equal
only so the two `.length`s are directly comparable. -/
theorem l1_l2_are_not_the_same_shape :
    (lockedStates.filter swIsWire).length = 2
      ∧ (lockedStates.filter (fun q =>
          bools.all fun x => bools.all fun y =>
            (stepSeq ceC [true, q.1, q.2.1, q.2.2.1] [false, x, y]).1
              == [if q.1 then y else x, if q.1 then x else y])).length = 16 := by
  decide +kernel

/-! ### What L2 was reaching for, and where it already exists

`fabric_routes` (`Silicon/Equiv/FabricRoutes.lean:231`) already certifies
**payload delivery through the banyan over the full 14-cycle frame**: `runFrame`
(`:132`) runs 14 cycles with the strobe schedule `act_stb = (cnt = 2s)`,
`sel_stb = (cnt = 2s+1)` (`:129`), and `routesOK` (`:192`) checks output cycles
`6 + t` for `t ∈ [0,8)` — the `[2k, 2k+P)` window — against a per-source
distinguishable payload, over all 255 concentrated destination sets, PARTIAL LOAD
INCLUDED.

⚠️ **What it does NOT carry is §2's H2.** `runFrame initFabric` (`:193`,
`initFabric := List.replicate 12 (false,false,false,false)`, `:102`) pins all 48
banyan flops at the all-false state. The block's H2 ("from ANY initial register
state") is therefore **discharged for the sorter** (`ceC_step_reset` /
`ceFrameTrace_from_any_state`, `SeamElement.lean:119,126`, and `st` is free in
B4) and **NOT discharged for the banyan**. That asymmetry is the honest statement
of what the successor theorem still owes on the banyan side — and it is not what
§3 says is owed.
-/

/-! ## (B) THE TRACE SHAPES AGAINST B4

### B4's hypotheses, read off `SeamJoinB.lean:188-195`

```
(st : List Bool) (tr : List (List Bool)) (n L : Nat)
(d : Fin 8 → Nat) (hd : ∀ i, d i < 8) (hdi : Function.Injective d)
(p : Fin 8 → List Bool)
(hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
(h0   : StageOK st tr L 0)
(hin  : ∀ i : Fin 8, tr.map (fun c => c.getD (1 + i.val) false) = cFrame true (d i) (p i))
```

### ✅ CLEAN — "extended over the full 14-cycle frame" needs no extension

`n` and `L` are **free variables of B4**. `hrst` pins `tr.length = n + 1`; `hin`
pins `tr.length = 6 + (p i).length`; `h0` pins every payload to length `L`. The
14-cycle frame is the instance `n := 13, L := 8`, and `hrst` says the same thing
there that it says anywhere: `rst` high on cycle 0, low on cycles 1…13. **No
hypothesis changes meaning.** Exhibited below on a real 14-cycle stimulus.

### ✅ CLEAN, ON A FALSE PREMISE — `StageOK` has no header window

The assignment asks whether `StageOK`'s induction carries past the header window.
It has no cycle index to carry past: `StageOK st tr L k` (`SeamJoinA.lean:185`)
is indexed by the **COMPARATOR** index, and `stageOK_all` (`:329`) inducts over
`k ≤ 24` — the 24 comparators of `batcher8`. Its frame clause is
`bnCFrameAt st tr k w = cFrame true d p` with `p.length = L` — a WHOLE frame,
payload included, for arbitrary `L`. `frames_succ_perm` (`:267`) transports whole
frames. Nothing in that induction is header-window-limited.
-/

/-- A per-line distinguishable 8-bit payload — the shape `FabricRoutes.payloadOf`
(`:152`) uses, so the two lanes' fixtures are comparable. -/
def pay14 (w : Nat) : List Bool := (List.range 8).map (fun b => Nat.testBit (w + 1) b)

/-- A **14-cycle** driven trace: eight active frames, destinations `7,6,…,0`
(distinct, worst order), an 8-bit payload each, `rst` on cycle 0 only. -/
def fixture14 : List (List Bool) :=
  (List.range 14).map (fun t =>
    (t == 0) :: (List.range 8).map (fun w => (cFrame true (7 - w) (pay14 w)).getD t false))

theorem fixture14_length : fixture14.length = 14 := by decide +kernel

/-- `hrst` at `n = 13`. -/
theorem fixture14_rst :
    fixture14.map (fun i => i.getD 0 false) = true :: List.replicate 13 false := by
  decide +kernel

/-- `hin` at `d i = 7 - i`, `p i = pay14 i`. -/
theorem fixture14_cols (w : Nat) (hw : w < 8) :
    fixture14.map (fun i => i.getD (1 + w) false) = cFrame true (7 - w) (pay14 w) := by
  interval_cases w <;> decide +kernel

/-- `h0` at `L = 8`. -/
theorem fixture14_stageOK (st : List Bool) : StageOK st fixture14 8 0 := by
  refine stageOK_zero_of_inputs st fixture14 8 ?_ ?_
  · intro w hw
    exact ⟨7 - w, pay14 w, by omega, by simp [pay14], fixture14_cols w hw⟩
  · intro w₁ w₂ h1 h2 hne
    rw [fixture14_cols w₁ h1, fixture14_cols w₂ h2,
        cDestOf_cFrame _ (by omega) _, cDestOf_cFrame _ (by omega) _]
    omega

theorem d14_inj : Function.Injective (fun i : Fin 8 => 7 - i.val) := by
  intro i j h
  have hi := i.isLt
  have hj := j.isLt
  simp only at h
  exact Fin.ext (by omega)

/-- ⭐ **B4 APPLIES VERBATIM AT 14 CYCLES.** `n := 13`, `L := 8`, every hypothesis
discharged from the stimulus, the initial state `st` still arbitrary. *This is the
positive half of (B): the "extension" the block asks for is an instantiation.* -/
theorem b4_at_14_cycles (st : List Bool) :
    (∀ m ≤ 3, Set.InjOn
        (fun s => SaltWorks.Banyan.line m s
          (SaltWorks.Stack.extendIio 0 (bnCOutKey st fixture14) s)) (Set.Iio 8)) ∧
      (∀ s < 8, SaltWorks.Banyan.line 3 s
        (SaltWorks.Stack.extendIio 0 (bnCOutKey st fixture14) s) = s) ∧
      (∀ s, SaltWorks.Banyan.line 0 s
        (SaltWorks.Stack.extendIio 0 (bnCOutKey st fixture14) s)
          = SaltWorks.Stack.extendIio 0 (bnCOutKey st fixture14) s) :=
  composed_switch_of_bnC_driven st fixture14 13 8
    (fun i => 7 - i.val) (fun _ => by omega) d14_inj (fun i => pay14 i.val)
    fixture14_rst (fixture14_stageOK st) (fun i => fixture14_cols i.val i.isLt)

/-! ### ⛔ L3 IS REFUTED — B4's machinery cannot carry a payload

§3's L3 says the composition rides "B4's own machinery (the hseam discharge)".
It cannot. `bnC_seam_runNet` (`SeamJoinB.lean:94`) concludes

    bnCOutKey st tr = runNet batcher8 (bnCInKey st tr)

and `bnCOutKey` (`SeamJoinB.lean:86`) is `cDestOf ∘ (output column)`. `cDestOf`
(`SeamJoinA.lean:45`) reads stream indices **1, 3 and 5 and nothing else**. It is
payload-blind by construction, so B4's conclusion is preserved by every
payload-mangling transformation — including the two the landed source already
exhibits (`ceC_pair_tie_splices_the_payload`, `SeamElement.lean:307`, and
`l1_failure_is_a_mid_frame_flip` above). -/

/-- ⛔ **THE PAYLOAD IS INVISIBLE TO B4's CONCLUSION**: two frames differing in
every payload bit have the same key. -/
theorem cDestOf_is_payload_blind :
    cDestOf (cFrame true 5 (List.replicate 8 false))
        = cDestOf (cFrame true 5 (List.replicate 8 true))
      ∧ cFrame true 5 (List.replicate 8 false) ≠ cFrame true 5 (List.replicate 8 true) := by
  decide +kernel

/-! ### ✅ …AND THE MACHINERY L3 ACTUALLY NEEDS IS ALREADY LANDED, ELSEWHERE

`bnC_output_frames_are_the_fold` (`SeamTrace.lean:1242`) — *"the network's EIGHT
OUTPUT FRAMES are `runNet`-over-`bnComps` applied to its eight INPUT FRAMES"* —
is the whole-frame, payload-carrying fold, and it consumes the **same**
`∀ k < 24, ElemSortsAt …` premise that `elemSortsAt_all` (`SeamJoinA.lean:342`)
discharges from B4's own `hrst` + `h0`. So the sorter half of L3 is a
**three-line composition of two landed theorems**, and it is not the hseam
discharge. Here it is. -/

/-- ⭐⭐ **THE SORTER HALF OF L3, WHOLE-FRAME, FROM B4's OWN HYPOTHESES.** Payload
included, frame length arbitrary (so 14 cycles in particular), initial state
arbitrary. *`ElemSortsAt` does not appear; the hypotheses are `hrst` and `h0`,
character for character B4's.* -/
theorem bnC_output_frames_driven
    (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st tr L 0) (w : Nat) (hw : w < 8) :
    (runTrace batcherNetC st tr).1.map (fun o => o.getD w false)
      = runNetF (fun x y => decide (cDestOf x ≤ cDestOf y)) bnComps
          (fun i => bnCFrameAt st tr 0 i) w :=
  bnC_output_frames_are_the_fold st tr _ (elemSortsAt_all st tr n L hrst h0) w hw

/-- …at the 14-cycle fixture, `st` still arbitrary. -/
theorem bnC_output_frames_at_14_cycles (st : List Bool) (w : Nat) (hw : w < 8) :
    (runTrace batcherNetC st fixture14).1.map (fun o => o.getD w false)
      = runNetF (fun x y => decide (cDestOf x ≤ cDestOf y)) bnComps
          (fun i => bnCFrameAt st fixture14 0 i) w :=
  bnC_output_frames_driven st fixture14 13 8 fixture14_rst (fixture14_stageOK st) w hw

/-!
### THE REMAINING GAP ON THE SORTER SIDE, NAMED

`bnC_output_frames_driven` says the output frame vector is
`runNetF le bnComps` of the input frame vector. To get §2's CLAIM
(`output (σ (dest i)) t = input i t`) one still needs **`runNetF` to be a
PERMUTATION of the frame vector, with `σ` the SAME permutation B4's key-level
conclusion names.** The one-comparator version is landed —
`frames_succ_perm` (`SeamJoinA.lean:267`):

```
∃ σ : Nat → Nat, (∀ w < 8, σ w < 8) ∧ (injective on [0,8)) ∧
  (∀ w, bnCFrameAt st tr (k+1) w = bnCFrameAt st tr k (σ w))
```

— but its `σ` is **existential and discarded**: `stageOK_succ` (`:313`) consumes
it only to transport the invariant, and nothing composes the 24 per-comparator
`σ`s into one. That composition, plus the (easy, `cKeyLE_full_load`-shaped)
agreement of the frame-level `σ` with the key-level `runNet batcher8`, is the
actual C-class work L3 hides behind "rides B4's machinery".

### SUMMARY OF REPAIRS OWED BY THE BLOCK

1. **§2** must add a third hypothesis, H3: `rst` asserted on cycle 0 and low for
   cycles 1…13 — B4's `hrst`. Without it L1 is false (`l1_fails_when_rst_returns`).
2. **§3 L1** must say "never-decided-in-the-header" has THREE cases, not one, and
   cite `ceC_frame_two_idle_stable` rather than the `..._rejects_idle_sorts_low`
   mutation control.
3. **§3 L2** must add `act0 ∧ act1 ∧ (sel0 ≠ sel1)` at each banyan element — i.e.
   `banyan_selfrouting`'s `no_conflict` at full load — or it is false in 14 of 16
   latched states, and the full-load conflict case is not covered by §2's idle
   rider. It must also name which object it is about: there is no banyan `Seq`.
4. **§3's "two of one shape"** is wrong: `ceC` is a mux, the banyan element is a
   claim-gated OR.
5. **§3 L3** must cite `bnC_output_frames_are_the_fold`, not the hseam discharge,
   and must name the un-landed piece: composing `frames_succ_perm`'s 24 `σ`s.
6. **§0/§4** should record that `fabric_routes` already certifies banyan payload
   delivery over the 14-cycle window at partial load, and that what it lacks is
   H2 (arbitrary initial banyan state), not the payload claim.
-/

#audit_axioms payA
#audit_axioms payB
#audit_axioms frA
#audit_axioms frB
#audit_axioms trRstOnce
#audit_axioms trRstAgain
#audit_axioms l1_stimuli_differ_in_one_bit
#audit_axioms l1_holds_under_rst_once
#audit_axioms l1_fails_when_rst_returns
#audit_axioms l1_failure_is_a_mid_frame_flip
#audit_axioms swOut
#audit_axioms swIsIdent
#audit_axioms swIsSwap
#audit_axioms swIsWire
#audit_axioms lockedStates
#audit_axioms lockedStates_count
#audit_axioms l2_locked_is_a_wire_in_two_states
#audit_axioms l2_the_two_wire_states
#audit_axioms l2_full_load_conflict_merges
#audit_axioms l2_idle_partner_drops_the_line
#audit_axioms l1_l2_are_not_the_same_shape
#audit_axioms pay14
#audit_axioms fixture14
#audit_axioms fixture14_length
#audit_axioms fixture14_rst
#audit_axioms fixture14_cols
#audit_axioms fixture14_stageOK
#audit_axioms d14_inj
#audit_axioms b4_at_14_cycles
#audit_axioms cDestOf_is_payload_blind
#audit_axioms bnC_output_frames_driven
#audit_axioms bnC_output_frames_at_14_cycles

end PayloadRefut
