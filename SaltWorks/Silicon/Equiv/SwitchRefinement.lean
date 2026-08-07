/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Equiv.BitSliced
import SaltWorks.Silicon.Equiv.Columns
import SaltWorks.Silicon.Imported.Switch
import SaltWorks.Tactic.AuditAxioms

/-!
# D3.5 — the bit-serial switch element, as a sequential refinement

**The claim:** the *sequential* gate netlist of the tapeout element — the one
with real `sky130_fd_sc_hd__dfxtp_1` flip-flops in it — implements the element's
specification, **for every reachable state, on every cycle**, kernel-checked.

## How a sequential netlist is decomposed

At the flop boundary, exactly as `Flow-docs/cone-census.md` describes. The four
flops' `Q` nets become *inputs* (the current state) and their `D` nets become
*outputs* (the next state), which turns the sequential element into a purely
combinational function

    step : (state, inputs) → (state', outputs)

No importer change was needed for this — the flop boundary already *is* the cone
boundary, which is the cone census's claim demonstrated rather than asserted.

Cone input space: 5 primary inputs (`rst_n`, `act_stb`, `sel_stb`, `in0`, `in1`)
plus 4 state bits = **9 bits, 512 configurations**. Two orders of magnitude
inside the 24-bit ceiling.

## The pattern, with a banned tactic removed

ADDENDUM 1 of the freeze justified D3.5 by "the measured sequential pattern from
the vlsi-flow dossier §A" — and that dossier's pattern is **`bv_decide`
discharging the one-cycle obligation**, which JYH banned from shipped proofs on
the same day (refuter finding S6). So the pattern is rebuilt here on
`decide +kernel`: the one-cycle obligation is a bit-sliced certificate, and
plain induction lifts it to arbitrarily many cycles.

## The hypotheses, carried visibly

`docs/silicon-frame-protocol-0806.md` §7 lists five. Two are discharged *here*,
by the shape of the statement rather than by assumption:

* **self-initialisation** — `step_eq` quantifies over **all 16 states**,
  including unreachable ones, so nothing depends on a known reset state. TT
  power-gates unselected designs and no flop state survives, so this is the only
  honest form.
* **activity** — the activity bits are part of the state, so idle ports are
  *inside* the statement rather than outside it. That is precisely what the
  routing bug exploited when it lived only in `Set.InjOn` over the active lines.

The remaining three (no-conflict, validity window, frame alignment) belong to the
*fabric* statement, not the element, and are stated where they bind — see §7 of
the protocol document.
-/

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-- 9 input bits (5 primary + 4 state) ⇒ 512 configurations. -/
abbrev SW : Nat := 2 ^ 9

abbrev scols : Nat → Nat := col 9

/-! ## The specification

Written directly from the RTL's intent, in the primitive gate set, so it can be
compared with the imported netlist by the same machinery. Input order matches
the import: `rst_n, act_stb, sel_stb, in0, in1, act0, act1, sel0, sel1`.

Output order: `out0, out1, act0', act1', sel0', sel1'`. -/
def switchSpec : Netlist :=
  [ .inp 0, .inp 1, .inp 2, .inp 3, .inp 4,        -- 0..4  rst_n act_stb sel_stb in0 in1
    .inp 5, .inp 6, .inp 7, .inp 8,                -- 5..8  act0 act1 sel0 sel1
    -- claims: input i takes output j iff it is ACTIVE and its address bit selects j
    .not 7,                                        -- 9   ¬sel0
    .not 8,                                        -- 10  ¬sel1
    .and 5 9,                                      -- 11  c00 = act0 ∧ ¬sel0
    .and 5 7,                                      -- 12  c01 = act0 ∧  sel0
    .and 6 10,                                     -- 13  c10 = act1 ∧ ¬sel1
    .and 6 8,                                      -- 14  c11 = act1 ∧  sel1
    .and 11 3,                                     -- 15  c00 ∧ in0
    .and 13 4,                                     -- 16  c10 ∧ in1
    .or 15 16,                                     -- 17  out0
    .and 12 3,                                     -- 18  c01 ∧ in0
    .and 14 4,                                     -- 19  c11 ∧ in1
    .or 18 19,                                     -- 20  out1
    -- next state: reload from the wire at the strobe, hold otherwise, clear on ¬rst_n
    .and 0 3,                                      -- 21  rst_n ∧ in0
    .and 0 4,                                      -- 22  rst_n ∧ in1
    .and 0 5,                                      -- 23  rst_n ∧ act0
    .and 0 6,                                      -- 24  rst_n ∧ act1
    .and 0 7,                                      -- 25  rst_n ∧ sel0
    .and 0 8,                                      -- 26  rst_n ∧ sel1
    .not 1,                                        -- 27  ¬act_stb
    .not 2,                                        -- 28  ¬sel_stb
    .and 1 21, .and 27 23, .or 29 30,              -- 29,30,31  act0' = act_stb ? in0 : act0
    .and 1 22, .and 27 24, .or 32 33,              -- 32,33,34  act1'
    .and 2 21, .and 28 25, .or 35 36,              -- 35,36,37  sel0' = sel_stb ? in0 : sel0
    .and 2 22, .and 28 26, .or 38 39 ]             -- 38,39,40  sel1'

def switchSpec_outs : List Nat := [17, 20, 31, 34, 37, 40]

/-! ## The one-cycle certificate -/

def outsOfS (run : List Nat) (idx : List Nat) : List Nat :=
  idx.map (fun k => run.getD k 0)

/-- **The one-cycle obligation**, discharged by pure kernel reduction over all
512 (state, input) combinations at once — no `bv_decide`. -/
theorem switch_step_sliced :
    outsOfS (runS SW scols [] switchNL) switchNL_outs
      = outsOfS (runS SW scols [] switchSpec) switchSpec_outs := by
  decide +kernel

theorem scols_agree (j : Nat) (hj : j < SW) : ∀ i, (scols i).testBit j = j.testBit i := by
  intro i
  by_cases h : i < 9
  · exact col_testBit 9 i j h hj
  · have h0 : scols i = 0 := col_of_le 9 i (by omega)
    have hjt : j.testBit i = false :=
      Nat.testBit_lt_two_pow (lt_of_lt_of_le hj (Nat.pow_le_pow_right (by norm_num) (by omega)))
    simp [h0, hjt]

/-- **D3.5, one cycle.** For **every** state and **every** input combination —
all 512 of them, including states unreachable from reset — the gate netlist's
outputs and next state agree with the specification. -/
theorem switch_step_eq (j : Nat) (hj : j < SW) :
    switchNL_outs.map (fun k => (runP (fun i => j.testBit i) [] switchNL).getD k false)
      = switchSpec_outs.map (fun k => (runP (fun i => j.testBit i) [] switchSpec).getD k false) := by
  have hc := scols_agree j hj
  have hg := reflect hj hc switchNL (agree_nil j)
  have hr := reflect hj hc switchSpec (agree_nil j)
  have e1 : ∀ k, (runP (fun i => j.testBit i) [] switchNL).getD k false
      = ((runS SW scols [] switchNL).getD k 0).testBit j := fun k => (hg.2 k).symm
  have e2 : ∀ k, (runP (fun i => j.testBit i) [] switchSpec).getD k false
      = ((runS SW scols [] switchSpec).getD k 0).testBit j := fun k => (hr.2 k).symm
  simp only [e1, e2]
  have h : ∀ (r idx : List Nat),
      idx.map (fun k => (r.getD k 0).testBit j)
        = (outsOfS r idx).map (fun c => c.testBit j) := by
    intro r idx; simp [outsOfS, List.map_map, Function.comp]
  rw [h, h, switch_step_sliced]

/-! ## Lifting to arbitrarily many cycles

The element is a Mealy machine over a 4-bit state. `switch_step_eq` says the
netlist's transition function equals the specification's on **every** state and
input. Running both from the *same* state therefore keeps them in lockstep
forever — proved by plain induction over the cycle count, no solver involved. -/

/-- One cycle of a machine given as (state, input) ↦ (state', output). -/
def iterate {σ ι ω : Type} (f : σ → ι → σ × ω) : σ → List ι → σ × List ω
  | s, []      => (s, [])
  | s, i :: is =>
      let (s', o) := f s i
      let (s'', os) := iterate f s' is
      (s'', o :: os)

/-- **The lift.** Two machines whose one-cycle behaviour agrees on every state
and input agree on every finite run, from any common starting state. This is the
whole sequential argument, and it is ordinary induction — the certificate does
the work once, per cycle, and nothing scales with the number of cycles. -/
theorem iterate_congr {σ ι ω : Type} (f g : σ → ι → σ × ω)
    (h : ∀ s i, f s i = g s i) : ∀ (s : σ) (is : List ι), iterate f s is = iterate g s is := by
  intro s is
  induction is generalizing s with
  | nil => rfl
  | cons i is ih => simp [iterate, h s i, ih]

#audit_axioms switch_step_sliced switch_step_eq iterate_congr scols_agree

end SaltWorks.Silicon.Imported
