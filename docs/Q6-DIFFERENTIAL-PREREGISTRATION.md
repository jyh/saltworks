# Q6 — THE LW DIFFERENTIAL SET, PRE-REGISTERED BEFORE HORN D

**Stamped `2026-08-20T12:47:15-0700`, tree at `542ae9c`. Horn D has not started.** This file exists so the verdicts
below cannot be fitted to what D turns out to produce. Q6 is ruled seat-only; this is its first
deliverable, and it is deliberately NOT code.

## Why a pre-registration is required here rather than merely useful

The LW exhibits **quantify over the CURRENT `decQ`**. Their statements do not mention memory, so
D changes what they MEAN while leaving their text identical.

```
decQ_mem (ins : Env) : (decQ ins).mem = Vector.replicate 8 0 := rfl
```
*`rfl`* — it holds **definitionally**, because `decQ` literally writes `mem := Vector.replicate 8 0`.
Every LW exhibit is downstream of that one declaration.

🔑 ***THE FAILURE MODE IS NOT THAT AN EXHIBIT BREAKS. IT IS THAT IT KEEPS PROVING FOR A NEW AND
VACUOUS REASON.*** "The LW refutation survived D" and "D made the LW refutation meaningless" are
**indistinguishable from a green build**, and no arm in the seat's kit separates them.

## ⛔ THE VACUITY IS CONCRETE, NOT HYPOTHETICAL — MEASURED ON THE LANDED LITERAL

```
def sL : Nat := 2 ^ 66 ||| 2 ^ 34 ||| (wL.toNat * 2 ^ 1056)
```
**`sL` HAS NO BITS ABOVE 1087 — AND NOT BY ACCIDENT OF THIS PARTICULAR LOAD.** Computed over the
WORST CASE `wL.toNat = 2^32 - 1`, i.e. for *every* `wL : BitVec 32`:

```
highest set bit index            1087
any bit at index >= 1088         False
region 1088..1311 (where mem sits if the instruction stays at 1056)   ALL ZERO
```
⇒ ***THE `sL` CONSTRUCTION IDIOM IS STRUCTURALLY INCAPABLE OF POPULATING A MEMORY REGION.*** It
tops out at 1088 because it is `state-bits ||| (word * 2^instrBase)` and nothing more. So this is
not "the witness happens to be empty there" — **no witness written in this shape can be anything
else**, and every LW exhibit in the module inherits that. A post-D run would therefore find the load still writing zero and report
`regDatapathOK_is_false_on_LW_either_way` as SURVIVING, on a witness that cannot distinguish
"the model has no memory" from "the model has a memory and it is empty here".

⇒ **THE BAR, STATED BEFORE THE EVIDENCE EXISTS: any post-D verdict on an LW exhibit computed
against a witness whose LOADED WORD IS NOT PROVABLY NON-ZERO IS VOID.** Re-choosing the witness
is part of Q6, not a detail of it.

## The must-break / must-survive set

| exhibit | REQUIRED post-D verdict | why | the WRONG way it could pass |
|---|---|---|---|
| `decQ_mem` | ⛔ **MUST BREAK** — `rfl` must fail | the single point where D enters the model | **if it still proves, D connected nothing** and the entire campaign is a no-op wearing 1313 bits |
| `step_lw_writes_zero` | ✅ **MUST SURVIVE, TEXT UNCHANGED** | hypothetical in `hmem`; a true ISA fact about *any* zero-memory state | — |
| `step_lw_trap_holds` | ✅ **MUST SURVIVE, TEXT UNCHANGED** | the trapping arm; no memory dependence at all | — |
| `stepT_lw_writes_zero` | ⛔ **MUST BREAK** | it discharges `hmem` **by supplying `decQ_mem ins`** | ⚠️ "repaired" by ADDING `(decQ ins).mem = Vector.replicate 8 0` as a hypothesis — true, and vacuous on all real traffic |
| `lw_forces_false_whatever_the_enable_does` | ⛔ **MUST BREAK** | rewrites with `stepT_lw_writes_zero` | same re-added zero-memory hypothesis |
| `datapath_forces_zero_select_on_LW` | ⛔ **MUST BREAK** | same chain | same |
| `no_enable_repairs_the_load` | ⛔ **MUST BREAK** | same chain | same |
| `regDatapathOK_is_false_on_LW_either_way` | ⛔ **MUST BREAK — this is D's whole purpose** | D exists so the load can be right | ⛔⛔ **survives on the zero-memory witness above.** THE most likely wrong pass, and it reads as vindication |
| `c4Spec_core_is_false` | ⛔ **MUST BREAK — but ONLY AFTER the load is repaired** | it is currently routed *through* the load | ⚠️ if it breaks while the load is still wrong, **a refutation was lost without a proof being gained** |
| `insL` group (`seen_insL`, `dec_insL`, `sel2_insL`, `held_insL`, `isa_insL`) | 🔁 **MUST BE RE-CHOSEN, NOT RE-PROVED** | `2 ^ 1056` in `sL` is `instrBase` written as a bare literal | under a contiguous D layout `instrBase` moves, `seen_insL` reads zeros and `dec_insL` dies **LOUDLY — the good case**. ⚠️ Patching the literal to the new base silently restores the zero-memory accident |

## The three checks that must run, in this order

1. **`decQ_mem` must fail to compile.** Run it FIRST. A green `decQ_mem` after D means stop —
   nothing downstream is informative.
2. **Every ⛔ row must fail, and each failure must be READ.** A row that fails for an unrelated
   reason (a moved net, a renamed lemma) has not discharged its obligation. *`#audit_axioms`
   aborts its list at the first failure, so absences read as clean — read TICKS, not absences.*
3. **Re-establish the load's verdict on a witness with a provably non-zero loaded word.** State
   the witness's memory content explicitly as a theorem, not as a literal a reader must decode.

## What this file does NOT license

It fixes the VERDICTS, not the repair. It does not authorise weakening any statement to make a
row land on its required side: **a row that will not reach its pre-registered verdict is a WALL,
reported as one.** And it says nothing about Q10 — the restated C4 sentence is ⚖️ Captain/Fable
and no differential here touches it.

---

## ⛔ AMENDMENT 2026-08-20T13:50:43-0700 — **I ENUMERATED THE POPULATION FROM A FILE, AND THE FILE WAS THE WRONG SET**

The table above was built by listing the exhibits **in `C4Refuted.lean`**. That is a FILE, not the
set the pre-registration is about. The set is **every declaration whose truth depends on the
model's memory being all-zero**, wherever it lives — and the Q4/Q7 wave produced new members
within the hour, outside that file.

**Measured on the seven returned candidates** (seeds: `decQ_mem`, `stepT_lw_writes_zero`,
`lw_forces_false_whatever_the_enable_does`, `regDatapathOK_is_false_on_LW_either_way`,
`no_enable_repairs_the_load`, `datapath_forces_zero_select_on_LW`):

```
ScratchQ4ADDEx  ScratchQ4ADDIEx  ScratchQ4SLTEx  ScratchQ4XOREx  ScratchQ7writersEx   independent
ScratchQ7x0Ex          DEPENDS ON regDatapathOK_is_false_on_LW_either_way
ScratchQ7nonwritersEx  DEPENDS ON regDatapathOK_is_false_on_LW_either_way
```

### New registered members — verdict **MUST BREAK** when Horn D lands

- **`Q7x0.on_target_case_is_false`** — proved as
  `fun h => C4Refuted.regDatapathOK_is_false_on_LW_either_way (regDatapathOK_of_on_target h)`.
  It is **not a new defect**: it is the known LW refutation transported into the reduced form, so
  it inherits the all-zero-memory dependency exactly.
  ⚠️ **Its companion `Q7x0.regDatapathOK_of_on_target` is DURABLE and must SURVIVE** — the
  reduction says nothing about memory. *Landing the pair without distinguishing them is how a
  perishable exhibit gets mistaken for a permanent result.*
- **the corresponding row in `ScratchQ7nonwritersEx`**, same seed, same verdict.

### THE RULE, replacing the file listing

> **Membership is the DEPENDENCY CLOSURE of the seeds, re-computed at each landing — never a
> file listing, and never a set enumerated once.** Any new declaration reaching a seed joins the
> must-break set in the same commit that lands it.

⚠️ **AND HOW NOT TO COMPUTE IT.** My first attempt built a textual reference graph over all 5327
declarations and returned a closure of **4468 — 84% of the tree**. The cause: once `C4Refuted`
members entered, their SHORT witness names (`r1`, `s0`, `insL`, `wI`) matched every declaration
mentioning those tokens anywhere, and it cascaded. **A token-reference graph answers "who typed
this string", never "who depends on this theorem."** The narrow per-candidate check quoted above
is the reliable instrument; the whole-tree closure as written is not, and its 84% must not be
quoted as a dependency figure.

---

## ⚖️ RULING 2026-08-20T16:38:36-0700 — **THE PIVOT IS NOT REPAIRED, NOT PRE-RETIRED. IT IS CONSUMED.**

*Math asked for a ruling before touching `Stack/Program.lean:1505–1510` — `decQ_mem` and
`decQ_trapped`, `rfl` proofs asserting `decQ` builds those fields as LITERALS — on the grounds that
retiring my own pivot is my call. It is, and here it is.*

**RULING: LEAVE THEM EXACTLY AS THEY ARE. Do not repair them, and — the part that matters —
DO NOT RETIRE THEM IN ADVANCE.**

🔑 ***A DIFFERENTIAL THAT IS REMOVED BEFORE THE CHANGE CANNOT FIRE AT THE CHANGE.*** *Pre-retiring
these would leave the swap with nothing to break, and "the pivot was already gone" is
indistinguishable from "the pivot did not fire" in every artifact anyone reads afterward.* Under D
they are FALSE, not merely unprovable, so they cannot be restated in shape — **retirement is
correct, and its TIMING is the whole content of this ruling.**

⇒ **They break AT the swap, in the open, and the swap commit RETIRES them citing the observation.**
Fire and consume in the same commit — the same rule the queue already puts on Q9's C4Refuted rows.

✅ **AND MATH'S RECLASSIFICATION IS ACCEPTED, against my own framing.** I reported "37 errors in
`Program.lean`" under a heading that read as *their* insufficiency. It is not one population:
`1505–1510` are MY pre-registered pivot breaking CORRECTLY, and the `and_true` cluster is that
pivot's SHADOW — `simp only [decQ, St.mk.injEq, and_true]` strips the `mem`/`trapped` conjuncts only
because they are definitionally literals; under D they are not, so `and_true` stops firing and
`exact ⟨hr, hp⟩` wants four components. **One fact, many sites — not many defects.** *`St` already
had four fields; the ARITY never moved, and I did not check that before implying it had.*

## ⛔ THIRD MEMBERSHIP MISS TODAY — the rule keeps being right and keeps not being run

`Stack.Program.decQ_mem` and `decQ_trapped` are must-break members **that this document never
listed**, because I enumerated from `C4Refuted.lean`. Running total of members found by being hit
rather than by enumeration: the `X0` row (from the Q4/Q7 wave), `StateCodecD.landed_decQ_loses_mem_and_trap`
(scaffolding I landed myself), and now these two in **another seat's glob**.

⇒ **The amendment's rule — membership is the DEPENDENCY CLOSURE, recomputed at each landing — has
now been written twice and executed zero times.** It is a REMINDER, and by this file's own standard
that makes it an open defect wearing a discharge marker. **Before the next swap attempt the closure
gets COMPUTED, across every glob, or the must-break list is not a list.**
