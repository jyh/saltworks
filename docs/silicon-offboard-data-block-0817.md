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
