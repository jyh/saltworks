/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Model

/-!
# AAU W3 — the bus loop: phases 0, 1, 2 and the pins they drive

In phases 0–2 of any loop, the only state that moves is `phase` (+1) and `in_acc` (one byte
lands). The pins carry byte `phase` of `out_word`. This file proves that once, for every loop
kind, so the per-instruction proofs only have to reason about phase 3.
-/

namespace SaltWorks.Silicon.Refine.Model
open SaltWorks.Silicon.Refine

/-- The inputs of a running cycle: `rst_n` high, `sof` low. -/
abbrev run (b : BitVec 8) : In := ⟨1, 0, b⟩

/-- `step` from `σ` over `n` cycles of host bytes starting at cycle `c`. -/
def runFrom (σ : St) (h : Nat → BitVec 8) (c : Nat) : Nat → St
  | 0     => σ
  | n + 1 => step (runFrom σ h c n) (run (h (c + n)))

theorem run_add (r0 : BitVec 5 → W) (h : Nat → BitVec 8) (c n : Nat) :
    core32bus.run r0 h (c + n) = runFrom (core32bus.run r0 h c) h c n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [show c + (n + 1) = (c + n) + 1 from rfl, runFrom, ← ih]; rfl

/-- One cycle in phase `p < 3`: `phase` advances, byte `p` of `in_acc` takes the host byte, and
every other flop holds. -/
theorem step_low (σ : St) (b : BitVec 8) (hp : σ.phase ≠ 3#2) :
    step σ (run b) =
      { σ with phase := σ.phase + 1,
               inAcc := (n_inAcc.eval σ (run b)) } := by
  have hr : retire.eval σ (run b) = 0 := by
    simp [retire, loop_end, phase, eqk, k, and1, Ex.eval, Sig.eval, hp]
  have hia : instr_avail.eval σ (run b) = 0 := by
    simp [instr_avail, phase, kind, eqk, k, and1, Ex.eval, Sig.eval, hp]
  have hmr : mem_retire_now.eval σ (run b) = 0 := by
    simp [mem_retire_now, loop_end, phase, eqk, k, and1, Ex.eval, Sig.eval, hp]
  simp only [step, St.mk.injEq]
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  all_goals first
    | rfl
    | (funext j; simp [rf_we, and1, not1, Ex.eval, hr])
    | simp [n_pc, n_phase, n_kind, n_storeBeat, n_fetchOwed, n_instrR, n_rdataR, lowRst, rstn,
        sof, pc_q, phase, kind, storeBeat, loop_end, eqk, k, and1, or1, not1, Ex.eval, Sig.eval, hp, hr,
        hia, hmr]

end SaltWorks.Silicon.Refine.Model
