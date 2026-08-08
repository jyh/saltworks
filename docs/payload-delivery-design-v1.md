# PAYLOAD-DELIVERY — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED (Inverted Purse). Captain-sessioned 8/8
### morning (the ③ docket item); scoping answers below are SPEC-DERIVED
### from docs/silicon-frame-protocol-0806.md and confirmed in session.
### Refutation assignments at the end. Sequenced AFTER the c1/(3,2)
### dispatches — this block costs no seat time until those land.
### Refutation state (8/8 12:2x): SILICON pass CLEAN (11 facts
### line-verified; 2 disclosures + 1 cross-check folded into §1).
### COMPILER clause 3 REFUTED → repaired (§4 port-axis trap; §5 ∀-P
### rider); A/B executor out. MATH pass OPEN (fires at its phase-2
### seam).

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
  every line active, destinations distinct — hence a bijection σ,
  the permutation B4's chain certifies;
- H2 (init, spec §5's honest form): the frame begins at or after the
  second act_stb following power-up, from ANY initial register state;

CLAIM: for every line i and every t ∈ [2k, 2k+P):
  `output (σ (dest i)) t = input i t`.

Riders:
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

## 3. THE DECOMPOSITION — three lemmas, two of one shape

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
  fabric from 2k on IS the fixed permutation σ of B4's conclusion;
  the claim follows by composing L1/L2 transparency along σ's paths.
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

## 6. REFUTATION ASSIGNMENTS (draft-until-refuted)

- SILICON: §1/§2 against the spec + the validated §8 harness — does
  any spec fact above misquote the protocol? Is the don't-care window
  correctly excluded?
- COMPILER: L1/L2 against the sequential Circ semantics + the trace
  shapes against the B4 induction machinery; the whole-window trap
  clause against your acceptance-bar revision.
- MATH: the statement form (H1/H2/claim) — is anything c2-shaped
  hiding in H2? Is the σ dependency stated or smuggled?
