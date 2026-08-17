# TEMPORAL OBLIGATION OWNERSHIP — ONE ARTIFACT, ONE PEN, cmp-VERIFIED

**Ordered by the helm 2026-08-17 12:02; custody arbitrated 12:06 after a collision.
Compiler holds the pen on this file; silicon's block embeds its bytes verbatim.**

> ⚠️ **CUSTODY, AND WHY IT IS WRITTEN AT THE TOP.** At 12:04 this file was created by
> compiler and destroyed within the minute: silicon wrote the same name in **lowercase**,
> macOS is case-insensitive/case-preserving, both names resolve to ONE INODE, and the
> second write replaced the first. The surviving name still carries compiler's uppercase
> `TABLE` — the proof of whose file it was. **It was untracked, so git held nothing.**
> ⇒ **ONE PEN (compiler) · COMMITTED ON CREATION · never a lowercase twin.**
> *Reproduced on this filesystem before being written down, not taken on report.*

---

## THE TABLE

| # | obligation | OWNER | CROSS-VERIFIER | ARTIFACT IT LANDS IN | CONTROL THAT WOULD CATCH ITS ABSENCE |
|---|---|---|---|---|---|
| T1 | stall / arbitration **contract** — which cycles are NOT-cycles | **silicon** | compiler | silicon's offboard block | a NOT-cycle the contract does not name, and no gate refuses the trace |
| T2 | which-cycle **statement shape** + the trace predicate | **compiler** | silicon | compiler's block → `Certs/` | a stalling trace under which the hypothesis is **still satisfiable** ⇒ vacuous, green, silent |
| T3 | bus-protocol **FSM proof** | **silicon** | compiler | silicon's offboard block | a trace where the FSM deadlocks mid-transaction and every current check stays green |
| T4 | arbitration **fairness**, restated as **BOUNDED WAIT** | **silicon** | compiler | silicon's offboard block | a fetch waiting longer than the stated phase bound, with no gate that counts |
| T5 | **store-path timing** — `dmem_we` rising vs the beat leaving the pins | **silicon** | compiler | silicon's block + the seam statement | `we` on beat *n*, data on beat *n+k*, and the seam theorem still elaborates |
| T6 | **`ISA.step` / `runWords` extension** | **compiler** | silicon | `Stack/Program.lean` | the extended object and `runWords` agreeing on **every** trace — no distinguishing witness means the extension is cosmetic and no stall entered |
| T7 | the **13 consumers'** re-proof | **compiler** | silicon | `Stack/Program.lean` | any consumer whose statement changed while its proof did not |
| T8 | the **K/N unit re-cut** (UK1) | ⛔ **the Captain, via the helm** | both | routed, not designed here | a guard passing at a fraction of the intended instructions — green and wrong |

## WHY THE THREE ORPHANS LAND ON SILICON — silicon's principle, adopted

**Each is a property of an artifact silicon writes. Ownership follows the ARTIFACT, not
the difficulty.** T3's FSM is RTL; T4's "fetch yields to data" is silicon's own arbitration
rule; T5's ordering is RTL sequencing. *An owner who does not hold the object cannot fix a
failed proof.*

## ⭐ T4 CHANGES SHAPE ON INSPECTION — silicon's finding, and it is the best thing here

*"Fairness" invites a **liveness** proof — "fetch is not starved forever" — and this fleet
has no liveness machinery in silicon.* **But under `FETCH YIELDS TO DATA` a data
transaction is BOUNDED: at most 8 phases.** ⇒ ***Fairness reduces to BOUNDED WAIT, a
SAFETY property provable by the same accounting that produced worst-case CPI. An
obligation nobody could discharge became an arithmetic one.***

⚠️ *And the structural reason starvation cannot arise: a data transaction exists only
because an instruction was already fetched. **There is no source of data traffic
independent of fetch.***

## ⛔ T6's CONTROL WAS A FALSE NEGATIVE, AND THIS TABLE FROZE IT INTO THREE FILES

*Repaired 2026-08-17 14:0x. The original read: "`runWords_succ` still closing by `rfl`
afterwards — if it does, no stall entered."* **`runWords_succ` is `rfl` BY THE SHAPE OF THE
RECURSION** *(`Program.lean:1413-1414`)*; *it survives any word-stream encoding, so it
would have reported "no stall entered" **while a stall had entered**.*

🔑 ***AND THE TELL IS STRUCTURAL, VISIBLE BY READING THE COLUMN DOWN: every other control
names a FAILURE STATE — something green-and-wrong that can occur while the obligation is
undischarged. T6 alone named a PASS CONDITION.*** *A control that describes success cannot
discriminate; it can only agree with you.*

⚠️ **THE INTERFACE ARTIFACT'S FIRST REAL LESSON, AND IT CUTS BOTH WAYS.** *Byte-identity
did exactly what it was built to do and **propagated a defective row to three files at
once**. A shared interface makes agreement cheap and makes a defect in the interface
maximally expensive. **The cmp check proves the copies match; it cannot prove the original
is right** — and nothing in the mechanism ever will.

## THE COLUMN THAT DOES THE WORK IS THE LAST ONE

*Owner and cross-verifier are assignments; **the control is what makes an assignment
checkable.** A row whose control says "review it carefully" is an unowned row with a name
attached.* ⇒ **Every control above names a state in which an artifact would be GREEN while
the obligation went undischarged** — because that is this seam's measured failure mode,
three times today, and not a hypothetical.

## WHAT CROSS-VERIFIER MEANS — a role, not a courtesy

```
the OWNER     writes the artifact, states the obligation, lands the proof
the VERIFIER  must be able to say NO: re-derive from their OWN instruments and
              REFUSE if it does not reproduce
```
⛔ **A cross-verifier who only reads is decoration.** *Each verifier owes at least one
demonstration that their check CAN reject.*

## STANDING CONDITIONS

- **No option is chosen and no wave runs** until this table is in both blocks and both
  revised blocks pass their refuter rounds. *(helm, 12:02)*
- **T8 is routed, not absorbed.** Neither seat designs the K/N re-cut without his word.
- **An obligation discovered later gets an owner BEFORE it gets work.** The orphans existed
  because the boundary was described before it was divided.
- **This file is committed on every edit.** An untracked artifact in a shared tree has no
  custody and no recovery — which is not a lesson from a manual, it is what happened here.
