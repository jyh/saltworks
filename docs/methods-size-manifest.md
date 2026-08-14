# METHODS SIZE MANIFEST — the "verified compiler" row

**This manifest DEFINES the "verified compiler" size row.** Born 2026-08-14 at the
Captain's cleanup ruling. The historical figure **5,067 lines / 13 files was not
reproducible**: the 13-file list was recorded nowhere, no canonical reading of the
compiler neighborhood produces it (named-modules gives 10 files / 5,189; adding the
certificate file gives 11 / 5,510; the true import closure gives 39 / 24,338), and
subset-sum over the corpus shows 145 distinct 13-file subsets summing to 5,067 — the
pair identifies nothing. From this date forward the row is derived from THIS file
list and never re-derived from prose.

**Status: PRE-FREEZE.** Extracted at saltworks HEAD
**a7935bedefe756e7e84b4b78874bfd377a046385** (branch master). HEAD advanced to
**bcf6453d071791effe89cc850f632b7bf3a5db36** during the extraction sitting with
ZERO diff to the 11 listed files (`git diff --stat a7935be..bcf6453 -- <list>` →
empty), so every number holds at both shas. Every number below re-runs at THE
ratified freeze sha in one sitting; this manifest fixes the LIST, the freeze
re-extraction fixes the numbers of record.

## The normative rule

The row counts `SaltWorks/Certs/Compiler.lean` (the compiler's comprehensibility
certificate) plus the import closure that elaborates it — the emitter, the scheme
consumers, and the compiler's IR/spec modules — truncated at exactly two named
boundaries:

1. `SaltWorks/Stack/Program.lean` (9,318 lines) — imported by `StraightLine.lean`
   but EXCLUDED: it is the executive+app stack row's file; counting it here would
   double-count across rows (the overlap hazard named in the 8/14 size-table audit).
2. `SaltWorks/Tactic/AuditAxioms.lean` — imported by `ISA.lean` but EXCLUDED:
   corpus-wide audit-gate infrastructure, belonging to no size row.

Derivation (every import edge read at the bytes, 8/14):
`Certs/Compiler → WhileSim → WhileScheme → IteScheme → BlockCalc → CompileS →
CompileE → {RegMap, TinyRustN0, StraightLine}`, and `RegMap → ISA`. The closure is
exhaustive: `TinyRustN0` imports nothing; the only other edges are the two boundary
exits above.

## The normative file list (11 files)

| File | Lines @ a7935be |
|---|---|
| SaltWorks/Certs/Compiler.lean | 321 |
| SaltWorks/HDL/CompileE.lean | 1,035 |
| SaltWorks/HDL/CompileS.lean | 848 |
| SaltWorks/HDL/WhileSim.lean | 315 |
| SaltWorks/HDL/WhileScheme.lean | 498 |
| SaltWorks/HDL/IteScheme.lean | 216 |
| SaltWorks/HDL/BlockCalc.lean | 323 |
| SaltWorks/HDL/RegMap.lean | 67 |
| SaltWorks/HDL/TinyRustN0.lean | 490 |
| SaltWorks/HDL/StraightLine.lean | 181 |
| SaltWorks/HDL/ISA.lean | 1,216 |
| **TOTAL** | **5,510** |

Sub-reading for comparison: the 10 module files without the certificate file total
**5,189** — the "named-modules" candidate of the 8/14 audit. Choosing 11/5,510 vs
10/5,189 as the published row is the Captain's ruling; this manifest records BOTH
sums from the SAME list so either choice is one deletion, not a re-derivation.

## The exact commands

```sh
cd saltworks
git rev-parse HEAD    # a7935bedefe756e7e84b4b78874bfd377a046385 at extraction
wc -l SaltWorks/Certs/Compiler.lean \
      SaltWorks/HDL/CompileE.lean SaltWorks/HDL/CompileS.lean \
      SaltWorks/HDL/WhileSim.lean SaltWorks/HDL/WhileScheme.lean \
      SaltWorks/HDL/IteScheme.lean SaltWorks/HDL/BlockCalc.lean \
      SaltWorks/HDL/RegMap.lean SaltWorks/HDL/TinyRustN0.lean \
      SaltWorks/HDL/StraightLine.lean SaltWorks/HDL/ISA.lean
# total 5,510; import edges verified with: grep -F "import " <each file>
```

## On 5,067 / 13

No 13-file reading reproduces it and none was forced. The compiler neighborhood
enumerated above has 11 files totaling 5,510 — already ABOVE 5,067 — so no
extension of the normative list to 13 files can sum to 5,067, and no principled
13-file subset of it exists (a subset of 13 would exceed the list's size). The
8/14 size-table audit found 145 distinct 13-file subsets of the wider corpus
summing to 5,067, with no universe or command recorded for any of them — the
pair identifies nothing. The figure is retired as NOT INDEPENDENTLY REPRODUCIBLE
AS PRINTED; this manifest replaces it.
