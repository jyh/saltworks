/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Banyan

/-!
# L2 of the payload-delivery block — the banyan element, under its hypothesis

LANDED wave (③ L2). `docs/payload-delivery-design-v1.md` §3, L2, **in the
form v2.3 states it** (the draft's form was refuted twice; those refutations are
respected here, not rediscovered):

> transparency of the banyan element UNDER THE HYPOTHESIS
> `act0 ∧ act1 ∧ (sel0 ≠ sel1)` at each element.

## ⛔ THE MUTATION CONTROLS — TRANSCRIBED, because their file is GITIGNORED

`ScratchL2MUT.lean` carries five mutants and is **`saltbuild EXIT=1` BY DESIGN**; all
five are refuted, fired by the compiler seat's own hand at 16:1x. It is
`Scratch*`-named and therefore carries NO HISTORY, so the list lives here — a control
whose file a reader cannot open is not a citation:
```
mut_claim_nets            wrong fabricEnv slot decode          REFUTED
mut_stage0_elements       claim nets swapped in the gate list   REFUTED
mut_stage0_data           data nets swapped                     REFUTED
mut_all_sixteen_are_wires "all 16 are wires" (vacuous-all mode) REFUTED
mut_no_state_is_a_wire    "no state is a wire"                  REFUTED
```
📌 *This transcription exists because five lemma names cited as `kernel-exhibited`
elsewhere in this campaign resolved to NOTHING — their scratch file was lawfully
deleted and the evidence went with it. Two of those five are re-established in this
file (`l2_act_sel_wire_states_are_two_of_sixteen`,
`l2_full_load_conflict_merges_at_the_gates`), at a SECOND artifact: the lost original
measured the silicon element, this measures the HDL gate-level one. Same number, two
independent artifacts.*

## The object

`fabric` (`SaltWorks/HDL/Banyan.lean:132`) is a **`Circ`** — no state, no cycle
index, so there is no "after sel_stb", and its claim signals are PRIMARY INPUTS
computed by an oracle (`claim`, `:158`) from `Banyan.line`/`srcAt`. The element
this file is about is therefore the artifact's own `element`
(`Banyan.lean:95`) — six gates, `pick ++ pick`, low output `base + 2`, high
output `base + 5` — evaluated by the artifact's own `run` (`Sem.lean:61`).
Nothing is modelled: §5's enumeration runs `run` on a literal instance of
`element`, and §7 exhibits those same six-gate blocks *inside* `(fabric 3).gates`.

## The four claim nets ARE `act ∧ sel`, proved not assumed

`element`'s four claim inputs are `(s₀lo, s₁lo, s₀hi, s₁hi)` — one per
(port, output half) — not `(act0, act1, sel0, sel1)`. §4 proves the translation
**from `claim`'s own body** (`claim_eq_act_and_sel`): with
`act p := (srcAt …).isSome` and `sel p := (dest s).testBit m`,

    claim … p hi = act p && (sel p == hi)

so `s_p_lo = act p && !sel p` and `s_p_hi = act p && sel p`. That is the
encoding §2/§5 use, and it is the artifact's, not this file's.

## What is proved, and what is NOT

* **PROVED** — under `act0 = true`, `act1 = true`, `sel0 ≠ sel1` the element's
  two outputs are `(a, b)` when `sel0 = false` and `(b, a)` when `sel0 = true`;
  i.e. a `List.Perm` of its two inputs (§2, §3), stated with the artifact's
  `claim`/`actOf`/`selOf` in §4.
* **PROVED, NEGATIVE** — the hypothesis is *exactly* the wire condition: of the
  16 `(act0, act1, sel0, sel1)` states, **2** are 2-permutations, and dropping
  any conjunct exhibits a merge (non-injective, at FULL LOAD) or a drop (§5, §6).
  The prior finding **2 of 16 is CONFIRMED**, now at the HDL artifact as well as
  at the silicon element where it was first measured.
* **NOT PROVED / OUT OF SCOPE** — that the hypothesis HOLDS at each element
  (transporting H1's distinct destinations to per-element sel-distinctness) is
  L4's work, by the block's own assignment; and composing the twelve elements
  into a statement about `sem (fabric 3)` is L3/L4's, not done here. §7 goes as
  far as an executor honestly can without it: the element blocks are exhibited
  inside the fabric's gate list, and the placement side conditions are
  discharged at the fabric's real net numbering.

Scope: P = 8 tapeout instance, k = 3. No ∀-P, no ∀-k.
-/

namespace L2Banyan

open SaltWorks.HDL

/-! ## 1. The element's two outputs, from the artifact's gates

`pick_spec` (`Banyan.lean:76`) gives one `pick`. `element` is two of them
sharing the data inputs `a`, `b`, so the second `pick` reads nets the first has
already written unless its operands live below `base` — which is exactly the
situation in `fabric` (claims are nets `8…55`, data nets are primary inputs or a
previous stage's outputs, and every stage's `base` is above both). The
`< base` side conditions below are that fact, made a hypothesis.

**FIVE conditions, not six — and the asymmetry is `pick_spec`'s own.** `s₀lo` is
read by gate `base` *before anything has been written*, and never again, so it
needs no constraint at all: it may even BE `base`. The first draft of this file
carried `s₀lo < base` "for symmetry", the unused-variable linter said so, and
dropping it makes every theorem below strictly stronger. Recorded because
`pick_spec`'s docstring says the fleet already paid for this lesson once. -/

/-- **The artifact's element, evaluated.** Low output `base + 2` and high output
`base + 5` are the two claim-gated ORs of `pick`. Straight-line, so this is
`pick_spec` twice with the frame conditions discharged. -/
theorem element_outs (env : Env) (s₀lo s₁lo s₀hi s₁hi a b base : Net)
    (hs1lo : s₁lo < base) (hs0hi : s₀hi < base)
    (hs1hi : s₁hi < base) (ha : a < base) (hb : b < base) :
    run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 2)
        = ((env s₀lo && env a) || (env s₁lo && env b))
      ∧ run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 5)
        = ((env s₀hi && env a) || (env s₁hi && env b)) := by
  -- Explicit terms rather than `omega`: `Banyan.lean:81` records that `omega`
  -- does not pick up `<` facts whose operands are typed `Net`.
  have key : ∀ (x : Net), x < base → ∀ k : Nat, x ≠ base + k := fun x hx k =>
    Nat.ne_of_lt (Nat.lt_of_lt_of_le hx (Nat.le_add_right base k))
  have kb : ∀ (x : Net), x < base → x ≠ base := fun x hx => Nat.ne_of_lt hx
  have n2 := key s₀hi hs0hi
  have n3 := key s₁hi hs1hi
  have n4 := key a ha
  have n5 := key b hb
  have m1 := kb s₁lo hs1lo
  have m2 := kb s₀hi hs0hi
  have m3 := kb s₁hi hs1hi
  have m4 := kb a ha
  have m5 := kb b hb
  refine ⟨?_, ?_⟩ <;>
    simp [element, pick, run, upd, Op.eval, n2, n3, n4, n5, m1, m2, m3, m4, m5]

/-! ## 2. L2 — transparency under `act0 ∧ act1 ∧ (sel0 ≠ sel1)`

The hypothesis is taken as a HYPOTHESIS, per the block: `act0 = true`,
`act1 = true`, `sel0 ≠ sel1`. It is stated over four Bool parameters and four
equations tying the element's claim nets to them, so that dropping a conjunct is
a well-defined operation — which is what §5/§6 then do. -/

/-- ⭐ **L2.** Under `act0 ∧ act1 ∧ (sel0 ≠ sel1)` the banyan element is
transparent: the low output carries port 0's bit and the high output port 1's
when `sel0 = false`, and they cross when `sel0 = true`. -/
theorem l2_banyan_element_is_transparent
    (env : Env) (s₀lo s₁lo s₀hi s₁hi a b base : Net) (act0 act1 sel0 sel1 : Bool)
    (hs1lo : s₁lo < base) (hs0hi : s₀hi < base)
    (hs1hi : s₁hi < base) (ha : a < base) (hb : b < base)
    (v0lo : env s₀lo = (act0 && !sel0)) (v1lo : env s₁lo = (act1 && !sel1))
    (v0hi : env s₀hi = (act0 && sel0)) (v1hi : env s₁hi = (act1 && sel1))
    (hact0 : act0 = true) (hact1 : act1 = true) (hsel : sel0 ≠ sel1) :
    run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 2)
        = (if sel0 then env b else env a)
      ∧ run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 5)
        = (if sel0 then env a else env b) := by
  obtain ⟨e2, e5⟩ :=
    element_outs env s₀lo s₁lo s₀hi s₁hi a b base hs1lo hs0hi hs1hi ha hb
  subst hact0
  subst hact1
  cases sel0 <;> cases sel1 <;> simp_all

/-! ## 3. …and that is literally a permutation of the two inputs -/

/-- Two-element swap, as a `Perm`. -/
theorem perm_two (x y : Bool) : ([y, x] : List Bool).Perm [x, y] := List.Perm.swap x y []

/-- ⭐ **L2, in the word the block uses**: the element's two outputs are a
PERMUTATION of its two inputs. (Not merely equinumerous: §2 says which one, and
`perm_two`'s use marks the crossing case.) -/
theorem l2_outputs_are_a_permutation_of_the_inputs
    (env : Env) (s₀lo s₁lo s₀hi s₁hi a b base : Net) (act0 act1 sel0 sel1 : Bool)
    (hs1lo : s₁lo < base) (hs0hi : s₀hi < base)
    (hs1hi : s₁hi < base) (ha : a < base) (hb : b < base)
    (v0lo : env s₀lo = (act0 && !sel0)) (v1lo : env s₁lo = (act1 && !sel1))
    (v0hi : env s₀hi = (act0 && sel0)) (v1hi : env s₁hi = (act1 && sel1))
    (hact0 : act0 = true) (hact1 : act1 = true) (hsel : sel0 ≠ sel1) :
    ([run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 2),
      run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 5)] : List Bool).Perm
      [env a, env b] := by
  obtain ⟨e2, e5⟩ :=
    l2_banyan_element_is_transparent env s₀lo s₁lo s₀hi s₁hi a b base act0 act1 sel0 sel1
      hs1lo hs0hi hs1hi ha hb v0lo v1lo v0hi v1hi hact0 hact1 hsel
  cases sel0 <;> rw [e2, e5] <;>
    first
      | exact List.Perm.refl _
      | exact perm_two _ _

/-! ## 4. The hypothesis in the artifact's own vocabulary

`element` has no `act`/`sel` ports. Its claim nets are fed by `claim`
(`Banyan.lean:158`), and `claim`'s body is exactly `act ∧ (sel == hi)`. So
`act`/`sel` are not a model imposed on the element — they are the two fields of
`claim`'s own `match`, named. -/

/-- Port `highPort` of element `e` at stage `m` HOLDS A PACKET — the `isSome` of
`claim`'s own `srcAt` lookup. -/
def actOf (n m e : Nat) (dest : Nat → Nat) (highPort : Bool) : Bool :=
  (srcAt n (m + 1) (if highPort then lowLine m e + 2 ^ m else lowLine m e) dest).isSome

/-- That packet's select bit at stage `m` — `claim`'s own `(dest s).testBit m`.
An idle port's select bit is `false` and is never read (see `claim_eq_act_and_sel`:
it is gated by `actOf`). -/
def selOf (n m e : Nat) (dest : Nat → Nat) (highPort : Bool) : Bool :=
  match srcAt n (m + 1) (if highPort then lowLine m e + 2 ^ m else lowLine m e) dest with
  | some s => (dest s).testBit m
  | none   => false

/-- **The artifact's claim signal IS `act ∧ (sel == half)`.** Pure unfolding of
`claim`; recorded as a theorem so the `act`/`sel` vocabulary in §2 is grounded in
`Banyan.lean` rather than asserted by this file. -/
theorem claim_eq_act_and_sel (n m e : Nat) (dest : Nat → Nat) (highPort hi : Bool) :
    claim n m e dest highPort hi
      = (actOf n m e dest highPort && (selOf n m e dest highPort == hi)) := by
  simp only [claim, actOf, selOf]
  cases srcAt n (m + 1) (if highPort then lowLine m e + 2 ^ m else lowLine m e) dest <;> simp

/-- ⭐ **L2 AT THE ARTIFACT'S CLAIMS.** The same statement as §2 with every
`act`/`sel` replaced by the oracle the fabric actually drives the element with.
The hypothesis is `actOf … false ∧ actOf … true ∧ selOf … false ≠ selOf … true`
— `act0 ∧ act1 ∧ (sel0 ≠ sel1)`, verbatim, in `claim`'s vocabulary. -/
theorem l2_at_the_artifact_claims
    (env : Env) (s₀lo s₁lo s₀hi s₁hi a b base : Net) (n m e : Nat) (dest : Nat → Nat)
    (hs1lo : s₁lo < base) (hs0hi : s₀hi < base)
    (hs1hi : s₁hi < base) (ha : a < base) (hb : b < base)
    (v0lo : env s₀lo = claim n m e dest false false)
    (v1lo : env s₁lo = claim n m e dest true false)
    (v0hi : env s₀hi = claim n m e dest false true)
    (v1hi : env s₁hi = claim n m e dest true true)
    (hact0 : actOf n m e dest false = true) (hact1 : actOf n m e dest true = true)
    (hsel : selOf n m e dest false ≠ selOf n m e dest true) :
    run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 2)
        = (if selOf n m e dest false then env b else env a)
      ∧ run env (element s₀lo s₁lo s₀hi s₁hi a b base) (base + 5)
        = (if selOf n m e dest false then env a else env b) := by
  refine l2_banyan_element_is_transparent env s₀lo s₁lo s₀hi s₁hi a b base
    (actOf n m e dest false) (actOf n m e dest true)
    (selOf n m e dest false) (selOf n m e dest true)
    hs1lo hs0hi hs1hi ha hb ?_ ?_ ?_ ?_ hact0 hact1 hsel
  · rw [v0lo, claim_eq_act_and_sel]; cases selOf n m e dest false <;> simp
  · rw [v1lo, claim_eq_act_and_sel]; cases selOf n m e dest true <;> simp
  · rw [v0hi, claim_eq_act_and_sel]; cases selOf n m e dest false <;> simp
  · rw [v1hi, claim_eq_act_and_sel]; cases selOf n m e dest true <;> simp

/-! ## 5. THE 16-STATE ENUMERATION, ON THE ARTIFACT'S GATES

A literal instance of `element`: claim nets `2,3,4,5`, data nets `0,1`,
`base = 6`, so the outputs are nets `8` and `11`. Everything below is `run` over
those six gates — the same `element` §2 talks about and §7 finds in `fabric 3`. -/

def bools2 : List Bool := [false, true]

/-- The artifact's element at a literal net assignment. -/
def elemGates : List Gate := element 2 3 4 5 0 1 6

/-- Nets: `0 = a` (low line in), `1 = b` (high line in), `2 = s₀lo`, `3 = s₁lo`,
`4 = s₀hi`, `5 = s₁hi`. -/
def envRaw (c0lo c1lo c0hi c1hi x y : Bool) : Env := fun j =>
  match j with
  | 0 => x
  | 1 => y
  | 2 => c0lo
  | 3 => c1lo
  | 4 => c0hi
  | 5 => c1hi
  | _ => false

/-- `(low output, high output) = (net 8, net 11)`, as a function of the four RAW
claim signals and the two data bits. -/
def rawOut (c0lo c1lo c0hi c1hi x y : Bool) : Bool × Bool :=
  (run (envRaw c0lo c1lo c0hi c1hi x y) elemGates 8,
   run (envRaw c0lo c1lo c0hi c1hi x y) elemGates 11)

/-- The same element driven through `claim`'s encoding (§4): the four claims are
`act ∧ ¬sel` / `act ∧ sel`. -/
def actSelOut (act0 act1 sel0 sel1 x y : Bool) : Bool × Bool :=
  rawOut (act0 && !sel0) (act1 && !sel1) (act0 && sel0) (act1 && sel1) x y

def isIdentAt (f : Bool → Bool → Bool × Bool) : Bool :=
  bools2.all fun x => bools2.all fun y => f x y == (x, y)

def isSwapAt (f : Bool → Bool → Bool × Bool) : Bool :=
  bools2.all fun x => bools2.all fun y => f x y == (y, x)

/-- "The element is a wire" = "the locked map is a static 2-permutation". -/
def isWireAt (f : Bool → Bool → Bool × Bool) : Bool := isIdentAt f || isSwapAt f

def actSelIsWire (act0 act1 sel0 sel1 : Bool) : Bool :=
  isWireAt (actSelOut act0 act1 sel0 sel1)

def rawIsWire (c0lo c1lo c0hi c1hi : Bool) : Bool := isWireAt (rawOut c0lo c1lo c0hi c1hi)

/-- All 16 quadruples, lexicographic, `false` first. -/
def quads : List (Bool × Bool × Bool × Bool) :=
  bools2.flatMap fun p => bools2.flatMap fun q =>
  bools2.flatMap fun r => bools2.map fun s => (p, q, r, s)

theorem quads_length : quads.length = 16 := by decide +kernel

/-- ⛔ **2 OF 16 — the prior finding CONFIRMED, now at the HDL artifact.**
`l2_locked_is_a_wire_in_two_states` (now TRACKED in `PayloadRefutations`)
measured 2 of 16 at the SILICON element (`elemOut`, `FabricRoutes.lean:59`). The
same count holds for the gate-level `element` of `Banyan.lean`, over the same 16
`(act0, act1, sel0, sel1)` states. Two independent artifacts, one number — no
correction to report. -/
theorem l2_act_sel_wire_states_are_two_of_sixteen :
    (quads.filter (fun q => actSelIsWire q.1 q.2.1 q.2.2.1 q.2.2.2)).length = 2 := by
  decide +kernel

/-- …and they are exactly "both ports active, opposite select bits". -/
theorem l2_act_sel_wire_states_named :
    quads.filter (fun q => actSelIsWire q.1 q.2.1 q.2.2.1 q.2.2.2)
      = [(true, true, false, true), (true, true, true, false)] := by
  decide +kernel

/-- ⭐ **THE HYPOTHESIS IS EXACTLY THE WIRE CONDITION** — not merely sufficient.
Over all 16 states, `isWire ↔ act0 ∧ act1 ∧ sel0 ≠ sel1`. This is the statement
that makes §2's hypothesis load-bearing rather than decorative: weaken any
conjunct and the element stops being a permutation. -/
theorem l2_hypothesis_is_exactly_the_wire_condition :
    quads.all (fun q =>
      actSelIsWire q.1 q.2.1 q.2.2.1 q.2.2.2
        == (q.1 && q.2.1 && (q.2.2.1 != q.2.2.2))) = true := by
  decide +kernel

/-- The count in the RAW claim space too (four independent primary inputs, no
`act`/`sel` encoding): identity is `(s₀lo, s₁lo, s₀hi, s₁hi) = (1,0,0,1)`, swap is
`(0,1,1,0)`, and nothing else. *Same 2, a different 16 — the coincidence is worth
recording so "2 of 16" is not read as one measurement.* -/
theorem l2_raw_claim_wire_states_named :
    quads.filter (fun q => rawIsWire q.1 q.2.1 q.2.2.1 q.2.2.2)
      = [(false, true, true, false), (true, false, false, true)] := by
  decide +kernel

/-! ## 6. NEGATIVE CONTROLS — the hypothesis dropped, one conjunct at a time

Each of these is a REFUTATION of L2-without-the-hypothesis at the same `element`
gates the positive theorems use. Cf. `l2_full_load_conflict_merges` and
`l2_idle_partner_drops_the_line` (now TRACKED in `PayloadRefutations`), which
measured the same two failures at the silicon element. -/

/-- ⛔ **DROP `sel0 ≠ sel1`, KEEP FULL LOAD: the element MERGES.** Both ports
active, both selects `0`: two distinct input pairs map to the same output pair, so
the map is not injective, let alone a permutation. §2's idle rider does not cover
this — it is a full-load state. -/
theorem l2_full_load_conflict_merges_at_the_gates :
    actSelOut true true false false true false = actSelOut true true false false false true
      ∧ actSelOut true true false false true false = (true, false) := by
  decide +kernel

/-- ⛔ …and the merge is visibly not a permutation on a single input pair either:
`(true, true) ↦ (true, false)`, which is neither the identity nor the swap of
`(true, true)`. -/
theorem l2_conflict_state_is_not_a_2_permutation :
    actSelOut true true false false true true = (true, false)
      ∧ ((true, false) : Bool × Bool) ≠ (true, true) := by
  decide +kernel

/-- ⛔ **DROP `act1`: the element DROPS a line.** With port 1 idle, `in1` is
discarded and the unclaimed output reads `0` — correct idle behaviour
(`bitserial_switch.v:81`), and still not a 2-permutation. -/
theorem l2_idle_partner_drops_the_line_at_the_gates :
    actSelOut true false false true false true = (false, false) := by decide +kernel

/-- ⛔ Neither failing state is a wire. -/
theorem l2_dropped_hypothesis_states_are_not_wires :
    actSelIsWire true true false false = false
      ∧ actSelIsWire true true true true = false
      ∧ actSelIsWire true false false true = false
      ∧ actSelIsWire false true false true = false
      ∧ actSelIsWire false false false true = false := by
  decide +kernel

/-- ⛔⛔ **L2 WITHOUT ITS HYPOTHESIS IS FALSE AT THE ARTIFACT.** The negative
control the assignment asks for, as a refutation rather than a count. -/
theorem l2_unhypothesized_transparency_is_false :
    ¬ (∀ act0 act1 sel0 sel1 : Bool, actSelIsWire act0 act1 sel0 sel1 = true) := by
  intro h
  exact absurd (h true true false false) (by decide +kernel)

/-! ## 7. THE ELEMENT BLOCKS ARE IN `fabric 3`, AND THE SIDE CONDITIONS HOLD THERE

Three facts, so that §1's `< base` hypotheses and §2's claim-net *order* are not
free-floating:

* stage 0 of `fabric 3` (which resolves destination bit `m = 2`) is literally four
  `element` blocks at nets `8+4e … 11+4e` / data `e`, `e+4` / `base = 56+6e`;
* at that numbering every side condition of §2 is arithmetic;
* the four claim nets are driven by `fabricEnv`'s slot decode, and that decode is
  `(port 0, low), (port 1, low), (port 0, high), (port 1, high)` — the ORDER
  `element`'s signature declares. That is the orientation certificate: without it,
  §5's enumeration and §2's theorem could each be self-consistent about a
  *different* port pairing.

**WHAT THIS IS NOT**: it is not a statement about `sem (fabric 3)`. Splitting the
72-gate list and composing twelve elements into a fabric-level conclusion is
L3/L4's work by the block's own assignment, and it is NOT done in this file. -/

/-- Stage 0's four element blocks, read out of the fabric's own gate list. -/
theorem fabric3_stage0_elements :
    [0, 1, 2, 3].all (fun e =>
      (((fabric 3).gates.drop (6 * e)).take 6)
        == element (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e) e (e + 4) (56 + 6 * e))
      = true := by
  decide +kernel

/-- ⭐ **L2 AT THE FABRIC'S REAL NET NUMBERING**, stage 0, every element. The
placement conditions are discharged from the numbering `fabric3_stage0_elements`
exhibits; the routing hypothesis is still a hypothesis (L4's job).

`he : e < 4` is NOT what discharges the arithmetic (`8 + 4e < 56 + 6e` holds for
every `e`); it is there to scope the statement to the four elements stage 0
actually has. Said explicitly because `omega` reads the whole context, so the
unused-variable linter cannot tell you which hypotheses a goal needed. -/
theorem l2_at_fabric3_stage0 (env : Env) (e : Nat) (he : e < 4)
    (act0 act1 sel0 sel1 : Bool)
    (v0lo : env (8 + 4 * e) = (act0 && !sel0))
    (v1lo : env (9 + 4 * e) = (act1 && !sel1))
    (v0hi : env (10 + 4 * e) = (act0 && sel0))
    (v1hi : env (11 + 4 * e) = (act1 && sel1))
    (hact0 : act0 = true) (hact1 : act1 = true) (hsel : sel0 ≠ sel1) :
    run env (element (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e) e (e + 4) (56 + 6 * e))
          (56 + 6 * e + 2)
        = (if sel0 then env (e + 4) else env e)
      ∧ run env (element (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e) e (e + 4) (56 + 6 * e))
          (56 + 6 * e + 5)
        = (if sel0 then env e else env (e + 4)) :=
  l2_banyan_element_is_transparent env (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e)
    e (e + 4) (56 + 6 * e) act0 act1 sel0 sel1
    (by show (9 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (10 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (11 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (e : Nat) < 56 + 6 * e; omega)
    (by show (e + 4 : Nat) < 56 + 6 * e; omega)
    v0lo v1lo v0hi v1hi hact0 hact1 hsel

/-- ⭐ **THE ORIENTATION CERTIFICATE.** `fabricEnv` (`Banyan.lean:166`) — the
fabric's own claim oracle — drives stage 0 element `e`'s four claim nets with
`claim n 2 e dest` at `(port, half) = (0,lo), (1,lo), (0,hi), (1,hi)`, in exactly
the order `element (s₀lo s₁lo s₀hi s₁hi …)` reads them. Proved from `fabricEnv`'s
slot arithmetic, not asserted. -/
theorem fabric3_stage0_claim_nets (n : Nat) (dest : Nat → Nat) (s₀ e : Nat) (he : e < 4) :
    fabricEnv n dest s₀ (8 + 4 * e) = claim n 2 e dest false false
      ∧ fabricEnv n dest s₀ (9 + 4 * e) = claim n 2 e dest true false
      ∧ fabricEnv n dest s₀ (10 + 4 * e) = claim n 2 e dest false true
      ∧ fabricEnv n dest s₀ (11 + 4 * e) = claim n 2 e dest true true := by
  interval_cases e <;> refine ⟨?_, ?_, ?_, ?_⟩ <;> simp [fabricEnv]

/-- ⭐⭐ **L2, FULLY TIED**: the real `element`, at the real stage-0 net numbering,
with its claim signals supplied by the real oracle `fabricEnv`, under exactly
`act0 ∧ act1 ∧ (sel0 ≠ sel1)` in `claim`'s own vocabulary. This is as far as L2
reaches without L4: the hypothesis is still assumed, and nothing here composes the
twelve elements. -/
theorem l2_at_fabric3_stage0_under_the_oracle
    (n : Nat) (dest : Nat → Nat) (s₀ e : Nat) (he : e < 4)
    (hact0 : actOf n 2 e dest false = true) (hact1 : actOf n 2 e dest true = true)
    (hsel : selOf n 2 e dest false ≠ selOf n 2 e dest true) :
    run (fabricEnv n dest s₀)
          (element (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e) e (e + 4) (56 + 6 * e))
          (56 + 6 * e + 2)
        = (if selOf n 2 e dest false then fabricEnv n dest s₀ (e + 4)
           else fabricEnv n dest s₀ e)
      ∧ run (fabricEnv n dest s₀)
          (element (8 + 4 * e) (9 + 4 * e) (10 + 4 * e) (11 + 4 * e) e (e + 4) (56 + 6 * e))
          (56 + 6 * e + 5)
        = (if selOf n 2 e dest false then fabricEnv n dest s₀ e
           else fabricEnv n dest s₀ (e + 4)) :=
  l2_at_the_artifact_claims (fabricEnv n dest s₀) (8 + 4 * e) (9 + 4 * e) (10 + 4 * e)
    (11 + 4 * e) e (e + 4) (56 + 6 * e) n 2 e dest
    (by show (9 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (10 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (11 + 4 * e : Nat) < 56 + 6 * e; omega)
    (by show (e : Nat) < 56 + 6 * e; omega)
    (by show (e + 4 : Nat) < 56 + 6 * e; omega)
    (fabric3_stage0_claim_nets n dest s₀ e he).1
    (fabric3_stage0_claim_nets n dest s₀ e he).2.1
    (fabric3_stage0_claim_nets n dest s₀ e he).2.2.1
    (fabric3_stage0_claim_nets n dest s₀ e he).2.2.2
    hact0 hact1 hsel

#audit_axioms element_outs
#audit_axioms l2_banyan_element_is_transparent
#audit_axioms perm_two
#audit_axioms l2_outputs_are_a_permutation_of_the_inputs
#audit_axioms actOf
#audit_axioms selOf
#audit_axioms claim_eq_act_and_sel
#audit_axioms l2_at_the_artifact_claims
#audit_axioms bools2
#audit_axioms elemGates
#audit_axioms envRaw
#audit_axioms rawOut
#audit_axioms actSelOut
#audit_axioms isIdentAt
#audit_axioms isSwapAt
#audit_axioms isWireAt
#audit_axioms actSelIsWire
#audit_axioms rawIsWire
#audit_axioms quads
#audit_axioms quads_length
#audit_axioms l2_act_sel_wire_states_are_two_of_sixteen
#audit_axioms l2_act_sel_wire_states_named
#audit_axioms l2_hypothesis_is_exactly_the_wire_condition
#audit_axioms l2_raw_claim_wire_states_named
#audit_axioms l2_full_load_conflict_merges_at_the_gates
#audit_axioms l2_conflict_state_is_not_a_2_permutation
#audit_axioms l2_idle_partner_drops_the_line_at_the_gates
#audit_axioms l2_dropped_hypothesis_states_are_not_wires
#audit_axioms l2_unhypothesized_transparency_is_false
#audit_axioms fabric3_stage0_elements
#audit_axioms l2_at_fabric3_stage0
#audit_axioms fabric3_stage0_claim_nets
#audit_axioms l2_at_fabric3_stage0_under_the_oracle

end L2Banyan
