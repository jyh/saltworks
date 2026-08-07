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
#audit_axioms aluSelectCuts
#audit_axioms zrIn
#audit_axioms zrLevels
#audit_axioms zrLevelWidth
#audit_axioms zrBelow
#audit_axioms zrOut
#audit_axioms zrPrev
#audit_axioms zeroTree
#audit_axioms zeroTreeCuts

end SaltWorks.HDL
