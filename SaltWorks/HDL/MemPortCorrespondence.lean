/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# The memory port's ISA correspondence — TWO LEGS OF THREE, and the third EXCLUDED BY THEOREM

`bridge_sem_eq_of_bridgeable` certifies a bridged circuit's `sem` at its declared `outs`. It does
not certify that the RIGHT nets were declared. `instOK` has the same shape one level up: it is a
TIMING AND STRUCTURE property and is silent about which wire was chosen. **This file closes two
thirds of that gap for the memory port, and refuses the third for a reason that is itself a
kernel-checked theorem rather than a comment.**

## What a full correspondence would say, against `ISA.lean`'s `SW rs1 rs2 imm ⟶ mem[(rs1 + sext(imm))/4] := rs2`

```
① ADDRESS      the 3 address nets carry bits [4:2] of the effective address   ⛔ EXCLUDED, see §3
② STROBE       the write-enable net is high exactly on a store                ✅ memWe_is_isSW
③ WRITE DATA   the 32 data nets carry the rs2 register value                  ✅ memWData_is_rs2
```

## ⛔⛔ §3 — WHY ① IS EXCLUDED, AS SIX THEOREMS AND NOT AS A SENTENCE

***An exclusion whose reason lives in a commit message or a bus post is one the next hand deletes.***
So the reason is `addrLink1`–`addrLink6` below. **They trace the address path to its selector and
show that selector is `decOut isADDILine` ALONE.** With the landed `OperandBMux.out_sem_obMux`
(`out_k = if sel then b_k else a_k`) that means: under a store the mux passes `rs2`, so the address
the organ would read is bits [4:2] of `rs1 + rs2`, where the ISA calls for `rs1 + sext(imm_S)`.
**To delete this exclusion you must delete a theorem, and the build will tell you.**

⚠️ **SCOPE, MEASURED 2026-08-27 AND NOT TO BE READ WIDER.** This is a fact about the LEAN MODEL. The
RTL in this tree computes the store address CORRECTLY — `core32.v` selects the immediate on
`is_immop|is_load|is_store|is_jalr` and `ctrl32.v` builds `imm_s` — so the divergence is
LEAN-MODEL-vs-RTL, with the Lean `obMux` modelling one case of a four-case select. **It is not a
silicon defect.** Which RTL top was fabricated is silicon's to answer and is NOT claimed here.

📌 **And `memOrgan` is not in `core.gates` at all** — `MemWiring.mem_instOK_placed` proves a
placement would be LEGAL at `offMem`; it does not place it. So ② and ③ below are statements about
the nets the organ WOULD read, at the position it WOULD occupy.
-/
import SaltWorks.HDL.MemWiring
import SaltWorks.HDL.EnableArm
import SaltWorks.HDL.DecoderTransport
import SaltWorks.HDL.Rs2Close
import SaltWorks.HDL.PcReads
import SaltWorks.HDL.Immediate

namespace SaltWorks.HDL
open SaltWorks.HDL CorePlace RegNextUniform

/-- ⭐ **THE REUSABLE LIFT.** A net no gate in the tail writes reads the same through the whole
core as through the prefix. Both legs of the correspondence need exactly this. -/
theorem run_core_eq_prefix (ins : Env) (n : Net) (pre tail : List Gate)
    (hsplit : core.gates = pre ++ tail) (hunw : ∀ g ∈ tail, g.out ≠ n) :
    run ins core.gates n = run ins pre n := by
  rw [hsplit, run_append, run_of_unwritten _ _ _ hunw]

/-- Every gate after the first thirteen organs writes at or above `offRw`. -/
theorem coreTail3_out_ge :
    ∀ g ∈ (instGates regWrite regWriteSig offRw
            ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
            ++ instGates regNext regNextSig offRegNext), offRw ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → offRw ≤ off →
      ∀ g ∈ instGates c σ off, offRw ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  rcases hg with h|h|h
  · exact key _ _ _ (by decide +kernel) (Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offPc, offRw, instNext]; omega) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offRegNext, offPc, offRw, instNext]; omega) g h

/-- ⭐⭐ **LEG ② — THE DECODER'S LINES, THROUGH THE WHOLE CORE.** -/
theorem core_decOut_spec_full (ins : Env) (j : Nat) (hj : j < 9) :
    run ins core.gates (decOut j) = (ctrlSpec (seenWord ins)).getD j false := by
  rw [run_core_eq_prefix ins (decOut j) coreThru13 _ core_gates_from13
    (fun g hg hEq => by
      have hge := coreTail3_out_ge g hg
      rw [hEq] at hge
      have hlt : decOut j < off1 := decOut_lt_off1 j hj
      have hle : off1 ≤ offRw := by
        simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd,
          offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega
      -- ⛔ NOT `omega` HERE: the `<` sits at `Net`, so omega drops `hlt` and reports a
      -- counterexample made only of the OTHER hypotheses — this seat's own card, firing.
      exact absurd hge (Nat.not_le.mpr (Nat.lt_of_lt_of_le hlt hle)))]
  exact core_decOut_spec ins j hj

/-- ⭐⭐⭐ **THE STORE STROBE IS THE ISA'S STORE PREDICATE, AT THE NET THE ORGAN WOULD READ.** -/
theorem memWe_is_isSW (ins : Env) :
    run ins core.gates MemWiring.memWeNet
      = (ctrlSpec (seenWord ins)).getD isSWLine false :=
  core_decOut_spec_full ins isSWLine (by decide)

#audit_axioms run_core_eq_prefix coreTail3_out_ge core_decOut_spec_full memWe_is_isSW


/-! ## LEG ③ — THE WRITE DATA -/

theorem core_gates_from_rw :
    core.gates = coreThruRw ++ (instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      ++ instGates regNext regNextSig offRegNext) := by
  simp only [core, coreThruRw, coreThru13, List.append_assoc]

theorem coreTail2_out_ge :
    ∀ g ∈ (instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
            ++ instGates regNext regNextSig offRegNext), offPc ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → offPc ≤ off →
      ∀ g ∈ instGates c σ off, offPc ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [List.mem_append] at hg
  rcases hg with h|h
  · exact key _ _ _ (by decide +kernel) (Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offRegNext, offPc, instNext]; omega) g h

theorem core_rs2Out_eq (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (rs2Out k) = run ins coreThruRw (rs2Out k) :=
  run_core_eq_prefix ins (rs2Out k) coreThruRw _ core_gates_from_rw
    (fun g hg hEq => by
      have hge := coreTail2_out_ge g hg
      rw [hEq] at hge
      have hlt : rs2Out k < off4 := rs2Out_lt_off4 k hk
      have hle : off4 ≤ offPc := by
        simp only [offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb,
          off5, off4, instNext]; omega
      exact absurd hge (Nat.not_le.mpr (Nat.lt_of_lt_of_le hlt hle)))

/-- ⭐⭐⭐ **LEG ③ — THE 32 WRITE-DATA NETS CARRY THE `rs2` REGISTER VALUE.** -/
theorem memWData_is_rs2 (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (MemWiring.memWDataNet k)
      = ((decQ ins).get ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩).getLsbD k := by
  have h1 : (rs2Of ins).getLsbD k = run ins coreThruRw (rs2Out k) := by
    rw [rs2Of]; exact wordOf_getLsbD _ k hk
  have h2 : (rs2Of ins).getLsbD k
      = ((decQ ins).get ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩).getLsbD k := by
    rw [rs2Of_is_St_get]
  rw [MemWiring.memWDataNet, core_rs2Out_eq ins k hk, ← h1, h2]

#audit_axioms core_gates_from_rw coreTail2_out_ge core_rs2Out_eq memWData_is_rs2
/-! ## §3 — THE EXCLUSION'S REASON, AS THEOREMS -/

/-- ① the memory organ's address bits are the adder's bits [4:2]. -/
theorem addrLink1 (j : Nat) : MemWiring.memAddrNet j = CorePlace.addOut (j + 2) := rfl

/-- ② the adder's operand-B bank is the obMux output. -/
theorem addrLink2 (k : Nat) (hk : k < 32) : addSig (32 + k) = obOut k := by
  have h1 : ¬ (32 + k < 32) := by omega
  have h2 : 32 + k < 64 := by omega
  have h3 : 32 + k - 32 = k := by omega
  simp only [addSig, if_neg h1, if_pos h2, h3]

/-- ③ obMux's a-input is rs2. -/
theorem addrLink3 (k : Nat) (hk : k < 32) : obSig k = rs2Out k := by
  simp only [obSig]; rw [if_pos hk]

/-- ④ obMux's b-input is the I-TYPE immediate. -/
theorem addrLink4 (j : Nat) (hj : j < 32) : obSig (32 + j) = instrNet (immI j) := by
  have h1 : ¬ (32 + j < 32) := by omega
  have h2 : 32 + j < 64 := by omega
  have h3 : 32 + j - 32 = j := by omega
  simp only [obSig, if_neg h1, if_pos h2, h3]

/-- ⑤ ⭐⭐ **THE SELECT LINE IS `isADDI`, AND NOTHING ELSE.** -/
theorem addrLink5 : obSig 64 = decOut isADDILine := rfl

/-- ⑥ and `isADDI` is not `isSW` — so a store does NOT select the immediate path. -/
theorem addrLink6 : decOut isADDILine ≠ decOut isSWLine := by decide +kernel

/-- ⭐⭐⭐ **THE MEMORY PORT CORRESPONDENCE, AS FAR AS IT HOLDS.** Two legs of three, over any input
valuation. The third is excluded and `addrLink1`–`addrLink6` above are why. -/
theorem mem_port_correspondence_partial (ins : Env) :
    run ins core.gates MemWiring.memWeNet
        = (ctrlSpec (seenWord ins)).getD isSWLine false
    ∧ (∀ k, k < 32 → run ins core.gates (MemWiring.memWDataNet k)
        = ((decQ ins).get ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩).getLsbD k) :=
  ⟨memWe_is_isSW ins, fun k hk => memWData_is_rs2 ins k hk⟩

#audit_axioms addrLink1 addrLink2 addrLink3 addrLink4 addrLink5 addrLink6
#audit_axioms mem_port_correspondence_partial

/-! ## §4 — DOES `LW` SHARE LEG ①'s SHAPE? MEASURED: YES, BUT NOT IDENTICALLY

I named this unchecked when I scoped leg ①. It is a measurement, so here it is.

**`LW` shares the SELECTOR half.** `addrLink5` pins the operand-B select to `decOut isADDILine`
alone, and `LW` is not `ADDI`, so a load does not divert to the immediate either: its address would
also be `rs1 + rs2`.

⭐ **BUT THE TWO ARE NOT THE SAME DEFECT, AND THE DIFFERENCE DECIDES WHAT A FIX MUST DO.**
`LW` is I-type, and the datum already sitting at the mux's b-input IS the I-type immediate
(`addrLink4`). ***So widening the select would fix `LW` outright.*** `SW` is S-type: its immediate
is a different extraction — `imm[11:5]` from bits 31:25 and `imm[4:0]` from bits 11:7 — and the
theorems below show the wired datum is the I-type position, not the S-type one. ⇒ ***WIDENING THE
SELECT ALONE WOULD FIX `LW` AND WOULD LEAVE `SW` STILL WRONG.***
-/

theorem lw_does_not_select : decOut isADDILine ≠ decOut isLWLine := by decide +kernel

/-- Immediate bit 0 is wired to instruction bit 20 — the I-type position. -/
theorem immBit0_is_Itype : immI 0 = 20 := by decide +kernel

/-- ⛔ **AND NOT THE S-TYPE POSITION.** S-type's `imm[4:0]` lives in bits 11:7, so its bit 0 is
instruction bit 7. The wired datum is 20. *This is why `SW` needs more than a wider select.* -/
theorem immBit0_is_not_Stype : immI 0 ≠ 7 := by decide +kernel

#audit_axioms lw_does_not_select immBit0_is_Itype immBit0_is_not_Stype

end SaltWorks.HDL
