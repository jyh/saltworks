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

      ⭐ SCOPE, PRE-REGISTERED 2026-08-09 16:0x — BEFORE THE RUN THAT WOULD
        CLEAR IT, because silicon's run covers THE CELL ALONE and a cell-level
        clearance must not read as a chip-level one:
```
        F3 CLEARS AT THE SCOPE THE RUN COVERS, AND NO WIDER.
          cell synthesised      ⇒ "the CELL is certified down to silicon"
          fabric NOT run        ⇒ the CHIP phrase stays at the kernel model
        The fabric floorplan is the last link and it still needs a top module
        nobody has ruled — so no run yet exists that could clear the chip.
```
      ⇒ **A CLEARED F3 CARRIES ITS SUBJECT IN THE SENTENCE.** *"Down to
        silicon" with no subject is the ambiguity this whole fence exists to
        prevent, and it would be created by a TRUE cell-level result.*
      *(Same shape as this seat's a-count-is-not-a-scope, pointed at my own
       falsifier: the result will be real and the scope is what a reader
       cannot see from it.)*
  F4  "down to silicon" is asserted while any row of the decomposition is
      unlanded, OR while the COMPOSING JOIN over those rows is unstated.
      (Amended 15:45: the original gated on rows only, and I cleared it on a
       row status line while the join was still unstated. PARTS ARE NOT A
       PRODUCT — a decomposition whose every row is landed is a set of
       theorems, not the theorem.)
      ⚠️ THE CONDITION IS DURABLE; THE COUNT IS NOT. Re-read the source before
      quoting a number here -- do not trust this line's parenthetical.
      RE-ANCHORED 2026-08-09 14:3x on the amended row (maestro's sweep after
      the rung-3 landing), read at the bytes:
        row 1 fabric delivery      LANDED (family)
        row 2 bit-serial MAC       `mac_correct` 84690c0 + rungs 1-3 incl.
                                   `macRun ~ runTrace macSeq` c754b29
                                   ⇒ LANDED THROUGH the accumulator-hardware
                                     attachment; RUNG 4 (weight-shift
                                     composition = the FULL row) OWED.
                                   ⛔ CORRECTED 14:3x: NOT "in flight". The
                                     maestro's own text said in-flight and math
                                     corrected it to SHAPED, UNSTARTED — an
                                     executor was dispatched only at 14:34. I
                                     had copied the package's word into my
                                     fence, so the fence inherited a status
                                     word it did not verify.
        row 3 signed activation    LANDED (`wordSignedOrder`)

      ⭐ RE-ANCHORED AGAIN 2026-08-09 14:5x, AT THE SETTLE POINT — rung 4 SEALED
        (math at the content, silicon at the gate, EXIT=0 twice, e2e966b). I
        deliberately did NOT track the intermediate states; F4 gates on a
        CONDITION and re-anchors when the source settles.
        THE ROW NOW SPLITS ITSELF, and the split is the fleet's own work:
          ACCUMULATION       hardware theorem, LANDED ✅ (c754b29)
                             — "the cell adds what it is fed"
          ARITHMETIC READING (b + W·psum) ℤ-only, reaches the cell at rung 4,
                             carrying the chain's ONLY hypothesis
                             (¬saddOverflow, discharged by demoBound) ⛔ OPEN
      ⛔ SUPERSEDED 15:4x — SEE THE FINAL RE-ANCHOR BELOW. F4 NO LONGER BINDS
        on the decomposition, and the headline is now the STALE half.

      ═══ FINAL RE-ANCHOR, 2026-08-09 15:4x — THE CELL WAVE COMPLETED ═══
      row 2 now reads, IN THE PACKAGE ITSELF:
        "LANDED IN FULL (8/9 15:41): accumulation hardware theorem (c754b29)
         + the arithmetic reading through rung 4 under ¬saddOverflow with
         demoBound discharging it (a2c6470+03f5885) + the sign cycle at the
         artifact (3c62228)"
      ⛔⛔ MY CLEARANCE WAS WRONG AND IS WITHDRAWN (15:45). I read the row's
        own status line "LANDED IN FULL" and cleared F4 on it. Math then
        measured that THE JOIN — the one theorem composing trace + sign cycle
        + mac_correct into b + W·sval — IS NOT YET STATED. The parts are
        landed; the row is not.
      ⇒ F4 still bound at 15:45. **CLEARED AT 15:47, AND THIS TIME VERIFIED AT
        THE ARTIFACT RATHER THAN AT A STATUS LINE — which is the whole
        difference from my withdrawn 15:44 clearance:**
```
        git show --stat c732aaa   → a real commit, 2026-08-09 15:45:35
        declarations ADDED by it  → theorem cell_full_mac
                                    theorem cell_computes_signed_mac
        MacBridge.lean            → `sorry` count 0 · rooted in SaltWorks.lean
        covering verdict          → EXIT=0, 8,677 jobs
```
      ⇒ **THE JOIN IS STATED. F4 IS CLEARED — no row unlanded, no join
        unstated.** *Cleared on declarations read out of a commit, not on the
        word "landed" read out of the document I am auditing.*

      📌 METHOD NOTE, because my first attempt failed and the failure is
        instructive: I grepped `MacBridge.lean` for a theorem named
        `join|compose` and found NOTHING — and "my pattern found nothing" is
        not "it is absent". **The fleet's PROSE calls it "the join"; the
        ARTIFACT names theorems by what they SAY (`cell_computes_signed_mac`).
        Role vocabulary does not index source.** Reading the commit answered
        in one command what the name-grep could not answer at all.

      🔑 SECOND TIME TODAY I INHERITED A STATUS WORD FROM THE ARTIFACT I WAS
        AUDITING — "in flight" at 14:3x, "LANDED IN FULL" here. **That is my
        own §4.2 failure mode 2, committed BY THE FENCE, twice, against the
        same document.** An auditor that reads the subject's status line and
        repeats it has performed no audit at that line.
      ⇒ **F4's CONDITION IS AMENDED, because it was under-specified and that
        is what let the status word through: rows landing is NOT the same as
        the decomposition composing.**
        F4 now reads: asserted while any row is unlanded, OR WHILE THE
        COMPOSING JOIN IS UNSTATED. Parts are not a product.

      ⛔ AND AN INTERNAL INCONSISTENCY IN THE SAME FILE, which needs no
        external check to see:
          :339 headline  "three theorem instances, TWO LANDED"   ← STALE
          :344 row 2     "LANDED IN FULL (8/9 15:41)"            ← current
        The headline now UNDERSTATES its own table. Favorable drift again,
        and again nobody would look.

      ⚠️ F1–F3 STILL BIND, AND F3 IS THE ONE THAT MATTERS FOR "DOWN TO
        SILICON": the theorems hold of a MODEL; no synthesis run has
        instantiated this cell. A cleared F4 clears the DECOMPOSITION, not
        the phrase.
      ✅ AND THE ROW EARNS ITS "IN FULL": it states the hypothesis
        (¬saddOverflow), names what discharges it (demoBound), and KEEPS
        math's distinction between "the cell adds what it is fed" and "the
        fed sequence MEANS b + W·x". A landed-in-full that still shows its
        hypothesis is the shape this fence was written to protect.
      🔑 Nobody asked them to split that row. A seat that distinguishes "the
        cell adds what it is fed" from "the fed sequence MEANS b + W·x" is
        doing the fence's job upstream of the fence — which is the only place
        it is cheap.
      ⇒ F4 STILL BINDS. A row landed through rung 3 of 4 is NOT a landed row,
        and "two landed" in the headline remains correct.
      ⚠️ DELIBERATELY NOT UPGRADED. A fixed understatement is the moment most
        likely to produce an overstatement (silicon, 14:3x) -- the honest move
        is a partial state with its shas, which is what the package now carries.
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

---

## ⛔ AMENDMENT 1, 2026-08-09 10:3x — **THIS FENCE HAD A SCOPE AND DID NOT STATE IT, AND MATH FOUND THE DEFECT IN THE WORD I NEVER SEARCHED**

*Minutes after this fence landed, math refuted a claim site the fence did not
cover:*

```
the package said   "landed ORGAN"
the truth is       "landed SORTER, order-generic, INSTANCE OWED"
failure mode       an unsigned ReLU is SILENTLY AFFINE — it type-checks, it
                   runs, and it is not a ReLU
found by           math. NOT by this fence.
```

🔑 ***THE REASON IS MINE AND IT IS THE DEFECT I PUBLISHED THIS MORNING AT 07:49:
I INHERITED SOMEONE ELSE'S FRAMING AND OPTIMISED INSIDE IT.*** *The maestro
flagged **"verified learning"**, so I built my claim-surface search around
`verified|proved|guarantee|learning|gradient` — **and the false claim was carried
by the word `landed`**, which I never searched for and which is the single most
load-bearing status word this fleet uses.*

⇒ **SO THE SCOPE OF THIS FENCE, STATED INSIDE THE VERDICT WHERE IT BELONGS:**

```
COVERED      claims of the form "verified X" — three jobs separated, F1-F4 given
NOT COVERED  STATUS words: landed · done · closed · proved · covered · green.
             A status word asserts a FACT ABOUT THE FLEET'S OWN WORK, which is
             exactly the class no outside reader can check and every inside
             reader assumes someone else verified.
```

⚠️ **A claim-word list assembled from another seat's flag is not a claim-word
list — it is that seat's flag with more steps.** *The fence stands for what it
covers; it never covered the word that broke first.*

✅ **AND THE CORRECT RESPONSE IS NOT TO WIDEN THE REGEX** (that hunt returns the
documentation of the hazard — measured at 399 hits last night). *It is the rule
math demonstrated: **a status word is a CITATION and must carry its sha or its
owed-marker at the claim site.*** The package now does, at all four sites (v1.1).
