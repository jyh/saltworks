/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# `RegField core 0` — the first of the thirty-four

`c4Spec_iff_fieldwise` splits `C4Spec core` into 34 obligations: the output count (landed,
`core_outs_length`), thirty-two `RegField`s, and `PcField`. **This file discharges one of
them**, and it is worth being exact about which one and why it was reachable.

**x0 IS THE ONE REGISTER THAT DOES NOT NEED THE DATAPATH.** `regWrite`'s output 0 is a
hardwired `.const false` — *P5, the absent write port* — so `run_gate_val` reads it as
`false` with no evaluation of the decoder, the ALU or the select, and the transport through
the placement (`core_rwOut0_false`) carries that to `core`. The reduced schema
(`core_outBit_reg_reduced`) then says the output bit IS the input state bit, and
`stepT_regs_zero` says the ISA does not write x0 either. **Both sides are the same input
bit, and neither side needed to know what the machine computes.**

⛔ **AND THAT IS PRECISELY WHY IT IS NOT EVIDENCE ABOUT THE OTHER THIRTY-ONE.** Its
cheapness comes entirely from the enable being a constant. Registers 1–31 need `rwOut r`
proved against the ISA (`regWrite` correctness, itself already exhaustive at the organ) and
`selOut k` proved against the ALU/decode/select path — and the second of those is the
campaign. *One of thirty-four, and the one that was free.*

⚠️ **DATED, per `RegFieldSchema`'s standing note:** `regWrite` has no retire port
(`regWrite_has_no_retire_input`), so item 10's change must widen that interface. This
obligation happens to be robust to it — x0's enable is constant `false` under any gating —
but the same is NOT true of registers 1–31.
-/
import SaltWorks.HDL.RegNextUniform
import SaltWorks.HDL.SsaGateSem

set_option maxHeartbeats 4000000
set_option maxRecDepth 8000

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL
open SaltWorks.HDL.CorePlace

/-- The fifteen organ blocks before `regWrite`. -/
def coreThru13 : List Gate :=
  instGates tieCells id offTie
    ++ instGates decoder decoderSig off0
    ++ instGates immBCirc immBSig off1
    ++ instGates readTree readTreeRs1Sig off2
    ++ instGates readTree readTreeRs2Sig off3
    ++ instGates bitXor32 bitXor32Sig off4
    ++ instGates bitNot32 bitNot32Sig off5
    ++ instGates selOr selOrSig offSelOr
    ++ instGates OperandB.obMux immMuxSig offImmMux
    ++ instGates OperandB.obMux obSig offOb
    ++ instGates adder32 addSig offAdd
    ++ instGates adder32 subSig offSub
    ++ instGates sltCirc sltSig offSlt
    ++ instGates SelectCut32.sliceASelect selSig offSel
    ++ instGates EncoderE1.ruledEnc encSig offEnc

/-- …with the TRAP GATE appended (R9a, ruling z 2026-08-31) — the prefix `regWrite`'s σ is
evaluated over, since its port 10 reads the gate's output. -/
def coreThruLw : List Gate :=
  coreThru13 ++ instGates lwWrCirc lwWrSig offLwWr

/-- …and with `regWrite` appended after that. -/
def coreThruRw : List Gate :=
  coreThruLw ++ instGates regWrite regWriteSig offRw

theorem corePre_split : corePre = coreThruRw ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc := by
  simp only [corePre, coreThruRw, coreThruLw, coreThru13, List.append_assoc]

/-- Nets below `offLwWr` read the same through `coreThruLw` as through `coreThru13` — the
trap gate writes only at or above its own offset. -/
theorem coreThruLw_agrees_below (ins : Env) (n : Net) (hn : n < offLwWr) :
    run ins coreThruLw n = run ins coreThru13 n := by
  rw [coreThruLw, run_append]
  exact run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range lwWrCirc lwWrSig offLwWr lwWrCirc_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr hn))

/-! ### x0's enable is a hardwired constant -/

theorem regWrite_out0_gate_mem :
    (⟨regWrite.outs.getD 0 0, Op.const false⟩ : Gate) ∈ regWrite.gates := by decide +kernel

theorem regWrite_ssaFrom : ssaFrom regWrite.nIn regWrite.gates = true := by
  have h := regWrite_ssa
  simp only [Circ.ssa, Bool.and_eq_true] at h
  exact h.1

/-- **In `regWrite` standalone, output 0 is `false` under EVERY environment** — it is a
`.const false` gate, so `run_gate_val` reads it with no evaluation of the decoder at all. -/
theorem regWrite_out0_false (env : Env) :
    run env regWrite.gates (regWrite.outs.getD 0 0) = false := by
  have h := run_gate_val env regWrite.gates regWrite.nIn regWrite_ssaFrom regWrite_out0_gate_mem
  simpa [Op.eval] using h

theorem rwOut0_eq : rwOut 0 = instMap regWrite regWriteSig offRw (regWrite.outs.getD 0 0) := by
  decide +kernel

theorem rwOut0_lt_offPc : rwOut 0 < offPc := by decide +kernel
theorem rwOut0_lt_offRegNext : rwOut 0 < offRegNext := by decide +kernel

/-- ⭐⭐ **x0's WRITE ENABLE IS FALSE IN `core`, FOR EVERY INPUT** — transported through the
placement without evaluating a single gate of the decoder or the ALU. -/
theorem core_rwOut0_false (ins : Env) : run ins core.gates (rwOut 0) = false := by
  rw [core_frame_below ins (rwOut 0) rwOut0_lt_offRegNext, corePre_split, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      SaltWorks.Stack.Program.pcAdd_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr rwOut0_lt_offPc))]
  rw [coreThruRw, run_append, rwOut0_eq]
  rw [inst_sem regWrite regWriteSig offRw (run ins coreThruLw)
      (fun a => run ins coreThruLw (regWriteSig a)) regWrite_instOK (fun _ _ => rfl)
      (regWrite.outs.getD 0 0) (Or.inr (by decide +kernel))]
  exact regWrite_out0_false _

/-! ### ⭐⭐⭐ THE FIRST OF THE THIRTY-FOUR -/

/-- `decQ` reads register 0's bits straight off the input valuation. -/
theorem decQ_reg0_bit (ins : Env) (k : Nat) (hk : k < 32) :
    ((decQ ins).regs[0]).getLsbD k = ins k := by
  have h : (decQ ins).regs[0] = wordOf (fun j => ins (32 * (0 : Fin 32).val + j)) := by
    simp [decQ]
  rw [h, wordOf_getLsbD _ _ hk]
  simp

/-- ⭐⭐⭐ **`RegField core 0` — THE FIRST `C4Spec` OBLIGATION DISCHARGED.**

*It is the one register that does not need the datapath.* `regWrite`'s output 0 is a
hardwired `.const false` (P5, the absent write port), so `core_rwOut0_false` kills the
`if` without evaluating the decoder, the ALU, or the select; the reduced schema then says
the output bit IS the input state bit; and `stepT_regs_zero` says the ISA does not write
x0 either. **Both sides are the same input bit, and neither side needed to know what the
machine computes.**

⛔ **AND THIS IS EXACTLY WHY IT IS NOT EVIDENCE ABOUT THE OTHER 31.** Its cheapness comes
from the enable being constant. Registers 1–31 require `rwOut r` and `selOut k` to be
proved against the ISA, which is the whole campaign. *One of thirty-four, and the one
that was free.* -/
theorem regField_core_zero : SaltWorks.Stack.Program.RegField core 0 := by
  rw [SaltWorks.Stack.Program.regField_iff_bits]
  intro ins k hk
  -- ⚠️ `rw` on the Fin→Nat coercion fails with "motive is not type correct": `regs[i]`
  -- carries an `i < 32` proof, so rewriting the index breaks its own bound. `show` accepts
  -- the defeq without touching the term.
  show SaltWorks.Stack.Program.outBit core ins (32 * 0 + k)
      = ((SaltWorks.ISA.stepT (decQ ins) (SaltWorks.Stack.Program.seenWord ins)).regs[0]).getLsbD k
  rw [core_outBit_reg_reduced ins 0 k (by omega) hk, core_rwOut0_false ins,
      SaltWorks.Stack.Program.stepT_regs_zero, decQ_reg0_bit ins k hk]
  simp

#audit_axioms regWrite_out0_false core_rwOut0_false
#audit_axioms decQ_reg0_bit regField_core_zero


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.corePre_split SaltWorks.HDL.RegNextUniform.regWrite_out0_gate_mem
#audit_axioms SaltWorks.HDL.RegNextUniform.regWrite_ssaFrom SaltWorks.HDL.RegNextUniform.rwOut0_eq
#audit_axioms SaltWorks.HDL.RegNextUniform.rwOut0_lt_offPc SaltWorks.HDL.RegNextUniform.rwOut0_lt_offRegNext
end SaltWorks.HDL.RegNextUniform
