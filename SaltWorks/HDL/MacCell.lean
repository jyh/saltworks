import SaltWorks.HDL.Seq
import SaltWorks.HDL.Compose
import SaltWorks.HDL.Adder

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

end SaltWorks.HDL.MacCell
