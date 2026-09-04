# Q6 — THE LW DIFFERENTIAL SET, PRE-REGISTERED BEFORE HORN D

**Stamped `2026-08-20T12:47:15-0700`, tree at `542ae9c`. Horn D has not started.** This file exists so the verdicts
below cannot be fitted to what D turns out to produce. Q6 is ruled seat-only; this is its first
deliverable, and it is deliberately NOT code.

⛔⛔ **READ THE 2026-08-29 AMENDMENT AT THE FOOT OF THIS FILE BEFORE USING ANY VERDICT HERE.**
Five of the exhibits below **no longer prove**, and they broke for a reason that is NOT Horn D:
leg ① of the CorePlace campaign repaired the operand-B immediate path. `c4Spec_core_is_false`
broke **while the load is still wrong**, which is the case this file pre-registered as *"a
refutation lost without a proof being gained."* ⚠️ **NOTHING ABOVE OR BELOW THIS LINE HAS BEEN
EDITED TO MATCH THE OUTCOME** — a pre-registration that is rewritten after the fact is worth
nothing, so the bar stands exactly as it was written and the amendment is additive.

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


## 2026-08-25 — THE SECOND FIRING: LAYER 1 REPAIRED, LAYER 2 ENUMERATED, PREDICTIONS SCORED 3/5

*Fired 13:38–13:50 under the helm's word. Tree reverted to green (`saltbuild EXIT=0`, `8745`
jobs, `0` errors) and the whole layer-1 state preserved re-appliable at
`docs/Q3-SWAP-LAYER1-COMPLETE-0825.diff` (`git apply --check` = 0 against the reverted tree).*

### THE SCORE — and the two losses are worth more than the three wins
```
  P1  14 errors, all StateCodecD, exactly the six      ✅ CONFIRMED, exact
  P2  next errors at depth 1, nothing deeper visible   ✅ CONFIRMED, all 35 in Stack.Program
  P3  decQ_mem fails to compile                        ✅ CONFIRMED (sorryAx) — check 1 satisfied
  P4  MORE than 27 declarations convicted              ❌ REFUTED — 26. Fewer, not more.
  P5  LwWitnessD breaks                                ❌ REFUTED — built GREEN, 3 decls ticked
```

### ⛔⭐⭐ ONE ROOT ERROR CAUSED BOTH REFUTATIONS: **I USED A MASKING CLOSURE TO PREDICT BREAKAGE**

**They are different sets and I conflated them.** Depth-1 membership says a module becomes
*VISIBLE* when the hub clears. **It says nothing whatever about whether that module then FAILS.**

⭐ **`LwWitnessD` is the proof:** it imports ONLY `StateCodecD` and touches the non-D codec
(`decQ`/`encD`/`stWidth`/`stBit`) **zero times — measured**. It consumes the D-side exclusively,
which is exactly what the swap makes canonical, **so being masked behind the hub never made it
fragile. It was swap-proof the entire time.** P4 failed the same way: this file's "the closure is a
LOWER BOUND" is a statement about MASKING, and I read it as licence to over-estimate BREAKAGE.

🔑 ***THE MASKED SET AND THE MUST-BREAK SET ARE INDEPENDENT. A hub hides its dependents whether or
not the change touches them, so `masked` bounds what you can SEE and predicts nothing about what
will FAIL.*** ⚠️ *This is the MIRROR IMAGE of the 08-25 morning error recorded above: that pass
UNDER-counted what was hidden; this one OVER-counted what would break. **Same conflation, opposite
sign** — which is the tell that the two sets were never distinguished in the first place.*

### ⛔ AND A DEFECT IN THIS FILE'S OWN 27-NAME LIST, IN THE SAFE DIRECTION
```
  Q6 predicted                     27
  actually convicted               26
  predicted but did NOT break       1   ->  stBit_pc   ✓ GREEN at [2 axioms]
  broke but NOT predicted           0
```
⇒ **the list is a near-exact SUPERSET: one false positive, ZERO false negatives.** *Recorded
because a list that errs only toward over-prediction is a materially different instrument from one
that can miss, and the difference is invisible unless someone diffs it against a run.*

### LAYER 2, ENUMERATED — 26 convicted, but only **9 REAL FAILURES AT ~6 SITES**
```
  1506-1511  the pre-registered pivot firing exactly as designed (decQ_mem / decQ_trapped):
             maxRecDepth · Type mismatch · Not a definitional equality · Type mismatch
  1568:82    omega could not prove the goal
  1599:13    Application type mismatch
  2436:5 / 2436:36   unsolved goals (x2)
  3129:36    omega could not prove the goal
```
**The other 26 errors are the `#audit_axioms` roll-call reporting `sorryAx` downstream of these.**
⇒ *A failed tactic errors AND fills its hole, so the roll-call multiplies one defect across every
consumer. Counting audit errors as work items over-prices this repair by roughly 4x.*

### ⛔ ROW 6 WAS NOT DISCHARGED BY THE BUILD, AND THAT WAS INVISIBLE WITHOUT READING IT
`landed_decQ_loses_mem_and_trap` failed with **maximum recursion depth in PRETTY-PRINTING** — a
RESOURCE failure, not a verdict. **Check 2 says a row failing for an unrelated reason has not
discharged its obligation, and retiring it on that evidence would have looked identical, in every
artifact anyone reads afterward, to the five rows that fired correctly.**
⇒ Verdict established separately, `EXIT=0`, clean audit, `maxRecDepth 40000`:
```
  round_trip_now_holds : decQ (fun j => (encD sTestD).getD j false) = sTestD   ✓ [2 axioms]
  retired_row_is_now_false : ¬(decQ … ≠ sTestD)                                ✓ [2 axioms]
```

⛔ **READER'S NOTE ADDED 2026-09-03: `round_trip_now_holds` and `retired_row_is_now_false` ARE NOT
IN THE REPOSITORY** — gitignored `ScratchQ6Row6Verdict.lean` only. The verdict was real; the
artifact a reader would open is not there.
⭐ **Stated as the POSITIVE arm — what the swap ACHIEVED — rather than as the old row's absence:
the 1313-bit codec ROUND-TRIPS a state with eight distinct memory words and the trap flag SET.**
*That is Horn D exhibited, and it is also most of check 3: the witness's memory content is a
theorem rather than a literal a reader must decode.*

### THE RETIREMENT AS PERFORMED — SIX DECLARATIONS, NOT THE MODULE
The kernel settled the departure recorded above: **22 declarations ticked green and exactly the 6
convicted had no tick.** Retiring the MODULE would have destroyed 22 working declarations, 7 of
them consumed by three importers. ⛔ **A retirement has THREE surfaces, and the third is the one
that bites: the declaration, its docstring, AND its `#audit_axioms` roll-call line** — leaving the
roll-call behind turns a retirement into `unknown identifier`. Plus two prose blocks that went
FALSE at the swap (*"`instrBase := stWidth` … is untouched and still reads 1056"*), rewritten in
the same commit, because **a docstring that outlives its declarations builds green forever while
saying something false.**

### ⛔⭐ CORRECTION, SAME DAY: **"A RETIREMENT HAS THREE SURFACES" IS WRONG. IT HAS FIVE, AND THE FIFTH IS INVISIBLE TO EVERY BUILD.**

*I wrote "three surfaces" as a sentence, not as a measurement. `claimcheck.sh` flagged it as a
relation over a population and asked whether a COMMAND produced the number. It had not. Computed:*
```
  1  the declaration            10 `theorem` lines removed
  2  its docstring               9 `/--` lines removed
  3  its #audit_axioms line      6 roll-call lines removed   <- leave it => unknown identifier
  4  the section header          2 `/-!` removed, 1 rewritten <- whole sections retired with them
  5  CROSS-FILE PROSE POINTERS   1 live one, and NO BUILD CAN SEE IT
```
⛔ **SURFACE 5, NAMED AND REGISTERED BEFORE IT ROTS — `SaltWorks/Stack/Program.lean:2610`** (math's
glob, granted to this seat), inside a docstring:

> *"The same growth at bit level is `stWidthD - stWidth = 257` (`8*32 + 1`), which
> `StateCodecD.extension_costs_257_bits` already carries in the kernel."*

**It is CORRECT TODAY and becomes DOUBLY FALSE the moment the swap lands:** it cites a theorem that
will no longer exist, AND states a quantity that becomes `0` because the two widths merge.
⇒ ***THIS IS THE ONE SURFACE THE KERNEL CANNOT DEFEND. The declaration, the docstring, the audit
line and the section header all fail loudly; a prose pointer in another file BUILDS GREEN FOREVER
while naming a retired theorem.*** **Registered NOW, before the rename lands, because that is the
only moment at which it is cheap** — after the landing it is a true sentence about a vanished
object and nothing anywhere will complain. `docs/ledger-tools/prose_rot.py` exists and is the
instrument for exactly this class.

⚠️ **AND THE SURFACE-4 CHECK WAS ONLY EMPTY BY LUCK OF SCOPE:** all six retired names also appear
in `SaltWorks/HDL/ScratchQ3CodecEx.lean`, which is UNTRACKED and not a root target, so it never
built and could not have reported anything. *An empty result from an instrument that never ran is
not an empty surface.*

## ⛔⛔⭐⭐ 2026-08-25 — **A THIRD MASKING VARIANT: A BROKEN-BUT-PRESENT DECLARATION MASKS ITS CONSUMERS, SO THE LAYER-2 ENUMERATION UNDERCOUNTS THE RETIREMENT BY CONSTRUCTION**

*Found by a commissioned adversarial pass over the six layer-2 sites (5 analysts, 5 refuters,
`0` refutations sustained), and then verified AT THIS HAND rather than taken on the write-up.*

### THE MECHANISM
`Program.lean:1700-1701`, inside `decQ_cyc_eq_of_memFree`, is two bullets that `rw` with the
pivot pair:
```
  1700|   · rw [decQ_mem, stepT_mem_frame_of_not_touchesMem _ _ hmf, decQ_mem]
  1701|   · rw [decQ_trapped, stepT_trapped_frame_of_not_touchesMem _ _ hmf, decQ_trapped]
```
**In the layer-2 build these lines produced ZERO errors — verified, `0` hits at `169x/170x`.**
⇒ ***BECAUSE A FAILED TACTIC ERRORS AND STILL FILLS THE HOLE.*** `decQ_mem` remained a
declaration OF THE RIGHT TYPE, backed by `sorryAx`, so every consumer elaborated exactly as
before. **Delete the name and those bullets become `unknown identifier` — a NEW error class the
layer-2 enumeration COULD NOT HAVE SHOWN, because that run kept the broken declarations present.**

🔑 ***THE THIRD VARIANT, AND THE FAMILY IS NOW COMPLETE:***
```
  1  A FAILING HUB masks its DEPENDENTS          (found 08-25 am; 56 modules, depth 15)
  2  MASKED is not MUST-BREAK                     (found 08-25 pm; cost P4 and P5)
  3  A BROKEN-BUT-PRESENT DECL masks its CONSUMERS  <- THIS. sorryAx is well-typed.
```
⚠️ **VARIANT 3 IS THE WORST OF THE THREE FOR THIS CAMPAIGN, because it is the only one whose
error count GROWS AT THE MOMENT OF REPAIR.** *Variants 1 and 2 mis-state work that already
exists; variant 3 means **the enumeration is an under-estimate of the RETIREMENT specifically,
and no build can correct it until the retirement is performed.*** ⇒ **Re-enumerate AFTER each
retirement, not only after each swap.**

### ⛔ AND CHECK 2 IS UNSATISFIED FOR `decQ_mem` — THE ROW-6 DEFECT, A SECOND TIME, MISSED BY ME
```
  1506:0  maximum recursion depth has been reached      <- decQ_mem   RESOURCE failure
  1508:57 Type mismatch
  1510:0  Not a definitional equality: the LHS …        <- decQ_trapped  A REAL VERDICT
  1511:46 Type mismatch
```
**`decQ_trapped` carries a verdict. `decQ_mem` carries a `maxRecDepth` — the SAME class this
document ruled insufficient for row 6 four hours ago, and I read that exact error text at layer 2
and did not apply my own ruling to it.** *Check 1 (must fail to compile) IS satisfied, which is
what P3 claimed and P3 stands; **check 2 (each failure must be READ) is NOT**, and the two are
easy to conflate because both render as a red row.*
⇒ **OWED, and it is the row-6 remedy exactly: establish `decQ_mem`'s verdict separately, with the
budget raised, as a POSITIVE arm.** *A universally-quantified statement with an explicit
counterexample — `e := fun j => decide (j = 1056)` makes `(decQ e).mem[0]` non-zero under D — is
FALSE, not merely unprovable, and that is the fact the retirement must cite.*

### 📌 SURFACES THIS PASS ADDED TO THE FIVE — the register is not closed
- **PROSE THAT GOES FALSE, in-file:** `Program.lean:1473-1477` (the stated justification for the
  M2 projection cut: *"`decQ` CONSTRUCTS `mem := replicate 8 0` … so the left side is clean for
  every `cyc`, always"* — under D the whole-`St` form becomes SATISFIABLE, inverting the argument)
  and `:1534` (*"`decQ` reads only the state nets — `0 … 1055`"*).
- **CROSS-FILE POINTERS, out of the root build so no build sees them:**
  `HDL/LwDifferentialD.lean:6` and `HDL/ScratchQ6Diff.lean:6`.
- ⛔ **A NAME COLLISION THAT DEFEATS GREP-BY-NAME:** `HDL/C4Refuted.lean:208` declares a **SECOND**
  `theorem decQ_mem` (this seat's own glob, its own must-break row). **`rw [decQ_mem]` resolves by
  NAMESPACE, and a name-grep cannot tell the two apart** — resolve per file, never by grep.
  *Sibling of `a-name-grep-cannot-see-a-duplicate-theorem`, arriving as a live hazard.*

## 🧱 2026-08-25 — **LAYER 2 CONTAINS A WALL, AND IT IS A DEFERRED OBLIGATION COMING DUE — NOT A PROOF THAT GOT HARDER**

*Reported as a wall, per this document's own rule: "a row that will not reach its pre-registered
verdict is a WALL, reported as one." Verified at this hand, not relayed.*

### THE ARITHMETIC OF THE GAP
```
  St has FOUR fields          regs · pc · mem · trapped          (HDL/ISA.lean:85-92)
  CycleRealisesStepProj
    constrains TWO            regs · pc ONLY                     (Program.lean:1487-1490)
  decQ_cyc_eq_of_memFree
    concludes ALL FOUR        decQ (cyc ins) = stepT …           (Program.lean:1697)
```
**Today the two-field gap closes for free: `decQ` builds `mem` and `trapped` as LITERALS, so the
remaining goals are discharged by `rw [decQ_mem]` / `rw [decQ_trapped]` (`:1700-1701`).**
⇒ ***UNDER D THOSE FIELDS BECOME FUNCTIONS OF THE ENV, AND NOTHING IN THE HYPOTHESIS CONSTRAINS
`cyc`'s MEMORY NETS.*** A cycle map that realises steps on `regs`/`pc` while scrambling any net in
`1056…1312` **satisfies `CycleRealisesStepProj` and refutes the conclusion.**
⛔ **SO `decQ_cyc_eq_of_memFree` IS FALSE UNDER D, AND NO TACTIC REPAIRS IT — THE HYPOTHESIS IS
TOO WEAK.** *It is not in the 26-name convicted list, and it is not in Q6's 27, because it never
failed: `sorryAx` kept it green (variant 3, one section up).*

### ⭐⭐ AND THE OWNER ALREADY WROTE DOWN WHY — THE SWAP FALSIFIES THE DEFERRAL'S OWN PREMISE
`Program.lean:1480-1484`, math's docstring on the predicate:

> ***"THE PROJECTION IS NOT A WEAKENING, IT IS THE CODEC'S ACTUAL COVERAGE."*** *§0.2 of the memory
> block always priced this: the core codec covers **(regs, pc) ONLY**; `mem` lives in the `dmem8`
> organ across the F4 bridge, deliberately not mirrored. Memory realisation is **stage ③'s
> commissioned obligation** at that bridge — this predicate now says what it can honestly say, and
> no more.*

🔑 ***THE PREMISE OF THE DEFERRAL IS "THE CORE CODEC COVERS (regs, pc) ONLY", AND THAT IS EXACTLY
THE SENTENCE HORN D FALSIFIES.*** **The obligation was not forgotten and the predicate is not a
defect — it was honestly scoped to a codec that no longer exists after the swap.** *A deliberately
deferred obligation comes due at the precise change that removes the reason for deferring it, and
nothing anywhere fires when that happens: the predicate still compiles, the docstring still reads
as a considered decision, and only the consumer's conclusion silently becomes false.*

### ⇒ WHAT IS OWED, AND BY WHOM — THIS IS A SPEC DECISION IN MATH'S LANE, NOT PROOF WORK IN MINE
```
  OPTION A  strengthen CycleRealisesStepProj with mem/trapped clauses
            -> every producer of that predicate must now realise memory. That is
               stage ③'s obligation, arriving.
  OPTION B  weaken decQ_cyc_eq_of_memFree to a PROJECTION equality (regs/pc only)
            -> ⛔ this document forbids weakening a statement to make a row land;
               it would also break the n-cycle deliverable that consumes the whole-St form.
  OPTION C  carry a memory-frame hypothesis on `cyc` at the call sites
            -> pushes the obligation to the consumers rather than discharging it.
```
⚠️ **I HOLD THE PEN ON THIS FILE UNDER MATH'S GRANT, AND I AM NOT TAKING THIS DECISION ON IT.**
*The grant is for a mechanical renumbering pass; **choosing which of three spec shapes the memory
obligation takes is not renumbering**, and the owner deferred it deliberately with a written
reason. Reported, not resolved.*

### ✅ 2026-08-25 15:1x — **CHECK 2 DISCHARGED FOR `decQ_mem`, AND THE PROBE CAUGHT A STALE-OLEAN TRAP FIRST**

*Short announced window, scratch probe only, tree reverted and rebuilt to green (`EXIT=0`, `8745`
jobs). The row's layer-2 failure was `1506:0 maximum recursion depth` — a RESOURCE failure — so
check 2 was unsatisfied for it while its sibling `decQ_trapped` had a real verdict.*
```
  ✓ decQ_reads_memory_bit        [2 axioms]   POSITIVE ARM — D's decoder READS memory
  ✓ decQ_mem_is_false_under_D    [2 axioms]   the retired row is FALSE, not unprovable
  ✓ control_zero_env_still_clean [2 axioms]   CONTROL — on a zero env the field is still clean
```

⛔ **READER'S NOTE ADDED 2026-09-03 — THESE THREE NAMES ARE NOT IN THE REPOSITORY.** They live
only in the gitignored `ScratchQ6DecQMemVerdict.lean`. The ticks above are REAL OUTPUT of a real
run, which is exactly the problem: **a machine-shaped receipt is what a reader trusts without
checking, and the remembered half — that the run was over scratch — does not travel with it.**
The prose above does say "scratch probe only"; the BLOCK does not, and the block is what gets
quoted. Found by `docs/ledger-tools/cited_but_unlanded.py`, which exists because no gate here
could see this class: every gate reads the TREE or the BUILD, and a gitignored file is in neither.
⭐ **The control is what makes the witness mean anything:** without it, `mem[0] ≠ 0` supports
*"`decQ` is broken"* exactly as well as *"`decQ` now READS"*. **Both readings had to be separated
before the verdict could be cited in a retirement.**

### ⛔⛔ **THE TRAP, AND IT IS ONE OF THIS SEAT'S OWN BANKED CARDS FIRING ON ITS AUTHOR**
**My first run of that probe REFUTED ITS OWN POSITIVE ARM** — `decide` proved
`(decQ eWit).mem[0]!.getLsbD 0 = true` **false**, and a diagnostic showed EVERY field reading
zero, `trapped` included, against source that plainly reads them.
```
  CAUSE   `saltbuild <file>.lean` is the AUDIT ARM: it runs `lake env lean`, which links the
          COMPILED OLEANS of the imports. I patched the SOURCE and never rebuilt, and the last
          full build was the POST-REVERT green one — so the probe measured the PRE-SWAP CODEC.
  CURE    build the patched module FIRST (`saltbuild SaltWorks.HDL.StateCodec`), THEN probe.
          Re-run: mem = [1,0,0,0,0,0,0,0], trap reads net 1312. Witness was right all along.
```
🔑 ***A PROBE AGAINST A STALE OLEAN DOES NOT ERROR — IT ANSWERS ABOUT YESTERDAY'S CODE, IN A
FORM INDISTINGUISHABLE FROM A REAL VERDICT.*** **Believed, it would have read as "the swap does
nothing", which is the most damaging possible false conclusion for this campaign** — and it
arrives wearing a kernel `decide` refutation, the most authoritative shape available.

⛔⭐ **AND THE REVERSE DIRECTION IS WORSE, WHICH IS THE HALF THE CARD DID NOT CARRY: reverting
the SOURCE without rebuilding leaves PATCHED OLEANS against REVERTED SOURCE.** *That state is
invisible in `git status`, survives the window's close, and hands the identical trap to the NEXT
seat who audit-arms anything importing this codec.* ⇒ **A REBUILD IS PART OF THE REVERT, NOT A
COURTESY AFTER IT.** *Performed here: `EXIT=0`, `8745` jobs, cache consistent with the source.*

## ✅⭐⭐ 2026-08-25 15:3x — **LAYER-2 REPAIRS: 19 OF 26 CLEARED — AND FIXING ERRORS *REVEALED* TWO MORE**

*Announced window, my lane only. Tree reverted and rebuilt green (`EXIT=0`, `8745` jobs). Repairs
preserved re-appliable at `docs/Q3-SWAP-LAYER2-REPAIRS-0825.diff`.*

```
  decQ_congr             bound-repair   ✓ GREEN   `apply hab` LEADS; `and_true` dropped
  decQ_envWith_eq        strengthen     ✓ GREEN   restated to the EXACT round trip `= s`
  decQ_cycOfBits_stalled cleanliness    ✓ GREEN   now `exact decQ_envWith_eq _ _`
  decQ_envWith_of_clean  SUBSUMED       ✓ GREEN   both hypotheses now UNUSED (`_hm`,`_ht`)

  errors 37 -> 16 · real proof failures 9 -> 5, of which FOUR are the pivot pair
  (retired at the swap BY DESIGN). ONE genuine site remains: c4Spec_iff_fieldwise.
```
⚠️ **`decQ_envWith_of_clean` WAS NOT IN ANY PREDICTED LIST — it broke because MY restatement of
`decQ_envWith_eq` made its proof close early (`No goals to be solved`).** *A truth-preserving
restatement is still a breaking change; `statement-shape-is-an-interface`, arriving from my own
hand. **Kept rather than deleted** — removing it would break every consumer in the swap commit,
and an unmeasured retirement blast radius is what this campaign has spent the day paying for.*

## ⛔⛔⭐⭐ **MASKING VARIANTS 4 AND 5 — AND VARIANT 5 MEANS THE ERROR COUNT DOES NOT MONOTONICALLY FALL**

**④ INLINED-NOT-CITED.** `decQ_cycOfBits_stalled` discharged its two cleanliness goals with
`(by simp [SaltWorks.HDL.decQ]) (by simp [SaltWorks.HDL.decQ])`. ***Those ARE `decQ_mem` and
`decQ_trapped` — inlined rather than cited.*** **A name-grep for the retired pivot cannot see this
site.** *A retirement's blast radius is not bounded by its own identifier.*

**⑤ `#audit_axioms` ABORTS ITS LIST, SO FIXING A NAME EXPOSES THE NAMES BEHIND IT.** Measured:
```
  9660  #audit_axioms not_pcField_coreShaped  coreShaped_isolation  not_C4Spec_coreShaped
  9662  #audit_axioms not_pcField_coreShapedT neither_coreShape_C4Spec
```
Both LEADING names were convicted at layer 2, so both calls aborted at name 1 and everything after
**read as clean — no tick AND no conviction.** Repairing the leaders let the audit walk on and
convict `not_C4Spec_coreShaped` and `neither_coreShape_C4Spec`; `coreShaped_isolation` went
NOT-REACHED → ✓ green. **THE EXPOSURE, COUNTED:**
```
  roll-call lines in Program.lean          251
  multi-name lines                         227
  names NOT FIRST on their line            534   <- every one MASKABLE by an earlier failure
```
🔑 ***SO AN AUDIT-BASED ENUMERATION OF THIS FILE UNDER-REPORTS BY UP TO `534` NAMES, INVISIBLY,
BECAUSE AN ABSENCE READS AS CLEAN.*** ⚠️ **AND THE CONSEQUENCE FOR PROJECT MANAGEMENT: `26 → 9`
is NOT `17` fixed. It is `19` cleared and `2` NEWLY EXPOSED.** *A falling error count is not
progress measured; it is progress NET of revelation, and the two are only equal when nothing was
masked.* ⇒ **Report CLEARED and REVEALED as separate numbers, every pass.**

📌 **THE FAMILY, FIVE DEEP:** ① hub masks dependents · ② masked ≠ must-break · ③ broken-but-present
masks consumers · ④ inlined-not-cited hides a consumer from grep · ⑤ audit-abort masks every later
name on the line. *Five distinct mechanisms, all producing "this looks smaller than it is", all
found in one day on one swap.*

## ⛔⭐⭐ 2026-08-25 15:5x — **EARLY REFUTATION SUSTAINED (math): MY LAYER-2 PATCH WAS A FALSE THEOREM WAITING FOR SOMEONE TO APPLY IT**

*I offered the `decQ_envWith_eq` restatement as a pre-read for early refutation. **It was refuted,
and not on its shape** — the shape was accepted for ⓐ's witness. The defect is LANDING ORDER, and
it was in MY PACKAGING, not in the proof.*

```
  Program.lean:1507   theorem decQ_mem (e) : (decQ e).mem = Vector.replicate 8 0 := rfl
```
**Under TODAY's codec that forces `mem` DEFINITIONALLY.** So the restated
`decQ (envWith s w) = s` demands `Vector.replicate 8 0 = s.mem` and is **REFUTED by this seat's own
dirty witness** — `StateCodecD.sTestD`, eight distinct memory words, trap SET.
⇒ ***THE RESTATEMENT IS TRUE UNDER D AND FALSE UNDER Q. It inherits the SAME forced ordering the
council placed on ⓐ: SWAP FIRST.*** *The reset clause I removed was not clutter — it was the
Q-regime truth.*

### ⛔ THE PACKAGING DEFECT, AND THE TOOL CANNOT CATCH IT
I shipped the repairs as `Q3-SWAP-LAYER2-REPAIRS-0825.diff`, **separate from layer 1**. Measured:
```
  git apply --check Q3-SWAP-LAYER2-REPAIRS-0825.diff   ->  EXIT=0     <- APPLIES CLEANLY
  result if applied without layer 1                    ->  A FALSE THEOREM IN A GREEN TREE
```
🔑 ***THE DANGEROUS PARTIAL IS THE ONE THAT APPLIES. `git apply --check` RETURNS 0 AND CANNOT WARN
ANYONE*** — layer 1 alone fails LOUDLY (red tree, recoverable), layer 2 alone succeeds SILENTLY into
a tree this campaign has twice watched stay green over a defect (`sorryAx` through M2; the
audit-abort). ⇒ **FIXED: `docs/Q3-SWAP-COMPLETE-0825.diff` is the one artifact safe to apply, and
both partials now carry a `DO NOT APPLY ALONE` preamble** (verified `git apply` tolerates a
preamble, driven with a control).

### ⭐⭐ AND THE LAW THAT COMES OUT OF IT — MATH'S, AND IT IS BETTER THAN MY REPORTING
> ***"STATE WHICH REGIME A GREEN WAS MEASURED IN. A bare `EXIT=0` no longer carries it."***

**My "measured GREEN in the window" was a D-GREEN**, taken inside a window I then reverted — it was
never evidence about the pre-swap tree, and I reported it as though `EXIT=0` were regime-free.
*Math's reading is exactly right: their refutation is CONSISTENT with my green, not against it.*
⇒ ***AN UNQUALIFIED GREEN IS TWO GREENS SHARING A WORD*** — the same shape as an undated claim
about a changing artifact, one axis over. **Every `EXIT=0` in this campaign now carries its regime.**
📌 *And math still holds the verification OWED: they have read what I TYPED, not what I BUILT, and
a quoted byte cannot show the range predicate inside the `decQ_congr` hypothesis — which is exactly
where a 1056-vs-1313 mismatch would hide. Correct, and I am not asking them to discharge it.*

## 📐 2026-08-25 16:1x — **`c4Spec_iff_fieldwise` PRICED POSITIVELY, NOT STARTED — AND THE PRICE IS NOT THE PROOF**

*The last genuine layer-2 site. Priced rather than begun, because the dominant cost is not where a
reader would look, and `an-estimate-from-absences` says price the dominant cost POSITIVELY.*
```
  1  THREE new declarations, none of which exist   MemField · TrappedField · stBit_mem
     ⚠️ my first grep said MemField/TrappedField EXISTED. It matched `MemFieldD`/
        `TrappedFieldD` — the D-side twins. Prefix match, wrong object. Exact-name
        re-check: 0 defs each. The proposal was right and my reading was not.
  2  the proof restatement                          ~81 lines, template LANDED and green
                                                    (`c4SpecD_iff_fieldwise`, :2829-2909)
  3  PROSE SAYING "34" / "THIRTY-FOUR"               8 sites across 7 FILES
  4  a POSITIONAL PROJECTION in another glob         C4Refuted.lean:295
```
### ⛔⛔ THE HAZARD THAT IS NOT IN `Program.lean` AT ALL
`C4Refuted.lean:295` reads `(((…c4Spec_iff_fieldwise core).mp h).2.1 r1)` — **it projects
POSITIONALLY into the conjunction.** The `34 → 43` growth changes that conjunction's SHAPE.
Worked through (right-associated `∧`):
```
  current    len ∧ RegFieldAll ∧ PcField                        .2.1 = RegFieldAll
  APPENDED   len ∧ RegFieldAll ∧ PcField ∧ MemFieldAll ∧ Trap   .2.1 = RegFieldAll   SAFE
  INSERTED   len ∧ MemFieldAll ∧ RegFieldAll ∧ PcField ∧ Trap   .2.1 = MemFieldAll   RE-AIMED
```
🔑 ***APPENDING IS SAFE AND INSERTING SILENTLY RE-AIMS A CONSUMER IN A DIFFERENT FILE — and the
re-aimed version may still TYPECHECK, because `.2.1` is well-formed either way.*** **Nothing in the
tree enforces the append-only constraint; it is an accident of ordering that happens to hold.**
⇒ **WHOEVER TAKES THIS: append the memory/trap conjuncts at the END, and say so in the docstring,
because the reason lives in another glob and no build will remind you.**

⭐⭐ **AND THE BETTER FIX, WHICH IS A REPAIR RATHER THAN A WORKAROUND (math, 08-25 17:16).** Append
avoids the hazard; **ARITY-ROBUSTNESS REMOVES IT.** The contrast is inside this one swap:
```
  decQ_congr   (hab : ∀ j, j < stWidth → a j = b j)      SURVIVED the swap untouched
               its bound is a SYMBOL, not a literal — "there is no number to get wrong",
               and its docstring says so on purpose: "ARITY-ROBUST … nothing here counts
               the fields." The width mismatch anyone would fear CANNOT ARISE.
  .2.1 / .1    positional projections                     FRAGILE — count positions, and
               re-aim silently when the arity grows
```
🔑 ***SAME SWAP, SAME DAY: ONE OBJECT HARDENED AGAINST ARITY AND ANOTHER COUNTING POSITIONS — and
only the second needed a rule.*** *`decQ_congr` cost its author nothing extra and paid for itself
five days later against a change they did not know was coming.* ⇒ **When growing this conjunction,
prefer giving consumers a NAMED accessor over asking them to append correctly: an append convention
is willpower at every future call site, and arity-robustness is a property.**

### 📌 AND THE PROSE SURFACE IS SEVEN FILES WIDE
`RegField0.lean` (×2) · `CoreAssembly.lean` · `PcFieldClosed.lean` · `RegFieldSchema.lean` ·
`C4Reduction.lean` · `ScratchC4Reduction.lean` · `ScratchRegField0.lean` — every one asserts the
split is **34**, and every one **builds green forever at 43.** *Surface 5 of the retirement rule
(cross-file prose), now at seven-file scale on a single restatement.*

⚖️ **NOT STARTED, AND THE REASON IS NOT SIZE: the work crosses globs** (`C4Refuted.lean` is mine,
but `RegField0`/`RegFieldSchema`/`PcFieldClosed`/`C4Reduction` prose and a positional projection are
a wider blast radius than a renumbering grant covers) **and five commits cannot currently push, so
nothing landed here could be read by the seat that would need to check it.** *Priced, published,
and left for a window that can actually close.*

---

## ⛔⛔ 2026-08-29 — AMENDMENT: FIVE EXHIBITS ARE DEAD, AND HORN D DID NOT KILL THEM

**Council 08/29, item (f), option ③ — bus offset `28710859`.** Written as an APPENDIX, with every
verdict above left verbatim, because *the value of a pre-registration is that it cannot be edited
to match what happened.*

### What broke, and where the before/after was measured
```
tree 38729e9  (leg (1) stage 2a -- organs PLACED, nothing wired)   ALL FIVE KERNEL-CLEAN, 0 errors
tree 79c6f04  (leg (1) stage 2b -- obSig WIRED through immMuxOut)  FIVE carry sorryAx
```
⚠️ **Both readings are from the BUILD arm** (`lake build`, the arm that writes oleans). The
path-form arm (`lake env lean <file>`) reported the branch GREEN — it elaborated `C4Refuted`
against **`CorePlace`'s stale olean from master**, so it was answering a question about the
previous core. *A verdict on a changed dependency needs the arm that rebuilds it.*

### The five, and the abort that hid two of them
```
sel2_insL                                  the seed -- `selOut 2` flipped `true` -> `false`
regField_core_one_is_false                 reported by the build
no_enable_repairs_the_load                 reported by the build
c4Spec_core_is_false                       ⛔ NEVER CHECKED -- concealed by the audit abort
regDatapathOK_is_false_on_LW_either_way    ⛔ NEVER CHECKED -- concealed by the audit abort
```

⛔ **READER'S NOTE ADDED 2026-09-03 — THIS IS A HISTORICAL BUILD REPORT, AND THREE OF ITS FIVE
NAMES ARE NOT IN THE TRACKED CORPUS TODAY, FOR TWO DIFFERENT REASONS THAT MUST NOT BE CONFUSED.**
`c4Spec_core_is_false` was **DELIBERATELY RETIRED** on 2026-08-29 (council item (f), option ③)
when leg ① repaired the operand-B immediate path and its witness died — **that retirement was
correct, and it is this CITATION that rotted, not the theorem.** `regField_core_one_is_false` and
`regDatapathOK_is_false_on_LW_either_way` were never landed and live only in the gitignored
`ScratchC4AUDITSPLIT.lean`. ⇒ ***"ABSENT FROM THE CORPUS" IS NOT ONE CONDITION: a retired theorem
and an unlanded one look identical to a grep and mean opposite things.***
**`#audit_axioms` aborts at its first failure, so the build named THREE and the truth was FIVE**
— and the two it concealed were the two that mattered. Recovered with the seat's audit-recovery tool (`auditreach.py`),
which also surfaced `held_insL` and `isa_insL` as *never checked* (they are clean; the log simply
could not say so). ⇒ **`C4Refuted.lean`'s audit calls are now ONE NAME PER CALL.** *Read ticks,
not absences.*

### ⛔ THE PRE-REGISTERED BAR FIRED IN ITS WARNING ARM, AND THIS IS THE ENTRY THAT SAYS SO
The row for `c4Spec_core_is_false` reads *MUST BREAK — but ONLY AFTER the load is repaired*, with
the warning *"if it breaks while the load is still wrong, **a refutation was lost without a proof
being gained**."*

**The load is still wrong.** `decQ` still writes `mem := Vector.replicate 8 0`; `decQ_mem` still
proves by `rfl`; Horn D has not run. The break came from the operand-B repair instead. ⇒ *This is
the warned outcome, named by this file before the evidence existed, and it is recorded here as a
DEBIT rather than as a milestone.* The compensation the ruling names is that the C4Spec proof
attempt (Sept 4–5) **is** the search — the council ruled out hunting a replacement witness, so
none was sought and no one should read the silence as evidence that none exists.

### ⚠️ WHAT THIS DOES TO THE REST OF THE FILE — READ BEFORE THE D SWAP
- The **2026-08-25 BASELINE table** below says *"Every declaration below PROVES TODAY."* **That
  sentence is now FALSE for five of its rows** at any tree from `79c6f04` on. It is left standing
  because it was true when stamped and it is the before-state of a DIFFERENT differential. ⛔ **Do
  not lift a verdict out of it without re-running the extraction; the file's own rule says the
  list is an output of the build, not an artifact anyone maintains.**
- The **MUST BREAK** rows for the surviving LW chain (`decQ_mem`, `stepT_lw_writes_zero`,
  `lw_forces_false_whatever_the_enable_does`, `datapath_forces_zero_select_on_LW`) are
  **UNAFFECTED and still live** — those declarations still prove and still must break under D.
- The rows for `no_enable_repairs_the_load`, `regDatapathOK_is_false_on_LW_either_way` and
  `c4Spec_core_is_false` are **VOID AS D DIFFERENTIALS**: their subjects no longer exist. D can no
  longer be measured by them, and *a differential whose subject was retired for an unrelated
  reason reads as a pass.* **The D campaign needs a fresh pre-registration against the post-leg-①
  core before it starts.**
- The `insL` group row (*"MUST BE RE-CHOSEN, NOT RE-PROVED"*) still stands, and its reason is
  unchanged: `sL`'s construction cannot populate memory.

### The sixth declaration — outside this file's reach, and outside the ruling's list of four
`EnableX0.on_target_case_is_false` consumed `regDatapathOK_is_false_on_LW_either_way` and died
with it. It was not on the ruling's list because that list was drawn by reading `C4Refuted.lean`,
and **a same-file count cannot see a consumer in a second module.** Retired in the same commit,
replaced by `counterexample_is_on_target`, which carries the surviving content (the residue is
`regDatapath_off_target` contraposed and never needed a witness).

⇒ **STATUS AFTER THIS AMENDMENT: `C4Spec core` is OPEN. `RegDatapathOK` is OPEN.** Neither is
proved; neither is refuted. **A dead witness is not a proof that the spec is true.**

### ✅ SUPERSEDED 2026-08-31 BY R9a — ANNOTATED 2026-09-04, TEXT ABOVE KEPT VERBATIM

⛔⛔ **THE STATUS LINE DIRECTLY ABOVE WENT FALSE ON 2026-08-31 AND READ "OPEN" FOR FOUR DAYS.**
Both objects are **REFUTED**, proved and landed in the tracked corpus, on `origin/master`:
```
SaltWorks/HDL/LwTrapRefuted.lean:199
  not_c4Spec_core_at_the_landed_witness : ¬ SaltWorks.HDL.C4Spec core
  = not_c4Spec_core_of_not_regDatapathOK regDatapathOK_is_false_at_the_LANDED_witness
axioms (checked 09-04, NOT assumed from the ✓): [propext, Classical.choice, Quot.sound]
  — the classical trio, NO sorryAx, on all three of the above and on sel3_insL.
```
The replacement witness the 08-29 amendment says *"none was sought"* **arrived anyway**, by a
different route: R9a's NON-TRAPPING `insL` at **bit 3** (`sel3_insL`), the cell the 08-29
retirement never read. ⇒ **`RegDatapathOK` is FALSE and `C4Spec core` is FALSE.**

⛔⛔ **AND THIS IS WHY THE ANNOTATION MATTERS MORE THAN THE FACT: THE "C4Spec PROOF ATTEMPT
(Sept 4–5)" NAMED ABOVE IS VOID — ITS TARGET IS PROVABLY FALSE.** That row is the compensation
the council awarded for a refutation lost, it is dated to a window that **is today**, and it was
the last open item at this seat's tier. **A seat booting into that window and obeying this file
would spend two days attempting to prove a theorem whose negation is landed, audited and pushed**
— and would find only failing proofs, which is precisely what a hard theorem also looks like.
⇒ ⭐⭐ **THE SEARCH SUCCEEDED; THE ITEM IS DISCHARGED BY EVENTS, NOT BY BEING PERFORMED.**
*A dated task is a claim about the world on that date. This one was true when written, and the
event that falsified it — a witness landing — is exactly the event nobody re-reads a plan after.*

⚠️ **A FALSE OPEN-ITEM IS WORSE THAN A FALSE FINDING, AND IN BOTH DIRECTIONS.** A stale finding
gets DISPUTED; a stale ASSIGNMENT gets EXECUTED, and the harm lands through the hand of whoever
dutifully performs it. I caught this only because I checked the target's status before starting
the work the file assigned me. **The check cost one grep; the item cost two days.**
