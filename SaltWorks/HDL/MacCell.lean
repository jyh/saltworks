import SaltWorks.HDL.Seq
import SaltWorks.HDL.Compose
import SaltWorks.HDL.Adder
-- for `adEnv` and `sem_adder32_gen`, the adder's landed certificate (math's slot).
import SaltWorks.Stack.Program

/-! # `macSeq` — THE MAC CELL AS A KERNEL `Seq`

**Ruled** (maestro, 2026-08-09 13:38, the CELL WAVE): *"compiler builds `macSeq` (the cell as
kernel `Seq`/`Circ`, after rows 15-16); math lands `macRun ≈ runTrace macSeq` against their own
`mac_correct`."* Rows 15–16 landed at `5f1abb7`, so this is the bridge node opening.

## WHAT THIS CELL IS, AND — read this first — WHAT IT IS NOT

`docs/mac-induction-scope-v1.md` §E is the binding spec and it decides the interface:

* *"the bias is **not a parallel preload**; it **streams as the first addend**, one cycle, **zero
  gates**"* (§E:187) — so the bias must arrive through the same adder as everything else, costing
  nothing extra. That is only possible if the cell's primary input **is the addend**.
* *"`acc_after t` read out of the **state component** of `runTrace`"* (§B2:72) — so the accumulator
  is the `Seq`'s state, and the cycle index is the trace length.

⇒ ***`macSeq` IS A 32-BIT ACCUMULATOR: one 32-bit addend in per cycle, `acc' = acc + addend`.***
It matches `MacInduction.macAfter`'s recursion term-for-term — `macAfter (t+2) = macAfter (t+1) +
(if x t then W * 2 ^ t else 0)` is exactly one cycle of this cell with that addend presented.

⛔ **WHAT IS *OUTSIDE* THIS CELL, STATED SO NOBODY READS `macSeq` AS "THE MULTIPLIER":**

```
   the 2^t weighting of W        NOT HERE — the caller presents W·2^t as the addend
   the AND with the stream bit   NOT HERE — the caller presents 0 when x_t is false
   the sign cycle's SUBTRACTION  NOT HERE — macFinal subtracts; this cell only ADDS
   the int8 -> 32 sign-extend    NOT HERE — MacInduction.signExtend_toInt is the ingress row
```

*Those four are real hardware and somebody owns them. If the ruling intends the cell to own the
shift register and the AND, that is a SECOND `Seq` and a different bridge theorem — my read of §E is
that it does not, because a preload-free bias forces the addend interface. **Flagged rather than
assumed**: the interface between my artifact and math's `macRun` IS the design decision, and this
paragraph is where a reader disagrees with me.*

## THE ONE GATE THIS CELL ADDS OF ITS OWN

`adder32.nIn = 65` and net `64` is a real carry-in **port**, so something below the instance has to
hold `false`. That is the `pcAdd` precedent (`Program.lean:4240-4243`) and the core assembly's row-0
tie cells: a constant is not decoration, it is the only way an instantiated adder gets a carry-in.
-/

namespace SaltWorks.HDL.MacCell

open SaltWorks.HDL

/-! ### The layout -/

/-- The addend — the cell's PRIMARY input, nets `0…31`. Per §E this is where the bias arrives on
its one cycle, and where `W·2^t` arrives on the others. -/
def maAddend (k : Nat) : Net := k

/-- The accumulator — the cell's STATE, nets `32…63`. `Seq.env` puts primary inputs first and state
immediately after, so this offset is forced by `Seq`, not chosen. -/
def maAcc (k : Nat) : Net := 32 + k

/-- `nIn + nState` — what the CORE sees. Distinct from `macSeq.nIn`, and the distinction is the one
my own cell account (`docs/compiler-cell-account-0808.md:14`) says readers get wrong: *"the core's
`nIn` is the machine's `nIn` PLUS its `nState`"*. -/
def maCoreIn : Nat := 64

/-- The carry-in constant — this cell's single own gate. -/
def maZero : Net := 64

/-- Where the adder instance begins: one past the tie. -/
def maOff : Nat := 65

/-- ⭐ **THE WIRING. `a := the accumulator`, `b := the addend`, carry-in `:= 0`.**

`adder32`'s ports are `a` on `0…31`, `b` on `32…63`, `cin` at `64` (`Adder.lean:69-71`). The
assignment is not symmetric in meaning even though `+` is commutative: naming `a` the accumulator
keeps the cell readable as *accumulate*, and the state/primary split then falls out of `Seq.env`. -/
def maSigma (i : Nat) : Net :=
  if i < 32 then maAcc i else if i < 64 then maAddend (i - 32) else maZero

/-- The 32 sum nets of the instance, in the host's numbering. -/
def maSum (k : Nat) : Net := instMap adder32 maSigma maOff (adS k)

/-- ⭐⭐ **THE CORE.** One tie gate, one `adder32` instance. The output list is the sum **twice** —
`Seq` reads `outs.take nOut` as this cycle's outputs and `outs.drop nOut` as the next state, and for
an accumulator those are the same 32 nets. *Listing a net twice in `outs` is a projection, not a
second gate; the gate count below is the check on that.* -/
def macCore : Circ :=
  { nIn := maCoreIn
    gates := ⟨maZero, .const false⟩ :: instGates adder32 maSigma maOff
    outs := (List.range 32).map maSum ++ (List.range 32).map maSum }

/-- ⭐ **THE CELL.** -/
def macSeq : Seq := { nIn := 32, nOut := 32, nState := 32, core := macCore }

/-! ### The certificates -/

theorem macCore_ssa : macCore.ssa = true := by decide +kernel

/-- Through `Circ.wf_of_ssa`, not `decide` — `wf`'s `nodupB` is quadratic. -/
theorem macCore_wf : macCore.wf = true := Circ.wf_of_ssa macCore_ssa

/-- **The widths are consistent**: `core.nIn = nIn + nState` and
`core.outs.length = nOut + nState`. This is `Seq.wf`, and it is the obligation that catches an
accumulator whose state width does not match its adder. -/
theorem macSeq_wf : macSeq.wf = true := by decide +kernel

/-- **161 gates: 1 tie + 160 adder.** Measured, then pinned — the number in a docstring should come
from the build, not from the author. -/
theorem macCore_gate_count : macCore.gates.length = 161 := by decide +kernel

/-- **32 state bits, 32 outputs, 64 core inputs** — the cell account's four columns. -/
theorem macSeq_dimensions :
    macSeq.nIn = 32 ∧ macSeq.nOut = 32 ∧ macSeq.nState = 32 ∧ macSeq.core.nIn = 64 := by
  refine ⟨rfl, rfl, rfl, rfl⟩

/-- ⭐ **THE PLACEMENT IS SOUND: every adder port lands strictly below the instance.** The same
`instOK` obligation the core assembly discharges sixteen times. -/
theorem mac_instOK : instOK adder32 maSigma maOff := by
  refine ⟨adder32_ssa, adder32_wf, ?_⟩
  intro i hi
  have hnn : adder32.nIn = 65 := by decide +kernel
  rw [hnn] at hi
  revert hi; revert i
  decide +kernel

/-- ⛔ **THE COLLISION CHECK, ASSERTED RATHER THAN ASSUMED.** The tie gate at net `64` must not be
any adder gate's output. *`instOK` cannot see this — it constrains one instance against its own
inputs and says nothing about whether another gate already owns a net. Sixteen true `instOK`s over
a colliding netlist is a defect this corpus shipped and repaired today (`5f1abb7`), so the pair
property is stated here at the cell's birth instead of being discovered later.* -/
theorem tie_does_not_collide_with_the_adder :
    maZero ∉ (instGates adder32 maSigma maOff).map (·.out) := by
  decide +kernel

/-- **CONTROL: the two output halves are the SAME nets.** An accumulator whose readable output and
whose next state disagreed would compute one thing and report another — and `Seq.wf` would still
pass, because it only checks the LENGTH. -/
theorem output_equals_next_state :
    macCore.outs.take 32 = macCore.outs.drop 32 := by
  decide +kernel

/-- **CONTROL: the accumulator is `a` and the addend is `b`, not the reverse.** `+` is commutative
so this cannot change the arithmetic — it is stated because the *state/primary* split is not
commutative: swapping them would feed the addend where `Seq.env` supplies state. -/
theorem acc_is_the_a_port_and_addend_is_the_b_port :
    maSigma 0 = maAcc 0 ∧ maSigma 32 = maAddend 0 ∧ maSigma 64 = maZero := by
  refine ⟨rfl, rfl, rfl⟩

/-- **CONTROL: the carry-in is tied LOW.** Tied high would add one on every single cycle — an error
of `n+1` per MAC that no single-cycle test distinguishes from a rounding choice. -/
theorem carry_in_is_low : (⟨maZero, Op.const false⟩ : Gate) ∈ macCore.gates := by
  decide +kernel

/-! ### What is OWED, named with its owner

The per-cycle BitVec theorem — `stepSeq macSeq st inp = (bits of (acc + addend), same)` — is the
next lemma and it is the real bridge. Its shape is fixed by what already exists:

* `sem_adder32_gen` (`Program.lean:3147`) certifies `sem adder32 (adEnv a b cin)` as BitVec addition;
* `inst_sem` (`Compose.lean:397`) needs `hin : ∀ i < c.nIn, envN (σ i) = envC i`;
* the `hin` clause splits three ways here — the `a` port reads the state, the `b` port reads the
  primary inputs, and **the carry-in reads a GATE, not an input**, so it needs the frame argument
  over the one tie gate (`pcAdd`'s `hin_adder` does exactly this at its net `129`).

⇒ **NOT CLAIMED HERE: no semantics. This file certifies the cell's SHAPE — `ssa`, `wf`, widths,
placement, non-collision, and the four wiring controls. `macRun ≈ runTrace macSeq` is math's by the
ruling, and the per-cycle lemma above is the piece it will induct over.** *Stated as owed rather
than left to be inferred from the file's silence.*
-/

/-! ### LAYER 1 — THE PER-CYCLE LEMMA, IN `BitVec`, UNCONDITIONAL

**Math's layer ruling (13:46), accepted:** this stays in `BitVec` and carries **no overflow
hypothesis**. The `ℤ` reading — where `(a + b).toInt = a.toInt + b.toInt` is *false* on wrap — lives
in layer 2 with the no-wrap condition that already exists there.

⇒ ***"A HYPOTHESIS IN THE WRONG LAYER IS HOW A BOUND BECOMES FOLKLORE."*** *I was heading for an `ℤ`
statement, which would have dragged the MAC's overflow bound into a fact about XOR gates.*

**AND A SECOND DIVISION, mine to state:** the lemma below reduces one cycle of the cell to
**`adder32`'s own `run`** rather than to BitVec arithmetic. The instantiation bookkeeping — the σ
agreement and the frame over the tie gate — is the part only this seat can do, because only this file
knows the wiring. `sem_adder32_gen` is math's certificate in math's file, and layer 2 applies it
there. *Splitting at the artifact boundary rather than at the arithmetic one.*
-/

/-- The 32 bits of a word, LSB first — the `Seq` trace's representation of a datapath value.

⚠️ **NAME COLLISION, DOCUMENTED RATHER THAN RENAMED.** `SaltWorks.HDL.bitsOf` already exists
(`Sem.lean:180`) and means something **different**: `(j : Nat) : Env`, a test-bit *environment*. With
`open SaltWorks.HDL.MacCell` from outside, both are visible and an unqualified `bitsOf` is ambiguous
— I hit that myself in a scratch probe. **Consumers must qualify (`MacCell.bitsOf`), and math's
`MacBridge` already does.**

*Not renamed because math's landed rung 3 (`c754b29`) cites `MacCell.bitsOf` eight times: a rename is
a breaking change to another seat's proved theorem for a cosmetic gain
(`statement-shape-is-an-interface`). Flagged here so the next reader does not lose the minutes I
did.* -/
def bitsOf (w : BitVec 32) : List Bool := (List.range 32).map w.getLsbD

theorem bitsOf_length (w : BitVec 32) : (bitsOf w).length = 32 := by simp [bitsOf]

theorem bitsOf_getD (w : BitVec 32) (k : Nat) (hk : k < 32) :
    (bitsOf w).getD k false = w.getLsbD k := by
  simp only [bitsOf, List.getD_eq_getElem?_getD, List.getElem?_map, List.getElem?_range, hk,
             if_pos, Option.map_some, Option.getD_some]

/-- The cell's own gate list is exactly the tie, so the frame argument is a one-gate step. -/
theorem macCore_gates_split :
    macCore.gates = [⟨maZero, Op.const false⟩] ++ instGates adder32 maSigma maOff := rfl

/-- The tie gate drives its net to `false`. -/
theorem tie_runs_to_false (E : Env) :
    run E [(⟨maZero, Op.const false⟩ : Gate)] maZero = false := by
  simp [run, upd, Op.eval]

/-- …and disturbs nothing else. **This is the frame the carry-in arm needs**: `adder32`'s `cin` port
reads a GATE, not an input, which is the arm math flagged and the same shape as `pcAdd`'s
`hin_adder` at its net `129`. -/
theorem tie_frame (E : Env) (n : Net) (hn : n ≠ maZero) :
    run E [(⟨maZero, Op.const false⟩ : Gate)] n = E n := by
  simp [run, upd, Op.eval, hn]

/-- ⭐ **THE σ AGREEMENT — `inst_sem`'s `hin`, discharged in three arms.** The `a` port reads the
state, the `b` port reads the primary inputs, and the carry-in reads the tie GATE. -/
theorem mac_hin (acc addend : BitVec 32) :
    ∀ i, i < adder32.nIn →
      run (macSeq.env (bitsOf addend) (bitsOf acc)) [(⟨maZero, Op.const false⟩ : Gate)] (maSigma i)
        = SaltWorks.Stack.Program.adEnv acc addend false i := by
  intro i hi
  have h65 : adder32.nIn = 65 := by decide +kernel
  rw [h65] at hi
  by_cases h1 : i < 32
  · have hne : (32 + i : Nat) ≠ 64 := by omega
    rw [maSigma, if_pos h1, maAcc, tie_frame _ _ hne]
    simp only [Seq.env, macSeq, SaltWorks.Stack.Program.adEnv,
               if_neg (show ¬(32 + i < 32) by omega), if_pos h1, Nat.add_sub_cancel_left]
    exact bitsOf_getD acc i h1
  · by_cases h2 : i < 64
    · have hne : (i - 32 : Nat) ≠ 64 := by omega
      rw [maSigma, if_neg h1, if_pos h2, maAddend, tie_frame _ _ hne]
      simp only [Seq.env, macSeq, SaltWorks.Stack.Program.adEnv,
                 if_pos (show i - 32 < 32 by omega), if_neg h1, if_pos h2]
      exact bitsOf_getD addend (i - 32) (by omega)
    · have h64 : i = 64 := by omega
      subst h64
      rw [maSigma, if_neg h1, if_neg h2, tie_runs_to_false]
      simp only [SaltWorks.Stack.Program.adEnv, if_neg h1, if_neg h2]

/-- ⭐⭐ **LAYER 1, POINTWISE. Sum bit `k` of one cycle IS `adder32`'s sum bit `k`, run on the
adder's own environment.** No hypothesis, no `ℤ`, no overflow condition — and no re-derivation of
math's certificate: the right-hand side is the adder's `run`, so layer 2 applies
`sem_adder32_gen` in the file that owns it. -/
theorem step_bit_is_adder_bit (acc addend : BitVec 32) (k : Nat) (hk : k < 32) :
    run (macSeq.env (bitsOf addend) (bitsOf acc)) macCore.gates (maSum k)
      = run (SaltWorks.Stack.Program.adEnv acc addend false) adder32.gates (adS k) := by
  have hmem : (adder32.gates.map Gate.out).contains (adS k) = true := by
    revert hk; revert k; decide +kernel
  have h := inst_sem adder32 maSigma maOff
      (run (macSeq.env (bitsOf addend) (bitsOf acc)) [(⟨maZero, Op.const false⟩ : Gate)])
      (SaltWorks.Stack.Program.adEnv acc addend false) mac_instOK (mac_hin acc addend)
      (adS k) (Or.inr hmem)
  rw [macCore_gates_split, run_append, maSum]
  exact h

/-- **The output half and the state half of a cycle are the same bits** — so the pointwise lemma
above characterises both. *`Seq.wf` checks only the LENGTH of `outs`; this is the value claim.* -/
theorem step_halves_agree (st inp : List Bool) :
    (stepSeq macSeq st inp).1 = (stepSeq macSeq st inp).2 := by
  -- ⚠️ The obvious `simp only [..., macCore]` UNFOLDS `instGates adder32 …` — 160 gates — and the
  -- kernel times out. The proof needs only the SHAPE of `outs` (`A ++ A`), never the gates, so
  -- `run E macCore.gates` is kept OPAQUE throughout. *Same lesson as the offset chain: state it
  -- structurally and no artifact is ever evaluated.*
  have hdup : ∀ (l : List Bool) (n : Nat), l.length = n →
      (l ++ l).take n = l ∧ (l ++ l).drop n = l := by
    intro l n h; subst h; exact ⟨List.take_left, List.drop_left⟩
  have houts : macCore.outs = (List.range 32).map maSum ++ (List.range 32).map maSum := rfl
  have hmap : macCore.outs.map (run (macSeq.env inp st) macCore.gates)
      = ((List.range 32).map maSum).map (run (macSeq.env inp st) macCore.gates)
        ++ ((List.range 32).map maSum).map (run (macSeq.env inp st) macCore.gates) := by
    rw [houts, List.map_append]
  have hl : (((List.range 32).map maSum).map (run (macSeq.env inp st) macCore.gates)).length = 32 := by
    simp
  obtain ⟨ht, hd⟩ := hdup _ 32 hl
  -- ⚠️ do NOT put `macSeq` in the simp set: it expands to the anonymous structure literal
  -- `{ nIn := 32, … }` and then `macSeq.env` in the hypotheses no longer matches the goal
  -- syntactically. Project the two fields it needs instead, and leave the machine folded.
  have hcore : macSeq.core = macCore := rfl
  have hnout : macSeq.nOut = 32 := rfl
  simp only [stepSeq, sem, hcore, hnout]
  rw [hmap, ht, hd]

/-! ### What layer 2 receives, stated plainly

`step_bit_is_adder_bit` + `step_halves_agree` say: **one cycle of `macSeq` computes, bit for bit,
what `adder32` computes on `(acc, addend, cin = 0)`, and stores it as the next state.** Composing
that with `sem_adder32_gen` (math's file) gives `acc' = acc + addend` in `BitVec 32`; composing THAT
with the no-wrap hypothesis gives the `ℤ` statement `macAfter` needs. **Three steps, three owners, and
the overflow condition appears only in the third.**
-/

/-! ## THE WEIGHT-SHIFT ORGAN — the cell's second `Seq`

**Ruled** (maestro 13:46): *"the 2^t weighting + AND with x_t = the WEIGHT-SHIFT ORGAN, a second
small `Seq` (`W_reg` shifting left per cycle + the AND row) — yours as the next increment."* This is
the organ `macSeq`'s docstring named as OUTSIDE the accumulator, now built rather than deferred.

It supplies exactly the addend `macAfter` asks for:

```
   macAfter (t+2) = macAfter (t+1) + (if x t then W * 2^t else 0)
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^ THIS organ's output
   state  W_i << t   (32 bits)      input  x_t (ONE bit)      output  the addend (32 bits)
```

⚠️ **`W_i`, NOT `W` — THE STATE IS THE *CURRENT INPUT'S* WEIGHT** (dual-stream ruling, maestro
2026-08-09 14:24: per-input weights, unbounded fan-in; weight-stationary is now the CNN *special
case*). **This organ has NO LOAD PATH and needs none** — measured: `nIn = 1` (the stream bit alone),
`wsCore.nIn = 33 = 1 + 32` so there is no spare port, and no next-state net is the stream-bit net,
i.e. *the next state is a function of state alone*. Re-loading happens through **`runTrace`'s initial
state**, which `Seq.lean:41-44` provides as an argument precisely because power-gating bans reset
assumptions. Each input is a fresh `runTrace` starting at `W_i`.

⛔ ***AND THE COMPOSITION MUST GIVE THE TWO ORGANS OPPOSITE STATE DISCIPLINE: the accumulator's state
PERSISTS across inputs (it is accumulating the sum); this organ's state RE-INITIALISES per input.***
*Running both under one `runTrace` from one initial state typechecks and places cleanly, and is wrong
in one of two ways — it either freezes `W` across inputs (weight-stationary, the special case) or
resets the accumulator every input (destroying the dot product). **The first composition hazard in
this file that is about TIME rather than NETS: no wire is wrong in either mistake, only which state
crosses which trace boundary.*** The theorems below are `∀ w` and are unaffected by the ruling; this
paragraph exists because the *framing* is what a reader carries into the design package.

⭐ **THE SHIFT COSTS NO GATES — it is pure rewiring.** `outs` may name input nets directly, so the
next state is `[0, wsh₀, …, wsh₃₀]`: thirty-one wires moved up one place and a constant in the
vacated LSB. **The only gates are the AND row and that one constant.** *A shifter built as gates
would have cost 32 more and computed the same thing.* -/

/-- The stream bit — the organ's single primary input, net `0`. -/
def wsX : Net := 0
/-- The shifted weight `W << t` — the organ's STATE, nets `1…32`. -/
def wsW (k : Nat) : Net := 1 + k
/-- `nIn + nState` = 1 + 32. -/
def wsCoreIn : Nat := 33
/-- The constant that fills the LSB the shift vacates — one of this organ's two gate kinds. -/
def wsZero : Net := 33
/-- The AND row: `addend[k] = x_t ∧ (W << t)[k]`, nets `34…65`. -/
def wsAnd (k : Nat) : Net := 34 + k

def wsGates : List Gate :=
  ⟨wsZero, Op.const false⟩ :: (List.range 32).map (fun k => ⟨wsAnd k, Op.and wsX (wsW k)⟩)

/-- ⭐⭐ **THE CORE.** Outputs: the 32 addend bits, then the 32 next-state bits. The next state is
the left shift, expressed as WIRES — `wsZero` then `wsW 0 … wsW 30`. -/
def wsCore : Circ :=
  { nIn := wsCoreIn
    gates := wsGates
    outs := (List.range 32).map wsAnd ++ (wsZero :: (List.range 31).map wsW) }

/-- ⭐ **THE ORGAN.** -/
def wshiftSeq : Seq := { nIn := 1, nOut := 32, nState := 32, core := wsCore }

theorem wsCore_ssa : wsCore.ssa = true := by decide +kernel
theorem wsCore_wf : wsCore.wf = true := Circ.wf_of_ssa wsCore_ssa

/-- **The widths are consistent** — `core.nIn = 1 + 32`, `core.outs.length = 32 + 32`. -/
theorem wshiftSeq_wf : wshiftSeq.wf = true := by decide +kernel

/-- **33 gates: one constant + a 32-wide AND row.** The shift itself is free. -/
theorem wsCore_gate_count : wsCore.gates.length = 33 := by decide +kernel

/-- ⛔ **BIRTH-ASSERTION (the maestro asked for this pattern in every organ from here): the constant
net is not an AND output.** The pair property no per-instance certificate can express, stated at the
organ's birth rather than found later. -/
theorem wsZero_does_not_collide :
    wsZero ∉ ((List.range 32).map (fun k => wsAnd k)) := by decide +kernel

/-- ⛔⛔ **THE MUTANT: A ROTATE PLACES EXACTLY AS CLEANLY AS A SHIFT.** Filling the vacated LSB from
`wsh₃₁` instead of from a constant is well-formed, same gate count, same widths — and computes
`W · 2^t mod (2^32 − 1)`-ish garbage the moment the weight's top bit is set. **Both halves asserted:
the LSB IS the constant, and the constant is NOT the top state bit.** -/
theorem shift_is_not_a_rotate :
    (wsCore.outs.drop 32).headD 0 = wsZero ∧ wsZero ≠ wsW 31 := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- ⛔ **THE OTHER MUTANT: LEFT, NOT RIGHT.** A right shift is also pure rewiring and also places
cleanly; it would weight bit `t` by `2^(-t)`. Next-state bit 1 must be state bit **0**. -/
theorem shift_is_left_not_right :
    (wsCore.outs.drop 32).getD 1 0 = wsW 0 ∧ (wsCore.outs.drop 32).getD 1 0 ≠ wsW 2 := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- **CONTROL: the AND row reads the STREAM BIT, not a state bit.** Every addend gate must have
`wsX` as one operand — an organ that ANDed two state bits would emit `wsh[k] ∧ wsh[k]` and ignore
the stream entirely, accumulating `W · 2^t` on every cycle regardless of `x`. -/
theorem and_row_reads_the_stream (k : Nat) (hk : k < 32) :
    (⟨wsAnd k, Op.and wsX (wsW k)⟩ : Gate) ∈ wsGates := by
  revert hk; revert k; decide +kernel

/-- **CONTROL: the two organs' state widths match, so they compose.** `wshiftSeq`'s 32 output bits
are exactly `macSeq`'s 32 addend inputs — the seam the composition layer will use. -/
theorem organs_compose_at_32_bits :
    wshiftSeq.nOut = macSeq.nIn ∧ wshiftSeq.nState = 32 ∧ macSeq.nState = 32 := by
  refine ⟨rfl, rfl, rfl⟩

/-! ### OWED, with its shape named

The per-cycle semantics of this organ — `stepSeq wshiftSeq [x] (bitsOf w) = (bitsOf (if x then w
else 0), bitsOf (w <<< 1))` — is the next rung and it is cheap: 33 gates, no instantiation, so no
`inst_sem` and no frame argument. **Stated as owed rather than left to be inferred from silence**,
exactly as `macSeq`'s per-cycle lemma was before layer 1 landed.

⛔ **AND STILL NOT CLAIMED: the composition.** Two organs with matching widths are not a machine.
`organs_compose_at_32_bits` says the seam FITS; it does not say anything is wired.
-/

/-! ### ORGAN 2'S PER-CYCLE SEMANTICS — the item I re-priced, now cheap for the stated reason

`run_of_flat_gates` (`Compose.lean`, landed `6969fa4`) exists because of this proof: without it, each
bit needs the gate list split at a **variable** index and `run_of_unwritten` applied twice. With it,
both halves are three lines. **The re-pricing said the cheap path was a named lemma rather than a
faster bespoke proof; this is that claim being cashed.**

`wsCore` is FLAT — every gate reads only `wsX` and a state net, both below `wsCoreIn` — which is
exactly the hypothesis the lemma's name carries and the reason it applies here and refuses `macCore`.
-/

theorem wsGates_flat : flatBelow wsCoreIn wsGates = true := by decide +kernel
theorem wsGates_ssa : ssaFrom wsCoreIn wsGates = true := by decide +kernel

/-- The organ's environment reads: the stream bit at `wsX`, state bit `k` at `wsW k`. -/
theorem wshift_env (x : Bool) (w : BitVec 32) (k : Nat) (hk : k < 32) :
    wshiftSeq.env [x] (bitsOf w) wsX = x
  ∧ wshiftSeq.env [x] (bitsOf w) (wsW k) = w.getLsbD k := by
  refine ⟨?_, ?_⟩
  · simp only [Seq.env, wshiftSeq, wsX]
    norm_num
  · have hne : ¬(1 + k < 1) := by omega
    simp only [Seq.env, wshiftSeq, wsW, if_neg hne, Nat.add_sub_cancel_left]
    exact bitsOf_getD w k hk

/-- ⭐⭐ **THE ADDEND BIT: `addend[k] = x_t ∧ (W << t)[k]`.** This is exactly the `macAfter` term
`if x t then W · 2^t else 0`, bit by bit. -/
theorem wshift_addend_bit (x : Bool) (w : BitVec 32) (k : Nat) (hk : k < 32) :
    run (wshiftSeq.env [x] (bitsOf w)) wsCore.gates (wsAnd k) = (x && w.getLsbD k) := by
  -- `wsCore.gates` and `wsGates` are definitionally equal but NOT syntactically, so `simpa`
  -- cannot close the gap on its own. Rewrite once, then the lemma applies.
  rw [show wsCore.gates = wsGates from rfl]
  have hmem : (⟨wsAnd k, Op.and wsX (wsW k)⟩ : Gate) ∈ wsGates := and_row_reads_the_stream k hk
  have h := run_of_flat_gates (wshiftSeq.env [x] (bitsOf w)) wsGates_flat wsGates_ssa hmem
  obtain ⟨hx, hw⟩ := wshift_env x w k hk
  simpa [Op.eval, hx, hw] using h

/-- ⭐ **THE SHIFT, BIT 0: the vacated LSB is the CONSTANT, not a wrapped bit.** Proved through the
same lemma — the tie is a gate of the flat list like any other. -/
theorem wshift_next_bit_zero (x : Bool) (w : BitVec 32) :
    run (wshiftSeq.env [x] (bitsOf w)) wsCore.gates wsZero = false := by
  rw [show wsCore.gates = wsGates from rfl]
  have hmem : (⟨wsZero, Op.const false⟩ : Gate) ∈ wsGates := by simp [wsGates]
  have h := run_of_flat_gates (wshiftSeq.env [x] (bitsOf w)) wsGates_flat wsGates_ssa hmem
  simpa [Op.eval] using h

/-- ⭐ **THE SHIFT, BITS 1…31: next-state bit `k+1` is state bit `k`.** These nets are INPUTS, never
written, so this is the frame rather than the flat-gate lemma — the two halves of the shift are
proved by different tools and that is the honest structure. -/
theorem wshift_next_bit_succ (x : Bool) (w : BitVec 32) (k : Nat) (hk : k < 31) :
    run (wshiftSeq.env [x] (bitsOf w)) wsCore.gates (wsW k) = w.getLsbD k := by
  have hne : ∀ g ∈ wsCore.gates, g.out ≠ wsW k := by
    intro g hg hEq
    have hb : wsCoreIn ≤ g.out := ssaFrom_out_ge wsGates wsCoreIn wsGates_ssa g hg
    rw [hEq] at hb
    have : (1 + k : Nat) < 33 := by omega
    simp only [wsCoreIn, wsW] at hb
    omega
  rw [run_of_unwritten _ _ _ hne]
  exact (wshift_env x w k (by omega)).2

/-! **WHAT THIS COMPLETES.** Organ 2's cycle is characterised: the addend is `x ∧ (W << t)`, and the
next state is `W << (t+1)` — bit 0 the constant, bits `1…31` the previous bits shifted up. Together
with `macSeq`'s layer 1 (`step_bit_is_adder_bit`), both cell organs now have per-cycle semantics.

⛔ **STILL NOT CLAIMED: THE COMPOSITION.** Two organs with per-cycle semantics and matching widths
are not a machine. Wiring organ 2's output into organ 1's addend port is a further object, and
`organs_compose_at_32_bits` says only that the seam FITS.
-/

/-! ### THE FREEZE MUTANT, MADE KERNEL-VISIBLE

**Silicon's 14:28 point, and it is a commission for this seat:** the asymmetric state discipline is
invisible to their whole toolchain — *"DRC, LVS, timing and my gate all pass a design that freezes W
across inputs. It is caught by a theorem or not at all."*

And their sharper observation is the reason it matters: ***`runTrace`'s `st₀` is a MODELLING DEVICE. In
silicon it is not a mechanism — a register does not acquire a value because a theorem quantified over
one.*** So "the shift costs no gates" is true of the SHIFT and says nothing about the LOAD, exactly as
"the bias costs zero gates" was true only of the streamed form.

⇒ **The theorem below exhibits the freeze by EVALUATION: the weight register's state MOVES, so a
second input continued from it is weighted by `W <<< n`, not by `W`.** *No wire is wrong in that
design; there is nothing for a port map or a disjointness control to point at.* -/

/-- ⛔⛔ **RELOADING IS REQUIRED, AND HERE IS THE ARITHMETIC THAT PROVES IT.** Starting from weight
`1`, the register holds `2` after one cycle and `4` after two — so it does **not** hold `1`, and an
input processed without re-initialisation is multiplied by the wrong weight.

**Concrete witnesses rather than a ∀-statement on purpose:** the claim being excluded is a *design*
(one `runTrace` spanning two inputs), and a single arithmetic witness refutes it. -/
theorem weight_state_moves_so_reload_is_required :
    (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false]]).2 = bitsOf (2 : BitVec 32)
  ∧ (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false], [false]]).2 = bitsOf (4 : BitVec 32)
  ∧ (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false]]).2 ≠ bitsOf (1 : BitVec 32) := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- **CONTROL: the stream bit does not reach the weight register.** Which is why the load path is a
*silicon* question and not a wiring one — there is no port to load through, so the mechanism must be
added, not merely connected. Measured: no next-state net is the stream-bit net. -/
theorem stream_bit_never_enters_the_weight_register :
    wsX ∉ wsCore.outs.drop 32 := by decide +kernel

/-! ⚖️ **THE LOAD PATH IS A DESIGN DECISION AND NOT MINE — priced here in KERNEL GATES, which is my
axis, beside silicon's area:**

```
   (a) SERIAL LOAD through the existing chain — the LSB selects `wsX` instead of the constant on
       load cycles. Needs ONE control input (`load`) and a 1-bit mux (~3 gates in this corpus's
       idiom): 33 -> ~36 gates, nIn 1 -> 2. The organ's single input does double duty, and
       LOAD_W then STREAM_X uses one wire for both.
   (b) PARALLEL LOAD — 32 muxes (~96 gates) and 32 new input ports: nIn 1 -> 34.
```

**(a) is the standard serial-load shift register and is ~30× cheaper in gates.** *A mode bit is
unavoidable in (a): with the LSB always taking `wsX`, streaming would inject stream bits INTO the
weight register — so the cheap option is cheap but not free, and saying "one mux" without the control
input would understate it.* **Maestro's call; I will implement either.**
-/

/-! ### The axiom audit — one declaration per call

*Added WITH the cell, not after it. `CorePlace` ran fourteen placements with `EXIT=0` and zero
audits, and on the first outing of its audit block two failed tactics had already put `sorryAx`
under a principal theorem. A multi-name call aborts its own list at the first failure, so
everything after a failure reads as clean. -/

#audit_axioms macCore_ssa
#audit_axioms macCore_wf
#audit_axioms macSeq_wf
#audit_axioms macCore_gate_count
#audit_axioms macSeq_dimensions
#audit_axioms mac_instOK
#audit_axioms tie_does_not_collide_with_the_adder
#audit_axioms output_equals_next_state
#audit_axioms acc_is_the_a_port_and_addend_is_the_b_port
#audit_axioms carry_in_is_low
#audit_axioms bitsOf_getD
#audit_axioms tie_runs_to_false
#audit_axioms tie_frame
#audit_axioms mac_hin
#audit_axioms step_bit_is_adder_bit
#audit_axioms step_halves_agree
#audit_axioms wsCore_ssa
#audit_axioms wsCore_wf
#audit_axioms wshiftSeq_wf
#audit_axioms wsCore_gate_count
#audit_axioms wsZero_does_not_collide
#audit_axioms shift_is_not_a_rotate
#audit_axioms shift_is_left_not_right
#audit_axioms and_row_reads_the_stream
#audit_axioms organs_compose_at_32_bits
#audit_axioms wsGates_flat
#audit_axioms wsGates_ssa
#audit_axioms wshift_env
#audit_axioms wshift_addend_bit
#audit_axioms wshift_next_bit_zero
#audit_axioms wshift_next_bit_succ
#audit_axioms weight_state_moves_so_reload_is_required
#audit_axioms stream_bit_never_enters_the_weight_register

end SaltWorks.HDL.MacCell
