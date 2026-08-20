/-
⚙️ REWIRED SCRATCH COPY of `SaltWorks/HDL/SelValueADDI.lean` — executor deliverable, NOTHING TRACKED IS TOUCHED.

The 8 local helper copies listed below were DELETED and every use repointed at
`SaltWorks.HDL.RegNextUniform.Shared` (proved once in `ScratchQ4RDedupEx`):
  · addOut_eq
  · addOut_lt_offSub
  · adder32_out_mem
  · adder32_outs_len
  · obMux_out_mem
  · obMux_outs_len
  · obOut_eq
  · tieFalse_lt_off0

⛔ `coreThruRw_split5` is DELIBERATELY UNTOUCHED (its removal has real integration
cost — a local prefix `def` name — and is out of this brief's scope).

⚠️ This file declares the SAME fully-qualified names as `SaltWorks/HDL/SelValueADDI.lean`; the two must
never enter one import graph.  Checked: nothing in this file's transitive closure
imports it (`SelValueSLTBit0` does, and is absent).
-/
/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Opus executor, queue item Q4 — ADDI)

# Q4 / ADDI — the VALUE half of `RegDatapathOK`'s enable arm, for the ADDI class

`core_selOut_transport` (EnableArm) says WHERE `selOut k` comes from.  This file says WHAT IT
IS on an `ADDI` word: the ISA's written bit.  Scope fence: NON-MEMORY classes only; `LW`/`SW`
are out of scope (Horn D).
-/
import SaltWorks.HDL.DecoderTransport
import SaltWorks.HDL.Rs2Close
import SaltWorks.HDL.Bridge4
import SaltWorks.HDL.SelValueShared

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-! ⚠️ **THE COLLISION IS GONE, NOT RENAMED.** Four concurrent Q4 executors wrote into
`SaltWorks.HDL.RegNextUniform`; the ADD executor's file flagged that this one declared
`obMux_outs_len`, `obOut_eq`, `addOut_eq`, `adder32_outs_len`, `addOut_lt_offSub` and more at
names it also used.  This copy declares NONE of them: they are `Shared.…`, one copy, and the
duplicate-qualified-name clash a name grep cannot see no longer exists. -/

namespace ADDI

/-! ## 0 · generic frame helpers -/

theorem run_frame_of_ge (ins : Env) (X Y : List Gate) (n : Net) (b : Nat)
    (hn : n < b) (hY : ∀ g ∈ Y, b ≤ g.out) :
    run ins (X ++ Y) n = run ins X n := by
  rw [run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => absurd (hEq ▸ hY g hg) (Nat.not_le.mpr hn))

theorem blk_out_ge (c : Circ) (σ : Net → Net) (off : Nat) (hssa : c.ssa = true)
    (b : Nat) (hb : b ≤ off) : ∀ g ∈ instGates c σ off, b ≤ g.out :=
  fun g hg => Nat.le_trans hb (instGates_out_range c σ off hssa g hg).1

/-! ## 1 · the organ prefixes this file needs -/

/-- The seven organ blocks before `obMux`. -/
def coreThru7 : List Gate :=
  instGates tieCells id offTie
    ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5

/-- …with `obMux`. -/
def coreThru8 : List Gate := coreThru7 ++ instGates OperandB.obMux obSig offOb

/-- …with the ADD adder. -/
def coreThru9 : List Gate := coreThru8 ++ instGates adder32 addSig offAdd

/-- The five organs between the decoder and `obMux`. -/
def coreMid5 : List Gate :=
  instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5

/-- The six organs from the ADD adder through `regWrite`. -/
def coreRest6 : List Gate :=
  instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc
    ++ instGates regWrite regWriteSig offRw

theorem coreThru7_split : coreThru7 = coreThru2 ++ coreMid5 := by
  simp only [coreThru7, coreThru2, coreMid5, List.append_assoc]

theorem coreThru11_split9 :
    coreThru11 = (coreThru9 ++ instGates adder32 subSig offSub)
                   ++ instGates sltCirc sltSig offSlt := by
  simp only [coreThru11, coreThru9, coreThru8, coreThru7, List.append_assoc]

theorem coreThruRw_split8 : coreThruRw = coreThru8 ++ coreRest6 := by
  simp only [coreThruRw, coreThru13, coreThru8, coreThru7, coreRest6, List.append_assoc]

theorem coreMid5_out_ge : ∀ g ∈ coreMid5, off1 ≤ g.out := by
  intro g hg
  simp only [coreMid5, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h
  · exact blk_out_ge _ _ _ (by decide +kernel) off1 (Nat.le_refl _) g h
  · exact blk_out_ge _ _ _ readTree_ssa off1
      (by simp only [off2, instNext]; omega) g h
  · exact blk_out_ge _ _ _ readTree_ssa off1
      (by simp only [off3, off2, instNext]; omega) g h
  · exact blk_out_ge _ _ _ bitXor32_ssa off1
      (by simp only [off4, off3, off2, instNext]; omega) g h
  · exact blk_out_ge _ _ _ (by decide +kernel) off1
      (by simp only [off5, off4, off3, off2, instNext]; omega) g h

theorem coreRest6_out_ge : ∀ g ∈ coreRest6, offAdd ≤ g.out := by
  intro g hg
  simp only [coreRest6, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h
  · exact blk_out_ge _ _ _ adder32_ssa offAdd (Nat.le_refl _) g h
  · exact blk_out_ge _ _ _ adder32_ssa offAdd
      (by simp only [offSub, instNext]; omega) g h
  · exact blk_out_ge _ _ _ sltCirc_ssa offAdd
      (by simp only [offSlt, offSub, instNext]; omega) g h
  · exact blk_out_ge _ _ _ SelectCut32.sliceASelect_ssa offAdd
      (by simp only [offSel, offSlt, offSub, instNext]; omega) g h
  · exact blk_out_ge _ _ _ EncoderE1.ruled_ssa offAdd
      (by simp only [offEnc, offSel, offSlt, offSub, instNext]; omega) g h
  · exact blk_out_ge _ _ _ regWrite_ssa offAdd
      (by simp only [offRw, offEnc, offSel, offSlt, offSub, instNext]; omega) g h

/-! ## 2 · the four frames -/

theorem run_thru11_to9 (ins : Env) (n : Net) (hn : n < offSub) :
    run ins coreThru11 n = run ins coreThru9 n := by
  rw [coreThru11_split9,
      run_frame_of_ge ins _ _ n offSub hn
        (blk_out_ge sltCirc sltSig offSlt sltCirc_ssa offSub
          (by simp only [offSlt, instNext]; omega)),
      run_frame_of_ge ins _ _ n offSub hn
        (blk_out_ge adder32 subSig offSub adder32_ssa offSub (Nat.le_refl _))]

theorem run_thruRw_to8 (ins : Env) (n : Net) (hn : n < offAdd) :
    run ins coreThruRw n = run ins coreThru8 n := by
  rw [coreThruRw_split8, run_frame_of_ge ins coreThru8 coreRest6 n offAdd hn coreRest6_out_ge]

theorem run_thru8_to7 (ins : Env) (n : Net) (hn : n < offOb) :
    run ins coreThru8 n = run ins coreThru7 n := by
  rw [coreThru8, run_frame_of_ge ins coreThru7 _ n offOb hn
        (blk_out_ge OperandB.obMux obSig offOb OperandB.ssa_obMux offOb (Nat.le_refl _))]

theorem run_thru7_to2 (ins : Env) (n : Net) (hn : n < off1) :
    run ins coreThru7 n = run ins coreThru2 n := by
  rw [coreThru7_split, run_frame_of_ge ins coreThru2 coreMid5 n off1 hn coreMid5_out_ge]

theorem run_thru13_to2 (ins : Env) (n : Net) (hn : n < off1) :
    run ins coreThru13 n = run ins coreThru2 n := by
  rw [coreThru13_split, run_frame_of_ge ins coreThru2 coreRest11 n off1 hn coreRest11_out_ge]

theorem run_thru2_input (ins : Env) (n : Net) (hn : n < offTie) :
    run ins coreThru2 n = ins n := by
  rw [coreThru2, run_frame_of_ge ins (instGates tieCells id offTie) _ n offTie hn
        (blk_out_ge decoder decoderSig off0 decoder_ssa offTie
          (by simp only [off0, instNext]; omega))]
  exact tie_input_stable ins n hn

/-! ## 3 · offsets and net bounds -/

theorem offTie_le_off1 : offTie ≤ off1 := by simp only [off1, off0, instNext]; omega
theorem off1_le_offOb : off1 ≤ offOb := by
  simp only [offOb, off5, off4, off3, off2, instNext]; omega
theorem off3_le_offAdd : off3 ≤ offAdd := by
  simp only [offAdd, offOb, off5, off4, instNext]; omega

theorem tieFalse_lt_off1 : tieFalse < off1 := by
  rw [tie_nets_are_the_first_two.1, off1_value]; decide
theorem tieFalse_lt_offOb : tieFalse < offOb :=
  Nat.lt_of_lt_of_le tieFalse_lt_off1 off1_le_offOb

theorem rs1Out_lt_offAdd (j : Nat) (hj : j < 32) : rs1Out j < offAdd :=
  Nat.lt_of_lt_of_le (rs1Out_lt_off3 j hj) off3_le_offAdd

/-! ## 4 · the tie cell's value -/

theorem tie_run_false (ins : Env) :
    run ins (instGates tieCells id offTie) tieFalse = false := by
  have hf : tieFalse = offTie := rfl
  have hg : instGates tieCells id offTie
      = [(⟨offTie, Op.const false⟩ : Gate), (⟨offTie + 1, Op.const true⟩ : Gate)] := rfl
  rw [hf, hg]
  simp [run, upd, Op.eval]

theorem tieFalse_thru8 (ins : Env) : run ins coreThru8 tieFalse = false := by
  rw [run_thru8_to7 ins tieFalse tieFalse_lt_offOb,
      run_thru7_to2 ins tieFalse tieFalse_lt_off1,
      coreThru2,
      run_frame_of_ge ins (instGates tieCells id offTie) _ tieFalse off0 Shared.tieFalse_lt_off0
        (blk_out_ge decoder decoderSig off0 decoder_ssa off0 (Nat.le_refl _))]
  exact tie_run_false ins

/-! ## 5 · the decoder and the instruction nets, read at row 7 -/

theorem decOut3_thru7 (ins : Env) :
    run ins coreThru7 (decOut 3) = (ctrlSpec (seenWord ins)).getD 3 false := by
  rw [run_thru7_to2 ins (decOut 3) (decOut_lt_off1 3 (by omega)),
      ← run_thru13_to2 ins (decOut 3) (decOut_lt_off1 3 (by omega))]
  exact core_decOut_spec ins 3 (by omega)

theorem instr_thru7 (ins : Env) (i : Nat) (hi : i < 32) :
    run ins coreThru7 (instrNet i) = ins (instrNet i) := by
  rw [run_thru7_to2 ins (instrNet i) (Nat.lt_of_lt_of_le (instrNet_lt i hi) offTie_le_off1),
      run_thru2_input ins (instrNet i) (instrNet_lt i hi)]

/-! ## 6 · operand B — the mux, and the immediate it delivers on `ADDI` -/

theorem obSig_64 : obSig 64 = decOut 3 := rfl

theorem obSig_imm (m : Nat) (hm : m < 32) : obSig (32 + m) = instrNet (immI m) := by
  have h1 : ¬ ((32 : Nat) + m < 32) := by omega
  have h2 : (32 : Nat) + m < 64 := by omega
  have h3 : (32 : Nat) + m - 32 = m := by omega
  simp only [obSig, if_neg h1, if_pos h2, h3]

/-- ⭐ The operand-B mux, read inside `core` at row 7. -/
theorem ob_thru8_mux (ins : Env) (m : Nat) (hm : m < 32) :
    run ins coreThru8 (CorePlace.obOut m)
      = (if run ins coreThru7 (obSig 64) then run ins coreThru7 (obSig (32 + m))
         else run ins coreThru7 (obSig m)) := by
  rw [coreThru8, run_append, Shared.obOut_eq m hm,
      inst_sem OperandB.obMux obSig offOb (run ins coreThru7)
        (fun a => run ins coreThru7 (obSig a)) ob_instOK (fun _ _ => rfl)
        (OperandB.obMux.outs.getD m 0) (Or.inr (Shared.obMux_out_mem m hm)),
      show run (fun a => run ins coreThru7 (obSig a)) OperandB.obMux.gates
             (OperandB.obMux.outs.getD m 0)
           = (sem OperandB.obMux (fun a => run ins coreThru7 (obSig a))).getD m false from
        (getD_map_lt _ _ _ (by rw [Shared.obMux_outs_len]; exact hm) 0 false).symm]
  exact OperandB.out_sem_obMux _ m hm

/-- ⭐⭐ **ON AN `ADDI` WORD THE ALU'S OPERAND B IS `sext(imm)`.** `useImm = isADDI` is high, so
the mux delivers the immediate bank, and the re-pointed σ makes that bank the I-type
immediate (`obB_is_sext_imm`). -/
theorem obOut_is_sext_imm (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (m : Nat) (hm : m < 32)
    (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    run ins coreThru8 (CorePlace.obOut m) = (imm.signExtend 32).getLsbD m := by
  have hsel : run ins coreThru7 (obSig 64) = true := by
    rw [obSig_64, decOut3_thru7 ins]; simp [ctrlSpec, h]
  rw [ob_thru8_mux ins m hm, hsel, if_pos rfl, obSig_imm m hm,
      instr_thru7 ins (immI m) (immI_lt_32 m)]
  exact obB_is_sext_imm ins rd a imm m hm h

/-! ## 7 · operand A — the `rs1` read port, at row 7 -/

theorem rs1_thru8 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins coreThru8 (rs1Out j) = (rs1Of ins).getLsbD j := by
  rw [rs1Of, wordOf_getLsbD _ _ hj]
  exact (run_thruRw_to8 ins (rs1Out j) (rs1Out_lt_offAdd j hj)).symm

/-! ## 8 · the adder, read inside the core -/

theorem adder32_outs_adS (k : Nat) (hk : k < 32) : adder32.outs.getD k 0 = adS k := by
  revert k; decide +kernel

theorem adder32_nIn_65 : adder32.nIn = 65 := by decide +kernel

/-- ⭐⭐ **THE ADD BANK ADDS THE TWO WIRES IT IS FED.** Placement plus `adder_run_is_sum_bit`:
no arithmetic is re-proved here, only transported. -/
theorem addOut_thru9 (ins : Env) (A B : BitVec 32) (k : Nat) (hk : k < 32)
    (hA : ∀ j : Nat, j < 32 → run ins coreThru8 (rs1Out j) = A.getLsbD j)
    (hB : ∀ j : Nat, j < 32 → run ins coreThru8 (CorePlace.obOut j) = B.getLsbD j)
    (hC : run ins coreThru8 tieFalse = false) :
    run ins coreThru9 (CorePlace.addOut k) = (A + B).getLsbD k := by
  have hin : ∀ (j : Nat), j < 65 → run ins coreThru8 (addSig j) = adEnv A B false j := by
    intro j hj
    simp only [addSig, adEnv]
    by_cases h1 : j < 32
    · rw [if_pos h1, if_pos h1]; exact hA j h1
    · rw [if_neg h1, if_neg h1]
      by_cases h2 : j < 64
      · rw [if_pos h2, if_pos h2]; exact hB (j - 32) (by omega)
      · rw [if_neg h2, if_neg h2]; exact hC
  rw [coreThru9, run_append, Shared.addOut_eq k hk,
      inst_sem adder32 addSig offAdd (run ins coreThru8) (adEnv A B false) add_instOK
        (fun a ha => hin a (by rw [adder32_nIn_65] at ha; exact ha))
        (adder32.outs.getD k 0) (Or.inr (Shared.adder32_out_mem k hk)),
      adder32_outs_adS k hk, adder_run_is_sum_bit A B false k hk]
  simp

/-! ## 9 · the select — which bank `selOut` delivers -/

theorem gsSel_0 : gsSel 3 2 0 = 96 := by decide +kernel
theorem gsSel_1 : gsSel 3 2 1 = 97 := by decide +kernel
theorem gsRes_bank0 (k : Nat) : gsRes 0 k = k := by simp [gsRes]

theorem selSig_lt32 (k : Nat) (hk : k < 32) : selSig k = CorePlace.addOut k := by
  simp only [selSig, if_pos hk]

theorem sliceASpec_getD (E : Env) (k : Nat) (hk : k < 32) :
    (SelectCut32.sliceASpec E).getD k false = SelectCut32.sliceABit E k := by
  rw [SelectCut32.sliceASpec, List.getD_eq_getElem?_getD, List.getElem?_map]
  simp [hk]

/-- ⭐ `selOut k` inside `core` IS the block's own port spec at the environment row 11 hands it. -/
theorem selOut_sliceABit (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (selOut k)
      = SelectCut32.sliceABit (fun a => run ins coreThru11 (selSig a)) k := by
  rw [core_selOut_transport ins k hk,
      show run (fun a => run ins coreThru11 (selSig a)) SelectCut32.sliceASelect.gates
             (SelectCut32.sliceASelect.outs.getD k 0)
           = (sem SelectCut32.sliceASelect
                (fun a => run ins coreThru11 (selSig a))).getD k false from
        (getD_map_lt _ _ _ (by rw [sliceASelect_outs_len]; exact hk) 0 false).symm,
      SelectCut32.sliceASelect_cert]
  exact sliceASpec_getD _ k hk

/-- ⭐ Both class lines low ⇒ the select delivers bank 0, the ADD adder. -/
theorem selOut_bank0 (ins : Env) (k : Nat) (hk : k < 32)
    (h1 : run ins coreThru11 (decOut 1) = false)
    (h2 : run ins coreThru11 (decOut 2) = false) :
    run ins core.gates (selOut k) = run ins coreThru11 (CorePlace.addOut k) := by
  rw [selOut_sliceABit ins k hk]
  simp [SelectCut32.sliceABit, gsSel_1, gsSel_0, gsRes_bank0, selSig_97, selSig_96,
        h1, h2, selSig_lt32 k hk]

/-! ## 10 · the `rs1` address IS `decode`'s `rs1` field -/

theorem iRs1_of_decode {w : BitVec 32} {rd rs1 : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.ADDI rd rs1 imm)) : toReg (w.extractLsb' 15 5) = rs1 := by
  simp only [decode] at h
  split_ifs at h <;>
    simp only [Option.some.injEq, Instr.ADDI.injEq, reduceCtorEq] at h
  exact h.2.1

theorem iRd_of_decode {w : BitVec 32} {rd rs1 : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.ADDI rd rs1 imm)) : toReg (w.extractLsb' 7 5) = rd := by
  simp only [decode] at h
  split_ifs at h <;>
    simp only [Option.some.injEq, Instr.ADDI.injEq, reduceCtorEq] at h
  exact h.1

theorem rs1_is_get_a (ins : Env) (rd a : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    rs1Of ins = (decQ ins).get a := by
  have hfield : toReg ((seenWord ins).extractLsb' 15 5) = a := iRs1_of_decode h
  have hval : ((seenWord ins).extractLsb' 15 5).toNat = a.val := congrArg Fin.val hfield
  have haddr : rs1AddrOf ins = a.val := (rs1AddrOf_is_decode_field ins).symm.trans hval
  rw [rs1Of_is_St_get ins]
  exact congrArg (St.get (decQ ins)) (Fin.eq_of_val_eq haddr)

/-! ## ⭐⭐⭐ 11 · THE THEOREM -/

/-- ⭐⭐⭐ **THE `ADDI` VALUE ARM.** On any word the decoder reads as `ADDI`, the bit the
assembled `core` presents at `selOut k` IS bit `k` of `rs1 + sext(imm)` — the ISA's written
value.  Every step is a transport of a landed organ theorem: `core_selOut_transport` for the
placement, `sliceASelect_cert` for the mux, `adder_run_is_sum_bit` for the arithmetic,
`out_sem_obMux` + `obB_is_sext_imm` for operand B, and `rs1Of_is_St_get` + `Bridge3` for
operand A.

⛔ **THIS IS THE VALUE HALF ONLY.** It says nothing about the enable and nothing about any
other instruction class; `LW`/`SW` are out of scope behind Horn D. -/
theorem core_selOut_value_ADDI (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (k : Nat)
    (hk : k < 32) (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    run ins core.gates (selOut k)
      = ((decQ ins).get a + imm.signExtend 32).getLsbD k := by
  have hx : run ins coreThru11 (decOut 1) = false := by
    rw [← decOut_thru11 ins 1 (by omega), core_decOut_spec ins 1 (by omega)]
    simp [ctrlSpec, h]
  have hs : run ins coreThru11 (decOut 2) = false := by
    rw [← decOut_thru11 ins 2 (by omega), core_decOut_spec ins 2 (by omega)]
    simp [ctrlSpec, h]
  rw [selOut_bank0 ins k hk hx hs,
      run_thru11_to9 ins (CorePlace.addOut k) (Shared.addOut_lt_offSub k hk),
      addOut_thru9 ins (rs1Of ins) (imm.signExtend 32) k hk
        (fun j hj => rs1_thru8 ins j hj)
        (fun j hj => obOut_is_sext_imm ins rd a imm j hj h)
        (tieFalse_thru8 ins),
      rs1_is_get_a ins rd a imm h]

/-! ## 12 · the ISA side, and the two joined -/

theorem stepT_addi_written (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val])
      = (decQ ins).get a + imm.signExtend 32 := by
  have h1 : SaltWorks.ISA.stepT (decQ ins) (seenWord ins)
      = SaltWorks.ISA.step (decQ ins) (.ADDI rd a imm) := by
    simp [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW, h]
  rw [h1]
  simp [SaltWorks.ISA.step, St.set, St.next, hrd]

/-- ⭐⭐⭐ **THE `ADDI` ROW OF `RegDatapathOK`'s VALUE ARM, AGAINST THE ISA ITSELF.** For a
destination other than `x0`, `selOut k` equals the bit the ISA writes into `rd`. -/
theorem core_selOut_is_isa_ADDI (ins : Env) (rd a : Fin 32) (imm : BitVec 12) (k : Nat)
    (hk : k < 32) (hrd : rd ≠ 0) (h : decode (seenWord ins) = some (.ADDI rd a imm)) :
    run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [stepT_addi_written ins rd a imm hrd h]
  exact core_selOut_value_ADDI ins rd a imm k hk h

/-! ## 13 · NON-VACUITY — the hypothesis is reachable, and the ∀ FIRES on a concrete word

⚠️ **A theorem whose hypothesis no word satisfies would build green and say nothing.** The
witness below is `ADDI x1, x0, 1` on an all-zero state — the same word `C4Refuted.insI` uses.
`C4Refuted.sel0_insI` establishes `selOut 0 = true` there by RUNNING the packed evaluator on
the netlist; `selOut0_insADDI` derives the same value from the ∀-statement above, so the two
agree by independent routes and neither is a restatement of the other. -/

def wADDI : BitVec 32 := encode (Instr.ADDI 1 0 1)
def sADDI : Nat := wADDI.toNat * 2 ^ 1056
def insADDI : Env := fun n => sADDI.testBit n

theorem seen_insADDI : seenWord insADDI = wADDI := by decide +kernel

theorem dec_insADDI : decode (seenWord insADDI) = some (Instr.ADDI 1 0 1) := by
  rw [seen_insADDI]; exact decode_encode _

/-- ⭐ **THE GENERAL THEOREM, FIRED** — `core` writes `x0 + 1 = 1`, whose bit 0 is `true`. -/
theorem selOut0_insADDI : run insADDI core.gates (selOut 0) = true := by
  rw [core_selOut_value_ADDI insADDI 1 0 1 0 (by decide) dec_insADDI]
  decide +kernel

#audit_axioms core_selOut_value_ADDI
#audit_axioms core_selOut_is_isa_ADDI
#audit_axioms obOut_is_sext_imm
#audit_axioms addOut_thru9
#audit_axioms selOut_bank0
#audit_axioms rs1_is_get_a
#audit_axioms stepT_addi_written
#audit_axioms selOut0_insADDI

end ADDI
end SaltWorks.HDL.RegNextUniform
