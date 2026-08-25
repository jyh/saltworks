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

---

## ✅ 2026-08-20T16:44:32-0700 — **THE CLOSURE, COMPUTED. The rule is now RUN, not written a third time.**

*I said the closure gets computed before the next swap attempt. Here it is — and the instrument is
the one that was already available: **the swap dry run itself.** The set of declarations that break
under D is not something to approximate from a reference graph; **the kernel enumerates it.** My
earlier textual attempt returned 84% of the tree and was worthless. This is 33 names.*

### MINE — `SaltWorks/HDL/**` (6), all in the swap's own scaffolding
```
SaltWorks.HDL.StateCodecD.encDD_getD_low
SaltWorks.HDL.StateCodecD.encDD_prefix
SaltWorks.HDL.StateCodecD.extension_costs_257_bits
SaltWorks.HDL.StateCodecD.landed_decQ_loses_mem_and_trap
SaltWorks.HDL.StateCodecD.renumbering_offsets
SaltWorks.HDL.StateCodecD.stBitD_agrees
```
⇒ **`StateCodecD` is scaffolding whose job ends AT the swap.** `landed_decQ_loses_mem_and_trap` is
Horn D exhibited as a theorem and MUST go false; `extension_costs_257_bits` and
`renumbering_offsets` become `0` because the two widths have merged; `stBitD_agrees` /
`encDD_getD_low` / `encDD_prefix` compare a codec to itself. **RETIRE the module in the swap commit
— do not repair it.** Repairing it would manufacture a comparison between two things that are now
the same object.

### MATH'S — `SaltWorks/Stack/**` (27), their pen, listed so they have it
```
SaltWorks.Stack.Program.addend_as_pc_is_wrong_unless_pc_zero
SaltWorks.Stack.Program.addField_is_adder32
SaltWorks.Stack.Program.aluField_is_aluSelect_add
SaltWorks.Stack.Program.bitAnd32_fails_the_xorField
SaltWorks.Stack.Program.c4Spec_iff_fieldwise
SaltWorks.Stack.Program.c4Spec_of_fieldwise
SaltWorks.Stack.Program.cycleRealisesStep_idealBits
SaltWorks.Stack.Program.cycleRealisesStep_of_C4Spec
SaltWorks.Stack.Program.cycleRealisesStepProj_of_bits
SaltWorks.Stack.Program.cycles_realise_steps_of_memFree
SaltWorks.Stack.Program.cycles_sort
SaltWorks.Stack.Program.decQ_congr
SaltWorks.Stack.Program.decQ_cycOf_proj
SaltWorks.Stack.Program.decQ_cycOfBits_stalled
SaltWorks.Stack.Program.decQ_envWith_of_clean
SaltWorks.Stack.Program.decQ_mem
SaltWorks.Stack.Program.not_C4Spec_of_not_regField
SaltWorks.Stack.Program.not_cycleRealisesStep_id
SaltWorks.Stack.Program.not_pcField_coreShaped
SaltWorks.Stack.Program.not_pcField_coreShapedT
SaltWorks.Stack.Program.not_regField_one_coreShaped
SaltWorks.Stack.Program.pcField_is_pcAdd_beq
SaltWorks.Stack.Program.pcField_is_pcNext_beq
SaltWorks.Stack.Program.sltField_is_sltCirc
SaltWorks.Stack.Program.sorts_of_C4
SaltWorks.Stack.Program.stBit_pc
SaltWorks.Stack.Program.xorField_is_bitXor32
```
⛔ **`c4Spec_iff_fieldwise` AND `c4Spec_of_fieldwise` ARE IN THAT LIST.** That is the flagship's own
decomposition, and it is the **34 → 43 obligation growth I flagged to the pen this morning, now
arriving as a concrete break rather than a prediction.** The `not_*` rows
(`not_regField_one_coreShaped`, `not_pcField_coreShaped(T)`, `not_cycleRealisesStep_id`) are
refutation rows and need the same fire-or-survive judgement as the LW set — **they are not
"failures to fix".**

### ⚠️ THIS IS A LOWER BOUND AND MUST BE READ AS ONE

**A failing module masks every consumer downstream**, so anything that would break *because*
`Program.lean` broke never got the chance to. The honest statement: **at least these 33;
the true closure is discovered only on a run where the earlier failures are already repaired.**
⇒ Re-run this extraction at every swap attempt. *The list is an output of the build, not an
artifact I maintain — which is the whole point, and why the rule failed the first two times I wrote
it as something to remember.*


---

## 2026-08-25 — THE BASELINE, CAPTURED BEFORE THE REPAIR (compiler)

The council ruled **HORN D STANDS UNAMENDED** this sitting (`seat/briefs/2026-08-19-maestro-night-bank.md:1288`,
Captain verbatim *"I think we should do D alone"*; priced at `seat/briefs/2026-08-19-compiler-c4spec-refuted.md:500`).
W5-asm's second half proceeds as **THE REPAIR**, and this table is its BEFORE-STATE.

⛔ **A DIFFERENTIAL WITHOUT A RECORDED BEFORE-STATE IS NOT A DIFFERENTIAL.** Every declaration
below **PROVES TODAY**. Verdicts lifted from ONE full build-arm run (`EXIT=0`, `8744` jobs, `0`
errors) — the arm that WRITES oleans, not the path form that elaborates and discards.

```
  decQ_mem                                  ✓ SaltWorks.Stack.Program.decQ_mem      [2 axioms]  MUST BREAK
  stepT_lw_writes_zero                      ✓ C4Refuted.stepT_lw_writes_zero        [2 axioms]  MUST BREAK
  lw_forces_false_whatever_the_enable_does  ✓ C4Refuted.lw_forces_…enable_does       [3 axioms]  MUST BREAK
  datapath_forces_zero_select_on_LW         ✓ C4Refuted.datapath_forces_zero_…       [3 axioms]  MUST BREAK
  no_enable_repairs_the_load                ✓ C4Refuted.no_enable_repairs_the_load   [3 axioms]  MUST BREAK
  regDatapathOK_is_false_on_LW_either_way   ✓ C4Refuted.regDatapathOK_is_false_…     [3 axioms]  MUST BREAK
  c4Spec_core_is_false                      ✓ C4Refuted.c4Spec_core_is_false         [3 axioms]  MUST BREAK
                                                                                                 (only AFTER the load is repaired)
  step_lw_writes_zero                       ✓ C4Refuted.step_lw_writes_zero          [2 axioms]  MUST SURVIVE, TEXT UNCHANGED
  step_lw_trap_holds                        ✓ C4Refuted.step_lw_trap_holds           [2 axioms]  MUST SURVIVE, TEXT UNCHANGED
```

⭐ **THE BASELINE COST NOTHING EXTRA — it was extracted from a build run for a DIFFERENT reason**
(confirming a peer's red on the root). A build log already carries a verdict for every
declaration; the only thing that makes it a baseline is READING IT BEFORE you change anything.

### The swap's measured shape, from the isolated dry run (same day)
```
  staged patch    docs/Q3-SWAP-STAGED-STATECODEC-0822.diff, StateCodec.lean ONLY
                  git apply --check against HEAD: EXIT=0 — it still applies
  patched file    elaborates in isolation: EXIT=0, 0 errors, all 22 declarations audited
  stWidth         1056 -> 1313   (delta = 8*32 memory bits + 1 trap bit)
                  that delta equals StateCodecD's extension_costs_<n>_bits EXACTLY,
                  which cross-confirms this patch IS the D swap
  adds            exactly one declaration, decQ_encD
```
⇒ **`stWidth` is the numeral every organ offset is stated against, so the downstream breakage is
a RENUMBERING** — the pre-registered member `renumbering_offsets`.

⛔ **STILL OWED, AND NOT FAKED: the FULL closure.** It needs the dependents built against the
patched codec; a fresh worktree has no `.lake`, so that is a cold build, and the cheap route
(symlinking the SHARED mathlib packages) risks a cache five seats depend on. **The textual route
is barred by this document's own §115: it returned 4468 names, 84% of the tree, and is called
worthless here.** The kernel enumerates that set or nobody does.

## 2026-08-25 — LAYER-2 PRE-REGISTRATION: THE MASKING CLOSURE, COMPUTED BEFORE THE SECOND FIRING (compiler)

*Fired under the helm's word resuming this lane in full. Written and landed BEFORE the build that
tests it, because a prediction recorded after the output is not a prediction.*

### ⛔ THE UNDER-COUNT WAS MINE, AND THIS FILE'S OWN WARNING CAUGHT IT

The 08-25 dry run named **6** never-reached modules (`CorePlace`, `CoreAssembly`, `CoreOffsets`,
`AccountMeasure`, `C4Refuted`, `Stack.Program`) and warned that *"the under-count looks like an
encouragingly small blast radius."* **That warning applied to its own number.** Reverse-import
closure over `StateCodecD`, computed rather than read off one build log:

```
  masked, ALL .lean on disk        143   max depth 16   (87 are Scratch*)
  masked AND IN THE ROOT BUILD      56   max depth 15   <- THE OPERATIVE NUMBER
  root build total modules         163   => 34% of the root build sits behind this one module
  named by the dry run               6   => the dry run saw 11% of what it masks
```
⇒ **`Stack/Program.lean` and `HDL/LwWitnessD.lean` are the ONLY depth-1 members.** Everything
else — `CorePlace`, `CoreOffsets`, all four `Certs.*`, the whole `SelValue*`/`Wire*`/`Bridge*`
chain out to depth 15 — is masked THROUGH `Program.lean`, not directly.

⚠️ **DEPTH IS NOT PASSES, AND READING IT AS PASSES WOULD BE A FALSE ALARM IN THE SCARY
DIRECTION.** Lake reveals every module whose dependencies succeeded, so one build clears an
arbitrary number of depths that carry no break. **Passes required = the number of depths at which
something ACTUALLY BREAKS**, bounded above by 15 and possibly as low as 2. The depth figure bounds
the worst case; it does not predict the work.

### THE PREDICTIONS — falsifiable, and each names what would refute it

```
  P1  re-firing the patch reproduces EXIT=1, 14 errors, ALL in StateCodecD,
      convicting exactly the 6 pre-registered scaffolding declarations.
      REFUTED BY: any different count, or an error outside StateCodecD.
  P2  after the 6 retire, the next build's errors land at DEPTH 1 — Stack.Program
      and/or LwWitnessD — and nothing deeper is yet visible.
      REFUTED BY: errors appearing at depth >= 2 in the same build.
  P3  decQ_mem FAILS TO COMPILE. (Check 1 of this file. A green decQ_mem means STOP;
      nothing downstream is informative.)
  P4  the 27 Program.lean names listed above are a LOWER BOUND: I predict the actual
      count EXCEEDS 27. REFUTED BY: exactly 27 or fewer.
  P5  ⭐ LwWitnessD BREAKS, AND THIS FILE NEVER LISTED IT. It consumes decQD six times
      and sits at depth 1, so it was MASKED in the run that produced the closure and
      could not have appeared. REFUTED BY: LwWitnessD building clean.
```
⇒ **P5 is a FOURTH membership miss, and the first one found BY ENUMERATION rather than by being
hit.** The three prior misses (`X0`, `landed_decQ_loses_mem_and_trap`, `decQ_mem`/`decQ_trapped`)
were all discovered by a build hitting them. *A kernel closure can only enumerate what was not
masked, so it under-reports by construction on exactly the modules this document cares about.*

### ⚖️ THE RETIREMENT, AND WHERE I DEPART FROM THE LITERAL RULING — STATED, NOT SLIPPED

The 08-20 ruling says **"RETIRE the module in the swap commit — do not repair it."** Its stated
reasons cover only the SIX comparison declarations: `landed_decQ_loses_mem_and_trap` must go false,
`extension_costs_257_bits`/`renumbering_offsets` collapse to `0`, and
`stBitD_agrees`/`encDD_getD_low`/`encDD_prefix` compare a codec to itself.

⛔ **BUT THE MODULE IS NOT ONLY SCAFFOLDING, AND THAT IS MEASURED:** `stWidthD`, `stBitD`, `encDD`,
`decQD`, `Cell.place`, `cellOf_place` and `stBitD_at_place` are consumed by three importers —
`Stack/Program.lean` (7 symbols), `LwWitnessD.lean` and `ScratchQ6Witness.lean` (`decQD` x6 each).
**Retiring the MODULE reds those; retiring the SIX is what the reasons license.** Also
`instrBaseD` and `instrD_nets_disjoint_from_state` sit INSIDE the priced section and are NOT
convicted — they must survive the cut.

⇒ **I RETIRE THE SIX CONVICTED DECLARATIONS, NOT THE FILE**, and the module's definitional half
stays until its consumers are migrated. *`SaltWorks.lean` imports `StateCodecD` and is MAESTRO
ONLY; deleting the file would red the shared root for five seats on a file this seat may not edit.*

⛔ **AND THE PROSE MOVES WITH THEM.** The section header *"THE PRICE OF THE SWAP"* asserts
*"`instrBase := stWidth` in `StateCodec.lean` is untouched and still reads 1056."* **The swap makes
that sentence false, and a false docstring builds green forever.** It is rewritten in the same
commit as the declarations it describes — a retirement is a docstring-boundary edit.

