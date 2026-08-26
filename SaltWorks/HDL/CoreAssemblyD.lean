/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# THE D-WIDTH PLACEMENT ARITHMETIC — c4spec STEP 7, the half that is provable today

`core_outs_length_ne_stWidthD` (C4Refuted) says the landed assembly has the wrong width for
`C4SpecD`: `core.outs.length = stWidth = 1056`, and `stWidthD = 1313`. The gap is 257 bits —
256 memory + 1 trap (`extension_costs_257_bits`).

⭐ **THE LEVER THIS FILE USES: `instOuts` IS A `map`, SO THE EMBEDDED OUTPUT COUNT DOES NOT
DEPEND ON THE WIRING.** `instOuts c σ off = c.outs.map (instMap c σ off)`, and `List.length_map`
kills σ and `off` outright. ⇒ **the WIDTH obligation can be discharged before the WIRING exists**,
which is what makes step 7 separable rather than one indivisible lump.

⛔ **WHAT THIS FILE DOES NOT DO, STATED SO NOBODY READS IT AS STEP 7 DISCHARGED.**
* It does **not** wire `memOrgan`. The σ for its 292 inputs — 3 address, 1 write-enable, 32
  write-data, 256 Q-leaves — is a datapath design question and is not answered here.
* It does **not** discharge `instOK memOrgan _ _`. No placement is claimed.
* It does **not** produce the trap bit. There is no gate-level trap next-state producer in any
  landed module; that is the one-bit residual on the block register, and this file's central
  theorem is the arithmetic statement OF that residual rather than a repair of it.
* `coreShapedD` (C4Refuted) remains what its own docstring says: a zero-gate width witness that
  must never be read as a step-7 candidate. Nothing here changes that.
-/
import SaltWorks.HDL.CoreAssembly
import SaltWorks.HDL.MemOrgan
import SaltWorks.HDL.StateCodecD

namespace SaltWorks.HDL.CoreAssemblyD
-- ⛔ `stWidthD` lives in `SaltWorks.HDL.StateCodecD`, NOT in `SaltWorks.HDL`. The first cut
-- opened only the latter two and every theorem mentioning `stWidthD` failed with "Unknown
-- identifier" — then `#audit_axioms` reported the SAME theorems as depending on `sorryAx`,
-- because an elaboration failure leaves a sorry behind. Five real errors, four cascaded ones,
-- one cause. (C4Refuted refers to it fully qualified, which is why the name looked available.)
open SaltWorks.HDL SaltWorks.HDL.CorePlace SaltWorks.HDL.StateCodecD

/-- **The wiring cannot change an output count.** `instOuts` maps over `c.outs`, so the number
of bits an organ contributes to the host is fixed by the organ alone — independent of σ and of
the offset it is placed at. *This is the whole reason the width half of step 7 is separable from
the placement half.* -/
theorem instOuts_length_eq (c : Circ) (σ : Net → Net) (off : Nat) :
    (instOuts c σ off).length = c.outs.length := by
  simp only [instOuts, List.length_map]

/-- `memOrgan`'s outputs are the 32-bit read port followed by the 256 next-state bits, so
dropping the read port leaves exactly the D-roots. -/
theorem memOrgan_next_length : (memOrgan.outs.drop 32).length = 256 := by
  have h : memOrgan.outs.length = 288 := memOrgan_ports.2
  simp only [List.length_drop, h]

/-- The same count, seen through a placement at an ARBITRARY σ and offset. -/
theorem memOrgan_next_length_placed (σ : Net → Net) (off : Nat) :
    ((instOuts memOrgan σ off).drop 32).length = 256 := by
  have h : (instOuts memOrgan σ off).length = 288 := by
    rw [instOuts_length_eq]; exact memOrgan_ports.2
  simp only [List.length_drop, h]

/-- The D layout's four fields, as a sum. -/
theorem d_width_decomposition : 1024 + 32 + 256 + 1 = stWidthD := by decide +kernel

/-- ⭐⭐⭐ **PLACING `memOrgan` REACHES EVERY D BIT EXCEPT THE TRAP FLAG.**

*The landed assembly contributes `stWidth = 1056` (1024 register + 32 pc); `memOrgan`'s
next-state half contributes 256. Their sum is `1312 = stWidthD - 1`.* ⇒ **the block register's
one-bit residual is not a matter of judgement — it is this arithmetic**, and any placement of
`memOrgan`, at any wiring, lands exactly one bit short of `C4SpecD`'s width conjunct. -/
theorem placement_reaches_all_but_trap :
    core.outs.length + (memOrgan.outs.drop 32).length = stWidthD - 1 := by
  rw [core_outs_length, memOrgan_next_length]
  decide +kernel

/-- The same statement in the form a future `coreD` will actually meet it: the width conjunct
of `C4SpecD` is `stWidthD`, and a register+pc+memory assembly is one short of it. -/
theorem reg_pc_mem_is_one_short : 1024 + 32 + 256 + 1 = stWidthD ∧ 1024 + 32 + 256 ≠ stWidthD := by
  refine ⟨d_width_decomposition, ?_⟩
  decide +kernel

/-- ⛔ **AND THE RESIDUAL IS EXACTLY ONE BIT — not "some more bits".** Stated separately because
"257 more output bits" is the number people carry, and after a `memOrgan` placement the number
is `1`. -/
theorem residual_after_placement : stWidthD - (core.outs.length + (memOrgan.outs.drop 32).length) = 1 := by
  rw [core_outs_length, memOrgan_next_length]
  decide +kernel

#audit_axioms instOuts_length_eq memOrgan_next_length memOrgan_next_length_placed
#audit_axioms d_width_decomposition placement_reaches_all_but_trap
#audit_axioms reg_pc_mem_is_one_short residual_after_placement

end SaltWorks.HDL.CoreAssemblyD
