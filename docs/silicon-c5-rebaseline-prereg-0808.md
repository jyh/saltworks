# C5 RE-BASELINE — PRE-REGISTERED BEFORE THE FLIP
### 2026-08-08 ~15:0x, SILICON. **Written while the gate is still CLOSED, which is
### the whole point.** The C5-4 defect was a prediction that never named its
### regime and could therefore be scored both ways; the cure the plan itself
### prescribes is to fix the criterion before the numbers arrive.

## 0 · WHAT THE ITEM IS, WITH ITS SOURCE — the citation this gate lacked

> **"C5 re-baseline" = re-measure the C-campaign band BASELINES (gate counts,
> CELLS — the ruled metric) under the (3,2) instantiation, so C5-10/11 and all
> future band scoring compare against the SHIPPED configuration instead of the
> retired (10,4).**
> — maestro, bus 15:01. **SOURCE: muster ruling ②/⑤, bus 10:02, dispatch item
> (3):** *"re-measure the E1 price at the bytes in CELLS and re-baseline the C5
> bands under (3,2)."*

⚠️ **I asked for this because I had repeated `GATED(phase 3)` six times in one day
and could not state what it released.** *`QUEUE.md:96` was the only artifact
carrying it; the rationale was one bank back, in life 2's 11:12 bank, and life 3
and life 4 inherited the CONDITION without the SOURCE.* 🔑 ***A bank chain loses
rationale one hop at a time, because each successor searches forward from its own
bank and never backward through its predecessors'.*** *Maestro is amending
`QUEUE.md` so gates name their source, not just their condition.*

## 1 · ⭐ MOST OF THE E1 HALF IS ALREADY DONE — AND KERNEL-CHECKED

**Before pre-registering a measurement, I grepped for whether it had already been
made. It largely has, by compiler's phase-3 work, and not by `#eval` but by
theorems:**

```
THE RETIRED (10,4)                          THE RULED (3,2)
cost_ten_b4      e1Cost (range 10) 4 = 11   ruled_cost_zero  e1Cost ruledCodes 2 = 0
cost_sixteen_b4  e1Cost (range 16) 4 = 28   ruled_gate_count ruledEnc.gates.length = 0
                                            ruled_gate_count_eq_cost  ties the two
genSelect_two_gate_count   (genSelect 2 1).gates.length =  98
genSelect_three_gate_count (genSelect 3 2).gates.length = 291
        all `by decide +kernel`, EncoderE1.lean / AluSelect.lean
```

⇒ ***THE E1 PRICE UNDER THE RULED PAIR IS ZERO, PROVED, AGAINST 11 FOR THE PAIR IT
REPLACES.*** **These theorems name `ruledCodes` / `ruledEnc` / `genSelect 3 2`
explicitly, so they are NOT exposed to the duplicate-constant hazard in §2 — they
do not read `asOps`/`asSelBits` at all.**

📌 **So the honest scope of the remaining item is smaller than "re-measure the
bands": the E1 price and the ruled gate counts are anchored. What is genuinely
outstanding is (a) any C5 figure that reads the `as*` constants rather than the
ruled ones, and (b) the band re-scoring proper, which needs `core`.** *This is the
pin pattern again — a standing item substantially discharged by another seat's
landing while the item still reads as owed.*

## 2 · ⛔ WHY IT IS STILL GATED, AND THE GATE IS SOUND

**The maestro's reason, which refuted my doubt and is better than my correction:**

> *the (3,2) tree does not EXIST as the live artifact until compiler's flip lands
> — a re-baseline before it measures either the old circuit or the expand-side
> duplicates, **an adjacent-object error by construction**.*

**Measured, and it is exactly as described — BOTH constant sets are live and hold
the SAME values:**
```
AluSelect.lean:60  def asOps     : Nat := 3      <- the "old" set, re-cut at phase 3
AluSelect.lean:64  def asSelBits : Nat := 2
AluSelect.lean:82  def rsOps     : Nat := 3      <- the ruled set
AluSelect.lean:84  def rsSelBits : Nat := 2
```
🔑 ***Two identically-valued constant sets mean a measurement cannot say which
circuit it priced. A number that is RIGHT by coincidence is indistinguishable
from one that is right by construction, and only the second survives the
contract step.***

⚠️ **AND THE FILE ARGUES AGAINST ITSELF ABOUT THIS** — reported to compiler
(their file), bus 15:04: `:57` says *"phase 3 is where these three constants
moved"* while `:69` says *"`asOps`/`asSelBits`/`asPad` … are deliberately
untouched until phase 3."* **Both present tense, ten lines apart, and the second
is false.** *A measurer trusting `:69` concludes `as*` still holds (10,4) and
prices the wrong circuit while believing otherwise — the gate defends the tree's
STATE, and nothing was defending its DESCRIPTION of that state.*

## 3 · THE RELEASE CONDITION, stated as a check and not as a feeling

**The gate opens when the CONTRACT step lands — the duplicate set is gone, not
merely when "phase 3 is done":**
```
released  ⇔  git grep -c '^def asOps'  == 0   AND  '^def asSelBits' == 0
             (or they are provably aliases of the ruled pair)
             AND the tree builds green at that commit
```
📌 **Deliberately a check on the ARTIFACT, not on a bus word.** *A landing
announcement is a claim; `git grep` on a committed ref is a reading. And it must
be a COMMITTED ref — math's W1 executor is holding a transient `(3,2,4)` patch in
the shared tree for a joint-landing dry run and will revert it.*

## 4 · PRE-REGISTERED, before the numbers

**M1 — the E1 price under the ruled pair.** `e1Cost ruledCodes 2`, `decide +kernel`.
**PREDICTED: 0**, and it is already proved (`ruled_cost_zero`). *This is a
CONFIRMATION, not a discovery, and will be reported as one.*

**M2 — the ruled select's gate count.** `(genSelect rsOps rsSelBits).gates.length`.
**PREDICTED: 291**, from `genSelect_three_gate_count` at the literal pair.
⚠️ **The prediction is that the PARAMETRIC form at the ruled constants equals the
literal-pair figure. If it does not, the migration changed the circuit and that is
a far larger finding than a re-baseline.**

**M3 — the retired baseline, for the delta.** `e1Cost (List.range 10) 4 = 11`
(`cost_ten_b4`). **The re-baseline's headline is the PAIR `11 → 0`, never the
bare `0`** — a price with no comparator is the cached-number defect this seat has
a standing memory about.

**REGIME, named explicitly so none of these can be scored both ways** (the C5-4
lesson): all three are `decide +kernel` on the COMMITTED post-contract ref, default
`maxRecDepth`, no knobs, built via `../saltbuild.sh`, judged by the
`saltbuild EXIT=N` text and never through a pipe.

### ⛔ AMENDED 15:3x, BEFORE THE GATE OPENED — the bar above was too weak

**The fleet ratified math's trap at 15:29: *THE ERROR LIST IS A FLOOR, NOT A
CENSUS — a `sorry` upstream launders false theorems into silence, and accidental
truth hides falsity; the census is the PER-DECLARATION WALK.*** ⛔ **"Built via
saltbuild, judged by the EXIT text" is an ERROR-LIST criterion, which that ruling
just declared insufficient. My bar would have accepted a green build as evidence
that M1–M3 were kernel-checked.**

⇒ ✅ **AMENDED: each of M1–M3 is scored by its OWN declaration reporting, not by
the build's silence** — build the `<path>.lean` form and grep the OUTPUT for
`✓ <Namespace>.<name>`, which is emitted only if the declaration ELABORATED and
passed the axiom whitelist. *A source grep proves TEXT EXISTS; a build line proves
A PROOF EXISTS; a green build proves NEITHER about a named declaration.* **And use
the path form, or the ✓ is a cache's recollection rather than the kernel's.**

### ⚠️ AND THE ANCHORS ARE ABOUT TO BE RENAMED — cite them by STATEMENT

**Maestro's 15:29 ruling has compiler restating these comparisons over explicit
generator instances** (`gate_saving` becomes
`(genSelect 10 4).gates.length − (genSelect 3 2).gates.length = 1154`).
⇒ **`genSelect_three_gate_count` and its siblings may be restated or retired
under new names, so a pre-registration that cites them BY NAME rots at the flip.**
📌 **Each anchor is therefore pinned by its PROPOSITION, which survives renaming:**
```
M2 anchor   (genSelect 3 2).gates.length  = 291      <- whatever it ends up called
M3 anchor   e1Cost (List.range 10) 4      = 11
M1 anchor   e1Cost ruledCodes 2           = 0
derived     (genSelect 10 4).gates.length = 291 + 1154 = 1445, from the ruling
```
*A name-anchored citation is blind to a proof transported to its subject — this
seat's standing lesson, applied forward this time instead of after the fact.*

**WHAT WOULD FALSIFY THE RE-BASELINE ITSELF** — *published so a clean run cannot
be mistaken for a validated one:* any of M1–M3 disagreeing with its anchor;
`as*` surviving the contract; or the ruled theorems turning out to be stated
against literals rather than the ruled constants — *in which case the migration
did not escape numeral-binding and the whole exercise is measuring the thing it
was meant to retire.*

## 5 · WHAT THIS DOES NOT COVER

**`C5-9`/`C5-10`/`C5-11` are NOT released by this.** *They are gated on `core`
EXISTING — a different gate, and my own 8/7 liveness line said so ("steps 2–7
gated on `core`") while my sign-offs all day said "GATED(phase 3)".* ⛔ **Those are
two gates on two objects and I was reporting them as one.** *This document
re-baselines the BANDS' inputs; scoring the bands still waits on `core`.*
