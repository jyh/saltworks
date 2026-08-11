import SaltWorks.HDL.BlockCalc

/-! # THE `ite` OFFSET SCHEME — PRE-REGISTERED, before any emitter produces these numbers

L2's branch cases are not written. **This file publishes the offset formulas, the checks,
and the pass/fail bar first**, per the house law that a criterion published before the work
sometimes fixes the work. It emits nothing and changes no `compileS` clause.

## Why this is not already covered by the landed certificate

`CodegenSpec.lean:190-230` kernel-executes the scheme down both branches and pins the byte
convention. ⚠️ **But its sample has `n_then = n_else = 2`, and a single sample at equal
block sizes does NOT discriminate between the right formula and at least two wrong ones:**

```
              at n = 2      general
  imm1        8             2*(n_s+2)   ← derived here
  rival A     8             4*n_s
  imm2        6             2*(n_t+1)   ← derived here
  rival B     6             3*n_t
```
*A test table is a sample. §3's certificates use `n_c = 1`, `n_s = 1`, `n_t = 3`, where
every rival above gives a different number — so a pass separates them and a mutant fails.*

## The layout, for a block starting at index 0

```
 0 .. n_c-1            condition code, result in t0
 n_c                   BEQ t0 x0 (iteThenSkip n_s)    taken when the condition is FALSE
 n_c+1 .. n_c+n_s      THEN block
 n_c+n_s+1             BEQ x0 x0 (iteElseSkip n_t)    unconditional, clears the ELSE block
 n_c+n_s+2 .. +n_t     ELSE block
 n_c+n_s+n_t+2         end
```
`bOffset imm = sext(imm) <<< 1`, measured **from the branch's own address** — so a
displacement is *half* the byte distance, and both formulas are position-independent
(they mention only block LENGTHS). That is what lets `compileS` stay free of a position
parameter, and it is the property `BlockCalc`'s `codeAt` is built to exploit.
-/

open SaltWorks.ISA

namespace SaltWorks.IteScheme

/-! ## 1. The formulas -/

/-- The conditional branch's immediate: skip the THEN block **and** the unconditional
branch that follows it, landing on ELSE. -/
def iteThenSkip (n_s : Nat) : BitVec 12 := BitVec.ofNat 12 (2 * (n_s + 2))

/-- The unconditional branch's immediate: skip the ELSE block, landing past it. -/
def iteElseSkip (n_t : Nat) : BitVec 12 := BitVec.ofNat 12 (2 * (n_t + 1))

/-! ## 2. ⛔ THE REPRESENTABILITY BOUND — A REJECTION CAUSE L2 INHERITS AND L1 DOES NOT

`imm` is a **12-bit SIGNED** field, so a forward displacement is capped at `2047`, i.e.
`4094` bytes, i.e. **1023 instructions**. ⇒ *A `then` or `else` block longer than about a
thousand instructions cannot be branched over.*

🔑 ***This is L0's cause (1) — "the immediate does not fit" — reappearing at the statement
level, and it is NOT the same thing as L0's version: L0's bound is on USER DATA (a `const`
the programmer wrote), this one is on GENERATED CODE SIZE. A program with no large
constants at all can still hit it.*** *Pre-registered here so that when `compileS` grows an
`ite` clause, the `none` it must return for an over-long block is a KNOWN cause rather than
a surprise found by a refuter.*

⚠️ **And it interacts with the candidate third cause priced at L0**: both are bounds on
emitted code length, but they bind at wildly different sizes (2^30 instructions for the
`pc` wrap, ~10^3 for a branch displacement). **The branch bound binds first by six orders
of magnitude**, so it is the one an implementer will actually meet. -/
def iteFits (n_s n_t : Nat) : Bool := 2 * (n_s + 2) ≤ 2047 && 2 * (n_t + 1) ≤ 2047

theorem iteFits_binds : iteFits 1021 1022 = true ∧ iteFits 1022 1022 = false := by
  refine ⟨by decide, by decide⟩

/-- …and the bound is REAL rather than notional: at the first rejected size the immediate
`BitVec.ofNat 12` produces has WRAPPED to a negative displacement — a forward branch that
jumps backwards. *This is why the guard is a `≤ 2047` on the Nat and not a check on the
`BitVec`, which would be checking the symptom.* -/
theorem iteThenSkip_wraps_past_the_bound :
    ((iteThenSkip 1022).signExtend 32 == BitVec.ofNat 32 2048) = false
  ∧ (iteThenSkip 1022).msb = true := by
  refine ⟨by decide, by decide⟩

#audit_axioms iteThenSkip iteElseSkip iteFits
#audit_axioms iteFits_binds
#audit_axioms iteThenSkip_wraps_past_the_bound

/-! ## 3. THE DISCRIMINATING CERTIFICATES — `n_c = 1`, `n_s = 1`, `n_t = 3` -/

/-- Instruction 0 sets the condition; every other instruction is shared between the two
runs, so the ONLY difference between the branches is the condition's value. -/
def iteCode (cond : BitVec 12) : List Instr :=
  [ .ADDI 10 0 cond,                 -- 0  condition into t0
    .BEQ 10 0 (iteThenSkip 1),       -- 1  FALSE -> jump to ELSE at index 4
    .ADDI 2 0 111,                   -- 2  THEN block, n_s = 1
    .BEQ 0 0 (iteElseSkip 3),        -- 3  unconditional -> index 7
    .ADDI 2 0 222,                   -- 4  ELSE block, n_t = 3
    .ADDI 3 0 1,                     -- 5
    .ADDI 4 0 2 ]                    -- 6

/-- ⭐ **CONDITION TRUE: the conditional branch is NOT taken, THEN runs, and the
unconditional branch clears the ELSE block ENTIRELY** — `x3` and `x4` untouched. -/
theorem ite_then_branch :
    let s := run (iteCode 1) St.init
    (s.get 2, s.get 3, s.get 4, s.pc) = (111, 0, 0, 28) := by
  decide +kernel

/-- ⭐ **CONDITION FALSE: the conditional branch IS taken and lands on ELSE** — not on the
unconditional branch one instruction earlier, which is where the frozen offset pointed. -/
theorem ite_else_branch :
    let s := run (iteCode 0) St.init
    (s.get 2, s.get 3, s.get 4, s.pc) = (222, 1, 2, 28) := by
  decide +kernel

/-! ## 4. THE MUTANTS — coexisting broken schemes, each failing in its OWN way

*Three distinct wrong formulas producing three distinct failures. A single mutant would
leave "the certificate passes" consistent with several rivals.* -/

/-- **RIVAL: `imm1 = 2*(n_s+1)`, the frozen off-by-one.** Lands on the unconditional branch
instead of on ELSE, so the else-path silently executes the wrong code. -/
def iteCode_offByOne : List Instr :=
  [ .ADDI 10 0 0, .BEQ 10 0 4, .ADDI 2 0 111, .BEQ 0 0 (iteElseSkip 3),
    .ADDI 2 0 222, .ADDI 3 0 1, .ADDI 4 0 2 ]

theorem offByOne_takes_the_wrong_path :
    ((run iteCode_offByOne St.init).get 2 == 222) = false := by decide +kernel

/-- **RIVAL: `imm2 = 3*n_t = 9`.** An ODD immediate, so the jump lands misaligned, `fetch`
refuses at a non-multiple-of-four `pc`, and the machine stops somewhere it should not.
*A different failure mode from the off-by-one, and worth separating.* -/
def iteCode_oddImm : List Instr :=
  [ .ADDI 10 0 1, .BEQ 10 0 (iteThenSkip 1), .ADDI 2 0 111, .BEQ 0 0 9,
    .ADDI 2 0 222, .ADDI 3 0 1, .ADDI 4 0 2 ]

theorem oddImm_misses_the_end :
    ((run iteCode_oddImm St.init).pc == 28) = false := by decide +kernel

/-- **RIVAL: `imm2 = 2*n_t`, the plausible "count the else block" error.** Lands INSIDE
the ELSE block instead of past it, so the then-path falls through into ELSE's tail — the
answer for `x2` is still right and the program is still wrong. -/
def iteCode_shortJump : List Instr :=
  [ .ADDI 10 0 1, .BEQ 10 0 (iteThenSkip 1), .ADDI 2 0 111, .BEQ 0 0 6,
    .ADDI 2 0 222, .ADDI 3 0 1, .ADDI 4 0 2 ]

theorem shortJump_falls_into_the_else_tail :
    let s := run iteCode_shortJump St.init
    (s.get 2 == 111, s.get 4 == 2) = (true, true) := by decide +kernel

#audit_axioms iteCode
#audit_axioms ite_then_branch ite_else_branch
#audit_axioms iteCode_offByOne offByOne_takes_the_wrong_path
#audit_axioms iteCode_oddImm oddImm_misses_the_end
#audit_axioms iteCode_shortJump shortJump_falls_into_the_else_tail

/-! ## 5. THE PASS/FAIL BAR, PRE-REGISTERED

When L2's `ite` clause lands, it passes only if **all** of these hold:

1. its emitted immediates are literally `iteThenSkip n_s` and `iteElseSkip n_t` — *not
   numbers that happen to agree on some sample*;
2. §3's two certificates still pass **against generated code**, not hand-written code;
3. the three §4 mutants still FAIL, and each still fails in its own recorded way;
4. `iteFits` is checked by the emitter, and an over-long block returns `none` — a
   **fourth** rejection cause, distinct from L0's three and named before it is met;
5. `run`-shaped statements are NOT used for the branching fragment (`BlockCalc` §6:
   `run` has too little fuel for a loop, and Row A must be `Reaches`-shaped).

⛔ **What this file does NOT establish, said plainly: that the formulas are correct for ALL
block sizes.** Two kernel-executed samples and three mutants are a *discriminating* test,
not a proof. **The proof obligation is a theorem about `bOffset` and `codeAt`, and it lands
with the emitter — this bar is what makes that theorem's failure visible early, not a
substitute for it.** -/

end SaltWorks.IteScheme
