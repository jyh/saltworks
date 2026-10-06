/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Step

/-!
# AAU W4 — LW and SW: decode inversion, and phase 3 of the FETCH, LOAD and STORE loops

LW is two loops: FETCH, then LOAD. At the LOAD loop's phase 3 the core writes `rd` from `rdata_r`,
the register that the same edge refills. That is erratum E's LW, here as a theorem about the
transcribed RTL. SW is three loops: FETCH, STORE (address, `store_beat = 0`), STORE (data,
`store_beat = 1`).
-/

namespace SaltWorks.Silicon.Refine.Model
open SaltWorks.Silicon.Refine

/-- The bit facts and the decoded value of an LW. -/
theorem decode_lw (iw : W) (d : Dec) (hd : decode iw = some d) (ho : d.op = .lw) :
    iw.extractLsb' 0 7 = 3#7 ∧ iw.extractLsb' 12 3 = 2#3 ∧
    d = ⟨.lw, iw.extractLsb' 7 5, iw.extractLsb' 15 5, iw.extractLsb' 20 5, immI iw⟩ := by
  unfold decode at hd; dsimp only at hd
  simp only [ite_eq_iff, Option.some.injEq, reduceCtorEq, and_false, false_or, or_false,
    and_or_left] at hd
  repeat' (obtain hd | hd := hd)
  all_goals (repeat' (obtain ⟨_, hd⟩ := hd))
  all_goals (try subst hd)
  all_goals (first | (exact ⟨by assumption, by assumption, rfl⟩) | (simp at ho))

/-- The bit facts and the decoded value of an SW. -/
theorem decode_sw (iw : W) (d : Dec) (hd : decode iw = some d) (ho : d.op = .sw) :
    iw.extractLsb' 0 7 = 35#7 ∧ iw.extractLsb' 12 3 = 2#3 ∧
    d = ⟨.sw, iw.extractLsb' 7 5, iw.extractLsb' 15 5, iw.extractLsb' 20 5, immS iw⟩ := by
  unfold decode at hd; dsimp only at hd
  simp only [ite_eq_iff, Option.some.injEq, reduceCtorEq, and_false, false_or, or_false,
    and_or_left] at hd
  repeat' (obtain hd | hd := hd)
  all_goals (repeat' (obtain ⟨_, hd⟩ := hd))
  all_goals (try subst hd)
  all_goals (first | (exact ⟨by assumption, by assumption, rfl⟩) | (simp at ho))

set_option hygiene false in
/-- The transcribed RTL, evaluated under the hypotheses in context. -/
macro "coresimp" : tactic => `(tactic| simp [step, n_pc, n_phase, n_kind, n_storeBeat, n_rdataR, n_instrR, acc32, retire, pc_next, rf_we, wb_val,
    alu_y, alu_op, br_taken, rf1, rf2, b_op, sh, alu_src, imm, imm_i, imm_s, imm_b, imm_u, imm_j,
    dmem_req, dmem_we, dmem_addr, dmem_wdata, is_load_w, is_store_w, is_load, is_store, is_word, is_jal,
    is_jalr, is_lui, is_auipc, is_br, is_immop, is_regop, reg_we, opcode, funct3, f7, rs1, rs2, rd,
    instr, c_instr, loop_end, lowRst, rstn, sof, pc_q, pc_plus_4, pc_plus_imm, ld_out, phase, kind,
    storeBeat, pin, inAcc, stale_decode, instr_avail, mem_retire_now, out_word, imem_addr, eqk, k,
    anyOf, and1, or1, not1, T_FETCH, T_LOAD, T_STORE, Ex.eval, Sig.eval, Arch.set, Arch.get, immI,
    immS, shamt, *, -ite_not])

set_option hygiene false in
/-- `coresimp` that leaves `c_instr` and `acc32` folded, for hypotheses stated over them. -/
macro "coresimp'" : tactic => `(tactic| simp [step, n_pc, n_phase, n_kind, n_storeBeat, n_rdataR, n_instrR, retire, pc_next, rf_we, wb_val,
    alu_y, alu_op, br_taken, rf1, rf2, b_op, sh, alu_src, imm, imm_i, imm_s, imm_b, imm_u, imm_j,
    dmem_req, dmem_we, dmem_addr, dmem_wdata, is_load_w, is_store_w, is_load, is_store, is_word, is_jal,
    is_jalr, is_lui, is_auipc, is_br, is_immop, is_regop, reg_we, opcode, funct3, f7, rs1, rs2, rd,
    instr, loop_end, lowRst, rstn, sof, pc_q, pc_plus_4, pc_plus_imm, ld_out, phase, kind,
    storeBeat, stale_decode, instr_avail, mem_retire_now, out_word, imem_addr, eqk, k,
    anyOf, and1, or1, not1, T_FETCH, T_LOAD, T_STORE, Ex.eval, Sig.eval, Arch.set, Arch.get, immI,
    immS, shamt, *, -ite_not])

/-- At FETCH phase 3 the core decodes exactly the word the next `instr_r` latches. -/
theorem acc32_fetch3 (σ : St) (b : BitVec 8) (hp : σ.phase = 3#2) (hk : σ.kind = 1#2) :
    acc32.eval σ (run b) = c_instr.eval σ (run b) := by
  coresimp

/-- Outside FETCH phase 3 the core decodes `instr_r`. -/
theorem c_instr_held (σ : St) (b : BitVec 8) (hk : σ.kind ≠ 1#2) :
    c_instr.eval σ (run b) = σ.instrR := by
  coresimp

/-- FETCH phase 3 of an LW: no retirement; the next loop is a LOAD and `instr_r` holds the word. -/
theorem fetch3_lw (σ : St) (b : BitVec 8) (iw : W) (hp : σ.phase = 3#2) (hk : σ.kind = 1#2)
    (hi : c_instr.eval σ (run b) = iw) (h1 : iw.extractLsb' 0 7 = 3#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    (step σ (run b)).pc = σ.pc ∧ (step σ (run b)).regs = σ.regs ∧ (step σ (run b)).phase = 0#2 ∧
    (step σ (run b)).kind = 2#2 ∧ (step σ (run b)).storeBeat = 0#1 ∧
    (step σ (run b)).instrR = iw ∧ (step σ (run b)).rdataR = σ.rdataR := by
  have hacc : acc32.eval σ (run b) = iw := by rw [acc32_fetch3 σ b hp hk, hi]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> (try funext j) <;> coresimp'

/-- FETCH phase 3 of an SW: no retirement; the next loop is a STORE (address beat). -/
theorem fetch3_sw (σ : St) (b : BitVec 8) (iw : W) (hp : σ.phase = 3#2) (hk : σ.kind = 1#2)
    (hi : c_instr.eval σ (run b) = iw) (h1 : iw.extractLsb' 0 7 = 35#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    (step σ (run b)).pc = σ.pc ∧ (step σ (run b)).regs = σ.regs ∧ (step σ (run b)).phase = 0#2 ∧
    (step σ (run b)).kind = 3#2 ∧ (step σ (run b)).storeBeat = 0#1 ∧
    (step σ (run b)).instrR = iw ∧ (step σ (run b)).rdataR = σ.rdataR := by
  have hacc : acc32.eval σ (run b) = iw := by rw [acc32_fetch3 σ b hp hk, hi]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> (try funext j) <;> coresimp'

/-- LOAD phase 3: retire. `rd` takes the OLD `rdata_r` (erratum E's LW) on the edge that refills it. -/
theorem load3 (σ : St) (b : BitVec 8) (iw : W) (hp : σ.phase = 3#2) (hk : σ.kind = 2#2)
    (hir : σ.instrR = iw) (h1 : iw.extractLsb' 0 7 = 3#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    (step σ (run b)).pc = σ.pc + 4 ∧
    (step σ (run b)).regs = (Arch.set ⟨σ.pc, σ.regs⟩ (iw.extractLsb' 7 5) σ.rdataR).x ∧
    (step σ (run b)).phase = 0#2 ∧ (step σ (run b)).kind = 1#2 ∧ (step σ (run b)).storeBeat = 0#1 ∧
    (step σ (run b)).rdataR = acc32.eval σ (run b) := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  all_goals (try (by_cases hz : BitVec.extractLsb' 7 5 iw = 0#5))
  all_goals (try funext j)
  all_goals coresimp

/-- STORE phase 3, address beat: no retirement; the data beat follows. -/
theorem store3a (σ : St) (b : BitVec 8) (iw : W) (hp : σ.phase = 3#2) (hk : σ.kind = 3#2)
    (hsb : σ.storeBeat = 0#1) (hir : σ.instrR = iw) (h1 : iw.extractLsb' 0 7 = 35#7)
    (h2 : iw.extractLsb' 12 3 = 2#3) :
    (step σ (run b)).pc = σ.pc ∧ (step σ (run b)).regs = σ.regs ∧ (step σ (run b)).phase = 0#2 ∧
    (step σ (run b)).kind = 3#2 ∧ (step σ (run b)).storeBeat = 1#1 ∧
    (step σ (run b)).instrR = σ.instrR ∧ (step σ (run b)).rdataR = σ.rdataR := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> (try funext j) <;> coresimp

/-- STORE phase 3, data beat: retire; nothing architectural but `pc` moves. -/
theorem store3d (σ : St) (b : BitVec 8) (iw : W) (hp : σ.phase = 3#2) (hk : σ.kind = 3#2)
    (hsb : σ.storeBeat = 1#1) (hir : σ.instrR = iw) (h1 : iw.extractLsb' 0 7 = 35#7)
    (h2 : iw.extractLsb' 12 3 = 2#3) :
    (step σ (run b)).pc = σ.pc + 4 ∧ (step σ (run b)).regs = σ.regs ∧ (step σ (run b)).phase = 0#2 ∧
    (step σ (run b)).kind = 1#2 ∧ (step σ (run b)).storeBeat = 0#1 ∧
    (step σ (run b)).rdataR = σ.rdataR := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> (try funext j) <;> coresimp

/-! ## What the pins carry in each loop -/

theorem out_fetch (σ : St) (x : In) (hk : σ.kind = 1#2) :
    out_word.eval σ x = (σ.pc.extractLsb' 2 30 ++ 0#2).setWidth 32 := by
  coresimp

theorem out_load (σ : St) (b : BitVec 8) (iw : W) (hk : σ.kind = 2#2) (hir : σ.instrR = iw)
    (h1 : iw.extractLsb' 0 7 = 3#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    out_word.eval σ (run b) = Arch.get ⟨σ.pc, σ.regs⟩ (iw.extractLsb' 15 5) + immI iw := by
  coresimp

theorem out_storeA (σ : St) (b : BitVec 8) (iw : W) (hk : σ.kind = 3#2) (hsb : σ.storeBeat = 0#1)
    (hir : σ.instrR = iw) (h1 : iw.extractLsb' 0 7 = 35#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    out_word.eval σ (run b) = Arch.get ⟨σ.pc, σ.regs⟩ (iw.extractLsb' 15 5) + immS iw := by
  coresimp

theorem out_storeD (σ : St) (b : BitVec 8) (iw : W) (hk : σ.kind = 3#2) (hsb : σ.storeBeat = 1#1)
    (hir : σ.instrR = iw) (h1 : iw.extractLsb' 0 7 = 35#7) (h2 : iw.extractLsb' 12 3 = 2#3) :
    out_word.eval σ (run b) = Arch.get ⟨σ.pc, σ.regs⟩ (iw.extractLsb' 20 5) := by
  coresimp

end SaltWorks.Silicon.Refine.Model
