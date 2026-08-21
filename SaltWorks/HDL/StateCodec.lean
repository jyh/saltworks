/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA
import SaltWorks.HDL.Sem

/-!
# C4 · the STATE CODEC — `decQ` and `encD`, the two coercions C4's sentence turns on

Campaign freeze v1.1 opened C4's construction gate on `compile`/`core`, `decQ`,
`encD`. The composition check
(`docs/hdl-c4-composition-check-0807.md` §1) found that **both coercions are
named in C4's prose and have no referent anywhere in the tree** — `grep` for
`toBits`/`ofBits`/`encodeSt`/`decodeSt` over `SaltWorks/` returned zero — and,
unlike `compile`, **they were on no manifest as owed.** This file is them.

## ⚠️ THIS FIXES AN INTERFACE, AND THAT IS THE POINT RATHER THAN A SIDE EFFECT

`decQ : Env → St` reads the **Q-leaves** (flop outputs, which enter the
combinational core as inputs) and `encD : St → List Bool` names the **D-roots**
in the core's output order. **Both are therefore indexed by the core's net
layout — a layout that does not exist yet.**

There are two ways round that, and only one of them is the seam doctrine this
leg was given: *"agree the interface BEFORE building"* (`hdl-design-v1.md` R2,
which is why leg 2 and leg 3 have a shared netlist type at all). ⇒ **The layout
is FIXED HERE, and `compile`/`core` is required to conform to it.** *The
alternative — build the core, then read its layout off and write the codec to
match — makes the codec a description of whatever was built, which cannot then
catch a layout mistake.*

📌 **SILICON: this is the flop layout your Q-leaf/D-root treatment will see.
It is a proposal until you say otherwise, and it is cheap to change NOW and
expensive to change after `core` exists.**

## The layout

```
index          contents
0 … 1023       register r, bit k, at  32 * r + k       (r,k < 32)
1024 … 1055    pc, bit k, at  1024 + k
               1056 bits total = 32 regs × 32 + 32
```

**`x0` occupies indices 0…31 and is part of the layout even though it is not
stored.** *That is deliberate: `St.regs` has 32 entries and `St.set 0` is a
no-op, so the codec mirrors `St` exactly and the "31 stored registers" fact
(`ReadTree.lean`) stays a property of the READ PATH rather than leaking into the
state encoding. Two different questions; the earlier one was already answered
wrongly once by conflating them.*
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-- Number of state bits: 32 registers × 32 bits, plus the pc. -/
def stWidth : Nat := 32 * 32 + 32

/-! ### The instruction word's input nets — pinned here on math's C4STMT finding

**This layout was silent about the fetched word, and that silence was not
harmless.** Math's `C4STMT` (8/7) had to *posit* an `instrBase` to state C4 at
all: `stepT : St → BitVec 32 → St` needs 32 wires the state layout never
named, and `grep -F 1056` over `SaltWorks/` returned only `stWidth`'s own
definition. **The one invented thing in the composed statement was a gap in this
file.**

🔴 **AND THE TRAP THEY FOUND IS THE REASON THIS IS PINNED RATHER THAN LEFT TO
THE CALLER.** `wordOf ins` **typechecks** — `Env`, `Net` and `Nat` are all
reducible, so nothing objects — and reads bits `0…31`, **which is register
`x0`**. *A C4 written that way is a well-typed theorem about the wrong 32
wires, and the reducibility that made the seam free is the same reducibility
that hides it.* **A named constant is the cheapest thing that makes the wrong
version look wrong.** -/

/-- **The fetched instruction word occupies nets `stWidth … stWidth + 31`** —
immediately above the state, so `decQ`'s domain and the word's domain do not
overlap. -/
def instrBase : Nat := stWidth

/-- The word's bit `k`. -/
def instrNet (k : Nat) : Net := instrBase + k

/-- Total input width of a core that takes the state and one instruction. -/
def coreInWidth : Nat := stWidth + 32

theorem instrBase_is_above_the_state : instrBase = 1056 := by decide +kernel
theorem coreInWidth_value : coreInWidth = 1088 := by decide +kernel

/-- **The instruction nets are disjoint from every state net** — the property
that makes `wordOf (fun k => ins (instrNet k))` the right reading and
`wordOf ins` the wrong one. -/
theorem instr_nets_disjoint_from_state :
    ((List.range 32).all fun k => instrNet k ≥ stWidth) = true := by decide +kernel

/-- ⚠️ **The trap, as a theorem: reading the word at net 0 reads `x0`, not the
instruction.** *`wordOf ins` and `wordOf (fun k => ins (instrNet k))` are
different functions, and only the type system's silence makes them look alike.* -/
theorem word_at_zero_is_register_x0 :
    instrNet 0 ≠ 0 ∧ instrNet 0 = stWidth := by decide +kernel

/-- A 32-bit word from a bit function. Built through `BitVec.ofBoolListLE`
because that is the constructor with a `getLsbD` lemma; the cast is discharged
by `List.length_map`/`length_range`. -/
def wordOf (f : Nat → Bool) : BitVec 32 :=
  (BitVec.ofBoolListLE ((List.range 32).map f)).cast (by simp)

/-- **The word codec's defining property.** -/
theorem wordOf_getLsbD (f : Nat → Bool) (k : Nat) (h : k < 32) :
    (wordOf f).getLsbD k = f k := by
  rw [wordOf, BitVec.getLsbD_cast, BitVec.getLsbD_ofBoolListLE]
  rw [List.getD_eq_getElem?_getD]
  simp [h]

/-- Bit `j` of the state, under the layout above. -/
def stBit (s : St) (j : Nat) : Bool :=
  if j < 1024 then (s.regs[j / 32]!).getLsbD (j % 32)
  else s.pc.getLsbD (j - 1024)

/-- **The pc field's bit, named once so the branch walk lives in ONE place.**

⭐ **REPAIRED 08/21: THIS IS NOW WIDTH-AGNOSTIC, WITH NO MATHLIB.**
`stBit`'s `if`-chain grows from two branches to four under Horn D, and any proof that walks it with
`rw [stBit, if_neg …]` is pinned to the branch COUNT — and the fix was to carry the MECHANISM
rather than import the vocabulary. `split_ifs` is Mathlib and this module has none (only `HDL.ISA`
and `HDL.Sem`), which walled the cross-glob template on 08/20. But the mechanism `split_ifs`
provides is only *"handle however many branches exist"*, and **`simp only` already provides it: it
does not fail on a lemma that finds no pattern, where `rw` does.** Name every condition the layout
could have; the ones that are not there simply do not fire.

**Both arms, measured:** Q — full tree `EXIT=0`. D (`stWidth`+`stBit` widened) — **this theorem
PASSES and `decQ_encD_proj` with it**; the only residue is the two class-2 literals below, which are
the swap itself and not repairs.

⛔ Do NOT reach for `congr 1` here — it blows the recursion-depth limit on the `getLsbD`
unification, which is what broke a shared tree on 08/20. -/
theorem stBit_pc (s : St) (k : Nat) (hk : k < 32) : stBit s (1024 + k) = s.pc.getLsbD k := by
  -- WIDTH-AGNOSTIC WITHOUT MATHLIB. The MECHANISM `split_ifs` provides is "handle however
  -- many branches exist"; the vocabulary is unavailable here. `simp only` supplies it: unlike
  -- `rw`, IT DOES NOT FAIL ON A LEMMA THAT FINDS NO PATTERN. So name every branch condition the
  -- layout could have; at Q the later ones simply do not fire, at D they do.
  have hnot : ¬(1024 + k < 1024) := by omega
  have hpc  : 1024 + k < 1056 := by omega
  have hidx : 1024 + k - 1024 = k := by omega
  simp only [stBit, if_neg hnot, if_pos hpc, hidx]

/-- **`encD` — the state encoding**, the D-root order C4 compares against. -/
def encD (s : St) : List Bool := (List.range stWidth).map (stBit s)

/-- **`decQ` — the Q-leaves' decoding**, reading the same layout back. -/
def decQ (ins : Env) : St :=
  { regs    := Vector.ofFn (fun r : Fin 32 => wordOf (fun k => ins (32 * r.val + k)))
    pc      := wordOf (fun k => ins (1024 + k))
    -- ⬥ M1a: `encD` encodes 1056 bits — regs and pc ONLY. The decoder therefore
    -- constructs the new fields at their defaults; it cannot read what was never
    -- written, and extending `encD` to 1313 bits would reopen the flop budget.
    mem     := Vector.replicate 8 0
    trapped := false }

/-- Reading `encD`'s list back at an index in range is `stBit`. -/
theorem encD_getD (s : St) (j : Nat) (h : j < stWidth) :
    (encD s).getD j false = stBit s j := by
  rw [encD, List.getD_eq_getElem?_getD]
  simp [stWidth] at h ⊢
  simp [h]

/-- **THE ROUND TRIP, AS A PROJECTION** (⬥M1a). *The property that makes the pair
a codec rather than two unrelated functions, and the one a layout mistake breaks.*

⚠️ **The whole-`St` form is FALSE once `St` carries `mem`/`trapped`**: `encD`
encodes 1056 bits, so the decoder rebuilds the new fields at their defaults and
cannot agree with a state that has non-default ones. The codec's content is
exactly the two encoded fields, and that is what this states. The whole-state
equality survives *conditionally*, immediately below. -/
theorem decQ_encD_proj (s : St) :
    (decQ (fun j => (encD s).getD j false)).regs = s.regs ∧
    (decQ (fun j => (encD s).getD j false)).pc = s.pc := by
  obtain ⟨regs, pc, mem, tr⟩ := s
  have hpc : wordOf (fun k => (encD ⟨regs, pc, mem, tr⟩).getD (1024 + k) false) = pc := by
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [wordOf_getLsbD _ _ hk, encD_getD _ _ (by simp [stWidth]; omega), stBit_pc _ _ hk]
  have hreg : ∀ (i : Nat) (hi : i < 32),
      wordOf (fun k => (encD ⟨regs, pc, mem, tr⟩).getD (32 * i + k) false) = regs[i] := by
    intro i hi
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [wordOf_getLsbD _ _ hk, encD_getD _ _ (by simp [stWidth]; omega), stBit,
        if_pos (by omega)]
    have hdiv : (32 * i + k) / 32 = i := by omega
    have hmod : (32 * i + k) % 32 = k := by omega
    rw [hdiv, hmod, getElem!_pos regs i hi]
  refine ⟨?_, hpc⟩
  simp only [decQ]
  apply Vector.ext
  intro i hi
  rw [Vector.getElem_ofFn]
  exact hreg i hi

/-- **THE CONDITIONAL WHOLE-`St` ROUND TRIP** (⬥M1a, the form the `run`-shaped
consumers need). On a state whose new fields are at their defaults — which is
every state the codec is fed, since `St.init` and `decQ` build them that way and
no slice-A instruction can dirty them — the codec still inverts exactly. -/
theorem decQ_encD_of_clean (s : St) (hm : s.mem = Vector.replicate 8 0)
    (ht : s.trapped = false) : decQ (fun j => (encD s).getD j false) = s := by
  obtain ⟨hr, hp⟩ := decQ_encD_proj s
  obtain ⟨regs, pc, mem, tr⟩ := s
  subst hm; subst ht
  simp only [decQ, St.mk.injEq, and_true]
  exact ⟨hr, hp⟩


/-! ### NON-VACUITY — a WRONG layout must break the round trip

*`decQ_encD_proj` is an equality between two functions I wrote; if the layout were
transposed in BOTH it would still hold. So the control is a decoder that reads
the SAME bits under a different indexing, and it must fail.* -/

/-- The transposed layout — register `r` bit `k` at `r + 32*k` instead of
`32*r + k`. **A plausible mistake: it is the same 1024 bits, read column-wise.** -/
def decQtransposed (ins : Env) : St :=
  { regs    := Vector.ofFn (fun r : Fin 32 => wordOf (fun k => ins (r.val + 32 * k)))
    pc      := wordOf (fun k => ins (1024 + k))
    mem     := Vector.replicate 8 0
    trapped := false }

/-- A state that distinguishes the two layouts: `x1 = 3`. -/
def sTest : St := St.init.set 1 3

/-- **THE CONTROL: the transposed decoder does NOT recover `x1`.** *Kernel-checked
on the register the layouts disagree about, rather than on the whole 1056-bit
state, because the witness is what matters and it is cheaper.* -/
theorem transposed_layout_breaks :
    (decQtransposed (fun j => (encD sTest).getD j false)).get 1 ≠ sTest.get 1 := by
  decide +kernel

/-- And the correct decoder DOES recover it — the same computation, one index
apart, so the control is not passing for an unrelated reason. -/
theorem correct_layout_recovers :
    (decQ (fun j => (encD sTest).getD j false)).get 1 = sTest.get 1 := by
  decide +kernel

#audit_axioms stWidth
#audit_axioms instrBase
#audit_axioms instrNet
#audit_axioms coreInWidth
#audit_axioms instrBase_is_above_the_state
#audit_axioms coreInWidth_value
#audit_axioms instr_nets_disjoint_from_state
#audit_axioms word_at_zero_is_register_x0
#audit_axioms wordOf
#audit_axioms wordOf_getLsbD
#audit_axioms stBit
#audit_axioms encD
#audit_axioms decQ
#audit_axioms encD_getD
#audit_axioms decQ_encD_proj
#audit_axioms decQ_encD_of_clean
#audit_axioms decQtransposed
#audit_axioms sTest
#audit_axioms transposed_layout_breaks
#audit_axioms correct_layout_recovers

end SaltWorks.HDL
