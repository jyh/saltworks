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

A verified compiler: source semantics → 5-op machine semantics, the
correctness theorem in the kernel, so that "the program does what the
source says" composes with "the core does what the ISA says" and
(later) "the executive schedules what the core runs." v1 targets
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
  face). T1 UNIFICATION (math, 19:20): the judgment IS wellFormed —
  one relation carrying typing + scope + live-binding budget +
  ranges; no separate predicate, F4 discharged by construction;
  completeness reads "well-typed programs compile." T2 CONTROLS
  pre-registered: one accepted and one REJECTED program (while 1 —
  i32 where bool is demanded), both by decide. T3: the unsigned-<
  lowering is LIVE in the backend (the comparator spec compares
  unsigned bit-strings — compiler's unification consumes it) and
  DEAD at the source until v2's u32 — marked so, not shipped
  silently. T4: the types do NOT close overflow — the semantics'
  named wrap choice does.
- Statements: `skip` · assignment · `seq` · `if` · `while`.
  Big-step semantics in Lean (IMP-shaped; termination NOT assumed —
  the semantics is a relation, and the compiler theorem quantifies
  over terminating runs in v1; a fuel/small-step variant is §5's
  successor for the executive's preemption story).

## 2. THE STATEMENT (v1.1 — math's slate folded; the PAIR is the
## theorem)

ROW A (correctness): for p with wellFormed p, compile p = some code →
  ∀ s s', bigStep p s s' →
    machRun code (encode s) = encode s'  ∧
    ∀ r ∉ pool p, (machRun code (encode s)) r = (encode s) r
  — the conclusion is FUNCTION EQUALITY (the machine is
  deterministic; F5), and the frame clause (registers outside the
  pool untouched) is IN the statement (F3 — today's L4 proved the
  ∀-w clause is the asset, not the risk).
ROW B (completeness; F1 — without it Row A is satisfied by
  `compile := fun _ => none`):
  ∀ p, wellFormed p → ∃ code, compile p = some code.
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
  and the bool-representation invariant — N1-N3 consume it.
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
- COMPILER: §2/§3 against the ACTUAL core semantics (your inventory:
  does machRun exist in the stated form, or what supplies it?); the
  offset arithmetic against the landed BEQ; N5's feasibility.
- SILICON: nothing hardware-side in v1; optional read.
- EVIDENCE: the claim-scope audit — does §0's composition sentence
  outrun what §2 states?
