# BB-1 — THE COMPOSED SWITCH (Batcher + banyan, one tile)
### Addendum to leg 3, drafted 8/7 on the Captain's word ("we have a lot
### of space — could we put a Batcher on the same tile?" → "woohoo").
### DRAFT-UNTIL-REFUTED. Never displaces the CPU campaign — rides beside.

## Objective
Add an 8×8 Batcher odd-even merge network (19 compare-exchange elements,
6 stages) upstream of the landed banyan on the SAME tile, and upgrade
the tile's theorem from conditional to ENTIRE:

> **the composed-switch theorem**: for arbitrary inputs with distinct
> destinations, every packet arrives on the wire its address names —
> `batcher_sorts ∘ banyan_selfrouting`, the sortedness hypothesis
> DISCHARGED BY HARDWARE. The full 1990 system claim, kernel-checked.

## Why it is cheap (everything is on the shelf)
- Element: bit-serial compare-exchange judging destination fields
  MSB-first as they stream — **the element of US 5,130,976** (the
  Captain's patent), provable by the landed SwitchRefinement pattern
  (FSM refines word semantics; per-cycle decide; cycle induction).
- Comparator core: ComparatorEquiv (D1/D3) already kernel-checked
  through the flow.
- Composition: the D4 pattern verbatim at 19 elements instead of 12.
- Spec layer: math's S3a (`Stack/ZeroOne.lean` + Batcher merge, IN
  FLIGHT for the software application) doubles as the hardware spec —
  one proof, two lanes.
- Area: ~1.6× the current fabric; the tile is mostly vacancy. Pins:
  UNCHANGED (sort→route pipelines behind the same 8-in/8-out; spare
  uio pins may expose a bypass/test mode).

## Deliverables
- **B0 — THE PROBE (fired 8/7)**: composition-checked feasibility —
  (a) the serial compare-exchange element in Circ: design sketch +
  the refinement statement ELABORATES; (b) the composed-switch theorem
  STATEMENT elaborates against the landed banyan theorem's actual
  hypotheses (name the exact sortedness/concentration form needed vs
  what batcher_sorts provides — the seam, composition-checked, C0
  doctrine); (c) area/pins through the flow at estimate grade;
  (d) the test-mode question (bypass worth its pins?).
- **B1** — the element: Circ FSM + refinement proof (compiler builds,
  silicon proves — the SwitchRefinement pattern).
- **B2** — the network: 19 elements assembled in Circ; batcher_sorts
  at the network level (math's abstract merge theorem instantiated).
- **B3** — the composed tile: Batcher→banyan in Circ; emit through the
  landed chain; TT CI green on the revision branch.
- **B4** — the composed-switch theorem end-to-end on the re-imported
  netlist (the D4 ceremony at 31 elements total).
- **B5** — THE REVISION: resubmitted to TTSKY26c before Sept 7 close.
  The banyan-only submission (the Captain's checkout, TODAY) stays the
  floor — if BB-1 slips, the proven banyan flies alone. The revision
  replaces it ONLY when CI is green and B4 is in the kernel.

## Kill-checks
- **KB1** Does the composed statement typecheck against the LANDED
  banyan theorem, or does the sortedness form mismatch (Perm vs Sorted
  vs concentrated — the exact seam)? Composition-check FIRST.
- **KB2** The serial element's latency: Batcher stages add pipeline
  depth — does the frame format (address MSB first) survive 6 more
  stages of skew? (The 1990 answer: pipelining per stage — verify ours.)
- **KB3** Duplicates: the composed claim needs DISTINCT destinations;
  state the exclusion explicitly (Chet's-loop territory stays future).
- **KB4** CI budget: the revision's gds/precheck must pass with ~2.6×
  logic — no reason to fail, but measured not assumed.

## Sequencing / cost honesty
B0 probe: one seat-session, queued behind current work (silicon: cone
census first; compiler: SAIL + C4 check first). B1–B4: a few
fleet-days beside the CPU campaign, never ahead of it. B5 any time
before Sept 7. Estimated total ≈ the D4 arc re-run at known pattern —
the discovery is already paid for.
