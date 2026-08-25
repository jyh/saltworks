# THE LANGUAGE — verified compiler design block v1 (maestro, 8/8 night)
### Status: DRAFT-UNTIL-REFUTED. Captain-opened 8/8 evening ("let's
### pick a software language"); the maestro's recommended fork drafted
### here — a small IMPERATIVE language — with the Lean-DSL fallback
### recorded. CAPTAIN-CHOSEN 8/8 19:1x: **TINY-RUST** — the campaign
### is named "a verified compiler from tiny-Rust to 5-op." Concrete
### syntax: Rust-familiar (fn/let mut/while/if, curly braces), parsed
### by a TRUSTED frontend — the theorem lives AST→machine (CompCert's
### posture, stated plainly). `yield` RESERVED as a primitive for
### B-EXEC (the ML-effects harvest). v2's star, named now: ownership
### becomes the proved isolation discipline B-EXEC consumes.
### MATH'S SLATE FOLDED (19:12, six findings — v1.1): see §2/§4/§5.
### PRECONDITIONS: Slice-A ISA as landed (ADD/ADDI/XOR/SLT/BEQ; the
### certified encoder organ; sem_* family in Stack/Program.lean at
### current bytes). Compiler's night inventory may amend §1.

## 0. THE CLAIM THIS BLOCK BUYS

> ⚖️ **2026-08-23 — the `- SEAT:` refutation rows in this doc are CLOSED** (council ruling 5).
> Live obligations migrated to `docs/QUEUE.md` §MIGRATED by object-liveness audit; rows below
> are HISTORY (ruling-#7 probes quote them verbatim — do not delete or edit them).

A verified compiler: source semantics → 5-op machine semantics, the
correctness theorem in the kernel, so that "the program does what the
source says" CAN COMPOSE with "the core does what the ISA says" —
prospective, by the corpus's own kernel-checked sentence: no circuit
witnesses the ISA claim end-to-end today (evidence's audit,
conformance_does_not_determine_semantics), so the composition is
N4's obligation and the layout campaign's meeting point, never a
free consequence — and (later) "the executive schedules what the
core runs." v1 targets
SLICE A EXACTLY AS IT EXISTS — no memory, no waiting on Slice B.

## 1. THE SOURCE LANGUAGE (v1 scope, deliberately small)

- Values: `i32` ONLY in v1 — signed, WRAPPING arithmetic BY
  DEFINITION (F7 exit 1, chosen by name: Tiny-Rust is
  release-semantics Rust; the machine wraps, the source wraps, the
  theorem is provable). `u32` is v2, typed (F8: SLT is signed;
  Rust's < is type-directed; one type in v1 makes every comparison
  unambiguous).
- State: the REGISTER FILE only (v1 has no heap — Slice A has no
  loads/stores; variables are register-allocated at compile time from
  a fixed pool; programs exceeding the pool are REJECTED, not
  spilled — spilling arrives with Slice B's memory).
- Expressions: variables · constants · `+` · `xor` · `<` (the ISA's
  own operations, nothing the backend must fake except:)
- Proved lowerings, promoted from the demand-traced compile-arounds:
  `*4` (self-adds) at the source; unsigned `<` (sign-bit XOR + SLT)
  lives in the BACKEND for the comparator spec (unsigned bit-string
  compare) and reaches the source only with v2's u32 (F8 rescope).
- TYPES (Captain's council ask, folded at v1.3): τ ::= i32 | bool,
  judgment-structured (Γ ⊢ e : τ); conditions are bool (Rust-faithful,
  no truthy ints), SLT's 0/1 output IS the bool representation; the
  PRESERVATION row (big-step preserves state typing, chiefly the
  bool-is-0/1 invariant) is a kernel node — it is what makes
  BEQ-on-bool sound. v2 grows u32 + references in the SAME judgment;
  borrow rules enter as typing rules (ownership-as-theorem's static
  face). T1 UNIFICATION (math, 19:20; FORM RULED v1.4 on math's
  statement-forms proposal, helm 20:0x; FORM CORRECTED at the
  heartbeat-2 coherence pass — the ⊣ Γ' turnstile I adopted at v1.4
  CONFLICTED with v1.9's Captain-shaped CLASSICAL SEQUENCE-TYPING
  and the Captain's form wins): the judgment IS wellFormed — TWO
  judgments, `Γ ⊢ e : τ` and the sequence-typed statement form (his
  notation: no output contexts, no nonstandard turnstiles; `let`
  binds over its continuation, so scope end = liveness end and the
  live-binding count reads straight off the syntax). Math's actual
  requirement — the budget computable with no second analysis, so
  F4's c2 has nowhere to move back in — is SATISFIED by this form;
  the threading variant is not adopted. Γ is an assoc list
  (decidable lookup, structural recursion, Γ.length = live
  bindings). ⚖️ THE POOL BOUND IS SEPARATE, not
  welded in: `liveMax p ≤ poolSize` is a RESOURCE hypothesis beside
  the judgment — the judgment stays a pure SOURCE property (the same
  program must not become ill-typed on a smaller core), and rejection
  keeps exactly two characterizable causes (ill-typed | pool-exceeded).
  "Ranges" do NOT ride in the judgment — that was exit-B residue;
  F7's named wrap choice (exit A) needs no range analysis. F4
  discharged by construction; completeness reads "well-typed,
  pool-fitting programs compile." T2 CONTROLS pre-registered: one
  accepted and one REJECTED program (while 1 — i32 where bool is
  demanded), both by decide; NOTE the proposal's "with one type the
  judgment is a scope checker" premise is SUPERSEDED by this v1.3
  bool fold — the reject control fails on a genuine TYPE mismatch.
  T3: the unsigned-< lowering is LIVE in the backend (the comparator
  spec compares unsigned bit-strings — compiler's unification
  consumes it) and DEAD at the source until v2's u32 — marked so,
  not shipped silently. T4: the types do NOT close overflow — the
  semantics' named wrap choice does.
- Statements: `skip` · `let mut x : τ = e` (block-scoped binding —
  scope end = liveness end, feeding the judgment's register budget) ·
  assignment · `seq` · `if` · `while`. Expressions add `true`/`false`
  literals with the bool type.
  Big-step semantics in Lean (IMP-shaped; termination NOT assumed —
  the semantics is a relation, and the compiler theorem quantifies
  over terminating runs in v1; a fuel/small-step variant is §5's
  successor for the executive's preemption story).

## 2. THE STATEMENT (v1.1 — math's slate folded; the PAIR is the
## theorem)

ROW A (correctness): for p with wellFormed p (the judgment, v1.4) and
  liveMax p ≤ poolSize (the separate resource bound),
  compile p = some code →
  ∀ s s', bigStep p s s' →
    machRun code (encode s) = encode s'  ∧
    ∀ r ∉ pool p, (machRun code (encode s)) r = (encode s) r
  — the conclusion is FUNCTION EQUALITY (the machine is
  deterministic; F5), and the frame clause (registers outside the
  pool untouched) is IN the statement (F3 — today's L4 proved the
  ∀-w clause is the asset, not the risk).
⛔⛔ **MIG-3 REFUTATION FOLDED IN (compiler, 2026-08-24) — ROW A AS RULED
ABOVE IS VACUOUS, AND THE CORPUS ALREADY CARRIES THE REPAIR.** Three
debts, one filing; each claim checked at the bytes or in the kernel.

(a) **F2 IS UNSATISFIABLE, SO ROW A IS VACUOUS RATHER THAN UNPROVED.**
  `State` is `Nat → BitVec 32` (infinite); `St` is four finite fields —
  32 registers, a `pc`, eight memory words, a flag. No function from an
  infinite type to a finite one is injective, so `Function.Injective
  encode` is REFUTABLE for *any* candidate `encode`. An implication with
  an unsatisfiable hypothesis is trivially true: a proof of Row A in the
  form above would certify NOTHING about the compiler. **Kernel exhibit:
  `SaltWorks.HDL.MIG3.no_injective_state_encoding`** (3 axioms, no
  `sorryAx`). ⭐ The *machine-state* half was already landed and is NOT
  re-minted here — `SaltWorks.CompileS.the_final_state_is_not_an_encoding`
  reads back a dirty scratch register and a live `pc` that no `encode σ'`
  mentions. ✅ **THE LANDED SHAPE IS THE CORRECT ONE**: `encodeOK` is a
  RELATION scoped to the pool's live levels, and `regState` falls back to
  `σ` above `poolSize` because the machine cannot hold the rest. §2's
  ruled text is what never caught up. 📌 Separately, the NAME `encode` is
  already taken by `SaltWorks.ISA.encode : Instr → BitVec 32`, the
  INSTRUCTION encoder; §2 applies it to a STATE.

(b) **N0.5 "VERIFIED INLINING" HAS NO AST CONSTRUCTOR TO INLINE.** The
  compiled AST is `TinyRustN0.Stmt` = `{skip, letmut, assign, seq, ite,
  while}` — there is no call, function or procedure form anywhere in the
  language `compileS` consumes. N0.5 is not hard, it is UNSTATED: it
  presupposes a construct v1 never introduced.

(c) **N3 IS HALF-LANDED AND N5 IS BLOCKED BEHIND IT — EXHIBITED, NOT
  ASSERTED.** `while` compiles; `ite` is refused. Kernel exhibits:
  `SaltWorks.CompileS.cause_outside_the_fragment_is_now_ite_only` (seq
  compiles ∧ **ite = none** ∧ while compiles) and
  `SaltWorks.CompileS.fragment_now_includes_while`. N5 (recompile Batcher
  FROM SOURCE) cannot run while a conditional cannot be lowered.

⚠️ **ESCALATION TRIGGER MEASURED, NOT ASSUMED**: the row rises to P1 *if
any paper quotes Row A*. Four `.tex` sources exist across the fleet
(`jas/article`, `salt/papers/witness`, `salt/papers/flagship` ×2); NONE
quotes Row A. **Stays P2** — re-measure before treating that as durable.
📌 The BEQ/offset sub-item was ALREADY satisfied by
`backOffByOne_diverges_on_a_stale_guard` — do not re-commission it.

ROW B (completeness; F1 — without it Row A is satisfied by
  `compile := fun _ => none`):
  ∀ p, wellFormed p → liveMax p ≤ poolSize →
    ∃ code, compile p = some code.
  ("Well-typed, POOL-FITTING programs compile" — the two hypotheses
  are the two honest rejection causes, and there is no third.)
⛔⛔ **MIG-6 FOLDED IN (math, 2026-08-24) — THE 08/09 ANSWER TO §6's OWN QUESTION, WHICH
WAS CONFIRMED AND NEVER WRITTEN DOWN.** §6 asks math *"is anything c2-shaped or
vacuously-true hiding in the well-formedness side?"* **The answer is YES, it arrived on
08/09 as refutation passes #1 (08:45) and #2 (08:53) — ~12 h after this doc's v1.1 fold at
08/08 19:12 — and it landed on ROW B, not on `wellFormed`.** Verified absent from this file
before folding: `imem`, `instruction memory`, `scope metric`, `vacuity` = 0 hits each.

(a) **ROW B HAS ITS OWN VACUITY MODE, AND F1 DOES NOT KILL IT.** F1 exists because Row A
  alone is satisfied by `compile := fun _ => none`. But — quoting the 08/09 pass —
  *"Row B is satisfied by making `liveMax` PESSIMISTIC — define it large enough and the
  hypothesis is almost never met, so the ∀ is near-empty and the row proves easily. The
  row's truth is controlled entirely by a function that does not exist yet, and both
  failure directions are live: too pessimistic ⇒ VACUOUS · too optimistic ⇒ FALSE."*
  ⇒ **PRE-REGISTERED DEMAND, carried here so it binds the wave that states Row B: when
  `liveMax` lands it comes WITH AN EXHIBITED WITNESS — a NON-TRIVIAL `p` for which
  `liveMax p ≤ poolSize` holds, by `decide`.** *Without it, F1's own logic applies to
  F1's own row.*

(b) **ROW B's "there is no third" IS A COMPLETENESS CLAIM AND THERE IS A CANDIDATE THIRD:
  INSTRUCTION MEMORY.** The parenthetical above reads *"the two hypotheses are the two
  honest rejection causes, and there is no third."* But *"a program can be well-typed AND
  pool-fitting and still emit more instructions than the machine can hold — the freeze's
  own no-`while` note makes `code.length` the machine bound, and this is a tiny CPU."*
  ⇒ **Either imem capacity is a THIRD hypothesis, or there is a lemma proving it cannot
  bind. Today it is neither, and the sentence claims exhaustiveness.**

(c) **THE STRUCTURAL POINT, which outlives its witness: `liveMax` is a SCOPE metric being
  used as a REGISTER-DEMAND metric.** `liveMax` counts `letmut` nesting and nothing else
  (`liveMax (.assign _ _) = 0` for ANY expression) while `Exp` is fully recursive, so
  expression depth is unbounded and its register cost is counted as ZERO. The 08/09
  witness, read off the definitions:
  `p := letmut x i32 (const 0) (assign x (add (add (var x) (var x)) (add (var x) (var x))))`
  gives `liveMax p = 1`, so **Row B at `poolSize = 1` asserts this program compiles** —
  while evaluating the outer `add` needs both inner results alive at once against one pool
  register and one reserved temp. *The two metrics coincide only when expressions are flat:
  scope-end = liveness-end is true for VARIABLES, and expression temporaries are not
  variables.*
  ⚠️ **HONEST SCOPE, carried forward unchanged from the 08/09 post: `compile` did not exist,
  so this is PRE-REGISTERED, NOT PROVEN — read from the definitions, not executed. When
  `compile` lands this program must either compile, and the finding is wrong, or Row B needs
  a third resource term.**

📌 **WHY THIS SAT FOR FIFTEEN DAYS, recorded because the class matters more than the row:**
the findings were answered on the bus and folded into the *compiler's* cast of Row B; **this
document was never updated, so §6 read as an OPEN assignment for fifteen days — until this
fold, which also closes it and points here.** *A question answered
in one artifact and left open in another is indistinguishable, to the next reader, from a
question nobody answered.* ⚠️ The 08:53 post's own line — *"Pass #1's two findings were folded
before the file was cast"* — refers to that cast, not to this file; a reader chasing it should
not conclude this fold is redundant.
HYPOTHESES IN THE STATEMENT: `Function.Injective encode` (F2 — the
  hdi lesson, dropped = false at a two-line witness).
`wellFormed` is a STANDALONE DECIDABLE predicate, independent of the
  allocator; the bridge wellFormed → allocator-succeeds is a PROVED
  row, never a definition (F4 — the c2, named and barred).
machRun is the EXISTING core semantics (Stack/Program.lean's sem_*
family — consumed, not restated); encode is the register-file
embedding.
- Branch offsets: BEQ's actual offset arithmetic per the ISA — the
  known trap class (off-by-one, sign) gets its own lemma + mutation
  controls, not inline arithmetic.

## 3. DECOMPOSITION

- N0 the type system + PRESERVATION (B): the judgment, decidability,
  and the bool-representation invariant — N1-N3 consume it. The
  judgment carries function signatures in a SEPARATE context Δ —
  arrows never enter τ (no first-class functions; this is what makes
  inlining complete and the DAG check well-defined; if arrows ever
  move into τ, JALR is the waiting hardware) — and DEMANDS the call
  graph be a DAG (decidable; recursion rejected in v1 — a
  pre-registered reject control alongside while-1).
- N0.5 VERIFIED INLINING (B/C): multiple functions with tail-
  expression returns, compiled by inlining (params → let-bindings);
  the theorem "inlining preserves bigStep" is its own node. No JAL
  needed; Slice B's JAL/JALR upgrade the STRATEGY, not the source.
  Boundary named: no tuples and no &mut in v1 ⇒ multi-output
  helpers (cex) stay frontend sugar until v2's references.
- N1 expression compilation + correctness (B): registers-and-ops,
  the two proved lowerings folded in.
- N2 statement compilation, straightline (B): seq/assign; the
  simulation lemma's shape fixed here.
- N3 control lowering (C, the soul): if/while via BEQ with computed
  offsets; the simulation argument over program-counter traces.
  The trap: a `while` whose body is empty and a branch to self —
  state the divergence case honestly (v1 proves terminating runs).
- N4 top-level composition + the end-to-end theorem (B, rides N1-N3).
- N5 demo: recompile the Batcher sort FROM SOURCE; the story's
  closing exhibit (the same program, now with a verified path from
  source text to certified gates).

## 4. KNOWN TRAPS

- Offset arithmetic (above). Every offset lemma carries a mutation
  control that makes the goal FALSE (±1 the offset), not unreachable.
- The encode/decode boundary: state the register-file embedding once;
  the ∀-w whole-file clause per the ③ campaign's port-axis lesson.
- Do NOT quantify over the machine's runFrame-style drivers — the
  theorem lives at the ISA semantics layer (the ③ lesson, ∀-P's
  ghost, pre-applied).
- Rejection is governed by Row B, not by prose (F1).
- PRE-REGISTERED CONTROL on bigStep itself (F6): one concrete program
  with `bigStep p s s'` INHABITED, by decide, before any wave — a
  mis-defined relation that steps nothing turns every row vacuously
  green; the relation is shown NONEMPTY, never assumed.

## 5. DEFERRED, BY NAME

- Memory (arrays, load/store): arrives WITH Slice B — the language's
  v2 and B-ISA are one campaign in two files.
- References, OWNERSHIP and BORROWING (F9, named so the title cannot
  over-claim): VACUOUS in v1 — registers only, nothing to own; v1's
  Tiny-Rust is the register-only fragment. The borrow discipline
  arrives with Slice B's memory, as the isolation theorem's static
  face.
- `u32` and typed signedness (F8): v2, with the source-level unsigned
  compare.
- RECURSION: rejected by the v1 judgment (DAG check); arrives with
  Slice B's JAL/JALR + stack — real frames replace inlining, source
  unchanged.
- Divergence-sensitive semantics (small-step + fuel): needed by
  B-EXEC's preemption story; v1's big-step terminating-runs form is
  the honest first cut. NAMED with it (math's slate): nothing in v1
  gives machine-termination ⇒ source-termination — that direction
  belongs to the preemption story and is deferred BY NAME so it is
  never assumed.
- The Lean-DSL fallback: if the two-week clock tightens, N1-N2 keep,
  N3 simplifies to macro-verification; ~3 days cheaper, weaker story.

## 6. REFUTATION ASSIGNMENTS (draft-until-refuted)

- MATH: §1/§2 statement forms — the semantics relation's shape, the
  encode quantification, the terminating-runs scope; is anything
  c2-shaped or vacuously-true hiding in the well-formedness side?
  ✅ **ANSWERED 08/09 (passes #1 08:45, #2 08:53) — YES, and the fold is
  in §2 under ROW B (MIG-6, folded 2026-08-24).** The vacuity is on
  ROW B, not on `wellFormed`: a pessimistic `liveMax` empties the ∀.
  Three parts — Row B's own vacuity mode with its pre-registered
  witness demand; the "no third rejection cause" completeness claim
  against a candidate third (imem); and `liveMax` as a SCOPE metric
  standing in for a REGISTER-DEMAND metric, with a witness at
  `poolSize = 1`. **PRE-REGISTERED, not proven — `compile` did not
  exist when the passes ran.**
- COMPILER: §2/§3 against the ACTUAL core semantics (your inventory:
  does machRun exist in the stated form, or what supplies it?); the
  offset arithmetic against the landed BEQ; N5's feasibility.
- SILICON: nothing hardware-side in v1; optional read.
- EVIDENCE: the claim-scope audit — does §0's composition sentence
  outrun what §2 states?
