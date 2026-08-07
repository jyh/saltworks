/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA

/-!
# The source language, and C3 — STATED against an ISA that exists

`docs/hdl-codegen-freeze-v1.md` has carried a theorem called C3 all evening. It
has been written three times and every version was against `step` **as a
description**, because `step` did not exist. The second refuter pass killed the
last one: the source language was over unbounded `Int` while the machine is
`BitVec 32`, so C3 was not unstateable — it was **stateable and FALSE**.

This file is the fourth version and the first against `SaltWorks.ISA` as landed.

## What this file is for, and what it deliberately is not

**It states C3. It does not prove it, and it does not assert it.** `C3Statement`
below is a `Prop`-valued *definition* parameterised over the code generator,
which does not exist yet. Nothing here is a `theorem` about `compile`; there is
no `sorry` and no axiom, and **the fact that this file elaborates is the whole
result** — that is precisely the test T4 failed, where a theorem could not be
written against the declared semantics at all.

*Writing the statement is how you find out it is unsatisfiable. Describing it is
how you avoid finding out. This file exists because I did the second thing three
times.*

## What changed, and what is still missing

Of the three referents the freeze flagged as absent when C3 was last written:

* `run` — **LANDED** (`ISA.run`), so the machine side of C3 is real;
* the pc convention — **PINNED**, so `terminal code` is now writable as
  `4 * code.length` rather than left as a name;
* `reg` and `t0` — **still absent**, but they are the CODE GENERATOR's, i.e.
  mine. ⇒ **C3 is no longer blocked on another seat's missing artifact.** It is
  blocked on a file I have not written, which is a different and much better
  kind of blocked.

## The certificates at the bottom are the load-bearing part tonight

§4.1's compilation scheme had **both** branch offsets wrong by exactly one
instruction, and C6's proposed mutation control was that very off-by-one — so
the scheme has never actually been executed. The two `decide +kernel`
certificates below hand-compile a real `ite` by §4.1's corrected scheme and run
it on the landed machine, **once down each branch**. They are the first
execution of that scheme in this campaign, and they are what would have caught
the bug had they existed this afternoon.

⚠️ **AND THEY IMMEDIATELY CAUGHT ONE OF MINE, WHICH IS THE BEST ARGUMENT FOR
THEM.** My first hand-compilation wrote `ADD x2, x0, x20` where it meant
`ADD x2, x0, x10` — the else-branch reading a register that is never written.
**The then-branch certificate passed anyway**, because that instruction is on
the path it does not execute. ⇒ ***A certificate covers the path it runs and no
other.*** That is "certify at PARTIAL LOAD" arriving one level down from where
this campaign minted it: a test suite that exercises one branch of an `ite` is
the full-load certificate all over again, and **the only reason the bug surfaced
is that I wrote the second certificate.**
-/

namespace SaltWorks.Codegen

open SaltWorks.ISA

/-! ## The source language — §2 of the freeze, at the machine's value domain -/

/-- Expressions over 32-bit machine words. **`BitVec 32`, not `Int`** — see the
freeze's §2.1: the `Int` version made C3 false, and truncation cannot be
repaired by any matching relation because `slt` is an *observation* rather than
an operation on the carrier. -/
inductive Exp where
  | var   (x : Nat)
  | const (n : BitVec 32)
  | add   (a b : Exp)
  | xor   (a b : Exp)
  | slt   (a b : Exp)
  deriving DecidableEq

/-- Three statement forms. **No `while`** — the freeze's largest scoping
decision, and it is what makes `srcSem` structural and the machine bound
`code.length`. -/
inductive Stmt where
  | assign (x : Nat) (e : Exp)
  | seq    (s t : Stmt)
  | ite    (c : Exp) (thn els : Stmt)
  deriving DecidableEq

/-- The source environment: a **total function**, never an append-extended list
(the leg-2 refuter pass measured 2.0× on that choice), and now at `BitVec 32`. -/
abbrev Env := Nat → BitVec 32

/-- Expression meaning. Every operation is the machine's, so the coupling
relation in C3 can be the identity. -/
def evalExp (σ : Env) : Exp → BitVec 32
  | .var x   => σ x
  | .const n => n
  | .add a b => evalExp σ a + evalExp σ b
  | .xor a b => evalExp σ a ^^^ evalExp σ b
  | .slt a b => if (evalExp σ a).slt (evalExp σ b) then 1 else 0

/-- Pointwise update — no append. -/
def upd (σ : Env) (x : Nat) (v : BitVec 32) : Env := fun y => if y = x then v else σ y

/-- **C1 — `srcSem` is total.** Structurally recursive, no fuel, no side
conditions. The `ite` follows the machine's convention: a zero condition takes
the ELSE branch, because §4.1 emits `BEQ t0 x0` to skip the then-branch. -/
def srcSem : Stmt → Env → Env
  | .assign x e, σ => upd σ x (evalExp σ e)
  | .seq s t,    σ => srcSem t (srcSem s σ)
  | .ite c s t,  σ => if evalExp σ c = 0 then srcSem t σ else srcSem s σ

/-- The variables a statement touches — C3 quantifies its matching relation over
exactly these, and no others. -/
def varsE : Exp → List Nat
  | .var x   => [x]
  | .const _ => []
  | .add a b => varsE a ++ varsE b
  | .xor a b => varsE a ++ varsE b
  | .slt a b => varsE a ++ varsE b

def vars : Stmt → List Nat
  | .assign x e => x :: varsE e
  | .seq s t    => vars s ++ vars t
  | .ite c s t  => varsE c ++ (vars s ++ vars t)

/-! ## C3, stated

Parameterised over the two objects that do not exist yet. **Nothing below
asserts that a `compile` with these properties exists** — that is the point. -/

section Statement

variable (reg : Nat → Fin 32) (compile : Stmt → Option (List Instr))

/-- **THE MATCHING RELATION, WRITTEN OUT.** Its absence for this document's
entire first life is exactly how an `Int`-vs-`BitVec 32` mismatch survived a
freeze, a self-review and a five-check kill-list.

With the retype it is the **identity** on mapped registers — under `Int` it had
to be a coupling relation, and the refuter pass showed no coupling relation
exists. Note it reads through `St.get`, so `x0` reads zero here exactly as it
does in the machine. -/
def Match (σ : Env) (st : St) (V : List Nat) : Prop :=
  ∀ x ∈ V, st.get (reg x) = σ x

/-- **C3 — THE SIMULATION THEOREM, AS A STATEMENT.**

Every referent resolves: `Instr`, `St`, `run` and the terminal `pc` are landed
Lean; `srcSem`, `Match` and `vars` are above. The two hypotheses that are not
yet definable — `compile` and `reg` — are section variables rather than
assumptions, so this file claims nothing about them.

The conclusion's `pc` is `4 * code.length` **in bytes**, per the convention
pinned in §4.1 and made executable in `ISA.fetch`. That number was `code.length`
in the previous draft, which was the instruction-indexed reading — one of the
two live conventions whose difference was the freeze's own mutation control. -/
def C3Statement : Prop :=
  ∀ (p : Stmt) (code : List Instr) (σ : Env) (st : St),
    compile p = some code →
    Match reg σ st (vars p) →
    st.pc = 0 →
    Match reg (srcSem p σ) (run code st) (vars p)
      ∧ (run code st).pc = BitVec.ofNat 32 (4 * code.length)

/-- **The obligations `reg` owes**, which the freeze's manifest row 9 listed and
no document ever stated. Written here so the code generator inherits them rather
than rediscovering them: **`reg x ≠ x0`** is silicon's P5 (an assignment to `x0`
is a silent no-op), and injectivity is what makes distinct source variables
distinct registers. -/
def RegOk (t0 : Fin 32) : Prop :=
  Function.Injective reg ∧ (∀ x, reg x ≠ 0) ∧ (∀ x, reg x < t0)

end Statement

/-! ## Certificates — §4.1's `ite` scheme, HAND-COMPILED AND EXECUTED

The scheme with the *corrected* offsets, run once down each branch. Source:

```
p = ite (slt (var 0) (const 5)) (assign 1 (const 10)) (assign 1 (const 20))
```

with `reg x = x + 1` and `t0 = x10`. Compiling by §4.1:

```
 0  ADD  x10 x0 x1        compileExp (var 0)   t0
 1  ADDI x11 x0 5         compileExp (const 5) (t0+1)
 2  SLT  x10 x10 x11      the condition, in t0
 3  BEQ  x10 x0 8         c = 0 -> skip S. 4*(|S|+2) = 16 bytes; imm = 16/2 = 8
 4  ADDI x10 x0 10        S = compile (assign 1 (const 10))
 5  ADD  x2  x0 x10
 6  BEQ  x0  x0 6         unconditional. 4*(|T|+1) = 12 bytes; imm = 12/2 = 6
 7  ADDI x10 x0 20        T = compile (assign 1 (const 20))
 8  ADD  x2  x0 x10
```

⚠️ **THE OFFSETS ARE THE POINT.** The frozen scheme emitted `|S| + 1 = 3` and
`|T| = 2` — instruction counts relative to the *next* instruction. Under the
pinned convention those land on the unconditional `BEQ` and on `T`'s last
instruction respectively, and **the `ite` silently executes the wrong code**.
These two certificates fail if that regression is ever reintroduced, which is
the mutation control C6 asked for and could not express. -/

/-- The then-branch: `x1 = 0`, so `0 <ₛ 5` and the conditional `BEQ` is NOT
taken. Falls into S, then the unconditional jump must clear T entirely. -/
theorem ite_scheme_then_branch :
    let code : List Instr :=
      [.ADD 10 0 1, .ADDI 11 0 5, .SLT 10 10 11, .BEQ 10 0 8,
       .ADDI 10 0 10, .ADD 2 0 10, .BEQ 0 0 6,
       .ADDI 10 0 20, .ADD 2 0 10]
    let s := run code St.init
    s.get 2 = 10 ∧ s.pc = 36 := by
  decide +kernel

/-- The else-branch: a prelude sets `x1 = 7`, so `7 <ₛ 5` is false, the
conditional `BEQ` IS taken, and it must land on `T` — not on the unconditional
`BEQ` one instruction earlier, which is where the frozen offset pointed.

**The branch immediates are unchanged from the certificate above**, which is the
whole virtue of pc-relative offsets: prepending an instruction shifts every
address and no displacement. -/
theorem ite_scheme_else_branch :
    let code : List Instr :=
      [.ADDI 1 0 7,
       .ADD 10 0 1, .ADDI 11 0 5, .SLT 10 10 11, .BEQ 10 0 8,
       .ADDI 10 0 10, .ADD 2 0 10, .BEQ 0 0 6,
       .ADDI 10 0 20, .ADD 2 0 10]
    let s := run code St.init
    s.get 2 = 20 ∧ s.pc = 40 := by
  decide +kernel

/-- **AND THE MUTATION CONTROL, in the `Certs.lean:227` shape the refuter pass
demanded: a COEXISTING broken definition carrying a permanent `decide +kernel`
inequality, never a destructive edit to a definition a theorem is proved about.**

`badCode` is the same program with the frozen off-by-one offsets (`|S| + 1 = 3`
and `|T| = 2`) sitting in the immediate field.

⭐ **AND WHAT IT ACTUALLY DOES IS WORSE AND SHARPER THAN "the wrong value",
which I only know because I measured it instead of asserting it.** The frozen
immediate `3` denotes `3 * 2 = 6` bytes, so the branch lands at `16 + 6 = 22`
— **not a multiple of 4.** `ISA.fetch` refuses a misaligned `pc`, `runFor`
stops, and the program **halts in the middle having written nothing at all**:
`x2 = 0`, `pc = 22`. *A wrong answer is a bug; a machine that stops on an
unfetchable address is the datapath catching the bug for you, and the two are
worth telling apart.* -/
theorem frozen_offsets_halt_the_machine_misaligned :
    let badCode : List Instr :=
      [.ADDI 1 0 7,
       .ADD 10 0 1, .ADDI 11 0 5, .SLT 10 10 11, .BEQ 10 0 3,
       .ADDI 10 0 10, .ADD 2 0 10, .BEQ 0 0 2,
       .ADDI 10 0 20, .ADD 2 0 10]
    let s := run badCode St.init
    s.pc = 22 ∧ s.pc.toNat % 4 ≠ 0 ∧ s.get 2 = 0 := by
  decide +kernel

/-- **Non-vacuity of the source semantics**, so `srcSem` is not satisfied by a
function that ignores its program: the same source statement the certificates
compile, evaluated directly, gives the values they produce. -/
theorem srcSem_agrees_with_the_certificates :
    let p : Stmt := .ite (.slt (.var 0) (.const 5))
                         (.assign 1 (.const 10)) (.assign 1 (.const 20))
    srcSem p (fun _ => 0) 1 = 10 ∧ srcSem p (upd (fun _ => 0) 0 7) 1 = 20 := by
  decide +kernel

/-! ## Axiom audit -/

#audit_axioms evalExp
#audit_axioms upd
#audit_axioms srcSem
#audit_axioms varsE
#audit_axioms vars
#audit_axioms Match
#audit_axioms C3Statement
#audit_axioms RegOk
#audit_axioms ite_scheme_then_branch
#audit_axioms ite_scheme_else_branch
#audit_axioms frozen_offsets_halt_the_machine_misaligned
#audit_axioms srcSem_agrees_with_the_certificates

end SaltWorks.Codegen
