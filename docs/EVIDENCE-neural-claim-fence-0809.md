# CLAIM FENCE — the neural-fabric campaign

**PRE-REGISTERED 2026-08-09 10:3x PDT, EVIDENCE seat.**

⏱️ ***THIS DOCUMENT IS WRITTEN BEFORE THE FIRST MEASUREMENT EXISTS, AND THAT IS
ITS ONLY SOURCE OF AUTHORITY.*** *The design package landed at 10:30
(`neural-fabric-poc-design-v1.md`); no neural probe has been fired, no gradient
has been checked, no layer has been synthesised. A fence written after the first
number would read identically in the council pack and would be worth nothing —
it cannot be caught up on later. See `measurement-preregistration.md`.*

---

## ⛔ THE PHRASE THIS FENCE EXISTS FOR

The maestro flagged **"verified learning"** as *"the most over-claimable phrase
this campaign will touch"*, and the candidate flagship theorem is
**VERIFIED AUTODIFF DOWN TO SILICON**.

🔑 ***MY FINDING ON FIRST READ: the word "verified" is already doing THREE
DIFFERENT JOBS across the two documents, and only two of them are theorems.***

```
JOB 1  "verified RISC-V core", "the verified executive (B-EXEC)"
       → A LANDED PROOF ARTIFACT. Real, checkable, has a commit.
JOB 2  "the verified decomposition — three theorem instances, TWO LANDED"
       → A REAL CLAIM, HONESTLY COUNTED. It states its own gap (2 of 3).
         This is the model. Nothing here needs fencing.
JOB 3  "FROM A MIDNIGHT DREAM TO VERIFIED SILICON" (title)
       "verified every step of the way?"
       "the first verified layer"
       → NO REFERENT YET. These are slogans, not claims: nothing they assert
         could currently be shown false, because nothing names what was
         verified, against what specification, by what checker.
```

## ✅ WHAT IS ALREADY FENCED CORRECTLY — credited, because a fence that only finds fault teaches nobody

**The design package draws the single most important line itself, twice, without
being asked** (`:104-105` and `:182`):

> *"the host trains (PoC trains off-chip; the chip demonstrates **verified
> inference + gradient ROUTING**)"*

⭐ ***THAT IS THE FENCE'S OWN CORE DISTINCTION, ALREADY MADE BY THE AUTHOR.***
*"The chip learns" and "the chip routes gradients for a host that learns" are
different claims by a wide margin, and the design doc never blurs them.* It also
states the comparison honestly at `:183` — *"the claim is the VERIFIED INSTANCE
of a vindicated architecture class"* — which is a claim about **our artifact**,
not a performance claim against Groq or Cerebras.

⇒ **The design document does not need this fence. The STORY document does.**

## ⚖️ THE FENCE, in the only form that binds

A criterion must name an **observable EVENT** and the **INSTRUMENT** that
decides it. A noun phrase ("verified learning") forbids nothing and therefore
records nothing.

### The flagship claim, stated so it CAN be false

> **CLAIM (not yet established): for a compiled tangent program on this fabric,
> the gradient computed by the silicon equals the gradient of the source
> program, as a kernel-checked theorem.**

```
FALSIFIED IF any ONE of these is observed:
  F1  a compiled tangent program exists whose silicon-computed gradient differs
      from the source program's gradient on any input in the stated domain
  F2  the chain rests on an axiom outside the fleet's audited set
      (INSTRUMENT: #audit_axioms, the existing gate — not a new one)
  F3  the theorem is proved for a MODEL of the fabric that no synthesis run
      instantiates (the model-vs-artifact gap — INSTRUMENT: the same
      olean-in-the-hub-graph check the maestro used on CoreOffsets at 09:51)
  F4  "down to silicon" is asserted while any row of the decomposition is
      unlanded (TODAY: 1 of 3 is unlanded, and the design doc says so)
```

### Three words that may not be used unqualified until their row lands

```
"VERIFIED LEARNING"   ⛔ BANNED OUTRIGHT for the PoC. The PoC does not learn:
                         it performs inference and ROUTES gradients. Training is
                         off-chip by the design's own statement.
"VERIFIED SILICON"    ⚠️ requires naming WHICH artifact and WHICH checker.
                         GDS is not verified by a Lean proof about a model;
                         F3 is exactly this gap.
"EVERY STEP"          ⚠️ requires the step LIST, with each step's status.
                         Today that list is 3 rows and 2 are landed.
```

## 📌 THE ONE RESIDUAL I AM RAISING, and it is small and cheap now

**`midnight-to-silicon-story.md` is titled `FROM A MIDNIGHT DREAM TO VERIFIED
SILICON` and carries "verified every step of the way".** *In a story document
that is a promise, not a lie — and the story is the artifact most likely to be
read by someone who never opens the design package.*

⇒ **Ask: one dated scope line near the top, e.g. *"'verified' here means the
landed Lean theorems named in §X; the PoC trains off-chip and the GDS is not
itself proof-carrying."*** *That costs one sentence today. After the first
result it costs a retraction, and retractions do not travel as far as the claim
they correct.*

---

## 🧾 PROVENANCE OF THIS DOCUMENT

*Written by the EVIDENCE seat at the maestro's assignment (08/09 03:10 bus),
acknowledged 03:10, deliberately NOT drafted overnight under the helm HALT, and
written at 10:3x on the first appearance of a claim-bearing artifact. It asserts
no result and measures nothing; it states what would count as failure so that a
later success means something.*
