/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# THE `Netlist → Circ` BRIDGE — c4spec step 7's representation gap

Step 7 needs `memOrgan`'s 3 address bits and 1 write-enable. They are PRODUCED — by
`dmemAddr8NL`, the landed D1b address checker, whose outputs include `we_out` and
`word_index[0..2]`. But `dmemAddr8NL : Silicon.Netlist` while `memOrgan : HDL.Circ`, and
nothing joined the two representations.

⭐ **THEY ARE ONE CONSTRUCTOR APART.**
```
Silicon.Gate   inp i | const b | not a | and a b | or a b | xor a b   POSITIONAL: net k = gate k
HDL.Op                 const b | not a | and a b | or a b | xor a b
HDL.Circ       { nIn, gates : List HDL.Gate, outs }                   inputs live in `nIn`
```
`.inp` is the only constructor without a counterpart, and it needs none: `Circ` carries primary
inputs STRUCTURALLY in `nIn` instead of spending net slots on them. **The two representations
differ in WHERE THE INPUTS LIVE, not in what a gate is.**

⛔ **AND THE SIDE CONDITION IS NOT COSMETIC.** The positional convention only survives the
translation when the netlist's `.inp` gates are exactly the first `n` entries, in order, with
`.inp k` at position `k`. Otherwise dropping them RENUMBERS every later net and the bridged
circuit reads the wrong wires — silently, since both sides stay well-formed. So the condition
is a decidable predicate the bridge can REFUSE on, not a comment.

⭐⭐ **SEMANTIC AGREEMENT IS PROVED — 2026-08-27, `bridge_sem_eq_of_bridgeable` at the foot of
this file.** For every netlist passing the two DECIDABLE gates the code already checks
(`bridgeable` and `acyclicFrom 0`), and every input valuation, the bridged `Circ`'s `sem` equals
the netlist's own `runP` at the declared outputs. `dmemAddr8_sem_eq` instantiates it on the real
landed netlist. ***The bridge is therefore fit to place into the assembly.***

⚠️ **WHAT THAT THEOREM DOES NOT SAY, stated because a headline is quoted and a scope is not.** It
is about BEHAVIOUR AT `outs`. `sem` never reads `nIn`, so the bridged circuit's PORT COUNT is not
certified by it — `dmemAddr8_bridge_ports` certifies that separately, and the two must both be
cited to claim the bridged object is right. And it says nothing about whether the RIGHT NETS were
declared as `outs`: choosing the wrong output net yields a true agreement about the wrong wire.
*That is the same gap `instOK` leaves, and naming it here is cheaper than rediscovering it.*
-/
import SaltWorks.HDL.Sem
import SaltWorks.Silicon.Imported.DmemAddr8

namespace SaltWorks.HDL.NetlistBridge
-- ⛔ `dmemAddr8NL` lives in `SaltWorks.Silicon.Imported`, NOT `SaltWorks.Silicon` — the TYPE
-- is `SaltWorks.Silicon.Netlist` and the VALUE is one namespace deeper, which is exactly the
-- shape that makes a qualified guess look right. (Second namespace miss today; the first cost
-- a build on CoreAssemblyD.)
open SaltWorks.HDL SaltWorks.Silicon.Imported

/-- The logic constructors correspond one-to-one; `.inp` alone has no image, because a
primary input is not a gate in `Circ`. -/
def opOf : SaltWorks.Silicon.Gate → Option Op
  | .inp _     => none
  | .const b   => some (.const b)
  | .not a     => some (.not a)
  | .and a b   => some (.and a b)
  | .or  a b   => some (.or a b)
  | .xor a b   => some (.xor a b)

/-- Retag each surviving gate with the net index it already occupies. **The index is the
POSITION in the netlist, not a fresh counter** — that is what preserves every operand
reference without rewriting a single one. -/
def bridgeGatesFrom : Nat → List SaltWorks.Silicon.Gate → List Gate
  | _, []      => []
  | k, g :: gs =>
    match opOf g with
    | none    => bridgeGatesFrom (k+1) gs
    | some op => ⟨k, op⟩ :: bridgeGatesFrom (k+1) gs

/-- How many leading `.inp` gates the netlist opens with. -/
def inpPrefix : List SaltWorks.Silicon.Gate → Nat
  | []            => 0
  | .inp _ :: gs  => inpPrefix gs + 1
  | _             => 0

/-- Is `.inp k` at position `k`, for the whole leading run? -/
def inpNumberedFrom : Nat → List SaltWorks.Silicon.Gate → Bool
  | _, []             => true
  | k, .inp i :: gs   => (i == k) && inpNumberedFrom (k+1) gs
  | _, _              => true

/-- Does any `.inp` appear after the leading run? -/
def noLateInp : List SaltWorks.Silicon.Gate → Bool
  | []            => true
  | .inp _ :: gs  => noLateInp gs
  | _ :: gs       => gs.all fun g => match g with | .inp _ => false | _ => true

/-- ⭐ **THE SIDE CONDITION, DECIDABLE.** A netlist the bridge may translate: its `.inp`
gates are exactly the first `inpPrefix` entries, numbered `.inp k` at position `k`, and no
`.inp` occurs later. -/
def bridgeable (nl : List SaltWorks.Silicon.Gate) : Bool :=
  inpNumberedFrom 0 nl && noLateInp nl

/-- The bridge. `nIn` is read from the netlist, not supplied, so it cannot disagree with the
gates it describes. -/
def bridge (nl : List SaltWorks.Silicon.Gate) (outs : List Net) : Circ :=
  { nIn := inpPrefix nl, gates := bridgeGatesFrom 0 nl, outs := outs }

/-! ## THE CONCRETE NETLIST — every clause measured, not assumed -/

/-- `dmemAddr8NL` meets the side condition. -/
theorem dmemAddr8_bridgeable : bridgeable dmemAddr8NL = true := by
  decide +kernel

/-- Its shape: 79 gates, 34 of them `.inp`, so 45 survive the translation. -/
theorem dmemAddr8_shape :
    dmemAddr8NL.length = 79 ∧
    inpPrefix dmemAddr8NL = 34 ∧
    (bridgeGatesFrom 0 dmemAddr8NL).length = 45 := by
  decide +kernel

/-- The bridged circuit's ports are the netlist's own declared ports. -/
theorem dmemAddr8_bridge_ports :
    (bridge dmemAddr8NL dmemAddr8NL_outs).nIn = 34 ∧
    (bridge dmemAddr8NL dmemAddr8NL_outs).outs.length = 7 := by
  decide +kernel

/-- ⭐ **THE TRANSLATION PRESERVES NET NUMBERING** — every surviving gate sits at the index it
occupied in the netlist. *This is the property an operand reference depends on, and it is the
one a fresh counter would destroy.* -/
theorem dmemAddr8_indices_preserved :
    (bridgeGatesFrom 0 dmemAddr8NL).map Gate.out
      = (List.range 79).drop 34 := by
  decide +kernel

/-- ⛔ **THE SIDE CONDITION CAN FAIL — a negative control, so `bridgeable` is shown to
discriminate rather than merely to return `true` on the one input anyone tried.** A netlist
whose `.inp` gates are misnumbered is refused. -/
theorem bridgeable_rejects_misnumbered :
    bridgeable [.inp 0, .inp 2, .and 0 1] = false := by decide +kernel

/-- And one refused for a LATE `.inp`, which is the other half of the condition. -/
theorem bridgeable_rejects_late_inp :
    bridgeable [.inp 0, .and 0 0, .inp 1] = false := by decide +kernel

#audit_axioms opOf bridgeGatesFrom inpPrefix inpNumberedFrom noLateInp bridgeable bridge
#audit_axioms dmemAddr8_bridgeable dmemAddr8_shape dmemAddr8_bridge_ports
#audit_axioms dmemAddr8_indices_preserved bridgeable_rejects_misnumbered
#audit_axioms bridgeable_rejects_late_inp

/-! ## ⭐ SEMANTIC AGREEMENT — a WITNESS now, the general theorem still owed

⛔ **THE GENERAL THEOREM IS NOT PROVED HERE AND THIS SECTION IS NOT IT.** What follows is a
NON-VACUITY WITNESS: on a concrete bridgeable netlist, over EVERY input configuration, the
bridged `Circ`'s `sem` agrees with the netlist's own `runP` at the declared outputs. That
rules out the cheapest way for the construction to be wrong — a translation that type-checks
and computes something else entirely — and it does NOT establish the general case. -/

/-- Read an input function off a `List Bool`, so a finite sweep can quantify over inputs. -/
def insOf (bs : List Bool) : Env := fun i => bs.getD i false

/-- A small bridgeable netlist that exercises every surviving constructor. -/
def demoNL : List SaltWorks.Silicon.Gate :=
  [.inp 0, .inp 1, .and 0 1, .not 2, .xor 0 3, .or 2 4, .const true, .and 5 6]

def demoOuts : List Net := [2, 3, 4, 5, 7]

theorem demo_bridgeable : bridgeable demoNL = true := by decide +kernel

/-- ⭐⭐ **THE WITNESS: over all 4 input configurations, the bridged circuit's outputs equal
the netlist's own values at the same net indices.** *Both sides are computed — neither is
copied from the other — so this can fail.* -/
theorem demo_sem_agrees :
    (List.range 4).all (fun m =>
      let bs := [m % 2 == 1, m / 2 == 1]
      sem (bridge demoNL demoOuts) (insOf bs)
        == demoOuts.map (fun k => (SaltWorks.Silicon.runP (insOf bs) [] demoNL).getD k false))
      = true := by
  decide +kernel

/-- ⛔ **AND THE WITNESS CAN FAIL — the control.** The same comparison against a DELIBERATELY
WRONG bridge (net numbering restarted from 0 instead of preserved) must NOT agree. *Without
this the theorem above is compatible with a comparison that is true by construction.* -/
def demoBridgeWrong : Circ :=
  { nIn := inpPrefix demoNL
  , gates := (bridgeGatesFrom 0 demoNL).map (fun g => ⟨g.out - inpPrefix demoNL, g.op⟩)
  , outs := demoOuts }

theorem demo_wrong_bridge_disagrees :
    (List.range 4).all (fun m =>
      let bs := [m % 2 == 1, m / 2 == 1]
      sem demoBridgeWrong (insOf bs)
        == demoOuts.map (fun k => (SaltWorks.Silicon.runP (insOf bs) [] demoNL).getD k false))
      = false := by
  decide +kernel

#audit_axioms insOf demoNL demoOuts demo_bridgeable demo_sem_agrees
#audit_axioms demoBridgeWrong demo_wrong_bridge_disagrees

/-! ## THE GENERAL THEOREM'S PRECONDITION — landed, so the theorem applies when it arrives

The general agreement theorem needs more than `bridgeable`. Silicon's `runP` reads
`env.getD a false` where `env` has length = the CURRENT position, so a gate reading a net at
or above its own index gets `false`; HDL's `run` reads `henv a`, which is the input value
there. **The two semantics diverge on a forward reference**, and nothing in `bridgeable`
forbids one. So the precondition is acyclicity, and it is stated and MEASURED here rather
than discovered mid-proof. -/

/-- Every operand of the gate at position `k` refers to a strictly earlier net. -/
def opndsLt (k : Nat) : SaltWorks.Silicon.Gate → Bool
  | .inp _   => true
  | .const _ => true
  | .not a   => a < k
  | .and a b => a < k && b < k
  | .or  a b => a < k && b < k
  | .xor a b => a < k && b < k

def acyclicFrom : Nat → List SaltWorks.Silicon.Gate → Bool
  | _, []      => true
  | k, g :: gs => opndsLt k g && acyclicFrom (k+1) gs

/-- ⭐ **THE REAL NETLIST MEETS IT.** So when the general theorem lands it applies to
`dmemAddr8NL` without a further obligation. -/
theorem dmemAddr8_acyclic : acyclicFrom 0 dmemAddr8NL = true := by decide +kernel

/-- And the demo witness above meets it too — the witness is not exercising a shape the
general theorem would exclude. -/
theorem demo_acyclic : acyclicFrom 0 demoNL = true := by decide +kernel

/-- ⛔ **ACYCLICITY CAN FAIL, AND THE DIVERGENCE IT GUARDS IS REAL.** A forward reference is
rejected — and it must be, because on such a netlist `runP` reads `false` where `run` reads
the input, so the two semantics genuinely disagree. -/
theorem acyclic_rejects_forward_reference :
    acyclicFrom 0 [.inp 0, .and 0 5, .const true] = false := by decide +kernel

#audit_axioms opndsLt acyclicFrom dmemAddr8_acyclic demo_acyclic
#audit_axioms acyclic_rejects_forward_reference

/-! ## ⭐⭐ SEMANTIC AGREEMENT — THE GENERAL THEOREM

**THE INVARIANT, WRITTEN DOWN BESIDE THE CODE SO IT IS INHERITED RATHER THAN RE-DERIVED.**
The induction carries four clauses, relating Silicon's `List Bool` env to HDL's `Net → Bool`:
```
① senv.length = k                        the list env is exactly the written prefix
② ∀ j < k,  senv.getD j false = henv j   the written region agrees
③ ∀ j ≥ k,  henv j = ins j               THE CLAUSE THAT IS EASY TO MISS: `.inp` emits NO
                                         HDL gate, so the input region must still read
                                         through the HDL env to `ins`
④ acyclicFrom k nl                       or ② is unusable at the operand indices
```
*③ exists only because the two representations disagree about whether an input IS a gate —
Silicon spends a net slot on it, HDL does not. Every other clause is bookkeeping.* -/

/-- Appending past a position does not disturb it. -/
theorem getD_append_lt {α} [Inhabited α] (l : List α) (x : α) (d : α) {j : Nat}
    (h : j < l.length) : (l ++ [x]).getD j d = l.getD j d := by
  simp [List.getD_eq_getElem?_getD, List.getElem?_append_left h]

/-- And the appended slot is the one at the old length. -/
theorem getD_append_eq {α} [Inhabited α] (l : List α) (x : α) (d : α) :
    (l ++ [x]).getD l.length d = x := by
  simp [List.getD_eq_getElem?_getD]

/-! ### 📜 THE ROUTE — and what three failed attempts bought, kept because it is why the
fourth went through on its first build

**HISTORY, 2026-08-26. `bridge_agrees` IS NOW LANDED at the foot of this file; this block is the
record of how, not an open item.** ⛔ *It previously carried the theorem's statement inside this
very comment, where it read like a declaration to a grep, to `#audit_axioms`, and to a reader —
and a docstring quoting a theorem builds green forever.* **That is why the record now names the
theorem rather than restating it.**

```
attempt 1   the five non-`.inp` branches discharged with `exact absurd hacy …`, as though a
            non-`.inp` gate contradicted acyclicity. IT DOES NOT — those branches ARE the
            theorem. It failed to elaborate, which is the good ending.
attempt 2   `inpNumberedFrom` carried as the induction hypothesis. It STOPS RECURSING at the
            first non-`.inp` gate, so after one ordinary gate it says nothing about the tail.
            ⇒ `inpAtPos` below exists because of this.
attempt 3   13 errors → 8. The content was right; the plumbing was not. Its three cures are
            recorded below and all three were paid exactly once.
```
-/

#audit_axioms getD_append_lt getD_append_eq

/-! ### THE INDUCTION-CARRYING FORM OF THE `.inp` CONDITION

⛔ `inpNumberedFrom` STOPS RECURSING at the first non-`.inp` gate — correct for `bridgeable`
(which only cares about the leading run) and USELESS as an induction hypothesis, because after
one ordinary gate it says nothing about the tail. The induction needs the condition at EVERY
position, so it gets its own predicate. *Found by trying to carry the wrong one.* -/

def inpAtPos : Nat → List SaltWorks.Silicon.Gate → Bool
  | _, []            => true
  | k, .inp i :: gs  => (i == k) && inpAtPos (k+1) gs
  | k, _ :: gs       => inpAtPos (k+1) gs

theorem dmemAddr8_inpAtPos : inpAtPos 0 dmemAddr8NL = true := by decide +kernel
theorem demo_inpAtPos : inpAtPos 0 demoNL = true := by decide +kernel

/-! ### 🔑 THE THREE CURES, PAID ONCE EACH — the plumbing findings from attempt 3

**Recorded as findings, not as scar tissue: each one is a general fact about proving over two
list-indexed semantics, and the landed proof below uses all three.**

**① `simp` NORMALISES `getD` OUT FROM UNDER THE HYPOTHESIS.** In the operand branches the goal
becomes `senv[a]?.getD false` while `h2` is stated with `List.getD`, so it no longer matches
syntactically. **Cure: `show` the reduced form and `rw [h2 …]`; never `simp` with `h2` in the set.**

**② `simp` HITS MAXIMUM RECURSION DEPTH unfolding `runP` and `bridgeGatesFrom`.** Both are
recursive on the netlist, and handing them to `simp` as unfolding lemmas diverges. **Cure: a
`show` of the one-step-reduced form — not a bigger `maxRecDepth`.** *The landed proof contains no
`simp` over either definition; every step case is a `show`.*

**③ A `subst` TRAP.** With `h1 : senv.length = k`, rewriting `← h1` to reach `getD_append_eq`
turns *every* `k` into `senv.length`, including the one another hypothesis is stated about.
**Cure: rewrite inside a `have` whose statement is already about the index in hand.** *In the
landed proof this is confined to `step2`, which is the only place the appended slot is read.*

⭐ **AND A FOURTH, FOUND IN THE LANDING RATHER THAN INHERITED: an `rw` whose side condition is
`by omega` elaborates that `omega` BEFORE the rewrite has fixed the index metavariable.** Cure:
bind the side condition to a named `have` first. *Cheap, invisible, and it costs a whole build.*
-/

#audit_axioms inpAtPos dmemAddr8_inpAtPos demo_inpAtPos

/-! ## ⭐⭐⭐ THE INDUCTION — LANDED 2026-08-27

Everything above this line was scaffolding for the theorem below. -/

/-- Clause ②, re-established across one appended slot. The appended value is the SAME on
both sides, which is what lets all six constructors share this step. -/
private theorem step2 {k : Nat} {senv : List Bool} {henv : Env} (v : Bool)
    (h1 : senv.length = k)
    (h2 : ∀ j, j < k → senv.getD j false = henv j) :
    ∀ j, j < k + 1 → (senv ++ [v]).getD j false = upd henv k v j := by
  intro j hj
  rcases Nat.lt_or_ge j k with h | h
  · have hlt : j < senv.length := by omega
    have hne : j ≠ k := by omega
    rw [getD_append_lt senv v false hlt, h2 j h, upd_of_ne v hne]
  · have hjk : j = k := by omega
    rw [hjk, upd_self, ← h1]
    exact getD_append_eq senv v false

/-- Clause ③, re-established across the update at `k`. -/
private theorem step3 {ins : Env} {k : Nat} {henv : Env} (v : Bool)
    (h3 : ∀ j, k ≤ j → henv j = ins j) :
    ∀ j, k + 1 ≤ j → upd henv k v j = ins j := by
  intro j hj
  have hne : j ≠ k := by omega
  rw [upd_of_ne v hne]
  exact h3 j (by omega)

/-- ⭐⭐ **THE BRIDGE INDUCTION.** -/
theorem bridge_agrees (ins : Env) :
    ∀ (nl : List SaltWorks.Silicon.Gate) (k : Nat) (senv : List Bool) (henv : Env),
      senv.length = k →
      (∀ j, j < k → senv.getD j false = henv j) →
      (∀ j, k ≤ j → henv j = ins j) →
      inpAtPos k nl = true →
      acyclicFrom k nl = true →
      ∀ j, j < k + nl.length →
        (SaltWorks.Silicon.runP ins senv nl).getD j false
          = run henv (bridgeGatesFrom k nl) j := by
  intro nl
  induction nl with
  | nil =>
    intro k senv henv _ h2 _ _ _ j hj
    show senv.getD j false = henv j
    exact h2 j (by simpa using hj)
  | cons g gs ih =>
    intro k senv henv h1 h2 h3 hinp hacy j hj
    have hjlen : j < (k + 1) + gs.length := by
      simp only [List.length_cons] at hj; omega
    cases g with
    | inp i =>
      have hinp2 : ((i == k) && inpAtPos (k + 1) gs) = true := hinp
      rw [Bool.and_eq_true, beq_iff_eq] at hinp2
      have hacy' : acyclicFrom (k + 1) gs = true := hacy
      have hstep := ih (k + 1) (senv ++ [ins i]) (upd henv k (ins i))
        (by simp [h1]) (step2 (ins i) h1 h2) (step3 (ins i) h3) hinp2.2 hacy' j hjlen
      have hcongr : ∀ n, upd henv k (ins i) n = henv n := by
        intro n
        by_cases hn : n = k
        · rw [hn, upd_self, hinp2.1]
          exact (h3 k (Nat.le_refl k)).symm
        · exact upd_of_ne _ hn
      show (SaltWorks.Silicon.runP ins (senv ++ [ins i]) gs).getD j false
          = run henv (bridgeGatesFrom (k + 1) gs) j
      rw [hstep]
      exact run_congr _ hcongr j
    | const b =>
      have hinp' : inpAtPos (k + 1) gs = true := hinp
      have hacy' : acyclicFrom (k + 1) gs = true := hacy
      show (SaltWorks.Silicon.runP ins (senv ++ [b]) gs).getD j false
          = run (upd henv k b) (bridgeGatesFrom (k + 1) gs) j
      exact ih (k + 1) (senv ++ [b]) (upd henv k b)
        (by simp [h1]) (step2 b h1 h2) (step3 b h3) hinp' hacy' j hjlen
    | not a =>
      have hinp' : inpAtPos (k + 1) gs = true := hinp
      have hacy2 : (opndsLt k (SaltWorks.Silicon.Gate.not a) && acyclicFrom (k + 1) gs) = true :=
        hacy
      rw [Bool.and_eq_true] at hacy2
      have ha : a < k := by simpa [opndsLt] using hacy2.1
      show (SaltWorks.Silicon.runP ins (senv ++ [!(senv.getD a false)]) gs).getD j false
          = run (upd henv k (!(henv a))) (bridgeGatesFrom (k + 1) gs) j
      rw [h2 a ha]
      exact ih (k + 1) (senv ++ [!(henv a)]) (upd henv k (!(henv a)))
        (by simp [h1]) (step2 _ h1 h2) (step3 _ h3) hinp' hacy2.2 j hjlen
    | and a b =>
      have hinp' : inpAtPos (k + 1) gs = true := hinp
      have hacy2 : (opndsLt k (SaltWorks.Silicon.Gate.and a b) && acyclicFrom (k + 1) gs) = true :=
        hacy
      rw [Bool.and_eq_true] at hacy2
      have hab : a < k ∧ b < k := by simpa [opndsLt] using hacy2.1
      show (SaltWorks.Silicon.runP ins
              (senv ++ [(senv.getD a false) && (senv.getD b false)]) gs).getD j false
          = run (upd henv k ((henv a) && (henv b))) (bridgeGatesFrom (k + 1) gs) j
      rw [h2 a hab.1, h2 b hab.2]
      exact ih (k + 1) (senv ++ [(henv a) && (henv b)]) (upd henv k ((henv a) && (henv b)))
        (by simp [h1]) (step2 _ h1 h2) (step3 _ h3) hinp' hacy2.2 j hjlen
    | or a b =>
      have hinp' : inpAtPos (k + 1) gs = true := hinp
      have hacy2 : (opndsLt k (SaltWorks.Silicon.Gate.or a b) && acyclicFrom (k + 1) gs) = true :=
        hacy
      rw [Bool.and_eq_true] at hacy2
      have hab : a < k ∧ b < k := by simpa [opndsLt] using hacy2.1
      show (SaltWorks.Silicon.runP ins
              (senv ++ [(senv.getD a false) || (senv.getD b false)]) gs).getD j false
          = run (upd henv k ((henv a) || (henv b))) (bridgeGatesFrom (k + 1) gs) j
      rw [h2 a hab.1, h2 b hab.2]
      exact ih (k + 1) (senv ++ [(henv a) || (henv b)]) (upd henv k ((henv a) || (henv b)))
        (by simp [h1]) (step2 _ h1 h2) (step3 _ h3) hinp' hacy2.2 j hjlen
    | xor a b =>
      have hinp' : inpAtPos (k + 1) gs = true := hinp
      have hacy2 : (opndsLt k (SaltWorks.Silicon.Gate.xor a b) && acyclicFrom (k + 1) gs) = true :=
        hacy
      rw [Bool.and_eq_true] at hacy2
      have hab : a < k ∧ b < k := by simpa [opndsLt] using hacy2.1
      show (SaltWorks.Silicon.runP ins
              (senv ++ [(senv.getD a false) ^^ (senv.getD b false)]) gs).getD j false
          = run (upd henv k ((henv a) ^^ (henv b))) (bridgeGatesFrom (k + 1) gs) j
      rw [h2 a hab.1, h2 b hab.2]
      exact ih (k + 1) (senv ++ [(henv a) ^^ (henv b)]) (upd henv k ((henv a) ^^ (henv b)))
        (by simp [h1]) (step2 _ h1 h2) (step3 _ h3) hinp' hacy2.2 j hjlen

/-- ⭐⭐⭐ **THE COMMISSION: `sem (bridge nl outs) = runP`.** -/
theorem bridge_sem_eq (nl : List SaltWorks.Silicon.Gate) (outs : List Net) (ins : Env)
    (hinp : inpAtPos 0 nl = true) (hacy : acyclicFrom 0 nl = true)
    (ho : ∀ k ∈ outs, k < nl.length) :
    sem (bridge nl outs) ins
      = outs.map (fun k => (SaltWorks.Silicon.runP ins [] nl).getD k false) := by
  show outs.map (run ins (bridgeGatesFrom 0 nl)) = outs.map _
  refine List.map_congr_left (fun k hk => ?_)
  exact (bridge_agrees ins nl 0 [] ins rfl
    (fun j hj => absurd hj (Nat.not_lt_zero j)) (fun _ _ => rfl) hinp hacy k
    (by simpa using ho k hk)).symm

/-! ## ⛔ CLOSING THE GATE-vs-PRECONDITION GAP

`bridge` REFUSES on `bridgeable`. The theorem above DEMANDS `inpAtPos`. Those are different
predicates, and until they are joined a caller can satisfy the gate the code checks and NOT the
hypothesis the correctness theorem needs — a dangling interface INSIDE one file. -/

/-- A gate list with no `.inp` at all is `inpAtPos` at every offset. -/
private theorem inpAtPos_of_noInp :
    ∀ (gs : List SaltWorks.Silicon.Gate) (k : Nat),
      (gs.all fun g => match g with | .inp _ => false | _ => true) = true →
      inpAtPos k gs = true := by
  intro gs
  induction gs with
  | nil => intro k _; rfl
  | cons g gs ih =>
    intro k h
    rw [List.all_cons, Bool.and_eq_true] at h
    cases g with
    | inp i => simp at h
    | const b => exact ih (k + 1) h.2
    | not a => exact ih (k + 1) h.2
    | and a b => exact ih (k + 1) h.2
    | or a b => exact ih (k + 1) h.2
    | xor a b => exact ih (k + 1) h.2

private theorem inpNumbered_noLate_inpAtPos :
    ∀ (nl : List SaltWorks.Silicon.Gate) (k : Nat),
      inpNumberedFrom k nl = true → noLateInp nl = true → inpAtPos k nl = true := by
  intro nl
  induction nl with
  | nil => intro k _ _; rfl
  | cons g gs ih =>
    intro k h1 h2
    cases g with
    | inp i =>
      have h1' : ((i == k) && inpNumberedFrom (k + 1) gs) = true := h1
      rw [Bool.and_eq_true] at h1'
      show ((i == k) && inpAtPos (k + 1) gs) = true
      rw [Bool.and_eq_true]
      exact ⟨h1'.1, ih (k + 1) h1'.2 h2⟩
    | const b => exact inpAtPos_of_noInp gs (k + 1) h2
    | not a => exact inpAtPos_of_noInp gs (k + 1) h2
    | and a b => exact inpAtPos_of_noInp gs (k + 1) h2
    | or a b => exact inpAtPos_of_noInp gs (k + 1) h2
    | xor a b => exact inpAtPos_of_noInp gs (k + 1) h2

/-- ⭐ **THE GATE IMPLIES THE PRECONDITION.** -/
theorem bridgeable_inpAtPos {nl : List SaltWorks.Silicon.Gate} (h : bridgeable nl = true) :
    inpAtPos 0 nl = true := by
  simp only [bridgeable, Bool.and_eq_true] at h
  exact inpNumbered_noLate_inpAtPos nl 0 h.1 h.2

/-- ⭐⭐⭐ **THE COMMISSION, STATED OVER THE TWO PREDICATES THE CODE ACTUALLY CHECKS.** -/
theorem bridge_sem_eq_of_bridgeable (nl : List SaltWorks.Silicon.Gate) (outs : List Net) (ins : Env)
    (hb : bridgeable nl = true) (hacy : acyclicFrom 0 nl = true)
    (ho : ∀ k ∈ outs, k < nl.length) :
    sem (bridge nl outs) ins
      = outs.map (fun k => (SaltWorks.Silicon.runP ins [] nl).getD k false) :=
  bridge_sem_eq nl outs ins (bridgeable_inpAtPos hb) hacy ho

/-! ## ⭐ THE GENERAL THEOREM RE-DERIVES THE LANDED WITNESS — and strictly beats it

`demo_sem_agrees` quantifies over FOUR input configurations by `decide +kernel`. This derives the
same agreement for EVERY `Env`, from the general theorem, consuming only the two decidable facts
already landed. *A general theorem that cannot reproduce the witness it was built beside has
proved something else.* -/
theorem demo_sem_agrees_general (ins : Env) :
    sem (bridge demoNL demoOuts) ins
      = demoOuts.map (fun k => (SaltWorks.Silicon.runP ins [] demoNL).getD k false) :=
  bridge_sem_eq_of_bridgeable _ _ ins demo_bridgeable demo_acyclic (by decide +kernel)

/-- ⭐⭐ **THE CUSTOMER: the landed D1b address checker.** -/
theorem dmemAddr8_sem_eq (ins : Env) :
    sem (bridge dmemAddr8NL dmemAddr8NL_outs) ins
      = dmemAddr8NL_outs.map
          (fun k => (SaltWorks.Silicon.runP ins [] dmemAddr8NL).getD k false) :=
  bridge_sem_eq_of_bridgeable _ _ ins dmemAddr8_bridgeable dmemAddr8_acyclic (by decide +kernel)

/-! ## ⛔ THE CONTROL — acyclicity is load-bearing IN THIS THEOREM, not merely discriminating

The file already shows `acyclicFrom` REFUSES a forward reference. That proves the PREDICATE
discriminates; it does NOT prove my theorem needs it. **A hypothesis can be true, scoped, and
decorative.** So: a netlist that PASSES `bridgeable` and FAILS `acyclicFrom`, on which the
conclusion is FALSE. If this ever becomes provable, `bridge_sem_eq` is unsound. -/

def fwdNL : List SaltWorks.Silicon.Gate := [.inp 0, .and 0 2, .const true]

theorem fwdNL_bridgeable : bridgeable fwdNL = true := by decide +kernel
theorem fwdNL_not_acyclic : acyclicFrom 0 fwdNL = false := by decide +kernel

/-- ⛔ **DROP ACYCLICITY AND THE CONCLUSION IS FALSE.** `runP` reads net 2 before it exists and
gets `false`; `run` reads it out of the total input env and gets `true`. -/
theorem fwd_disagrees :
    sem (bridge fwdNL [1]) (fun _ => true)
      ≠ [1].map (fun k => (SaltWorks.Silicon.runP (fun _ => true) [] fwdNL).getD k false) := by
  decide +kernel

#audit_axioms fwdNL fwdNL_bridgeable fwdNL_not_acyclic fwd_disagrees
#audit_axioms step2 step3 bridge_agrees bridge_sem_eq
#audit_axioms inpAtPos_of_noInp inpNumbered_noLate_inpAtPos bridgeable_inpAtPos
#audit_axioms bridge_sem_eq_of_bridgeable demo_sem_agrees_general dmemAddr8_sem_eq

end SaltWorks.HDL.NetlistBridge
