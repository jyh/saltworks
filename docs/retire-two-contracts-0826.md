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

> **A store occupies TWO consecutive bus loops. Both announce `T_STORE` on the type pins at
> phase 0. The first carries `c_dmem_addr` on `pin_out`; the second carries `c_dmem_wdata`.
> The ONLY output that distinguishes them is `retire`: LOW on the address beat, HIGH on the
> data beat.**
>
> **Therefore: any consumer that places a store datum MUST read `retire`. A consumer that
> reads only the type pins will pair the beats wrongly and write the ADDRESS into memory as
> the datum — silently, with no hang and no type-stream anomaly.**

Kernel-checked in `BusFSM.lean`: `retire_is_the_only_separator` (`:178`) is exhaustive by
`decide +kernel` over every state pair sharing a type code and differing in payload.

### 1.1 ⛔ PROVENANCE — AND A LABEL OF MINE THAT WAS FALSE, CORRECTED 2026-08-26

**The text above is now copied from silicon's OWN LANDED DOCUMENT**
(`docs/silicon-T5-contract-and-T2-check-0826.md` §1.2, `saltworks 34b14ab5`, silicon's hand, in
git). ⇒ *the relay is discharged by an ARTIFACT rather than by a promise, and it needs no further
confirmation from a seat that has since banked and left.*

⛔ **WHAT WAS HERE BEFORE, AND WHY IT WAS WRONG.** §1 previously carried a 41-word passage reaching
me through the helm, labelled *"silicon's words, verbatim, not paraphrased"*. **Measured against
silicon's landed text: 17.3% word overlap, 41 words against 86.** It was a CONDENSATION wearing a
verbatim label — *and I wrote the warning about exactly this ("a verbatim quotation relayed
through a third party is still a relay") in the same section it was false in.*
🔑 ***AND THE HALF THE CONDENSATION DROPPED IS THE HALF A RATIFIER MOST NEEDS: the FAILURE MODE.***
silicon's contract says what goes wrong — *a consumer that reads only the type pins pairs the beats
wrongly and writes the ADDRESS into memory as the datum, silently, with no hang and no type-stream
anomaly.* **My version stated the fact and dropped the consequence.** A signature obtained against
the short version would have been a signature against a strictly weaker claim.

## 2. CONTRACT B — `retire` DECLARES THE CORE'S STALLS  *(compiler's)*

**`retire` DECLARES THE CORE'S STALLS.** The kernel's `Env` is `Net → Bool`, and the modelled
domain is `stWidth = 32*32 + 32 = 1056` state nets plus one 32-bit instruction word
(`coreInWidth = stWidth + 32`) — **architectural state and one instruction, and nothing else.**
`Circ` is purely combinational; there is no flop node in the kernel at all. ⇒ **an adapter FSM
output cannot be a function of that domain.** That is criterion (c), and it is why this contract
had to be written down at all.

**THE INSTANTIATION IS `stalls := ¬retire`, AND IT BECOMES AVAILABLE THROUGH THE RATIFIED
WIDENING.** silicon measured the domain: `retire = f(kind, storeBeat, req)`, where `kind` (2 bits,
`busadapt8.v:77`) and `storeBeat` (1 bit, `:78`) are ADAPTER REGISTERS and only `req` is in `Env`.
Once the widening puts those three bits in the state, `retire` is a function of `Env` and the
parameter can be supplied. ⇒ ***T2's BLOCKER AND STEP 7's RENUMBERING ARE THE SAME ITEM*** — the
act the Captain ratified for the assembly is the act that makes this contract instantiable.

### 2.1 ⛔ WHAT §2 SAID BEFORE, AND WHY IT IS STRUCK — WRITTEN IN, NOT REPLACED

> *"…the resolution is not to widen the domain but to stop needing it: **a stall is declared by
> the WORD presented to the core**. `decode 0 = none`, so a bubble is `MemFree` by construction."*
> *"**THE RTL MUST SUPPLY:** while the adapter is not ready, the word presented on the core's
> instruction nets is the bubble encoding."*

***REFUTED BY THE WIRE, 2026-08-26, by compiler reading the RTL rather than waiting to be
checked:***
```
busadapt8.v:215   assign c_instr = (kind == T_FETCH && phase == 2'd3)
                                     ? {pin_in, in_acc[23:0]} : instr_r;   ⇐ THE HELD PREVIOUS
                                                                              INSTRUCTION
grep bubble|nop over SaltWorks/Silicon/RTL/*.v                             ⇐ NOTHING
plane32bus.v:73   .en(retire)                                              ⇐ STALLED BY ENABLE
```
⇒ **THE MACHINE DOES NOT PRESENT A BUBBLE WHILE THE ADAPTER IS BUSY. It holds the previous
instruction and freezes the core with `en`.** The struck text asked the RTL for a sentence the RTL
does the opposite of — which would have been a DESIGN CHANGE presented as a description.
⚠️ ***AND NOTE THE DIRECTION OF THE ERROR: it made the campaign's critical path look CHEAPER and
UNBLOCKED.*** A wrong answer that removes a dependency is the one nobody checks. It was found only
because the ratification carried an explicit condition to hunt for INCONSISTENCY rather than
confirmation.

### 2.2 ⭐⭐ WHAT SAVED THE DEFINITION: PARAMETERISATION — A TECHNIQUE, NOT TODAY'S LUCK

`CycleRealisesStepOrStalls` takes `stalls : Env → Bool` **as a parameter**. The predicate says what
a stall MEANS; which cycles ARE stalls is supplied from outside.
```
had `stalls` been a CONSTANT baked to the bubble reading:
    the refutation above falsifies THE DEFINITION, the witness, and every theorem over it
because `stalls` is a PARAMETER:
    only the INSTANTIATION died. Shape, witness, reduction and strict-extension all stand.
```
🔑 ***PARAMETERISE THE PART THE OTHER LANE OWNS.*** The kernel owns what a stall MEANS; the RTL
owns which cycles ARE stalls. Writing that boundary into the TYPE — rather than into a comment —
is what let two lanes work independently and still meet, and it is what bounded a wrong reading of
the wire to one line of instantiation instead of a campaign.
📌 **silicon named the parameterisation as the load-bearing half in its check (§2.1 of
`docs/silicon-T5-contract-and-T2-check-0826.md`) BEFORE the refutation was found.** *It was
identified as the thing carrying the weight before anything fell on it, which is the only kind of
evidence that a design technique works.*

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

## 5.1 ⭐⭐ THE CONSISTENCY CHECK — RUN AGAINST silicon's OWN MODEL, TRYING TO BREAK THE PAIR

The helm's condition on this ratification: *"if the two contracts turn out NOT to be consistent,
that stops the ratification and outranks the document."* **`SaltWorks/HDL/T2T5Consistency.lean`
is the attempt to break it, and it failed to.**
```
retire_iff_frame_ends                 retire is EXACTLY the frame-end — exhaustive over all 8
                                      states x req x we. Had this failed in one cell, T2 would
                                      put the core's advance on a beat the frame is still running.
control_mutant_breaks_the_anchor      THE NEGATIVE CONTROL: the same check against a MUTATED
                                      retire evaluates to FALSE, so the exhaustive test CAN fail
store_retires_on_the_second_beat_only T5's low-on-address / high-on-data and T2's bubble-then-
                                      instruction name THE SAME BEAT — one instruction, one retire
fetch_with_request_holds              a fetch with a request in flight does NOT retire, so the
                                      core is held exactly while memory is being reached
                                      all four: [0 axioms], saltbuild EXIT=0
```
⛔ **AND THE RESIDUE, NAMED RATHER THAN IMPLIED: `BusFSM` models the adapter's state, NOT the word
presented to the core.** So T2's final link — *while the adapter is not ready the word presented is
the bubble encoding* — **is NOT decided by this file and is not claimed by it.** What is decided is
the anchor that link hangs on. ⇒ **ONE WIRE QUESTION REMAINS, AND IT IS SILICON'S** — and as
of §5.2 it is a question about the FETCH STATE, not about the correspondence at large.

## 5.2 ⭐⭐ THE `req` OBLIGATION, CONFINED TO ONE STATE — `SaltWorks/HDL/ReqWordSource.lean`

`StallsAtWidened` names an obligation it cannot see, in its own header:

> *"If it is off by one, the equation below still holds — it is stated over whatever `reqAt`
> returns — but the FUNCTION would be reading the wrong word, and no theorem here would notice."*

⛔ **WHY NO THEOREM THERE NOTICES IS STRUCTURAL, NOT AN OVERSIGHT.** `stallsAt_eq_not_retire` reads
`stallsAt e = !(retire s (reqAt e))` — with `reqAt e` **on both sides**. It is an IDENTITY in the
`req` argument, so it holds for *every* word source, including one reading uninitialised memory.
***A THEOREM THAT MENTIONS THE SUSPECT QUANTITY ON BOTH SIDES OF ITS OWN EQUATION IS NOT EVIDENCE
ABOUT THAT QUANTITY.***

The cure is this seat's own technique — **parameterise the part the other lane owns** — applied to
the word source itself, `stallsFrom (word : Env → BitVec 32)`, with `stallsAt = stallsFrom
seenWordFull` definitionally. Three results the identity could not give:
```
stallsFrom_agrees_off_fetch        CONFINEMENT — `retire` consults `req` in the `fetch` state and
                                   NOWHERE ELSE, so two word sources can disagree about `stalls`
                                   ONLY where the adapter is fetching. Every load, store and idle
                                   state is IMMUNE to the off-by-one.
word_source_decides_at_fetch       SENSITIVITY — in the fetch state the word source DECIDES,
                                   witnessed on two real RV32I words (a LW and an ADD): opposite
                                   stall decisions. ⇒ THE OBLIGATION IS REAL, NOT COSMETIC.
off_by_one_confined_to_fetch       THE BOUNDED SIDE CONDITION — if the presented word and the
                                   word actually held agree on `req` WHENEVER THE ADAPTER IS
                                   FETCHING, they define the SAME stall function everywhere.
control_confinement_needs_its_hypothesis   drops the fetch hypothesis; conclusion FALSE
control_retire_is_not_req_blind            `retire` does depend on `req` somewhere, so the
                                           confinement result is not vacuous
                                   11 audited names, 0 sorryAx, saltbuild EXIT=0
```
⇒ **WHAT CHANGES FOR SILICON'S SUCCESSOR.** They do **not** have to prove that `instr_r` presents
the current instruction in general. They have to settle it **on the fetch state only** — and
`off_by_one_confined_to_fetch` is what turns that reduction from a plausible argument into a
checked one. The surface shrinks from *"the `req` correspondence"* to *"the `req` correspondence in
the fetch state"*.

⛔ **THIS PROVES NOTHING ABOUT `busadapt8.v`, AND IS NOT A DISCHARGE.** Which word the RTL presents
is silicon's lane. **The item stays OPEN on the pair.** What changed here is that the Lean side can
now SEE the difference, and the open item has a stated blast radius instead of an unbounded one.

⚠️ **THIS SUBSECTION WAS WRITTEN AT 19:2x AND ITS RTL CLAUSE WENT STALE AT 19:46:52** — it said
`busadapt8.v:126-131` was *"unchanged and still says so in its author's own words"*, and silicon
changed exactly those lines two and a half hours later. ⭐ **The citation itself moved and LANDS
SAFELY ANYWAY: the quoted paragraph is now `:130-136`, and silicon put the strike header at
`:126-129` — exactly where this document's pointer aimed — with the stated reason "compiler cites
these lines". A stale pointer that arrives at the notice that its target was answered is a pointer
someone maintained on my behalf across a lane boundary.** **The sentence was true when written, and
an undated claim about another lane's live file is a claim with an expiry nobody can see.** The
current state is §5.3; this paragraph is corrected in place rather than rewritten, because §5.2's
argument does not depend on it and the correction is the more useful record.

## 5.3 ⭐⭐ THE RTL SIDE, MEASURED — AND WHAT STILL STANDS BETWEEN THIS AND A SIGNATURE

**silicon `45c9c56`, 2026-08-26 19:46:52.** The open `req`-timing item's own file already held the
answer, about ninety lines below the paragraph that declared it open.

```
THE MECHANISM   the instruction bypass presents the newly assembled word at exactly
                `kind == T_FETCH && phase == 2'd3`, and `loop_end` IS `phase == 2'd3`
                ⇒ at the decision edge the decode reads the CURRENT instruction
ARM A   as shipped .............. 6/6 PASS
ARM B   bypass defeated ......... RED, 2/6 FAIL, reproducing the recorded 08/18 signature
                                  exactly: st_data=00000000, instr=0000a183, rs2=0
THE RUNNER REFUSES if ARM B ever goes green, so ARM A's green is EVIDENCE, not a replay.
                Committed rather than typed — a receipt whose producer lives in a terminal
                dies with the terminal.
WHY THE 08/18 PARAGRAPH WAS WRONG: it was written at 14:2x and the bypass it did not know
                about was ratified at 16:5x THE SAME DAY, for exactly this defect. It is
                struck in place and kept verbatim, because this document cites those lines.
```

### How the two lanes met, having not aimed at each other

silicon's commit states it plainly: **compiler's `off_by_one_confined_to_fetch` is what makes the
RTL fact SUFFICIENT rather than merely encouraging — without the confinement, a green bench is only
a green bench.** And the bypass fires at `T_FETCH`, which is the state the confinement had already
isolated as the only one where `req` is consulted.

⇒ ***THE TWO RESULTS MET BECAUSE EACH WAS STATED IN TERMS THE OTHER LANE COULD CHECK, NOT BECAUSE
EITHER WAS WRITTEN FOR THE OTHER.*** Neither seat asked the other for this shape.

### The Lean side's half, as it now stands (`SaltWorks/HDL/ReqWordSource.lean`)

```
§2   CONFINEMENT      `retire` consults `req` at the FETCH state and nowhere else
§3   SENSITIVITY      at a fetch the word DECIDES — two real RV32I words, opposite answers
§4   THE SIDE CONDITION  agreement on `req` at fetch ⇒ the same stall function everywhere
§4.1 THE AUDIT        `stallsAt_is_middle` exhibits its middle at two STORE states, where
                      `req` is provably ignored ⇒ the landed non-vacuity witness holds for
                      EVERY word source. Flagged by a pre-registered identity audit, and
                      the missing FETCH-state arm is now supplied.
§4.2 THE EXACT SET    an IFF, not a containment: two readings differ PRECISELY at a fetch
                      where the words disagree on memory-ness. At a fetch, `stalls` IS `req`.
§4.3 CROSS-CHECK      §4.2 predicts such a failure needs the pair to differ in memory-ness,
                      so at least one is a LW/SW. ARM B's `0000a183` decodes as a load, and
                      an ALU control returns false — the prediction had a way to lose.
```

## ⛔⛔ 5.3.1 — WHAT REMAINS, AND WHY THIS IS STILL NOT A SIGNATURE

```
req timing   RTL side MEASURED, both arms, driven negative control, committed runner.
             Lean side CONFINED, CHARACTERISED and CROSS-CHECKED.
             ⛔ UNPROVED: the netlist ↔ Lean correspondence, `sem (bridge nl outs) = runP`.
placement    the three adapter bits into `core.outs` — SAME BRIDGE. Not started.
```
⇒ **BOTH REMAINING ITEMS REDUCE TO ONE OBJECT: the bridge induction, already routed off both
seats.** That is a known blocker, not a new one, and it is the reason a measured bench and a
kernel-checked model still do not compose into a signature.

⚠️ **AND THE HONEST STATEMENT OF §4.3'S WORTH:** two independently-derived facts agreeing is
EVIDENCE OF AGREEMENT, not proof of correspondence. **Two models wrong in the same way would agree
too.** What the cross-check rules out is the cheap failure — where the Lean side's discriminating
set and the RTL's actual failure mode are simply about different things. That is worth stating and
worth no more than that.

## 6. SIGNATURES — AGAINST THE PAIR, NEVER AGAINST ONE

### 6.1 compiler — SIGNED 2026-08-26, and here is exactly what I am attesting

**I attest, at my own hand:**
- **Contract B is mine**, and its kernel half is built and kernel-audited (§5 receipt).
- The **citations in §5 exist** as written, verified with a control.
- The **coupling in §3 is real** and its statement was split across two files.

**I do NOT attest:**
- **that Contract A's RTL behaves as §1 says** — I did not verify the RTL; I verified that the
  theorem exists and how it is proved. **That half is silicon's to stand behind, and §1 is now
  silicon's own landed text rather than a relay through me.**
- **that the two contracts are jointly satisfiable in the built hardware.** §5.1 raises §3 from a
  reading to a machine-checked result **over silicon's model** — with a control proving the check
  could fail — but a model is not the wire, and the one link it cannot see is named there.

### 6.2 the Captain — RATIFICATION OF THE PAIR

```
    signed: THE CAPTAIN — at the R10 sitting, 2026-09-02 12:4x–12:56 PDT ("accept rec")
    date:   2026-09-02
    record: the helm's R10 sitting minute (bare filename 2026-09-02-R10-SITTING-minute.md, private record) @ bf813512, §(C)  <- THE MINUTE IS THE SIGNATURE;
            this block is silicon's CITATION of it (recorded 13:0x), not a signature in its own right.
    with §5.3.1 READ INTO THE MINUTE: the netlist<->Lean correspondence (sem (bridge nl outs) = runP) and
            the three-bit placement both reduce to the bridge induction, routed off both seats — the pair
            is MEASURED on RTL and KERNEL-CHECKED on the model, NOT COMPOSED. The signature ratifies a
            STATEMENT of the pin's two contracts; it certifies no hardware.
    ⇒ ratifies §1 AND §2 together, per §0. Not the width; the width was ruled separately.
```

## 7. WHAT THIS DOCUMENT DOES NOT DO

It does not change a wire, a proof, or a schedule. It states two contracts in one place so that
one signature cannot be read as covering a contract nobody wrote down — **and so that the next
hand to touch `retire` learns, before the edit, that the pin has two jobs.**
