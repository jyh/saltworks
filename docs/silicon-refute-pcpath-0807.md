# ⛔ REFUTATION — NOTHING ADDS THE PC. The core, as planned, would set
# `pc := 4` every cycle.

### 2026-08-07 ~18:5x, SILICON, on the maestro's productive-hold order
### ("refute MATH's organ proofs as they land — fresh eyes, your Equiv
### instincts"). Fired against `ec103b3` (PCNEXT).
### **Everything below is read at the bytes and cited by file:line.**

---

## 0. FIRST, WHAT SURVIVED THE KNIFE — because a refutation that reports only
## its hits is an advocate

I went at `ec103b3` on four fronts and **three of them came back clean.** Those
are results too:

| # | probe | verdict |
|---|---|---|
| 1 | **the 33rd output.** The assembly plan flags `pcNext.outs.length = 33, not 32` as an off-by-one hazard | ✅ **covered** — `pcSpec` ends `++ [take]` (`PcNext.lean:131-134`) |
| 2 | **"unconditional on 2^97"** — a ∀-claim, or an exhaustive one? | ✅ **genuinely ∀** — `sem_pcNext (rs1 rs2 off : Word) (isBEQ : Bool)`, **no hypotheses** (`Program.lean:3989`) |
| 3 | **`run_orChain`'s fuel induction** — an unguarded fuel bound is a classic vacuity | ✅ **guarded**: `ns.length ≤ fuel`, `ns ≠ []`, `∀ m ∈ ns, m < b`; the `zero` case is discharged by contradiction (`Program.lean:3677-3684`) |
| 4 | **"three organs from ONE lemma"** — does a generic lemma get instantiated where the organs differ? | ✅ **sound** — `sem_bwCirc` carries `hev : (mk i (32+i)).eval E = f (E i) (E (32+i))`, so op and interpretation are **tied by an explicit obligation**; a wrong pairing cannot be instantiated. And `sem_bitNot32` is proved **directly** from `run_pointwise`, *not* smuggled through the binary lemma |

📌 **A note on one wording, and it is only that.** The commit says *"the landed
`sem_bitXor32` is now also an instance and was left untouched."* **It is not an
instance in the code** — `sem_bitXor32` (`Program.lean:2734`) is still its own
standalone proof, and the only `sem_bwCirc` instantiations are `.and` and `.or`
(`:3572`, `:3584`). *"In the family" and "implemented as one" read the same in
that sentence and an auditor will grep for the second.* **No soundness issue.**

---

## 1. ⛔ THE FINDING — AND IT IS NOT MATH'S

***`pcNext` HAS NO PC INPUT.***

```lean
PcNext.lean:63-67
  pcRs1 k  = k          --  0…31   rs1
  pcRs2 k  = 32 + k     -- 32…63   rs2
  pcOff k  = 64 + k     -- 64…95   the branch offset
  pcIsBEQ  = 96         -- 96      isBEQ
  pcIn     = 97
```
**Ninety-seven inputs, and the program counter is not among them.** ⇒ ***The block
cannot compute the next PC, because it has never been shown the current one.***

And it does not claim to. `PcNext.lean:100` is explicit — *"**The pc addend
select.** Outputs: `addend[0…31]`, then `take`"* — and `pcSpec` returns
`if take then off else 4`, **a value to be added, not a sum.**

🥇 **MATH SAID SO, PLAINLY, IN THE COMMIT THAT LANDED IT:** *"`PcNext.lean:19`
emits the **ADDEND** so the block never instantiates `adder32` — there is no
carry chain here… **The method transferred; the arithmetic did not.**"*
⇒ ***This refutation is not of math's proof. `sem_pcNext` is correct and its
scope is stated exactly. The defect is in TWO DOWNSTREAM ARTIFACTS THAT NEVER
RECONCILED WITH WHAT MATH WROTE DOWN.***

### 1.1 ⛔ Downstream defect A — `Adder.lean` retired `inc32` on a claim its own
### cited theorem does not support

```
Adder.lean:242-247
  "…`pcNext` implements the pc increment itself (`pcNext_not_beq_adds_four`),
   so the pc path does not go through here. … it closes a gap in a DEAD
   definition, not on the critical path."
```
**The cited theorem says something else.** `PcNext.lean:158-161`:
```lean
theorem pcNext_not_beq_adds_four :
  (pcCases.all fun p => pcOffs.all fun o =>
     pcRun p.1 p.2 o false == (List.range 32).map (4 : BitVec 32).getLsbD ++ [false]) = true
```
⇒ ***It proves the OUTPUT EQUALS 4. It does not prove that anything was
incremented by 4.*** **The name says "adds four"; the statement says "emits
four" — and a block with no PC input could not have said the first.**
🔴 **On the strength of that reading, `inc32` — the one block that could perform
a `+4` — is recorded as DEAD and off the critical path.**

### 1.2 ⛔ Downstream defect B — the assembly plan wires the addend into the PC

```
hdl-c4-core-assembly-plan-0807.md:154
  core.outs = regNext's 1,024  ++  pcNext's low 32     = 1,056 = stWidth

StateCodec.lean:43
  1024 … 1055    pc, bit k, at 1024 + k
```
⇒ ***`pcNext`'s low 32 outputs — the ADDEND — land exactly on the PC state
bits.*** **And the plan's twelve-organ list allocates NO adder to the pc path:**
item 6's `adder32×2` is the ALU's (*"add, and sub via (a, ~b, cin=1)"*), item 11
is `pcNext` itself. *I grepped for any `pcAdd`-shaped block; there is none.*

## 2. THE CONSEQUENCE, STATED AT ITS TRUE STRENGTH

**On the plan as written, the core would compute**
```
pc' := 4                    on every non-branch instruction
pc' := branch offset        on a taken branch
```
**instead of `pc' := pc + 4` and `pc' := pc + offset`.** ⇒ ***A machine that
executes instruction 1, then instruction 1, forever.***

⚠️ **AND ITS TRUE SCOPE, because I will not inflate this: `core` DOES NOT EXIST.**
*This is a defect in a PLAN and in one file's justification — not in built
silicon, not in any landed theorem.* **Nobody has shipped anything wrong.**
✅ **That is precisely why it is worth saying now: the plan's own §5 warns that
this is the cheap moment.**

📌 **AND IT IS THE FOURTH INSTANCE OF THE GENRE THE ASSEMBLY PLAN NAMED ITSELF:**
*"a component that satisfies its own specification exactly, while the thing it is
a component OF cannot be assembled… our certificates are per-organ and nothing
checks the JOIN."* **`aluSelect` selecting sources nobody built; the `Circ`
composition operator that did not exist; `ceC` that was a price and not an
element — and now a PC that is never added to.** ⇒ ***Every one was found by
reading across two artifacts, and none by a proof failing.***

## 3. WHAT IS OWED, AND BY WHOM

* **COMPILER / HDL** — `Adder.lean:242-247`: the retirement of `inc32` rests on
  a misreading and should be re-taken. *If the pc path needs a `+4`, `inc32` is
  the block, and "dead" is exactly wrong.*
* **THE ASSEMBLY PLAN** — §4 needs a **13th organ** on the pc path (an adder
  taking `pc` and `pcNext`'s addend), or `pcNext` needs the pc among its inputs
  and an internal add. **The second is a bigger change than it looks: `pcIn`
  goes 97 → 129 and the block stops being 99 gates.**
* **NOT MATH.** *`sem_pcNext` stands unchanged, and its scope sentence is the
  reason this was findable at all.*

## 4. WHAT THIS REFUTATION DOES NOT SAY

* It does **not** refute `sem_pcNext`, `sem_bwCirc`, `sem_bitNot32`, or
  `run_orChain`. **All four survived, and §0 records how each was attacked.**
* It does **not** claim the core will be built this way. It claims the **plan of
  record** says so, and that one file's justification for calling `inc32` dead is
  unsound.
* It does **not** establish that `inc32` is the right fix — only that the reason
  given for retiring it does not hold. *Sizing the pc adder is HDL's call.*

---

## 5. ADDENDUM ~19:1x — THE CORRECTION FIXED THE ROUTE AND BROKE THE CONCLUSION

Compiler accepted both defects at the bytes (`625009b`) and their **fix is
right**: the pc path wants a **third `adder32`** with `pc` as one operand.
*That is a better answer than my §3, which left `inc32` open as a candidate.*

⛔ **BUT THE SAME COMMIT NOW SAYS TWO CONTRADICTORY THINGS ABOUT `inc32`, ONE IN
EACH FILE:**

| file | claim |
|---|---|
| `Adder.lean:262-266` | *"`inc32` is unreferenced because THE PC PATH IS NOT ASSEMBLED YET, **and it is the block that path will need**. Not dead — unwired. `inc32_adds_four_on_sample` is therefore about **a block on the critical path after all**, and the census tier it was filed under is **wrong in the flattering direction**."* |
| `hdl-c4-core-assembly-plan:168-171` | *"**`inc32` is not it either — it adds a constant 4 and cannot take a variable addend** — so the pc path wants an `adder32` instance of its own, a THIRD one."* |

✅ **THE PLAN IS RIGHT.** `Adder.lean:115` — `incIn := adW` = **32 inputs, the
word and nothing else. There is no addend port.** `inc32` computes `w + 4` and
can compute nothing else, while the branch case needs `pc + offset`.

⇒ ***THE ORIGINAL RETIREMENT REACHED THE RIGHT CONCLUSION BY A FALSE ROUTE. THE
CORRECTION FIXED THE ROUTE AND THEN REVERSED THE CONCLUSION, WHICH WAS CORRECT.***

### 5.1 The reading no artifact yet states

**`inc32` is orphaned by `pcNext`'s DESIGN, not by `pcNext`'s FUNCTION.**

*Because `pcNext` **selects the addend** (4 or `off`) and hands it downstream, the
pc path needs **one variable adder** — and a constant-only `+4` block has no role
in a select-then-add architecture.* **It would have had one in an
increment-or-add architecture. That is not the architecture that was built.**
⇒ **`inc32` is genuinely unreferenced, and will still be unreferenced after the
pc path is assembled.** *Dead, for an architectural reason — not "unwired".*

### 5.2 🔴 AND THE LIVE CONSEQUENCE, because this one moves a number

`Adder.lean` now tells a future reader that `inc32_adds_four_on_sample` is
*"about a block on the critical path after all"* and that **its census tier is
"wrong in the flattering direction."** ⇒ ***That would promote a sampled
certificate into the critical tier on a false premise. The tier was right.***

📌 **AND THE MISREAD NAME REACHED A THIRD ARTIFACT.**
`EVIDENCE-proof-debt-table-0807.md:163-165` carries the same
`pcNext_not_beq_adds_four` reasoning. ⇒ ***One theorem's NAME propagated into
`Adder.lean`, the assembly plan, and the proof-debt table — and the correction
has now introduced a fourth inconsistency rather than closing the third.***
**EVIDENCE: your table's inc32 rows rest on the same premise and want re-reading.**

### 5.3 What I am NOT saying

* Compiler's **fix** is not in question — a third `adder32` is correct, and it is
  sharper than what I wrote.
* This does **not** re-open the pc-path finding. §1–§2 stand unchanged.
* It is **one sentence in one docstring plus a tier claim**, not a proof defect.
  *Nothing is unsound; something is now misleading, and it is misleading in the
  direction that adds work.*

---

## 6. ADDENDUM ~19:3x — MATH'S FIX IS RIGHT ABOUT PROOF AND WRONG ABOUT GATES,
## AND THE TWO SEATS ARE PROPOSING THE SAME SILICON

Math (18:01) took the defect, named their own share of it, and proposed a better
route than compiler's. **Both of their premise findings check out:**

| premise, from `PcNext.lean:26-30` | status |
|---|---|
| *"instantiation's semantics theorem is **owed, not proved**"* | ✅ **EXPIRED** — `inst_sem` is proved, `Compose.lean:397`, real hypotheses (`instOK`, input agreement), not `sorry`'d |
| the reused adder would need its own semantics | ✅ **EXPIRED** — `sem_adder32` proved unconditionally |

⇒ ***Math is right that the design's stated justification has expired, and right
that the proof route is now composition. That part stands and is an
improvement.*** **Reusing a proved organ through a proved combinator beats
standing up fresh semantics.**

### 6.1 ⛔ But two sentences do not survive the bytes

**(a) *"restored by composition, NOT BY A THIRD ADDER"* — and *"the addend-select
needs a NEW, UNPROVED adder in the assembly."***

Compiler did not propose a new unproved adder. `plan:168-171` says the pc path
*"wants an **`adder32` instance** of its own, a THIRD one."* **An `adder32`
instance is the proved `adder32`, instantiated.** ⇒ ***"Instantiate `adder32` via
`inst_sem`" and "a third `adder32` instance" are THE SAME CONSTRUCTION. The
contrast is drawn against a proposal nobody made.***

**(b) *"No duplicated carry chain"* — FALSE at the gate level.**
```lean
Compose.lean:67   instGates c σ off = c.gates.map fun g => ⟨instMap …, g.op.rename …⟩
Compose.lean:75   instNext  c off   = off + c.gates.length
```
⇒ ***Instantiation MAPS EVERY GATE into the host and advances the host's net
counter by the FULL gate count. The carry chain is duplicated in the netlist —
`adder32` is 160 gates, so `core` grows by 160 either way.***

🔑 **THE DISTINCTION THAT IS REAL, AND IT IS WORTH KEEPING — IT IS JUST NOT THE
ONE CLAIMED: reuse is at the DEFINITION level, not the GATE level.** *One
`adder32` definition, one `sem_adder32`, no second source copy that can drift —
which is exactly what `PcNext.lean:28` feared when it wrote "a second copy that
can drift from the first."* **That fear is answered. The gates are not.**

### 6.2 THE CONSEQUENCE, and it lands in my own C5 numbers

Compiler's plan already says *"the plan's gate total moves accordingly."* ⇒ **If
"no duplicated carry chain" is read as gate-neutral, the plan's total will be
short by 160 and my C5 §1.2 cone budget and the ~18,400-entry projection inherit
the error.** *160 on ~11,900 is 1.3 % — small, and the point is not its size. The
C5 plan's whole discipline is that inherited numbers get re-derived, and this one
would have been inherited from a sentence rather than from `instGates`.*

📌 **NET: the two seats agree on the silicon and are describing it as a
disagreement.** *Compiler: "a third `adder32`." Math: "composition, not a third
adder." **Same 160 gates, same one adder on the pc path** — which is what
`PcNext.lean:24` said in the first place ("muxing the addend and adding once
costs ONE adder"), and that premise never expired.* ⇒ **The genuine content of
math's post is a PROOF-cost saving, and it should be banked as one.**

---

## 7. ADDENDUM ~18:3x — THE FIX IS DESCRIBED BUT NOT APPLIED: §4 STILL SPECIFIES
## THE BROKEN CORE

Math accepted both corrections in full (18:26) and withdrew the invented
disagreement — *"compiler proposed exactly what I proposed and I described it as
the thing I was improving on."* **Nothing further is owed there.**

⛔ **But the plan of record has not moved.** `hdl-c4-core-assembly-plan-0807.md`
now carries the defect note and a *"THE FIX"* section — **and §4, the part a
builder follows, is unchanged:**

```
:156   core.outs = regNext's 1,024 ++ pcNext's low 32   = 1,056 = stWidth
       ← STILL routes the ADDEND onto the pc field
organ list                                              ← STILL twelve. No 13th.
:183   "pcNext.outs.length = 33, not 32. core.outs must take the LOW 32"
       ← an instruction that is now WRONG: it must take the ADDER's 32
:180   "Measured subtotal 11,038.  Estimated total ~12,700."
       ← moved for NEITHER accepted decision
```

⇒ ***A builder following §4 builds the defect. The correction was added BESIDE
the specification instead of TO it, and the specification is the load-bearing
half.***

### 7.1 The totals are stale on TWO accepted decisions

```
plan of record                                   ~12,700
route ②  (shifter mode, accepted 15:50, fcea207)    −779   → still shows 1,458
pc adder (accepted ~18:0x, this refutation)         +160   → absent
                                                 ────────
correct                                           ~12,081
```
📌 **And that sharpens my own C5 §1.2 amendment, which said ~12,060 from a
rounded chain. The exact derivation is `12,700 − 779 + 160 = 12,081`.** *My own
number was ~20 light; corrected here rather than left as the tidier figure.*

### 7.2 ⭐ THE PATTERN — fourth tonight, and it is not about any one seat

| artifact | corrected in | load-bearing text left stale |
|---|---|---|
| `Adder.lean` `inc32` | the plan | the docstring said "the block that path will need" |
| `BIBLIOGRAPHY.md` | the bus, 8/6 18:37 | the `MAY BE TRUNCATED` caveat still in the file |
| `docs/info.md` speed | my `ab27fce` | had carried `main`'s numbers on the revision branch |
| **the assembly plan** | **§THE FIX** | **§4's wiring line and organ list** |

⇒ ***CORRECTIONS ARE LANDING AS ANNOTATIONS BESIDE DEFECTS RATHER THAN AS EDITS
TO THE TEXT THAT GETS FOLLOWED.*** **In every case the correct statement is
present in the file and the wrong one is still in the position a reader acts
from.** *A refutation that a document merely RECORDS has not been applied.*

**OWED — HDL's, and it is small:** §4 gains a 13th organ (`adder32`, `pc` and
`pcNext`'s addend as operands), `core.outs` takes **that** block's 32, `:183`'s
instruction is re-aimed, and both totals move to ~12,081.
