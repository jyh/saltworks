/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The pc half — the 33rd obligation, reduced

`C4Reduction` left `C4Spec core` on `RegDatapathOK ∧ PcField core`. This file does for the
pc what `RegNextUniform` did for the registers: transports the organ's outputs through the
placement, so `PcField` stops being a raw obligation and becomes a **datapath sentence of the
same shape as the register one**.

```
core_outBit_pc  : outBit core ins (1024+k) = pcAdd's own output k, on the
                  environment the first fourteen organs produce
pcField_of_datapath : PcDatapathOK → PcField core
c4Spec_core_of_two_datapaths : RegDatapathOK → PcDatapathOK → C4Spec core
```

⚠️ **WHY THIS WAS DONE NOW, AND IT IS A REVERSAL WORTH STATING.** At 22:15 this seat argued
*against* taking `PcField` first, on the ground that it reads a different organ and buys
nothing about the 32. **That argument was about ORDERING while the shared register work was
available.** It no longer is: `a10f980` proved `core`'s write-enable is wired to `decOut 5`
(`isLW`) instead of `decOut 8` (`valid`), so `RegDatapathOK` is false until an owner outside
this seat repairs `CorePlace`. **`PcField` is the only unblocked object left, and `pcAddSig`
reads `decOut 4` = `isBEQ`, verified correct in the blast-radius sweep.** *The reason changed;
the judgement did not.*

⛔ **STILL A REDUCTION, NOT A PAYMENT.** `PcDatapathOK` contains the whole pc/branch path and
is not proved here. Not C4, not a witness, does not close R9/B2, criterion (c) open.
-/
import SaltWorks.HDL.DecoderTransport

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- `getD` through a `drop`. -/
theorem getD_drop {α} [Inhabited α] (l : List α) (n k : Nat) (d : α) :
    (l.drop n).getD k d = l.getD (n + k) d := by
  simp [List.getD, List.getElem?_drop]

theorem pcAdd_outs_len : SaltWorks.Stack.Program.pcAdd.outs.length = 32 := by decide +kernel

theorem pcOut_lt_offRegNext (k : Nat) (hk : k < 32) :
    instMap SaltWorks.Stack.Program.pcAdd pcAddSig offPc
      (SaltWorks.Stack.Program.pcAdd.outs.getD k 0) < offRegNext := by
  revert k; decide +kernel

theorem pcAdd_out_mem (k : Nat) (hk : k < 32) :
    (SaltWorks.Stack.Program.pcAdd.gates.map Gate.out).contains
      (SaltWorks.Stack.Program.pcAdd.outs.getD k 0) = true := by
  revert k; decide +kernel

/-- Output bit `1024+k` of `core` names the relocated `pcAdd` output `k`. -/
theorem core_outs_pc_index (k : Nat) (hk : k < 32) :
    core.outs.getD (1024 + k) 0
      = instMap SaltWorks.Stack.Program.pcAdd pcAddSig offPc
          (SaltWorks.Stack.Program.pcAdd.outs.getD k 0) := by
  rw [← getD_drop core.outs 1024 k 0, core_outs_pc_half, instOuts,
      getD_map_lt _ _ _ (by rw [pcAdd_outs_len]; exact hk) 0 0]

/-- ⭐⭐ **THE PC HALF, TRANSPORTED.** Output bit `1024+k` of `core` IS `pcAdd`'s own output
`k`, evaluated on the environment the first fourteen organs produce. *Mirror of
`core_outBit_reg` for the 33rd obligation — and unaffected by the `valid` defect, since
`pcAddSig` reads `decOut 4` = `isBEQ`, verified correct.* -/
theorem core_outBit_pc (ins : Env) (k : Nat) (hk : k < 32) :
    SaltWorks.Stack.Program.outBit core ins (1024 + k)
      = run (fun a => run ins coreThruRw (pcAddSig a)) SaltWorks.Stack.Program.pcAdd.gates
          (SaltWorks.Stack.Program.pcAdd.outs.getD k 0) := by
  have hlen : core.outs.length = 1056 := by rw [core_outs_length]; rfl
  have hlt : 1024 + k < core.outs.length := by rw [hlen]; omega
  show (core.outs.map (run ins core.gates)).getD (1024 + k) false = _
  rw [getD_map_lt _ _ _ hlt 0 false, core_outs_pc_index k hk,
      core_frame_below ins _ (pcOut_lt_offRegNext k hk), corePre_split, run_append]
  exact inst_sem SaltWorks.Stack.Program.pcAdd pcAddSig offPc (run ins coreThruRw)
    (fun a => run ins coreThruRw (pcAddSig a)) pcAdd_instOK (fun _ _ => rfl)
    (SaltWorks.Stack.Program.pcAdd.outs.getD k 0) (Or.inr (pcAdd_out_mem k hk))

/-! ### ⭐ THE 33rd OBLIGATION, REDUCED TO A DATAPATH SENTENCE -/

/-- **The pc datapath obligation** — the same shape as `RegDatapathOK`: an organ's own
output against the ISA, with every structural step discharged. -/
def PcDatapathOK : Prop :=
  ∀ (ins : Env) (k : Nat), k < 32 →
    run (fun a => run ins coreThruRw (pcAddSig a)) SaltWorks.Stack.Program.pcAdd.gates
        (SaltWorks.Stack.Program.pcAdd.outs.getD k 0)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).pc).getLsbD k

theorem pcField_of_datapath (h : PcDatapathOK) : PcField core := by
  rw [pcField_iff_bits]
  intro ins k hk
  rw [core_outBit_pc ins k hk]
  exact h ins k hk

/-- ⭐⭐⭐ **`C4Spec core` FROM TWO DATAPATH SENTENCES.** Both remaining objects now have the
SAME shape — an organ's output against the ISA — and **every structural step between them
and `C4Spec` is discharged**: placement, transport, output map, field split, schema, and the
pc half.

⛔ **STILL A REDUCTION, NOT A PAYMENT.** `RegDatapathOK` contains the ALU/decode/select path
and is **currently FALSE** at the mis-wired `valid` port (`a10f980`); `PcDatapathOK` contains
the pc/branch path and is untouched. *Neither is proved here.* -/
theorem c4Spec_core_of_two_datapaths (h1 : RegDatapathOK) (h2 : PcDatapathOK) :
    SaltWorks.HDL.C4Spec core :=
  c4Spec_core_of_datapath_and_pc h1 (pcField_of_datapath h2)

#audit_axioms getD_drop core_outs_pc_index core_outBit_pc
#audit_axioms pcField_of_datapath c4Spec_core_of_two_datapaths

end SaltWorks.HDL.RegNextUniform
