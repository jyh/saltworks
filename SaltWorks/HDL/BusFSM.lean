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
landed at PR #14), state `(kind, beat)`:
```
retire  = kind = FETCH → ¬req  |  kind = LOAD → beat  |  kind = STORE → beat  |  IDLE → true
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
✅ **AND SINCE 2026-09-06 THAT SENTENCE IS NO LONGER ONLY A SENTENCE.** A docstring cannot fail,
which is why the confession above stood for two days while being perfectly true. The check is
`docs/ledger-tools/rtl_transcription_drift.sh`, and this is the pin it reads:

    RTL-PIN busadapt8.v logic-sha256/16 = 68c0a0ce98178e58

It hashes `busadapt8.v` with COMMENTS STRIPPED, so a comment-only RTL commit does NOT fire it
(measured: silicon's `1916ea0..afa8a2e` touched that file with a 47-line raw diff and an EMPTY
non-comment delta) while a logic commit DOES (measured: `9769fa1..035241f`, 13 non-comment delta
lines, **0** `.lean` files -- the event this whole paragraph is about).
⛔ **IF THE PIN AND THE RTL DISAGREE, RE-READ THE SOURCE AND FIX THE TRANSCRIPTION FIRST.
RE-PINNING IS THE LAST STEP, BECAUSE THE PIN IS THE RECORD THAT A HUMAN LOOKED.**
⚠️ It certifies only that the SOURCE HAS NOT MOVED. That the transcription was ever CORRECT is
still the load-bearing reading, and no check in this repo carries it.
✅ **NAME DEBT PAID 2026-09-06 — THE FIELD WAS `storeBeat` AND IS NOW `beat`.** It carries the
data beat of EITHER memory loop; the RTL keeps two registers (`store_beat`, `load_beat`) and
`kind` already discriminates them, so one field was always faithful to `retire` while the NAME
was not. The 09-04 note set the trigger *"rename when this file is next opened for any other
reason"* and modelling the `sof` arm below is that reason.
⛔ **THE OLD NAME IS WRITTEN HERE ON PURPOSE, AND IT IS THE ONLY REASON TEN PROSE CITATIONS STILL
RESOLVE.** `storeBeat` is named in `docs/` — the R10 flagship statement, the R10 sitting table,
the two 08-26 contract notes — all of them DATED RECORDS, left verbatim because a dated document
said the name that was true on its date and rewriting it would be forging the record. **No
`.lean` file DECLARES the old name any more; the only three occurrences left in the tree are the
ones in this note**, which is exactly what makes a grep land here — the same device
`load_takes_two` gets below.
⚠️ **I FIRST WROTE THAT SENTENCE AS "a grep for `storeBeat` now finds nothing in any `.lean`",
AND WRITING IT INTO A `.lean` MADE IT FALSE** — the build was green, the claim was false, and the
falsifier was the claim itself. This seat banked *"an absence claim SELF-FALSIFIES on
publication"* weeks ago and I reproduced it inside the sentence citing the discipline. ⇒ **STATE
ABSENCE OVER DECLARATIONS, NEVER OVER TEXT** — a mention is not a declaration, and only the
build log can tell them apart.
⛔⛔ **AND THE DEBT'S OWN THREE NUMBERS DISAGREED, WHICH IS THE FINDING WORTH MORE THAN THE
RENAME.** The note said **22 uses**; the lead re-measured **24** at origin/master on 09-06; the
rename touched **26**. All three are honest and none is a correction of another: 22 was stale,
24 is LINES CONTAINING the token, 26 is OCCURRENCES — and `BusFSM:17` and `StallsAtWidened:17`
each carry it twice, which is the whole of the gap. ⇒ **A DEFERRAL AGES IN ITS COUNT AND ITS
COUNT'S DEFINITION, and "uses" was never defined.** The number a rename must satisfy is
OCCURRENCES; the number a reviewer naturally greps is LINES; nothing anywhere said which.

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
`instr_r` is written on the phase-3 edge and `kind`/`beat` update on that SAME edge, so the
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
  beat : Bool
  deriving Repr, DecidableEq, Inhabited

/-- `busadapt8.v:160-162`, a decode of the frame introducing no new state. -/
def retire (s : BusState) (req : Bool) : Bool :=
  match s.kind with
  | .fetch => !req
  | .load  => s.beat   -- option (2): the LOAD's data beat, mirroring the store's
  | .store => s.beat
  | .idle  => true

/-- `busadapt8.v:138-157`, the loop-end transition. -/
def next (s : BusState) (req we : Bool) : BusState :=
  if retire s req then { kind := .fetch, beat := false }
  else if s.kind = .fetch then { kind := if we then .store else .load, beat := false }
  else { s with beat := true }

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
  | .store => if s.beat then .dmemWdata else .dmemAddr
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


/-! ## T3-SCOPE — THE `sof` ARM: THE TRANSITION NO THEOREM ABOVE CAN SEE

⭐⭐ **EVERY THEOREM ABOVE THIS LINE IS ABOUT `next`, AND `next` IS ONE ARM OF A THREE-ARM STATE
UPDATE.** `busadapt8.v:192-207` is a priority chain:

```
if (!rst_n)        → (T_FETCH, 0, 0)                                  reset
else if (sof)      → beats cleared; kind ⟵ c_dmem_req ? … : T_FETCH   REALIGN   ← NOT MODELLED
else if (loop_end) → the retire / fetch / beat chain                  LOOP END  ← `next`
                     (no arm)  → hold                                 HOLD
```

**`BusFSM.next` transcribes the third arm only, and nothing in this file said so.** The
consequence is not that a theorem here is wrong — every one of them is true of `next`. It is
that `no_deadlock`, `bounded_wait`, `only_three_costs` and `adapterNext_correct` are all
*silent* about a transition the shipped machine performs. ⇒ 🔑 **A SILENCE AND A CLEAN BILL OF
HEALTH ARE THE SAME COLOUR**, and the whole verified surface is the colour of health.

⛔⛔ **THIS IS AMENDMENT 2, AND IT IS NO LONGER A HYPOTHESIS.** This seat exhibited the
asymmetry in the kernel on 09-04 and stated plainly that it had NOT traced the path to memory.
silicon traced it on the SHIPPED DUT with nothing mutated (`4d155b79`, 09-06, signed and
ratified by the lead): one `sof` pulse takes host memory from **19 completed stores to 20
against 19 SW fetches**, and — the half that raised the severity — **`lw_exec` 18 → 17: an
instruction is DESTROYED, not merely a transaction repeated.** The PC advances by 4 twice for
one instruction, so it never jumps and no stride criterion can see it.

⛔ **AND MY OWN 09-04 EXHIBIT NAMED THE WRONG CELL, WHICH IS THE FINDING I WOULD KEEP.** It
filtered on `retire s req = true` — "a COMPLETED transaction" — and produced the two reachable
cells below. The measured damage is at `⟨fetch, false⟩` with a STALE decode, where `retire` is
**false**, so *my exhibit's own filter excludes the cell that actually bit*. The exhibit was
right that the arm is unsound and right that a second write was the thing to fear; it was wrong
about where. ⇒ ⭐ **A CORRECT FINDING CAN CARRY AN INCORRECT WITNESS, and the witness is the
half a reader reuses.** Both cells are stated below, marked for what each one is.

📐 **WHAT THIS MODEL STILL CANNOT SEE, DECLARED RATHER THAN LEFT TO BE DISCOVERED.** `BusState`
has no PHASE and no INSTRUCTION REGISTER. The measured defect needs both: the window is phases
0/1/2 of the following fetch loop, and the mechanism is a decode still showing the retired SW
while `pc_r` has moved on. Phase 3 is clean ONLY because the 08/18 instruction bypass — landed
for an unrelated defect — happens to put a freshly assembled word in front of the decode. **None
of that is expressible here**, and a theorem below that looks like it covers the defect covers
only its loop-level shadow. The cycle-level statement needs a phase counter this file does not
have; that is a NEW obligation, not a discharged one.
-/

/-- The REALIGN arm, `busadapt8.v:193-197`. **Note what is absent: `s`.** The arm re-derives
`kind` from the decode alone and clears the beat, so it cannot consult `retire`, which is a
function of the state. -/
def sofNext (req we : Bool) : BusState :=
  { kind := if req then (if we then .store else .load) else .fetch, beat := false }

/-- Which arm of the priority chain is selected this cycle. `busadapt8.v:192-207`. -/
structure Ctrl where
  sof     : Bool
  loopEnd : Bool
  deriving Repr, DecidableEq, Inhabited

/-- ⭐ **THE WHOLE STATE UPDATE**, reset aside — the object `next` is one arm of. -/
def step (s : BusState) (c : Ctrl) (req we : Bool) : BusState :=
  if c.sof then sofNext req we
  else if c.loopEnd then next s req we
  else s

/-- `next` IS the loop-end arm, exactly — so every theorem above is a theorem about `step`
restricted to `sof = false, loopEnd = true`, and about nothing else. -/
theorem next_is_the_loop_end_arm (s : BusState) (req we : Bool) :
    step s ⟨false, true⟩ req we = next s req we := rfl

/-- **THE ARM CANNOT CONSULT `retire`:** under a realign the next state is the same from EVERY
state, so it is independent of `retire s req` — the shape the 08/18 ruling rejected.
⛔⛔ **AND THIS THEOREM IS TRUE BY CONSTRUCTION OF `sofNext`, WHICH TAKES NO STATE ARGUMENT — SO
IT CERTIFIES MY TRANSCRIPTION AND NOT THE MACHINE.** It cannot fail, and a theorem that cannot
fail re-proves green with nobody deciding. It is kept because it makes the transcription's
commitment CHECKABLE BY A READER against `busadapt8.v:193-197` — the fidelity of that reading is
the load-bearing step, and no theorem in this file can carry it. Same caveat, verbatim, for
`state_is_held_between_loop_ends` below. The contentful theorems in this section are the ones
that COMPUTE a disagreement: `sof_reissues_exactly_two_reachable_cells` and the two `(A)`
readings, which return answers I did not put in. -/
theorem sof_arm_ignores_the_state :
    allStates.all (fun a => allStates.all fun b =>
      [false, true].all fun req => [false, true].all fun we =>
        [false, true].all fun le =>
          step a ⟨true, le⟩ req we == step b ⟨true, le⟩ req we) = true := by
  decide +kernel

/-- ⛔⛔ **THE GAP, AS ONE THEOREM: WITHOUT `sof` THE STATE MOVES ONLY AT A LOOP END.** This is
the invariant every loop-counting theorem above silently assumes. -/
theorem state_is_held_between_loop_ends :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      step s ⟨false, false⟩ req we == s) = true := by
  decide +kernel

/-- ⛔⛔ **AND `sof` BREAKS IT — A MID-LOOP TRANSITION, WHICH IS THE MEASURED MECHANISM.** At
`⟨fetch, false⟩` with the decode still showing a store, a realign fired between loop ends moves
the machine into a fresh STORE transaction while a fetch is in flight. `retire` is FALSE here,
which is why the 09-04 exhibit's filter could not see it. -/
theorem sof_moves_the_state_mid_loop :
    step ⟨.fetch, false⟩ ⟨true, false⟩ true true = ⟨.store, false⟩
  ∧ step ⟨.fetch, false⟩ ⟨false, false⟩ true true = ⟨.fetch, false⟩
  ∧ retire ⟨.fetch, false⟩ true = false := by
  decide +kernel

/-- The six states the machine can actually occupy. `idle` is a modelling artifact: no arm
produces it and reset does not. -/
def reachableStates : List BusState :=
  [ .fetch, .load, .store ].flatMap fun k => [⟨k, false⟩, ⟨k, true⟩]

/-- `idle` is unreachable under BOTH arms, which is what licenses the cut from four to two. -/
theorem idle_is_unreachable :
    allStates.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      ((next s req we).kind != .idle) && ((sofNext req we).kind != .idle)) = true := by
  decide +kernel

/-- States where the transaction is COMPLETE and the two arms disagree — the 09-04 exhibit,
now in the model instead of in a bank. -/
def sofReissues (l : List BusState) (req we : Bool) : List BusState :=
  l.filter fun s => retire s req && (sofNext req we != next s req we)

/-- ⭐ **THE EXHIBIT, PINNED BY ITS MEMBERS AND NOT BY ITS COUNT.** Raw four over all eight
states; exactly two once `idle` is cut. Printing the list rather than the length is deliberate —
a count cannot be checked against the machine, and a membership can. -/
theorem sof_reissues_exactly_two_reachable_cells :
    sofReissues allStates true true
      = [⟨.idle, false⟩, ⟨.idle, true⟩, ⟨.load, true⟩, ⟨.store, true⟩]
  ∧ sofReissues reachableStates true true = [⟨.load, true⟩, ⟨.store, true⟩]
  ∧ sofReissues reachableStates true false = [⟨.load, true⟩, ⟨.store, true⟩] := by
  decide +kernel

/-- ⛔ **THE STORE CELL — RE-ENTRY IS A SECOND WRITE.** The loop-end arm ends the transaction;
the realign arm puts the machine back at the store's ADDRESS beat, which is a whole second store.
**MEASURED: stores 19 → 20 against 19 SW fetches** (silicon, `4d155b79`). -/
theorem sof_re_enters_the_store :
    retire ⟨.store, true⟩ true = true
  ∧ next ⟨.store, true⟩ true true = ⟨.fetch, false⟩
  ∧ sofNext true true = ⟨.store, false⟩
  ∧ outWord ⟨.store, false⟩ = OutWord.dmemAddr := by
  decide +kernel

/-- ⛔ **SCOPE, AS A THEOREM RATHER THAN AS PROSE: `loopsToRetire` COUNTS LOOP-END STEPS.** It is
defined by iterating `next`, so `no_deadlock` and `bounded_wait` bound the number of LOOP ENDS to
a retire and say nothing about how many CYCLES the machine spends, nor whether a realign resets
the count. Under a realign every cell below returns to a fresh transaction, so the bound is a
bound on an interval no `sof` interrupts. -/
theorem loops_are_counted_through_the_loop_end_arm (s : BusState) (req we : Bool) :
    loopsToRetire s req we
      = (if retire s req then 1
         else if retire (step s ⟨false, true⟩ req we) req then 2
         else if retire (step (step s ⟨false, true⟩ req we) ⟨false, true⟩ req we) req then 3
         else 0) := rfl

/-! ### THE REPAIR — TWO SHAPES, AND A QUESTION I AM PUTTING BACK RATHER THAN ANSWERING

silicon recommends shape **(B)**, a "fetch owed" bit, and asks this seat's eye on the DriveMap
half before anything lands, because (B) puts SEQUENCING in the adapter and that is the exact
reasoning that chose shape (A) in 08/18.

⛔⛔ **BEFORE THAT RULING CAN BE GIVEN, SHAPE (A) HAS TWO READINGS AND THEY ARE OPPOSITE.**
*"Gate the arm on `retire`"* can mean SUPPRESS the realign while `retire` is high, or PERMIT it
only while `retire` is high. Both are natural readings of four words. Modelled below and
kernel-checked, they do not merely differ in strength — **one of them is inert on the measured
cell and the other blocks it** — so the ruling silicon wants cannot be given against the phrase.
This is not a quibble about wording: at the damaging cell `retire` is FALSE, and every reading
turns on that one bit.
-/

/-- Shape (A), reading 1: the realign is SUPPRESSED while `retire` is high. -/
def stepA_suppress (s : BusState) (c : Ctrl) (req we : Bool) : BusState :=
  if c.sof && !retire s req then sofNext req we
  else if c.loopEnd then next s req we
  else s

/-- Shape (A), reading 2: the realign is PERMITTED only while `retire` is high. -/
def stepA_permit (s : BusState) (c : Ctrl) (req we : Bool) : BusState :=
  if c.sof && retire s req then sofNext req we
  else if c.loopEnd then next s req we
  else s

/-- ⛔⛔ **THE TWO READINGS SPLIT ON THE MEASURED CELL, AND READING 1 IS INERT THERE.** At
`⟨fetch, false⟩` with a stale store decode — silicon's `TR 0 → TR 1` — `retire` is false, so
reading 1 still performs the hijack while reading 2 holds the fetch. **A repair named by four
words is two repairs, one of which does nothing to the defect it was proposed for.** -/
theorem the_two_readings_of_A_disagree_at_the_measured_cell :
    stepA_suppress ⟨.fetch, false⟩ ⟨true, false⟩ true true = ⟨.store, false⟩
  ∧ stepA_permit   ⟨.fetch, false⟩ ⟨true, false⟩ true true = ⟨.fetch, false⟩ := by
  decide +kernel

/-- ⛔ **AND THEY SPLIT THE OTHER WAY ON MY 09-04 CELLS**, where `retire` IS high: reading 1
blocks the re-issue and reading 2 performs it. **Neither reading covers both cells**, which is
the whole content of this block and the reason (A) cannot be ruled on as stated. -/
theorem neither_reading_of_A_covers_both_cells :
    stepA_suppress ⟨.store, true⟩ ⟨true, false⟩ true true = ⟨.store, true⟩
  ∧ stepA_permit   ⟨.store, true⟩ ⟨true, false⟩ true true = ⟨.store, false⟩ := by
  decide +kernel

#audit_axioms sofNext step next_is_the_loop_end_arm sof_arm_ignores_the_state
#audit_axioms state_is_held_between_loop_ends sof_moves_the_state_mid_loop
#audit_axioms reachableStates idle_is_unreachable sofReissues
#audit_axioms sof_reissues_exactly_two_reachable_cells sof_re_enters_the_store
#audit_axioms loops_are_counted_through_the_loop_end_arm
#audit_axioms stepA_suppress stepA_permit
#audit_axioms the_two_readings_of_A_disagree_at_the_measured_cell
#audit_axioms neither_reading_of_A_covers_both_cells


/-! ### SHAPE (B), PRICED IN THE KERNEL BEFORE THE RULING — NOT PRE-EMPTING IT

The Captain's decision at the 07:41 sitting is whether to re-submit; shape (B) is what silicon
recommends and what carries both technical signatures (mine on the `DriveMap` half, silicon's on
the shape). **Nothing here lands a repair.** It answers, ahead of the ruling, the one question
that is mine to answer and that a ruling cannot wait on: **does (B) disturb the surface this file
already proves?**

silicon's rule: *after a memory instruction retires and before the next is assembled the ONLY
correct `kind` is `fetch` — there is nothing to re-derive from.* So the adapter carries a bit
saying "a fetch is owed", and the realign arm consults THAT instead of a decode that may still
describe the retired instruction.
-/

/-- Shape (B)'s state: the (2) state plus the fetch-owed bit. -/
structure BusStateB where
  kind      : Kind
  beat      : Bool
  fetchOwed : Bool
  deriving Repr, DecidableEq, Inhabited

/-- Forget the new bit. This is the map under which (B) must look like the machine I proved. -/
def proj (s : BusStateB) : BusState := ⟨s.kind, s.beat⟩

def retireB (s : BusStateB) (req : Bool) : Bool := retire (proj s) req

/-- The loop-end arm under (B). The bit is SET when an instruction retires (a fetch is now owed)
and CLEARED when a fetch loop commits a memory instruction — i.e. when a decode becomes
trustworthy. -/
def nextB (s : BusStateB) (req we : Bool) : BusStateB :=
  if retireB s req then { kind := .fetch, beat := false, fetchOwed := true }
  else if s.kind = .fetch then
    { kind := if we then .store else .load, beat := false, fetchOwed := false }
  else { s with beat := true }

/-- The realign arm under (B): while a fetch is owed, a realign HOLDS the fetch. -/
def sofNextB (s : BusStateB) (req we : Bool) : BusStateB :=
  if s.fetchOwed then { kind := .fetch, beat := false, fetchOwed := true }
  else { kind := if req then (if we then .store else .load) else .fetch
       , beat := false, fetchOwed := false }

def stepB (s : BusStateB) (c : Ctrl) (req we : Bool) : BusStateB :=
  if c.sof then sofNextB s req we
  else if c.loopEnd then nextB s req we
  else s

/-- The sixteen states of (B). -/
def allStatesB : List BusStateB :=
  [ .idle, .fetch, .load, .store ].flatMap fun k =>
    [ ⟨k, false, false⟩, ⟨k, false, true⟩, ⟨k, true, false⟩, ⟨k, true, true⟩ ]

theorem allStatesB_card : allStatesB.length = 16 := by decide +kernel

/-- ⭐⭐⭐ **THE RESULT THAT MATTERS TO THIS FILE: (B) DOES NOT MOVE THE LOOP-END ARM.** Under the
projection that forgets `fetchOwed`, `nextB` IS `next` — on all sixteen states and all four
inputs. **So every theorem above this section survives shape (B) unchanged**: `no_deadlock`,
`bounded_wait`, `only_three_costs`, `reachable_costs_are_exactly_one_and_three`, `retire_resets`,
the T5 block, and `adapterNext_correct`'s 32-input sweep all describe `next`, and `next` is what
(B) still does at a loop end.
⚖️ **This is the compiler seat's half of the two-signature row, and it is the half that could
have refused (B):** a repair that changed the loop-end transition would have invalidated the
verified surface and cost a re-proof, which is a real price on a 30-hour clock. It does not. -/
theorem shapeB_leaves_the_loop_end_arm_alone :
    allStatesB.all (fun s => [false, true].all fun req => [false, true].all fun we =>
      proj (nextB s req we) == next (proj s) req we) = true := by
  decide +kernel

/-- And `retire` itself is untouched, which is what `DriveMap` cares about: (B) adds no term to
the decode. -/
theorem shapeB_does_not_move_retire :
    allStatesB.all (fun s => [false, true].all fun req =>
      retireB s req == retire (proj s) req) = true := by
  decide +kernel

/-- ⭐⭐ **(B) CLOSES THE CELL THAT BIT.** silicon's `TR 0 → TR 1`: a fetch in flight, the decode
still showing the retired SW, a realign mid-loop. Under (B) the fetch is HELD. Compare
`sof_moves_the_state_mid_loop` above, where the same cell produced a fresh store. -/
theorem shapeB_holds_the_fetch_at_the_measured_cell :
    stepB ⟨.fetch, false, true⟩ ⟨true, false⟩ true true = ⟨.fetch, false, true⟩ := by
  decide +kernel

/-- ⭐⭐ **AND IT CLOSES MY 09-04 CELLS TOO — the ones `stepA_permit` re-issued.** A completed
store, then a realign: the machine stays at a fetch instead of re-entering `T_STORE`. **Neither
reading of (A) covered both; (B) covers both.** -/
theorem shapeB_closes_both_cells :
    stepB ⟨.fetch, false, true⟩ ⟨true, false⟩ true true = ⟨.fetch, false, true⟩
  ∧ (stepB ⟨.store, true, false⟩ ⟨false, true⟩ true true).fetchOwed = true
  ∧ stepB ⟨.store, true, true⟩ ⟨true, false⟩ true true = ⟨.fetch, false, true⟩ := by
  decide +kernel

/-- ⛔ **THE NEGATIVE CONTROL, SO THIS IS NOT A REPAIR THAT SIMPLY FREEZES THE MACHINE.** With no
fetch owed, the realign arm still realigns — (B) restricts the arm, it does not delete it. Without
this, every theorem above would also hold of a `sof` that did nothing at all. -/
theorem shapeB_still_realigns_when_no_fetch_is_owed :
    stepB ⟨.fetch, false, false⟩ ⟨true, false⟩ true true = ⟨.store, false, false⟩
  ∧ stepB ⟨.fetch, false, false⟩ ⟨true, false⟩ false false = ⟨.fetch, false, false⟩ := by
  decide +kernel

/-- ⛔ **AND THE BIT IS REACHABLE IN BOTH VALUES FROM A RESET START** — so neither arm of the
control above is vacuous on the machine as it actually runs. -/
theorem shapeB_bit_takes_both_values_from_reset :
    (nextB ⟨.fetch, false, false⟩ false false).fetchOwed = true
  ∧ (nextB ⟨.fetch, false, false⟩ true true).fetchOwed = false := by
  decide +kernel

#audit_axioms BusStateB proj retireB nextB sofNextB stepB allStatesB allStatesB_card
#audit_axioms shapeB_leaves_the_loop_end_arm_alone shapeB_does_not_move_retire
#audit_axioms shapeB_holds_the_fetch_at_the_measured_cell shapeB_closes_both_cells
#audit_axioms shapeB_still_realigns_when_no_fetch_is_owed
#audit_axioms shapeB_bit_takes_both_values_from_reset


/-! #### WHICH CLAIM CATCHES WHICH WRONG (B) — the controls' scope, measured, not asserted

I first wrote in a landing post that without the realign control *"every theorem above would hold
just as well of a `sof` arm that did nothing at all"*. **`claimcheck` flagged the sentence, I drove
the mutants, and it is FALSE.** The two wrong shapes of (B) are caught by different claims, and
one of them is caught by exactly one. Landed as theorems rather than left in the scratch file that
produced them, because a measurement in a scratch file protects nothing.
-/

/-- WRONG (B) #1: the realign arm does nothing — the "freeze" repair. -/
def sofNextB_noop (s : BusStateB) (_req _we : Bool) : BusStateB := s

/-- WRONG (B) #2: the realign arm ALWAYS holds fetch — over-restriction. This is the dangerous
one: it repairs the defect and quietly deletes the realign protocol. -/
def sofNextB_always (s : BusStateB) (_req _we : Bool) : BusStateB :=
  { kind := .fetch, beat := false, fetchOwed := s.fetchOwed }

def stepB_with (f : BusStateB → Bool → Bool → BusStateB)
    (s : BusStateB) (c : Ctrl) (req we : Bool) : BusStateB :=
  if c.sof then f s req we else if c.loopEnd then nextB s req we else s

/-- ⛔⛔ **THE CONTROLS' SCOPE, AS A TABLE THE KERNEL CHECKED.** `true` = the wrong shape SATISFIES
that claim, i.e. the claim is BLIND to it.
```
                            holds_fetch   closes_both(3rd)   still_realigns
  #1 no-op                     BLIND           catches           catches
  #2 always-hold-fetch         BLIND            BLIND            catches
```
⇒ **`shapeB_still_realigns_when_no_fetch_is_owed` IS THE ONLY CLAIM THAT CATCHES #2**, and #2 is
the shape a hurried repair actually reaches: it closes the measured cell AND my 09-04 cells and
passes every positive theorem in this section. **Delete that one control and the over-restricting
repair ships green.** -/
theorem which_control_catches_which_wrong_B :
    -- #1 satisfies the fetch-hold claim, and FAILS the other two
    (stepB_with sofNextB_noop ⟨.fetch, false, true⟩ ⟨true, false⟩ true true
       == ⟨.fetch, false, true⟩) = true
  ∧ (stepB_with sofNextB_noop ⟨.store, true, true⟩ ⟨true, false⟩ true true
       == ⟨.fetch, false, true⟩) = false
  ∧ (stepB_with sofNextB_noop ⟨.fetch, false, false⟩ ⟨true, false⟩ true true
       == ⟨.store, false, false⟩) = false
    -- #2 satisfies BOTH positive claims, and is caught ONLY by the realign control
  ∧ (stepB_with sofNextB_always ⟨.fetch, false, true⟩ ⟨true, false⟩ true true
       == ⟨.fetch, false, true⟩) = true
  ∧ (stepB_with sofNextB_always ⟨.store, true, true⟩ ⟨true, false⟩ true true
       == ⟨.fetch, false, true⟩) = true
  ∧ (stepB_with sofNextB_always ⟨.fetch, false, false⟩ ⟨true, false⟩ true true
       == ⟨.store, false, false⟩) = false := by
  decide +kernel

/-- ⛔ **AND THE PROJECTION THEOREM IS BLIND TO BOTH, BY CONSTRUCTION.** Neither wrong shape touches
`nextB`, so `shapeB_leaves_the_loop_end_arm_alone` holds of both. **It certifies the LOOP-END arm
and says nothing whatever about the realign arm** — stated here so its strength is not borrowed by
the claim next to it. The two theorems are about different arms of the same machine. -/
theorem the_projection_theorem_cannot_see_the_realign_arm :
    (allStatesB.all fun s => [false, true].all fun req => [false, true].all fun we =>
      proj (nextB s req we) == next (proj s) req we) = true
  ∧ (stepB_with sofNextB_noop   ⟨.store, true, true⟩ ⟨true, false⟩ true true
       == ⟨.fetch, false, true⟩) = false
  ∧ (stepB_with sofNextB_always ⟨.fetch, false, false⟩ ⟨true, false⟩ true true
       == ⟨.store, false, false⟩) = false := by
  decide +kernel

#audit_axioms sofNextB_noop sofNextB_always stepB_with
#audit_axioms which_control_catches_which_wrong_B
#audit_axioms the_projection_theorem_cannot_see_the_realign_arm

end SaltWorks.HDL.BusFSM
