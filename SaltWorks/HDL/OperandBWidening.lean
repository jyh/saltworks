/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# Widening operand B — the pieces that do not depend on the placement freeze

Leg ① closes a LEAN-MODEL gap: `core32.v` (byte-identical to the fabricated commit, verified
die-side by silicon 2026-08-28) selects the ALU's operand B on
`is_immop | is_load | is_store | is_jalr`, while the model's `obSig` selects on
`decOut isADDILine` ALONE — so a modelled store addresses `rs1 + rs2` where the die addresses
`rs1 + sext(imm_S)`.

⛔ **THE MODEL IS THE NARROWER ARTIFACT: `obMux` models ONE case of the die's four-way select.**
Carried here from `MemPortCorrespondence` §3, which pins the same gap with `addrLink1..6`.

**This file holds the two pieces that are the same under EITHER placement**, landed ahead of the
freeze so the placement work is not also carrying them:

* the widened select needs NO new signal — `isADDI ∨ req` is exactly the three-way condition,
  because `req` is true on precisely `LW` and `SW`. That was ASSERTED from reading a table in the
  design sketch; here it is a theorem over EVERY word, including those that do not decode.
* `immS`, S-type's immediate as a NET MAP in the shape of the landed `immI` — **zero gates**.

📌 The placement freeze (insert-in-place, Captain 2026-08-28) governs WHERE the widened organs sit.
Nothing in this file depends on that choice.
-/
import SaltWorks.HDL.Decoder
import SaltWorks.HDL.DecoderLines
import SaltWorks.HDL.Immediate
import SaltWorks.HDL.OperandBMux

namespace SaltWorks.HDL
open SaltWorks.HDL SaltWorks.ISA

/-- ⭐⭐ **THE CLAIM MY SKETCH ASSERTED FROM READING A TABLE, NOW A THEOREM.**
`req` is exactly `isLW ∨ isSW`, for EVERY word — including the ones that do not decode. -/
theorem req_is_lw_or_sw (w : BitVec 32) :
    (ctrlSpec w).getD reqLine false
      = ((ctrlSpec w).getD isLWLine false || (ctrlSpec w).getD isSWLine false) := by
  unfold ctrlSpec
  cases h : decode w with
  | none => rfl
  | some i => cases i <;> rfl

/-- ⭐⭐⭐ **THEREFORE THE WIDENED SELECT IS ONE OR GATE.** `isADDI ∨ req` is exactly the
three-way "this instruction addresses with an immediate", so the model needs no new signal. -/
theorem usesImm_is_addi_or_req (w : BitVec 32) :
    ((ctrlSpec w).getD isADDILine false || (ctrlSpec w).getD reqLine false)
      = ((ctrlSpec w).getD isADDILine false
          || (ctrlSpec w).getD isLWLine false
          || (ctrlSpec w).getD isSWLine false) := by
  rw [req_is_lw_or_sw, Bool.or_assoc]

/-- ⛔ **AND THE CONTROL: `req` is NOT the same as any single arithmetic line**, so the OR is
doing work rather than restating something already present. -/
theorem req_is_not_isADDI : ∃ w : BitVec 32,
    (ctrlSpec w).getD reqLine false ≠ (ctrlSpec w).getD isADDILine false :=
  ⟨encode (Instr.SW 1 2 0), by decide +kernel⟩

/-! ## The S-type wiring function — the second freeze-independent piece -/

/-- S-type's immediate, as a NET MAP in the shape of the landed `immI`: `imm[4:0]` from
instruction bits 11:7, `imm[11:5]` from bits 31:25, sign bit 31 above. **Zero gates.** -/
def immS (k : Nat) : Net := if k < 5 then 7 + k else if k < 12 then 25 + (k - 5) else 31

/-- ⭐ **THE WIRING PINNED AGAINST THE ISA'S OWN FIELD STATEMENT**, bit by bit, by the kernel:
`imm[4:0] ← w[11:7]` and `imm[11:5] ← w[31:25]`, and everything at or above 12 is the sign. -/
theorem immS_table :
    (List.range 5).map immS = [7, 8, 9, 10, 11]
    ∧ ((List.range 7).map (fun j => immS (5 + j))) = [25, 26, 27, 28, 29, 30, 31]
    ∧ immS 12 = 31 ∧ immS 31 = 31 := by
  decide +kernel

/-- ⛔ **immS IS NOT immI** — the two extractions genuinely differ, which is why widening the
SELECT alone would fix `LW` and leave `SW` wrong. -/
theorem immS_ne_immI : immS 0 ≠ immI 0 := by decide +kernel

#audit_axioms req_is_lw_or_sw usesImm_is_addi_or_req req_is_not_isADDI
#audit_axioms immS immS_table immS_ne_immI

/-! ## The widened select, as a placeable organ

The organ is freeze-independent: only WHERE it is placed depends on the placement ruling.
⭐ Its partner needs no new circuit at all — choosing `immI` vs `immS` is a 32-bit 2:1 mux
with one select, which IS `OperandB.obMux`, already certified by `out_sem_obMux`. -/

/-- **THE WIDENED SELECT, AS A CIRCUIT.** Two inputs, one OR gate, one output — the whole
widening `core32.v`'s four-way `alu_src` needs in this ISA, because `isADDI ∨ req` is already
the three-way condition (`OperandBWidening.usesImm_is_addi_or_req`). -/
def selOr : Circ := { nIn := 2, gates := [⟨2, .or 0 1⟩], outs := [2] }

theorem selOr_ssa : selOr.ssa = true := by decide +kernel
theorem selOr_wf : selOr.wf = true := by decide +kernel
theorem selOr_gate_count : selOr.gates.length = 1 := by decide +kernel
theorem selOr_ports : selOr.nIn = 2 ∧ selOr.outs.length = 1 := by decide +kernel

/-- ⭐ **ITS MEANING, EXHAUSTIVELY — all four input configurations.** -/
theorem selOr_sem_is_or :
    (List.range 4).all (fun m =>
      sem selOr (fun i => if i = 0 then m % 2 == 1 else m / 2 == 1)
        == [(m % 2 == 1) || (m / 2 == 1)]) = true := by
  decide +kernel

/-- ⛔ **AND THE CONTROL: an AND organ in the same shape does NOT satisfy it**, so the witness
above discriminates rather than passing on anything shaped like a gate. -/
def selAndMutant : Circ := { selOr with gates := [⟨2, .and 0 1⟩] }

theorem selOr_control :
    (List.range 4).all (fun m =>
      sem selAndMutant (fun i => if i = 0 then m % 2 == 1 else m / 2 == 1)
        == [(m % 2 == 1) || (m / 2 == 1)]) = false := by
  decide +kernel

#audit_axioms selOr selOr_ssa selOr_wf selOr_gate_count selOr_ports
#audit_axioms selOr_sem_is_or selAndMutant selOr_control

end SaltWorks.HDL
