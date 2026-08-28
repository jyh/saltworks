/-
Q4 executor scratch — the ENABLE ARM's VALUE half for the XOR class.

Target: under `decode (seenWord ins) = some (.XOR rd a b)`, say what
`run ins core.gates (selOut k)` IS.

Route (all bricks already landed; nothing here re-proves a block):
  core_selOut_transport   EnableArm     selOut k  ↦  sliceASelect's own output k
  sliceASelect_cert       SelectCut32   the select block, ∀ Env
  sel_nets_agree          DecoderTr.    the two select nets carry ctrlSpec[1], ctrlSpec[2]
  bitXor32_sem            SingleLevel   ⭐ THE UNIVERSAL XOR CERTIFICATE, ∀ env
  rs1Of_is_St_get         Rs1Close      the rs1 port IS St.get
  rs2Of_is_St_get         Rs2Close      the rs2 port IS St.get
  rs1/rs2AddrOf_is_decode_field  Bridge3 the addresses ARE decode's fields
-/
import SaltWorks.HDL.DecoderTransport
import SaltWorks.HDL.Rs2Close
import SaltWorks.HDL.Bridge3
import SaltWorks.HDL.SingleLevel

namespace SaltWorks.HDL.RegNextUniform.XOR
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-! ## ① `selOut k`, unfolded to the select block's own arms -/

/-- The value at port `k`, with the select block's spec spelled out on the eleven-organ
environment. No hypothesis on the decoder — this is `core_selOut_transport` cashed against
`sliceASelect_cert`. -/
theorem core_selOut_arms (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (selOut k)
      = (if run ins coreThru11 (selSig (gsSel 3 2 1))
         then (if run ins coreThru11 (selSig (gsSel 3 2 0)) then false
               else run ins coreThru11 (selSig (gsRes 2 k)))
         else (if run ins coreThru11 (selSig (gsSel 3 2 0))
               then run ins coreThru11 (selSig (gsRes 1 k))
               else run ins coreThru11 (selSig (gsRes 0 k)))) := by
  rw [core_selOut_transport ins k hk]
  have hs := congrArg (fun l : List Bool => l.getD k false)
    (SelectCut32.sliceASelect_cert_explicit (fun a => run ins coreThru11 (selSig a)))
  simp only [sem] at hs
  rw [getD_map_lt _ _ _ (by rw [sliceASelect_outs_len]; exact hk) 0 false] at hs
  rw [hs, getD_map_lt _ _ _ (by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk]]

/-! ## ② The XOR bank, transported: `xorOut k` inside the eleven organs -/

/-- The five organ blocks placed after `bitXor32` and before the select. -/
def coreRest5 : List Gate :=
  instGates bitNot32 bitNot32Sig off5
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt

/-- The prefix up to and including the rs2 read port — what `bitXor32` sees. -/
def coreThru5 : List Gate := coreThru4 ++ instGates readTree readTreeRs2Sig off3

theorem coreThru11_xor_split :
    coreThru11 = (coreThru5 ++ instGates bitXor32 bitXor32Sig off4) ++ coreRest5 := by
  simp only [coreThru11, coreThru5, coreThru4, coreThru3, coreRest5, List.append_assoc]

theorem coreRest5_out_ge : ∀ g ∈ coreRest5, off5 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off5 ≤ off →
      ∀ g ∈ instGates c σ off, off5 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [coreRest5, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h
  · exact key _ _ _ (by decide +kernel) (Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by simp only [offOb, instNext]; omega) g h
  · exact key _ _ _ adder32_ssa (by simp only [offAdd, offOb, instNext]; omega) g h
  · exact key _ _ _ adder32_ssa (by simp only [offSub, offAdd, offOb, instNext]; omega) g h
  · exact key _ _ _ sltCirc_ssa (by simp only [offSlt, offSub, offAdd, offOb, instNext]; omega) g h

theorem bitXor32_outs_len : bitXor32.outs.length = 32 := by decide +kernel

theorem xorOut_lt_off5 (k : Nat) (hk : k < 32) : xorOut k < off5 := by
  revert k; decide +kernel

theorem xorOut_eq (k : Nat) (hk : k < 32) :
    xorOut k = instMap bitXor32 bitXor32Sig off4 (bitXor32.outs.getD k 0) := by
  rw [xorOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [bitXor32_outs_len]; exact hk) 0 0

theorem bitXor32_out_mem (k : Nat) (hk : k < 32) :
    (bitXor32.gates.map Gate.out).contains (bitXor32.outs.getD k 0) = true := by
  revert k; decide +kernel

/-- ⭐ **THE XOR BANK, AT THE GATE LEVEL.** Port `k` of `bitXor32` inside the eleven organs
is the XOR of the two read ports' bit `k` — from `bitXor32_sem`, the UNIVERSAL certificate
(∀ env, no sample, no `decide`), not from `bitXor32_correct_on_sample`. -/
theorem core_xor_bank (ins : Env) (k : Nat) (hk : k < 32) :
    run ins coreThru11 (xorOut k)
      = xor (run ins coreThru5 (rs1Out k)) (run ins coreThru5 (rs2Out k)) := by
  rw [coreThru11_xor_split, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := coreRest5_out_ge g hg
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (xorOut_lt_off5 k hk)))]
  rw [run_append, xorOut_eq k hk]
  rw [inst_sem bitXor32 bitXor32Sig off4 (run ins coreThru5)
      (fun a => run ins coreThru5 (bitXor32Sig a)) bitXor32_instOK (fun _ _ => rfl)
      (bitXor32.outs.getD k 0) (Or.inr (bitXor32_out_mem k hk))]
  have hs := congrArg (fun l : List Bool => l.getD k false)
    (bitXor32_sem (fun a => run ins coreThru5 (bitXor32Sig a)))
  simp only [sem] at hs
  rw [getD_map_lt _ _ _ (by rw [bitXor32_outs_len]; exact hk) 0 false] at hs
  rw [hs, getD_map_lt _ _ _ (by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk]]
  have h1 : bitXor32Sig k = rs1Out k := by simp only [bitXor32Sig, if_pos hk]
  have h2 : bitXor32Sig (32 + k) = rs2Out k := by
    have hn : ¬ ((32 + k : Net) < 32) := by simp only [Net]; omega
    have he : (32 + k : Net) - 32 = k := by simp only [Net]; omega
    simp only [bitXor32Sig, if_neg hn, he]
  show xor (run ins coreThru5 (bitXor32Sig k)) (run ins coreThru5 (bitXor32Sig (32 + k))) = _
  rw [h1, h2]

/-! ## ③ The read ports, framed back from `coreThruRw` to `coreThru5` -/

theorem coreThruRw_split5 : coreThruRw = coreThru5 ++ coreRest9 := coreThruRw_split2

theorem thru5_eq_thruRw (ins : Env) (n : Net) (hn : n < off4) :
    run ins coreThruRw n = run ins coreThru5 n := by
  rw [coreThruRw_split5, run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := coreRest9_out_ge g hg
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr hn))

theorem rs1Out_lt_off4 (k : Nat) (hk : k < 32) : rs1Out k < off4 := by
  revert k; decide +kernel

/-- ⭐⭐ **THE XOR BANK CARRIES `rs1 ^^^ rs2`, AS WORDS.** -/
theorem core_xor_bank_words (ins : Env) (k : Nat) (hk : k < 32) :
    run ins coreThru11 (xorOut k) = ((rs1Of ins) ^^^ (rs2Of ins)).getLsbD k := by
  rw [core_xor_bank ins k hk,
      ← thru5_eq_thruRw ins (rs1Out k) (rs1Out_lt_off4 k hk),
      ← thru5_eq_thruRw ins (rs2Out k) (rs2Out_lt_off4 k hk),
      BitVec.getLsbD_xor, rs1Of, rs2Of, wordOf_getLsbD _ _ hk, wordOf_getLsbD _ _ hk]

/-! ## ④ The select control on an XOR word -/

theorem gsSel0_three_two : gsSel 3 2 0 = 96 := by decide +kernel
theorem gsSel1_three_two : gsSel 3 2 1 = 97 := by decide +kernel

theorem sel_net0_ctrl (ins : Env) :
    run ins coreThru11 (selSig (gsSel 3 2 0)) = (ctrlSpec (seenWord ins)).getD 1 false := by
  have h := (sel_nets_agree ins).1
  rw [gsSel0_is_96] at h
  rw [gsSel0_three_two]
  exact h

theorem sel_net1_ctrl (ins : Env) :
    run ins coreThru11 (selSig (gsSel 3 2 1)) = (ctrlSpec (seenWord ins)).getD 2 false := by
  have h := (sel_nets_agree ins).2
  rw [gsSel1_is_97] at h
  rw [gsSel1_three_two]
  exact h

/-- Bank 1 IS the XOR bank: `gsRes 1 k` is `sliceASelect` input `32 + k`, and `selSig` sends
that to `xorOut k`. -/
theorem selSig_bank1 (k : Nat) (hk : k < 32) : selSig (gsRes 1 k) = xorOut k := by
  have hr : gsRes 1 k = 32 + k := by simp only [gsRes]
  have hn : ¬ ((32 + k : Net) < 32) := by simp only [Net]; omega
  have hlt : (32 + k : Net) < 64 := by simp only [Net]; omega
  have he : (32 + k : Net) - 32 = k := by simp only [Net]; omega
  rw [hr]
  simp only [selSig, if_neg hn, if_pos hlt, he]

/-! ## ⑤ The decode bridge for the XOR class -/

/-- `decode`'s XOR arm names the rs1/rs2 fields — `decode_beq_regs` at the XOR row. -/
theorem decode_xor_regs (w : BitVec 32) (rd a b : Fin 32)
    (h : decode w = some (.XOR rd a b)) :
    a = toReg (w.extractLsb' 15 5) ∧ b = toReg (w.extractLsb' 20 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

theorem rs1Of_is_get_a_XOR (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) :
    rs1Of ins = (decQ ins).get a := by
  rw [rs1Of_is_St_get]
  congr 1
  have ha := (decode_xor_regs _ rd a b h).1
  apply Fin.ext
  show rs1AddrOf ins = a.val
  rw [ha, ← rs1AddrOf_is_decode_field ins]
  rfl

theorem rs2Of_is_get_b_XOR (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) :
    rs2Of ins = (decQ ins).get b := by
  rw [rs2Of_is_St_get]
  congr 1
  have hb := (decode_xor_regs _ rd a b h).2
  apply Fin.ext
  show rs2AddrOf ins = b.val
  rw [hb, ← rs2AddrOf_is_decode_field ins]
  rfl

/-! ## ⑥ ⭐⭐⭐ THE VALUE, ON AN XOR WORD -/

/-- ⭐⭐⭐ **THE ENABLE ARM'S VALUE HALF, XOR CLASS.** On any valuation whose instruction word
decodes to `XOR rd a b`, the select's port `k` — the bit the register file would write — is
bit `k` of `St.get a ^^^ St.get b` of the decoded state. Arbitrary `ins`, every `k < 32`. -/
theorem core_selOut_on_XOR (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) :
    run ins core.gates (selOut k)
      = ((decQ ins).get a ^^^ (decQ ins).get b).getLsbD k := by
  rw [core_selOut_arms ins k hk, sel_net0_ctrl ins, sel_net1_ctrl ins]
  rw [show (ctrlSpec (seenWord ins)).getD 2 false = false from by simp [ctrlSpec, h],
      show (ctrlSpec (seenWord ins)).getD 1 false = true from by simp [ctrlSpec, h]]
  rw [if_neg (by simp), if_pos rfl, selSig_bank1 k hk, core_xor_bank_words ins k hk,
      rs1Of_is_get_a_XOR ins rd a b h, rs2Of_is_get_b_XOR ins rd a b h]

/-! ## ⑦ The ISA side, and the two joined -/

/-- The ISA's written word on an XOR: `regs[rd] := get a ^^^ get b` (with `rd ≠ 0`; the
`rd = 0` case is `regDatapath_holds_at_zero`'s territory). -/
theorem stepT_regs_on_XOR (ins : Env) (rd a b : Fin 32) (k : Nat)
    (h : decode (seenWord ins) = some (.XOR rd a b)) (hrd : ¬ (rd = 0)) :
    ((stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k
      = ((decQ ins).get a ^^^ (decQ ins).get b).getLsbD k := by
  simp [stepT, stepW, h, SaltWorks.ISA.step, St.set, St.next, hrd]

/-- ⭐⭐⭐ **THE JOIN — `selOut k` IS the ISA's written bit, on the XOR class.** This is
exactly `RegDatapathOK`'s enable-arm consequent for XOR words with a non-zero destination. -/
theorem core_selOut_is_isa_write_on_XOR (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) (hrd : ¬ (rd = 0)) :
    run ins core.gates (selOut k)
      = ((stepT (decQ ins) (seenWord ins)).regs[rd.val]).getLsbD k := by
  rw [core_selOut_on_XOR ins rd a b k hk h, stepT_regs_on_XOR ins rd a b k h hrd]

/-! ## ⑧ THE TWO CONTROLS — because a scoped hypothesis can be UNSATISFIABLE, and a
theorem can hold for a reason that has nothing to do with its hypothesis. -/

/-- ⚠️ **TWO `seenWord`s, IDENTICAL BODIES, DIFFERENT CONSTANTS.** `SaltWorks.HDL.seenWord`
(`C4.lean:66`) and `SaltWorks.Stack.Program.seenWord` (`Program.lean:1458`) are both
`wordOf (fun k => ins (instrNet k))`. Everything above is stated over the FORMER (the one the
opened namespaces resolve to); `seenWord_envWith` is proved about the LATTER. They are `rfl`,
and saying so is cheaper than a `rw` that reports "did not find an occurrence" and reads like
a proof failure. -/
theorem seenWord_HDL_is_Program (ins : Env) :
    seenWord ins = SaltWorks.Stack.Program.seenWord ins := rfl

/-- **CONTROL 1 — THE HYPOTHESIS IS SATISFIABLE.** `decode (seenWord ins) = some (.XOR rd a b)`
is true on a real valuation, for EVERY `rd a b` and every state: the canonical presentation of
that state with the encoded word. Without this, ⑥ could be a true sentence about an empty set. -/
theorem xor_hypothesis_is_satisfiable (s : St) (rd a b : Fin 32) :
    decode (seenWord (envWith s (encode (.XOR rd a b)))) = some (.XOR rd a b) := by
  rw [seenWord_HDL_is_Program, SaltWorks.Stack.Program.seenWord_envWith]
  exact decode_encode _

/-- …and the headline INSTANTIATED there, so the non-vacuity is of the theorem, not of a
neighbouring sentence. -/
theorem core_selOut_on_XOR_instantiated (s : St) (rd a b : Fin 32) (k : Nat) (hk : k < 32) :
    run (envWith s (encode (.XOR rd a b))) core.gates (selOut k)
      = ((decQ (envWith s (encode (.XOR rd a b)))).get a
          ^^^ (decQ (envWith s (encode (.XOR rd a b)))).get b).getLsbD k :=
  core_selOut_on_XOR _ rd a b k hk (xor_hypothesis_is_satisfiable s rd a b)

/-- **CONTROL 2 — THE `XOR` HYPOTHESIS IS LOAD-BEARING.** On an `ADD` word the SAME port `k`
reads bank 0, not bank 1. So ⑥ is not a fact about `selOut` that happens to mention `XOR`. -/
theorem core_selOut_on_ADD_takes_bank0 (ins : Env) (rd a b : Fin 32) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) :
    run ins core.gates (selOut k) = run ins coreThru11 (selSig (gsRes 0 k)) := by
  rw [core_selOut_arms ins k hk, sel_net0_ctrl ins, sel_net1_ctrl ins]
  rw [show (ctrlSpec (seenWord ins)).getD 2 false = false from by simp [ctrlSpec, h],
      show (ctrlSpec (seenWord ins)).getD 1 false = false from by simp [ctrlSpec, h]]
  simp

/-- …and the two banks are DIFFERENT NETS at every port, so control 2 is a real disagreement
and not two names for one wire. -/
theorem bank0_ne_bank1 (k : Nat) (hk : k < 32) : selSig (gsRes 0 k) ≠ selSig (gsRes 1 k) := by
  revert k; decide +kernel

#audit_axioms core_selOut_arms
#audit_axioms core_xor_bank
#audit_axioms core_xor_bank_words
#audit_axioms core_selOut_on_XOR
#audit_axioms stepT_regs_on_XOR
#audit_axioms core_selOut_is_isa_write_on_XOR
#audit_axioms seenWord_HDL_is_Program
#audit_axioms xor_hypothesis_is_satisfiable
#audit_axioms core_selOut_on_XOR_instantiated
#audit_axioms core_selOut_on_ADD_takes_bank0
#audit_axioms bank0_ne_bank1


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.bitXor32_out_mem SaltWorks.HDL.RegNextUniform.XOR.bitXor32_outs_len
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.coreRest5_out_ge SaltWorks.HDL.RegNextUniform.XOR.coreThru11_xor_split
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.coreThruRw_split5 SaltWorks.HDL.RegNextUniform.XOR.decode_xor_regs
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.gsSel0_three_two SaltWorks.HDL.RegNextUniform.XOR.gsSel1_three_two
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.rs1Of_is_get_a_XOR SaltWorks.HDL.RegNextUniform.XOR.rs1Out_lt_off4
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.rs2Of_is_get_b_XOR SaltWorks.HDL.RegNextUniform.XOR.selSig_bank1
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.sel_net0_ctrl SaltWorks.HDL.RegNextUniform.XOR.sel_net1_ctrl
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.thru5_eq_thruRw SaltWorks.HDL.RegNextUniform.XOR.xorOut_eq
#audit_axioms SaltWorks.HDL.RegNextUniform.XOR.xorOut_lt_off5
end SaltWorks.HDL.RegNextUniform.XOR
