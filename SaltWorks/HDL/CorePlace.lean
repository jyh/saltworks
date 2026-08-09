import SaltWorks.HDL.Compose
import SaltWorks.HDL.StateCodec
import SaltWorks.HDL.Decoder
import SaltWorks.HDL.Immediate

/-!
# W5-asm, increment 2a — the FIRST organ placed at the real offset, `instOK` discharged

**Council ruling #4** (option (a), interleaved). Increment 1 (`CoreOffsets`) settled the σ
arithmetic as data. This file places the **first organ into the core's actual net space** and
discharges the side condition, establishing the placement convention the other fourteen follow.

## PRECONDITION PREAMBLE

* **CLAIMED** — `decoder` is placed at the core's real `off0`; `instOK` is **discharged, not
  assumed**; the placement uses `StateCodec`'s **named accessors** rather than raw arithmetic;
  and the margin by which `instOK` holds is exhibited (it is exactly zero — see
  `placement_margin_is_exactly_tight`).
* **NOT CLAIMED** — no other organ is placed, no `core` Circ exists yet, no semantic refinement.
  One placement, fully discharged, is the unit of progress here.
* **ARCHITECTURE, per the maestro's 09:51 flag** — **specific organ imports from the first
  line, never the hub.** A hub-importing construction file can never be rooted, cited, or
  composed; increment 1 had to be retrofitted for exactly this, so increment 2 starts correct.

## WHY `instOK` IS THE WHOLE POINT

`instOK c σ off` demands `c.ssa`, `c.wf`, and `∀ i < c.nIn, σ i < off`: every input wire must
already be computed by the host. **`SubFragment`, the two-organ probe, held this by a one-gate
margin (96 < 97).** Here the margin is *zero* — the instruction word ends exactly where the
gates begin — which is the tightest a placement can legally be, and worth a theorem rather than
a comment.
-/

namespace SaltWorks.HDL.CorePlace

open SaltWorks.HDL

/-! ## 1. The core's net space — LANDED constants, not literals

`StateCodec` already carries the layout as theorems: state at `0…1055`, the instruction word at
`1056…1087`, and `coreInWidth = 1088`. This file cites those rather than restating the numbers,
so a change to the layout breaks the placement instead of silently misaligning it. -/

/-- The host's first free net: everything below is core INPUT (state, then instruction). -/
def off0 : Nat := coreInWidth

theorem off0_value : off0 = 1088 := coreInWidth_value

/-! ## 2. The first placement — `decoder`, reading the instruction word

`decoder.nIn = 32`: it reads the instruction and nothing else. Its σ is therefore exactly
`StateCodec.instrNet`, the *named* accessor for the instruction nets. -/

/-- The decoder's input map: input `i` is instruction bit `i`. **`instrNet`, not `1056 + i`** —
the named accessor is the StateCodec conformance the pre-named risk #3 asked for. -/
def decoderSig : Net → Net := instrNet

/-- ⭐ **`instOK` DISCHARGED for the first placement.** Not assumed, not `sorry`ed: `decoder` is
SSA and well-formed, and every one of its 32 input wires lands strictly below `off0`. -/
theorem decoder_instOK : instOK decoder decoderSig off0 := by
  refine ⟨by decide +kernel, by decide +kernel, ?_⟩
  intro i hi
  -- `decoder.nIn = 32`, so `i < 32`; `instrNet i = 1056 + i < 1088`.
  have h32 : i < 32 := by
    have : decoder.nIn = 32 := by decide +kernel
    omega
  simp only [decoderSig, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  omega

/-- ⚠️ **THE MARGIN IS EXACTLY ZERO — the tightest a legal placement can be.**

The instruction word occupies `1056…1087` and the host's gates begin at `1088`. So the LAST input
wire sits one below `off0` (stated as `+ 1 = off0`, never as `off0 - 1` — truncated
subtraction is what defeats `omega` on `Net`-typed goals): one more input bit, or one fewer state net, and `instOK` fails.

*`SubFragment` held by a one-gate margin and that was worth remarking. This holds by NONE.
Recorded as a theorem because a zero margin is invisible to inspection and fatal to an edit —
anyone widening the instruction field or narrowing the state must re-derive this placement.* -/
theorem placement_margin_is_exactly_tight :
    decoderSig 31 + 1 = off0 ∧ ¬ (decoderSig 32 < off0) := by
  refine ⟨by decide +kernel, ?_⟩
  simp only [decoderSig, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  omega

/-- **CONTROL: the placement is not vacuous.** `instOK`'s third clause is a `∀ i < c.nIn`, so a
circuit with `nIn = 0` would satisfy it trivially. `decoder` has 32 inputs, all constrained. -/
theorem placement_is_not_vacuous : decoder.nIn = 32 ∧ 0 < decoder.nIn := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- **CONTROL: the state nets are genuinely disjoint from the instruction nets**, so the decoder
cannot be reading a register by accident. This is `StateCodec`'s own landed theorem, cited here
because the placement's correctness depends on it and a citation that is never exercised is a
citation nobody has checked. -/
theorem decoder_reads_only_the_instruction (k : Nat) (hk : k < 32) :
    stWidth ≤ decoderSig k ∧ decoderSig k < off0 := by
  simp only [decoderSig, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  omega

/-! ## 3. INCREMENT 2b — the chain step, and the second placement

The chain lemma below is what makes placements #3–#15 mechanical: an organ whose inputs all sit
below the FIRST free net is placeable at **every later** offset, so each placement needs only its
own σ checked once against `off0`, never re-checked against its actual position. -/

/-- ⭐ **`instOK` IS MONOTONE IN THE OFFSET.** If every input wire is below `off`, it is below any
`off' ≥ off`. Trivial to prove and load-bearing to have: without it, each of the fifteen
placements would need its σ re-verified against its own offset, and the σ that reads only core
INPUTS (state and instruction) is the same σ at every position in the chain. -/
theorem instOK_mono {c : Circ} {σ : Net → Net} {off off' : Nat}
    (h : instOK c σ off) (hle : off ≤ off') : instOK c σ off' := by
  obtain ⟨hssa, hwf, hin⟩ := h
  exact ⟨hssa, hwf, fun i hi => Nat.lt_of_lt_of_le (hin i hi) hle⟩

/-- The second placement's offset: the decoder's `instNext`. -/
def off1 : Nat := instNext decoder off0

theorem off1_value : off1 = 1190 := by
  simp only [off1, instNext, off0, coreInWidth, stWidth]
  decide +kernel

/-- `immBCirc` reads the instruction word, so its σ is `instrNet` — the same named accessor as
the decoder's. -/
def immBSig : Net → Net := instrNet

/-- ⭐ **THE SECOND PLACEMENT, DISCHARGED VIA THE CHAIN LEMMA rather than re-derived.** `immBCirc`
reads only the instruction, so its inputs are below `off0`; `off0 ≤ off1` because a chain step
adds gates. This is the pattern every remaining input-reading organ follows. -/
theorem immB_instOK : instOK immBCirc immBSig off1 := by
  refine instOK_mono (off := off0) ?_ ?_
  · refine ⟨by decide +kernel, by decide +kernel, ?_⟩
    intro i hi
    have hnn : immBCirc.nIn = 32 := by decide +kernel
    rw [hnn] at hi
    simp only [immBSig, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
    omega
  · simp only [off1, instNext, off0]
    omega

/-- **CONTROL: the chain step genuinely ADVANCED.** If `off1 = off0` the second placement would be
a no-op dressed as progress — and a zero-gate organ would make exactly that happen (increment 1's
`zero_gate_organ_does_not_advance`). The decoder has 102 gates, so this step is real. -/
theorem chain_step_advanced : off0 < off1 ∧ off1 = off0 + 102 := by
  refine ⟨?_, ?_⟩
  · simp only [off1, instNext, off0, coreInWidth, stWidth]
    decide +kernel
  · simp only [off1, instNext, off0]
    congr 1
    decide +kernel

/-- **CONTROL: the two placements do not collide.** The decoder's gates occupy `off0 … off1 - 1`,
and `immBCirc`'s begin at `off1`. Stated additively, never with truncated subtraction. -/
theorem placements_do_not_collide :
    off0 + decoder.gates.length = off1 ∧ instNext immBCirc off1 = off1 + 1 := by
  refine ⟨rfl, ?_⟩
  simp only [instNext]
  congr 1


end SaltWorks.HDL.CorePlace
