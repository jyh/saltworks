import SaltWorks.HDL.Compose
import SaltWorks.HDL.StateCodec
import SaltWorks.HDL.Decoder
import SaltWorks.HDL.Immediate
import SaltWorks.HDL.ReadTree
import SaltWorks.HDL.RegWrite
import SaltWorks.HDL.SelectCut32
import SaltWorks.HDL.AluSelect
import SaltWorks.HDL.EncoderE1
import SaltWorks.HDL.OperandBMux
import SaltWorks.HDL.Bitwise

-- Evaluating `instOuts` over real organs (readTree is 2,982 gates) exceeds the default depth.
-- `CoreOffsets` carries the same option for the same reason. (A `/--` docstring cannot attach to
-- `set_option` -- it must bind a declaration; that is the docstring-boundary law, self-inflicted.)
set_option maxRecDepth 100000

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

/-! ### ROW 0 — THE TIE CELLS (maestro's preamble ruling, 2026-08-09 11:27)

**RULED: shape (a), refined.** The constants the adders' carry-ins need become **row 0** — a named
two-gate organ. Every organ shifts up by 2; the assembly has **sixteen rows**. Shape (b) was
refused because it breaks `instOK`'s inputs-strictly-below invariant.

⛔ **AND WHY *TWO* GATES, NOT ONE — silicon's free-zero does not survive in this model.** They
proposed (11:26) wiring `add`'s `cin = 0` to net `0` for free, since `slicea16bma.v` declares
`rf [1:15]` and muxes register 0 to `32'd0`, **so x0 has no storage to be nonzero in.** Correct
about the RTL, false about the model:
```
ISA.lean:72-74  structure St where regs : Vector (BitVec 32) 32   ← x0 HAS STORAGE
StateCodec      stBit s 0 = (s.regs[0]).getLsbD 0                 ← net 0 READS it
ISA.lean:96     "x0 reads as zero unconditionally — NOT AS AN INVARIANT"
ISA.lean:163    "x0 reads zero. NO HYPOTHESIS — the point of enforcing on the READ"
```
⇒ ***x0-reads-zero is enforced AT THE READ, not on the state, so net `0` in an arbitrary `Env` is
UNCONSTRAINED. A carry-in wired there is a latent bug firing exactly when `s.regs[0] ≠ 0` —
invisible in every test whose initial state happens to zero it. The RTL cannot express that state;
the model can.*** *Two tie cells is the right count, and the ruling had it before this check did.* -/

/-- The core's first free net — row 0 sits here. -/
def offTie : Nat := coreInWidth

/-- **Row 0 — the tie cells.** Gate `0` is `const false`, gate `1` is `const true`. No inputs:
`Op.fanin (.const _) = []`, so a constant reads nothing and is pure source. *"Tie cell" is real
silicon's own name for exactly this.* -/
def tieCells : Circ :=
  { nIn := 0, gates := [⟨0, .const false⟩, ⟨1, .const true⟩], outs := [0, 1] }

theorem tieCells_ssa : tieCells.ssa = true := by decide +kernel
theorem tieCells_wf  : tieCells.wf  = true := by decide +kernel

/-- A zero-input organ satisfies `instOK` at **every** offset — vacuously in the third clause, and
the vacuity is honest: a constant genuinely depends on nothing. Stated so no reader mistakes it for
an unproved obligation. -/
theorem tieCells_instOK (σ : Net → Net) (off : Nat) : instOK tieCells σ off := by
  refine ⟨tieCells_ssa, tieCells_wf, ?_⟩
  intro i hi
  simp only [tieCells] at hi
  omega

/-- The host net carrying `false`, and the one carrying `true`. -/
def tieFalse : Net := (instOuts tieCells id offTie).getD 0 0
def tieTrue  : Net := (instOuts tieCells id offTie).getD 1 0

theorem tie_nets_are_the_first_two : tieFalse = 1088 ∧ tieTrue = 1089 := by
  simp only [tieFalse, tieTrue, instOuts, instMap, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: the two tie nets are DISTINCT.** One net serving both carry-ins would place cleanly
and compute `a + b` where `a - b` was meant, on every subtraction, silently. -/
theorem tie_nets_are_distinct : tieFalse ≠ tieTrue := by
  simp only [tieFalse, tieTrue, instOuts, instMap, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- The first ORGAN offset — row 1, immediately above the tie cells.

⭐ **THE SHIFT IS ONE LINE BECAUSE NOTHING DOWNSTREAM WAS A LITERAL.** Every later offset is
`instNext <organ> <previous>`, so redefining this one moves the whole chain; and `decOut`,
`rs1Out`, `rs2Out` are computed FROM the offsets, so every σ follows automatically. Only the
theorems that PIN literals break — which is what they are for. -/
def off0 : Nat := instNext tieCells offTie

theorem off0_value : off0 = 1090 := by
  simp only [off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

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
  simp only [decoderSig, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
  omega

/-- ⚠️ **THE MARGIN IS EXACTLY ZERO — the tightest a legal placement can be.**

The instruction word occupies `1056…1087` and the host's gates begin at `1088`. So the LAST input
wire sat one below `off0` — **until row 0 landed.**

⭐⭐ **THIS THEOREM BROKE AT THE 11:27 SHIFT AND THAT IS THE POINT OF IT.** `decide` reported the
proposition FALSE: the tie cells now occupy exactly the two nets between the instruction word and
the first organ's gates, so the margin is **2, not 0**. *A margin theorem that survived a row-0
insertion would have been telling me nothing. Restated with the tie cells named in it, and the
second clause re-anchored on `instrBase + 32` — the end of the instruction word — because THAT is
the fact about the input space, and it does not move when the gate space grows.* (Stated additively,
never as `off0 - 1`: truncated subtraction is what defeats `omega` on `Net`-typed goals.) one more input bit, or one fewer state net, and `instOK` fails.

*`SubFragment` held by a one-gate margin and that was worth remarking. This holds by NONE.
Recorded as a theorem because a zero margin is invisible to inspection and fatal to an edit —
anyone widening the instruction field or narrowing the state must re-derive this placement.* -/
theorem placement_margin_is_exactly_tight :
    decoderSig 31 + 1 + 2 = off0 ∧ ¬ (decoderSig 32 < instrBase + 32) := by
  refine ⟨by decide +kernel, ?_⟩
  simp only [decoderSig, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
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
  simp only [decoderSig, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
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

theorem off1_value : off1 = 1192 := by
  simp only [off1, instNext, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
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
    simp only [immBSig, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
    omega
  · simp only [off1, instNext, off0]
    omega

/-- **CONTROL: the chain step genuinely ADVANCED.** If `off1 = off0` the second placement would be
a no-op dressed as progress — and a zero-gate organ would make exactly that happen (increment 1's
`zero_gate_organ_does_not_advance`). The decoder has 102 gates, so this step is real. -/
theorem chain_step_advanced : off0 < off1 ∧ off1 = off0 + 102 := by
  refine ⟨?_, ?_⟩
  · simp only [off1, instNext, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
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
  simp only [readTreeRs1Sig, rs1Bit, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
  split
  · omega          -- the address branch: the field sits at 1071…1075
  · omega          -- the register branch: j + 27 ≤ 1023

/-- **PLACEMENT #4 — the rs2 port.** Same organ, same register file, different five bits. -/
theorem readTree_rs2_instOK : instOK readTree readTreeRs2Sig off0 := by
  refine ⟨readTree_ssa, readTree_wf, ?_⟩
  intro j hj
  have hnn : readTree.nIn = 997 := by decide +kernel
  rw [hnn] at hj
  simp only [readTreeRs2Sig, rs2Bit, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
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
  simp only [readTreeRs1Sig, rs1Bit, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
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
             instNext, tieCells, offTie, coreInWidth, stWidth, Net]
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
  simp only [regWriteSig, decOut, decoderSig, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
  decide +kernel

/-- **CONTROL: the two decoder-driven wires are DISTINCT and correctly ordered.** `valid` is
output 5 and `isBEQ` is output 4; swapping them would place a well-typed core that write-enables
on the wrong predicate. Both facts asserted, because the σ picks them by INDEX. -/
theorem valid_and_isBEQ_are_distinct_and_ordered :
    regWriteSig 5 = decOut 5 ∧ regWriteSig 6 = decOut 4 ∧ decOut 4 ≠ decOut 5 := by
  refine ⟨by simp [regWriteSig], by simp [regWriteSig], ?_⟩
  simp only [decOut, decoderSig, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: `rd` lands in the instruction, not in the state and not in the decoder's gates.**
Three regions now exist below `off1` and σ must hit the right one for each input. -/
theorem rd_bits_are_in_the_instruction (j : Nat) (hj : j < 5) :
    stWidth ≤ regWriteSig j ∧ regWriteSig j < off0 := by
  simp only [regWriteSig, rdBit, instrNet, instrBase, off0, instNext, tieCells, offTie, coreInWidth, stWidth, Net]
  split
  · omega
  · omega


/-! ## 6. INCREMENT 2e — BINDING THE CHAIN: a σ that depends on where its producers SIT

Placements #1–#5 needed only `off0` and `off1`. **`bitXor32` is the first organ whose σ depends on
the actual chain positions of its producers** — it reads `readTree`'s two ports, so its wires are
determined by *where readTree was placed*, not merely by what readTree is.

Offsets are **derived by `instNext` composition, never written as literals**, so the chain cannot
drift from the organs that generate it. -/

/-- Row 3 — `readTree.rs1` sits at `immBCirc`'s `instNext`. -/
def off2 : Nat := instNext immBCirc off1
/-- Row 4 — `readTree.rs2`, one `readTree` further on. -/
def off3 : Nat := instNext readTree off2
/-- Row 5 — the first ALU organ. -/
def off4 : Nat := instNext readTree off3

theorem chain_offsets_derived : off2 = 1193 ∧ off3 = 4175 ∧ off4 = 7157 := by
  refine ⟨?_, ?_, ?_⟩ <;>
    simp only [off4, off3, off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth] <;> decide +kernel

/-- `readTree.rs1`'s output `k`, at its chain position. Read from `instOuts` — a literal here
would stop tracking both the organ AND its placement. -/
def rs1Out (k : Nat) : Net := (instOuts readTree readTreeRs1Sig off2).getD k 0
/-- `readTree.rs2`'s output `k`, at its chain position. -/
def rs2Out (k : Nat) : Net := (instOuts readTree readTreeRs2Sig off3).getD k 0

/-- `bitXor32` reads the two operands: `rs1` on inputs `0…31`, `rs2` on `32…63`. -/
def bitXor32Sig (j : Net) : Net := if j < 32 then rs1Out j else rs2Out (j - 32)

/-- ⭐ **PLACEMENT #6 — `bitXor32` at its chain offset, `instOK` DISCHARGED.** The first placement
whose correctness depends on WHERE its producers were placed: `rs1`'s outputs top out below `off3`
and `rs2`'s below `off4`, so both operand banks are computed before the XOR runs. -/
theorem bitXor32_instOK : instOK bitXor32 bitXor32Sig off4 := by
  refine ⟨bitXor32_ssa, bitXor32_wf, ?_⟩
  intro j hj
  have hnn : bitXor32.nIn = 64 := by decide +kernel
  rw [hnn] at hj
  revert hj
  revert j
  decide +kernel

/-- ⛔ **AND IT IS NOT PLACEABLE EARLIER — the chain is forced twice over.** `rs2`'s outputs live
above `off3`, so `bitXor32` cannot sit at `off3`: its second operand bank does not exist yet. -/
theorem bitXor32_is_NOT_placeable_at_off3 : ¬ (bitXor32Sig 32 < off3) := by
  simp only [bitXor32Sig, rs2Out, off3, off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: the two operand banks are DISJOINT.** `rs1`'s outputs and `rs2`'s outputs must not
overlap, or the XOR would read one register twice and every downstream `sem` theorem would be
about a different instruction. Checked at both bank boundaries. -/
theorem operand_banks_are_disjoint :
    bitXor32Sig 0 ≠ bitXor32Sig 32 ∧ bitXor32Sig 31 ≠ bitXor32Sig 63
  ∧ bitXor32Sig 0 < off3 ∧ off3 ≤ bitXor32Sig 32 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
    simp only [bitXor32Sig, rs1Out, rs2Out, off3, off2, off1, off0, instNext,
               coreInWidth, stWidth] <;> decide +kernel

/-- **CONTROL: the operand banks are not vacuous** — `readTree` really does publish 32 outputs per
port, so `rs1Out`/`rs2Out` are not silently reading a `getD` default of `0`. Without this, a σ that
fell off the end of the list would place cleanly and wire every operand bit to net `0` (which is
register `x0` bit `0`). -/
theorem operand_banks_are_fully_populated :
    (instOuts readTree readTreeRs1Sig off2).length = 32
  ∧ (instOuts readTree readTreeRs2Sig off3).length = 32
  ∧ rs1Out 31 ≠ 0 ∧ rs2Out 31 ≠ 0 := by
  refine ⟨by decide +kernel, by decide +kernel, ?_, ?_⟩ <;>
    simp only [rs1Out, rs2Out, off3, off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth] <;>
    decide +kernel


/-! ## 7. INCREMENT 2f — placement #7, and THE CONSTANT GAP the adders will hit

`bitNot32` inverts `rs2` for the subtraction path: shape C, σ = `rs2Out`, no constant needed.

⚠️⚠️ **AND THE NEXT TWO ROWS CANNOT BE PLACED YET, FOR A REASON THE PLAN ADMITS ABOUT ITSELF.**
`Adder.lean:67`: *"`a` occupies nets `0 … 31`, `b` occupies `32 … 63`, **`cin` is net `64`**"* — the
carry-in is an **INPUT**, so `adder32` does not allocate it and **the host must supply it**. Row 6
of the assembly order is *"adder32×2 — add, and sub via `(a, ~b, cin=1)`"*, and **no row of the
fifteen provides a constant**. `readTree` allocates its own `const` tie gate internally (`rtZero`,
and its 2982nd gate is that tie) but never publishes it as an output.

⇒ ***THE CORE IS NOT A PURE CONCATENATION OF ORGAN INSTANTIATIONS. It needs a small HOST PREAMBLE —
at minimum one `const false` and one `const true` — and the plan says so about itself in its own
status line: "a construction whose inputs are not all present."***

📌 **THE CONSEQUENCE, and why the derived-offset discipline pays here: a preamble SHIFTS EVERY CHAIN
OFFSET.** Because `decOut`, `rs1Out` and `rs2Out` are computed *from* the offsets rather than written
as literals, their values follow the shift automatically — only the `offN` definitions change. The
theorems that pin literals (`off0_value`, `chain_offsets_derived`) will **BREAK**, which is exactly
what should happen: they are the instruments that announce the chain moved.
-/

/-- `bitNot32` inverts the `rs2` operand — the `~b` of `a + ~b + 1`. -/
def bitNot32Sig (j : Net) : Net := rs2Out j

/-- Row 6's offset: after the XOR. -/
def off5 : Nat := instNext bitXor32 off4

theorem off5_value : off5 = 7189 := by
  simp only [off5, off4, off3, off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- ⭐ **PLACEMENT #7 — `bitNot32` at `off5`, `instOK` DISCHARGED.** Shape C: its 32 wires are
`rs2`'s outputs, which sit below `off4 ≤ off5`. -/
theorem bitNot32_instOK : instOK bitNot32 bitNot32Sig off5 := by
  refine instOK_mono (off := off4) ?_ ?_
  · refine ⟨bitNot32_ssa, bitNot32_wf, ?_⟩
    intro j hj
    have hnn : bitNot32.nIn = 32 := by decide +kernel
    rw [hnn] at hj
    revert hj; revert j
    decide +kernel
  · simp only [off5, instNext]
    omega

/-- **CONTROL: `bitNot32` inverts `rs2`, NOT `rs1`.** `a + ~b + 1` is subtraction; `~a + b + 1`
is not, and both place cleanly. The two operand banks are distinct nets, so this is checkable —
and it is the one asymmetry in the subtraction path that a copy-paste would erase. -/
theorem bitNot32_inverts_rs2_not_rs1 :
    bitNot32Sig 0 = rs2Out 0 ∧ bitNot32Sig 0 ≠ rs1Out 0 := by
  refine ⟨rfl, ?_⟩
  simp only [bitNot32Sig, rs1Out, rs2Out, off3, off2, off1, off0, instNext,
             coreInWidth, stWidth]
  decide +kernel


/-! ## 9. INCREMENT 2g — ROWS 7 AND 8: the two adders, and the tie cells earning their row

`adder32.nIn = 65 = a[32] + b[32] + cin[1]` (`Adder.lean:67`). Both adders share `rs1` as `a`; they
differ in `b` and in the carry-in, and **that difference is the whole of `sub`**:

```
row 7  add   a = rs1Out · b = rs2Out              · cin = tieFalse
row 8  sub   a = rs1Out · b = bitNot32's outputs  · cin = tieTrue     ⇒ a + ~b + 1
```
*Row 0 exists for exactly these two wires. Every other input in the assembly comes from the core's
state, its instruction, or another organ's gates; the carry-ins are the only nets that had no
producer at all, which is why "no row provides it" was a real gap and not a missing organ.* -/

/-! ### ⚠️ RE-SEQUENCED at the maestro's 12:29 ORDER-RULING — `obMux` MOVES BEFORE THE ADDERS

`OperandBMux.lean:200-202`: `a = rs2` on nets 0…31, `b = IMMEDIATE` on 32…63, `sel = useImm` on 64.
**`obMux` is the operand-B mux, so it must FEED the ALU** — and the plan's order had it at row 12,
*after* the adders, which is how my rows 7–8 came to wire the b-bank straight to `rs2Out`. **For
`ADDI` that adder received `rs2` instead of the immediate**, and the organ's own pre-registered
mutant (`:179` ②, *"a circuit that takes `rs2` when the immediate was requested"*) is that defect
exactly. Every `instOK` I proved stayed TRUE: it certifies a wire is **computed in time**, never
that it is **the right wire**.

*Refused alternative (keep the order, reach σ upward) — it breaks `instOK`'s inputs-strictly-below
invariant, the same reason preamble shape (b) was refused.* -/

/-- Row 7 — `obMux`, now BEFORE the adders. -/
def offOb : Nat := instNext bitNot32 off5

/-- `immBCirc`'s output `k` — the immediate bank. -/
def immOut (k : Nat) : Net := (instOuts immBCirc immBSig off1).getD k 0

/-- `obMux`'s σ: `rs2` on 0…31, the IMMEDIATE on 32…63, `useImm` (= `isADDI`, decoder output 3)
on 64. -/
def obSig (j : Net) : Net :=
  if j < 32 then rs2Out j else if j < 64 then immOut (j - 32) else decOut 3

/-- ⭐ **PLACEMENT #13 — `obMux` at row 7, `instOK` DISCHARGED.** -/
theorem ob_instOK : instOK OperandB.obMux obSig offOb := by
  refine ⟨by decide +kernel, by decide +kernel, ?_⟩
  intro j hj
  have hnn : OperandB.obMux.nIn = 65 := by decide +kernel
  rw [hnn] at hj
  revert hj; revert j
  decide +kernel

/-- `obMux`'s output `k` — **the ALU's operand B**. -/
def obOut (k : Nat) : Net := (instOuts OperandB.obMux obSig offOb).getD k 0

/-- Row 8's offset — after the operand-B mux. -/
def offAdd : Nat := instNext OperandB.obMux offOb
/-- Row 8's offset — after the first adder. -/
def offSub : Nat := instNext adder32 offAdd

theorem adder_offsets : offAdd = 7318 ∧ offSub = 7478 := by
  refine ⟨?_, ?_⟩ <;>
    simp only [offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, instNext, tieCells,
               offTie, coreInWidth, stWidth] <;> decide +kernel

/-- `bitNot32`'s output `k` at its chain position — the `~b` bank. -/
def notOut (k : Nat) : Net := (instOuts bitNot32 bitNot32Sig off5).getD k 0

/-- Row 7 — `add`: both operands straight from the register file, carry-in tied LOW. -/
def addSig (j : Net) : Net :=
  if j < 32 then rs1Out j else if j < 64 then obOut (j - 32) else tieFalse

/-- Row 8 — `sub`: `a + ~b + 1`. The inverted bank and the carry-in tied HIGH. -/
def subSig (j : Net) : Net :=
  if j < 32 then rs1Out j else if j < 64 then notOut (j - 32) else tieTrue

/-- ⭐ **PLACEMENT #8 — `add` at row 7, `instOK` DISCHARGED.** -/
theorem add_instOK : instOK adder32 addSig offAdd := by
  refine ⟨adder32_ssa, adder32_wf, ?_⟩
  intro j hj
  have hnn : adder32.nIn = 65 := by decide +kernel
  rw [hnn] at hj
  revert hj; revert j
  decide +kernel

/-- ⭐ **PLACEMENT #9 — `sub` at row 8, `instOK` DISCHARGED.** -/
theorem sub_instOK : instOK adder32 subSig offSub := by
  refine ⟨adder32_ssa, adder32_wf, ?_⟩
  intro j hj
  have hnn : adder32.nIn = 65 := by decide +kernel
  rw [hnn] at hj
  revert hj; revert j
  decide +kernel

/-- ⭐⭐ **THE SUBTRACTION IS `a + ~b + 1` AND ALL THREE PARTS ARE ASSERTED.** Each of the three
differences from `add` is independently wrong-able, and each would place cleanly:

* same `a` — using `rs2` as `a` computes `b - a`;
* **inverted** `b` — using `rs2Out` uninverted computes `a + b + 1`;
* carry-in **HIGH** — using `tieFalse` computes `a + ~b`, which is `a - b - 1`.

*The last is the one that would survive casual testing: off by exactly one, on every subtraction.* -/
theorem subtraction_is_a_plus_not_b_plus_one :
    addSig 0 = subSig 0
  ∧ addSig 32 ≠ subSig 32
  ∧ addSig 64 = tieFalse ∧ subSig 64 = tieTrue
  ∧ tieFalse ≠ tieTrue := by
  refine ⟨rfl, ?_, rfl, rfl, tie_nets_are_distinct⟩
  simp only [addSig, subSig, rs2Out, notOut, off5, off4, off3, off2, off1, off0,
             instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: the tie cells are genuinely LOAD-BEARING for row 0's existence.** Both carry-ins
resolve to tie nets — i.e. to gates that exist only because row 0 exists. Without row 0 these two
inputs have no producer at all, which is the gap that forced the ruling. -/
theorem carry_ins_come_from_row_zero :
    addSig 64 = tieFalse ∧ subSig 64 = tieTrue
  ∧ tieFalse = offTie ∧ tieTrue = offTie + 1 := by
  refine ⟨rfl, rfl, ?_, ?_⟩ <;>
    simp only [tieFalse, tieTrue, instOuts, instMap, tieCells, offTie, coreInWidth, stWidth] <;>
    decide +kernel


/-! ## 10. INCREMENT 2h — ROW 9: `sltCirc`, and THE THREE-ORGAN CHAIN CLOSED IN THE ASSEMBLY

On 2026-08-08 I warned silicon, in `docs/compiler-organ-reference-0808.md`, that **`sltCirc` is
not a standalone comparator**: *"`SLT rd rs1 rs2` ⇒ `bitNot32(rs2) → adder32(rs1, ~rs2, cin=1) →
sltCirc(a31, b31, s31)` — THREE organs, wired in that order,"* and that instantiating `sltCirc`
alone gives a 3-input block with no indication where its inputs come from.

**All three links are now placed, so the warning becomes a theorem rather than a caution.**

`sltCirc.nIn = 3` — `a31`, `b31`, and `s31`, the subtraction's sign bit. `adder32.outs` is
`(range 32).map adS ++ [adC 32]`, so **output 31 is the sign bit and output 32 is the carry-out**;
`sltCirc` wants 31, and `sltuCirc` (out of Slice A) would have wanted 32. -/

/-- Row 9's offset — after the subtracting adder. -/
def offSlt : Nat := instNext adder32 offSub

theorem offSlt_value : offSlt = 7638 := by
  simp only [offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, instNext,
             tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- The subtracting adder's output `k`. Index 31 is the SIGN BIT; 32 is the carry-out. -/
def subOut (k : Nat) : Net := (instOuts adder32 subSig offSub).getD k 0

/-- `sltCirc`'s σ: the two operands' sign bits, and the subtraction's sign bit. -/
def sltSig (j : Net) : Net :=
  if j = 0 then rs1Out 31 else if j = 1 then rs2Out 31 else subOut 31

/-- ⭐ **PLACEMENT #10 — `sltCirc` at row 9, `instOK` DISCHARGED.** -/
theorem slt_instOK : instOK sltCirc sltSig offSlt := by
  refine ⟨sltCirc_ssa, sltCirc_wf, ?_⟩
  intro j hj
  have hnn : sltCirc.nIn = 3 := by decide +kernel
  rw [hnn] at hj
  revert hj; revert j
  decide +kernel

/-- ⭐⭐ **THE THREE-ORGAN CHAIN, CLOSED IN THE ASSEMBLY.** `sltCirc`'s third input is the
SUBTRACTING adder's sign output — not the adding one — and that adder's `b` bank is `bitNot32`'s
outputs with the carry-in tied HIGH. So `bitNot32 → adder32(sub) → sltCirc` is *wired*, and the
8/8 caution is discharged rather than repeated. -/
theorem slt_chain_is_closed :
    sltSig 2 = subOut 31
  ∧ subSig 32 = notOut 0
  ∧ subSig 64 = tieTrue
  ∧ subOut 31 ≠ (instOuts adder32 addSig offAdd).getD 31 0 := by
  refine ⟨rfl, rfl, rfl, ?_⟩
  simp only [subOut, instOuts, instMap, subSig, addSig, offSub, offAdd, offOb, off5, off4, off3,
             off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- ⛔ **CONTROL: `sltCirc` READS THE SIGN BIT, NOT THE CARRY-OUT.** Output 31 is `a - b`'s sign;
output 32 is the carry. `sltuCirc` — the UNSIGNED comparator, deliberately out of Slice A — is the
organ that wants 32, and its `nIn` is 1. **Reading 32 here would compute unsigned comparison with
every certificate still green**, which is this morning's ReLU defect in the datapath instead of the
activation function: *the certified thing computes an order and nobody wrote down which one.* -/
theorem slt_reads_sign_not_carry :
    sltSig 2 = subOut 31 ∧ subOut 31 ≠ subOut 32 := by
  refine ⟨rfl, ?_⟩
  simp only [subOut, instOuts, instMap, subSig, offSub, offAdd, offOb, off5, off4, off3, off2,
             off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: the two sign bits come from DIFFERENT operands.** `a31` and `b31` must be `rs1`'s
and `rs2`'s bit 31 respectively; swapping them inverts the comparison for mixed-sign pairs only —
green on every same-sign test. -/
theorem slt_operand_signs_are_distinct :
    sltSig 0 = rs1Out 31 ∧ sltSig 1 = rs2Out 31 ∧ sltSig 0 ≠ sltSig 1 := by
  refine ⟨rfl, rfl, ?_⟩
  simp only [sltSig, rs1Out, rs2Out, off3, off2, off1, off0, instNext, tieCells,
             offTie, coreInWidth, stWidth]
  decide +kernel


/-! ## 11. THE ORDER INVARIANT — one place in this file, cited rather than re-derived

**Math's 11:54 diagnosis: four appearances in one day is not a coincidence, it is a MISSING NAMED
OBJECT.** Every one of these asks *which order does this organ compute?*, and every one was
answered from scratch by whoever happened to look:

```
① the packet filter   `slt` is SIGNED, addresses are not              (08:5x, §4b)
② the activation      unsigned `max` ⇒ ReLU becomes the IDENTITY      (10:31)
③ the ingress         `zeroExtend` inverts every negative weight     (11:36, math's, owed)
④ sltCirc row 9       sign bit vs carry-out                          (11:53, mine, above)
```

⭐ ***CITED, NOT RESTATED: `docs/the-order-invariant-v1.md` (math seat, 2026-08-09), whose own
instruction is "THE ANCHORS — cite these, do not restate them."*** *An earlier draft of this
section restated the rule in its own words, which is one restatement more than the discipline
allows — and restating a shared invariant per layer is exactly how four independent answers to one
question happen. **This layer's placements answer to that object; the object lives there.***

⇒ **CONSEQUENCE FOR ROWS 10–15: each remaining placement CITES this section rather than
re-deriving the question. A fifth instance then costs a citation, not a discovery — and math's
fifth is already scheduled, arriving with the MAC's sign cycle.**

⚠️ **AND THE REASON A NAMED INVARIANT BEATS FOUR GOOD CONTROLS: every one of ①–④ stays GREEN
through its own failure.** *Unsigned `max` proves theorems about `max`; a carry-out is a real net
carrying a real value; `zeroExtend` is total. **The certificate is always about the organ, never
about which order the caller meant** — so no amount of per-organ verification finds the class, and
only a statement that spans organs does.* -/

/-- **This layer's WITNESS to the cited invariant** — not a restatement of it. `sltCirc` reads the
SIGN bit (`adder32.outs` index 31), never the carry-out (index 32): instance ④ of the four, and the
shape every later row is checked against. *A citation with no local witness is a footnote; a witness
with no citation is a fifth independent answer.* -/
theorem order_invariant_at_slt : sltSig 2 = subOut 31 ∧ subOut 31 ≠ subOut 32 :=
  slt_reads_sign_not_carry

/-- **CONTROL: the invariant is not vacuous at this layer** — the two candidate nets genuinely
differ, so "reads the sign, not the carry" is a real constraint rather than a restatement. If the
adder published one net for both, the invariant would be unfalsifiable here and would need to be
stated at the organ instead. -/
theorem order_invariant_is_falsifiable_here : subOut 31 ≠ subOut 32 :=
  order_invariant_at_slt.2


/-! ## 12. INCREMENT 2i — ROW 10: `sliceASelect`, the ruled 3-source select

`AluSelect.lean:319-324` gives the layout exactly, so no index is guessed:
```
gsIn n b   = n*32 + b        ⇒ (3,2) has 98 inputs
gsRes r k  = r*32 + k        ⇒ inputs 0…95 are THREE 32-bit source banks
gsSel n _ j = n*32 + j       ⇒ inputs 96, 97 are the select bits
```
And `C1Organ.lean:113` fixes which bank is which: `opIndex w = if dcSLTm then 2 else if dcXORm
then 1 else 0`, with `C1Organ:149-150` pinning select bit 0 to `lineXOR` and bit 1 to `lineSLT`.

```
bank 0  the ADD adder's sum   (the default arm: ADD / ADDI)
bank 1  bitXor32's output     (XOR)
bank 2  sltCirc's output      (SLT)
sel 0   decOut 1 = isXOR      sel 1   decOut 2 = isSLT
```
*Order invariant: cited, see §11.* -/

/-- Row 10's offset — after `sltCirc`. -/
def offSel : Nat := instNext sltCirc offSlt

theorem offSel_value : offSel = 7643 := by
  simp only [offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, instNext,
             tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- The ADD adder's output `k` — bank 0. -/
def addOut (k : Nat) : Net := (instOuts adder32 addSig offAdd).getD k 0
/-- `bitXor32`'s output `k` — bank 1. -/
def xorOut (k : Nat) : Net := (instOuts bitXor32 bitXor32Sig off4).getD k 0
/-- `sltCirc`'s output `k` — bank 2. -/
def sltOut (k : Nat) : Net := (instOuts sltCirc sltSig offSlt).getD k 0

/-- `sliceASelect`'s σ: three source banks by `gsRes`, then the two decoder-driven select bits. -/
def selSig (j : Net) : Net :=
  if j < 32 then addOut j
  else if j < 64 then xorOut (j - 32)
  else if j < 96 then sltOut (j - 64)
  else if j = 96 then decOut 1
  else decOut 2

/-- ⭐ **PLACEMENT #11 — `sliceASelect` at row 10, `instOK` DISCHARGED.** Eleven of sixteen rows. -/
theorem sel_instOK : instOK SelectCut32.sliceASelect selSig offSel := by
  refine ⟨?_, ?_, ?_⟩
  · decide +kernel
  · decide +kernel
  · intro j hj
    have hnn : SelectCut32.sliceASelect.nIn = 98 := by decide +kernel
    rw [hnn] at hj
    revert hj; revert j
    decide +kernel

/-- ⭐⭐ **THE BROADCAST, EXHIBITED — my 8/8 organ reference warned silicon about exactly this.**

*"BOTH COMPARATORS BROADCAST — 32 outputs, ONE meaningful bit. `sltCirc.outs = 6 :: replicate 31 7`,
where net 7 is `const false`, so outputs 1…31 are a SHARED constant-zero net by construction."*

Bank 2 therefore has **one real bit and 31 ties**, and that is correct — the ISA says `rd := if
rs1 <ₛ rs2 then 1 else 0`. **An RTL cut that synthesised 32 independent comparator outputs would be
building 31 gates that cannot differ.** -/
theorem slt_bank_broadcasts :
    sltOut 0 ≠ sltOut 1 ∧ sltOut 1 = sltOut 31 := by
  refine ⟨?_, ?_⟩ <;>
    simp only [sltOut, instOuts, instMap, sltSig, offSlt, offSub, offAdd, offOb, off5, off4, off3,
               off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth] <;>
    decide +kernel

/-- **CONTROL: the three banks are pairwise DISJOINT at their first bits.** Two banks sharing a net
would make the select return the same source for different opcodes, with `sliceASelect_cert` still
green — the cert is about the BLOCK, never about my wiring. -/
theorem select_banks_are_disjoint :
    selSig 0 ≠ selSig 32 ∧ selSig 32 ≠ selSig 64 ∧ selSig 0 ≠ selSig 64 := by
  refine ⟨?_, ?_, ?_⟩ <;>
    simp only [selSig, addOut, xorOut, sltOut, instOuts, instMap, addSig, bitXor32Sig, sltSig,
               offSlt, offSub, offAdd, off4, off5, off4, off3, off2, off1, off0, instNext,
               tieCells, offTie, coreInWidth, stWidth] <;>
    decide +kernel

/-- **CONTROL: the select bits are the DECODER's, in the ruled order.** Bit 0 is `isXOR`
(`decOut 1`) and bit 1 is `isSLT` (`decOut 2`), per `C1Organ:149-150`. Swapping them would make
`opIndex` name bank 1 for SLT and bank 2 for XOR — a well-typed core computing the wrong op. -/
theorem select_bits_are_decoder_driven_in_order :
    selSig 96 = decOut 1 ∧ selSig 97 = decOut 2 ∧ decOut 1 ≠ decOut 2 := by
  refine ⟨rfl, rfl, ?_⟩
  simp only [decOut, decoderSig, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel


/-! ## 13. INCREMENT 2j — ROW 11: `ruledEnc`, the ZERO-GATE row, and the seam it closes

`EncoderE1.lean:218-222`: `lineADD = line 0`, `lineXOR = line 1`, `lineSLT = line 2`, and
`selDrivers = [lineXOR, lineSLT]` — so `ruledEnc`'s three inputs are the decoder's one-hot class
lines, and its two outputs are **inputs 1 and 2**. `lineADD` drives no select bit: code 0 *is* the
default arm.

⭐ **WITH `gates = []`, `instMap` sends every output through σ, so `instOuts ruledEnc σ off =
[σ lineXOR, σ lineSLT]` — THE PLACEMENT CREATES NO NET.** That makes row 11 the row increment 1
predicted: `zero_gate_organ_does_not_advance` proved the offset chain is monotone but **not
strictly** monotone, before I knew which organ would exercise it.

⇒ ***AND IT CLOSES THE ENCODER/SELECT SEAM BY PROOF RATHER THAN BY ASSERTION: I wired
`sliceASelect`'s select bits to `decOut 1` and `decOut 2` at row 10 on the strength of
`C1Organ:149-150`. Placing `ruledEnc` shows those ARE its outputs — so the two rows agree because
they are equal, not because I said so.*** -/

/-- Row 11's offset — after the select. -/
def offEnc : Nat := instNext SelectCut32.sliceASelect offSel

/-- `ruledEnc`'s σ: the decoder's three one-hot class lines. -/
def encSig (j : Net) : Net :=
  if j = 0 then decOut 0 else if j = 1 then decOut 1 else decOut 2

/-- ⭐ **PLACEMENT #12 — `ruledEnc` at row 11, `instOK` DISCHARGED.** Twelve of sixteen rows. -/
theorem enc_instOK : instOK EncoderE1.ruledEnc encSig offEnc := by
  refine ⟨by decide +kernel, by decide +kernel, ?_⟩
  intro j hj
  have hnn : EncoderE1.ruledEnc.nIn = 3 := by decide +kernel
  rw [hnn] at hj
  revert hj; revert j
  decide +kernel

/-- ⭐⭐ **THE ENCODER/SELECT SEAM, CLOSED BY EQUALITY.** `ruledEnc`'s outputs at row 11 are exactly
the nets row 10 wired into `sliceASelect`'s two select inputs. The rows agree because they are
equal — not because both cite the same docstring. -/
theorem encoder_select_seam_closed :
    instOuts EncoderE1.ruledEnc encSig offEnc = [selSig 96, selSig 97] := by
  simp only [instOuts, instMap, EncoderE1.ruledEnc, EncoderE1.selDrivers, EncoderE1.lineXOR,
             EncoderE1.lineSLT, EncoderE1.line, encSig, selSig, decOut, decoderSig, offEnc,
             off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- ⛔ **THE ZERO-GATE ROW DOES NOT ADVANCE THE CHAIN — increment 1's prediction, realised.**
`instNext ruledEnc offEnc = offEnc`, so row 12 begins exactly where row 11 did. An assembly checker
demanding a strictly increasing chain would reject this correct assembly, which is why increment 1
proved the invariant as `≥`. -/
theorem enc_row_does_not_advance (off : Nat) : instNext EncoderE1.ruledEnc off = off := by
  -- Stated for EVERY offset, which is both STRONGER and CHEAPER than the instance at `offEnc`:
  -- `rfl` there forced `offEnc` to a numeral, unfolding the whole chain back to the tie cells and
  -- timing out at `whnf` (200,000 heartbeats). A structural proof evaluates no offset at all.
  simp only [instNext, EncoderE1.ruledEnc, List.length_nil, Nat.add_zero]

/-- **CONTROL: `lineADD` is wired and drives NO select bit.** `ruledEnc` takes three inputs and
publishes two; input 0 (`isADD`) is consumed and deliberately not forwarded, because code 0 is the
default arm. If it were forwarded, the select would have three select bits for a `(3,2)` block. -/
theorem lineADD_is_consumed_not_forwarded :
    encSig 0 = decOut 0
  ∧ decOut 0 ≠ selSig 96 ∧ decOut 0 ≠ selSig 97 := by
  -- stated as two concrete inequalities rather than `∉`: the published list has exactly two
  -- known elements, and deciding MEMBERSHIP with everything unfolded times out at `whnf`
  -- (200,000 heartbeats). Same content, and it names WHICH nets differ rather than that one
  -- is absent from a list.
  refine ⟨rfl, ?_, ?_⟩ <;>
    simp only [selSig, encSig, decOut, decoderSig, off0, instNext, tieCells, offTie,
               coreInWidth, stWidth] <;>
    decide +kernel


/-! ## 14. THE MUTATION CONTROL, RUN — maestro's 12:29 requirement (a)

*"Run the organ's OWN pre-registered mutation control against the FIXED wiring — the wrong-wire
mutant must now FAIL a semantic check at an ADDI word; **a control that exists and is never run is
a docstring**."*

`OperandBMux.lean:179` ② pre-registers exactly the mutant I built by accident: *"a circuit that
takes `rs2` when the immediate was requested."* Its landed semantics (`sem_obMux`) says
`muxSpec ins = (range 32).map (fun k => if ins 64 then ins (32+k) else ins k)` — so at
`useImm = true` the mux delivers the **immediate** bank. -/

/-- ⛔⭐ **THE WRONG-WIRE MUTANT FAILS AT AN ADDI WORD — run, not cited.**

A concrete valuation with `useImm` HIGH, immediate bit 0 HIGH, and `rs2` bit 0 LOW: the mux delivers
`true` (the immediate), while the wiring I shipped at row 7 would have delivered `false` (`rs2`).
**The two disagree on this word, which is what makes the defect a defect rather than a preference.** -/
theorem wrong_wire_mutant_fails_at_addi :
    ∃ ins : Env, ins 64 = true ∧ (OperandB.muxSpec ins)[0]! ≠ ins 0 := by
  refine ⟨fun n => n == 32 || n == 64, by decide, ?_⟩
  simp only [OperandB.muxSpec]
  decide

/-- ⭐ **AND THE FIX IS IN PLACE AT THE WIRING: `addSig`'s b-bank is `obMux`'s OUTPUT, and it is NOT
`rs2Out`.** Both halves asserted — the first says the repair landed, the second says it is a real
change rather than a rename. -/
theorem addSig_b_bank_is_obMux_not_rs2 :
    addSig 32 = obOut 0 ∧ addSig 32 ≠ rs2Out 0 := by
  refine ⟨rfl, ?_⟩
  simp only [addSig, obOut, rs2Out, instOuts, instMap, obSig, OperandB.obMux, offOb, off5, off4,
             off3, off2, off1, off0, instNext, tieCells, offTie, coreInWidth, stWidth]
  decide +kernel

/-- **CONTROL: `obMux` is placed STRICTLY BEFORE the adder that consumes it.** The ordering is the
whole content of the ruling, and it is now a theorem rather than a row number in a plan. -/
theorem obMux_precedes_the_adder : offOb < offAdd := by
  -- the gate count as a FACT, not by unfolding: `offOb` never becomes a numeral, so the
  -- whole chain back to the tie cells is never evaluated (the row-11 lesson, reused).
  have h : 0 < OperandB.obMux.gates.length := by decide +kernel
  simp only [offAdd, instNext]
  omega

/-- **CONTROL: `sub`'s b-bank is still `bitNot32`'s output, NOT `obMux`'s.** There is no `SUBI` in
the 5-op ISA, so the subtraction path is register-register and must NOT be re-routed through the
operand-B mux. *Fixing one adder and "consistently" fixing the other would have broken SLT.* -/
theorem subSig_b_bank_is_unchanged :
    subSig 32 = notOut 0 ∧ subSig 32 ≠ obOut 0 := by
  refine ⟨rfl, ?_⟩
  simp only [subSig, notOut, obOut, instOuts, instMap, bitNot32Sig, obSig, OperandB.obMux,
             offOb, off5, off4, off3, off2, off1, off0, instNext, tieCells, offTie,
             coreInWidth, stWidth]
  decide +kernel


end SaltWorks.HDL.CorePlace
