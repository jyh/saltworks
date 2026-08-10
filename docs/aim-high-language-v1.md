# AIM-HIGH BLOCK ① — THE LARGER LANGUAGE AND THE COMPILER THAT EXISTS (v1)

**Maestro draft (Fable hand), 2026-08-10, for the 16:00 council. Feeds the
Captain's push ①: "a LARGER LANGUAGE and more realistic compiler than
tiny-Rust" under the standing doctrine ("We need to aim high, beyond what we
think is possible, because 1) we already have a lot! and 2) we keep aiming too
low." — QUEUE:1073-1075). Recon basis:
${SEAT_DIR}/briefs/2026-08-10-aim-high-trio-recon.json (language section, byte-cited);
deltas since recon folded in §2. Refuter pass owed BEFORE council consumption.**

## §A · REFUTER-PASS AMENDMENTS (v1.1, 12:1x — five refuters, all verdicts folded; the wave fires on THIS section where it conflicts with the body)

- **A1 · Row A takes the `emit_runs` shape, not the bare ∃-fuel (r-fuel).**
  The corpus already carries the fuel algebra LANDED and audited —
  `runFor_add` (Stack/Program.lean:615, no side condition),
  `runFor_of_fetch_none` (:598), `runFor_eq_of_halted` (:628) — so §4's
  core unlock STANDS (better: it is already paid for), but the bare
  `∃ n, runFor n code (encode σ) = encode σ'` is gameable two ways
  (append-a-loop transit; n=0 on no-op-shaped programs). AMENDED FORM:
  entry-pc + `EmbedsAt` hypotheses, exit conjunct
  `(runFor k img st).pc.toNat = 4*off + 4*code.length` (which forces
  `fetch = none` and stabilizes all larger fuel), frame at the EXIT state.
  Pre-registered controls: the append-a-loop mutant and the emit-nothing
  mutant must both FAIL the amended Row A.
- **A2 · The planned reg-map hypothesis was a vacuity bomb (r-fuel).**
  `Function.Injective (reg : Nat → Fin 32)` is pigeonhole-UNSATISFIABLE;
  every theorem carrying `RegOk` as drafted would be vacuously green.
  AMENDED: `reg : Fin poolSize → Fin 32` (poolSize = 15, RTL-mirrored) or
  injectivity bounded below `poolDemand p`; an INHABITANCE control
  (exhibit one `reg`) lands before any theorem consumes it. L1's
  "injectivity as a theorem" re-aims at the finite-domain embedding.
- **A3 · The frame clause ranges over scratch, not a fixed boundary
  (r-fuel).** Scratch grows with `expCostNoSwap`; a fixed `t0` frame is
  FALSE for `mathP`-shaped programs. Frame = complement of (Γ's registers
  ∪ the node's scratch range), with `poolDemand p ≤ 15` carried.
- **A4 · L6's closing sentence was an end-to-end regression (r-claims).**
  Amended: L6 closes universal sortedness for the PROGRAM against the
  certified NETWORK MODEL (`batcher8_sortsTo_word`); one comparator spec
  by PROVENANCE; the compiler verified between source and machine WORDS;
  netlist/silicon composition stays prospective behind W5-asm.
- **A5 · Controls hardened (r-claims).** L0 gains a per-rung totality
  lemma (`compileE` returns `some` on well-typed, in-pool expressions) so
  the reject-everything mutant binds at L0, not only at L4; L3 gains the
  paired ACCEPT control (a recursion-free two-function program whose DAG
  check passes and whose inlining theorem is green).
- **A6 · Stale status corrected (r-claims).** §2's "only stage
  preservation remains" was already false at drafting: (A)(B)(C)(D) ALL
  LANDED (`819c685`/`1b5453c`; `bnC_output_frames_partial`; silicon MEAS
  no-defect 11:43). Carried WITH 1b5453c's own guard: this is NOT "the
  Batcher sorts" — the abstract-fold↔cSorted seam remains, abstract to
  abstract. §6's "at the door" gate is effectively OPEN on compiler's side.
- **A7 · L6 has no seat, and the seat math does not close (r-sequencing).**
  The cross-trio tally busts the window (see the council pack's bundle):
  this block's in-window recommendation is **L0→L1→L2→L4 at compiler,
  L3/L5 CUT unless math's X-ladder is cut instead, L6 RULED at council**
  (default: named cut; stretch: compiler post-L4 if W5-asm/B-ISA deferral
  is ruled). W5-asm/B-ISA deferral is the Captain's to rule — their slots
  are his standing orders, not this block's to consume silently.
- **A8 · L6 vs block ②'s partitions (r-sequencing).** `sortProg` needs
  NINE registers concurrently (SortDemo.lean:462-465); a partitioned task
  class at N=4 gives 3, at N=2 gives 7. L6 and compiler-enforced
  partition isolation are incompatible demonstrations on this machine —
  stated in both blocks; L6 runs only at N=1 (whole-pool).

## §0 · THE HONEST STARTING LINE, SAID FIRST

There is no compiler. `def compile` → zero hits in the corpus (recon
language/absent[1]); Rows A/B exist as prose and as `C3Statement` (a `Prop`
over section variables that asserts nothing, CodegenSpec.lean:161); of the
declared N0..N5 ladder only N0's PROBE layer is landed (TinyRustN0.lean says
so itself, :13-30). "A larger language" before ANY compiler would be growing
the unverified half. So this block reads the Captain's push as one sentence:

## §1 · THE AIM-HIGH TARGET (the star sentence)

**A COMPLETE VERIFIED COMPILER — correctness AND completeness, source through
machine words — for a tiny-Rust with `while` and functions, closing with the
Batcher sort RECOMPILED FROM SOURCE so the demo program's certificates become
consequences of source semantics.** That is CompCert's shape at 1/1000 scale
on our OWN certified target, in nine days, and every rung below is
independently bankable.

The "larger" in the Captain's sentence is delivered as: `while` (in the landed
AST, currently uncompilable), functions (fully designed, verified inlining,
zero new hardware — recon language/capabilities[9]), and ONE verified
optimization pass (constant folding) to earn "more realistic" — a multi-pass
compiler with a proved pass, not a syntax tree walk.

## §2 · WHAT STANDS (deltas since recon marked ★)

- Typing judgment, de Bruijn levels, `bigStep`, pool model vs real RTL
  (pool=15, drift-guarded), 23 theorems, controls green — TinyRustN0.lean.
- Target machine complete + certified: `Instr`/`step`/`run`, `encode`/`decode`,
  `decode_encode`, total `stepT`; word lift `runW_map` UNCONDITIONAL — every
  Instr-level theorem is a machine-word theorem by `rw` (Executive.lean:176).
- The `ite` lowering scheme kernel-executed down both branches with the
  off-by-one mutant coexisting (CodegenSpec.lean:201-256).
- A 120-instruction generated program with certificates (SortDemo) whose
  universal sortedness waits on exactly the simulation theorem N5 states.
- ★ Since recon: the partial-load lift is COMPLETE — (A)(B)(C)(D) all landed
  (`819c685`, MEAS'd, not-refuted; see §A A6 for the guard: NOT "the Batcher
  sorts"); `BatcherRun`+`PortLengths` rooted (02155be). The
  "story-completing" pair the Captain sequenced FIRST has effectively sealed
  on compiler's side — this block fires behind it, as ruled.

## §3 · THE WALLS THIS BLOCK RESPECTS (each quoted in the recon)

- Five ops, no sixth free; ALU op-set UNCHANGED is a standing ruling. So: NO
  `AND`/shift/`ult` at the source in this block — they need ISA growth, which
  is B-ISA's lane, not ours. Header-field extraction stays a port-organ
  question (application block's problem, named there).
- No memory ⇒ no arrays/spilling; over-pool programs are REJECTED (Row B's
  honest second cause). Unchanged here.
- The frontend stays TRUSTED and declared so (CompCert's own posture).
- The composition sentence stays PROSPECTIVE behind W5-asm
  (`conformance_does_not_determine_semantics` is in the kernel); nothing below
  restates end-to-end silicon claims.
- `hpool`-separate remains the Captain's live veto point; the ladder works
  under either ruling (the judgment never mentions poolSize).

## §4 · THE KEY UNLOCK THE RECON EXPOSED (why `while` is NOT blocked)

The recon's wall reads "any real `while` lowering needs a new driver before
N3 can state its theorem." **Narrowed: that is true for `run` (fuel =
`code.length`) and FALSE for the corpus's own `runFor`, which is
fuel-parameterized today.** Row A is scoped to TERMINATING runs (v1's ruled
scope), so the correct statement is existential in fuel:

```
bigStep Γ p σ σ'  →  compile p = some code  →
  ∃ n, runFor n code (encode σ) = encode σ'   (+ the frame clause)
```

The fuel witness is CONSTRUCTED by the simulation induction (each `bigStep`
derivation node contributes its instruction count). The step-indexed/
coinductive driver remains B-EXEC's row for INFINITE runs — fairness needs
it; terminating-run compiler correctness never did. Named consequence: N3
decouples from the executive block entirely. The census's "cheapest fix"
(the decidable forward-branch predicate + `runFor_extend`) still lands at
rung L0 because straight-line code deserves the sharper `run` form and the
predicate is the S2 safety net the census asked for.

## §5 · THE LADDER (stop anywhere; every rung banks alone)

- **L0 · N1, expressions + the fuel lemmas** (compiler seat, ~1 day).
  `compileE : Ctx → Exp → Reg → Option (List Instr)` against the landed
  `evalE`; correctness per expression form; `Forward` predicate +
  `runFor_extend : n ≥ code.length → Forward code → runFor n code s = run
  code s`. CONTROLS pre-registered: a reject-everything mutant must fail
  completeness's witness; the Sethi-Ullman trap stays pinned by
  `expCostNoSwap` (NOT the classic number — its own docstring law).
- **L1 · N2, straightline statements** (compiler). `seq`/`assign`/`letmut`;
  the simulation lemma's SHAPE is fixed here (state-agreement relation
  `encodeOK Γ σ st` — the F2 injectivity hypothesis lands as a theorem about
  the level-indexed embedding, closing recon absent[7]).
- **L2 · N3, control** (compiler; the soul). `ite` first — the scheme is
  already kernel-executed; then `while` in the ∃-fuel form of §4. The
  off-by-one mutant rides as the standing control.
- **L3 · N0 proper + N0.5, preservation + functions** (math seat —
  parallelizable with L1/L2 since it is source-level only). Statement-level
  preservation over `bigStep` (the owed N0 row, `stateOK` carried across);
  verified inlining with the DAG-checked call graph (recursion REJECTED, the
  pre-registered control), params-to-letmut, `inline_preserves_bigStep`.
- **L4 · N4, Rows A and B assembled** (compiler+math joint). `compile_correct`
  and `compile_total` as REAL theorems in the recon's adopted signature, frame
  clause included; completeness's two honest rejection causes and no third
  (instruction-memory as candidate third cause: PRICED at this rung, not
  assumed away — if image length can exceed what the harness serves, it
  becomes hypothesis three, SAID).
- **L5 · one verified pass** (math, small). Constant folding
  `fold : Stmt → Stmt` + `fold_preserves_bigStep` + `fold_shrinks_or_equal`.
  Cheap, classic, and it makes the word "compiler" mean a pipeline.
- **L6 · N5, THE FLAG**. Recompile the sort from tiny-Rust source (a source
  program of 24 comparator blocks — straight-line, no while needed, functions
  make it readable); Row A turns SortDemo's certificate suite into theorems
  about the SOURCE program; the simulation theorem `run sortProg ≈ runNetW
  batcher8` (SortDemo.lean:61's named gap) closes universal sortedness for
  the PROGRAM against the CERTIFIED NETWORK — software and silicon sharing
  one comparator spec, now with the compiler verified between them.

## §6 · SEQUENCING, COST, OWNERSHIP

Fires AFTER the story-completing pair seals (Captain's ruled sequence; both
are at the door). Compiler seat carries L0→L2→L4 as its ONE write track
(W5-asm and B-ISA waves interleave at its seam — council arbitrates the
order); math carries L3/L5 in parallel (source-level, lock-disjoint from
compiler's HDL range). Nine days: L0-L2 ≈ 3, L3 ≈ 2 (parallel), L4 ≈ 2,
L5 ≈ 1 (parallel), L6 ≈ 2. Tight and honest: the ladder banks value at every
rung if the tail is cut — L4 alone is "a verified compiler exists"; L6 is the
story. Every rung: saltbuild-only, pre-registered controls before the wave,
axiom audit per landing, precondition preambles per the house law.

## §7 · CLAIM FENCES + VETO POINTS (pre-registered)

- Never "end-to-end" / "down to silicon" for the compiler until W5-asm +
  composition land — the sentence is "source to certified machine WORDS."
- The AD/differentiability flagship is NOT this block's claim (application
  block owns it, on the no-while fragment; growing `while` here and AD there
  is compatible BECAUSE AD is defined on the fragment, stated so).
- VETO POINTS for the Captain: (a) the ∃-fuel Row A form (vs waiting for the
  step-indexed driver); (b) constant folding as the one pass (vs none, or vs
  copy-propagation); (c) L6's source-program shape (generated-from-bnComps
  source vs hand-written source — the first keeps one comparator spec, the
  second reads better as "a program someone wrote").
