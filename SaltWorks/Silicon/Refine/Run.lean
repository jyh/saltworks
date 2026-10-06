/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Mem

/-!
# AAU W4 — loops in time: `runFrom`, the assembled word, the boundary invariant, the pins per cycle
-/

namespace SaltWorks.Silicon.Refine.Model
open SaltWorks.Silicon.Refine

theorem acc_bytes (A : BitVec 32) (b0 b1 b2 : BitVec 8) :
    let a1 := (A.extractLsb' 8 24 ++ b0).setWidth 32
    let a2 := ((a1.extractLsb' 16 16 ++ b1) ++ a1.extractLsb' 0 8).setWidth 32
    let a3 := ((a2.extractLsb' 24 8 ++ b2) ++ a2.extractLsb' 0 16).setWidth 32
    a3.extractLsb' 0 24 = b2 ++ b1 ++ b0 := by
  intro a1 a2 a3
  apply BitVec.eq_of_getLsbD_eq; intro i hi
  simp only [a3, a2, a1, BitVec.getElem_extractLsb', BitVec.getElem_setWidth, BitVec.getLsbD_setWidth,
    BitVec.getElem_append, BitVec.getLsbD_append, BitVec.getLsbD_extractLsb']
  rcases (by omega : i < 8 ∨ (8 ≤ i ∧ i < 16) ∨ (16 ≤ i ∧ i < 24)) with h | ⟨h1, h2⟩ | ⟨h1, h2⟩
  · simp [h, hi, show i < 32 by omega, show i < 16 by omega]
  · simp [hi, h2, show i < 32 by omega, show ¬ i < 8 by omega, show i - 8 < 8 by omega]
  · simp [hi, show i < 32 by omega, show ¬ i < 8 by omega, show ¬ i < 16 by omega,
      show i - 16 < 8 by omega, show ¬ i - 8 < 8 by omega, show i - 8 - 8 = i - 16 by omega]

theorem runFrom_succ (σ : St) (h : Nat → BitVec 8) (c n : Nat) :
    runFrom σ h c (n + 1) = step (runFrom σ h c n) (run (h (c + n))) := rfl

/-- Three cycles of phases 0, 1, 2: the loop's first three host bytes land in `in_acc`. -/
theorem low3 (σ : St) (h : Nat → BitVec 8) (c : Nat) (hp : σ.phase = 0#2) :
    (runFrom σ h c 3).phase = 3#2 ∧
    (runFrom σ h c 3).inAcc.extractLsb' 0 24 = h (c + 2) ++ h (c + 1) ++ h c ∧
    (runFrom σ h c 3).pc = σ.pc ∧ (runFrom σ h c 3).regs = σ.regs ∧
    (runFrom σ h c 3).kind = σ.kind ∧ (runFrom σ h c 3).storeBeat = σ.storeBeat ∧
    (runFrom σ h c 3).instrR = σ.instrR ∧ (runFrom σ h c 3).rdataR = σ.rdataR := by
  have s1 := step_low σ (run (h c)).pin (by simp [hp])
  generalize hσ1 : step σ (run (h c)) = σ1 at s1
  have s2 := step_low σ1 (h (c + 1)) (by rw [s1]; simp [hp])
  generalize hσ2 : step σ1 (run (h (c + 1))) = σ2 at s2
  have s3 := step_low σ2 (h (c + 2)) (by rw [s2, s1]; simp [hp])
  generalize hσ3 : step σ2 (run (h (c + 2))) = σ3 at s3
  have hr : runFrom σ h c 3 = σ3 := by
    rw [← hσ3, ← hσ2, ← hσ1]; rfl
  rw [hr, s3, s2, s1]
  simp only [n_inAcc, lowRst, rstn, phase, inAcc, pin, eqk, k, not1, Ex.eval, Sig.eval, hp]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  all_goals (try trivial)
  all_goals (try decide)
  exact acc_bytes σ.inAcc (h c) (h (c + 1)) (h (c + 2))

/-- The four host bytes of a loop, assembled the way `busadapt8` does it, are `hostWord`. -/
theorem assemble_hostWord (h : Nat → BitVec 8) (c : Nat) :
    (h (c + 3) ++ (h (c + 2) ++ h (c + 1) ++ h c)).setWidth 32 = hostWord h c := by
  apply BitVec.eq_of_getLsbD_eq; intro i hi
  simp only [hostWord, BitVec.getLsbD_setWidth, BitVec.getLsbD_append]
  rcases (by omega : i < 8 ∨ (8 ≤ i ∧ i < 16) ∨ (16 ≤ i ∧ i < 24) ∨ (24 ≤ i ∧ i < 32)) with
    h0 | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩
  · simp [h0, hi, show i < 16 by omega, show i < 24 by omega]
  · simp [hi, h2, show i < 24 by omega, show ¬ i < 8 by omega, show i - 8 < 8 by omega]
  · simp [hi, show i < 24 by omega, show ¬ i < 8 by omega, show ¬ i < 16 by omega,
      show i - 16 < 8 by omega, show ¬ i - 8 < 8 by omega, show i - 8 - 8 = i - 16 by omega]
  · simp [hi, show ¬ i < 24 by omega, show ¬ i < 8 by omega, show ¬ i < 16 by omega,
      show ¬ i - 8 < 8 by omega, show ¬ i - 16 < 8 by omega, show i - 8 - 8 - 8 = i - 24 by omega,
      show i - 24 < 8 by omega, show ¬ i - 8 - 8 < 8 by omega]

/-- The invariant at every instruction boundary. `fetch_owed` and `in_acc` are free: the first
only matters when `sof` pulses, and the second is rewritten before it is read. -/
def Inv (σ : St) (s : EState) : Prop :=
  σ.phase = 0#2 ∧ σ.kind = 1#2 ∧ σ.storeBeat = 0#1 ∧ σ.pc = s.arch.pc ∧ σ.regs = s.arch.x ∧
  σ.rdataR = s.lastLoad ∧ s.arch.pc.extractLsb' 0 2 = 0#2

theorem inv_reset (r0 : BitVec 5 → W) : Inv (core32bus.reset r0) (EState.init r0) := by
  simp [Inv, core32bus, EState.init]

/-- The pins in one cycle: byte `phase` of `out_word`, and the TYPE in phase 0, the phase after. -/
theorem out_at (σ : St) (b : BitVec 8) :
    core32bus.out σ b = ((out_word.eval σ (run b)).extractLsb' (8 * σ.phase.toNat) 8,
                         if σ.phase = 0#2 then σ.kind else σ.phase) := by
  have hl := σ.phase.isLt
  rcases (by omega : σ.phase.toNat = 0 ∨ σ.phase.toNat = 1 ∨ σ.phase.toNat = 2 ∨ σ.phase.toNat = 3)
    with h | h | h | h
  all_goals
    have hp : σ.phase = BitVec.ofNat 2 σ.phase.toNat := by simp
    rw [h] at hp
    simp [core32bus, pin_out, phase_pins, phase, kind, eqk, k, Ex.eval, Sig.eval, hp, h]
    all_goals rfl

theorem runFrom_add (σ : St) (h : Nat → BitVec 8) (c m n : Nat) :
    runFrom σ h c (m + n) = runFrom (runFrom σ h c m) h (c + m) n := by
  induction n with
  | zero => rfl
  | succ n ih => rw [← Nat.add_assoc, runFrom_succ, runFrom_succ, ih, Nat.add_assoc]

/-- Phases 0..k of a loop, for k ≤ 3: only `phase` (and `in_acc`) move. -/
theorem lowk (σ : St) (h : Nat → BitVec 8) (c k : Nat) (hp : σ.phase = 0#2) (hk : k ≤ 3) :
    (runFrom σ h c k).phase = BitVec.ofNat 2 k ∧ (runFrom σ h c k).pc = σ.pc ∧
    (runFrom σ h c k).regs = σ.regs ∧ (runFrom σ h c k).kind = σ.kind ∧
    (runFrom σ h c k).storeBeat = σ.storeBeat ∧ (runFrom σ h c k).instrR = σ.instrR ∧
    (runFrom σ h c k).rdataR = σ.rdataR := by
  induction k with
  | zero => simp [runFrom, hp]
  | succ k ih =>
    obtain ⟨h1, h2, h3, h4, h5, h6, h7⟩ := ih (by omega)
    rw [runFrom_succ, step_low _ _ (by rw [h1]; intro e; have := congrArg BitVec.toNat e; simp at this; omega)]
    refine ⟨?_, h2, h3, h4, h5, h6, h7⟩
    rw [h1]; apply BitVec.eq_of_toNat_eq; simp

/-- A loop whose `out_word` is fixed by the frame (pc, regs, kind, store_beat, instr_r) drives
exactly `Loop.emit` on the pins over its four cycles. -/
theorem loop_pins (σ : St) (h : Nat → BitVec 8) (c : Nat) (K : Kind) (w : W)
    (hp : σ.phase = 0#2) (hk : σ.kind = K.code)
    (hw : ∀ σ' : St, σ'.pc = σ.pc → σ'.regs = σ.regs → σ'.kind = σ.kind →
      σ'.storeBeat = σ.storeBeat → σ'.instrR = σ.instrR → ∀ b, out_word.eval σ' (run b) = w) :
    ∀ i, i < 4 → (Loop.emit ⟨K, w⟩)[i]? = some (core32bus.out (runFrom σ h c i) (h (c + i))) := by
  intro i hi
  obtain ⟨h1, h2, h3, h4, h5, h6, -⟩ := lowk σ h c i hp (by omega)
  rw [out_at, hw _ h2 h3 h4 h5 h6, h1, h4, hk]
  rcases (by omega : i = 0 ∨ i = 1 ∨ i = 2 ∨ i = 3) with rfl | rfl | rfl | rfl <;> simp [Loop.emit]

end SaltWorks.Silicon.Refine.Model
