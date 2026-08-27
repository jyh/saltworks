/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.MemOrganPlacement
import SaltWorks.HDL.DecoderLines

/-!
# The thirty-six datapath wires — memOrgan's placement with NO free parameters left

`MemOrganPlacement` reduced memOrgan's σ from "292 inputs, a datapath design question" to
**thirty-six wires**, with the other 256 discharged as layout. This file supplies the thirty-six
from organs already standing in `core`, and closes `instOK memOrgan` with nothing left open.

```
3   address     addOut (j+2)   — the adder's byte-address bits [4:2]
1   write-en    decOut 6       — isSW
32  write-data  rs2Out k       — readTree's rs2 port at its chain position
```

## Each choice is MEASURED, and the two that could be off by one are cited

**ADDRESS — `byte_addr[4:2]`, not `[2:0]`.** `SaltWorks/Silicon/RTL/dmem_addr8.v` states it in its
own header: *"word_index = byte_addr[4:2], 3 BITS"*, with `ISA.lean`'s `addrClass_ok_lt` proved
behind it — an `ok` address has its low two bits clear and is `< 32`, so the word index is exactly
bits 2,3,4. Taking `addOut 0,1,2` would index by byte and alias every fourth word.

**WRITE-ENABLE — `decOut 6`, and this seat has already been bitten by the neighbouring index.**
`CorePlace.lean:409` records the decoder's output order verbatim —
`isADD isXOR isSLT isADDI isBEQ isLW isSW req valid` — **so `isSW` is 6 and `isLW` is 5.** Reading
`decOut 5` where `6` was meant was a real landed defect, kernel-proved and repaired 2026-08-19.
The same off-by-one is available here and it is the reason this paragraph exists.

## ⛔⛔ WHAT `instOK` DOES AND DOES NOT CERTIFY — READ BEFORE QUOTING THE RESULT

`instOK` is a **TIMING AND STRUCTURE** property: the organ is dense SSA, well-formed, and every
input wire is computed before it runs. ***IT SAYS NOTHING ABOUT WHETHER THE RIGHT WIRE WAS
CHOSEN.*** This seat has the receipt: two placements once fed `rs2` where `ADDI` needs the
immediate, and **every `instOK` was TRUE.**

⇒ **so the theorem below closes the PLACEMENT and leaves the CORRESPONDENCE open**: that these
thirty-six nets carry the address, strobe and data the ISA's store semantics call for is a
statement about `sem`, it is not proved here, and no amount of `instOK` will reach it. The cheap
half — the two indices most likely to be wrong — is pinned by citation above and by the controls
in §4, which is not the same thing as proved.
-/

-- The 32-fold `interval_cases k <;> decide +kernel` in §2 evaluates `readTree`'s placed output
-- list once per bit. The tree's established budget for kernel-decided placement work —
-- CoreAssembly.lean:31, EnableX0.lean:58, C4Refuted.lean:58 all carry the same line.
set_option maxHeartbeats 4000000

namespace SaltWorks.HDL.MemWiring

open SaltWorks.HDL SaltWorks.HDL.CorePlace SaltWorks.HDL.MemOrganPlacement
open SaltWorks.HDL.DecoderLines

/-! ## §1 — THE THIRTY-SIX, FROM ORGANS ALREADY IN THE CHAIN -/

/-- Word index bit `j` — the adder's byte-address bit `j+2`. -/
def memAddrNet (j : Nat) : Net := CorePlace.addOut (j + 2)

/-- The store strobe: the decoder's `isSW` line, index 6. -/
def memWeNet : Net := decOut isSWLine

/-- ⭐ The name is not decoration: `isSWLine` is pinned to the match table's SW row in
`DecoderLines`, and the adjacent `isLWLine` is pinned beside it with a control proving the two
patterns differ. **The bare `6` that stood here is what cost this tree a landed defect on
08-19.** -/
theorem memWeNet_is_the_named_line : memWeNet = decOut isSWLine := rfl

/-- Write data bit `k`: `readTree`'s rs2 port at its chain position. -/
def memWDataNet (k : Nat) : Net := rs2Out k

/-- memOrgan sits after every organ that feeds it — the end of the placed chain. -/
def offMem : Nat := instNext regNext offRegNext

/-- The organ's σ with all thirty-six supplied. **No parameters remain.** -/
def memPlacementSigma : Net → Net := memSigma memAddrNet memWeNet memWDataNet

/-! ## §2 — THE PRODUCERS ALL FINISH BEFORE memOrgan STARTS -/

theorem addr_below (j : Nat) (hj : j < 3) : memAddrNet j < offMem := by
  interval_cases j <;> decide +kernel

theorem we_below : memWeNet < offMem := by decide +kernel

theorem wdata_below (k : Nat) (hk : k < 32) : memWDataNet k < offMem := by
  interval_cases k <;> decide +kernel

/-! ## §3 — THE PLACEMENT, CLOSED -/

/-- ⭐⭐⭐ **`instOK memOrgan` WITH NOTHING LEFT OPEN.** The 256 layout inputs fall to arithmetic,
the thirty-six datapath inputs to the chain. This is the last structural obligation on the
adapter-bearing assembly. -/
theorem mem_instOK_placed : instOK memOrgan memPlacementSigma offMem :=
  mem_instOK memAddrNet memWeNet memWDataNet offMem (by decide +kernel)
    addr_below we_below wdata_below

/-! ## §4 — CONTROLS, INCLUDING THE TWO OFF-BY-ONES THIS FILE IS MOST EXPOSED TO -/

/-- ⛔ **THE WRITE-ENABLE IS NOT `isLW`.** The neighbouring index is a different net, so the
08-19 defect's shape would be visible rather than silent. -/
theorem control_we_is_not_isLW : memWeNet ≠ decOut 5 := by decide +kernel

/-- ⛔ **THE ADDRESS IS NOT BYTE-INDEXED.** Bits [4:2] and bits [2:0] are different nets, so the
aliasing choice is a real fork and not a restatement. -/
theorem control_addr_is_not_byte_indexed : memAddrNet 0 ≠ CorePlace.addOut 0 := by decide +kernel

/-- ⛔ **THE THREE ADDRESS BITS ARE DISTINCT** — a collapsed address would index one word. -/
theorem control_addr_bits_distinct :
    memAddrNet 0 ≠ memAddrNet 1 ∧ memAddrNet 1 ≠ memAddrNet 2
      ∧ memAddrNet 0 ≠ memAddrNet 2 := by decide +kernel

/-- ⛔ **THE OFFSET IS LOAD-BEARING.** Placed at the adder's own offset, the address wires are
not yet computed and `instOK` fails — so §3 is not true for any offset whatsoever. -/
theorem control_offset_matters : ¬ (memAddrNet 0 < offAdd) := by decide +kernel

#audit_axioms memAddrNet memWeNet memWDataNet offMem memPlacementSigma
#audit_axioms memWeNet_is_the_named_line
#audit_axioms addr_below we_below wdata_below mem_instOK_placed
#audit_axioms control_we_is_not_isLW control_addr_is_not_byte_indexed
#audit_axioms control_addr_bits_distinct control_offset_matters

end SaltWorks.HDL.MemWiring
