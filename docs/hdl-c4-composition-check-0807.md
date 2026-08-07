# C4 — COMPOSITION CHECK (seat: compiler/compiler-acct)

### 2026-08-07. Ordered by the maestro; ordered by C4's own text.
### Campaign freeze v1 §C4: *"The EXACT statement is C1+C3's first joint
### artifact and must be COMPOSITION-CHECKED (a `Scratch` elaboration of the
### statement's type, no proof) before either freezes."*

**VERDICT: C4 IS STATEABLE. It elaborates — in `emitN_sem`'s own observation
shape — as soon as four absent functions are posited. One seam does NOT close,
and it is a decision the freeze has not made rather than a defect in it.**

Method is silicon's F2 (C0 doctrine): every probe carries a control, because *a
file that merely fails to build is not evidence*. No `sorry`, no
`native_decide` — `#check` elaborates a `Prop` without proving it.

---

## §0 CONTROL — the landed seam, printed rather than assumed

```
emitN_sem : ∀ (c : Circ), c.ssa = true → ∀ (ins : Env),
   List.map (fun n => (Silicon.runP ins [] (emitN c)).getD n false) c.outs = sem c ins
sem       : Circ → Env → List Bool
Silicon.runP : (ℕ → Bool) → List Bool → Silicon.Netlist → List Bool
ISA.step  : ISA.St → ISA.Instr → ISA.St
ISA.stepW : ISA.St → BitVec 32 → Option ISA.St
```

All five elaborate. Everything below is therefore evidence.

---

## §1 WHAT C4 NAMES AND THE TREE DOES NOT CONTAIN

```
compile        0 declarations        <- silicon's F1 (8/6) STILL STANDS
core           0 declarations
"the Q-leaves' decoding"    Env → ISA.St          — named in prose, absent
"the state encoding"        ISA.St → List Bool    — named in prose, absent
```

*A grep for `toBits`/`ofBits`/`encodeSt`/`decodeSt` over `SaltWorks/` returns
**zero**.* The two coercions C4's sentence turns on have no referent at all —
**and unlike `compile`, they are not on any manifest as owed.**

---

## §2 THE PROBES

```lean
variable {Src : Type} (compile : Src → Circ) (core : Src)
variable (decQ : SaltWorks.HDL.Env → SaltWorks.ISA.St)     -- Q-leaves' decoding
variable (encD : SaltWorks.ISA.St → List Bool)             -- state encoding
variable (instrOf : SaltWorks.HDL.Env → SaltWorks.ISA.Instr)

-- PROBE 1 — the Circ level, the form C4 says the obligation reduces to
#check (∀ ins : SaltWorks.HDL.Env,
          sem (compile core) ins
            = encD (SaltWorks.ISA.step (decQ ins) (instrOf ins)) : Prop)

-- PROBE 2 — the netlist level, in emitN_sem's own observation shape
#check (∀ ins : SaltWorks.HDL.Env,
          (compile core).outs.map
            (fun n => (SaltWorks.Silicon.runP ins [] (emitN (compile core))).getD n false)
            = encD (SaltWorks.ISA.step (decQ ins) (instrOf ins)) : Prop)

-- PROBE 3 — the partiality seam
variable (wordOf : SaltWorks.HDL.Env → BitVec 32)
#check (∀ ins : SaltWorks.HDL.Env,
          sem (compile core) ins
            = encD (SaltWorks.ISA.stepW (decQ ins) (wordOf ins)) : Prop)
```

**PROBE 1 ✅ ELABORATES.** **PROBE 2 ✅ ELABORATES.**

⇒ ***C4's composition closes at the type level.*** *That is the positive result
and it is worth stating first: v0's headline did not typecheck at all
(silicon's F2); v1's does, once its named-but-absent pieces are given types.*

---

## §3 ⛔ THE SEAM THAT DOES NOT CLOSE — PROBE 3, MEASURED

```
error: Application type mismatch: The argument
  ISA.stepW (decQ ins) (wordOf ins)
has type
  Option ISA.St
but is expected to have type
  ISA.St
```

**A netlist's observation is `List Bool` — TOTAL. `stepW` is `Option St` —
PARTIAL.** They do not compose, and no encoding can make them: there is no
`List Bool` that means "this word did not decode".

⚠️ **PROBE 1 CLOSES ONLY BECAUSE `instrOf : Env → Instr` HANDS `step` AN
ALREADY-DECODED INSTRUCTION.** That is not a neutral modelling choice — it
quietly places the decoder **outside** the verified boundary, or assumes
undecodable words never reach it.

🔴 **AND THAT ASSUMPTION IS FALSE BY CONSTRUCTION FOR SLICE A.** Slice A defines
five instructions and *excludes everything else* — no loads, stores, `LUI`,
`AUIPC`, `JAL`, shifts, `M`, CSRs. **Undecodable words are not an edge case;
they are the overwhelming majority of the 2^32 word space.** `decode` returning
`none` is the landed, deliberate behaviour (`decode_rejects_lui`).

**⇒ C4 MUST CHOOSE, AND THE FREEZE HAS NOT:**
1. a **total** step-on-words with explicit behaviour for undecodable words
   (trap? no-op? hold?) — *this is a specification decision, not a proof
   detail*; or
2. a **hypothesis** restricting inputs to decodable words — which then has to be
   discharged by whatever drives the fetch path, and that obligation must be
   written down; or
3. the decoder **inside** the boundary with the `Option` handled — the honest
   shape, and the most expensive.

*Silicon's 8/6 note anticipated the same class from the hardware side:
"RV32I will bring resettable flops… I would rather it be on the C-list now than
discovered at C4."*

---

## §4 TWO NAMING HAZARDS, both instances of the F3 law's own subject

F3 made fully-qualified identifiers mandatory in freezes, naming three ambiguous
ones: `step`, `run`, `runS`. **There are at least two more, and both sit inside
C4's sentence.**

```
Env       SaltWorks.HDL.Env       := Net → Bool          (Sem.lean:32)
          SaltWorks.Codegen.Env   := Nat → BitVec 32     (CodegenSpec.lean:94)
          ^ bits vs WORDS — and C4's composition runs through both layers

compile   campaign freeze v1 C4:  `compile core : Circ`
          codegen freeze v1 §4:   `compile : Stmt → Option (List Instr)`
          ^ TWO LIVE FREEZES, same bare name, unrelated types
```

📌 **AND THE DOCUMENT NAMES COLLIDE TOO:** `docs/riscv-core-campaign-v0.md` is
titled *"campaign freeze v1"* while `docs/hdl-codegen-freeze-v1.md` is a
different freeze **also at v1, also with a theorem numbered C4** (there, *"the
tower, composed"*). *"C4 against freeze v1" is ambiguous between two documents
until one of them is renamed.* **The campaign file's NAME still says `v0` while
its title says v1**, which is the cheapest half of the fix.

---

## §5 ONE HYPOTHESIS C4 INHERITS AND DOES NOT CARRY

`emitN_sem` carries **`c.ssa = true`**. C4 composes with it by name and
`grep -i ssa` over the campaign freeze returns **no mention**. A non-SSA circuit
makes `emitN_sem` inapplicable, so the hypothesis is load-bearing, not
bookkeeping. *`emitPipeline'_sem` discharges it for `normalize (opt c)`, so the
route exists — but C4 must say which it composes.* **Raised 8/6; still open.**

---

## §6 WHAT WOULD MAKE C4 WRITABLE — the shortest list

```
1. compile, core                     types fixed by PROBE 1/2 (Src → Circ)
2. decQ : Env → ISA.St               the Q-leaf decoding
3. encD : ISA.St → List Bool         the state encoding
4. a RULING on partiality            §3 — specification, not proof
5. the ssa hypothesis, named         §5
6. fully-qualified Env and compile   §4
```

*Items 1–3 are construction. Item 4 is the only one that cannot be delegated to
whoever writes the code, and it is the one a proof attempt would discover last.*

---

# ADDENDUM — C4's PARTIALITY FORK, PRICED (same day, ~11:10)

The maestro's 10:50 post makes **C4/C5 a gate before any CPU tapeout**. §3 above
left a fork that *"cannot be delegated to whoever writes the code"* — so here it
is costed, so the ruling can rest on measurement rather than on preference.

## All three options ELABORATE — the fork is not a type problem

Same method: control, then one probe per option, `#check` only.

```
OPTION 1  total step-on-words     sem (compile core) ins = encD (stepT (decQ ins) (wordOf ins))
                                  ✅ elaborates
OPTION 2  guarded statement       (decode (wordOf ins)).isSome = true → ∃ s', …
                                  ✅ elaborates
OPTION 3  decoder inside          sem (compile core) ins = encO (stepW (decQ ins) (wordOf ins))
                                  ✅ elaborates   (encO : Option St → List Bool)
```

⇒ ***Lean will accept any of the three. Nothing here decides itself, which is
precisely why it needs a ruling and not an implementation.***

## What each one OWES — the part that is not free

**OPTION 1 owes a COMPATIBILITY obligation**, and without it `stepT` is a
different ISA wearing the same name:

```lean
∀ s w s', SaltWorks.ISA.stepW s w = some s' → stepT s w = s'      -- ✅ elaborates
```

*A total `stepT` that quietly disagreed with `stepW` on a decodable word would
make C4 true and the ISA claim false.* **This obligation is cheap to state and
must not be skipped.**

**OPTION 2 owes the discharge of its guard — and the guard is far stronger than
it looks.** How much of the word space does `decode` actually accept?

```
KERNEL-CHECKED   the funct3 = 0 plane (128 funct7 × 128 opcodes = 16384 words):
                 planeCount = 257  =  1 (ADD, funct7 must be 0)
                                   + 128 (ADDI, funct7 bits are immediate)
                                   + 128 (BEQ,  likewise)
                 `plane_is_257 : planeCount = 257 := by decide +kernel`, EXIT=0
```

That confirms the acceptance-set model, from which the whole-space figure
follows by arithmetic (**arithmetic, not kernel-checked — labelled as such**):

```
ADD + XOR + SLT   3 × 2^15  =     98,304     (rd, rs1, rs2 free; funct7 pinned)
ADDI + BEQ        2 × 2^22  =  8,388,608     (12 immediate bits free)
                  total     =  8,486,912  of  2^32  =  0.1976 %
```

⇒ **`(decode w).isSome` excludes 99.80 % of the word space.** *That is not a
side condition; it is nearly the whole input domain.* **Whoever drives the fetch
path owes that discharge, and the freeze must name them.**

⚠️ **AND A SAMPLING ERROR I MADE AND CAUGHT, because it would have overstated
the case by 2.5×.** My first measurement counted decodable words among the
**first 2^16** — `320 / 65536 = 0.488 %`. **That slice is not representative:
its words have bits 31:16 = 0, which pins `funct7 = 0` and so over-selects the
R-type forms.** *The honest figure is 0.1976 %, and the biased one was the
convenient direction — it made the guard look four times weaker than it is.*

**OPTION 3 owes a validity bit in the netlist** — `encO : Option St → List Bool`
means the hardware must *emit* "this word did not decode". Honest, and the only
one of the three where the netlist's totality and `stepW`'s partiality are
reconciled **in the artifact** rather than in the statement.

## The recommendation this seat would make if asked

**Option 1 with the compatibility obligation**, on one ground: it is the only
choice that keeps the netlist total *and* pins the disagreement to a written
theorem. Option 2 relocates the problem to a hypothesis 99.8 % of words fail;
option 3 is correct but pays for it in gates on every instruction.

⛔ **But this is a recommendation, not a ruling — it changes what the ISA
*means* on 99.8 % of its input space, and that is the council's to decide.**

---

# ADDENDUM 2 — §5 RESOLVED: C4 SHOULD COMPOSE WITH `emitPipeline'_sem`, NOT `emitN_sem`

§5 left an open item: *"C4 composes with `emitN_sem` by name and must say which
of `emitN` / `emitPipeline'` it composes."* **It is determinate, and the freeze
names the wrong one.** Both routes elaborate; the difference is what C4 must
then carry and what it is talking about.

```
ROUTE A   emitN_sem          hypothesis:  (compile core).ssa = true
                             observes:    emitN (compile core)          <- UNOPTIMISED
ROUTE B   emitPipeline'_sem  hypothesis:  (compile core).wf  = true
                             observes:    emitPipeline' (compile core)  <- opt + normalize
```

**THREE REASONS ROUTE B, and the second is the one that actually matters:**

1. **The hypothesis is strictly weaker.** `wf` is well-formedness, which any
   compiler output has by construction; `ssa` is dense-SSA form, a real
   obligation on `compile`'s output shape. **And nobody owes `ssa` on route B:
   it is discharged internally — `emitPipeline'_sem`'s proof goes through
   `normalize_ssa (opt_wf c h)`.** *So the hypothesis C4 was inheriting simply
   evaporates.*

2. ⭐ **ROUTE A TALKS ABOUT AN ARTIFACT THAT IS NOT FABRICATED.**
   `emitN (compile core)` is the **unoptimised** emission. The thing that goes
   through the flow is `emitPipeline' = emitN ∘ normalize ∘ opt`. ***A C4 proved
   on route A would be a true theorem about a netlist nobody tapes out*** — the
   same genre of error as measuring the wrong object, one level up.

3. `opt_sem` and `normalize_sem` are already landed and already inside
   `emitPipeline'_sem`'s proof, so route B costs nothing to adopt.

## What route B costs — stated, because it is not free

**The observation is at the NORMALISED port list**, `(normalize (opt (compile
core))).outs`, not `(compile core).outs`. So **`encD` must be indexed against
the normalised outs.** *The pipeline law's own docstring already rules the
positional form — "the two agree positionally, output `k` for output `k`, which
is the form the refuter pass ruled the seam must use" — so this is a stated
convention to honour, not a new problem.*

## ⇒ The freeze edit, in one line

> *…composed with `emitPipeline'_sem` (landed), whose hypothesis is
> `(compile core).wf = true`; the SSA condition is discharged internally and is
> **not** C4's to carry. The observation is at `(normalize (opt (compile
> core))).outs`.*

**§5 closes. Item 5 of §6's list is struck.**
