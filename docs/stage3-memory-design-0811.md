# STAGE ③ — OBJECTIVE: LW/SW HARDWARE ON THE SEPT-7 DIE, VERIFIED BEFORE THE CLICK
**STATE: NOT ON THE SUBMITTED DIE — measured, the 446-line wrapper carries
ZERO dmem8 and ZERO memif. This block is a campaign, not a report.**
**Maestro (Fable), 2026-08-11 evening, at the Captain's word: "I have no doubt that we can
hit verified lw/sw in this submission if we keep at it." DRAFT-UNTIL-REFUTED: the refuter
pass fires before any executor pulls. Governing inheritance: memory-design v1.5.1+
(dmem_addr8 ruled · kernel outOfRange ≥ 32 from M1) · M2's four rulings (touchesMem frame
laws · the (regs,pc) projection · the control-plane guard theorem · the memory-free-stream
hypothesis) · the fabbed-is-verified law (the UPDATE is a submission; full ritual before
any click; THE CLICK IS THE CAPTAIN'S, Tier-1).**

## §0 · THE PRIZE AND THE CLOCK
Verified load/store hardware on the SUBMITTED NDF die via the shuttle update window
(closes 2026-09-07 13:00 PDT — 27 days). The ISA/proof half LANDED 8/11 (M2 acd3982 +
M4 ac3bf77, MEAS-witnessed; certs sealed). The die's real estate is measured: logic
occupies x ∈ [1.2%, 51.0%] of the tile; ~49% free (tonight's GDS census, 5,722 logic
cells vs 47,438 filler). If the window is missed: ③ ships next shuttle, nothing wasted.

## §1 · THE THREE DOORS AS ONE CAMPAIGN (today's rulings made them; this block opens them)
- **D1 — THE DMEM8 ORGAN**: the physical 8-word×32-bit memory (per dmem_addr8: onboard,
  kernel outOfRange ≥ 32 semantics from M1). ⭐ PRICE DROP (silicon 18:52, pre-hardening):
  BOTH organs already exist as synthesised netlists from the untaped RISC-V work — dmem8
  (673 cells / 256 flops = the full 8×32 bit array) and memif (182 cells, combinational).
  Neither is in the submitted die. D1 SPLITS IN THREE [math⊕silicon synthesis, 19:10 — "the RTL" was ambiguous
  and the ruled module is UNWRITTEN]: **D1a — THE STORAGE ARRAY** (the shelf dmem8
  netlist, 673c/256f): verify-and-adopt as pure storage, exactly as re-scoped below.
  **D1b — dmem_addr8 ITSELF**: unwritten but NOT UNDESIGNED [AMENDED at math's
  19:34 self-correction of the synthesis this clause folded — "AUTHOR" overpriced it
  by a module]: `dmem_addr16.v` EXISTS, designed AND priced (b494a67, Aug 8 — 14
  cells · 83.83 µm² · zero sequential), its header (lines 8–18) already carrying the
  trap-in-the-address-path reasoning from Aug 8. D1b is a WIDTH EDIT (two bit-ranges:
  `[31:6]`→`[31:5]`, `[5:2]`→`[4:2]`), VERIFIED against the RULED semantics (kernel
  outOfRange ≥ 32 from M1) — never against the sibling's own width, so the edit cannot
  silently inherit a 16-word bound — and never reverse-engineered from the shelf
  array; the two trap bits live in its MASK, not the array. Silicon's law rides:
  UNWRITTEN IS NOT UNDESIGNED — open the sibling before pricing the commission. **D1t — THE
  ADDRESS CHECKER** as minted below. Verify-and-adopt applies to D1a ONLY. Original
  re-scope follows — RE-SCOPED at silicon's
  refuter finding (18:55, against the clause its own price-drop created): dmem8's address
  port is 3 BITS and it carries ZERO trap logic — there is nothing to audit against the
  trap semantics, and that is the ARCHITECTURE, not a defect. The organ is PURE STORAGE
  (word-addressed 0..7), adopted as-is; the kernel's step semantics are realised by a
  COMPOSITION [AMENDED at silicon's 10:27 8/12 finding — the original text here
  commissioned the address-path HARDWARE under the id D1t, and the 19:34 re-price then
  gave the SAME hardware to D1b, orphaning this clause's name onto a second phantom
  module]: the address-path hardware is **D1b — dmem_addr8, ONE module**: byte-address
  in, the TWO trap causes as separate hardware facts (misaligned = low bits ≠ 0 ·
  outOfRange = byte addr ≥ 32) carried in its MASK, word-address out to the organ only
  when clean — arm-for-arm matched to the ruled step semantics at the CHECKER⊕ORGAN
  composition, never inside the organ. **D1t IS THE INSTRUMENT, not hardware**: the
  acceptance checker + its PRE-REGISTERED bar (planted failures, runner exit = the
  gate; delivered d96de83, cleared 7/7 independently). Both objects exist; no third
  module is owed; (b) the Lean netlist model + the
  realisation proofs against the adopted netlists — TRAP-ARM PHRASING per math's refuter
  (repair-then-fire): the two trap causes (misaligned · outOfRange ≥ 32) stated as
  SEPARATE kernel facts matched arm-for-arm to the ruled step semantics, never folded
  into one disjunction the organ cannot distinguish; (c) the SAT link. The provenance
  fence rides: adopted netlists are HAND-RTL-era artifacts until their emission lineage
  is established — Fig-3's provenance coloring and §4's grades state whichever is true.
- **D2 — THE MEMORY CONTROL PLANE**: decode rows for LW/SW opcodes + the new control bits
  + the memory port on the core. RETIRES the guard theorem's deliberate absence — that
  retirement is a STATEMENT EVENT: ctrlSpec's arms change meaning, so the guard theorem
  (ctrlSpec_not_decoded_of_touchesMem) is REPLACED by the positive decode rows, and the
  docstring's slice-A scope re-cuts to the grown vocabulary. Owner glob: compiler's
  (its 18:50 claim stands). The datapath change re-prices timing/area — silicon re-runs
  the hardening numbers; NO published figure survives the change unre-measured.
- **D3 — THE N-STEP BRIDGE**: organ + core joined so cycles_realise_steps discharges for
  memory-bearing streams — the C4 projection (M2's form) EXTENDS to a whole-St realisation
  once mem is real. The M1a projection idiom governs the intermediate forms. THE SUMMIT
  THEOREM [REPAIRED at math's refuter finding, 18:53]: stated over the PAIR — core codec
  ⊕ organ state — which IS §0.2's two-object bridge. decQ is structurally 1056-bit
  (regs+pc; mem literally zeroed, rfl-proved in M4); the pre-M2 sentence over decQ would
  need the 1313-bit codec §0.2 REJECTED BY NAME. The width is earned OVER A DIFFERENT
  OBJECT, and the summit carries a NEW NAME so no pre-M2 citation silently resolves to a
  different theorem.

## §2 · SEAT SEAMS (pre-costed by the seats themselves where noted)
- **compiler** (18:50 pre-cost, folded): the control plane (D2) in its glob; the
  memory-free-stream discharge stays FREE on current compiler traffic (the emitter emits
  no LW/SW — WHEN the compiler gains load/store emission, that is a SEPARATE campaign,
  not ③); ⚠️ its flagged hazard is a block LAW: **isForward's catch-all is a live hazard
  the moment any arm stops ending in .next — every new instruction class re-walks the
  CATCH-ALL sites — and the map is a CATCH-ALL CENSUS, not the M2 arm counts [compiler's
  refuter finding 18:53: arms and catch-alls are different objects — ExecutiveX1 has
  7-10 arms and ZERO catch-alls; StraightLine has ONE arm and IS the hazard]; the census
  re-runs at D2's opening, keyed on `| _` incl. multi-argument forms, plus wrappers per
  the Option-T law. AND THE EXHAUSTIVENESS LAW — RATIFIED BY THE CAPTAIN AT EVENING
  COUNCIL 19:0x: EXHAUSTIVE ARMS ARE PREFERRED IN ALL CASES, catch-alls only where
  enumeration is genuinely IMPRACTICAL, and there the FENCE THEOREM is the required
  floor AND a census row (an uncounted fence recreates the silent class one level up).
  A new constructor fails to compile at the classification site — the failure surfaces
  where the bug is. Disposition of the known sites: branchIsForward → exhaustive NOW
  (math's slot, tonight); isForward + the StraightLine site → exhaustive AT THE ③ PULL
  (the pre-granted files open then; zero extra churn); touchesMem already fenced by the
  frame laws (math's control run) and converts on next touch.**
- **silicon**: D1's RTL/hardening lane + the re-hardening runs (Linux CI path per #522's
  own finding: the submitted-die provenance standard) + MEAS throughout. Its relight
  REMAINS PENDING at its own seam (~17h) — the ③ sprint is the natural fresh-head start.
- **math**: D1's realisation proofs + D3's bridge theorems (the M2/M4 hand is the warm
  hand); the mutation discipline per M4's own standard (address mutants incl. the rs1=x0
  class it caught today).
- **evidence**: the fence rides every landing; cert updates ride the statement events
  (the cert canary array WILL fire on D2's re-cuts — that firing is the system working,
  budget it, don't fight it).
- **maestro**: root wires · the refuter pass · the summit-theorem statement (iron rule 1)
  · the resubmission ritual assembly for the Captain's click.

## §3 · THE RITUAL BEFORE ANY CLICK (fabbed-is-verified, applied to the update)
Full kernel build green both repos · every new/changed theorem axiom-audited · SAT links
re-run on the changed Verilog · TT CI (Linux) green on the updated repo · hardening
numbers re-measured and re-fenced (the old figures DIE with the datapath change) · MEAS
independent witness on every landing · the cert layer current (the canary array green
again after the D2 re-cuts) · gate-level tests against the kernel runW traces for
memory-bearing programs. THEN the assembled resubmission surface goes to the Captain.

## §4 · ENTRY CRITERIA + OPENING ORDER
The block is REFUTER-PASSED before executors (the verify-posture law; refuters assigned
at morning council). Opening order at ratification: D1-model+D2-decode in parallel
(different files, different globs) → D1-realisation → D3. The window math reviews at
every council; the NO-GO line (ship next shuttle instead) is the Captain's call any day.
