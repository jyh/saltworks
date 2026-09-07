/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# THE CYCLE-LEVEL MODEL — WHERE THE `sof` WINDOW BECOMES EXPRESSIBLE

⛔⛔ **WHY THIS FILE EXISTS.** `BusFSM.BusState` is `kind × beat` and has NO PHASE. The landed
`busadapt8.v` guards its realign arm with `fetch_owed && !instr_avail`, and
`instr_avail = (kind == T_FETCH) && (phase == 2'd3)`. **A model with no phase cannot state that
guard**, so every theorem in `BusFSM.lean` is strictly coarser there and the 3-cycle window
silicon measured is not expressible in it. That gap was recorded as the standing obligation
designed at `d8d3760`.

⭐ **THE DESIGN INSIGHT, AND IT IS WHAT MAKES THIS CHEAP: YOU DO NOT NEED THE INSTRUCTION WORD,
YOU NEED ITS DECODE.** `busadapt8.v` consumes the instruction only through `c_dmem_req` and
`c_dmem_we` — two pure decodes, which is exactly and only what `DriveMap` assumes. So staleness
needs a **2-bit decode TAG**, not a 32-bit register, and the bypass becomes one line.

⭐ **ROUTE: PARALLEL, NOT REWRITE.** `req` and `we` are FREE PARAMETERS in every theorem in
`BusFSM.lean`; deriving them would be a breaking change to every statement's shape. Instead this
file adds a projection that forgets the new fields plus ONE bridge theorem, so **every existing
theorem survives unchanged** — the same route shape (B) took.

⛔ **THE BRIDGE IS THE PIECE THAT CAN FAIL**, and its failure would be a larger finding than this
file: it would mean the loop model was never a faithful abstraction, not merely a narrower one.
📌 **IT DID NOT FAIL** — `bridge_at_loop_start` holds on all 128 loop starts, so the loop model
is faithful and every theorem in `BusFSM.lean` transfers.

📐 **ONE DEVIATION FROM `d8d3760`, RECORDED SO A READER CHECKING THE DESIGN AGAINST THIS FILE IS
NOT LEFT TO WONDER.** The design priced the sweep at *"512 rows, × sof = 1024"*. This file sweeps
**512**: `sof` is not carried as a state field, because the realign is a FUNCTION of the state
(`sofKind`), and the theorem that matters compares TWO such functions POINTWISE over all 512
states. That is the same coverage in a different shape — the `sof=false` half of a 1024-row sweep
would have been the identity on both arms and decided nothing. **Stated rather than silently
re-priced: a row count is a claim about an instrument, and this one changed shape.**
-/
import SaltWorks.HDL.BusFSM

namespace SaltWorks.HDL.BusCycle

open SaltWorks.HDL.BusFSM

/-- The 2-bit decode the adapter actually consumes: `c_dmem_req` and `c_dmem_we`. **This is the
whole of the instruction, as far as `busadapt8.v` is concerned.** -/
structure Dec where
  req : Bool
  we  : Bool
  deriving Repr, DecidableEq, Inhabited

def allDec : List Dec :=
  [⟨false, false⟩, ⟨false, true⟩, ⟨true, false⟩, ⟨true, true⟩]

/-- The four phases of a bus loop. **An INDUCTIVE, not `Fin 4`, and the reason is measurable:**
with `Fin 4` every theorem in this file came out at `[1 axioms]` (`propext`, pulled in by the
`Fin`/`List` machinery — `allCyc_card` alone needed it), while every theorem in `BusFSM.lean`
is `[0 axioms]`. ⇒ **A BRIDGE THAT COSTS AN AXIOM ITS TARGET DOES NOT HAVE IS A WEAKER LINK
THAN THE TWO THINGS IT JOINS.** Matching `Kind`'s shape costs nothing and keeps the footprint
identical on both sides. -/
inductive Phase where
  | p0 | p1 | p2 | p3
  deriving Repr, DecidableEq, Inhabited

/-- Phases advance cyclically; phase 3 is loop end. -/
def Phase.succ : Phase → Phase
  | .p0 => .p1
  | .p1 => .p2
  | .p2 => .p3
  | .p3 => .p0

/-- The cycle-level state: the loop state, **the phase the loop model lacks**, and TWO decode
tags — the instruction currently driving the adapter and the one the fetch is bringing in. -/
structure CycState where
  kind    : Kind
  beat    : Bool
  phase   : Phase
  prevDec : Dec
  nextDec : Dec
  deriving Repr, DecidableEq, Inhabited

/-- Forget everything the loop model never had. This is the map under which the cycle model must
look like the machine already proved. -/
def proj (s : CycState) : BusState := ⟨s.kind, s.beat⟩

/-- `instr_avail`, transcribed from `busadapt8.v`:
`wire instr_avail = (kind == T_FETCH) && (phase == 2'd3);` -/
def instrAvail (s : CycState) : Bool := (s.kind == Kind.fetch) && (s.phase == Phase.p3)

/-- ⭐⭐ **THE BYPASS.** The instruction bypass presents the NEW word at exactly
`kind == T_FETCH && phase == 3` — and nowhere else. Off that cell the adapter is still decoding
**the instruction that already retired**. One line, and it is the whole hazard. -/
def decode (s : CycState) : Dec := if instrAvail s then s.nextDec else s.prevDec

/-- The decode in force at the loop end, from a state at any phase of the same loop. `kind` and
the tags do not move between phases, so this is `decode` at phase 3. -/
def endDecode (s : CycState) : Dec := if s.kind == Kind.fetch then s.nextDec else s.prevDec

/-- ONE CYCLE. The phase advances; at phase 3 — loop end — the loop-level transition fires with
`req`/`we` **DERIVED from the decode** rather than taken as free parameters, and a completed
fetch makes the incoming word current. -/
def cycNext (s : CycState) : CycState :=
  if s.phase == Phase.p3 then
    let d := decode s
    let s' := next (proj s) d.req d.we
    { kind    := s'.kind
    , beat    := s'.beat
    , phase   := Phase.p0
    , prevDec := if s.kind == Kind.fetch then s.nextDec else s.prevDec
    , nextDec := s.nextDec }
  else
    { s with phase := s.phase.succ }

/-- Four cycles is one bus loop. -/
def loopStep (s : CycState) : CycState := cycNext (cycNext (cycNext (cycNext s)))

/-- All 512 cycle states: `kind × beat × phase × prevDec × nextDec`. -/
def allCyc : List CycState :=
  [Kind.idle, Kind.fetch, Kind.load, Kind.store].flatMap fun k =>
    [false, true].flatMap fun b =>
      [Phase.p0, Phase.p1, Phase.p2, Phase.p3].flatMap fun p =>
        allDec.flatMap fun pd =>
          allDec.map fun nd => ⟨k, b, p, pd, nd⟩

theorem allCyc_card : allCyc.length = 512 := by decide +kernel

/-- The 128 states at a loop START, where the bridge is stated. -/
def allCyc0 : List CycState := allCyc.filter (fun s => s.phase == Phase.p0)

theorem allCyc0_card : allCyc0.length = 128 := by decide +kernel

/-- ⭐⭐⭐ **THE BRIDGE — AND IT IS THE PIECE THAT COULD HAVE REFUTED THE WHOLE LOOP MODEL.**
From every loop start, four cycles of the cycle-level machine project onto exactly one step of
`BusFSM.next`, with the free parameters `req`/`we` instantiated by the decode in force at the
loop end. **So the loop model is a faithful abstraction of the cycle model, not merely a
narrower one — and every theorem in `BusFSM.lean` transfers unchanged.** -/
theorem bridge_at_loop_start :
    allCyc0.all (fun s =>
      proj (loopStep s) == next (proj s) (endDecode s).req (endDecode s).we) = true := by
  decide +kernel

/-- What a realign re-derives the loop kind to be, from a decode. `busadapt8.v`'s `sof` arm. -/
def rederive (d : Dec) : Kind :=
  if d.req then (if d.we then Kind.store else Kind.load) else Kind.fetch

/-- The realign arm as LANDED: re-derive from `decode`, i.e. **with** the bypass. -/
def sofKind (s : CycState) : Kind := rederive (decode s)

/-- ⛔ THE MUTANT: the same arm with the **bypass DEFEATED** — always the previous decode. This
is the control, and it exists so the theorem below has something it could have failed against. -/
def sofKindNoBypass (s : CycState) : Kind := rederive s.prevDec

/-- ⭐⭐⭐ **`the_bypass_is_the_protection` — AND IT IS A CHARACTERISATION, NOT A RESTATEMENT.**
The landed arm and the bypass-defeated arm differ at **exactly** the cells where the bypass is
presenting (`instr_avail`) AND the two decodes re-derive to different kinds. Stated as an
`==` over all 512 rows, so it is false if the differing set is any larger or any smaller.
⛔ Note the second conjunct is doing real work: `rederive` ignores `we` when `req` is false, so
`prevDec ≠ nextDec` does **not** imply the kinds differ. -/
theorem the_bypass_is_the_protection :
    allCyc.all (fun s =>
      (sofKind s != sofKindNoBypass s) ==
        (instrAvail s && (rederive s.prevDec != rederive s.nextDec))) = true := by
  decide +kernel

/-- ⛔ **CONTROL 1 — THE DIFFERING SET IS NON-EMPTY.** A characterisation over an EMPTY set is
true and worthless, so its size is pinned: a change to the model cannot quietly empty it, and
20 is the kernel's number, not mine — I guessed 24 and `decide +kernel` refused.

⛔⛔ **AND THE NAME OF THIS THEOREM IS DELIBERATELY *NOT* "reached".** The design named this
control *"the window must be REACHED, not merely allowed"*, and **this theorem does not
establish that.** It quantifies over the ENUMERATED state space, which is every combination of
the fields — it says nothing about which of those states the machine can actually get into from
reset. ⇒ **NON-EMPTY IN AN ENUMERATION IS NOT REACHABLE FROM RESET**, and calling it "reached"
would have been an overclaim sitting in the one place a reader reuses: the name.
📌 True reachability needs an INPUT MODEL — `prevDec`/`nextDec` come from the instruction
stream, and `cycNext` holds `nextDec` fixed, so this file cannot generate them. **That is the
honest remainder of the `d8d3760` control, and it is OWED, not discharged.** -/
def bypassCells : List CycState := allCyc.filter (fun s => sofKind s != sofKindNoBypass s)

theorem bypass_cells_are_non_empty_in_the_enumeration : bypassCells.length = 20 := by
  decide +kernel

/-- ⛔ **CONTROL 2 — A NO-OP REALIGN MUST FAIL THE PAYLOAD.** If the realign arm did nothing —
if `sofKind` simply kept the current kind — the characterisation above would be FALSE. Driving
that here means the theorem is not satisfied by an inert arm. -/
def sofKindNoOp (s : CycState) : Kind := s.kind

theorem a_noop_realign_would_break_the_characterisation :
    allCyc.all (fun s =>
      (sofKindNoOp s != sofKindNoBypass s) ==
        (instrAvail s && (rederive s.prevDec != rederive s.nextDec))) = false := by
  decide +kernel

/-- ⛔ **CONTROL 3 — THE BRIDGE MUST BE NON-VACUOUS.** A bridge is trivially true if the thing it
bridges to never varies. `next` takes at least two distinct values over the swept loop starts, so
the bridge is constraining something. -/
theorem the_bridge_is_non_vacuous :
    (allCyc0.map (fun s => next (proj s) (endDecode s).req (endDecode s).we)).eraseDups.length
      = 5 := by
  decide +kernel

/-- ⭐⭐ **AND THE POINT OF THE WHOLE FILE, NOW SAYABLE:** off the bypass cell a realign
re-derives the loop kind from **the instruction that already retired**. This is the sentence
`BusFSM.lean` cannot state, because `prevDec`, `nextDec` and `phase` do not exist there. -/
theorem off_the_bypass_the_realign_reads_the_retired_instruction :
    allCyc.all (fun s => !instrAvail s → (sofKind s == rederive s.prevDec)) = true := by
  decide +kernel

-- ⛔ AXIOM GATES, ONE CALL PER THEOREM ON PURPOSE. `#audit_axioms` with several names ABORTS
-- AT THE FIRST FAILURE, and the names it never reached print nothing — which reads exactly
-- like clean. Count the TICKS (8), never the absence of complaints.
-- ⛔ AND THIS COMMENT IS `--`, NOT `/-- -/`: a DOC comment must attach to a DECLARATION, and
-- `#audit_axioms` is a COMMAND. The doc form is a parse error that names the next line.
#audit_axioms allCyc_card
#audit_axioms allCyc0_card
#audit_axioms bridge_at_loop_start
#audit_axioms the_bypass_is_the_protection
#audit_axioms bypass_cells_are_non_empty_in_the_enumeration
#audit_axioms a_noop_realign_would_break_the_characterisation
#audit_axioms the_bridge_is_non_vacuous
#audit_axioms off_the_bypass_the_realign_reads_the_retired_instruction

end SaltWorks.HDL.BusCycle
