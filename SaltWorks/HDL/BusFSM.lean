/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# T3 — THE BUS-PROTOCOL FSM, MODELLED AND PROVED NON-DEADLOCKING

The temporal ownership table gives silicon T3 (**bus-protocol FSM proof**) and T4
(**arbitration fairness, restated as BOUNDED WAIT**), and names the control that would catch
their absence: *"a trace where the FSM deadlocks mid-transaction and every current check stays
green."* `busadapt8.v` implements the machine; **nothing modelled it**, so no such trace could
be refused by anything but simulation.

⭐ **THE MACHINE, READ OFF THE RTL** (`busadapt8.v:132-162`), state `(kind, storeBeat)`:
```
retire  = kind = FETCH → ¬req  |  kind = LOAD → true  |  kind = STORE → storeBeat  |  IDLE → true
next    = retire            → (FETCH, false)
          kind = FETCH      → (if we then STORE else LOAD, false)
          otherwise         → (kind, true)          -- the store's data beat
```
🔑 **AND THIS IS WHY THE MEASURED CPI HISTOGRAM HAS EXACTLY THREE BUCKETS.** One loop is four
phases, so the loop count per instruction IS the CPI/4:
```
FETCH, ¬req                        1 loop  =  4 cycles
FETCH → LOAD → retire              2 loops =  8 cycles
FETCH → STORE → STORE(beat) → ret  3 loops = 12 cycles
```
*The arbitration simulation measured `4cyc=28 · 8cyc=14 · 12cyc=14 · other=0`. `other=0` is not
luck — it is this state graph having no fourth path, and that is what the theorems below say.*

⚠️ **CARRIED FORWARD, NOT SMOOTHED — the RTL's own open question** (`busadapt8.v:126-131`):
`instr_r` is written on the phase-3 edge and `kind`/`storeBeat` update on that SAME edge, so the
decision reads a `c_dmem_req` derived from the PREVIOUS instruction. **Whether that is off-by-one
or exactly right is NOT settled here.** This file models the state graph as written; the
req-timing question is a different obligation and stays open.
-/
import SaltWorks.HDL.Sem

namespace SaltWorks.HDL.BusFSM

/-- What this loop is doing. `busadapt8.v:76`. -/
inductive Kind where
  | idle | fetch | load | store
  deriving Repr, DecidableEq, Inhabited

/-- The FSM's whole state: the loop kind and the store's beat flag. -/
structure BusState where
  kind      : Kind
  storeBeat : Bool
  deriving Repr, DecidableEq, Inhabited

/-- `busadapt8.v:160-162`, a decode of the frame introducing no new state. -/
def retire (s : BusState) (req : Bool) : Bool :=
  match s.kind with
  | .fetch => !req
  | .load  => true
  | .store => s.storeBeat
  | .idle  => true

/-- `busadapt8.v:138-157`, the loop-end transition. -/
def next (s : BusState) (req we : Bool) : BusState :=
  if retire s req then { kind := .fetch, storeBeat := false }
  else if s.kind = .fetch then { kind := if we then .store else .load, storeBeat := false }
  else { s with storeBeat := true }

/-- The eight states, for exhaustive checking. -/
def allStates : List BusState :=
  [ .idle, .fetch, .load, .store ].flatMap fun k => [⟨k, false⟩, ⟨k, true⟩]

theorem allStates_card : allStates.length = 8 := by decide +kernel

/-- Loops until the next retire, from a state, under a fixed request pattern. -/
def loopsToRetire (s : BusState) (req we : Bool) : Nat :=
  if retire s req then 1
  else if retire (next s req we) req then 2
  else if retire (next (next s req we) req we) req then 3
  else 0   -- 0 marks "not within three", which the theorem below rules out

/-- ⭐⭐⭐ **T3 — THE FSM CANNOT DEADLOCK.** From EVERY state, under EVERY request pattern, a
retire occurs within three loops. *`loopsToRetire = 0` is the encoding of "did not retire in
three", and it never happens.* -/
theorem no_deadlock :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      loopsToRetire s req we != 0) = true := by
  decide +kernel

/-- ⭐⭐ **T4 — BOUNDED WAIT, with the bound stated as a number.** No instruction occupies more
than three bus loops, i.e. **12 cycles at four phases per loop** — §7's worst-case CPI, here as
a property of the state graph rather than a measurement. -/
theorem bounded_wait :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      loopsToRetire s req we ≤ 3) = true := by
  decide +kernel

/-- ⭐ **THE THREE BUCKETS ARE EXHAUSTIVE — this is what the simulation's `other=0` means.**
Every reachable loop count is 1, 2 or 3, so every CPI is 4, 8 or 12 and there is no fourth
path through the machine. -/
theorem only_three_costs :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      let n := loopsToRetire s req we
      n = 1 || n = 2 || n = 3) = true := by
  decide +kernel

/-- ⭐ **EVERY RETIRE RETURNS TO `fetch` WITH THE BEAT CLEARED** — the machine cannot carry a
stale store beat into the next instruction, which is the state-corruption a deadlock trace
would otherwise hide. -/
theorem retire_resets :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      !(retire s req) || (next s req we == ⟨.fetch, false⟩)) = true := by
  decide +kernel

/-- ⛔ **AND THE STORE PATH REALLY DOES TAKE THREE — a negative control, so `bounded_wait` is
not vacuously true of a machine that always retires at once.** A committed store from `fetch`
takes exactly three loops. -/
theorem store_takes_three :
    loopsToRetire ⟨.fetch, false⟩ true true = 3 := by decide +kernel

/-- And a plain instruction takes exactly one, so the bound is TIGHT at both ends. -/
theorem plain_takes_one :
    loopsToRetire ⟨.fetch, false⟩ false false = 1 := by decide +kernel

/-- A load takes exactly two. -/
theorem load_takes_two :
    loopsToRetire ⟨.fetch, false⟩ true false = 2 := by decide +kernel

#audit_axioms retire next allStates allStates_card loopsToRetire
#audit_axioms no_deadlock bounded_wait only_three_costs retire_resets
#audit_axioms store_takes_three plain_takes_one load_takes_two

end SaltWorks.HDL.BusFSM
