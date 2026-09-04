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

⭐ **THE MACHINE, READ OFF THE RTL** (`busadapt8.v:184-186`, re-read 2026-09-04 AFTER option (2)
landed at PR #14), state `(kind, storeBeat)`:
```
retire  = kind = FETCH → ¬req  |  kind = LOAD → storeBeat  |  kind = STORE → storeBeat  |  IDLE → true
next    = retire            → (FETCH, false)
          kind = FETCH      → (if we then STORE else LOAD, false)
          otherwise         → (kind, true)          -- the memory loop's data beat
```
⛔ **OPTION (2), RATIFIED BY COUNCIL 09/04 AND LANDED IN THE RTL BEFORE THIS FILE MOVED.** The
`LOAD` arm was `true` — a load retired on its ADDRESS loop, giving the host no turnaround. It is
now `load_beat`, mirroring `store_beat` exactly. ⭐⭐ **AND THE GAP IS THE POINT: `busadapt8.v`
changed and NOT ONE `.lean` FILE DID** (`git diff --name-only 9769fa1..035241f -- '*.lean'` = 0),
**so the whole verified surface stayed GREEN across a ratified change to the machine.** Nothing
here is verified against the RTL; it is verified against THIS TRANSCRIPTION, and a transcription
cannot notice that its source moved. Re-read the source before trusting the block above.
⚠️ **NAME DEBT, DATED 09-04, WITH ITS TRIGGER:** the field is still called `storeBeat` and it now
carries the data beat of EITHER memory loop. The RTL keeps two registers (`store_beat`,
`load_beat`); `kind` already discriminates them, so one field is faithful to `retire` — but the
NAME is not. **Rename to `beat` when this file is next opened for any other reason** (22 uses
across 6 files, which is why it is not bundled here). Retire this note by doing that rename.

🔑 **THE CPI HISTOGRAM NOW HAS TWO BUCKETS, NOT THREE.** One loop is four phases, so the loop
count per instruction IS the CPI/4:
```
FETCH, ¬req                        1 loop  =  4 cycles
FETCH → LOAD → LOAD(beat) → ret    3 loops = 12 cycles   ← was 2 loops / 8 cycles
FETCH → STORE → STORE(beat) → ret  3 loops = 12 cycles
```
⛔ **THE `8cyc` BUCKET IS EMPTY UNDER OPTION (2), AND THE OLD SENTENCE HERE CLAIMED THREE.** The
08/26 arbitration sim measured `4cyc=28 · 8cyc=14 · 12cyc=14 · other=0` on the PRE-option-(2)
machine; under (2) that trace's shape becomes `4cyc=28 · 12cyc=28`. ⚠️ **THAT SECOND FIGURE IS
ARITHMETIC ON ONE SIM'S HISTOGRAM, NOT A RE-RUN** — silicon's measurement, forwarded, and it is
the only measurement any of it rests on. `other=0` remains not luck: it is this state graph
having no fourth path, and `only_three_costs` below is the reason rather than the evidence.

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
  | .load  => s.storeBeat   -- option (2): the LOAD's data beat, mirroring the store's
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

/-- ⭐ **NO FOURTH PATH — this is what the simulation's `other=0` means.** Every reachable loop
count is 1, 2 or 3.
⛔⛔ **THIS DOCSTRING USED TO SAY "so every CPI is 4, 8 or 12", AND IT SURVIVED OPTION (2)
UNCHANGED AND UNCHALLENGED, BECAUSE THE THEOREM CANNOT SEE IT.** `n = 1 || n = 2 || n = 3` is a
statement about which counts are ALLOWED, not about which are REACHED — so it stays TRUE when a
bucket EMPTIES. Under option (2) the count `2` is unreachable from an instruction start and the
`8`-cycle CPI is gone, and this theorem went on passing at 0 axioms throughout.
⇒ **A PERMISSIVE BOUND CANNOT DATE ITS OWN PROSE.** `reachable_costs_are_exactly_one_and_three`
below is the cure: it pins the set from BOTH sides, so the next change to the machine makes it
RED instead of letting the sentence rot. -/
theorem only_three_costs :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      let n := loopsToRetire s req we
      n = 1 || n = 2 || n = 3) = true := by
  decide +kernel

/-- ⭐⭐ **THE SET, PINNED FROM BOTH SIDES — the theorem the file was missing.** From an
instruction start `(fetch,false)`, the reachable loop counts are EXACTLY `{1, 3}`: 1 and 3 are
attained, and 2 is attained by NOTHING. Option (2) emptied the 2/`8cyc` bucket, and no theorem
in this file could previously say so. **Any further change to `retire` moves one of these three
conjuncts and turns this RED.** -/
theorem reachable_costs_are_exactly_one_and_three :
    loopsToRetire ⟨.fetch, false⟩ false false = 1
  ∧ loopsToRetire ⟨.fetch, false⟩ true  false = 3
  ∧ ([false, true].all fun req => [false, true].all fun we =>
       loopsToRetire ⟨.fetch, false⟩ req we != 2) = true := by
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

/-- ⭐ **A LOAD TAKES EXACTLY THREE UNDER OPTION (2).**
⚖️ **`load_takes_two` DELIBERATELY RETIRED 2026-09-04** — it said `= 2`, was true of the
pre-option-(2) machine, and became FALSE when the RTL moved. Replaced rather than joined,
because keeping it beside its successor would be keeping a false theorem; and RENAMED rather
than edited in place, so a reader who greps `load_takes_two` finds nothing and comes looking,
instead of finding a name whose meaning changed underneath them. **The retirement is CORRECT;
this line exists so the CITATION does not rot** — the standing class-B convention, applied to
the one instance this commit creates. -/
theorem load_takes_three :
    loopsToRetire ⟨.fetch, false⟩ true false = 3 := by decide +kernel

/-- ⛔⛔ **THE CONTROL THAT USED TO DISCRIMINATE, AND NO LONGER DOES — SAID OUT LOUD RATHER THAN
DELETED.** `store_takes_three` was the negative control proving `bounded_wait` is not vacuous.
Under option (2) the LOAD path also takes three, so the two controls now agree and neither one
separates the load path from the store path any more. **A control that stopped discriminating is
not a control**; the load/store distinction is carried by `retire_resets` and by the T5 block
below, and this note exists so nobody reads the surviving pair as stronger than it is. -/
theorem load_and_store_now_cost_the_same :
    loopsToRetire ⟨.fetch, false⟩ true false = loopsToRetire ⟨.fetch, false⟩ true true := by
  decide +kernel

/-- ⛔ **AND THE BOUND IS NOW REACHED, NOT APPROACHED.** Option (2) does not move
`bounded_wait`'s number — it moves the LOAD onto it. Stated so the next reader does not have to
re-derive that the two facts are compatible. -/
theorem the_bound_is_attained :
    loopsToRetire ⟨.fetch, false⟩ true false = 3
  ∧ (allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      loopsToRetire s req we ≤ 3) = true) := by decide +kernel

#audit_axioms retire next allStates allStates_card loopsToRetire
#audit_axioms no_deadlock bounded_wait only_three_costs retire_resets
#audit_axioms reachable_costs_are_exactly_one_and_three
#audit_axioms store_takes_three plain_takes_one load_takes_three
#audit_axioms load_and_store_now_cost_the_same the_bound_is_attained

/-! ## T5 — STORE-PATH TIMING. THE FINDING IS THAT `we` IS NOT AT THE PINS AT ALL.

The ownership table frames T5 as *"`dmem_we` rising vs the beat leaving the pins"*, with the
control *"`we` on beat n, data on beat n+k, and the seam theorem still elaborates."* **Measured
at the port list, the framing is too generous: `busadapt8` HAS NO WRITE-ENABLE OUTPUT.** Its
outputs are `pin_out`, `phase_pins`, `retire` — and `c_dmem_we` is an INPUT from the core that
never reaches a pin.

⇒ **So there is no `we` edge to skew against the data.** The host must instead reconstruct the
write from what the pins DO carry, and the question becomes: *can the host tell the store's
ADDRESS beat from its DATA beat?* `out_word` differs between them (`c_dmem_addr` vs
`c_dmem_wdata`), so getting it wrong writes the address into memory as data. -/

/-- What the type pins carry at phase 0. `busadapt8.v:165`. -/
def typeAtPhase0 (s : BusState) : Kind := s.kind

/-- Which word leaves on `pin_out` this loop. `busadapt8.v:168-170`, as a tag. -/
inductive OutWord where
  | imemAddr | dmemAddr | dmemWdata
  deriving Repr, DecidableEq, Inhabited

def outWord (s : BusState) : OutWord :=
  match s.kind with
  | .fetch => .imemAddr
  | .store => if s.storeBeat then .dmemWdata else .dmemAddr
  | _      => .dmemAddr

/-- ⛔⛔ **THE TWO STORE BEATS ARE INDISTINGUISHABLE ON THE TYPE PINS.** `kind` is deliberately
NOT reassigned between them (`busadapt8.v:149-155`, "the type code stays T_STORE so the host
knows the datum is coming"), so phase 0 shows `T_STORE` on both. -/
theorem store_beats_share_a_type_code :
    typeAtPhase0 ⟨.store, false⟩ = typeAtPhase0 ⟨.store, true⟩ := by decide +kernel

/-- ⛔ **AND THEY PUT DIFFERENT WORDS ON THE PINS.** Address on the first beat, store data on
the second — so a host that confuses them writes the ADDRESS into memory as the datum. -/
theorem store_beats_differ_in_payload :
    outWord ⟨.store, false⟩ ≠ outWord ⟨.store, true⟩ := by decide +kernel

/-- ⭐⭐⭐ **THE DISCRIMINATOR EXISTS, AND IT IS `retire` — THE ONE PIN WHOSE CONTRACT IS NOT
RATIFIED.** `retire` is low on the store's address beat and high on its data beat, so it is the
ONLY output that separates two loops carrying different payloads under the same type code. -/
theorem retire_separates_the_store_beats :
    retire ⟨.store, false⟩ true = false ∧ retire ⟨.store, true⟩ true = true := by
  decide +kernel

/-- ⭐ **AND NOTHING ELSE DOES.** Over every state pair that shares a type code and differs in
payload, `retire` differs too — stated as an exhaustive check so "nothing else does" is a
measurement rather than a reading of the port list. -/
theorem retire_is_the_only_separator :
    allStates.all (fun a => allStates.all fun b =>
      !(typeAtPhase0 a == typeAtPhase0 b && outWord a != outWord b)
      || (retire a true != retire b true)) = true := by
  decide +kernel

/-- ⛔ **THE T5 CONTROL, AS THE TABLE ASKED FOR IT.** *"`we` on beat n, data on beat n+k, and the
seam theorem still elaborates."* Here the analogue is sharper and it FIRES: a host reading only
the type pins cannot place the datum, because `store_beats_share_a_type_code` says the two beats
are equal there while `store_beats_differ_in_payload` says the pins carry different words.
**Type pins alone are insufficient — stated as a theorem so no seam statement can quietly assume
otherwise.** -/
theorem type_pins_are_insufficient_for_the_store_path :
    (typeAtPhase0 ⟨.store, false⟩ = typeAtPhase0 ⟨.store, true⟩)
      ∧ (outWord ⟨.store, false⟩ ≠ outWord ⟨.store, true⟩) :=
  ⟨store_beats_share_a_type_code, store_beats_differ_in_payload⟩

#audit_axioms typeAtPhase0 outWord store_beats_share_a_type_code
#audit_axioms store_beats_differ_in_payload retire_separates_the_store_beats
#audit_axioms retire_is_the_only_separator type_pins_are_insufficient_for_the_store_path

end SaltWorks.HDL.BusFSM
