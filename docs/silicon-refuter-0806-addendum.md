# LEG 3 REFUTER PASS — ADDENDUM: the re-dispatched lanes
### 2026-08-06, seat: jason (Silicon). Companion to `docs/silicon-refuter-0806.md`.
### Four web/read-only lanes, re-dispatched after the third fleet OOM cancelled
### the first workflow. 58 findings, every one adversarially verified, none
### withdrawn. **Several refute the main document, and one refutes something I
### had already posted to the fleet bus as established fact.**

---

## 0. THE CORRECTIONS I OWE — things I asserted that are FALSE

These are first, and separately, because I stated them publicly and other seats
may have acted on them.

### ✗ C1. "Every sky130 cell declares exactly VPWR/VGND/VPB/VNB, so the powered netlist adds exactly four pins per instance for the importer to discard."

**FALSE.** Stated in the main refuter doc, in `Cells/Sky130.lean`'s module
docstring, in `Flow-docs/hardware-versions.md`, and on FLEET.md at 09:31.
Three independent lanes refuted it against real artifacts:

- `sky130_fd_sc_hd__tapvpwrvgnd_1` carries **exactly two** connections
  (`.VGND`, `.VPWR`) and appears **225–456 times in every real TT netlist**.
- It is **not in the Liberty file at all** — which is precisely why my
  Liberty-derived survey could not have seen it. `fill_1`, `fill_2` likewise.
- 23 of the 428 cells violate the four-pin rule, and they are concentrated in
  the `lpflow` family — the same family `abc` already reached for.
- The vendor *blackbox Verilog* declares all four for `tapvpwrvgnd_1`, so a
  parser validating arity against the Verilog **also** breaks on every tap cell.

**Corrected rule:** discard any connection whose pin name is in
`{VPWR, VGND, VPB, VNB}`; assert **nothing** about how many appear. And the
cell-model generator cannot be Liberty-only: "absent from Liberty ⇒ error" is
wrong, because the three highest-count cells in a real netlist are absent from
Liberty by design.

**Root cause, worth naming:** I generalised from a Liberty survey to a claim
about *netlists*. Liberty describes cells that have logic; a netlist also
contains cells that do not. The survey could not have falsified the claim it
was used to support.

### ✗ C2. "Post-synthesis grammar carries over: zero `assign`, zero constants, zero escaped identifiers."

**FALSE for the artifact that matters.** My sample was post-*synthesis* of RTL
with flat, one-word net names. Measured across 14 genuine powered
`tt_submission/<top>.v` files:

- **`assign` statements appear in every one** (18–22 each), always of the form
  `assign <vector_port>[<i>] = <scalar_net>;` in a tail block after the instances.
- **Escaped identifiers appear in 13 of 14**, up to **1,573** occurrences, and
  they embed `.`, `[`, and `]`.
- Constants reach the design only through `conb_1` **tie cells** — so there are
  no numeric literals, but there *is* a cell whose meaning is a constant.

**And one of these is a soundness bug, not a parse failure.** An escaped
identifier terminates on **whitespace**: `\cnt[0] ` is an *atomic scalar net*,
not bit 0 of a vector `cnt`. A parser that strips the backslash and then treats
`[0]` as a bit-select **aliases distinct nets onto one** — it will happily prove
a netlist equivalent to a design it does not implement. The lane demonstrated
this concretely: a whitespace-terminated tokenizer finds *no* unescaped
bit-selects on non-port bases, while a regex that ignores the backslash invents
a dozen phantom vectors.

**Corrected rule:** on `\`, consume to the next whitespace; that text *is* the
net's identity and is **never decomposed**. `name[i]` is a bit-select only when
unescaped, and then `name` must be a declared vector port — enforce that, it is
free, and it converts the hazard into a checked obligation.

### ✗ C3. "The 13-cell set, and `dfxtp_1` is our flop."

**Mostly the wrong cells.** LibreLane's sky130A defaults exclude far more than I
assumed (`no_synth.cells`: 185 entries — all `clkbuf_*`/`clkinv_*`, all latches,
all scan flops, decap, diode). **Eight of the nine cells I named are excluded by
those defaults and appear in none of 118 real TTSKY26c netlists** — including
`clkinv_1`, which was 9 of my 36 instances.

Conversely, post-P&R contains cells **no synthesis run will ever show**:
`clkbuf_16/8/4/2` (CTS), `clkdlybuf4s25_1` and `dlygate4sd3_1` (hold repair),
`diode_2` (antenna), plus the physical `fill_*`/`decap_*`/`tapvpwrvgnd_1`.

And **the flop is `dfrtp_2`** — CLK, D, **RESET_B**, Q: an *asynchronous,
active-low-reset* flop — not `dfxtp_1`. My note that "yosys chose `dfxtp_1`,
which has no reset pin, so reset folded into the D path" is an artifact of bare
yosys without the TT flow, and the HDL seat's proposed shared normal form
inherits the same error.

Real distinct-logic-cell counts: 9–11 types for designs our size, 64 for a
1,748-cell design; median ~53 across TT projects. So the trusted-model budget is
**2–4× my figure**, though still far below 428.

### ✗ C4. "Pin the PDK to `0536d02d…`."

**Wrong pin.** `0536d02d…` is the **precheck-only** PDK. The netlist and GDS are
hardened against **`8afc8346a57fe1ab7934ba5a6056ea8b43078e71`**. There are four
sky130A revisions in play. My `Flow/synth.sh` additionally hard-codes
`c6d73a35…` (volare's newest) as its default, which is a third value.

### ✗ C5. "CONFIRMED: the resonance claim is true."

**Confirmed about the wrong constant.** `Facade.lean`'s `testBit_step` is stated
over `ProbeFacade.line` — a *duplicate* definition in a *duplicate* namespace —
not over `SaltWorks.Banyan.line`. The bodies are identical, so the mathematics is
untouched and the claim is true of the copy. But as a statement about *the landed
proof* it does not yet typecheck, and it is headed for a README. The bridge must
be stated over the real constant.

---

## 1. WHAT SURVIVED, AND WHAT WAS WON

The lane that hunted a real artifact **discharged D1's blocking exit criterion**:
nine genuine powered post-P&R sky130 netlists are now on disk, three of them
built by `librelane 3.0.5` for TTSKY26c itself. The provenance is pinned to a
line of code — `tt-support-tools/project.py:575-611` copies
`runs/wokwi/final/pnl/<top>.pnl.v` to `tt_submission/<top>.v` — so the freeze's
`final/nl/<design>.logical_nl.v` is wrong in **both** directory and suffix
(`nl` is the *unpowered* netlist; ours is `pnl`).

Confirmed true across 14 files rather than one: **no compiler directives, no
comments, no numeric literals, no positional connections, no vector `wire`
declarations, no behavioral constructs, ever.** A complete character-level
tokenizer plus recursive-descent reader of this exact grammar measured **144
non-blank lines** and parsed all 14 to EOF with zero residue — so the ≤300-line
trusted-parser budget survives, provided the parser stays a pure syntax layer.

Two findings make the chain *stronger* than I argued:

- **The mandatory gate-level cocotb test consumes byte-for-byte the same file
  we prove.** Two independent methods, one artifact, no seam between them.
- **`RUN_EQY` already exists in LibreLane 3.0.5** — a formal RTL-vs-netlist
  equivalence step supporting sky130A, gated by one boolean defaulting to false.
  A free, independent, formal cross-check nobody had switched on.
- **"Small by construction" is available.** `user_config.json` overrides only
  seven keys for sky130A, so every other key in `src/config.json` survives the
  merge — including the cell-exclusion knobs
  (`SYNTH_EXCLUDED_CELL_FILE`, `PNR_EXCLUDED_CELL_FILE`, `EXTRA_EXCLUDED_CELLS`).

---

## 2. THE FINDINGS THAT CHANGE THE PLAN

**The bit-slicing wall moved; it did not vanish (O5, S7).** My F5 reported a time
result and did not publish the new law. Sliced cost is **memory**:
≈ `#nets × 2^(n−3)` bytes. My headline datum (24 bits, 60 gates) is ~192 MiB —
comfortable — but the *monolithic* 8×8 serial fabric is 8 primary inputs plus
12 elements × ~3 state bits ≈ **44 bits ≈ 2 TB**. So bit-slicing does **not**
rescue a monolithic fabric proof; per-module equivalence plus *structural*
composition remains mandatory, exactly as the landed routing theorem is
structural. **The memory law must be published beside the time law.**

**D4's composition is priced with a banned tactic (O6).** "The fabric composes at
the BitVec level per the measured compositional law" cites dossier numbers that
were **all** `bv_decide`. There is no `decide +kernel` measurement of composition.

**D3.5's justification is likewise a banned tactic (S6).** ADDENDUM 1 grounds the
FSM plan in "the measured sequential pattern from the vlsi-flow dossier §A" —
whose sequential pattern is `bv_decide` discharging the one-cycle obligation.

**The ordering is wrong at the front (O7).** D5 (TinyTapeout packaging) is fifth
but contains the only lead-time-limited item (tile purchase, inventory
constrained, both preceding sky130 shuttles closed at 512/512) *and* the source
of the artifact D1/D2 are blocked on. It must move first.

**Nine pieces of real work belong to nobody, and one is missing entirely (O10):
the serial frame protocol.** Nothing anywhere specifies how the 8 serial streams
are delimited, when the routing latch clears, or what the 8 spare `uio` pins do.
That document is a prerequisite for D3.5, not a detail of it.

**Hold, not setup, is the timing risk (O13).** "96 cells, nowhere near
timing-critical" is a setup-only statement; lowering the clock does not fix a
hold violation, and LibreLane hard-fails hold violations on all corners.

**The trusted base has a four-valued layer nobody has modelled (O4, C11).** The
vendor Verilog wraps **every** cell in a `udp_pwrgood_pp$PG` primitive
parameterised by VPWR/VGND. Our two-valued Liberty-derived models are correct
only under an unstated "power rail is good" hypothesis. That hypothesis should be
written down rather than left implicit.

**The cell cross-check is vacuous for 5 of 13 cells (O3)** — including the
flip-flop, the one sequential cell the tapeout depends on. Where the readable
model and the Liberty string are syntactically the same expression, "a slip must
be made twice in two notations" is not true; it was made once and copied. Those
five need a genuinely independent second source.

---

## 3. THE TWO HONESTY FINDINGS

**"THREE AXIOMS END TO END" is false as written, and the words that break it are
"END TO END" (O1).** An axiom audit is a statement about *proofs*, not about the
chip, and it is **invariant** under every failure mode that actually threatens
this campaign: import the wrong file, mis-parse a port, mis-model a cell — the
audit still prints three axioms. The headline must say what the audit covers and
what it cannot.

**The chip cannot exhibit its own theorem's hypothesis (O17, O18, and the R3
verifier's headline miss).** `banyan_selfrouting` is conditional on destinations
being sorted, distinct, and concentrated. The Batcher sorter that would produce
them is being built neither in Lean nor in silicon. So the taped-out part is a
router that routes correctly **only if something off-chip pre-sorts its input**.

This is not a defect — it is *exactly* the 1988 two-chip partition, and taping
out chip 2 (the proved half) was the plan. But it must be said in the README in
one plain sentence, because a reader of the name "banyan_selfrouting" believes an
8×8 network delivers every packet without collision, and what is proved is that
an arithmetic function on ℕ is injective. There is no network, no switch, no
packet, and no time in the statement.

---

## 4. WHAT I AM DOING NEXT

Applied immediately (this commit): the five corrections in §0, to the main
refuter doc, `Cells/Sky130.lean`, `Flow-docs/hardware-versions.md`, and the bus.

Ordered next, revised by these findings:

1. **Publish the memory law** beside the time law, and re-state F5 honestly.
2. **Re-derive the cell set** against the real corpus and TT's actual config —
   not against bare yosys — and switch on `EXTRA_EXCLUDED_CELLS` so the trusted
   set is small by construction. Model `dfrtp_2`, not `dfxtp_1`.
3. **Write the importer against the real grammar**: whitespace-terminated escaped
   identifiers, the `assign` tail block, omitted pins, tie cells, and a
   pin-name-based PG discard with no arity assumption.
4. **Write the serial frame protocol document** — it blocks D3.5.
5. **Switch on `RUN_EQY`** — a free formal cross-check.
6. Ask the maestro for a writer slot for the shared netlist type (§S1), and for
   the hub imports already owed.
