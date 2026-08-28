/-
⚙️ REWIRED SCRATCH COPY of `SaltWorks/HDL/SelValueADD.lean` — executor deliverable, NOTHING TRACKED IS TOUCHED.

The 10 local helper copies listed below were DELETED and every use repointed at
`SaltWorks.HDL.RegNextUniform.Shared` (proved once in `ScratchQ4RDedupEx`):
  · addOut_eq
  · addOut_lt_offSub
  · adder32_out_mem
  · adder32_outs_len
  · obMux_out_mem
  · obMux_outs_len
  · obOut_eq
  · tieFalse_lt_off0
  · rdOf_is_decode_field
  · decode_add_rd

⛔ `coreThruRw_split5` is DELIBERATELY UNTOUCHED (its removal has real integration
cost — a local prefix `def` name — and is out of this brief's scope).

⚠️ This file declares the SAME fully-qualified names as `SaltWorks/HDL/SelValueADD.lean`; the two must
never enter one import graph.  Checked: nothing in this file's transitive closure
imports it (`SelValueSLTBit0` does, and is absent).
-/
/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Opus executor, queue item Q4 — ADD class)

# Q4 / ADD — the VALUE half of `RegDatapathOK`'s enable arm, and the row it completes

`core_selOut_transport` (EnableArm) says WHERE `selOut k` comes from. This file says WHAT IT
IS on a word the decoder reads as `ADD`, and then joins it to the LANDED enable.

```
selOut_value_ADD               run ins core.gates (selOut k) = (get a + get b).getLsbD k
selOut_is_isa_written_bit_ADD  … = ((stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k
regDatapath_ADD                `RegDatapathOK`'s OWN shape at r = rd, ENABLE DISCHARGED
```

**Every step is a transport of a landed organ theorem; no new arithmetic is proved here.**
```
core_selOut_transport          the placement              EnableArm
sliceASelect_cert_explicit     the 3-source select        SelectCut32
sel_nets_agree                 the two class lines        DecoderTransport
out_sem_obMux                  the operand-B mux          OperandBMux
sem_adder32_gen                the 32-bit addition        Stack/Program
rs1Of_is_St_get / rs2Of_…      the two read ports         Rs1Close / Rs2Close
rs1AddrOf_is_decode_field …    the address fields         Bridge3
core_writes_on_ADD             the enable                 DecoderTransport
```

⛔ **SCOPE — THREE FENCES, ALL LOAD-BEARING.**
① **ADD ONLY.** Nothing here is said about `XOR`/`SLT`/`ADDI`/`BEQ`, and `LW`/`SW` are out of
   scope behind Horn D (the model's memory is all-zero — a KNOWN open refutation).
② **`rd ≠ 0` IS LOAD-BEARING, NOT DECORATION.** `St.set` DISCARDS a write to `x0`, so at
   `rd = 0` the ISA writes nothing while `selOut` still carries `rs1 + rs2`;
   `stepT_ADD_regs_zero` below exhibits that. **The row is not a gap:** `core_rwOut0_false`
   puts `r = 0` in the HOLD arm, where `regDatapath_holds_at_zero` (C4Reduction) closes it.
③ **`regDatapath_ADD` IS ONE ROW (`r = rd`), NOT `RegDatapathOK`.** The obligation quantifies
   over all thirty-two `r`; the rows `r ≠ rd` need the enable proved FALSE there, which is the
   non-writers half and is NOT done here.

⚠️ **THE `rd` BRIDGE NO LONGER LIVES HERE.** `Bridge3` closed `rs1` and `rs2` and never the
DESTINATION field. That bridge is now `Shared.rdOf_is_decode_field`, proved once in
`ScratchQ4RDedupEx` and used from here.

⚠️ **NAME-COLLISION WARNING FOR THE SEAT.** Four concurrent Q4 executors write into
`SaltWorks.HDL.RegNextUniform`. This file nests everything in `ScratchQ4ADDEx`;
That collision class is what the `Shared` namespace retires: `obMux_outs_len`, `obOut_eq`,
`addOut_eq`, `adder32_outs_len`, `addOut_lt_offSub` and the rest are declared in NEITHER class
leaf now — they are `Shared.…` and there is one copy. **A duplicate qualified name is invisible
to a name grep, so the cure is to stop minting the second one.**

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.PcFieldClosed
import SaltWorks.HDL.SelValueShared

set_option maxRecDepth 100000

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

-- ⚠️ NESTED: see the collision warning in the module header.
namespace ADD

/-! ## 0 · the generic frame step -/

theorem run_drop (ins : Env) (P S : List Gate) (bnd : Nat) (n : Net)
    (hn : n < bnd) (hS : ∀ g ∈ S, bnd ≤ g.out) :
    run ins (P ++ S) n = run ins P n := by
  rw [run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => absurd (hEq ▸ hS g hg) (Nat.not_le.mpr hn))

theorem blk_ge (c : Circ) (σ : Net → Net) (off : Nat) (hssa : c.ssa = true)
    (bnd : Nat) (hb : bnd ≤ off) : ∀ g ∈ instGates c σ off, bnd ≤ g.out :=
  fun g hg => Nat.le_trans hb (instGates_out_range c σ off hssa g hg).1

/-! ## 1 · the prefixes this proof reads at -/

/-- The seven organ blocks before `obMux`. -/
def cT7 : List Gate :=
  instGates tieCells id offTie
    ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5

/-- …and those seven with `obMux` appended: the environment the ADD adder reads. -/
def cT8 : List Gate := cT7 ++ instGates OperandB.obMux obSig offOb

/-- The five blocks through the rs2 read port. -/
def cT5 : List Gate := coreThru4 ++ instGates readTree readTreeRs2Sig off3

theorem cT8_eq : cT8 = cT7 ++ instGates OperandB.obMux obSig offOb := rfl

theorem coreThruRw_split4 : coreThruRw = coreThru4 ++ coreRest10 := coreThruRw_split

theorem coreThruRw_split5 : coreThruRw = cT5 ++ coreRest9 := coreThruRw_split2

theorem cT7_split5 : cT7 = cT5
    ++ (instGates bitXor32 bitXor32Sig off4 ++ instGates bitNot32 bitNot32Sig off5) := by
  simp only [cT7, cT5, coreThru4, coreThru3, List.append_assoc]

theorem cT8_split4 : cT8 = coreThru4
    ++ (instGates readTree readTreeRs2Sig off3
        ++ instGates bitXor32 bitXor32Sig off4
        ++ instGates bitNot32 bitNot32Sig off5
        ++ instGates OperandB.obMux obSig offOb) := by
  simp only [cT8, cT7, coreThru4, coreThru3, List.append_assoc]

theorem cT8_split_tie : cT8 = instGates tieCells id offTie
    ++ (instGates decoder decoderSig off0
        ++ instGates immBCirc immBSig off1
        ++ instGates readTree readTreeRs1Sig off2
        ++ instGates readTree readTreeRs2Sig off3
        ++ instGates bitXor32 bitXor32Sig off4
        ++ instGates bitNot32 bitNot32Sig off5
        ++ instGates OperandB.obMux obSig offOb) := by
  simp only [cT8, cT7, List.append_assoc]

theorem coreThru11_split_add : coreThru11 = (cT8 ++ instGates adder32 addSig offAdd)
    ++ (instGates adder32 subSig offSub ++ instGates sltCirc sltSig offSlt) := by
  simp only [coreThru11, cT8, cT7, List.append_assoc]

theorem coreThru11_split7 : coreThru11 = cT7
    ++ (instGates OperandB.obMux obSig offOb
        ++ instGates adder32 addSig offAdd
        ++ instGates adder32 subSig offSub
        ++ instGates sltCirc sltSig offSlt) := by
  simp only [coreThru11, cT7, List.append_assoc]


/-! ## 2 · the offsets are monotone, and the nets sit under the right block -/

theorem off_le_0_1 : off0 ≤ off1 := by simp only [off1, instNext]; omega
theorem off_le_1_2 : off1 ≤ off2 := by simp only [off2, instNext]; omega
theorem off_le_2_3 : off2 ≤ off3 := by simp only [off3, instNext]; omega
theorem off_le_3_4 : off3 ≤ off4 := by simp only [off4, instNext]; omega
theorem off_le_4_5 : off4 ≤ off5 := by simp only [off5, instNext]; omega
theorem off_le_5_ob : off5 ≤ offOb := by simp only [offOb, instNext]; omega
theorem off_le_ob_add : offOb ≤ offAdd := by simp only [offAdd, instNext]; omega
theorem off_le_add_sub : offAdd ≤ offSub := by simp only [offSub, instNext]; omega
theorem off_le_sub_slt : offSub ≤ offSlt := by simp only [offSlt, instNext]; omega

theorem decOut_lt_offOb (j : Nat) (hj : j < 9) : decOut j < offOb := by
  revert j; decide +kernel

/-! ### the tails, block by block -/

theorem tail_after_thru4 : ∀ g ∈ (instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb), off3 ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h
  · exact blk_ge _ _ _ readTree_ssa off3 (Nat.le_refl _) g h
  · exact blk_ge _ _ _ bitXor32_ssa off3 off_le_3_4 g h
  · exact blk_ge _ _ _ bitNot32_ssa off3 (le_trans off_le_3_4 off_le_4_5) g h
  · exact blk_ge _ _ _ OperandB.ssa_obMux off3
      (le_trans off_le_3_4 (le_trans off_le_4_5 off_le_5_ob)) g h

theorem tail_after_cT5 : ∀ g ∈ (instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5), off4 ≤ g.out := by
  intro g hg
  simp only [List.mem_append] at hg
  rcases hg with h|h
  · exact blk_ge _ _ _ bitXor32_ssa off4 (Nat.le_refl _) g h
  · exact blk_ge _ _ _ bitNot32_ssa off4 off_le_4_5 g h

theorem tail_after_cT7 : ∀ g ∈ (instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt), offOb ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h
  · exact blk_ge _ _ _ OperandB.ssa_obMux offOb (Nat.le_refl _) g h
  · exact blk_ge _ _ _ adder32_ssa offOb off_le_ob_add g h
  · exact blk_ge _ _ _ adder32_ssa offOb (le_trans off_le_ob_add off_le_add_sub) g h
  · exact blk_ge _ _ _ sltCirc_ssa offOb
      (le_trans off_le_ob_add (le_trans off_le_add_sub off_le_sub_slt)) g h

theorem tail_after_add : ∀ g ∈ (instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt), offSub ≤ g.out := by
  intro g hg
  simp only [List.mem_append] at hg
  rcases hg with h|h
  · exact blk_ge _ _ _ adder32_ssa offSub (Nat.le_refl _) g h
  · exact blk_ge _ _ _ sltCirc_ssa offSub off_le_sub_slt g h

theorem tail_after_tie : ∀ g ∈ (instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb), off0 ≤ g.out := by
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  have h01 : off0 ≤ off1 := off_le_0_1
  have h02 : off0 ≤ off2 := le_trans h01 off_le_1_2
  have h03 : off0 ≤ off3 := le_trans h02 off_le_2_3
  have h04 : off0 ≤ off4 := le_trans h03 off_le_3_4
  have h05 : off0 ≤ off5 := le_trans h04 off_le_4_5
  have h0ob : off0 ≤ offOb := le_trans h05 off_le_5_ob
  rcases hg with h|h|h|h|h|h|h
  · exact blk_ge _ _ _ decoder_ssa off0 (Nat.le_refl _) g h
  · exact blk_ge _ _ _ immBCirc_ssa off0 h01 g h
  · exact blk_ge _ _ _ readTree_ssa off0 h02 g h
  · exact blk_ge _ _ _ readTree_ssa off0 h03 g h
  · exact blk_ge _ _ _ bitXor32_ssa off0 h04 g h
  · exact blk_ge _ _ _ bitNot32_ssa off0 h05 g h
  · exact blk_ge _ _ _ OperandB.ssa_obMux off0 h0ob g h


/-! ## 3 · the three reads the ADD adder needs, at the prefix that feeds it -/

theorem run_rw_to_thru4 (ins : Env) (n : Net) (hn : n < off3) :
    run ins coreThruRw n = run ins coreThru4 n := by
  rw [coreThruRw_split4]
  exact run_drop ins coreThru4 coreRest10 off3 n hn coreRest10_out_ge

theorem run_cT8_to_thru4 (ins : Env) (n : Net) (hn : n < off3) :
    run ins cT8 n = run ins coreThru4 n := by
  rw [cT8_split4]
  exact run_drop ins coreThru4 _ off3 n hn tail_after_thru4

theorem run_rw_to_cT5 (ins : Env) (n : Net) (hn : n < off4) :
    run ins coreThruRw n = run ins cT5 n := by
  rw [coreThruRw_split5]
  exact run_drop ins cT5 coreRest9 off4 n hn coreRest9_out_ge

theorem run_cT7_to_cT5 (ins : Env) (n : Net) (hn : n < off4) :
    run ins cT7 n = run ins cT5 n := by
  rw [cT7_split5]
  exact run_drop ins cT5 _ off4 n hn tail_after_cT5

theorem run_thru11_to_cT7 (ins : Env) (n : Net) (hn : n < offOb) :
    run ins coreThru11 n = run ins cT7 n := by
  rw [coreThru11_split7]
  exact run_drop ins cT7 _ offOb n hn tail_after_cT7

theorem run_thru11_to_add (ins : Env) (n : Net) (hn : n < offSub) :
    run ins coreThru11 n = run ins (cT8 ++ instGates adder32 addSig offAdd) n := by
  rw [coreThru11_split_add]
  exact run_drop ins _ _ offSub n hn tail_after_add

/-- ⭐ **THE rs1 BANK, AT THE ADDER'S OWN PREFIX.** `rs1Of` is stated at `coreThruRw`;
the adder reads it eight blocks earlier, and nothing in between writes it. -/
theorem rs1_at_cT8 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins cT8 (rs1Out j) = (rs1Of ins).getLsbD j := by
  have h1 : (rs1Of ins).getLsbD j = run ins coreThruRw (rs1Out j) := by
    rw [rs1Of, wordOf_getLsbD _ _ hj]
  rw [h1, run_rw_to_thru4 ins _ (rs1Out_lt_off3 j hj),
      run_cT8_to_thru4 ins _ (rs1Out_lt_off3 j hj)]

/-- ⭐ **THE rs2 BANK, AT `obMux`'s OWN PREFIX.** -/
theorem rs2_at_cT7 (ins : Env) (j : Nat) (hj : j < 32) :
    run ins cT7 (rs2Out j) = (rs2Of ins).getLsbD j := by
  have h1 : (rs2Of ins).getLsbD j = run ins coreThruRw (rs2Out j) := by
    rw [rs2Of, wordOf_getLsbD _ _ hj]
  rw [h1, run_rw_to_cT5 ins _ (rs2Out_lt_off4 j hj),
      run_cT7_to_cT5 ins _ (rs2Out_lt_off4 j hj)]

/-- The decoder's outputs, at `obMux`'s prefix, against `ctrlSpec`. -/
theorem decOut_cT7 (ins : Env) (j : Nat) (hj : j < 9) :
    run ins cT7 (decOut j) = (ctrlSpec (seenWord ins)).getD j false := by
  rw [← run_thru11_to_cT7 ins (decOut j) (decOut_lt_offOb j hj), ← decOut_thru11 ins j hj]
  exact core_decOut_spec ins j hj

/-! ### the carry-in really is a hard zero -/

theorem tie_block_false (ins : Env) :
    run ins (instGates tieCells id offTie) tieFalse = false := by
  have hg : instGates tieCells id offTie
      = [(⟨1088, Op.const false⟩ : Gate), (⟨1089, Op.const true⟩ : Gate)] := by
    decide +kernel
  have ht : tieFalse = 1088 := tie_nets_are_the_first_two.1
  rw [hg, ht]
  simp [upd, Op.eval]

theorem tieFalse_at_cT8 (ins : Env) : run ins cT8 tieFalse = false := by
  rw [cT8_split_tie, run_drop ins _ _ off0 tieFalse Shared.tieFalse_lt_off0 tail_after_tie]
  exact tie_block_false ins

/-! ## 4 · `obMux` DELIVERS `rs2` WHEN `isADDI` IS LOW -/

/-- ⭐⭐ **OPERAND B IS `rs2` ON EVERY NON-`ADDI` WORD.** The `sel` input of `obMux` is
`decOut 3` = `isADDI`; low, and the mux delivers its `a` bank, which `obSig` wires to the
`rs2` read port. *No fact about the immediate bank is used or needed.* -/
theorem ob_is_rs2 (ins : Env) (m : Nat) (hm : m < 32)
    (h3 : run ins cT7 (decOut isADDILine) = false) :
    run ins cT8 (CorePlace.obOut m) = run ins cT7 (rs2Out m) := by
  have hstep : run ins cT8 (CorePlace.obOut m)
      = run (fun a => run ins cT7 (obSig a)) OperandB.obMux.gates
          (OperandB.obMux.outs.getD m 0) := by
    rw [cT8_eq, Shared.obOut_eq m hm, run_append]
    exact inst_sem OperandB.obMux obSig offOb (run ins cT7)
      (fun a => run ins cT7 (obSig a)) ob_instOK (fun _ _ => rfl)
      (OperandB.obMux.outs.getD m 0) (Or.inr (Shared.obMux_out_mem m hm))
  have h := OperandB.out_sem_obMux (fun a => run ins cT7 (obSig a)) m hm
  simp only [sem] at h
  rw [getD_map_lt (run (fun a => run ins cT7 (obSig a)) OperandB.obMux.gates)
        OperandB.obMux.outs m (by rw [Shared.obMux_outs_len]; exact hm) 0 false] at h
  rw [hstep, h]
  have h64 : obSig 64 = decOut isADDILine := by simp [obSig]
  have hmm : obSig m = rs2Out m := by simp [obSig, hm]
  simp only [h64, hmm, h3]
  simp

/-! ## 5 · THE ADDER ADDS, IN PLACE -/

theorem adder32_nIn : adder32.nIn = 65 := by decide +kernel

/-- The ADD adder's 65 input wires, read at its own prefix, ARE `adEnv A B false`. -/
theorem add_env_agrees (ins : Env) (A B : BitVec 32)
    (hA : ∀ j, j < 32 → run ins cT8 (rs1Out j) = A.getLsbD j)
    (hB : ∀ j, j < 32 → run ins cT8 (CorePlace.obOut j) = B.getLsbD j) :
    ∀ i, i < adder32.nIn → run ins cT8 (addSig i) = adEnv A B false i := by
  intro i hi
  rw [adder32_nIn] at hi
  by_cases h1 : i < 32
  · rw [show addSig i = rs1Out i from by simp [addSig, h1], hA i h1]
    show _ = (if i < 32 then A.getLsbD i else if i < 64 then B.getLsbD (i - 32) else false)
    rw [if_pos h1]
  · by_cases h2 : i < 64
    · rw [show addSig i = CorePlace.obOut (i - 32) from by simp [addSig, h1, h2],
          hB (i - 32) (by omega)]
      show _ = (if i < 32 then A.getLsbD i else if i < 64 then B.getLsbD (i - 32) else false)
      rw [if_neg h1, if_pos h2]
    · have hi64 : i = 64 := by omega
      subst hi64
      rw [show addSig 64 = tieFalse from by simp [addSig], tieFalse_at_cT8 ins]
      show _ = (if (64 : Nat) < 32 then A.getLsbD 64
                else if (64 : Nat) < 64 then B.getLsbD (64 - 32) else false)
      simp

theorem setWidth_ofBool_false : BitVec.setWidth 32 (BitVec.ofBool false) = (0 : BitVec 32) := by
  decide

/-- ⭐⭐ **THE ADD ADDER'S OUTPUT BIT `k`, READ INSIDE `core`, IS BIT `k` OF `A + B`.**
`sem_adder32_gen` is math's landed certificate; this is it, transported onto the placement. -/
theorem add_bit (ins : Env) (A B : BitVec 32) (k : Nat) (hk : k < 32)
    (hA : ∀ j, j < 32 → run ins cT8 (rs1Out j) = A.getLsbD j)
    (hB : ∀ j, j < 32 → run ins cT8 (CorePlace.obOut j) = B.getLsbD j) :
    run ins coreThru11 (CorePlace.addOut k) = (A + B).getLsbD k := by
  rw [run_thru11_to_add ins _ (Shared.addOut_lt_offSub k hk), Shared.addOut_eq k hk, run_append,
      inst_sem adder32 addSig offAdd (run ins cT8) (adEnv A B false) add_instOK
        (add_env_agrees ins A B hA hB) (adder32.outs.getD k 0)
        (Or.inr (Shared.adder32_out_mem k hk))]
  have h : (sem adder32 (adEnv A B false)).getD k false
      = (A + B + BitVec.setWidth 32 (BitVec.ofBool false)).getLsbD k := by
    rw [sem_adder32_gen]
    exact getD_of_range_append _ _ k hk
  simp only [sem] at h
  rw [getD_map_lt (run (adEnv A B false) adder32.gates) adder32.outs k
        (by rw [Shared.adder32_outs_len]; omega) 0 false] at h
  rw [h, setWidth_ofBool_false]
  simp


/-! ## 6 · THE SELECT PICKS BANK 0 WHEN NEITHER `isXOR` NOR `isSLT` IS SET -/

theorem gsSel_3_2_0 : gsSel 3 2 0 = 96 := by decide +kernel
theorem gsSel_3_2_1 : gsSel 3 2 1 = 97 := by decide +kernel
theorem gsRes_0 (k : Nat) : gsRes 0 k = k := by simp [gsRes]
theorem selSig_low (k : Nat) (hk : k < 32) : selSig k = CorePlace.addOut k := by
  simp [selSig, hk]

/-- ⭐⭐ **THE OUTPUT SELECT DELIVERS THE ADD ADDER'S BANK.** Both class lines low ⇒
`gsSelOf = 0` ⇒ `sliceASelect_selects` names source 0, which `selSig` wires to `addOut`. -/
theorem sel_is_add_bank (ins : Env) (k : Nat) (hk : k < 32)
    (h1 : run ins coreThru11 (decOut isXORLine) = false)
    (h2 : run ins coreThru11 (decOut isSLTLine) = false) :
    run ins core.gates (selOut k) = run ins coreThru11 (CorePlace.addOut k) := by
  have hE0 : run ins coreThru11 (selSig (gsSel 3 2 0)) = false := by
    rw [gsSel_3_2_0, selSig_96]; exact h1
  have hE1 : run ins coreThru11 (selSig (gsSel 3 2 1)) = false := by
    rw [gsSel_3_2_1, selSig_97]; exact h2
  have hsel0 : gsSelOf 3 2 (fun a => run ins coreThru11 (selSig a)) = 0 := by
    simp [SelectCut32.sliceASelOf, hE0, hE1]
  have hs := SelectCut32.sliceASelect_selects (fun a => run ins coreThru11 (selSig a))
    (by rw [hsel0]; omega)
  rw [hsel0] at hs
  have hleft : run (fun a => run ins coreThru11 (selSig a)) SelectCut32.sliceASelect.gates
        (SelectCut32.sliceASelect.outs.getD k 0)
      = (sem SelectCut32.sliceASelect (fun a => run ins coreThru11 (selSig a))).getD k false := by
    simp only [sem]
    exact (getD_map_lt _ _ _ (by rw [sliceASelect_outs_len]; exact hk) 0 false).symm
  rw [core_selOut_transport ins k hk, hleft, hs,
      getD_map_lt _ _ _ (show k < (List.range 32).length from by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk]]
  show run ins coreThru11 (selSig (gsRes 0 k)) = _
  rw [gsRes_0, selSig_low k hk]

/-! ## 7 · THE ISA SIDE — decode's register fields, and `ctrlSpec`'s ADD row -/

theorem decode_add_regs (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.ADD rd a b)) :
    rd = toReg (w.extractLsb' 7 5) ∧ a = toReg (w.extractLsb' 15 5)
      ∧ b = toReg (w.extractLsb' 20 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

theorem rs1Of_is_get_a_ADD (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) : rs1Of ins = (decQ ins).get a := by
  rw [rs1Of_is_St_get]
  congr 1
  have ha := (decode_add_regs _ rd a b h).2.1
  apply Fin.ext
  show rs1AddrOf ins = a.val
  rw [ha, ← rs1AddrOf_is_decode_field ins]
  rfl

theorem rs2Of_is_get_b_ADD (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) : rs2Of ins = (decQ ins).get b := by
  rw [rs2Of_is_St_get]
  congr 1
  have hb := (decode_add_regs _ rd a b h).2.2
  apply Fin.ext
  show rs2AddrOf ins = b.val
  rw [hb, ← rs2AddrOf_is_decode_field ins]
  rfl

theorem ctrlSpec_add (w : BitVec 32) (rd a b : Fin 32) (h : decode w = some (.ADD rd a b)) :
    ctrlSpec w = [true, false, false, false, false, false, false, false, true] := by
  simp [ctrlSpec, h]

/-! ## 8 · ⭐⭐⭐ THE VALUE ARM FOR THE ADD CLASS -/

/-- ⭐⭐⭐ **`selOut k` IS BIT `k` OF `rs1 + rs2` ON EVERY WORD THE DECODER READS AS `ADD`.**
No hypothesis on `rd`: this is the ALU's value, not yet the ISA's write. -/
theorem selOut_value_ADD (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (selOut k)
      = ((decQ ins).get a + (decQ ins).get b).getLsbD k := by
  have hc := ctrlSpec_add (seenWord ins) rd a b h
  have hd1 : run ins cT7 (decOut isXORLine) = false := by rw [decOut_cT7 ins isXORLine (by decide +kernel), hc]; rfl
  have hd2 : run ins cT7 (decOut isSLTLine) = false := by rw [decOut_cT7 ins isSLTLine (by decide +kernel), hc]; rfl
  have hd3 : run ins cT7 (decOut isADDILine) = false := by rw [decOut_cT7 ins isADDILine (by decide +kernel), hc]; rfl
  have hd1' : run ins coreThru11 (decOut isXORLine) = false := by
    rw [run_thru11_to_cT7 ins _ (decOut_lt_offOb isXORLine (by decide +kernel))]; exact hd1
  have hd2' : run ins coreThru11 (decOut isSLTLine) = false := by
    rw [run_thru11_to_cT7 ins _ (decOut_lt_offOb isSLTLine (by decide +kernel))]; exact hd2
  have hB : ∀ j, j < 32 → run ins cT8 (CorePlace.obOut j) = (rs2Of ins).getLsbD j := by
    intro j hj
    rw [ob_is_rs2 ins j hj hd3, rs2_at_cT7 ins j hj]
  rw [sel_is_add_bank ins k hk hd1' hd2',
      add_bit ins (rs1Of ins) (rs2Of ins) k hk (rs1_at_cT8 ins) hB,
      rs1Of_is_get_a_ADD ins rd a b h, rs2Of_is_get_b_ADD ins rd a b h]

/-- The ISA's ADD write, read back at `rd`. **`rd ≠ 0` is load-bearing** — `St.set`
DISCARDS a write to `x0`. -/
theorem stepT_ADD_regs (ins : Env) (rd a b : Fin 32) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val])
      = (decQ ins).get a + (decQ ins).get b := by
  have hstep : SaltWorks.ISA.stepT (decQ ins) (seenWord ins)
      = ((decQ ins).set rd ((decQ ins).get a + (decQ ins).get b)).next := by
    simp [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW, h, SaltWorks.ISA.step]
  rw [hstep]
  simp [St.next, St.set, hrd]

/-- ⭐⭐⭐ **Q4 (ADD) — THE ENABLE ARM'S VALUE HALF, FOR THE ADD CLASS.** -/
theorem selOut_is_isa_written_bit_ADD (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32)
    (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [selOut_value_ADD ins rd a b k hk h, stepT_ADD_regs ins rd a b hrd h]

/-! ## 9 · TWO CONTROLS -/

/-- ⛔ **WHY `rd ≠ 0` IS NOT COSMETIC.** At `rd = 0` the ISA writes NOTHING, while the
circuit's `selOut` still carries `rs1 + rs2`; the two disagree whenever that sum differs
from the held bit. The row is not a gap: `core_rwOut0_false` puts `RegDatapathOK` at `r = 0`
in its HOLD arm, where `regDatapath_holds_at_zero` already closes it. -/
theorem stepT_ADD_regs_zero (ins : Env) (a b : Fin 32)
    (h : decode (seenWord ins) = some (.ADD 0 a b)) :
    (SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[(0 : Nat)]
      = (decQ ins).regs[(0 : Nat)] := by
  have hstep : SaltWorks.ISA.stepT (decQ ins) (seenWord ins)
      = ((decQ ins).set 0 ((decQ ins).get a + (decQ ins).get b)).next := by
    simp [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW, h, SaltWorks.ISA.step]
  rw [hstep]
  simp [St.next, St.set]

/-- **NON-VACUITY: an `Env` whose seen word really does decode to an `ADD`.** -/
theorem add_hypothesis_is_reachable :
    ∃ (ins : Env) (rd a b : Fin 32),
      decode (seenWord ins) = some (.ADD rd a b) := by
  refine ⟨fun n => (encode (.ADD 3 1 2)).getLsbD (n - instrBase), 3, 1, 2, ?_⟩
  have hw : seenWord
      (fun n => (encode (.ADD 3 1 2)).getLsbD (n - instrBase)) = encode (.ADD 3 1 2) := by
    apply BitVec.eq_of_getLsbD_eq_iff.mpr
    intro i hi
    rw [seenWord, wordOf_getLsbD _ _ hi]
    simp [instrNet]
  rw [hw, decode_encode]

#audit_axioms run_drop
#audit_axioms rs1_at_cT8
#audit_axioms rs2_at_cT7
#audit_axioms decOut_cT7
#audit_axioms tieFalse_at_cT8
#audit_axioms ob_is_rs2
#audit_axioms add_env_agrees
#audit_axioms add_bit
#audit_axioms sel_is_add_bank
#audit_axioms decode_add_regs
#audit_axioms rs1Of_is_get_a_ADD
#audit_axioms rs2Of_is_get_b_ADD
#audit_axioms ctrlSpec_add
#audit_axioms selOut_value_ADD
#audit_axioms stepT_ADD_regs
#audit_axioms selOut_is_isa_written_bit_ADD
#audit_axioms stepT_ADD_regs_zero
#audit_axioms add_hypothesis_is_reachable

/-! ## 10 · ⭐ THE ENABLE, TOO — the `rd` bridge `Bridge3` did not carry

`Bridge3` closed `rs1` and `rs2`; the destination field was never bridged, because the pc path
did not need it. The enable arm does: `core_writes_on_ADD` is stated at `rdOf ins`, and the
obligation is stated at `rd.val`. **One more bridge of exactly `Bridge3`'s shape joins them,
and then BOTH arms of `RegDatapathOK`'s `ADD` row are discharged rather than assumed.** -/

theorem rdOf_is_rd_ADD (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) : rdOf ins = rd.val := by
  rw [← Shared.rdOf_is_decode_field ins, Shared.decode_add_rd _ rd a b h]
  rfl

/-- ⭐⭐⭐ **THE `ADD` ROW OF `RegDatapathOK`, IN ITS OWN SHAPE, WITH THE ENABLE DISCHARGED.**
The enable is not a hypothesis here: `core_writes_on_ADD` (landed) says the circuit writes the
register `ADD` names, and the `rd` bridge above says that register is `decode`'s `rd`.

⛔ **THIS IS ONE ROW (`r = rd`), NOT `RegDatapathOK`.** The obligation quantifies over all
thirty-two `r`; the rows `r ≠ rd` need the enable to be proved FALSE there, which is the
non-writers half and is not done here. -/
theorem regDatapath_ADD (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32) (hrd : rd ≠ 0)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    (if run ins core.gates (rwOut rd.val) then run ins core.gates (selOut k)
     else ins (32 * rd.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  have hrdv : rdOf ins = rd.val := rdOf_is_rd_ADD ins rd a b h
  have hne : ¬ (rdOf ins = 0) := by
    rw [hrdv]
    intro hz
    apply hrd
    apply Fin.ext
    simpa using hz
  have hen : run ins core.gates (rwOut rd.val) = true := by
    rw [← hrdv]
    exact core_writes_on_ADD ins rd a b h hne
  rw [hen, if_pos (by simp)]
  exact selOut_is_isa_written_bit_ADD ins rd a b k hk hrd h

#audit_axioms Shared.rdOf_is_decode_field
#audit_axioms Shared.decode_add_rd
#audit_axioms rdOf_is_rd_ADD
#audit_axioms regDatapath_ADD


end ADD

-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.adder32_nIn SaltWorks.HDL.RegNextUniform.ADD.blk_ge
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.cT7_split5 SaltWorks.HDL.RegNextUniform.ADD.cT8_eq
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.cT8_split4 SaltWorks.HDL.RegNextUniform.ADD.cT8_split_tie
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.coreThru11_split7 SaltWorks.HDL.RegNextUniform.ADD.coreThru11_split_add
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.coreThruRw_split4 SaltWorks.HDL.RegNextUniform.ADD.coreThruRw_split5
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.decOut_lt_offOb SaltWorks.HDL.RegNextUniform.ADD.gsRes_0
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.gsSel_3_2_0 SaltWorks.HDL.RegNextUniform.ADD.gsSel_3_2_1
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.off_le_0_1 SaltWorks.HDL.RegNextUniform.ADD.off_le_1_2
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.off_le_2_3 SaltWorks.HDL.RegNextUniform.ADD.off_le_3_4
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.off_le_4_5 SaltWorks.HDL.RegNextUniform.ADD.off_le_5_ob
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.off_le_add_sub SaltWorks.HDL.RegNextUniform.ADD.off_le_ob_add
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.off_le_sub_slt SaltWorks.HDL.RegNextUniform.ADD.run_cT7_to_cT5
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.run_cT8_to_thru4 SaltWorks.HDL.RegNextUniform.ADD.run_rw_to_cT5
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.run_rw_to_thru4 SaltWorks.HDL.RegNextUniform.ADD.run_thru11_to_add
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.run_thru11_to_cT7 SaltWorks.HDL.RegNextUniform.ADD.selSig_low
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.setWidth_ofBool_false SaltWorks.HDL.RegNextUniform.ADD.tail_after_add
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.tail_after_cT5 SaltWorks.HDL.RegNextUniform.ADD.tail_after_cT7
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.tail_after_thru4 SaltWorks.HDL.RegNextUniform.ADD.tail_after_tie
#audit_axioms SaltWorks.HDL.RegNextUniform.ADD.tie_block_false
end SaltWorks.HDL.RegNextUniform
