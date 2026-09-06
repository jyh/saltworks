# DESIGN — what it costs to make the `sof` window EXPRESSIBLE

**compiler, 2026-09-06 07:2x. evidence's 06:38 order, item (2). DESIGN, NOT A BUILD.**
Item (2) was conditioned on (1) landing with window left; (1) landed at `9715418`, Scrub SUCCESS.
⛔ **Nothing here is started. The build needs a word evidence explicitly did not have before the
07:41 sitting, and this document does not assume it.**

---

## 0 · THE GAP, STATED ONCE

`BusFSM.BusState` is `(kind, beat)`. It has **no phase and no instruction register**, so:

- the measured damage window — *phases 0/1/2 of the following fetch loop* — cannot be written
  down in it;
- the mechanism — *a decode that still describes the retired instruction* — cannot be written
  down in it, because `req` and `we` are **free Bools**, not functions of any register;
- and *why phase 3 is safe* cannot be written down either, since that rests on the 08/18
  instruction bypass putting a freshly assembled word in front of the decode.

⇒ Every theorem I landed today about the `sof` arm is a **loop-level shadow** of a cycle-level
fact. `shapeB_closes_both_cells` is true and is not "the defect is closed".

---

## 1 · THE DESIGN INSIGHT, WHICH IS WHAT MAKES THIS CHEAP

**You do not need the instruction word. You need its decode.**

`busadapt8.v` consumes the instruction only through `c_dmem_req` and `c_dmem_we`, two pure
decodes. `DriveMap` says exactly that and nothing more (`DmemKernelBridge.lean:61-63`:
`req : ins 32 = (ctrlSpec w)[7]!`, `we : ins 33 = (ctrlSpec w)[6]!`). So a 32-bit register is
**not** required to express staleness — a 2-bit *decode tag* is.

And the bypass is what makes the tag a function of phase:

```
c_instr(phase) = if phase = 3 ∧ kind = fetch then theNewWord else instr_r
⇒ decode(phase) = if phase = 3 ∧ kind = fetch then nextDecode else prevDecode
```

That single line is the whole of the 08/18 bypass, at exactly the resolution the defect needs.

---

## 2 · THE STATE, AND ITS SIZE

```
CycleState = kind      : Kind          4
             beat      : Bool          2
             phase     : Fin 4         4
             prevDec   : Decode        4     (req, we) of the instruction in instr_r
             nextDec   : Decode        4     (req, we) of the word being assembled
                                    ─────
                                       512 states
inputs: sof : Bool                       2
                                    ─────
                                     1024 rows for an exhaustive sweep
```

**1024 is comfortably inside `decide +kernel`** at this seat's demonstrated scale — `allStates`
sweeps 8×4 = 32 today and `adapterNext_correct` does 32 rows over a 15-gate circuit. No new
tactic risk, no `native_decide`, no axiom growth.

⚠️ `loop_end` stops being an input and becomes `phase = 3`, which is the point: today it is a free
Bool and the model therefore cannot distinguish "between loop ends" from "at one".

---

## 3 · THE DOMINANT COST, PRICED POSITIVELY

The dominant cost is **not** the new definitions (~40 lines) and **not** the sweep. It is that
`req` and `we` are FREE PARAMETERS in every theorem in `BusFSM.lean` and in
`adapterNext_correct`'s 5-input sweep. Making them derived is a **breaking change to every
statement's shape**, which is the interface hazard this seat has already been bitten by.

**⇒ Take the route (B) proved this morning: PARALLEL, NOT REWRITE.** `shapeB` added a state type,
a `proj` that forgets the new field, and one theorem that `nextB` projects onto `next` — and
every existing theorem survived *unchanged*. The same shape works here:

```
proj : CycleState → BusState := fun s => ⟨s.kind, s.beat⟩

THE BRIDGE (the one obligation that carries the whole design):
  at phase = 3 with sof = false,
    proj (cycleStep s) = next (proj s) (decode s).req (decode s).we
  and at phase ≠ 3 with sof = false,
    proj (cycleStep s) = proj s                    -- the loop model's HOLD
```

That bridge is what licenses reading every existing loop-level theorem as a statement about the
cycle machine. **It is also the piece that can FAIL, and if it fails the finding is larger than
this document** — it would mean the loop model was never a faithful abstraction of the machine,
not merely a narrower one.

```
PRICED, positively, by part:
  definitions (CycleState, decode, cycleStep, proj)          ~40 lines
  the BRIDGE theorem + its two arms                          1 sweep, 1024 rows
  the WINDOW theorem (the payload, §4)                       1 sweep
  negative controls (§5)                                     3 theorems
  restating nothing                                          0 lines   ← the parallel route
```

---

## 4 · WHAT IT BUYS — the theorems I cannot write today

```
sof_at_phase_0_1_2_reissues     with kind = fetch, beat = false, prevDec = (req:=1, we:=1),
                                a sof at phase ∈ {0,1,2} moves the machine to (store, false)
                                — a SECOND store, from a decode describing the RETIRED
                                instruction.
sof_at_phase_3_is_safe          the same pulse at phase 3 reads nextDec instead, and the
                                machine goes where the ISA demands.
the_window_is_exactly_three     the set of phases at which the hijack occurs is EXACTLY
                                {0,1,2} — pinned from BOTH sides, so a change to the bypass
                                turns it RED instead of letting the prose rot.
the_bypass_is_the_protection    delete the bypass (nextDec := prevDec) and phase 3 joins the
                                window. This is silicon's mechanism as a theorem rather than
                                as a trace, and it is the one I most want: silicon measured
                                it by DEFEATING the bypass and its control failed in the
                                FLATTERING direction. A kernel sweep has no flattering
                                direction.
```

⭐ The last one is the real prize. silicon's own account says its mutation control broke more than
the quantity under test and it nearly published *"the bypass is not the mechanism"* — the
opposite of the truth, on a real measurement. **The bypass's role is exactly the kind of claim a
1024-row exhaustive sweep settles and a simulation cannot.**

---

## 5 · THE CONTROLS, NAMED NOW SO THEY ARE NOT OPTIONAL LATER

Today's lesson, paid for twice: a positive theorem set can be satisfied by a machine that does
nothing, or by one that freezes. These are part of the price, not an extra:

1. **The window must be REACHED, not merely allowed.** `the_window_is_exactly_three` pins the set
   from both sides. (`only_three_costs` shipped green for two days saying which counts were
   *allowed*.)
2. **A no-op `sof` must FAIL the window theorem.** Otherwise the payload is vacuous.
3. **The bridge must be shown NON-VACUOUS**: at least one reachable state where `phase = 3` and
   the loop model genuinely steps. A bridge quantified over an empty set is a theorem about
   nothing, and this seat has shipped one of those.

---

## 6 · WHAT THIS DESIGN DOES **NOT** BUY — stated so it cannot drift

- It does **not** verify the RTL. It extends a *transcription*, and `rtl_transcription_drift.sh`
  (`9715418`) is what now notices when the source moves under it.
- It does **not** touch `DriveMap`. `prevDec`/`nextDec` are decodes of a word, which is precisely
  what `DriveMap` already assumes; nothing here makes a port a function of cycle state.
- It does **not** settle whether the repair should land, or which shape. That is the Captain's.
- ⛔ It does **not** close the `instr_r` timing question carried in `BusFSM.lean`'s header since
  09-04 (*"`instr_r` is written on the phase-3 edge and `kind`/`beat` update on that SAME edge"*).
  This design **models** that edge ordering; it does not adjudicate whether it is off-by-one.
  A separate obligation, and naming it here is not paying it.

---

## 7 · WHEN

⛔ **Not started, and not to be started on my own word.** The trigger is a ruling at the 07:41
sitting *plus* an assignment. If (B) lands, this design's bridge theorem should be built **in the
same window as the transcription update**, because that is the moment `rtl_transcription_drift.sh`
fires and a human is already re-reading the source — the cheapest hour this work will ever have.

If the sitting instead takes the host-protocol route and the RTL does not move, the window
theorems are still worth building: **the hazard remains latent in the shipped design**, and a
latent hazard nobody can state is the condition that produced amendment 2 in the first place.
