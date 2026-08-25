# PAYLOAD-DELIVERY — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED (Inverted Purse). Captain-sessioned 8/8
### morning (the ③ docket item); scoping answers below are SPEC-DERIVED
### from docs/silicon-frame-protocol-0806.md and confirmed in session.
### Refutation assignments at the end. Sequenced AFTER the c1/(3,2)
### dispatches — this block costs no seat time until those land.
### v2.3 (8/8 15:5x) — ALL GATES DOWN, WAVES DISPATCHED: phase 3
### closed (d85e13a) + 3b (bb82d5c); ALL round-2 reads IN and folded
### (math 13:33 · silicon 13:47/12:59 · compiler 15:50). CLAIM
### scoped to the tapeout instance P=8 (compiler's R1: `runFrame`
### bakes the 14; ∀-P's true price = the driver, named in §5). Body
### citations converted to symbol/sentence anchors per the citation
### law. THE ③ WAVES ARE LIVE: L0/L1/L2 → compiler's HDL slot;
### L3 → math (three lines); L4 → math (C-class, the summit).
### (History: 6b8dc71/d71a59f/bdb75f2/1a70c99 + this fold.)

## 0. WHAT B4 DID AND DID NOT CERTIFY

> ⚖️ **2026-08-23 — the `- SEAT:` refutation rows in this doc are CLOSED** (council ruling 5).
> Live obligations migrated to `docs/QUEUE.md` §MIGRATED by object-liveness audit; rows below
> are HISTORY (ruling-#7 probes quote them verbatim — do not delete or edit them).

`composed_switch_of_bnC_driven` (SeamJoinB.lean, 33a3c86) certifies
**destination-header delivery**: under the driven-trace hypotheses,
every header reaches the output it names. Verified at the source 8/8
00:16 (d567ca4 thread): headers, NOT payloads. This block scopes the
successor theorem: the P payload bits riding behind each locked header
arrive **verbatim, in order, at the same output, in the same cycle**.

## 1. THE FRAME (spec §2, restated for the certificate's eyes)

k=3, P=8, frame = 2k+P = 14 cycles per line, MSB first:
`[ACT, a₂, ACT, a₁, ACT, a₀, p₀ … p₇]`. P = 8 is the tapeout's
PLACEHOLDER (spec, the P-placeholder sentence — was :270, drifted to
:361 per §5's drift table), not a frozen constant — the statement is
parametric in P and the certificate must not hard-code 14 (silicon's
③ disclosure 1). Frame order cross-checked against consumption:
stage s consumes destination bit k−1−s at cycle 2s+1 (spec, the
stage-consumption sentence), so
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
- H2 (init — RESTATED at silicon's 13:47 measurement, citing the
  AMENDED spec §5 D3.5, 9efc4f5): the frame is WELL-PHASED — cycle 0
  coincident with cnt==0, established by `sof` or `rst_n` — from ANY
  initial register state. STRICTLY STRONGER than the retired
  second-act_stb form, which was measured INERT on the phase axis
  (the counter's period equals the frame length, so waiting repairs
  nothing: 188/200 and 192/200 mis-phased failures on frames 1 and 2
  alike) and conservative-only on registers (the first well-phased
  frame is already correct: 0/200 failures across arbitrary
  register+counter states, mutant control biting at 194/200, with a
  TREATMENT ASSERTION guarding that the alignment actually applied).
  Well-phasedness is an INPUT EVENT and appears as its own
  hypothesis — never inherited from a frame count;
- H3 (reset discipline — compiler's ③ A/B pass, the L1 refutation):
  B4's own `hrst` binder (SeamJoinB, the binder itself): the reset trace is
  `true :: List.replicate n false` — one pulse at cycle 0, none
  after. Without it a mid-frame rst erases `decided` and the element
  re-decides on PAYLOAD bits: a correct-looking delivery with the
  WRONG payload tail (kernel-exhibited: `l1_fails_when_rst_returns` /
  `l1_failure_is_a_mid_frame_flip`, PROMOTED to a tracked module at
  f3751d2 — the names RESOLVE; scratch-provenance 12:28 in the
  module's history) — exactly the failure class this block
  exists to certify against;
- H4 (the wire-tie — math's round-2 WAVE-BLOCKER, 13:33): B4's `hin`
  binder — `∀ i : Fin 8, tr.map (fun c => c.getD (1 + i.val) false)
  = cFrame true (d i) (p i)` — is the ONLY thing tying the abstract
  `d i`/`p i` to the fabric's wires; without it the CLAIM has no
  referent and cannot be transcribed into Lean. B4's `h0 : StageOK
  st tr L 0` (the stage-0 invariant, transported inward by
  `stageOK_succ`) rides with it. §2's hypothesis set is B4's binder
  list IN FULL — nothing summarized away. Bonus from the same read:
  `p : Fin 8 → List Bool` is arbitrary-length, so B4's sorter leg is
  ALREADY ∀-P;

CLAIM (stated at the tapeout instance P = 8, frame = 14 — compiler's
R1, 15:50: the fabric's own driver `runFrame` bakes the 14 in as a
literal, so ∀-P is artifact-supported on the SORTER leg only; the
generalization stays deferred in §5, where its true price — the
driver's length parameter — is now named): for every line i and
every t ∈ [2k, 2k+P):
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
  needs (partial load) is constructed and priced there. (The
  per-comparator σ's that DO get priced are L4's — anonymous,
  sorter-only, never mentioning `dest`: different objects from the
  struck statement-level σ, and their pricing lives in L4, not here —
  math's round-2 F1 residue.)
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
- ⛔ **MIG-7 DISCHARGED 2026-08-24 (math) — H2 IS c2-SHAPED, AND THE
  HIDDEN LEMMA IS THE COUNTER'S WHOLE-FRAME INVARIANT.** H2 states
  well-phasedness as a ONE-CYCLE coincidence — "cycle 0 coincident with
  cnt==0" — and nothing downstream consumes a one-cycle fact. The strobe
  decode is `act_stb[s] = (cnt == 2*s)` / `sel_stb[s] = (cnt == 2*s+1)`
  (`banyan_fabric.v`, the strobe `generate` block); §3's L0 leans on H2 to
  "quantify the counter away" for the whole frame; and the one Lean object
  that models the banyan's schedule — `runFrame` (`FabricRoutes.lean`,
  `let cnt := 14 - (n + 1)`) — IDENTIFIES `cnt` with the cycle index for
  all fourteen cycles and carries no `sof` port at all. Every consumer
  needs `cnt == t` on `[0, 2k+P)`; H2 supplies `t = 0`. **The step between
  them is a lemma this block never writes, and its premise set is
  incomplete.** The block holds the free-run fact and states it
  CONDITIONALLY — §5: "the only zeroing paths are rst_n, sof, and the
  natural wrap" — H3 gives one of those paths its mid-frame discipline
  ("one pulse at cycle 0, none after") and **`sof` never gets the
  sentence H3 is the template for.** Witnessable, not stylistic: a trace
  satisfying H1∧H2∧H3∧H4 verbatim with a second `sof` at cycle 6 re-zeroes
  `cnt` at cycle 7, re-fires `act_stb[0]`/`sel_stb[0]` at cycles 7/8, and
  `bitserial_switch` reloads `act0/act1/sel0/sel1` UNCONDITIONALLY from
  what is on the wires — payload bits — replacing stage 0's routing for
  the rest of the window `[2k, 2k+P)`.
  ⭐ **AND THE MEASUREMENT SUPPLIES WHAT THE STATEMENT DOES NOT**: the
  0/200 arm's `drive_frame` drives `sof = 1'b0` on EVERY cycle of the
  frame (`tb_counter_init.v`), so the quoted counts were taken under an
  `sof` discipline H2 does not carry, and no arm can fail on this axis.
  (The same class, realized and fixed, is recorded in a sibling module's
  own comment — mid-loop `sof` truncation, missed by a bench that pulses
  `sof` only where phase is already 0. That module is `busadapt8` and the
  file is UNTRACKED scratch: precedent for the class, not evidence about
  this fabric.)
  **REPAIR — it belongs in H2, not in a node**: state well-phasedness
  WHOLE-FRAME (`cnt == t` for every `t ∈ [0, 2k+P)`), and give `sof` the
  quiescence sentence `rst_n` already has.
  ⛔ **NOT FOUND, AND LOOKED FOR — two clauses cleared.** (a) "from ANY
  initial register state" is NOT c2-shaped: it is the ABSENCE of a
  hypothesis, a ∀ that STRENGTHENS the theorem, and the burden it creates
  lands conclusion-side on §3's L0 and on spec §5's unconditional-reload
  bullets — both WRITTEN. The banyan half's Lean coverage is a disclosed
  LANDING gap (`PayloadRefutations.lean`: "discharged for the sorter …
  and NOT discharged for the banyan"), not a hidden lemma. (b) The σ half
  stays CLOSED and the strike's verdict is confirmed: B4 concludes three
  Prop conjuncts over `Banyan.line`/`bnCOutKey` — no permutation object —
  and the CLAIM names `dest` and needs no σ binder. The rider's stated
  GROUND is loose (the stage-3 identity is `bnCOutKey`-phrased, hence
  payload-blind by this block's own L3), but what it gestures at is
  priced BY NAME as the unlanded L4: loosely worded, not c2.
  **BLAME**: math, adjudicating three commissioned checkers 2026-08-24;
  the finding is the third checker's clean bill on the phase half,
  overturned. If it is wrong, it is wrong because "well-phased FRAME" was
  always meant whole-frame and the one-cycle gloss is an abbreviation —
  in which case the repair is STILL owed, because that abbreviation is
  exactly what H3 spells out for `rst_n` and what `runFrame` bakes in.

## 3. THE DECOMPOSITION — five nodes (L0 added at math's ③ pass;
## L1/L2/L3 revised and L4 named at compiler's A/B pass, 12:28)

- **L0 (init-independence — the induction's SEED; math's ③ finding
  3, tightened at silicon's 12:59 flag; SENTENCE REPAIRED at the
  wave landing — compiler's finding (a): "a function of the header
  bits" was one word too strong, since `bothAct` samples the DATA
  wires on every even cycle, payload cycles included; bit 3 is
  proved DEAD under the protocol in PayloadL0, so the ROUTING
  conclusion stands unchanged)**: within a WELL-PHASED frame,
  every per-stage control latch value from its strobe cycle onward
  is PROTOCOL-DETERMINED, from ANY initial register
  state. The datapath is combinational and carries no state (§4); the
  init surface is the per-stage latches (all strobed inside [0, 2k))
  PLUS the frame counter — and the counter is exactly what
  "well-phased" quantifies away: L0 is stated FOR well-phased frames,
  and H2 supplies well-phasedness DIRECTLY as the sof-anchored
  premise (amended spec §5 D3.5, 9efc4f5). The earlier attribution —
  "H2's second-act_stb clause supplies it" — was REFUTED by
  silicon's 13:47 measurement: that clause is inert on phase, and
  the composition was citing an unsourced seed (math's 12:52 shape,
  one level out). L0 + H2 compose; neither claims the other's
  ground. B-class, element-level, L2's genre.
- **L1 (Batcher element, ceC — REVISED at compiler's ③ pass)**: under
  H3, after its decide the compare-exchange is a static 2-permutation
  for the rest of the frame. The persistence is LANDED
  (`ceC_step_decided`, `ceC_body_mux`); H3 is what makes it
  usable. The undecided cases are THREE, not two: two idles =
  straight-through (`ceC_frame_two_idle_stable` — the
  previously-cited `…_rejects_idle_sorts_low` is a MUTATION CONTROL,
  not the statement; and the REASON is repaired at the wave landing,
  compiler's finding (b): it holds because an on-protocol idle line
  is SILENT all frame, NOT because idleness stops the decide — idle
  headers with differing payloads decide on payload bit 0 and SWAP,
  and the partial-load successor inherits exactly that reason, where
  idle silence is no longer guaranteed); and two ACTIVE lines with
  EQUAL destinations — the tie SPLICES the payload
  (`ceC_pair_tie_splices_the_payload`), excluded by StageOK's
  distinctness clause — a B4 hypothesis AT STAGE 0 (its own binder),
  transported inward by `stageOK_succ`, not a consequence of H1
  (math's round-2 F2 residue: "interior" was loose). COMPLETENESS,
  proved at the wave (finding (c)): undecided ⟺ headers
  bit-identical ⟺ two idles ∨ an active tie, over all 256 header
  pairs — there is no fourth case. The statement carries it.
- **L2 (banyan element — RESTATED at compiler's ③ pass; the draft's
  form was refuted TWICE)**: there is no sequential banyan in the
  fleet — `fabric` (Banyan.lean, the definition) is a `Circ`: no state, no cycle
  index, no "after sel_stb"; its claim signals are PRIMARY INPUTS
  supplied by an oracle computed from `Banyan.line`/`srcAt`, never
  from header bits on the wire. And the locked element is a
  CLAIM-GATED OR, not a mux — a 2-permutation in 2 of 16 latched
  states, and full-load conflict-merge is non-injective; §2's idle
  rider does NOT cover it. (Both exhibits PROMOTED to a tracked module at f3751d2 — the
  names resolve; scratch-provenance 12:28 recorded there.) L2's true form:
  transparency UNDER HYPOTHESIS `act0 ∧ act1 ∧ (sel0 ≠ sel1)` at
  each element; transporting H1's distinct destinations down to
  per-element sel-distinctness is L4's work. (The old heading "two
  of one shape" dies here: ceC is 8/8 states, the banyan element
  2/16.)
- **L3 (composition — PROOF ROUTE RE-LAID at compiler's ③ pass)**:
  the old route ("ride B4's hseam discharge") is refuted at the
  bytes: B4 concludes about `cDestOf ∘ output column`, and `cDestOf`
  reads header indices 1/3/5 and nothing else (`cDestOf_is_payload_blind`, tracked at f3751d2) —
  payload-blind BY CONSTRUCTION, it
  survives every payload-mangling transformation and cannot carry a
  payload theorem. The machinery that CAN is landed elsewhere:
  `bnC_output_frames_are_the_fold` (SeamTrace.lean) —
  whole-frame, payload-CARRYING, consuming the same `ElemSortsAt`
  premise `elemSortsAt_all` discharges. The composition from those
  two landed theorems is THREE LINES (executor-proved in the pass).
- **L4 (RE-PRICED at math's 16:09 L4 scope — candidate B-class,
  C-class fallback)**: the old pricing rested on `frames_succ_perm`'s
  existential-and-discarded σ. But TWO stronger lemmas are already
  in the kernel: `runNetF_key` (SeamTrace — key of the frame-fold =
  the key-fold, ANY key, ANY comparator list: the σ-agreement is NOT
  unproved) and `bnCFrameAt_succ_frames` (SeamJoinC — the per-stage
  step explicit and PAYLOAD-CARRYING, every other wire unchanged).
  The candidate route: induction over the 24 stages composing those
  two — NO σ object ever constructed. RISK, named: the ∀-w
  "unchanged" clause is where it would break; if it does, the
  C-class σ-composition is the fallback. L4 still absorbs L2's
  H1→per-element sel-distinctness transport. Genuinely absent
  (searched -F): any frames_perm over 24 stages, any payload-delivery
  theorem — nothing of L4 is landed; `runNet_perm` does not import
  (typeclass mismatch).
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
  safe — but the companion is a LITERAL-k fact (`fabric3_shape`
  contains no P anywhere — math's round-2 F3, the finding that
  survived): it stops applying when k generalizes, and blaming ∀-P
  for it was a false alarm. The Lean statement for L3/CLAIM carries
  the port-coverage clause EXPLICITLY, never by companion — concrete
  shape (F4 residue): `∀ o, o < batcherNetC.nOut → ∃ i : Fin 8,
  d i = o`, closed by `seam_hyps_force_full_load`.
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
  do not bundle it into the first wave. CORRECTED at math's round-2
  F3: the port-coverage companion is literal-k, NOT P-bound — it
  survives ∀-P and dies at ∀-k, so it was never a reason to defer P;
  and B4's sorter leg is ALREADY ∀-P (`p` arbitrary-length, per H4's
  read). AND (compiler's R1, 15:50): the artifact ground reappears
  one level up — `runFrame` hardcodes the 14, so generalizing the
  DRIVER is the ∀-P wave's true price, named here so it is never
  silently carried. AND (math's 16:09 residue): `StageOK` carries
  `p.length = L` — a UNIFORM payload length across all eight lines,
  so the sorter leg's ∀-P is arbitrary-but-EQUAL, not arbitrary —
  invisible at P=8, another named piece of the ∀-P price. The
  deferral's remaining ground is the frame
  counter alone;
  the generalized statement still carries port coverage explicitly
  per §4. ARTIFACT-SIDE GROUND REMOVED (silicon 13:47): the
  counter-width literal is fixed ($clog2, netlist-neutral at P=8),
  so "touches the frame counter" no longer names an artifact defect
  — any remaining reason to defer ∀-P is PROOF-side only.
- CITATION LAW (silicon's cross-document rule, adopted for this
  block): spec citations are SECTION + QUOTED SENTENCE, never bare
  line numbers — three of this block's line-cites rotted inside one
  spec amendment (:270→:361, :191→:221, :202→:232, :174→:175;
  recorded so no reader chases stale lines).
  ⛔⛔ **MIG-8 RE-READ, 2026-08-24 (silicon): ALL FOUR OF THOSE "REPAIRED"
  TARGETS HAVE NOW ROTTED TOO — and they were recorded as BARE LINE NUMBERS in
  the very sentence that adopts "SECTION + QUOTED SENTENCE, never bare line
  numbers." THE REPAIR INHERITED THE SHAPE OF THE ERROR IT REPAIRED.**
  Measured against the current spec (`55831de`; blob-identical to HEAD, zero
  commits since, so the pin itself is sound):
  - `:361` → unrelated bench prose. The P-placeholder now lives in **spec §9
    OPEN**: *"`P` (payload length). 8 is a placeholder chosen to make a 14-cycle
    frame."* — it changed SECTION, which no line number can express.
  - `:221` → *"unsourced in both nodes."*, the tail of §5's consumer warning.
  - `:232` → **an empty line.**
  - `:175` → the power-gate/`l_ena` sentence; §5's reset material starts `:176`.
  - the free-run prose this block cites as `:191/:202` is now in **spec §6**:
    *"cnt : 0 … (2k+P−1), free-running, reset by rst_n and re-aligned by sof"*.
  ⇒ **USE THE QUOTED SENTENCES ABOVE. Do not re-record these as line numbers —
  that is the move that has now failed twice in this same bullet.**

- ✅ **MIG-8 DISCHARGED 2026-08-24 (silicon) — THE SPEC FACTS THEMSELVES ARE
  CLEAN.** Re-read of §1/§2's spec-derived claims against the current spec, the
  question being "does any spec fact misquote the protocol?" **No misquote
  found.** Verified at section + sentence: frame `2k+P` = 14 MSB-first (**§2**)
  · stage `s` consumes bit `k−1−s` at cycle `2s+1` (**§2**, verbatim) · data path
  combinational end to end (**§4**) · fabric outputs defined from cycle `2k`
  (**§4**) · payload window `(2k …)` = validity window (**§4**), with this
  block's CLOSED upper bound `2k+P` still correctly attributed to itself and not
  to the spec · `P = 8` a placeholder (**§9**).
  ⭐ **THE HIGHEST-RISK ITEM IS THE ONE THAT IS CLEANEST.** Spec §5 carries an
  explicit warning to consumers that anything citing the second-`act_stb` clause
  as the SOURCE of well-phasedness "attributes the premise to a clause that
  cannot produce it." **This block does not: it carries the amended sof-anchored
  form and names the old attribution as REFUTED in the same breath.** Its quoted
  counts check out against **spec §8 rows 6 and 7** exactly — `188/200` and
  `192/200`. Rows 5–11 all present; row 5 `0/200` and row 10 `0/255` with mutant
  controls at rows 9 and 11.

- **PROBE CLOSED (8/8 13:3x — answered INDEPENDENTLY by silicon
  13:31 and math 13:33, same bytes, same verdict)**: the counter
  FREE-RUNS. banyan_fabric.v:44-47 — the only zeroing paths are
  rst_n, sof, and the natural wrap; act_stb is a pure DECODE of cnt
  (:57), so the reset direction is structurally impossible (an
  output cannot reset its own source; spec :191/:202 states the
  free-run in prose). NO spec amendment triggered; H2's
  second-act_stb clause is LOAD-BEARING and stays, spec-quoted, as
  drafted. OPEN SUCCESSOR (silicon's own artifact, pre-registered
  13:31): spec §8's validation models only HALF the init surface —
  frame_sim.py has no counter at all — and silicon is measuring the
  missing half against the real RTL; if that confirms
  conservative-on-registers + inert-on-phase, the consequence lands
  on the SPEC's §5 wording first (a sof-phase premise), the block
  cites the amended spec second. SUCCESSOR MEASUREMENT COMPLETE
  (13:47): conservative+inert CONFIRMED — 200-seed arms with
  treatment assertions; spec §5 AMENDED (9efc4f5); H2 restated
  above on the amended form; the block now cites the spec it was
  waiting for.

## 6. REFUTATION ASSIGNMENTS (draft-until-refuted)

- SILICON: §1/§2 against the spec + the validated §8 harness — does
  any spec fact above misquote the protocol? Is the don't-care window
  correctly excluded?
- COMPILER: L1/L2 against the sequential Circ semantics + the trace
  shapes against the B4 induction machinery; the whole-window trap
  clause against your acceptance-bar revision.
- MATH: the statement form (H1/H2/claim) — is anything c2-shaped
  hiding in H2? Is the σ dependency stated or smuggled?
  ✅ **ANSWERED 2026-08-24 (MIG-7, commissioned three-checker pass) —
  YES on H2, NO on σ.** H2 is c2-shaped: it states a ONE-CYCLE
  coincidence while every consumer needs the whole-frame invariant
  `cnt == t`, and the step between is an unwritten lemma whose premise
  set is incomplete (`sof` never gets the mid-frame quiescence sentence
  H3 gives `rst_n`). The σ dependency is **stated, not smuggled** — the
  strike's verdict is confirmed; only the rider's stated ground is
  loose. Discharge rider in §2, after the Zero-latency bullet.
