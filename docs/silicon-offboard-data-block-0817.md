# DESIGN BLOCK — OFFBOARD DATA, ORDERED IN-WINDOW

**silicon, 2026-08-17, authored under the 11:27:21 commission. Design-block-first; a
refuter pass gates the wave. NOTHING IS BUILT AGAINST THIS.**

> The Captain: *"We should do offboard data this window… as a 'complete' product. I
> know silicon will have to scramble for it."* The scramble is ordered; the no-crunch
> doctrine bends at his word, not silently. 21 days to Sept-7.

---

## §1 · THE BLOCKER, FIRST, BECAUSE IT PRICES EVERYTHING ELSE: THERE ARE NO PINS LEFT

TinyTapeout gives 24 usable pins. **All 24 are allocated today.**

```
ui_in[7:0]    → slicea16bma .instr_byte        8 pins   FULLY USED
uo_out[7:0]   → slicea16bma .addr_byte         8 pins   FULLY USED
uio_oe = 8'b1011_0011  ⇒ OUT={7,5,4,1,0}  IN={6,3,2}
  uio_out[7] valid      uio_out[5] edge_out_vld   uio_out[4] edge_out_dat
  uio_out[1:0] phase_o                            ⇒ all 5 outputs used
  uio_in[6]  sof        uio_in[3] edge_in_vld     uio_in[2] edge_in_dat
                                                  ⇒ all 3 inputs used
```

⛔ **A SERIALIZED OFFBOARD INTERFACE NEEDS AT MINIMUM: data-in, data-out, a strobe,
and an acknowledgement. There is nowhere to put them.** The `_unused` line at
`tt_um_saltworks_ndf.v:440` names `uio_in[7], uio_in[5:4], uio_in[1:0]` — but every
one of those is configured as an **OUTPUT** by `uio_oe`, so they are not free inputs;
they are outputs whose input side is correctly ignored. **Reading that line as "five
spare pins" is the trap this section exists to prevent.**

⇒ **THREE WAYS OUT, AND THE CHOICE IS NOT MINE:**
```
(a) RE-FREEZE THE PIN MAP        D6 froze it; offboard was not in scope then.
                                 Cheapest in silicon, costs whatever depends on D6.
(b) TIME-MULTIPLEX AN EXISTING   share the fabric's edge pins between edge traffic
    FUNCTION                     and offboard traffic under `sof` framing. No new
                                 pins, but it couples two protocols that currently
                                 cannot interfere, and that coupling is a proof
                                 obligation nobody has today.
(c) DROP A FUNCTION              the `slicea16bma core` on ui_in/uo_out is 16 pins
                                 and is described in its own comment as "as-is (R4:
                                 demonstrates on its own bus)".
```
⚠️ **I am not choosing among these. (a) and (c) are scope rulings; (b) is the only one
that is purely engineering, and it is the one that manufactures a new proof
obligation.**

## §2 · (i) THE ADDRESS-MAP SPLIT — IT MOVES A THEOREM, NOT JUST A WIRE

Today (`dmem_addr8.v:88-92`):

```verilog
assign out_of_range = |byte_addr[31:5];
assign trap         = req & (misaligned | out_of_range);
assign we_out       = we_in & req & ~misaligned & ~out_of_range;
```

`out_of_range` is *everything above 32 bytes*, and it traps. Offboard needs that
region **split**: some of it routes off-chip, the rest still traps.

⛔ **WHAT THAT TOUCHES, AND IT IS NOT THE RTL:**
```
DmemAddr8Suppress.dmemAddr8_we_out_excludes_trap   proved AT THE EMITTED GATES over
                                                   the CURRENT net list. A new arm
                                                   RE-SYNTHESISES the module ⇒ the
                                                   `rfl` shape lemmas (net78/net72)
                                                   FAIL LOUDLY, by design.
ISA.addrClass / addrClass_ok_lt                    the kernel's own address classes
F4 door 1 (DmemKernelBridge)                       quotes we_out's suppression
```
✅ **THE `rfl` TRIPWIRE FIRING IS THE GOOD CASE** — `DmemAddr8Suppress` says so in its
own header: *"if the netlist is ever re-synthesised into a different shape, these
lemmas fail loudly instead of proving something else."* **Budget for re-deriving them;
do not budget for them surviving.**

## §3 · (iii) THE STALL CONTRACT IS A KERNEL CHANGE WEARING AN RTL COSTUME

`core32` is single-cycle: `dmem8`'s read is combinational and every instruction
retires in one clock. **An offboard access cannot be.**

```
ISA.step / stepT / run    one instruction, one step, no notion of a stalled cycle
⇒ a fixed-latency or handshaked memory makes the kernel model MULTI-CYCLE, which
  is a change to the verified core, exactly as the commission says — not a wrapper
```
⚠️ **CROSS-LANE, AND THE COMMISSION IS EXPLICIT THAT I MUST NOT ASSUME: compiler's
bridge is touched.** `DmemKernelBridge` relates a single decoded word to a single
gate-level strobe. Under stalls, "the cycle the strobe rises" and "the instruction
that decoded it" stop being the same clock, and every seam theorem quantified over
`ins` needs to say *which cycle*. **I will not design that boundary alone and I have
not started it.**

## §4 · (iv) THE CLAIM LADDER — WHAT IS PROVEN AT TAPE-OUT VERSUS AFTER

Statement-tier, for the Captain at the freeze. **The point of this ladder is that the
lower rungs are honest, not that the top rung is tall.**

```
RUNG 4  PROVEN AT THE GATES, TOTAL          — where dmem_addr8 lives today
RUNG 3  PROVEN AT THE GATES, RESTRICTED     — dmem8's datum: rst_n ≡ 1, silent about
                                              the deassertion seam
RUNG 2  PROVED IN RTL, ASSUMED IN LEAN      — DriveMap TODAY: true of the hardware,
                                              still a hypothesis in the certificate
RUNG 1  SIMULATED, NOT PROVED               — tb_memplane8's round trip; the offboard
                                              PROTOCOL will land here at the freeze
RUNG 0  MEASURED ONLY                       — area, DRC/LVS, timing
```
⭐ **MY HONEST FORECAST FOR SEPT-7, AND I WOULD RATHER BE HELD TO A LOW ONE:** *the
address-map split can reach RUNG 4 (it is combinational and the existing tautology
route applies). **The serialized protocol will be at RUNG 1** — a protocol is a
temporal object and this fleet has no temporal proof machinery in silicon. **The
stall contract will be at RUNG 1 or 2** and depends entirely on the cross-lane
boundary in §3.*
⛔ ***"COMPLETE PRODUCT" MUST NOT BE READ AS "COMPLETE PROOF". If the freeze needs one
sentence from me, it is: the part will do offboard data; the claim that it does so
correctly will be simulation-backed, not kernel-backed, unless §3 lands.***

## §5 · THE COLLISION I WAS ASKED TO SURFACE

**This campaign and the `DriveMap` discharge wave share my pen — and worse, they share
their SUBJECT.**

```
the discharge wave    proves things about core32's strobes and dmem_addr8's ports
this campaign         CHANGES core32 (stall contract) and dmem_addr8 (address map)
```
⇒ ***RUNNING THE DISCHARGE FIRST WOULD PROVE PROPERTIES OF RTL THAT THIS CAMPAIGN IS
ABOUT TO INVALIDATE — and the 43-cell-model investment (§9 of the discharge block)
would be spent against a moving target.***

📌 **RECOMMENDATION, AS A RECOMMENDATION: sequence the discharge AFTER the offboard
RTL freezes.** *The discharge's cost is dominated by cell-model coverage, which is
insensitive to which core32 it runs on — so deferring costs almost nothing, while
running it early risks paying twice.* **The helm asked for collisions at seams; this
is the seam.**

---

# REVISION 1 — THE PIN FORK WAS CLOSED UNPICKED. §1 IS WITHDRAWN.

**Captain's ruling 11:39:29, option (d) — one I did not enumerate. §1 above is left
standing because dated records are not rewritten; it is WRONG and this supersedes it.**

## §6 · WHAT I MISREAD, AND IT IS A READING ERROR NOT AN ARITHMETIC ONE

```
§1 SAID     all 24 pins are allocated, so there is nowhere to put an offboard link;
            the ways out are re-freeze / multiplex / drop a function
THE TRUTH   THOSE PINS ALREADY ARE A BUS. uo[7:0] is addr_byte in FOUR PHASES,
            ui[7:0] is the returned word assembling low-byte-first, uio[1:0] is the
            phase strobe SO THE HOST CAN ALIGN. slicea16bma.v:10-17 says so in its
            own header.
```
🔑 ***I READ THE PIN ASSIGNMENTS AND NEVER THE PROTOCOL THEY CARRY. "ui_in → .instr_byte"
told me the pins were CONSUMED; it should have told me there was a MEMORY BUS already
on them, with a host on the other end and a phase strobe published for it.*** A count
of allocated pins was the wrong instrument for a question about protocol capacity.

✅ **THE RULED ARCHITECTURE — pin assignments UNTOUCHED, only D6's semantic text
amends:** *the bus protocol EXTENDS with transaction types (fetch / load / store);
address phases on `uo` exactly as today; read data returns on `ui`; **store data is
multiplexed out on `uo` after the address phases**. The Captain's cost acceptance,
verbatim: **"we have to multiplex them, it is slow, but fine"**.*

## §7 · (iii) REVISED — FETCH-vs-DATA ARBITRATION AND WORST-CASE CPI

**`uo` is now contended: it carries fetch addresses, load/store addresses, AND store
data. A load or store STEALS BUS CYCLES FROM FETCH.** That is the arbitration
question, and it is the core32 stall contract's real content.

**ARBITRATION, stated as a rule rather than described:**
> ***FETCH YIELDS TO DATA. A memory instruction that has committed at phase 3 owns
> `uo` for its entire transaction; the next fetch begins only when the data
> transaction retires.*** *The alternative — fetch priority — would require the data
> transaction to be interruptible and re-issued, which needs a resumable memory
> protocol nobody is buying at this window.*

**PHASE ACCOUNTING. One phase = one clock.**
```
                    uo carries              ui carries          phases
FETCH               PC[7:0]…PC[31:24]       instr bytes  ⇐      4
LOAD  address       EA[7:0]…EA[31:24]       read data    ⇐      4
STORE address       EA[7:0]…EA[31:24]       (idle)              4
STORE data          wdata[7:0]…[31:24]      (idle)              4
```
⚠️ **THE LOAD ROW ASSUMES READ DATA RETURNS ON `ui` DURING THE ADDRESS PHASES, exactly
as the instruction does during a fetch. That is an assumption about THE HOST, not
about this design** — and `slicea16bma.v:27` already flags the same open question
(*"whether the instruction for phase 0 arrives at phase 3 or a loop later … is a
DESIGN question this artifact does not settle"*). **If the host cannot turn a read
around in-phase, every LOAD row below gains 4.**

```
WORST-CASE CPI, under FETCH-YIELDS-TO-DATA and in-phase read turnaround:
  non-memory instruction     4          fetch only
  LW                         4 + 4  =  8
  SW                         4 + 4 + 4 = 12      ← THE WORST CASE
if the host CANNOT turn a read around in-phase:
  LW                         4 + 8  = 12
  SW                        12 (unchanged — a store never waits on ui)
```
⇒ ***WORST-CASE CPI IS 12, AND IT IS A STORE. A store costs 3× a non-memory
instruction because `uo` must carry an address AND a datum it cannot overlap.***

📌 **WHAT THIS DOES NOT SETTLE, kept explicit:** *no wait-state / not-ready signalling
is specified here — the phase strobe tells the host WHERE the bus is, not whether the
core is ready. A host slower than the phase counter needs a stall input, and there is
no pin for one under (d). **That is the next hard question and I am naming it now
rather than discovering it in RTL.***

## §8 · UNCHANGED BY THIS REVISION

- **§2** (the address-map split moves a theorem) stands.
- **§5** (the collision: the discharge wave proves about RTL this campaign changes)
  stands, and the ruling strengthens it — `core32` now gains a stall contract too.
- **§4's claim sentence is NOT RATIFIED.** The helm was explicit. It remains my
  proposal and must not be quoted as ruled.
- The fabric's stubbed CPU-client port and spare stay untouched; **this block does not
  argue for them.**

---

# REVISION 2 — THE CLAIM LADDER BECOMES A PLAN-TO-PROVE. AIM RULED HIGH.

**Captain, 11:42:48: *"first layout can be simulation, but we aim to finish the proof
before Sept 7, and will revise if needed. That's first priority above everything
else."* §4's low forecast is SUPERSEDED AS A TARGET — not as a statement of what is
proven today.**

## §9 · AIM AND CLAIM ARE DIFFERENT OBJECTS, AND THE RULING KEEPS THEM APART

```
THE AIM    the complete proof, temporal and protocol rungs included, before 09-07
THE CLAIM  at any moment, exactly what IS proven — write-time hygiene UNCHANGED
```
🔑 ***These do not conflict and it matters that they cannot. An aim is a commitment
about EFFORT; a claim is a report about STATE. My §4 forecast was a claim and stays
true as one; it was never licence to stop reaching.*** **And the ruling names the
failure mode explicitly: if the aim breaks, revision is an HONEST, CAPTAIN-VISIBLE
EVENT, never a silent downgrade.** *A silent downgrade is the only way this goes
wrong.*

## §10 · THE SCHEDULING INSIGHT THAT CHANGES THE ORDER OF WORK

**§5 said: defer the discharge wave until the offboard RTL freezes, because its
subject is moving. That stands for the THEOREMS. It is WRONG for the CELL MODELS.**

```
the 43 missing cell models are a property of the sky130 LIBRARY and the cell mix,
NOT of which core32 they are used on. They are RTL-INDEPENDENT.
⇒ START THEM NOW, IN PARALLEL WITH RTL THAT IS STILL MOVING.
```
⭐ ***That is the one piece of the critical path that does not wait for anything, and
under a 21-day aim it is the difference between a queue and a pipeline.*** *It is also
the largest single mechanical cost in the plan (a ~54% enlargement of `EXPAND`, each
entry owing a Liberty proof), so it is exactly the work that must not sit behind a
freeze.*

## §11 · PLAN-TO-PROVE, DATED. 21 DAYS.

```
DATE     RUNG / DELIVERABLE                                  GATE
08-17→19 TEMPORAL CO-DESIGN BLOCK with compiler:             refuter pass
         which-cycle binding · stall/arbitration contract
         · bus-protocol FSM. COMMISSIONED BUILD, co-design,
         and I do not own the kernel half.
08-17→27 CELL-MODEL COVERAGE, 43 entries + Liberty proofs.   census with its
         RUNS IN PARALLEL — RTL-independent (§10).           three-sided control
08-20→23 ADDRESS-MAP SPLIT: route-or-trap in dmem_addr8,     the rfl tripwire
         re-derive the suppression lemmas at the gates.      MUST fire and be
         Target: PROVEN AT THE GATES, TOTAL.                 re-derived, not
                                                             worked around
08-23→27 BUS-PROTOCOL FSM + core32 STALL CONTRACT in RTL.    tb + arbitration
         Simulation-gated.                                   sim; CPI measured
                                                             against §7's 12
08-27    ⇒ FIRST LAYOUT. Simulation gates it, by ruling.     DRC / LVS / antenna
08-28→09-03 TEMPORAL PROOFS: protocol FSM and which-cycle    refuter pass
         binding land against the FROZEN RTL.
09-03→06 DriveMap DISCHARGE against frozen RTL, on the       the six criteria,
         cell models finished 08-27.                         D4′ mutant included
09-07    WINDOW.
```
⚠️ **THE THREE PLACES THIS PLAN BREAKS, NAMED NOW SO A BREAK IS RECOGNISED RATHER
THAN ABSORBED:**
```
1  the temporal co-design (08-17→19) is CROSS-LANE. If the kernel half is not
   agreed by 08-19, everything after 08-28 slips and the discharge is the first
   casualty. THIS IS THE CRITICAL PATH, not the RTL.
2  the address-map split re-synthesises dmem_addr8, so the suppression lemmas
   must be RE-DERIVED. If re-derivation is harder than expected, 08-23 slips into
   the FSM window and the first layout date moves.
3  the 43 cell models are mechanical but each owes a Liberty proof. If the rate is
   worse than ~4/day the 08-27 completion fails and the 09-03 discharge cannot
   start.
```
📌 **EACH OF THOSE IS A CAPTAIN-VISIBLE REVISION EVENT IF IT FIRES. I will report a
slip on the day it becomes likely, not on the day it becomes certain** — *a schedule
whose slips arrive only at the deadline is a schedule that lied for three weeks.*

## §12 · WHAT I STILL DO NOT OWN

- **The kernel half of the temporal machinery.** Co-design means compiler and I agree
  the which-cycle binding; it does not mean I write `ISA.step`'s successor alone.
- **The outward push.** Still the Captain's.
- **§4's claim SENTENCE.** Superseded as a target by this revision; the *hygiene* rule
  it served is untouched and I will keep quoting only what is proven at the time.

---

# THE TEMPORAL OWNERSHIP TABLE, EMBEDDED BYTE-IDENTICAL

**Canonical: `docs/temporal-ownership-TABLE-0817.md`, compiler's pen. RE-EMBEDDED 08/17 19:0x at `f3957c3` — the 7f38ad8 copy went
STALE and my 12:24 EXIT=0 receipt kept asserting an equality that had stopped holding.
Embedded here under the helm's 12:02 order; verified by `docs/ledger-tools/table_identical.sh`,
which is compiler's instrument and not mine — a copy checked by its own author's tool is not checked.**

> ⛔ **I DO NOT EDIT THIS REGION.** It is a COPY. If it and the canonical ever disagree, the
> canonical wins and this file is wrong by construction. The cmp receipt below is the only
> thing that makes that claim checkable.

<!-- TEMPORAL-OWNERSHIP-TABLE v1 · BEGIN -->
# TEMPORAL OBLIGATION OWNERSHIP — ONE ARTIFACT, ONE PEN, cmp-VERIFIED

**Ordered by the helm 2026-08-17 12:02; custody arbitrated 12:06 after a collision.
Compiler holds the pen on this file; silicon's block embeds its bytes verbatim.**

> ⚠️ **CUSTODY, AND WHY IT IS WRITTEN AT THE TOP.** At 12:04 this file was created by
> compiler and destroyed within the minute: silicon wrote the same name in **lowercase**,
> macOS is case-insensitive/case-preserving, both names resolve to ONE INODE, and the
> second write replaced the first. The surviving name still carries compiler's uppercase
> `TABLE` — the proof of whose file it was. **It was untracked, so git held nothing.**
> ⇒ **ONE PEN (compiler) · COMMITTED ON CREATION · never a lowercase twin.**
> *Reproduced on this filesystem before being written down, not taken on report.*

---

## THE TABLE

| # | obligation | OWNER | CROSS-VERIFIER | ARTIFACT IT LANDS IN | CONTROL THAT WOULD CATCH ITS ABSENCE |
|---|---|---|---|---|---|
| T1 | stall / arbitration **contract** — which cycles are NOT-cycles | **silicon** | compiler | silicon's offboard block | a NOT-cycle the contract does not name, and no gate refuses the trace |
| T2 | which-cycle **statement shape** + the trace predicate | **compiler** | silicon | compiler's block → `Certs/` | a stalling trace under which the hypothesis is **still satisfiable** ⇒ vacuous, green, silent |
| T3 | bus-protocol **FSM proof** | **silicon** | compiler | silicon's offboard block | a trace where the FSM deadlocks mid-transaction and every current check stays green |
| T4 | arbitration **fairness**, restated as **BOUNDED WAIT** | **silicon** | compiler | silicon's offboard block | a fetch waiting longer than the stated phase bound, with no gate that counts |
| T5 | **store-path timing** — `dmem_we` rising vs the beat leaving the pins | **silicon** | compiler | silicon's block + the seam statement | `we` on beat *n*, data on beat *n+k*, and the seam theorem still elaborates |
| T6 | **`ISA.step` / `runWords` extension** | **compiler** | silicon | `Stack/Program.lean` | the extended object and `runWords` agreeing on **every** trace — no distinguishing witness means the extension is cosmetic and no stall entered |
| T7 | the **13 consumers'** re-proof | **compiler** | silicon | `Stack/Program.lean` | any consumer whose statement changed while its proof did not |
| T8 | the **K/N unit re-cut** (UK1) | ⛔ **the Captain, via the helm** | both | routed, not designed here | a guard passing at a fraction of the intended instructions — green and wrong |

## WHY THE THREE ORPHANS LAND ON SILICON — silicon's principle, adopted

**Each is a property of an artifact silicon writes. Ownership follows the ARTIFACT, not
the difficulty.** T3's FSM is RTL; T4's "fetch yields to data" is silicon's own arbitration
rule; T5's ordering is RTL sequencing. *An owner who does not hold the object cannot fix a
failed proof.*

## ⭐ T4 CHANGES SHAPE ON INSPECTION — silicon's finding, and it is the best thing here

*"Fairness" invites a **liveness** proof — "fetch is not starved forever" — and this fleet
has no liveness machinery in silicon.* **But under `FETCH YIELDS TO DATA` a data
transaction is BOUNDED: at most 8 phases.** ⇒ ***Fairness reduces to BOUNDED WAIT, a
SAFETY property provable by the same accounting that produced worst-case CPI. An
obligation nobody could discharge became an arithmetic one.***

⚠️ *And the structural reason starvation cannot arise: a data transaction exists only
because an instruction was already fetched. **There is no source of data traffic
independent of fetch.***

## ⛔ T6's CONTROL WAS A FALSE NEGATIVE, AND THIS TABLE FROZE IT INTO THREE FILES

*Repaired 2026-08-17 14:0x. The original read: "`runWords_succ` still closing by `rfl`
afterwards — if it does, no stall entered."* **`runWords_succ` is `rfl` BY THE SHAPE OF THE
RECURSION** *(`Program.lean:1413-1414`)*; *it survives any word-stream encoding, so it
would have reported "no stall entered" **while a stall had entered**.*

🔑 ***AND THE TELL IS STRUCTURAL, VISIBLE BY READING THE COLUMN DOWN: every other control
names a FAILURE STATE — something green-and-wrong that can occur while the obligation is
undischarged. T6 alone named a PASS CONDITION.*** *A control that describes success cannot
discriminate; it can only agree with you.*

⚠️ **THE INTERFACE ARTIFACT'S FIRST REAL LESSON, AND IT CUTS BOTH WAYS.** *Byte-identity
did exactly what it was built to do and **propagated a defective row to three files at
once**. A shared interface makes agreement cheap and makes a defect in the interface
maximally expensive. **The cmp check proves the copies match; it cannot prove the original
is right** — and nothing in the mechanism ever will.

## THE COLUMN THAT DOES THE WORK IS THE LAST ONE

*Owner and cross-verifier are assignments; **the control is what makes an assignment
checkable.** A row whose control says "review it carefully" is an unowned row with a name
attached.* ⇒ **Every control above names a state in which an artifact would be GREEN while
the obligation went undischarged** — because that is this seam's measured failure mode,
three times today, and not a hypothetical.

## WHAT CROSS-VERIFIER MEANS — a role, not a courtesy

```
the OWNER     writes the artifact, states the obligation, lands the proof
the VERIFIER  must be able to say NO: re-derive from their OWN instruments and
              REFUSE if it does not reproduce
```
⛔ **A cross-verifier who only reads is decoration.** *Each verifier owes at least one
demonstration that their check CAN reject.*

## STANDING CONDITIONS

- **No option is chosen and no wave runs** until this table is in both blocks and both
  revised blocks pass their refuter rounds. *(helm, 12:02)*
- **T8 is routed, not absorbed.** Neither seat designs the K/N re-cut without his word.
- **An obligation discovered later gets an owner BEFORE it gets work.** The orphans existed
  because the boundary was described before it was divided.
- **This file is committed on every edit.** An untracked artifact in a shared tree has no
  custody and no recovery — which is not a lesson from a manual, it is what happened here.
<!-- TEMPORAL-OWNERSHIP-TABLE v1 · END -->

---

# REVISION 3 — TWO RUNGS DATED, AND THE AIM HAS TWO UNSATISFIED HYPOTHESES, NOT ONE

**Helm 15:15:03: two dated rungs are owed into the plan — the C4Spec witness for the
composed core, and the flagship restatement. Dated below. Also: the held core32 datum
question is resolved — the discharge block's round 2 owns it, sequenced after the
offboard RTL freeze. KEEP HOLDING. Nothing is lost.**

## §13 · THE STRUCTURAL FINDING BEHIND RUNG (1), VERIFIED BEFORE DATING IT

I checked the premise rather than taking it on report:

```
C4Spec (HDL/C4.lean:76) is a Prop over a Circ.
Every occurrence in the tree takes it as a HYPOTHESIS:
   C4.lean:84                spec : C4Spec c          (a field, assumed)
   C4.lean:115               (h : C4Spec c) → …       (consumes it)
   Stack/Program.lean:2306   cycleRealisesStep_of_C4Spec (h : C4Spec …)
NOTHING INHABITS IT FOR A REAL CIRCUIT.
```

⭐ **SO THE AIM NOW HAS TWO UNSATISFIED HYPOTHESES, AND THEY ARE THE SAME SHAPE:**
```
DriveMap   the gate↔decoder seam    assumed in DmemKernelBridge, satisfied nowhere
C4Spec     the core-conformance seam assumed in C4/Program,      satisfied nowhere
```
⇒ ***Both are "true of the hardware, assumed in the proof" — the exact state §8 named
for DriveMap, arriving a second time at a different seam. "Complete proof" is not true
while either stands, and until today the fleet was tracking one of them.***

## §14 · THE TWO RUNGS, DATED

⚖️⚖️ **LIVE TABLE — COUNCIL RULING z, 2026-08-31 (the 08-31 minute: "accept"; sitting-close
routing 09:30:39), ENTERED BY COMPILER THE SAME HOUR. The revised dates are DERIVED from the
branch receipts — merged to master at `235834e`, `saltbuild EXIT=0`, 4648 audit ticks — not
asserted at the sitting; the derivation is printed under the table. Everything below this
block in this section is HISTORY.**
```
DATE         RUNG                                        OWNER · NOTE
08-31→09-02  R9a · THE CORE REPAIR, leg 1 — place+wire   COMPILER, on the leg-1 release word
             the trap gate (the write enable suppressed  (the build was OFFERED 08-30 and is
             on isLW ∧ trapping) + the differential in   still unreleased). The differential is
             the SAME act: the trapping-LW refutation    MANDATORY: regDatapathOK_is_false_on_
             goes PROVED → UNPROVABLE at its own         trapping_LW must DIE at insT, and
             witness, and the LANDED insL witness MUST   regDatapathOK_is_false_at_the_LANDED_
             STILL PROVE — leg 2 survives any trap       witness must STILL PROVE — the 08-29
             repair, which is the one-bit lesson         one-cell retirement, mechanized so it
             mechanized                                  cannot repeat.
09-04→09-06  R10 · FLAGSHIP RESTATEMENT — bound stated   JOINT per the ownership table; T8 is
             in the units the machine honors; no bare    routed to the Captain. Dates UNCHANGED —
             literal surviving the retired cycle=step    carried up verbatim. ⛔ NOW LOAD-BEARING
             identity — AND the LW row's honest          FOR R9b: the runbook's own law makes
             disposition rides with it                   removing a direction FALSE in the new
                                                         setting REQUIRED HONESTY, and LW is now
                                                         kernel-proved to be such a direction.
09-06        R9b · THE C4Spec WITNESS proper, against    COMPILER; silicon cross-verifies, dated
             the ratified sentence — inhabit it for      WITH this rung, never before it (duty
             the real circuit, not merely consume it     unchanged from the 08/17 table).
09-07        THE WINDOW. Sept-7 HOLDS WITH ~1 DAY OF MARGIN, on the two contingencies below.
```

#### THE DERIVATION — ruling z's own words: *"the revised date derives from compiler's receipts, not asserted at the sitting"*
**KERNEL GROUND** (`SaltWorks/HDL/LwTrapRefuted.lean`, master `235834e`):
`regDatapathOK_is_false_on_trapping_LW` + `not_c4Spec_core_on_trapping_LW` (leg 1, expressible
in 1056) and `regDatapathOK_is_false_at_the_LANDED_witness` (leg 2, `insL` at bit 3 — survives
any trap repair). ⇒ **The 08-29 row was not LATE, it was UNMEETABLE: it dated a proof of a
proposition the kernel now refutes.** A date revision alone cannot cure falseness, so the rung
changed shape — that is the split into R9a/R9b.
⇒ **The 08-29 order argument died with it.** R9-before-R10 rested on `stallArm_reduces` (a
witness against today's core IS the restated predicate's base case) — sound only while today's
predicate is TRUE of the core. Refuted, there is no witness to carry forward, and the LW row's
truth arrives only with R10's disposition. **R9b therefore dates WITH R10's close — the swap
§14's earlier text weighed and rejected is now forced by the kernel, not chosen by a seat.**
**MEASURED COMPARABLES** (git, this repo):
```
leg-① repair arc   cdd63ab 08-28 14:00 → 79c6f04 08-29 00:28 — sketch, conservative proof,
                   place, wire: ONE WORKING DAY. Nearest analog to R9a's gate; R9a gets that
                   day plus one for the differential and drift.
four value rows    one session, 08-29 12:32 → 18:33 (≈1.5 h/row) — prices R9b's assembly.
the row-v reading  pre-registration → discharge, 11:03 → 11:29 (26 min) — prices the witness
                   run itself.
leg 2 as REAL LW   needs the ratified 1056→1316 widening AND a memory-data input the core
                   does not have (silicon's synthesis, on the record 08-30): 3–5 days elapsed,
                   mostly not this seat's — INFERRED 08/29 and still unlanded. NOT inside this
                   window; it is the road PAST it.
```
**TWO NAMED CONTINGENCIES — said now, never silently (the 08/26 rule):**
1. R9a starts on the leg-1 release word. Each day of silence past 08-31 moves R9a and R9b
   day-for-day.
2. R9b holds only if R10 holds 09-04→09-06 and disposes the LW row. If R10 slips, R9b slips
   past the window, and the Captain hears it as a revision with the new dates attached.

### ⬇️ THE 08-29 TABLE, RETAINED VERBATIM AS HISTORY — SUPERSEDED BY RULING z ABOVE, NEVER DELETED
*Its dates were entered under the helm's 08-29 ruling; ruling v (08-30) pre-ruled that a refuting
witness returns as a date revision, the witness ran 08-30 and REFUTED, and ruling z (08-31)
accepted the revision. The text below is unedited except its first line, which carries a
"(was: LIVE TABLE)" marker so a hurried reader cannot take the old dates as standing.*

⚖️⚖️ **HISTORY (was: LIVE TABLE) — HELM RULING 2026-08-29 14:3x, ENTERED BY COMPILER THE SAME HOUR. THIS IS THE
BLOCK `QUEUE.md` CITES; everything below it in this section is HISTORY.**
```
DATE         RUNG                                        OWNER · NOTE
08-29→09-03  R9 · C4Spec WITNESS for the composed core   COMPILER (ownership moved 08/17 15:58,
             — inhabit C4Spec for the real circuit,      §17). Silicon's R9 duty is CROSS-
             not merely consume it                       VERIFICATION only, dated WITH this rung,
                                                         never before it.
09-04→09-06  R10 · FLAGSHIP RESTATEMENT — bound stated   JOINT per the ownership table; T8 is
             in the units the machine honors; no bare    routed to the Captain, so silicon dates
             literal surviving the retired cycle=step    only its own half. UNCHANGED by this
             identity                                    ruling — carried up verbatim.
09-07        THE WINDOW. Sept-7 STANDS.
```
⛔ **IF R9 SLIPS PAST 09-03, THE CAPTAIN HEARS IT AS A REVISION WITH THE NEW DATES ATTACHED —
NEVER SILENTLY** (08/26 ruling, restated in the 08-29 order). *The rung is dated from TODAY and is
being worked from today; there is no idle prefix to spend.*

#### ⛔ THE ORDER IS RIGHT AND THE REASON RECORDED FOR IT IS NOT — SAID BEFORE IT HARDENS HERE
The order was recorded as resting on my own *"B blocked on A, sequence required."* **Read at its
source, that phrase argues for the OPPOSITE order** — and I wrote it, so I am the one who has to
say so. The letters are bound in bus `124081`: *"A before B; the witness is unbuildable against
today's sentence and **waits for the restatement**"* ⇒ **A = R10 (the restatement), B = R9 (the
witness)**. So *"B blocked on A"* reads **R10 before R9**, the reverse of what is now scheduled.
⚠️ **WHY THAT CLAUSE STILL LOOKED LIVE:** its verdict's operative half was RETRACTED thirteen minutes
later (bus `124139`: *"R9 is UNBUILDABLE against today's sentence. **That is FALSE OF TODAY'S
CORE.** Withdrawn as stated."*). **The retraction was contained to one line — and the contained
string is the half that got quoted forward.** *Containment protects the fleet from the error while
preserving the sentence that caused it.*

✅ **THE ORDER STANDS ANYWAY, ON A STRONGER FACT THAT IS LANDED IN THE TREE — kernel-checked at this
hand on 2026-08-29, `saltbuild EXIT=0`, BUILT not Replayed:**
```
SaltWorks/HDL/StallShape.lean:133
  stallArm_reduces : CycleRealisesStepOrStalls cyc wordAt (fun _ => false)
                       ↔ CycleRealisesStepProj cyc wordAt := Iff.rfl
  #print axioms  ->  [propext, Quot.sound]          NO sorryAx, NO Classical.choice
SaltWorks/HDL/StallShape.lean:156
  stallArm_strictly_extends : ADMITTED by the stall arm ∧ REFUTED by today's predicate
  #print axioms  ->  [propext, Classical.choice, Quot.sound]
```
⇒ **the reduction is DEFINITIONAL (`Iff.rfl`), so a witness proved against today's core IS the
empty-stall instance of the restated predicate.** R9's product is not waste awaiting R10 — **it is
R10's BASE CASE, and it survives the restatement by definitional unfolding.** And
`stallArm_strictly_extends` proves the restatement is a real WEAKENING, not a rename, so R10 keeps
its content. ⇒ **R9-BEFORE-R10 IS NOT MERELY PERMITTED; IT IS THE ORDER THE KERNEL PREFERS.**
🔑 **Recorded because a reason nobody needs is a reason nobody checks — it propagates, and fixing it
later can flip the conclusion.** *The dates are the helm's and I am not touching them; the* because
*was mine and it was wrong.*

#### ⚠️ R9's OWN NOTE NAMES A PRECONDITION THAT IS UNMET — SCOPE DECLARED, NOT ASSUMED
The original R9 row below says the rung *"needs the FROZEN RTL and the core32 datum."* Measured
2026-08-29:
```
FROZEN RTL     ✅ satisfied — 08-29 is past the 08-27 freeze.
core32 datum   ⛔ NOT IN THE TREE. `SaltWorks/Silicon/Imported/Core32.lean` does not exist, and
                  ZERO `.lean` files in this repo mention `Core32`. Silicon DEMONSTRATED the
                  import (4,441 instances → 18,439 gates) and the helm recorded AT THE TIME that
                  this was a demonstration, NOT a landing. It is still not landed.
```
⇒ **"R9" NAMES TWO SCOPES AND THEY NEED DIFFERENT INPUTS.** Declared here so the date means one
thing and a successor cannot read it as the other:
```
R9 AS DATED (MINE)    the witness for the LEAN composed core — `CorePlace.core`
                      (CoreAssembly.lean:38) against `C4Spec` (C4.lean:76). BOTH EXIST TODAY and
                      it needs NO import. This is what council (f)/③ means by "the C4Spec proof
                      IS the search", and it is startable on the dated day.
R9 AT THE NETLIST     the witness for the IMPORTED core32 netlist. BLOCKED on silicon landing
(NOT DATED HERE)      Core32.lean. NOT MINE, NOT scheduled by this entry, and NOT counted in the
                      08-29→09-03 window.
```

### ⬇️ THE ORIGINAL 08/17 ROWS, RETAINED VERBATIM AS HISTORY — SUPERSEDED, NEVER DELETED
*R9's row here was STRUCK by §17 the same afternoon (not silicon's to date); R10's row stands and
is carried into the live table above unchanged.*

```
DATE        RUNG                                          NOTE
09-01→09-04 R9 · C4Spec WITNESS for the composed core     needs the FROZEN RTL and
            — inhabit C4Spec for the real circuit,        the core32 datum, so it
            not merely consume it                          cannot start before the
                                                           08-27 freeze
09-04→09-06 R10 · FLAGSHIP RESTATEMENT — bound stated in  JOINT per the ownership
            the units the machine honors; no bare literal  table; T8 is routed to
            surviving the retired cycle=step identity      the Captain, so silicon
                                                           dates only its own half
```
⚠️ **AND I AM MARKING R9's DURATION AS UNMEASURED, DELIBERATELY.** *I have guessed a
cost three times today and been wrong three times — 43 cells that were 7, "hours or a
day" that was minutes, a pin count that was a protocol.* ***I have never inhabited a
`C4Spec`, so 09-01→09-04 is a PLACEHOLDER WITH A DATE, not an estimate.*** **What would
make it measurable: attempt the witness for the SMALLEST conforming circuit in the
tree first, and report the real cost before the composed core is attempted.** *That
probe is cheap and I will take it at the first idle seam.*

## §15 · WHAT CLOSED EARLY, AND WHAT IT FREES

**The cell-model rung (`08-17→27`) CLOSED ON 08-17** — ten days early, at `b3be185`:
48 of 48 netlists import-clean, seven models proved `[0 axioms]`. *§11's
break-condition 3 is retired, not merely void.* ⇒ **The freed capacity goes to R9's
probe, which is the rung whose cost I actually do not know.**

📌 *The held core32 datum (394 KB, 6.4× my read cap) stays held under the helm's
15:15 ruling. My §1(1) argument against monoliths applies to it, and the discharge
block's round 2 owns the resolution — after the offboard RTL freezes, not before.*

---

# REVISION 4 — RUNG ZERO AT THE HEAD; THE R9 ROWS STRUCK; A LYING RECEIPT REPAIRED

**Under the Captain's ACT-AND-ACCOUNT law (ratified 19:1x): where I would have stood
down, I proceed and account. Absorbing refuter verdicts `seat 7eb6658` (5/5 HOLD, 12
FATAL) and the recon `seat f54d74e`. Rung zero is assigned: OWNER SILICON,
CROSS-VERIFIER COMPILER.**

## §16 · THE FATAL THAT WAS LIVE IN THE TREE — REPAIRED FIRST, BEFORE ACCOUNTING

```
canonical moved   7f38ad8 (5,043 B) → f3957c3 (6,249 B)
my embed          stayed at 5,043 B; table_identical EXIT=1 at char 2103
my 12:24 receipt  EXIT=0 — TRUE WHEN PUBLISHED, and asserting it ever since
REPAIRED          re-embedded at f3957c3; both 6,249 B / 18f990b87a9c6356; EXIT=0
```
⛔ **A RECEIPT THAT WAS TRUE WHEN WRITTEN IS NOT A RECEIPT THAT IS TRUE.** *The rotted
sha READ AS CONFIRMING — which is the precise failure my own citation law names, landing
on the one artifact I built to be checkable.* ⇒ ***The embed now cites `f3957c3` and
says why the previous one rotted. A copy must carry the version it copied, or the cmp
is a ritual.***

⚠️ **AND THE SUBSTANCE UNDER IT: the canonical repaired T6's control as a FALSE
NEGATIVE** — `runWords_succ` closes by `rfl` from the shape of the recursion, so the
control would report *"no stall entered"* **while a stall had entered.** ***I am T6's
cross-verifier. Frozen at the old bytes, I would have read a broken control out of my
own document and passed it. The table's requirement that a verifier be able to say NO
was defeated by my copy being stale, not by my judgement.***

## §17 · §14's R9 ROWS ARE STRUCK, NOT AMENDED

✅ **RESOLVED-2026-08-29 — THE STRIKE DID ITS JOB AND IS NOW DISCHARGED. Kept verbatim below,
because a marker is history:** the rung this section struck was re-dated by the helm on 08-29 to
`08-29→09-03` and entered in §14's LIVE table above, **owned by COMPILER exactly as this section
required.** Silicon's cross-verification duty — which §17 correctly noted the block scheduled
nowhere — is dated WITH that rung. *Nothing below is amended.*

**Ownership moved to COMPILER at 15:58. §14 dated a rung that is not mine and my own
prose promised to work it.**
```
STRUCK  "R9 · C4Spec WITNESS … 09-01→09-04"          — not silicon's to date
STRUCK  §14's "attempt the witness … at the first idle seam"
STRUCK  §15's routing of freed capacity to the R9 probe
```
⛔ ***THOSE SENTENCES WOULD HAVE PUT A SECOND PEN ON COMPILER'S RUNG — against the
one-pen custody clause I helped write six hours after destroying a file for want of
it.*** **Silicon's R9 duty is CROSS-VERIFICATION and nothing else, and the block
scheduled no such duty — that omission is itself corrected here: my cross-verification
of R9 is dated with compiler's rung, not before it.**

## §18 · THE CLAIM LADDER'S VERB IS CORRECTED, AND ITS MISSING ROW ADDED

```
STRUCK   RUNG 2 "DriveMap PROVED in RTL"
         false at three levels: the discharge HELD with five fatals; the RTL makes
         DriveMap TRUE OF THE HARDWARE, which is not a proof; and no Lean object
         inhabits it
CORRECT  RUNG 2 = "TRUE OF THE HARDWARE BY CONSTRUCTION, ASSUMED IN LEAN"
ADDED    a C4Spec row at the same rung — the ladder had NO ROW FOR IT AT ALL, so the
         statement-tier object routed to the Captain UNDER-REPORTED the proof debt
         by exactly the seam rev 3 was written to add
```

## §19 · §7 IS THE FSM's SPECIFICATION, AND IT HAS FATALS — WHICH DECIDES TONIGHT'S ORDER

The refuters found §7 under-specified **at the pins**:
```
· the four transaction types are INDISTINGUISHABLE at the interface — the host must
  drive `ui` for FETCH and LOAD but not STORE, and NO chip→host signal says which
· the `sof` framing the design assumes HAS NO PORT ON THE CORE
· the gate-level bench asserts `phase_o` increments mod 4 EVERY cycle, which my own
  arbitration rule breaks the moment a data transaction owns the bus
```
⇒ ***§7 IS THE FSM's SPEC. Drafting the FSM tonight against a spec with three fatals
would produce a draft whose retraction is guaranteed rather than cheap.*** **The
alternative measured: repair §7 first — that repair IS the specification — and the FSM
draft becomes a transcription instead of a guess.**

## §11′ · THE PLAN, RE-DERIVED WITH RUNG ZERO AT ITS HEAD

```
RUNG ZERO  build and measure the COMPOSITION — owner SILICON, x-verifier COMPILER
           (1) composed top: LW/SW plane + fabric/neuron complex in the 24-pin
               wrapper, via the byte-phase adapter §7 specifies
           (2) synth + layout receipts NAMED BY FILE (stat, DRC/LVS, real PDN)
           (3) the TTNDF manifest brought true; scaffold header retired
           (4) a bench driving at least one LW and one SW through the pins
           CONTROL: any composed-area claim must cite a COMMITTED stat file whose
           netlist greps positive for BOTH a core/plane instance AND banyan_fabric.
           NO FILE, NO CLAIM.
⇒ everything above re-derives behind it. The 08-27 freeze is load-bearing on rung
  zero ALONE. NOT DATED TONIGHT — dating it is the fourth cost-guess I have refused
  today, and it is refused until §7's fatals are repaired.
```
⛔ **AND MY 112,962 µm² / 48.6% IS RETIRED BY MY OWN HAND** *(struck on the bus 18:57)*:
it was measured on `tt_um_saltworks_ndf_composed.v`, a **scratchpad file that has never
existed in this tree**. It is precisely the green-and-wrong state rung zero's control
row names, and it was mine.
