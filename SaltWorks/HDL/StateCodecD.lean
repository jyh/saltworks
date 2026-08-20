/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Opus executor, queue item Q3 — Horn D, part 1)
-/
import SaltWorks.HDL.ISA
import SaltWorks.HDL.Sem
import SaltWorks.HDL.StateCodec

/-!
# Q3 / Horn D part 1 — the FULL state codec, built ALONGSIDE the landed one

⛔ **NOTHING IN THE TRACKED TREE IS TOUCHED BY THIS FILE.** `stWidth`, `stBit`, `encD`
and `decQ` in `StateCodec.lean` are untouched, and `instrBase := stWidth` therefore still
reads 1056, so no instruction net and no gate offset moves. The renumbering swap is the
seat's, deliberately; this file only prices it and proves it.

## What is here

```
stWidthD   1313 = 1024 (regs) + 32 (pc) + 256 (mem) + 1 (trap)
stBitD     the four-branch bit function
encDD      the 1313-bit encoding
decQD      the decoder that rebuilds ALL FOUR fields
```

## The three deliverables

1. `stWidthD_value` · and the layout is INJECTIVE **as a theorem, not a comment**:
   `Cell` names a field-and-offset, `Cell.place` is the layout, `Cell.ok` is its domain, and
   `layout_injective` / `layout_surjective_on` / `place_lt_stWidthD` say the placement is a
   BIJECTION from the ok-cells onto `Fin 1313` — every bit used exactly once, no field
   sharing an index, no bit wasted. `stBitD_at_place` is what stops that machinery being a
   parallel fiction: it says `stBitD` reads **the cell `place` names**.
2. `decQD_encDD` — **THE FULL ROUND TRIP**, `∀ s`, no cleanliness hypothesis. The landed
   `decQ_encD_proj` is a PROJECTION (regs and pc only) and `decQ_encD_of_clean` needs
   `s.mem = 0 ∧ s.trapped = false`; this one needs neither, and recovers the eight memory
   words and the trap flag as well.
3. `stBitD_agrees` / `encDD_getD_low` / `encDD_prefix` — the extension is CONSERVATIVE below
   1056: on every bit the landed codec has an opinion about, the two agree, and `encDD`'s
   first 1056 bits ARE `encD`.

## What a reader must check

* the four branch bounds in `stBitD` are `1024 / 1056 / 1312` and match `Cell.place`'s four
  arms — a mismatch between them is exactly what `stBitD_at_place` would catch;
* `decQD`'s memory arm reads `1056 + 32 * w + k` (word-major, the same stride the regs use)
  and NOT `1056 + w + 8 * k` — `memT_layout_breaks` is the negative control for that, and
  `correct_layout_recovers_mem` is the same computation one indexing apart;
* the round trip is `∀ s : St`, quantified over dirty memory and a set trap flag, with no
  hypothesis on `s` — that is the whole difference from the landed pair.
-/

namespace SaltWorks.HDL
namespace StateCodecD

open SaltWorks.ISA

/-! ### The extended layout -/

/-- The FULL state width: 32 registers × 32, the pc, the eight memory words, the trap flag. -/
def stWidthD : Nat := 32 * 32 + 32 + 8 * 32 + 1

theorem stWidthD_value : stWidthD = 1313 := by decide +kernel

/-- Bit `j` of the state under the extended layout. -/
def stBitD (s : St) (j : Nat) : Bool :=
  if j < 1024 then (s.regs[j / 32]!).getLsbD (j % 32)
  else if j < 1056 then s.pc.getLsbD (j - 1024)
  else if j < 1312 then (s.mem[(j - 1056) / 32]!).getLsbD ((j - 1056) % 32)
  else s.trapped

/-- **`encDD` — the extended state encoding.** -/
def encDD (s : St) : List Bool := (List.range stWidthD).map (stBitD s)

/-- **`decQD` — the extended decoding**, rebuilding ALL FOUR fields. -/
def decQD (ins : Env) : St :=
  { regs    := Vector.ofFn (fun r : Fin 32 => wordOf (fun k => ins (32 * r.val + k)))
    pc      := wordOf (fun k => ins (1024 + k))
    mem     := Vector.ofFn (fun w : Fin 8 => wordOf (fun k => ins (1056 + 32 * w.val + k)))
    trapped := ins 1312 }

/-! ### 1 · THE LAYOUT IS INJECTIVE — as a theorem

A `Cell` is a field together with its offsets; `place` is the layout map. Injectivity of
`place` on the ok-cells is exactly *"no two distinct fields share a bit index"*, and it is
proved by exhibiting a LEFT INVERSE (`cellOf`), which also gives coverage. -/

/-- A named bit of the state: which field, and where inside it. -/
inductive Cell where
  | reg (r k : Nat) : Cell
  | pc (k : Nat) : Cell
  | mem (w k : Nat) : Cell
  | trap : Cell
  deriving DecidableEq, Repr

/-- The domain: the cells that actually exist. -/
def Cell.ok : Cell → Prop
  | .reg r k => r < 32 ∧ k < 32
  | .pc k => k < 32
  | .mem w k => w < 8 ∧ k < 32
  | .trap => True

/-- **THE LAYOUT**, as a function from named field-bits to net indices. -/
def Cell.place : Cell → Nat
  | .reg r k => 32 * r + k
  | .pc k => 1024 + k
  | .mem w k => 1056 + 32 * w + k
  | .trap => 1312

/-- The inverse reading: which field-bit does index `j` name? -/
def cellOf (j : Nat) : Cell :=
  if j < 1024 then .reg (j / 32) (j % 32)
  else if j < 1056 then .pc (j - 1024)
  else if j < 1312 then .mem ((j - 1056) / 32) ((j - 1056) % 32)
  else .trap

/-- `cellOf` is a LEFT INVERSE of `place` on the ok-cells. -/
theorem cellOf_place (c : Cell) (h : c.ok) : cellOf c.place = c := by
  cases c with
  | reg r k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, cellOf]
      rw [if_pos (by omega)]
      have h1 : (32 * r + k) / 32 = r := by omega
      have h2 : (32 * r + k) % 32 = k := by omega
      rw [h1, h2]
  | pc k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, cellOf]
      rw [if_neg (by omega), if_pos (by omega)]
      have h1 : 1024 + k - 1024 = k := by omega
      rw [h1]
  | mem w k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, cellOf]
      rw [if_neg (by omega), if_neg (by omega), if_pos (by omega)]
      have h1 : (1056 + 32 * w + k - 1056) / 32 = w := by omega
      have h2 : (1056 + 32 * w + k - 1056) % 32 = k := by omega
      rw [h1, h2]
  | trap =>
      simp only [Cell.place, cellOf]
      rw [if_neg (by omega), if_neg (by omega), if_neg (by omega)]

/-- **THE INJECTIVITY OF THE LAYOUT.** No two distinct field-bits are placed at the same
net index — for registers, the pc, the eight memory words and the trap flag alike. -/
theorem layout_injective {c₁ c₂ : Cell} (h₁ : c₁.ok) (h₂ : c₂.ok)
    (h : c₁.place = c₂.place) : c₁ = c₂ := by
  rw [← cellOf_place c₁ h₁, ← cellOf_place c₂ h₂, h]

/-- Every ok-cell lands inside the 1313 bits. -/
theorem place_lt_stWidthD (c : Cell) (h : c.ok) : c.place < stWidthD := by
  cases c with
  | reg r k => simp only [Cell.ok] at h; simp only [Cell.place, stWidthD]; omega
  | pc k => simp only [Cell.ok] at h; simp only [Cell.place, stWidthD]; omega
  | mem w k => simp only [Cell.ok] at h; simp only [Cell.place, stWidthD]; omega
  | trap => simp only [Cell.place, stWidthD]; omega

/-- And every one of the 1313 bits is SOME ok-cell — so the layout wastes no bit and the
width is exactly right. With `layout_injective` and `place_lt_stWidthD` this is a bijection
between the ok-cells and `Fin 1313`. -/
theorem layout_surjective_on (j : Nat) (h : j < stWidthD) :
    (cellOf j).ok ∧ (cellOf j).place = j := by
  simp only [stWidthD] at h
  unfold cellOf
  by_cases h1 : j < 1024
  · rw [if_pos h1]
    exact ⟨by simp only [Cell.ok]; omega, by simp only [Cell.place]; omega⟩
  · rw [if_neg h1]
    by_cases h2 : j < 1056
    · rw [if_pos h2]
      exact ⟨by simp only [Cell.ok]; omega, by simp only [Cell.place]; omega⟩
    · rw [if_neg h2]
      by_cases h3 : j < 1312
      · rw [if_pos h3]
        exact ⟨by simp only [Cell.ok]; omega, by simp only [Cell.place]; omega⟩
      · rw [if_neg h3]
        exact ⟨by simp only [Cell.ok], by simp only [Cell.place]; omega⟩

/-- The value of a named field-bit, read straight off `St`. -/
def cellBit (s : St) : Cell → Bool
  | .reg r k => (s.regs[r]!).getLsbD k
  | .pc k => s.pc.getLsbD k
  | .mem w k => (s.mem[w]!).getLsbD k
  | .trap => s.trapped

/-- ⚠️ **THE TIE-DOWN: the injectivity above is ABOUT `stBitD`, not about a parallel
fiction.** At the index `place` assigns to a cell, `stBitD` reads exactly that cell. -/
theorem stBitD_at_place (s : St) (c : Cell) (h : c.ok) : stBitD s c.place = cellBit s c := by
  cases c with
  | reg r k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, stBitD, cellBit]
      rw [if_pos (by omega)]
      have h1 : (32 * r + k) / 32 = r := by omega
      have h2 : (32 * r + k) % 32 = k := by omega
      rw [h1, h2]
  | pc k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, stBitD, cellBit]
      rw [if_neg (by omega), if_pos (by omega)]
      have h1 : 1024 + k - 1024 = k := by omega
      rw [h1]
  | mem w k =>
      simp only [Cell.ok] at h
      simp only [Cell.place, stBitD, cellBit]
      rw [if_neg (by omega), if_neg (by omega), if_pos (by omega)]
      have h1 : (1056 + 32 * w + k - 1056) / 32 = w := by omega
      have h2 : (1056 + 32 * w + k - 1056) % 32 = k := by omega
      rw [h1, h2]
  | trap =>
      simp only [Cell.place, stBitD, cellBit]
      rw [if_neg (by omega), if_neg (by omega), if_neg (by omega)]

/-! ### 2 · THE FULL ROUND TRIP -/

/-- Reading `encDD`'s list back at an index in range is `stBitD`. -/
theorem encDD_getD (s : St) (j : Nat) (h : j < stWidthD) :
    (encDD s).getD j false = stBitD s j := by
  rw [encDD, List.getD_eq_getElem?_getD]
  simp only [stWidthD] at h ⊢
  simp [h]

/-- **THE FULL ROUND TRIP — ALL FOUR FIELDS, NO HYPOTHESIS ON `s`.**

*This is the whole point of Horn D part 1.* The landed `decQ_encD_proj` compares only `regs`
and `pc`, because `decQ` manufactures `mem` and `trapped` at their defaults;
`decQ_encD_of_clean` gets the whole state back only by ASSUMING those defaults. Here the
memory and the flag are encoded, so the equality is the whole `St` and is quantified over
every state, dirty memory and set trap flag included. -/
theorem decQD_encDD (s : St) : decQD (fun j => (encDD s).getD j false) = s := by
  obtain ⟨regs, pc, mem, tr⟩ := s
  have hreg : ∀ (i : Nat) (hi : i < 32),
      wordOf (fun k => (encDD ⟨regs, pc, mem, tr⟩).getD (32 * i + k) false) = regs[i] := by
    intro i hi
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [wordOf_getLsbD _ _ hk, encDD_getD _ _ (by simp only [stWidthD]; omega), stBitD,
        if_pos (by omega)]
    have hdiv : (32 * i + k) / 32 = i := by omega
    have hmod : (32 * i + k) % 32 = k := by omega
    rw [hdiv, hmod, getElem!_pos regs i hi]
  have hpc : wordOf (fun k => (encDD ⟨regs, pc, mem, tr⟩).getD (1024 + k) false) = pc := by
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [wordOf_getLsbD _ _ hk, encDD_getD _ _ (by simp only [stWidthD]; omega), stBitD,
        if_neg (by omega), if_pos (by omega)]
    have h1024 : 1024 + k - 1024 = k := by omega
    rw [h1024]
  have hmem : ∀ (w : Nat) (hw : w < 8),
      wordOf (fun k => (encDD ⟨regs, pc, mem, tr⟩).getD (1056 + 32 * w + k) false)
        = mem[w] := by
    intro w hw
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [wordOf_getLsbD _ _ hk, encDD_getD _ _ (by simp only [stWidthD]; omega), stBitD,
        if_neg (by omega), if_neg (by omega), if_pos (by omega)]
    have hdiv : (1056 + 32 * w + k - 1056) / 32 = w := by omega
    have hmod : (1056 + 32 * w + k - 1056) % 32 = k := by omega
    rw [hdiv, hmod, getElem!_pos mem w hw]
  have htr : (encDD ⟨regs, pc, mem, tr⟩).getD 1312 false = tr := by
    rw [encDD_getD _ _ (by simp only [stWidthD]; omega), stBitD]
    simp
  simp only [decQD, St.mk.injEq]
  refine ⟨?_, hpc, ?_, htr⟩
  · apply Vector.ext
    intro i hi
    rw [Vector.getElem_ofFn]
    exact hreg i hi
  · apply Vector.ext
    intro i hi
    rw [Vector.getElem_ofFn]
    exact hmem i hi

/-! ### 3 · THE EXTENSION IS CONSERVATIVE BELOW 1056 -/

/-- **AGREEMENT: on the regs and pc bits, `stBitD` IS the landed `stBit`.** -/
theorem stBitD_agrees (s : St) (j : Nat) (h : j < stWidth) : stBitD s j = stBit s j := by
  have h56 : j < 1056 := by simp only [stWidth] at h; omega
  unfold stBitD stBit
  by_cases hj : j < 1024
  · rw [if_pos hj, if_pos hj]
  · rw [if_neg hj, if_neg hj, if_pos h56]

/-- The same fact in the form the consumers use — a `getD` read of the two encodings. -/
theorem encDD_getD_low (s : St) (j : Nat) (h : j < stWidth) :
    (encDD s).getD j false = (encD s).getD j false := by
  have hD : j < stWidthD := by
    simp only [stWidth] at h; simp only [stWidthD]; omega
  rw [encDD_getD _ _ hD, encD_getD _ _ h]
  exact stBitD_agrees s j h

/-- And at the list level: **`encDD`'s first 1056 bits ARE `encD`.** -/
theorem encDD_prefix (s : St) : (encDD s).take stWidth = encD s := by
  have hlen : ((encDD s).take stWidth).length = (encD s).length := by
    simp only [encDD, encD, List.length_take, List.length_map, List.length_range, stWidth,
      stWidthD]
    omega
  refine List.ext_getElem hlen ?_
  intro n h₁ h₂
  have hn : n < stWidth := by
    simp only [encD, List.length_map, List.length_range] at h₂
    exact h₂
  simp only [encDD, encD, List.getElem_take, List.getElem_map, List.getElem_range]
  exact stBitD_agrees s n hn

/-! ### THE PRICE OF THE SWAP — the numbers the seat needs BEFORE the tracked tree moves

⛔ These are stated HERE, about `stWidthD`, and change nothing: `instrBase := stWidth` in
`StateCodec.lean` is untouched and still reads 1056. This section only prices what the seat's
renumbering would cost. -/

/-- The extension costs **257 additional state bits** — 256 memory + 1 trap flag — i.e. 257
more flops and 257 more D-roots than the landed 1056. -/
theorem extension_costs_257_bits : stWidthD - stWidth = 257 := by decide +kernel

/-- Where the instruction word would sit under the D layout — the definitional consequence
of `instrBase := stWidth` once `stWidth` becomes 1313. -/
def instrBaseD : Nat := stWidthD

/-- **THE RENUMBERING, AS TWO NUMBERS.** `instrBase` moves 1056 → 1313 and the gate-chain
anchor `coreInWidth` (`offTie`) moves 1088 → 1345: every instruction net and every gate
offset above the input region shifts by exactly 257. -/
theorem renumbering_offsets :
    instrBaseD = 1313 ∧ instrBaseD + 32 = 1345 ∧
    instrBaseD - instrBase = 257 ∧ (instrBaseD + 32) - coreInWidth = 257 := by
  decide +kernel

/-- The D-layout instruction nets stay disjoint from the state — the same property
`instr_nets_disjoint_from_state` states for the landed layout, re-established at the new
base rather than assumed to survive. -/
theorem instrD_nets_disjoint_from_state :
    ((List.range 32).all fun k => instrBaseD + k ≥ stWidthD) = true := by decide +kernel

/-! ### NON-VACUITY — a WRONG memory layout must BREAK the round trip

*`decQD_encDD` is an equality between two functions I wrote; a stride transposed in BOTH
would leave it true. The control is a decoder reading the SAME 256 memory bits with the
word/bit strides swapped, and it must fail on a state whose eight words differ.* -/

/-- The transposed memory layout — word `w` bit `k` at `1056 + w + 8 * k`. -/
def decQDmemT (ins : Env) : St :=
  { regs    := Vector.ofFn (fun r : Fin 32 => wordOf (fun k => ins (32 * r.val + k)))
    pc      := wordOf (fun k => ins (1024 + k))
    mem     := Vector.ofFn (fun w : Fin 8 => wordOf (fun k => ins (1056 + w.val + 8 * k)))
    trapped := ins 1312 }

/-- A state the landed codec cannot even represent: eight DISTINCT memory words and the
trap flag SET. -/
def sTestD : St :=
  { St.init with
    mem := Vector.ofFn (fun w : Fin 8 => BitVec.ofNat 32 (w.val + 1))
    trapped := true }

/-- **THE CONTROL: the transposed memory decoder does NOT recover word 1.** -/
theorem memT_layout_breaks :
    (decQDmemT (fun j => (encDD sTestD).getD j false)).mem[1]! ≠ sTestD.mem[1]! := by
  decide +kernel

/-- And the correct decoder DOES — the same computation, one indexing apart. -/
theorem correct_layout_recovers_mem :
    (decQD (fun j => (encDD sTestD).getD j false)).mem[1]! = sTestD.mem[1]! := by
  decide +kernel

/-- ⚠️ **AND THE LANDED DECODER FAILS ON THIS STATE** — which is Horn D, exhibited: the
1056-bit codec cannot carry a dirty memory or a set trap flag. -/
theorem landed_decQ_loses_mem_and_trap :
    decQ (fun j => (encD sTestD).getD j false) ≠ sTestD := by
  decide +kernel

#audit_axioms stWidthD
#audit_axioms stWidthD_value
#audit_axioms stBitD
#audit_axioms encDD
#audit_axioms decQD
#audit_axioms Cell.ok
#audit_axioms Cell.place
#audit_axioms cellOf
#audit_axioms cellOf_place
#audit_axioms layout_injective
#audit_axioms place_lt_stWidthD
#audit_axioms layout_surjective_on
#audit_axioms cellBit
#audit_axioms stBitD_at_place
#audit_axioms encDD_getD
#audit_axioms decQD_encDD
#audit_axioms stBitD_agrees
#audit_axioms encDD_getD_low
#audit_axioms encDD_prefix
#audit_axioms extension_costs_257_bits
#audit_axioms instrBaseD
#audit_axioms renumbering_offsets
#audit_axioms instrD_nets_disjoint_from_state
#audit_axioms decQDmemT
#audit_axioms sTestD
#audit_axioms memT_layout_breaks
#audit_axioms correct_layout_recovers_mem
#audit_axioms landed_decQ_loses_mem_and_trap

end StateCodecD
end SaltWorks.HDL
