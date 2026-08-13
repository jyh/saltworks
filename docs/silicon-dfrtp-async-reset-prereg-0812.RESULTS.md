# RESULTS — the `dfrtp` async-reset pre-registration

### SILICON seat · run 2026-08-12 evening · companion to
### `silicon-dfrtp-async-reset-prereg-0812.md`, which is FROZEN and unedited.
### Helm ruling 18:28 approved **M1** as shape; condition (4) cleared the
### importer-side mechanics to build tonight, emitter shape waiting on math.

## ⛔ VERDICT FIRST: **THE BAR IS NOT MET. NO DATUM LANDS.**

**C3 fails as literally registered, and C6's first form was a check that could not
fail.** Both are recorded below with what was done about them. The *mechanics*
land (default is still refusal, so nothing is loosened); the *certified dmem
datum* does not, and is not requested.

---

## 1 · THE SIX CHECKS

| | check | result | evidence |
|---|---|---|---|
| **C1** | all `RESET_B` reach the one named net; it is a primary input, not driven | ✅ **GREEN** | passes on `dmem8_nl.v` (execution proceeds past it) and on the fixture |
| **C2** | report every other consumer of the pinned net | ✅ **GREEN** | `0` on base/dmem; `1` **named** (`_06_.A (and2_1)`) on the planted arms |
| **C3** | pinned datum byte-identical to the `dfrtp`→`dfxtp` rewrite | ⛔ **FAILS AS REGISTERED** | §2 — diff published, cause named, **found a real defect** |
| **C4** | without the flag, `dfrtp` still refuses | ✅ **GREEN** | `EXIT=1` on `dmem8_nl.v` (`dfrtp_1 x256`) and on the fixture |
| **C5** | no path takes `RESET_B` as a data input | ✅ **GREEN** | 0 occurrences reach a gate constructor; **query shown to discriminate** on a planted line |
| **C6** | state-bit conservation | ✅ **GREEN, after being rebuilt** | §3 — the first version was tautological |

## 2 · ⛔ C3 — FAILS AS REGISTERED, AND IT EARNED ITS KEEP

Registered prediction: **byte-identical**, on the grounds that under `RESET_B ≡ 1`
the vendor `ff` group reduces to `dfxtp`'s field for field. **The full-file
comparison is RED.** The diff, published as the pre-registration requires:

**⭐ The first run showed a REAL defect, not a cosmetic one:**
```
  /-- fxNL: 7 gates ... -/        <- dfxtp arm
  /-- fxNL: 8 gates ... -/        <- pinned arm      + a stray  .const true
  def fxNL_outs := [3, 4, 6, 2]   vs   [3, 4, 7, 2]  + every index shifted
```
The pinned constant was seeded **eagerly**, so a `.const` was emitted even when
nothing read it — and when the reset feeds only reset pins (which the flop
treatment never reads) that constant is **dead**, yet it still inflated the gate
count and shifted every later index. ***The check caught precisely the thing it
was registered to catch, and I would not have looked.***

**Fixed**: the pinned net now binds **on first read**. Re-run:

| | |
|---|---|
| gate list, `_outs`, all indices | ✅ **identical** |
| `-- source:` filename | differs — two input files; artifact of the test method |
| the scope-marker header block | differs — **required by helm condition (2)** |
| flop table's cell-name column | differs — `dfrtp_1` vs `dfxtp_1`, documentary |

⚖️ **So the SUBSTANTIVE claim is verified — the pinned datum is GATE-FOR-GATE the
`dfxtp` reading — while the criterion AS WRITTEN cannot pass**, because it demands
byte-identity of a header the ruling itself requires to differ.

⛔ **I am not amending the criterion.** The bar stands as registered (ruling,
condition 1), so C3 is RED and the datum does not land. **The amendment I would
propose, for the helm to rule on:** C3 compares the gate list, `_outs`, and the
state-pairing table — the datum's *content* — and explicitly exempts the header
and the cell-name column. *A criterion I rewrite after seeing the result is worth
nothing, which is the entire reason it was published first.*

## 3 · ⛔ C6 — THE FIRST VERSION WAS A CHECK THAT COULD NOT FAIL

As first written it compared `len(ins) + len(auto) + len(cuts)` against
`len(ins_all)` — **and `ins_all` IS that sum.** An identity. It printed
`expected 5 measured 5 OK` and would have printed OK on every input forever.

*It read exactly like a check. It was decoration.* [[a-check-never-shown-to-fail]]

**Rebuilt** against a genuinely independent measurement — a raw regex over the
netlist **text**, sharing no code with the tokenizer or the instance assembly, in
the same spirit as `cones.py`'s independent cone census:
```
conservation : sequential instances — text scan 2, parsed 2, cut 2 + 0 caller-listed  OK
```
**And SHOWN to go red**, which the first version never could:
```
planted: one COMMENTED-OUT dfrtp instance
result : text scan 3, parsed 2  ⛔ MISMATCH   EXIT=1
```
⚠️ **That control also exposes the check's sensitivity direction, recorded in the
source rather than hidden:** a commented-out flop is a **false positive**. That is
the chosen direction — refusing on a commented flop is noisy; missing a dropped
one loses a state bit silently, and every doctrine in this importer prefers noise.

## 4 · THE CONTROLS — six planted defects, run through the REAL command

| control | must | observed |
|---|---|---|
| **NC1** reset pins split across two nets | RED | ✅ `exit=1` — "span 2 nets" |
| **NC1b** single reset net, but **driven** by `inv_1` | RED | ✅ `exit=1` — "derived reset, not a primary input" |
| **NC2** extra consumer of the pinned net | report, **not** block | ✅ `exit=0`, names `_06_.A (and2_1)` |
| **NC2b** extra consumer that **reaches an output** | constant emitted **and used** | ✅ `exit=0`, `.const true` = 1 (base: 0), 9 gates |
| **NCx** pinned net also listed in `--inputs` | RED | ✅ `exit=1` |
| **NCy** `--pin-reset` on a netlist with no flops | RED | ✅ `exit=1` — no silent no-op |
| **NC6** commented-out sequential instance | RED | ✅ `exit=1` (§3) |

**NC2 + NC2b are a controlled PAIR**, and the pair is the point: reset feeding
only reset pins ⇒ **no constant, gate-for-gate identical to `dfxtp`**; reset
feeding live logic ⇒ **constant emitted and genuinely used**. Either alone proves
nothing about the lazy binding.

## 5 · 📌 THE REMAINING BLOCKER FOR D1a IS NOT `dfrtp` — IT IS ONE COMBINATIONAL CELL

With `--pin-reset rst_n`, `dmem8_nl.v` clears the flop gate, C1, C2 and the clock
domain, then stops on:
```
importer: no expansion for cell 'nand4_1' (instance _0397_) — add it to EXPAND and to Sky130.lean
```
**Measured against the resolver's own rule** (exact key, else drive-stripped):
`dmem8` uses **11 distinct cell types; exactly ONE is unmodelled — `nand4_1`.**

⚠️ *My first two attempts at that number said "7 missing" and included `nand2` —
wrong both times, because I compared base names against a key set that mixes
`nand2_1` (full) and `and3` (base). **The cure each time was to read the
resolver's own function instead of assuming its convention.***

Adding `nand4` is **not** part of this pre-registration: cell models carry their
own discipline (full truth-table simulation against vendor Liberty, plus a proved
model in `Cells/Sky130.lean`). Named here, priced at one cell, not half-done.

## 6 · WHAT LANDED, AND WHAT DID NOT

```
LANDED    the mechanics: --pin-reset, the gated SEQ_MODELS entry, C1/C2/C4/C5/C6,
          the scope marker on the emitted datum, the lazy constant binding
          DEFAULT IS STILL REFUSAL — nothing is loosened for a caller who does
          not ask, and C4 proves it on the real artifact
NOT       any certified dmem datum. C3 is red as registered and the bar governs.
NOT       the Lean statement shape — math's call, untouched, no emitter pre-empted
REGRESSION  reimport 4 of 7 committed data, ALL REPRODUCE, EXIT=0, before and after
```

⚓ **Two of the six checks failed in a way that improved the artifact, and neither
would have been visible without registering them first.**

---

# ADDENDUM A — C3 AS AMENDED, RE-RUN · 2026-08-12 19:01 PDT · tree `7eac344`

### Filed under helm ruling **2026-08-12 18:49** (FLEET.md:81221), which amended C3 to
### two assertions and authorised the datum to land on this seat's own receipt if the
### bar were met. **The frozen pre-registration file is untouched.**

## A.0 · ⛔ VERDICT FIRST: **THE BAR IS STILL NOT MET. NO DATUM LANDS.**

**A1 is GREEN. A2 is RED on exactly one residual.** The nine control rows all
behaved and the three new controls all discriminate — so the RED is a reading,
not a broken instrument.

```
9 control rows          ALL BEHAVED          (script EXIT=1 solely from C3.A2)
C3.A1 logic identity    ✅ GREEN             NC3a shows it can go RED
C3.A2 diff == marker    ⛔ RED               NC3b, NC3c show it can go RED
```

## A.1 · ⚠️ THE AMENDMENT INHERITED THE SHAPE OF THE ERROR IT REPAIRED

The registered C3 was RED because it **demanded byte-identity of a header the
ruling itself required to differ.** The amendment asserts that header — correctly,
and it is stronger. But the amended clause reads *"the file diff EQUALS EXACTLY
the mandated scope marker, **nothing else**"*, and there is a **second** field the
experiment's own design requires to differ:

```
     removed (must be none, per "nothing else"):
       * `  0`  Q `s0`  ←— `w0`   (_02_, dfxtp_1)
       * `  1`  Q `s1`  ←— `d1`   (_03_, dfxtp_1)
     added vs golden:
       11a12,13
       > * `  0`  Q `s0`  ←— `w0`   (_02_, dfrtp_1)
       > * `  1`  Q `s1`  ←— `d1`   (_03_, dfrtp_1)
```
The flop table's **cell-name column**. RESULTS §2 listed it (row 4, *"documentary"*)
and the ruling's *nothing else* did not except it. ⇒ **The repair surface and the
durable surface differed by one field.** [[a-repair-inherits-the-error-shape]]

🔑 ***And this difference is not a tolerance to widen — it is the experiment's
INDEPENDENT VARIABLE.*** The two arms are supposed to be the same design read
through different cells. **If those two lines were identical, the arms would not
have been distinct inputs and the whole comparison would be vacuous.** An A2 that
passed by their being equal would be reporting that the treatment never applied.
[[verify-the-treatment-applied]]

## A.2 · ⚖️ PROPOSED — NOT MADE. The second amendment, for the helm.

> **A2′** — the file diff equals the mandated scope marker **plus the flop table's
> cell-name column**, and **the cell-name column MUST differ**: its identity across
> the arms is a FAILURE, because it means the two arms were the same input.

This moves the same direction the helm moved: **a tolerated difference becomes an
asserted one.** ⛔ *This seat has not applied it. A criterion rewritten by the hand
that saw its result is worth nothing, and the precedent set tonight is that the
amending authority is the one that ruled it.*

> ⚓ **SUPERSEDED 2026-08-13 — the sentence below was true when written and is
> now FALSE in its most important word.** *A2′ **DISCHARGES**. The helm adopted
> it 08/12 19:07:52 (re-confirmed 19:15:19); it was promoted to the discharging
> criterion at `7958286`, and extended at `98fd83c` with the mechanical name
> clause (rev-2). **A2 is the row that is now non-discharging.*** *The paragraph
> is kept unedited below because it is the RECORD of the proposal state — but
> "non-discharging" now names the opposite row, and a reader who quotes this
> sentence today would invert the criterion.*
> 🔑 *Caught by sweeping my own docs for retired mechanisms described as live,
> after a peer caught the same class in my price table twice.*

**A2′ IS IMPLEMENTED AND MEASURED — as a non-discharging informational row that
does not touch the exit status** (`pinreset_controls.sh`, `C3.A2′`). It reports
**GREEN**. *Measured, not predicted: a proposal that carries a verdict it never ran
is advice, and advice travels unchecked.* ⇒ **If the helm adopts A2′, the bar
closes on this run with no other change.**

⚠️ *One honest weakness, stated because it is in the clause this seat chose: the
column requirement is asserted STRUCTURALLY — every pinned row must name
`dfrtp_1`, every rewrite row `dfxtp_1` — and not merely as "the columns differ",
which any difference would satisfy, including a wrong one.*

## A.3 · WHAT THE RE-RUN FIXED IN THE HARNESS (not in the criterion)

* ⭐ **ONE OF THE THREE DIFFERENCES WAS NEVER REAL.** §2 row 2 recorded a
  `-- source:` divergence as *"an artifact of the test method"* — and it was
  **literally that**. Both arms are now generated from **one base netlist by the
  registered method** (textual rewrite) into **the same basename** in two
  directories. The line vanishes. *A difference attributed to the test method
  should be removed by fixing the test method, not carried in the results table.*
* **A fixture-drift control was missing.** The old harness compared two
  hand-maintained fixtures; nothing checked that `pinreset_dfxtp.v` was still the
  rewrite the criterion names. It **is** (verified byte-identical, now asserted on
  every run). The fixture is retained for row NCy.
* **Three controls added** for the amended check — NC3a (perturbed gate ⇒ A1 red),
  NC3b (extra non-marker difference ⇒ A2 red), NC3c (**mandated marker stripped ⇒
  A2 red**, the direct test of helm condition (2)).
* **The marker is now a committed golden** (`fixtures/pinreset_scope_marker.txt`),
  compared against, never regenerated at check time. *Honest limit: it was seeded
  from the current emission, so it does not independently validate the wording —
  its force is the "nothing else" clause and future drift.*

## A.4 · TWO OWN-GOALS IN THIS CHECK, BOTH CAUGHT ON ITS FIRST RUN

```
A FALSE RED   A1 compared comment-stripped files, and the shared stripper
              PRESERVES LINE NUMBERING — 11 stripped comment lines became 11
              blank lines, so A1 was measuring ALIGNMENT, not logic. Failed in
              the ALARMING direction, which is the lucky one.
A SILENT SKIP My first A2 rows read `[ -f "$GOLD" ] && a2 ...` — with the golden
              absent that short-circuits to the ELSE branch and PRINTS ✅.
              That is the silent-skip-reads-as-a-pass defect written into
              pinreset_controls.sh's OWN HEADER, shipped again one function
              lower, the same day. The guard now REFUSES up front.
              [[a-law-applied-is-not-a-law-held]]
```

## A.5 · A PRECISION ON "NINE CONTROLS RED"

The ruling's phrase is shorthand. **The nine rows are 6 RED-expected and 3
PASS-expected**, and the PASS rows are load-bearing: the script's own comment
records that *a run which always fails satisfies every RED row for free.* The bar
this seat reads, and ran, is **the nine-row fixture exits 0** — which it does; the
EXIT=1 above comes from C3.A2 alone.

---

# ADDENDUM B — `nand4_1` LANDED · D1a's HARDWARE DOOR IS OPEN

### Authorised as routine by the same helm ruling (18:49, item 2): *"a combinational
### model in your lane's standard class; the sensitive class was and remains sequential."*

## B.1 · ⭐ `dmem8` NOW IMPORTS CLEAN — **EXIT=0, readback GREEN**

```
instances     : 673  (417 logic, 256 physical/sequential)
gates emitted : 1984
flops cut     : 256  (256 by the treatment, 0 listed by the caller)
clock domain  : one — root 'clk', parity 0, via 1 CLK net(s)
⚠ RESTRICTED  : 'rst_n' PINNED to 1 — 256 async-reset flop(s) imported under it
pin fan-out   : 0 other consumers — 'rst_n' feeds only reset pins
conservation  : text scan 256, parsed 256, cut 256 + 0 caller-listed  OK
readback      : 32 random vectors, 288 outputs each — agrees with vendor Liberty
```
⚓ **The predecessor's measurement was exact: one unmodelled combinational cell
stood between the flow and a clean `dmem8` import. It is modelled, and the door
is open.** `nand4_1` is **17 instances** of the 673.

⛔ **THE DATUM STILL DOES NOT LAND.** The bar governs (Addendum A), and helm
condition (4) holds the emitted **statement form** for math. This is the
*hardware* door, not the theorem.

## B.2 · THE MODEL, AND WHY ITS THEOREM IS NOT VACUOUS

Written **by hand from what the name means**, per the rule in
`Cells/CI-cell-census.md`: *"If the model is generated from that same liberty, the
theorem compares a value with itself and proves nothing."*

```lean
def nand4 (A B C D : Bool) : Bool := !(A && B && C && D)      -- from the NAME
theorem nand4_liberty (A B C D : Bool) :
    nand4 A B C D = ((!A) || (!B) || (!C) || (!D))            -- from the VENDOR
  := by decide +kernel +revert
```
The two sides are **syntactically different expressions** — a conjunction under a
negation versus a disjunction of negations. The theorem is De Morgan on this pin
set, and it is the reason the model is trusted rather than assumed.

```
vendor      nand4_1  in=(A,B,C,D)   Y = (!A) | (!B) | (!C) | (!D)
            read by Cells/extract_liberty.py from the PDK's own Liberty
kernel      ✓ SaltWorks.Silicon.Cells.nand4_liberty [0 axioms]   saltbuild EXIT=0
            (a real build — 29s, not a Replayed module)
EXPAND      independently cross-checked by readback.py, which takes the cell's
            function from Liberty and NOT from the importer's own table
regression  reimport.sh EXIT=0, 4 of 7, ALL REPRODUCE byte-for-byte
```

## B.3 · A NUMBER THAT LOOKED LIKE A CONTRADICTION AND WAS NOT

The importer prints **`cell types : 10`**; the predecessor measured **11**. Both
are right and they count different objects — the importer's line is **logic types
only**, excluding the sequential `dfrtp_1`. Census of the netlist itself:

```
256 mux2_1 · 256 dfrtp_1 · 83 a22oi_1 · 30 a222oi_1 · 17 nand4_1 · 15 nand3_1
  8 nand2_1 · 3 nor3b_1 · 3 and3b_1 · 1 nor3_1 · 1 and3_1        = 11 distinct
```
*Recorded because the adjacent-object reading is the one that gets published.*

## B.4 · ⚠️ A DEFECT IN THE FROZEN PRE-REGISTRATION'S OWN REPRODUCTION COMMAND

§1.3 documents the run as `--inputs clk,rst_n,we,addr[0..2],wdata[0..31]
--outputs rdata[0..31]`. **`[0..31]` is not importer syntax.** The importer takes
an explicitly enumerated list (`rdata[0],rdata[1],…`, as `reimport.sh`'s `seq8`
builds it), and the documented command fails with `net 'rdata[0..31]' has no
driver and is not an input`.

🔑 ***It was never caught because the `dfrtp` refusal fired FIRST.*** The command
was only ever run in a configuration that exits before the port list is parsed,
so its later arguments were never exercised. ⇒ **A reproduction command that
always fails early has not been shown to reproduce anything** — the
[[a-check-never-shown-to-fail]] pattern, one level up, in a documented command
rather than in a check. *(Also: `rst_n` must be OMITTED from `--inputs` under
`--pin-reset`, which control NCx enforces.)*

The prereg is frozen and stays frozen. **The working command is recorded here:**
```
--inputs  clk,we,addr[0],addr[1],addr[2],wdata[0]…wdata[31]     (rst_n OMITTED)
--outputs rdata[0]…rdata[31]
--pin-reset rst_n
```

---

# ADDENDUM C — C3 RE-RUN ON THE **REAL `dmem8`**, NOT THE 7-GATE FIXTURE

### Every C3 result before this one — the original, and Addendum A — was measured on
### `pinreset_base.v`: **7 gates, 2 flops.** `nand4_1` made the real artifact reachable,
### so the criterion has now been run on **1984 gates and 256 flops**.

## C.1 · THE ARMS, AND THE PROOF THAT THE REWRITE IS FAITHFUL

The comparison arm is the registered textual rewrite, applied to the real
netlist. `dmem8`'s `dfrtp` instances are multi-line, and `.RESET_B` is the **last
port**, so a naive line-delete leaves a dangling comma — the port and its comma
are removed together.

```
dfrtp_1 occurrences rewritten : 256        residual RESET_B in rewrite : 0
RESET_B ports removed         : 256        residual dfrtp   in rewrite : 0
rst_n mentions   259 -> 3      == exactly the three DECLARATIONS, which is the
                                  arithmetic the frozen prereg §1.2 predicted
```
Both arms import **EXIT=0 with readback GREEN** (32 vectors × 288 outputs).

## C.2 · ⭐ A1 IS GREEN AT FULL SCALE

```
emitted LOGIC lines   pinned 2000   dfxtp 2000   —   byte-identical
```
⇒ **On 1984 gates and 256 flops, the pinned `dfrtp` reading is GATE-FOR-GATE the
`dfxtp` reading.** *§3's field-for-field vendor argument, which predicted this
before any code was written, holds on the real artifact and not merely on a
seven-gate toy.*

## C.3 · A2 IS RED — AND THE RESIDUAL IS **THE SAME TWO CLASSES**, AT 256× THE SCALE

```
total differing lines   523  =  11 marker  +  256 removed  +  256 added
removed NON-flop lines    0      <- "nothing else" holds outside the two classes
all 256 flop rows differ ONLY in the cell-name column; Q/D pairing IDENTICAL
column purity          256/256 name dfrtp_1  ·  256/256 name dfxtp_1
```
🔑 ***The fixture and the real artifact agree on the residual CLASS. Scale changes
the count and changes nothing else*** — so the pending ruling does not become
riskier on the real datum, which is the thing worth knowing before ruling.

## C.4 · A2′ IS GREEN ON THE REAL `dmem8` — MEASURED, NOT INFERRED

The proposed predicate was run against these arms, including its **structural**
column clause (every pinned row must name `dfrtp_1`, every rewrite row
`dfxtp_1` — not a bare inequality):

```
✅ A2′ (PROPOSED) is GREEN on the REAL dmem8
```
⛔ **This still does not discharge C3.A2, and no datum lands.** A2′ is a proposal
awaiting the helm; the ruled criterion is RED, at the fixture and at scale alike.

*Reproduction: the arms are built by the rewrite in C.1 and imported into the
SAME BASENAME in two directories, exactly as `pinreset_controls.sh` does for the
fixture. Not added to that script as a row — two full `dmem8` imports are far too
heavy for a fixture that must stay cheap enough to run on every change.*
