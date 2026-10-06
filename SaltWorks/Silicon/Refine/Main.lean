/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Inst

/-!
# AAU — THE THEOREM: the fabricated core refines RV32I with erratum E

`core32bus_refinesE : RefinesE core32bus`. The proposition is `Statement.lean`'s, unchanged. The
machine is `Model.lean`'s transcription of `plane32bus` at `jyh/tt-neural-dataflow-fabric@01e19f7`.
It is linked to that RTL by yosys SAT in `SaltWorks/Silicon/Formal/refine_link/run_link.sh`.

**THE CONTROL, in the kernel:** `core32bus_not_refinesRV32I : ¬ RefinesRV32I core32bus`. The same
proposition against plain RV32I is FALSE for this machine. Two instructions (ADDI, SRAI) separate
them, so the theorem above does say something about the erratum.
-/

namespace SaltWorks.Silicon.Refine
open SaltWorks.Silicon.Refine.Model

theorem flatMap_emit_len (ls : List Loop) : (ls.flatMap Loop.emit).length = 4 * ls.length := by
  induction ls with
  | nil => rfl
  | cons l ls ih => simp [List.flatMap_cons, emit_len, ih]; omega

theorem refines_k (r0 : BitVec 5 → W) (h : Nat → BitVec 8) (k : Nat) (s : EState) (c : Nat)
    (ls : List Loop) (hk : runSpec true h r0 k = some (s, c, ls)) :
    c = 4 * ls.length ∧ Inv (core32bus.run r0 h c) s ∧
    ∀ t, t < c → (ls.flatMap Loop.emit)[t]? = some (core32bus.out (core32bus.run r0 h t) (h t)) := by
  induction k generalizing s c ls with
  | zero =>
    simp only [runSpec, Option.some.injEq, Prod.mk.injEq] at hk
    obtain ⟨rfl, rfl, rfl⟩ := hk
    exact ⟨rfl, inv_reset r0, fun t ht => absurd ht (Nat.not_lt_zero t)⟩
  | succ k ih =>
    cases h0 : runSpec true h r0 k with
    | none => simp [runSpec, h0] at hk
    | some r =>
    obtain ⟨s0, c0, ls0⟩ := r
    cases h1 : stepH true h s0 c0 with
    | none => simp [runSpec, h0, h1] at hk
    | some q =>
    obtain ⟨s1, c1, ls1⟩ := q
    simp only [runSpec, h0, h1, bind, Option.bind, pure, Option.some.injEq, Prod.mk.injEq] at hk
    obtain ⟨rfl, rfl, rfl⟩ := hk
    obtain ⟨e0, inv0, pins0⟩ := ih s0 c0 ls0 h0
    obtain ⟨e1, inv1, pins1⟩ := inst_step _ s0 h c0 inv0 s1 c1 ls1 h1
    refine ⟨by rw [e1, e0, List.length_append]; omega, ?_, ?_⟩
    · rw [e1, Model.run_add]; exact inv1
    · intro t ht
      rw [List.flatMap_append]
      by_cases htc : t < c0
      · rw [List.getElem?_append_left (by rw [flatMap_emit_len]; omega)]; exact pins0 t htc
      · rw [List.getElem?_append_right (by rw [flatMap_emit_len]; omega), flatMap_emit_len, ← e0]
        have e := pins1 (t - c0) (by omega)
        rw [← Model.run_add, show c0 + (t - c0) = t by omega] at e
        exact e

/-- **THE THEOREM.** The fabricated `core32` + `busadapt8` (as transcribed in `Model.lean`, and
linked to the 01e19f7 RTL by `run_link.sh`) refines RV32I with erratum E. -/
theorem core32bus_refinesE : RefinesE core32bus := by
  intro r0 h k s c ls hk
  obtain ⟨-, ⟨-, -, -, hpc, hrg, -, -⟩, pins⟩ := refines_k r0 h k s c ls hk
  refine ⟨pins, hpc, fun r => ?_⟩
  unfold Arch.get; split
  · rfl
  · exact congrFun hrg r


/-- The control program: `ADDI x1,x0,-8` then `SRAI x2,x1,1`. -/
def ctlWords : List W := [0xFF800093#32, 0x4010D113#32]
def ctlHost (c : Nat) : BitVec 8 := ((ctlWords.getD (c / 4) 0) >>> (8 * (c % 4))).setWidth 8
def ctlR0 : BitVec 5 → W := fun _ => 0

/-- The model, run 8 cycles: `x2` after SRAI is the LOGICAL shift. -/
theorem core_x2 : (core32bus.arch (core32bus.run ctlR0 ctlHost 8)).get 2 = 0x7FFFFFFC#32 := by decide
/-- Plain RV32I says arithmetic. -/
theorem spec_x2 : (runSpec false ctlHost ctlR0 2).map (fun (s, c, _) => (s.arch.get 2, c)) =
    some (0xFFFFFFFC#32, 8) := by decide

theorem core32bus_not_refinesRV32I : ¬ RefinesRV32I core32bus := by
  intro H
  have hs := spec_x2
  rcases hr : runSpec false ctlHost ctlR0 2 with _ | ⟨s, c, ls⟩
  · rw [hr] at hs; simp at hs
  · rw [hr] at hs
    simp only [Option.map_some, Option.some.injEq, Prod.mk.injEq] at hs
    obtain ⟨hs2, rfl⟩ := hs
    have hx := (H ctlR0 ctlHost 2 s 8 ls hr).2.2 2
    rw [core_x2, hs2] at hx
    exact absurd hx (by decide)

/-- The reset convention is the RTL's: from ANY state, an edge with `rst_n` low (any `sof`, any
`ui_in`) lands in `core32bus.reset` of whatever the register file then holds. The register file is
the one flop with no reset, and `RefinesE` quantifies over it. -/
theorem reset_edge (σ : St) (sof : BitVec 1) (b : BitVec 8) :
    step σ ⟨0#1, sof, b⟩ = core32bus.reset (step σ ⟨0#1, sof, b⟩).regs := by
  simp [step, core32bus, n_pc, n_phase, n_kind, n_storeBeat, n_fetchOwed, n_inAcc, n_instrR, n_rdataR,
    lowRst, rstn, not1, k, Ex.eval, Sig.eval, T_FETCH]

end SaltWorks.Silicon.Refine
