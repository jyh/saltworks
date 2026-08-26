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

end SaltWorks.HDL.NetlistBridge
