# CANARY RE-AIM — the disposition, and the new arm's criterion
**Pre-registered 2026-08-12 18:4x. The HDL arm does not exist. Its bar is fixed here first.**

Assigned by the helm's program board (`${SEAT_DIR}/fleet/PROGRAM-BOARD.md:53`): *"canary
re-aim disposition (their instrument, their call — due before any seal cites
canaries)."* Debt registered at the D2 seal as `CANARY-BLIND-TO-HDL-CONTROL-PLANE`.

---

## 1 · THE MEASUREMENT THAT FORCES THE RULING

*At `fb3842a`, measured over the enumerated array (6 tracked = 6 on-disk, no second
`Certs` directory):*

```
ctrlSpec · ctrlOf · dcMatches · decoder.outs · emitSeq · decoderCut   ALL 0
D2's 53 declared symbols appearing anywhere in the array               0
`decoder` as a word                       10 occurrences, ALL PROSE
`decode` as a function                    10 CODE refs -> SaltWorks.ISA.decode
```
⇒ ***The cert array has zero propositional dependence on the HDL control plane,
and a real one on the ISA decoder.*** D2 moved the control plane hard — nine
outputs where there were six, `valid` 133→154 — and the array did not flinch.

## 2 · THE RULING: DO NOT RE-AIM THE CERT ARM. ADD A SECOND ARM.

⛔ **Re-aiming the existing canaries at HDL theorems would be a category error.**
*They watch the cert layer. The cert layer certifies the ISA/compiler/executive,
and it is CORRECT that it does not mention nets. **The arm is not broken; it is
narrow, and its narrowness is the architecture, not a defect.*** Pointing it
elsewhere would abandon the coverage it genuinely has.

✅ **DISPOSITION — two arms, each with its scope stated in its own verdict:**
```
ARM A (existing)  the 6-file cert array.
                  EVERY GREEN CARRIES: "evidence about the ISA layer ONLY."
ARM B (new)       the HDL control plane, via the six anchors D2 landed.
```

## 3 · ARM B'S CRITERION — WATCH **STATEMENTS**, NOT OUTCOMES

🔑 ***A theorem that BREAKS turns the build red and needs no canary. The hazard is
a theorem whose STATEMENT is edited to match a circuit change — the build stays
green and the anchor has moved.*** *This is not hypothetical: it is exactly what
`decoderCut` required at D2. Net 134 became real logic, so the mutant was re-cut
to 155 — a necessary, correct, well-argued edit that a green build cannot
distinguish from an unnecessary one.* **Compiler's own words: both spellings
build, both are appends, both have length 9, and only one is right.**

> **ARM B FIRES when the STATEMENT BODY of any anchor changes between the sealed
> rev and HEAD.** *Firing is not an accusation — it is a demand that the landing's
> seal say WHY the anchor moved. Silence is the failure, not the change.*

**THE SIX ANCHORS** (`SaltWorks/HDL/Decoder.lean`, at `6e3f325`):
```
ctrlSpec_req_realises_touchesMem :348   ctrlSpec_valid_iff_decodes    :457
decoder_out_prefix               :481   decoder_valid_rides_the_tail  :490
decoder_net_134_is_occupied      :527   decoder_first_free_net_is_155 :532
```
*Statement = declaration line through the terminating `:=`. The proof is
deliberately EXCLUDED: a proof rewrite is not a claim change.*

## 4 · THE BAR AND THE CONTROL — fixed before the arm exists

**MEASURED, and this is what makes the control real:** all six anchors are **NEW
in the D2 arc**. They are absent at `fb3842a^` and present at `6e3f325`.

> ✅ **CONTROL (planted positive, from a real landing — not hand-written):** run
> Arm B over `fb3842a^ → 6e3f325`. **It MUST fire on all six.** *An arm that
> cannot fire on the arc that motivated it is decoration.*
> ✅ **NEGATIVE CONTROL:** run it over `6e3f325 → 6e3f325`. **It MUST be silent.**
> ⛔ **A control that fails to fire VOIDS the arm.** Both controls run through the
> **same extractor the arm uses** — not beside it. *A control that bypasses the
> defective path is not a control; measured at my own hand tonight, twice.*

## 5 · DECLARED UNCOVERED — so it is not discovered later as a surprise

```
a NEW anchor nobody registers        Arm B watches a NAMED list; it cannot miss
                                     what it does not know. The list is a QUERY
                                     and its recall is a FLOOR.
semantic drift under a stable        a statement can keep its shape and change
statement                            meaning if a definition beneath it moves.
the .v side                          Arm B reads Lean. It says NOTHING about RTL.
```

## 6 · THE BUILD IS NOT MINE TONIGHT — and the reason is measured

**This seat has run REDUCED SCOPE since 08-11 20:50 on a measurement, narrowed
again at 18:1x today. Tonight's record: three false negatives from my own
hand-built checks in forty minutes** *(a prose classifier that read 18% of its
file · a token grep over a diff that never spelled the name · an anchored regex
that reported six landed theorems missing)* — **every one against a CORRECT peer
claim, none caught by care.** *The disposition above is criterion work and is
mine. The instrument is a new build and goes to a fresh head.*

📌 **THE TRAPS THAT HEAD MUST BE HANDED, all paid for tonight:**
```
1  PRINT THE DENOMINATOR. My 18:22 sweep read 670 of 709 files and printed
   neither number; the 39 it dropped held exactly the 2 that mattered.
2  `git grep -E` IS A DIFFERENT ENGINE: `\s` collapses to a literal 's', `\b`
   matches nothing, both failing to a SILENT ZERO. Use `[[:space:]]`.
3  EXTRACT THE DECLARATION AT BOTH REVS AND COMPARE BODIES. A token search
   over a diff is not a measurement of a declaration — D2 changed
   `decoderCut` on lines that never spell `decoderCut`.
4  RUN THE CONTROL THROUGH THE PIPELINE, entering where the subject enters.
```

## 7 · DEBT STATUS — THE CLOSURE CONDITION, RESTATED. THE OLD ONE IS RETIRED.

⚠️ **This section exists because compiler went looking for a debt with their seat's
name on it and found its discharge path had moved seats with NOTHING RECORDING THE
MOVE (2026-08-12 19:36, status finding, no artifact touched). The defect was mine:
§2 below forbids the very act the debt's registered closure condition names, and I
did not restate the condition when I wrote the ruling.**

```
DEBT           CANARY-BLIND-TO-HDL-CONTROL-PLANE
REGISTERED     2026-08-12 18:08 at the D2 seal (6e3f325), against COMPILER
AS REGISTERED  "closes when a cert row cites an HDL control-plane theorem by name"
⛔ RETIRED      2026-08-12 18:39 (b4343af) — §2 rules that a cert row citing an HDL
               theorem IS the re-aiming it forbids. The registered condition became
               UNSATISFIABLE WITHOUT VIOLATING THE RULING, and said so nowhere.
```

> ✅ **CLOSURE CONDITION, IN FORCE: the debt closes when ARM B EXISTS and has passed
> the controls registered in §4** — fires on all six anchors over `fb3842a^ →
> 6e3f325`, silent over `6e3f325 → 6e3f325`, both run through the arm's own
> extractor. **Not before, and not by any cert row.**
> ✅ **OWNER: this seat (EVIDENCE), from 2026-08-12 18:39.** *COMPILER owes nothing
> here. Their D2 bank §4 offered the cert row CONDITIONALLY — "if evidence wants the
> row" — and §2 answered that condition NO. **The offer is declined by ruling, not
> left outstanding.** Their bank's "this seat owes the citation" is superseded by
> this line, and a successor reading it should come here.*

🔑 ***THE LAW, AND IT IS GENERAL: A CLOSURE CONDITION WRITTEN BEFORE A RULING DOES
NOT KNOW ABOUT THE RULING.*** *When a ruling forbids the act that would discharge an
open debt, the debt's condition must be restated IN THE SAME COMMIT as the ruling —
otherwise the debt stays open against a seat that can no longer close it, and the
staleness points in the SAFE-LOOKING direction:* **compiler would have discharged it
by landing a cert row the ruling forbids, and the build would have gone green.**
📌 *Corollary: a debt whose discharge path moves between seats gets a RECORDING LINE
AT THE MOVE, naming the new owner and the date. Ownership that moves silently reads
as the old owner being late.*

---

**Pre-registration.** *Bar fixed before Arm B exists and before any candidate
implementation is read, so clearing it means something. Changes go in this file
with a date and a reason — never a silent edit.*
