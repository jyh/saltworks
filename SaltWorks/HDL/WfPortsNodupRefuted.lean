/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Bitwise
import SaltWorks.HDL.Immediate

/-! # Clause ①⁵ (`portsNodup`) is UNSOUND as an acceptance bar — MIG-5

`docs/wf-ports-nodup-design-v1.md` §2 proposes clause **①⁵**: *every NEW block certifies*
`Circ.portsNodup c := c.outs.Nodup`.

⛔ **THAT BAR REJECTS SIGN-EXTENSION AND ZERO-EXTENSION.** A net legitimately fans out to
many output ports: an N-bit field widened to 32 bits drives the SAME net at every position
above N. The theorems below are the counterexamples, and they are LANDED, CERTIFIED blocks.

```
  block             |outs|   distinct   why the duplicates are CORRECT
  sltCirc              32        2       1-bit compare result, ZERO-extended to 32
  sltuCirc             32        2       same
  immICirc             32       12       12-bit I-type immediate, SIGN-extended
  immBCirc             32       13       13-bit B-type displacement, SIGN-extended
  immBshiftedCirc      32       12       same
```

⇒ **①⁵ IS NOT MERELY UNLANDED, IT IS UNSOUND.** `Circ.portsNodup` occurs in ZERO `.lean`
files (checked by name AND by conclusion shape, `outs.Nodup`), so nothing enforces it today —
but adopting it as written would convict correct hardware.

⚠️ **AND COST IS NOT THE BINDING CONSTRAINT, which is worth saying because the debt asked:**
deciding `Nodup` on a 32-element list is ~1024 comparisons, trivial at this scale. **The bar
fails on CORRECTNESS long before it fails on cost** — pricing it first would have measured the
wrong thing and returned a comfortable number.

📌 **WHAT THE BAR APPEARS TO WANT** is that no two ports are *accidentally* aliased. `outs.Nodup`
cannot express that: it cannot distinguish a deliberate fan-out from a copy-paste slip, because
both produce the same list. A repair has to name the intent, not the shape.
-/

namespace SaltWorks.HDL.MIG5
open SaltWorks.HDL

/-- ①⁵'s predicate, inlined from the design block because it is landed nowhere. -/
def portsNodupB (c : Circ) : Bool := c.outs.length == c.outs.eraseDups.length

/-- ⛔ `sltCirc` has 32 ports carrying only 2 distinct nets — a zero-extended compare result. -/
theorem sltCirc_fails_clause5 :
    sltCirc.outs.length = 32 ∧ sltCirc.outs.eraseDups.length = 2
    ∧ portsNodupB sltCirc = false := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- ⛔ `sltuCirc`, likewise. -/
theorem sltuCirc_fails_clause5 :
    sltuCirc.outs.eraseDups.length = 2 ∧ portsNodupB sltuCirc = false := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- ⛔ `immICirc` — a 12-bit immediate sign-extended to 32: 12 distinct nets. -/
theorem immICirc_fails_clause5 :
    immICirc.outs.length = 32 ∧ immICirc.outs.eraseDups.length = 12
    ∧ portsNodupB immICirc = false := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- ⛔ `immBCirc` — a 13-bit displacement sign-extended: 13 distinct nets. -/
theorem immBCirc_fails_clause5 :
    immBCirc.outs.eraseDups.length = 13 ∧ portsNodupB immBCirc = false := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- ✅ THE POSITIVE CONTROL — the bar is not vacuously failing everything. `bitAnd32` has 32
distinct ports and PASSES ①⁵, so the failures above discriminate. -/
theorem bitAnd32_passes_clause5 :
    bitAnd32.outs.length = 32 ∧ bitAnd32.outs.eraseDups.length = 32
    ∧ portsNodupB bitAnd32 = true := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

end SaltWorks.HDL.MIG5

#print axioms SaltWorks.HDL.MIG5.sltCirc_fails_clause5
#print axioms SaltWorks.HDL.MIG5.immICirc_fails_clause5
#print axioms SaltWorks.HDL.MIG5.bitAnd32_passes_clause5
