/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Certs
import SaltWorks.Banyan.SelfRouting

/-!
# T4 — the Banyan fabric as a `Circ`

This is the file that ties leg 2 to leg 3a: the fabric that
`SaltWorks.Banyan.banyan_selfrouting` reasons about, built as an actual circuit
in the compiler's own source language, so the routing theorem and the emitted
hardware are statements about the same object.

## Why T4 could not be stated as the freeze wrote it

`docs/hdl-design-v1.md:25-26` asked for "`banyan_circ` … + proof its `sem`
realizes `line`-routing". That is unstateable: `sem` exposes only the **primary
outputs**, which is stage boundary `m = 0`, and `line 0 s d = d` holds for every
`s` and every `dest` with no hypotheses at all. So T4 is stated here against the
**stage structure** — the fabric is a chain of stages, and stage `m` is exactly
the circuit that moves a packet from line `line (m+1) s d` to `line m s d`,
resolving bit `m` of the line index. That is `SaltWorks.Banyan.step_line`, in
gates.

## ⚠️ The first version of this file was WRONG, and the certificate caught it

The element was built the way `SaltWorks/Silicon/RTL/bitserial_switch.v` builds
it — one control bit, both outputs derived from it — and `fabric3_routes` was
proved **FALSE** by `decide +kernel`. The cause is the same defect this seat
reported against that RTL earlier today: with one control bit an element cannot
distinguish an idle port from a port whose destination bit is 0, so an active
packet meeting an idle partner is dropped. `banyan_selfrouting` does not exclude
this — `no_conflict` is `Set.InjOn` over `Set.Iio n`, constraining the **active**
lines only, and concentrated sources are precisely what makes idle ports appear
at interior stages.

The repair is `docs/hdl-frame-protocol-v1.md` §4: **each port gets its own claim
signals**, so an output is driven only by a port that actually holds a packet
bound for it, and an unclaimed output reads 0 (idle). Both are recorded here
because "the certificate caught the designer's own instance of the bug he had
just reported elsewhere" is worth more as a datum than a clean file would be.
-/

namespace SaltWorks.HDL

open SaltWorks.Banyan

/-! ## The output multiplexer

One output of a 2×2 element. `s₀`/`s₁` are the two input ports' *claims* on this
output: port `i` drives it exactly when it holds an active packet routed here.
An unclaimed output reads `false`, which is the idle convention. -/
def pick (s₀ s₁ a b base : Net) : List Gate :=
  [ ⟨base,     .and s₀ a⟩
  , ⟨base + 1, .and s₁ b⟩
  , ⟨base + 2, .or base (base + 1)⟩ ]

/-- **The multiplexer computes a claim-gated select**, proved generically for any
nets strictly below `base`. Under the no-conflict hypothesis at most one claim is
true, so this is a selection; with neither claim it is `false`, i.e. idle. -/
theorem pick_spec (env : Env) (s₀ s₁ a b base : Net)
    (h₀ : s₀ < base) (h₁ : s₁ < base) (ha : a < base) (hb : b < base) :
    run env (pick s₀ s₁ a b base) (base + 2)
      = ((env s₀ && env a) || (env s₁ && env b)) := by
  -- NB: `omega` reports "no usable constraints" on these — it does not pick up
  -- `<` facts whose operands are typed `Net` rather than `Nat`, even though
  -- `Net` is an `abbrev`. Explicit terms instead.
  have e₀ : s₀ ≠ base := Nat.ne_of_lt h₀
  have e₁ : s₁ ≠ base := Nat.ne_of_lt h₁
  have ea : a ≠ base := Nat.ne_of_lt ha
  have eb : b ≠ base := Nat.ne_of_lt hb
  have eb1 : b ≠ base + 1 := Nat.ne_of_lt (Nat.lt_succ_of_lt hb)
  simp [pick, run, upd, Op.eval, e₀, e₁, ea, eb, eb1]

/-- A 2×2 element: two claim-gated outputs. Six gates from `base`; the low-line
output is `base+2` and the high-line output is `base+5`. -/
def element (s₀lo s₁lo s₀hi s₁hi a b base : Net) : List Gate :=
  pick s₀lo s₁lo a b base ++ pick s₀hi s₁hi a b (base + 3)

/-! ## The fabric, parametric in k -/

/-- The low line of element `e` at stage `m`: insert a `0` bit at position `m`. -/
def lowLine (m e : Net) : Net := (e / 2 ^ m) * 2 ^ (m + 1) + e % 2 ^ m

/-- The element index handling line `l` at stage `m`: delete bit `m`. -/
def elemIdx (m l : Net) : Net := (l / 2 ^ (m + 1)) * 2 ^ m + l % 2 ^ m

/-- One stage's gates: one element per pair of lines, four control nets each. -/
def stageGates (m : Net) (cur ctl : List Net) (base : Net) (half : Nat) : List Gate :=
  (List.range half).flatMap fun e =>
    element (ctl.getD (4 * e) 0) (ctl.getD (4 * e + 1) 0)
      (ctl.getD (4 * e + 2) 0) (ctl.getD (4 * e + 3) 0)
      (cur.getD (lowLine m e) 0) (cur.getD (lowLine m e + 2 ^ m) 0) (base + 6 * e)

/-- After a stage, line `l`'s data lives at this net. -/
def stageOuts (m base : Net) (N : Nat) : List Net :=
  (List.range N).map fun l => base + 6 * elemIdx m l + (if l.testBit m then 5 else 2)

/-- Chain the stages, descending. -/
def stagesFrom (k : Nat) : Nat → List Net → List Net → Net → (List Gate × List Net)
  | _, [],      cur, _    => ([], cur)
  | i, m :: ms, cur, base =>
    let half := 2 ^ (k - 1)
    let ctl := (List.range (4 * half)).map fun t => 2 ^ k + 4 * half * i + t
    let gs := stageGates m cur ctl base half
    let cur' := stageOuts m base (2 ^ k)
    let (gs', cur'') := stagesFrom k (i + 1) ms cur' (base + 6 * half)
    (gs ++ gs', cur'')

/-- **The banyan fabric as a `Circ`**, parametric in `k`. Nets `0 ..< 2^k` are the
input data lines; the next `4 · k · 2^(k-1)` are the per-port claim signals; the
gates follow. Stages descend `k-1 … 0`, so the first stage resolves the
destination's most significant bit — the 1988 frame's wire order. -/
def fabric (k : Nat) : Circ :=
  let N := 2 ^ k
  let half := 2 ^ (k - 1)
  let base := N + 4 * half * k
  let (gs, cur) := stagesFrom k 0 ((List.range k).map fun i => k - 1 - i) (List.range N) base
  { nIn := base, gates := gs, outs := cur }

/-! ## k = 3 — the 8×8 fabric, 72 gates -/

theorem fabric3_shape :
    (fabric 3).nIn = 56 ∧ (fabric 3).gates.length = 72 ∧ (fabric 3).outs.length = 8 := by
  decide +kernel

theorem fabric3_wf : (fabric 3).wf = true := by decide +kernel

/-! ## Tying the gates to `line` -/

/-- The source occupying line `l` at stage boundary `m`, among `n` active
sources. This is `SaltWorks.Banyan.line` used as the addressing function it is. -/
def srcAt (n m l : Nat) (dest : Nat → Nat) : Option Nat :=
  (List.range n).find? fun s => line m s (dest s) == l

/-- Port `p`'s claim on output half `hi` for element `e` at stage `m`: the port
holds an active packet (`srcAt` finds a source) whose destination bit `m`
selects that half. **An idle port claims nothing** — the defect the first version
of this file reproduced. -/
def claim (n m e : Nat) (dest : Nat → Nat) (highPort hi : Bool) : Bool :=
  let l := if highPort then lowLine m e + 2 ^ m else lowLine m e
  match srcAt n (m + 1) l dest with
  | some s => (dest s).testBit m == hi
  | none   => false

/-- The input valuation: a one-hot pulse on source `s₀`'s line, and the claim
signals `dest` demands. -/
def fabricEnv (n : Nat) (dest : Nat → Nat) (s₀ : Nat) : Env := fun j =>
  if j < 8 then j == line 3 s₀ (dest s₀)
  else if j < 56 then
    let idx := j - 8
    let e := idx / 4 % 4
    let i := idx / 16
    let slot := idx % 4
    claim n (2 - i) e dest (slot == 1 || slot == 3) (slot == 2 || slot == 3)
  else false

/-- Four active sources bound for outputs 1, 3, 4, 6 — strictly monotone, so
`banyan_selfrouting` applies, and only half the ports are active, so every
interior stage has idle ports. -/
def dest4 : Nat → Nat
  | 0 => 1
  | 1 => 3
  | 2 => 4
  | _ => 6

/-- **The routing certificate.** Every active source's pulse emerges on the
output line its destination names, with the claims computed from `line` and
nothing else. -/
theorem fabric3_routes :
    [0, 1, 2, 3].all (fun s =>
      (sem (fabric 3) (fabricEnv 4 dest4 s)).getD (dest4 s) false) = true := by
  decide +kernel

/-- …and it is *routing*, not mere reachability: nothing appears anywhere else. -/
theorem fabric3_no_crosstalk :
    [0, 1, 2, 3].all (fun s =>
      ((List.range 8).filter (fun o =>
        (sem (fabric 3) (fabricEnv 4 dest4 s)).getD o false)) == [dest4 s]) = true := by
  decide +kernel

/-- A MUTATION CONTROL: corrupt one claim signal and the routing must break, or
the certificate is not testing the claims at all. -/
theorem fabric3_claims_matter :
    ¬ ((sem (fabric 3) (fun j => if j = 8 then !(fabricEnv 4 dest4 0 8)
                                 else fabricEnv 4 dest4 0 j)).getD (dest4 0) false = true) := by
  decide +kernel

#audit_axioms pick_spec
#audit_axioms fabric3_shape fabric3_wf
#audit_axioms fabric3_routes fabric3_no_crosstalk fabric3_claims_matter

end SaltWorks.HDL
