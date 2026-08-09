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
- Laws that ride every item: saltbuild-only builds; pathspec-only
  commits; trailer-free; unique Scratch<NODE>-<agent>.lean
  (per-AGENT); explicit-brief law for executors; the kernel-census
  aiming rider for any deletion; **SaltWorks.lean (the root) is
  MAESTRO-ONLY** — landings post "import owed" and the maestro wires
  + runs the full-build verdict (the one-hand rule; restated 17:32
  after a benign crossing).
- **THE AUDIT-CAP TRAP (as CORRECTED by compiler's 20:4x retraction —
  the earlier "unlandable-to" law here was FALSE and is struck): the
  cap applies ONLY to saltbuild's AUDIT form (path form, `-M 12000`);
  the full build's module form is UNCAPPED and cold-rebuilds fine
  (measured: Immediate cold module-form EXIT=0, 79s). What survives:
  path-form audits of `Immediate`, `Decoder`, `FabricRoutes` exit 134
  at the default — USE `--cap 24000` FOR THOSE THREE, and an EXIT=134
  on them is the CAP, not your edit.** ADD-BESIDE remains good
  practice on its own merits; its cap justification is retracted. The
  default cap does not move without a maestro ruling (20:09).

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
- W5 · WRITE · **GATED(the Captain's morning review)** — the `core`
  construction: the seam between machine words and gates (compiler's
  named next, inventory Q1). Registered, not fired: capacity may be
  redirected to tiny-Rust/B-ISA waves at review.
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
  run (FP_SIZING absolute) is the next measurement.**
- **COLD-CACHE REPRODUCIBILITY — CLOSED BY RETRACTION (compiler
  20:4x): the full build's module form is UNCAPPED; cold rebuild
  measured green. The corpus reproducibility gap NEVER EXISTED — it
  was a one-arm read of saltbuild's two-arm case dispatch. W6's
  census TABLE stands as readings of the AUDIT instrument: three
  modules need `--cap 24000` path-form (now a QUEUE law above).
  Remaining council line, small: whether the AUDIT default rises to
  cover three modules, or the --cap rider stands.**
- **N7 DESIGN DEBTS, MAESTRO-OWED (post-council, Fable-tier — opened
  20:39 on math's exhaustion measurement): (a) the N7 ASSEMBLY design
  block (wiring the landed+composing (7.7) inputs and the kernel'd
  2-adic collapse into the road row); (b) the W4-a DESIGN CAMPAIGN
  (gap row 8: real-primitive-conductor 2-part classification;
  1,300–2,600 ln pricing CONFIRMED by math's shrink attempt — mathlib
  has the tools, not the theorem). The flagship front at solo tier is
  exhausted until one of these opens a gate.**
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
