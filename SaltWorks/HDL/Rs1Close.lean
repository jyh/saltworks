/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The rs1 read port, closed

```
rs1Of_is_St_get : rs1Of ins = (decQ ins).get ⟨rs1AddrOf ins, _⟩
```

**`core` reads register `rs1` as the ISA's `St.get`** — one of the five wires `PcReads` left
open, and the same read the register datapath needs for its ALU operands.

The chain: a ten-block frame peel from `regWrite` back to the port (`coreRest10_out_ge`,
built on the `coreRest11_out_ge` template), then `inst_sem` at `off2` with
`rs1Env_agrees` supplying the wiring, then `sem_readTree_St` — *"the port IS `St.get`",
every state, every ISA register, every bit* — which was already landed and needed no work.

⚠️ **`instOK_mono` EARNS ITS KEEP HERE.** `readTree_rs1_instOK` is stated at `off0`, but
`core` places the port at `off2`; the monotone lemma consumes the existing certificate at
the real offset rather than re-proving the σ bound. *That is exactly the case it was added
for.*

⛔ **`rs2` IS NOT DONE.** It is this file with five address bits changed (`rs2Bit`,
`instrNet (20 + j)`, `readTreeRs2Sig`, `off3`) — but its frame peel spans **nine** blocks,
not ten, so it needs its own `coreRest9_out_ge`. Mechanical, and not yet built.

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.RtTransport

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- The ten organ blocks between the rs1 read port and `regWrite` (inclusive of `regWrite`). -/
def coreRest10 : List Gate :=
  instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc
    ++ instGates regWrite regWriteSig offRw

theorem coreThruRw_split :
    coreThruRw = (coreThru3 ++ instGates readTree readTreeRs1Sig off2) ++ coreRest10 := by
  simp only [coreThruRw, coreThru13, coreThru3, coreRest10, List.append_assoc]

theorem coreRest10_out_ge : ∀ g ∈ coreRest10, off3 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off3 ≤ off →
      ∀ g ∈ instGates c σ off, off3 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [coreRest10, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h|h|h|h|h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ regWrite_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

theorem rs1Out_lt_off3 (k : Nat) (hk : k < 32) : rs1Out k < off3 := by revert k; decide +kernel
theorem readTree_outs_len : readTree.outs.length = 32 := by decide +kernel
theorem rs1Out_eq (k : Nat) (hk : k < 32) :
    rs1Out k = instMap readTree readTreeRs1Sig off2 (readTree.outs.getD k 0) := by
  rw [rs1Out, instOuts]
  exact getD_map_lt _ _ _ (by rw [readTree_outs_len]; exact hk) 0 0
theorem readTree_out_mem (k : Nat) (hk : k < 32) :
    (readTree.gates.map Gate.out).contains (readTree.outs.getD k 0) = true := by
  revert k; decide +kernel
theorem readTree_out_bound (k : Nat) (hk : k < 32) :
    readTree.outs.getD k 0 < readTree.nIn + readTree.gates.length := by revert k; decide +kernel

/-- ⭐⭐⭐ **THE rs1 PORT, CLOSED: `core` READS REGISTER `rs1` AS `St.get`.** -/
theorem rs1Of_is_St_get (ins : Env) :
    rs1Of ins = (decQ ins).get ⟨rs1AddrOf ins, rs1AddrOf_lt ins⟩ := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [rs1Of, wordOf_getLsbD _ _ hk, coreThruRw_split, run_append,
    run_of_unwritten _ _ _ (fun g hg hEq => by
      have hge := coreRest10_out_ge g hg
      rw [hEq] at hge
      exact absurd hge (Nat.not_le.mpr (rs1Out_lt_off3 k hk))),
    rs1Out_eq k hk, run_append,
    inst_sem readTree readTreeRs1Sig off2 (run ins coreThru3)
      (rtEnvOfSt (decQ ins) ⟨rs1AddrOf ins, rs1AddrOf_lt ins⟩)
      (instOK_mono readTree_rs1_instOK (by simp only [off2, off1, off0, instNext]; omega))
      (fun a ha => rs1Env_agrees ins a ha)
      (readTree.outs.getD k 0) (Or.inr (readTree_out_mem k hk))]
  have hs := congrArg (fun l : List Bool => l.getD k false)
    (sem_readTree_St (decQ ins) ⟨rs1AddrOf ins, rs1AddrOf_lt ins⟩)
  simp only [sem] at hs
  rw [getD_map_lt _ _ _ (by rw [readTree_outs_len]; exact hk) 0 false] at hs
  rw [hs, getD_map_lt _ _ _ (by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk]]

#audit_axioms coreRest10_out_ge rs1Of_is_St_get

end SaltWorks.HDL.RegNextUniform
