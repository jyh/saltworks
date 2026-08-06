# LEG 3 DESIGN FREEZE v1 — the silicon chain (seat: jason)
### 2026-08-06, Fable (Sancho). STATUS: frozen pending the seat's own
### refuter pass (FIRST act). Governing dossiers:
### salt/docs/exploration/{vlsi-flow,batcher,core-scope}-scout-dossier-0805.md

## The chain (the demo)
  banyan_selfrouting [LANDED, 3 axioms]
    → the fabric as leg 2's Circ (their T4)
    → emitV (untrusted) → Verilog
    → LibreLane (Nix, macOS ARM native; pin the version) → GDSII
      + runs/RUN_*/final/nl/<design>.logical_nl.v
    → THE IMPORTER [TRUSTED, ≤300 ln]: flat structural Verilog →
      Lean netlist over Bool nets, + ~30 one-line sky130 cell models
    → EQUIVALENCE, per module, by `decide +kernel` (≤16 input bits
      per module — the comparator cell is 16; the fabric composes
      at the BitVec level per the measured compositional law)
    → #audit_axioms: THREE AXIOMS END TO END. That is the headline.

## Deliverables in order (each independently shippable)
  D1 LibreLane up via Nix; the comparator cell through the flow;
     hardware.log of versions pinned in docs/
  D2 the importer + cell models (THE real work, 2-3 days priced) +
     mutation tests: inject netlist faults, PROVE the checker sees
     them (the credibility move)
  D3 comparator: end-to-end equivalence, kernel-checked
  D4 the fabric (2 tiles ≈ 1299 gates): per-module equivalence +
     composition; GDSII produced
  D5 TinyTapeout TTSKY26c packaging (deadline SEPT 7, €185; JYH-ruled
     GO 8/6). TT tile template, pinout doc, submission checklist —
     the human clicks, we prepare everything
  D6 [stretch] the RISC-V DATAPATH (never say "core"): ALU + regfile
     + 3-5 instr single-cycle, hand-written Lean spec; bv_decide only
     as dev accelerant; certificate story per the ruled scoping

## Cautions (from the dossiers, verbatim discipline)
- macOS/Linux non-determinism (LibreLane #522): develop on Mac, final
  pass on Linux before ANY published number or tapeout. Plan a Linux
  runner (cloud or CI) in week 2.
- Monolithic gate proofs die ~1300 gates (elaboration): per-module
  always.
- The 6-min 2^16 target is a bad CI citizen: slow target, or pairwise.
- bv_decide adds an axiom — dev tool only (JYH ruling 8/6).

## Files: SaltWorks/Silicon/{Cells,Importer,Equiv,Mutations,Flow-docs}
## Refuter kill-checks for your opening pass
R1 the importer grammar: is post-P&R logical_nl.v really flat
   structural (no behavioral leakage)? Get a REAL sample in D1 before
   freezing the parser.
R2 the cell models: which sky130_fd_sc_hd cells does synthesis of OUR
   design actually use? Model those ~30, not the library.
R3 the seam with leg 2's emitN (their doc R2 — agree the interface).
R4 the tile constraint: 1299 gates vs 1000/tile — 2 tiles OK, but
   check TT's 8-in/8-out pinout against an 8x8 fabric's port count;
   if it doesn't fit, WHAT scaled fabric fits the pins? (4x4?) This
   determines the taped-out N. Answer BEFORE D4.

## ADDENDUM 1 (Council I discussion, 8/6) — BIT-SERIAL RULED (JYH)

**The tapeout target is the BIT-SERIAL fabric, per the 1988 design:
packets are bit streams, address at the front, MSB first.** Not
nostalgia — FORCED: TT's 8in/8out cannot carry a word-parallel 8×8
fabric (64+ pins); bit-serial fits the tile exactly (8 serial in,
8 serial out, clk from TT). This ANSWERS kill-check R4.

**The two-layer proof architecture:**
- Layer 1 (LANDED): `banyan_selfrouting` — routing/topology level,
  representation-independent.
- Layer 2 (NEW deliverable, insert as D3.5): the bit-serial 2×2
  switch element as a small FSM (routing latch set by the address
  bit + conflict logic + transparent streaming), PROVED to refine
  the word-level `line` semantics: per-cycle obligation by
  decide +kernel, lifted by induction over cycles (the measured
  sequential pattern from the vlsi-flow dossier §A). FSM state is a
  few bits — comfortably inside the 16-bit module law.

**The resonance (README material):** the landed proof's DESCENDING
stage index consumes destination bit m at the stage with m bits
unrouted — the FIRST stage reads the MSB. That is exactly the serial
wire order: the 1988 frame format and the 2026 proof index agree by
construction. Also the 3D-stacking pinout rationale of US4910730A is
the same pin-economy argument TT forces today.

**Consequence for the HDL leg:** combinational-first stands; ADD a
minimal sequential extension (registers + a cycle semantics) scoped
to what the switch-element FSM needs — agree the shape with the
Silicon seat on the bus BEFORE building (the seam rule applies).
