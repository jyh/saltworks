# PAYLOAD-DELIVERY — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED (Inverted Purse). Captain-sessioned 8/8
### morning (the ③ docket item); scoping answers below are SPEC-DERIVED
### from docs/silicon-frame-protocol-0806.md and confirmed in session.
### Refutation assignments at the end. Sequenced AFTER the c1/(3,2)
### dispatches — this block costs no seat time until those land.
### Refutation state (8/8 12:5x): SILICON pass CLEAN (folded into
### §1). COMPILER clause 3 repaired (§4/§5); A/B executor out. MATH
### pass COMPLETE — σ STRUCK from §2 (findings 1+2), L0 seed lemma
### added to §3 (finding 3), act_stb probe OPEN in §5 (the flagged
### suspicion, silicon's domain).

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

## 3. THE DECOMPOSITION — four lemmas (L0 added at math's ③ pass)

- **L0 (init-independence — the induction's SEED; math's ③ finding
  3)**: within a well-phased frame, every control latch value from its
  strobe cycle onward is a function of the frame's own header bits,
  from ANY initial register state. The datapath is combinational and
  carries no state (§4), so the control latches are the ONLY init
  surface — and every one is strobed inside [0, 2k). B-class,
  element-level, L2's genre. This grounds H2's "any initial state"
  half — previously assumed, now named and priced.
- **L1 (Batcher element, ceC/bnC)**: after its decide (first differing
  bit inside the header — guaranteed under H1 since distinct
  destinations differ inside [0, 2k)), the compare-exchange is a
  static 2-permutation of its two lines for every later cycle of the
  frame. Never-decided (two idles) = straight-through — exists as
  element-order results (`ce_rejects_idle_sorts_low` family); becomes
  load-bearing only at partial load.
- **L2 (banyan element)**: after sel_stb (cycle 2s+1), the element is
  a static 2-permutation for the rest of the frame. "A locked element
  is a wire."
- **L3 (composition)**: by cycle 2k every element is static, so the
  fabric from 2k on realizes the routing i ↦ dest i that B4's chain
  certifies (stage-3 identity: the named output IS the actual output);
  the claim follows by composing L1/L2 transparency along those
  static paths.
  No offsets (combinational). The trace-induction style is B4's own
  (the hseam discharge); the hypotheses are B4's driven-trace
  conditions extended over the full 14-cycle frame.

## 4. PROOF-ROUTE NOTES + KNOWN TRAPS

- The per-element "locked ⇒ transparent" lemmas live where the element
  semantics live (HDL slot); the composition is Equiv-side beside
  ComposedSwitch. Difficulty: L1/L2 = B-class each (same genre as the
  landed element certs); L3 = C-class, one wave, riding B4's machinery.
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

- **OPEN PROBE (math's ③ flagged suspicion; cheap; fires before L0
  is priced)**: does act_stb reset/align the frame counter? If YES,
  first-act_stb frames are already well-phased and H2 STRENGTHENS to
  "at or after the FIRST act_stb" — a strictly stronger theorem; if
  the counter free-runs, the second-act_stb clause is load-bearing
  and stays. Spec/RTL question — silicon's domain, queued behind its
  ④ pass. H2 stays spec-quoted (:180-183) either way until answered;
  the clause is never weakened, only possibly strengthened.

## 6. REFUTATION ASSIGNMENTS (draft-until-refuted)

- SILICON: §1/§2 against the spec + the validated §8 harness — does
  any spec fact above misquote the protocol? Is the don't-care window
  correctly excluded?
- COMPILER: L1/L2 against the sequential Circ semantics + the trace
  shapes against the B4 induction machinery; the whole-window trap
  clause against your acceptance-bar revision.
- MATH: the statement form (H1/H2/claim) — is anything c2-shaped
  hiding in H2? Is the σ dependency stated or smuggled?
