# THE LANGUAGE — verified compiler design block v1 (maestro, 8/8 night)
### Status: DRAFT-UNTIL-REFUTED. Captain-opened 8/8 evening ("let's
### pick a software language"); the maestro's recommended fork drafted
### here — a small IMPERATIVE language — with the Lean-DSL fallback
### recorded. The Captain christens the name; redirection is cheap.
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

- Values: machine words (the core's width; from compiler's inventory).
- State: the REGISTER FILE only (v1 has no heap — Slice A has no
  loads/stores; variables are register-allocated at compile time from
  a fixed pool; programs exceeding the pool are REJECTED, not
  spilled — spilling arrives with Slice B's memory).
- Expressions: variables · constants · `+` · `xor` · `<` (the ISA's
  own operations, nothing the backend must fake except:)
- Proved lowerings, promoted from the sort demo's compile-arounds:
  `*4` (self-adds), unsigned `<` (sign-bit XOR + SLT). These enter as
  verified rewrite lemmas in the backend, not as source primitives.
- Statements: `skip` · assignment · `seq` · `if` · `while`.
  Big-step semantics in Lean (IMP-shaped; termination NOT assumed —
  the semantics is a relation, and the compiler theorem quantifies
  over terminating runs in v1; a fuel/small-step variant is §5's
  successor for the executive's preemption story).

## 2. THE STATEMENT (shape)

For a well-formed program p (register-allocable, in-range constants):
  compile p = some code →
  ∀ s s', bigStep p s s' → machRun code (encode s) ⇓ (encode s')
where machRun is the EXISTING core semantics (Stack/Program.lean's
sem_* family — the compiler theorem consumes the certified organs,
it does not restate them), and encode is the register-file embedding.
- The compiler is a FUNCTION (may reject: `none` on pool overflow or
  width overflow — rejection is not a theorem obligation).
- Branch offsets: BEQ's actual offset arithmetic per the ISA — the
  known trap class (off-by-one, sign) gets its own lemma + mutation
  controls, not inline arithmetic.

## 3. DECOMPOSITION

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
- The rejection path is not decorative: `compile p = none` cases need
  a completeness note (what v1 rejects and why), or the theorem
  reads stronger than it is.

## 5. DEFERRED, BY NAME

- Memory (arrays, load/store): arrives WITH Slice B — the language's
  v2 and B-ISA are one campaign in two files.
- Divergence-sensitive semantics (small-step + fuel): needed by
  B-EXEC's preemption story; v1's big-step terminating-runs form is
  the honest first cut.
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
