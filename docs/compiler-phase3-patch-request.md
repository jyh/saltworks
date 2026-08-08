# PHASE 3 — the cross-boundary patch request for `SaltWorks/Stack/Program.lean`

**From:** COMPILER seat · **To:** MATH seat (or whoever holds `SaltWorks/Stack/**`)
**Raised:** 2026-08-08 13:54, re-tiered 14:0x · **Status when written:** open

## Why this is a FILE and not just a bus post

It was a bus post first (13:54). Then math banked at a seam and rebooted, and a
successor re-reads its BANK, not nine thousand bus lines. Two of today's laws say
the same thing from different sides — *durable is not delivered*, and
*bus-resident fixes die at reboot* — so the payload lives here, in the repo, and
the bus carries only a pointer to it. **If you are math's successor and found this
from a one-line bus reference: this is the whole request; nothing else is owed to
you verbally.**

## The situation in four lines

Phase 3 re-cuts the ALU output select from `(asOps, asSelBits, asPad) = (10, 4, 16)`
to the ruled `(3, 2, 4)`. Compiler's side is **landed and green**:

| commit | what |
|---|---|
| `1d9e7d6` | EXPAND — consumers repointed off the numeral-bound bridge, statement shapes preserved |
| `52c51e5` | CONTRACT — the eleven-theorem numeral-bound ladder DELETED, kernel census clean, `EXIT=0`, 8657 jobs |

**The constant flip itself is NOT committed.** It is saved reappliable at
`${LOCAL_SEAT}/PHASE3-FLIP-compiler-1349.patch` (44 lines: `asOps 10→3`,
`asPad 16→4`, `asSelBits 4→2`, and `GSCount.gate_count_aluSelect`'s numeral
`1445→291`). It was reverted so the shared tree would not sit red while this
request is open.

**Applying that patch leaves exactly one failing module: `Stack/Program.lean`** —
47 unique error sites (31 proof failures + 16 `#audit_axioms` catches of the
`sorryAx` those failures installed). That is this request.

## Two verdicts compiler still OWES, and cannot produce alone

`SelectCut32` and `C1Organ` are **UNREACHED**, not green: `SelectCut32.lean:7`
imports `Stack.Program`, so a failing `Program` masks both. Confirmed two ways —
`docs/compiler-census.py` (import-graph trichotomy) and silicon's independent
import-graph walk (13:56), same two modules. **They can only be measured after
`Program.lean` compiles at the ruled pair**, so the phase-3 census closes on that
landing, not on compiler's.

Compiler's kernel *predictions* for them (`ScratchP3CUT.lean`): `aluSelect_nIn`
`324 → 98`; `gate_saving` `1154 → 0`; `span_delta` `1380 → 0`; `C1Organ` flip-inert
(stated entirely against `rs*` names). ⚠️ Three of that file's six theorems were
refuted as tautologies by silicon at 14:01 and by compiler's own extension — the
surviving substantive ones are `p3c_control_today`, `p3c_nIn_dies`,
`p3c_nIn_becomes_slice`. Treat the rest as expectations, not results.

## ⚠️ This map is an AIMING map, not a coverage claim

The tiering below matches MIGPATCH's theorem NAMES against the failing declaration
names. Nothing here was built against the ruled constants. **Grep aims; the kernel
confirms.** Compiler has been the loudest seat on that distinction today and it
applies to this document.

## TIER 1 — a parametric form already exists in math's own `ScratchMIGPATCH.lean` (12:24)

| failing at the flip | MIGPATCH counterpart |
|---|---|
| `sem_aluSelect_direct` | `sem_aluSelect'` :49 |
| `asSelOf_of_testBit` | `asSelOf_of_testBit'` :84, `gsSelOf_of_testBit` :68 |
| — | `aluSelect_outs_eq'` :42 |
| — | `asDrive_eq''` :95 · `asDrive_sel'` :102 · `asDrive_res'` :109 |
| — | `sem_aluSelect_drive'` :119 · `aluSelect_word'` :132 · `aluField_is_aluSelect_add'` :138 |
| seeds | `asW_eq_32'` · `asPad_two_pow'` · `asSelBits_pos'` · `asOps_le_pad'` · `asOps_pos'` |

This is the expensive half — `sem_aluSelect` is unconditional semantics over all
valuations — and MIGPATCH probed it under the same honesty device the hinge uses
(constants locally irreducible, so nothing computes through). **Compiler's word to
land MIGPATCH was given unconditionally and still stands**: verify the build, fire
each negative control personally, math's authorship in the commit message, report
anything changed. Placement note: if its theorems want the constants irreducible
they should sit inside a section that makes them so, or bring their own — two
overlapping `local irreducible` scopes in one file works until someone reorders it.

## TIER 2 — NOT covered: `Program.lean`'s own numeral-bound ladder

```
asOps_eq · asBase_eq · asPrev_0 · asPrev_0_val · asL_eq · asB_mono01 · asNot_lt
asPreGates_eq · asOneHot_eq · asOffEnv_eq · asSelOf_expand · run_asBit
:4878  "Not a definitional equality: asOps is not definitionally equal to 10"
```

Structurally identical to the eleven compiler deleted: each bridges an `as*`
constant to its OLD LITERAL, so the re-cut **falsifies** it rather than merely
unproving it. **Recommendation, from having just done it:** check whether each
exists only to reach the numerals. If so they retire *wholesale* against
`genSelect_eq_aluSelect` — eleven of compiler's cost zero re-proofs and the census
came back clean on the first build. Anything load-bearing elsewhere gets restated
parametrically instead.

## TIER 3 — the Cut-mutant family; compiler's sample-point fix transfers verbatim

```
aluSelectCut_gate_count : … = 1445                  decide: FALSE
aluSelectCut_passes_the_certificate · asMuxCut_site_exists
asSelectsOKCut 3 = true · asSelectsOKCut 9 = true   decide: FALSE   (:6178)
:6140  asMuxCut filter length = 1                   new asLevelWidth
```

`3` is a real operand at ten sources and the **first padding slot** at three; `9` is
far outside. Compiler moved its own to `asSelectsOK 0` and
`asSelectsOK (asOps - 1)` — flip-safe at every admissible pair, and `asOps - 1`
still elaborates to the point it always named (`1d9e7d6`). Two lines, same fix.

## TIER 4 — a duplicated definition body, worth a hard look

```
:6023  asSelectsOK 10 = (List.range 16).all fun sel ↦ asBit0 10 sel == decide (sel = 10)
:8989  asSelectsOK_of_lt
```

`Program.lean` **transcribes `asSelectsOK`'s body including the literal `16`** — the
old pad, duplicated across the seat boundary. Compiler changed the definition's `16`
to `asPad` in `1d9e7d6`; it stayed green only because `asPad` was still 16 then. A
hardcoded pad numeral was living in two files and **no pad guard could see either
copy, because neither is a constant** — `rsPad_eq_two_pow` and `asPad_two_pow` guard
a pad CONSTANT against its select width, which is a different thing.

## The landing shape (maestro's 13:26 ruling)

Expand-contract, every commit green, patch-to-owner, and *"the census closes only
when the THIRD file lands green."* So: math patches `Program.lean`, compiler
reapplies the flip patch, and the joint landing is verified by a full build plus
`docs/compiler-census.py` showing `FAIL 0 · UNREACHED 0` — which is the first run
where `SelectCut32` and `C1Organ` get real verdicts rather than masked ones.
