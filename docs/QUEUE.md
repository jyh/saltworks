# QUEUE.md — the fleet queue (maestro-owned; seats PULL at seams)
### Born 2026-08-08, Captain-ratified in session: "we try to address
### structural issues, coarsening the dependencies where possible,
### giving each seat multiple options, and preauthorizing where
### possible too." Maintained by the maestro AT EVERY RULING; seats
### read it at every seam. The bus still carries orders; this file
### carries STANDING work so an empty queue self-refills without a
### dispatch.

## THE SEMANTICS (read once, they are the point)

- **PRE-AUTH** means: pull it at your seam WITHOUT ASKING. Post one
  line when you start and one when you land. Redirection may arrive
  at any time and costs nothing — corrected work has already paid
  its exploration value (the Captain's principle, 8/8: "the simple
  act of working has exploration value, even if you need to
  correct it").
- **GATED(x)** means: do not start until x. Coarse gates only —
  a gate names a landing or a word, never a micro-step.
- **TRACKS**: each seat carries at most ONE write track live (the
  shared tree and the lock make two pens per seat dangerous) plus
  any number of READ tracks (refutation passes, censuses, reads —
  lock-free, suspend-free) plus SPECULATIVE work (probes — always
  authorized, quota-only, results may be parked).
- **STEALING**: author-anywhere, LAND-AT-OWNER (patch-to-owner, run
  three times 8/8: hinge math→compiler, MIGPATCH math→compiler,
  phase-3 residue compiler→math). Labor moves; the owner runs the
  controls and lands. Read-work floats freely — any seat may refute
  any block.
- **PRECONDITIONS (optimistic concurrency — the Captain's frame,
  US9229774's discipline adapted 8/8)**: every WAVE BRIEF opens with
  its assumed world — the constants it relies on, the spec sentences
  QUOTED (never line numbers), the statement bytes, the files it
  expects unmoved — and the executor VALIDATES them against the
  live tree BEFORE starting, aborting-with-a-report on drift
  instead of proving against a ghost. Floating (stealable) work is
  claimed by one bus line naming the item + "unclaimed as of <last
  line read>": the append-only bus serializes claims and a later
  claimant self-rejects. The policy split, named: validate-BEFORE
  for expensive transactions (waves, deletions, tapeout decisions);
  validate-AFTER (draft-until-refuted) for cheap ones (docs, where
  amendment is measured-cheap). Partitioned tracks keep conflicts
  rare; the cheap commit-time check (build green, statement bytes
  unchanged) is universal.
- **THE BUS APPEND LAW NAMES METHODS (finalized 08-09 01:4x after
  the truncate-rewriter was found — compiler's pathlib.write_text,
  self-confessed with its blast radius measured): FLEET.md is
  written by `>>` (shell) or mode='a' ONLY. Banned on the bus:
  `>`, write_text, mode='w', mv/atomic-replace, sed -i — a
  whole-file rewrite opens a window where a concurrent reader sees
  an EMPTY file and a concurrent append is EATEN. The shrink
  detector (maestro, 0.25s) stands as the tripwire.**
- Laws that ride every item: saltbuild-only builds; pathspec-only
  commits; trailer-free; unique Scratch<NODE>-<agent>.lean
  (per-AGENT); explicit-brief law for executors; the kernel-census
  aiming rider for any deletion; **SaltWorks.lean (the root) is
  MAESTRO-ONLY** — landings post "import owed" and the maestro wires
  + runs the full-build verdict (the one-hand rule; restated 17:32
  after a benign crossing).
- **THE CAP PICTURE (FOURTH REVISION, 08-09 12:0x — DEFAULT RAISED
  BY CAPTAIN RULING: audit form now `-M 24000` DEFAULT in the
  wrapper; the `--cap 24000` dance for known heavies is RETIRED —
  Immediate/Decoder/FabricRoutes audit at the default now). Module
  form unchanged: `-M 20000` PER PROCESS from `lakefile.toml`'s
  weakLeanArgs — the full build is NOT uncapped. THE RULE BY CAUSE
  survives with a new threshold: EXIT=134 at the 24000 default
  means a >24 GB module — a NEW weight class, worth a look rather
  than a bigger cap reflex; caps still do not move without a
  maestro ruling. History (third revision, 00:2x): the old 12000
  default + --cap dance, and the refuted symptom-list form. ✅ THE MACHINE-LEVEL QUESTION IS
  MEASURED, NOT OPEN (was stated here as an unmeasured 80-GB hazard;
  that rotted in the dangerous direction and is STRUCK): realised
  fleet peak 43.08 GB of 64 GiB (compiler 01:0x, scratch clone);
  the per-process 20-GB cap NEVER binds (~10.8 GB actual); the FLEET
  LOCK is the machine-level guard — it fits, and nobody should "fix"
  the cap on the strength of the old 80-GB arithmetic.** ADD-BESIDE
  remains good practice on its own merits. Caps do not move without
  a maestro ruling.

## COMPILER

- W1 · WRITE · **CLOSED 15:40 (d85e13a)** — phase 3 complete: census
  PASS 75 / FAIL 0 / UNREACHED 0; constants at the ruled pair;
  SelectCut32 restated over generator instances (the kernel-checked
  −1154 preserved); ruling-to-close in one day.
- W2 · WRITE · **FIRED 15:51 (all gates down)** — ③ waves L0/L1/L2
  in the HDL slot, statements per v2.3 (P=8 scope; H1–H4 in full;
  three undecided cases; claim-gated-OR transparency; ∀-P off
  runFrame traces); precondition preambles mandatory.
- R1 · READ · **DISCHARGED 15:50** — the last ③ gate read (one
  load-bearing refutation, folded as v2.3; the waves dispatched on
  it).
- R2 · READ · **DISCHARGED 17:25** — the last ④ read (the +1-cycle
  price revived as a causality floor; piece 5 re-founded over
  testBit; folded into the heritage doc).
- W3 · WRITE · **LANDED 18:07 (499360d, rooted 8663-green)** — ④
  pieces 2 AND 5: Cell1988.lean, six-state FSM, the framework law
  zero_offset_rotation_is_impossible; piece 5 over testBit rode the
  same landing. Neither refuted.
- W4 · WRITE · **LANDED 19:44 (86553a6) + ROOTED 19:53 (5446a98,
  saltbuild EXIT=0, 8668 jobs)** — Executive.lean, the word-level
  executive, self-pulled under the aggressive mandate into the gap
  compiler itself published: all five pre-registered bar lines MET,
  `runW_map` unconditional (the prize), six SortDemo certificates
  lifted by rewrite with zero re-execution, the undecodable-word
  boundary shown with witnesses. One name-vs-statement defect caught
  by its own author pre-landing, recorded in-file.
- W5-asm (the core assembly — track-suffixed per math's 8/9 collision
  catch: bare "W5" also names salt wave-5 nodes and a Weil-track label;
  Captain-facing text carries the suffix) · WRITE · **OPEN — COUNCIL
  RULING #4 (09:2x, the Captain,
  option (a) interleaved): "even if we choose the packet-IO route,
  I'd like our original plan to be complete, verified, and ready
  for tapeout... I would actually tend toward (a), in case we
  encounter issues it may feed back."** The `core` construction:
  assemble the certified organs into ONE machine and prove the
  single-cycle refinement (assembled gates, clocked once, = stepT).
  METHOD: the probe pattern at scale — instOK per organ, sem_*
  certificates consumed by rewrite, never re-proved; the 8/7
  assembly plan's row map + StateCodec conformance. PRE-NAMED
  RISKS: sigma off-by-ones (the probe's own bar-3 class), composite
  heaviness (the audit-cap rider stands), StateCodec/encode
  agreement. THE PRIZE: emitS the completed core as the tapeout
  RTL — the fabbed thing becomes the verified thing. INTERLEAVED
  at compiler's seam with tiny-Rust N-waves and B-ISA (one write
  track, compiler's sequencing judgment); issues FEED BACK to the
  design docs immediately, per the Captain's rationale.
- W6 · MEAS · **APPROVED 20:18 (maestro), compiler's slot** — the
  TARGETED COLD-COST CENSUS: path-form elaboration at the DEFAULT cap
  of plausibly-over-cap modules (decide +kernel over large ranges),
  pass/fail PER MODULE with the invocation attached (compiler's own
  pre-registered trap: no bare totals — a count is not a scope).
  Through saltbuild.sh (the fleet lock serializes the heavy runs;
  EXIT=134 rows are expected OUTCOMES, not failures of the census).
  Output feeds the morning cap ruling: it converts "at least one
  module is cold-unbuildable at the default" (Immediate.lean,
  measured EXIT=134) into a NUMBER.

## MATH

- W1 · WRITE · **PRE-AUTH** — the phase-3 Program.lean patch, on
  arrival of compiler's request (land it yourself; your file).
- W2 · WRITE · **LANDED 15:31 — the flagship's first theorem in five
  math lives**: norm_majorantCoeff_le_sq in the kernel (8b4c94c,
  clean axioms, audit by math's own hand); pre-flight held whole;
  M2 is the banked control (residual ⊢ 2 = 1, no slack). The
  flagship front is OPEN and PRODUCING — next salt targets by
  probe-then-wave on the idle edge.
- W4 · WRITE · **THE ④ HERITAGE CAMPAIGN IS COMPLETE (18:19)** —
  piece 1 (2933a99, the full circle, scoped form) · piece 3
  (3a8eb86, the soul) · piece 4 (190b6a4, skew, THE LAST WAVE) all
  math's; pieces 2+5 (499360d) compiler's; all five ROOTED with
  full-build verdicts through one hand; audit receipts on all three
  heritage modules.
- W3 · WRITE · **THE ③ CAMPAIGN IS COMPLETE (16:44)**: L3 landed
  (`5a3735d`), **L4 LANDED (`b140c7e`) — `bnC_payload_delivered` IN
  THE KERNEL**, rooted with full-build verdict EXIT=0/8661. The
  candidate-B route held: NO σ object ever constructed; the flagged
  ∀-w clause was the leg that made the induction trivial. Goal-level
  controls with pre-written witnesses, both biting.
- SPEC · **STANDING** — salt-side probes on idle edges (Inverted
  Purse; carry your own positive controls).

## SILICON

- W1 · WRITE · **PRE-AUTH** — the §8 half-surface repair: the
  iverilog measurement per your pre-registered 13:31 criterion
  against the real RTL; frame_sim's missing-counter gap fixed in
  your artifact; the spec §5 sof-phase amendment IF the measurement
  confirms conservative+inert (your file, your bar; the ③ block
  cites the amended spec second).
- R1 · READ · **SUPERSEDED 17:03 (silicon's own reading, receipted)**
  — the ③ campaign completed past it; substance covered by its 13:47
  pass + the landing verifications.
- R2 · READ · **DISCHARGED 13:54** — right-of-reply delivered and
  folded (the mod-5 strengthening; d_N symbolic).
- MEAS · **STANDING** — conveyor refutation on every compiler
  landing; CELLS pricing on request. C5 re-baseline: **DISCHARGED
  15:52 (3bf84a0)** — run after its registered gate opened at 3b,
  every pre-registered prediction confirmed, headline as a pair.
  (Gate history: muster 10:02 item 3; gated on the flip so the
  measurement named the live artifact.)

## EVIDENCE

- CHARTER · **STANDING** — the five held-open items with close
  conditions (your predecessor's durable queue, ba9ccdd); the
  slate-price number written ONCE at slate close; the nightly
  ledger run.
- R1 · READ · **PRE-AUTH, OPTIONAL** — ③/④ reads at seams (your
  duty-filter design carries no landing-triggered duties; keep it
  light by design).

## THE CAPTAIN'S REGISTER (Captain-ratified 8/8 ~14:10, his words)

> "It is better to ask for correction than for permission." — and the
> Purse: "do it, unless it is obviously wrong."

- **TIER 1 — SOLELY THE CAPTAIN'S, never defaulted**: anything
  PUBLIC · MONEY · ENDORSEMENTS · frozen-statement re-cuts · the
  summit word · named clicks (B5). The maestro's duty is the fact
  sheet BEFORE ripeness, so each costs one read and one word.
- **TIER 2/3 — PREAUTHORIZED TO THE MAESTRO**: everything else;
  the Captain's later veto always available. Decisions touching
  Tier-1-adjacent artifacts are FLAGGED with their veto point named
  (the pin pattern, 13:49).

STANDING ORDER (the Captain, 8/8 night, verbatim): "be aggressive,
you have more ability than you know" — 11 days remain on the
two-week clock; the plan holds. HIS NAMED NEXT STEP if the current
plan lands soon: **GENERALIZING THE EXECUTIVE** (post-B-EXEC:
preemption per the named small-step/fuel deferral, and beyond).
Morning: he reviews the council pack + tiny-Rust v1.9 + the story.

OPEN ITEMS:
- **COMPILER'S UNREGISTERED GATED ITEMS (swept into the register
  08:1x per the re-raise clause's own first job — an item never
  registered cannot be protected; compiler's declared-interest
  find): (a) raise the saltbuild DEFAULT cap 12000→24000 (still
  CAP=12000 in the wrapper; compiler's 01:34 recommendation, its
  own interest declared — registered ≠ endorsed, a maestro ruling
  at council decides) · (b) import owed: SubFragment, SingleLevel
  (line-57 records the CONVENTION, not these two specific debts) ·
  (c) ImmediateScope retirement via the aiming rider (already noted
  below, compiler's slot). Re-raise clock: council.**
- **RE-RAISE CLOCKS ON GATED ITEMS (silicon 07:5x, `a standing order
  outlives its world`): every authorization-gated open item wants a
  RE-RAISE cadence, or it dies quietly the day the authorizing word
  stops coming — a gate is not a grave. Rule: any item GATED on the
  Captain's word that has not moved in a review cycle gets
  re-surfaced at the next council, not left to rot in silence.
  Applies to W5, the ③+④ session, (7.3), B5, and the two neural
  sketches' design-team questions (those are SCHEDULES awaiting a
  Fable-tier slot, not ruling-dependencies — re-raise when the slot
  opens, not when a word is owed).**
- **THE CAPTAIN'S STANDING WORDS (recovered 08-09 02:1x from the 22
  early-format posts invisible to every filter — silicon's triage,
  compiler's ask; now in the register where standing law lives,
  single-ownership rule): [8/6 18:11] the public-TT-repo is GO
  ("#1: yes", verbatim) · [8/6 19:16] THE CHARGE, verbatim: "No
  idling…" · [8/7 10:50] CAPTAIN'S INTENT: HE WANTS THE CPU
  FABRICATED, his sizing "BB in ~2 tiles" (the night's tile arc
  executed this intent before the filters could see it) · [8/6
  council I] the seam doctrine stands ratified. Originals at their
  bus lines; this entry is the durable recall surface.**

- **COUNCIL RULING #5 (09:4x, the Captain, verbatim: "for the pure
  RISC-V path let's keep the dmem8 + offboard memory"): the pure
  RISC-V core's memory architecture is SETTLED — dmem8 onboard as
  data scratch, program + bulk data offboard via the 8-bit
  multiplexed pinout (RP2040-served, the standard TT pattern).
  The latch-array probe continues as LADDER KNOWLEDGE (it gates
  the packet-boot idea, not this path). ACCOUNT-CHECK COMPLETE
  same sitting: five seats, five accounts, one-to-one, zero
  divergence (one account per seat); maestro is ALONE on jason — the
  tier-drop seat had no same-account control, now measured.
  PACKET-IO APPLICATION SLATE under discussion, his framing:
  1) packet filter, 2) CPU as smart neuron, 3) switch fabric as
  NN "presumably using bit-serial multipliers, requires
  discussion"; #1 and #2 use offboard memory (his word), #3's
  memory story is part of the open discussion.**

- **CORE-ACCOUNT COMMISSIONED (13:2x, the Captain, verbatim:
  "let's do it!") — docs/core-account.md skeleton on the tree; the
  bb-switch-account 70-min pattern: compiler kernel half (measured,
  #eval'd) · silicon priced half (3x2 signoff artifacts) · maestro
  joint reading · math standing refutation · evidence fence pass.
  GATE: §1 final row table awaits assembly rows 15-16; halves
  proceed now.**

- **THE TRACE INHERITANCE — LANDED (c2428b3, fresh executor,
  covering build in flight): the full-state per-cycle step (both
  64 state bits, compiler's cell_wsh_next citing), the trace
  induction (cellSeq_runTrace_state), THE INHERITANCE
  (cellSeq_inherits_macSeq_state — the composed cell's
  accumulator half IS rung 3's state over the manufactured addend
  trace), join + signed corollaries with cited conjuncts, four
  mutants RUN on the real 193-gate netlist by decide +kernel incl.
  the spanning-trace state-discipline mutant in full. Docstrings
  theorem-sized; forbidden sentence absent.
  ⛔ FINDING 1 — TOMORROW'S DESIGN ITEM #2 (beside the top module):
  THE SIGN CYCLE IS NOT EXECUTABLE ON THE COMPOSED CELL, kernel-
  checked refutation landed: ccCore's addend port carries only
  andWord x w (0 or the weight register); NO COMPLEMENT PATH
  EXISTS in the netlist — the (b) ruling's planned bitNot32 stage
  was never integrated into ccCore. The signed MAC's full trace is
  not a cellSeq trace until the complement path is designed in
  (bitNot32 row on the addend, or the priced XOR-bank alternative).
  The accumulation-phase join stands; the SIGNED claim for the
  COMPOSED cell waits on hardware, not proofs.
  ⇒ FIRED TONIGHT 8/9 18:5x at the Captain's word ("we can
  proceed"): compiler's write track, XOR-BANK FORM adopted by
  maestro ruling (addend XOR sign, one gate level, 32 gates,
  replaces inverter bank AND select, maCin same-signal; semantics
  acc+~x+1 unchanged from ruling (b)). **CAPTAIN-CONFIRMED 18:5x
  ("yes please fire away") — the amendment flag RETIRES; the path
  is clean end-to-end.** Math gated behind the landing for the
  signed trace inheritance; silicon MEAS reactive; timing MEASURED
  never predicted (silicon's refusal binds all seats).
  ✅ **LANDED 19:05 (7364548, compiler, fire-to-kernel in 16 min):
  `scellSeq`/`scCore` 225 gates BESIDE `cellSeq` — compiler's own
  object (MacCell.lean:702), with math's 26 MacBridge theorems
  ABOUT it untouched (the expensive side, taken deliberately:
  statement-shape-is-an-interface; consumer consent, not
  ownership, gates retirement — compiler's 19:14 precision).
  `sign` REPLACES cin, nIn stays 3, emitted boundary will stay
  67/96. 32 audited theorems — 31 at landing + the one rfl
  coverage gap (scSign_eq_ccCin, harmless) silicon's MEAS caught
  at 19:10 and compiler closed at 80c572a (32/32, 89 ticks);
  three mutants on the real 225-gate netlist. SEALS: silicon MEAS NO DEFECT (kernel-green own-hand)
  · MAESTRO COVERING BUILD saltbuild EXIT=0, 8,677 jobs. MATH'S
  GATE ② IS OPEN (compiler's three facts: the object is scellSeq;
  macSeq untouched so cell_computes_signed_mac applies without
  restatement, addend becomes cmplWord s (andWord x w);
  scellSeq_env_is_cellEnv landed as rfl). ⚠️ F5 SEMANTIC DRIFT
  REGISTERED (silicon's catch): mac_cell.v is STILL the unsigned
  16:02 emission — f5_port_test EXIT 1 now means LANDED-NOT-YET-
  EMITTED, not nothing-happened; silicon's signed emission is the
  cure and is in flight. Timing: still NO nanoseconds published —
  measure on the emitted artifact.
  ✅✅ SEALED THROUGH SILICON'S STEPS (1)(2)(3) BY 19:34: signed
  cell EMITTED (F5 a+b met on the emitted netlist) + HARDENED as
  a CONTROLLED PAIR ON ONE DIE (configs 3a8b452, netlist 0e88bad;
  DRC/LVS/antenna/max-slew 0 both arms). THE MEASURED COST OF THE
  COMPLEMENT PATH: +332.82 µm² stdcell (+9.79%), logic 190→222
  (+32 = the XOR bank exactly; both arms purge the same 3
  unobservable gates), setup margin at the slow corner +2.0831 →
  +1.1123 ns — BOTH ARMS CLOSE AT 55 ns; THE CLOCK RULING HOLDS,
  now measured on the signed artifact. The chain reconciles
  kernel→emitted→liberty→post-layout to 0.0024 µm², and xor2
  survives LibreLane's yosys 96→96 — fabbed-is-verified MEASURED
  (net NAMES do not survive synthesis: criterion (d) checks the
  EMITTED netlist only). Method note banked: FP_CORE_UTIL sizes
  the die FROM the cell area — the first attempt was two
  different dies, caught by its own control (DPL-0036). Step (4),
  the EUR-280 settling run, STAYS GATED on the top-module block
  clearing its refuter pass — a block under refutation is not a
  ruling (silicon's words).
  ✅✅✅ ITEM ② SEALED 21:4x (the covering build stood owed from
  19:17 — math named it twice without complaint; the maestro's
  miss, discharged): 81bf3d2 (19:17, TEN MINUTES after the gate
  opened) = scellSeq_computes_signed_mac — THE SIGNED TRACE
  INHERITANCE ON THE COMPOSED SIGNED CELL, with
  cell_addend_cannot_present_the_sign_operand still true and
  still in the file (the refutation and its answer coexist).
  SEALS: silicon MEAS clean 19:21 · maestro covering build
  saltbuild EXIT=0, 8,677 jobs (21:4x). THE BOUNDARY, math's
  line kept verbatim: F5 CLEARS ON THE DATAPATH AND KEEPS
  BINDING ON THE CONTROL — the theorem is true of a trace the
  cell CAN present and not yet of a machine that DRIVES ITSELF;
  the supplier is the sequencer (V9/D10.7, the sitting's item).
  ⇒ THE NEURON IS SEMANTICALLY WHOLE — accumulation AND sign —
  at the kernel model on the composed artifact, dream to
  signed-silicon-candidate in under one day; the chip-level
  "down to silicon" still closes only at the top-module run
  (F3).**
  📌 FINDING 2 — AUDIT-COVERAGE CAMPAIGN CANDIDATE: Sem.lean's
  "real number is zero" note is stale — ⛔ 204 ⛔ (THIS FIGURE IS
  STRUCK — the true number is 180; read the supersession block
  below before quoting anything from this sentence) unaudited
  theorems corpus-wide (CorePlace 38 [struck: 37] · CoreOffsets
  23 · TinyRustN0 23 · MacBridge's 32 pre-existing · others); the
  executor audited its own 16 with an explicitly-scoped block. A
  sweep candidate for the doc-refresh campaign.
  ⇒ **FIGURE SUPERSEDED 22:3x AT THE MEASUREMENT (three hands,
  three methods, reconciled on the bus 21:4x-22:3x; registered on
  silicon's 22:31 report — its own law arriving from the far side,
  "my measurement never left the bus"): THE NUMBER IS 180, NOT
  204 — 232 total − 52 in GITIGNORED Scratch*.lean (the census
  tool counts development scaffolding; the tool lives in
  docs/hdl-tools/ and ITS FIX IS UNCLAIMED); CorePlace is 37, not
  38. THE PARTITION, claimed in protocol form overnight: compiler
  83 · math 47 · silicon 35 · RESIDUAL 15 (floor of 10 =
  SelfRouting) — the residual-15 assignment and the census-tool
  fix are the sitting's two remaining decisions here. Sem.lean's
  zero-note is still stale AND the 204 replacement was stale too
  — both die at this line.
  ⛔⛔ AND THE 180 IS HELD TOO (silicon 07:31, found by opening
  its own claimed files): the census tool has a SECOND defect — it
  compares qualified #audit_axioms names against bare in-namespace
  declarations WITHOUT NORMALISING, so 32 correctly-audited
  theorems across SIX files read as unaudited. TRULY UNAUDITED:
  138 (PartialLoad: census said 18; the file's own audit block
  names 16 of them — truly 2). AND THE CONFESSION THAT MATTERS
  MORE THAN THE NUMBER: the 21:51 "confirmed by a third hand, by
  a different method" was FALSE in the half that mattered — all
  three hands ran audit_completeness.py; one instrument thrice is
  ONE measurement (agreement-is-not-corroboration, silicon's own
  law, owned in full). WHAT SURVIVES: the gitignored-52 defect
  (independently confirmed) and the PARTITION SHAPE by owner; the
  per-owner NUMBERS re-derive after compiler's tool fix (which
  now answers TWO defects: gitignore class + name normalization).
  No figure from this entry travels to the Captain except
  138-provisional-on-the-tool-fix.**

- **THE COMPOSED CELL — STATE AT ITS EXACT SIZE (compiler's 16:03
  trim of the maestro's verdict — the FOURTH one-theorem-larger
  sentence today and the FIRST cut by the seat that would benefit):
  one module, 193/193, SHAPE-CERTIFIED with the seam and
  disjointness proved (cell_seam_is_the_addend — the right-wire
  claim port by port; cell_instances_are_disjoint — the pair
  property instOK cannot express) — the composition's per-cycle
  theorem was OWED at compiler's seam — **DISCHARGED 17:20,
  covered EXIT=0: the cell's cycle IS the accumulator's cycle on
  the addend the weight organ made. The emission CAN now inherit the
  join — math's 17:21 precision: A CAPABILITY, NOT YET A THEOREM;
  the remaining arrow is the trace-level induction over cellSeq
  (the same gap math crossed for macSeq at rung 3). The maestro's
  fifth one-arrow-larger sentence, trimmed within minutes like
  the other four. HONEST STATE: per-cycle composition PROVED ·
  trace inheritance OWED (small, shaped by precedent) · then the
  neuron is semantically whole.**

- **THE NDF CLOCK — RULED 15:5x at silicon's discriminator (the
  red is REAL, not a die artifact: mac_acc's 32-bit ripple carry
  misses 25 MHz by 0.9%; quadrupled density bought 0.046 of the
  0.388 ns needed, wirelength unchanged — the chain is the floor):
  **RE-RULED 16:0x — THE NDF RUNS AT CLOCK_PERIOD 55 (~18.2 MHz)**:
  silicon's composed-cell measurement showed the 20 MHz valve was
  priced on mac_acc ALONE — the composed cell's worst path is
  50.939 ns (the WSHIFT→AND→ADDER seam adds 10.60 ns THAT NO
  PARTS-MEASUREMENT COULD PREDICT — the parts-vs-composition
  lesson as a number). 52 closes with +1.06 ns; 55 ships with
  +4.06 ns — margin bought in the free currency ahead of the
  floorplan run's unknown costs. Still zero silicon, still one
  config line, frame protocol still indifferent.
  ADDER SURGERY REFUSED for the PoC (config-beats-organs, the
  wiring-beats-organs prior's cousin; CLA/skip stays priced on
  record if a future clock demands it). THE AGREEMENT LAW RIDES:
  when the NDF submission repo is assembled, config.json AND
  info.yaml declare 20 MHz TOGETHER (the BB's lesson was the
  agreement, not the number). Unmeasured remainder, honestly:
  the fabric-floorplan run re-measures beside BB + core; the
  carry chain is a floor no floorplan improves, and at 20 MHz it
  carries 9.6 ns of margin for whatever the floorplan costs.**

- **THE CELL WAVE — RUNG 4 SEALED, THE RESIDUE BOARD (14:5x):
  a2c6470 landed (fresh Opus hand, 4b induction first attempt,
  three mutants kernel-FALSE incl. the total-only wrong-theorem
  refutation) + e2e966b headline amended per math's review (psum
  not sval). SEALS: math ENDORSED (content) · silicon MEAS green ·
  maestro saltbuild EXIT=0 x2. REMAINING, two named items, the
  reviews' two halves of one rung: (i) hW-DISCHARGE — compose the
  weight-shift organ (its per-cycle theorems ARE the assumed
  weight schedule) + the SECOND overflow condition compiler flagged
  (W<<<t register overflow — exists nowhere yet, needs shaping);
  (ii) SIGN-CYCLE COMPOSITION — FINAL: COMPILER'S OPTION (b) +
  LOAD-PATH OPTION A, RULED TOGETHER (restored 14:5x after a
  ten-minute governance arc, full trail): macSeq gains a carry-in
  port (nIn 32→33, gates 161→160, const gates 0); sign cycle =
  acc + ~x + 1 via the LANDED idiom
  subtraction_is_a_plus_not_b_plus_one + certified bitNot32;
  load path = port not constant; carry_in_is_low retires
  deliberately; the cell ends ZERO constant gates, two admitted
  ports; six per-cycle restatements ONCE. MATH'S LEDGER NOTE now
  IN the ruling per its 14:52 ask: the proof-side cost (the
  restatements + the carry-in composition lemma) is real and
  owned at math/compiler's seams — "strictly dominates" was
  gates-only. THE ARC, kept for governance: ruled → amended on
  silicon's crossing schedule-negated argument → silicon WITHDREW
  in six minutes (it priced a MID-STREAM reload, a mechanism its
  own stream_bit_never_enters_the_weight_register proves absent —
  "second time in fifteen minutes I estimated where they built")
  → restored. LESSONS BANKED: constructions outrank estimates
  EVEN when the estimate's principle is banked-and-true — a
  principle applies only where its mechanism exists; and the
  tied-constant-is-an-unadmitted-port pattern stands (3rd
  measured instance). Nothing was built on any intermediate
  state; the whipsaw cost zero work.
  SETTLEMENT COMPLETE 14:58 — THE FREEZE LIFTS: all three protocol
  pieces delivered (silicon's specifics · math's two-form proof
  ledger · compiler's artifact adjudication), and the adjudicator
  ruled against its own last reversal: schedule-alone is
  arithmetically sufficient but MECHANICALLY costs +32 cycles per
  input (option A's injection width is one bit per cycle — no
  short load exists in the artifact). (b)+A CONFIRMED FINAL by
  the loop, not by default. Implementation clear: compiler (b)+A;
  math the rung-1-3 restatements (rung 3 → (addend,carry) pairs)
  + hW-discharge + second overflow condition against the settled
  interface. PROGRESS 15:3x: (b)+A implemented (b070e38+b801003,
  193 gates, zero constants) · restatements landed (d7d1d6a,
  collision survived 7/7) · compatibility corollary (c08f6a1) ·
  hW-DISCHARGE LANDED (03f5885, attempts 2, wshift_runTrace_state
  = W<<<t after t load-low cycles, covered EXIT=0) · second
  overflow condition ALREADY EXISTED as compiler's landed
  shiftSafe+shiftSafe_at_int8_scale (my dispatch mis-attributed
  it to math; read-before-building caught it free) · SIGN CYCLE
  LANDED 15:41 (3c62228, attempts 3, cell_sign_cycle: acc + ~w +
  1 = acc − w on the (b)-admitted port; off-by-one mutant run;
  rung 3 unchanged — the separate-stepSeq deferral vindicated;
  the :66-68 stale prose past-tensed in the same commit; covered
  EXIT=0 8,677 jobs).
  ⭐⭐ THE CELL WAVE IS COMPLETE AT THE KERNEL MODEL — THE JOIN
  LANDED FIRST ATTEMPT (c732aaa, 15:46, covered EXIT=0 8,677):
  the composing theorem exists — trace + sign cycle + mac_correct
  = b + W·sval — so the trimmed sentence is now TRUE AS A THEOREM
  (trim 15:44 → truth 15:46, twenty-two minutes). BOUNDARIES
  INTACT: evidence's F3 (kernel-model certified; down-to-silicon
  closes at emitS + synthesis) and F4 re-running at evidence's
  fence against ARTIFACTS not status lines (its own 15:46
  clearance withdrawal — trusted the audited doc's status line,
  second instance). NEXT: emitS (compiler, gate open; its 15:45
  emission-criterion corrections govern silicon's parked run).
  The parts: two organs (accumulator w/ carry-in +
  weight-shift w/ load gate, zero constant gates, 193 gates) ·
  the bridge (rungs 1-4, arithmetic reading under ¬saddOverflow,
  demoBound-discharged) · add, shift, AND subtract in the kernel.
  NEXT GATE OPEN: emitS the cell (compiler's genre, pre-authorized
  by the September scope law "kernel Circ + emitS from day one")
  → silicon's EUR-280 settling run fires on the emitted RTL.
  Trap banked: BitVec.shiftLeft_shiftLeft does not exist — the
  real name is BitVec.shiftLeft_add.
  Every seat argued against its own position at least
  once in this thread; the register moved twice and both moves
  are in the trail.**

- **CROSS-SESSION MESSAGING — ADOPTION PLANNED AT NEXT RELIGHT
  (the Captain flagged the new system 14:1x; assessed from the doc
  + live probes): binary 2.1.226 HAS it; every RUNNING session
  predates it (sockets unbound, zero local peers — only cloud/
  Remote-Control rows). WHAT IT REPLACES: the tmux send-keys NUDGE
  layer (addressed delivery between tool calls; kills the
  keystroke-fragility class — Enter-separately, input-box
  stranding, ghost text). WHAT IT DOES NOT REPLACE: the BUS —
  durable append-only record, broadcast, watches; DOCTRINE:
  messages carry POINTERS, the bus carries the RECORD. RELIGHT
  CHECKLIST: (i) name seats via --name in fleet-up.sh (silicon/
  compiler/math/evidence — dir-derived names would collide);
  (ii) verify /list-agents shows all four locally post-relight
  (per-seat CLAUDE_CONFIG_DIR may affect registry — TEST);
  (iii) bypass<->bypass default-delivers, no settings needed;
  (iv) LANE FIREWALL EXTENDS TO THIS CHANNEL: never message
  outside-lane sessions (visible in listings); consider
  isolatePeerMachines:true. NOT worth restarting a humming fleet
  mid-campaign for a nudge upgrade — adopt at the natural cycle.**

- **THE CELL WAVE — THE BRIDGE NODE, RULED at math's 13:36
  refusal-of-credit (its own wave's): maestro's "NDF critical path
  CLOSED" is STRUCK — the honest state is TWO hardware theorems
  (bnC_payload_delivered about batcherNetC; batcher8_sortsTo_word
  about runNetW) + ONE SPEC (mac_correct, arithmetic model, no
  hardware attached). THE BRIDGE = the ONE unbuilt node: (i)
  macSeq — the neuron cell as a kernel Seq/Circ over the organs
  (COMPILER's genre, sequenced after W5-asm rows 15-16; this IS
  the September scope-law "cell as kernel Circ + emitS from day
  one" item, now named as the bridge); (ii) the refinement lemma
  macRun ≈ runTrace macSeq (MATH, author-anywhere land-at-owner
  against its own mac_correct; bit-level carry reasoning — priced
  honestly as NOT-four-minutes); (iii) emitS of the cell (the
  fabbed-is-verified law); (iv) silicon's EUR-280 settling run
  FIRES on the RTL from (i). Genre closed; bridge OPEN; the chain
  completes at (ii).**

- **FUEL COLUMNS — CONFIRMED AT GROUND TRUTH (13:3x, the Captain,
  verbatim: "the columns are account-name,5h,all-models,fable-only
  (fable gets to spend at most half the total budget). Budget on
  jason has the weekly reset tomorrow 4pm, I believe we are going
  to make it."): triple = (5-hour session %, all-models weekly %,
  FABLE-ONLY weekly %); STRUCTURAL LAW: fable's allowance = at
  most HALF the total budget. jason reset = SUNDAY 8/10 16:00
  (SUPERSEDES the earlier "Mon 4pm" note). Burn arithmetic at
  confirmation: fable 51->62 over ~18h ≈ 0.6%/h -> ~78 at reset —
  WE MAKE IT, per his word and the numbers agreeing. Watch rule
  >= 80 stands as backstop. compiler-acct 7/jasonh 3 = fable residue from
  pre-switch sessions (prediction: frozen until reset).
  [History below: the narrowed-hypothesis entry this supersedes.]**
- **THIRD FUEL COLUMN — SEMANTICS NARROWED BY THE CAPTAIN'S DATUM
  (13:3x, verbatim: "*all* the other seats run Opus 5, and credits
  are not being used on any of them"): the CREDITS reading is DEAD
  for the peers (compiler-acct 7 / jasonh 3 are NOT credits); the surviving
  reading = the PREMIUM-TIER WEEKLY METER (effectively the FABLE
  meter) — jason 62 climbing = the maestro's Fable hours; peers'
  zeros = in-plan Opus 5; compiler-acct/jasonh small residues = candidate
  provenance: pre-switch maestro sessions earlier in the week
  (PREDICTION: frozen until Mon reset while jason alone climbs).
  RESIDUALS for the Captain's next portal glance: the column's
  literal LABEL + the pre-switch-host confirmation. WATCH RULE
  ARMED (maestro): any reported jason triple with third column
  >= 80 -> immediate flag + the HARD house-split (Opus for
  coordination/ceremony, Fable strictly for design blocks).
  Operational fact: the fleet's entire premium burn is ONE seat;
  four seats run at zero marginal premium cost.**

- **NDF PACKAGE APPROVED (13:2x, the Captain, verbatim: "NDF
  lgtm") — the design package v1 (through the r-convention, the
  k-collision banner, §§1-6 + 2b/2c/3b/5b/5c) stands APPROVED as
  the NDF's design baseline. Subsequent changes are amendments to
  an approved document, not drafts.**

- **COUNCIL BUNDLE (12:0x, the Captain, slate items): (2) COST
  WINDOWS "so ruled" — story row = dream->ruling (1.14M measured),
  cost row = NDF-from-T0, campaign total separate, every number
  names its window; (5) PCBs RIDE THE NDF ("for the BB I will
  probably not get PCBs, but let's use them on NF"); IMMEDIATESCOPE
  RETIRED (authorized + executed: remove + saltbuild EXIT=0,
  8674->8673 jobs, the rider's own proof form); DEFAULT AUDIT CAP
  RAISED 12000->24000 (saltbuild.sh CAP line + comment; the --cap
  dance for known heavies retired; machine guard remains the fleet
  lock); (7.3) CLICK SPENT (12:0x, his verbatim "assemble (7.3)")
  — the Opus assembly wave DISPATCHED (salt repo, math-seat
  pattern; flags anchors 21293/22150/22257 as statement source,
  precondition preamble, saltbuild-only, warnings-by-difference,
  axiom check, one pathspec commit, stop-loudly-on-resistance);
  ✅ LANDED 12:2x FIRST ATTEMPT — sawtoothMajorant_fourier_expansion
  + hasSum_majorantCoeff (Salt/Weil/MajorantExpansion.lean, salt
  e2307cc pushed): HB (7.3) literally, K>=2, every real theta;
  axioms clean x7 rows verified twice; saltbuild EXIT=0, 9722 jobs,
  warnings 190->190; mutation control ran properly (FALSE mutant ->
  EXIT=1, byte-identical restore, green rebuild); two flags naming
  facts corrected (root-namespace fourierCoeff; Fact (0<1) local);
  the one out-of-pathspec stale dossier row fixed by maestro
  (a1f8f0b). THE WEIL SAWTOOTH KIT (7.2)+(7.3)+(7.4) IS COMPLETE; (4) the 3+4 deep session CONFIRMED NOT YET HELD (the
  evening went to the tile/packet/neural arc; subjects crossed the
  helm at their landings — the deja vu source); proposal open:
  fold into an NDF theory review sitting. RISC-V ACCOUNT DOC:
  does not exist as one artifact; commissioning offered (the
  bb-switch-account 70-min pattern). THIRD FUEL COLUMN: "credits"
  hypothesis before him, awaiting one-word confirmation.**

- **THE SHUTTLE DEADLINE — THE SCHEDULE ANCHOR, CAPTAIN-CORRECTED
  11:5x: HIS LOGGED-IN PORTAL SHOWS 29 DAYS TO RESUBMIT ≈ SEPT 7
  (corroborates the standing B5 Sept-7 date; GOVERNS over the
  public-site fetch's "SKY26c, 44 days ≈ Sept 22" — possibly a
  different shuttle; his account view is authoritative). 3x2 slots
  still available per his read. Login portal = app.tinytapeout.com
  (GitHub sign-in — separate subdomain, no login link on the main
  site). Early-bird pricing limited per shuttle. ALL NDF
  SCHEDULING BACKS OUT FROM ~SEPT 7 — two weeks tighter than the
  first estimate.**

- **NDF TILE SHAPE — AWAITING THE CAPTAIN'S PURSE RULING (silicon's
  probe answer, 11:46, post-layout measured): minimal demo (k=4 +
  8x8 BB + core) requires 6x2 = 12 TILES, EUR 840, TWO-HIGH
  (unscarce shape; 3x4 = same capacity but burns one of two scarce
  4-high slots — refused). 6x2 actually delivers k=7-9 headroom.
  Ladder: 2x2 core-does-not-fit · 3x2 core-only (1,399 um^2 spare
  — this morning's approval stands FOR THE CORE, cannot be the NDF
  tile) · 4x2 k=2-3 short · 8x2 EUR 1,120 k=12-15 (stretch, not
  recommended). MYTH BUST: the "24-tile cap" = the 6x4 SHAPE (and
  the pinout count) — documented max is 8x4=32. Density lever
  50->60% ≈ +20% cells, NOT recommended without a slew run.
  MAESTRO RECOMMENDATION: 6x2 at EUR 840.
  RESERVATION TIMING RULED (11:5x, the Captain, verbatim: "I'll
  not reserve the 6x2 until we are close to layout. If we get
  bumped to the next one (2 weeks later) it is ok"): NO early
  reservation; reserve at layout-readiness; a one-shuttle slip
  (~2 weeks past ~Sept 7) is ACCEPTABLE. Full throttle unchanged —
  the target stands, the deadline is soft by his word.
  THE EUR-280 QUESTION (silicon 11:55, pending measurement —
  auto-resolves inside the timing ruling's window): 4x2/EUR 560
  would hold the minimal demo at 52.7-56.2% utilization — the
  UNMEASURED band (clean points 44.65/48.77%; the 63% datum was
  free-floorplan, does not transfer). Settling instrument: one
  ~10-min hardening run, 4x2 die, synthetic 71.8-76.6k um^2 load —
  FIRES THE MOMENT THE CELL RTL EXISTS (silicon's first run).
  Until then 6x2 stands, now measured-ROBUST (35-37% util).
  SILICON'S 12:09 ADVERSARIAL SELF-CORRECTION (recommendation
  SURVIVES, inputs corrected): (i) the floorplan had used the bare
  BANYAN not the BB — fabric understated ~4,159 um^2 (0.7 cell);
  corrected 6x2 util = 36.5-38.8% still comfortable; 4x2 = 55.4-
  58.9%, deeper into the unmeasured band. (ii) the "24-tile cap"
  myth-bust WITHDRAWN — the 24 is the PIN budget (design doc §3b),
  an arithmetic coincidence published as provenance. (iii) THE
  INVERSION: k IS CAPPED AT 4 BY FABRIC PORTS (8 = 4 cells + CPU
  + 2 edge + 1 spare), NOT by area — bigger tiles buy unaddressable
  silicon; 6x2 is the RIGHT size, not merely sufficient; k>4 needs
  a bigger FABRIC (16x16, v2), never a bigger tile.**

- **NDF BENCH HARNESS (registered 11:4x at the Captain's memory-
  hassle question): RP2040 firmware = the memory-server side of the
  8->32 multiplexed bus (PIO state machines: latch 4 addr bytes,
  serve 4 data bytes — the standard TT ROM/RAM-emulator pattern,
  ~100 lines PIO+C) + the packet-port side (feed weight/input
  packets, capture results). STATUS: scheduled September work,
  small; OUTSIDE the verified surface (test equipment, same trust
  class as the logic analyzer). The CHIP side of the protocol is
  ALREADY BUILT AND SIGNED OFF (slicea16bma's phase demux, 3x2
  die). Owner: assign at the harness seam (compiler or silicon).**

- **COUNCIL RULING #8 — THE WIDTH RULING (11:3x, the Captain,
  verbatim: "Yes, the word width is not important for the PoC,
  let's rule 8-bit"): VALUES ARE 8-BIT FIXPOINT (weights +
  activations — the quantization story stands and supplies the
  cheap overflow bounds); WORD WIDTH ruled UNIMPORTANT for the
  PoC ⇒ implementation takes the seats' converged free path:
  the LANDED 32-BIT DATAPATH carrying int8 values sign-extended
  at ingress (option-2 mechanics). Zero new certificates
  (wordSignedOrder + CE + adder32 all reused at 32); activation
  compares at 32 (math's width question CLOSED); no-overflow
  witness trivial from the int8 bound (B5 discharged by decide);
  NO requantization organ in the minimal demo; 8-bit-NATIVE
  datapath (8b latches, 8-cycle MACs, shift+saturate requant) =
  the v2/production optimization, priced as reference only.
  Decision inputs that converged: math's certificate ranking
  (2)<<(1)<(3); silicon's "area should not decide this" (native
  saving does not change tile count).**

- **COUNCIL RULING #7 — THE PATH RULING (11:3x, the Captain,
  verbatim): "This is my proposal: * Keep the pure BB switch, I
  will update TT * Keep the pure RISC-V + 5 op ISA + EXEC + tiny
  Rust + sort demo; defer submission to TT * Full throttle on the
  new Neural Dataflow Fabric, new submission to TT, target in
  Sept, we start as shown in the THE FABRIC, I assume we adapt
  EXEC as needed, tiny-Rust is probably unchanged."
  ⇒ THREE-PROJECT STRUCTURE: (1) BB switch — kept, Captain
  handles the TT update himself; (2) pure RISC-V stack — runs to
  COMPLETION (per ruling #4: complete/verified/tapeout-ready),
  TT submission DEFERRED — costs nothing, the core ships INSIDE
  the NDF as its control plane; (3) NEURAL DATAFLOW FABRIC (NDF,
  his "THE FABRIC" = design package Sec2 chip diagram: BB + k
  cells + core, one combined project) — FULL THROTTLE, NEW TT
  submission, SEPTEMBER TARGET. EXEC adapts (phase sequencer:
  LOAD_W/rounds/ACTIVATE/EMIT as executive-scheduled tasks);
  tiny-Rust ~unchanged (possible v2.1 packet-IO intrinsics).
  ALL FOUR Sec7 PROBES FIRED at this ruling (silicon cell+
  floorplan vs the 24-tile cap · math MAC induction — CRITICAL
  PATH — + signed-order discipline · compiler layer-compiler
  rows beside W5-asm · evidence fence armed, clock starts).
  MAESTRO'S FLAGGED RISKS AT DISPATCH: (a) NDF is the LARGEST
  project yet — tile count vs 24 must land EARLY; (b) Sept =
  ~3-4 weeks — demo scope freezes early (minimal: k=4 cells +
  8x8 BB + core, ONE GNN layer, bench demo; multi-layer/training
  = stretch); (c) the cell is built as a KERNEL Circ + emitS from
  day one (the fabbed thing IS the verified thing — no hand RTL);
  (d) the actual TT shuttle deadline is the Captain's TT-update
  errand — flagged as the schedule anchor.**

- **COUNCIL ITEM (10:2x, the Captain — the #3 DETAIL PACKAGE,
  conditional not yet a ruling): "Yes, dataflow architecture, of
  course :)" — he likes the path ("close to home but not too close…
  very close to home personally") and framed THE STORY: "I had a
  revelation in the middle of the night! What is the total cost to
  bring it all the way from that unconscious dream to PoC silicon,
  *verified* every step of the way? ~2days for the design, ~20M
  tokens, ~$500 for TT" (numbers adjustable). His SIX ASKS, all
  delivered 10:2x in docs/neural-fabric-poc-design-v1.md (§1 cell
  + block diagram + LSB-first answered: not a problem, sign-cycle
  op mux, parallel accumulator boundary; §2 fabric chip+system;
  §3 CPU role: yes, control plane, the W5-asm core; §4 GNN worked
  example w/ 3-row verified decomposition; §5 tradeoff table) and
  docs/midnight-to-silicon-story.md (§6 the running story log w/
  evidence-fenced cost table). SEAT PROBES (§7: silicon cell
  pricing/floorplan · math MAC-induction scoping · compiler
  layer-compiler rows · evidence number fence) FIRE ON HIS WORD.
  DECISION PENDING: choose this path / shelve with drawer alive.**

- **COUNCIL RULING #6 (10:0x, the Captain, verbatim: "Both 1 and 2
  are good choices, but I need to work through 3a/3b to convince
  myself if there is anything new here, or it was just a dream. So
  let's defer 1 and 2 for the #3a/b discussion, then we will circle
  back."): #1 AND #2 DEFERRED-NOT-DROPPED; #3 discussion is the
  active council thread. His lead questions on the table: (q1) the
  unit of operation — his sketch: values bit-serial on one input,
  weights (+bias?) on another, weighted sum then nonlinearity
  ("the Batcher mux?"); (q2) generality — CNNs, GNNs, etc.
  Maestro's council answer given (the fused cell: latched-weight
  serial MAC + bias-as-preload + certified CE-as-ReLU; generality
  via the {affine,max,route} = piecewise-linear = ReLU-family
  characterization; GNN-native reading; softmax honestly flagged
  approximable-not-native; novelty = the VERIFIED stack, not the
  hardware genre). LATCH LADDER same sitting: storage 35%
  smaller/bit than flops (silicon, method validated against
  measured flop table); does NOT rescue packet-boot imem — SRAM
  remains the onboard-program rung; full latch figure needs
  explicit PDK cell instantiation, Captain's call whether the
  rung closes at 35%-on-storage.**
- **COUNCIL RULING #3 (09:0x, the Captain): B-ISA AND B-EXEC WAVES
  ARE GO — "Either way, we will want to do the B-ISA, B-EXEC
  waves." SEQUENCING per the block's own capacity law: B-ISA
  per-op waves interleave at compiler's seam as tiny-Rust N-waves
  clear (one write track); B-EXEC follows B-ISA structurally,
  DRIVER row first. FINAL LAYOUT IS DEFERRED until the packet-IO
  discussion — his two options, verbatim: "1) BB (silicon), RISC-V
  (silicon, separate project from BB)  2) BB + PACKET-IO CPU (TBD,
  silicon), RISC-V (layout, only for now, until we decide to fab
  it)". TILE GEOMETRY DATUM (silicon, 8/9 10:35, pre-registered
  90-min cap): 3×2 = ROUTABLE TILE (8 min to full signoff);
  2×2 = MARGINAL, not refused, not proven (stuck at 10 violations,
  168 iterations at floor) — PLAN ON 3×2; the 2×2 is a research
  afternoon only if tile money demands it. Silicon's 8/8 "REFUSED"
  verdict was withdrawn as overclaimed. THE MUX FACT THAT SHAPES
  THEM (dossier §2.2, V-SRC):
  unselected TT designs are POWER-GATED OFF — separate projects
  are never powered simultaneously, so on-die packet interaction
  exists ONLY in option 2's combined project; option 1's joint
  demo is two chips + host wiring. Per-project tile pricing; the
  owned-4 reallocation question remains the Captain's checkout
  read.**
- **COUNCIL RULING #2 (08:4x, the Captain: "Yes, fire the probes"):
  THE TINY-RUST PROVING CAMPAIGN IS FIRED, PROBE-FIRST per the
  probe-then-wave doctrine. The hpool-separate flag stood UNVETOED —
  "well-typed, pool-fitting programs compile" is the campaign form
  (lang-design v1.4). SEQUENCE: N0 PROBE LAYER first (compiler's
  slot, the HDL/CodegenSpec frame): the typing judgment as data +
  the pre-registered controls — T2 accept AND reject (`while 1`,
  i32-where-bool), F6 bigStep-inhabitation — all by decide, positive
  controls carried per the Purse; waves N0→N5 fire as probes come
  back green, statements at the v1.4 forms. MATH's standing
  refutation pass rides every statement BEFORE its wave fires (the
  slate system that produced 20 findings pre-kernel stays in the
  loop). W5 remains its own decision (agenda #4), unconflated.**
- **COUNCIL RULING #1 (2026-08-09 08:4x, the Captain, verbatim: "we
  have the RISC-V layout fitting in a 3x2 -- we will want this
  layout no matter what, even if we decide not to submit it, so
  let's approve and make it real"): THE 3×2 LAYOUT IS APPROVED —
  MAKE IT REAL. The work is DECOUPLED from the submission decision:
  hardening fires NOW (silicon's slot, PRE-AUTH under this ruling);
  the calculator read (€140/€420) no longer gates work and moves to
  SUBMISSION time (rides the B5 window, his word then). THE
  CAMPAIGN: slicea16bma at the REAL 3×2 die (FP_SIZING absolute) ·
  DRV repair (637 typical/1,678 worst-corner slew) · the
  submission-config checklist (CLOCK_PERIOD=40 reconciliation, the
  registered trap) · pin map finalization (18/24) · fetch-protocol
  design question runs in parallel, does not gate the hardening.**
- **TILE DECISION — THE CAPTAIN'S CONDITIONAL WORD IS GIVEN (21:2x,
  at the helm, verbatim on the bus): byte-wide feed + 32-BIT
  ADDRESSES multiplexed onto the 8 address pins (4 byte-phases, like
  the data) + OWN TILE — "if so, we should choose it, on its own
  tile." The EUR 280 is authorized BY HIS WORD, conditional only on
  silicon BUILDING the multiplexed-address variant (slicea16b-ma)
  green: 32-bit PC out in 4 phases over uo_out, instruction in over
  ui_in, phase strobe on uio; the pipelining question (overlap
  next-address with current-data for ~4 cyc/word vs 8 naive)
  answered at the bytes. The (a)-vs-(b) fork is CLOSED — (b) chosen;
  co-tenancy retired (byte-wide needs 10+ vs 7 available; the switch
  is itself byte-wide). History: parallel untapeable (64 sig vs 24);
  serial priced 781K instr/s; byte-wide priced FREE IN AREA
  (2,706 cells vs serial's 2,709) at 6.25M instr/s. Hardening:
  LibreLane UP (additive, PDK-copy guard); slicea16b harden
  in flight as the FLOW verdict; -ma becomes the tapeout candidate
  on silicon's green. HARDEN VERDICT (21:23): flow COMPLETE — GDS ·
  DRC 0 · LVS clear · STA +19.29 ns at 40 ns (25 MHz answered by
  STA). ⚠️ POST-LAYOUT IS 1.56× PRE-LAYOUT: 43,120 µm² stdcell =
  95.1% of a 2×2 — past silicon's registered 80% bar, the sheet
  word is TIGHT, and the 4.9% headroom predates the address path.
  The Captain's condition therefore remains genuinely OPEN on AREA
  (pins near-yes): silicon measures slicea16b-ma rather than
  reasons. Named escape if 2×2 fails: TILES BUY AREA — a larger
  tile (3×2+) preserves "own tile" at higher EUR; his word named
  the tile, not the size. DRV violations (1,391 slew/21 cap/17
  fanout) owed before any real submission; the true TT tile-fit
  run (FP_SIZING absolute) is the next measurement. -ma MEASURED
  (21:26, c939abe): PINS YES — 18 of 24, six to spare, and the
  bring-up port DISAPPEARS (the address bus IS the PC, better debug
  for free); pre-layout 29,583 µm² (+7% vs -b; fewer cells MORE
  area — flops beat logic cells; area the honest axis). ⭐ THE
  UNASKED CORRECTNESS FINDING: in -s/-b yosys DELETES 17 of 32 PC
  bits (unobservable) — "has a 32-bit PC" was true of the RTL, not
  the gates; -ma is the FIRST variant whose PC is architecturally
  REAL in silicon (31 pc_q flops). The Captain's pinout choice
  fixed a truth gap nobody had seen. OPEN: post-layout area (harden
  in flight; expected near/just over a 2×2 — tiles-buy-area frame
  adopted, size vs EUR is the residual question) and the FETCH
  PROTOCOL (latency/wait states — a named DESIGN question for the
  morning, not settled by this artifact). ⭐ -ma HARDENED (21:30,
  measured): flow complete · DRC 0 · LVS clear · timing MET
  (+16.91 ns at 25 MHz) · pins 18/24 · post-layout 45,205.9 µm² =
  99.7% of a 2×2 — silicon REFUSES the technical pass (25 cells of
  headroom with 1,678 max-slew fixes owed that ADD cells): the
  honest reading is -ma DOES NOT FIT a 2×2; A 3×2 IS 65.6%
  (CORRECTED 22:51: height ∈ {1,2,4} per the placer — no 3×3
  exists; silicon's catalogue catch),
  comfortable with DRV+ECO room. Family finding: even -b is 95.1%
  — a 2×2 was never comfortable for 16-reg/32-bit Slice A; the
  register file is the mass, fourth instrument agreeing. ⇒ THE
  CAPTAIN'S CONDITION IS MET; the executable form of his word is
  BYTE-WIDE -ma ON ITS OWN 3×2 (€420 fresh / €140 incremental if
  the owned 4 apply toward 6). RESIDUAL (T1, money): the 3×2's
  actual EUR (the 280 was the 2×2 figure — real TT price to be
  read, never inferred) — his one-word confirmation at morning.
  DRV repair owed pre-submission.**
- **COLD-CACHE REPRODUCIBILITY — CLOSED BY RETRACTION (compiler
  20:4x): the full build's module form is UNCAPPED; cold rebuild
  measured green. The corpus reproducibility gap NEVER EXISTED — it
  was a one-arm read of saltbuild's two-arm case dispatch. W6's
  census TABLE stands as readings of the AUDIT instrument: modules
  demanding >12 GB need `--cap 24000` path-form (now a QUEUE law
  above, stated BY CAUSE). Remaining council line, framed HONESTLY
  (silicon 08:15 — the "three modules" scope tilted the answer):
  heavy modules keep landing, so the question is whether the AUDIT
  default rises (cause-adequate) or the --cap rider stands
  (list-adequate only until the next heavy module) — the framing
  is the decision, so it is stated by cause.**
- **N7 DESIGN DEBTS, MAESTRO-OWED (post-council, Fable-tier — opened
  20:39 on math's exhaustion measurement): (a) the N7 ASSEMBLY design
  block (wiring the landed+composing (7.7) inputs and the kernel'd
  2-adic collapse into the road row); (b) the W4-a DESIGN CAMPAIGN
  (gap row 8: real-primitive-conductor 2-part classification;
  1,300–2,600 ln pricing CONFIRMED by math's shrink attempt — mathlib
  has the tools, not the theorem). The flagship front at solo tier is
  exhausted until one of these opens a gate.**
- **⭐⭐⭐ THE 01:0x NIGHT COUNCIL — ALL EIGHT RATIFIED (the Captain,
  at the helm past midnight, verbatim: "all recommendations
  ratified, let's fire up the fleet" + the target: "can we get
  first layout tonight"). The 07:30 sitting COLLAPSES to the ③+④
  walk — the design decisions are ruled here:
  R1 FABRIC STAGING: per-round decide+kernel fixtures for September
  (each demo round its own check on the netlist model); the Batcher
  sort-then-route seam = the named v1.1 node.
  R2 DRIVE: _1 combinational (the owned TT-CI green) · _2 flops
  (dfxtp_1 on no_synth.cells, one-sided) · the _2 settling
  measurement rides emitSeq bring-up.
  R3 FETCH = THE TAPE CONTRACT: byte k on phase (k+3) mod 4 (byte 0
  leads its address by one phase); reset quirk documented (addr-0
  instruction skipped, pc→4); the RP2040 plays a byte stream
  generated OFFLINE from the Lean runW trace, bench-asserted at
  phase_o.
  R4 CPU: September = DEMONSTRATE (verified code on its own bus,
  sequencer autonomous); conduct = B-ISA SW + port organ, v1.1;
  PC-decode strobes stay priced, unbuilt.
  R5 THE PIN AMENDMENT CONFIRMED (the Captain's word, the D10.6
  veto spent): sof+valid replace the ruled third packet port;
  frame-phase observability narrows to valid-only; the argument
  is rst_n-destructiveness once the die carries state.
  R6 THE SHELL RATIFIED: per-cell acc CLEAR + en_wsh + en_acc +
  sign-extension hold; V9 kernel model owed; OWNER COMPILER; cost
  lands in emitSeq flops — scCore and all 19:34 measurements
  untouched.
  R7: residual-15 audit theorems → MATH (SelfRouting floor, its
  lane) · census-tool gitignore fix → COMPILER (its tool).
  ⭐ THE 01:1x BLANKET (the Captain, verbatim): "do everything you
  can to make this happen. don't wait, asking for correction is
  better than asking for permission. you are pre-authorized for
  all decisions. if we can make this tonight, that *is* the gold.
  revisions can always come after should we decide." — ALL SEATS
  operate correction-over-permission for the night push; the
  maestro parallelizes by hand where it shortens the path
  (author-anywhere land-at-owner).
  R8 FIRE PLAN LIVE — NIGHT WAVES AUTHORIZED, SUPERSEDES REST:
  compiler = emitSeq → shell emission (4 cells) → SER/activation
  organ → tt_um_saltworks_ndf wrapper + sequencer (hand RTL per
  the D2(b) exemptions, 2-2-1 schedule) → per-round fixtures;
  silicon = the 4x2 settling run + the 6x2 FIRST LAYOUT the
  moment composed RTL exists (config pair 55/18181818, DIE_AREA
  6x2, the agreement law in one commit); math = standing
  refutation + residual-15 at its pace; evidence = fence rides
  every landing, demo-sentence pass owed pre-walk. FIRST LAYOUT
  TONIGHT is the named target; the fabbed-is-verified law governs
  the SUBMISSION, not the first measurement run — V1-V3/V9/V10
  land behind the layout, before any tapeout word.**
- **⭐⭐⭐ THE THREE-TIER AMENDMENT (8/10 17:0x, the Captain at council,
  his words: "for PoC no memory is fine, but it is very unrealistic, you
  can do a design today. P1 stays as it stands, LW/SW move into P2, and
  the others become P3"): the two-track ruling below is AMENDED to three
  tiers, same mechanics (clean-boundary switching · a lower tier NEVER
  gates a higher · one pen per seat), strict priority P1 > P2 > P3.**
  **P1: UNCHANGED** (the bundle + math's day-zero opener, below).
  **P2 = THE LW/SW ARC, internally gated, in order:** ① the MEMORY
  DESIGN BLOCK — maestro-owed, Fable-tier, TONIGHT (the byte-vs-word
  ruling · misalignment in the address path · F4's bridging obligation
  written before either side builds · B2's coverage discipline · the
  wS/wI encoder plan; refuter pass BEFORE any seat consumes it) ·
  ② the KERNEL LANDING (math+compiler shared, ~3 seat-days, gated on ①)
  · ③ SILICON INTEGRATION (dmem8+memif+layout, gated on ②,
  update-window scoped). No P2 pull exists until ① posts.
  **RULING (c) — PARTITION COUNT, SAME SITTING (17:0x, the Captain,
  verbatim "sure N=2"): N = 2 — two task partitions of ~7 registers
  beside the executive's own slice (task 0). X1's theorem class ranges
  over programs with `poolDemand ≤ 7`; both corpus witnesses fit; the
  E-4 overlap witness and its positive control construct as
  pre-registered. L6's N=1 incompatibility stands recorded.**
  **RULING (b) — RECORDED AS SUBSUMED (17:1x, register hygiene): the
  Captain's P1 ratification fired X0→X2 at math as SPEC-LEVEL rows,
  which IS the ruling-#3 lift the pack's ask (b) requested; math was on
  X0 within the minute. Council ruling #3's "B-EXEC follows B-ISA"
  continues to govern the COMPILED executive (X4+).**
  **RULING (d) — SAME SITTING (17:1x, the Captain, verbatim "Yes (B)"):
  RULING #8 IS RE-OPENED AND RESOLVED TO BRANCH (B) — the REQUANTIZER
  ORGAN lands: shift + saturate, ~40 gates, in the SER's sAct row, with
  its V9-class kernel model priced beside it. h ∈ [0,127] becomes a
  THEOREM; the per-network weight-side duty RETIRES; the trainer is
  freed. Ruled TOGETHER, as the refuters required: the adjoint
  convention is STRAIGHT-THROUGH 2^-s with the floor's zero-derivative
  region NAMED (the nonzero-gradient anti-vacuity control stands, else
  the adjoint theorem is satisfiable by zero). A2/A3 (P3) take this
  form; silicon's P3 roster gains the requantizer beside the SER
  shift-enable (one SER row, two organs, priced together);
  update-window silicon.**
  **RULING (f) — THE SALT PILLAR, SAME SITTING (17:2x, the Captain,
  verbatim "f-i: yes, f-ii: yes, I'll keep pursuing arXiv, no action
  needed, the clearance body responded quickly, give them more time on SaltBench"):
  (f-i) THE Pi WRITING TASK FIRES — math owns the flagship draft
  (papers/flagship/main.tex, a week cold) on its named salt days (~2,
  interleaved at its X-ladder's natural pauses); maestro reviews at
  Fable tier; THE SUBMISSION CLICK IS PUBLIC/T1, THE CAPTAIN'S ALONE.
  (f-ii) THE MAESTRO'S FABLE SEQUENCE STANDS RULED: memory design block
  TONIGHT (gates P2) · the next-rung four-agent RE-RECON fired tonight
  (agent-work, reads tomorrow) · the N7 GATE BLOCK tomorrow morning on
  the fresh recon — the flagship proving front reopens behind it.
  arXiv endorsement: HIS lane, no fleet action. clearance/SaltBench: give
  them more time — no nudge.**
  **P3 = the former P2 rosters, unchanged in content and order:**
  compiler V9 → A1 → L5 → batcher_c/SER → L6 source probe · math L3
  half → X3 → 47-row → A3 (still gated on ruling d) · silicon cocotb
  fix → 1x2/BB → DRV → tile-fit → sim harness · evidence GraphCast
  citation. NOTE: V9's demotion to P3 is the amendment's one real
  trade (it was A1's fence) — priced at the table, the Captain's word
  stands; A1 ships fenced WHEN DRIVEN until V9 lands from P3.
  Captain at council, his words: "I am willing to bet my shirt that they
  aim too low. However, I honor the refuters too… One main track
  first priority, essential, label it P1. Secondary track for longer
  shots… *if* a seat falls idle on the main track, it picks up a task on
  the secondary track. Strict scheduling, P1 comes before P2, no
  preemption." Ratified with the maestro's recommendations: "queue it
  up, with your recommendations :)").**
  **P1 (essential, the refuter bundle + the day-zero opener):**
  MATH day 0: the abstract-fold↔cSorted seam (ONE obligation, its own
  15:44 measurement) — closes the Captain's "easy and completes the
  story" pair BEFORE the campaign draws breath · then X0 → X1 → X2
  (per block ② §A: shared-regfile SysSt, bound step_frame, concrete E-4
  witness, execution-witness E-5, non-halting fairness antecedent).
  COMPILER: L0 → L1 → L2 → L4 (per block ① §A: emit_runs-shaped Row A,
  handoff exit conjunct per the 15:44 clarification, finite-domain reg
  map, range frame). SILICON: A0 (the 2-2-1 V10 fixtures).
  **P2 (longer shots, pulled ONLY at P1 idle, per seat, in order):**
  compiler: V9 (highest leverage — A1's fence AND its own debt) → A1 →
  L5 (post-L2) → batcher_c composition + SER shift-enable (shared w/
  silicon) → L6 source-side probe (no proofs). math: L3 math half
  (inlining preservation, file-disjoint) → X3 mailbox → the 47-row audit
  (decision then mechanical) → A3 adjoint semantics (gated on ruling d).
  silicon: cocotb bench fix test.py:247 (unowned→OWNED here) → 1x2/BB
  re-signoff → DRV two-population hypotheses → batcher-wired tile-fit →
  gate-level sim harness for A2. evidence: GraphCast paper citation +
  not-carried list (public-paper-only).
  **THE THREE MECHANICS (law of the two tracks):** ① clean-boundary
  switching — P2 parks AT THE NEXT COMMIT when P1 readies; banked,
  never abandoned; P2 items must be parkable. ② P2 NEVER GATES P1 —
  refutation asks on P2 landings queue as P2; no P1 rung may wait on a
  P2 obligation. ③ one pen per seat still binds — P2 prefers files
  disjoint from that seat's P1 range.
  **RECORDED WITH THE RULING (the bundle's premise, stated at the
  table, veto-in-the-moment if unintended): W5-asm and the B-ISA
  per-op waves are DEFERRED for the sprint window.** Pending rulings
  that now gate SPECIFIC rungs rather than cuts: (c) partition N →
  X1 · (d) ruling-#8 fork → A2/A3's form · (g) Row A amended shape →
  L2/L4 (compiler's reading confirmed; the form stands as clarified
  at ff43d08 unless the Captain objects at its rung).**
- **⭐⭐ THE AIM-HIGH TRIO: DRAFTED → REFUTED → AMENDED → COMMITTED (8/10
  11:4x-12:10, the successor maestro, Fable hand): the three scoping
  blocks docs/aim-high-{language,executive,application}-v1.md at
  `1988c36`, five-refuter adversarial pass complete (5/5
  REPAIR-THEN-FIRE; FOUR fatals repaired in the §A v1.1 banners at
  `d989028`: the Vector-St-N isolation vacuity → shared-regfile SysSt;
  A4's identically-zero multi-round gradient → single-round rescope with
  seed bound; both seat tallies bust nine days → the largest-honest-bundle
  recommendation), verdicts persisted whole
  (${SEAT_DIR}/briefs/2026-08-10-aim-high-trio-refuter-verdicts.txt).
  COUNCIL PACK: docs/council-pack-0810.md carries the bundle
  (① L0→L4 compiler · ② X0→X2 + named salt days at math · ③ A0 only)
  and the seven-item ask-list that is HIS alone (W5-asm/B-ISA deferral ·
  ruling-#3 lift · partition N rec 2 · RULING #8 re-open A/B · L6's
  fate · salt-pillar days · the emit_runs-shaped Row A). NEW T1 INPUT
  folded: GraphCast as the GNN-compiler demo (his 11:4x hand; fence
  extended — never "forecasts weather"; the clearance route for public naming).**
- **THE SUCCESSOR'S RELIGHT + FIRST SEAL (8/10 11:31-11:38, register
  line): boot per the midday bank; BatcherRun + PortLengths ROOTED at
  `02155be` (the closure ritual's own find — PortLengths tracked-unrooted
  since 8/8's "import owed", its hub-cycle import rewritten; 8681-green,
  EXIT=0 read from the line); disk-vs-graph closure now returns only
  Scratch*. TT CI FULLY GREEN on the live commit: the benign viewer
  failure decoded one level deeper (duplicate github-pages artifacts from
  the rerun; both deleted, attempt-3 SUCCESS) — the Captain's three
  clicks gate only on his hand now.**
- **SORT-THEN-ROUTE SHAPE RULED (8/10 10:5x, the Captain, verbatim
  "Yes (b) exactly"): THE BIT-SERIAL BATCHER — his own 1990 shape
  (ISS90 p.78 §3.1: first-difference latching, "16 bit-times" =
  sorted IN TIME). THE PATH: emitSeq(batcherNetC) + shell (the L1
  play rehearsed on the cell) — the certified frame-streaming
  sorter (the bnC theorem family's own object, 96 state bits)
  gains its flops from last night's emitter; the domain crossing
  dissolves into a FRAME-ALIGNMENT CONSTANT (the sorter's fixed
  latency vs the banyan's sof) — a timetable number. FIRED:
  compiler emits + pre-registers counts (per V7's which-not-how-
  many form); silicon shells/composes/measures the 1x2 projection
  AT the composed object (its own struck-twice rule honored);
  math refutes the alignment arithmetic. The update window is the
  deadline; today's submission unaffected.SHARPENED 11:0x AT THE
  CAPTAIN'S OBJECTION ("I don't even see how a combinational
  Batcher would work because the packet is arbitrarily long"):
  option (a) was never merely expensive — it is INCOHERENT at the
  architecture level, a bounded-frame special case; with ∀-P
  payloads (and 1990's 424-bit ATM cells behind 8-bit headers) the
  sort decision MUST be made on the bounded header prefix while
  the unbounded payload streams — first-difference-then-hold. The
  certified object already embodies this: bnC_payload_delivered
  holds for ARBITRARY-length payloads precisely because the
  element decides on the header and goes transparent (B4's own
  bonus finding: the sorter leg is already ∀-P). (b) is not a
  preference; it is the only shape the architecture admits.**
- **⭐⭐ THE SWITCH RE-PLANNED — FULL BB, ITS OWN REPO, 1x1 IN PLAY
  (8/10 17:4x, the Captain at/after council): the standalone switch is
  the FULL BATCHER-BANYAN (batcher_c WIRED to the banyan — today's
  sort-then-route closure makes it honest), on its OWN public repo
  **jyh/tt-verified-batcher-banyan** (distinct from the existing
  jyh/tt-verified-banyan-switch, the bare-banyan 2x2 record that was
  confusing TT); **THE 1x2 BARE-BANYAN PLAN IS DISCARDED.** THE FIT
  QUESTION — UNDECIDED, the run is the answer (CORRECTED 17:51 at
  silicon's `48aadb5` self-catch; the maestro relayed a WRONG-OBJECT
  number to the Captain 17:4x and struck it 17:5x): the sorter is
  **batcher_seq 6,065.82 um2 EXACT** (720 cells, 96 flops — the full
  next-state organ), NOT batcher_c 4,023.86 (its combinational core
  only; quoting that understates the sorter by 50.7% — compiler's
  ndf-account.md:112 warned this in advance). ⇒ FULL-BB FLOOR =
  3,824.92 (banyan, measured) + 6,065.82 = **9,890.74 um2 = 73.5% of
  the 1x1 core (13,460.40), CELLS ALONE**, before repair buffers/taps/
  routing. That is BELOW the old ~12.2k "won't close" projection but
  TIGHT — the call is settled in NEITHER direction by arithmetic. ⇒
  THE RUN IS THE ONLY ANSWER: full-BB-on-1x1 on TT's grid IN FLIGHT
  (accepted 17:51); NO TILE PURCHASE until close/no-close + util lands.
  If it closes, THE 1x1 IS THE BUY.
  ⭐ PRIORITY RULED 17:5x (the Captain, verbatim "let's move it to P3
  — it is just for nostalgia, we can even move it to the Sept 27
  shuttle"): THE FULL-BB SWITCH IS **P3** — nostalgia (the 1990
  Bellcore switch, his patent), NOT deadline-critical, and it may
  target the **Sept-27 shuttle** rather than the current one. So: the
  in-flight 1x1 run FINISHES (near-done, the fit answer for free) and
  the number banks; the seam-wire, the repo, and the tile purchase all
  drop to do-when-idle. The current-window tapeout attention is the
  NDF (6x2) alone; the switch rides P3 at its own pace. NO seat spends
  P1 or NDF cycles on it. Repo scaffolds around the
  full-BB target; the wording takes evidence's fence before public.
  Deadline: submit-real-by-Aug-31, fits with room.**
- **THE TILE PLAN IS CONFIRMED (8/10 10:4x, the Captain, verbatim
  "Ok, that's our plan, a 1x2 and a 6x2") — ⭐ SWITCH HALF SUPERSEDED
  17:4x (see above: full BB on its own repo, 1x1 in play, 1x2
  discarded; the 6x2 NDF stands): the standalone switch on
  a NEW 1x2 (submitted today with banyan content; the full
  Batcher-banyan wired during the update window — his personal
  word: the Bellcore team gets the full BB, "it is more
  meaningful") + the NDF on the upgraded 6x2. Chip-count facts
  banked from the dossier: chips ride DevKit PCBs at EUR 300+15
  each (subsidized 80/80 SOLD OUT); EVERY board carries the ENTIRE
  shuttle die mux-selected — each gifted board holds BOTH machines;
  delivery ~May 2027. NDF-ON-GITHUB: not yet — the scaffold
  (TTNDF/, 347924a) is ready in the private tree; the public repo
  creation is the next act and is T1-PUBLIC (his word/hand); TT's
  CI on the public repo runs the REAL flow with TT's PDN.
  ⭐⭐ SUPERSEDED IN THE GOOD DIRECTION 10:48 — THE TILE-FIT IS
  ALREADY RUN AND PASSES: silicon tested its own "blocked on TT's
  PDN def" claim (false, never tested — compiler's 10:40
  self-catch made it look), found the def in TT's PUBLIC tooling,
  fetched it, and ran the REAL tile-fit locally: PASSES. The
  first layout's "not a tile-fit signoff" scope clause is
  DISCHARGED pre-submission; the account's priced half absorbs
  the numbers.**
- **⭐⭐ THE SUBMISSION PUSH (8/10 10:3x, the Captain, T1 — his
  words): "I want to submit NDF to TT today if possible" + the
  VENDOR DATUM from TT's own reply (ground truth, his
  correspondence): SIZE-UP IS ALLOWED, SIZE-DOWN IS NOT. HIS
  RESIZE PLAY, under maestro analysis same sitting: upgrade the
  owned 2x2 (the BB's) → 6x2 and put the NDF there; the BB switch
  moves to a NEW separate 1x1 (the Captain's refinement 10:3x:
  "if the BB fits on a 1x1, we should use that" — MAESTRO ANALYSIS:
  the shipped submission is the bare banyan, 4,031 µm² post-layout,
  vs a 1x1's ~14-15k usable core ≈ 26-28% util — FITS COMFORTABLY,
  silicon's run confirms; the full-BB-with-batcher variant (~12.2k
  projected) would NOT close on a 1x1 — AND THAT IS SAFE BY TT'S
  OWN RULE: size-UP is allowed, so the growth path to a batcher-
  wired switch stays open from the 1x1; a no-regret choice). ⇒ FIRED: (a) THE NDF ACCOUNT
  (docs/ndf-account.md) via the bb-switch-account pattern —
  compiler kernel half (measured, #eval'd) + silicon priced half
  (signoff artifacts) IN PARALLEL, then maestro joint reading,
  math standing refutation, evidence fence pass; the account is
  TODAY'S PRIORITY, V9/DRV resume behind it at their owners'
  sequencing. (b) BB-at-1x2 feasibility + re-hardening (silicon,
  after its account half): bare-banyan 4,031 µm² post-layout vs
  ~32k µm² 1x2 core = trivial fit; PRICE NAMED: re-signoff at the
  new die + the stale cocotb bench fix (test.py:247, registered,
  still unowned) + the BB's own DRV debt rides along. (c) The
  submission-today framing: HONEST ONLY AS update-until-close —
  the artifact ships with named debts (no tile-fit signoff yet,
  V10/bench behind, batcher unwired, y int8-only, DRV 1,757/31)
  and improves until the ~Sept 7 freeze; the public README wording
  takes EVIDENCE'S FENCE PASS BEFORE the Captain's click (public
  = T1, the click is HIS). Money arithmetic (maestro, labeled):
  resize play ≈ €910 total (280 sunk + ~560 upgrade + 70 the 1x1)
  vs €1,120 for keep-2x2-plus-new-6x2 — SAVES ≈ €210, IF TT
  upgrade pricing is pay-the-difference (UNVERIFIED — his checkout
  read confirms). Reservation-timing ruling SATISFIED: "reserve at
  layout-readiness" — the layout exists as of 01:46.**
- **⭐⭐⭐ THE ③+④ DEEP SESSION IS HELD AND COMPLETE (8/10 09:5x —
  the Captain-committed duty of 8/8 14:14, verified not-yet-held
  last night, PAID IN FULL at this sitting): ④ walked (full circle
  + nonblocking + six-state + premises + his two primary-source
  recollections folded) and ③ walked (the eight refutation rounds
  + the forged claim + L4's risk-turned-gift), THE RIDERS RATIFIED
  AS DOCTRINE (his verbatim: "whew this is amazing, good job math!
  Ratified") — sigma-struck · header-window-excluded · P=8-scoped
  with the ∀-P price named. The do-not-forget entry CLOSES. The
  one optional table item remaining from the original fold: the
  packet-IO slate's #3 memory story (switch-fabric-as-NN), at his
  pleasure, no clock on it.**
- **THE ④ WALK COMPLETE (8/10 09:4x, the Captain, verbatim "good,
  *now* I understand, and the current design is fine, because it is
  a BB, not a pure banyan"): the SIX-STATE FORM RATIFIED as
  kernel-canonical, with the 1988 duration-controlled architecture
  recorded as a distinct design point (his primary-source
  recollection folded into the heritage block same sitting). AND
  THE CAPTAIN'S DESIGN DICTUM, banked for v2/scale: "for
  composable banyans the address-length-agnostic design is better"
  — strobe-timed cells for any multi-chip/16x16 fabric where
  addresses grow; irrelevant at the PoC's fixed r=3 BB, binding
  wisdom beyond it. ④ is WALKED: full circle + nonblocking +
  six-state + stage-count premise + framework law + his recalled
  timing + his recalled S2 mechanism — all ratified or folded.**
- **THE ④ WALK, FIRST RATIFICATIONS (8/10 09:2x, the Captain at
  council, verbatim "Both asks ratified"): ① THE STAGE-COUNT
  PREMISE stands ratified — identifying the paper's address-length
  restoration index with the routing-stage count k is the block's
  OWNED premise (Rotation.lean:76-77's honesty note becomes doctrine).
  ② THE FRAMEWORK-LAW PROMOTION stands ratified —
  zero_offset_rotation_is_impossible is LAW, with
  schedule_11_does_not_heal as its mutant witness. Same sitting:
  the second 1990 claim walked — distinct-addresses-nonblocking =
  composed_switch_of_bnC_driven's three conjuncts (landed 8/7);
  its full partial-load generality = the convention-C seam = R1's
  v1.1 node (one seam, already owned).**
- **⭐⭐⭐ THE SOFTWARE TURN + AIM-HIGH DOCTRINE (8/10 11:1x, the
  Captain, strategic steer, his words): the hardware story is
  POWERFUL AND SUFFICIENT ("switch + RISC-V + NDF (this one <24h)
  all verified, 2 going to fab — this is very convincing") —
  ATTENTION TURNS TO THE SOFTWARE SIDE, four pillars: verified
  compiler (tiny-Rust→RISC-V) · verified executive · verified
  application · verified math (salt). SEQUENCE: FIRST finish
  minimal-executive + batcher-sort ("easy and completes the
  story") — both already in flight. THEN HIGHER-RISK MODE for the
  remaining 9 sprint days, his three named pushes: (1) a LARGER
  LANGUAGE and more realistic compiler than tiny-Rust · (2) a
  MINI-OS instead of the executive · (3) a SIGNIFICANT
  APPLICATION. THE DOCTRINE, verbatim and standing: "We need to
  aim high, beyond what we think is possible, because 1) we
  already have a lot! and 2) we keep aiming too low." Fable-tier
  scoping blocks for the trio: maestro drafts for the afternoon
  council.**
- **THE AFTERNOON COUNCIL (8/10, time at the Captain's word;
  agenda registered): ① SALT NEXT STEPS — submit to Pi (the
  ratified venue; flagship skeleton exists at papers/flagship/) ·
  *continue* the arXiv endorsement effort (reopened from
  his-lane-only to an active item at his word) · CLEARANCE STATUS
  BANKED: salt RE-APPROVED ✓ · jas APPROVED ✓ · SaltBench NOT
  YET (pending). ② LTI MEETING PREP (WEDNESDAY 8/12) — the
  narrative REDONE now that the scheduled meeting changed the frame;
  draft at council. ③ the higher-risk trio scoping blocks. ④ the
  fab logistics tail (clicks/boards) as it stands by then.**
- **THE CAPTAIN'S MORNING RULINGS (8/10 07:3x-07:4x, three words
  total): ① h ≤ 127 CONFIRMED (executed c2b16bc — the range
  obligation names the SIGNED int8 bound, never byte width; math's
  catch). ② THE DUPLICATE LEMMA = OPTION (b), THE HOIST: the
  adder's arithmetic-bit lemma moves to Stack/Program BESIDE its
  parent sem_adder32_gen; then BOTH copies retire by repointing —
  math lands the hoist + retires MacBridge:39's copy (its file);
  compiler repoints MacCell:1215/:1225 and retires sc_adder_bit
  (its file). Land-at-owner, math's hoist first. FIRED at the
  ruling. ③ THE AUDIT SCOPE = OPTION (a): when MacBridge's 32
  pre-existing theorems are audited (math's 47-row), they land as
  a NEW SEPARATELY-SCOPED audit block — the scoped-block style IS
  the audit trail; whole-file certificates are not the house form;
  the predecessor's refusal stands vindicated as doctrine.**
- **⭐⭐⭐ FIRST LAYOUT IS IN — THE CAPTAIN'S NAMED TARGET MET
  (8/10 01:46, silicon 465c669): the composed NDF — 4 shelled
  cells + 3 SER organs + the banyan fabric + the RISC-V core —
  PLACED AND ROUTED on the 6x2 die. stdcell 69,776.9 µm² = 30.0%
  of die · 902 flops · setup +8.1891 ns at the SLOW corner, hold
  met, violations 0/0 · DRC 0 (magic AND klayout) · LVS 0 ·
  antenna 0 · inferred latches 0. MEASUREMENT #1 ANSWERED —
  ENDPOINTS REFUTED, MIDDLE CONFIRMED (compiler's 01:48
  narrowing, traced hop-by-hop): the critical path is
  uio_in[2]→ser0.q30, and the named chain's expensive middle
  (AND→XOR→ripple) SITS INSIDE IT — the measurement refuted the
  predicted ENDPOINTS (enters from an input port, not SER;
  terminates at SER's flop, not acc). The internal chain IS the
  cost, and the I/O softness caveat (the number moves with the
  input-delay model) is MORE load-bearing under this reading.
  The pre-approved port-register escape was NOT spent (+8.1891
  margin — a pre-approval is not a reason to spend it, silicon's
  words).
  THE CLOCK ON THE STORY: the Captain's 3am dream (8/9 ~03:06) →
  composed first layout (8/10 01:46) ≈ 22h40m; ruling T0 (11:27)
  → layout = 14h19m; his "can we get first layout tonight"
  (01:0x) → layout = ~40 minutes of fleet time. THE CHAIN, every
  link sealed under one hand: emitSeq/L1 (2704fa0, saltbuild
  EXIT=0) → L1 layout (e7c76ca, 64/64 flops) → L2 shell (9915a60,
  EXIT=0; layout 5da7a92, THE SHELL COSTS 51 ps) → SER (b9641c8,
  EXIT=0; emitted 938206f, 99 cells exactly as pre-registered) →
  wrapper (maestro draft v2 → compiler adoption 16d40c1 + the
  linter-caught floating-input fix 34a1076) → the composed run.
  SCOPE, BINDING (silicon's clause, evidence's fence): LibreLane
  PDN, NOT a tile-fit signoff — the die was SET to 6x2 dims, not
  fitted to TT's tile; trustworthy for area/timing/DRC/LVS/
  antenna; batcher_c is UNWIRED, NOT MISSING (silicon's 01:51
  datum, measured: the organ EXISTS complete in RTL/ at 624
  sky130 cells; instantiations in the wrapper: ZERO — a
  COMPOSITION decision of an afternoon, not an organ to build;
  the sort-then-route seam is R1's named v1.1 node; whether it
  fits/closes beside the 30.0% die is A MEASUREMENT TO RUN, not
  a number to guess); functional demo correctness = V10 fixtures
  + bench, behind. DEBTS NAMED: 1,757 max-slew +
  31 max-cap (DRV, not DRC) + 7 non-critical disconnected pins —
  September's submission answers for them. Revisions can come
  after, should we decide — the Captain's own words, now with an
  artifact under them.**
- **EVIDENCE FENCE VERDICTS (registered at its 23:30 ask — the two
  lines the register lacked; its "settled both ends" catch): the ②
  fence reads (a)(b)(d) MET · (c) discharged at math's hand · F5
  STILL BINDS on the composed cell's signed claim — every
  whole-neuron sentence carries WHEN DRIVEN (driver = the
  sequencer, V9/R6). The v1.1 demo sentence remains FENCE-PENDING
  at evidence until its pass posts.**
- **REFUTER-PASS OUT-OF-FREEZE FINDS (19:3x, registered from the
  five-refuter pass on the top-module block): (a) ⛔ THE BB COCOTB
  BENCH IS STALE against the 8/8 cnt[3] ruling — TT/test/test.py:247
  asserts `(uio >> 5) == 0`, which the Captain-confirmed `cnt_o[3]`
  on uio_out[5] (the assign at project.v:60) violates for cycles
  8-13. THE SWEEP is discharged (silicon 20:13, exact size: first
  failure t=8, window 8-13 — corroborated for free by project.v's
  OWN 8/8 comment "cycles 8..13 alias onto 0..5", two provenances,
  neither reading the other); THE BENCH ITSELF REMAINS STALE and
  its FIX IS UNOWNED — a claimable float or a sitting assignment;
  diagnosed ≠ fixed, kept separate here on silicon's 20:19 catch. (b) PayloadL4.lean:30-31
  carries a stale "import owed / targeted-build verdict" note —
  SaltWorks.lean:77 imports it; one-line doc fix, any hand.**
- **NEXT-RUNG RE-RECON, MAESTRO-OWED (post-council; opened 21:37 on
  math's entry-2 scan): docs/blueprints/next-rung-scoping.md (Fable
  7/07) carries a dated staleness banner as of ea3fb1b — its S1
  absence list rotted from success (SW, large sieve, Mertens,
  Vaughan all corpus-landed since). The four-agent recon re-runs
  against today's corpus before any next-rung planning consumes it.**
- **SUBMISSION-CONFIG CHECKLIST (named 23:09, silicon — a trap, not
  a live defect): TT/info.yaml declares 25 MHz (40 ns) but the
  switch's TT/src/config.json ships CLOCK_PERIOD 20 (50 MHz) — fine
  for the switch, FATAL-BY-INHERITANCE for the core's future config
  (measured: core slack +16.9 at 40 ns, −3.1 at 20 ns; the failure
  would masquerade as a design problem). THE RULE: the core's
  submission config sets CLOCK_PERIOD to match the declared
  clock_hz, and the two files are reconciled in the same commit.**
- **THE CAPTAIN'S CONCURRENCY-MEMORY MEASUREMENT — ✅ DISCHARGED
  01:0x (was standing here as OPEN, struck to done by silicon's
  08:15 co-reference check): his own 8/6 "measure the concurrency
  hazard tomorrow", lost two days, resurfaced 00:2x, MEASURED by
  compiler on a scratch clone — realised peak 43.08 GB of 64 GiB,
  per-process cap never binds (~10.8 GB), the fleet lock is the
  guard. The 80-GB question it was gated to price NO LONGER EXISTS
  (struck at the cap law above). Silicon's tile-fit-run anchor is
  moot — the clone measurement is why that run was never needed.
  Kept as a discharged-record line, not an open item.**
- B5 (T1): the click; Sept-7 13:00 PDT close; REF QUESTION + floor
  law remain his; fact sheet on his word. Adjacent MONEY item from
  the muster flags: PCBs 0/80 — the real TT scarcity; ordering is
  his word.
- The pin cnt[3] → uio_out[5]: **CAPTAIN-CONFIRMED 14:14 ·
  IMPLEMENTED 14:25** (silicon life-4: 05f423f/f76ee81/a2fa973;
  the counter was ALREADY 4-bit from the 13:47 $clog2 fix — the
  earlier "implements in RTL" wording was half-stale and silicon
  read past it correctly). CLOSED.
- **POST-FAB, CAPTAIN'S OWN (18:5x, his words): chips to the
  BELLCORE TEAM — Chet, his first manager, "still alive and
  breathing... deeply caring and important to me." Carried with the
  PCB decision (boards make chips giftable) and the B5 fact sheet.**
- PCBs 0/80 (T1, money): the Captain is UNDECIDED, will decide
  later — resurface gently with the B5 fact sheet, not before.
- **THE ③+④ DEEP SESSION — CAPTAIN-COMMITTED, do-not-forget duty
  (his words 14:14: "please don't let us forget — tonight, or
  tomorrow morning")**: the maestro re-surfaces it THIS EVENING
  before ~19:00, and again TOMORROW MORNING ~07:30 if not held
  tonight. Brief ready: the blocks are five refutation rounds
  richer; the 1990 paper states the full-circle theorem verbatim.
  **RULED 8/9 18:5x (the Captain, at the maestro's recommendation,
  re-surfaced on schedule before 19:00): FOLDED into the NDF
  THEORY-REVIEW SITTING, tomorrow morning ~07:30 — ONE TABLE for
  the ④ full-circle material, the ③ blocks, the NDF top-module
  design block (drafts tonight, refuter pass behind it), and the
  packet-IO slate's #3 memory story. The do-not-forget duty
  becomes the sitting's opening.**
  **VERIFIED NOT-YET-HELD 8/9 19:1x at the Captain's challenge
  ("we already did the 3+4 review last night, please verify"):
  12-reader sweep over the full 8/8-14:00→8/9-08:00 bus window +
  the 8/9 noon council window, two ADVERSARIAL judges (one briefed
  as the Captain's advocate) — both NOT_HELD, high confidence.
  The trail: ③+④ PARKED at the 8/8 10:05 muster (ruling ⑦, "one
  conversation") · his 14:14 commitment is itself proof ("please
  don't let us forget") · 14:18 he left the helm · the evening =
  the ④ LANDING CEREMONY at 18:35 (his correctly-scoped sentence,
  "the paper's assertion, now proved!") + three NEW campaigns
  (tiny-Rust/RTL-layout/Slice-B) + the 21:04-21:31 tile/pinout
  design review. FOUR NAMED DEJA-VU ANCHORS, all real: the doc
  headers say "Captain-sessioned 8/8" (recording the PARKED muster
  touch) · his own 10:32 design premise folded into the heritage
  block · the 18:35 scoping act · the genuine (but other-subject)
  21:0x review. UNREVIEWED and waiting for the sitting: block ③'s
  eight refutation rounds, block ④'s six-state correction + the
  framework law + the stage-count premise + HIS OWN recalled-1988
  timing as folded. The fold ruling STANDS.**
- Endorsement + witness approval #2 (T1): his lanes, he monitors
  personally (his 8/7 disposition; no maestro re-surfacing).
- Salt (7.3) (T1, the Captain's click): now **ONE CLICK** — its last
  missing input (`summable_norm_majorantCoeff`) landed 16:06 for an
  independent reason; the assembly itself remains untouched and his.
  THE FACT-SHEET LINE: "the cost changed, the ownership did not."
  Surface with the ③+④ session tonight or tomorrow morning.
- The ③+④ deep design session: open at his pleasure — a
  collaboration, not an authorization; the blocks are five
  refutation rounds richer than when he last held them.

## WAVE-GATES (the coarse dependency map, one glance)

```
phase 3 (compiler W1 → math W1) ──┐
compiler R1 + silicon R1 ─────────┼──► ③ waves: L0/L1/L2 (compiler W2)
                                  │        └──► L3 → L4 (math W3)
③ waves + compiler R2 ────────────┴──► ④ waves (statements per v2 fold)
salt probe GO + maestro word ─────► salt W5(S2)#1 (math W2)
PARKED (Captain): B5 · the ③+④ design session · the endorsement clock
```
