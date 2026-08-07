/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Decoder

/-!
# C4 · `core` — IMMEDIATE EXTRACTION

Third block of `compile`/`core`, and the one that costs **almost no gates and
most of the risk**.

## Why a block with (nearly) no gates gets its own certificate

Immediate extraction is **wiring**: every output bit is some input bit, or a
replication of the sign bit, or a structural zero. The `I`-type immediate needs
**zero gates**; the `B`-type needs **one**, for the implicit low zero.

⛔ **And that is exactly why it is dangerous.** A wiring block cannot fail a
*gate-level* check because it has no gates to get wrong — it fails by being
wired to the wrong bit, silently, in a way that every structural measurement
reports as perfect. ***This campaign has already been bitten here once:*** the
codegen freeze's `BEQ` offsets were **short by exactly one instruction** under
two live conventions, and `C6` had named *"an off-by-one branch offset"* as its
own mutation control — **so the mutant was the bug**.

📌 **The `B`-type immediate is the classic RISC-V transcription error**, because
its bits are *scrambled across the word* rather than contiguous:

```
imm bit   11      10       9…4        3…0
from w    [31]    [7]      [30…25]    [11…8]
```

**and the whole field denotes `imm[12:1]`**, so the byte displacement is
`sext(imm) * 2` — the low zero is structural and unrepresentable, which is the
convention `ISA.lean` pins and `bOffset` computes.

## What is certified

Not "the wiring looks right" but **the wired bits equal what `ISA.decode`
followed by `bOffset` actually produces**, exhaustively over every immediate
field value.
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### The `I`-type immediate — `ADDI`, sign-extended from bit 31 -/

/-- Bit `k` of `sext(w[31:20])`. Bits 0–11 are the field; 12–31 replicate the
sign bit. **No gate: every output is an input net.** -/
def immI (k : Nat) : Net := if k < 12 then 20 + k else 31

/-- The `I`-immediate as a `Circ` — 32 outputs, **zero gates**. -/
def immICirc : Circ :=
  { nIn := 32, gates := [], outs := (List.range 32).map immI }

theorem immICirc_wf : immICirc.wf = true := by decide +kernel

theorem immICirc_has_no_gates : immICirc.gates.length = 0 := by decide +kernel

/-! ### The `B`-type immediate — `BEQ`, scrambled, then doubled -/

/-- Net carrying bit `j` of the 12-bit field `imm[12:1]`, per the table above. -/
def immBField (j : Nat) : Net :=
  if j < 4 then 8 + j
  else if j < 10 then 25 + (j - 4)
  else if j = 10 then 7
  else 31

/-- The structural low zero lives on net 32 — the block's only gate. -/
def immBZero : Net := 32

/-- Bit `k` of the byte displacement `sext(imm) * 2`. Bit 0 is the structural
zero; bits 1–12 are the field shifted up; 13–31 replicate the sign. -/
def immB (k : Nat) : Net :=
  if k = 0 then immBZero
  else if k < 13 then immBField (k - 1)
  else immBField 11

/-- The `B`-displacement as a `Circ` — 32 outputs, **one gate**. -/
def immBCirc : Circ :=
  { nIn := 32, gates := [⟨immBZero, .const false⟩], outs := (List.range 32).map immB }

theorem immBCirc_wf : immBCirc.wf = true := by decide +kernel

theorem immBCirc_has_one_gate : immBCirc.gates.length = 1 := by decide +kernel

/-! ### The certificates — against `ISA.decode`, not against the table

*The table above is prose; if I mis-transcribed it into `immBField`, a check
against the table would agree with the mistake. So both certificates evaluate
the circuit and compare against what `decode` and `bOffset` actually compute.* -/

/-- A well-formed `ADDI` word carrying immediate field `v` (12 bits). -/
def wordI (v : Nat) : BitVec 32 := encode (.ADDI 1 0 (BitVec.ofNat 12 v))

/-- A well-formed `BEQ` word carrying immediate field `v` (12 bits). -/
def wordB (v : Nat) : BitVec 32 := encode (.BEQ 1 2 (BitVec.ofNat 12 v))

/-- **`ADDI`: the wiring reproduces `sext(imm)` for all 4096 field values.** -/
def immI_OK : Bool :=
  (List.range 4096).all fun v =>
    sem immICirc (fun i => (wordI v).getLsbD i)
      == (List.range 32).map ((BitVec.ofNat 12 v).signExtend 32).getLsbD

theorem immI_correct : immI_OK = true := by decide +kernel

/-- **`BEQ`: the wiring reproduces `bOffset` — the scramble AND the doubling —
for all 4096 field values.** -/
def immB_OK : Bool :=
  (List.range 4096).all fun v =>
    sem immBCirc (fun i => (wordB v).getLsbD i)
      == (List.range 32).map (bOffset (BitVec.ofNat 12 v)).getLsbD

theorem immB_correct : immB_OK = true := by decide +kernel

/-! ### Non-vacuity, and the mutation the freeze already suffered -/

/-- **The low bit of a `B` displacement is ALWAYS zero** — the structural bit
that makes odd offsets unrepresentable rather than silently truncated. -/
theorem immB_low_bit_is_structural :
    ((List.range 4096).all fun v =>
      (sem immBCirc (fun i => (wordB v).getLsbD i)).getD 0 true == false) = true := by
  decide +kernel

/-- **THE OFF-BY-ONE MUTANT, kernel-refuted.** `C6` named "an off-by-one branch
offset" as its mutation control and the freeze then shipped that very bug. Here
the mutant is a displacement wired one bit lower — i.e. *forgetting the
doubling* — and it must NOT match `bOffset`. -/
def immBshifted (k : Nat) : Net := if k < 12 then immBField k else immBField 11

def immBshiftedCirc : Circ :=
  { nIn := 32, gates := [⟨immBZero, .const false⟩],
    outs := (List.range 32).map immBshifted }

theorem immB_rejects_the_undoubled_wiring :
    ((List.range 4096).all fun v =>
      sem immBshiftedCirc (fun i => (wordB v).getLsbD i)
        == (List.range 32).map (bOffset (BitVec.ofNat 12 v)).getLsbD) = false := by
  decide +kernel

/-- And the immediates are not constantly zero. -/
theorem immI_is_not_constant :
    sem immICirc (fun i => (wordI 1).getLsbD i)
      ≠ sem immICirc (fun i => (wordI 2).getLsbD i) := by decide +kernel

#audit_axioms immI
#audit_axioms immICirc
#audit_axioms immICirc_wf
#audit_axioms immICirc_has_no_gates
#audit_axioms immBField
#audit_axioms immB
#audit_axioms immBCirc
#audit_axioms immBCirc_wf
#audit_axioms immBCirc_has_one_gate
#audit_axioms immI_correct
#audit_axioms immB_correct
#audit_axioms immB_low_bit_is_structural
#audit_axioms immB_rejects_the_undoubled_wiring
#audit_axioms immI_is_not_constant

end SaltWorks.HDL
