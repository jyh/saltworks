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
*A test table is a sample.*

⚠️ **AND ONE MORE SAMPLE IS NOT ENOUGH EITHER — math's 18:46 check, folded into §3.** Two
points determine a line with nothing to spare, so a single bad sample would not fail the
test, it would *pass a wrong formula*. **§3 carries THREE points per formula, in this file,
with the code built from the formulas rather than from numbers once computed from them.**

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

/-! ## 3. THE CERTIFICATES — THREE POINTS PER FORMULA, IN ONE FILE, BUILT FROM THE FORMULAS

⚠️ **THIS SECTION WAS REBUILT AFTER MATH'S 18:46 CHECK, WHICH IS CORRECT AND SHARPER THAN
WHAT IT CORRECTED.** My first version carried ONE new sample (`n_s = 1`) and leaned on the
landed `CodegenSpec` certificate (`n_s = 2`) for the second point. Their finding:

> *One sample at `n_s = 1` cannot pin a linear formula — **every** line through `(1,6)`
> survives it (`3n+3`, `4n+2`, `6n` all agree there). The separation is done by the PAIR,
> and two points determine a line with **nothing to spare**. At zero redundancy, one bad
> sample is not a failing test; it is a WRONG FORMULA THAT PASSES.*

⚖️ ***And the part I cannot argue with: I had just refused to accept "the rival is
implausible" from the old certificate, so I do not get to accept it for a quadratic.***
Two repairs, both cheap:

1. **A THIRD POINT PER FORMULA** — `n_s ∈ {1,2,3}` and `n_t ∈ {1,2,3,4}` below. Three
   collinear points kill the one-parameter quadratic family `2n+4 + a(n−1)(n−2)`, **and,
   the part that pays for itself, they make a transcription error in any single point
   VISIBLE — which at two points nothing could do.**
2. **THE POINTS LIVE IN THIS FILE AND THE CODE IS BUILT FROM THE FORMULAS.** Relying on a
   sample in another module made the pair depend on a cross-file citation that can rot, and
   hand-typed immediates are exactly the transcription risk being guarded against.
   `iteOf` calls `iteThenSkip`/`iteElseSkip`, so the certificates test the FORMULAS rather
   than numbers that were once computed from them. -/

/-- The scheme's shape, with the two immediates left FREE — so a mutant differs from the
real thing in nothing but a number. -/
def iteBlock (cond i1 i2 : BitVec 12) (thenB elseB : List Instr) : List Instr :=
  (.ADDI 10 0 cond) :: (.BEQ 10 0 i1) :: (thenB ++ (.BEQ 0 0 i2) :: elseB)

/-- The scheme with the DERIVED immediates. -/
def iteOf (cond : BitVec 12) (thenB elseB : List Instr) : List Instr :=
  iteBlock cond (iteThenSkip thenB.length) (iteElseSkip elseB.length) thenB elseB

/-- A THEN block of `n` instructions whose OBSERVABLE depends on `n` — so a block-length
error changes the answer instead of hiding. -/
def thenBlk (n : Nat) : List Instr :=
  (List.range n).map (fun k => .ADDI 2 0 (BitVec.ofNat 12 (100 + k)))

/-- …and an ELSE block, writing a different register. -/
def elseBlk (n : Nat) : List Instr :=
  (List.range n).map (fun k => .ADDI 3 0 (BitVec.ofNat 12 (200 + k)))

/-- ⭐⭐⭐ **FOUR CONFIGURATIONS, BOTH BRANCHES EACH, ALL KERNEL-EXECUTED.**
`n_s` ranges over `{1,2,3}` and `n_t` over `{1,2,3,4}`, so each formula has **three
distinct points** and the total image length varies too (the `(2,4)` row breaks the
`n_s + n_t = 4` coincidence the first three shared, which would otherwise have made the
`pc` check identical in every row). -/
theorem ite_certificates :
    ([(1,3), (2,2), (3,1), (2,4)] : List (Nat × Nat)).all (fun cfg =>
      let ns := cfg.1
      let nt := cfg.2
      let sT := run (iteOf 1 (thenBlk ns) (elseBlk nt)) St.init
      let sF := run (iteOf 0 (thenBlk ns) (elseBlk nt)) St.init
      (sT.get 2 == BitVec.ofNat 32 (100 + ns - 1)) && (sT.get 3 == 0) &&
      (sF.get 2 == 0) && (sF.get 3 == BitVec.ofNat 32 (200 + nt - 1)) &&
      (sT.pc == BitVec.ofNat 32 (4 * (ns + nt + 3))) &&
      (sF.pc == BitVec.ofNat 32 (4 * (ns + nt + 3)))) = true := by
  decide +kernel

#audit_axioms iteBlock iteOf thenBlk elseBlk
#audit_axioms ite_certificates

/-! ## 4. THE MUTANTS — same shape, ONE number different

*Each rival is `iteBlock` with a wrong immediate, so nothing but the formula varies. Run at
`(n_s, n_t) = (1,3)`, where every rival differs from the derived value.* -/

/-- **RIVAL `imm1 = 2*(n_s+1) = 4`, the frozen off-by-one.** Lands on the unconditional
branch instead of on ELSE: the else-path silently runs the wrong code. -/
theorem offByOne_takes_the_wrong_path :
    ((run (iteBlock 0 4 (iteElseSkip 3) (thenBlk 1) (elseBlk 3)) St.init).get 3
      == BitVec.ofNat 32 202) = false := by decide +kernel

/-- **RIVAL `imm1 = 4*n_s = 4`** — coincides with the off-by-one at `n_s = 1`, which is
itself worth recording: *two distinct wrong formulas can produce the same wrong program at
one sample, so a mutant that fails proves less than it appears to.* -/
theorem rivalA_and_offByOne_coincide_here : (4 : BitVec 12) = 4 := rfl

/-- **RIVAL `imm2 = 3*n_t = 9`.** An ODD immediate: the jump lands misaligned, `fetch`
refuses at a non-multiple-of-four `pc`, and the machine stops where it should not. -/
theorem oddImm_misses_the_end :
    ((run (iteBlock 1 (iteThenSkip 1) 9 (thenBlk 1) (elseBlk 3)) St.init).pc
      == BitVec.ofNat 32 28) = false := by decide +kernel

/-- ⭐⭐ **RIVAL `imm2 = 2*n_t = 6`, the "count the else block" error — AND MATH NAMES THIS
AS THE ONE TO KEEP IF ONLY ONE COULD BE KEPT.** It lands INSIDE the ELSE block, so the
then-path falls through into ELSE's tail: **`x2` is still RIGHT and the program is still
WRONG.**

*A mutant that leaves the observed value correct is the only kind that tests whether the
control observes the right thing at all; the others fail loudly and any check would catch
them.* -/
theorem shortJump_falls_into_the_else_tail :
    let s := run (iteBlock 1 (iteThenSkip 1) 6 (thenBlk 1) (elseBlk 3)) St.init
    (s.get 2 == BitVec.ofNat 32 100, s.get 3 == BitVec.ofNat 32 202) = (true, true) := by
  decide +kernel

#audit_axioms offByOne_takes_the_wrong_path
#audit_axioms rivalA_and_offByOne_coincide_here
#audit_axioms oddImm_misses_the_end
#audit_axioms shortJump_falls_into_the_else_tail

/-! ## 5. THE PASS/FAIL BAR, PRE-REGISTERED

When L2's `ite` clause lands, it passes only if **all** of these hold:

1. its emitted immediates are literally `iteThenSkip n_s` and `iteElseSkip n_t` — *not
   numbers that happen to agree on some sample*;
2. §3's four configurations still pass **against generated code**, not against `iteOf`;
3. the §4 mutants still fail, each in its own recorded way;
4. `iteFits` is checked by the emitter, and an over-long block returns `none` — a
   **fourth** rejection cause, distinct from L0's three and named before it is met;
5. `run`-shaped statements are NOT used for the branching fragment (`BlockCalc` §6:
   `run` has too little fuel for a loop, and Row A must be `Reaches`-shaped).

⛔ **What this file does NOT establish, said plainly: that the formulas are correct for ALL
block sizes.** Three points per formula kill the linear and one-parameter-quadratic rivals
and give the redundancy that makes a bad sample visible — **they are still a discriminating
test, not a proof.** *The proof obligation is a theorem about `bOffset` and `codeAt`, and it
lands with the emitter; this bar makes its failure visible early and does not substitute
for it.* -/

end SaltWorks.IteScheme
