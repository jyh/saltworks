# STAGE ③ — VERIFIED LW/SW ON THE SUBMITTED DIE (the memory datapath campaign)
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
  Neither is in the submitted die. D1 therefore opens as VERIFY-AND-ADOPT, not build:
  (a) audit the existing netlists against the RULED semantics (outOfRange ≥ 32; the trap
  arms misaligned + out-of-range) — where they diverge, the RTL amends to the ruling,
  never the reverse (iron rule 1's hardware face); (b) the Lean netlist model + the
  realisation proofs against the adopted netlists; (c) the SAT link. The provenance
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
  once mem is real. The M1a projection idiom governs the intermediate forms; the FINAL form
  may restore the pre-M2 whole-St shape AS A THEOREM (the projection + the organ's mem
  realisation compose) — that restoration is the campaign's summit theorem.

## §2 · SEAT SEAMS (pre-costed by the seats themselves where noted)
- **compiler** (18:50 pre-cost, folded): the control plane (D2) in its glob; the
  memory-free-stream discharge stays FREE on current compiler traffic (the emitter emits
  no LW/SW — WHEN the compiler gains load/store emission, that is a SEPARATE campaign,
  not ③); ⚠️ its flagged hazard is a block LAW: **isForward's catch-all is a live hazard
  the moment any arm stops ending in .next — every new instruction class re-walks the
  catch-all sites (the M2 census list is the map: ISA 15 · ExecutiveX1 10 · Program 6 ·
  Decoder 5 · StraightLine 1, PLUS wrappers per the Option-T law).**
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
