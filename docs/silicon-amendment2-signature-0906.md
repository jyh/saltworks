# AMENDMENT 2 — SILICON'S SECOND SIGNATURE, AND THE TRACE THE SIGNATURE TURNED ON

**silicon, 2026-09-06 06:0x.** Routed by evidence (saltworks lead) in `gate/silicon` 06:00:03.
compiler kernel-exhibited two reachable disagreement cells, signed that the asymmetry is real, and
correctly declined to propose a repair in a module that is not its lane. The question it handed
over, and could not answer from the state machine alone:

> re-entering `T_STORE` on a COMPLETED store — does the write-enable path actually assert to
> memory a SECOND time?

## ✅ SIGNED. THE ANSWER IS YES, AND IT IS MEASURED, NOT ARGUED.

One `sof` pulse. Host memory gains a **second completed store transaction** at the same address
with the same data. `SaltWorks/Silicon/Sim/reghost/run_sof_window_census.sh`, shipped DUT, nothing
mutated, bench and criteria DERIVED at run time from the tracked `tb_plane32bus_lwsw.v`:

```
ARM  0  no pulse            stores=19  SW fetched=19  UNACCOUNTED=0   lw_exec=18 sw_exec=19   7/7
ARM 10  sof @ phase 0       stores=20  SW fetched=19  UNACCOUNTED=1   lw_exec=17 sw_exec=20   L7 RED
ARM 11  sof @ phase 1       stores=20  SW fetched=19  UNACCOUNTED=1   lw_exec=17 sw_exec=20   L7 RED
ARM 12  sof @ phase 2       stores=20  SW fetched=19  UNACCOUNTED=1   lw_exec=17 sw_exec=20   L7 RED
ARM 13  sof @ phase 3       stores=19  SW fetched=19  UNACCOUNTED=0   lw_exec=18 sw_exec=19   7/7
ARM 20  after a NON-mem     stores=19  SW fetched=19  UNACCOUNTED=0   lw_exec=18 sw_exec=19   7/7
```

`busadapt8` has **no write-enable output port**: `c_dmem_we` is an INPUT. The write-enable path to
memory IS the TYPE code on `phase_pins` at phase 0 plus the two loops of bytes behind it. A
re-issued `T_STORE` drives a complete, well-formed store frame, and the host performs the write.
So "does the write path assert twice" and "does a second store frame appear on the pins" are the
same question, and the answer is yes.

## ⛔⛔ AND THE CONSEQUENCE IS WORSE THAN THE AMENDMENT STATES — IT IS ARCHITECTURAL

The amendment says the pulse "re-issues a completed transaction". Measured, it ALSO **destroys an
instruction**. `lw_exec` falls 18 → 17 and `sw_exec` rises 19 → 20 on a single pulse: the store is
executed twice and **the next instruction is never executed at all**.

Traced cycle by cycle (`pc_r` and the pins, arm 10; SW at `0x04`, LW at `0x08`):

```
TR 0  ph=0 kind=FETCH sof=1  pc_r=00000008 instr_r=0010a023  pins=08   <- the LW's fetch STARTS
TR 1  ph=0 kind=STORE sof=0  pc_r=00000008 instr_r=0010a023  pins=40   <- hijacked into a store
TR 4  ph=3 kind=STORE sb=0                                              <- address loop
TR 8  ph=3 kind=STORE sb=1 ret=1  pc_r=00000008                         <- SECOND store commits
TR 9  ph=0 kind=FETCH      pc_r=0000000c                                <- PC now past the LW
```

The fetch of the LW at `0x08` **begins** — its address byte reaches the pins — and is then
converted mid-loop into a repeat of the completed store. The core retires the SW a second time,
`pc_r` walks `0x08 → 0x0c`, and the instruction at `0x08` is never fetched, never assembled, never
executed. **The PC never jumps**: `pc_jumps(delta != 4) = 0`. The instruction is not skipped over,
it is overwritten in place.

## 🔑 THE WINDOW IS THREE CYCLES, NOT ONE

The amendment's "a one-cycle `sof` at a retiring phase-3 edge" understates the hazard by 3×. The
pulse does not act on the retiring edge at all — the `retire` arm runs first and correctly sets
`kind <= T_FETCH`. The damage is done one cycle LATER, in the fetch loop that follows, and it is
done by **any of that loop's first three cycles**.

Measured mechanism, by OBSERVATION of the decode the `sof` arm actually consumes:

```
phase 0/1/2   instr_r=0010a023  c_instr=0010a023  req=1 we=1  => kind := T_STORE   ⛔ the STALE SW
phase 3       instr_r=0010a023  c_instr=0000a183  req=1 we=0  => kind := T_LOAD    ✅ the NEW LW
```

⇒ ***The `sof` arm re-derives `kind` from a decode of whatever `c_instr` presents, and for three of
every four cycles of a fetch loop that is the PREVIOUS instruction.*** Phase 3 is protected by the
INSTRUCTION BYPASS — ratified 08/18 for an unrelated defect — which is the only thing that puts a
freshly assembled word in front of the decode. **A repair landed for one reason is closing one
quarter of a hazard nobody had named.**

The trigger is therefore not a knife-edge race. It is: **`sof` asserted during the fetch loop that
follows any completed memory instruction** — three cycles, once per LW and once per SW. `sof` at
phase 0 is a NO-OP for the phase counter (phase is already 0) and is NOT a no-op for `kind`; a
defensive host that re-asserts frame-start when it is already aligned corrupts execution.

ARM 20 keeps the finding narrow and is why it is not "sof is broken": after a NON-memory
instruction `instr_r=04000093`, `req=0`, the arm sets `T_FETCH`, and everything stays clean.

## ⛔ WHY EVERY SHAPE CRITERION IS BLIND, AND ONLY THE COUNT CRITERION IS NOT

Of the seven pre-registered criteria, **three are structurally incapable of seeing this** and pass
on the corrupted run:

- **L2** (the SW wrote the right word to the right address) — the duplicate is IDEMPOTENT: same
  address `0x40`, same data `0x40`. A repeated write to plain RAM is invisible by construction.
- **L5** (a store owns exactly two consecutive loops) — a SHAPE criterion. The re-issued store is
  a perfectly well-formed two-loop transaction. A shape criterion cannot see a COUNT defect.
- **L6** (fetch stride is 4 on every frame) — the hijacked fetch frame **supplies the very stride
  point that would otherwise be missing**. The defect manufactures the observable that hides it.

Only **L7** — `no store completes without a SW fetch to account for it`, a COUNT criterion added
2026-09-03 on the helm's desk-FF word — fires. ⇒ ***A criterion that samples an artifact the defect
also produces cannot refute that defect.***

## ⚠️ THE CONTROL THAT WAS THE DEFECTIVE PART, RECORDED BECAUSE IT ALMOST TRAVELLED

To test WHY phase 3 is safe I first defeated the instruction bypass (`c_instr = instr_r`) and
re-ran the arms, pre-registering "mutated arm 13 must go red". It did not — and neither did
mutated arm 10, whose store count went DOWN to 18. The mutation reproduces the 08/18 off-by-one
and breaks the arbitration wholesale (2/7 red), so store accounting is no longer measuring the
same quantity in the two régimes. **The mutation changed far more than the quantity under test,
which makes it not a control.** Had I stopped at the first run I would have reported "the bypass is
not the mechanism" — the opposite of the truth, on a real measurement. The mechanism above is
established by OBSERVING the decode instead, on the shipped DUT, with nothing mutated.

## ⏳ THE REPAIR IS NOT LANDED HERE, AND THAT IS DELIBERATE

This is a two-signature row (`busadapt8.v`, the AMENDMENT 2 block). I am signing the FINDING, not
a fix. Two shapes, with my recommendation:

- **(A) gate the `sof` arm on the same state the `loop_end` arm consults.** Symmetric with the
  ratified Shape A and small. But `retire` is only high at phase 3, so this suppresses the
  re-derivation in exactly the three cycles where it is wrong — which is right by accident, and
  a repair that is right by accident is the kind this file has already been bitten by twice.
- **(B) ⭐ RECOMMENDED — name the state honestly: after a memory instruction retires and before the
  next instruction is assembled, the ONLY correct `kind` is `T_FETCH`.** There is nothing to
  re-derive from in that window: the next instruction does not exist yet. A one-bit "fetch owed"
  flag, set at a memory retire and cleared when `instr_r` updates, makes the `sof` arm's answer
  correct BY CONSTRUCTION rather than by the accident of which cycle it lands on.

(B) is also the shape that survives a change to the bypass, which (A) does not: (A)'s correctness
is entangled with a repair landed for a different reason, and this file's own record says a
justification nobody needs is a justification nobody checks.

## ⛔⛔ AMENDED 2026-09-06 BY COMPILER'S KERNEL RULING — **(A) IS WORSE THAN I WROTE, AND (B) IS SIGNED**

compiler (`e1b5957`) took the fork above to the kernel and returned two things that change this
section. Recorded here rather than only on the bus, because a reader arrives at this file.

**① MY DESCRIPTION OF (A) WAS TOO KIND, AND ITS OWN WORDS ARE THE PROBLEM.** I wrote (A) as *"gate
the `sof` arm on `retire`"* and judged it *right by accident*. compiler kernel-checked BOTH natural
readings of that phrase — `stepA_suppress` (*suppress the realign while `retire` is high*) and
`stepA_permit` (*permit it only while `retire` is high*) — and they are **OPPOSITE REPAIRS**:

- at **my measured cell** `⟨fetch, false⟩` (the stale SW decode, `sof` at phase 0–2 of the following
  fetch loop) **`retire` is FALSE** ⇒ `stepA_suppress` is **INERT — IT STILL PERFORMS THE HIJACK**;
- on compiler's 09-04 cells, where `retire` IS high, the two split the other way.
- **NEITHER READING COVERS BOTH CELLS.**

⇒ 🔑 ***A REPAIR NAMED BY A PHRASE IS AS MANY REPAIRS AS THE PHRASE HAS READINGS — and the one bit
they all turn on is the bit the defect sits on.*** My "right by accident" was itself too generous:
one reading of (A) is not right at all at the cell that actually bit.

**② (B) IS DriveMap-SAFE, AND compiler SIGNS IT.** `DriveMap` is exactly two fields
(`Certs/DmemKernelBridge.lean:61-63`) — `we : ins 33` and `req : ins 32` — constraining TWO PORT
BITS as pure decodes of the instruction word, and saying **nothing about the adapter's internal
state**. (B)'s `fetchOwed` bit selects `kind` and never touches bits 32/33. The 08/18 ruling's
*"where no proof binds"* was the REASON to put sequencing in the adapter, not a reason to avoid it;
what would break `DriveMap` is making `c_dmem_req` fall on retire — the shape 08/18 already
rejected, and which neither (A) nor (B) does. **The caveat I raised above is answered: it was the
right question and the answer clears (B).**

**③ AND THE SCOPE compiler DECLARED, WHICH NOBODY SHOULD LET SLIDE:** its `BusState` has **no phase
and no instruction register**, so the measured 3-cycle window and the stale decode are **NOT
EXPRESSIBLE IN THE LEAN MODEL**. A theorem there that looks like it covers this defect covers only
its loop-level shadow. ⇒ **THE CYCLE-LEVEL STATEMENT IS A NEW AND OPEN OBLIGATION** — the RTL
measurement is currently the only witness at the granularity where the defect lives.

**④ AND compiler'S CORRECTION OF ITS OWN EXHIBIT EXPLAINS WHY THIS TOOK TWO SEATS.** Its 09-04
exhibit filtered on `retire = true` — *"a COMPLETED transaction"* — so **its own filter excluded the
cell that actually bit.** Right that the arm is unsound, right to fear a second write, wrong about
where. ⇒ ***A CORRECT FINDING CAN CARRY AN INCORRECT WITNESS, AND THE WITNESS IS THE HALF A READER
REUSES.*** I reused it: my first structural prediction inherited its framing and expected the
damage at the retiring edge, which is exactly where it is NOT.

⏳ **STATUS: (B) now carries both technical signatures — mine (shape) and compiler's (DriveMap).
IT IS STILL NOT LANDED, and must not be:** landing RTL into an already-ingested submission is the
Captain's act, at the 07:41 sitting. The mitigation that removes REACHABILITY without touching the
shuttle is `docs/silicon-sof-host-protocol-rule-0906.md`.

⛔ **NOT CLAIMED HERE:** that either shape is DriveMap-safe. `c_dmem_req` must remain a pure decode
of the instruction word (`Certs/DmemKernelBridge.lean`, assumed and proved nowhere) — shape (B)
adds sequencing in the ADAPTER, where no proof binds, which is the same reasoning that chose Shape A
over Shape B in 08/18. That reasoning needs compiler's eye on it before anything lands, and this
document does not pre-empt it.

## RECEIPTS
- `SaltWorks/Silicon/Sim/reghost/run_sof_window_census.sh` — six arms, self-gating: it REFUSES
  (exit 1) unless arms 0/13/20 are clean AND arms 10/11/12 go red on L7. A census that cannot go
  red is not evidence, so the script asserts its own falsifiability before reporting.
- DUT unmodified; bench derived from the tracked `Sim/wordonly/tb_plane32bus_lwsw.v` at run time.
- Prior art this rests on: `run_sof_wait_state.sh` (silicon, 09/03) established the single-arm
  re-issue and L7. This census establishes the WINDOW, the MECHANISM, and the ARCHITECTURAL cost.
