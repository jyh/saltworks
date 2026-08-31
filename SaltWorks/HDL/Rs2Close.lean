/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The rs2 read port, and the pc wire

```
rs2Of_is_St_get  : rs2Of ins = (decQ ins).get ⟨rs2AddrOf ins, _⟩
pcOf_is_decQ_pc  : pcOf ins  = (decQ ins).pc            (definitional)
```

**Three of `PcReads`' five wires are now closed** — `pcOf`, `rs1Of`, `rs2Of`. Remaining:
`immOf` (the immediate block) and `isBEQOf'` (`decOut 4`, for which `core_decOut_spec`
already exists over `coreThru13` and needs re-stating over `coreThruRw`).

⚠️ **THE TWIN IS NOT A COPY, AND THE DIFFERENCE IS THE FRAME.** `rs2` sits one organ later
than `rs1`, so its peel spans **nine** blocks rather than ten (`coreRest9_out_ge`, bounded at
`off4` rather than `off3`). Everything else is the five address bits: `rs2Bit`,
`instrNet (20 + j)`, `readTreeRs2Sig`, `off3`. *`readTree_rs2_instOK` is stated at `off0`
like its sibling, so `instOK_mono` carries it to the real offset again.*

📌 *`pcOf` is `rfl`: `pcNet k = 1024 + k` and `decQ`'s pc field is
`wordOf (fun k => ins (1024 + k))`. It is worth a name anyway — an unnamed definitional
fact gets re-derived by whoever needs it next, and `PcReads` states the obligation over
`pcOf`, not over `decQ`.*

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.Rs1Close

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- The prefix up to and including the rs1 port — what the rs2 port sees. -/
def coreThru4 : List Gate := coreThru3 ++ instGates readTree readTreeRs1Sig off2

/-- The ELEVEN organ blocks after the rs2 port, through `regWrite`. (rs1 had twelve.) -/
def coreRest9 : List Gate :=
  instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc
    ++ instGates lwWrCirc lwWrSig offLwWr
    ++ instGates regWrite regWriteSig offRw

theorem coreThruRw_split2 :
    coreThruRw = (coreThru4 ++ instGates readTree readTreeRs2Sig off3) ++ coreRest9 := by
  simp only [coreThruRw, coreThruLw, coreThru13, coreThru4, coreThru3, coreRest9, List.append_assoc]

theorem coreRest9_out_ge : ∀ g ∈ coreRest9, off4 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off4 ≤ off →
      ∀ g ∈ instGates c σ off, off4 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [coreRest9, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h|h|h|h|h|h|h
  · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ lwWrCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ regWrite_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

theorem coreThru4_sub : coreThru4 ⊆ core.gates := by
  intro g hg
  refine coreThru13_sub ?_
  simp only [coreThru4, coreThru3, List.mem_append, or_assoc] at hg
  simp only [coreThru13, List.mem_append, or_assoc]
  tauto

theorem coreThru4_input_stable (ins : Env) (n : Net) (hn : n < coreInWidth) :
    run ins coreThru4 n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ core_gate_out_ge g (coreThru4_sub hg)) (Nat.not_le.mpr hn))

/-- The `rs2` address — bits 20…24 of the instruction word. -/
def rs2AddrOf (ins : Env) : Nat :=
  (if ins (instrNet 20) then 1 else 0) + (if ins (instrNet 21) then 2 else 0)
  + (if ins (instrNet 22) then 4 else 0) + (if ins (instrNet 23) then 8 else 0)
  + (if ins (instrNet 24) then 16 else 0)

theorem rs2AddrOf_lt (ins : Env) : rs2AddrOf ins < 32 := by
  cases h20 : ins (instrNet 20) <;> cases h21 : ins (instrNet 21) <;>
    cases h22 : ins (instrNet 22) <;> cases h23 : ins (instrNet 23) <;>
    cases h24 : ins (instrNet 24) <;> simp [rs2AddrOf, h20, h21, h22, h23, h24]

theorem rs2AddrOf_testBit (ins : Env) (j : Nat) (hj : j < 5) :
    (rs2AddrOf ins).testBit j = ins (instrNet (20 + j)) := by
  cases h20 : ins (instrNet 20) <;> cases h21 : ins (instrNet 21) <;>
    cases h22 : ins (instrNet 22) <;> cases h23 : ins (instrNet 23) <;>
    cases h24 : ins (instrNet 24) <;>
    interval_cases j <;> norm_num [rs2AddrOf, h20, h21, h22, h23, h24] <;> decide

theorem rs2Bit_lt (j : Nat) (hj : j < 5) : rs2Bit j < coreInWidth := by revert j; decide +kernel

theorem rs2Env_agrees (ins : Env) (j : Nat) (hj : j < readTree.nIn) :
    run ins coreThru4 (readTreeRs2Sig j)
      = rtEnvOfSt (decQ ins) ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩ j := by
  rw [readTree_nIn_997] at hj
  by_cases h5 : j < 5
  · rw [show readTreeRs2Sig j = rs2Bit j from by simp [readTreeRs2Sig, h5],
        coreThru4_input_stable ins _ (rs2Bit_lt j h5)]
    show ins (instrNet (20 + j)) = rtEnvOf _ _ j
    rw [rtEnvOf_addr _ _ j h5, rs2AddrOf_testBit ins j h5]
  · rw [show readTreeRs2Sig j = j + 27 from by simp [readTreeRs2Sig, h5],
        coreThru4_input_stable ins _ (by
          have : j + 27 < 1088 := by omega
          simpa only [coreInWidth, stWidth] using this)]
    have hr : (j - 5) / 32 + 1 < 32 := by omega
    have hmod : ((j - 5) / 32 + 1) % 32 = (j - 5) / 32 + 1 := Nat.mod_eq_of_lt hr
    have hne : ¬ ((⟨((j - 5) / 32 + 1) % 32, Nat.mod_lt _ (by norm_num)⟩ : Fin 32) = 0) := by
      intro hz
      have := congrArg Fin.val hz
      simp only [hmod] at this
      omega
    simp only [rtEnvOfSt, rtEnvOf, rtAddrBits, rtWidth, St.get, if_neg hne]
    rw [if_neg h5]
    have harith : 32 * (((j - 5) / 32 + 1) % 32) + (j - 5) % 32 = j + 27 := by
      rw [hmod]
      have := Nat.div_add_mod (j - 5) 32
      omega
    rw [show ((decQ ins).regs[(((j - 5) / 32 + 1) % 32 : Nat)]).getLsbD ((j - 5) % 32)
          = ins (32 * (((j - 5) / 32 + 1) % 32) + (j - 5) % 32) from
        decQ_reg_bit ins ⟨((j - 5) / 32 + 1) % 32, Nat.mod_lt _ (by norm_num)⟩ _
          (Nat.mod_lt _ (by norm_num)), harith]

theorem rs2Out_lt_off4 (k : Nat) (hk : k < 32) : rs2Out k < off4 := by revert k; decide +kernel
theorem rs2Out_eq (k : Nat) (hk : k < 32) :
    rs2Out k = instMap readTree readTreeRs2Sig off3 (readTree.outs.getD k 0) := by
  rw [rs2Out, instOuts]
  exact getD_map_lt _ _ _ (by rw [readTree_outs_len]; exact hk) 0 0

/-- ⭐⭐⭐ **THE rs2 PORT, CLOSED.** -/
theorem rs2Of_is_St_get (ins : Env) :
    rs2Of ins = (decQ ins).get ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩ := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [rs2Of, wordOf_getLsbD _ _ hk, coreThruRw_split2, run_append,
    run_of_unwritten _ _ _ (fun g hg hEq => by
      have hge := coreRest9_out_ge g hg
      rw [hEq] at hge
      exact absurd hge (Nat.not_le.mpr (rs2Out_lt_off4 k hk))),
    rs2Out_eq k hk, run_append,
    inst_sem readTree readTreeRs2Sig off3 (run ins coreThru4)
      (rtEnvOfSt (decQ ins) ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩)
      (instOK_mono readTree_rs2_instOK (by simp only [off3, off2, off1, off0, instNext]; omega))
      (fun a ha => rs2Env_agrees ins a ha)
      (readTree.outs.getD k 0) (Or.inr (readTree_out_mem k hk))]
  have hs := congrArg (fun l : List Bool => l.getD k false)
    (sem_readTree_St (decQ ins) ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩)
  simp only [sem] at hs
  rw [getD_map_lt _ _ _ (by rw [readTree_outs_len]; exact hk) 0 false] at hs
  rw [hs, getD_map_lt _ _ _ (by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk]]

/-- ⭐ **AND THE THIRD WIRE IS DEFINITIONAL.** `pcNet k = 1024 + k` and `decQ`'s pc field is
`wordOf (fun k => ins (1024 + k))`, so the pc the adder sees IS the decoded state's pc. -/
theorem pcOf_is_decQ_pc (ins : Env) : pcOf ins = (decQ ins).pc := rfl

#audit_axioms coreRest9_out_ge rs2Env_agrees rs2Of_is_St_get pcOf_is_decQ_pc


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThru4_input_stable SaltWorks.HDL.RegNextUniform.coreThru4_sub
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThruRw_split2 SaltWorks.HDL.RegNextUniform.rs2AddrOf_lt
#audit_axioms SaltWorks.HDL.RegNextUniform.rs2AddrOf_testBit SaltWorks.HDL.RegNextUniform.rs2Bit_lt
#audit_axioms SaltWorks.HDL.RegNextUniform.rs2Out_eq SaltWorks.HDL.RegNextUniform.rs2Out_lt_off4
end SaltWorks.HDL.RegNextUniform
