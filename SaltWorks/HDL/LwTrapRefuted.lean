/-
# ROW v — THE ONE WITNESS: does a TRAPPING `LW` refute `RegDatapathOK`?

Authorized by the Captain, council 2026-08-30, row v, ACCEPT REC. Criterion pre-registered
on the bus at 11:03:41 BEFORE this file was written; P5 (`selOut 0`) was deliberately left
unpredicted there.

FIXTURE: `insT` is `insL`'s trapping sibling, changed in ONE field — the immediate, 4 -> 1.
  x2 = 4 (net 66), x1 = 4 (net 34).  addr = x2 + sext(1) = 5: in range, MISALIGNED => TRAP.
-/
import SaltWorks.HDL.C4Refuted

namespace SaltWorks.HDL.LwTrapRefuted

open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL.C4Refuted

set_option maxHeartbeats 4000000

def wT : BitVec 32 := encode (.LW 1 2 1)
def sT : Nat := 2 ^ 66 ||| 2 ^ 34 ||| (wT.toNat * 2 ^ 1056)
def insT : Env := fun n => sT.testBit n

/-! ### P1 — the fixture is the word I claim -/
theorem seen_insT : seenWord insT = wT := by decide +kernel

theorem dec_insT : decode (seenWord insT) = some (Instr.LW 1 2 1) := by
  rw [seen_insT]; exact decode_encode _

/-! ### P2 — TRAPPING, read by an independent reader (`addrClass`, not my prose) -/
theorem x2_insT : (decQ insT).get 2 = 4 := by decide +kernel

theorem trapping_insT :
    addrClass ((decQ insT).get 2 + (1 : BitVec 12).signExtend 32) = AddrClass.misaligned := by
  decide +kernel

theorem not_ok_insT :
    ¬ (addrClass ((decQ insT).get 2 + (1 : BitVec 12).signExtend 32) = AddrClass.ok) := by
  rw [trapping_insT]; decide

/-! ### P3 — THE ENABLE FIRES ON A TRAPPING LOAD -/
theorem rw_insT : run insT core.gates (rwOut r1.val) = true :=
  (runB_eq core.gates sT (rwOut r1.val)).symm.trans (by decide +kernel)

/-! ### P4 — the ISA HOLDS x1 = 4, so its bit 0 is clear and its bit 2 is set -/
theorem isa0_insT : ((stepT (decQ insT) (seenWord insT)).regs[r1.val]).getLsbD 0 = false := by
  decide +kernel

theorem isa2_insT : ((stepT (decQ insT) (seenWord insT)).regs[r1.val]).getLsbD 2 = true := by
  decide +kernel

/-! ### P5 — THE MEASUREMENT. Unpredicted in the pre-registration. -/
theorem sel0_insT : run insT core.gates (selOut 0) = true :=
  (runB_eq core.gates sT (selOut 0)).symm.trans (by decide +kernel)

theorem sel2_insT : run insT core.gates (selOut 2) = true :=
  (runB_eq core.gates sT (selOut 2)).symm.trans (by decide +kernel)

/-! ### THE VERDICT -/
theorem regDatapathOK_is_false_on_trapping_LW : ¬ RegDatapathOK := by
  intro h
  have hx := h insT r1 0 (by decide)
  rw [rw_insT, if_pos rfl, sel0_insT, isa0_insT] at hx
  exact Bool.noConfusion hx

/-! ### THE NEGATIVE CONTROL — the same four cells at the LANDED NON-TRAPPING `insL`,
where the sides are known to AGREE. If this reports a refutation the harness is broken. -/
theorem control_ok_insL :
    addrClass ((decQ insL).get 2 + (4 : BitVec 12).signExtend 32) = AddrClass.ok := by
  decide +kernel

theorem control_sides_agree_insL :
    (if run insL core.gates (rwOut r1.val) then run insL core.gates (selOut 2)
     else insL (32 * r1.val + 2))
      = ((stepT (decQ insL) (seenWord insL)).regs[r1.val]).getLsbD 2 :=
  lw_sides_agree_at_insL

#audit_axioms regDatapathOK_is_false_on_trapping_LW control_sides_agree_insL

end SaltWorks.HDL.LwTrapRefuted

/-! ## ADDENDA — written AFTER the verdict, each one a hostile check of it. -/

namespace SaltWorks.HDL.LwTrapRefuted.Addenda
open SaltWorks.HDL SaltWorks.ISA SaltWorks.HDL.CorePlace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL.C4Refuted SaltWorks.HDL.LwTrapRefuted
-- ⛔ NO `open SaltWorks.Stack.Program` HERE: it makes `seenWord` AMBIGUOUS (two constants,
-- one name) and silently sorry-fills the two theorems below. Qualify `RegField` instead.

/-! ### CONTROL 2 — WITHIN THE FIXTURE, and it can reject.
At bit 2 the address (5) and the held x1 (4) AGREE. If my instrument refuted here too it
would be a blanket refuter and the bit-0 reading would be worthless. -/
theorem sides_agree_at_bit_two_insT :
    (if run insT core.gates (rwOut r1.val) then run insT core.gates (selOut 2)
     else insT (32 * r1.val + 2))
      = ((stepT (decQ insT) (seenWord insT)).regs[r1.val]).getLsbD 2 := by
  rw [rw_insT, if_pos rfl, sel2_insT, isa2_insT]

/-! ### MECHANISM — WHAT is the core putting on the write bank on a load?
addr = 5 = 0b101.  If the select bank carries the ALU sum, bit 1 is CLEAR. -/
theorem sel1_insT : run insT core.gates (selOut 1) = false :=
  (runB_eq core.gates sT (selOut 1)).symm.trans (by decide +kernel)

/-! ### ⛔ THE HOSTILE CHECK OF THE 2026-08-29 RETIREMENT ITSELF.
`insL` is NON-trapping: addr = 8 = 0b1000, ISA writes the constant 0 from the all-zero
memory. The retirement read ONE BIT (bit 2) and found agreement. Bit 3 of 8 is SET. -/
theorem sel3_insL : run insL core.gates (selOut 3) = true :=
  (runB_eq core.gates sL (selOut 3)).symm.trans (by decide +kernel)

theorem isa3_insL : ((stepT (decQ insL) (seenWord insL)).regs[r1.val]).getLsbD 3 = false := by
  decide +kernel

theorem regDatapathOK_is_false_at_the_LANDED_witness : ¬ RegDatapathOK := by
  intro h
  have hx := h insL r1 3 (by decide)
  rw [rw_insL, if_pos rfl, sel3_insL, isa3_insL] at hx
  exact Bool.noConfusion hx

/-! ### THE REVERSE REDUCTION — the schema's arrow runs BOTH ways.
`regField_iff_bits` is an iff and `core_outBit_reg_reduced` an equality, so the 32 register
fields do not merely FOLLOW FROM `RegDatapathOK`, they are EQUIVALENT to it. -/
theorem regDatapathOK_of_regFields
    (h : ∀ r : Fin 32, SaltWorks.Stack.Program.RegField core r) : RegDatapathOK := by
  intro ins r k hk
  have hb := (SaltWorks.Stack.Program.regField_iff_bits core r).mp (h r) ins k hk
  rwa [core_outBit_reg_reduced ins r.val k r.isLt hk] at hb

/-! ### ⛔⛔ THE CONSEQUENCE FOR THE FLAGSHIP. -/
theorem not_c4Spec_core_of_not_regDatapathOK (hn : ¬ RegDatapathOK) :
    ¬ SaltWorks.HDL.C4Spec core := by
  intro hc
  exact hn (regDatapathOK_of_regFields
    ((SaltWorks.Stack.Program.c4Spec_iff_fieldwise core).mp hc).2.1)

theorem not_c4Spec_core_on_trapping_LW : ¬ SaltWorks.HDL.C4Spec core :=
  not_c4Spec_core_of_not_regDatapathOK regDatapathOK_is_false_on_trapping_LW

#audit_axioms sides_agree_at_bit_two_insT sel1_insT
#audit_axioms regDatapathOK_is_false_at_the_LANDED_witness
#audit_axioms regDatapathOK_of_regFields not_c4Spec_core_on_trapping_LW

end SaltWorks.HDL.LwTrapRefuted.Addenda
