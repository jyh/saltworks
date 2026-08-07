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

🔴 **AND AFTER THE SECOND PASS (10 agents, 20:07-20:25): THERE IS A SECOND,
INDEPENDENT REASON NOT TO START, AND IT IS THE MORE SERIOUS OF THE TWO.** The
missing seam **stops** work. **A false C3 does not — it lets work proceed and
fails at the end.** §2's source language was over unbounded `Int` while the
machine is `BitVec 32`; `grep -c BitVec` on this document returned **0** against
**15** in the brief. **C3 was therefore not unstateable — it was stateable and
FALSE**, refuted by a 23-statement program this document's own `compile`
accepts. That is the T4 class of defect arriving in a worse form: *a false
theorem is a harder failure than an unstateable one, because it survives being
written down.* **§2 is retyped to `BitVec 32` as of this revision** (§2, §4 C1,
and C3's matching relation, which is now written out IN FULL — its absence is
what let this through, and that is the identical failure to T4's).

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

⚠️ **WITH ONE QUALIFICATION THE REFUTER PASS PUT ON THIS EXACT SENTENCE, and it
is fair.** `grep -rn "import SaltWorks.HDL.Renumber"` returns **0 hits
fleet-wide**: `Renumber.lean` imports `EmitN` and **nothing imports
`Renumber`**, so it sits outside the hub's transitive closure and **its
`#audit_axioms` never fire in the DEFAULT build.** The renumber IS
kernel-checked — by a targeted build, on this machine, `Built` and not
`Replayed` — but *"the default build covers leg 2"* is false tonight. ***Import
owed: `SaltWorks.HDL.Renumber`.*** Maestro-owned; reported, not touched. *An
agent with no knowledge of my 19:50 muster re-derived this from the citation
above — which is the paragraph arguing that the bottom of the tower is not a
promise.*

---

## 1. THE OBJECT — and the boundary with the datapath brief

Evidence's `EVIDENCE-riscv-datapath-brief.md` scopes **Slice A: the datapath** —
`St`, `decode`, `step`, five instructions, and T-EQUIV against a `Circ`. It is a
brief, not a freeze, and it stops at `step`.

**This freeze is the layer ABOVE it: a source language, a code generator into
those five instructions, and the theorem that the generated code simulates the
source.** ~~The two documents meet at exactly one artifact and nowhere else:~~

🔴 **STRUCK — FALSIFIED 138 LINES LATER BY THIS DOCUMENT ITSELF (R1(d), refuter
pass, 20:25).** C4 below is `C3 ∘ T-EQUIV ∘ emitN_sem`, and **T-EQUIV is the
BRIEF's artifact** (W2.3) — so the keystone claim touches two of the brief's
artifacts, the diagram immediately below draws four, and §0 names three missing
objects rather than one. **The seam is the manifest in §1.1. One row is pinned;
zero are landed.** *The sentence was a claim about scope, and scope is exactly
what a freeze is for.*

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

### 1.1 THE SEAM MANIFEST — replacing the struck "exactly one artifact"

**Eleven artifacts. ONE is pinned. ZERO are landed.** Each needs a named owner
and a landing date before day 1; the status column is `grep`, not opinion.

| # | Artifact | Status |
|---|---|---|
| 1 | `St` | **PINNED** — brief:110-111. *The only one.* |
| 2 | `Instr`, with field types | absent — brief:127 is a markdown table header, the sole occurrence |
| 3 | `decode` | a name only — brief:302; no type anywhere |
| 4 | `step` | one line inside a fenced diagram, brief:186, in a file whose line 6 says *"a brief, not a freeze"* |
| 5 | `encode : Instr → BitVec 32` | absent and **REQUIRED**: `compile` yields `List Instr`, `step` consumes `BitVec 32` |
| 6 | `decode (encode i) = i` | absent |
| 7 | `run : List Instr → St → …` | **absent and UNOWNED** — `step` consumes one instruction; C3 needs iteration; brief:302's own exit test presupposes it |
| 8 | the pc↔index convention (byte vs instruction) | **CONTRADICTED** — C3 vs brief:248. See §4.1. |
| 9 | `reg : Nat → Nat` and `t0`, with `reg` injective, `reg x ≠ 0`, `reg x < 32`, range disjoint from `[t0, t0+depth]` | used throughout §4.1 and in C3's *"mapped variables"* — **never defined** |
| 10 | the `x0`-suppression theorem | brief:304 owns it; **C2's frame lemma is false without it** |
| 11 | `BitVec 32 ↔ List Bool` bus coding | **genuinely unassigned** — T-EQUIV equates `Circ → (Net → Bool) → List Bool` (`Sem.lean:32,:72`) with `St → BitVec 32 → St`; `grep -rn BitVec SaltWorks/HDL/*.lean` returns ONE hit and it is a comment (`Certs.lean:16`) |

⚖️ **AND THE BRIEF MUST MAKE ONE RULING OUT LOUD**, because rows 5 and 6 exist
only because of it: either **retype `step : St → Instr → St`** — which deletes
rows 5-6 and demotes `decode`, at the cost of weakening the "ISA spec" reading —
**or keep `BitVec 32` and own the encoder**, whose partiality (odd byte offsets
are unrepresentable in B-format, brief:249) is a **further** partiality source.
*Either is fine. One must be chosen and written down.* **Not mine to choose.**

---

## 2. THE SOURCE LANGUAGE — and why it stops where it stops

```lean
inductive Exp where
  | var   (x : Nat)
  | const (n : BitVec 32)      -- RETYPED, see 2.1. Was `Int`, and that was the kill.
  | add   (a b : Exp)          -- BitVec.add  (wrapping)
  | xor   (a b : Exp)          -- BitVec.xor
  | slt   (a b : Exp)          -- BitVec.slt, yielding 0 or 1

inductive Stmt where
  | assign (x : Nat) (e : Exp)
  | seq    (s t : Stmt)
  | ite    (c : Exp) (t e : Stmt)
```

### 2.1 WHY THE VALUE DOMAIN IS `BitVec 32` — the refuter pass's only kill that blocks a line of Lean

⛔ **AS FROZEN AT `380224d` THIS LANGUAGE WAS OVER UNBOUNDED `Int` AND THE
MACHINE IS `BitVec 32` (brief:110-111). C3 WAS THEREFORE STATEABLE AND FALSE.**
`grep -c BitVec` on that revision of this document: **0**. On the brief: **15**.
*A simulation theorem between an unbounded-integer language and a 32-bit
machine, and the word never occurred.*

**WITNESS 1 — accepted by this document's own `compile`, from `σ₀ = fun _ => 0`.**
`assign 0 (const 2000)`, then 21× `assign 0 (add (var 0) (var 0))`, then
`assign 1 (slt (var 0) (const 0))`. Depth 2 (P1 ✅), two variables (P2 ✅),
constants inside `[-2048, 2047]` (P3 ✅), straight-line (P4 cannot fire),
`reg 1 ≠ x0` arrangeable (P5 ✅). **MEASURED — recomputed, not quoted:**

```
2000 · 2²¹ = 4,194,304,000       source  slt(v, 0) = False   ⇒  σ 1 = 0
mod 2³²    = 0xFA000000          toInt   = -100,663,296      ⇒  machine writes 1
MINIMAL:   2047 · 2²⁰ = 2,146,435,072 < 2³¹ — no P3-legal constant reaches the
           sign bit in twenty doublings.
Init/Data/BitVec/Basic.lean:388   protected def slt (x y : BitVec n) : Bool := x.toInt < y.toInt
```

🔴 **WITNESS 2 KILLS THE OBVIOUS REPAIR, AND IT IS THE HALF I WOULD HAVE GOT
WRONG.** `assign y (slt (const 0) (add (var a) (var b)))` with `σ a = σ b = 2³⁰`.
**Both inputs are comfortably in signed range, so an initial-state range
invariant HOLDS.** Source: `2³¹ > 0` ⇒ 1. Machine: the temporary is
`0x80000000`, `toInt = -2³¹` ⇒ 0. ***The overflow is INTERMEDIATE and never
appears in any variable, so no relation on the state can see it.***

⭐ **WHY NO CLEVERER RELATION RESCUES `Int`, and it is not the reason I
predicted.** Truncation mod 2³² **IS** a homomorphism for `add` and `xor` — both
survive it intact. It dies at **`slt`**, because `slt` is not an operation on the
carrier: it is an **OBSERVATION** that collapses the carrier to `{0,1}`, and
truncation does not commute with an order comparison. *I pre-registered the
prediction that overflowing `+` would be the kill. `+` is fine. Had I fixed this
myself by bounding `+`, I would have shipped the same false theorem.*

⚠️ **AND IT CANNOT BE PUSHED INTO `Option`, WHICH BREAKS §3's CELEBRATED MOVE.**
P1-P5 are **syntactic** properties of `p`, which is precisely why
`compile : Stmt → Option (List Instr)` can decide them. **Overflow is a property
of the PAIR `(p, σ)` — and `compile` never sees `σ`.** So §3's *"a bug in the
budget analysis costs compilation; it cannot cost correctness"* is **false as a
general claim about this design**: this was a correctness hole no budget analysis
is a check for. ⇒ **RULING: retype, do not side-condition.** The alternative —
keep `Int`, add `NoOvf : Stmt → Env → Prop` to C3 — is stateable and true, but it
is a semantic side condition `compile` cannot discharge, and it would put back
exactly the conditional-on-a-hypothesis shape this design exists to avoid.
**The retype's dividend: the matching relation becomes the IDENTITY on mapped
registers**, which collapses half of C2's bookkeeping.

📌 **The one defence the frozen text offered does not defend it.** C1 pinned
`Nat → Int` *"per the measured rule from the leg-2 refuter pass."* That rule
(`hdl-refuter-0806.md:43-44`) is about the environment's **SHAPE** — a 2.0×
finding on append versus prepend. **It says nothing about the value type.**
`Nat → BitVec 32` obeys it exactly as well.

**`while` IS DELIBERATELY ABSENT, and this is the freeze's largest scoping
decision.** With loops the source semantics needs fuel or coinduction and the
simulation theorem becomes conditional on termination — a different and much
larger proof. Without loops:

* the source language is **terminating by construction**, so `srcSem` is a
  total structural function and the simulation proof is a structural induction;
* **machine execution is bounded by the code length**, because every branch the
  generator emits is FORWARD. No fuel parameter is needed anywhere. ✅ **CHECKED
  AND CONFIRMED (R4, 20:25): every displacement §4.1 emits is non-negative under
  ALL FOUR candidate conventions** (own-address or next-instruction × bytes or
  instructions), so the no-fuel model is not unsound on that ground. ⚠️ **But
  the sentence's JUSTIFICATION was wrong and is corrected here: it is a
  consequence of excluding loops AND of every offset fitting the B-type
  immediate — which is P4.** Excluding loops alone does not bound the machine.

⭐ **AND ONE THING THE NO-FUEL CLAIM DOES *NOT* FORCE, refuted inside the pass:**
that C5 must use well-founded recursion on `code.length - pc`, which
`Sem.lean:18-21` warns will not reduce in the kernel. `go` structural on a `Nat`,
invoked as `exec code s := go code.length code s`, is **structural,
kernel-reducible, and puts no fuel parameter in any theorem** — which is exactly
what this section claims. *Neither fuel nor `decide_cbv` is forced.*

**It is still a language.** Assignment, sequencing and conditionals over machine
words is a terminating imperative language, and it exercises **all five**
of Slice A's instructions: `ADD` (add), `ADDI` (const, from `x0`), `XOR` (xor),
`SLT` (slt), `BEQ` (ite). Nothing smaller exercises `BEQ`; nothing larger is
needed to say the tower closed.

**Loops are a separately-frozen stretch (`while`, fuel-indexed).** Naming it
here so that "no loops" reads as a decision rather than an omission.

---

## 3. THE COMPILER IS PARTIAL, AND THAT IS FORCED BY THE DATAPATH

Slice A has **no memory** — no loads, no stores (the brief's §2.2, and it calls
the absence a feature). Therefore **there is no spill space**, and therefore the
code generator cannot be total. ~~Three~~ **FIVE** independent sources of
partiality — three below, P4 and P5 found by the refuter passes — all inherited
rather than chosen. *(The count read "three" for the whole of this document's
first life; it is corrected here rather than quietly, because §7's R3 asks
whether the list is complete and a stale count is the first thing a refuter
should be able to trust.)*

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

### P6 and P7 — FOUND BY THE SECOND REFUTER PASS (20:25). ALSO NOT MINE.

⛔ **THE COUNT AGAINST THIS LIST WAS THREE MORE, NOT ZERO. I MARKED R3 "CLOSED"
IN §7 HAVING ABSORBED THE TWO SMALLEST.** The third — the **value domain** — is
in §2.1 and is deliberately **NOT a row here**, because no `Option` can express
it: that is the whole point of §2.1's ruling. The other two:

| # | Source | The bound |
|---|---|---|
| **P6** | **The branch-offset BASE convention** — P4 bounds the offset's *magnitude*; **nothing pinned its ORIGIN** | own-address (brief:248) vs next-instruction differ by exactly one instruction, and §4.1 was written in the undeclared one. See §4.1. |
| **P7** | **P1 and P2 are ONE COUPLED INEQUALITY, not two rows** | the real constraint is `maxVarReg < t0 ∧ t0 + rightDepth(e) ≤ 31` |

🔴 **AND P7's FAILURE MODE IS P5 ARRIVING THROUGH THE ALLOCATOR.** Two checks
that each pass alone — say 20 variables and nesting 15 — **jointly run the temp
index past 31, where it WRAPS in the 5-bit register field and lands on `x0`,
whose write is discarded.** Not a refusal: **a silent no-op.** *The two rows were
presented as independent bounds and they draw on one 31-register pool.*

⚠️ **AND P1's METRIC IS WRONG, at a completeness cost rather than a soundness
one.** Against §4.1's own recursion the high-water mark is **maximum RIGHT-nesting**
— `N(add a b) = max(N a, N b + 1)` — not syntactic depth, so **left-leaning
chains of any length need two registers** and "expression depth" over-rejects.
May stay if stated accurately; it may not stay stated as "depth".

⭐ **AND C2 IS VACUOUS AT `d = 0`.** C2 says *"modifies no register below `d`"*;
at `d = 0` **there is nothing below**, so an allocator that hands out `x0` as a
temporary is invisible to the lemma this document calls *"the proof, and
everything else is bookkeeping."* §3's P5 note records that the `x0`-as-temporary
prediction was wrong in *direction* — **the frame lemma's blind spot at 0 is a
separate fact and is still live.** ⇒ C2 needs `0 < d`, or `t0 > 0` as a
standing invariant of row 9 of §1.1's manifest.

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

⚠️ **AND THE SENTENCE THIS PARAGRAPH NEEDED FROM THE START, because without it
the observation is true of P1-P7 and FALSE of the thing that nearly sank C3.**
The move works **only for failures that are SYNTACTIC properties of `p`** — which
is exactly why `compile` can decide them without seeing the environment. **It
does not cover a failure that is a property of the pair `(p, σ)`.** The value
domain (§2.1) was one of those: `compile` never sees `σ`, so no amount of
checking-and-falling-back could have caught it, and the fix had to be a retype
rather than another `none`. *The philosophy is sound and it has a boundary; the
boundary is where the only correctness kill in two refuter passes came from.*

---

## 4. THE THEOREMS — the deliverables, in dependency order

**C1 — `srcSem` is total.** `srcSem : Stmt → Env → Env`, structurally recursive,
no fuel, no side conditions. *(Env is a total function `Nat → BitVec 32` —
RETYPED per §2.1. It remains a total function per the measured rule from the
leg-2 refuter pass: never an append-extended environment. **That rule was about
the environment's SHAPE and never about its value type**, which is the defence
the frozen `Int` was leaning on and did not have.)*

**C2 — THE EXPRESSION FRAME LEMMA.** `compileExp e d` emits code that leaves
`evalExp e σ` in register `d` and **modifies no register below `d`**, *for
`0 < d`* — see §3's P7 note: **at `d = 0` the lemma is vacuous** and an allocator
handing out `x0` as a temporary is invisible to it.

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
`pc = 0` reaches the end of `code` in a state matching `srcSem p σ`.

⛔ **THE MATCHING RELATION, WRITTEN OUT IN FULL — this is the amendment the
refuter pass demanded and it is the one that matters.** *The relation was named
and never stated for this document's entire first life, and that is precisely how
an `Int`-vs-`BitVec 32` mismatch survived a freeze, a self-review and a
five-check kill-list. **T4 failed the identical way: a theorem whose observation
function was described rather than written.** Describing a relation is how you
avoid discovering it is unsatisfiable.*

```lean
-- With §2.1's retype, this is the IDENTITY on mapped registers. That is the
-- dividend: under `Int` it had to be a coupling relation, and no coupling
-- relation exists (§2.1, witness 2).
def Match (σ : Nat → BitVec 32) (st : St) (V : Finset Nat) : Prop :=
  ∀ x ∈ V, st.regs[reg x]! = σ x

theorem C3 (p : Stmt) (code : List Instr) (σ : Nat → BitVec 32) (st : St)
    (hc : compile p = some code)          -- carries P1-P7 as syntactic checks
    (hm : Match σ st (vars p))            -- ← STATED, not "a state matching"
    (hpc : st.pc = 0) :
    ∃ st', run code st = st' ∧ st'.pc = terminal code
         ∧ Match (srcSem p σ) st' (vars p)
```

⚠️ **THREE REFERENTS IN THAT STATEMENT DO NOT EXIST AND ARE NAMED HERE RATHER
THAN ASSUMED:** `run` (manifest row 7 — **unowned**; `step` consumes ONE
instruction and C3 needs iteration), `reg` and `t0` (row 9 — **never defined**,
and `reg` needs injectivity, `reg x ≠ 0`, `reg x < 32`), and `terminal code`
(row 8 — *`code.length` or `4 * code.length` depending on the pc convention,
which is §4.1's P6 and is why the conclusion is written `terminal code` rather
than either*). **C3 is not writable until §1.1's manifest has owners.**

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
compile (seq s t)    = compile s ++ compile t          -- Option-plumbed; see below
compile (ite c s t)  = compileExp c t0
                    ++ [BEQ t0 x0 (4 * (|S| + 2))]     -- c = 0  -> skip S, land on T
                    ++ S                                -- S = compile s
                    ++ [BEQ x0 x0 (4 * (|T| + 1))]      -- unconditional: skip T
                    ++ T                                -- T = compile t
```

### THE BRANCH-OFFSET CONVENTION, PINNED HERE AND NOWHERE ELSE (P6)

⛔ **THE TWO IMMEDIATES ABOVE WERE `|S| + 1` AND `|T|` AND BOTH WERE SHORT BY
EXACTLY ONE INSTRUCTION.** Under the convention the brief **declares** —
brief:248, *"branch target `pc + sext(imm)`, fall-through `pc + 4`"*, i.e.
relative to the branch's **OWN** address, in **BYTES** — `|S| + 1` landed the
conditional on **the unconditional `BEQ`, not on T**, flatly contradicting this
line's own comment; and `|T|` landed the unconditional on **T's last
instruction**. Traced: the else path executed one instruction of T; the then
path executed S *and then* T's last instruction.

⚠️ **THEY WERE EXACTLY CORRECT UNDER `target = pc + 1 + imm` — next-instruction
relative, counted in INSTRUCTIONS — WHICH NEITHER DOCUMENT DECLARED.** P4's fork
above argues the offset's **RANGE**; **nothing pinned its ORIGIN**, and I closed
R3 on the range with the base sitting underneath it.

⇒ **PINNED: brief:248's convention. Byte displacement from the branch's own
address.** Both immediates are re-derived above and are multiples of 4, so the
implicit-zero-LSB encoding is satisfied. **C3's conclusion is therefore
`pc = 4 * code.length`, which is why C3 above is written `terminal code`.**
*The cheaper option was to declare this document instruction-indexed and keep
the original numbers — but then this freeze's `pc` is not the brief's `pc`, and
C4's composition pays for the mismatch at the seam. **A freeze does not get to
leave the unit of its own branch offsets to the reader.***

🔴 **AND THIS IS WHY IT MATTERED MORE THAN AN ARITHMETIC SLIP: C6 NAMES *"an
off-by-one branch offset"* AS ITS MUTANT, AND THAT IS PRECISELY THE DELTA
BETWEEN THE TWO LIVE CONVENTIONS.** Applying the mutation could not distinguish
*"I detected the mutation"* from *"I corrected the scheme."* **The mutant was the
bug.** See C6 as restated.

📌 **TYPE-LEVEL, and it afflicts the whole block:** `compile : Stmt → Option
(List Instr)`, yet `compile (seq s t) = compile s ++ compile t` appends two
`Option`s and the `ite` case splices `S` and `T` into a `List Instr`. Low
severity on an explicitly pseudocode block — **but every arithmetic claim about
`|S|` and `|T|` above is stated over the `Option`-plumbed version, so that is the
referent, and the real definition must bind through `do`.**

**Both branches are forward**, which is what §2's no-fuel execution model rests
on. ✅ **CONFIRMED BY R4 AND IT IS A REAL RESULT:** every displacement emitted is
non-negative under **all four** candidate conventions (own-address or
next-instruction × bytes or instructions), so the sign — which is what R4 asks —
never depended on P6's ambiguity. ⭐ **And the unconditional jump is `BEQ x0 x0`
— `x0` equals itself always, so the branch is taken unconditionally and NO SIXTH
INSTRUCTION IS NEEDED.** Slice A excludes `JAL`/`JALR`; without this trick `ite`
would not compile and the five-instruction claim would be false. ✅ **R4 confirms
it is load-bearing exactly as claimed** — `x0` reads 0 (brief:110), RV32I has no
delay slot and no condition codes. *(The refuter should still confirm that `step`
AS LANDED evaluates `BEQ x0 x0` as taken rather than special-casing `x0` reads —
that half remains unrunnable until `step` exists.)*

⭐ **TWO NON-FINDINGS, RECORDED SO NOBODY RE-DERIVES THEM.** ① **`P3`'s
`[-2048, 2047]` is exactly right** — `ADDI` sign-extends a 12-bit signed field
and `BitVec.ofInt 32 n = n` for negative `n` in that range; the suspected
sign-extension trap does not exist. ② **Nested `ite` costs NO temporaries** — the
condition in `t0` is dead once the `BEQ` has consumed it, so S and T may reuse
`t0`. **Nested `ite` blows the branch RANGE (P4), not the register budget.**

📐 **ONE NUMERIC CORRECTION TO P4, since this section is where the arithmetic
lives.** B-type encodes `imm[12:1]` ⇒ forward reach 4094 bytes, and a 4-aligned
target caps it at 4092 = **1023 instructions, not ±1024. The reach is
ASYMMETRIC** — backward is 1024. *The ±1024 above is the manual's ±4 KiB rounded
through a four-byte instruction; the encodable maximum is one less going
forward.*

**C5 — CERTIFICATES.** Concrete programs run end to end by `decide +kernel`.
Cost is EVALUATION, not quantification — no input space is enumerated. ⚠️ **THE
COST CLAIM IS RELABELLED: ESTIMATED, ~10-100 ms for a 9-instruction program, AND
THE ESTIMATE CROSSES INSTRUMENTS.** It previously read *"so this is cheap"* with
**neither the MEASURED nor the ESTIMATED label §0.2 makes mandatory** — in a
document whose §0 says every number carries one. The only `Vector`-backed regfile
measurement in this fleet is brief:115 (2,048 cases / 2.4 s ≈ 1.17 ms/case) **and
that row was taken with bare `decide`** — the tactic §6 bans. ***There is no
measured `decide +kernel` regfile number anywhere in this fleet.*** The
*conclusion* is still right, and for a reason worth stating: branches are
forward, so steps ≤ `code.length` and only one path executes — **there is no
branching blow-up.** *(And the gate-layer figure does NOT belong in this price:
C4 composes THEOREMS. Nothing proposes evaluating a program through the netlist.)*

**C6 — A MUTATION CONTROL, non-negotiable.** *The leg-2 refuter pass found
T1/T2/T5 each satisfied by a one-line trivial witness; D4's control was this
morning's real routing bug. **A certificate with no mutation control is not
evidence.*** ⛔ **BUT C6 AS FROZEN WAS ITSELF KILLED (R5, 20:25), ON THREE
GROUNDS, AND IT IS RESTATED HERE:**

1. ⛔ **THE NAMED MUTANT WAS THE BUG.** *"An off-by-one branch offset"* is
   exactly the delta between §4.1's two live conventions (P6), so it could not
   distinguish detection from correction. **P6 is now pinned; only then does a
   branch mutant have a referent.**
2. ⛔ **IT WAS THE WRONG SHAPE, AND THE RIGHT ONE IS ALREADY IN THIS REPO.**
   `Certs.lean:227`'s `xorMutant` is a **COEXISTING definition** carrying a
   permanent `decide +kernel` inequality (`mutation_detected`, audited at
   `Certs.lean:236`); `Banyan.lean:200` does the same by corrupting an INPUT.
   **Neither is "edit a definition and watch the build go red."** C6 proposed
   mutating a definition that *two theorems are proved about* — so it reddens
   **C3's proof** by construction, measuring the **C3 ∪ C5 union** that §7's own
   R5 forbids. *(§7's R5 worried it would break C2 — wrong lemma: C2 is scoped
   to `compileExp`, which emits **no branches at all**. C2 was never at risk.)*
   ⇒ **C6 does not need inventing. It needs copying.**
3. ⛔ **THE CERTIFICATE C5 UNIQUELY OWNS WAS MISSING.** C5's only content beyond
   C3 is that **C3's hypothesis is INHABITED** — the K1 vacuity obligation
   (brief:223-230; the sp1-lean finding in §6). Add
   `example : compile p ≠ none := by decide +kernel`, **labelled honestly as the
   K1 obligation rather than as a mutation control.** *(A first-pass proposal to
   ship `compile := fun _ => none` as a "mutant" was incoherent — it is
   informationally the same statement.)*
4. ⭐ **AND THE CERTIFICATE PROGRAM MUST BE DISCRIMINATING:** then- and
   else-branches writing **DIFFERENT values to the SAME observed register**, so a
   stray instruction cannot be accidentally idempotent. This is the analogue of
   `Certs.lean:222`'s `fungible_is_xor`, which pins a certificate *to a stated
   function rather than merely to agreement*.

---

## 5. WHAT IS DELIBERATELY NOT CLAIMED

- **Not a compiler.** No optimisation, no register allocation worth the name
  (a fixed budget with a `none` on overflow), no calling convention, no linking.
- **Not CompCert.** The source language has three statement forms.
- **No loops, no functions, no memory, no I/O.** P1–P7 are stated exclusions.
- **NOT arbitrary-precision arithmetic.** The source language is over `BitVec 32`
  and **wraps**, exactly as the machine does (§2.1). A reader who assumes
  mathematical integers will assume a stronger theorem than the one proved —
  and that assumption was in this document's own frozen syntax until 20:25.
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

⚠️ **ALL FIVE NOW HAVE A DISPOSITION AND ONLY ONE PASSED.** Two passes ran:
**silicon, 20:05-20:11** (an independent seat with a clean board and no brief
from me — the arrangement §0 requires) and **a 10-agent substituted pass,
20:07-20:25** (5 refuters, each COUNTER-attacked by a hostile re-checker told to
break it). ***The second pass was framed by briefs I wrote, so it is not the
independent review §0 requires — and its one kill landed in the half I had
publicly flagged as the one I was most afraid of, which is the only reason it
was worth running.*** Four of its first-pass claims did not survive the
counter-attack and are listed at the end of this section.

**R1 — IS THE SEAM REAL? ⛔ UNRUNNABLE (a-c) / ✅ RUN AND KILLED (d).** Read the
datapath brief's `step` and instruction datatype **as landed, not as described**.
Does `compile`'s output type match what `step` consumes? — **Unanswerable: 0
referents fleet-wide** (silicon 20:05, re-confirmed 20:25). ⛔ **But (d) killed a
sentence of MINE**: §1's *"the two documents meet at exactly one artifact and
nowhere else"* is **falsified 138 lines later by C4 = C3 ∘ T-EQUIV ∘ `emitN_sem`**,
since T-EQUIV is the brief's. **Struck; replaced by §1.1's 11-row manifest.**
*I wrote three kill-checks against an artifact that does not exist, in a document
whose §4.1 note says "a kill-check whose referent is missing cannot be run."*

**R2 — IS C3 STATEABLE? ✅ RUN 2026-08-06 20:25 — KILLED, AND THIS IS THE ONE
THAT BLOCKS A LINE OF LEAN.** T4 was killed because `sem` exposed only primary
outputs and the theorem could not be written against it. ⛔ **C3 was WORSE than
T4: T4 could not be written; C3 CAN be written and was FALSE.** The source
language was over unbounded `Int`, the machine is `BitVec 32`, and a
23-statement program this document's own `compile` accepts separates them —
**§2.1, with both witnesses and the reason no matching relation repairs it.**
*A false theorem is a harder failure than an unstateable one, because it
survives being written down.* ⇒ **§2 retyped; C3's matching relation now written
out IN FULL, which is what §7 asked for and what the document had never done.**
📌 **AND MY PRE-REGISTERED PREDICTION WAS RIGHT ON THE VERDICT AND WRONG ON THE
MECHANISM:** I named overflowing `+`. **`add` and `xor` survive truncation
intact — it is a homomorphism for both.** The kill is at `slt`. **Had I fixed
this myself, I would have shipped the same false theorem.**

**R3 — ARE P1–P3 THE ONLY PARTIALITY? ✅ RUN 2026-08-06 20:07 BY THE SILICON
SEAT — RETURNED TWO, AND MY PREDICTION WAS WRONG IN DIRECTION.** I predicted a
trap at `x0`-as-a-TEMPORARY. The found ones are **P4 (branch-offset range)** —
which I had not considered at all and which no P1–P3 bound touches — and **P5,
`x0` as a DESTINATION**, which is the same register and the opposite direction.
Both are now in §3. **A refuter that returns the defect you predicted has told
you less than one that returns the defect beside it.**

⛔ **AND "R3 CLOSED" WAS PREMATURE BY THREE — RE-RUN 20:25, AND I HAD CLOSED IT
HAVING ABSORBED THE TWO SMALLEST.** The three: **the value domain** (§2.1 —
deliberately NOT a partiality row, because no `Option` can express it, which is
the whole of its ruling); **P6, the offset BASE convention** (P4 bounded the
offset's magnitude and nothing pinned its origin); and **P7, P1∧P2 being one
coupled inequality** whose joint failure wraps the temp index onto `x0` — *P5
arriving through the allocator.* ⇒ **§3 now lists P1-P7, and the header count of
"three sources" is corrected there.** 📌 ***A check marked CLOSED by the author
of the thing being checked is a check marked closed by the interested party. I
closed R3 forty minutes after silicon opened it, on the two findings I could
absorb in one commit each.***

**R4 — IS THE FORWARD-BRANCH CLAIM TRUE? ✅ RUN 2026-08-06 20:25 —
SURVIVES-AMENDED. THE ONLY CHECK THAT PASSED, AND IT IS A REAL RESULT.** §2
asserts every emitted branch is forward, and the whole no-fuel execution model
rests on it. ✅ **CONFIRMED: every displacement §4.1 emits is non-negative under
ALL FOUR candidate conventions** (own-address or next-instruction × bytes or
instructions), **so the SIGN — which is what R4 asks — never depended on the
ambiguity.** ✅ **And `BEQ x0 x0` is a genuine, load-bearing unconditional jump:**
`x0` reads 0 (brief:110), no delay slot, no condition codes, `JAL`/`JALR`
excluded — without it `ite` does not compile and the five-instruction claim is
false. ⚠️ **AMENDED (P6): both immediates were short by exactly one instruction
against brief:248's declared convention.** Three refuters escalated this to a
kill; they were measuring the offsets' **BASE**, which is an amendment, not the
**SIGN**, which is what R4 asks. **Fixed in §4.1, and the convention is now
pinned in one place.**

**R5 — IS THE MUTATION CONTROL DISCRIMINATING? ✅ RUN 2026-08-06 20:25 — KILLED,
AND THE MUTANT WAS THE BUG.** Per tonight's rule: a mutant must be caught by the
check that owns it AND BY NO OTHER. ⛔ **C6's named mutant — "an off-by-one
branch offset" — is EXACTLY the delta between §4.1's two live conventions, so it
could not distinguish detection from correction.** ⛔ **And under C6's own
wording it is a destructive edit to `compile`, which reddens C3's proof — the
C3 ∪ C5 union this very check forbids.** 📌 **This check's own text worried the
mutant would break "the frame lemma" — WRONG LEMMA: C2 is scoped to
`compileExp`, which emits no branches at all. C2 was never at risk.** *A
kill-check that names the wrong collision is a kill-check with a wrong referent,
which is the same defect R4 had.* ⇒ **C6 restated in §4 on four grounds.**

### WHAT THE SECOND PASS WITHDREW — recorded because a refuter that reports only its hits is running the instrument this document exists to warn about

| withdrawn claim | why it did not survive the counter-attack |
|---|---|
| ***"`step*` is unstateable — T4 all over again"*** — raised **independently by three** refuters | brief:146's *"no memory model"* sits in a list of **ISA FEATURE** exclusions, and brief:302 makes *"a hand-traced 6-instruction program matches by `decide`"* **W2.1's own EXIT TEST** ⇒ iteration is the brief's acceptance gate, not its exclusion. **`run` is unwritten and unowned — that is SCOPE (manifest row 7), not unstateability.** *T4 was unstateable because a LANDED `sem`'s type structurally could not observe what was needed; here nothing is landed to be too narrow, and every refuter that raised the alarm wrote the missing `run` themselves in their own remedy.* |
| ***"T-EQUIV is unowned"*** | brief:304 assigns it to W2.3. Only the `BitVec 32 ↔ List Bool` bus coding is genuinely unassigned — **manifest row 11.** |
| ***"C5 is unrunnable against the declared execution model"*** | `go` structural on a `Nat`, invoked `exec code s := go code.length code s`: **kernel-reducible, and no fuel parameter appears in any theorem.** Neither fuel nor `decide_cbv` is forced. |
| ***"C6's failure mode is a hang, hence unjudgeable"*** | the mutant keeps every offset non-negative, `pc` strictly increases, `Nat` subtraction truncates ⇒ **it goes cleanly RED with a wrong state, not void.** |

⭐ **AND EVERY FIRST-PASS CITATION WAS AGAINST A STALE REVISION** — the refuters
read `38fc8e6` (299 lines) while silicon and I were amending toward `380224d`
(341). **The counter-checkers caught this themselves**, resolved each citation
with `git show 38fc8e6:…`, and re-stated against HEAD; three of them
independently reported that this document had already absorbed findings they
were about to claim. *A pass that cannot say which revision it read cannot be
told apart from a pass that fabricated its line numbers.*

---

## 8. WHAT WOULD MAKE ME ABANDON THIS — stated before the data

1. **`step` is not landed and frozen at start.** Then this is not startable, per
   §1. It waits; it does not begin against a moving target. ⛔ **THIS CRITERION
   IS MET AS OF 2026-08-06 20:07 AND CONFIRMED AT 20:25.** Not merely unlanded —
   **unspecified**: of the eleven objects in §1.1's manifest, **one** has a
   definition anywhere. *This is the criterion firing exactly as pre-registered,
   which is the only thing an abandonment criterion is for.*
1b. **AND A SECOND, INDEPENDENT REASON THE FREEZE DID NOT KNOW ABOUT — added
   20:25.** The frozen source language was over the wrong value domain, and
   building against it would have produced **a false C3** (§2.1). ⚠️ **This is
   the more dangerous of the two, and the asymmetry is the lesson: the missing
   seam STOPS work, so it cannot cost more than the delay. A false theorem does
   not stop anything — it lets the work proceed for a week and fails at the
   end.** *Retyped as of this revision, so this reason is now CLEARED while
   reason 1 remains open.*
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
> that do not fit in the register file, and says so by returning `none`. The
> source language is over 32-bit machine words and wraps — it is not a language
> of mathematical integers, and the theorem does not claim it is."*

*(The second sentence was added at 20:25. Without it the claim in §9 would have
been true of the model and false of the machine — which is the sp1-lean shape
this document cites in §6 and had reproduced in its own frozen syntax.)*
