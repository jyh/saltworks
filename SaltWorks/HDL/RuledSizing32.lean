/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.GenSelectCount

/-!
# The RULED `aluSelect` sizing `(n = 3, b = 2)` — proof coverage, in one place

Muster ruling ① (Captain-ratified, 8/8 09:59) sizes `aluSelect` at the PAIR
`(n = 3, b = 2)`: 291 gates, −1,154 against as-built `(10, 4)`.

This file asserts nothing new. It INSTANTIATES the general theorems landed this
morning at exactly the ruled pair, so the ruling has a single kernel receipt
rather than a reader's inference across three files.

⛔ SCOPE — what this file deliberately does NOT contain:
* the general reachability guard `genSelect_sources_reachable (n b) (hb) (hn : n ≤ 2^b)`
  is **math's**, dispatched under rider (3). Not duplicated here.
* the re-cut of `aluSelect` itself is barred pending ruling ② (rider 5).
-/
namespace SaltWorks.HDL
namespace RuledSizing32

open SaltWorks.HDL.GSCount

/-! ## ① COST — the ruled pair's gate count, from the closed form -/

theorem ruled_gate_count : (genSelect 3 2).gates.length = 291 := gate_count_three

/-- And the saving against as-built `(10, 4)`, in the kernel rather than in prose. -/
theorem ruled_saving : (genSelect 10 4).gates.length - (genSelect 3 2).gates.length = 1154 := by
  rw [gate_count_ten, gate_count_three]

/-! ## ② VALIDITY — dense SSA and well-formedness, by instantiation -/

theorem ruled_ssa : (genSelect 3 2).ssa = true := genSelect_ssa 3 2 (by decide)
theorem ruled_wf  : (genSelect 3 2).wf  = true := genSelect_wf  3 2 (by decide)

/-! ## ③ THE HYPOTHESIS IS DISCHARGED, NOT ASSUMED

`0 < b` is the one hypothesis `genSelect_ssa`/`_wf` carry, and at `b = 2` it is
closed by `decide` above. `genSelect_zero_b_not_ssa` shows it is not decoration. -/

theorem ruled_b_positive : 0 < 2 := by decide

/-! ## ④ CAPACITY — the ruled pair reads EVERY source, and has one slot spare

`n = 3 ≤ 4 = 2^b`, so no source is stranded above the leaf count. The general
statement of this is math's guard theorem; here is the ruled instance, which is
the only one the ruling depends on. -/

theorem ruled_sources_fit : 3 ≤ 2 ^ 2 := by decide

/-- The ISA demands three slots; the ruled pair supplies four. -/
theorem ruled_spare_slot : 2 ^ 2 - 3 = 1 := by decide

/-- No leaf pads at the ruled pair — every one of the 4 leaves reads a real
source, except the single spare. Contrast `ten_pads_six` at the as-built pair. -/
theorem ruled_leaf_reads (k i : Nat) (hi : i < 3) : gsPrev 3 2 k 0 i = gsRes i k := by
  show (if 3 ≤ i then gsZero 3 2 else gsRes i k) = gsRes i k
  rw [if_neg (by omega)]

/-! ## ⑤ INTERFACE — the port list is 32, definitionally, at the ruled pair -/

theorem ruled_outs_len : (genSelect 3 2).outs.length = 32 := by decide +kernel

#audit_axioms ruled_gate_count
#audit_axioms ruled_saving
#audit_axioms ruled_ssa
#audit_axioms ruled_wf
#audit_axioms ruled_b_positive
#audit_axioms ruled_sources_fit
#audit_axioms ruled_spare_slot
#audit_axioms ruled_leaf_reads
#audit_axioms ruled_outs_len

end RuledSizing32
end SaltWorks.HDL
