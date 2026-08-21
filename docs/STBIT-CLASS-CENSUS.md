# THE `stBit`-BRANCH CLASS — STRUCTURAL CENSUS

**Read, not built. Stamped `2026-08-21T11:46:29-0700`, tree at `7db7cef`.** Rerouted to this pen from math (helm 11:41),
who is saturated on MRT + W-F3. Deliverable: every proof that walks `stBit`'s branch structure,
with its per-member branch shape, so the Q3 swap chain has a map rather than a peel-one-at-a-time.

## ⛔ FIRST: THE POPULATION IS 6, NOT 22, AND NOT 388

```
grep -F  'stBit'   -> 388 hits / 50 files    ⛔ CONTAMINATED: `testBit` CONTAINS `stBit` (217 of them)
grep -Fw 'stBit'   ->  22 hits /  5 files    the real references
of those, proofs that WALK THE BRANCH STRUCTURE ->  6
```
*The other 16 are the `def` itself, `encD`'s use of it as a mapped function, `encD_getD` (which
reasons about the INDEX RANGE, never the branches), one `#audit_axioms` row, and five docstrings.*
⚠️ **A substring grep over-reports this class by 64×.** Anyone re-running the census must use `-Fw`.

## THE SIX, WITH BRANCH SHAPE

| # | member | branch targeted | shape | verdict at D |
|---|---|---|---|---|
| 1 | `StateCodec.decQ_encD_proj` · `hpc` | **pc** (else) | `rw [stBit, if_neg (by omega)]` then `rw [h1024]` | ⛔ **PINNED** — one `if_neg`; D needs `if_neg` then `if_pos` |
| 2 | `StateCodec.decQ_encD_proj` · `hreg` | **regs** (first) | `rw [stBit, if_pos (by omega)]` | ✅ **SURVIVES** |
| 3 | `StateCodecD.stBitD_agrees` | regs + pc | `unfold`; `by_cases j < 1024`; `rw [if_pos/if_neg …, if_pos h56]` | ♻️ **SCAFFOLDING** — compares two codecs the swap MERGES; retires with its module, does not need repair |
| 4 | `DecoderTransport.stBit_decQ` | regs + pc | `rw [stBit]`; `by_cases h : j < 1024` | ⛔ **PINNED** — see below |
| 5 | `Program.stBit_reg` | **regs** (first) | `rw [stBit, if_pos (by omega), hdiv, hmod, getElem!_pos]` | ✅ **SURVIVES** |
| 6 | `Program.stBit_pc` | **pc** | `unfold`; `split_ifs <;> first \| omega \| (congr 1; omega)` | ✅ **WIDTH-AGNOSTIC** (math `e467d8d`) |

## 🔑 THE LAW THE CENSUS YIELDS — it is about WHAT A PROOF NAMES

***A proof survives the widening exactly when it does not name a BRANCH COUNT.***
- **Survives by position:** #2 and #5 target the FIRST branch (`regs`). D appends branches; it does
  not move the first one, so `if_pos` still selects it. *Free, and nobody designed it that way.*
- **Survives by abstention:** #6 names no branch at all — `split_ifs` takes however many exist and
  `omega` kills the impossible ones.
- **Pinned:** #1 and #4 both encode the layout's ARITY. #1 encodes its DEPTH (one `if_neg` = "the
  else-branch is the answer"). #4 encodes its WIDTH (`by_cases` on ONE condition = "there are two
  branches"). **These are different mistakes with the same cause.**

## ⚠️ MEMBER #4 IS THE ONE NO EXTRACTION HAS NAMED

`DecoderTransport.stBit_decQ` was **ABSENT from the 33-name kernel closure of `2d7dd49`.** Its
`by_cases h : j < 1024` splits two ways and treats the negative side as *the pc branch*; under D that
side is itself a 3-way chain.

⇒ **This is the census earning its keep: a structural read reaches members a kernel extraction
cannot, because a failing module masks its dependents and an extraction only ever reports a LOWER
BOUND.** The prediction is falsifiable and pre-registered before the D-arm run that tests it.

## WHAT THIS DOES NOT CLAIM

It does not price the repairs. #1's fix is known and blocked on tactic availability — `split_ifs`
and `and_intros` are **Mathlib**, and `StateCodec.lean` imports only `HDL.ISA` and `HDL.Sem`, so
math's template does not transfer to that file (measured 08/20, three attempts, walled). #4's fix is
unexplored. **Neither is attempted here: this is READ work under the helm's dispatch, and a repair
claim would owe a dry-run-under-D acceptance that this document does not carry.**
