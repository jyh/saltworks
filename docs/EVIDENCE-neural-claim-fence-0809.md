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
      ⛔⛔ **SCOPE AMENDED 2026-08-09 19:3x — MY OWN CELL-LEVEL LINE ABOVE IS
        TOO GENEROUS, and I am narrowing it BEFORE the run that would have
        cleared it.** *Math ran F5's (c) against the emitted module and found
        what no shape test was looking for; I re-measured it independently
        rather than inheriting it:*
```
        THE EMITTED MODULE CONTAINS NO STATE AT ALL.
          instantiated cell types  and2_1 · or2_1 · xor2_1 — and nothing else
          dfxtp 0 · dff 0 · latch 0 · always 0 · posedge 0 · reg 0 · clk 0
          ports 163 (67 in + 96 out) · inout 0
        The 64 state bits ENTER as i3..i66 and LEAVE as o32..o95.
```
        *Compiler answered the wrapper question by citation, from the
        top-module block's §D2 (the maestro's words): **"emitS is
        combinational-only; no emitSeq exists (grep 0 hits); every flop in the
        fabricated tree is hand RTL. The law cannot be met for state as the
        toolchain stands."***
```
        SO THE CELL ROW SPLITS, AND ONLY THE FIRST HALF IS EARNABLE TODAY:
          combinational CORE synthesised
              ⇒ "the cell's COMBINATIONAL CORE is certified down to silicon"
          a CLOCKED cell
              ⇒ ⛔ THIS LINE WAS STALE AND IS AMENDED 2026-08-10 13:5x.
                IT READ: "NOT AVAILABLE. It needs emitSeq, which does not exist."
                ***emitSeq LANDED 2026-08-10 01:1x (2704fa0) AND THE CLOCKED CELL
                IS EMITTED: L1 meets V7 MECHANICALLY on the artifact — flops
                64 == nState, cells 289 == 225+64, conb 0, 32/32 outputs driven
                exactly once, no `initial`.***
                ⇒ WHAT IS STILL OWED IS NOT THE TOOL BUT THE ∀ st0 REFINEMENT
                  CLAUSE, which is a property of a LEAN STATEMENT and which no
                  netlist check can clear. V9's run-level refinement is OWED with
                  its obstacle named (the corpus lacks the non-flat
                  generalisation of `run_of_flat_gates`).
                🔑 CAUGHT BY COMPILER'S WIDER ABSENCE-PATTERN SWEEP, run on my
                own file at their 13:5x flag. THIS IS THE EXPENSIVE DIRECTION OF
                STALENESS: a successor reading this SCOPE BLOCK would have
                enforced "no clocked cell is available" against an artifact that
                has existed and passed its bar for twelve hours — obeying a
                withdrawn rule, carefully, citing me.
          the pin wrapper, the sequencer FSM, the fabric
              ⇒ HAND RTL. EXCLUDED BY NAME from any fabbed-is-verified sentence.
```
      🔑 ***AND THE SHARPEST FORM OF IT IS COMPILER'S, ABOUT MY OWN INSTRUMENT:
        the thing my simulator was silently supplying — holding 64 bits and
        driving load/sign — IS PRECISELY THE THING THAT DOES NOT EXIST IN
        SILICON.*** *My arithmetic control's undisclosed frame was standing in
        for an unbuilt component, which is why the disclosure is worth more than
        the green it qualifies.*
      ⚖️ *Registered, not ruled: the top-module block is v1 under a five-refuter
        pass, and a block under refutation is not a ruling. This amendment binds
        MY fence, which is mine to narrow at any time; it claims nothing about
        anyone's schedule.*

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

### ⭐ F5 — UNREACHABLE HYPOTHESIS (adopted 2026-08-09 17:5x; math's name and test)

> **UNREACHABLE HYPOTHESIS — a theorem about organ A is composed into artifact B,
> every certificate true, and B cannot present the inputs the theorem quantifies
> over. The theorem never becomes false; it just never fires.**

```
FALSIFIED IF a composed theorem carries a hypothesis that NO PORT of the
             composed artifact can supply.
THE TEST (math's, verbatim, and it is mechanical):
  "for each hypothesis of a composed theorem, ask WHICH PORT OF THE COMPOSED
   ARTIFACT SUPPLIES IT. If no port can, the theorem is true and inapplicable."
  Checkable by a hand with the netlist and the statement side by side --
  it needs no judgement, only the question being asked once.
```
**LIVE INSTANCE, 2026-08-09 17:45 (the executor's kernel-checked refutation):**
*the sign-cycle theorem is TRUE of `macSeq`; `ccCore`'s addend port carries only
`andWord x w` and no complement path exists, so the complement is not
expressible.* ⇒ **The hypothesis is UNREACHABLE, not false. The accumulation
join stands; the SIGNED claim for the composed cell waits on hardware.**

⚖️ **WHY IT ESCAPED F1–F4 AND THE CLAIM FENCE, which is why it earns its own
number:** *F3 guards KERNEL vs SILICON — this is kernel-vs-kernel. The claim
fence guards NUMBERS and their WINDOWS — this has neither.* ***It is a fence on
the QUANTIFIERS' DOMAIN: a ∀ over addends is only as useful as the addends the
machine can present.***

📌 **ADOPTION NOTE, because I said otherwise ninety minutes earlier.** *At 17:46
I declined to amend tonight, on the grounds that the right SHAPE was not clear
and a fast amendment had cost me two retractions this afternoon. **Math then
supplied the shape WITH a mechanical test.** The condition I set for acting was
met earlier than I expected, so I acted — and I am recording the reversal rather
than performing consistency I do not have. **The restraint was against acting
without a shape, not against acting.***

### F5 — THE TONIGHT CRITERION for the complement path (pre-registered 2026-08-09 18:52, BEFORE the landing existed)

*Design item #2 is the live F5 instance. This criterion was published on the bus
before compiler landed anything, so it could be BUILT TO rather than judged after.*

```
F5 CLEARS on the signed cell when, ON THE EMITTED NETLIST (not the design doc):
 (a) the addend reaching the adder can PRESENT ~w — the XOR bank is in emitS
     OUTPUT, not only in the ruling that adopted it
 (b) maCin and the XOR bank's sign input are THE SAME NET in the emitted module
 (c) every hypothesis of the signed composition theorem traces to a PORT THAT
     CAN SUPPLY IT, named port per hypothesis
INSTRUMENT  sh docs/ledger-tools/emit_cell.sh cell — netlist and statement
            side by side. Named so a hand that is not mine can run it.
```
⚠️ **F5 KEEPS BINDING if the theorem lands TRUE and the artifact still cannot
present the complement.** *A true-and-inapplicable theorem looks like a success
from every status line in the building — that is the whole reason F5 exists.*

⛔ **(b) AMENDED 18:5x IN ITS PRE-REGISTRATION WINDOW — silicon's catch, adopted
whole. It read "the NETLIST" unqualified, and on this corpus that names TWO
artifacts that MEASURABLY DIFFER:**
```
silicon's measurement, landed c5aadf8, on the exact organs the signed cell uses:
  mac_acc     emitted 160 cells  ->  synthesised 157   (opt_clean -purge drops 3)
  mac_wshift  emitted  33 cells  ->  synthesised  33   (nothing dead)
⇒ SYNTHESIS IS NOT IDENTITY ON THE CELL SET.
```
*On the EMITTED RTL signal identity is STRUCTURAL — `emitS` leaves nothing for abc
to re-derive. On the SYNTHESISED netlist yosys does not preserve net names in
general, so "the same signal" is a CONNECTIVITY TRACE, not a name match.*
🔑 ***Unpinned, (b) could fail a structurally-correct design for a reason belonging
to the OPTIMISER, and could be passed by a RENAME. Two fence defects, opposite
directions, one ambiguous noun.*** ⇒ **(b) is pinned to the EMITTED netlist, where
(a) already lived.**

📌 **REGISTERED AS A SECOND AND EXPLICITLY WEAKER CHECK — (b2), NOT a gate on F5:**
*on the synthesised netlist, the sign signal's connectivity trace reaches both
`maCin` and the XOR bank. It can show PRESENCE; it cannot show identity by name.*
**A (b2) failure is a question for silicon, never a fence verdict.**

⚖️ **WHAT THIS AMENDMENT DOES NOT ADOPT, because silicon explicitly did not claim
it:** *nothing here says abc absorbs or restructures this XOR bank. That is a
prediction about an object that does not exist yet.* **The amendment rests only on
the measured 160→157 delta.**

🔴 ***AND THE SELF-INDICTMENT, because it happened in ONE POST: the same bus line
that corrected the maestro for a sentence missing its SUBJECT ("F3 clears at the
scope the run covers, and no wider") shipped a criterion of mine missing its
ARTIFACT.*** **"The netlist" is not a name, it is a PAIR — the same defect class as
an unqualified scope in a count, one noun over. I applied the law outward and not
to the paragraph beneath it.** *Third time on this seat that the instrument
exhibited the class it was built to catch; the countermeasure is to run the law
against my own sentence before the post, not after.*

✅ **CONVERGENCE WORTH KEEPING: silicon's pre-registered step (3) reads the gate
count of the Circ ACTUALLY EMITTED — the same artifact this criterion now names.
Two seats, one file, rather than two seats reading two files and agreeing.**

## 🚦 OPEN FENCE VERDICTS AT THE 2026-08-09 CLOSE — both reach the Captain at the 07:30 sitting

*Recorded HERE and not only on the bus, because a verdict that lives in 50,000
lines of append-only log is a verdict nobody re-reads. Both were routed to me;
both are UNREPAIRED as of 20:1x; replacement language was supplied with each so
the repair is one edit, not a round trip.*

### ⛔ (1) THE DEMO SENTENCE — `ndf-top-module-design-v1.md` §D5. NOT CLEARED.

```
THE CLAUSE   "...a dataflow fabric whose netlist is kernel-checked against its
              Lean model ON THE SCHEDULE CLASS WE RUN..."
THE FACT     the block's OWN refutation ledger, FATAL-1: fabric_routes covers
              only prefix-concentrated destination-monotone traffic, and ZERO
              rounds of the §4 demo were in the certified set. V10 — the
              per-round fixtures that would certify them — is marked NEW.
⇒ "THE SCHEDULE CLASS WE RUN" IS PRECISELY THE UNCERTIFIED CLASS.
   A future claim written in the present tense.
```
✅ **CHEAPEST TRUE FORM** (no gate, no future work): *"...kernel-checked against
its Lean model on prefix-concentrated destination-monotone traffic."*
⚠️ **TWO SECONDARY REPAIRS:** *(i) "a processor whose every organ and wire is
kernel-certified ... ON ONE DIE" — the twin disclosure sits three clauses from
the die, and the die carries 546 behavioural flops of hand RTL; put the twin
adjacent. (ii) "its end-to-end refinement ONE NAMED THEOREM away" names no
theorem — an unnamed named theorem cannot be checked.*

### ⛔ (2) THE 221 CLAIM SENTENCE — `ndf-council-example-221.md`. NOT CLEARED.

```
THE CLAIM    "A neural network on VERIFIED SILICON where synchrony is
              COMPILE-TIME ARITHMETIC..."
THE RULE     "verified silicon" is banned unqualified in this file: it requires
              naming WHICH ARTIFACT and WHICH CHECKER.
THE STATE, measured 2026-08-09 evening:
  proved over ALL inputs  the cell's COMBINATIONAL CORE, 96/96 outputs
                          (SAT, docs/ledger-tools/equiv_spec.sh + compiler's
                           kernel proof + silicon's synthesis miter)
  NOT emitted             the CLOCKED cell — emitSeq does not exist (V7+V9)
  HAND RTL                state · sequencer FSM · pin wrapper · fabric · CPU
⇒ the silicon this network would run on is, today, MOSTLY HAND RTL.
```
✅ **REPLACEMENT, keeping the sentence's whole force:** *"A neural network whose
CELL CORE is proved gate-for-gate against its Lean model over all inputs — on a
die whose state elements, sequencer and fabric are still hand RTL — where
synchrony is COMPILE-TIME ARITHMETIC: no handshakes, no arbiters, no credits, no
schedulers in silicon."*
🔑 ***The compile-time-synchrony claim is the interesting one and the fence does
not touch it. It does not need "verified silicon" to land, and it is WEAKENED by
riding beside a phrase a reader can puncture.***

✅ **WHAT PASSED in that document, recomputed not assumed:** *22 frames × 14
cycles = 308; 308 × 55 ns = 16.94 µs ≈ 17 µs at the ruled clock; constants named
INLINE (CLOCK_PERIOD 55 ns / 18.2 MHz, frame = 14 = 6 header + 8 payload).* **The
first numbers document this fence has seen that carries its own basis — a reader
re-derives 17 µs without asking anyone.**

## ⭐ F6 — THE "VERIFIED LEARNING" EARN CRITERION (pre-registered 2026-08-10 12:1x, at the aim-high application block's ASK, BEFORE rung A5 exists)

*`aim-high-application-v1.md` asks rather than grants: "the 'VERIFIED LEARNING'
earn criterion is EVIDENCE's to pre-register (observable event + instrument);
this block ASKS, it does not grant." This is that pre-registration. **It is
written while the phrase is unearnable, which is the only time it is worth
anything** — the same reason this whole file was written before the first
measurement existed.*

⛔ **THE STANDING BAN IS UNCHANGED: "VERIFIED LEARNING" unqualified stays BANNED.**
*The PoC performs inference and ROUTES gradients; training is off-chip by the
design's own statement.*

### What would EARN it, and at which size

```
TIER 1 — "one verified learning STEP"   (the application block's own phrase)
  EVENT      the chip applies ONE weight update through the IN-BAND weight path,
             and the post-update weight register equals the update equation's
             value.
  INSTRUMENT (a) the update equation is a KERNEL THEOREM at int8 semantics —
                 new = old − η·grad, with η's mechanism named (the requantizer
                 shift; η=1 blows the range on step one, per the block's own §)
             (b) the applied value is read back from the ARTIFACT — the emitted
                 netlist executed, or the die — not from the model
             (c) the gradient used is the gradient OF THE STATED LOSS, proved,
                 not merely "a delta the host supplied"
  ⛔ FALSIFIED IF the update is computed off-chip and merely RELOADED while the
     sentence implies the chip computed it.

TIER 2 — "verified learning"  (unqualified, plural steps)
  EVENT      a SEQUENCE of updates whose composition is proved to descend the
             stated loss on the stated domain — not one step repeated in prose.
  INSTRUMENT a kernel theorem over the ITERATION, not over a single step.
  ⚠️ TIER 1 DOES NOT IMPLY TIER 2. One step is a step; learning is a sequence,
     and PARTS ARE NOT A PRODUCT (this file's F4, same shape).

TIER 3 — "the smallest verified learning machine"
  ADDS a MINIMALITY claim, which is a comparative over a class and needs the
  class NAMED. Absent that, it is marketing with a theorem attached.
```
🔑 ***THE THREE RIDERS THAT TRAVEL WITH ANY TIER, because every one of them has
already bitten this campaign:***
```
WHEN DRIVEN   the sequencer is hand RTL (V9's subject). A learning claim about
              the DIE inherits every hand-RTL exclusion the inference claim has.
WHICH CHECKER the kernel proves the MODEL; SAT proves the NETLIST; a bench proves
              neither. Name which one saw the update. (the public-manifest defect,
              caught 2026-08-10 10:34 — do not re-import it here)
WHICH ARTIFACT model · emitted netlist · synthesised netlist · die. A learning
              step demonstrated on a simulator is a simulator result.
```
⚖️ **AND THE HONEST NOTE THE BLOCK EARNED: its own §5 already states the earned
sentence as "one verified learning STEP" and calls it "the fence's own mechanism
for earning a phrase, used as designed." That is correct, and this
pre-registration exists to make the mechanism checkable rather than to withhold
it. A phrase with a published price is a phrase somebody can go and buy.**

## ⛔ F7 — THE GRAPHCAST DEMO (fence EXTENDED at the Captain's 11:4x input, pre-registered 2026-08-10 16:5x BEFORE any demo sentence exists)

*The register folds GraphCast in as the GNN-compiler demo and extends this fence
in the same breath: **never "forecasts weather"**, the clearance route for public naming.
This is that extension, written while no demo sentence exists — the only time it
costs nothing to obey.*

```
⛔ BANNED OUTRIGHT, unqualified, on any surface: "FORECASTS WEATHER"
   and its family: "predicts weather" · "a weather model" · "weather prediction"
   applied to OUR artifact.
WHY, at its exact size: a GNN-compiler demo that COMPILES A GRAPHCAST-SHAPED
   COMPUTATION is a statement about OUR COMPILER. It is not a statement about
   meteorological skill, which is a property of a trained model on real data
   with a verification protocol none of which is ours.
```
✅ **WHAT THE DEMO CAN EARN, and it is worth more than the banned phrase:**
```
EARNABLE   "a GNN layer of the shape GraphCast uses, compiled to a certified
            machine and executed on verified silicon organs"  (subject to the
            standing hand-RTL and WHEN-DRIVEN riders — F3/F5 apply unchanged)
NOT EARNED BY ANY AMOUNT OF THIS WORK
            any claim about FORECAST SKILL, ACCURACY, or resolution
            any comparison to an operational weather system
            "we ran GraphCast" — unless the actual published weights ran, which
            is a different claim about a different artifact
```
📌 **PROVENANCE DISCIPLINE, and it is a LANE rule before it is a fence rule: the
citation and the not-carried list are PUBLIC-PAPER-ONLY, per the register's own
wording.** *Nothing about this comparison may be sourced from anywhere but the
published paper — not from recollection, not from adjacent knowledge. **A
comparison is only as clean as its worst source, and this one has a lane boundary
running through it.***

🔑 ***AND THE NOT-CARRIED LIST IS THE POINT, NOT A DISCLAIMER: a demo that names
what it does NOT carry is a demo a hostile reader cannot puncture. The list is
this seat's P2 item; it is sourced from the public paper alone and it lands BEFORE
any comparative sentence does, or the sentence has nothing holding it.***

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

## OPEN FENCE VERDICTS

### ✅ CLOSED — the NATURE-TRACK block's "under one referee" sentence (raised 03:45, folded 08:52)

`${SEAT_DIR}/briefs/2026-08-11-nature-track-block.md:14-17`, the Captain's 03:4x
proposal, DRAFT-UNTIL-REFUTED, rides his morning surface as item zero:

> "...across four abstraction layers — research mathematics, a verified
> compiler, a verified executive, and FABRICATED SILICON — under one referee
> (the Lean kernel)..."

```
MEASURED ON THE SUBMITTED DIE (this seat, 08/10, at the artifact):
  352 of 902 flops (39.0%) kernel-emitted · 550 (61.0%) HAND RTL
  PROVED      the combinational MAC core — all 96 outputs, all inputs, SAT
  NOT PROVED  clocked cell ∀st0 · sequencer · pin wrapper · fabric · core
⇒ THE FABRICATED SILICON IS NOT UNDER THE LEAN KERNEL.
```
⛔ **F3/F4 exactly — the model-vs-artifact gap — on the highest-amplification
surface this fleet has drafted.** *This is the same claim kept out of the TT
datasheet, `info.yaml`, the priced-half account and the public repo all week.*

🔑 ***AND IT EXPOSES THIS SEAT'S OWN COVERAGE LIMIT: nine banned phrases held at
the submitted bytes, and "under one referee" says the same thing in words the
phrase list does not contain.*** *A phrase fence catches phrasings it was built
from. `claim_fence.py` returns GREEN on this sentence — verified — which is why
M4 of every criterion this seat writes requires the tool to disclose its frame.*

**REPAIR SUPPLIED (one clause, and the honest version reads stronger):**
> "...and silicon whose arithmetic core is kernel-proved and fabricated — under
> one referee for everything the kernel touched, with the hand-written
> remainder named."

✅ **CLOSED 2026-08-11 08:52 at `4d1c8c2`, verified at the bytes not on a status
line.** *The §1 thesis now reads "silicon whose arithmetic core is kernel-proved
and fabricated — under one referee for everything the kernel touched, with the
hand-written remainder named (the die: 352 of 902 flops kernel-emitted, 39.0%;
the rest hand RTL)". Measured at `origin/master`: the false form "under one
referee (the Lean kernel)" is at ZERO occurrences; the qualified clause, the
partition and the remainder phrase each present.*

> ⛔⛔ **CORRECTION, 2026-08-12 18:2x — THE NUMBER IN THE REPAIR ABOVE MIXED TWO
> SCOPES, AND THE REPAIR WAS MINE.** *Silicon's structural join (`8858017`,
> `docs/silicon-figure4-structural-join-0812.md:59-62`) measured that **352 is an
> RTL-SIDE count** (4 shells x 64 + 3 sers x 32) while **the die's kernel-emitted
> flops are 288.** The difference of 64 is exactly one MAC cell — `cell3` — which
> is **not on the die at all**: its enables and inputs are tied to `1'b0` at
> RTL:265 and synthesis constant-propagated the island away.*
> ```
> WRITTEN HERE   "the die: 352 of 902 flops kernel-emitted, 39.0%"
> DIE TRUTH       288 / 902  = 31.9%   (+ 614 agent-RTL)
> RTL TRUTH       352 / 966  = 36.4%
> ⇒ the old figure put an RTL NUMERATOR over a DIE DENOMINATOR.
> ```
> ✅ *Corrected in the live draft at `a3786ad` (maestro, 2026-08-12 17:59), with
> both scopes stated and the `cell3` disposition carried.* **The lines above are
> left UNCHANGED on purpose: they are the dated record of what this seat measured
> and what the 08-11 repair actually said. Changing them would falsify the
> record; this note stops the number travelling.**
> 🔑 ***THE LESSON IS MINE AND IT IS NOT ABOUT ARITHMETIC: I supplied a REPAIR
> containing a figure, and a repair invites gratitude rather than a check*** —
> [[a-repair-invites-gratitude]]. **Three seats hardened that block in four
> minutes and nobody re-derived the ratio, because it arrived as the fix.**
> *And the scope error is [[adjacent-object-principle]] exactly: a true reading of
> the RTL, labelled with the die.*
⚠️ **IT TOOK A RE-RAISE AT 08:50 — the first refutation crossed the fold window
at 03:45 and sat five hours while three other seats' counsel landed.** *Not a
decline; a crossing. **The lesson is mine: I recorded it as OPEN and did not
re-check it until the morning was arriving.** An item routed to another seat is
not progressing because you filed it.*

📌 **Remaining, and NOT this seat's to close: Two adjacent
claims FLAGGED, NOT JUDGED, because they are not this seat's to measure: "a
verified compiler" and "a verified executive" — their owners should state what
those words cover before the sentence travels.** *"first formalizations" is an
M3 priority claim under `EVIDENCE-maths-paper-fence-0811.md`: never machine-
checkable, needs a stated search.*



### ✅ CLOSED — the audit-cap headroom figure (raised 19:31, closed 2026-08-11 00:1x)

Silicon's MEAS on `1a92292` posted `Program.lean` peak 10,387 MB as **86.6% of
cap, headroom 1,613 MB**, and recommended the helm consider raising the cap
before M2–M5. Measured against the tracked artifact:

```
tools/saltbuild.sh:29   CAP=24000   ← tracked, `a522403`, 08-09 12:54
                        "raised from 12000 at the Captain 8/9 ruling"

peak 10,387 MB   against 12000 →  86.6% used · headroom  1,613 MB
                 against 24000 →  43.3% used · headroom 13,613 MB
```
⭐ **Not a `meas_build` defect** — `meas_build.sh:75` reads `CAP=` from saltbuild
dynamically and exits 2 rather than guessing. The tool holds the current number;
the prose holds the old one. Same file carries a comment at `:66-67` explaining
the raise to 24000 and one at `:151` still reading "default 12000 MB".

✅ **CLOSED BY SILICON'S OWN BANK, in their words, before their relight:**
*"Cap is 24,000 MB (LIVE — I quoted 12,000 from a stale memory line and
manufactured a false alarm; evidence corrected it in 90 seconds)."*
⇒ **The run used the DEFAULT. Real headroom 13,613 MB, not 1,613.** The register
carries the Captain's 08-09 ruling (`QUEUE.md:96-101`): audit form is `-M 24000`
by default and the `--cap 24000` dance for known heavies is retired.

⚠️ **AND THIS ENTRY WAS STALE FOR FOUR HOURS.** *It was recorded "OPEN" at 19:35
and answered shortly after; this seat carried it as a live item in its own bank
and would have handed a successor a CLOSED question marked OPEN — the exact
shape its own laws warn gets obeyed. Found only by checking whether the item
survived silicon's relight.* ***An item is not open because you last saw it
open.***

⚠️ **Why it is recorded rather than left on the bus: M2–M5 sizing is about to be
planned on this number, and the failure direction is a FALSE ALARM — it costs
attention and may prompt a raise that already happened on 8/9.**



### batcher_seq — CLEARED on cells+flops, NOT on area (2026-08-10 18:50)

The account (`docs/ndf-account-priced-half.md:85`) rests the Captain's
tile-purchase gate on `batcher_seq 720 cells · 96 flops · 6,065.82 um2 EXACT`.
Read at the artifact, not inherited from the account:

```
CLAIMED   720 cells · 96 flops
COUNTED   720 cells · 96 flops · conb 0     ⇒ both MATCH; conb row of V7 clear
NOT CHECKED  6,065.82 um2 — needs a synthesis run this seat did not take.
             The area figure remains silicon's and is UNCORROBORATED HERE.
```
⚠️ **The artifact is UNTRACKED** (not gitignored — `check-ignore` exits 1; 55 of
56 files in `SaltWorks/Silicon/RTL/` are committed and this is the sole
exception). Compiler named the failure mode this seat missed: the number rests
on bytes that any emitter edit would silently replace. Binding pair, computed
2026-08-10 18:50 while the emitter was still at the sha the account cites:

```
sha256   ddc8b8cd6449283917307af356c04c91fbde78a843247af4e48c9c643f4d6687
bytes    57261
emitter  docs/hdl-tools/emit_seq.sh @ 8be6d48   (unmoved since 10:57)
command  #eval IO.print (emitSeqMux "1" "2" "batcher_seq" batcherNetC)
```
⇒ **Re-verify by regenerating and comparing the sha256.** If it differs, the
emitter moved and the account's numbers describe a file that no longer exists —
that is the check, and it is one command.

