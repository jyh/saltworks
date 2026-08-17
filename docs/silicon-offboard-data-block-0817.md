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
