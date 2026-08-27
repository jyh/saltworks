# `retire` CARRIES TWO CONTRACTS — ONE DOCUMENT, ONE RATIFICATION OF THE PAIR

**Authored by:** compiler seat · **2026-08-26**
**Under:** the Captain's ruling *"Yes (a)"* (17:4x), on the helm's recommendation, after compiler
reported that one pin carries two independent contracts.
**Convention:** COMPILER DEMONSTRATES, THE CAPTAIN RATIFIES.

---

## ⛔⛔ 0. THE SIGNATURE CLAUSE — READ THIS BEFORE SIGNING ANYTHING BELOW

***A SIGNATURE ON THIS DOCUMENT IS A SIGNATURE ON BOTH CONTRACTS IN §1 AND §2, TOGETHER AND
INSEPARABLY. THERE IS NO WAY TO SIGN ONE OF THEM HERE.***

This clause is the point of the document. The two contracts were previously stated in two files
whose owners do not read each other's, and two signatures were owed on the wire — so a single
"yes" could later have been read as covering both while only one had ever been stated. **Putting
them in one document does not close that ambiguity unless the document says so in its own text.
This is that sentence.**

⛔ **AND WHAT IS EXPLICITLY NOT A SIGNATURE ON EITHER CONTRACT:** the Captain's earlier *"Yes,
renumber"* (17:3x) ratified **the width fallback and nothing else** — the 1316 arithmetic, landed
as one act. The helm fenced that on the bus before it could be misread. **It is not one of the two
signatures owed here, and it must never be counted as one.**

⇒ **SIGNATURES OWED AGAINST THE PAIR: compiler's (§6.1), then the Captain's (§6.2).**

---

## 1. CONTRACT A — `retire` SEPARATES THE STORE BEATS  *(silicon's, in silicon's words)*

> **`retire` SEPARATES THE STORE BEATS**, low on address, high on data.
> `retire_is_the_only_separator` (`BusFSM.lean:178`) is exhaustive by `decide +kernel` over every
> state pair sharing a type code and differing in payload, **so the store datum's PLACEMENT rests
> on `retire` and nothing else.**

⚠️ **PROVENANCE, STATED SO IT CANNOT BE MISTAKEN FOR MINE:** this text reached me from the helm at
17:4x as silicon's own wording. **I did not write it and I did not paraphrase it.** ⛔ *A verbatim
quotation relayed through a third party is still a relay* — **silicon confirms or corrects §1
before the Captain signs.** I verified only what I could verify at my own hand: the theorem exists
at that file and line, and its proof is `decide +kernel` (§5).

## 2. CONTRACT B — `retire` DECLARES THE CORE'S STALLS  *(compiler's)*

**`retire` DECLARES THE CORE'S STALLS: it is exactly "not presenting a bubble".** That is what
makes `stalls : Env → Bool` **faithful rather than convenient.**

The kernel's `Env` is `Net → Bool`, and the modelled domain is `stWidth = 32*32 + 32 = 1056` state
nets plus one 32-bit instruction word (`coreInWidth = stWidth + 32`) — **architectural state and
one instruction, and nothing else.** `Circ` is purely combinational; there is no flop node in the
kernel at all. ⇒ **an adapter FSM output cannot be a function of that domain**, and the resolution
is not to widen the domain but to stop needing it: **a stall is declared by the WORD presented to
the core.** `decode 0 = none`, so a bubble is `MemFree` by construction.

⇒ **THE RTL MUST SUPPLY:** *while the adapter is not ready, the word presented on the core's
instruction nets is the bubble encoding; and `retire` is exactly "not presenting a bubble".*

## 3. WHY ONE DOCUMENT — THE HAZARD THIS CLOSES

***A CHANGE MADE FOR ONE CONTRACT SILENTLY ALTERS THE OTHER.*** Move `retire` one beat to answer a
store-placement question and you have changed **which cycles the kernel calls stalls** — in a file
nobody was editing, through a predicate nobody was reading.

**And the placement made it worse than the coupling itself:** Contract A sat in a Verilog port
comment, Contract B in a Lean module header, **and neither owner reads the other's file.** The
coupling was physical from the start; only its *statement* was split.

✅ **compiler's position on consistency, stated as opinion and labelled as such:** the two contracts
appear to me to be **consistent** — during a multi-beat store the core should see bubbles until the
final beat, which is precisely when `retire` rises. ⛔ **CONSISTENT IS NOT SAFE**, and that is why
this document exists rather than a note saying "they agree".

## 4. WHERE THIS LIVES, AND WHAT POINTS AT IT

This document is the home. **Pointers are owed at both old homes, each written by that file's
owner** — a pointer written by a non-owner is an edit across a lane boundary:
```
SaltWorks/HDL/StallShape.lean   compiler's   ✅ points here (compiler's hand)
SaltWorks/HDL/BusFSM.lean       silicon's    ⛔ OWED — silicon's hand
SaltWorks/Silicon/RTL/busadapt8.v beside `output retire;`   silicon's   ⛔ OWED — silicon's hand
```
🔑 **THE RTL POINTER IS THE ONE THAT MATTERS MOST, AND IT IS THE ONE MISSING.** The hand most
likely to move `retire` is editing RTL, arrives at `output retire;`, and today has no path from
there to either contract. **The direction that is absent is the direction that gets used.**

## 5. EVIDENCE — EVERY CITATION VERIFIED AT COMPILER'S HAND, WITH A CONTROL

```
CONTRACT A   retire_is_the_only_separator          SaltWorks/HDL/BusFSM.lean:178   decide +kernel
             retire_separates_the_store_beats      SaltWorks/HDL/BusFSM.lean
             store_beats_share_a_type_code         SaltWorks/HDL/BusFSM.lean
             store_beats_differ_in_payload         SaltWorks/HDL/BusFSM.lean
             type_pins_are_insufficient_for_the_store_path   SaltWorks/HDL/BusFSM.lean
CONTRACT B   stallArm_reduces · stallArm_strictly_extends · mixed_stall_witness
                                                   SaltWorks/HDL/StallShape.lean
             saltbuild EXIT=0 · 8611 jobs · 0 errors · 0 sorryAx · 26 audited names
CONTROL      a name that must NOT exist returned 0 matches, so the check could fail
```
⚠️ **A citation is a measurement**, and a document citing a renamed theorem reads correct forever.
Every name above was resolved against the tree at authoring time, with a negative control.

## 6. SIGNATURES — AGAINST THE PAIR, NEVER AGAINST ONE

### 6.1 compiler — SIGNED 2026-08-26, and here is exactly what I am attesting

**I attest, at my own hand:**
- **Contract B is mine**, and its kernel half is built and kernel-audited (§5 receipt).
- The **citations in §5 exist** as written, verified with a control.
- The **coupling in §3 is real** and its statement was split across two files.

**I do NOT attest:**
- **that Contract A's RTL behaves as §1 says** — I did not verify the RTL; I verified that the
  theorem exists and how it is proved. **That half is silicon's to stand behind.**
- **that the two contracts are jointly satisfiable in the built hardware.** §3's consistency is my
  reading, not a proof, and it is labelled as such.

### 6.2 the Captain — RATIFICATION OF THE PAIR

```
    signed: ______________________   date: __________
    ⇒ ratifies §1 AND §2 together, per §0. Not the width; the width was ruled separately.
```

## 7. WHAT THIS DOCUMENT DOES NOT DO

It does not change a wire, a proof, or a schedule. It states two contracts in one place so that
one signature cannot be read as covering a contract nobody wrote down — **and so that the next
hand to touch `retire` learns, before the edit, that the pin has two jobs.**
