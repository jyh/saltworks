/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CorePlace

/-! # §1's NUMBERS AS THEOREMS — the measurement harness, converted

**Instrument for `docs/core-account.md` §1.** v1 of this file was an `#eval` harness that PRINTED
the row table; v2 asserts it. The conversion was silicon's point (13:47) and my answer to it:

```
   v0  Scratch* name          gitignored     ⇒ §1 named an instrument no third party could run
   v1  tracked, unrooted      not built      ⇒ a CorePlace change could break the instrument
                                               silently, which is v0's defect one layer in
   v2  tracked, rooted, THEOREMS             ⇒ kernel-guarded, and ZERO print noise
```

⇒ ***A PRINTED NUMBER IS GUARDED BY WHOEVER RE-RUNS THE PRINT. A THEOREM IS GUARDED BY THE BUILD.***
*An organ that changes dimension now BREAKS THE BUILD instead of changing a number nobody re-ran —
which is what `CoreOffsets`' `row_*` theorems have done from the start, and I should have followed
that precedent instead of inventing a printing one.*

## WHAT THIS FILE DELIBERATELY DOES **NOT** RESTATE

*Restating a landed certificate is how two numbers drift apart, and I have been corrected on exactly
this before ("cite these, do not restate").*

| already certified | where |
|---|---|
| every organ's **gate count** | `CoreOffsets.row_decoder` … `row_regNext` (13 theorems) |
| `regNext`'s `nIn` / `outs.length` | `CoreOffsets`, same block |
| `off0 … off5`, `offAdd`, `offSub`, `offSlt`, `offSel` | `CorePlace.off0_value`, `off1_value`, `chain_offsets_derived`, `off5_value`, `adder_offsets`, `offSlt_value`, `offSel_value` |
| the coverage identity | `CorePlace.chain_accounts_for_every_placed_organ` |
| the 16 placements | `CorePlace.*_instOK` |

**What is left, and therefore what this file adds:** the six chain offsets that no theorem pinned,
the chain's end, and the cross-instrument reconciliation §1.2 cites.
-/

namespace SaltWorks.HDL.AccountMeasure

open SaltWorks.HDL SaltWorks.HDL.CorePlace SaltWorks.Stack.Program

/-- ⭐ **THE SIX OFFSETS §1.1 REPORTS THAT NOTHING PREVIOUSLY CERTIFIED.** The other ten are pinned
in `CorePlace` and cited above rather than repeated here.

*Until R9a, `offEnc = offRw` was the zero-gate row (`ruledEnc` has no gates) — the ONE case
where two rows legitimately shared a starting net. Since R9a it is `offEnc = offLwWr` that
shares (the trap gate starts where `ruledEnc` started), and `offRw` sits a 30-gate trap gate
further on: 8053 + 30 = 8083, with `offPc`/`offRegNext` shifted by the same 30.* -/
theorem offsets_pinned :
    offTie = 1088 ∧ offOb = 7340 ∧ offEnc = 8053 ∧ offLwWr = 8053 ∧ offRw = 8083
      ∧ offPc = 8250 ∧ offRegNext = 8510 := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel, by decide +kernel,
          by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- **The chain's end — §1.2's "total nets".**

⛔ **RENAMED 2026-08-20: this was `chain_end_is_11482` while PROVING `= 11486`.** The name
asserted a figure its own statement contradicts, by four, and a name is checked by nothing —
it built green from the day it landed. *I cited the wrong name twice on 08-20 as evidence that
the ADDI repair moved no offset; the citation was sound and the FIGURE I propagated was not.*
⇒ **Grep a headline's numerals in the STATEMENT before landing it.**

⚠️ **REGISTERED BEFORE HORN D LANDS, because D MOVES THIS NUMBER:** extending `encD` to the
8-word memory and the trap flag takes the state 1056 → 1313 bits, and `instrBase := stWidth`
definitionally, so every instruction net and every gate offset shifts by **+257** — this end
becomes **11743 + 30** once the widening also carries the trap gate. When that lands, this
declaration must be renamed AGAIN. A name carrying a literal is a maintenance obligation, not a
description. **RENAMED 2026-08-31 (R9a): was `chain_end_is_11584`; the trap gate's 30 gates
moved the end to 11614 — renamed the same commit the figure moved, per this docstring's own
law.** -/
theorem chain_end_is_11614 : instNext regNext offRegNext = 11614 := by decide +kernel

/-- ⭐⭐ **THE CROSS-INSTRUMENT RECONCILIATION — the reason §1's figures are two-witness.**

`CoreOffsets`' table starts at its own `off0 = 1088` and does **not** model the two tie cells, so the
derived chain must exceed its literal `chain_last` by exactly `tieCells.gates.length`. Stated with the
tie count as a TERM rather than as `+ 2`, so the identity survives a change to the preamble.

⚠️ *The harness that first checked this printed `chain_last - chainEnd` in `Nat`, which TRUNCATED TO
0 and reported "difference = 0" — indistinguishable from agreement, and unable to tell the true end
from a 2-short one. As a theorem the truncation cannot hide: the equation is either true or it fails.*

⬥ **D2 MOVED BOTH SIDES BY +21** — the decoder grew from 102 gates to 123, so every organ placed
after it shifts by the same amount. *The pair was `11459 / 11461` before D2 and is `11480 / 11482`
now; the RECONCILIATION is what did not move, which is the property this theorem exists to state.* -/
theorem chain_reconciles_with_CoreOffsets :
    instNext regNext offRegNext = 11612 + tieCells.gates.length := by decide +kernel

/-- **CONTROL: the reconciliation is not vacuous.** Both sides are pinned independently, so a reader
can see the two instruments agreeing rather than an identity that holds by construction. -/
theorem reconciliation_is_not_vacuous :
    instNext regNext offRegNext = 11614 ∧ 11612 + tieCells.gates.length = 11614 := by
  refine ⟨chain_end_is_11614, by decide +kernel⟩

#audit_axioms offsets_pinned
#audit_axioms chain_end_is_11614
#audit_axioms chain_reconciles_with_CoreOffsets
#audit_axioms reconciliation_is_not_vacuous

end SaltWorks.HDL.AccountMeasure
