/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Q4 executor, SLT class)

# Q4 / SLT — the VALUE half of `RegDatapathOK`'s enable arm, for the SLT class

SCOPE, stated first because the class is asymmetric: `SLT` writes `1` or `0`, so
**thirty-one of the thirty-two written bits are constant zero and exactly one is data.**
This file closes the thirty-one and states the wall at the one.
-/
import SaltWorks.HDL.DecoderTransport

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

namespace SLT

/-! ## 1. The ten organs before `sltCirc`, and the `sltCirc` block itself -/

def coreThru10 : List Gate :=
  instGates tieCells id offTie
    ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub

theorem coreThru11_split :
    coreThru11 = coreThru10 ++ instGates sltCirc sltSig offSlt := by
  simp only [coreThru11, coreThru10, List.append_assoc]

/-! ## 2. `sltCirc`'s broadcast: outputs 1…31 are ONE constant-false net -/

theorem sltCirc_outs_len' : sltCirc.outs.length = 32 := by decide +kernel

theorem sltCirc_outs_high (k : Nat) (hk : k < 32) (hk0 : 0 < k) :
    sltCirc.outs.getD k 0 = 7 := by
  revert hk0; revert hk; revert k; decide +kernel

theorem sltOut_high_net (k : Nat) (hk : k < 32) (hk0 : 0 < k) :
    sltOut k = instMap sltCirc sltSig offSlt 7 := by
  rw [sltOut, instOuts,
      getD_map_lt _ _ _ (by rw [sltCirc_outs_len']; exact hk) 0 0,
      sltCirc_outs_high k hk hk0]

theorem instMap_slt_seven : instMap sltCirc sltSig offSlt 7 = offSlt + 4 := by
  decide +kernel

/-- The `sltCirc` block's net for outputs 1…31 is written by its LAST gate, a
`const false`. -/
theorem run_slt_block_high (env : Env) :
    run env (instGates sltCirc sltSig offSlt) (offSlt + 4) = false := by
  simp [instGates, sltCirc, instMap, Op.rename, Op.eval, upd]

theorem coreThru11_sltOut_high (ins : Env) (k : Nat) (hk : k < 32) (hk0 : 0 < k) :
    run ins coreThru11 (sltOut k) = false := by
  rw [coreThru11_split, run_append, sltOut_high_net k hk hk0, instMap_slt_seven]
  exact run_slt_block_high _

/-! ## 3. The select routes bank 2 under an SLT word -/

theorem ctrlSpec_slt_bits {w : BitVec 32} {rd a b : Fin 32}
    (h : decode w = some (.SLT rd a b)) :
    (ctrlSpec w).getD 1 false = false ∧ (ctrlSpec w).getD 2 false = true := by
  constructor <;> simp [ctrlSpec, h]

theorem sel_nets_slt (ins : Env) {rd a b : Fin 32}
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins coreThru11 (selSig 96) = false ∧ run ins coreThru11 (selSig 97) = true := by
  obtain ⟨h0, h1⟩ := sel_nets_agree ins
  obtain ⟨c1, c2⟩ := ctrlSpec_slt_bits h
  simp only [gsSel0_is_96, gsSel1_is_97] at h0 h1
  exact ⟨h0.trans c1, h1.trans c2⟩

theorem selSig_bank2 (k : Nat) (hk : k < 32) : selSig (gsRes 2 k) = sltOut k := by
  have he : gsRes 2 k = 64 + k := by simp [gsRes]
  rw [he]
  have h1 : ¬ ((64 + k : Nat) < 32) := by omega
  have h2 : ¬ ((64 + k : Nat) < 64) := by omega
  have h3 : (64 + k : Nat) < 96 := by omega
  have h4 : (64 + k : Nat) - 64 = k := by omega
  simp only [selSig, if_neg h1, if_neg h2, if_pos h3, h4]

/-- ⭐⭐ **THE SELECT DELIVERS `sltCirc`'s BANK ON AN `SLT` WORD — all 32 ports.** -/
theorem core_selOut_is_slt_bank (ins : Env) {rd a b : Fin 32} (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut k) = run ins coreThru11 (sltOut k) := by
  obtain ⟨hs0, hs1⟩ := sel_nets_slt ins h
  set E : Env := fun n => run ins coreThru11 (selSig n) with hE
  have h96 : E (gsSel 3 2 0) = false := hs0
  have h97 : E (gsSel 3 2 1) = true := hs1
  have hcert := SelectCut32.sliceASelect_cert_explicit E
  have hport : (sem SelectCut32.sliceASelect E).getD k false = E (gsRes 2 k) := by
    rw [hcert]
    rw [List.getD_eq_getElem?_getD, List.getElem?_map, List.getElem?_range hk]
    simp [h96, h97]
  have htrans := core_selOut_transport ins k hk
  have hmap : (sem SelectCut32.sliceASelect E).getD k false
      = run E SelectCut32.sliceASelect.gates (SelectCut32.sliceASelect.outs.getD k 0) := by
    simp only [sem]
    exact getD_map_lt _ _ _ (by rw [sliceASelect_outs_len]; exact hk) 0 false
  rw [htrans, ← hmap, hport, hE]
  exact congrArg (run ins coreThru11) (selSig_bank2 k hk)

/-! ## 4. The ISA side: `SLT` writes `1` or `0`, so bits 1…31 are zero -/

theorem cmpWord_high_bit (c : Bool) (k : Nat) (hk0 : 0 < k) :
    (if c then (1 : BitVec 32) else 0).getLsbD k = false := by
  have hk : ¬ (k = 0) := by omega
  cases c <;> simp [BitVec.getLsbD_one, hk]

theorem isa_slt_high_bit (s : St) (w : BitVec 32) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk0 : 0 < k) (h : decode w = some (.SLT rd a b)) :
    ((stepT s w).regs[rd.val]).getLsbD k = false := by
  rw [stepT_compat s w (step s (.SLT rd a b)) (by simp [stepW, h])]
  show (((s.set rd (if (s.get a).slt (s.get b) then 1 else 0)).next).regs[rd.val]).getLsbD k
      = false
  simp only [St.next, St.set, if_neg hrd]
  rw [Vector.getElem_set_self]
  exact cmpWord_high_bit _ k hk0

/-! ## 5. ⭐⭐⭐ THE VALUE, BITS 1…31 -/

/-- ⭐⭐⭐ **THE `SLT` VALUE ARM AT BITS 1…31.** On a word the decoder reads as
`SLT rd a b` with `rd ≠ x0`, the select's output bit `k` for every `1 ≤ k < 32` is
`false`, and that is exactly the ISA's written bit. -/
theorem core_selOut_eq_isa_slt_high (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk : k < 32) (hk0 : 0 < k)
    (h : decode (seenWord ins) = some (.SLT rd a b)) :
    run ins core.gates (selOut k)
      = ((stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [core_selOut_is_slt_bank ins k hk h, coreThru11_sltOut_high ins k hk hk0,
      isa_slt_high_bit (decQ ins) (seenWord ins) hrd k hk0 h]

/-- The same sentence in `RegDatapathOK`'s own shape, at `r = rd`. The enable is a
HYPOTHESIS: this file proves the VALUE half only. -/
theorem regDatapath_slt_high (ins : Env) {rd a b : Fin 32} (hrd : rd ≠ 0)
    (k : Nat) (hk : k < 32) (hk0 : 0 < k)
    (h : decode (seenWord ins) = some (.SLT rd a b))
    (hen : run ins core.gates (rwOut rd.val) = true) :
    (if run ins core.gates (rwOut rd.val) then run ins core.gates (selOut k)
     else ins (32 * rd.val + k))
      = ((stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [hen, if_pos (by simp)]
  exact core_selOut_eq_isa_slt_high ins hrd k hk hk0 h

/-! ## 6. ⭐ BIT 0 — reduced to the THREE DRIVE NETS, comparator function CLOSED

`sem_sltCirc` (Program.lean) settles what the comparator computes from its three inputs, for
all eight valuations, and `sltDrive_uncond` settles that the sign formula IS `BitVec.slt` for
all 2^64 operand pairs. **Both are ORGAN theorems.** What is missing at bit 0 is therefore
neither of those: it is the CORE-SIDE transport of the three nets `sltSig 0/1/2` — `rs1Out 31`,
`rs2Out 31` and the SUBTRACTING adder's `subOut 31` — through the first TEN organs. Those three
hypotheses are stated explicitly below so the remaining obligation is one named thing. -/

/-- `sltOut 0` inside `core` IS `sltCirc`'s own output net 6, on the ten organs' drive. -/
theorem coreThru11_sltOut_zero (ins : Env) :
    run ins coreThru11 (sltOut 0)
      = run (fun j => run ins coreThru10 (sltSig j)) sltCirc.gates 6 := by
  rw [coreThru11_split, run_append]
  have hz : sltOut 0 = instMap sltCirc sltSig offSlt 6 := by
    rw [sltOut, instOuts, getD_map_lt _ _ _ (by rw [sltCirc_outs_len']; omega) 0 0,
        show sltCirc.outs.getD 0 0 = 6 from by decide +kernel]
  rw [hz]
  exact inst_sem sltCirc sltSig offSlt (run ins coreThru10)
      (fun j => run ins coreThru10 (sltSig j)) slt_instOK (fun _ _ => rfl) 6
      (Or.inr (by decide +kernel))

/-- `sltCirc`'s output net 6 as a function of its three input nets ONLY — the block reads
nothing else, so an arbitrary host environment agreeing at nets 0, 1, 2 gives the same bit. -/
theorem sltCirc_out6_eq (env : Env) (x31 y31 s31 : Bool)
    (h0 : env 0 = x31) (h1 : env 1 = y31) (h2 : env 2 = s31) :
    run env sltCirc.gates 6 = (s31 ^^ ((x31 ^^ y31) && (x31 ^^ s31))) := by
  have hag : run env sltCirc.gates 6
      = run (fun i => if i == 0 then x31 else if i == 1 then y31 else s31)
          sltCirc.gates 6 := by
    refine run_agree_of_inputs_circ sltCirc sltCirc_ssa _ _ ?_ 6 (by decide +kernel)
    intro a ha
    have hnn : sltCirc.nIn = 3 := by decide +kernel
    rw [hnn] at ha
    match a, ha with
    | 0, _ => simpa using h0
    | 1, _ => simpa using h1
    | 2, _ => simpa using h2
    | (n+3), hh => exact absurd hh (by omega)
  rw [hag]
  have hport : List.getD
        (sem sltCirc (fun i => if i == 0 then x31 else if i == 1 then y31 else s31)) 0 false
      = run (fun i => if i == 0 then x31 else if i == 1 then y31 else s31) sltCirc.gates 6 := by
    simp only [sem]
    rw [getD_map_lt _ _ _ (by rw [sltCirc_outs_len']; omega) 0 false,
        show sltCirc.outs.getD 0 0 = 6 from by decide +kernel]
  rw [← hport, SaltWorks.Stack.Program.sem_sltCirc x31 y31 s31]
  rfl

set_option maxRecDepth 40000 in
/-- ⭐⭐⭐ **BIT 0 OF THE `SLT` VALUE, MODULO THE THREE DRIVE NETS.** Given that the three nets
`sltCirc` reads inside `core` carry `x`'s sign, `y`'s sign and the sign bit of `x - y`, the
select's bit 0 is `BitVec.slt x y` — the ISA's own comparison.

⛔ **THE THREE HYPOTHESES ARE THE WALL, AND THEY ARE NOT DISCHARGED HERE.** They are the
`readTree` / `bitNot32` / `adder32` transports onto the first TEN organs. -/
theorem core_selOut_slt_bit0 (ins : Env) {rd a b : Fin 32} (x y : BitVec 32)
    (h : decode (seenWord ins) = some (.SLT rd a b))
    (hx : run ins coreThru10 (sltSig 0) = x.getLsbD 31)
    (hy : run ins coreThru10 (sltSig 1) = y.getLsbD 31)
    (hs : run ins coreThru10 (sltSig 2) = (SaltWorks.HDL.subOut x y).getD 31 false) :
    run ins core.gates (selOut 0) = BitVec.slt x y := by
  rw [core_selOut_is_slt_bank ins 0 (by omega) h, coreThru11_sltOut_zero ins,
      sltCirc_out6_eq _ (x.getLsbD 31) (y.getLsbD 31)
        ((SaltWorks.HDL.subOut x y).getD 31 false) hx hy hs]
  have h3 := (SaltWorks.Stack.Program.sltDrive_eq_sign_formula x y).symm.trans
    (SaltWorks.Stack.Program.sltDrive_uncond x y)
  simpa [SaltWorks.HDL.cmpWord] using congrArg (fun l => l.getD 0 false) h3

/-! ## 7. ⛔ THE FENCE — bit 0 is NOT covered, and it is not covered for a REASON -/

/-- ⛔ **BIT 0 IS DATA-DEPENDENT AT THE PLACED BLOCK.** Two valuations of the three
`sltCirc` input nets, one output net, two different answers — so no constant-value
theorem of the shape proved above can reach `k = 0`. *This is the control that stops
the thirty-one-bit result being read as a thirty-two-bit one.* -/
theorem slt_bit0_is_not_constant :
    run (fun _ => false) (instGates sltCirc sltSig offSlt) (sltOut 0) = false
  ∧ run (fun n => decide (n = sltSig 2)) (instGates sltCirc sltSig offSlt) (sltOut 0)
      = true := by
  decide +kernel

#audit_axioms coreThru11_split
#audit_axioms sltCirc_outs_high
#audit_axioms sltOut_high_net
#audit_axioms run_slt_block_high
#audit_axioms coreThru11_sltOut_high
#audit_axioms ctrlSpec_slt_bits
#audit_axioms sel_nets_slt
#audit_axioms selSig_bank2
#audit_axioms core_selOut_is_slt_bank
#audit_axioms cmpWord_high_bit
#audit_axioms isa_slt_high_bit
#audit_axioms core_selOut_eq_isa_slt_high
#audit_axioms regDatapath_slt_high
#audit_axioms coreThru11_sltOut_zero
#audit_axioms sltCirc_out6_eq
#audit_axioms core_selOut_slt_bit0
#audit_axioms slt_bit0_is_not_constant

/-! ## 8. STATEMENT SHAPE, PRINTED — `^^` binds TIGHTER than `=`

⚠️ **A LIVE TRAP CAUGHT HERE.** `run env gs 6 = s31 ^^ f` parses as `(decide (run env gs 6 = s31)) ^^ f`,
which elaborates, type-checks, and states something else entirely. The statements are printed so a
reader checks the INTERFACE rather than the name. -/

#check @core_selOut_is_slt_bank
#check @coreThru11_sltOut_high
#check @isa_slt_high_bit
#check @core_selOut_eq_isa_slt_high
#check @regDatapath_slt_high
#check @sltCirc_out6_eq
#check @core_selOut_slt_bit0
#check @slt_bit0_is_not_constant

end SLT

-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.SLT.instMap_slt_seven SaltWorks.HDL.RegNextUniform.SLT.sltCirc_outs_len'
end SaltWorks.HDL.RegNextUniform
