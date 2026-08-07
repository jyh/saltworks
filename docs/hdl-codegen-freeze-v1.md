# LEG 2 WEEK-2 FREEZE v1 — the code generator and the simulation proof
### 2026-08-06, compiler seat (compiler-acct). The keystone of Council I's tower.
### STATUS: FROZEN PENDING AN ADVERSARIAL PASS — see §0. Do not start building.

---

## 0. READ THIS FIRST — the status of this document, stated honestly

**This freeze was written by the seat that would build it.** That is a conflict,
and this campaign has already paid for the alternative arrangement: the leg-2
freeze (`hdl-design-v1.md`) was written by a seat that had not measured, and the
refuter pass (`hdl-refuter-0806.md`) killed three of its rulings in an afternoon
— the `Vector` bus type, the "2^16 ≈ 12 s" cost law, and T4, **which was not
merely mis-scoped but UNSTATEABLE against the declared semantics.**

⛔ **REAL STATUS AFTER THE FIRST PASS (silicon, 20:05-20:07): THREE OF FIVE
KILL-CHECKS ARE BLOCKED ON ONE MISSING ARTIFACT.** `step`, `Instr` and `St` do
not exist in Lean — `grep` returns 0 hits for `inductive Instr`, `structure St`
and `def decode` across the repo, and the four `def step*` that do exist are
Banyan routing and gate evaluation. **R1 is UNRUNNABLE; R2 and R4 are runnable
only in the halves that do not mention `step`; the P4 fork above is unresolvable
until it lands.** *This freeze is not wrong — it is EARLY, and it is a document
about a seam whose far side has not been built.*

Two consequences, both binding:

1. **A refuter pass runs before a line is written.** Kill-checks are in §7. The
   pass must be run by a seat that is not me.
2. **Every number in this document is labelled MEASURED or ESTIMATED**, and the
   estimates are marked as the weak ones. Today's most expensive error in this
   fleet was a constant I derived by subtracting two instruments and published
   as a property of the world. I am not repeating it in a freeze.

**What is different from the leg-2 freeze, in this document's favour:** leg 2's
artifacts now EXIST and are kernel-checked, so the bottom of the tower is not a
promise. `Circ`, `sem`, `opt`+`opt_sem`+`opt_wf`, `emitN`+`emitN_sem`,
`normalize` with all five renumber obligations, and the `Seq` sequential
extension are landed, axiom-clean and warning-free.

---

## 1. THE OBJECT — and the boundary with the datapath brief

Evidence's `EVIDENCE-riscv-datapath-brief.md` scopes **Slice A: the datapath** —
`St`, `decode`, `step`, five instructions, and T-EQUIV against a `Circ`. It is a
brief, not a freeze, and it stops at `step`.

**This freeze is the layer ABOVE it: a source language, a code generator into
those five instructions, and the theorem that the generated code simulates the
source.** The two documents meet at exactly one artifact and nowhere else:

```
    Src (this freeze)  --compile-->  List Instr
        |                                |
    srcSem                          step*  (the ISA spec — EVIDENCE'S BRIEF, W2.1)
        |                                |
        +======= SIMULATION THEOREM =====+     <-- THIS FREEZE
                                         |
                                     T-EQUIV                <-- the brief, W2.3
                                         |
                                    sem (Circ)              <-- leg 2, LANDED
                                         |
                              emitN / normalize / netlist   <-- leg 2, LANDED tonight
```

⛔ **THE SEAM IS THE SCHEDULE RISK AND IT IS NOT MINE TO CLOSE.** The code
generator targets `step`. If `step`'s type, its instruction datatype, or its
register model move after I start, every proof in this freeze re-opens. The
leg-2 refuter pass's R2 said exactly this about the leg-2/leg-3 seam and it was
the one kill-check that mattered. ⇒ **`step` must be landed and frozen before
day 1 of this work.** Not sketched. Landed.

---

## 2. THE SOURCE LANGUAGE — and why it stops where it stops

```lean
inductive Exp where
  | var   (x : Nat)
  | const (n : Int)
  | add   (a b : Exp)
  | xor   (a b : Exp)
  | slt   (a b : Exp)          -- signed <, yielding 0 or 1

inductive Stmt where
  | assign (x : Nat) (e : Exp)
  | seq    (s t : Stmt)
  | ite    (c : Exp) (t e : Stmt)
```

**`while` IS DELIBERATELY ABSENT, and this is the freeze's largest scoping
decision.** With loops the source semantics needs fuel or coinduction and the
simulation theorem becomes conditional on termination — a different and much
larger proof. Without loops:

* the source language is **terminating by construction**, so `srcSem` is a
  total structural function and the simulation proof is a structural induction;
* **machine execution is bounded by the code length**, because every branch the
  generator emits is FORWARD. No fuel parameter is needed anywhere. *(This is a
  real consequence of excluding loops and it should be checked by the refuter:
  if any emitted branch can be backward, the bound is wrong and so is the
  execution model.)*

**It is still a language.** Assignment, sequencing and conditionals over integer
expressions is a terminating imperative language, and it exercises **all five**
of Slice A's instructions: `ADD` (add), `ADDI` (const, from `x0`), `XOR` (xor),
`SLT` (slt), `BEQ` (ite). Nothing smaller exercises `BEQ`; nothing larger is
needed to say the tower closed.

**Loops are a separately-frozen stretch (`while`, fuel-indexed).** Naming it
here so that "no loops" reads as a decision rather than an omission.

---

## 3. THE COMPILER IS PARTIAL, AND THAT IS FORCED BY THE DATAPATH

Slice A has **no memory** — no loads, no stores (the brief's §2.2, and it calls
the absence a feature). Therefore **there is no spill space**, and therefore the
code generator cannot be total. Three independent sources of partiality, all
inherited rather than chosen:

| # | Source | The bound |
|---|---|---|
| P1 | **Expression depth** — temporaries live only in registers | nesting beyond the temp budget cannot be compiled |
| P2 | **Variable count** — one register per live variable | more variables than registers cannot be compiled |
| P3 | **Immediate range** — `ADDI` takes a 12-bit SIGNED immediate | constants outside `[-2048, 2047]` need `LUI`, which Slice A excludes |

### P4 and P5 — FOUND BY THE REFUTER PASS (silicon, R3, 20:07). NOT MINE.

| # | Source | The bound |
|---|---|---|
| **P4** | **BEQ branch-offset RANGE** — `§4.1`'s offsets grow with the compiled body | a `then` branch longer than ~1023 instructions cannot be **encoded** |
| **P5** | **`x0` as an assignment DESTINATION** | if `reg x = x0`, `[ADD (reg x) x0 t0]` is `ADD x0 x0 t0` — **a silent NO-OP** |

⛔ **P4 IS A FORK, AND BOTH PRONGS COST SOMETHING — it is not a missing table row.**

| if `step` models the offset as… | consequence |
|---|---|
| a **bounded encoding** — the ISA manual's own words, fetched by the silicon seat from `riscv/riscv-isa-manual`, `src/unpriv/rv32.adoc`: *"The 12-bit B-immediate encodes signed offsets in multiples-of-two bytes"*, *"The conditional branch range is ±4 KiB"* ⇒ **±1024 four-byte instructions** | **P4 is real and was unlisted**; `compile` must return `none` on long branches and C3's hypothesis needs the extra conjunct |
| an **unbounded index** (`Int`, instruction-counted) | **there is no P4 — and C3 then proves a theorem about a machine that is not RISC-V.** The five-instruction claim silently becomes *"five instructions, one of which has an encoding we do not model"* |

**Nothing in P1–P3 bounds it:** P1 bounds expression *depth*, P2 bounds *live
variables*, P3 bounds *`ADDI` immediates*. **A `seq` of a few thousand small
statements violates none of them and still cannot be encoded.**

⚠️ **AND P5 IS THE `x0` TRAP ON THE SIDE §7's R3 DID NOT NAME.** I predicted *"a
generator that ever allocates `x0` as a TEMPORARY"*. The real one is `x0` as a
**destination**: the program compiles, runs, and the variable never changes.
**Right register, wrong direction** — and a certificate catches it only if some
program in the suite actually assigns to that variable.

⇒ **`compile : Stmt → Option (List Instr)`, and the simulation theorem is
conditioned on `compile p = some code`.**

⭐ **This is leg 2's own design philosophy arriving at the top of the tower, and
the freeze should say so out loud.** `dce` does not *prove* its liveness
analysis correct — it CHECKS the property it needs and falls back
(`Opt.lean`). `emitPipeline` does not *prove* `opt` preserves density — it
checks `ssa` and falls back (`EmitN.lean`). **The code generator does not prove
every program fits in 32 registers — it checks, and returns `none`.** A bug in
the budget analysis costs compilation; it cannot cost correctness. *Three
instances of one move, at three levels of the same tower.*

---

## 4. THE THEOREMS — the deliverables, in dependency order

**C1 — `srcSem` is total.** `srcSem : Stmt → Env → Env`, structurally recursive,
no fuel, no side conditions. *(Env is a total function `Nat → Int`, per the
measured rule from the leg-2 refuter pass: never an append-extended environment.)*

**C2 — THE EXPRESSION FRAME LEMMA.** `compileExp e d` emits code that leaves
`evalExp e σ` in register `d` and **modifies no register below `d`**.

> This is the proof, and everything else is bookkeeping around it. It is the
> same shape as every load-bearing lemma in leg 2 — `run_of_unwritten`,
> `run_filter`, `runP_ssaFrom`, `run_renumFrom`: *a frame condition saying what
> a piece of generated code does NOT touch.* The renumber's `run_renumFrom`
> turned out to need no injectivity once the frame was stated as "everything
> defined renames strictly below the next new name"; **the refuter should ask
> whether C2 has a similarly weaker sufficient form before anyone proves the
> obvious one.**

**C3 — THE SIMULATION THEOREM.** For `compile p = some code` and a source
environment matching the register file on mapped variables, running `code` from
`pc = 0` reaches `pc = code.length` in a state matching `srcSem p σ`.

**C4 — THE TOWER, COMPOSED.** C3 ∘ T-EQUIV ∘ `emitN_sem`: a source program's
meaning, carried to the gate netlist, with no unproved link. **This is the
keystone claim and it is the only sentence in this freeze worth saying in
public.**

### 4.1 The intended compilation scheme — stated so R4 can actually be run

*Added after writing §7: **R4 asks the refuter to check that every emitted branch
is forward, and the document did not say what the generator emits.** A
kill-check whose referent is missing cannot be run — which is the defect this
fleet spent 2026-08-06 finding in four separate instruments, including a guard
specified against an error string that does not exist in Lean. So:*

```
compileExp (const n) d = [ADDI d x0 n]                    -- P3 bounds n
compileExp (var x)   d = [ADD  d x0 (reg x)]
compileExp (add a b) d = compileExp a d ++ compileExp b (d+1) ++ [ADD d d (d+1)]
   (xor, slt identically, with XOR / SLT)

compile (assign x e) = compileExp e t0 ++ [ADD (reg x) x0 t0]
compile (seq s t)    = compile s ++ compile t
compile (ite c s t)  = compileExp c t0
                    ++ [BEQ t0 x0 (|S| + 1)]      -- c = 0  -> skip S, land on T
                    ++ S                           -- S = compile s
                    ++ [BEQ x0 x0 |T|]             -- unconditional: skip T
                    ++ T                           -- T = compile t
```

**Both branches are forward**, which is what §2's no-fuel execution model rests
on. ⭐ **And the unconditional jump is `BEQ x0 x0` — `x0` equals itself always,
so the branch is taken unconditionally and NO SIXTH INSTRUCTION IS NEEDED.**
Slice A excludes `JAL`/`JALR`; without this trick `ite` would not compile and the
five-instruction claim would be false. *The refuter should confirm that `step`
as landed actually evaluates `BEQ x0 x0` as taken rather than special-casing
`x0` reads in a way that breaks it — that is R3's `x0` trap arriving from the
other side.*

**C5 — CERTIFICATES.** Concrete programs run end to end by `decide +kernel`.
Cost is EVALUATION, not quantification — no input space is enumerated — so this
is cheap and should be exercised on a program a reader can follow by hand.

**C6 — A MUTATION CONTROL, non-negotiable.** At least one deliberately broken
generator (an off-by-one branch offset is the natural one) must make C5 FAIL.
The leg-2 refuter pass found T1/T2/T5 each satisfied by a one-line trivial
witness; D4's control was this morning's real routing bug. **A certificate with
no mutation control is not evidence.**

---

## 5. WHAT IS DELIBERATELY NOT CLAIMED

- **Not a compiler.** No optimisation, no register allocation worth the name
  (a fixed budget with a `none` on overflow), no calling convention, no linking.
- **Not CompCert.** The source language has three statement forms.
- **No loops, no functions, no memory, no I/O.** P1–P3 are stated exclusions.
- **`emitV` remains UNTRUSTED**, as in leg 2. The trusted path is `emitN`.
- **The generated code is not claimed to be efficient, small, or idiomatic** — and
  one specific non-idiom must be said out loud rather than discovered by a
  referee who knows RV32I: **Slice A excludes `JAL`, so `ite` is compiled with an
  always-true `BEQ`, which the ISA manual tells you not to do.** The manual's two
  reasons — offset range and branch-prediction pollution — are a *performance*
  objection; **neither affects the theorem, and both are consequences of the
  datapath's stated exclusions rather than of the generator's design.**

**If this is described as anything but "a terminating three-form imperative
language compiled to five RV32I instructions, with a machine-checked simulation
proof", the claim is being overstated.** *(The datapath brief's §7 makes the
same move for the same reason, and it is right.)*

---

## 6. IRON RULES

salt's, unchanged: **no `sorry`, no `native_decide`, no new axioms**;
`#audit_axioms` on every theorem AND on every definition; `decide +kernel`,
never bare `decide`; `bv_decide` only as a dev accelerant, never shipped
(JYH-ruled 8/6); A/B/C classification before attempts; 3-attempt budget then
flag. **Every Lean invocation through `../saltbuild.sh`** — never bare `lake`,
never bare `lean`.

**And three added tonight, each earned:**

* **Judge builds by the TEXT and by the VERB.** `Replayed` is not `Built`; a
  green build whose modules replay proves the cache, not the kernel.
* **A cap hit is `(kernel) excessive memory consumption detected` or
  `excessive memory consumption detected at '<component>'`, and nothing else.**
* **`abbrev Net := Nat` defeats `omega` — SIX times across leg 2.** Any
  arithmetic on a type-aliased index needs restating at `Nat` in a `have`
  before use. Whatever this freeze's index type is, expect the same.

---

## 7. REFUTER KILL-CHECKS — run these before a line is written

**R1 — IS THE SEAM REAL?** Read the datapath brief's `step` and instruction
datatype **as landed, not as described**. Does `compile`'s output type match
what `step` consumes? The leg-2 pass found T2 "had no referent"; the same
failure here is a week.

**R2 — IS C3 STATEABLE?** T4 was killed because `sem` exposed only primary
outputs and the theorem could not be written against it. **Write C3's statement
in full, against the landed `step`, before trusting this document.** If it needs
a hypothesis that cannot be inhabited, C3 is vacuous — and the sp1-lean audit's
first finding was exactly a vacuously-true theorem about `SLT`.

**R3 — ARE P1–P3 THE ONLY PARTIALITY? ✅ RUN 2026-08-06 20:07 BY THE SILICON
SEAT — RETURNED TWO, AND MY PREDICTION WAS WRONG IN DIRECTION.** I predicted a
trap at `x0`-as-a-TEMPORARY. The found ones are **P4 (branch-offset range)** —
which I had not considered at all and which no P1–P3 bound touches — and **P5,
`x0` as a DESTINATION**, which is the same register and the opposite direction.
Both are now in §3. **A refuter that returns the defect you predicted has told
you less than one that returns the defect beside it.**

**R4 — IS THE FORWARD-BRANCH CLAIM TRUE?** §2 asserts every emitted branch is
forward, and the whole no-fuel execution model rests on it. **The scheme is now
written out in §4.1 so this check has a referent** — attack the `ite` case, and
in particular the `BEQ x0 x0` unconditional jump, which is load-bearing: without
it `ite` needs `JAL`, which Slice A excludes, and the five-instruction claim is
false. If either branch can be backward, the execution model is wrong and C3's
statement changes shape.

**R5 — IS THE MUTATION CONTROL DISCRIMINATING?** Per tonight's rule: a mutant
must be caught by the check that owns it AND BY NO OTHER. A broken branch offset
that also breaks the frame lemma has tested their union, which is not a thing
anyone relies on.

---

## 8. WHAT WOULD MAKE ME ABANDON THIS — stated before the data

1. **`step` is not landed and frozen at start.** Then this is not startable, per
   §1. It waits; it does not begin against a moving target.
2. **C2 does not converge in three attempts.** Then the fallback is
   straight-line only (drop `ite`), which loses `BEQ` and therefore loses the
   claim that the codegen exercises the datapath — **and at that point the
   honest move is to stop, not to ship a smaller tower quietly.**
3. **Leg 3's floor or the shuttle deadline needs the hours.** The tapeout is the
   promise; the tower is the bonus. 31 days to the hard deadline as of writing
   *(computed, not carried — a countdown is correct once and wrong every day
   after)*.

---

## 9. THE ONE SENTENCE, IF IT LANDS

> *"A three-form imperative language, compiled by a machine-checked code
> generator into five RV32I instructions, whose generated programs are proved to
> simulate their source — and the same proof chain continues through the
> datapath to a gate-level netlist. Source to silicon, three axioms end to end."*

And the honest companion, to be said in the same breath:

> *"The compiler is partial: no memory means no spilling, so it refuses programs
> that do not fit in the register file, and says so by returning `none`."*
