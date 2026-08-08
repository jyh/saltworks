/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.Compose

/-!
# The ALU output select and the flag reduction — obligations ③ and ⑤

Emitter obligations ③ *(name each op result before an output select)* and ⑤
*(emit wide reductions as trees with named levels)* from the silicon seat's
survey. They live together because both are the ALU's tail and both are the same
lever the barrel shifter turned out to need: **tree it, and name the levels.**

## The numbers to beat, and where they come from

| block | silicon, treated | mechanism |
|---|---:|---|
| ALU op select, one-hot | 20 | 10 op results + 10 select lines |
| ALU op select, encoded | 14 | 10 op results + 4 select bits |
| `zero` flag, one operand | 8 | group size 8 |
| branch comparator, two operands | 16 | 8 positions × **2 operands** |

⚠️ **The seat's own ×2 rule is obeyed here and is worth restating, because it is
the one that surprised them: a TWO-operand reduction is twice as wide as a
one-operand one.** The per-bit combining row is not itself a cut, so each group
cone reaches through it to *both* operands. **`zero` reduces one 32-bit result
and is cheap; `rs1 == rs2` reduces two and is not.**

## What this file does differently, and why

The seat's `20` and `14` are the cone of the select **when the op results are the
cut and the mux is left flat**. ⇒ **Treeing the select and naming its levels
takes it to 3**, exactly as the log shifter took the shift from 11 to 3 — a
2:1 mux has two sources and one select bit and nothing can be smaller.

The select is padded from 10 op results to 16 with a shared constant, so the tree
is a clean four-level binary one. **The padding costs one gate and is invisible
to the cone**, because the pad leaf is a `const` rather than an input.

## What is NOT claimed

**No theorem says this selects the right op, or that the reduction computes
`zero`.** As in `Adder.lean`, `ReadTree.lean` and `Shifter.lean`, the functional
obligation belongs to the code generator's correctness argument. *These files
establish cone shape and cell count; a construction with the right shape and the
wrong function passes every check in them.*
-/

namespace SaltWorks.HDL

/-! ## ③ The op-result select -/

def asW : Nat := 32
/-- Ten op results: add, sub, and, or, xor, slt, sltu, sll, srl, sra. -/
def asOps : Nat := 10
/-- Padded to a power of two so the tree is clean. -/
def asPad : Nat := 16
/-- Encoded select, four bits — the seat's measured saving over a one-hot ten. -/
def asSelBits : Nat := 4

/-! ## THE RULED PAIR — phase 1 of the expand-contract, landed BESIDE the old

Muster ruling ① sizes the select at `(n = 3, b = 2)`.  These are the NEW
constants the migration states against; `asOps`/`asSelBits`/`asPad` above are the
OLD ones and are deliberately untouched until phase 3.  Transitional prefix `rs`
("ruled select"), recorded on the bus.

⚠️ **State phase-2 work against THESE NAMES, never against bare `3`/`2`.**  The
whole point of the migration is to escape numeral-bound theorems — a new theorem
written as `gsSelOf 3 2` is one more of exactly the thing being escaped, and it
is how `genSelect_ten : genSelect 10 4 = aluSelect` became expensive. -/

/-- Ruled source count. -/
def rsOps : Nat := 3
/-- Ruled select width. -/
def rsSelBits : Nat := 2
/-- Ruled pad — MUST track the width; the guard below is what forces it. -/
def rsPad : Nat := 4

/-- The pad tracks the width.  Separate definitions with nothing forcing them to
agree is how a re-cut silently desynchronises geometry from select width. -/
theorem rsPad_eq_two_pow : rsPad = 2 ^ rsSelBits := by decide +kernel

/-- Every ruled source is addressable: `n ≤ 2^b`.  An inadmissible re-pairing
fails `decide` here and BREAKS THE BUILD, which is the mechanism rider 3 asked
for.  Do not "fix" a failure of this by weakening the guard. -/
theorem rsPair_admissible : rsOps ≤ 2 ^ rsSelBits := by decide +kernel

/-- …and the ruled pair is the one the muster ruled. -/
theorem rsPair_is_the_ruled_pair : rsOps = 3 ∧ rsSelBits = 2 := by decide +kernel

#audit_axioms rsPad_eq_two_pow
#audit_axioms rsPair_admissible
#audit_axioms rsPair_is_the_ruled_pair

/-- Op result `r` bit `k` occupies net `r * 32 + k`; the four select bits follow. -/
def asIn : Nat := asOps * asW + asSelBits
def asRes (r k : Nat) : Net := r * asW + k
def asSel (j : Nat) : Net := asOps * asW + j

/-- The shared constant that pads 10 results to 16 leaves. One gate for the whole
file, and **invisible to every cone** because it is a `const` and not an input. -/
def asZero : Net := asIn
/-- One inverter per select bit, shared by every mux at that level. -/
def asNot (j : Nat) : Net := asIn + 1 + j

/-- Level `j` of bit `k`'s tree has `16 / 2^(j+1)` muxes. -/
def asLevelWidth (j : Nat) : Nat := asPad / 2 ^ (j + 1)
/-- Muxes below level `j`, per bit: 8 + 4 + 2 + 1. -/
def asBelow : Nat → Nat
  | 0 => 0
  | j + 1 => asBelow j + asLevelWidth j
/-- Every bit's tree is 15 muxes; three gates each. -/
def asBase (k j i : Nat) : Nat :=
  asIn + 1 + asSelBits + (k * (asPad - 1) + asBelow j + i) * 3
/-- **The named output of level `j`, position `i`, for bit `k`.** -/
def asOut (k j i : Nat) : Net := asBase k j i + 2

/-- What level `j` reads: level 0 reads the op results (padding with the shared
constant above index 9), later levels read the level below. -/
def asPrev (k j i : Nat) : Net :=
  if j == 0 then (if i ≥ asOps then asZero else asRes i k)
  else asOut k (j - 1) i

/-- One mux: `sel[j] ? prev[2i+1] : prev[2i]`. -/
def asMux (k j i : Nat) : List Gate :=
  [⟨asBase k j i,     .and (asPrev k j (2 * i))     (asNot j)⟩,
   ⟨asBase k j i + 1, .and (asPrev k j (2 * i + 1)) (asSel j)⟩,
   ⟨asOut k j i,      .or (asBase k j i) (asBase k j i + 1)⟩]

/-- **The ALU output select**: 32 bits, each a four-level tree over 16 padded
sources. -/
def aluSelect : Circ :=
  { nIn := asIn
    gates :=
      (⟨asZero, .const false⟩ : Gate)
        :: (List.range asSelBits).map (fun j => (⟨asNot j, .not (asSel j)⟩ : Gate))
        ++ (List.range asW).flatMap fun k =>
             (List.range asSelBits).flatMap fun j =>
               (List.range (asLevelWidth j)).flatMap (asMux k j)
    outs := (List.range asW).map fun k => asOut k (asSelBits - 1) 0 }

/-- The cut set: **every level of every bit's tree**. -/
def aluSelectCuts : List Net :=
  (List.range asW).flatMap fun k =>
    (List.range asSelBits).flatMap fun j =>
      (List.range (asLevelWidth j)).map (asOut k j)

/-! ## ⑤ The flag reduction — `zero`

A 32-input AND-reduction as a **binary tree with every level named**, rather than
the seat's group-of-eight. A binary node has two sources and no select, so a
named level costs **2** where a group of eight costs 8. -/

def zrIn : Nat := asW
def zrLevels : Nat := 5
def zrLevelWidth (j : Nat) : Nat := asW / 2 ^ (j + 1)
def zrBelow : Nat → Nat
  | 0 => 0
  | j + 1 => zrBelow j + zrLevelWidth j
/-- 31 nodes, one gate each. -/
def zrOut (j i : Nat) : Net := zrIn + zrBelow j + i
def zrPrev (j i : Nat) : Net := if j == 0 then i else zrOut (j - 1) i

/-- **`zero` as a named binary tree.** `nor` of the whole word would need a
different basis; this reduces with `or` and the generator negates at the end. -/
def zeroTree : Circ :=
  { nIn := zrIn
    gates :=
      (List.range zrLevels).flatMap fun j =>
        (List.range (zrLevelWidth j)).map fun i =>
          (⟨zrOut j i, .or (zrPrev j (2 * i)) (zrPrev j (2 * i + 1))⟩ : Gate)
    outs := [zrOut (zrLevels - 1) 0] }

def zeroTreeCuts : List Net :=
  (List.range zrLevels).flatMap fun j => (List.range (zrLevelWidth j)).map (zrOut j)

/-! ## The measurements -/

/-- Same instrument as `Adder.lean` and `Shifter.lean`. ⚠️ **A root in its own
cut set reports only itself** — exclude the measured boundary from the cut. -/
partial def asCone (c : Circ) (cut : List Net) (n : Net) : List Net :=
  let rec go (fuel : Nat) (seen : List Net) (todo : List Net) : List Net :=
    match fuel, todo with
    | 0, _ => seen
    | _, [] => seen
    | f + 1, x :: rest =>
        if seen.contains x then go f seen rest
        else if x < c.nIn || cut.contains x then go f (x :: seen) rest
        else match c.gates.find? (fun g => g.out == x) with
          | some g => go f seen (g.op.fanin ++ rest)
          | none   => go f seen rest
  go 200000 [] [n]

-- ③ UNCUT: 10 op results + 4 select bits = 14, the seat's ENCODED figure.
#eval (asCone aluSelect [] (asOut 0 (asSelBits - 1) 0)).length

-- ③ CUT AT EVERY LEVEL: a 2:1 mux is 2 sources + 1 select.  MEASURED: max 3.
#eval ((List.range asW).flatMap fun k =>
        (List.range asSelBits).flatMap fun j =>
          (List.range (asLevelWidth j)).map fun i =>
            (asCone aluSelect (aluSelectCuts.filter (· != asOut k j i)) (asOut k j i)).length
      ).foldl Nat.max 0

-- ⑤ UNCUT: the reduction reaches the whole word = 32.
#eval (asCone zeroTree [] (zrOut (zrLevels - 1) 0)).length

-- ⑤ CUT AT EVERY LEVEL: a binary node has two sources and no select.  MEASURED: 2.
#eval ((List.range zrLevels).flatMap fun j =>
        (List.range (zrLevelWidth j)).map fun i =>
          (asCone zeroTree (zeroTreeCuts.filter (· != zrOut j i)) (zrOut j i)).length
      ).foldl Nat.max 0

-- Cells: the select is 32 bits x 15 muxes; the reduction is 31 nodes.
#eval (aluSelect.gates.length, muxCount aluSelect, zeroTree.gates.length)


/-! ## Instantiability — the precondition for C4's assembly

*`instOK` requires `ssa`, not merely `wf`: under `wf` alone a circuit may have
sparse gate outputs and `instNext` under-reports the region it occupies
(`Compose.instNext_under_reports_without_ssa`). So `ssa` is what makes this organ
safe to embed in `core`, and `wf` then follows for free.* -/

theorem aluSelect_ssa : aluSelect.ssa = true := by decide +kernel

/-- **`wf` by the structural route** (1,445 gates). -/
theorem aluSelect_wf : aluSelect.wf = true := Circ.wf_of_ssa aluSelect_ssa


/-! ## ⭐⭐ THE SOURCE COUNT, PARAMETRISED — `genSelect n b`

**`aluSelect` IS `genSelect asOps asSelBits`** (`genSelect_eq_aluSelect`, math's
parametric hinge, below).

⚠️ *This line read "`aluSelect` IS `genSelect 10 4` (`genSelect_ten`, below)" until
phase 3 retired the ladder. Left alone it would have named a deleted theorem AND
asserted a literal pair the constants no longer hold — a docstring that survives a
re-cut while its content does not.*

*The block above is written at one width, and the semantics theorem
(`sem_aluSelect`, math's `Stack/Program.lean`) was written at that width too —
`329 + 45*k + 42`, `pfr (320 + j)`, `< 324`, and level 3 baked into the lemma
names (`asV3_eq`, `asB3`, `asOut k 3 0`). So every theorem proved against
`asIn = 324` was another line in a future rewrite, and the sizing question became
a **DEADLINE rather than a trade** (silicon, `79bb72a`).*

⇒ **The deadline was a property of one proof having been written at a literal
width, not of the decision.** `genSelect n b` is the same construction at `n`
sources and `b` encoded select bits; `sem_genSelect` (math) proves it selects,
unconditionally, at every `n`. ⚠️ **The landed `aluSelect` is NOT redefined** —
it is *recovered*, so nothing that consumes it moves.

## The shape

A balanced mux tree over `2^b` leaves per output bit, with an **encoded** select
(`b` bits, not `2^b` one-hot lines — the choice that cut the uncut cone from 20
to 14), and the padding leaves above `n` sharing one `const false`. Cost is a
step function on the doubling: a source costs nothing until it crosses a power
of two.

⚠️ **ONE GATE MORE THAN THE SIZING TABLE AT EXACT POWERS OF TWO — AND THE 97 IS
NOT AN ERROR.** That formula carries `+ [n < pad]`: the pad constant, charged
only when there IS padding. `genSelect` emits it unconditionally, so at `n = 2^b`
it is a **dead net** — `genSelect 2 1` is **98** gates, and `n = 8` would be 676.
Measured in the kernel (`genSelect_two_gate_count`), not derived. `n = 3` (291)
and `n = 10` (1,445) match the table exactly.

🔑 **What moved is the REFERENT, not the row** (silicon, `74fd26b`):

```
97   a BESPOKE 32-bit 2:1 mux    correct — and OWES an organ proof
98   genSelect 2 1               — and HAS one, inherited from the generator
```

*The choice was never "97 or 98". It is "97 gates and a proof you owe" versus
"98 gates and a proof you have", and the extra gate IS the price of the free
theorem.* ⛔ **So do not edit a plan's bespoke-mux row to 98.** -/

/-- `n` sources of 32 bits each, then `b` encoded select bits. -/
def gsIn (n b : Nat) : Nat := n * 32 + b
/-- Source `r` bit `k`. -/
def gsRes (r k : Nat) : Nat := r * 32 + k
/-- Select bit `j`. (`b` is carried for uniformity with the rest of the family.) -/
def gsSel (n _b j : Nat) : Nat := n * 32 + j
/-- The shared constant that pads `n` sources up to `2^b` leaves. -/
def gsZero (n b : Nat) : Nat := gsIn n b
/-- One inverter per select bit, shared by every mux at that level. -/
def gsNot (n b j : Nat) : Nat := gsIn n b + 1 + j
def gsPad (b : Nat) : Nat := 2 ^ b
/-- Positions feeding level `j`; level `0` is fed by the `2^b` padded leaves. -/
def gsWidth (b j : Nat) : Nat := gsPad b / 2 ^ j
/-- Muxes at level `j` — half its input width. -/
def gsLevelWidth (b j : Nat) : Nat := gsWidth b (j + 1)
/-- Muxes below level `j`, per bit. -/
def gsBelow (b : Nat) : Nat → Nat
  | 0 => 0
  | j + 1 => gsBelow b j + gsLevelWidth b j
def gsBase (n b k j i : Nat) : Nat :=
  gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j + i) * 3
/-- **The named output of level `j`, position `i`, for bit `k`.** -/
def gsOut (n b k j i : Nat) : Nat := gsBase n b k j i + 2
/-- What level `j` reads: level 0 the padded sources, later levels the level below. -/
def gsPrev (n b k : Nat) : Nat → Nat → Nat
  | 0,     i => if n ≤ i then gsZero n b else gsRes i k
  | j + 1, i => gsOut n b k j i
/-- One mux: `sel[j] ? prev[2i+1] : prev[2i]`. -/
def gsMux (n b k j i : Nat) : List Gate :=
  [⟨gsBase n b k j i,     .and (gsPrev n b k j (2 * i))     (gsNot n b j)⟩,
   ⟨gsBase n b k j i + 1, .and (gsPrev n b k j (2 * i + 1)) (gsSel n b j)⟩,
   ⟨gsOut n b k j i,      .or (gsBase n b k j i) (gsBase n b k j i + 1)⟩]

/-- **The output select at a general source count**: 32 bits, each a `b`-level
tree over `2^b` padded leaves of which the first `n` are real sources. -/
def genSelect (n b : Nat) : Circ :=
  { nIn := gsIn n b
    gates :=
      (⟨gsZero n b, .const false⟩ : Gate)
        :: (List.range b).map (fun j => (⟨gsNot n b j, .not (gsSel n b j)⟩ : Gate))
        ++ (List.range 32).flatMap fun k =>
             (List.range b).flatMap fun j =>
               (List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)
    outs := (List.range 32).map fun k => gsOut n b k (b - 1) 0 }

/-! ### The landed block, recovered — ⛔ **THE ELEVEN-THEOREM LADDER RETIRED AT PHASE 3**

**What stood here, and what left together:** `gsLevelWidth_four`, `gsBelow_four`,
`gsPad_four`, `gsIn_ten`, `gsBase_ten`, `gsOut_ten`, `gsPrev_ten`, `gsMux_ten`,
`genSelect_ten_gates`, `genSelect_ten_outs`, `genSelect_ten` — **eleven**
declarations, every one an equation between the generator AT THE LITERAL PAIR
`(10, 4)` and the `as*` block, plus the three `#audit_axioms` lines that named
them.

⚠️ **THEY WERE NOT MERELY SUPERSEDED — THE RE-CUT FALSIFIES EVERY ONE OF THEM.**
*`gsPad_four` becomes `16 = 4`; `gsIn_ten` becomes `324 = 98`;
`gsLevelWidth_four` fails at `j = 0` with `8 = 2`. All exhibited in the KERNEL
before the deletion, with a positive control proving the deletion set is not too
wide (`ScratchP3PRICE.lean`, 7/7).*

✅ **THEIR WHOLE PURPOSE WAS TO BUILD `genSelect_ten`, AND MATH'S PARAMETRIC HINGE
`genSelect_eq_aluSelect` (below, `efa5fe4`) REPLACES THE LOT FROM TWO SEED FACTS.**
So the ladder retires wholesale instead of being re-proved at the ruled pair —
eleven dead declarations rather than eleven migrations. *That is the hinge earning
its keep in the only currency that counts.*

📌 **The banked phase-3 estimate said "3 deletions". It was eleven.** *The
difference was found by asking who RIDES a bridge rather than what the bridge
proves — and the one consumer from outside this file
(`GSCount.gate_count_aluSelect`) was repointed at the hinge in `1d9e7d6`, the
commit before this one, so that this deletion could go in green.* -/

/-! ### The two shrunk instances, measured

*The rows the sizing table cares about, in the kernel rather than in a formula.
The behavioural theorems for both are `sem_operandBMux` and `sem_sliceASelect`
(math, `Stack/Program.lean`), and the mutation control that makes the `n = 2`
number mean something is `genSelectCut2` beside them — the same place
`aluSelectCut` sits for the ten-source block.* -/

-- (gates, gates, muxes, muxes) for `n = 2` and `n = 3`. ⚠️ The 98 is the
-- table's 97 PLUS the unconditional pad constant, dead at `n = 2^b`.
#eval ((genSelect 2 1).gates.length, (genSelect 3 2).gates.length,
       muxCount (genSelect 2 1), muxCount (genSelect 3 2))

/-- ⭐ **THE ADDI OPERAND-B MUX, TO THE GATE** — **98**. ⚠️ *Not a correction of
the table's 97: that row prices a bespoke 2:1 mux and is right about it. This
row prices the one that arrives with `sem_operandBMux` already proved.* -/
theorem genSelect_two_gate_count : (genSelect 2 1).gates.length = 98 := by decide +kernel

/-- ⭐ **SLICE A'S ALU SELECT `{add, xor, slt}`** — 291, matching the table
exactly, because `3 < 4` charges the pad constant on both sides. -/
theorem genSelect_three_gate_count : (genSelect 3 2).gates.length = 291 := by decide +kernel

theorem genSelect_two_ssa : (genSelect 2 1).ssa = true := by decide +kernel
theorem genSelect_two_wf : (genSelect 2 1).wf = true := Circ.wf_of_ssa genSelect_two_ssa
theorem genSelect_three_ssa : (genSelect 3 2).ssa = true := by decide +kernel
theorem genSelect_three_wf : (genSelect 3 2).wf = true := Circ.wf_of_ssa genSelect_three_ssa

#audit_axioms gsIn gsRes gsSel gsZero gsNot gsPad gsWidth gsLevelWidth
#audit_axioms gsBelow gsBase gsOut gsPrev gsMux genSelect
#audit_axioms genSelect_two_gate_count genSelect_three_gate_count
#audit_axioms genSelect_two_ssa genSelect_two_wf genSelect_three_ssa genSelect_three_wf


/-! ## ⭐ DOES IT SELECT? — the behavioural certificate this file did not have

**Before today this file carried NO theorems.** *It is a 1,445-gate mux tree that
`core` depends on totally, and nothing said it picks the operand the select bits
name.* ⇒ **Found by census after the same gap turned up in three other files
(`docs/hdl-c4-core-assembly-plan-0807.md`).**

*Driver: operand result `m` alone holds all-ones, so bit 0 of the output is
`true` exactly when the tree selected `m`. One bit distinguishes all sixteen
select values — which is what makes this total over the select space AND cheap.
No division: one comparison per net, per the `ReadTree` lesson that output count
multiplies `sem`'s dominant cost.* -/

/-- Operand result `m` alone holds all-ones; the four select bits carry `sel`. -/
def asOneHot (m sel : Nat) : Env := fun n =>
  if n < asOps * asW then decide (m * asW ≤ n ∧ n < m * asW + asW)
  else decide (sel.testBit (n - asOps * asW))

def asBit0 (m sel : Nat) : Bool := (sem aluSelect (asOneHot m sel)).getD 0 false

/-- Every select value picks the operand it names — and the PADDING slots
(`asOps ≤ sel < asPad`) read the shared constant and yield zero, which is the one
behaviour the pad design decision is responsible for.

⛔ **THE SELECT SPACE IS `asPad`, NOT A LITERAL `16` — corrected at phase 3's
aiming sweep, and this was the most dangerous line in the file.** *It read
`List.range 16`: correct-by-coincidence at `asPad = 16` and a re-cut hazard
everywhere else. At the ruled `asSelBits = 2` the literal iterates SIXTEEN values
over a FOUR-value select space, so `sel = 4…15` alias onto `0…3` — `asOneHot`
feeds `sel.testBit j` to nets that are gate outputs rather than inputs, so `sem`
ignores them — while the predicate still demands `sel = m`.* ⇒ ***That makes
`asSelectsOK` FALSE AT EVERY `m`, and it would have taken BOTH certificates below
down with it.***

🔑 *No pad guard could have caught it. `rsPad_eq_two_pow` and `asPad_two_pow`
guard a pad CONSTANT against its select width — exactly the desynchronisation
they were built for. Nothing guards a pad numeral **hardcoded inside a
predicate**, because nothing knows it is a pad.* -/
def asSelectsOK (m : Nat) : Bool :=
  (List.range asPad).all fun sel => asBit0 m sel == decide (sel = m)

/-- ⛔ **DO NOT GENERALISE THIS — `asSelectsOK m` IS FALSE FOR `asOps ≤ m < asPad`.**

*Math found it (`ec21bb5`, 8/7 18:44) and it is checkable at `asPrev` above:
level 0 reads `asZero` — the shared tie constant — for every `i ≥ asOps`. Slots
the slots at and above `asOps` are PADDING, so `asOneHot asOps` paints a region
the tree NEVER READS while the predicate still expects `sel = asOps` to select
it.* **The predicate holds exactly on `m < asOps ∨ asPad ≤ m`, and both points
proved below sit inside the first range.**

⚠️ **STATED AGAINST THE CONSTANTS SINCE PHASE 3, AND THAT IS NOT COSMETIC.** *In
literal form ("FALSE for `10 ≤ m < 16`") this docstring was a TRUE sentence that
the re-cut turns into a FALSE one, sitting directly above two certificates whose
sample points it licenses. The prose and the theorems have to move together or
the file starts lying about itself while still compiling.*

🔑 **SO THIS IS NOT THE USUAL "PROVES LESS THAN ITS NAME" — IT IS A PREDICATE
THAT IS FALSE SOMEWHERE.** *The theorems below are TRUE. A seat generalising
them to "the selector selects" would be asserting something FALSE, not merely
something unproven.*

✅ **SUPERSEDED — use `sem_aluSelect` (math, `SaltWorks/Stack/Program.lean`):
unconditional over all 2^324 valuations and all 32 outputs, with
`asSelectsOK_of_lt` recovering this predicate for the ten REAL operands as a
corollary.** *What follows is a tripwire. That is the theorem.*

⚠️ **AND THIS DOCSTRING USED TO READ "all sixteen select values,
kernel-checked" — TRUE about `sel` and SILENT about the other three axes:** `m`
(two points, not sixteen), the operand bits (one pattern out of 2^320), and the
output (**BIT 0 ONLY** — `asBit0` is `getD 0`). *The exhaustive half was
genuine, which is exactly what made the whole sentence persuasive.*

📌 **SAMPLE POINT MOVED `3 → 0` AT PHASE 3.** *`3` is a real operand at ten
sources and is the FIRST PADDING SLOT at three — so the old statement does not
merely lose its proof at the re-cut, it becomes FALSE. `0` is a real operand at
every admissible pair, which is what a sample point has to be if it is written
once and read after a re-cut.* -/
theorem aluSelect_selects_on_sample : asSelectsOK 0 = true := by decide +kernel

/-- …and again at the LAST real operand (`asOps - 1`; `sra`, index 9, at ten
sources), so the first is not an accident of where one index sits in the tree.

⛔ **CORRECTED: this docstring used to claim "the 9/10 padding boundary is
exercised". IT IS NOT.** *`asOps - 1` is the last point at which the predicate is
TRUE; the boundary is approached and never crossed, and crossing it is precisely
where `asSelectsOK` becomes FALSE (`asSelectsOK asOps = false`).* **A sample that
stops at the last good value is evidence about the good range, never about the
edge — see the correction above.**

📌 **WRITTEN AS `asOps - 1` SINCE PHASE 3, WHICH IS THE SAME POINT IT ALWAYS
NAMED.** *At ten sources it still elaborates to `9`, so this certificate's
content is unchanged and its kernel check is the same computation — but "the last
real operand" now tracks the constant instead of asserting a numeral about it,
and the sentence above is what it means at every pair.* -/
theorem aluSelect_selects_on_sample_last :
    asSelectsOK (asOps - 1) = true := by decide +kernel

#audit_axioms asW
#audit_axioms asOps
#audit_axioms asPad
#audit_axioms asSelBits
#audit_axioms asIn
#audit_axioms asRes
#audit_axioms asSel
#audit_axioms asZero
#audit_axioms asNot
#audit_axioms asLevelWidth
#audit_axioms asBelow
#audit_axioms asBase
#audit_axioms asOut
#audit_axioms asPrev
#audit_axioms asMux
#audit_axioms aluSelect
#audit_axioms aluSelect_ssa
#audit_axioms aluSelect_wf
#audit_axioms asOneHot asBit0 asSelectsOK
#audit_axioms aluSelect_selects_on_sample
#audit_axioms aluSelect_selects_on_sample_last
#audit_axioms aluSelectCuts
#audit_axioms zrIn
#audit_axioms zrLevels
#audit_axioms zrLevelWidth
#audit_axioms zrBelow
#audit_axioms zrOut
#audit_axioms zrPrev
#audit_axioms zeroTree
#audit_axioms zeroTreeCuts

/-! # THE PARAMETRIC HINGE — `genSelect asOps asSelBits = aluSelect`

**Authored by the MATH seat** (probe `ScratchHINGE.lean`, with a negative
control `ScratchHINGECTL.lean`); landed here by the compiler seat under the
maestro's 10:58 PATCH-TO-OWNER ruling — no cross-slot grant, because a patch
handed to the slot-owner needs none.

The landed `genSelect_ten : genSelect 10 4 = aluSelect` is NUMERAL-BOUND: a calc
of `rfl` steps at 10 and 4.  So the `ALUSEL-PARAM` parametrization bought gate
counts and `ssa`/`wf` free at every `(n,b)` and did NOT buy the IDENTIFICATION of
the generator with the bespoke block — which is the fact that made the `(3,2)`
migration look like a fortnight.  This is that identification, once,
parametrically.

⭐ **THE HONESTY DEVICE, and it is why this proof is worth more than its
statement:** after harvesting the only two numeric facts the construction needs,
the four named constants are made LOCALLY IRREDUCIBLE.  From that point the
elaborator cannot delta-unfold `asOps`/`asSelBits`/`asPad`/`asW` to numerals, so
no `rfl` and no plain `decide` can silently compute its way through the equality.

⛔⛔ **AND THE EXCEPTION, WHICH IS NOT A DETAIL: `attribute [local irreducible]`
is an ELABORATOR reducibility hint. THE KERNEL DOES NOT HONOUR IT.** So
`decide +kernel` walks straight through the device. Replicated on this seat's own
hand (`ScratchDeviceProbe.lean`) after math reported it, because it is a claim
about a guarantee math authored and this seat certified:

```
under the live attribute:
  asOps = 10 := rfl                  ⛔ Type mismatch     ← the device working
  asSelBits = 4 := rfl               ⛔ Type mismatch     ← the device working
  asOps = 10 := by decide +kernel    ✅ SUCCEEDS, [0 axioms]
  asSelBits = 4 := by decide +kernel ✅ SUCCEEDS, [0 axioms]
```

⛔ **STANDING BAN, ratified: NO `decide +kernel` INSIDE `section ParametricHinge`.**
Anything proved that way here would carry the device's certification, read as
parametric, and SHATTER AT THE RE-CUT. The section is clean today (zero `decide`
of any kind); this ban is a door being closed, not a crack being patched.

⚠️ The general form, and it is the day's law in miniature: a verification device
is itself an instrument, and *which layer it binds* is part of its design. This
one binds the elaborator. The kernel is a different reader and answers a
different question — which is normally the whole point of having it.
Everything below goes through the two seeds alone.

Math's negative control confirms the device BITES — both examples MUST fail and
do, `ScratchHINGECTL.lean`, re-verified after the phase-3 deletion (13:39, both
failing with **Type mismatch**):
```
CONTROL 1  gsPad asSelBits = asPad        := rfl   -- would be computing 16 = 2^4
CONTROL 2  gsIn asOps asSelBits = asIn    := rfl   -- would be computing 98 = 3*32+2
```
**A device that cannot fail would prove nothing, and this one was tested against
itself.**

⛔ **CONTROL 2 WAS REPLACED AT PHASE 3, AND THE REASON IS A TRAP WORTH THE LINES.**
*It used to be `genSelect asOps asSelBits = aluSelect := genSelect_ten` — the
numeral-bound bridge offered for the named-constant statement. Phase 3 DELETED
`genSelect_ten`, so that example would have gone on "failing" — with `unknown
identifier`.* ⇒ ***It would have failed BY ABSENCE while the device it exists to
test went untested, and the standing instruction "both examples MUST fail" would
have read GREEN.*** **A control whose subject no longer exists is not a control.**
📌 *Both controls are transcribed here because `Scratch*.lean` is gitignored: the
control file is durable on disk but carries no history, so the repo's only record
of what the device was tested against is this docstring.*

⚠️ Contained in its own `section` so `local irreducible` cannot leak into the
`decide +kernel` theorems above, which need to compute.

📌 The downstream migration test — `sem_aluSelect` restated through this hinge
with no numeral in sight — is math's `ScratchHINGE2.lean` and belongs in
`Stack/Program.lean`, not here: it needs `sem_genSelect` and `gsSelOf`, and this
module is imported BY `Program`. -/

section ParametricHinge

/-! ## The two seed facts — the ONLY numeric input -/

/-- Seed 1: the datapath width the generator hard-codes. -/
theorem asW_eq_32 : asW = 32 := rfl

/-- Seed 2: the pad alignment (`asPad_eq_two_pow` of `Stack/Program.lean`,
re-proved here to show it does NOT force downstream siting). -/
theorem asPad_two_pow : asPad = 2 ^ asSelBits := rfl

attribute [local irreducible] asW asOps asPad asSelBits

/-! ## The layout lemmas, parametrically -/

theorem gsPad_eq : gsPad asSelBits = asPad := asPad_two_pow.symm

theorem gsIn_eq : gsIn asOps asSelBits = asIn := by
  show asOps * 32 + asSelBits = asOps * asW + asSelBits
  rw [asW_eq_32]

theorem gsRes_eq (r k : Nat) : gsRes r k = asRes r k := by
  show r * 32 + k = r * asW + k
  rw [asW_eq_32]

theorem gsSel_eq (j : Nat) : gsSel asOps asSelBits j = asSel j := by
  show asOps * 32 + j = asOps * asW + j
  rw [asW_eq_32]

theorem gsZero_eq : gsZero asOps asSelBits = asZero := gsIn_eq

theorem gsNot_eq (j : Nat) : gsNot asOps asSelBits j = asNot j := by
  show gsIn asOps asSelBits + 1 + j = asIn + 1 + j
  rw [gsIn_eq]

theorem gsLevelWidth_eq (j : Nat) : gsLevelWidth asSelBits j = asLevelWidth j := by
  show gsPad asSelBits / 2 ^ (j + 1) = asPad / 2 ^ (j + 1)
  rw [gsPad_eq]

theorem gsBelow_eq (j : Nat) : gsBelow asSelBits j = asBelow j := by
  induction j with
  | zero => rfl
  | succ j ih =>
    show gsBelow asSelBits j + gsLevelWidth asSelBits j = asBelow j + asLevelWidth j
    rw [ih, gsLevelWidth_eq]

theorem gsBase_eq' (k j i : Nat) : gsBase asOps asSelBits k j i = asBase k j i := by
  show gsIn asOps asSelBits + 1 + asSelBits
        + (k * (gsPad asSelBits - 1) + gsBelow asSelBits j + i) * 3
      = asIn + 1 + asSelBits + (k * (asPad - 1) + asBelow j + i) * 3
  rw [gsIn_eq, gsPad_eq, gsBelow_eq]

theorem gsOut_eq' (k j i : Nat) : gsOut asOps asSelBits k j i = asOut k j i := by
  show gsBase asOps asSelBits k j i + 2 = asBase k j i + 2
  rw [gsBase_eq']

theorem gsPrev_eq (k j i : Nat) : gsPrev asOps asSelBits k j i = asPrev k j i := by
  cases j with
  | zero =>
    show (if asOps ≤ i then gsZero asOps asSelBits else gsRes i k)
        = (if asOps ≤ i then asZero else asRes i k)
    rw [gsZero_eq, gsRes_eq]
  | succ j =>
    show gsOut asOps asSelBits k j i = asOut k j i
    rw [gsOut_eq']

theorem gsMux_eq (k j : Nat) : gsMux asOps asSelBits k j = asMux k j := by
  funext i
  show [(⟨gsBase asOps asSelBits k j i,
          .and (gsPrev asOps asSelBits k j (2 * i)) (gsNot asOps asSelBits j)⟩ : Gate),
        ⟨gsBase asOps asSelBits k j i + 1,
          .and (gsPrev asOps asSelBits k j (2 * i + 1)) (gsSel asOps asSelBits j)⟩,
        ⟨gsOut asOps asSelBits k j i,
          .or (gsBase asOps asSelBits k j i) (gsBase asOps asSelBits k j i + 1)⟩] = _
  rw [gsBase_eq', gsOut_eq', gsPrev_eq, gsPrev_eq, gsNot_eq, gsSel_eq]
  rfl

/-! ## The three fields -/

theorem genSelect_gates_eq' : (genSelect asOps asSelBits).gates = aluSelect.gates := by
  have hnot : (fun j => (⟨gsNot asOps asSelBits j, .not (gsSel asOps asSelBits j)⟩ : Gate))
            = (fun j => (⟨asNot j, .not (asSel j)⟩ : Gate)) := by
    funext j; rw [gsNot_eq, gsSel_eq]
  have hbody : (fun k => (List.range asSelBits).flatMap fun j =>
                  (List.range (gsLevelWidth asSelBits j)).flatMap (gsMux asOps asSelBits k j))
             = (fun k => (List.range asSelBits).flatMap fun j =>
                  (List.range (asLevelWidth j)).flatMap (asMux k j)) := by
    funext k
    have h2 : (fun j => (List.range (gsLevelWidth asSelBits j)).flatMap
                          (gsMux asOps asSelBits k j))
            = (fun j => (List.range (asLevelWidth j)).flatMap (asMux k j)) := by
      funext j; rw [gsLevelWidth_eq, gsMux_eq]
    rw [h2]
  show (⟨gsZero asOps asSelBits, .const false⟩ : Gate)
        :: (List.range asSelBits).map
             (fun j => (⟨gsNot asOps asSelBits j, .not (gsSel asOps asSelBits j)⟩ : Gate))
        ++ (List.range 32).flatMap (fun k =>
             (List.range asSelBits).flatMap fun j =>
               (List.range (gsLevelWidth asSelBits j)).flatMap (gsMux asOps asSelBits k j))
      = (⟨asZero, .const false⟩ : Gate)
        :: (List.range asSelBits).map (fun j => (⟨asNot j, .not (asSel j)⟩ : Gate))
        ++ (List.range asW).flatMap (fun k =>
             (List.range asSelBits).flatMap fun j =>
               (List.range (asLevelWidth j)).flatMap (asMux k j))
  rw [hnot, hbody, gsZero_eq, asW_eq_32]

theorem genSelect_outs_eq' : (genSelect asOps asSelBits).outs = aluSelect.outs := by
  have h : (fun k => gsOut asOps asSelBits k (asSelBits - 1) 0)
         = (fun k => asOut k (asSelBits - 1) 0) := by
    funext k; rw [gsOut_eq']
  show (List.range 32).map (fun k => gsOut asOps asSelBits k (asSelBits - 1) 0)
      = (List.range asW).map (fun k => asOut k (asSelBits - 1) 0)
  rw [h, asW_eq_32]

/-! ## ⭐ THE HINGE -/

theorem genSelect_eq_aluSelect : genSelect asOps asSelBits = aluSelect := by
  have hn : (genSelect asOps asSelBits).nIn = aluSelect.nIn := gsIn_eq
  calc genSelect asOps asSelBits
      = ⟨(genSelect asOps asSelBits).nIn, (genSelect asOps asSelBits).gates,
         (genSelect asOps asSelBits).outs⟩ := rfl
    _ = ⟨aluSelect.nIn, aluSelect.gates, aluSelect.outs⟩ := by
          rw [hn, genSelect_gates_eq', genSelect_outs_eq']
    _ = aluSelect := rfl

#audit_axioms genSelect_eq_aluSelect
#audit_axioms genSelect_gates_eq'
#audit_axioms genSelect_outs_eq'

end ParametricHinge

end SaltWorks.HDL
