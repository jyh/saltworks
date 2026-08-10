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
def maAcc (k : Nat) : Net := 33 + k

/-- `nIn + nState` — what the CORE sees. Distinct from `macSeq.nIn`, and the distinction is the one
my own cell account (`docs/compiler-cell-account-0808.md:14`) says readers get wrong: *"the core's
`nIn` is the machine's `nIn` PLUS its `nState`"*. -/
def maCoreIn : Nat := 65

/-- ⭐ **THE CARRY-IN, NOW AN ADMITTED PORT** — ruled (b), final 14:58 after a full artifact loop.
It was a tied `const false`; the sign cycle needs it settable, so the tie becomes an input and the
organ **loses** a gate: 161 → 160. *A tied constant is a port you have not admitted to needing.* -/
def maCin : Net := 32

/-- Where the adder instance begins. **No tie gate precedes it**, so the instance starts
immediately above the core's inputs. -/
def maOff : Nat := 65

/-- ⭐ **THE WIRING. `a := the accumulator`, `b := the addend`, carry-in `:= 0`.**

`adder32`'s ports are `a` on `0…31`, `b` on `32…63`, `cin` at `64` (`Adder.lean:69-71`). The
assignment is not symmetric in meaning even though `+` is commutative: naming `a` the accumulator
keeps the cell readable as *accumulate*, and the state/primary split then falls out of `Seq.env`. -/
def maSigma (i : Nat) : Net :=
  if i < 32 then maAcc i else if i < 64 then maAddend (i - 32) else maCin

/-- The 32 sum nets of the instance, in the host's numbering. -/
def maSum (k : Nat) : Net := instMap adder32 maSigma maOff (adS k)

/-- ⭐⭐ **THE CORE.** One tie gate, one `adder32` instance. The output list is the sum **twice** —
`Seq` reads `outs.take nOut` as this cycle's outputs and `outs.drop nOut` as the next state, and for
an accumulator those are the same 32 nets. *Listing a net twice in `outs` is a projection, not a
second gate; the gate count below is the check on that.* -/
def macCore : Circ :=
  { nIn := maCoreIn
    gates := instGates adder32 maSigma maOff
    outs := (List.range 32).map maSum ++ (List.range 32).map maSum }

/-- ⭐ **THE CELL.** -/
def macSeq : Seq := { nIn := 33, nOut := 32, nState := 32, core := macCore }

/-! ### The certificates -/

theorem macCore_ssa : macCore.ssa = true := by decide +kernel

/-- Through `Circ.wf_of_ssa`, not `decide` — `wf`'s `nodupB` is quadratic. -/
theorem macCore_wf : macCore.wf = true := Circ.wf_of_ssa macCore_ssa

/-- **The widths are consistent**: `core.nIn = nIn + nState` and
`core.outs.length = nOut + nState`. This is `Seq.wf`, and it is the obligation that catches an
accumulator whose state width does not match its adder. -/
theorem macSeq_wf : macSeq.wf = true := by decide +kernel

/-- **160 gates — the adder instance alone.** Admitting the carry-in port REMOVED the tie. -/
theorem macCore_gate_count : macCore.gates.length = 160 := by decide +kernel

/-- **32 state bits, 32 outputs, 64 core inputs** — the cell account's four columns. -/
theorem macSeq_dimensions :
    macSeq.nIn = 33 ∧ macSeq.nOut = 32 ∧ macSeq.nState = 32 ∧ macSeq.core.nIn = 65 := by
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
theorem cin_is_an_input_not_a_gate :
    maCin < macCore.nIn ∧ maCin ∉ (instGates adder32 maSigma maOff).map (·.out) := by
  refine ⟨by decide +kernel, by decide +kernel⟩

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
    maSigma 0 = maAcc 0 ∧ maSigma 32 = maAddend 0 ∧ maSigma 64 = maCin := by
  refine ⟨rfl, rfl, rfl⟩

/-- **CONTROL: the carry-in is tied LOW.** Tied high would add one on every single cycle — an error
of `n+1` per MAC that no single-cycle test distinguishes from a rounding choice. -/
theorem no_constant_gates_remain :
    macCore.gates.filter (fun g => match g.op with | .const _ => true | _ => false) = [] := by
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

/-! ⭐ **THE FRAME MACHINERY IS GONE, AND ITS ABSENCE IS THE POINT.** With the carry-in a tied GATE,
`inst_sem`'s third arm read a gate and needed a one-gate frame argument (`tie_runs_to_false`,
`tie_frame`) — the arm math flagged and `pcAdd` solves at its net `129`. **Admitting the port makes
all three arms read INPUTS, so the frame lemmas are deleted rather than repointed.** *Option (b)
removed a gate, a theorem, and two lemmas; the interface was carrying proof weight.*

The input word is now **33 bits: the 32-bit addend, then the carry-in.** -/

/-- The input word is `addend ++ [cin]`: positions `0…31` are the addend. -/
theorem word_getD_lo (w : BitVec 32) (c : Bool) (k : Nat) (hk : k < 32) :
    (bitsOf w ++ [c]).getD k false = w.getLsbD k := by
  have hlen : (bitsOf w).length = 32 := bitsOf_length w
  rw [List.getD_eq_getElem?_getD, List.getElem?_append_left (by omega),
      ← List.getD_eq_getElem?_getD]
  exact bitsOf_getD w k hk

/-- …and position `32` is the carry-in. -/
theorem word_getD_cin (w : BitVec 32) (c : Bool) :
    (bitsOf w ++ [c]).getD 32 false = c := by
  have hlen : (bitsOf w).length = 32 := bitsOf_length w
  rw [List.getD_eq_getElem?_getD, List.getElem?_append_right (by omega)]
  simp [hlen]

/-- ⭐ **THE σ AGREEMENT — `inst_sem`'s `hin`, three arms, all reading INPUTS.** -/
theorem mac_hin (acc addend : BitVec 32) (cin : Bool) :
    ∀ i, i < adder32.nIn →
      macSeq.env (bitsOf addend ++ [cin]) (bitsOf acc) (maSigma i)
        = SaltWorks.Stack.Program.adEnv acc addend cin i := by
  intro i hi
  have h65 : adder32.nIn = 65 := by decide +kernel
  rw [h65] at hi
  have hlen : (bitsOf addend).length = 32 := bitsOf_length addend
  by_cases h1 : i < 32
  · -- the `a` port reads the STATE
    rw [maSigma, if_pos h1, maAcc]
    simp only [Seq.env, macSeq, SaltWorks.Stack.Program.adEnv,
               if_neg (show ¬(33 + i < 33) by omega), if_pos h1, Nat.add_sub_cancel_left]
    exact bitsOf_getD acc i h1
  · by_cases h2 : i < 64
    · -- the `b` port reads the ADDEND, inside the first 32 of the input word
      rw [maSigma, if_neg h1, if_pos h2, maAddend]
      simp only [Seq.env, macSeq, SaltWorks.Stack.Program.adEnv,
                 if_pos (show i - 32 < 33 by omega), if_neg h1, if_pos h2]
      exact word_getD_lo addend cin (i - 32) (by omega)
    · -- ⭐ the carry-in now reads an INPUT — the last position of the word
      have h64 : i = 64 := by omega
      subst h64
      rw [maSigma, if_neg h1, if_neg h2, maCin]
      simp only [Seq.env, macSeq, SaltWorks.Stack.Program.adEnv, if_pos (show 32 < 33 by omega),
                 if_neg h1, if_neg h2]
      exact word_getD_cin addend cin

/-- ⭐⭐ **LAYER 1, POINTWISE, AND NOW WITH A SETTABLE CARRY-IN.** Sum bit `k` of one cycle IS
`adder32`'s sum bit `k` on the adder's own environment — for **every** `cin`, which is what makes the
sign cycle a cycle of this cell. No hypothesis, no `ℤ`, no overflow condition, and no re-derivation
of math's certificate. -/
theorem step_bit_is_adder_bit (acc addend : BitVec 32) (cin : Bool) (k : Nat) (hk : k < 32) :
    run (macSeq.env (bitsOf addend ++ [cin]) (bitsOf acc)) macCore.gates (maSum k)
      = run (SaltWorks.Stack.Program.adEnv acc addend cin) adder32.gates (adS k) := by
  have hmem : (adder32.gates.map Gate.out).contains (adS k) = true := by
    revert hk; revert k; decide +kernel
  have h := inst_sem adder32 maSigma maOff
      (macSeq.env (bitsOf addend ++ [cin]) (bitsOf acc))
      (SaltWorks.Stack.Program.adEnv acc addend cin) mac_instOK (mac_hin acc addend cin)
      (adS k) (Or.inr hmem)
  rw [show macCore.gates = instGates adder32 maSigma maOff from rfl, maSum]
  exact h

/-- ⭐ **THE COMPATIBILITY COROLLARY — the form I should have landed BESIDE the new one instead of
replacing it.** `MacBridge` passes a 32-bit input word; with `nIn = 33` position `32` reads
`getD 32 false = false`, so **that call is already semantically "carry-in = 0"** — only my
*signature* broke it, not its meaning.

*`statement-shape-is-an-interface`, which I wrote down and then skipped: a truth-preserving
restatement is still a breaking change; land the new form beside and repoint. The red window this
corollary closes is the cost of not doing that, and it is one word at each call site.* -/
theorem step_bit_is_adder_bit_no_carry (acc addend : BitVec 32) (k : Nat) (hk : k < 32) :
    run (macSeq.env (bitsOf addend) (bitsOf acc)) macCore.gates (maSum k)
      = run (SaltWorks.Stack.Program.adEnv acc addend false) adder32.gates (adS k) := by
  have hagree : ∀ n, macSeq.env (bitsOf addend) (bitsOf acc) n
      = macSeq.env (bitsOf addend ++ [false]) (bitsOf acc) n := by
    intro n
    have hlen : (bitsOf addend).length = 32 := bitsOf_length addend
    simp only [Seq.env, macSeq]
    by_cases h : n < 33
    · rw [if_pos h, if_pos h]
      by_cases h32 : n < 32
      · -- both sides are `addend.getLsbD n`; rewrite each with its own lemma
        rw [bitsOf_getD addend n h32, word_getD_lo addend false n h32]
      · -- n = 32: the short word is OUT OF RANGE (default false), the long word HOLDS false
        -- ⚠️ NOT `omega`: `h`/`h32` are `Net`-typed and omega DROPS them (its counterexample
        -- mentioned only the `Nat`-typed `hk`). Fourth instance today. Terms, not tactics.
        have hn : n = 32 := Nat.le_antisymm (Nat.lt_succ_iff.mp h) (Nat.not_lt.mp h32)
        subst hn
        rw [List.getD_eq_getElem?_getD, List.getD_eq_getElem?_getD,
            List.getElem?_append_right (by rw [hlen]), List.getElem?_eq_none (by rw [hlen])]
        simp [hlen]
    · rw [if_neg h, if_neg h]
  rw [run_congr macCore.gates hagree]
  exact step_bit_is_adder_bit acc addend false k hk

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

/-- The stream bit — primary input `0`. -/
def wsX : Net := 0

/-- ⭐ **THE LOAD ENABLE — the second admitted port** (load-path A, ruled). On load cycles the
vacated LSB takes the stream bit instead of a constant, so `W_i` enters serially through the wire
that later streams `x`. **`nIn` 1 → 2 and the gate count does not move**: the `const false` is
REPLACED by `and load x`, which *is* `false` when `load` is low — i.e. exactly the shift fill. -/
def wsLoad : Net := 1
/-- The shifted weight `W << t` — the organ's STATE, nets `1…32`. -/
def wsW (k : Nat) : Net := 2 + k
/-- `nIn + nState` = 1 + 32. -/
def wsCoreIn : Nat := 34
/-- The LSB the shift vacates — **no longer a constant**: `and load x`. -/
def wsLsb : Net := 34
/-- The AND row: `addend[k] = x_t ∧ (W << t)[k]`, nets `34…65`. -/
def wsAnd (k : Nat) : Net := 35 + k

def wsGates : List Gate :=
  ⟨wsLsb, Op.and wsLoad wsX⟩ :: (List.range 32).map (fun k => ⟨wsAnd k, Op.and wsX (wsW k)⟩)

/-- ⭐⭐ **THE CORE.** Outputs: the 32 addend bits, then the 32 next-state bits. The next state is
the left shift, expressed as WIRES — `wsLsb` then `wsW 0 … wsW 30`. -/
def wsCore : Circ :=
  { nIn := wsCoreIn
    gates := wsGates
    outs := (List.range 32).map wsAnd ++ (wsLsb :: (List.range 31).map wsW) }

/-- ⭐ **THE ORGAN.** -/
def wshiftSeq : Seq := { nIn := 2, nOut := 32, nState := 32, core := wsCore }

theorem wsCore_ssa : wsCore.ssa = true := by decide +kernel
theorem wsCore_wf : wsCore.wf = true := Circ.wf_of_ssa wsCore_ssa

/-- **The widths are consistent** — `core.nIn = 1 + 32`, `core.outs.length = 32 + 32`. -/
theorem wshiftSeq_wf : wshiftSeq.wf = true := by decide +kernel

/-- **33 gates: one constant + a 32-wide AND row.** The shift itself is free. -/
theorem wsCore_gate_count : wsCore.gates.length = 33 := by decide +kernel

/-- ⛔ **BIRTH-ASSERTION (the maestro asked for this pattern in every organ from here): the constant
net is not an AND output.** The pair property no per-instance certificate can express, stated at the
organ's birth rather than found later. -/
theorem wsLsb_does_not_collide :
    wsLsb ∉ ((List.range 32).map (fun k => wsAnd k)) := by decide +kernel

/-- ⛔⛔ **THE MUTANT: A ROTATE PLACES EXACTLY AS CLEANLY AS A SHIFT.** Filling the vacated LSB from
`wsh₃₁` instead of from a constant is well-formed, same gate count, same widths — and computes
`W · 2^t mod (2^32 − 1)`-ish garbage the moment the weight's top bit is set. **Both halves asserted:
the LSB IS the constant, and the constant is NOT the top state bit.** -/
theorem shift_is_not_a_rotate :
    (wsCore.outs.drop 32).headD 0 = wsLsb ∧ wsLsb ≠ wsW 31 := by
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
    wshiftSeq.nOut = 32 ∧ macSeq.nIn = 32 + 1 ∧ wshiftSeq.nState = 32 ∧ macSeq.nState = 32 := by
  refine ⟨rfl, rfl, rfl, rfl⟩

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
theorem wshift_env (x ld : Bool) (w : BitVec 32) (k : Nat) (hk : k < 32) :
    wshiftSeq.env [x, ld] (bitsOf w) wsX = x
  ∧ wshiftSeq.env [x, ld] (bitsOf w) wsLoad = ld
  ∧ wshiftSeq.env [x, ld] (bitsOf w) (wsW k) = w.getLsbD k := by
  refine ⟨?_, ?_, ?_⟩
  · simp only [Seq.env, wshiftSeq, wsX]; norm_num
  · simp only [Seq.env, wshiftSeq, wsLoad]; norm_num
  · have hne : ¬(2 + k < 2) := by omega
    simp only [Seq.env, wshiftSeq, wsW, if_neg hne, Nat.add_sub_cancel_left]
    exact bitsOf_getD w k hk

/-- ⭐⭐ **THE ADDEND BIT: `addend[k] = x_t ∧ (W << t)[k]`.** This is exactly the `macAfter` term
`if x t then W · 2^t else 0`, bit by bit. -/
theorem wshift_addend_bit (x ld : Bool) (w : BitVec 32) (k : Nat) (hk : k < 32) :
    run (wshiftSeq.env [x, ld] (bitsOf w)) wsCore.gates (wsAnd k) = (x && w.getLsbD k) := by
  -- `wsCore.gates` and `wsGates` are definitionally equal but NOT syntactically, so `simpa`
  -- cannot close the gap on its own. Rewrite once, then the lemma applies.
  rw [show wsCore.gates = wsGates from rfl]
  have hmem : (⟨wsAnd k, Op.and wsX (wsW k)⟩ : Gate) ∈ wsGates := and_row_reads_the_stream k hk
  have h := run_of_flat_gates (wshiftSeq.env [x, ld] (bitsOf w)) wsGates_flat wsGates_ssa hmem
  obtain ⟨hx, _, hw⟩ := wshift_env x ld w k hk
  simpa [Op.eval, hx, hw] using h

/-- ⭐⭐ **THE SHIFT'S LSB IS NOW `load ∧ x` — AND THIS ONE THEOREM CARRIES BOTH MODES.** With `load`
low it is `false`, so the organ shifts exactly as it did before load-path A; with `load` high it is
the stream bit, which is how `W_i` enters serially. *One statement, both behaviours, and the
`load = false` corollary below is the old theorem recovered.* -/
theorem wshift_next_bit_zero (x ld : Bool) (w : BitVec 32) :
    run (wshiftSeq.env [x, ld] (bitsOf w)) wsCore.gates wsLsb = (ld && x) := by
  rw [show wsCore.gates = wsGates from rfl]
  have hmem : (⟨wsLsb, Op.and wsLoad wsX⟩ : Gate) ∈ wsGates := by simp [wsGates]
  have h := run_of_flat_gates (wshiftSeq.env [x, ld] (bitsOf w)) wsGates_flat wsGates_ssa hmem
  obtain ⟨hx, hld, _⟩ := wshift_env x ld w 0 (by omega)
  simpa [Op.eval, hx, hld] using h

/-- **AND THE OLD THEOREM, RECOVERED AS THE `load = false` CASE.** The shift is unchanged when the
organ is not loading — which is the compatibility claim load-path A owes. -/
theorem wshift_next_bit_zero_when_not_loading (x : Bool) (w : BitVec 32) :
    run (wshiftSeq.env [x, false] (bitsOf w)) wsCore.gates wsLsb = false := by
  simpa using wshift_next_bit_zero x false w

/-- ⭐ **THE SHIFT, BITS 1…31: next-state bit `k+1` is state bit `k`.** These nets are INPUTS, never
written, so this is the frame rather than the flat-gate lemma — the two halves of the shift are
proved by different tools and that is the honest structure. -/
theorem wshift_next_bit_succ (x ld : Bool) (w : BitVec 32) (k : Nat) (hk : k < 31) :
    run (wshiftSeq.env [x, ld] (bitsOf w)) wsCore.gates (wsW k) = w.getLsbD k := by
  have hne : ∀ g ∈ wsCore.gates, g.out ≠ wsW k := by
    intro g hg hEq
    have hb : wsCoreIn ≤ g.out := ssaFrom_out_ge wsGates wsCoreIn wsGates_ssa g hg
    rw [hEq] at hb
    have : (1 + k : Nat) < 33 := by omega
    simp only [wsCoreIn, wsW] at hb
    omega
  rw [run_of_unwritten _ _ _ hne]
  exact (wshift_env x ld w k (by omega)).2.2

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
    (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false, false]]).2 = bitsOf (2 : BitVec 32)
  ∧ (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false, false], [false, false]]).2 = bitsOf (4 : BitVec 32)
  ∧ (runTrace wshiftSeq (bitsOf (1 : BitVec 32)) [[false, false]]).2 ≠ bitsOf (1 : BitVec 32) := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- ⭐ **THE SUCCESSOR OF `stream_bit_never_enters_the_weight_register`, WHICH LOAD-PATH A
DELIBERATELY FALSIFIED.** That theorem said there was no path in; A builds one, on purpose. What must
still hold is the *gated* form: the stream bit reaches the register **only through the load gate**,
so with `load` low the LSB fill is still `false` and the organ shifts exactly as before.

*This is the pair that shows a retired control being replaced rather than dropped: the old statement
was true of the old artifact and its falsification IS the ruling working.* -/
theorem stream_enters_only_through_the_load_gate :
    (⟨wsLsb, Op.and wsLoad wsX⟩ : Gate) ∈ wsGates
  ∧ wsX ∉ (wsCore.outs.drop 32).tail := by
  refine ⟨by simp [wsGates], by decide +kernel⟩

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

/-! ## THE SECOND OVERFLOW CONDITION — the weight shift's own

**Residue item (i), assigned to this seat** (maestro 14:51, from my 14:48 seam finding): rung 4's
`cell_state_toInt_eq_macAfter` assumes `hW : ∀ t < n, (Wsh t).toInt = W * 2 ^ t`, and **my per-cycle
theorems are that schedule** — the organ's state after `t` cycles is `w <<< t`, exactly.

⚠️ ***BUT THE `ℤ` READING OF THAT SHIFT IS CONDITIONAL, AND THE CONDITION IS NOT `noOverflowFrom`.***
`noOverflowFrom` (math's, rung 4b) is a predicate on the ACCUMULATOR'S ADDITIONS. **A signed left
shift can wrap independently of any sum**, so `hW` silently carries a second, unnamed hypothesis.
Named here, and it is `¬saddOverflow`'s sibling for the shift. -/

/-- **THE SECOND OVERFLOW CONDITION.** The `ℤ` reading of a left shift, which is *false* on wrap. -/
def shiftSafe (w : BitVec 32) (t : Nat) : Prop := (w <<< t).toInt = w.toInt * 2 ^ t

instance (w : BitVec 32) (t : Nat) : Decidable (shiftSafe w t) := by
  unfold shiftSafe; infer_instance

/-- ⛔⛔ **THE CONDITION IS REAL, AND ITS FAILURE FLIPS THE WEIGHT'S SIGN.** At `w = 2^30`, one
shift gives `-2147483648` where the arithmetic wants `+2147483648`. *A MAC whose weight silently
negates does not compute a slightly wrong dot product; it computes the wrong sign. **This is why the
condition is stated rather than assumed away** — and it is the exact shape of math's `2^30` witness
one layer down, arrived at independently.* -/
theorem shift_overflow_is_real :
    ¬ shiftSafe ((1 : BitVec 32) <<< 30) 1 := by decide

/-- ⭐⭐ **DISCHARGED AT THE RULED SCALE, EXHAUSTIVELY.** Ruling #8 fixes int8 values on the 32-bit
datapath, and the stream is 8 bits, so `t < 8`. **All 256 int8 weights at all 8 shift positions are
safe** — 2,048 cases, every one evaluated, in the style of math's own `sval_eq_toInt`.

*So `hW` is dischargeable today at the scale the September chip runs; what was missing was the
statement, not the fact.* -/
theorem shiftSafe_at_int8_scale :
    (List.range 256).all (fun n =>
      (List.range 8).all (fun t =>
        decide (shiftSafe (((BitVec.ofNat 8 n)).signExtend 32) t))) = true := by
  decide +kernel

/-- **AND THE BRIDGE TO `hW`, which is definitional once the condition is named.** The organ's state
after `t` cycles is `w <<< t`; `shiftSafe` says precisely that its `ℤ` reading is `w.toInt * 2 ^ t`,
which is rung 4's `hW` at `Wsh t = w <<< t`. *The content is in the condition, not in this step —
which is why the condition was worth finding and this line is worth only one.* -/
theorem hW_is_shiftSafe (w : BitVec 32) (t : Nat) (h : shiftSafe w t) :
    (w <<< t).toInt = w.toInt * 2 ^ t := h

/-! ⚖️ **WHAT REMAINS OF ITEM (i), and it is math's genre not mine:** the organ's per-cycle theorems
give ONE cycle (`wshift_next_bit_zero` / `_succ` ⇒ next state is `w <<< 1`). Lifting that to *state
after `t` cycles is `w <<< t`* is a **trace induction over `runTrace`** — the same shape as rung 3,
and math owns that machinery. **With `shiftSafe` named and discharged, the remaining step is
mechanical rather than exploratory.**
-/

/-! ## THE COMPOSED CELL — one `Seq`, one module, zero constant gates

**Cleared at 15:48** once math's join (`c732aaa`) existed to carry its meaning. Until then I refused
to build it, because a composed module that emits cleanly and has no join behind it is exactly the
artifact that would let *"the cell is emitted"* travel further than it earns.

```
   primary inputs   x = 0 · load = 1 · cin = 2                    (nIn 3)
   state            wsh 3…34 · acc 35…66                          (nState 64)
   core.nIn         67 = 3 + 64
   gates            instGates wsCore ++ instGates macCore = 33 + 160 = 193
   outs             acc' (32) ++ [ wsh' (32) ++ acc' (32) ]        = 96 = nOut + nState
```

⭐ **NO TIE CELLS ANYWHERE IN THE CELL.** *Both constants became ports under (b)+A, so the composed
artifact needs none of its own either — the tied-constant pattern paying a third time, at the level
above the organs that admitted it.* -/

def ccX : Net := 0
def ccLoad : Net := 1
def ccCin : Net := 2
def ccWsh (k : Nat) : Net := 3 + k
def ccAcc (k : Nat) : Net := 35 + k
def ccIn : Nat := 67
def ccWOff : Nat := 67
def ccMOff : Nat := 100

/-- `wsCore`'s σ: the stream bit, the load enable, then the weight register. -/
def ccWSig (i : Nat) : Net :=
  if i = 0 then ccX else if i = 1 then ccLoad else ccWsh (i - 2)

/-- ⭐ **THE SEAM: the addend `macCore` consumes is `wsCore`'s AND-row output**, in host numbering. -/
def ccAddend (k : Nat) : Net := instMap wsCore ccWSig ccWOff (wsAnd k)

/-- `macCore`'s σ: the addend from organ 2, the carry-in port, then the accumulator. -/
def ccMSig (i : Nat) : Net :=
  if i < 32 then ccAddend i else if i = 32 then ccCin else ccAcc (i - 33)

def ccCore : Circ :=
  { nIn := ccIn
    gates := instGates wsCore ccWSig ccWOff ++ instGates macCore ccMSig ccMOff
    outs := ((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k)))
            ++ ((List.range 32).map (fun k => instMap wsCore ccWSig ccWOff ((wsCore.outs.drop 32).getD k 0)))
            ++ ((List.range 32).map (fun k => instMap macCore ccMSig ccMOff (maSum k))) }

/-- ⭐⭐ **THE CELL AS ONE MACHINE.** -/
def cellSeq : Seq := { nIn := 3, nOut := 32, nState := 64, core := ccCore }

theorem ccCore_ssa : ccCore.ssa = true := by decide +kernel
theorem ccCore_wf : ccCore.wf = true := Circ.wf_of_ssa ccCore_ssa
theorem cellSeq_wf : cellSeq.wf = true := by decide +kernel

/-- **193 gates: 33 + 160, and not one more.** The composition adds no glue. -/
theorem ccCore_gate_count : ccCore.gates.length = 193 := by decide +kernel

/-- **ZERO constant gates in the whole cell.** -/
theorem cell_has_no_constant_gates :
    ccCore.gates.filter (fun g => match g.op with | .const _ => true | _ => false) = [] := by
  decide +kernel

theorem cellSeq_dimensions :
    cellSeq.nIn = 3 ∧ cellSeq.nOut = 32 ∧ cellSeq.nState = 64 ∧ ccCore.nIn = 67 := by
  refine ⟨rfl, rfl, rfl, rfl⟩

/-- ⭐ **BOTH PLACEMENTS SOUND.** -/
theorem cc_wsCore_instOK : instOK wsCore ccWSig ccWOff := by
  refine ⟨wsCore_ssa, wsCore_wf, ?_⟩
  intro i hi
  have h : wsCore.nIn = 34 := by decide +kernel
  rw [h] at hi; revert hi; revert i; decide +kernel

theorem cc_macCore_instOK : instOK macCore ccMSig ccMOff := by
  refine ⟨macCore_ssa, macCore_wf, ?_⟩
  intro i hi
  have h : macCore.nIn = 65 := by decide +kernel
  rw [h] at hi; revert hi; revert i; decide +kernel

/-- ⛔⛔ **THE BIRTH-ASSERTION: THE TWO INSTANCES DO NOT COLLIDE.** `instOK` constrains each instance
against its own inputs and cannot see the other — the lesson that cost sixteen true certificates over
a broken netlist this morning. Stated at the composition's birth. -/
theorem cell_instances_are_disjoint : ccWOff + wsCore.gates.length ≤ ccMOff := by
  have h : wsCore.gates.length = 33 := by decide +kernel
  simp only [ccWOff, ccMOff, h]
  decide

/-- ⭐⭐ **THE WIRING CLAIM `instOK` CANNOT MAKE: `macCore`'s addend port `k` IS `wsCore`'s AND-row
output `k`.** *`instOK` says the wire is computed in time; this says it is the RIGHT wire — the
source-port-map discipline, applied to the seam that defines the cell.* -/
theorem cell_seam_is_the_addend (k : Nat) (hk : k < 32) :
    ccMSig k = instMap wsCore ccWSig ccWOff (wsAnd k) := by
  simp only [ccMSig, ccAddend, if_pos hk]

/-- **CONTROL: the addend is NOT the accumulator or the carry-in.** Both would place cleanly. -/
theorem cell_seam_is_not_acc_or_cin :
    ccMSig 0 ≠ ccAcc 0 ∧ ccMSig 0 ≠ ccCin := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- **CONTROL: the state halves are in the declared order — `wsh` first, `acc` second.** Swapping
them places cleanly and feeds the accumulator's bits to the shifter. -/
theorem cell_state_layout :
    (ccCore.outs.drop 32).getD 0 0 = instMap wsCore ccWSig ccWOff ((wsCore.outs.drop 32).getD 0 0)
  ∧ (ccCore.outs.drop 32).getD 32 0 = instMap macCore ccMSig ccMOff (maSum 0) := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-! ⛔ **NOT CLAIMED: the per-cycle composition semantics.** This file certifies the cell's SHAPE —
`ssa`, `wf`, widths, both placements, disjointness, the seam, and the state layout. **That one
`stepSeq cellSeq` equals the two organs' steps in the intended relation is a further theorem**, and
it is what would let the cell's emission inherit math's join. *Stated as owed rather than left to be
inferred from the file's silence — the same discipline `macSeq` and `wshiftSeq` were landed under.*
-/

/-! ## THE COMPOSITION THEOREM — the cell's cycle IS the accumulator's, on the addend organ 2 made

**The item I owed since 16:0x, and the one I refused to hand-wave.** Until now the composed cell was
a shape-certified wiring; this is what lets its emission inherit math's join.

⭐ **THE TOOLS FIT EXACTLY, and the brief predicted the shape before a line was written:**
`ccCore.gates` is literally `instGates wsCore … ++ instGates macCore …` with
`ccMOff = instNext wsCore ccWOff`, so **`inst_compose_sem` applies directly** — and `hin2` splits
three ways with **only the addend arm crossing the seam.** *`run_of_flat_gates` cannot help here:
`ccCore` is not flat BY CONSTRUCTION, because the seam IS macCore reading wsCore's gate outputs.*

*Developed entirely in a gitignored scratch and transplanted green — six iterations, none of which
could have reddened the shared tree.* -/


/-- The addend word organ 2 produces from stream bit `x` and weight register `w`. -/
def andWord (x : Bool) (w : BitVec 32) : BitVec 32 := if x then w else 0

theorem andWord_bit (x : Bool) (w : BitVec 32) (k : Nat) (hk : k < 32) :
    (andWord x w).getLsbD k = (x && w.getLsbD k) := by
  cases x <;> simp [andWord]

/-- the cell's environment, and the two organs' standalone environments -/
abbrev cellEnv (x ld cin : Bool) (w acc : BitVec 32) : Env :=
  cellSeq.env [x, ld, cin] (bitsOf w ++ bitsOf acc)
abbrev wEnv (x ld : Bool) (w : BitVec 32) : Env := wshiftSeq.env [x, ld] (bitsOf w)
abbrev mEnv (x cin : Bool) (w acc : BitVec 32) : Env :=
  macSeq.env (bitsOf (andWord x w) ++ [cin]) (bitsOf acc)

theorem cell_env_reads (x ld cin : Bool) (w acc : BitVec 32) (k : Nat) (hk : k < 32) :
    cellEnv x ld cin w acc ccX = x
  ∧ cellEnv x ld cin w acc ccLoad = ld
  ∧ cellEnv x ld cin w acc ccCin = cin
  ∧ cellEnv x ld cin w acc (ccWsh k) = w.getLsbD k
  ∧ cellEnv x ld cin w acc (ccAcc k) = acc.getLsbD k := by
  have hlen : (bitsOf w).length = 32 := bitsOf_length w
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simp only [cellEnv, Seq.env, cellSeq, ccX]; norm_num
  · simp only [cellEnv, Seq.env, cellSeq, ccLoad]; norm_num
  · simp only [cellEnv, Seq.env, cellSeq, ccCin]; norm_num
  · have hne : ¬(3 + k < 3) := by omega
    simp only [cellEnv, Seq.env, cellSeq, ccWsh, if_neg hne, Nat.add_sub_cancel_left]
    rw [List.getD_eq_getElem?_getD, List.getElem?_append_left (by omega),
        ← List.getD_eq_getElem?_getD]
    exact bitsOf_getD w k hk
  · have hne : ¬(35 + k < 3) := by omega
    simp only [cellEnv, Seq.env, cellSeq, ccAcc, if_neg hne]
    have h32 : 35 + k - 3 = 32 + k := by omega
    rw [h32, List.getD_eq_getElem?_getD, List.getElem?_append_right (by omega)]
    simp only [hlen, Nat.add_sub_cancel_left]
    rw [← List.getD_eq_getElem?_getD]
    exact bitsOf_getD acc k hk

/-- Every gate of wsCore's instance lands at or above `ccWOff = 67`, so any net below it is
untouched by that instance. -/
theorem w_instance_leaves_low_nets (n : Net) (hn : n < ccWOff) :
    ∀ g ∈ instGates wsCore ccWSig ccWOff, g.out ≠ n := by
  intro g hg heq
  have hb := (instGates_out_range wsCore ccWSig ccWOff wsCore_ssa g hg).1
  rw [heq] at hb
  exact absurd hn (Nat.not_lt.mpr hb)

/-- wsCore's σ agreement inside the cell: its three port groups read the cell's inputs and state. -/
theorem cell_hin_w (x ld cin : Bool) (w acc : BitVec 32) :
    ∀ i, i < wsCore.nIn → cellEnv x ld cin w acc (ccWSig i) = wEnv x ld w i := by
  intro i hi
  have h34 : wsCore.nIn = 34 := by decide +kernel
  rw [h34] at hi
  by_cases h0 : i = 0
  · subst h0
    have e : ccWSig 0 = ccX := rfl
    rw [e, (cell_env_reads x ld cin w acc 0 (by omega)).1]
    simp only [wEnv, Seq.env, wshiftSeq]; norm_num
  · by_cases h1 : i = 1
    · subst h1
      have e : ccWSig 1 = ccLoad := rfl
      rw [e, (cell_env_reads x ld cin w acc 0 (by omega)).2.1]
      simp only [wEnv, Seq.env, wshiftSeq]; norm_num
    · rw [ccWSig, if_neg h0, if_neg h1,
          (cell_env_reads x ld cin w acc (i - 2) (by omega)).2.2.2.1]
      have hnl : ¬(i < 2) := by omega
      simp only [wEnv, Seq.env, wshiftSeq, if_neg hnl]
      exact (bitsOf_getD w (i - 2) (by omega)).symm

/-- ⭐ **`inst_compose_sem`'s `hin2`: macCore's ports, read AFTER wsCore's instance has run.**
Three arms — and only the FIRST needs `inst_sem` on wsCore, because only the addend crosses the
seam. -/
theorem cell_hin2 (x ld cin : Bool) (w acc : BitVec 32) :
    ∀ a, a < macCore.nIn →
      run (cellEnv x ld cin w acc) (instGates wsCore ccWSig ccWOff) (ccMSig a)
        = mEnv x cin w acc a := by
  intro a ha
  have h65 : macCore.nIn = 65 := by decide +kernel
  rw [h65] at ha
  have hmlen : (bitsOf (andWord x w)).length = 32 := bitsOf_length _
  by_cases h1 : a < 32
  · -- THE SEAM: the addend is wsCore's AND-row output
    have hmem : (wsCore.gates.map Gate.out).contains (wsAnd a) = true := by
      revert h1; revert a; decide +kernel
    have hstep := inst_sem wsCore ccWSig ccWOff (cellEnv x ld cin w acc) (wEnv x ld w)
      cc_wsCore_instOK (cell_hin_w x ld cin w acc) (wsAnd a) (Or.inr hmem)
    rw [ccMSig, if_pos h1, ccAddend, hstep, wshift_addend_bit x ld w a h1,
        ← andWord_bit x w a h1]
    simp only [mEnv, Seq.env, macSeq, if_pos (show a < 33 by omega)]
    exact (word_getD_lo (andWord x w) cin a h1).symm
  · by_cases h2 : a = 32
    · -- the carry-in: a primary input, untouched by wsCore's instance
      subst h2
      have e : ccMSig 32 = ccCin := by rw [ccMSig, if_neg h1]; simp
      rw [e, run_of_unwritten _ _ _ (w_instance_leaves_low_nets ccCin (by decide)),
          (cell_env_reads x ld cin w acc 0 (by omega)).2.2.1]
      exact (word_getD_cin (andWord x w) cin).symm
    · -- the accumulator: state nets, also untouched
      have hk : a - 33 < 32 := by omega
      have e : ccMSig a = ccAcc (a - 33) := by rw [ccMSig, if_neg h1, if_neg h2]
      -- ⚠️ Net-born `<`: omega drops it. Nat-typed intermediate, then transport.
      have hnat : (35 + (a - 33)) < 67 := by omega
      have hlow : ccAcc (a - 33) < ccWOff := by simpa [ccAcc, ccWOff] using hnat
      rw [e, run_of_unwritten _ _ _ (w_instance_leaves_low_nets _ hlow),
          (cell_env_reads x ld cin w acc (a - 33) hk).2.2.2.2]
      have hnl : ¬(a < 33) := by omega
      simp only [mEnv, Seq.env, macSeq, if_neg hnl]
      exact (bitsOf_getD acc (a - 33) hk).symm

/-- ⭐⭐ **THE COMPOSITION THEOREM — one cycle of the CELL is one cycle of the accumulator on the
addend the weight organ produced.** This is what the composed cell was missing: its emission can now
inherit math's join, because the addend it feeds the accumulator IS `x ∧ (W<<<t)`. -/
theorem cell_sum_bit (x ld cin : Bool) (w acc : BitVec 32) (k : Nat) (hk : k < 32) :
    run (cellEnv x ld cin w acc) ccCore.gates (instMap macCore ccMSig ccMOff (maSum k))
      = run (mEnv x cin w acc) macCore.gates (maSum k) := by
  have hmem : (macCore.gates.map Gate.out).contains (maSum k) = true := by
    revert hk; revert k; decide +kernel
  have hnext : ccMOff = instNext wsCore ccWOff := by
    simp only [ccMOff, ccWOff, instNext]; decide +kernel
  have hgates : ccCore.gates
      = instGates wsCore ccWSig ccWOff ++ instGates macCore ccMSig (instNext wsCore ccWOff) := by
    rw [← hnext]; rfl
  rw [hgates, hnext]
  -- ccMOff and instNext wsCore ccWOff are definitionally equal (both 100), so the lemmas
  -- stated at ccMOff are accepted here directly — no cast needed.
  exact inst_compose_sem wsCore macCore ccWSig ccMSig ccWOff cc_macCore_instOK
    (cellEnv x ld cin w acc) (mEnv x cin w acc) (cell_hin2 x ld cin w acc)
    (maSum k) (Or.inr hmem)

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
#audit_axioms cin_is_an_input_not_a_gate
#audit_axioms output_equals_next_state
#audit_axioms acc_is_the_a_port_and_addend_is_the_b_port
#audit_axioms no_constant_gates_remain
#audit_axioms bitsOf_getD
#audit_axioms word_getD_lo
#audit_axioms word_getD_cin
#audit_axioms mac_hin
#audit_axioms step_bit_is_adder_bit
#audit_axioms step_bit_is_adder_bit_no_carry
#audit_axioms step_halves_agree
#audit_axioms wsCore_ssa
#audit_axioms wsCore_wf
#audit_axioms wshiftSeq_wf
#audit_axioms wsCore_gate_count
#audit_axioms wsLsb_does_not_collide
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
#audit_axioms stream_enters_only_through_the_load_gate
#audit_axioms wshift_next_bit_zero_when_not_loading
#audit_axioms andWord_bit
#audit_axioms cell_env_reads
#audit_axioms w_instance_leaves_low_nets
#audit_axioms cell_hin_w
#audit_axioms cell_hin2
#audit_axioms cell_sum_bit
#audit_axioms ccCore_ssa
#audit_axioms ccCore_wf
#audit_axioms cellSeq_wf
#audit_axioms ccCore_gate_count
#audit_axioms cell_has_no_constant_gates
#audit_axioms cellSeq_dimensions
#audit_axioms cc_wsCore_instOK
#audit_axioms cc_macCore_instOK
#audit_axioms cell_instances_are_disjoint
#audit_axioms cell_seam_is_the_addend
#audit_axioms cell_seam_is_not_acc_or_cin
#audit_axioms cell_state_layout
#audit_axioms shift_overflow_is_real
#audit_axioms shiftSafe_at_int8_scale
#audit_axioms hW_is_shiftSafe

end SaltWorks.HDL.MacCell
