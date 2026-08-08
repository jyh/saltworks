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
  aiming rider for any deletion.

## COMPILER

- W1 · WRITE · **PRE-AUTH** — phase-3 surgery to completion in
  SaltWorks/HDL/** (expand-contract per the interface law: statement
  byte-unchanged + parametric companion BESIDE it; omega consumers
  get literals; tripwires retire in the flip commit with the
  migration-completing epitaph). Then the precise patch request to
  math with the kernel's error text.
- W2 · WRITE · **GATED(W1 + both round-2 reads in)** — ③ waves
  L1 + L2 (HDL-slot element lemmas, v2.1 statements: H3/hrst carried;
  claim-gated OR under act0∧act1∧sel0≠sel1; the three undecided
  cases incl. tie-splice). L0 rides with them (element-level, L2's
  genre).
- R1 · READ · **PRE-AUTH** — ③ v2.1 round-2 read (bdb75f2/1a70c99).
- R2 · READ · **PRE-AUTH** — ④ refutation pass (the FSM model's fit
  in sequential Circ; piece-4 trace shapes; piece-5 well-formedness
  over Banyan.line).

## MATH

- W1 · WRITE · **PRE-AUTH** — the phase-3 Program.lean patch, on
  arrival of compiler's request (land it yourself; your file).
- W2 · WRITE · **FIRED 13:59 (the word given on the green trace)** —
  the salt flagship: W5(S2)#1, K/(π²m²) arm, statement + route +
  supply per the 13:58 pre-flight; mutation control = the refuted
  K/(2π²m²) re-cut must FAIL. The flagship front is OPEN.
- W3 · WRITE · **GATED(L1+L2 landed)** — ③ L3 (three lines from
  bnC_output_frames_are_the_fold + elemSortsAt_all), then L4 (the
  σ-composition, C-class, absorbs the sel-distinctness transport).
  L4 SCOPING may start any time as a read.
- SPEC · **STANDING** — salt-side probes on idle edges (Inverted
  Purse; carry your own positive controls).

## SILICON

- W1 · WRITE · **PRE-AUTH** — the §8 half-surface repair: the
  iverilog measurement per your pre-registered 13:31 criterion
  against the real RTL; frame_sim's missing-counter gap fixed in
  your artifact; the spec §5 sof-phase amendment IF the measurement
  confirms conservative+inert (your file, your bar; the ③ block
  cites the amended spec second).
- R1 · READ · **PRE-AUTH** — ③ v2.1 round-2 read.
- R2 · READ · **PRE-AUTH** — ④ timing RIGHT-OF-REPLY: math's 13:42
  refutation of your 4-clock repair is folded as UNFIXED-BY-PROSE
  (d_cell symbolic); confirm or contest — the doc awaits your word.
- MEAS · **STANDING** — conveyor refutation on every compiler
  landing; CELLS pricing on request; C5 re-baseline GATED(phase 3).

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

OPEN ITEMS:
- B5 (T1): the click; Sept-7 13:00 PDT close; REF QUESTION + floor
  law remain his; fact sheet on his word. Adjacent MONEY item from
  the muster flags: PCBs 0/80 — the real TT scarcity; ordering is
  his word.
- The pin cnt[3] → uio_out[5] (T2, exercised 13:49): rides into B5
  unless struck; put to the Captain directly 8/8 14:1x.
- Endorsement + witness approval #2 (T1): his lanes, he monitors
  personally (his 8/7 disposition; no maestro re-surfacing).
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
