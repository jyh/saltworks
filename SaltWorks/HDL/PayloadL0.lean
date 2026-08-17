/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement

/-!
# L0 — INIT-INDEPENDENCE, THE PAYLOAD-DELIVERY INDUCTION'S SEED

`docs/payload-delivery-design-v1.md` §3, L0:

> Within a WELL-PHASED frame, every per-stage control latch value **from its
> strobe cycle onward is a function of the frame's own header bits, from ANY
> initial register state.**

**Formalized as a COUPLING statement**, which is what "independent of initial
state" means operationally and what makes L0 usable as a seed: run the element
from **two arbitrary and possibly different initial latch states** on the **same
input trace**; the control-latch values AGREE.

## ⚠️ TWO THINGS A SUCCESSOR SHOULD KNOW ABOUT THIS FILE

**(1) §3's WORDING IS ONE WORD TOO STRONG, AND THIS FILE MEASURES IT.**
`l0_header_bits_alone_do_not_fix_the_bothAct_latch`: with identical headers and a
changed line-0 payload, `[decided, swap]` agrees for the whole frame, but the FULL
latch vector does not — `bothAct'` samples the data wires on every even cycle,
payload cycles included. So "a function of the frame's own **header** bits" is
literally false of the latch vector. Bit 3 is the bit `ceC_fourth_state_bit_is_dead`
proves nothing reads under the protocol, so **the routing conclusion is untouched —
the repair is the SENTENCE**, either "the frame's own bits" or "control latch"
restricted to `[decided, swap]`.

**(2) `set_option maxRecDepth 8000` IS FILE-SCOPE AND UNTESTED.**
No single declaration is identified as needing it, and every future declaration here
inherits it silently — the same shape as a silent cap. *A successor tightening this
file should try REMOVING it and read which goal actually fails; the phrasing is
usually the cost, not the circuit.* Recorded rather than fixed, because it was found
mid-wave.

## ⭐ AND THE METHODOLOGICAL FINDING, which is why L0 is stated on LATCHES

`l0_late_strobe_output_form_is_blind`: on a late-strobe frame the **output** trace is
init-independent (1 behaviour, 0 disagreeing pairs) **and wrong** — payloads exchanged,
from every initial state including the canonical one — while the **latch** trace has 9
behaviours. ⇒ ***An L0 stated on outputs would report GREEN on a frame that delivers
the wrong payload.*** That is the argument for stating the seed on latches, and it was
measured rather than reasoned.

## What is proved here, and over what

* The artifact is `ceC` (`CompareExchangeC.lean:98`), a real `Seq` — 4 latches
  (`decided, swap, phase, bothAct`), 3 primary inputs (`rst, in0, in1`), 34
  gates. The datapath is combinational, so those 4 latches (plus the fabric's
  frame counter, see the scope note) ARE the whole init surface.
* The stepper is the artifact's own `stepSeq` / `runTrace` (`Seq.lean:71,78`).
  **No new simulator was written**: `latchAt m st tr t := (runTrace m st (tr.take
  t)).2` is a projection of `runTrace`, the exact analogue of the landed
  `outAt` (`Seq.lean:100`), and `latchAt_full` pins it against `runTrace`'s own
  returned final state.
* **Well-phasedness at this element is the frame-start strobe on cycle 0.** §2's
  H2 says well-phasedness is "established by `sof` or `rst_n`"; `ceC`'s only
  phase-setting port is `rst` (gate `⟨10, .and 5 7⟩` — `rst` forces the even
  phase), and B4's `hrst` binder / §2's H3 put exactly one pulse at cycle 0. So
  L0's hypothesis is discharged here as `i.getD 0 false = true` on cycle 0 of the
  trace — an INPUT EVENT, never read off a frame count, as §3 requires.

## THREE WAYS THIS IS STRONGER THAN §3's TEXT — stated so nobody re-prices it

1. **"from its strobe cycle onward" → from CYCLE 1 onward.** Stage strobes sit at
   cycles 2s and 2s+1 (s = 0,1,2), i.e. inside [0,6). Agreement is proved from
   cycle 1, which is earlier than every stage's own strobe but one. Cycle 0 is
   *not* claimed and cannot be — the latch values at cycle 0 *are* the two given
   initial states (`l0_cycle_zero_is_excluded`), and the header window [0,2k) is
   don't-care by §2's own rider, so `.tail` is exactly tight.
2. **"a function of the frame's own header bits" → the function is EXHIBITED**:
   run from the canonical zero state (`l0_latches_are_a_function_of_the_frame`),
   which is the functional reading of the coupling form with the function named
   rather than asserted. ⚠️ **But read as "of the HEADER bits only" §3's sentence
   is one word too strong, and that is measured, not argued** — see
   `l0_header_bits_alone_do_not_fix_the_bothAct_latch` below: the routing pair
   `[decided, swap]` and `phase` ARE header-only, the fourth latch `bothAct`
   samples the data wires on every even cycle, payload cycles included. Bit 3 is
   the bit `ceC_fourth_state_bit_is_dead` proves nothing reads under the
   protocol, so the routing conclusion is untouched — **the repair is §3's
   wording, not the hardware and not L0 as proved here.**
3. **The hypothesis is on the STROBE BIT ALONE, not on the frame shape.** §3
   states L0 "within a well-phased frame"; the theorem needs only that cycle 0
   carries the strobe, so it applies verbatim to the network's per-element trace
   `bnCElemTrace` (§4's composition target) and not merely to `ceFrameTrace`.

## THE NEGATIVE CONTROL — well-phasedness is load-bearing, and it is ONE BIT

`l0TrWP` and `l0TrMis` present the SAME 14 frame bits and differ in exactly one
bit of one cycle: cycle 0's strobe (`l0_wellphased_and_misphased_differ_in_one_bit`).

| over the 16 initial latch states  | distinct latch behaviours | disagreeing ordered pairs |
|-----------------------------------|---------------------------|---------------------------|
| well-phased  (`l0TrWP`)           | **1**                     | **0** / 256               |
| strobe absent (`l0TrMis`)         | **9**                     | **220** / 256             |
| strobe one cycle late (`l0TrLate`)| **9**                     | **220** / 256             |

and the un-hypothesized statement is refuted outright, at both the latch level
and the output level (`l0_is_false_without_the_strobe`,
`l0_output_form_is_false_without_the_strobe`) — the mis-phased failure is a
*wrong-payload delivery*: from `[decided, swap] = [1,1]` the element is a frozen
crossing mux and the two payloads come out exchanged, in well-formed frames.

⚠️ **AND THE LATCH FORM CATCHES A FAILURE THE OUTPUT FORM CANNOT SEE.** On
`l0TrLate` the output trace is init-INDEPENDENT (1 distinct behaviour) and
*wrong* — swapped — from every initial state including the canonical one, while
the latch trace has 9. An L0 stated on outputs would pass this frame. That is why
§3 states L0 on LATCHES, and it is the reason to prefer this form.

## SCOPE, AND WHAT IS **NOT** PROVED (stated as unproved, not worked around)

* **The frame counter has no Lean model in this repo.** §3's init surface is
  "the per-stage latches PLUS the frame counter"; the counter lives in
  `SaltWorks/Silicon/RTL/banyan_fabric.v:44-47` and appears nowhere in the Lean
  fabric. At the element, `phase` is its 1-bit analogue and IS covered. The
  counter half of §3's init surface is therefore **not** discharged in Lean here
  — it is discharged by hypothesis (the strobe), exactly as §3 says
  ("the counter is exactly what well-phased quantifies away"), and the RTL-side
  measurement is silicon's 13:47 arm, not a theorem.
* **The full network lift is NOT proved.** `l0_network_slice_forgets_own_slice`
  gets the honest half: element `e`'s slice of the network's next state is a
  function of element `e`'s INPUT TRACE alone, its own initial slice erased, for
  every `e < 24` and every network state. The remaining gap is named:
  `bnCElemInAt st inp e = bnCElemInAt st' inp e` under the strobe, i.e. that the
  *data* bits an interior element sees are themselves state-independent. That is
  a cascade induction over the 24-instance build (it is true for stage-0 elements
  by `bnCWireAt_zero`, whose nets are primary inputs) and it is **C-class, not
  attempted here**.
* **Mis-phasing is modelled two ways only** — strobe absent from the window, and
  strobe one cycle late. A rotation of the frame bits against a free-running
  counter is the fabric-level model and needs the counter, which Lean does not
  have.
* P = 8 only (`l0_at_P8_length` pins the 14), per §5. The general theorems are
  ∀-trace and so are P-agnostic; only the fixtures are at P = 8.
-/

namespace SaltWorks.HDL

set_option maxRecDepth 8000

/-! ## 1. THE INSTRUMENT — latch values, as a projection of the artifact's `runTrace` -/

/-- The latch vector at the start of cycle `t`: the state `runTrace` is left in
after `t` cycles. **This is not a second simulator** — it is `runTrace`, the
analogue of the landed `outAt`. -/
def latchAt (m : Seq) (st : List Bool) (tr : List (List Bool)) (t : Nat) : List Bool :=
  (runTrace m st (tr.take t)).2

/-- The whole latch trace, cycles `0 … tr.length`. The window's bounds are IN the
object, per §4's whole-window trap. -/
def latchTrace (m : Seq) (st : List Bool) (tr : List (List Bool)) : List (List Bool) :=
  (List.range (tr.length + 1)).map (latchAt m st tr)

theorem latchAt_zero (m : Seq) (st : List Bool) (tr : List (List Bool)) :
    latchAt m st tr 0 = st := rfl

/-- ⭐ **THE TIE TO THE LANDED RUN FUNCTION.** At the end of the trace the
instrument reads exactly the state `runTrace` itself returns, so `latchAt` cannot
drift from the artifact's semantics. -/
theorem latchAt_full (m : Seq) (st : List Bool) (tr : List (List Bool)) :
    latchAt m st tr tr.length = (runTrace m st tr).2 := by
  simp [latchAt]

theorem latchTrace_length (m : Seq) (st : List Bool) (tr : List (List Bool)) :
    (latchTrace m st tr).length = tr.length + 1 := by
  simp [latchTrace]

theorem latchTrace_tail (m : Seq) (st : List Bool) (tr : List (List Bool)) :
    (latchTrace m st tr).tail = (List.range tr.length).map (fun t => latchAt m st tr (t + 1)) := by
  simp [latchTrace, List.range_succ_eq_map, Function.comp]

/-! ## 2. THE STROBE ERASES THE LATCHES — one cycle, any state, any input word -/

/-- `ceC` reads its input word at nets `0,1,2` and nowhere else, so the whole
environment is fixed by the first three bits. *Needed because the network hands
elements a 3-bit word built by `bnCElemInAt`, and `ceC_step_reset` is stated on a
literal triple.* -/
theorem ceC_env_input_trunc (i st : List Bool) :
    ∀ j, ceC.env i st j = ceC.env [i.getD 0 false, i.getD 1 false, i.getD 2 false] st j := by
  intro j
  show (if j < ceC.nIn then i.getD j false else st.getD (j - ceC.nIn) false)
      = (if j < ceC.nIn then _ else st.getD (j - ceC.nIn) false)
  by_cases h : j < ceC.nIn
  · rw [if_pos h, if_pos h]
    have h3 : j < 3 := h
    interval_cases j <;> rfl
  · rw [if_neg h, if_neg h]

theorem ceC_step_input_trunc (st i : List Bool) :
    stepSeq ceC st i = stepSeq ceC st [i.getD 0 false, i.getD 1 false, i.getD 2 false] := by
  simp only [stepSeq]
  rw [sem_congr ceC.core (ceC_env_input_trunc i st)]

/-- ⭐ **THE SEED, AT ONE CYCLE.** A cycle whose input word carries the
frame-start strobe produces the same outputs AND the same next state from any two
initial latch states. *This is `ceC_step_reset` (`SeamElement.lean:119`) lifted
off the literal `[true, x, y]` shape onto an arbitrary input word.* -/
theorem ceC_step_strobe_erases (a b c d a' b' c' d' : Bool) (i : List Bool)
    (hi : i.getD 0 false = true) :
    stepSeq ceC [a, b, c, d] i = stepSeq ceC [a', b', c', d'] i := by
  rw [ceC_step_input_trunc [a, b, c, d] i, ceC_step_input_trunc [a', b', c', d'] i, hi]
  exact (ceC_step_reset a b c d _ _).trans (ceC_step_reset a' b' c' d' _ _).symm

/-- Two runs that agree on cycle 0 — outputs and next state — agree forever. -/
theorem runTrace_cons_congr (m : Seq) (st st' i : List Bool) (rest : List (List Bool))
    (h : stepSeq m st i = stepSeq m st' i) :
    runTrace m st (i :: rest) = runTrace m st' (i :: rest) := by
  simp only [runTrace, h]

theorem ceC_run_strobe_erases (a b c d a' b' c' d' : Bool) (i : List Bool)
    (rest : List (List Bool)) (hi : i.getD 0 false = true) :
    runTrace ceC [a, b, c, d] (i :: rest) = runTrace ceC [a', b', c', d'] (i :: rest) :=
  runTrace_cons_congr ceC _ _ i rest (ceC_step_strobe_erases a b c d a' b' c' d' i hi)

/-! ## 3. ⭐⭐ L0 -/

/-- L0, per cycle: from cycle 1 onward the control latches agree, from two
arbitrary initial latch states, on any trace whose cycle 0 carries the strobe. -/
theorem l0_latch_agreement (a b c d a' b' c' d' : Bool) (i : List Bool)
    (rest : List (List Bool)) (hi : i.getD 0 false = true) (t : Nat) :
    latchAt ceC [a, b, c, d] (i :: rest) (t + 1)
      = latchAt ceC [a', b', c', d'] (i :: rest) (t + 1) := by
  simp only [latchAt, List.take_succ_cons]
  exact congrArg Prod.snd (ceC_run_strobe_erases a b c d a' b' c' d' i (rest.take t) hi)

/-- ⭐⭐ **L0, WHOLE-WINDOW.** The whole latch trace from cycle 1 to the end of the
frame — bounds inside the statement, not a per-sample form — agrees between two
arbitrary initial latch states. -/
theorem l0_whole_frame (a b c d a' b' c' d' : Bool) (i : List Bool)
    (rest : List (List Bool)) (hi : i.getD 0 false = true) :
    (latchTrace ceC [a, b, c, d] (i :: rest)).tail
      = (latchTrace ceC [a', b', c', d'] (i :: rest)).tail := by
  rw [latchTrace_tail, latchTrace_tail]
  exact List.map_congr_left fun t _ => l0_latch_agreement a b c d a' b' c' d' i rest hi t

/-- …and with the state as a bare `∀ st`, since `ceC.nState = 4`. -/
theorem l0_any_state_list (st st' i : List Bool) (rest : List (List Bool))
    (hs : st.length = 4) (hs' : st'.length = 4) (hi : i.getD 0 false = true) :
    (latchTrace ceC st (i :: rest)).tail = (latchTrace ceC st' (i :: rest)).tail := by
  obtain ⟨a, b, c, d, rfl⟩ : ∃ a b c d, st = [a, b, c, d] := by
    match st, hs with
    | [a, b, c, d], _ => exact ⟨a, b, c, d, rfl⟩
  obtain ⟨a', b', c', d', rfl⟩ : ∃ a b c d, st' = [a, b, c, d] := by
    match st', hs' with
    | [a, b, c, d], _ => exact ⟨a, b, c, d, rfl⟩
  exact l0_whole_frame a b c d a' b' c' d' i rest hi

/-- ⭐ **THE FUNCTIONAL READING, WITH THE FUNCTION EXHIBITED.** §3's "is a
function of the frame's own bits" — the function is "run from the canonical zero
state", and every initial state gives that answer. -/
theorem l0_latches_are_a_function_of_the_frame (a b c d : Bool) (i : List Bool)
    (rest : List (List Bool)) (hi : i.getD 0 false = true) :
    (latchTrace ceC [a, b, c, d] (i :: rest)).tail
      = (latchTrace ceC [false, false, false, false] (i :: rest)).tail :=
  l0_whole_frame a b c d false false false false i rest hi

/-- The output-side companion (which the datapath being combinational makes the
delivery statement). *A strict generalization of the landed
`ceFrameTrace_from_any_state` (`SeamElement.lean:126`): no frame shape, no
non-emptiness side conditions, and both states free.* -/
theorem l0_output_agreement (a b c d a' b' c' d' : Bool) (i : List Bool)
    (rest : List (List Bool)) (hi : i.getD 0 false = true) :
    (runTrace ceC [a, b, c, d] (i :: rest)).1 = (runTrace ceC [a', b', c', d'] (i :: rest)).1 :=
  congrArg Prod.fst (ceC_run_strobe_erases a b c d a' b' c' d' i rest hi)

/-- ⛔ **CYCLE 0 IS NOT CLAIMED, AND CANNOT BE** — the latch values at cycle 0 are
the two given initial states. *So `.tail` above is tight, not conservative; the
header window [0,2k) is don't-care by §2's own rider.* -/
theorem l0_cycle_zero_is_excluded (i : List Bool) (rest : List (List Bool)) :
    latchAt ceC [true, false, false, false] (i :: rest) 0
      ≠ latchAt ceC [false, false, false, false] (i :: rest) 0 := by
  simp [latchAt, runTrace]

/-! ## 4. THE TAPEOUT INSTANCE — P = 8, frame = 14 -/

theorem cFrame_cons (a : Bool) (d : Nat) (p : List Bool) :
    cFrame a d p
      = a :: (a && Nat.testBit d 2) :: a :: (a && Nat.testBit d 1) :: a
          :: (a && Nat.testBit d 0) :: p := rfl

/-- An ACTIVE convention-C frame pair opens with `[strobe, 1, 1]`: both activity
bits high. *So L0's hypothesis is met by construction on every full-load frame.* -/
theorem ceFrameTrace_cFrame (d0 d1 : Nat) (p0 p1 : List Bool) :
    ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1)
      = [true, true, true] :: ceBody
          ((true && Nat.testBit d0 2) :: true :: (true && Nat.testBit d0 1) :: true
            :: (true && Nat.testBit d0 0) :: p0)
          ((true && Nat.testBit d1 2) :: true :: (true && Nat.testBit d1 1) :: true
            :: (true && Nat.testBit d1 0) :: p1) := by
  rw [cFrame_cons true d0 p0, cFrame_cons true d1 p1]
  rfl

/-- P = 8 ⇒ 2k + P = 14 cycles, for every destination pair and every payload
pair. *The literal 14 is DERIVED here, not baked in.* -/
theorem l0_at_P8_length (d0 d1 : Nat) (p0 p1 : List Bool)
    (hp0 : p0.length = 8) (hp1 : p1.length = 8) :
    (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1)).length = 14 := by
  rw [ceFrameTrace_cFrame]
  simp [ceBody, hp0, hp1]

/-- ⭐⭐ **L0 AT THE TAPEOUT INSTANCE**, on the artifact's own frame driver, for
arbitrary destinations and arbitrary payloads. -/
theorem l0_at_P8 (a b c d a' b' c' d' : Bool) (d0 d1 : Nat) (p0 p1 : List Bool) :
    (latchTrace ceC [a, b, c, d]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).tail
      = (latchTrace ceC [a', b', c', d']
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).tail := by
  rw [ceFrameTrace_cFrame]
  exact l0_whole_frame a b c d a' b' c' d' [true, true, true] _ rfl

theorem l0_at_P8_output (a b c d a' b' c' d' : Bool) (d0 d1 : Nat) (p0 p1 : List Bool) :
    runTrace ceC [a, b, c, d] (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))
      = runTrace ceC [a', b', c', d'] (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1)) := by
  rw [ceFrameTrace_cFrame]
  exact ceC_run_strobe_erases a b c d a' b' c' d' [true, true, true] _ rfl

/-! ## 5. THE NETWORK BRIDGE — how far L0 travels, and where it stops -/

theorem bnCElemTrace_cons (st inp : List Bool) (is : List (List Bool)) (e : Nat) :
    bnCElemTrace st (inp :: is) e
      = bnCElemInAt st inp e :: bnCElemTrace (stepSeq batcherNetC st inp).2 is e := rfl

theorem bnCSlice_cons (st : List Bool) (e : Nat) :
    bnCSlice st e = [st.getD (4 * e) false, st.getD (4 * e + 1) false,
                     st.getD (4 * e + 2) false, st.getD (4 * e + 3) false] := rfl

/-- ⭐ **THE STROBE IS A BROADCAST PRIMARY INPUT**, so a strobed network cycle is a
strobed cycle at EVERY element — for every element index and every network state.
*`bnCRst` is net 0 (`BatcherNetC.lean:56`); no gate can write it.* -/
theorem l0_network_strobe_reaches_element (st inp : List Bool) (e : Nat) :
    (bnCElemInAt st inp e).getD 0 false = inp.getD 0 false := by
  simp only [bnCElemInAt, List.getD_cons_zero]
  exact bnC_rst_val st inp

/-- ⭐⭐ **L0 AT THE NETWORK, THE HALF THAT IS TRUE OF THE ARTIFACT.** Element `e`'s
slice of the 96-bit network state after a strobed trace is a function of element
`e`'s INPUT TRACE alone — its own initial slice is erased — for every `e < 24`,
every initial network state, and every trace length.

⚠️ **AND THE OTHER HALF IS OPEN, BY NAME**: `bnCElemTrace st (inp :: is) e` still
mentions `st`, because an interior element's DATA bits come through upstream
elements. Closing that needs `bnCElemInAt st inp e = bnCElemInAt st' inp e` under
the strobe — a cascade induction over the 24-instance build. **Not proved here.**
-/
theorem l0_network_slice_forgets_own_slice (st inp : List Bool) (is : List (List Bool))
    (e : Nat) (he : e < 24) (hrst : inp.getD 0 false = true) :
    bnCSlice (runTrace batcherNetC st (inp :: is)).2 e
      = (runTrace ceC [false, false, false, false] (bnCElemTrace st (inp :: is) e)).2 := by
  have hhead : (bnCElemInAt st inp e).getD 0 false = true :=
    (l0_network_strobe_reaches_element st inp e).trans hrst
  rw [bnC_trace_factors (inp :: is) st e he, bnCElemTrace_cons, bnCSlice_cons]
  exact congrArg Prod.snd
    (ceC_run_strobe_erases _ _ _ _ false false false false _ _ hhead)

/-! ## 6. THE FIXTURE — the tapeout instance, P = 8, at real convention-C frames -/

/-- Line 0's 8-bit payload. -/
def l0PayA : List Bool := [true, true, false, true, false, false, false, false]
/-- Line 1's 8-bit payload, distinguishable from line 0's at every position. -/
def l0PayB : List Bool := [false, false, true, false, true, true, true, true]
/-- `d0 = 2 < 5 = d1`, so `cKeyLE` says NO swap: both frames must pass straight
through, and any swap in the output is a delivery failure. -/
def l0FrA : List Bool := cFrame true 2 l0PayA
def l0FrB : List Bool := cFrame true 5 l0PayB

/-- **WELL-PHASED** — the artifact's own frame driver: strobe on cycle 0. -/
def l0TrWP : List (List Bool) := ceFrameTrace l0FrA l0FrB
/-- **MIS-PHASED (a)** — the same 14 frame bits, no strobe in the window (the
pulse landed elsewhere). One bit from `l0TrWP`. -/
def l0TrMis : List (List Bool) := ceBody l0FrA l0FrB
/-- **MIS-PHASED (b)** — the strobe one cycle LATE, so the element decodes an
address cycle as an activity cycle. Two bits from `l0TrWP`. -/
def l0TrLate : List (List Bool) :=
  (List.range 14).map fun t => [t == 1, l0FrA.getD t false, l0FrB.getD t false]

/-- All 16 initial latch states — `[decided, swap, phase, bothAct]`, reachable or
not. -/
def l0States : List (List Bool) :=
  bools.flatMap fun a => bools.flatMap fun b => bools.flatMap fun c => bools.map fun d => [a, b, c, d]

/-- The 16 latch behaviours (cycle 1 onward), one per initial state. -/
def l0LatchBehaviours (tr : List (List Bool)) : List (List (List Bool)) :=
  l0States.map fun s => (latchTrace ceC s tr).tail

/-- The 16 output behaviours, one per initial state. -/
def l0OutBehaviours (tr : List (List Bool)) : List (List (List Bool)) :=
  l0States.map fun s => (runTrace ceC s tr).1

/-- Ordered pairs of initial states whose behaviours DISAGREE, out of 16 × 16. -/
def l0Disagree (bs : List (List (List Bool))) : Nat :=
  (bs.flatMap fun x => bs.map fun y => x != y).count true

theorem l0States_count : l0States.length = 16 := by decide +kernel

/-- The fixture IS the tapeout instance: 8-bit payloads, 14-cycle frames,
14-cycle traces, and 15 latch samples (cycles 0…14). -/
theorem l0_fixture_is_the_tapeout_instance :
    l0PayA.length = 8 ∧ l0PayB.length = 8
      ∧ l0FrA.length = 14 ∧ l0FrB.length = 14
      ∧ l0TrWP.length = 14 ∧ l0TrMis.length = 14 ∧ l0TrLate.length = 14
      ∧ (latchTrace ceC [false, false, false, false] l0TrWP).length = 15 := by
  decide +kernel

/-- ⛔ **THE MUTANT IS ONE BIT FROM THE CONTROL** — same frame bits, same 14
cycles; only cycle 0's strobe differs. *A differential is evidence only if the
mutant is one edit away.* -/
theorem l0_wellphased_and_misphased_differ_in_one_bit :
    (l0TrWP.zip l0TrMis).countP (fun p => p.1 != p.2) = 1 := by decide +kernel

/-- …and the late-strobe mutant is two bits: cycle 0 loses the strobe, cycle 1
gains it. -/
theorem l0_late_strobe_differs_in_two_bits :
    (l0TrWP.zip l0TrLate).countP (fun p => p.1 != p.2) = 2 := by decide +kernel

/-! ### NON-VACUITY — the well-phased frame is the one that delivers correctly -/

/-- ✅ **THE WELL-PHASED FIXTURE IS THE LANDED BEHAVIOUR**, derived from
`ceC_pair_full_load_out0` (`SeamElement.lean:264`) rather than re-measured: `2 <
5` so line 0's frame leaves on `out0` verbatim. *So L0's agreement below is
agreement on the CORRECT delivery, not agreement on garbage.* -/
theorem l0_wellphased_delivery_is_the_landed_one :
    (runTrace ceC [false, false, false, false] l0TrWP).1.map (fun o => o.getD 0 false)
      = l0FrA := by
  show (runTrace ceC [false, false, false, false]
      (ceFrameTrace (cFrame true 2 l0PayA) (cFrame true 5 l0PayB))).1.map (fun o => o.getD 0 false)
      = cFrame true 2 l0PayA
  rw [ceC_pair_full_load_out0 2 5 (by decide) (by decide) (by decide) l0PayA l0PayB (by decide)]
  decide +kernel

/-- ✅ …and it holds from EVERY initial latch state, which is L0's output half at
the fixture. -/
theorem l0_wellphased_delivers_from_every_state :
    (l0OutBehaviours l0TrWP).all (fun o => o == ceIL l0FrA l0FrB) = true := by decide +kernel

/-! ### §3's "FUNCTION OF THE **HEADER** BITS", TESTED LITERALLY — and it is one
word too strong

§3 says the latch values are "a function of the frame's own **header** bits". The
COUPLING form proved above does not need that reading, but the reading is
checkable, so it was checked: same headers, one line's payload changed. -/

/-- A third payload, all-ones, so the even-cycle AND `i0 && i1` — the only way a
payload bit reaches a latch — actually flips. *Exchanging the two payloads does
NOT work as a mutant: `i0 && i1` is symmetric, and that near-miss is why this is
stated as a measured mutant rather than an argument.* -/
def l0PayC : List Bool := [true, true, true, true, true, true, true, true]
def l0FrC : List Bool := cFrame true 2 l0PayC
def l0TrPay : List (List Bool) := ceFrameTrace l0FrC l0FrB

/-- The mutant keeps the header EXACTLY — both the frame's six header bits and the
trace's first six cycles. -/
theorem l0_payload_mutant_keeps_the_header :
    l0FrA.take 6 = l0FrC.take 6 ∧ l0TrWP.take 6 = l0TrPay.take 6 := by decide +kernel

/-- ✅ **THE ROUTING LATCHES REALLY ARE HEADER-ONLY.** The `[decided, swap]` pair
agrees over the whole frame between the two payloads, `phase` agrees, and from
cycle 2k = 6 onward the pair is the CONSTANT `[true, false]` for all nine
remaining samples — decided, no swap, since `2 < 5`. *This is the projection of
the latch vector that §3's sentence is true of, and it is the projection L1/L3
consume.* -/
theorem l0_routing_latches_are_header_only :
    (latchTrace ceC [false, false, false, false] l0TrWP).map (fun s => s.take 2)
        = (latchTrace ceC [false, false, false, false] l0TrPay).map (fun s => s.take 2)
      ∧ (latchTrace ceC [false, false, false, false] l0TrWP).map (fun s => s.getD 2 false)
        = (latchTrace ceC [false, false, false, false] l0TrPay).map (fun s => s.getD 2 false)
      ∧ ((latchTrace ceC [false, false, false, false] l0TrWP).drop 6).map (fun s => s.take 2)
        = List.replicate 9 [true, false] := by decide +kernel

/-- ⛔ **BUT THE FOURTH LATCH READS THE PAYLOAD, so §3's "function of the frame's
own HEADER bits" is literally FALSE of the full latch vector.** `bothAct' =
(!phase && (in0 && in1)) || (phase && bothAct)` (`ceC_step_decided`,
`SeamElement.lean:110`) samples the two data wires on every even cycle, payload
cycles included: the column reads
`[…,false,false,false,false,false,false]` against `[…,false,true,true,true,true,true,true]`.

📌 **THE ROUTING CONCLUSION IS UNTOUCHED** — bit 3 is the bit
`ceC_fourth_state_bit_is_dead` (`CompareExchangeC.lean:529`) proves nothing reads
under the protocol. **The repair is one word in §3**: "a function of the frame's
own bits" (which is exactly what the coupling form gives), or "control latch"
restricted to `[decided, swap]`. Not a defect in the hardware, and not a defect in
L0 as proved here — a defect in the SENTENCE. -/
theorem l0_header_bits_alone_do_not_fix_the_bothAct_latch :
    (latchTrace ceC [false, false, false, false] l0TrWP).tail
        ≠ (latchTrace ceC [false, false, false, false] l0TrPay).tail
      ∧ (latchTrace ceC [false, false, false, false] l0TrWP).map (fun s => s.getD 3 false)
        ≠ (latchTrace ceC [false, false, false, false] l0TrPay).map (fun s => s.getD 3 false) := by
  decide +kernel

/-! ### ⛔ THE NEGATIVE CONTROL — drop well-phasedness and L0 FAILS -/

/-- ✅ **CONTROL: 1 latch behaviour, 0 disagreeing pairs out of 256.** *The
exhaustive form of `l0_at_P8` at the fixture — an independent check that the
general theorem's conclusion is what the hardware does.* -/
theorem l0_wellphased_latches_agree :
    (l0LatchBehaviours l0TrWP).eraseDups.length = 1
      ∧ l0Disagree (l0LatchBehaviours l0TrWP) = 0 := by decide +kernel

/-- ⛔ **MUTANT (a): 9 latch behaviours, 220 disagreeing pairs out of 256.** One
bit — cycle 0's strobe — and L0's conclusion is false at the artifact. -/
theorem l0_misphased_latches_disagree :
    (l0LatchBehaviours l0TrMis).eraseDups.length = 9
      ∧ l0Disagree (l0LatchBehaviours l0TrMis) = 220 := by decide +kernel

/-- ⛔ …and the mis-phased failure reaches the OUTPUT too: 2 delivery behaviours,
128 disagreeing pairs. -/
theorem l0_misphased_outputs_disagree :
    (l0OutBehaviours l0TrMis).eraseDups.length = 2
      ∧ l0Disagree (l0OutBehaviours l0TrMis) = 128 := by decide +kernel

/-- ⛔⛔ **THE WITNESS, AND IT IS A WRONG-PAYLOAD DELIVERY.** Without the strobe,
`[decided, swap] = [1, 1]` freezes the element as a crossing mux for all 14
cycles: both payloads arrive at the wrong port in well-formed frames — exactly
the failure class the payload-delivery block exists to certify against. The
canonical state delivers correctly on the same trace, so the trace is not simply
broken.

📌 **AND BOTH WITNESS STATES ARE ALREADY PHASE-ALIGNED** (`phase = false`, the
third conjunct): so "well-phased" cannot be weakened to "the phase latch happens
to be even". The strobe must EVENT-establish it, because `decided` survives
otherwise — which is §2's H3 and §3's "well-phasedness is an INPUT EVENT". -/
theorem l0_misphased_counterexample :
    (runTrace ceC [true, true, false, false] l0TrMis).1 = ceIL l0FrB l0FrA
      ∧ (runTrace ceC [false, false, false, false] l0TrMis).1 = ceIL l0FrA l0FrB
      ∧ ([true, true, false, false] : List Bool).getD 2 false
          = ([false, false, false, false] : List Bool).getD 2 false
      ∧ ceIL l0FrA l0FrB ≠ ceIL l0FrB l0FrA := by decide +kernel

/-- The 8 phase-aligned initial states. -/
def l0StatesPhaseEven : List (List Bool) := l0States.filter fun s => !(s.getD 2 false)

/-- ⛔ **PHASE ALIGNMENT ALONE IS NOT ENOUGH, EXHAUSTIVELY**: restrict to the 8
initial states whose `phase` latch is already even and the mis-phased frame still
has 2 delivery behaviours. -/
theorem l0_phase_alignment_alone_is_not_enough :
    l0StatesPhaseEven.length = 8
      ∧ (l0StatesPhaseEven.map fun s => (runTrace ceC s l0TrMis).1).eraseDups.length = 2 := by
  decide +kernel

/-- ⛔ **MUTANT (b): 9 latch behaviours from a strobe one cycle late.** -/
theorem l0_late_strobe_latches_disagree :
    (l0LatchBehaviours l0TrLate).eraseDups.length = 9
      ∧ l0Disagree (l0LatchBehaviours l0TrLate) = 220 := by decide +kernel

/-- ⚠️⚠️ **AND HERE IS WHY L0 IS STATED ON LATCHES.** On the late-strobe frame the
OUTPUT trace is init-INDEPENDENT — one behaviour, zero disagreeing pairs — and it
is WRONG: the two payloads are exchanged, from every initial state including the
canonical one. **An L0 stated on outputs would pass this frame and report a
green.** The latch form reports 9. -/
theorem l0_late_strobe_output_form_is_blind :
    (l0OutBehaviours l0TrLate).eraseDups.length = 1
      ∧ l0Disagree (l0OutBehaviours l0TrLate) = 0
      ∧ (runTrace ceC [false, false, false, false] l0TrLate).1 = ceIL l0FrB l0FrA
      ∧ ceIL l0FrA l0FrB ≠ ceIL l0FrB l0FrA := by decide +kernel

/-! ### ⛔ THE UN-HYPOTHESIZED STATEMENT, REFUTED -/

theorem l0TrMis_cons : l0TrMis = [false, true, true] :: ceBody l0FrA.tail l0FrB.tail := rfl

/-- ⛔⛔ **L0 WITH THE WELL-PHASEDNESS HYPOTHESIS DELETED IS FALSE.** Exactly
`l0_whole_frame` minus `hi`. -/
theorem l0_is_false_without_the_strobe :
    ¬ ∀ (a b c d a' b' c' d' : Bool) (i : List Bool) (rest : List (List Bool)),
        (latchTrace ceC [a, b, c, d] (i :: rest)).tail
          = (latchTrace ceC [a', b', c', d'] (i :: rest)).tail := by
  intro h
  have hc := h true true false false false false false false [false, true, true]
    (ceBody l0FrA.tail l0FrB.tail)
  rw [← l0TrMis_cons] at hc
  exact absurd hc (by decide +kernel)

/-- ⛔ …and so is the output-side companion. Exactly `l0_output_agreement` minus
`hi`. -/
theorem l0_output_form_is_false_without_the_strobe :
    ¬ ∀ (a b c d a' b' c' d' : Bool) (i : List Bool) (rest : List (List Bool)),
        (runTrace ceC [a, b, c, d] (i :: rest)).1
          = (runTrace ceC [a', b', c', d'] (i :: rest)).1 := by
  intro h
  have hc := h true true false false false false false false [false, true, true]
    (ceBody l0FrA.tail l0FrB.tail)
  rw [← l0TrMis_cons] at hc
  exact absurd hc (by decide +kernel)

/-! ## 7. AUDITS — one declaration per call -/

#audit_axioms latchAt
#audit_axioms latchTrace
#audit_axioms latchAt_zero
#audit_axioms latchAt_full
#audit_axioms latchTrace_length
#audit_axioms latchTrace_tail
#audit_axioms ceC_env_input_trunc
#audit_axioms ceC_step_input_trunc
#audit_axioms ceC_step_strobe_erases
#audit_axioms runTrace_cons_congr
#audit_axioms ceC_run_strobe_erases
#audit_axioms l0_latch_agreement
#audit_axioms l0_whole_frame
#audit_axioms l0_any_state_list
#audit_axioms l0_latches_are_a_function_of_the_frame
#audit_axioms l0_output_agreement
#audit_axioms l0_cycle_zero_is_excluded
#audit_axioms cFrame_cons
#audit_axioms ceFrameTrace_cFrame
#audit_axioms l0_at_P8_length
#audit_axioms l0_at_P8
#audit_axioms l0_at_P8_output
#audit_axioms bnCElemTrace_cons
#audit_axioms bnCSlice_cons
#audit_axioms l0_network_strobe_reaches_element
#audit_axioms l0_network_slice_forgets_own_slice
#audit_axioms l0PayA
#audit_axioms l0PayB
#audit_axioms l0FrA
#audit_axioms l0FrB
#audit_axioms l0TrWP
#audit_axioms l0TrMis
#audit_axioms l0TrLate
#audit_axioms l0States
#audit_axioms l0LatchBehaviours
#audit_axioms l0OutBehaviours
#audit_axioms l0Disagree
#audit_axioms l0States_count
#audit_axioms l0_fixture_is_the_tapeout_instance
#audit_axioms l0_wellphased_and_misphased_differ_in_one_bit
#audit_axioms l0_late_strobe_differs_in_two_bits
#audit_axioms l0_wellphased_delivery_is_the_landed_one
#audit_axioms l0_wellphased_delivers_from_every_state
#audit_axioms l0PayC
#audit_axioms l0FrC
#audit_axioms l0TrPay
#audit_axioms l0_payload_mutant_keeps_the_header
#audit_axioms l0_routing_latches_are_header_only
#audit_axioms l0_header_bits_alone_do_not_fix_the_bothAct_latch
#audit_axioms l0_wellphased_latches_agree
#audit_axioms l0_misphased_latches_disagree
#audit_axioms l0_misphased_outputs_disagree
#audit_axioms l0_misphased_counterexample
#audit_axioms l0StatesPhaseEven
#audit_axioms l0_phase_alignment_alone_is_not_enough
#audit_axioms l0_late_strobe_latches_disagree
#audit_axioms l0_late_strobe_output_form_is_blind
#audit_axioms l0TrMis_cons
#audit_axioms l0_is_false_without_the_strobe
#audit_axioms l0_output_form_is_false_without_the_strobe

end SaltWorks.HDL
