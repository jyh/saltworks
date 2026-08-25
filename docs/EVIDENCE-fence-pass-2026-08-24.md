# 🚦 EVIDENCE FENCE PASS — 2026-08-24 night shift
**Duty:** queue — *"the public README wording takes EVIDENCE'S FENCE PASS BEFORE the Captain's
click (public = T1, the click is HIS)"* and *"The v1.1 demo sentence remains FENCE-PENDING at
evidence until its pass posts."*

**Every fact below verified AT THE OBJECT, not inherited from a ledger.**

---

## ✅ VERDICT 1 — THE PUBLIC TT README: **CLEARED. The Captain's click is not blocked by me.**
`SaltWorks/Silicon/TT/README.md` — the surface that ships with the TTSKY26c submission.

**It passes because it answers the F5 test in its own text, unprompted:**
```
F5 — UNREACHABLE HYPOTHESIS: "for each hypothesis of a composed theorem, ask WHICH PORT
     OF THE COMPOSED ARTIFACT SUPPLIES IT. If no port can, the theorem is true and
     inapplicable."
README:22-24 — "The Batcher sorter that would guarantee sortedness is on neither this chip
     nor in Lean. So this is a correct router *given a correct input order*, and the
     ordering must come from off-chip — as it did in 1988."
```
⭐ **That is the F5 question ASKED AND ANSWERED BY THE CLAIMANT.** *The hypothesis is named, the
absence of an on-chip supplier is stated, and the off-chip origin is disclosed — in the public
text, not in a footnote.*
✅ **And it quantifies rather than gestures:** *"Of all 40,320 full-load permutations, exactly
4,096 (10.16 %) route without internal collision."* **A reader can falsify that.**
✅ **Section heading is literally "What is actually proved, and what is not."** *Plus the trust
base stated: "No SAT solver is trusted and no `native_decide` is used."*
📌 **NOTHING IS OWED HERE. I am not asking for a single word to change.**

## ⛔ VERDICT 2 — THE v1.1 DEMO SENTENCE: **STILL NOT CLEARED.** Same defect as 2026-08-09.
`docs/ndf-top-module-design-v1.md:258-264` — quoted verbatim:
> *"a processor whose every organ and wire is kernel-certified — its end-to-end refinement one
> named theorem away, its fabbed twin scheduled for replacement — beside a dataflow fabric whose
> netlist is kernel-checked against its Lean model **on the schedule class we run**, on one die,
> driven by a compiler-emitted schedule."*

### THE DECISIVE FACT, CHECKED AT THE KERNEL
```
the certificate    SaltWorks/Silicon/Equiv/FabricRoutes.lean:231  theorem fabric_routes
what it quantifies allScenarios — and its own docstring says what that is:
                   "All non-empty sorted, concentrated destination sets: every subset of
                    {0,…,7} in increasing order. 255 of them"
the demo's rounds  V10 · "PER-ROUND schedule fixtures (one-hot payloads) for every demo
                   round" · STATUS: **NEW**   (ndf-top-module-design-v1.md:384)
```
⇒ ***THE CERTIFIED CLASS IS SORTED/CONCENTRATED DESTINATION SUBSETS. "THE SCHEDULE CLASS WE RUN"
IS THE DEMO'S OWN ROUNDS, WHICH ARE V10, WHICH IS `NEW`.*** **The sentence claims certification
over precisely the class that is not certified — a future claim written in the present tense.**
⚠️ **I did not take this from the 08-09 ledger. I read the theorem and its docstring.** *The
ledger said the same thing; agreement between a doc and the object is only worth something when
someone checked the object.*

### ✅ THE CHEAPEST TRUE FORM — unchanged from 08-09, still costs nothing
> *"…kernel-checked against its Lean model **on prefix-concentrated destination-monotone
> traffic**."*
**No gate, no future work, no permission needed. It is true today.**

### ⚠️ AND ONE SECONDARY DEFECT SURVIVES UNREPAIRED
*"its end-to-end refinement **one named theorem** away"* — **names no theorem.** *An unnamed
named theorem cannot be checked, so the clause asserts proximity to a result the reader cannot
locate.* ⇒ **Name it or drop "named".**
📌 *The third 08-09 repair — the "ON ONE DIE" twin-disclosure adjacency — I am NOT re-raising:
the twin disclosure now sits inside the same sentence.*

## 📌 SCOPE OF THIS PASS — stated so it cannot be over-read
```
COVERS   SaltWorks/Silicon/TT/README.md (the public submission surface)
         docs/ndf-top-module-design-v1.md §D5 (the v1.1 demo sentence)
DOES NOT the repo-root README.md · docs/ · any paper draft · info.yaml's description field
⇒ A PASS ON ONE SURFACE IS NOT A PASS ON THE REPO. If the Captain's click publishes any text
  beyond the TT README, that text has NOT been fence-passed and I should be asked.
```
⛔ **AND THE PASS IS ON WORDING, NOT ON SILICON.** *I am certifying that the public sentences do
not overstate the artifact. I am not certifying the artifact.*

---

## ⛔⛔ AMENDMENT 1 — 2026-08-24 20:5x. **MY OWN VERDICT 1 OVERCLAIMED ITS SCOPE. READ THIS BEFORE ACTING ON IT.**

**Verdict 1 said "CLEARED" of the public TT README. I checked it against F5 ONLY.**
***F1, F2, F3 AND F4 ALL BIND AND I APPLIED NONE OF THEM.***
⇒ **A PASS AGAINST ONE FENCE REPORTED AS A PASS IS THE EXACT ERROR THIS SEAT SPENT THE DAY
NAMING — [[a-count-is-not-a-scope]], committed in a verdict on PUBLIC wording.** *The verdict's
own §3 states its FILE scope carefully and says nothing about its FENCE scope.*

### WHAT THE FULLER PASS FINDS — reported, not adjudicated
```
F3 SCOPE RULE  "A CLEARED F3 CARRIES ITS SUBJECT IN THE SENTENCE"  (fence:139)
TITLE          "Verified 8×8 bit-serial banyan switch"        subject = THE 8×8 FABRIC
BODY  :36      "the 2×2 element — the thing the Lean proof is about"
BODY  :14      "The synthesized gate netlist of the switch ELEMENT"
⇒ THE TITLE'S SUBJECT IS WIDER THAN THE PROOF'S SUBJECT.
```
⚖️ **I am NOT calling this a breach, and the reason matters:** *the body corrects the title
within fifteen lines, under a heading that reads "What is actually proved, and what is not",
and the fabric-level result `fabric_routes` is real (routing over 255 sorted/concentrated
destination sets).* **But a title is the most-read string in a public submission and it is the
one line that travels alone — into a shuttle listing, a link preview, a citation.**
⇒ 📌 **RAISED FOR THE CAPTAIN, NOT RULED BY ME. Public is T1.**

### ⚠️ AND TWO DEFECTS IN THE FENCE DOCUMENT ITSELF, FOUND BY USING IT
```
1  F3's EXCLUSION LIST (fence:125) names "the fabric ⇒ HAND RTL. EXCLUDED BY NAME".
   THAT IS STALE: README:39 — banyan_fabric.v is "generated into this repo, not authored
   here... the same bytes are what the equivalence proof and the synthesis script read."
   A generated artifact is not hand RTL. The exclusion would fence a TRUE sentence.
2  F4's STATUS IS SELF-CONTRADICTORY AT THE BYTES: fence:204 "F4 IS CLEARED" and
   fence:247 "F4 STILL BINDS" — and :247 sits LOWER, so a top-to-bottom reader takes the
   STALE one. The file's own :180 tries to route past it to "the final re-anchor below",
   and the final re-anchor is NOT below :247.
```
🔑 ***A FENCE DOCUMENT THAT CONTRADICTS ITSELF DOES NOT FAIL LOUDLY — IT HANDS EACH READER
WHICHEVER ANSWER THEIR READING ORDER REACHES LAST.*** **Both defects are in MY seat's own
document. Repairing them is owed and is not this pass.**

### ⇒ THE CORRECTED VERDICT
```
TT README, against F5                CLEARED — the F5 answer is in its own public text
TT README, against F1/F2/F3/F4       NOT ASSESSED. Verdict 1 should have said so.
TITLE vs BODY subject width          RAISED to the Captain. Not ruled by me.
v1.1 demo sentence                   STILL NOT CLEARED (unchanged, kernel-verified)
```
⛔ **NOTHING ABOVE THE AMENDMENT LINE HAS BEEN EDITED — the overclaiming verdict stands
visible, because a corrected record must show what it corrected.**
