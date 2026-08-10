# AIM-HIGH BLOCK ③ — THE SIGNIFICANT APPLICATION (v1)

**Maestro draft (Fable hand), 2026-08-10, for the 16:00 council. Feeds the
Captain's push ③: "a SIGNIFICANT APPLICATION." His inputs on record: the GNN
compiler is one named option (8/9 03:0x pull: differentiability the hard
requirement); "or mysql or something :)" = a recognizable-app direction;
self-hosting = principle-flavor, not-necessarily-compelling. ★ NEW T1 INPUT
(8/10 11:4x, his hand, this sitting): "on your GNN-compiler idea, if we did
that we should compile GRAPHCAST as the demo app (arXiv 2212.12794) — again
self-referential, but a really good example." Recon basis:
${SEAT_DIR}/briefs/2026-08-10-aim-high-trio-recon.json (application section).
Refuter pass owed BEFORE council consumption.**

## §A · REFUTER-PASS AMENDMENTS (v1.1, 12:1x — one FATAL repaired by rescoping A4; the wave fires on THIS section where it conflicts with the body)

- **C1 · The envelope arithmetic is REPLACED (r-envelope).** The imported
  "~170 cycles/neuron" is the fan-in-2 case ONLY; the true form is
  **49 + 40n cycles at fan-in n, with n = 2(1+deg) at 2-dim state — a
  NODE is TWO neurons**. The demo's own numbers: 4 nodes / 2 dims /
  3 rounds = 336-432 frames = 4,704-6,048 cycles = **259-333 µs**, not
  "tens of µs" (still bench-visible; but the council rules on THIS
  number). Weight reloads are 50% of fabric frames and 80% of cell time —
  cite `weight_state_moves_so_reload_is_required` (MacCell.lean:570); the
  "ONE weight stream" multicast framing is STRUCK (contradicted twice in
  the corpus). The 2-2-1 anchor, int8-consistent: 19 frames / 266 cycles /
  14.6 µs. Accounting basis: the OVERLAPPED timetable, named.
- **C2 · The buffering seam, surfaced (r-envelope).** A round produces 8
  node-states against 4 accumulators: at least half of every round's
  states round-trip through the RP2040 — OUTSIDE the verified surface —
  and round r+1's tape is DATA-DEPENDENT (the offline-tape premise breaks
  at round composition). The round-composition seam is FENCED, not
  proved, in September. Pre-registered control: a single-bit weight
  mutation must change BOTH the emitted byte AND the byte re-injected
  next round (the RP2040 replays what it CAPTURED, never a precomputed h).
- **C3 · h ≤ 127 COMPOUNDS per round — RULING #8 RE-OPENS here as a new
  veto point (r-envelope + r-claims).** The stable range is H ≤ 128/(S−1)
  (S = positive weight mass per output); at deg 3 / R 3 with integer
  weights the reachable state collapses to H ≈ 2 — numerically dead.
  Ruling #8's stated premise ("one layer, no cell→cell chaining") was
  already void for the 2-2-1. Branches for the Captain: **(A)** keep
  no-requant → deg ≤ 2, H ≤ 64, ternary weights, and the target renamed
  honestly (a threshold/erosion field update — "advection-diffusion" is
  dropped); **(B)** land the requantizer the corpus already designed
  (shift + saturate, ~40 gates, in the SER's sAct row) — converts h ≤ 127
  from a per-network weight duty into a THEOREM, freeing the trainer —
  priced as new silicon with a V9-class kernel model, and ruled TOGETHER
  with §4's derivative convention (straight-through 2^-s, the floor's
  zero-derivative region NAMED, else the adjoint theorem is satisfiable
  by zero).
- **C4 · Adjoint duties + the fixed §4 form (r-envelope + r-claims).**
  New per-adjoint-round duties in §0: (i) a gradient-magnitude
  certificate |g| ≤ G_r at every hop, G_r ≤ 127 on any int8 frame;
  (ii) a FRESH `noOverflowFrom` instance on the ADJOINT addend trace
  (demoBound is forward-only); (iii) shiftSafe at the adjoint's actual
  stream length (proven range stops at t < 8) with the wide quantity on
  the STREAMED side. §4's theorem takes the SYMBOLIC form: under the
  forward certificate h ≤ 127 (so emission truncation is identity on the
  reachable set), the emitted adjoint equals D(x)ᵀWᵀ with D the ReLU mask
  RECORDED on the forward pass, convention at 0 named. The "1/256 of the
  domain" sentence is DELETED (a fabricated constant — the kink set is
  weight-dependent, its size a per-network measurement). Controls: the
  transposed-weights mutant now carries a pre-registered `W ≠ Wᵀ` witness
  (symmetric W would pass it), plus a dropped-mask (D = I) mutant.
- **C5 · FATAL REPAIRED — A4 rescoped to ONE adjoint round (r-envelope).**
  Over 3 rounds the int8-per-hop constraint caps the seed gradient below
  1 — an identically-zero gradient no mutant can falsify. A4 is now a
  SINGLE adjoint round with the seed bound stated in the rung (|g| ≤ 21
  at deg 2, unit weights) and an anti-vacuity control: gradients
  pre-registered NONZERO at every hop. "One byte per result honored" is
  DELETED (it asserted what the arithmetic refutes). Multi-round backprop
  moves to A5/v2 and carries the SER shift-enable + multi-frame operand
  path + shiftSafe extension as NAMED, PRICED silicon.
- **C6 · A5 is explicitly v2 (r-claims).** An on-chip update replaces the
  compile-time-checked weights, so the range obligation for the
  POST-UPDATE network is a new, unpriced proof (update rule
  range-preserving over reachable weights) — and η has no mechanism on an
  integer datapath without the requantizer's shift (η = 1 blows the range
  on step one). The "VERIFIED LEARNING" earn criterion is EVIDENCE's to
  pre-register (observable event + instrument); this block ASKS, it does
  not grant. §4's earn sentence is amended accordingly.
- **C7 · Fences at the claim site (r-claims).** §2's three-row sentence
  now carries all three where it stands: the decomposition computes the
  neuron **WHEN DRIVEN** (sequencer = hand RTL, V9's subject), **AT THE
  KERNEL MODEL** (F3 stands — "down to silicon" clears only at a run on
  this top module), and **on the certified traffic class only** (ZERO
  demo rounds are in `fabric_routes`; V10 per-round fixtures OWED — they
  are direct `decide +kernel` evaluations, so no theorem family is
  waited on, said explicitly; single-source frames are outside the
  prefix-concentrated class). Tile-fit retirement is scoped: the 6x2 AS
  RUN; whether a LARGER application closes remains unrun (this block adds
  no RTL). Partial-load status carries exact shas + 1b5453c's guard (NOT
  "the Batcher sorts").
- **C8 · The GraphCast fence is EXTENDED (r-claims).** Never "we ran
  GraphCast" AND never "forecasts weather": the demo runs SYNTHETIC
  dynamics on a 4-node mesh; no weather data enters, no forecast skill is
  measured — applied at every use site including the star sentence and
  the council pack. Any PUBLIC wording naming GraphCast routes through
  clearance before it ships and carries a no-affiliation line. OWED before any
  public wording: the paper's processor-section citation + the explicit
  list of published-model features the PoC does NOT carry (from the
  public paper only — the lane note stands).
- **C9 · Schedule honesty (r-sequencing).** A1 is gated on V9 — a
  compiler-owned live debt in no ladder (priced on compiler's track, or
  A1's sentences ship permanently fenced WHEN DRIVEN). A2's V10 route
  count is 16-20 classes (≈3× the 2-2-1's six; ~4-5 days at A0's rate) —
  fixture cost scales with ROUTE CLASSES (which saturate), runtime and
  range certificates scale with ROUNDS; §7(d) re-aimed at the right
  variables. The in-window exhibit surface is GATE-LEVEL SIMULATION
  (chips ~May 2027; the bench harness is September work outside the
  verified surface). A0 is owed work — a credit, not capacity.
- **C10 · The nine-day recommendation (r-sequencing).** In-window: **A0
  only.** A1-A5 are September/v2 claims and the block says so before any
  prose travels.

## §0 · THE ENVELOPE EVERY CANDIDATE LIVES INSIDE (measured, not argued)

k=4 cells (fabric ports, not area — the cap is the 8-port map, FROZEN);
6 active ports max; int8 values on the 32-bit path, inter-layer h ∈ [0,127]
by compile-time weight choice (ruled); ~170 cycles/neuron canonical, 2-2-1 =
308 cycles ≈ 17 µs; edge emission ONE int8 frame per result until the SER
grows a shift-enable; clock 55 ns fixed; no state survives deselection;
Sept-7 13:00 PDT hard close, submit-real-by-Aug-31 the dossier's own advice.
Per-network proof duties recur: `noOverflowFrom` on the addend trace +
`shiftSafe` at scale + V10 per-round route fixtures (OWED, not started —
every new network multiplies this set; priced per rung below).
★ Deltas since recon: the tile-fit CLAUSE IS RETIRED (silicon ran TT's real
grid: PASSES); the partial-load lift is COMPLETE (`819c685`, silicon MEAS
no-defect) — the sort-then-route seam's kernel half has closed while this
block was being drafted.

## §1 · THE AIM-HIGH TARGET (the star sentence)

**A VERIFIED LAYER-COMPILER FOR MESSAGE-PASSING NETWORKS, DEMONSTRATED ON A
GRAPHCAST-LINEAGE FORECAST STEP — the same encoder-processor-decoder
message-passing shape as the published model (arXiv 2212.12794), at PoC
scale, every arrow from graph spec to fabric schedule a theorem — plus ONE
COMPILED ADJOINT: the gradient program emitted and verified against the
layer's own semantics.** The self-reference is the point twice over: the
chip is a switch fabric computing a GNN, and the demo is the Captain's own
field's flagship GNN — the fabric forecasting weather at the scale of a toy
mesh, with proofs.

## §2 · WHY GRAPHCAST FITS THE FABRIC (the structural match, honestly cut)

GraphCast's processor is message passing on a mesh: node update =
f(h_v, Σ_{u∈N(v)} msg(h_u, e_uv)) — and the fabric's LANDED three-row
decomposition (delivery ∘ MAC ∘ activation at wordSignedOrder) computes
exactly h'_v = ReLU(W_self·h_v + Σ W_msg·h_u + b) with edges as routed
frames. The worked 4-node example in neural-fabric-poc-design-v1.md §4 IS a
processor round already; the demo is that machinery pointed at a
meteorological toy: a 4-node mesh patch (k=4), 2-dim state per node
(e.g., pressure/temperature anomaly, int8 fixed-point), R message-passing
rounds = one forecast step; weights TRAINED OFF-CHIP on synthetic
advection-diffusion data (or hand-derived), loaded in-band as weight packets.

THE CLAIM FENCE, pre-registered before any prose exists: never "we ran
GraphCast." The sentence is "a GraphCast-LINEAGE message-passing step at PoC
scale, from the public architecture." LANE NOTE (the firewall law): built
from the PUBLIC paper (arXiv 2212.12794) only — architecture-shape citation,
our own implementation, no outside-lane code or non-public detail may enter; the
block invites the in-the-moment flag if any drifts near.

## §3 · THE THREE CANDIDATES, RANKED (the council chooses; one recommendation)

- **(A) RECOMMENDED — the GraphCast-lineage step (his 11:4x steer).** Rides
  the most landed silicon+kernel of the three; the layer-compiler probe is
  already fired at compiler's seat; the story is unmatchable ("the verified
  switch fabric forecasts weather"). Costs: V10 fixture set per round;
  per-network overflow duties; the h≤127 discipline constrains trained
  weights (a QUANTIZATION-AWARE constraint the off-chip trainer must honor —
  named now so nobody discovers it at the bench).
- **(B) THE FIREWALL (the "mysql or something" answer with teeth).** "World's
  smallest verified firewall" — recognizable to every systems person, theorem
  already stated (no violating packet escapes ∘ complete mediation ∘ source
  ⊨ P). BUT: its chain quotes compiler Rows A/B (unlanded — block ①'s L4)
  AND needs the port organ (ABSENT, unpriced) AND header-field extraction
  needs AND/shift the source lacks (port organ delivers fields per-variable,
  or the language grows operators it cannot lower). Honest standing: the
  drawer's best resident, promoted the day block ① lands L4. Named, kept.
- **(C) SELF-HOSTING (packet-boot).** His own read: principle-flavor, not
  necessarily compelling. The recon agrees mechanically: latch rung does not
  rescue packet-boot imem; ~2 tiles for 64 words. DRAWERED with its price
  tag attached.

## §4 · THE ADJOINT ROW (where the AD flagship actually lives)

The verified-AD-down-to-silicon candidate stays alive at the LAYER level,
where it is honest: the layer's semantics is finite composition (no while
anywhere in a schedule — the timetable is a straight-line program), so the
adjoint schedule is definable by structural recursion over the same rows —
gradient-is-routing (3b's insight) made a theorem: **the compiler emits the
forward timetable AND the adjoint timetable, and the adjoint provably
computes the semantic derivative of the layer map over ℤ (int8-embedded).**
Scope cuts, said now: derivative over the LINEAR rows exactly; ReLU's
subgradient handled as the standard case split with the boundary case NAMED
(int8 makes the measure-zero argument false — the boundary is 1/256 of the
domain, so the theorem says "away from the kink, exactly; at it, the chosen
convention"). "VERIFIED LEARNING" stays BANNED (evidence's fence) unless
rung A5 lands its row: one on-chip weight UPDATE applied via the in-band
weight path, at which point the earned sentence is "one verified learning
STEP" — the fence's own mechanism for earning a phrase, used as designed.

## §5 · THE LADDER (stop anywhere; every rung banks alone)

- **A0 · V10 fixtures for the 2-2-1** (compiler+silicon; owed to the
  SUBMISSION anyway — this rung is dual-use by construction). Closes "ZERO
  demo rounds certified."
- **A1 · the layer-compiler as Lean rows** (compiler). `LayerSpec` (graph,
  weights, biases) → timetable emission + the three-row correctness table as
  STATEMENTS with the schedule-fixture obligations discharged per round.
  The supplier gap stays fenced: every whole-layer sentence carries WHEN
  DRIVEN until V9's run-level refinement closes (the shell's owed half —
  repriced "genuinely mechanical").
- **A2 · the GraphCast-lineage forward step** (all seats). 4-node mesh, R
  rounds, off-chip-trained int8 weights honoring h≤127; per-network duties
  discharged; bench tape generated from the Lean trace; the logic-analyzer
  exhibit at 18 MHz (single-step for the demo — the dossier's own "better
  exhibit anyway").
- **A3 · the adjoint emission + its theorem** (compiler+math). §4's row over
  the linear rows; the ReLU convention named; controls: a WRONG-adjoint
  mutant (transposed-weights error) must fail the derivative check.
- **A4 · gradient round-trip on the bench** (silicon). The adjoint timetable
  RUN on the fabric (gradients are traffic like anything else); one byte per
  result honored (SER growth is a v2 line item, not assumed).
- **A5 · one verified update step** (stretch; earns the fenced phrase). New
  weights = old − η·grad computed and RELOADED in-band; the update equation
  a theorem at int8 semantics; "the smallest verified learning machine"
  becomes sayable by the fence's own rule.

## §6 · SEQUENCING, COST, OWNERSHIP

A0/A1 start immediately post-council (they serve the submission regardless
of the trio's fate — no-regret rungs). A2 needs A1 plus the September
update-window silicon unchanged (it is a SCHEDULE, not new RTL). A3-A5 are
the aim-high tail, cuttable without unsaying anything. Compiler-seat
contention with block ① is real and the council sequences it; silicon's lane
(fixtures, bench, tape) and math's (adjoint semantics, refutation) run clear.
Nine days: A0 ≈ 1.5, A1 ≈ 2, A2 ≈ 2, A3 ≈ 2, A4/A5 ≈ the window's remainder
— with Aug-31 submit-real as the cut line for what the public artifact
claims.

## §7 · VETO POINTS (his)

(a) Candidate choice — (A) recommended, (B) promotable later, both kept
alive; (b) the GraphCast NAME in any public wording (lane-adjacent; the
private blocks can carry it regardless); (c) whether A5 (the learning step)
is in the nine-day ambition or explicitly v2; (d) mesh size/rounds for A2
(4-node/3-round proposed — the certified-fixture cost scales with rounds).
