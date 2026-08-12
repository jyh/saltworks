/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.WhileSim

/-!
# COMPREHENSIBILITY CERTIFICATE — the compiler's simulation theorems

Campaign: `docs/cert-layer-design-0811.md` (the fifth deliverable).
Landed by the **COMPILER seat**.

| certificate | proved from | in |
| --- | --- | --- |
| `cert_compileE_value` | `run_compileE_eq_evalE` | `HDL/CompileE.lean` |
| `cert_compileS_simulation` | `run_compileS_correct_of_branchFree` | `HDL/CompileS.lean` |
| `cert_compileS_simulation_with_loops` | `reaches_of_compileS_including_while` | `HDL/WhileSim.lean` |
| `cert_the_fragment_boundary` | `cause_outside_the_fragment_is_now_ite_only` | `HDL/CompileS.lean` |
| `cert_branchFree_does_not_imply_compiles` | `branchFree_is_necessary_not_sufficient` | `HDL/CompileS.lean` |
| `cert_pool_exhaustion_is_a_real_limit` | `cause_pool_exhaustion_at_letmut` | `HDL/CompileS.lean` |
| `cert_the_fragment_exceeds_branch_free` | `fragment_now_includes_while` | `HDL/CompileS.lean` |

## ⭐ THE ONE MOVE THIS FILE MAKES: `encodeOK` IS UNFOLDED INTO THE STATEMENTS

The landed theorems are stated through a defined predicate:

```
encodeOK Γ reg σ st  ≡  ∀ i : Fin poolSize, i.val < Γ.length → st.get (reg i) = σ i.val
```

**Every certificate below writes that quantifier out in full instead of naming it.**
That is the whole comprehensibility gain and it is not cosmetic: the name `encodeOK`
reads like *"the machine state encodes the source state"*, and the definition says
something strictly smaller — **it constrains REGISTERS and says nothing whatever
about `mem` or about the trap flag**, both of which `St` also carries.

```
⛔ FALSE plain reading   "the compiled code computes what the source program says"
✅ HONEST plain reading  "for every variable the source has IN SCOPE, the register
                         the compiler assigned to it ends up holding that
                         variable's value"
```

*A reader who takes the false reading has been told the compiler is correct about
memory. Nothing here says that.* **With the predicate unfolded in the statement, the
scope is visible to anyone who reads the theorem, and no docstring has to be trusted
to convey it.** *That the unfolded statements close by `exact` is the proof the
unfolding is definitional rather than merely plausible.*

## ⚠️ WHAT THE REGISTERS-ONLY SCOPE DOES AND DOES NOT COST

For the code `compileS` actually emits, ignoring `mem` and the trap flag is **safe**,
and the reason is a fact about the emitter rather than an argument:

```
THE EMITTER'S CLOSURE is exactly two files — `CompileS.lean` imports ONLY
`CompileE.lean`, and the offset constants live at the emitter rather than in the
scheme files (forced by an import cycle, which is why `WhileScheme`/`IteScheme`
are CONSUMERS of the emitter and not part of it).

THE EMITTED SET over that closure (measured 2026-08-11):
    CompileE   ADDI · ADD · XOR · SLT
    CompileS   ADDI · BEQ
  ⇒          { ADDI, ADD, XOR, SLT, BEQ }     — no load, no store, no trap op.
```

**Not one of those five arms can reach memory or set the trap flag**, so the two
fields `encodeOK` declines to mention are fields this compiler's output never moves.

⚠️ *The corpus also carries a landed pair of frame theorems proving exactly that for
these arms. **This certificate deliberately does not cite them by name**: as of
2026-08-11 they were being re-cut under the M2 node (helm ruling, 16:48) from an
unconditional form into a `touchesMem`-conditional one **under new names**, so the
names available when this file was written were about to become residue and the
incoming ones could not yet be resolved.* **The emitted-set fact above is stated
instead because it is a property of the emitter and cannot be renamed out from under
this docstring.**

## ⚠️ SCOPE LIMITS carried from the landed theorems — nothing here is wider

* **`cert_compileS_simulation` is the BRANCH-FREE fragment**, and that is a limit of
  the statement's SHAPE, not a technicality: `run`'s fuel is one tick per instruction,
  so a loop cannot be expressed in it *even in principle*
  (`run_has_too_little_fuel_for_a_loop` is the landed proof of that).
* **`cert_compileS_simulation_with_loops` is the shape that carries loops** — it says
  a reachable state exists, not that a fixed number of ticks suffices.
* **The compiler is PARTIAL and this is not a defect of the proofs**: it refuses real
  programs, and §5 EXHIBITS the refusals rather than describing them —
  **a conditional does not compile** (`cert_the_fragment_boundary`), **an oversized
  constant does not compile even though it is branch-free**
  (`cert_branchFree_does_not_imply_compiles`), and **the register pool runs out at
  level 15** (`cert_pool_exhaustion_is_a_real_limit`). *A conditional is the only
  source CONSTRUCT outside the fragment; the other two are limits that bite inside it.*
* **There is no whole-compiler theorem** — no `compile_correct` / `compile_total`
  anywhere in the corpus. These are per-construct simulation results, and a reader
  should not compose them in their head into a claim nobody has proved.
* **Typing is a hypothesis** (`chkS Γ p = true`) and is load-bearing: `slotOf` is
  total and answers `0` on an unbound name, so an ill-typed `var` would read a slot
  the context never granted.

## DIRECTION (iron rule 3)

**Every certificate here is the SAME PROPOSITION as its landed theorem** — the only
change is that defined predicates (`encodeOK`, `RegsHold`, `PoolBelow`, `Reaches`) are
written out as the quantifiers they abbreviate. Each closes by `exact`, which is
exactly the evidence that nothing was traded: a definitional unfolding that did not
hold would not typecheck.

## AXIOMS (iron rule 4)

Measured at the landing of this file, quoted from the `#print axioms` block below:

```
cert_compileE_value                     [propext, Classical.choice, Quot.sound]
cert_compileS_simulation                [propext, Classical.choice, Quot.sound]
cert_compileS_simulation_with_loops     [propext, Classical.choice, Quot.sound]
cert_the_fragment_boundary              [propext, Quot.sound]
cert_branchFree_does_not_imply_compiles [propext, Quot.sound]
cert_pool_exhaustion_is_a_real_limit    [propext, Quot.sound]
cert_the_fragment_exceeds_branch_free   [propext, Quot.sound]
```

No `sorryAx`, no corpus-local axiom.

## ⭐ THIS FILE IS ALSO A MEASUREMENT OF `M2`'s BLAST RADIUS

Every certificate here closes by `exact <landed compiler theorem>`. **So if the `M2`
node (`acd3982`, which grew `Instr` with `LW`/`SW` and re-cut four statement-level
layers) had altered any of the landed statements this file cites, the corresponding
`exact` would have failed to typecheck.** None did: the four simulation rows were
written before `M2` landed and needed **zero** edits after it, and the three §5
refusal rows — added after — went green against the post-`M2` corpus on first build.

*That is a kernel-checked statement about `M2`'s reach into the compiler's simulation
layer — obtained without a single grep, on a day when six census greps across four
seats all turned out to have domain bugs.* **It is also the cert layer's own
maintenance property doing its job: a certificate's Lean half self-sweeps on any
restatement, because the `exact` is what breaks.**
-/

namespace SaltWorks.Certs

open SaltWorks.ISA
open SaltWorks.StraightLine
open SaltWorks.RegMap
open SaltWorks.HDL.TinyRustN0
open SaltWorks.CompileE
open SaltWorks.CompileS
open SaltWorks.BlockCalc
open SaltWorks.WhileSim

/-! ## 1. EXPRESSIONS — the value ends up in the destination register -/

/-- **L0, in plain quantifiers.** Compile an expression, run the emitted program from
`pc = 0`, and the destination register holds the value the expression denotes.

The two hypotheses that were named predicates are written out: *every pool register
holds its source variable's value to begin with* (`RegsHold`), and *the whole pool
sits strictly below the scratch register* (`PoolBelow`).

⚠️ `4 * c.length < 2 ^ 32` is the one hypothesis `compileE` does **not** check —
carried, not assumed away. Direction: **same proposition**, closed by `exact`.

Witness: **EXEMPT** — universal, no witness. -/
theorem cert_compileE_value (Γ : Ctx) (reg : RegMap) (σ : State) (e : Exp) (d : Nat)
    (c : List Instr) (st : St) (rd : Fin 32)
    (hc : compileE Γ reg e d = some c) (hrd : regAt d = some rd)
    (hst : ∀ i : Fin poolSize, st.get (reg i) = σ i.val)
    (hpb : ∀ i : Fin poolSize, (reg i).val < d)
    (hpc : st.pc = 0) (hb : 4 * c.length < 2 ^ 32) :
    (run c st).get rd = evalE Γ σ e :=
  run_compileE_eq_evalE Γ reg σ e d c st rd hc hrd hst hpb hpc hb

/-! ## 2. STATEMENTS, WITHOUT LOOPS — every in-scope variable lands in its register -/

/-- ⭐⭐ **L1, WITH `encodeOK` WRITTEN OUT.** Take a branch-free statement that the
source semantics runs from `σ` to `σ'`. Compile it, start the machine at `pc = 0` in
any state whose registers already hold `σ`'s in-scope variables, run it — and **every
in-scope variable's register now holds its value in `σ'`**.

Read the two quantified lines: they mention `st.get (reg i)` and nothing else. **This
statement says nothing about memory and nothing about the trap flag.**

Direction: **same proposition** as `run_compileS_correct_of_branchFree`, closed by
`exact`.

Witness: **EXEMPT** — universal, no witness. *The `hbf`/`hchk` binder is inhabited non-degenerately by the programs `cert_the_fragment_boundary` compiles.* -/
theorem cert_compileS_simulation {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {Γ : Ctx} {p : Stmt} {σ σ' : State} (hbs : bigStep Γ p σ σ')
    (hbf : branchFree p = true) (hchk : chkS Γ p = true)
    (c : List Instr) (st : St) (hc : compileS reg d Γ p = some c)
    (henc : ∀ i : Fin poolSize, i.val < Γ.length → st.get (reg i) = σ i.val)
    (hpc : st.pc = 0) (hb : 4 * c.length < 2 ^ 32) :
    ∀ i : Fin poolSize, i.val < Γ.length → (run c st).get (reg i) = σ' i.val :=
  run_compileS_correct_of_branchFree hreg hbs hbf hchk c st hc henc hpc hb

/-! ## 3. STATEMENTS **WITH LOOPS** — the shape that can express a loop at all -/

/-- ⭐⭐⭐ **L2, WITH BOTH `encodeOK` AND `Reaches` WRITTEN OUT.** The same claim for
a statement that may contain `while`, and placed at an arbitrary offset `q` inside a
larger program image rather than at `pc = 0`.

The conclusion says: **there is a machine state `st'` that the image reaches in some
number `n` of steps**, whose registers hold `σ'` on every in-scope variable, and whose
`pc` sits exactly past the compiled block.

⚠️ **`∃ n` IS THE POINT, NOT A WEAKNESS.** `run`'s one-tick-per-instruction fuel
cannot express a loop; naming the number of steps existentially is what makes the
statement expressible at all. *This is a different SHAPE from §2, not a weaker version
of it.*

Direction: **same proposition** as `reaches_of_compileS_including_while`, closed by
`exact`.

Witness: **EXEMPT** — universal in its hypotheses. *The `∃ st'` is the CONCLUSION, not a control: this cert proves an existence claim, it does not offer a witness ABOUT itself. `cert_the_fragment_boundary` exhibits a `while` program that compiles, which is what inhabits `hc` here.* -/
theorem cert_compileS_simulation_with_loops {reg : RegMap} {d : Nat} (hreg : RegOk reg d)
    {Γ : Ctx} {p : Stmt} {σ σ' : State} (hbs : bigStep Γ p σ σ') (hchk : chkS Γ p = true)
    {image blk : List Instr} {q : Nat} {st : St}
    (hc : compileS reg d Γ p = some blk) (hat : codeAt image q blk)
    (henc : ∀ i : Fin poolSize, i.val < Γ.length → st.get (reg i) = σ i.val)
    (hpc : st.pc.toNat = 4 * q) (hb : 4 * (q + blk.length) < 2 ^ 32) :
    ∃ st' : St, (∃ n : Nat, runFor n image st = st') ∧
      (∀ i : Fin poolSize, i.val < Γ.length → st'.get (reg i) = σ' i.val) ∧
      st'.pc.toNat = 4 * (q + blk.length) :=
  reaches_of_compileS_including_while hreg hbs hchk hc hat henc hpc hb

/-! ## 4. THE BOUNDARY — what this compiler REFUSES, exhibited rather than described -/

/-- ⛔ **THE FRAGMENT BOUNDARY, AS A CERTIFICATE.** Three concrete programs over the
same context, decided by the kernel:

1. a **sequence** of assignments compiles;
2. a **conditional** does **not** — `compileS` returns `none`;
3. a **loop** compiles.

*So "the compiler is verified" is a claim about a fragment WITH loops and WITHOUT
conditionals, and this theorem is where a reader can see that without taking anyone's
word for it.* **A certificate layer that only ever restates what was proved would
leave the most important fact about this compiler — that it refuses half of control
flow — visible nowhere.**

Direction: **same proposition** as `cause_outside_the_fragment_is_now_ite_only`.

Witness: **NON-DEGENERACY** — three programs over the SAME context and register map. ⚠️ ***CORRECTED 10:36: my first version said they differ "only in the construct". THEY DO NOT — the `.while` body is `.skip` where the `.ite` then-branch is `.assign`, so the programs differ in more than one property, which is the very thing that sentence claimed to rule out.*** *The attribution survives on a DIFFERENT and checkable argument, which is the one that should have been written: **every component of the refused `.ite` appears inside a program that COMPILES** — its condition `(.slt (.var 0) (.const 5))` is the `.while`'s condition, and its branch `(.assign 0 (.const 5))` is the `.seq`'s body. So the refusal cannot be blamed on the condition or on the branch; only the construct is left. **Holding the context and register map fixed is necessary and was never sufficient.*** -/
theorem cert_the_fragment_boundary :
    (compileS regCanonical 16 [(0, Ty.i32)]
        (.seq (.assign 0 (.const 5)) .skip)).isSome = true
  ∧ compileS regCanonical 16 [(0, Ty.i32)]
      (.ite (.slt (.var 0) (.const 5)) (.assign 0 (.const 5)) .skip) = none
  ∧ (compileS regCanonical 16 [(0, Ty.i32)]
      (.while (.slt (.var 0) (.const 5)) .skip)).isSome = true :=
  cause_outside_the_fragment_is_now_ite_only

/-! ## 5. WHAT ELSE IT REFUSES — the other rejection causes, kernel-exhibited

*Added at the evidence seat's 18:14 observation on the executive row: **every other
certificate in this campaign proves that a claim HOLDS; a certificate over a landed
NEGATIVE CONTROL proves that a hypothesis is LOAD-BEARING.** "A theorem tells a
referee the claim is true; a refutation of the hypothesis-free version tells them the
claim is not vacuous." The corpus has more of these than the cert layer was reaching
for; these three were landed and unreached.* -/

/-- ⛔ **BEING BRANCH-FREE IS NOT ENOUGH TO COMPILE.** A perfectly ordinary
straight-line assignment — `x := 99999` — is `branchFree`, and `compileS` **refuses
it**, because the constant does not fit the machine's immediate field.

*So `branchFree` is a NECESSARY condition in the L1 theorems and not a sufficient one:
a reader must not conclude from "the branch-free fragment is verified" that every
branch-free program compiles.* Direction: **same proposition** as
`branchFree_is_necessary_not_sufficient`.

Witness: **NON-DEGENERACY** — the literal `99999` is chosen to exceed the immediate field. *A small constant would compile, satisfy both conjuncts trivially in the wrong direction, and witness nothing; the witness only separates the two notions because the value is out of range.* -/
theorem cert_branchFree_does_not_imply_compiles :
    branchFree (.assign 0 (.const 99999)) = true
  ∧ compileS regCanonical 16 [(0, Ty.i32)] (.assign 0 (.const 99999)) = none :=
  branchFree_is_necessary_not_sufficient

/-- ⛔ **THE REGISTER POOL IS A REAL LIMIT, AT THE STATEMENT LEVEL.** Level 14 has a
register; level 15 does not. Sixteen nested bindings need a sixteenth cell, `lvlReg`
refuses, and therefore so does `compileS`.

*A "verified compiler" that silently spilled to memory here would be a different
program; this one declines.* Direction: **same proposition** as
`cause_pool_exhaustion_at_letmut`.

Witness: **NON-DEGENERACY** — the pair `14`/`15` straddles the boundary. *Any two levels both inside or both outside the pool would be degenerate: the content is that the limit falls BETWEEN these two, so adjacency is load-bearing.* -/
theorem cert_pool_exhaustion_is_a_real_limit :
    (lvlReg regCanonical 14).isSome = true ∧ lvlReg regCanonical 15 = none :=
  cause_pool_exhaustion_at_letmut

/-- ⭐ **AND THE FRAGMENT IS STRICTLY LARGER THAN THE BRANCH-FREE ONE — the witness
that the two notions have PARTED.** A loop compiles, and a loop is not `branchFree`.

*This matters for reading §2 against §3: the L1 certificates are scoped to `branchFree`
statements, but the compiler's domain is bigger than that scope. **The two are no
longer the same set, and this is the program that separates them.*** Direction: **same
proposition** as `fragment_now_includes_while`.

Witness: **NON-DEGENERACY** — a `while` program that compiles AND is not branch-free. *A branch-free program would satisfy the first conjunct and refute nothing; the witness must sit in the gap between the two notions or it is not a witness.* -/
theorem cert_the_fragment_exceeds_branch_free :
    (compileS regCanonical 16 [(0, Ty.i32)]
       (.while (.slt (.var 0) (.const 5)) .skip)).isSome = true
  ∧ branchFree (.while (.slt (.var 0) (.const 5)) .skip) = false :=
  fragment_now_includes_while

#audit_axioms cert_branchFree_does_not_imply_compiles
#audit_axioms cert_pool_exhaustion_is_a_real_limit
#audit_axioms cert_the_fragment_exceeds_branch_free

#audit_axioms cert_compileE_value
#audit_axioms cert_compileS_simulation
#audit_axioms cert_compileS_simulation_with_loops
#audit_axioms cert_the_fragment_boundary

#print axioms cert_compileE_value
#print axioms cert_compileS_simulation
#print axioms cert_compileS_simulation_with_loops
#print axioms cert_the_fragment_boundary

end SaltWorks.Certs
