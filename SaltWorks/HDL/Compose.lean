/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Renumber

/-!
# C4 · `core` — INSTANTIATION: putting one `Circ` inside another

**This module exists because the tree does not contain it.** Every landed block
— `adder32`, `readTree`, `aluSelect`, `decoder`, `regWrite`, `regNext` — is a
standalone `Circ` with **hand-allocated net numbering**, and `Renumber` offers
`renum`/`normalize`, which renumber *one* circuit rather than embedding one in
another. *A `grep` for `compose`/`inst`/`embed`/`relabel` over `SaltWorks/HDL`
returns nothing that composes circuits.*

⇒ ***So `core`'s assembly is blocked on a combinator that has to be built, and
that is worth saying at block 5 of 6 rather than at block 6.*** **It is the same
shape as this morning's O(n²) discovery: a structural prerequisite that the plan
listed as a step.**

## What instantiation is

Embedding `c` into a host at net offset `off`, with `c`'s inputs supplied by
host nets through `σ`:

```
net n of c  ↦  σ n                  when n < c.nIn     (an input, wired by σ)
            ↦  off + (n - c.nIn)    otherwise          (an internal, shifted)
```

**The side condition is the whole risk**: the shifted region `off …` must not
collide with anything the host has already defined, and `σ`'s image must be
nets the host has *already computed*. Stated as `instOK` below rather than left
to the caller's care.

## ⚠️ GRADE OF THIS FILE, STATED PLAINLY

**Definitions: landed. A concrete instantiation: KERNEL-CHECKED. The general
semantics theorem: `#check`ed and NOT PROVED.**

*That is the honest grade and not a resting place — `inst_sem` is what makes
assembly verified rather than glue, and it is the next proof obligation on this
seat's board. A composite whose semantics theorem is missing is exactly the
"unproved link" C4's own sentence forbids.*
-/

namespace SaltWorks.HDL

/-! ### The combinator -/

/-- Remap a net of `c` into the host. -/
def instMap (c : Circ) (σ : Net → Net) (off : Nat) (n : Net) : Net :=
  if n < c.nIn then σ n else off + (n - c.nIn)

/-- `c`'s gates, embedded. -/
def instGates (c : Circ) (σ : Net → Net) (off : Nat) : List Gate :=
  c.gates.map fun g => ⟨instMap c σ off g.out, g.op.rename (instMap c σ off)⟩

/-- Where `c`'s outputs land in the host. -/
def instOuts (c : Circ) (σ : Net → Net) (off : Nat) : List Net :=
  c.outs.map (instMap c σ off)

/-- The next free net after an instantiation — `c`'s internal count, shifted. -/
def instNext (c : Circ) (off : Nat) : Nat := off + c.gates.length

/-- **The side condition, stated rather than left to care.** Every input wire
`σ i` must be strictly below `off` (already computed by the host), and `c` must
be **dense SSA** — not merely well-formed.

⛔ **`wf` IS NOT ENOUGH, AND THIS WAS WRONG WHEN FIRST LANDED.** I wrote
`c.wf = true` here, and attempting `inst_sem` is what exposed it. `Circ.wf`
requires gate outputs to be **distinct and `≥ nIn`** — it does *not* require them
to be **contiguous**. So under `wf` alone a circuit may have sparse outputs
(say `{5, 12, 7}` with `nIn = 5`), `instMap` sends them to `off+0, off+7, off+2`,
and **`instNext = off + gates.length` UNDER-REPORTS the region actually
occupied** — the next instantiation placed at `instNext` would silently collide
with this one.

✅ **`Circ.ssa` is exactly the missing property**: `ssaFrom nIn` forces
`g.out == base` incrementing, so gate `i`'s output is exactly `nIn + i` and the
image is precisely `off … off + gates.length - 1`. *And it costs nothing to
require: `normalize_ssa` is landed and `emitPipeline'` normalizes anyway, so any
block can be made dense before instantiation.* -/
def instOK (c : Circ) (σ : Net → Net) (off : Nat) : Prop :=
  c.ssa = true ∧ c.wf = true ∧ ∀ i, i < c.nIn → σ i < off

/-! ### A concrete instantiation, kernel-checked

*Two half-adders: the second's inputs are the first's outputs. If the combinator
mis-shifted a net or mis-wired an input, this composite would compute something
else — and it is small enough that the kernel can say so.* -/

/-- `sum = a ^^^ b`, `carry = a &&& b` — two inputs, two outputs, two gates. -/
def ha : Circ := { nIn := 2, gates := [⟨2, .xor 0 1⟩, ⟨3, .and 0 1⟩], outs := [2, 3] }

theorem ha_wf : ha.wf = true := by decide +kernel

/-- Host: two primary inputs `0,1`; one `ha` instantiated on them at offset 2;
a second `ha` instantiated on the FIRST one's two outputs, at offset 4. -/
def haChain : Circ :=
  let g1 := instGates ha (fun i => i) 2
  let o1 := instOuts ha (fun i => i) 2
  let g2 := instGates ha (fun i => o1.getD i 0) 4
  let o2 := instOuts ha (fun i => o1.getD i 0) 4
  { nIn := 2, gates := g1 ++ g2, outs := o1 ++ o2 }

theorem haChain_wf : haChain.wf = true := by decide +kernel

/-- **The composite computes what hand-composition says it should**, on all four
input pairs. `ha`'s outputs are `(a^^^b, a&&&b)`; feeding those to a second `ha`
gives `((a^^^b) ^^^ (a&&&b), (a^^^b) &&& (a&&&b))` — and the second is always
`false`, which is a real fact about this composite and a good witness that the
wiring is not accidental. -/
def haChainOK : Bool :=
  [false, true].all fun a => [false, true].all fun b =>
    sem haChain (fun i => if i == 0 then a else b)
      == [a ^^ b, a && b, (a ^^ b) ^^ (a && b), (a ^^ b) && (a && b)]

theorem haChain_correct : haChainOK = true := by decide +kernel

/-- **NON-VACUITY — the instantiated copy is genuinely a SECOND copy**, not the
first one read twice: the composite has four gates, not two. -/
theorem haChain_has_four_gates : haChain.gates.length = 4 := by decide +kernel

/-- And the two instances occupy disjoint net ranges. -/
theorem haChain_nets_disjoint :
    (instGates ha (fun i => i) 2).map Gate.out
      = [2, 3] ∧
    (instGates ha (fun i => [2,3].getD i 0) 4).map Gate.out = [4, 5] := by
  decide +kernel


/-! ### The blocks this seat has built are dense — checked, not assumed

*If they were not, each would need `normalize` before instantiation. They are,
so `instNext` is a genuine bound for every one of them.* -/

theorem ha_ssa : ha.ssa = true := by decide +kernel

/-- **Under `ssa`, the instantiated region is exactly `off … off+len-1`** — which
is what makes `instNext` a real bound rather than an optimistic one. -/
theorem ha_inst_region :
    (instGates ha (fun i => i) 7).map Gate.out = [7, 8]
      ∧ instNext ha 7 = 9 := by decide +kernel

/-! ### `instGates_eq_renumFrom` — ONE LINE SHORT, AND THE RESIDUE IS NAMED

**Second authorized run (clean budget of 2, granted because the `ssa`/`wf`
correction changed the statement). Both spent. Stopping as ruled.**

⭐ **THE ROUTE IS SETTLED AND IT IS NOT THE ONE THAT BURNED THE FIRST BUDGET.**
The two-base induction was the wrong shape entirely. The statement is
**pointwise**: gate `i` of the embedded list is gate `i` of `renumFrom`'s,
because under `ssa` gate `i`'s output is `c.nIn + i` (`ssaFrom_out`) and
`instMap` sends it to `off + i`. **`renumGates_getD` already says what
`renumFrom`'s `i`-th element is — nothing needed inducting again.** *Attempt 1
died on `renumGates_getD`'s argument order (`gs i k`, and I passed `i 0` where
it wants `0 i`); attempt 2 fixed that and got to a single failing step.*

⛔ **THE RESIDUE, EXACTLY — one `omega`, and it is NOT an arithmetic failure.**

```lean
    have hmap : instMap c σ off c.gates[i].out = off + i := by
      rw [← hgd, hout, instMap_internal c σ off _ (by omega)]   -- ← this `_`
      omega
```
**`omega`'s reported counterexample names `(instGates …).length`, `i`,
`(renumGates …).length` and `c.gates.length` — and NOT `c.nIn`.** *So the goal
it was handed is not `¬(c.nIn + i < c.nIn)`: the `_` is still a metavariable
when the `by omega` is elaborated, and it is proving something about the
ambient context instead.*

📌 **THE FIX I BELIEVE CLOSES IT IS ONE TOKEN — supply the net explicitly:**
`instMap_internal c σ off (c.nIn + i) (by omega)`. **I have NOT run it.** *Saying
"one token" and then spending a third attempt to find out is precisely the move
the budget exists to stop, and the tell I posted at 12:47 — the diagnosis changed
between attempts, so both were verification; a third would be the first that was
not.*

**MAESTRO: this is the residue, handed over as ordered.** `instMap_internal`
below is proved and is what the step consumes. -/

/-- `instMap` on an internal net, with the branch discharged once. -/
theorem instMap_internal (c : Circ) (σ : Net → Net) (off n : Nat) (h : ¬ (n < c.nIn)) :
    instMap c σ off n = off + (n - c.nIn) := by
  rw [instMap]; exact if_neg h

section
variable (c : Circ) (σ : Net → Net) (off : Nat)

#check (c.ssa = true →
        instGates c σ off = renumFrom (instMap c σ off) off c.gates : Prop)
end

#audit_axioms instMap
#audit_axioms instGates
#audit_axioms instOuts
#audit_axioms instNext
#audit_axioms ha
#audit_axioms ha_wf
#audit_axioms haChain
#audit_axioms haChain_wf
#audit_axioms haChain_correct
#audit_axioms haChain_has_four_gates
#audit_axioms haChain_nets_disjoint
#audit_axioms ha_ssa
#audit_axioms ha_inst_region
#audit_axioms instMap_internal

end SaltWorks.HDL
