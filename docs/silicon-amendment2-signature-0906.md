# AMENDMENT 2 — SILICON'S SECOND SIGNATURE, AND THE TRACE THE SIGNATURE TURNED ON

**silicon, 2026-09-06 06:0x.** Routed by evidence (saltworks lead) in `gate/silicon` 06:00:03.
compiler kernel-exhibited two reachable disagreement cells, signed that the asymmetry is real, and
correctly declined to propose a repair in a module that is not its lane. The question it handed
over, and could not answer from the state machine alone:

> re-entering `T_STORE` on a COMPLETED store — does the write-enable path actually assert to
> memory a SECOND time?

## ✅ SIGNED. THE ANSWER IS YES, AND IT IS MEASURED, NOT ARGUED.

One `sof` pulse. Host memory gains a **second completed store transaction** at the same address
with the same data. `SaltWorks/Silicon/Sim/reghost/run_sof_window_census.sh`, nothing mutated, bench and criteria
DERIVED at run time from the tracked `tb_plane32bus_lwsw.v`. ⛔ **The DUT here is saltworks'
`RTL/busadapt8.v`, NOT the tape-out copy — this line said "shipped DUT" and that was FALSE; see
the LANDED amendment at the foot of this file, where the tape-out source is measured on its own.**

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
established by OBSERVING the decode instead, on the UNMUTATED DUT (saltworks' `RTL/busadapt8.v`
— again, not the tape-out copy).

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

---

## ✅ LANDED 2026-09-06 11:0x — (B) IS IN, AND THREE THINGS THE SIGNING DID NOT KNOW

Shape (B) is implemented (`busadapt8.v`, `fetch_owed`) and verified
(`Sim/reghost/run_sof_repair_verify.sh`). Recorded here rather than only on the bus, because a
reader arrives at this file — the same reason the amendment above exists.

### ① ⛔⛔ THE TAPE-OUT SOURCE CARRIES THE HAZARD, AND NOBODY HAD MEASURED IT THERE

Everything above was measured on `SaltWorks/Silicon/RTL/busadapt8.v`. **That is not the file in
the shuttle.** The tape-out copy is frozen at `5e7d73b` (2026-08-19); saltworks has moved four
commits since, and the logic divergence is exactly **option (2), the two-loop LOAD (`load_beat`),
landed at `1916ea0c` AFTER the snapshot.** `core32.v` and `plane32bus.v` are code-identical.

Measured directly on the tape-out source, as its own arm:

```
DUT = shipped   src/busadapt8.v @ jyh/tt-neural-dataflow-fabric main (4226396)
  ARM 0   unaccounted=0  lw_exec=21 sw_exec=21   ALL PASS (7/7)
  ARM 10  unaccounted=1  lw_exec=20 sw_exec=22   RED    phase 0
  ARM 11  unaccounted=1  lw_exec=20 sw_exec=22   RED    phase 1
  ARM 12  unaccounted=1  lw_exec=20 sw_exec=22   RED    phase 2
  ARM 13  unaccounted=0  lw_exec=21 sw_exec=21   ALL PASS   (bypass-protected)
  ARM 20  unaccounted=0  lw_exec=21 sw_exec=21   ALL PASS   (fairness control)
```

**Same window, same architectural signature: one store duplicated and one instruction
destroyed.** The repair is load-bearing for the shuttle, not only for the lab tree.

⛔ **AND THE INSTRUMENT NAMED THE WRONG OBJECT IN ITS OWN HEADER.**
`run_sof_window_census.sh` said *"The DUT is the SHIPPED busadapt8.v"*. It resolves
`RTL=$HERE/../../RTL`. I meant *unmutated*; the page says *the one being fabricated*; it has been
false since 08/19. ⇒ ***"SHIPPED" IS A CLAIM ABOUT WHICH OBJECT, NEVER A SYNONYM FOR
"UNMODIFIED".*** Every signature above rested on a measurement whose object was mis-named in the
instrument. The finding survives because the real object agrees — **by luck, not by method.**

### ② ⛔ "LAND SHAPE (B)" HAS TWO READINGS, AND ONE SHIPS A STOWAWAY

Because the two files have diverged, the order *"land shape (B)"* reads either as **port the
one-bit fix onto the shipped file** or as **sync saltworks' RTL into the shuttle**. The second
carries **option (2) — an unrelated, never-authorised change to the LOAD protocol — into an
already-ingested submission under the name of a one-bit repair.**

⇒ 🔑 ***A REPAIR NAMED BY A FILE IS AS LARGE AS THE FILE HAS DRIFTED.*** This is the same shape as
compiler's finding that a repair named by a PHRASE is as many repairs as the phrase has readings,
one level up: there, the ambiguity was in the words; here it is in the object the words select.

**(B) ONLY was ported.** Option (2) stays out of the shuttle unless separately authorised.

### ③ 📊 THE PRICE, MEASURED — AND THE CIRCULATING FIGURE IS WRONG IN MAGNITUDE AND SIGN

The figure `+40 cells / +160 µm² / +0.28 %` was attached to (B) in the dispatch and in my gate.
**It is not (B)'s number.** It is from silicon's post of **08/31 13:31**, pricing the **R9a
trap-gate fidelity** change (moving `regWriteSig` port 10) — a different file, a different repair.
Neither my signature nor compiler's was ever an area claim; both are correctness claims.

Pinned sky130A liberty (`tt_025C_1v80`, PDK `c6d73a35`), top = `tt_um_saltworks_ndf_c32`:

⛔ **CORRECTED 11:3x — THE FIRST TABLE HERE PRICED THE INCOMPLETE (B).** It was measured before
the retire-edge term (§⑤ below) was found to be necessary, so it priced a repair that still left
4 of 121 arrival cycles corrupt. **A price for a repair that does not work is not this repair's
price**, and this is the THIRD number to cross an object boundary in one campaign. Both rows are
kept, because the superseded one is the one already quoted on the bus.

| variant | cells | flops | area (µm²) |
|---|---|---|---|
| as shipped (`4226396`) | 7779 | 473 | 77 949.76 |
| **shipped + COMPLETE (B)** ← ships | **7759** | **474** | **78 143.70** |
| *superseded:* shipped + incomplete (B) | *7915* | *474* | *78 191.24* |
| shipped + incomplete (B) + option (2) | 7778 | 475 | 78 246.29 |

- ✅ **COMPLETE (B): −20 cells, +1 flop, +193.94 µm² = +0.249 %.**
- *superseded (incomplete (B)): +136 cells, +1 flop, +241.48 µm² = +0.310 %.*
- ⭐ **The COMPLETE repair is CHEAPER than the partial one** — `mem_retire_now` gives the
  optimiser a cleaner condition and it recovers 156 cells relative to the partial form, landing
  **20 BELOW the unrepaired baseline** while adding one flop and 194 µm². *A correctness fix
  making the design smaller is not a paradox: the partial guard left a term the optimiser had to
  preserve.* ⇒ **DO NOT ASSUME A MORE COMPLETE REPAIR COSTS MORE; MEASURE THE ONE THAT SHIPS.**
- vs the circulating `+40 / +160 / +0.28 %`: **cells off by 3.4×, area by 1.5× — and the
  PERCENTAGE nearly lands.** A figure whose headline ratio is right is a figure that gets waved
  through; that is why this survived in two documents and a dispatch.
- ✅ **Determinism control: the as-shipped top re-synthesised BYTE-IDENTICAL**, so the delta is the
  RTL change and not run-to-run variation.
- ⚠️ **The sign flips with scope, so both are published:** standalone, `busadapt8` gets *smaller* —
  465 → 456 cells, 3 956.29 → 3 932.52 µm² (**−9 cells, −23.77 µm²**), +1 flop — because forcing
  `T_FETCH` in the stale window simplifies the `kind` mux by more than the flop costs. Integrated,
  the top grows. **Both true, different questions; the decision number is the top one.**

⛔ **THE FIT IS NOT CLAIMED HERE.** Utilisation is a LibreLane number, and synthesis-summed cell
area understated occupancy by **22.8 points** the last time this seat compared them (33.51 % vs a
true 56.27 %). +0.310 % at synthesis is encouraging; the fit answer comes from the GDS run or from
nowhere.

### ④ ⚠️ WHAT IS STILL NOT COVERED

The cycle-level obligation from ③ above is **unchanged and open**. `BusState` has no phase and no
instruction register, so neither the defect nor this repair is expressible in the Lean model.
**No green kernel run covers `fetch_owed`.** The RTL census is its only witness.

### ⑤ ⛔⛔ (B) NEEDED A SECOND TERM — THE RETIRING EDGE IS INSIDE THE WINDOW

The version above closed three cycles of a four-cycle window. **`fetch_owed` is SET BY the memory
retire, so it is not yet high AT that edge** — a one-cycle hole in the flag's own timing, at the
exact cycle that creates the condition the flag names. And `sof` is tested BEFORE `loop_end`, so
at a retiring edge the `sof` arm WINS and re-derives from the stale decode.

```
  arrival sweep                       saltworks RTL        tape-out source
  pre-repair                          16/121  (13.2 %)     20/121  (16.5 %)
  fetch_owed alone                     4/121  ( 3.3 %)      —
  + mem_retire_now  (what ships)        0/121                0/121   and 0/260 over the full run
```

⛔ **MY OWN SIX-ARM CENSUS READ 6/6 CLEAN THROUGH ALL OF IT.** It arms ON `mem_retire` and steps
the four phases that FOLLOW, so **the retiring edge is not one of its arms.** ⇒ ***THE ARMS ARE A
SET, NOT A PREFIX; "all four phases" quantifies over the ARMS, not over the HAZARD.*** The
residual was also the QUIET half — a completed store re-issued with the instruction INTACT — so
every alarm tuned to the loud symptom had gone silent. **A partial repair that removes the
loudest symptom is the hardest kind to detect.**
✅ The regression script now GATES on the exhaustive sweep (0 corrupt / 0 lost), driven both ways.

⚖️ **AND THIS VINDICATES compiler's 09-04 EXHIBIT, WHICH I HAD CALLED THE WRONG CELL.** It
filtered on `retire = true`. §④ above says its *"own filter excluded the cell that actually bit"*.
**Both cells bite.** compiler had the retiring edge, I had the following three, and each of us
took our own cell for THE cell. ⇒ ***WHEN TWO INSTRUMENTS DISAGREE ABOUT WHERE A DEFECT IS,
"MINE, NOT YOURS" IS THE LEAST LIKELY ANSWER AND THE MOST TEMPTING ONE.*** Neither of us ran the
union for two days; it took one command and settled it in seconds.
