# NDF TOP MODULE — design block v1 (design item #1)

**Maestro (Fable), drafted 2026-08-09 evening at the Captain's "proceed";
refuter pass owed before the ~07:30 sitting consumes it. Sources: the
five-reader recon of 18:5x (design package · cell · core · BB fabric ·
TT physical), every claim below carries its label — RULED (a standing
ruling), MEASURED (an artifact number), ESTIMATE (labeled arithmetic),
ABSENT (verified missing), PROPOSED (this block's own rulings, the
sitting's to confirm or strike).**

**Precondition preamble (validate before consuming): the SIGNED cell
LANDED at 7364548 (19:05, fire ① of the Captain's PROCEED) as
`scellSeq` / `scCore` — 225 gates (wsCore 67…99 · XOR bank 100…131 ·
macCore 132…291), zero constant gates, 32 audited theorems (32/32
after 80c572a closed the one rfl coverage gap silicon's MEAS caught),
landed BESIDE `cellSeq` — COMPILER's object (MacCell.lean:702); the
193-gate cell and math's MacBridge theorems ABOUT it keep their
meaning, and consumer consent (math's), not ownership, gates any
retirement. The boundary the top module wires is UNCHANGED:
nIn = 3 {x, load, sign} — `sign` REPLACES the old cin (they are one
wire by ruling (b)), 67 in / 96 out at emission. QUEUE cited by
header text, never line number (it grew 860→876 during the recon
itself).**

---

## D1. THE OBJECT (proposed)

One combined TT project — RULED (§2: "One combined TT project…
separate TT projects are power-gated and never coexist").

- Name: `tt_um_saltworks_ndf`. TT hard rules ride: the fixed 8-port
  list exactly, no extras; all outputs assigned; `rst_n` active LOW;
  `ena` tied off, never gating logic (it is also the power-gate
  enable). (dossier, MEASURED precedent `tt_um_saltworks_banyan`.)
- Contents: `banyan_fabric` (routing) + `batcher_c` placed as compute
  organ (§D3) + 4 × `scCore` (the SIGNED cell, emitted, shelled per
  §D7) + `slicea16bma` (the core, as-is per Option A) + ONE central
  phase sequencer (§D5) + the pin wrapper. k = 4 is FORCED by fabric
  ports, not chosen (RULED, the inversion).

## D2. THE LAYER SPLIT — kernel vs hand RTL (proposed ruling)

The scope law says "kernel Circ + emitS from day one — no hand RTL."
MEASURED reality: `emitS` is combinational-only; no `emitSeq` exists
(grep 0 hits); every flop in the fabricated tree is hand RTL. The law
cannot be met for state as the toolchain stands. Two honest exits:

**(a) BUILD `emitSeq` — PROPOSED.** `emitSeq : String → String → Seq
→ String`: emit the core via the existing `emitS` body, plus one
`dfxtp_<drive>` per state bit, feedback o[nOut..] → i[nIn..], done.
Mechanical; serves the cell now and the assembled core later.
Acceptance criteria (pre-registered): flop count == nState EXACTLY
(the -ma lesson: a flop shortfall is state you thought you had);
cell instances == gates + nState; conb == 0; one assign per primary
output (NOT "0 assigns" — that criterion would fail correct emitS
output, EmitS.lean:188-203). Owner: compiler genre. The refinement
stays stated ∀ st₀ (power-gating law) — `initial` banned.

**(b) The named exemption list.** What remains hand RTL, minimized and
named (the fabbed-is-verified sentence must exclude these by name):
the `tt_um_` pin wrapper (port packing, `uio_oe`, tied `ena`), the
central sequencer FSM (§D5; candidate for a later kernel Circ), and
`banyan_fabric.v`/`bitserial_switch.v` (fabricated precedent, already
outside). `(* keep *)` at every reasoned seam (MEASURED: 1.7% area,
cone coverage 86.9→94.8%); read back by CONE CENSUS, never name-grep.

## D3. THE FABRIC — the one ruling the sitting must make

The architecture is the BB — RULED at the Captain's own clarification
("THE FABRIC IS THE BB… not a bare banyan"). But — ABSENT, verified:
no composed Batcher+banyan artifact exists in either lane; the
fabricated BB submission ships the bare banyan; the two RTL file sets
are disjoint; nothing in Lean joins `batcherNetC` to the banyan.

And the theorem families split on load: the full-load family
(`bnC_payload_delivered`, `composed_switch_of_seam_k3`) FORCES all
eight lines active (`seam_hyps_force_full_load`) — the NDF's spare
port (idle, all-zero frame) puts the chip permanently in PARTIAL
load, where that family is silent and the shared-idle-code refutation
(`repeated_input_code_refutes_no_conflict`) bites. What DOES cover
partial load today: `fabric_routes` — 255 concentrated scenarios,
kernel-checked ON THE REAL BANYAN NETLIST at P=8 (MEASURED), needing
only `mem_allScenarios` (stated, unproved) for the completeness
sentence; plus §2b's own doctrine that the sort happens ONCE, in the
compiler ("our traffic is static per phase… deterministic
permutation-round schedules").

**PROPOSED: both halves ship on-die; the ROUTING duty stages.**
September routes with the banyan under compiler-emitted conflict-free
permutation schedules — the lane that is already certified at the
operating point we will actually run. The Batcher half is placed
on-die as the certified compute organ (its sorting theorems applied
as used) and the sort-then-route front-end integration is a NAMED
v1.1 node (its gate: `mem_allScenarios` or the convention-C order
seam, whichever lands first). The Captain's architecture is intact —
both halves fabbed, one seam deferred with its gate named. The
alternative (assemble the BB now) adds a new unpriced construction
node + an unproved seam to a September clock. His call.

## D4. THE CELL ATTACHMENT (what silicon twice refused to author)

**(a) The cell boundary — ANSWERED AT THE LANDING (7364548).**
`sign` REPLACES `ccCin` as the third primary input: nIn stays 3
{x=i0, load=i1, sign=i2}, state i3…i66 unrenumbered, emitted module
67 in / 96 out — the smaller boundary of the two candidate shapes.
The object is `scellSeq` (`scCore`, 225 gates); the subtract cycle is
`sc_sign_cycle_subtracts` (sign=1 ⇒ acc − andWord x w), the seam is
`sc_seam_is_the_xor_of_the_and_row`, disjointness is TWO bounds
(`sc_ws_below_xor` · `sc_xor_below_mac`). PIN INDICES ARE FROZEN.
Still: regenerate offsets from the Lean defs, never hard-code.

**(b) Input side — NO deserializer needed.** The cell is bit-serial
by construction: `ccX` eats one bit per cycle; weights enter serially
through the SAME wire under `ccLoad` (load-path A). A fabric port's
payload window drives `ccX` directly.

**(c) The endianness seam — resolved by CONVENTION, zero silicon
(PROPOSED).** Fabric frame headers are MSB-first (address); payload
is streamed transparently. The cell streams LSB-first. RULE: payload
bit-order is a PACKING convention owned by the schedule compiler and
the RP2040 firmware — payloads are packed LSB-first at the source.
One sentence in the frame spec; no hardware.

**(d) Output side — the SER organ (ABSENT today).** One 32-bit
parallel-load shift register per cell + the activation. Activation =
CE-vs-0 at the LANDED signed order, `wordSignedOrder` passed
EXPLICITLY in the term, NEVER an instance (`letI_le_is_still_unsigned`
is the kernel witness). Kernel Circ + emitSeq shell, compiler genre.

**(e) Result width — P stays 8 (PROPOSED).** Frame = 14, identical to
the BB; counter/valid mechanics reuse. The 32-bit accumulator result
streams as FOUR P=8 frames (zero new silicon). No requantization
organ (RULED, #8) and none needed: the minimal demo's one GNN layer
emits to the edge, no cell→cell second layer exists to feed. Changing
P instead would re-open every concrete routing fixture (recon).

**(f) Per-instance obligations.** Each cell instance: `instOK` +
membership in ONE pairwise-disjointness/coverage theorem (the
`chain_accounts_for_every_placed_organ` shape — sixteen true instOKs
once stood over a netlist that could not compose) + one seam theorem
per wire class (`cell_seam_is_the_addend` shape).

## D5. THE SEQUENCER AND THE CPU — honest staging (proposed)

**One CENTRAL sequencer, four cells' strobes.** §1's per-cell "phase
FSM" and §3's "route round" reconcile as: a single FSM walking
(LOAD_W → STREAM_X)* → ACTIVATE → EMIT, driving per-cell
`load/sign/emit` strobe lines and frame alignment from the SAME
`sof`/reset event as the fabric (well-phasedness comes from an input
event, never a frame count — the amended §5 law). Per-cell FSM
silicon: zero (matches the fan-in banner's "zero new silicon"). For
September the schedule is FIXED (one GNN layer, the §4 worked
example: CONFIG · 3 rounds · SELF · ACT · EMIT).

**The CPU demonstrates; it does not yet conduct — and the block says
so plainly.** MEASURED chain: `slicea16bma` has no packet port; the
port organ is ABSENT/unpriced; and the 5-op ISA has NO store/IO
instruction — no architectural path exists from software to the
sequencer. September: the core ships on-die (RULED #7), runs verified
code over its 18-pin bus, and the sequencer runs autonomously.
"Managed by the CPU" (the dream sentence) lands as v1.1 = B-ISA SW +
the port organ + B-EXEC's driver row (all three already named in the
register; none new). The demo sentence is written at the theorem that
exists: "a verified core and a verified dataflow fabric on one die,
the fabric scheduled by the compiler" — not "managed by the cpu",
yet.

**Fetch protocol (open question, PROPOSED answer):** same-window
service — the RP2040 PIO serves the instruction byte within the
phase in which its address byte is presented; wait-state-free is a
FIRMWARE CONTRACT, pre-registered as a bench assertion (phase_o
observed, byte latency measured), not a hardware assumption. If the
bench refutes it, the named fallback is one-loop-later with `ir` as
the pipeline register — a firmware+documentation change, zero
silicon. (slicea16bma commits unconditionally at phase 3 either way.)

## D6. PIN MAP — bit-exact (proposed; none existed before this block)

```
ui_in[7:0]   instr_byte[7:0]   in   CPU memory bus (per slicea16bma)
uo_out[7:0]  addr_byte[7:0]    out  PC bytes, 4 phases
uio[0]       phase_o[0]        out  } phase strobe
uio[1]       phase_o[1]        out  }
uio[2]       edge_in_data      in   } packet port: weights/inputs
uio[3]       edge_in_valid     in   }
uio[4]       edge_out_data     out  } packet port: results
uio[5]       edge_out_valid    out  }
uio[6]       sof               in   frame alignment (the input event
                                    well-phasedness requires; BB
                                    precedent uio[0])
uio[7]       valid             out  payload-window flag (bring-up)
uio_oe = 8'b1011_0011  (static; 1=output)
```
24/24 exact — and the ruled "spare/debug" pair is SPENT as
sof+valid: alignment is a correctness input (the mis-phased
measurement: 192/200 fail on frame 2 — waiting repairs nothing), and
valid is the one observability bit the BB bring-up actually used.
Fabric port allocation: 4 cells + CPU-client (stubbed idle until the
port organ, §D5) + edge-in + edge-out + spare (tied to the all-zero
idle frame — idle is a fixed point of claim-gated OR). Relief valve
unchanged (narrow data bus to 4 pins) if v1.1 wants more edge ports.

## D7. STATE, AREA, TILE (estimates labeled)

- Per cell: 64 flops (emitSeq) + SER 32 flops + strobe wiring.
  ESTIMATE from the liberty BOM (875.8 µm² / 35 flops ≈ 25 µm²/flop):
  ~2.4k µm²/cell state, ~9.7k µm² at k=4, pre-layout class. NOT
  MEASURED; silicon prices at emission. The 5,191 µm² organ figure
  contains ZERO state ("sequential elements: 0.000000") — never carry
  it as "the cell."
- Floorplan load: 71.8–76.6k µm² (recon, post-layout class) + state
  ESTIMATE ⇒ 6x2 utilization ~40–44% — inside the measured-clean
  band (44.65/48.77% clean points). 6x2 at €840 stands (RULED
  recommendation); the €280 settling run (4x2, 55.4–58.9% =
  UNMEASURED band) FIRES on this block's emitted RTL and may hand
  back €280. Reservation at layout-readiness (RULED).
- DRV debt rides the core: 1,678 max-slew repairs ADD cells,
  unpriced — named here so the tile margin owns it.

## D8. CLOCK — the pair, ruled explicitly (proposed)

`config.json CLOCK_PERIOD: 55` + `info.yaml clock_hz: 18181818`
(1e9/18181818 = 55.0000005 ns — agreement holds at the precision the
flow reads; stated here so nobody computes it at assembly time).
MEASURED basis: composed cell +2.061 ns at the limit corner at 55;
52 does not close (−0.94); pad output ceiling 33 MHz ≫ 18.2. THE
STALE LITERAL: the QUEUE's agreement-law sentence still says "20 MHz"
— the LAW carries, the number died at the 16:0x re-rule; amend the
register at this block's adoption. AND: no instrument enforces the
agreement (validate.py has zero CLOCK_PERIOD hits) — add the
reconciliation check to validate.py as part of the NDF submission
tree (one function, its negative control: a mismatched pair must
FAIL).

## D9. VERIFICATION OBLIGATIONS (the table the sitting signs)

| # | obligation | shape exists as | status |
|---|---|---|---|
| V1 | per-instance instOK, every placed organ | cc_*_instOK | pattern landed |
| V2 | ONE coverage/disjointness theorem, whole die | chain_accounts_… | pattern landed |
| V3 | seam theorem per wire class | cell_seam_is_the_addend | pattern landed |
| V4 | partial-load routing at the operating point | fabric_routes (P=8, real netlist) | LANDED; completeness gate = mem_allScenarios (stated, unproved) |
| V5 | signed activation discipline | wordSignedOrder explicit | law landed |
| V6 | ∀ st₀ power-gating refinement, all new state | D3.5 pattern | pattern landed |
| V7 | emitSeq acceptance (flops==nState, cells==gates+nState, conb 0) | this block §D2 | NEW |
| V8 | overflow at scale rides int8: shiftSafe_at_int8_scale + noOverflowFrom discharged per network by the schedule compiler | landed at int8 | landed; per-network duty named |
| F3 | "down to silicon" for the CHIP clears ONLY at the synthesis run on THIS top module, scope named in the sentence | evidence fence | stands |

## D10. OPEN FOR THE SITTING (cannot be ruled from the evidence)

1. **D3's staging** — banyan-routes-now/BB-seam-v1.1 (my
   recommendation) vs assemble-the-BB-now. The Captain's
   architecture either way; the difference is September's verified
   surface vs a new unpriced node.
2. **Drive strength `_1` vs `_2`** — `_1` has a real TT-CI green;
   `_2` has the local no_synth evidence; the settling measurement
   (TT-CI structural run at `_2`) is named and unrun.
3. ~~The XOR-bank landed shape~~ — ANSWERED before the draft was an
   hour old: `sign` replaces cin, boundary unchanged, `scellSeq`
   beside `cellSeq` (§D4a). Residual for the sitting: NONE (math's
   duplication call `sc_adder_bit` vs `adder_run_is_sum_bit` is
   math's, not this block's).
4. **Fetch-protocol contract** — accept §D5's firmware-contract
   proposal or demand a hardware wait-state.
5. **The CPU-role sentence** — confirm the honest staging (§D5) as
   the demo's public sentence, or re-scope September to include the
   port organ + SW (priced: new ISA op + unpriced organ on a 4-week
   clock — not recommended).

**What fires on adoption: compiler — emitSeq + SER/activation Circ +
the glue kernel objects (V1–V3, V7); silicon — the settling run on
the emitted RTL, then the 6x2 floorplan; math — standing refutation
+ V4's completeness gate if the sitting wants it closed; evidence —
F3's scope sentence at the run. The schedule anchor stands: ~Sept 7,
soft by one shuttle, reservation at layout-readiness.**

🧂⚓
