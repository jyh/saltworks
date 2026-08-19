/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The `SW` witness — a refutation, and the repair that retired it

⭐⭐⭐ **THIS FILE ONCE PROVED `¬ C4Spec core`. IT NO LONGER CAN, AND THAT IS THE POINT.**
On 2026-08-19 it carried, in the kernel:

```
  regDatapathOK_is_false      : ¬ RegDatapathOK                       -- PROVED
  regField_core_four_is_false : ¬ RegField core ⟨4,_⟩                 -- PROVED
  c4Spec_core_is_false        : ¬ C4Spec core                         -- PROVED
```

against `core` **as it was assembled that morning**, with the witness `SW x1, x2, 4`: the
store's `imm[4:0]` is `4`, the enable read bits 7…11 as an `rd`, so the circuit write-enabled
register 4 while the ISA held it. Its own docstring said those were DIFFERENTIAL receipts and
that **a repair leaving them compiling had not been made.**

⇒ ***THE REPAIR WAS MADE, AND THEY STOPPED COMPILING.*** `regWrite`'s enable now reads
`writes = isADD ∨ isXOR ∨ isSLT ∨ isADDI ∨ isLW`, which the `SW` row does not raise. **What
survives here is the same witness, evaluated the same way, reporting the opposite answer** —
`witness_no_longer_enables` below. *A refutation that dies to a repair is the only kind worth
landing, and it is kept rather than deleted so the next reader can see BOTH halves.*

⛔ **WHAT THIS DOES NOT SAY.** `C4Spec core` is **not** proved — it is merely no longer refuted
by this witness. The 31 `RegField` rows still need `selOut`'s VALUE against the ISA result, the
expensive half, untouched by the enable repair. **Do not read a green tree here as the flagship
recovered.**

⚠️ The packed evaluator this file introduced now lives in `Sem.lean` (`runB`/`semB` with
`runB_eq`/`semB_eq`), lifted there so every organ certificate can use it. The local copies are
gone; a duplicate under a second qualified name is exactly the hazard this seat banked.
-/
import SaltWorks.HDL.DecoderTransport

namespace SaltWorks.HDL.C4Refuted
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.HDL.RegNextUniform

set_option maxHeartbeats 4000000

/-! ## The witness environment, presented as a packed `Nat`. -/

/-- `SW x1, x2, 4` = `2138659#32`. -/
def wSW : BitVec 32 := encode (.SW 1 2 4)

/-- Register 4 bit 0 (net 128) set; pc = 0; the word at nets 1056…1087. -/
def s0 : Nat := 2 ^ 128 ||| (2138659 * 2 ^ 1056)

def ins0 : Env := fun n => s0.testBit n

theorem seen_ins0 : seenWord ins0 = wSW := by decide +kernel
theorem rd_ins0 : rdOf ins0 = 4 := by decide +kernel
theorem held_ins0 : ins0 (32 * rdOf ins0 + 0) = true := by rw [rd_ins0]; decide +kernel

/-! ## The packed evaluation (STRICT: the kernel forces every one of the 10394 gates). -/

/-- ⭐ **THE PACKED WITNESS** — every one of `core`'s 10394 gates evaluated by the kernel. -/
theorem bFull : (runB s0 core.gates).testBit 7675 = false := by decide +kernel

theorem selOut0_net : selOut 0 = 7675 := by decide +kernel

theorem dec_ins0 : decode (seenWord ins0) = some (.SW 1 2 4) := by
  rw [seen_ins0]; exact decode_encode _

theorem rdOf_ins0_ne_zero : ¬ (rdOf ins0 = 0) := by rw [rd_ins0]; decide

/-- ⭐⭐⭐ **THE REPAIR, AT THE EXACT WITNESS THAT REFUTED THE FLAGSHIP.** Same environment,
same gate list, same packed evaluator — and the enable that used to be `true` is now `false`.

⛔ **THIS IS THE DIFFERENTIAL IN ONE LINE.** Before the repair this seat proved
`run ins0 core.gates (rwOut 4) = true` here (`control_packed_true`); the store's immediate bits
selected register 4 and the circuit clobbered it. **The same expression is now `false`, and
nothing about the witness changed.** -/
theorem witness_no_longer_enables : run ins0 core.gates (rwOut 4) = false :=
  (runB_eq core.gates s0 (rwOut 4)).symm.trans (by decide +kernel)

/-- **AND SYMBOLICALLY, WITHOUT EVALUATING A GATE** — `core_writes_nothing_on_SW` says it for
every register on any store; this instantiates it at the witness, so the packed evaluation and
the symbolic proof are checked against each other exactly as they were before the repair. -/
theorem witness_no_longer_enables_symbolic :
    run ins0 core.gates (rwOut (rdOf ins0)) = false :=
  core_writes_nothing_on_SW ins0 (rdOf ins0) (rdOf_lt ins0) 1 2 4 dec_ins0

theorem witness_same_net :
    run ins0 core.gates (rwOut 4) = run ins0 core.gates (rwOut (rdOf ins0)) := by
  rw [rd_ins0]

/-- **THE ISA STILL WRITES NOTHING ON A STORE** — unchanged by the repair, and the half that
was never in doubt. Both sides now agree, which is what `RegDatapathOK` asks for at this
register. -/
theorem isa_writes_nothing_on_SW (a b : Fin 32) (imm : BitVec 12) :
    writesReg (.SW a b imm) = none := rfl

#audit_axioms wSW s0 ins0 seen_ins0 rd_ins0 held_ins0
#audit_axioms dec_ins0 rdOf_ins0_ne_zero isa_writes_nothing_on_SW
#audit_axioms witness_no_longer_enables witness_no_longer_enables_symbolic witness_same_net

set_option pp.fullNames true in
#check @witness_no_longer_enables

end SaltWorks.HDL.C4Refuted
