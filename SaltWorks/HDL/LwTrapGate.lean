/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# R9a — THE TRAP GATE, AS AN ORGAN: `lwWr = isLW ∧ ¬trap`

Ruling z (council 2026-08-31) released the leg-1 core repair: on a TRAPPING load the ISA
holds `rd` (`step`'s trap arm writes nothing) while the assembled core write-enables and
puts the computed address on the write bank — kernel-proved at `insT`
(`LwTrapRefuted.regDatapathOK_is_false_on_trapping_LW`, retired by this repair's landing
act). The cure argued in that file's bank is BUILT here: the write enable's `isLW`
contribution is gated on the address NOT trapping.

**What `trap` means is `ISA.addrClass`'s complement, read off its definition, not invented:**
`addrClass a = ok  ↔  a.toNat < 32 ∧ a.toNat % 4 = 0`, so over the 32 address bits
`trap = a₀ ∨ a₁ ∨ a₅ ∨ a₆ ∨ … ∨ a₃₁` — bits 0,1 are misalignment, bits 5…31 are range.
Bits 2,3,4 are the in-range word index and do not appear. 29 bits, one OR fold.

**Port layout** (the σ lives in `CorePlace`, beside the other seventeen):
ports `0…28` are the 29 trap-relevant ADDRESS bits in ascending bit order
(`0,1,5,6,…,31`); port `29` is `isLW`. One output: `isLW ∧ ¬(⋁ trap bits)`.

⭐ **THE `regWrite` ORGAN IS DELIBERATELY UNTOUCHED.** Its spec (`weSpec`), its exhaustive
certificate (`regWrite_correct`) and its 128-case unpacking all stand; the semantic change
enters the core through ONE σ re-aim (`regWriteSig` port 10, `decOut isLWLine` → this
organ's output). The repair is therefore auditable as: one new organ, one moved wire.
-/
import SaltWorks.HDL.Compose

namespace SaltWorks.HDL

/-- **THE TRAP GATE.** Ports `0…28`: the trap-relevant address bits, ascending
(`addr[0], addr[1], addr[5], …, addr[31]`). Port `29`: `isLW`.
Gates: a 28-gate left OR fold over ports `0…28` (nets `30…57`), `¬trap` at `58`,
`isLW ∧ ¬trap` at `59`. Output: net `59`. -/
def lwWrCirc : Circ :=
  { nIn   := 30
  , gates :=
      [⟨30, .or 0 1⟩,   ⟨31, .or 30 2⟩,  ⟨32, .or 31 3⟩,  ⟨33, .or 32 4⟩,
       ⟨34, .or 33 5⟩,  ⟨35, .or 34 6⟩,  ⟨36, .or 35 7⟩,  ⟨37, .or 36 8⟩,
       ⟨38, .or 37 9⟩,  ⟨39, .or 38 10⟩, ⟨40, .or 39 11⟩, ⟨41, .or 40 12⟩,
       ⟨42, .or 41 13⟩, ⟨43, .or 42 14⟩, ⟨44, .or 43 15⟩, ⟨45, .or 44 16⟩,
       ⟨46, .or 45 17⟩, ⟨47, .or 46 18⟩, ⟨48, .or 47 19⟩, ⟨49, .or 48 20⟩,
       ⟨50, .or 49 21⟩, ⟨51, .or 50 22⟩, ⟨52, .or 51 23⟩, ⟨53, .or 52 24⟩,
       ⟨54, .or 53 25⟩, ⟨55, .or 54 26⟩, ⟨56, .or 55 27⟩, ⟨57, .or 56 28⟩,
       ⟨58, .not 57⟩,   ⟨59, .and 29 58⟩]
  , outs  := [59] }

theorem lwWrCirc_ssa : lwWrCirc.ssa = true := by decide +kernel
theorem lwWrCirc_wf  : lwWrCirc.wf  = true := by decide +kernel
theorem lwWrCirc_gate_count : lwWrCirc.gates.length = 30 := by decide +kernel

/-- The OR fold the trap half computes, in the chain's own left-associated shape. -/
def lwTrapFold (env : Env) : Bool :=
  env 0 || env 1 || env 2 || env 3 || env 4 || env 5 || env 6 || env 7 || env 8
    || env 9 || env 10 || env 11 || env 12 || env 13 || env 14 || env 15 || env 16
    || env 17 || env 18 || env 19 || env 20 || env 21 || env 22 || env 23 || env 24
    || env 25 || env 26 || env 27 || env 28

/-- ⭐⭐ **THE ORGAN'S SEMANTICS, OVER EVERY VALUATION** — not a sample: the output is
`isLW ∧ ¬(⋁ ports 0…28)` for arbitrary `env`. This is what the core-level bridge
(`EnableSpec`) consumes, so the enable's new formula is a theorem, not a wiring hope. -/
theorem lwWrCirc_sem (env : Env) :
    sem lwWrCirc env = [env 29 && !(lwTrapFold env)] := by
  simp [sem, run, upd, Op.eval, lwWrCirc, lwTrapFold]

/-! ### The organ's two directions, DRIVEN (organ-level; the in-core drives are the
`insT`/`insL` witnesses in `LwTrapRefuted`). A gate that cannot be seen to refuse is not
known to refuse. -/

/-- Clean address, `isLW` high ⇒ the enable contribution PASSES. -/
theorem lwWrCirc_passes_clean :
    sem lwWrCirc (fun i => i == 29) = [true] := by decide +kernel

/-- ONE trap bit (misalignment, port 0), `isLW` high ⇒ REFUSED. -/
theorem lwWrCirc_blocks_misaligned :
    sem lwWrCirc (fun i => i == 29 || i == 0) = [false] := by decide +kernel

/-- ONE trap bit (range, port 28 = address bit 31), `isLW` high ⇒ REFUSED. -/
theorem lwWrCirc_blocks_out_of_range :
    sem lwWrCirc (fun i => i == 29 || i == 28) = [false] := by decide +kernel

/-- Not a load ⇒ the contribution is `false` REGARDLESS of the address — the gate cannot
enable anything `isLW` did not already ask for. -/
theorem lwWrCirc_off_when_not_LW :
    sem lwWrCirc (fun i => !(i == 29)) = [false] := by decide +kernel

#audit_axioms lwWrCirc lwWrCirc_ssa lwWrCirc_wf lwWrCirc_gate_count
#audit_axioms lwTrapFold lwWrCirc_sem
#audit_axioms lwWrCirc_passes_clean lwWrCirc_blocks_misaligned
#audit_axioms lwWrCirc_blocks_out_of_range lwWrCirc_off_when_not_LW

end SaltWorks.HDL
