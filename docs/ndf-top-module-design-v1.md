# NDF TOP MODULE — design block v1.1 (design item #1, REFUTED-AND-REPAIRED)

**Maestro (Fable). v1 drafted 2026-08-09 evening at the Captain's
"proceed"; v1.1 same evening after the FIVE-REFUTER ADVERSARIAL PASS
(all five: REPAIR-THEN-FIRE; two CONFIRMED-FATAL findings and one
numerical-correctness hole, all repaired below by RESTATEMENT, none by
deletion). The sitting (~07:30) consumes THIS version. Labels:
RULED / MEASURED / ESTIMATE / ABSENT / PROPOSED / **AMENDS(veto)** —
the last marks Tier-1-adjacent amendments awaiting the Captain's word.**

## REFUTATION LEDGER (what the pass killed, so the sitting need not re-find it)

- ⛔ FATAL-1 (theorem-family): v1's "the lane that is already
  certified at the operating point" was FALSE — `fabric_routes`
  covers only prefix-concentrated, destination-monotone traffic;
  ZERO rounds of the §4 demo were in the certified set. → D3
  restated; per-round fixtures adopted (V10).
- ⛔ FATAL-2 (scope-law): the hand-RTL exemption list omitted the
  CPU — the largest hand-RTL block on the die — and the demo
  sentence overclaimed "verified core." → D2(b), D5 restated.
- ⛔ HOLE (scope-law U-1): the cell accumulator has NO
  initialization path in silicon — bias entry and clearing are the
  SHELL's obligations, unstated in v1. → D4(f) new; V9.
- ⛔ (area-clock): v1's own 19:20 acc-enable amendment contradicted
  the Seq model (which has no enable) — the shell is a NEW semantic
  object needing its kernel counterpart. → D2(a)/V9.
- Pin veto unflagged; sof argument was a non-sequitur; utilization
  arithmetic survived by two errors cancelling; clock basis carried
  an unsigned number into a signed context (superseded same hour by
  silicon's 19:34 signed measurement); DRV numbers stale AND
  mis-modeled. All repaired in place.
- ✔️ Survived unchanged: the 24-pin arithmetic and uio_oe literal
  (checked bit-by-bit, twice), slicea16bma pin directions, the
  D4(e) P-literal claim, the V7 "0-assigns-would-be-wrong" trap,
  the D8 ABSENT claim (validate.py has zero CLOCK_PERIOD hits).
- Out-of-freeze finds registered in the QUEUE: the BB cocotb bench
  is STALE against the 8/8 cnt[3] ruling (test.py:247 would fail);
  PayloadL4.lean:30-31 carries a stale import-owed note.

---

**Precondition preamble (validate before consuming): the SIGNED cell
LANDED at 7364548 (19:05, fire ① of the Captain's PROCEED) as
`scellSeq` / `scCore` — 225 gates (wsCore 67…99 · XOR bank 100…131 ·
macCore 132…291), zero constant gates, 32 audited theorems (32/32
after 80c572a), landed BESIDE `cellSeq` — COMPILER's object
(MacCell.lean:702); math's MacBridge theorems ABOUT it keep their
meaning; consumer consent, not ownership, gates retirement. Boundary:
nIn = 3 {x=i0, load=i1, sign=i2}, 67 in / 96 out. AND MEASURED at
19:34 (silicon steps 1-3, controlled pair, ONE die, configs 3a8b452):
signed cell +332.82 µm² stdcell (+9.79%), logic 190→222, setup at the
slow corner +2.0831 → +1.1123 ns — BOTH ARMS CLOSE AT 55 ns; xor2
survives yosys 96→96. QUEUE cited by header text, never line number.**

## D1. THE OBJECT (proposed)

One combined TT project — RULED (§2: separate TT projects are
power-gated and never coexist).

- Name: `tt_um_saltworks_ndf`. TT hard rules ride: the fixed 8-port
  list exactly; all outputs assigned (including uio_out[6,3,2],
  driven 0 — their oe bits are inputs); `rst_n` active LOW; `ena`
  tied off, never gating logic.
- Contents: `banyan_fabric` (routing) + `batcher_c` placed as the
  compute organ (§D3) + 4 × `scCore` (the SIGNED cell, emitted,
  shelled per §D2(a)+§D4(f)) + `slicea16bma` (the core, as-is per
  Option A) + ONE central phase sequencer (§D5) + the pin wrapper.
- k = 4 — forced GIVEN THIS BLOCK'S D6 ALLOCATION (refuter
  precision: the §2 text alone allows 5+1+2 with no spare; the
  inversion plus D6's spare + CPU-stub makes it 4). Bigger tiles
  still buy unaddressable silicon (RULED).

## D2. THE LAYER SPLIT — kernel vs hand RTL

THE LAW, quoted at its true scope (QUEUE, COUNCIL RULING #7, risk
(c), verbatim): "the cell is built as a KERNEL Circ + emitS from day
one (the fabbed thing IS the verified thing — no hand RTL)." The law
is CELL-scoped. The cell is a `Seq` (nState = 64) and `emitS` is
combinational-only, therefore:

**(a) `emitSeq` is REQUIRED, not optional** — the cell cannot be
emitted as a clocked artifact without it. Spec: emit the core via
the emitS body + one flop per state bit + feedback o[nOut..] →
i[nIn..]; `drive` is an ARGUMENT exactly as emitS's is (for the FLOP
class the evidence is currently ONE-SIDED toward `_2`: dfxtp_1 IS on
the pinned PDK's no_synth.cells at line 152, dfxtp_2/_4 are not —
refuter-measured; the combinational question stays open per D10.2).
THE SHELL IS A NEW SEMANTIC OBJECT: the acc half carries an ENABLE
(hold during LOAD_W) and a synchronous CLEAR (§D4(f)) — the plain
`Seq`/`stepSeq` model has neither, so the kernel counterpart (an
enable/clear-aware Seq form + its refinement to scellSeq's
runTrace-per-input shape) is a NAMED DESIGN ROW, compiler genre (V9).
Acceptance criteria, corrected by the pass: flop count == nState
EXACTLY (64) · cell instances == gates + nState (225 + 64 = 289 for
scCore, emitSMux peephole OFF) · conb count == the Circ's `.const`
gate count (ZERO for scCore BY THEOREM, not as a general emitSeq
property — do not carry it to the SER organ unexamined) · assign
count == core.outs.length (96). "0 assigns" would reject a correct
emission (EmitS.lean:188-203 — verified accurate).

**(b) The hand-RTL residue — an AMENDMENT to the law's spirit,
flagged as such, complete this time:** the `tt_um_` pin wrapper ·
the central sequencer FSM · `banyan_fabric.v`/`bitserial_switch.v`
(fabricated precedent) · **`slicea16bma.v` — THE CPU, the largest
hand-RTL block on the die (546 behavioural flops; core-account:
"no kernel statement mentions it" — a TWIN by construction
discipline, not a theorem; replacing it with the emitted kernel core
is the W5-asm prize and is NOT September scope)** · the per-cell
shells until emitSeq lands. `(* keep *)` on behavioural RTL
preserves the NET, not the DEPENDENCY (measured — the carry-lookahead
re-derivation); boundaries are read back by CONE CENSUS only.

## D3. THE FABRIC — restated at the theorems' exact size

The architecture is the BB — RULED (the Captain's clarification).
CORRECTED ABSENT claim: Lean DOES partially join the halves —
`composed_switch_of_bnC_driven` (SeamJoinB, audited, in the hub
closure) delivers the banyan's three-conjunct self-routing conclusion
FROM the fabricated sorter's driven trace. What remains absent: the
RTL composition, and the partial-load seam.

WHAT IS CERTIFIED TODAY, exactly: `fabric_routes` — 255 fixtures at
P=8, ONE initial state, ONE payload per source, covering ONLY
prefix-concentrated actives with destination-monotone assignments;
the ELEMENT is the imported gate netlist, the fabric level is the
Lean model. **ZERO rounds of the §4 worked example are in that set**
(the pass's fatal find — v1's "already certified" sentence would have
been the day's sixth one-theorem-larger sentence). Two partial-load
families exist: `partial_load_selfrouting` (ANY activity pattern —
but abstract `cSorted`, REQUIRES the Batcher, the convention-C seam
owed at compiler) and `fabric_routes` (netlist-model lane, restricted
class). The full-load family cannot cover any idle line
(`seam_hyps_force_full_load` — verified sound).

**PROPOSED — the September verification path: PER-ROUND FIXTURES.**
The demo schedule is FIXED and SMALL; each of its rounds ships its
own `decide +kernel` fixture on the netlist model (the fixture
machinery exists; regenerated payload alphabets go ONE-HOT — the
current codes 1..8 are not OR-alias-free, a refuter hygiene find).
The Batcher-integrated `partial_load` route (any permutation, the
compiler's seam) is the v1.1 general claim. Both halves still ship
on-die; the sitting rules the staging (D10.1). TWO fabric ports are
permanently idle in September (the spare AND the stubbed CPU
client) — max active 6; the idle pair sits at the TOP indices by
D6's frozen map, so actives form the 0-5 prefix.

## D4. THE CELL ATTACHMENT

**(a) The boundary — ANSWERED AT THE LANDING (7364548).** `sign`
REPLACES `ccCin`: nIn stays 3, state i3…i66 unrenumbered, 67/96.
The object is `scellSeq`/`scCore`; the subtract cycle is
`sc_sign_cycle_subtracts`; seam `sc_seam_is_the_xor_of_the_and_row`;
disjointness two bounds. PIN INDICES FROZEN. Regenerate offsets from
the Lean defs, never hard-code.

**(b) Input side — no deserializer.** The cell is bit-serial: `ccX`
eats one bit per cycle; weights enter serially through the SAME wire
under `ccLoad` (load-path A).

**(c) The endianness seam — by CONVENTION, zero silicon.** Payload
bit-order is a PACKING rule owned by the schedule compiler and the
RP2040: payloads packed LSB-first at the source. One frame-spec
sentence.

**(d) Output side — the SER organ (ABSENT).** 32-bit parallel-load
shift register + activation = CE-vs-0 at the LANDED signed order,
`wordSignedOrder` explicit in the term, never an instance. Kernel
Circ + emitSeq shell, compiler genre.

**(e) Result width — P stays 8.** Frame = 14, BB-identical; the
32-bit result streams as FOUR frames. No requantization organ
(RULED #8) and none needed (one layer, no cell→cell chaining).
P-change re-opens every concrete fixture (refuter-verified: the
kernel certificates are P-literal).

**(f) THE ACC INITIALIZATION HOLE (the pass's numerical-correctness
find, adopted):** scellSeq's acc bits 35…66 have NO input path — the
adder's own feedback is their only writer; `runTrace`'s initial state
is a MODELLING DEVICE, not a mechanism. Therefore THE SHELL supplies:
(i) a synchronous CLEAR on the acc bank, sequencer-driven at neuron
start — this also discharges the ∀st₀ power-gating obligation for
those flops; (ii) TWO ENABLES, not one — **upgraded 20:1x at the Captain's
timetable construction, the evening's THIRD question-found defect:
the weight register shifts EVERY clocked cycle unconditionally
(wshift_runTrace_state — W<<<t marches with the clock), so a weight
parked between its load and its stream DECAYS by 2^gap. The shell
therefore freezes the WHOLE cell outside its scheduled windows:
`en_wsh` high during load/extension/stream/bias cycles, `en_acc`
high during stream/bias cycles only (the acc hold during load —
the AND row is live during load, 33 gates = ungated row, and would
otherwise dribble andWord(w_bit, residue) into acc). Frozen gaps
are nonexistent time in the kernel's two-runTrace model — the
freeze IS what makes parking a weight valid, and V9's model covers
both enables;** (iii) bias entry by the LANDED
bias-as-first-addend ruling: after CLEAR, load `b` as the first
"weight" and stream ONE x=1 cycle → acc = b; then load W₁. Both
shell controls are NEW SILICON, priced at emission, and both need
the V9 kernel model. COMPILER-VERIFIED 19:42 on scCore by fanout
measurement (`load` touches ONE gate; all 32 next-acc outputs are
the adder sums unconditionally) with the repair NARROWED: the
missing capability is ZERO-the-accumulator ONLY — no bias port
(a second way in for something that has one); the cost lands in
emitSeq's flops, NOT scCore, so the 19:34 area/timing/equivalence
results all stand. THE CLASS RIDER (compiler's, adopted into
V1-V3's method): at every composition seam, enumerate the
capabilities each port used to accept and verify each one
ABSORBED, PRESERVED, or DELIBERATELY KILLED — the addend port's
four: two absorbed, two broken (sign 17:45, bias 19:40, one root
cause). The top-module seams get this audit at V3.
**LOAD_W is 32 cycles canonical** (full-width
serial load: 8 value + 24 sign-extension bits) so the register ends
holding exactly `bitsOf W`; the 4× weight-load cost is PROPAGATED
into the schedule budget (§D5) — a schedule fact, not a footnote.

**(g) Per-instance obligations.** instOK per organ + ONE
coverage/disjointness theorem for the whole die + one seam theorem
per wire class (the landed shapes).

**(h) FRAME↔PHASE SYNCHRONIZATION (the Captain's 19:5x question).**
One clock domain + the sof-aligned frame counter IS the shared grid;
the sequencer walks the SAME grid — there is no handshake anywhere
in the machine. A WEIGHT packet's payload window (frame cycles 6-13)
= the cell's 8 load cycles; the SHELL then extends the sign LOCALLY
for 24 more load cycles (the sender sends 8 bits ONCE — one frame
per weight, matching §4's bandwidth arithmetic; the extension is a
1-bit hold mux, priced in the shell). A VALUE packet's payload
window IS the 8 accumulation cycles, with `sign` asserted at frame
cycle 13 (LSB-first payload ⇒ the MSB arrives last). The bias costs
one weight-frame (b) + ONE sequencer-local x=1 cycle (a constant —
no packet). ACTIVATE reads; EMIT drives four result frames. The
schedule compiler emits the whole thing as a frame-by-frame
TIMETABLE and the RP2040 plays its side offline — deterministic
phases, §5c's zero-scheduler clause made literal. **THE WEIGHT
LATCH NEEDS NO RESET, EVER: the full-width load is self-cleaning
(all 32 bits rewritten every load — which is also the weight half's
∀st₀ power-gating discharge). The acc CLEAR is the cell's ONLY
reset, and it opens the NEXT neuron rather than riding ACTIVATE —
ACTIVATE is read-only on the cell.**

## D5. THE SEQUENCER AND THE CPU — honest staging

**One CENTRAL sequencer.** A single FSM walking CLEAR → BIAS →
(LOAD_W → STREAM_X)* → ACTIVATE → EMIT, driving per-cell
clear/enable/load/sign strobes and frame alignment from the same
`sof`/reset event as the fabric (well-phasedness from an INPUT
EVENT — the amended §5 law). Per-neuron cycle budget AT THE CANONICAL
LOAD (int8, two inputs): 1 clear + 33 bias + 2×(32 load + 8 stream)
+ activate + 4×14 emit frames ≈ 170 cycles — the compiler's schedule
rows own the exact table (the 32-cycle load quadruples v1's implied
weight-load cost; stated so nobody discovers it at the bench).

**The CPU demonstrates; it does not yet conduct — restated at the
account's size.** The kernel ISA has five constructors and no
store/IO (byte-verified); `slicea16bma.v` has no packet port. NO
ON-DIE path from software to the sequencer exists today; the paths
that DO exist run through the RP2040 — outside the verified surface.
THE DEMO SENTENCE — ⛔ **FENCE PASS RUN 2026-08-25 by the evidence
seat: NOT CLEARED, THREE FINDINGS.** The original is left visible
below because a corrected record has to show what it corrected.

ORIGINAL (fence-pending since the sitting): "a processor whose every
organ and wire is kernel-certified — its end-to-end refinement one
named theorem away, its fabbed twin scheduled for replacement —
beside a dataflow fabric whose netlist is kernel-checked against its
Lean model on the schedule class we run, on one die, driven by a
compiler-emitted schedule." Nothing stronger survives
core-account.md's own authorization.

**(1) ⛔ THE TRAVEL CONDITION IS BREACHED, AND THIS SEAT SET IT.**
`core-account.md` §4.3′ — the evidence pass of 2026-08-09 — rules
that *"every organ and every wire is kernel-certified"* is defensible
**only with §1.4's gloss**: `ruledEnc` has no `sem_*` certificate, it
is a zero-gate rewiring whose stand-in is `encoder_select_seam_closed`,
so every organ carries A kernel-checked theorem but not all of the
same kind. That pass says in terms: *"the sentence must not travel
without that disclosure, because 'kernel-certified' will be read as
'has a semantic certificate'."* MEASURED IN THIS FILE: `ruledEnc` 0
hits, `encoder_select_seam_closed` 0, `sem_` 0. **The sentence
travelled and the disclosure did not.**
⇒ A TRAVEL CONDITION ATTACHED TO A SENTENCE HAS NOTHING ENFORCING IT.
The condition lived in the authorizing document; the sentence moved to
this one and arrived bare. Sixteen days, no alarm.

**(2) ⛔ "ON THE SCHEDULE CLASS WE RUN" IS REFUTED 130 LINES ABOVE, IN
THIS FILE.** §"WHAT IS CERTIFIED TODAY" states in bold that
`fabric_routes` covers ONLY prefix-concentrated actives with
destination-monotone assignments, and that **ZERO rounds of the §4
worked example are in that set**; per-round fixtures are V10, status
NEW. The certified class and the demo's class are disjoint.
CHEAPEST TRUE FORM, free and gate-less: **"on prefix-concentrated
destination-monotone traffic."**

**(3) ⚠️ AND THE ASSEMBLY CLAIMS MORE THAN EITHER CLAUSE.** The
processor half is capped by core-account §3's authorized sentence
(§4.5′: *"that sentence is the ceiling"*); the fabric half rides a
different lane with its own fence. Both can be true and the SENTENCE
still implies a single end-to-end certified system on one die, which
neither account authorizes. Two true parts, one false assembly — and
no sentence-level check sees it, because no sentence is false.

**✅ RATIFIED FORM — the Captain, 2026-08-25 21:1x, verbatim as proposed.**
*This is now THE demo sentence. The original above is left visible under the
corrected-record rule; it is superseded, not deleted.*
"a processor whose every organ and every wire carries a kernel-checked
theorem — though not all of the same kind: `ruledEnc` carries a
seam-closure, not a semantic certificate (§1.4) — its composed
end-to-end semantics one named theorem away and NOT yet stated, its
fabbed twin scheduled for replacement; and, separately certified on
the same die, a dataflow fabric whose netlist is kernel-checked
against its Lean model on prefix-concentrated destination-monotone
traffic, driven by a compiler-emitted schedule."
📌 "separately certified" is load-bearing: it is what stops finding (3).
📌 The `ruledEnc` clause is load-bearing too, and for a different reason: it is
the §4.3′ travel condition, which this sentence broke for sixteen days by moving
into this file without it. **It travels with the sentence from here on — that is
what "ratified verbatim" bought.**
⚖️ RATIFICATION: the Captain, 2026-08-25 21:1x, on the evidence seat's fence
pass of the same evening (three findings, `saltworks 6096b30`). Authority for
the processor clauses remains `core-account.md` §3, whose authorized sentence is
the ceiling (§4.5′); authority for the fabric clause is this file's own
"WHAT IS CERTIFIED TODAY".

**Fetch protocol — the contract the RTL actually demands (refuter
correction adopted; v1's same-window proposal was arithmetically
unserviceable):** instruction word byte k is driven on ui_in during
phase (k+3) mod 4 — byte 0 LEADS its own address by one phase; the
first commit after reset executes ir=0 (undecodable → skipped,
pc→4) — documented, not repaired. And the mechanism that makes this
TRIVIAL for September: the core is closed and deterministic (no
loads, no IO, exactly 4 clocks per instruction), so the RP2040
generates the ENTIRE byte stream OFFLINE from the Lean `runW` trace —
the "handshake" reduces to a precomputed tape, bench-asserted against
`phase_o`.

## D6. PIN MAP — bit-exact

```
ui_in[7:0]   instr_byte[7:0]   in   CPU memory bus (per slicea16bma)
uo_out[7:0]  addr_byte[7:0]    out  PC bytes, 4 phases
uio[0]       phase_o[0]        out  } phase strobe
uio[1]       phase_o[1]        out  }
uio[2]       edge_in_data      in   } packet port: weights/inputs
uio[3]       edge_in_valid     in   }
uio[4]       edge_out_data     out  } packet port: results
uio[5]       edge_out_valid    out  }
uio[6]       sof               in   frame re-align (non-destructive)
uio[7]       valid             out  payload-window flag
uio_oe = 8'b1011_0011 (static; verified bit-by-bit, twice)
```
24/24 exact. **⚠️ AMENDS(veto) the Captain-ratified Option A
(§3b): the ruled third PACKET PORT ("spare/debug") becomes two
non-packet pins (sof in, valid out); fabric port 8 loses its pin
escape; and frame-phase observability NARROWS from the BB's
Captain-confirmed 4-bit non-aliasing counter + valid to valid alone
(phase recovered from valid's rising edge, which uniquely names
cycle 6 in a 14-cycle frame). VETO POINT: the Captain, at the
sitting — D10.6, per the register's Tier-1-adjacent flagging rule
(the pin pattern, 13:49).** The honest sof argument (v1's was a
non-sequitur): §5's law allows `rst_n` for alignment, but on the NDF
`rst_n` is DESTRUCTIVE — it clears the PC, the register file, and
the cell accumulators — and re-alignment must be non-destructive
once the die carries state, which the bare BB never did. Mid-run
`sof` semantics DEFINED: it re-aligns the fabric frame counter and
the sequencer's phase position; no register state is touched.
Fabric port indices FROZEN (they decide fixture-class membership):
0-3 cells · 4 edge-in · 5 edge-out · 6 CPU-client (stubbed idle) ·
7 spare (idle) — actives are the 0-5 prefix.

## D7. STATE, AREA, TILE (labels per the pass)

- Per cell: 64 state flops — BOTH banks enabled-class per the 20:1x
  D4(f) upgrade and R6 (compiler's 01:12 catch: an earlier version
  of this line said "wsh 32 plain," predating en_wsh — R6 GOVERNS,
  the plain-wsh pricing is STRUCK). Per-TYPE pricing: acc 32 ×
  ~30.0 (enable-class, core32 precedent) + wsh 32 × ~30.0
  (enable-class, same basis — NOT dfxtp_1's 20.019)
  + SER as the measured parallel-load organ 1,161.1 µm² pre-layout ⇒
  **~2.8–3.1k µm²/cell, ~11–12.3k at k=4, PRE-LAYOUT class**, plus
  the sequencer and edge-port registers, unpriced. (The 25.023/flop
  dfrtp_1 figure survives only as a method cross-check; catch #253
  noted — a 35-flop constant applied at ~11× carries no clock-tree
  term.)
- Floorplan (rebuilt — v1's band survived by two errors cancelling):
  the 71.8–76.6k µm² load is SYNTHETIC (the register's own label)
  and ALREADY CONTAINS per-cell state via the BOM it scales; new on
  top = SER (4 × 1,161.1 × 1.55–1.881 ⇒ 7.2–8.7k post-layout class)
  + the BB fabric correction (+4,159). CORRECTED LOAD 86.4–93.4k.
  Against the 6x2 CORE area 205,640 µm²: **42–45%** — at the edge of
  the measured-clean band (44.65/48.77 clean). Against the 4x2 core
  136,237 µm²: **63–69%** — deep in the unmeasured band; the €280
  question tilts toward 6x2 harder than v1 said. 6x2 @ €840 stands;
  the settling run still decides.
- DRV debt (corrected): the real-die numbers are 2,019 max-slew @ss
  / 854 @tt (the 1,678 was free-floorplan; the drift is
  UNFAVORABLE ~+20%), and they are RESIDUAL VIOLATIONS after the
  resizer — a signoff-closure debt, not a pending area increment.

**THE NAMED LONGEST-PATH CANDIDATE (the Captain's 20:0x synchrony
question surfaced it): cell-to-cell same-cycle transport — SER flop
(cell 0) → 3 combinational fabric stages → cell 1's x input → AND
row → XOR bank → 32-stage ripple → acc flop. The fabric is
combinational end-to-end (a bit presented at cycle t LEAVES at
cycle t), so this register-to-register path spans the die and
EXCEEDS the measured cell-internal 50.939 ns worst path by the
fabric's levels + wire. The floorplan run measures it FIRST. The
named escape if it fails at 55: ONE port register per fabric port —
a single pipeline cycle that shifts the receive window by a
compile-time constant in the timetable; determinism unchanged, no
protocol change.**

## D8. CLOCK — the pair, with the fresh measurement

`config.json CLOCK_PERIOD: 55` + `info.yaml clock_hz: 18181818`
(1e9/18181818 = 55.00000055 ns; the FLOOR is chosen deliberately —
the ceiling 18181819 would declare 54.999997 ns, faster than the
signed-off period). BASIS, now labeled correctly AND current:
**MEASURED ON THE SIGNED ARTIFACT 19:34** — controlled pair, one
die: unsigned +2.0831 / signed +1.1123 ns at the slow corner, both
close at 55. "52 does not close (−0.94)" remains an ESTIMATE
(extrapolated from the unsigned 55 ns run). The stale "20 MHz"
literal in the QUEUE's agreement clause dies at this block's
adoption. THE CHECK (self-refutation repaired): a float-equality
test would REJECT the correct pair — the added validate.py check is
a rounding law, `clock_hz == floor(1e9 / CLOCK_PERIOD)`, and
core-account's "must equal" is amended in the same commit; negative
control: a mismatched pair must FAIL.

## D9. VERIFICATION OBLIGATIONS

| # | obligation | status |
|---|---|---|
| V1 | instOK per placed organ | pattern landed |
| V2 | ONE coverage/disjointness theorem, whole die | pattern landed |
| V3 | seam theorem per wire class | pattern landed |
| V4 | routing certificates: `fabric_routes` LANDED for prefix-concentrated destination-monotone at P=8; the demo's own rounds = V10; completeness gate `mem_allScenarios` stated-unproved | restated |
| V5 | signed activation discipline (explicit wordSignedOrder) | law landed |
| V6 | ∀ st₀ power-gating for all new state (acc CLEAR discharges the acc bank's) | pattern landed |
| V7 | emitSeq acceptance: flops==nState(64) · cells==gates+nState(289) · conb==const-count(0 for scCore by theorem) · assigns==outs(96) | NEW |
| V8 | overflow at int8: shiftSafe_at_int8_scale + noOverflowFrom per network (compiler's schedule rows) | landed + duty |
| V9 | the SHELL's kernel model: enable/clear-aware Seq form + refinement to scellSeq's per-input shape | NEW, compiler |
| V10 | PER-ROUND schedule fixtures (one-hot payloads) for every demo round | NEW |
| F3 | chip-level "down to silicon" clears ONLY at the run on THIS top module, scope named | stands |

## D10. FOR THE SITTING

1. **D3 staging** — per-round fixtures now + Batcher-seam v1.1 (my
   recommendation, restated at the theorems' size) vs assemble-now.
2. **Drive strength** — combinational `_1` vs `_2` still OPEN (the
   TT-CI green covers no sequential cell); for FLOPS the evidence is
   one-sided toward `_2` (dfxtp_1 on no_synth.cells:152).
3. ~~XOR-bank shape~~ — answered at the landing (§D4a).
4. **Fetch contract** — ratify the tape contract (byte k at phase
   (k+3) mod 4, reset quirk documented, offline stream from the
   Lean trace).
5. **CPU role** — three options now: (i) RP2040-mediated (outside
   verified surface), (ii) B-ISA SW + port organ (v1.1 scope),
   (iii) PC-address-decode strobes (~10 gates on addr_byte+phase_o,
   no ISA change, OPEN-LOOP only). September default = demonstrate,
   not conduct; his call.
6. **⚠️ THE PIN AMENDMENT (veto)** — D6's sof+valid spend of the
   ruled third packet port + the observability narrowing. His word.
7. **The shell ratification** — acc CLEAR + ENABLE as new silicon
   with a kernel model owed (V9); the alternative (no clear = no
   bias path and no ∀st₀ discharge) is not viable; ratify the
   mechanism and its owner (compiler).

**On adoption: compiler — emitSeq + the shell kernel model (V9) +
SER/activation Circ + per-round fixtures (V10) + glue objects
(V1-V3, V7); silicon — the settling run on the emitted composition,
then the 6x2 floorplan; math — standing refutation + the signed
trace item ② in flight; evidence — the demo sentence's fence pass
BEFORE the sitting + F3 scope at the run. Anchor ~Sept 7, soft by
one shuttle; reservation at layout-readiness.**

🧂⚓
