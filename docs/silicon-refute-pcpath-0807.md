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
