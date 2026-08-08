# PAYLOAD-DELIVERY — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED (Inverted Purse). Captain-sessioned 8/8
### morning (the ③ docket item); scoping answers below are SPEC-DERIVED
### from docs/silicon-frame-protocol-0806.md and confirmed in session.
### Refutation assignments at the end. Sequenced AFTER the c1/(3,2)
### dispatches — this block costs no seat time until those land.
### Refutation state (8/8 13:0x): ALL ③ READS COMPLETE AND FOLDED.
### SILICON clean (§1, + the 12:59 hazard → probe re-scoped).
### COMPILER clause-3 (§4/§5) AND the A/B pass (12:28): H3 added to
### §2; L1 hypotheses fixed; L2 restated for the real artifact (Circ
### fabric, claim-gated OR, act/sel hypothesis); L3 re-routed via
### bnC_output_frames_are_the_fold; L4 NAMED = the σ-composition,
### C-class, the summit. MATH: σ struck, L0 added, act_stb probe
### open (silicon's, dispatched 13:06). This is v2 of the
### decomposition — WAVES DISPATCH ONLY AFTER the seats read v2
### (draft-until-refuted, round 2).

## 0. WHAT B4 DID AND DID NOT CERTIFY

`composed_switch_of_bnC_driven` (SeamJoinB.lean:188, 33a3c86) certifies
**destination-header delivery**: under the driven-trace hypotheses,
every header reaches the output it names. Verified at the source 8/8
00:16 (d567ca4 thread): headers, NOT payloads. This block scopes the
successor theorem: the P payload bits riding behind each locked header
arrive **verbatim, in order, at the same output, in the same cycle**.

## 1. THE FRAME (spec §2, restated for the certificate's eyes)

k=3, P=8, frame = 2k+P = 14 cycles per line, MSB first:
`[ACT, a₂, ACT, a₁, ACT, a₀, p₀ … p₇]`. P = 8 is the tapeout's
PLACEHOLDER (spec :270), not a frozen constant — the statement is
parametric in P and the certificate must not hard-code 14 (silicon's
③ disclosure 1). Frame order cross-checked against consumption:
stage s consumes destination bit k−1−s at cycle 2s+1 (spec :121), so
the MSB-first frame and the stage order AGREE — an LSB-first frame
would satisfy every quoted spec sentence and route backwards
(silicon's ③ pass, the cross-check this block had not stated).
Payload streams RAW from cycle
2k (no interleave continuation — the phase discipline question is
ANSWERED BY SPEC, not open). The data path is **combinational end to
end** (§4): a payload bit presented at input cycle t leaves at output
cycle t. Stage s latches activity at 2s, select at 2s+1, outputs
defined from 2s+2; fabric outputs defined from 2k. **The payload
window [2k, 2k+P) equals the validity window** — the open end (2k…)
is §4's own sentence; the CLOSED upper bound 2k+P is this block's
tightening, coinciding within a frame (silicon's ③ disclosure 2 —
the bracket is ours, not the spec's, and is no longer attributed to
§4): that is why the header is 2k.

## 2. THE STATEMENT (shape, not yet Lean)

For the k=3 fabric under:
- H1 (B4's regime, FORCED at k=3 by `seam_hyps_force_full_load`):
  every line active, destinations distinct — B4's own binders
  (`hd : ∀ i, d i < 8`, `hdi : Function.Injective d`); no bijection
  OBJECT is taken (σ STRUCK — first rider below);
- H2 (init, spec §5's honest form): the frame begins at or after the
  second act_stb following power-up, from ANY initial register state;
- H3 (reset discipline — compiler's ③ A/B pass, the L1 refutation):
  B4's own `hrst` binder (SeamJoinB.lean:192): the reset trace is
  `true :: List.replicate n false` — one pulse at cycle 0, none
  after. Without it a mid-frame rst erases `decided` and the element
  re-decides on PAYLOAD bits: a correct-looking delivery with the
  WRONG payload tail (kernel-exhibited, `l1_fails_when_rst_returns` /
  `l1_failure_is_a_mid_frame_flip`) — exactly the failure class this
  block exists to certify against;

CLAIM: for every line i and every t ∈ [2k, 2k+P):
  `output (dest i) t = input i t`.

Riders:
- **σ STRUCK (math's ③ findings 1+2, resolved by the block's owner)**:
  B4's conclusion certifies PROPERTIES — per-stage injectivity, a
  stage-3 IDENTITY, a stage-0 value — not a permutation object; there
  is no σ to read off, and constructing one was work the block never
  priced. And none is needed: the stage-3 identity plus §0's own
  "same output" make the named output the actual output, so the claim
  speaks in `dest` directly. A σ parameter would be either dead
  (= id — one binder stronger than needed, for no gain) or false
  (≠ id contradicts §0). Any bijection object a successor campaign
  needs (partial load) is constructed and priced there.
- **Header window excluded by design**: output cycles [0, 2k) are
  don't-care (§4); the certificate says NOTHING about them. A clause
  claiming them would be false and the spec forbids reading them.
- **Idle non-interference** (vacuous at full load, stated for the
  partial-load successor): an ACT=0 line claims no output; unclaimed
  outputs drive 0 all frame (§3 — idleness is a fixed point). At k=3
  full load is forced, so this rider becomes load-bearing only in the
  partial-load statement (see §5 below).
- **Zero latency is a theorem input, not a convenience**: combinational
  datapath (§4) means no per-path offset bookkeeping. The 1988 chipset
  needed per-stage skew accounting; convention C does not — record the
  contrast in the heritage block, not here.

## 3. THE DECOMPOSITION — five nodes (L0 added at math's ③ pass;
## L1/L2/L3 revised and L4 named at compiler's A/B pass, 12:28)

- **L0 (init-independence — the induction's SEED; math's ③ finding
  3, tightened at silicon's 12:59 flag)**: within a WELL-PHASED frame,
  every per-stage control latch value from its strobe cycle onward is
  a function of the frame's own header bits, from ANY initial register
  state. The datapath is combinational and carries no state (§4); the
  init surface is the per-stage latches (all strobed inside [0, 2k))
  PLUS the frame counter — and the counter is exactly what
  "well-phased" quantifies away: L0 is stated FOR well-phased frames,
  and H2's second-act_stb clause is what SUPPLIES well-phasedness
  (the spec's own one-complete-frame argument, §5:174). L0 + H2
  compose; neither claims the other's ground. B-class, element-level,
  L2's genre.
- **L1 (Batcher element, ceC — REVISED at compiler's ③ pass)**: under
  H3, after its decide the compare-exchange is a static 2-permutation
  for the rest of the frame. The persistence is LANDED
  (`ceC_step_decided` :110, `ceC_body_mux` :157); H3 is what makes it
  usable. The undecided cases are THREE, not two: two idles =
  straight-through (`ceC_frame_two_idle_stable` :232 — the
  previously-cited `…_rejects_idle_sorts_low` is a MUTATION CONTROL,
  not the statement); and two ACTIVE lines with EQUAL destinations —
  the tie SPLICES the payload (`ceC_pair_tie_splices_the_payload`
  :307), excluded at interior comparators only by StageOK's
  distinctness clause, which is a B4 HYPOTHESIS, not a consequence of
  H1. The statement carries it.
- **L2 (banyan element — RESTATED at compiler's ③ pass; the draft's
  form was refuted TWICE)**: there is no sequential banyan in the
  fleet — `fabric` (Banyan.lean:132) is a `Circ`: no state, no cycle
  index, no "after sel_stb"; its claim signals are PRIMARY INPUTS
  supplied by an oracle computed from `Banyan.line`/`srcAt`, never
  from header bits on the wire. And the locked element is a
  CLAIM-GATED OR, not a mux — a 2-permutation in 2 of 16 latched
  states (`l2_locked_is_a_wire_in_two_states`); full-load
  conflict-merge is non-injective (`l2_full_load_conflict_merges`)
  and §2's idle rider does NOT cover it. L2's true form:
  transparency UNDER HYPOTHESIS `act0 ∧ act1 ∧ (sel0 ≠ sel1)` at
  each element; transporting H1's distinct destinations down to
  per-element sel-distinctness is L4's work. (The old heading "two
  of one shape" dies here: ceC is 8/8 states, the banyan element
  2/16.)
- **L3 (composition — PROOF ROUTE RE-LAID at compiler's ③ pass)**:
  the old route ("ride B4's hseam discharge") is refuted at the
  bytes: B4 concludes about `cDestOf ∘ output column`, and `cDestOf`
  reads header indices 1/3/5 and nothing else
  (`cDestOf_is_payload_blind`) — payload-blind BY CONSTRUCTION, it
  survives every payload-mangling transformation and cannot carry a
  payload theorem. The machinery that CAN is landed elsewhere:
  `bnC_output_frames_are_the_fold` (SeamTrace.lean:1242) —
  whole-frame, payload-CARRYING, consuming the same `ElemSortsAt`
  premise `elemSortsAt_all` discharges. The composition from those
  two landed theorems is THREE LINES (executor-proved in the pass).
- **L4 (the σ-composition — the C-class work L3 was hiding; NAMED at
  compiler's ③ pass)**: `frames_succ_perm` (SeamJoinA.lean:267)
  holds the one-comparator permutation, but its σ is EXISTENTIAL AND
  DISCARDED — `stageOK_succ` uses it only to transport the invariant;
  nothing composes the 24 per-comparator σ's, and frame-σ's agreement
  with key-σ is unproved. That composition + agreement is the block's
  real C-class node, and it absorbs L2's H1→per-element
  sel-distinctness transport. One wave, the block's summit.
  No offsets (combinational). The trace-induction style is B4's own
  (the hseam discharge); the hypotheses are B4's driven-trace
  conditions extended over the full 14-cycle frame.

## 4. PROOF-ROUTE NOTES + KNOWN TRAPS

- The per-element "locked ⇒ transparent" lemmas live where the element
  semantics live (HDL slot); the composition is Equiv-side beside
  ComposedSwitch. Difficulty RE-PRICED at the ③ folds: L0/L1/L2 =
  B-class; L3 = three lines from two landed theorems; L4 = the
  C-class wave, the summit.
- TRAP (from the morning's sweep): state the conclusion WHOLE-LIST /
  whole-window — `∀ t ∈ [2k, 2k+P)` with the window's BOUNDS in the
  statement, not a per-sample form. A `take`-shaped claim pins no
  upper bound (compiler's ①⁗ finding).
- TRAP — REFUTED-AND-REPAIRED (compiler's ③ pass, 8/8 12:15): the
  clause above guarded only the TIME axis. The conclusion must be
  whole over the PORT axis too (①‴, from the same bar revision) —
  whole over ports, or the statement carries `outs.length` explicitly.
  At k=3 the port coverage is PINNED-BY-COMPANION (`fabric3_shape`'s
  literal 8 + `hdi` injectivity ⇒ σ∘dest onto), so the k=3 wave is
  safe — but the companion stops applying at the ∀-P generalization
  while the claim's shape does not change. The Lean statement for
  L3/CLAIM carries the port-coverage clause EXPLICITLY, never by
  companion.
- TRAP: the certificate must quantify over the INPUT streams as free
  trace variables (B4's driven-trace form), never over a sampled
  environment; `_on_sample` names are for disclosed-scope certs only.
- Facade caveat — CLEARED 8/8 (maestro, 64f9311): `Facade` restated
  over `SaltWorks.Banyan.line`, `ProbeFacade` deleted. §2.1's
  resonance may be cited directly; the prerequisite repair is done.

## 5. WHAT THIS BLOCK DEFERS, BY NAME

- **Partial load**: `repeated_code_refutes_no_conflict` shows the
  routing conclusion is FALSE with a shared idle code, so partial-load
  delivery needs the product order (¬active, dest) and its own Batcher
  statement. Separate campaign; the idle riders here are its hooks.
- **P as a parameter**: state over the tapeout's P=8 first; the
  ∀-P generalization is free-looking but touches the frame counter —
  do not bundle it into the first wave. AND (clause-3 refutation): at
  ∀-P the port-coverage companion (`fabric3_shape`'s literal 8) stops
  applying — the generalized statement must carry port coverage
  explicitly or it inherits the index-wise blindness the repaired §4
  trap names.

- **OPEN PROBE (math's ③ suspicion, RE-SCOPED at silicon's 12:59
  flag)**: the factual question stands — does act_stb reset/align the
  frame counter, or does it free-run? — but its H2 consequence now
  routes THROUGH THE SPEC: §5's "second" is the conclusion of the
  spec's own one-complete-frame argument (:174), so a first-act_stb
  H2 would out-claim the spec, and under citation discipline the
  block cannot source it from §5. If the probe finds counter-reset
  at the RTL, the path is: spec AMENDMENT first (silicon's file, on
  silicon's evidence, its own bar), block cites the amended spec
  second. DEFAULT UNCHANGED either way: H2 stays spec-quoted at
  second-act_stb. Silicon's domain, queued behind its ④ pass.

## 6. REFUTATION ASSIGNMENTS (draft-until-refuted)

- SILICON: §1/§2 against the spec + the validated §8 harness — does
  any spec fact above misquote the protocol? Is the don't-care window
  correctly excluded?
- COMPILER: L1/L2 against the sequential Circ semantics + the trace
  shapes against the B4 induction machinery; the whole-window trap
  clause against your acceptance-bar revision.
- MATH: the statement form (H1/H2/claim) — is anything c2-shaped
  hiding in H2? Is the σ dependency stated or smuggled?
