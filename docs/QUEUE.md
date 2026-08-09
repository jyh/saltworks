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
