/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Opus executor, Q4 residue — SLT bit 0)

# Q4 / SLT residue — BIT 0, the bit where the COMPARISON lives

`SelValueSLT` closed bits 1…31 (all constant `false`) and reduced bit 0 to THREE named
hypotheses — the core-side transport of `sltCirc`'s three drive nets through the first TEN
organs.  **This file discharges those three and states the SLT value arm with NO `0 < k`.**
-/
import SaltWorks.HDL.SelValueSLT
import SaltWorks.HDL.SelValueADD

set_option maxRecDepth 100000

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

namespace SLTBit0

/-! ## 1 · the two extra prefixes this proof reads at -/

/-- The six organ blocks through `bitXor32` — what `bitNot32` reads. -/
def cT6 : List Gate := ADD.cT5 ++ instGates bitXor32 bitXor32Sig off4

/-- The nine organ blocks through the ADDING adder — what the SUBTRACTING adder reads. -/
def cT9 : List Gate := ADD.cT8 ++ instGates adder32 addSig offAdd

theorem cT6_split5 : cT6 = ADD.cT5 ++ instGates bitXor32 bitXor32Sig off4 := rfl
theorem cT9_split_add : cT9 = ADD.cT8 ++ instGates adder32 addSig offAdd := rfl

theorem cT9_split4 : cT9 = coreThru4
    ++ (instGates readTree readTreeRs2Sig off3
        ++ instGates bitXor32 bitXor32Sig off4
        ++ instGates bitNot32 bitNot32Sig off5
        ++ instGates selOr selOrSig offSelOr
        ++ instGates OperandB.obMux immMuxSig offImmMux
        ++ instGates OperandB.obMux obSig offOb
        ++ instGates adder32 addSig offAdd) := by
  simp only [cT9, ADD.cT8, ADD.cT7, coreThru4, coreThru3, List.append_assoc]

theorem cT9_split5 : cT9 = ADD.cT5
    ++ (instGates bitXor32 bitXor32Sig off4
        ++ instGates bitNot32 bitNot32Sig off5
        ++ instGates selOr selOrSig offSelOr
        ++ instGates OperandB.obMux immMuxSig offImmMux
        ++ instGates OperandB.obMux obSig offOb
        ++ instGates adder32 addSig offAdd) := by
  simp only [cT9, ADD.cT8, ADD.cT7, ADD.cT5, coreThru4, coreThru3, List.append_assoc]

theorem cT9_split_not : cT9 = (cT6 ++ instGates bitNot32 bitNot32Sig off5)
    ++ (instGates selOr selOrSig offSelOr
        ++ instGates OperandB.obMux immMuxSig offImmMux
        ++ instGates OperandB.obMux obSig offOb ++ instGates adder32 addSig offAdd) := by
  simp only [cT9, cT6, ADD.cT8, ADD.cT7, ADD.cT5, coreThru4, coreThru3, List.append_assoc]

theorem thru10_split_sub :
    SLT.coreThru10 = cT9 ++ instGates adder32 subSig offSub := by
  simp only [SLT.coreThru10, cT9, ADD.cT8, ADD.cT7, List.append_assoc]

/-! ## 2 · the tails, so a net below a block's offset can be read at that block's own prefix -/

theorem tail4_9 : ∀ g ∈ (instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd), off3 ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  have h34 : off3 ≤ off4 := ADD.off_le_3_4
  have h35 : off3 ≤ off5 := le_trans h34 ADD.off_le_4_5
  have h3ob : off3 ≤ offOb := le_trans h35 ADD.off_le_5_ob
  have h3add : off3 ≤ offAdd := le_trans h3ob ADD.off_le_ob_add
  rcases hg with h|h|h|h|h|h|h
  · exact ADD.blk_ge _ _ _ readTree_ssa off3 (Nat.le_refl _) g h
  · exact ADD.blk_ge _ _ _ bitXor32_ssa off3 h34 g h
  · exact ADD.blk_ge _ _ _ bitNot32_ssa off3 h35 g h
  · exact ADD.blk_ge _ _ _ (by decide +kernel) off3 (by simp only [offSelOr, off5, off4, off3, off2, off1, off0, instNext]; omega) g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux off3 (by simp only [offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, instNext]; omega) g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux off3 h3ob g h
  · exact ADD.blk_ge _ _ _ adder32_ssa off3 h3add g h

theorem tail5_9 : ∀ g ∈ (instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd), off4 ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  have h4ob : off4 ≤ offOb := le_trans ADD.off_le_4_5 ADD.off_le_5_ob
  rcases hg with h|h|h|h|h|h
  · exact ADD.blk_ge _ _ _ bitXor32_ssa off4 (Nat.le_refl _) g h
  · exact ADD.blk_ge _ _ _ bitNot32_ssa off4 ADD.off_le_4_5 g h
  · exact ADD.blk_ge _ _ _ (by decide +kernel) off4 (by simp only [offSelOr, off5, off4, off3, off2, off1, off0, instNext]; omega) g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux off4 (by simp only [offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, instNext]; omega) g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux off4 h4ob g h
  · exact ADD.blk_ge _ _ _ adder32_ssa off4 (le_trans h4ob ADD.off_le_ob_add) g h

theorem tail_ob_add : ∀ g ∈ (instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd), offOb ≤ g.out := by
  intro g hg
  simp only [List.mem_append] at hg
  rcases hg with h|h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux offOb (Nat.le_refl _) g h
  · exact ADD.blk_ge _ _ _ adder32_ssa offOb ADD.off_le_ob_add g h

/-- ⚠️ **THE BOUND HERE IS `offSelOr`, NOT `offOb`, AND THAT IS THE POINT.** Leg ① stage 2a put
two organs BELOW `obMux`, so they write nets strictly under `offOb`; `offOb ≤ g.out` is FALSE
for them. A tail lemma that kept the old bound would be unprovable, not merely unproved. -/
theorem tail_selOr_add : ∀ g ∈ (instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd), offSelOr ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  have hsi : offSelOr ≤ offImmMux := by
    simp only [offImmMux, instNext]; omega
  have hso : offSelOr ≤ offOb := by
    simp only [offOb, offImmMux, instNext]; omega
  rcases hg with h|h|h|h
  · exact ADD.blk_ge _ _ _ (by decide +kernel) offSelOr (Nat.le_refl _) g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux offSelOr hsi g h
  · exact ADD.blk_ge _ _ _ OperandB.ssa_obMux offSelOr hso g h
  · exact ADD.blk_ge _ _ _ adder32_ssa offSelOr (le_trans hso ADD.off_le_ob_add) g h

theorem tail_xor : ∀ g ∈ instGates bitXor32 bitXor32Sig off4, off4 ≤ g.out :=
  ADD.blk_ge _ _ _ bitXor32_ssa off4 (Nat.le_refl _)

/-! ## 3 · the frame steps -/

theorem run_thru10_to_cT9 (ins : Env) (n : Net) (hn : n < offSub) :
    run ins SLT.coreThru10 n = run ins cT9 n := by
  rw [thru10_split_sub]
  exact ADD.run_drop ins cT9 _ offSub n hn
    (ADD.blk_ge _ _ _ adder32_ssa offSub (Nat.le_refl _))

theorem run_cT9_to_thru4 (ins : Env) (n : Net) (hn : n < off3) :
    run ins cT9 n = run ins coreThru4 n := by
  rw [cT9_split4]; exact ADD.run_drop ins coreThru4 _ off3 n hn tail4_9

theorem run_cT9_to_cT5 (ins : Env) (n : Net) (hn : n < off4) :
    run ins cT9 n = run ins ADD.cT5 n := by
  rw [cT9_split5]; exact ADD.run_drop ins ADD.cT5 _ off4 n hn tail5_9

theorem run_cT9_to_notblk (ins : Env) (n : Net) (hn : n < offSelOr) :
    run ins cT9 n = run ins (cT6 ++ instGates bitNot32 bitNot32Sig off5) n := by
  rw [cT9_split_not]
  exact ADD.run_drop ins _ _ offSelOr n hn tail_selOr_add

theorem run_cT6_to_cT5 (ins : Env) (n : Net) (hn : n < off4) :
    run ins cT6 n = run ins ADD.cT5 n := by
  rw [cT6_split5]; exact ADD.run_drop ins ADD.cT5 _ off4 n hn tail_xor

theorem run_cT9_to_cT8 (ins : Env) (n : Net) (hn : n < offAdd) :
    run ins cT9 n = run ins ADD.cT8 n := by
  rw [cT9_split_add]
  exact ADD.run_drop ins ADD.cT8 _ offAdd n hn
    (ADD.blk_ge _ _ _ adder32_ssa offAdd (Nat.le_refl _))

/-! ## 4 · the two register-file banks, at the prefixes the SUB adder and `bitNot32` read -/

theorem rs1_at_cT9 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins cT9 (rs1Out j) = (rs1Of ins).getLsbD j := by
  have h1 : (rs1Of ins).getLsbD j = run ins coreThruRw (rs1Out j) := by
    rw [rs1Of, wordOf_getLsbD _ _ hj]
  rw [h1, ADD.run_rw_to_thru4 ins _ (rs1Out_lt_off3 j hj),
      run_cT9_to_thru4 ins _ (rs1Out_lt_off3 j hj)]

theorem rs2_at_cT6 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins cT6 (rs2Out j) = (rs2Of ins).getLsbD j := by
  have h1 : (rs2Of ins).getLsbD j = run ins coreThruRw (rs2Out j) := by
    rw [rs2Of, wordOf_getLsbD _ _ hj]
  rw [h1, ADD.run_rw_to_cT5 ins _ (rs2Out_lt_off4 j hj),
      run_cT6_to_cT5 ins _ (rs2Out_lt_off4 j hj)]

theorem rs2_at_cT9 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins cT9 (rs2Out j) = (rs2Of ins).getLsbD j := by
  have h1 : (rs2Of ins).getLsbD j = run ins coreThruRw (rs2Out j) := by
    rw [rs2Of, wordOf_getLsbD _ _ hj]
  rw [h1, ADD.run_rw_to_cT5 ins _ (rs2Out_lt_off4 j hj),
      run_cT9_to_cT5 ins _ (rs2Out_lt_off4 j hj)]

/-! ## 5 · ⭐ THE `~b` BANK — `bitNot32`, in place -/

theorem bitNot32_nIn : bitNot32.nIn = 32 := by decide +kernel
theorem bitNot32_outs_len' : bitNot32.outs.length = 32 := by decide +kernel

theorem bitNot32_out_mem (m : Nat) (hm : m < 32) :
    (bitNot32.gates.map Gate.out).contains (bitNot32.outs.getD m 0) = true := by
  revert hm; revert m; decide +kernel

theorem bitNot32_out_index (m : Nat) (hm : m < 32) :
    bitNot32.outs.getD m 0 < bitNot32.nIn + bitNot32.gates.length := by
  revert hm; revert m; decide +kernel

theorem notOut_eq (m : Nat) (hm : m < 32) :
    CorePlace.notOut m = instMap bitNot32 bitNot32Sig off5 (bitNot32.outs.getD m 0) := by
  rw [CorePlace.notOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [bitNot32_outs_len']; exact hm) 0 0

theorem notOut_lt_offOb (m : Nat) (hm : m < 32) : CorePlace.notOut m < offOb := by
  revert hm; revert m; decide +kernel

/-- The inverted bank sits below the widened organs too — the bound `run_cT9_to_notblk`
needs after leg ① stage 2a. -/
theorem notOut_lt_offSelOr (m : Nat) (hm : m < 32) : CorePlace.notOut m < offSelOr := by
  revert hm; revert m; decide +kernel

/-- ⭐⭐ **THE SUBTRACTOR'S `b` BANK IS `¬ rs2`, READ INSIDE `core`.** `sem_bitNot32` is
math's landed organ certificate; this is it transported onto placement #7. -/
theorem not_bit (ins : Env) (m : Nat) (hm : m < 32) :
    run ins cT9 (CorePlace.notOut m) = !((rs2Of ins).getLsbD m) := by
  rw [run_cT9_to_notblk ins _ (notOut_lt_offSelOr m hm), notOut_eq m hm, run_append,
      inst_sem bitNot32 bitNot32Sig off5 (run ins cT6)
        (fun j => run ins cT6 (bitNot32Sig j)) bitNot32_instOK (fun _ _ => rfl)
        (bitNot32.outs.getD m 0) (Or.inr (bitNot32_out_mem m hm))]
  have hag : run (fun j => run ins cT6 (bitNot32Sig j)) bitNot32.gates
        (bitNot32.outs.getD m 0)
      = run (fun i => (rs2Of ins).getLsbD i) bitNot32.gates (bitNot32.outs.getD m 0) := by
    refine run_agree_of_inputs_circ bitNot32 bitNot32_ssa _ _ ?_ _ (bitNot32_out_index m hm)
    intro a ha
    rw [bitNot32_nIn] at ha
    show run ins cT6 (rs2Out a) = _
    exact rs2_at_cT6 ins a ha
  rw [hag]
  have hsem := SaltWorks.Stack.Program.sem_bitNot32 (rs2Of ins)
  have hport : (sem bitNot32 (fun i => (rs2Of ins).getLsbD i)).getD m false
      = run (fun i => (rs2Of ins).getLsbD i) bitNot32.gates (bitNot32.outs.getD m 0) := by
    simp only [sem]
    exact getD_map_lt _ _ _ (by rw [bitNot32_outs_len']; exact hm) 0 false
  rw [← hport, hsem,
      getD_map_lt _ _ _ (show m < (List.range 32).length from by simpa using hm) 0 false,
      show (List.range 32).getD m 0 = m from by simp [hm]]
  simp [hm]

/-! ## 6 · the carry-in is a hard ONE -/

theorem tieTrue_lt_off0 : tieTrue < off0 := by decide +kernel

theorem tie_block_true (ins : Env) :
    run ins (instGates tieCells id offTie) tieTrue = true := by
  have hg : instGates tieCells id offTie
      = [(⟨1088, Op.const false⟩ : Gate), (⟨1089, Op.const true⟩ : Gate)] := by
    decide +kernel
  have ht : tieTrue = 1089 := tie_nets_are_the_first_two.2
  rw [hg, ht]
  simp [upd, Op.eval]

theorem tieTrue_at_cT9 (ins : Env) : run ins cT9 tieTrue = true := by
  rw [run_cT9_to_cT8 ins tieTrue
        (lt_of_lt_of_le tieTrue_lt_off0
          (le_trans ADD.off_le_0_1 (le_trans ADD.off_le_1_2 (le_trans ADD.off_le_2_3
            (le_trans ADD.off_le_3_4 (le_trans ADD.off_le_4_5
              (le_trans ADD.off_le_5_ob ADD.off_le_ob_add))))))),
      ADD.cT8_split_tie,
      ADD.run_drop ins _ _ off0 tieTrue tieTrue_lt_off0 ADD.tail_after_tie]
  exact tie_block_true ins

/-! ## 7 · ⭐⭐ THE SUBTRACTING ADDER, IN PLACE -/

theorem subOut_eq (k : Nat) (hk : k < 33) :
    CorePlace.subOut k = instMap adder32 subSig offSub (adder32.outs.getD k 0) := by
  rw [CorePlace.subOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [Shared.adder32_outs_len]; exact hk) 0 0

theorem subOut_lt_offSlt (k : Nat) (hk : k < 33) : CorePlace.subOut k < offSlt := by
  revert hk; revert k; decide +kernel

/-- The 65 wires the SUBTRACTING adder reads, at its own prefix, ARE the environment
`SaltWorks.HDL.subOut` runs `adder32` on: `a`, `~b`, carry-in HIGH. -/
theorem sub_env_agrees (ins : Env) : ∀ i, i < adder32.nIn →
    run ins cT9 (subSig i)
      = (if i < 32 then (rs1Of ins).getLsbD i
         else if i < 64 then !((rs2Of ins).getLsbD (i - 32)) else true) := by
  intro i hi
  rw [ADD.adder32_nIn] at hi
  by_cases h1 : i < 32
  · rw [show subSig i = rs1Out i from by simp [subSig, h1], rs1_at_cT9 ins i h1, if_pos h1]
  · by_cases h2 : i < 64
    · rw [show subSig i = CorePlace.notOut (i - 32) from by simp [subSig, h1, h2],
          not_bit ins (i - 32) (by omega), if_neg h1, if_pos h2]
    · have hi64 : i = 64 := by omega
      subst hi64
      rw [show subSig 64 = tieTrue from by simp [subSig], tieTrue_at_cT9 ins]
      simp

/-- ⭐⭐⭐ **THE SUBTRACTION'S SIGN BIT, READ INSIDE `core`, IS `subOut`'s OWN BIT 31.**
`SaltWorks.HDL.subOut x y` is literally `sem adder32` on that environment, so this needs
no arithmetic at all — only that the placed wires carry it. -/
theorem sub_bit (ins : Env) (k : Nat) (hk : k < 33) :
    run ins SLT.coreThru10 (CorePlace.subOut k)
      = (SaltWorks.HDL.subOut (rs1Of ins) (rs2Of ins)).getD k false := by
  have hmem : (adder32.gates.map Gate.out).contains (adder32.outs.getD k 0) = true := by
    revert hk; revert k; decide +kernel
  rw [thru10_split_sub, subOut_eq k hk, run_append,
      inst_sem adder32 subSig offSub (run ins cT9)
        (fun i => if i < 32 then (rs1Of ins).getLsbD i
                  else if i < 64 then !((rs2Of ins).getLsbD (i - 32)) else true)
        sub_instOK (sub_env_agrees ins) (adder32.outs.getD k 0) (Or.inr hmem)]
  show _ = (sem adder32 _).getD k false
  simp only [sem]
  exact (getD_map_lt _ _ _ (by rw [Shared.adder32_outs_len]; exact hk) 0 false).symm


/-! ## 8 · ⭐⭐⭐ THE THREE DRIVE NETS, DISCHARGED — and BIT 0 CLOSED -/

theorem sltSig_0 : sltSig 0 = rs1Out 31 := rfl
theorem sltSig_1 : sltSig 1 = rs2Out 31 := rfl
theorem sltSig_2 : sltSig 2 = CorePlace.subOut 31 := rfl

theorem drive0 (ins : Env) :
    run ins SLT.coreThru10 (sltSig 0) = (rs1Of ins).getLsbD 31 := by
  rw [sltSig_0,
      run_thru10_to_cT9 ins _ (lt_of_lt_of_le (rs1Out_lt_off3 31 (by omega))
        (le_trans ADD.off_le_3_4 (le_trans ADD.off_le_4_5 (le_trans ADD.off_le_5_ob
          (le_trans ADD.off_le_ob_add ADD.off_le_add_sub))))),
      rs1_at_cT9 ins 31 (by omega)]

theorem drive1 (ins : Env) :
    run ins SLT.coreThru10 (sltSig 1) = (rs2Of ins).getLsbD 31 := by
  rw [sltSig_1,
      run_thru10_to_cT9 ins _ (lt_of_lt_of_le (rs2Out_lt_off4 31 (by omega))
        (le_trans ADD.off_le_4_5 (le_trans ADD.off_le_5_ob
          (le_trans ADD.off_le_ob_add ADD.off_le_add_sub)))),
      rs2_at_cT9 ins 31 (by omega)]

theorem drive2 (ins : Env) :
    run ins SLT.coreThru10 (sltSig 2)
      = (SaltWorks.HDL.subOut (rs1Of ins) (rs2Of ins)).getD 31 false := by
  rw [sltSig_2]; exact sub_bit ins 31 (by omega)

/-- ⭐⭐⭐ **BIT 0 OF THE `SLT` VALUE, UNCONDITIONALLY.** `SelValueSLT.core_selOut_slt_bit0`
left three hypotheses standing; all three are now theorems, so the select's bit 0 on an
`SLT` word IS the signed comparison of the two register reads. -/
theorem core_selOut_slt_bit0_closed (ins : Env) {rd a b : Fin 32}
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut 0) = BitVec.slt (rs1Of ins) (rs2Of ins) :=
  SLT.core_selOut_slt_bit0 ins (rs1Of ins) (rs2Of ins) h (drive0 ins) (drive1 ins) (drive2 ins)

/-! ## 9 · the ISA side at bit 0 -/

theorem decode_slt_regs (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.SLT rd a b)) :
    rd = toReg (w.extractLsb' 7 5) ∧ a = toReg (w.extractLsb' 15 5)
      ∧ b = toReg (w.extractLsb' 20 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

theorem rs1Of_is_get_a_SLT (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) : rs1Of ins = (decQ ins).get a := by
  rw [rs1Of_is_St_get]
  congr 1
  have ha := (decode_slt_regs _ rd a b h).2.1
  apply Fin.ext
  show rs1AddrOf ins = a.val
  rw [ha, ← rs1AddrOf_is_decode_field ins]
  rfl

theorem rs2Of_is_get_b_SLT (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) : rs2Of ins = (decQ ins).get b := by
  rw [rs2Of_is_St_get]
  congr 1
  have hb := (decode_slt_regs _ rd a b h).2.2
  apply Fin.ext
  show rs2AddrOf ins = b.val
  rw [hb, ← rs2AddrOf_is_decode_field ins]
  rfl

/-- The ISA's `SLT` write, read back at `rd`. **`rd ≠ 0` is load-bearing** — `St.set`
DISCARDS a write to `x0`. -/
theorem stepT_SLT_regs (ins : Env) (rd a b : Fin 32) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val])
      = (if ((decQ ins).get a).slt ((decQ ins).get b) then (1 : BitVec 32) else 0) := by
  have hstep : SaltWorks.ISA.stepT (decQ ins) (seenWord ins)
      = ((decQ ins).set rd
          (if ((decQ ins).get a).slt ((decQ ins).get b) then 1 else 0)).next := by
    simp [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW, h, SaltWorks.ISA.step]
  rw [hstep]
  simp [St.next, St.set, hrd]

theorem cmpWord_bit0 (c : Bool) : (if c then (1 : BitVec 32) else 0).getLsbD 0 = c := by
  cases c <;> simp

theorem isa_slt_bit0 (ins : Env) (rd a b : Fin 32) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD 0
      = BitVec.slt ((decQ ins).get a) ((decQ ins).get b) := by
  rw [stepT_SLT_regs ins rd a b hrd h, cmpWord_bit0]

/-! ## 10 · ⭐⭐⭐ THE ROW THAT WAS MISSING, AND THE UNSCOPED HEADLINE -/

/-- ⭐⭐⭐ **THE `SLT` VALUE ARM AT BIT 0 — the residue, closed.** -/
theorem core_selOut_eq_isa_slt_bit0 (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut 0)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD 0 := by
  rw [core_selOut_slt_bit0_closed ins h, isa_slt_bit0 ins rd a b hrd h,
      rs1Of_is_get_a_SLT ins rd a b h, rs2Of_is_get_b_SLT ins rd a b h]

/-- ⭐⭐⭐ **THE UNSCOPED `SLT` VALUE ARM — ALL THIRTY-TWO BITS, NO `0 < k`.**
This is `SelValueSLT.core_selOut_eq_isa_slt_high` with its `hk0` retired: bits 1…31 come from
the landed constant-broadcast argument, bit 0 from the comparator chain closed above. -/
theorem core_selOut_eq_isa_slt (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rcases Nat.eq_zero_or_pos k with hk0 | hk0
  · subst hk0; exact core_selOut_eq_isa_slt_bit0 ins hrd h
  · exact SLT.core_selOut_eq_isa_slt_high ins hrd k hk hk0 h

/-! ### the same sentence in `RegDatapathOK`'s own shape, ENABLE DISCHARGED -/

theorem decode_slt_rd (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.SLT rd a b)) :
    rd = toReg (w.extractLsb' 7 5) := (decode_slt_regs w rd a b h).1

theorem rdOf_is_rd_SLT (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) : rdOf ins = rd.val := by
  rw [← Shared.rdOf_is_decode_field ins, decode_slt_rd _ rd a b h]
  rfl

/-- ⭐⭐⭐ **THE `SLT` ROW OF `RegDatapathOK`, AT `r = rd`, BOTH ARMS DISCHARGED AND ALL
THIRTY-TWO BITS.** The enable is not a hypothesis: `core_writes_on_SLT` (landed) plus the `rd`
bridge give it.

⛔ **THIS IS ONE ROW (`r = rd`), NOT `RegDatapathOK`.** The obligation quantifies over all
thirty-two `r`; the rows `r ≠ rd` are the non-writers half and are not done here. -/
theorem regDatapath_SLT (ins : Env) {rd a b : Fin 32} (k : Nat) (hk : k < 32) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    (if run ins core.gates (rwOut rd.val) then run ins core.gates (selOut k)
     else ins (32 * rd.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  have hrdv : rdOf ins = rd.val := rdOf_is_rd_SLT ins rd a b h
  have hne : ¬ (rdOf ins = 0) := by
    rw [hrdv]; intro hz; exact hrd (Fin.ext (by simpa using hz))
  have hen : run ins core.gates (rwOut rd.val) = true := by
    rw [← hrdv]; exact core_writes_on_SLT ins rd a b h hne
  rw [hen, if_pos (by simp)]
  exact core_selOut_eq_isa_slt ins hrd k hk h

/-! ### the two SCOPED rows DERIVE BACK — so retiring them is safe

⚠️ *A truth-preserving restatement is still a breaking change.* These two say the landed
`SelValueSLT` statements are instances of the unscoped ones, so the seat can delete them
without checking their call sites for a shape mismatch. -/

/-- `SelValueSLT.core_selOut_eq_isa_slt_high`, derived: it is the unscoped row with an
unused `0 < k`. -/
theorem core_selOut_eq_isa_slt_high_derived (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk : k < 32) (_hk0 : 0 < k)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k :=
  core_selOut_eq_isa_slt ins hrd k hk h

/-- `SelValueSLT.regDatapath_slt_high`, derived: the unscoped row, with the enable taken
back as a HYPOTHESIS rather than discharged. -/
theorem regDatapath_slt_high_derived (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk : k < 32) (_hk0 : 0 < k)
    (h : decode (seenWord ins) = some (.SLT rd a b))
    (hen : run ins core.gates (rwOut rd.val) = true) :
    (if run ins core.gates (rwOut rd.val) then run ins core.gates (selOut k)
     else ins (32 * rd.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [hen, if_pos (by simp)]
  exact core_selOut_eq_isa_slt ins hrd k hk h

/-! ## 11 · ⛔ CONTROLS -/

/-- ⛔ **THE SIGN BIT, NOT THE CARRY-OUT — AT THE VALUE LEVEL.** `CorePlace.slt_reads_sign_not_carry`
says the two NETS differ; this says the two BITS differ, on a concrete pair. Had `sltSig 2` been
`subOut 32`, `sub_bit` would have delivered a different Boolean and every placement certificate
would still be green. -/
theorem sign_and_carry_differ_in_value :
    (SaltWorks.HDL.subOut 0x80000000 1).getD 31 false
      ≠ (SaltWorks.HDL.subOut 0x80000000 1).getD 32 false := by
  decide +kernel

/-- ⛔ **THE CLOSED STATEMENT'S RIGHT-HAND SIDE IS THE SIGNED ORDER.** `BitVec.slt` and
`BitVec.ult` disagree on `(0x80000000, 1)`, so `core_selOut_eq_isa_slt` at `k = 0` is not
satisfiable by an unsigned comparator. -/
theorem bit0_is_signed_not_unsigned :
    BitVec.slt (0x80000000 : BitVec 32) 1 = true
      ∧ BitVec.ult (0x80000000 : BitVec 32) 1 = false := by
  decide

/-- **NON-VACUITY: an `Env` whose seen word really does decode to an `SLT`.** -/
theorem slt_hypothesis_is_reachable :
    ∃ (ins : Env) (rd a b : Fin 32),
      decode (seenWord ins) = some (.SLT rd a b) := by
  refine ⟨fun n => (encode (.SLT 3 1 2)).getLsbD (n - instrBase), 3, 1, 2, ?_⟩
  have hw : seenWord
      (fun n => (encode (.SLT 3 1 2)).getLsbD (n - instrBase)) = encode (.SLT 3 1 2) := by
    apply BitVec.eq_of_getLsbD_eq_iff.mpr
    intro i hi
    rw [seenWord, wordOf_getLsbD _ _ hi]
    simp [instrNet]
  rw [hw, decode_encode]

/-! ## 12 · AXIOM AUDIT — one name per call, TICKS read, not absences -/

#audit_axioms not_bit
#audit_axioms tieTrue_at_cT9
#audit_axioms sub_env_agrees
#audit_axioms sub_bit
#audit_axioms drive0
#audit_axioms drive1
#audit_axioms drive2
#audit_axioms core_selOut_slt_bit0_closed
#audit_axioms decode_slt_regs
#audit_axioms rs1Of_is_get_a_SLT
#audit_axioms rs2Of_is_get_b_SLT
#audit_axioms stepT_SLT_regs
#audit_axioms cmpWord_bit0
#audit_axioms isa_slt_bit0
#audit_axioms core_selOut_eq_isa_slt_bit0
#audit_axioms core_selOut_eq_isa_slt
#audit_axioms rdOf_is_rd_SLT
#audit_axioms regDatapath_SLT
#audit_axioms core_selOut_eq_isa_slt_high_derived
#audit_axioms regDatapath_slt_high_derived
#audit_axioms sign_and_carry_differ_in_value
#audit_axioms bit0_is_signed_not_unsigned
#audit_axioms slt_hypothesis_is_reachable

/-! ## 13 · STATEMENT SHAPE, PRINTED -/

#check @core_selOut_slt_bit0_closed
#check @core_selOut_eq_isa_slt_bit0
#check @core_selOut_eq_isa_slt
#check @regDatapath_SLT
#check @core_selOut_eq_isa_slt_high_derived
#check @sub_bit
#check @not_bit

end SLTBit0

-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.bitNot32_nIn SaltWorks.HDL.RegNextUniform.SLTBit0.bitNot32_out_index
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.bitNot32_out_mem SaltWorks.HDL.RegNextUniform.SLTBit0.bitNot32_outs_len'
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.cT6_split5 SaltWorks.HDL.RegNextUniform.SLTBit0.cT9_split4
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.cT9_split5 SaltWorks.HDL.RegNextUniform.SLTBit0.cT9_split_add
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.cT9_split_not SaltWorks.HDL.RegNextUniform.SLTBit0.decode_slt_rd
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.notOut_eq SaltWorks.HDL.RegNextUniform.SLTBit0.notOut_lt_offOb
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.notOut_lt_offSelOr SaltWorks.HDL.RegNextUniform.SLTBit0.tail_selOr_add
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.rs1_at_cT9 SaltWorks.HDL.RegNextUniform.SLTBit0.rs2_at_cT6
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.rs2_at_cT9 SaltWorks.HDL.RegNextUniform.SLTBit0.run_cT6_to_cT5
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.run_cT9_to_cT5 SaltWorks.HDL.RegNextUniform.SLTBit0.run_cT9_to_cT8
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.run_cT9_to_notblk SaltWorks.HDL.RegNextUniform.SLTBit0.run_cT9_to_thru4
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.run_thru10_to_cT9 SaltWorks.HDL.RegNextUniform.SLTBit0.sltSig_0
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.sltSig_1 SaltWorks.HDL.RegNextUniform.SLTBit0.sltSig_2
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.subOut_eq SaltWorks.HDL.RegNextUniform.SLTBit0.subOut_lt_offSlt
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.tail4_9 SaltWorks.HDL.RegNextUniform.SLTBit0.tail5_9
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.tail_ob_add SaltWorks.HDL.RegNextUniform.SLTBit0.tail_xor
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.thru10_split_sub SaltWorks.HDL.RegNextUniform.SLTBit0.tieTrue_lt_off0
#audit_axioms SaltWorks.HDL.RegNextUniform.SLTBit0.tie_block_true
end SaltWorks.HDL.RegNextUniform
