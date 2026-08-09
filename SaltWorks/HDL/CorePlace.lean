import SaltWorks.HDL.Compose
import SaltWorks.HDL.StateCodec
import SaltWorks.HDL.Decoder
import SaltWorks.HDL.Immediate
import SaltWorks.HDL.ReadTree
import SaltWorks.HDL.RegWrite

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
  refine ⟨decoder_ssa, decoder_wf, ?_⟩
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


/-! ## 4. INCREMENT 2c — the first organs that read STATE, and σ as the field extractor

`readTree` is placement #3/#4 and the first organ whose inputs are not all instruction bits.
Its layout (`ReadTree.lean:101`): `raddr` on inputs `0…4`, and **stored** register `i`
(`1 ≤ i ≤ 31`) bit `k` on input `5 + (i-1)*32 + k`.

**THE CORE'S LAYOUT COMPOSES WITH IT AS A PURE SHIFT.** `StateCodec.stBit` puts register `r`
bit `k` at net `32*r + k` (and `decQ` reads it back the same way). `readTree` skips `x0` exactly
as the core's nets `0…31` *are* `x0`, and both are register-major with 32-bit rows — so for
`j ≥ 5`:

```
σ j = 32 * ((j-5)/32 + 1) + (j-5) % 32  =  (j-5) + 32  =  j + 27
```
*Checked at both ends: `j = 5 ↦ 32` (x1 bit 0) and `j = 996 ↦ 1023` (x31 bit 31 = 32*31+31).*

📌 **AND σ IS THE FIELD EXTRACTOR — there is no missing organ.** `regWrite` consumes `rd` already
isolated on its inputs `0…4` (`RegWrite.lean:46`), and `readTree` likewise wants an index, not a
word. Extracting a field from the instruction is **pure wiring**, so it belongs in σ, not in a
circuit: the same fact as `ruledEnc` costing zero gates — *emit the nets, not a module.* Field
positions are taken from the corpus's own encoder (`ISA.wR`: `funct7 rs2 rs1 funct3 rd opcode`),
so `rs1` is bits `15…19` and `rs2` is `20…24` — read, not recalled.
-/

/-- Bits `15…19` of the instruction: the `rs1` index. -/
def rs1Bit (j : Nat) : Net := instrNet (15 + j)

/-- Bits `20…24` of the instruction: the `rs2` index. -/
def rs2Bit (j : Nat) : Net := instrNet (20 + j)

/-- `readTree`'s σ for the rs1 port: address bits from the `rs1` field, and the stored register
file as the pure shift `j + 27`. -/
def readTreeRs1Sig (j : Net) : Net := if j < 5 then rs1Bit j else j + 27

/-- The rs2 port differs from the rs1 port in the FIVE ADDRESS BITS AND NOTHING ELSE — the same
register file, a different index. -/
def readTreeRs2Sig (j : Net) : Net := if j < 5 then rs2Bit j else j + 27

/-- ⭐ **PLACEMENT #3 — `readTree` on the rs1 port, `instOK` DISCHARGED.** Both halves of σ land
below `off0`: the `rs1` field at `1071…1075`, and the register file at `32…1023`. -/
theorem readTree_rs1_instOK : instOK readTree readTreeRs1Sig off0 := by
  refine ⟨readTree_ssa, readTree_wf, ?_⟩
  intro j hj
  have hnn : readTree.nIn = 997 := by decide +kernel
  rw [hnn] at hj
  simp only [readTreeRs1Sig, rs1Bit, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  split
  · omega          -- the address branch: the field sits at 1071…1075
  · omega          -- the register branch: j + 27 ≤ 1023

/-- **PLACEMENT #4 — the rs2 port.** Same organ, same register file, different five bits. -/
theorem readTree_rs2_instOK : instOK readTree readTreeRs2Sig off0 := by
  refine ⟨readTree_ssa, readTree_wf, ?_⟩
  intro j hj
  have hnn : readTree.nIn = 997 := by decide +kernel
  rw [hnn] at hj
  simp only [readTreeRs2Sig, rs2Bit, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  split
  · omega          -- the address branch: the field sits at 1071…1075
  · omega          -- the register branch: j + 27 ≤ 1023

/-- ⭐ **THE SHIFT IS EXACT AT BOTH ENDS — the claim that makes the pure-shift σ legitimate.**
Input `5` is register `x1` bit `0` (net `32`), and input `996` is register `x31` bit `31`
(net `1023 = 32*31 + 31`). If either end were off by one, the core would read a neighbouring
register's bit and every `sem` theorem above it would be about the wrong wires. -/
theorem register_shift_is_exact :
    readTreeRs1Sig 5 = 32 ∧ readTreeRs1Sig 996 = 32 * 31 + 31 := by
  refine ⟨by decide, by decide⟩

/-- **CONTROL: the two ports differ, and differ ONLY in the address.** A copy-paste that left
both ports reading `rs1` would type-check, place cleanly, and compute the wrong instruction —
so the difference is asserted, and the agreement on the register file is asserted too. -/
theorem rs1_and_rs2_differ_only_in_the_address :
    readTreeRs1Sig 0 ≠ readTreeRs2Sig 0
  ∧ readTreeRs1Sig 4 ≠ readTreeRs2Sig 4
  ∧ readTreeRs1Sig 5 = readTreeRs2Sig 5
  ∧ readTreeRs1Sig 996 = readTreeRs2Sig 996 := by
  refine ⟨by decide, by decide, by decide, by decide⟩

/-- **CONTROL: the address bits land in the instruction, not in the state.** `rs1`'s five wires
sit at or above `stWidth`, so a port cannot be reading a register by accident — the same guard as
the decoder's, re-exercised because σ is now a two-branch function and the branch that reads the
instruction is the one an off-by-one would silently move into the state. -/
theorem address_bits_are_in_the_instruction (j : Nat) (hj : j < 5) :
    stWidth ≤ readTreeRs1Sig j ∧ readTreeRs1Sig j < off0 := by
  simp only [readTreeRs1Sig, rs1Bit, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  split
  · omega
  · omega


/-! ## 5. INCREMENT 2d — the first σ that reads ANOTHER ORGAN'S OUTPUTS

Placements #1–#4 all read only core INPUTS, so `instOK_mono` lifted them to every later offset
for free. **`regWrite` is the first placement where that is false**, and the difference is the
whole reason the assembly order exists.

`RegWrite.lean:46` gives its layout: `rd` on inputs `0…4`, `valid` on `5`, `isBEQ` on `6`.
* `rd` is an instruction field (bits `7…11` per `ISA.wR`) — a core input, below `off0`.
* **`valid` and `isBEQ` are the DECODER'S OUTPUTS** — gate nets, and therefore *above* `off0`.

`instMap c σ off n = if n < c.nIn then σ n else off + (n - c.nIn)`, so the decoder's six outputs
land at `[1135, 1151, 1167, 1176, 1185, 1189]` — `isBEQ` at index 4, `valid` at index 5, both
inside `off0 … off1 - 1`. ⇒ ***`regWrite` is placeable from `off1` onward and NOT at `off0`:
the ordering constraint is now load-bearing rather than a formality.***
-/

/-- The host net carrying the decoder's output `k`, once the decoder is placed at `off0`.
Read from `instOuts`, never written as a literal — a literal here would be a number that
silently stops tracking the decoder. -/
def decOut (k : Nat) : Net := (instOuts decoder decoderSig off0).getD k 0

/-- Bits `7…11` of the instruction: the `rd` index (`ISA.wR`: `funct7 rs2 rs1 funct3 rd opcode`). -/
def rdBit (j : Nat) : Net := instrNet (7 + j)

/-- `regWrite`'s σ: `rd` from the instruction, `valid` from decoder output 5, `isBEQ` from
decoder output 4. -/
def regWriteSig (j : Net) : Net :=
  if j < 5 then rdBit j else if j = 5 then decOut 5 else decOut 4

/-- ⭐ **PLACEMENT #5 — `regWrite` at `off1`, `instOK` DISCHARGED, and the first placement whose
σ reaches into another organ's gates.** -/
theorem regWrite_instOK : instOK regWrite regWriteSig off1 := by
  refine ⟨regWrite_ssa, regWrite_wf, ?_⟩
  intro j hj
  have hnn : regWrite.nIn = 7 := by decide +kernel
  rw [hnn] at hj
  simp only [regWriteSig, rdBit, instrNet, instrBase, decOut, decoderSig, off1, off0,
             instNext, coreInWidth, stWidth, Net]
  split
  · omega
  · split <;> decide +kernel

/-- ⛔ **WHY `instOK_mono` CANNOT LIFT THIS ONE — the theorem that makes the ordering real.**

The decoder's outputs sit ABOVE `off0`, so `regWrite`'s σ does *not* land below `off0` and the
monotone lemma has no premise to work from. Placements #1–#4 were order-independent; this one is
not, and the difference is exhibited rather than asserted. *Anyone extending this file who assumes
`instOK_mono` covers every organ will produce a placement that type-checks against the wrong
offset.* -/
theorem regWrite_is_NOT_placeable_at_off0 : ¬ (regWriteSig 5 < off0) := by
  simp only [regWriteSig, decOut, decoderSig, off0, coreInWidth, stWidth, Net]
  decide +kernel

/-- **CONTROL: the two decoder-driven wires are DISTINCT and correctly ordered.** `valid` is
output 5 and `isBEQ` is output 4; swapping them would place a well-typed core that write-enables
on the wrong predicate. Both facts asserted, because the σ picks them by INDEX. -/
theorem valid_and_isBEQ_are_distinct_and_ordered :
    regWriteSig 5 = decOut 5 ∧ regWriteSig 6 = decOut 4 ∧ decOut 4 ≠ decOut 5 := by
  refine ⟨by simp [regWriteSig], by simp [regWriteSig], ?_⟩
  simp only [decOut, decoderSig, off0, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: `rd` lands in the instruction, not in the state and not in the decoder's gates.**
Three regions now exist below `off1` and σ must hit the right one for each input. -/
theorem rd_bits_are_in_the_instruction (j : Nat) (hj : j < 5) :
    stWidth ≤ regWriteSig j ∧ regWriteSig j < off0 := by
  simp only [regWriteSig, rdBit, instrNet, instrBase, off0, coreInWidth, stWidth, Net]
  split
  · omega
  · omega


end SaltWorks.HDL.CorePlace
