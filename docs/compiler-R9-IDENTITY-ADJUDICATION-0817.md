# R9 vs THE STALL ARM — MY ADJUDICATION (round 4, act 0)

**Drafted by compiler per the helm 16:09:02. The blind packet is
`compiler-R9-IDENTITY-BLIND-PACKET-0817.md`, committed `50a2f5f` at 16:12:33 — BEFORE
this file existed, which `git log` shows and I do not ask anyone to take on trust.**

> ⛔ **REFUTER: IF YOU ARE THE BLIND ARM, STOP. PUBLISH YOUR DERIVATION FIRST.**
> *Read the packet, not this. This document exists to be compared against yours, and a
> comparison you have already read is not a comparison.*

---

## THE VERDICT

***TWO obligations, not one — but JOINED AT THE KERNEL, and the join is DIRECTIONAL:
A must land before B can be built.***

**Count: 2 rungs. Dated in SEQUENCE, never in parallel.**

---

## WHY TWO AND NOT ONE

They differ in every property that makes an obligation a unit of work:

| | **A — the stall arm** | **B — R9, the `C4Spec` witness** |
|---|---|---|
| deliverable | a **statement shape** (a restated predicate) | an **inhabitant** (a `Circ` term + its proof) |
| artifact | `Stack/Program.lean` | `HDL/` — `CorePlace`, `C4`, `StateCodec` |
| failure mode | the restatement is wrong, or does not reduce | the term does not exist, or its proof fails |
| cross-verifier's instrument | refuter reading, kernel | **silicon's RTL + placement facts** |
| discharged by | a definition and two properties | a construction |

*A restatement cannot be discharged by building a circuit, and a circuit cannot be
discharged by restating a predicate. Two rungs.*

## WHY THEY ARE NOT INDEPENDENT — AND THIS IS KERNEL FACT, NOT MY READING

The bridge already in the tree, `Program.lean:2306`:

```lean
theorem cycleRealisesStep_of_C4Spec (h : C4Spec c) (nextW) (pad) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord
```

Its **contrapositive** is a one-liner, and I have kernel-checked it (scratch, held back
from the tree until the blind twin publishes — see CONTAMINATION CONTROL below):

```lean
theorem not_C4Spec_of_not_cycleRealises (nextW) (pad)
    (h : ¬ CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord) : ¬ C4Spec c :=
  fun hc => h (cycleRealisesStep_of_C4Spec hc nextW pad)
```

*Both audit `[propext, Classical.choice, Quot.sound]`, no `sorryAx`, build EXIT=0.*

⇒ **Object A's impossibility TRANSPORTS ONTO Object B.** A's finding is that **no
stalling cycle map satisfies `CycleRealisesStepProj`** (because `stepT` falls through to
`St.next` and every word advances the pc — `ISA.lean:1115`, `:207`). By the contrapositive,
**any circuit whose induced cycle map stalls cannot inhabit `C4Spec`.**

**THE SEAM, NAMED:** *the unconditional **one-ISA-step-per-cycle** demand, carried in both
sentences by the **pc** field.*
- in **A**: `(decQ (cyc ins)).pc = (stepT (decQ ins) (wordAt ins)).pc`
- in **B**: `PcField c : ∀ ins, outPc c ins = (stepT (decQ ins) (seenWord ins)).pc`
  (`:2557`), and `not_C4Spec_of_not_pcField` (`:2738`) is the landed general lemma that
  a pc failure alone refutes `C4Spec`.

**WHAT CROSSES THE SEAM:** the **stall semantics** — which cycles are NOT-cycles, silicon's
T1 contract. **DIRECTION: A → B.** A fixes the sentence; B is then built against the fixed
sentence.

## ⛔ THE CONSEQUENCE THE COUNT ALONE DOES NOT CARRY

***R9 is not "unbuilt". Against today's sentence, for a stalling core, it is UNBUILDABLE —
and by the same field, for the same reason, as the defect round 4 exists to repair.***
**Constructing the witness before the restatement lands would be constructing against a
sentence that is about to change.**

⚠️ **A THIRD FAILURE MODE, which the helm's kill-check does not literally name.** The
check asks: *neither double-counted nor zero-counted.* **Two is the right count and a plan
can still be wrong** — by dating the two rungs **CONCURRENTLY**, which is neither double
nor zero counting. *That plan looks correct on its face and cannot execute.* ⇒ **the
kill-check should read: is the count right AND is the ORDER right.**

## 🔑 WHAT WOULD FLIP THIS VERDICT — and I have NOT checked it

**The verdict rests on ONE PREMISE I HAVE NOT VERIFIED: that the real composed core's
INDUCED cycle map — `cycOfCirc c nextW pad` — is one that stalls.**

*If stalls are absorbed BELOW the C4 abstraction — if `cycOfCirc` indexes a retimed or
per-instruction cycle in which every cycle does realise a step — then `C4Spec` is
inhabitable today, B is not blocked on A, and the two obligations are genuinely
independent and datable in parallel.* **Then my verdict is wrong in its operative half.**

⛔ **I cannot settle this from my instruments: it is a fact about the RTL and the
placement, which is SILICON'S half.** *This is the load-bearing uncertainty of the whole
adjudication, and it is named here rather than discovered later.* **SILICON: this is the
question your cross-verification should attack first — and it is exactly the demonstration
that your check CAN reject.**

## CONTAMINATION CONTROL — why the theorem is not in the tree yet

The two scratch theorems live in `SaltWorks/HDL/ScratchR9Identity.lean`, which is
**gitignored** (`.gitignore:2`, confirmed by `git check-ignore`). **A theorem named for my
conclusion, landed in the shared tree, is my conclusion published where any innocent
`grep C4Spec` finds it — a refuter obeying "do not read compiler's block" would be
contaminated anyway, silently.** *The document you are reading is labelled and avoidable;
a theorem in the shared tree is neither.* ⇒ **it lands after the twin publishes.**

## WHAT I PROVED vs WHAT I INFERRED — stated separately on purpose

```
PROVED (kernel, this session)   C4Spec c → CycleRealisesStepProj (cycOfCirc c …)
                                and its contrapositive.  [3 axioms, no sorryAx]
PROVED (kernel, landed earlier) not_cycleRealisesStep_stalledBits — a specific
                                stalling map fails the predicate (:2404)
INFERRED, NOT PROVED            that the REAL composed core's induced cycle map is a
                                stalling one. ⛔ THE VERDICT'S OPERATIVE HALF RESTS
                                ON THIS AND I DID NOT VERIFY IT.
```

## WHAT I OWE NEXT (act 1, not started)

The helm's 15:58:02 ruling: **the control for R9 must be a NEW DEMAND LINE** — a concrete
instantiation that **fails to elaborate until the witness exists** — because today's tree
*is* the green-and-wrong state (`C4Spec` consumed everywhere, inhabited nowhere, build
green), so no existing check can serve. **Its exact form is proposed in round 4's block,
and the refuters gate it.**
