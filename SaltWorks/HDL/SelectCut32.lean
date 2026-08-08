/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.GenSelectCount
import SaltWorks.Stack.Program

/-!
# `sliceASelect` — the SELECT SIDE of the ruled `(n = 3, b = 2)` re-cut

Muster ruling ① (Captain-ratified, 8/8) sizes the ALU's output select at the
PAIR `(n = 3, b = 2)`: **291 gates, −1,154 against the as-built `(10, 4)`.**
This file carries the block that would REPLACE today's `aluSelect`, together
with the certificate the ruled shape needs and the mutation controls that make
the certificate mean something.

⛔ **`AluSelect.lean` IS NOT TOUCHED and `aluSelect` IS NOT RE-CUT.** The corpus
swap is a separate landing (rider 5). `sliceASelect` is a NEW name in a NEW
namespace; every claim below is about it.

⛔ **NOT DUPLICATED.** `RuledSizing32.lean` already instantiates the basic
`(3,2)` facts — cost, `ssa`/`wf`, capacity, `outs.length`. What is here is the
BEHAVIOURAL side it deliberately left out, plus the drop-in delta.

## ⚠️ WHAT HAPPENS AT SELECT = 3 — READ THIS BEFORE QUOTING ANY THEOREM BELOW

At the ruled pair the select is **two bits**, so it can encode `3`; and `n = 3`,
so `3` is **out of range**. `sem_genSelect` guards on `gsSelOf n b E < n`, and
when that guard is FALSE the block emits the **all-false arm** — zeros, not a
result. `select = 3` is REPRESENTABLE and therefore REACHABLE from an arbitrary
`Env`, and no theorem in this file pretends otherwise.

Two statements, and they are not the same statement:

| theorem | quantifier | what it says at `select = 3` |
| --- | --- | --- |
| `sliceASelect_cert` | **UNCONDITIONAL**, `∀ E : Env` | zeros — it is a CASE of the spec |
| `sliceASelect_selects` | **GUARDED** on `gsSelOf 3 2 E < 3` | says nothing; the guard excludes it |

⇒ **The total certificate is unconditional and the "it selects the source the
bits name" certificate is guarded.** The guard is not a weakness and not a gap
in the proof: at this pair the block genuinely MUST be guarded there, because
the encoding admits a value the source list does not have. Making it
unconditional is not this block's job — it is the SEAM's, and it is discharged
by showing the decoder never drives `select = 3`.

## 🔑 AND THAT SEAM OBLIGATION IS CURRENTLY UNPROVED IN THIS CORPUS

At the ruled pair each select bit is a WIRE from exactly one class line, so
`select = 3` (binary `11`) ⟺ **two class lines hot at once** ⟺ a one-hot
violation. Silicon reports **no at-most-one-hot theorem over `dcMatches` or
`decoder.outs` anywhere in the corpus**. Mutual exclusion is therefore
load-bearing for correctness and nobody has proved it.

⚠️ **The sizing change makes that fault LOUDER, not likelier.** At `(10, 4)`
two hot lines gave a wrong-but-in-range index — a wrong op, silently. At
`(3, 2)` they give exactly `3`, which is out of range — **zero instead of a
wrong op.** Same root, louder symptom. `mutPadTrue` below is the mutant that
exists only to prove that arm is real: it agrees with the spec on every
in-range select and disagrees ONLY at `select = 3`.
-/

namespace SaltWorks.HDL
namespace SelectCut32

open SaltWorks.HDL.GSCount
open SaltWorks.Stack.Program

/-! ## ⭐ THE BLOCK -/

/-- **The ruled output select** — `genSelect` at the pair the muster chose.
This is the term a `core` assembly would put where `aluSelect` sits today. -/
def sliceASelect : Circ := genSelect 3 2

/-! ## ⭐ THE SPECIFICATION, AND THE CERTIFICATE PREDICATE

The spec is a WHOLE LIST over the PORT axis with a determined length —
`(List.range 32).map …` — so a circuit cannot satisfy it by agreeing on a
prefix, on one index, or on 31 of 32 ports. `Cert` is stated once and the
mutants below are refuted against THAT statement, not against a weaker one. -/

/-- Port `k` of the ruled select, as a function of the input valuation.
`sel = 3` (both select nets high) is the `false` arm — the padding leaf. -/
def sliceABit (E : Env) (k : Nat) : Bool :=
  if E (gsSel 3 2 1) then (if E (gsSel 3 2 0) then false else E (gsRes 2 k))
  else (if E (gsSel 3 2 0) then E (gsRes 1 k) else E (gsRes 0 k))

/-- The whole port list. Length is determined by the spec itself. -/
def sliceASpec (E : Env) : List Bool := (List.range 32).map (sliceABit E)

/-- **THE CERTIFICATE**, as a predicate on circuits so a mutant can be refuted
against the identical sentence the live block satisfies. -/
def Cert (c : Circ) : Prop := ∀ E : Env, sem c E = sliceASpec E

/-! ## ① THE CERT — unconditional, over an arbitrary `Env`, no fixture -/

/-- ⭐⭐ **THE RULED SELECT MEETS THE CERTIFICATE.** For EVERY valuation of the
98 input nets — no sample, no driver, no `decide` at fixed inputs — all 32
output ports carry the source the two select nets name, and `false` at every
port when they name the padding slot. Instantiated from `sem_genSelect`; not one
line of new semantic proof. -/
theorem sliceASelect_cert : Cert sliceASelect := by
  intro E
  show sem (genSelect 3 2) E = sliceASpec E
  exact sem_sliceASelect E

/-- The same sentence with `Cert` and `sliceASpec` spelled out, so a reader need
unfold nothing to check what was proved. -/
theorem sliceASelect_cert_explicit (E : Env) :
    sem sliceASelect E
      = (List.range 32).map (fun k =>
          if E (gsSel 3 2 1) then (if E (gsSel 3 2 0) then false else E (gsRes 2 k))
          else (if E (gsSel 3 2 0) then E (gsRes 1 k) else E (gsRes 0 k))) :=
  sliceASelect_cert E

/-! ## ①″ THE PORT LIST'S LENGTH, PINNED IN THE KERNEL

The whole-list form above already determines it, and it is pinned again here
explicitly so no reader has to infer it from the shape of a `map`. -/

theorem sliceASelect_outs_length : sliceASelect.outs.length = 32 := by decide +kernel

theorem sliceASpec_length (E : Env) : (sliceASpec E).length = 32 := by
  show ((List.range 32).map (sliceABit E)).length = 32
  rw [List.length_map, List.length_range]

/-- ⭐ **32 PORTS, PROVED FROM THE CERT** — the cert is not satisfiable by a
shorter list. -/
theorem sliceASelect_sem_length (E : Env) : (sem sliceASelect E).length = 32 := by
  rw [sliceASelect_cert E]
  exact sliceASpec_length E

/-! ## ⚠️ SELECT = 3, STATED RATHER THAN ASSUMED AWAY -/

theorem map_range32_false :
    (List.range 32).map (fun _ : Nat => false) = List.replicate 32 false := by decide

/-- The two select nets, read as a number, at the ruled pair. -/
theorem sliceASelOf (E : Env) :
    gsSelOf 3 2 E = (if E (gsSel 3 2 0) then 1 else 0) + (if E (gsSel 3 2 1) then 2 else 0) :=
  gsSelOf_three E

/-- ⚠️ **BOTH SELECT NETS HIGH ⇒ SELECT = 3** — the value the source list does
not have. This is the one-hot violation, in the block's own vocabulary. -/
theorem select_three_of_both (E : Env)
    (h0 : E (gsSel 3 2 0) = true) (h1 : E (gsSel 3 2 1) = true) : gsSelOf 3 2 E = 3 := by
  simp [sliceASelOf, h0, h1]

/-- ⭐ **THE GUARD, DECODED.** `gsSelOf 3 2 E < 3` is EXACTLY "the two select
nets are not both high" — i.e. exactly at-most-one-hot on the two class lines. -/
theorem guard_iff (E : Env) :
    gsSelOf 3 2 E < 3 ↔ (E (gsSel 3 2 0) && E (gsSel 3 2 1)) = false := by
  rw [sliceASelOf]
  cases h0 : E (gsSel 3 2 0) <;> cases h1 : E (gsSel 3 2 1) <;> decide

/-- ⭐⭐ **AT SELECT = 3 THE BLOCK EMITS 32 ZEROS.** Not "unreachable", not
"undefined" — a proved, specific, WRONG-LOOKING-BUT-DEFINED output. A consumer
that reads this as "the ALU produced 0" will see a plausible word. -/
theorem sliceASelect_at_select_three (E : Env)
    (h0 : E (gsSel 3 2 0) = true) (h1 : E (gsSel 3 2 1) = true) :
    sem sliceASelect E = List.replicate 32 false := by
  have h : sliceASpec E = (List.range 32).map (fun _ : Nat => false) := by
    show (List.range 32).map (sliceABit E) = _
    refine List.map_congr_left ?_
    intro k _
    show sliceABit E k = false
    simp [sliceABit, h0, h1]
  rw [sliceASelect_cert E, h]
  exact map_range32_false

/-! ## ⭐ THE GUARDED CERT — "it selects the source the bits name"

This is the sentence the muster actually wants, and it is GUARDED. Stated
directly from `sem_genSelect` so the guard is the generator's own, not one
invented here. -/

/-- ⭐⭐ **GUARDED: `gsSelOf 3 2 E < 3` ⇒ every port carries the named source.**
The hypothesis is not decoration — `sliceASelect_at_select_three` shows the
conclusion is FALSE without it whenever a real source is nonzero. -/
theorem sliceASelect_selects (E : Env) (hg : gsSelOf 3 2 E < 3) :
    sem sliceASelect E = (List.range 32).map (fun k => E (gsRes (gsSelOf 3 2 E) k)) := by
  show sem (genSelect 3 2) E = _
  rw [sem_genSelect 3 2 (by decide) E]
  refine List.map_congr_left ?_
  intro k _
  rw [if_pos hg]

/-- ⭐ **THE SAME, AS A WORD** — the shape a `core` assembly applies, and the
form that reads port 31 as well as port 0. -/
theorem sliceASelect_word (E : Env) (hg : gsSelOf 3 2 E < 3) :
    SaltWorks.HDL.wordOf (fun k => (sem sliceASelect E).getD k false)
      = SaltWorks.HDL.wordOf (fun k => E (gsRes (gsSelOf 3 2 E) k)) := by
  rw [sliceASelect_selects E hg, wordOf_getD_map_range]

/-! ## ② THE GATE COUNT — `rw` from the closed form, not an independent `decide`

`genSelect_gates_length` has NO hypotheses and `n` does not appear in it. The
291 below is that identity at `b = 2`, not a third `decide` agreeing with two
others. -/

theorem sliceASelect_gate_count : sliceASelect.gates.length = 291 := by
  show (genSelect 3 2).gates.length = 291
  rw [genSelect_gates_length]
  rfl

/-! ## VALIDITY — by instantiation of the general theorems, not re-proved -/

theorem sliceASelect_ssa : sliceASelect.ssa = true := genSelect_ssa 3 2 (by decide)
theorem sliceASelect_wf : sliceASelect.wf = true := genSelect_wf 3 2 (by decide)

/-! ## ③ THE MUTATION CONTROLS

Four mutants. Each is `ssa` and each is 291 gates — so none is refuted for being
malformed or for being a different size — and each is proved to FAIL `Cert`,
the same predicate `sliceASelect` satisfies. -/

/-! ### MUTANT 1 — the `outs` REVERSAL (port axis scrambled, gates untouched) -/

def mutOutsRev : Circ := { sliceASelect with outs := sliceASelect.outs.reverse }

/-- Source 0 bit 0 alone; both select nets low ⇒ `select = 0`. -/
def envRev : Env := fun m => decide (m = 0)

theorem mutOutsRev_gate_count : mutOutsRev.gates.length = 291 := sliceASelect_gate_count
theorem mutOutsRev_ssa : mutOutsRev.ssa = true := by decide +kernel

/-- ⭐ **THE CERT SEES A PERMUTED PORT LIST.** A single-index or length-free
statement would not. -/
theorem mutOutsRev_fails_cert : ¬ Cert mutOutsRev := by
  intro h
  have h1 : (sem mutOutsRev envRev).getD 0 false = false := by decide +kernel
  have h2 : (sliceASpec envRev).getD 0 false = true := by decide +kernel
  rw [h envRev, h2] at h1
  exact Bool.noConfusion h1

/-! ### MUTANT 2 — the SELECT-LINE SWAP: level `j` reads select bit `1 - j` -/

def selSwap (j : Nat) : Net := gsSel 3 2 (1 - j)

def mutSwap : Circ :=
  { sliceASelect with
    gates :=
      (⟨gsZero 3 2, .const false⟩ : Gate)
        :: (List.range 2).map (fun j => (⟨gsNot 3 2 j, .not (selSwap j)⟩ : Gate))
        ++ (List.range 32).flatMap fun k =>
             (List.range 2).flatMap fun j =>
               (List.range (gsLevelWidth 2 j)).flatMap (fun i =>
                 [(⟨gsBase 3 2 k j i, .and (gsPrev 3 2 k j (2 * i)) (gsNot 3 2 j)⟩ : Gate),
                  ⟨gsBase 3 2 k j i + 1, .and (gsPrev 3 2 k j (2 * i + 1)) (selSwap j)⟩,
                  ⟨gsOut 3 2 k j i, .or (gsBase 3 2 k j i) (gsBase 3 2 k j i + 1)⟩]) }

/-- Source 2 bit 0 alone, `sel0` high, `sel1` low ⇒ `select = 1` ⇒ the spec
reads source 1 (all-false here). The mutant reads source 2. -/
def envSwap : Env := fun m => decide (m = 64 ∨ m = 96)

theorem mutSwap_gate_count : mutSwap.gates.length = 291 := by decide +kernel
theorem mutSwap_ssa : mutSwap.ssa = true := by decide +kernel

/-- The swap touches 98 gates: both shared inverters, and the `sel`-reading gate
of all 3 muxes in each of the 32 bit trees. -/
theorem mutSwap_gate_delta :
    (List.zip mutSwap.gates sliceASelect.gates).countP (fun p => p.1 != p.2) = 98 := by
  decide +kernel

theorem mutSwap_fails_cert : ¬ Cert mutSwap := by
  intro h
  have h1 : (sem mutSwap envSwap).getD 0 false = true := by decide +kernel
  have h2 : (sliceASpec envSwap).getD 0 false = false := by decide +kernel
  rw [h envSwap, h2] at h1
  exact Bool.noConfusion h1

/-! ### MUTANT 3 — the PAD CONSTANT FLIPPED: the `select = 3` arm, and NOTHING else

⭐ **This is the mutant the hazard section is about.** One gate — the shared tie
constant — flips `false` to `true`. It agrees with the spec at every in-range
select and disagrees ONLY at `select = 3`. So it proves the all-false arm is a
real, load-bearing, checkable claim rather than a clause nobody exercises. -/

def mutPadTrue : Circ :=
  { sliceASelect with
    gates :=
      (⟨gsZero 3 2, .const true⟩ : Gate)
        :: (List.range 2).map (fun j => (⟨gsNot 3 2 j, .not (gsSel 3 2 j)⟩ : Gate))
        ++ (List.range 32).flatMap fun k =>
             (List.range 2).flatMap fun j =>
               (List.range (gsLevelWidth 2 j)).flatMap (gsMux 3 2 k j) }

/-- BOTH select nets high ⇒ `select = 3` ⇒ the padding slot. -/
def envPad : Env := fun m => decide (m = 96 ∨ m = 97)

theorem mutPadTrue_gate_count : mutPadTrue.gates.length = 291 := by decide +kernel
theorem mutPadTrue_ssa : mutPadTrue.ssa = true := by decide +kernel

/-- ⭐ **EXACTLY ONE GATE DIFFERS.** -/
theorem mutPadTrue_is_one_gate :
    (List.zip mutPadTrue.gates sliceASelect.gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

/-- ⚠️ **AND IT AGREES WITH THE SPEC ON AN IN-RANGE SELECT.** So the refutation
below is not "this mutant is broken everywhere" — it is precisely and only the
`select = 3` arm being wrong. -/
theorem mutPadTrue_agrees_in_range : sem mutPadTrue envRev = sliceASpec envRev := by
  decide +kernel

theorem mutPadTrue_fails_cert : ¬ Cert mutPadTrue := by
  intro h
  have h1 : (sem mutPadTrue envPad).getD 0 false = true := by decide +kernel
  have h2 : (sliceASpec envPad).getD 0 false = false := by decide +kernel
  rw [h envPad, h2] at h1
  exact Bool.noConfusion h1

/-! ### MUTANT 4 — ONE LEAF CUT: bit 0's level-0 mux 0 reads leaf 0 twice -/

def gsMuxCut3 (k j i : Nat) : List Gate :=
  if k == 0 && j == 0 && i == 0 then
    [(⟨gsBase 3 2 k j i, .and (gsPrev 3 2 k j (2 * i)) (gsNot 3 2 j)⟩ : Gate),
     ⟨gsBase 3 2 k j i + 1, .and (gsPrev 3 2 k j (2 * i)) (gsSel 3 2 j)⟩,
     ⟨gsOut 3 2 k j i, .or (gsBase 3 2 k j i) (gsBase 3 2 k j i + 1)⟩]
  else gsMux 3 2 k j i

def mutLeafCut : Circ :=
  { sliceASelect with
    gates :=
      (⟨gsZero 3 2, .const false⟩ : Gate)
        :: (List.range 2).map (fun j => (⟨gsNot 3 2 j, .not (gsSel 3 2 j)⟩ : Gate))
        ++ (List.range 32).flatMap fun k =>
             (List.range 2).flatMap fun j =>
               (List.range (gsLevelWidth 2 j)).flatMap (gsMuxCut3 k j) }

/-- Source 1 bit 0 alone, `sel0` high, `sel1` low ⇒ `select = 1` ⇒ spec port 0
is `true`; source 1 is unreachable at bit 0 in the mutant. -/
def envCut : Env := fun m => decide (m = 32 ∨ m = 96)

theorem mutLeafCut_gate_count : mutLeafCut.gates.length = 291 := by decide +kernel
theorem mutLeafCut_ssa : mutLeafCut.ssa = true := by decide +kernel

/-- ⭐ **EXACTLY ONE GATE DIFFERS.** -/
theorem mutLeafCut_is_one_gate :
    (List.zip mutLeafCut.gates sliceASelect.gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

theorem mutLeafCut_fails_cert : ¬ Cert mutLeafCut := by
  intro h
  have h1 : (sem mutLeafCut envCut).getD 0 false = false := by decide +kernel
  have h2 : (sliceASpec envCut).getD 0 false = true := by decide +kernel
  rw [h envCut, h2] at h1
  exact Bool.noConfusion h1

/-! ## ⚠️⚠️ WHERE `(3,2)` IS **NOT** A DROP-IN FOR `genSelect 10 4`

The corpus swap will trip on these. They are stated in the kernel rather than in
prose because each one is a number a reader would otherwise carry by memory. -/

theorem sliceASelect_nIn : sliceASelect.nIn = 98 := rfl
theorem aluSelect_nIn : aluSelect.nIn = 324 := rfl

/-- The saving the ruling bought, against the LANDED block rather than against
`genSelect 10 4`. -/
theorem gate_saving : aluSelect.gates.length - sliceASelect.gates.length = 1154 := by
  have h1 := gate_count_aluSelect
  have h2 := sliceASelect_gate_count
  omega

/-- ⚠️ **EVERY DOWNSTREAM NET OFFSET MOVES BY 1,380.** `Compose.instNext` places
the next organ at `nIn + gates.length`; that is `1769` today and `389` at the
ruled pair. Nothing in the type system notices an organ placed at the old
offset. -/
theorem span_delta :
    (aluSelect.nIn + aluSelect.gates.length)
      - (sliceASelect.nIn + sliceASelect.gates.length) = 1380 := by
  have h1 := gate_count_aluSelect
  have h2 := sliceASelect_gate_count
  have h3 : aluSelect.nIn = 324 := rfl
  have h4 : sliceASelect.nIn = 98 := rfl
  omega

/-- ⚠️⚠️ **NET 96 AND NET 97 CHANGE MEANING SILENTLY.** Under `(10,4)` net 96 is
bit 0 of op result **3** and net 97 is bit 1 of it. Under `(3,2)` net 96 is
**select bit 0** and net 97 is **select bit 1**. Same numbers, opposite roles,
and both blocks are `Circ` — no type distinguishes them. Any consumer holding a
net map from the ten-source block reads the ruled block's select lines as
operand bits. **This is the sharpest edge in the whole swap.** -/
theorem net96_97_change_meaning :
    gsRes 3 0 = gsSel 3 2 0 ∧ gsRes 3 1 = gsSel 3 2 1 := ⟨rfl, rfl⟩

/-- The tie constant moves too: `324` (`asZero`) becomes `98` (`gsZero 3 2`). -/
theorem pad_net_moves : gsZero 3 2 = 98 ∧ asZero = 324 := ⟨rfl, rfl⟩

/-- ⚠️ **THE ROOT IS AT LEVEL 1, NOT LEVEL 3.** Every theorem and lemma name in
`Program.lean` pinned to the old depth — `asV3_eq`, `asB3`, `asOut k 3 0`,
`aluSelect_outs_eq` — is about a level this block does not have. -/
theorem root_is_level_one :
    sliceASelect.outs = (List.range 32).map (fun k => gsOut 3 2 k 1 0) := rfl

theorem aluSelect_root_is_level_three :
    aluSelect.outs = (List.range 32).map (fun k => asOut k 3 0) := rfl

/-- ⚠️ **THREE SOURCE PORTS, NOT TEN.** The ruled block has slots for
`{add, xor, slt}` only. The seven other op results `aluSelect` names — `sub`,
`and`, `or`, `sltu`, `sll`, `srl`, `sra` — have NO port here. This is a scope
decision of the muster, not a property of the generator, and it is the reason
the swap is a re-cut of the ISA slice and not a resize. -/
theorem source_capacity : (2 : Nat) ^ 2 = 4 ∧ (2 : Nat) ^ 4 = 16 := ⟨rfl, rfl⟩

/-- ⚠️ **THE PADDING FRACTION CHANGES.** At `(10,4)` six of sixteen leaves pad,
so six of sixteen select values are out of range. At `(3,2)` ONE of four does.
The all-false arm is not new — what is new is that it now sits at a single,
adjacent, one-hot-violation-reachable code point. -/
theorem pad_slots : (16 - 10 : Nat) = 6 ∧ (4 - 3 : Nat) = 1 := ⟨rfl, rfl⟩

/-! ## ⑤ AXIOM AUDIT — ONE DECLARATION PER CALL

`#audit_axioms` abandons the rest of its own argument list at the first failure,
so a name after a failure in a multi-name call reads as clean when it was never
reached. One name per call makes "not reported" impossible. -/

#audit_axioms sliceASelect
#audit_axioms sliceABit
#audit_axioms sliceASpec
#audit_axioms Cert
#audit_axioms sliceASelect_cert
#audit_axioms sliceASelect_cert_explicit
#audit_axioms sliceASelect_outs_length
#audit_axioms sliceASpec_length
#audit_axioms sliceASelect_sem_length
#audit_axioms map_range32_false
#audit_axioms sliceASelOf
#audit_axioms select_three_of_both
#audit_axioms guard_iff
#audit_axioms sliceASelect_at_select_three
#audit_axioms sliceASelect_selects
#audit_axioms sliceASelect_word
#audit_axioms sliceASelect_gate_count
#audit_axioms sliceASelect_ssa
#audit_axioms sliceASelect_wf
#audit_axioms mutOutsRev
#audit_axioms envRev
#audit_axioms mutOutsRev_gate_count
#audit_axioms mutOutsRev_ssa
#audit_axioms mutOutsRev_fails_cert
#audit_axioms selSwap
#audit_axioms mutSwap
#audit_axioms envSwap
#audit_axioms mutSwap_gate_count
#audit_axioms mutSwap_ssa
#audit_axioms mutSwap_gate_delta
#audit_axioms mutSwap_fails_cert
#audit_axioms mutPadTrue
#audit_axioms envPad
#audit_axioms mutPadTrue_gate_count
#audit_axioms mutPadTrue_ssa
#audit_axioms mutPadTrue_is_one_gate
#audit_axioms mutPadTrue_agrees_in_range
#audit_axioms mutPadTrue_fails_cert
#audit_axioms gsMuxCut3
#audit_axioms mutLeafCut
#audit_axioms envCut
#audit_axioms mutLeafCut_gate_count
#audit_axioms mutLeafCut_ssa
#audit_axioms mutLeafCut_is_one_gate
#audit_axioms mutLeafCut_fails_cert
#audit_axioms sliceASelect_nIn
#audit_axioms aluSelect_nIn
#audit_axioms gate_saving
#audit_axioms span_delta
#audit_axioms net96_97_change_meaning
#audit_axioms pad_net_moves
#audit_axioms root_is_level_one
#audit_axioms aluSelect_root_is_level_three
#audit_axioms source_capacity
#audit_axioms pad_slots

end SelectCut32
end SaltWorks.HDL
