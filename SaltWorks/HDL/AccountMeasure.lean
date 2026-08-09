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

*`offEnc = offRw` is the zero-gate row (`ruledEnc` has no gates) and it is the ONE case where two
rows legitimately share a starting net — the distinction from the `regWrite` collision repaired at
`5f1abb7`, which is one word wide and is why both appear in this conjunction.* -/
theorem offsets_pinned :
    offTie = 1088 ∧ offOb = 7221 ∧ offEnc = 7934 ∧ offRw = 7934
      ∧ offPc = 8097 ∧ offRegNext = 8357 := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel, by decide +kernel,
          by decide +kernel, by decide +kernel⟩

/-- **The chain's end — §1.2's "total nets".** -/
theorem chain_end_is_11461 : instNext regNext offRegNext = 11461 := by decide +kernel

/-- ⭐⭐ **THE CROSS-INSTRUMENT RECONCILIATION — the reason §1's figures are two-witness.**

`CoreOffsets`' table starts at its own `off0 = 1088` and does **not** model the two tie cells, so the
derived chain must exceed its literal `chain_last` by exactly `tieCells.gates.length`. Stated with the
tie count as a TERM rather than as `+ 2`, so the identity survives a change to the preamble.

⚠️ *The harness that first checked this printed `11459 - chainEnd` in `Nat`, which TRUNCATED TO 0 and
reported "difference = 0" — indistinguishable from agreement, and unable to tell 11461 from a 2-short
11459. As a theorem the truncation cannot hide: the equation is either true or it fails.* -/
theorem chain_reconciles_with_CoreOffsets :
    instNext regNext offRegNext = 11459 + tieCells.gates.length := by decide +kernel

/-- **CONTROL: the reconciliation is not vacuous.** Both sides are pinned independently, so a reader
can see the two instruments agreeing rather than an identity that holds by construction. -/
theorem reconciliation_is_not_vacuous :
    instNext regNext offRegNext = 11461 ∧ 11459 + tieCells.gates.length = 11461 := by
  refine ⟨chain_end_is_11461, by decide +kernel⟩

#audit_axioms offsets_pinned
#audit_axioms chain_end_is_11461
#audit_axioms chain_reconciles_with_CoreOffsets
#audit_axioms reconciliation_is_not_vacuous

end SaltWorks.HDL.AccountMeasure
