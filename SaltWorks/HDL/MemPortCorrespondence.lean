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
① ADDRESS      the 3 address nets carry bits [4:2] of the effective address   ⛔ STILL EXCLUDED,
               but the REASON changed on 2026-08-29 — see §3. The wiring is repaired;
               the ADDER VALUE theorem it now waits on does not exist for any instruction.
② STROBE       the write-enable net is high exactly on a store                ✅ memWe_is_isSW
③ WRITE DATA   the 32 data nets carry the rs2 register value                  ✅ memWData_is_rs2
```

## ⛔⛔ §3 — WHY ① IS EXCLUDED. **THE REASON CHANGED ON 2026-08-29 AND THE EXCLUSION DID NOT.**

***An exclusion whose reason lives in a commit message or a bus post is one the next hand deletes.***
So the reason is `addrLink1`–`addrLink9` below, and it is now a DIFFERENT reason than it was.

**WHAT IT USED TO SAY, and no longer does.** Until leg ① stage 2b the chain showed the operand-B
selector was `decOut isADDILine` ALONE. With `OperandBMux.out_sem_obMux`
(`out_k = if sel then b_k else a_k`) that meant: under a store the mux passed `rs2`, so the
address the organ would read was bits [4:2] of `rs1 + rs2`, where the ISA calls for
`rs1 + sext(imm_S)`. ***THAT WAS A STRUCTURAL DEFECT IN THE MODEL AND IT IS NOW REPAIRED.***
`addrLink5` reads `obSig 64 = selOrOut 0`; `addrLink6`–`addrLink7` show that select is
`isADDI ∨ req` and that `req` is HIGH ON EVERY STORE; `addrLink8`–`addrLink9` show the bank the
store then reaches is the S-TYPE immediate, `immS`, which is provably not `immI`.

⛔⛔ **AND YET ① IS STILL EXCLUDED, FOR A REASON THAT IS SMALLER AND ENTIRELY DIFFERENT.** The
address path is now WIRED correctly; what is missing is a VALUE theorem. **No theorem in this
tree states what `CorePlace.addOut k` computes, for ANY instruction.** ① needs exactly that —
bits [4:2] of `rs1 + sext(imm_S)` at the adder's output — and until it exists ① cannot be stated,
let alone proved. *The old exclusion was a defect. This one is unfinished work, and the
difference matters to whoever reads this next.*
📌 **DO NOT READ THE REPAIR AS THE CORRESPONDENCE.** Wiring is not value; that confusion is the
same shape as `instOK`'s, which this file's first paragraph exists to name.

⚠️ **SCOPE, MEASURED 2026-08-27 AND STILL EXACT.** All of the above is about the LEAN MODEL. The
RTL in this tree computed the store address CORRECTLY THE WHOLE TIME — `core32.v` selects the
immediate on `is_immop|is_load|is_store|is_jalr` and `ctrl32.v` builds `imm_s` — so the divergence
was always LEAN-MODEL-vs-RTL, with the Lean `obMux` modelling one case of a four-case select.
**It was never a silicon defect, and leg ① fixed nothing on the die.** Which RTL top was
fabricated is silicon's to answer and is NOT claimed here.

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

/-- Every gate after the first fifteen organ blocks writes at or above `offLwWr` — since R9a
the trap gate leads the tail (was `coreTail3_out_ge`, bounded at `offRw`). -/
theorem coreTail4_out_ge :
    ∀ g ∈ (instGates lwWrCirc lwWrSig offLwWr
            ++ instGates regWrite regWriteSig offRw
            ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
            ++ instGates regNext regNextSig offRegNext), offLwWr ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → offLwWr ≤ off →
      ∀ g ∈ instGates c σ off, offLwWr ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  simp only [List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h
  · exact key _ _ _ lwWrCirc_ssa (Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offRw, offLwWr, instNext]; omega) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offPc, offRw, offLwWr, instNext]; omega) g h
  · exact key _ _ _ (by decide +kernel)
      (by simp only [offRegNext, offPc, offRw, offLwWr, instNext]; omega) g h

/-- ⭐⭐ **LEG ② — THE DECODER'S LINES, THROUGH THE WHOLE CORE.** -/
theorem core_decOut_spec_full (ins : Env) (j : Nat) (hj : j < 9) :
    run ins core.gates (decOut j) = (ctrlSpec (seenWord ins)).getD j false := by
  rw [run_core_eq_prefix ins (decOut j) coreThru13 _ core_gates_from13
    (fun g hg hEq => by
      have hge := coreTail4_out_ge g hg
      rw [hEq] at hge
      have hlt : decOut j < off1 := decOut_lt_off1 j hj
      have hle : off1 ≤ offLwWr := by
        simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd,
          offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega
      -- ⛔ NOT `omega` HERE: the `<` sits at `Net`, so omega drops `hlt` and reports a
      -- counterexample made only of the OTHER hypotheses — this seat's own card, firing.
      exact absurd hge (Nat.not_le.mpr (Nat.lt_of_lt_of_le hlt hle)))]
  exact core_decOut_spec ins j hj

/-- ⭐⭐⭐ **THE STORE STROBE IS THE ISA'S STORE PREDICATE, AT THE NET THE ORGAN WOULD READ.** -/
theorem memWe_is_isSW (ins : Env) :
    run ins core.gates MemWiring.memWeNet
      = (ctrlSpec (seenWord ins)).getD isSWLine false :=
  core_decOut_spec_full ins isSWLine (by decide)

#audit_axioms run_core_eq_prefix coreTail4_out_ge core_decOut_spec_full memWe_is_isSW


/-! ## LEG ③ — THE WRITE DATA -/

theorem core_gates_from_rw :
    core.gates = coreThruRw ++ (instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      ++ instGates regNext regNextSig offRegNext) := by
  simp only [core, coreThruRw, coreThruLw, coreThru13, List.append_assoc]

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
        simp only [offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr,
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

/-- ④ ⭐⭐ **RE-POINTED BY LEG ① STAGE 2b.** obMux's b-input is no longer the raw I-type net; it
is the IMMEDIATE MUX's output, which chooses between `immI` and `immS`. -/
theorem addrLink4 (j : Nat) (hj : j < 32) : obSig (32 + j) = CorePlace.immMuxOut j := by
  have h1 : ¬ (32 + j < 32) := by omega
  have h2 : 32 + j < 64 := by omega
  have h3 : 32 + j - 32 = j := by omega
  simp only [obSig, if_neg h1, if_pos h2, h3]

/-- ⑤ ⭐⭐⭐ **THE SENTENCE THIS WHOLE FILE TURNED ON, AND IT IS NOW FALSE.** It read
`obSig 64 = decOut isADDILine` — the select was `isADDI` AND NOTHING ELSE, which is precisely why
a store took the `rs2` bank. The select is now the WIDENED one. -/
theorem addrLink5 : obSig 64 = CorePlace.selOrOut 0 := rfl

/-- ⑥ ⭐⭐ **AND THE WIDENED SELECT'S SECOND INPUT IS `req`** — so the select is `isADDI ∨ req`,
not `isADDI`. -/
theorem addrLink6 : selOrSig 1 = decOut reqLine := rfl

/-- ⑦ ⭐⭐⭐ **`req` IS HIGH ON EVERY STORE** (`req_is_lw_or_sw`), so the widened
select FIRES on a store and the mux takes its b bank. **This is the exact inversion of the old
⑥, which proved `isADDI ≠ isSW` to show a store did NOT reach the immediate path.** -/
theorem addrLink7 (w : BitVec 32) (h : (ctrlSpec w).getD isSWLine false = true) :
    ((ctrlSpec w).getD isADDILine false || (ctrlSpec w).getD reqLine false) = true := by
  rw [req_is_lw_or_sw, h]
  simp

/-- ⑧ ⭐⭐ **AND THE BANK THE STORE THEN GETS IS THE S-TYPE IMMEDIATE.** The immediate mux selects
on `isSW` and its b bank is `immS` — the extraction the ISA calls for, and provably NOT `immI`
(`immS_ne_immI`). -/
theorem addrLink8 : immMuxSig 64 = decOut isSWLine := rfl

theorem addrLink9 (j : Nat) (hj : j < 32) :
    immMuxSig (32 + j) = instrNet (immS j) := by
  have h1 : ¬ (32 + j < 32) := by omega
  have h2 : 32 + j < 64 := by omega
  have h3 : 32 + j - 32 = j := by omega
  simp only [immMuxSig, if_neg h1, if_pos h2, h3]

/-- ⭐⭐⭐ **THE MEMORY PORT CORRESPONDENCE, AS FAR AS IT HOLDS.** Two legs of three, over any input
valuation. The third is excluded and `addrLink1`–`addrLink9` above are why — and since
2026-08-29 the why is an ABSENT VALUE THEOREM, not a mis-wired select. -/
theorem mem_port_correspondence_partial (ins : Env) :
    run ins core.gates MemWiring.memWeNet
        = (ctrlSpec (seenWord ins)).getD isSWLine false
    ∧ (∀ k, k < 32 → run ins core.gates (MemWiring.memWDataNet k)
        = ((decQ ins).get ⟨rs2AddrOf ins, rs2AddrOf_lt ins⟩).getLsbD k) :=
  ⟨memWe_is_isSW ins, fun k hk => memWData_is_rs2 ins k hk⟩

#audit_axioms addrLink1 addrLink2 addrLink3 addrLink4 addrLink5 addrLink6
#audit_axioms addrLink7 addrLink8 addrLink9
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
