/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Run

/-!
# AAU W4 — one instruction, every class

`inst_step` covers one in-scope instruction (`stepH` succeeds), starting from the boundary invariant
`Inv`. It shows the pins over the instruction's 4, 8 or 12 cycles are exactly `Loop.emit` of the
loops `exec true` predicts, and that `Inv` holds again at its end with the new spec state.
-/

namespace SaltWorks.Silicon.Refine
open SaltWorks.Silicon.Refine.Model

theorem aligned_add4 (p : W) (h : p.extractLsb' 0 2 = 0#2) : (p + 4#32).extractLsb' 0 2 = 0#2 := by
  have := congrArg BitVec.toNat h
  apply BitVec.eq_of_toNat_eq
  simp [BitVec.extractLsb'_toNat, BitVec.toNat_add] at this ⊢
  omega

theorem exec_facts (e : Bool) (s s' : EState) (d : Dec) (lw : W) (ls : List Loop)
    (hal : s.arch.pc.extractLsb' 0 2 = 0#2) (hx : exec e s d lw = some (s', ls)) :
    s'.arch.pc.extractLsb' 0 2 = 0#2 ∧
    ((d.op ≠ .lw ∧ d.op ≠ .sw ∧ ls = [⟨.fetch, s.arch.pc⟩] ∧ s'.lastLoad = s.lastLoad) ∨
     (d.op = .lw ∧ (s.arch.get d.rs1 + d.imm).extractLsb' 0 2 = 0#2 ∧
        ls = [⟨.fetch, s.arch.pc⟩, ⟨.load, s.arch.get d.rs1 + d.imm⟩] ∧
        s' = ⟨{ s.arch.set d.rd (if e then s.lastLoad else lw) with pc := s.arch.pc + 4 }, lw⟩) ∨
     (d.op = .sw ∧ (s.arch.get d.rs1 + d.imm).extractLsb' 0 2 = 0#2 ∧
        ls = [⟨.fetch, s.arch.pc⟩, ⟨.store, s.arch.get d.rs1 + d.imm⟩, ⟨.store, s.arch.get d.rs2⟩] ∧
        s' = { s with arch := { s.arch with pc := s.arch.pc + 4 } })) := by
  obtain ⟨op, rd, rs1, rs2, imm⟩ := d
  cases op <;> simp only [exec, jumpTo] at hx <;> (repeat' (split at hx)) <;>
    (try simp only [reduceCtorEq, Option.map_some, Option.map_none] at hx) <;>
    (try simp only [Option.some.injEq, Prod.mk.injEq] at hx) <;>
    (try obtain ⟨rfl, rfl⟩ := hx) <;>
    simp_all [Arch.set, aligned_add4]

theorem aligned_id (p : W) (h : p.extractLsb' 0 2 = 0#2) : (p.extractLsb' 2 30 ++ 0#2).setWidth 32 = p := by
  apply BitVec.eq_of_getLsbD_eq; intro i hi
  simp only [BitVec.getLsbD_setWidth, BitVec.getLsbD_append, BitVec.getLsbD_extractLsb']
  by_cases h2 : i < 2
  · have := congrArg (fun v => v.getLsbD i) h
    simp only [BitVec.getLsbD_extractLsb', BitVec.getLsbD_zero] at this
    simp [h2, hi] at this ⊢; exact this
  · simp [h2, hi, show i - 2 < 30 by omega, show 2 + (i - 2) = i by omega]

theorem emit_len (l : Loop) : (Loop.emit l).length = 4 := rfl

theorem acc32_word (σ : St) (b : BitVec 8) :
    acc32.eval σ (run b) = (b ++ σ.inAcc.extractLsb' 0 24).setWidth 32 := by
  simp [acc32, pin, inAcc, Ex.eval, Sig.eval]

theorem inst_step (σ : St) (s : EState) (h : Nat → BitVec 8) (c : Nat) (hinv : Inv σ s)
    (s' : EState) (c' : Nat) (ls : List Loop) (hst : stepH true h s c = some (s', c', ls)) :
    c' = c + 4 * ls.length ∧ Inv (runFrom σ h c (4 * ls.length)) s' ∧
    ∀ i, i < 4 * ls.length →
      (ls.flatMap Loop.emit)[i]? = some (core32bus.out (runFrom σ h c i) (h (c + i))) := by
  obtain ⟨hp, hk, hsb, hpc, hrg, hrd, hal⟩ := hinv
  cases hd : decode (hostWord h c) with
  | none => simp [stepH, hd] at hst
  | some d =>
  cases hx : exec true s d (hostWord h (c + 4)) with
  | none => simp [stepH, hd, hx] at hst
  | some r =>
  obtain ⟨s'', ls'⟩ := r
  simp only [stepH, hd, hx, bind, Option.bind, pure, Option.some.injEq, Prod.mk.injEq] at hst
  obtain ⟨rfl, rfl, rfl⟩ := hst
  refine ⟨rfl, ?_⟩
  -- the fetch loop's first three cycles
  obtain ⟨p3, a3, pc3, rg3, k3, sb3, ir3, rd3⟩ := low3 σ h c hp
  have hiw : c_instr.eval (runFrom σ h c 3) (run (h (c + 3))) = hostWord h c := by
    rw [← acc32_fetch3 _ _ p3 (by rw [k3, hk]), acc32_word, a3, assemble_hostWord]
  have h4 : runFrom σ h c 4 = step (runFrom σ h c 3) (run (h (c + 3))) := runFrom_succ _ _ _ 3
  have hwF : ∀ σ' : St, σ'.pc = σ.pc → σ'.regs = σ.regs → σ'.kind = σ.kind →
      σ'.storeBeat = σ.storeBeat → σ'.instrR = σ.instrR → ∀ b,
      out_word.eval σ' (run b) = s.arch.pc := by
    intro σ' e1 _ e3 _ _ b; rw [out_fetch _ _ (by rw [e3, hk]), e1, hpc, aligned_id _ hal]
  have pinsF := loop_pins σ h c .fetch s.arch.pc hp (by rw [hk]; rfl) hwF
  obtain ⟨hal', hcls⟩ := exec_facts true s s'' d (hostWord h (c + 4)) ls' hal hx
  rcases hcls with ⟨_, _, rfl, hll⟩ | ⟨hop, haddr, rfl, rfl⟩ | ⟨hop, haddr, rfl, rfl⟩
  · -- one loop: every non-memory instruction
    obtain ⟨f1, f2, f3, f4, f5, f6, f7⟩ := fetch3_nonmem (runFrom σ h c 3) (h (c + 3)) s s'' d
      (hostWord h (c + 4)) p3 (by rw [k3, hk]) (by rw [pc3, hpc]) (by rw [rg3, hrg]) (by rw [hiw]; exact hd) hx
    refine ⟨⟨?_, ?_, ?_, ?_, ?_, ?_, hal'⟩, ?_⟩
    all_goals (try simp only [List.length_singleton, Nat.mul_one, h4])
    · exact f3
    · exact f4
    · exact f5
    · exact f1
    · exact f2
    · rw [f6, rd3, hrd, f7]
    · intro i hi; simpa [List.flatMap_cons, List.flatMap_nil] using pinsF i hi
  · -- LW: FETCH, then LOAD
    obtain ⟨l1, l2, hdl⟩ := decode_lw _ d hd hop
    subst hdl
    obtain ⟨g1, g2, g3, g4, g5, g6, g7⟩ :=
      fetch3_lw (runFrom σ h c 3) (h (c + 3)) (hostWord h c) p3 (by rw [k3, hk]) hiw l1 l2
    rw [← h4] at g1 g2 g3 g4 g5 g6 g7
    obtain ⟨q3, qa3, qpc, qrg, qk, qsb, qir, qrd⟩ := low3 (runFrom σ h c 4) h (c + 4) g3
    obtain ⟨m1, m2, m3, m4, m5, m6⟩ := load3 (runFrom (runFrom σ h c 4) h (c + 4) 3) (h (c + 4 + 3))
      (hostWord h c) q3 (by rw [qk, g4]) (by rw [qir, g6]) l1 l2
    have h8 : runFrom σ h c (4 * 2) =
        step (runFrom (runFrom σ h c 4) h (c + 4) 3) (run (h (c + 4 + 3))) := by
      rw [show 4 * 2 = 4 + 4 from rfl, runFrom_add, runFrom_succ]
    have harch : (⟨(runFrom (runFrom σ h c 4) h (c + 4) 3).pc,
        (runFrom (runFrom σ h c 4) h (c + 4) 3).regs⟩ : Arch) = s.arch := by
      rw [qpc, qrg, g1, g2, pc3, rg3, hpc, hrg]
    have hw4 : ∀ σ' : St, σ'.pc = (runFrom σ h c 4).pc → σ'.regs = (runFrom σ h c 4).regs →
        σ'.kind = (runFrom σ h c 4).kind → σ'.storeBeat = (runFrom σ h c 4).storeBeat →
        σ'.instrR = (runFrom σ h c 4).instrR → ∀ b,
        out_word.eval σ' (run b) = s.arch.get ((hostWord h c).extractLsb' 15 5) + immI (hostWord h c) := by
      intro σ' e1 e2 e3 _ e5 b
      rw [out_load σ' b (hostWord h c) (by rw [e3, g4]) (by rw [e5, g6]) l1 l2, e1, e2, g1, g2, pc3,
        rg3, hpc, hrg]
    have pinsL := loop_pins (runFrom σ h c 4) h (c + 4) .load _ g3 (by rw [g4]; rfl) hw4
    refine ⟨⟨?_, ?_, ?_, ?_, ?_, ?_, hal'⟩, ?_⟩
    all_goals (try simp only [List.length_cons, List.length_nil, h8])
    · exact m3
    · exact m4
    · exact m5
    · rw [m1, qpc, g1, pc3, hpc]
    · rw [m2, harch, qrd, g7, rd3, hrd]; rfl
    · rw [m6, acc32_word, qa3, show c + 4 + 3 = (c + 4) + 3 from rfl, assemble_hostWord]
    · intro i hi
      simp only [List.flatMap_cons, List.flatMap_nil, List.append_nil]
      by_cases hi4 : i < 4
      · rw [List.getElem?_append_left (by simp [emit_len, hi4])]; exact pinsF i hi4
      · rw [List.getElem?_append_right (by simp [emit_len]; omega), emit_len]
        have e := pinsL (i - 4) (by simp at hi; omega)
        rw [← runFrom_add, show 4 + (i - 4) = i by omega, show c + 4 + (i - 4) = c + i by omega] at e
        exact e
  · -- SW: FETCH, STORE (address), STORE (data)
    obtain ⟨l1, l2, hdl⟩ := decode_sw _ d hd hop
    subst hdl
    obtain ⟨g1, g2, g3, g4, g5, g6, g7⟩ :=
      fetch3_sw (runFrom σ h c 3) (h (c + 3)) (hostWord h c) p3 (by rw [k3, hk]) hiw l1 l2
    rw [← h4] at g1 g2 g3 g4 g5 g6 g7
    -- address loop
    obtain ⟨q3, -, qpc, qrg, qk, qsb, qir, qrd⟩ := low3 (runFrom σ h c 4) h (c + 4) g3
    obtain ⟨a1, a2, a3, a4, a5, a6, a7⟩ := store3a (runFrom (runFrom σ h c 4) h (c + 4) 3)
      (h (c + 4 + 3)) (hostWord h c) q3 (by rw [qk, g4]) (by rw [qsb, g5]) (by rw [qir, g6]) l1 l2
    have h8 : runFrom σ h c 8 = step (runFrom (runFrom σ h c 4) h (c + 4) 3) (run (h (c + 4 + 3))) := by
      rw [show 8 = 4 + 4 from rfl, runFrom_add, runFrom_succ]
    rw [← h8] at a1 a2 a3 a4 a5 a6 a7
    -- data loop
    obtain ⟨r3, -, rpc, rrg, rk, rsb, rir, rrd⟩ := low3 (runFrom σ h c 8) h (c + 8) a3
    obtain ⟨d1, d2, d3, d4, d5, d6⟩ := store3d (runFrom (runFrom σ h c 8) h (c + 8) 3)
      (h (c + 8 + 3)) (hostWord h c) r3 (by rw [rk, a4]) (by rw [rsb, a5])
      (by rw [rir, a6, qir, g6]) l1 l2
    have h12 : runFrom σ h c (4 * 3) =
        step (runFrom (runFrom σ h c 8) h (c + 8) 3) (run (h (c + 8 + 3))) := by
      rw [show 4 * 3 = 8 + 4 from rfl, runFrom_add, runFrom_succ]
    have hw4 : ∀ σ' : St, σ'.pc = (runFrom σ h c 4).pc → σ'.regs = (runFrom σ h c 4).regs →
        σ'.kind = (runFrom σ h c 4).kind → σ'.storeBeat = (runFrom σ h c 4).storeBeat →
        σ'.instrR = (runFrom σ h c 4).instrR → ∀ b,
        out_word.eval σ' (run b) = s.arch.get ((hostWord h c).extractLsb' 15 5) + immS (hostWord h c) := by
      intro σ' e1 e2 e3 e4 e5 b
      rw [out_storeA σ' b (hostWord h c) (by rw [e3, g4]) (by rw [e4, g5]) (by rw [e5, g6]) l1 l2, e1, e2,
        g1, g2, pc3, rg3, hpc, hrg]
    have hw8 : ∀ σ' : St, σ'.pc = (runFrom σ h c 8).pc → σ'.regs = (runFrom σ h c 8).regs →
        σ'.kind = (runFrom σ h c 8).kind → σ'.storeBeat = (runFrom σ h c 8).storeBeat →
        σ'.instrR = (runFrom σ h c 8).instrR → ∀ b,
        out_word.eval σ' (run b) = s.arch.get ((hostWord h c).extractLsb' 20 5) := by
      intro σ' e1 e2 e3 e4 e5 b
      rw [out_storeD σ' b (hostWord h c) (by rw [e3, a4]) (by rw [e4, a5]) (by rw [e5, a6, qir, g6]) l1 l2,
        e1, e2, a1, a2, qpc, qrg, g1, g2, pc3, rg3, hpc, hrg]
    have pinsA := loop_pins (runFrom σ h c 4) h (c + 4) .store _ g3 (by rw [g4]; rfl) hw4
    have pinsD := loop_pins (runFrom σ h c 8) h (c + 8) .store _ a3 (by rw [a4]; rfl) hw8
    refine ⟨⟨?_, ?_, ?_, ?_, ?_, ?_, hal'⟩, ?_⟩
    all_goals (try simp only [List.length_cons, List.length_nil, h12])
    · exact d3
    · exact d4
    · exact d5
    · rw [d1, rpc, a1, qpc, g1, pc3, hpc]
    · rw [d2, rrg, a2, qrg, g2, rg3, hrg]
    · rw [d6, rrd, a7, qrd, g7, rd3, hrd]
    · intro i hi
      simp only [List.flatMap_cons, List.flatMap_nil, List.append_nil]
      by_cases hi4 : i < 4
      · rw [List.getElem?_append_left (by simp [emit_len, hi4])]; exact pinsF i hi4
      · rw [List.getElem?_append_right (by simp [emit_len]; omega), emit_len]
        by_cases hi8 : i < 8
        · rw [List.getElem?_append_left (by simp [emit_len]; omega)]
          have e := pinsA (i - 4) (by omega)
          rw [← runFrom_add, show 4 + (i - 4) = i by omega, show c + 4 + (i - 4) = c + i by omega] at e
          exact e
        · rw [List.getElem?_append_right (by simp [emit_len]; omega), emit_len]
          have e := pinsD (i - 4 - 4) (by simp at hi; omega)
          rw [← runFrom_add, show 8 + (i - 4 - 4) = i by omega,
            show c + 8 + (i - 4 - 4) = c + i by omega] at e
          exact e


end SaltWorks.Silicon.Refine
