/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Loop
import Mathlib.Logic.Basic

/-!
# AAU W4 — phase 3 of a FETCH loop, for every non-memory instruction

`fetch3_nonmem`: at FETCH phase 3, the word being completed decodes to a non-memory instruction
(`exec` makes exactly one loop). One clock edge then lands the core in the state `exec true`
predicts, and the next loop is a FETCH at phase 0. A single proof covers all 29 such instructions.
It walks `decode`'s if-chain (`ite_eq_iff`, distributed) and evaluates the transcribed RTL under
each branch's bit facts. No `bv_decide`, no `native_decide`.
-/

namespace SaltWorks.Silicon.Refine.Model
open SaltWorks.Silicon.Refine

@[simp] theorem b1_ite_eq_one (p : Prop) [Decidable p] : ((if p then 1#1 else 0#1) = 1#1) ↔ p := by
  by_cases h : p <;> simp [h]
@[simp] theorem b1_and (p q : Prop) [Decidable p] [Decidable q] :
    ((if p then 1#1 else 0#1) &&& (if q then 1#1 else 0#1)) = if p ∧ q then 1#1 else 0#1 := by
  by_cases h : p <;> by_cases h' : q <;> simp [h, h']
@[simp] theorem b1_or (p q : Prop) [Decidable p] [Decidable q] :
    ((if p then 1#1 else 0#1) ||| (if q then 1#1 else 0#1)) = if p ∨ q then 1#1 else 0#1 := by
  by_cases h : p <;> by_cases h' : q <;> simp [h, h']
@[simp] theorem b1_not (p : Prop) [Decidable p] :
    (~~~(if p then 1#1 else 0#1)) = if ¬p then 1#1 else 0#1 := by
  by_cases h : p <;> simp [h]

@[simp] theorem b1_one_and (x : BitVec 1) : 1#1 &&& x = x := by
  rcases (by decide : ∀ y : BitVec 1, y = 0#1 ∨ y = 1#1) x with h | h <;> subst h <;> decide
@[simp] theorem b1_and_one (x : BitVec 1) : x &&& 1#1 = x := by
  rcases (by decide : ∀ y : BitVec 1, y = 0#1 ∨ y = 1#1) x with h | h <;> subst h <;> decide

@[simp] theorem b1_setWidth (p : Prop) [Decidable p] :
    (if p then 1#1 else 0#1).setWidth 32 = if p then 1#32 else 0#32 := by
  by_cases h : p <;> simp [h]

theorem bv3_five (x : BitVec 3) (h0 : ¬x = 0#3) (h1 : ¬x = 1#3) (h2 : ¬x = 2#3) (h3 : ¬x = 3#3)
    (h4 : ¬x = 4#3) (h6 : ¬x = 6#3) (h7 : ¬x = 7#3) : x = 5#3 := by
  have hl := x.isLt
  simp only [BitVec.toNat_eq, BitVec.toNat_ofNat] at *
  omega

theorem bv3_seven (x : BitVec 3) (h0 : ¬x = 0#3) (h1 : ¬x = 1#3) (h2 : ¬x = 2#3) (h3 : ¬x = 3#3)
    (h4 : ¬x = 4#3) (h5 : ¬x = 5#3) (h6 : ¬x = 6#3) : x = 7#3 := by
  have hl := x.isLt
  simp only [BitVec.toNat_eq, BitVec.toNat_ofNat] at *
  omega

@[simp] theorem not_one_32 : (~~~1#32 : BitVec 32) = 4294967294#32 := by decide

theorem ext30 (iw : W) : iw.extractLsb' 30 1 = (iw.extractLsb' 25 7).extractLsb' 5 1 := by
  apply BitVec.eq_of_toNat_eq
  simp [BitVec.extractLsb'_toNat, Nat.shiftRight_eq_div_pow]
  omega

set_option maxHeartbeats 8000000 in
theorem fetch3_nonmem (σ : St) (b : BitVec 8) (s s' : EState) (d : Dec) (lw : W)
    (hp : σ.phase = 3#2) (hk : σ.kind = 1#2) (hpc : σ.pc = s.arch.pc) (hrg : σ.regs = s.arch.x)
    (hd : decode (c_instr.eval σ (run b)) = some d)
    (hx : exec true s d lw = some (s', [⟨.fetch, s.arch.pc⟩])) :
    (step σ (run b)).pc = s'.arch.pc ∧ (step σ (run b)).regs = s'.arch.x ∧
    (step σ (run b)).phase = 0#2 ∧ (step σ (run b)).kind = 1#2 ∧ (step σ (run b)).storeBeat = 0#1 ∧
    (step σ (run b)).rdataR = σ.rdataR ∧ s'.lastLoad = s.lastLoad := by
  generalize hi : c_instr.eval σ (run b) = iw at hd
  unfold decode at hd; dsimp only at hd
  simp only [ite_eq_iff, Option.some.injEq, reduceCtorEq, and_false, false_or, or_false, and_or_left] at hd
  repeat' (obtain hd | hd := hd)
  all_goals (repeat' (obtain ⟨_, hd⟩ := hd))
  all_goals (try subst hd)
  all_goals (have h30 := ext30 iw)
  all_goals (simp only [exec, jumpTo] at hx)
  all_goals (repeat' (split at hx))
  all_goals (try (simp only [reduceCtorEq, Option.map_some, Option.map_none] at hx))
  all_goals (try (simp only [Option.some.injEq, Prod.mk.injEq, List.cons.injEq, Loop.mk.injEq, reduceCtorEq] at hx))
  all_goals (first
    | exact hx.2.2.elim
    | (obtain ⟨rfl, -⟩ := hx
       try (have h5 := bv3_five (BitVec.extractLsb' 12 3 iw) (by assumption) (by assumption)
              (by assumption) (by assumption) (by assumption) (by assumption) (by assumption))
       try (have h7 := bv3_seven (BitVec.extractLsb' 12 3 iw) (by assumption) (by assumption)
              (by assumption) (by assumption) (by assumption) (by assumption) (by assumption))
       simp [step, n_pc, n_phase, n_kind, n_storeBeat, n_rdataR, retire, pc_next, rf_we, wb_val, alu_y, alu_op,
        br_taken, rf1, rf2, b_op, sh, alu_src, imm, imm_i, imm_s, imm_b, imm_u, imm_j, dmem_req, dmem_we,
        is_load_w, is_store_w, is_load, is_store, is_word, is_jal, is_jalr, is_lui, is_auipc, is_br,
        is_immop, is_regop, reg_we, opcode, funct3, f7, rs1, rs2, rd, instr, loop_end, lowRst, rstn, sof,
        pc_q, pc_plus_4, pc_plus_imm, ld_out, phase, kind, storeBeat, stale_decode, instr_avail,
        mem_retire_now, eqk, k, anyOf, and1, or1, not1, T_FETCH, T_LOAD, T_STORE, Ex.eval, Sig.eval,
        Arch.set, Arch.get, immI, immS, immB, immU, immJ, shamt, *, -ite_not]
       try (by_cases hz : BitVec.extractLsb' 7 5 iw = 0#5 <;> simp [hz])
       try (simp_all [Arch.get, immI, immS, immB, immU, immJ, shamt, -ite_not])))
end SaltWorks.Silicon.Refine.Model
