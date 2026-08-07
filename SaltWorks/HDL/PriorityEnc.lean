/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS

/-!
# The interrupt priority encoder — a chain plus a reduction

The last construction the silicon seat's block survey names and the only shape
outside the original five emitter obligations. Their measurement:
**`irq_id` = 30 untreated**, and their classification — *"a priority chain, the
comparator's family"* — is exactly right in a way that predicts the treatment.

## Why this needs no new mechanism, stated before the measurement

A priority encoder over 16 interrupt sources is **two shapes already built**:

```
p[i]    = mip[i] & mie[i]                    a per-bit row, cone 2
na[i+1] = na[i] & !p[i]                      A SERIAL CHAIN — the adder's shape
sel[i]  = p[i] & na[i]                       one-hot: highest priority wins
irq_id  = OR-tree over the sel[i]            A REDUCTION — the `zero` tree's shape
```

`na[i]` — *"nothing of higher priority is pending"* — **is a carry chain wearing
a different name.** It ripples from bit 0 to bit 15 exactly as a carry ripples
from bit 0 to bit 31, and it fails and is repaired for the same reasons.

⇒ **Cut the chain, THE ONE-HOT ROW, and the reduction levels, and every cone is
3 or 2** — the floor the silicon seat's rule predicts.

⛔ **AND THE ONE-HOT ROW IS THE PART I GOT WRONG, HAVING READ THE RULE THAT
NAMES IT.** My first cut set was the chain and the tree levels only. **Measured
6, not 3** — because `sel[i] = p[i] & na[i]` was left uncut, so every level-0
reduction node reached *through* two `sel` terms to `{mip[i], mie[i], na[i]}`
twice: **2 × 3 = 6.** ***That is exactly the silicon seat's ×2 finding — "the
per-bit combining row is not itself a cut, so each group cone reaches through it
to both operands" — which I had copied into `AluSelect.lean`'s header an hour
earlier and then walked into here.*** **A rule you have written down is not a
rule you have applied.**

⚠️ **AND THE SEAT'S SIXTH BYPASS LANDS HERE.** They marked `irq` with
`(* keep *)`, it survived as a declared name, **and it was not in `trap`'s cone**
— the optimiser dissolved the flag and re-derived it inline, reaching `mip` and
`mie` directly for 32 of 57 leaves. ***Six blocks, six bypasses; `(* keep *)` has
never once held where the optimiser had room to re-associate.*** That is the case
for structural emission made by exhaustion rather than by argument.

## What is NOT claimed

**No theorem says this encodes the highest-priority interrupt.** As in the other
four construction files, the functional obligation belongs to the code
generator's correctness argument; this establishes cone shape and cell count.
-/

namespace SaltWorks.HDL

/-- Sixteen machine-mode interrupt sources. -/
def peN : Nat := 16
/-- `irq_id` is four bits. -/
def peIdBits : Nat := 4

/-- `mip` occupies nets `0 … 15`, `mie` occupies `16 … 31`. -/
def peIn : Nat := 2 * peN
def peMip (i : Nat) : Net := i
def peMie (i : Nat) : Net := peN + i

/-- `p[i] = mip[i] & mie[i]` — pending and enabled. -/
def pePend (i : Nat) : Net := peIn + i

/-- `na[0]` is the constant true that starts the chain. -/
def peNaTrue : Net := peIn + peN
/-- `!p[i]`, allocated in pairs with the chain node it feeds. -/
def peNotP (i : Nat) : Net := peIn + peN + 1 + 2 * i
/-- **`na[i]` — "nothing of higher priority is pending".** `na[0]` is the
constant; `na[i+1] = na[i] & !p[i]`. **This is the chain, and the cut set.** -/
def peNa (i : Nat) : Net := if i == 0 then peNaTrue else peIn + peN + 2 + 2 * (i - 1)

/-- One-hot select: `sel[i] = p[i] & na[i]`. -/
def peSel (i : Nat) : Net := peIn + peN + 1 + 2 * peN + i

/-! ### The OR-reduction trees

`irq_id[k]` is the OR of `sel[i]` over every `i` whose bit `k` is set — eight
terms, a three-level tree. `valid` is the OR of all sixteen. -/

/-- The eight sources contributing to `irq_id[k]`. -/
def peIdSrc (k j : Nat) : Net :=
  -- the j-th index (0..7) whose bit k is set: insert a 1 at position k
  let lo := j % 2 ^ k
  let hi := j / 2 ^ k
  peSel (lo + 2 ^ k + hi * 2 ^ (k + 1))

/-- Trees are allocated after the one-hot row: four `irq_id` trees of 7 nodes,
then a 15-node `valid` tree. -/
def peTreeBase : Nat := peIn + peN + 1 + 2 * peN + peN
def peIdNode (k j : Nat) : Net := peTreeBase + k * 7 + j
def peValNode (j : Nat) : Net := peTreeBase + peIdBits * 7 + j

/-- A three-level OR tree over eight sources, nodes `0…3`, `4…5`, `6`. -/
def peIdTree (k : Nat) : List Gate :=
  (List.range 4).map (fun j => (⟨peIdNode k j, .or (peIdSrc k (2*j)) (peIdSrc k (2*j+1))⟩ : Gate))
  ++ (List.range 2).map (fun j => (⟨peIdNode k (4+j), .or (peIdNode k (2*j)) (peIdNode k (2*j+1))⟩ : Gate))
  ++ [⟨peIdNode k 6, .or (peIdNode k 4) (peIdNode k 5)⟩]

/-- A four-level OR tree over all sixteen `sel`, nodes `0…7`, `8…11`, `12…13`, `14`. -/
def peValTree : List Gate :=
  (List.range 8).map (fun j => (⟨peValNode j, .or (peSel (2*j)) (peSel (2*j+1))⟩ : Gate))
  ++ (List.range 4).map (fun j => (⟨peValNode (8+j), .or (peValNode (2*j)) (peValNode (2*j+1))⟩ : Gate))
  ++ (List.range 2).map (fun j => (⟨peValNode (12+j), .or (peValNode (8+2*j)) (peValNode (8+2*j+1))⟩ : Gate))
  ++ [⟨peValNode 14, .or (peValNode 12) (peValNode 13)⟩]

/-- **The interrupt priority encoder.** Outputs are `irq_id[0..3]` then `valid`. -/
def priorityEnc : Circ :=
  { nIn := peIn
    gates :=
      (List.range peN).map (fun i => (⟨pePend i, .and (peMip i) (peMie i)⟩ : Gate))
      ++ [⟨peNaTrue, .const true⟩]
      ++ (List.range (peN - 1)).flatMap (fun i =>
           [(⟨peNotP i, .not (pePend i)⟩ : Gate),
            (⟨peNa (i + 1), .and (peNa i) (peNotP i)⟩ : Gate)])
      ++ (List.range peN).map (fun i => (⟨peSel i, .and (pePend i) (peNa i)⟩ : Gate))
      ++ (List.range peIdBits).flatMap peIdTree
      ++ peValTree
    outs := (List.range peIdBits).map (fun k => peIdNode k 6) ++ [peValNode 14] }

/-- The cut set: **the priority chain and every reduction level**, exported by
construction as with `adder32Carries`, `shifter32Cuts` and `aluSelectCuts`. -/
def priorityEncCuts : List Net :=
  (List.range peN).map peNa
  ++ (List.range peN).map peSel        -- the one-hot ROW must be cut; see below
  ++ (List.range peIdBits).flatMap (fun k => (List.range 7).map (peIdNode k))
  ++ (List.range 15).map peValNode

/-! ## The measurements -/

/-- Same instrument as the other construction files. ⚠️ **A root in its own cut
set reports only itself.** -/
partial def peCone (c : Circ) (cut : List Net) (n : Net) : List Net :=
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

-- UNCUT: irq_id[3] reaches back through the whole chain. The silicon seat
-- measured this shape at 30.
#eval ((List.range peIdBits).map fun k =>
        (peCone priorityEnc [] (peIdNode k 6)).length).foldl Nat.max 0

-- CUT AT THE CHAIN AND EVERY TREE LEVEL. A chain node is {na[i], mip[i], mie[i]}
-- and a reduction node is two sources.  MEASURED: max 3.
#eval ((priorityEncCuts).map fun n =>
        (peCone priorityEnc (priorityEncCuts.filter (· != n)) n).length
      ).foldl Nat.max 0

-- The outputs themselves under the same cut.  MEASURED: max 2.
#eval (priorityEnc.outs.map fun n =>
        (peCone priorityEnc (priorityEncCuts.filter (· != n)) n).length).foldl Nat.max 0

#eval (priorityEnc.gates.length, priorityEnc.outs.length)

#audit_axioms peN
#audit_axioms peIdBits
#audit_axioms peIn
#audit_axioms peMip
#audit_axioms peMie
#audit_axioms pePend
#audit_axioms peNaTrue
#audit_axioms peNotP
#audit_axioms peNa
#audit_axioms peSel
#audit_axioms peIdSrc
#audit_axioms peTreeBase
#audit_axioms peIdNode
#audit_axioms peValNode
#audit_axioms peIdTree
#audit_axioms peValTree
#audit_axioms priorityEnc
#audit_axioms priorityEncCuts

end SaltWorks.HDL
