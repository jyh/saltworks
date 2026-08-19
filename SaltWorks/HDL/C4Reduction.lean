/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# `C4Spec core` — thirty-four obligations become two

`c4Spec_iff_fieldwise` split `C4Spec core` into 34: an output count, thirty-two `RegField`s,
and `PcField`. Tonight closed the structural gap between those and the machine:

```
output count      core_outs_length            LANDED (CoreAssembly)
RegField core 0   regField_core_zero          LANDED (RegField0) — the free one
RegField core r   ⟸ RegDatapathOK             ONE hypothesis, all 32 at once
PcField core      —                           stands alone
```

⇒ ***`c4Spec_core_of_datapath_and_pc : RegDatapathOK → PcField core → C4Spec core`.***

⛔ **THIS IS A RESTRUCTURING, NOT PROGRESS ON THE DATAPATH, AND THE DISTINCTION IS THE
WHOLE VALUE OF SAYING IT PLAINLY.** `RegDatapathOK` contains the entire ALU/decode/select
path and `PcField` contains the pc path; **nothing here proves either.** What it buys is
that **no further structural work sits between those two sentences and `C4Spec`** — the
placement, the transport, the output map, the field split and the schema are all discharged,
so the next unit of work is datapath correctness and nothing else.

*Not C4, not a witness, does not close R9/B2. Criterion (c) remains open at the RTL site.*
-/
import SaltWorks.HDL.RegField0

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- **THE REGISTER DATAPATH OBLIGATION — one sentence covering all thirty-two registers.**
Its two sides are exactly the two reads the schema left open: `rwOut r` (which register is
being written) and `selOut k` (what is being written), both register-independent in form. -/
def RegDatapathOK : Prop :=
  ∀ (ins : Env) (r : Fin 32) (k : Nat), k < 32 →
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k

/-- ⭐⭐ **ONE HYPOTHESIS DISCHARGES ALL THIRTY-TWO `RegField`s.** This is the schema
cashed: the reduction is done, so what remains is a single datapath sentence. -/
theorem regFields_of_datapath (h : RegDatapathOK) : ∀ r : Fin 32, RegField core r := by
  intro r
  rw [regField_iff_bits]
  intro ins k hk
  rw [core_outBit_reg_reduced ins r.val k r.isLt hk]
  exact h ins r k hk

/-- ⭐⭐⭐ **`C4Spec core` FROM TWO OBLIGATIONS.** The output count is landed
(`core_outs_length`); the thirty-two register fields collapse to `RegDatapathOK`; `PcField`
stands alone. **Thirty-four became two.**

⛔ **AND THE TWO ARE NOT SMALL — this is a restructuring, not progress on the datapath.**
`RegDatapathOK` contains the entire ALU/decode/select path; `PcField` contains the pc path.
Nothing here proves either. What it buys is that no *further* structural work sits between
them and `C4Spec`. -/
theorem c4Spec_core_of_datapath_and_pc (h : RegDatapathOK) (hpc : PcField core) :
    SaltWorks.HDL.C4Spec core :=
  c4Spec_of_fieldwise core_outs_length (regFields_of_datapath h) hpc

/-- **NON-VACUITY, and it is not free of content:** the `r = 0` instance of `RegDatapathOK`
is already a theorem — that is exactly `regField_core_zero`'s content — so the obligation
is known satisfiable at one register rather than merely unrefuted. -/
theorem regDatapath_holds_at_zero (ins : Env) (k : Nat) (hk : k < 32) :
    (if run ins core.gates (rwOut 0) then run ins core.gates (selOut k)
     else ins (32 * 0 + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[0]).getLsbD k := by
  rw [core_rwOut0_false ins, SaltWorks.Stack.Program.stepT_regs_zero, decQ_reg0_bit ins k hk]
  simp

#audit_axioms regFields_of_datapath c4Spec_core_of_datapath_and_pc regDatapath_holds_at_zero

end SaltWorks.HDL.RegNextUniform
