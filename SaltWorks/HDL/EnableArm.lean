/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The ENABLE arm's transport

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

end SaltWorks.HDL.RegNextUniform
