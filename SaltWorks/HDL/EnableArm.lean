/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The ARM TRANSPORTS — enable, and (since 2026-08-19) value

⚠️ **THE FILE IS NAMED FOR THE ENABLE AND NOW CARRIES BOTH.** `core_selOut_transport` was added
at the foot rather than in a `SelectArm.lean` of its own, for one reason: **this file is in the
build graph and a new module would not have been.** That is not a style preference — this seat
landed a refutation module outside the graph the same morning and advertised a differential
receipt that could not fire. **Architecture second, reachability first**, and the mismatch is
named here so a later reader sees a decision rather than an accident.

`IsaHold` closed `RegDatapathOK`'s hold arm and left two: **the circuit's enable agrees with
the ISA's write decision**, and the written value is right. This file does the *placement*
half of the first — it says what `rwOut k` IS when read inside `core`.

```
core_rwOut_transport :  run ins core.gates (rwOut k)
                          = run ⟨the first thirteen organs' output⟩ regWrite.gates
                              (regWrite.outs.getD k 0)
```

*This is `core_rwOut0_false`'s machinery with the constant-gate shortcut removed*: `x0`'s
answer was known before the transport ran, so that proof never had to say what the other
thirty-one enables were. This one does, for every `k < 32`.

⭐ **AND THE ARM SPLITS FURTHER THAN EXPECTED, WHICH IS THE USEFUL PART.** `regWriteSig`
routes `rd` straight from `instrNet` — bits 7…11 of the instruction word, **primary inputs,
with no decoder between them** (`core_rd_is_the_instruction`). So the enable arm's ADDRESS
half needs no decoder correctness whatsoever; only its `valid`/`isBEQ` half does.

⛔ **WHAT IT DOES NOT DO.** It does not connect `regWrite`'s output to `decode w`. The next
step is to feed `regWrite_correct` (exhaustive, 128 control combinations, landed) through
`run_agree_of_inputs_circ` — which needs the environment the thirteen organs produce to be
recognised as the canonical `rd`/`valid`/`isBEQ` shape that `weOf` is stated over. Not built
here, and named so it is not mistaken for done.

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.IsaHold

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- `getD` commutes with `map` below the length. -/
theorem getD_map_lt {α β} [Inhabited β] (f : α → β) (l : List α) (i : Nat) (h : i < l.length)
    (da : α) (db : β) : (l.map f).getD i db = f (l.getD i da) := by
  have h' : i < (l.map f).length := by simpa using h
  rw [List.getD_eq_getElem _ _ h', List.getD_eq_getElem _ _ h, List.getElem_map]

theorem regWrite_outs_len : regWrite.outs.length = 32 := by decide +kernel

theorem rwOut_eq (k : Nat) (hk : k < 32) :
    rwOut k = instMap regWrite regWriteSig offRw (regWrite.outs.getD k 0) := by
  rw [rwOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [regWrite_outs_len]; exact hk) 0 0

theorem rwOut_lt_offPc (k : Nat) (hk : k < 32) : rwOut k < offPc := by
  revert k; decide +kernel

theorem rwOut_lt_offRegNext (k : Nat) (hk : k < 32) : rwOut k < offRegNext := by
  revert k; decide +kernel

theorem rwOut_mem (k : Nat) (hk : k < 32) :
    (regWrite.gates.map Gate.out).contains (regWrite.outs.getD k 0) = true := by
  revert k; decide +kernel

/-- ⭐⭐ **THE ENABLE ARM'S TRANSPORT — `rwOut k` read inside `core` IS `regWrite`'s own
output `k`, evaluated on the environment the first thirteen organs produce.** *This is
`core_rwOut0_false`'s machinery with the constant-gate shortcut removed, so it now covers
every register rather than the one whose answer was already known.* -/
theorem core_rwOut_transport (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (rwOut k)
      = run (fun a => run ins coreThru13 (regWriteSig a)) regWrite.gates
          (regWrite.outs.getD k 0) := by
  rw [core_frame_below ins (rwOut k) (rwOut_lt_offRegNext k hk), corePre_split, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      SaltWorks.Stack.Program.pcAdd_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (rwOut_lt_offPc k hk)))]
  rw [coreThruRw, run_append, rwOut_eq k hk]
  exact inst_sem regWrite regWriteSig offRw (run ins coreThru13)
      (fun a => run ins coreThru13 (regWriteSig a)) regWrite_instOK (fun _ _ => rfl)
      (regWrite.outs.getD k 0) (Or.inr (rwOut_mem k hk))

#audit_axioms getD_map_lt rwOut_eq core_rwOut_transport

/-! ### Where `rd` actually comes from -/

theorem core_gates_from13 :
    core.gates = coreThru13 ++ (instGates regWrite regWriteSig offRw
      ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      ++ instGates regNext regNextSig offRegNext) := by
  simp only [core, coreThru13, List.append_assoc]

theorem coreThru13_sub : coreThru13 ⊆ core.gates := by
  rw [core_gates_from13]; exact List.subset_append_left _ _

/-- **A primary input reads the same through the first thirteen organs as in the valuation.**
`core_input_stable` at a prefix — the gates are a subset, so the same bound applies. -/
theorem coreThru13_input_stable (ins : Env) (n : Net) (hn : n < coreInWidth) :
    run ins coreThru13 n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ core_gate_out_ge g (coreThru13_sub hg)) (Nat.not_le.mpr hn))

theorem rdBit_lt (j : Nat) (hj : j < 5) : rdBit j < coreInWidth := by
  revert j; decide +kernel

/-- ⭐⭐ **THE `rd` INDEX THE REGISTER FILE USES IS THE INSTRUCTION WORD'S OWN BITS 7…11,
read directly** — no decoder sits between them. *`regWriteSig` routes `rd` straight from
`instrNet`, so the enable arm's address half needs no decoder correctness at all; only its
`valid`/`isBEQ` half does.* -/
theorem core_rd_is_the_instruction (ins : Env) (j : Nat) (hj : j < 5) :
    run ins coreThru13 (rdBit j) = ins (instrNet (7 + j)) := by
  rw [coreThru13_input_stable ins (rdBit j) (rdBit_lt j hj)]
  rfl

#audit_axioms core_gates_from13 coreThru13_input_stable core_rd_is_the_instruction

/-! ## ⭐ THE VALUE ARM'S TRANSPORT — the counterpart, and the first brick of the open half

`RegDatapathOK`'s hold arm is closed and its enable arm's circuit half is closed. What remains
is the VALUE: when the enable is high, `selOut k` must equal the ISA's written bit. This is the
placement half of that — it says what `selOut k` IS when read inside `core`, exactly as
`core_rwOut_transport` does for the enable.

⛔ **IT PROVES A PLACEMENT, NOT A VALUE.** Nothing here says what `sliceASelect` COMPUTES; the
banks (`adder32`, `bitXor32`, `sltCirc` through `obMux`) are all still owed. This is the brick
the rest stands on, and it is the cheap one — said plainly because this seat has three times
today mistaken a structural step for progress on the expensive half.

⚠️ AND IT IS UPSTREAM OF TWO UNDECIDED QUESTIONS: `C4Refuted` proves `C4Spec core` FALSE by an
`ADDI` witness (the operand-B "immediate" bank is the B-type BRANCH displacement) and by an
`LW` witness (the enable fires and `core` has no memory). **This transport is true regardless
and is needed by every repair, which is why it lands before either is settled.** -/

/-- The eleven organ blocks before `sliceASelect`. -/
def coreThru11 : List Gate :=
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
    ++ instGates sltCirc sltSig offSlt

theorem coreThru13_sel_split :
    coreThru13 = coreThru11 ++ instGates SelectCut32.sliceASelect selSig offSel
                   ++ instGates EncoderE1.ruledEnc encSig offEnc := by
  simp only [coreThru13, coreThru11, List.append_assoc]

/-! ### `selOut`'s position, the analogue of `rwOut_eq` / `rwOut_lt_*` / `rwOut_mem`. -/

theorem sliceASelect_outs_len : SelectCut32.sliceASelect.outs.length = 32 := by decide +kernel

theorem selOut_eq (k : Nat) (hk : k < 32) :
    selOut k = instMap SelectCut32.sliceASelect selSig offSel
                 (SelectCut32.sliceASelect.outs.getD k 0) := by
  rw [selOut, instOuts]
  exact getD_map_lt _ _ _ (by rw [sliceASelect_outs_len]; exact hk) 0 0

theorem selOut_lt_offEnc (k : Nat) (hk : k < 32) : selOut k < offEnc := by
  revert k; decide +kernel

theorem selOut_lt_offRw (k : Nat) (hk : k < 32) : selOut k < offRw := by
  revert k; decide +kernel

theorem selOut_lt_offPc (k : Nat) (hk : k < 32) : selOut k < offPc := by
  revert k; decide +kernel

theorem selOut_lt_offRegNext (k : Nat) (hk : k < 32) : selOut k < offRegNext := by
  revert k; decide +kernel

theorem selOut_mem (k : Nat) (hk : k < 32) :
    (SelectCut32.sliceASelect.gates.map Gate.out).contains
      (SelectCut32.sliceASelect.outs.getD k 0) = true := by
  revert k; decide +kernel

/-- ⭐⭐ **THE VALUE ARM'S TRANSPORT — `selOut k` read inside `core` IS `sliceASelect`'s own
output `k`, evaluated on the environment the first ELEVEN organs produce.** The exact
counterpart of `core_rwOut_transport`, and the first brick of the VALUE half. -/
theorem core_selOut_transport (ins : Env) (k : Nat) (hk : k < 32) :
    run ins core.gates (selOut k)
      = run (fun a => run ins coreThru11 (selSig a)) SelectCut32.sliceASelect.gates
          (SelectCut32.sliceASelect.outs.getD k 0) := by
  rw [core_frame_below ins (selOut k) (selOut_lt_offRegNext k hk), corePre_split, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      SaltWorks.Stack.Program.pcAdd_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (selOut_lt_offPc k hk)))]
  rw [coreThruRw, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range regWrite regWriteSig offRw regWrite_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (selOut_lt_offRw k hk)))]
  rw [coreThru13_sel_split, run_append, run_append]
  rw [run_of_unwritten _ _ _ (fun g hg hEq => by
    have hge := (instGates_out_range EncoderE1.ruledEnc encSig offEnc
      EncoderE1.ruled_ssa g hg).1
    rw [hEq] at hge
    exact absurd hge (Nat.not_le.mpr (selOut_lt_offEnc k hk)))]
  rw [selOut_eq k hk]
  exact inst_sem SelectCut32.sliceASelect selSig offSel (run ins coreThru11)
      (fun a => run ins coreThru11 (selSig a)) sel_instOK (fun _ _ => rfl)
      (SelectCut32.sliceASelect.outs.getD k 0) (Or.inr (selOut_mem k hk))

#audit_axioms coreThru13_sel_split sliceASelect_outs_len selOut_eq
#audit_axioms selOut_lt_offEnc selOut_lt_offRw selOut_lt_offPc selOut_lt_offRegNext
#audit_axioms selOut_mem core_selOut_transport


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.coreThru13_sub SaltWorks.HDL.RegNextUniform.rdBit_lt
#audit_axioms SaltWorks.HDL.RegNextUniform.regWrite_outs_len SaltWorks.HDL.RegNextUniform.rwOut_lt_offPc
#audit_axioms SaltWorks.HDL.RegNextUniform.rwOut_lt_offRegNext SaltWorks.HDL.RegNextUniform.rwOut_mem
end SaltWorks.HDL.RegNextUniform
