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

⚠️ **WHAT THIS FILE DOES AND DOES NOT CLAIM.** It builds the map and pins the concrete facts
for `dmemAddr8NL` by `decide +kernel`. **It does NOT yet prove semantic agreement**
(`sem (bridge nl outs) ≡ runP`). Until that theorem exists a bridged circuit's behaviour is
asserted by construction, and `instOK` would pass while the wired thing might compute
something else — the same shape `coreShapedD` is fenced for. **The bridge is therefore NOT
yet fit to place into the assembly, and this file says so rather than leaving it implied.**
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

#audit_axioms opOf bridgeGatesFrom inpPrefix bridgeable bridge
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

/-! ### ⛔ THE REMAINING OBLIGATION — attempted 2026-08-26 16:4x, DID NOT GO

**`bridge_agrees` is NOT here, and this block is the record of why rather than a silence.**

```
theorem bridge_agrees (ins : Env) :
  ∀ nl k senv henv,
    senv.length = k →
    (∀ j, j < k → senv.getD j false = henv j) →
    (∀ j, k ≤ j → henv j = ins j) →
    inpNumberedFrom k nl = true →
    acyclicFrom k nl = true →
    ∀ j, j < k + nl.length →
      (Silicon.runP ins senv nl).getD j false = run henv (bridgeGatesFrom k nl) j
```
**WHAT WENT THROUGH:** the `nil` case, and the `.inp` case whole — including the step that
needs ③, where the appended slot `senv.getD k` must equal `henv k` and the only route is
`henv k = ins k` because HDL emitted no gate there.
⛔ **WHERE IT BROKE:** the FIVE remaining constructors. `cases g` needs each alternative
supplied — a `| _ =>` catch-all is rejected — and each one carries the real content, not
bookkeeping: for `.not a` one must show `!(senv.getD a false) = !(henv a)`, which needs `a < k`
out of `acyclicFrom` and then ②, and `.and/.or/.xor` need it twice. Then the step case must
re-establish ② and ③ across `upd henv k v`, where ② splits at `j < k` (via `upd_of_ne`) and
`j = k` (via `upd_self`).
📌 **AND MY FIRST ATTEMPT WAS WRONG IN A WAY WORTH RECORDING:** I discharged those five
branches with `exact absurd hacy …`, as though a non-`.inp` gate contradicted acyclicity. **It
does not — those branches ARE the theorem.** *A placeholder that type-checks in the author's
head is how a proof of nothing gets written; it failed to elaborate, which is the good ending.*
⇒ **The work is five constructor branches over `getD_append_lt`, `upd_of_ne` and `upd_self`.
The two `getD` lemmas below are landed and are what those branches consume.**
-/

#audit_axioms getD_append_lt getD_append_eq

end SaltWorks.HDL.NetlistBridge
