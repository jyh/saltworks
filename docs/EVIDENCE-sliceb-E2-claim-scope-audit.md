# MIG-11 — SLICE-B E2 CLAIM-SCOPE AUDIT

**Owner:** evidence · **Ordered:** Captain's migration, 08/23 · **Run:** 2026-08-23 21:0x
**Trigger the row names:** *"rises to P1 if any Slice-B text enters the story or a paper."*
That trigger is the whole reason this audit is about TRAVEL, not about wording.

---

## 0 · THE NAMED TARGET DOES NOT EXIST, AND THAT IS THE CHEAP HALF

The row asks for an audit of the post-v1.1 **"OS" wording**. Measured:

```
"OS" in docs/slice-b-design-v1.md : 1 occurrence, line 159
line 159 is:  the debt row itself — "the claim-scope audit on E2 (an "OS" this is not"
"operating system" / "kernel" / "supervisor" as a claim : 0
the doc says throughout : EXECUTIVE (title, ## B-EXEC :75, :79) and, in E2 itself,
                          "the honest cooperative-v1 scope"
```
⇒ **The v1.1 fold (math's E-4..E-7) already did the wording work the debt asked for.**
*Reporting only that would be reporting the absence of a word.* **A claim-scope audit asks
whether the CLAIM outruns its SUPPORT, so that is what follows.**

## 1 · THE PROSE IS UNUSUALLY WELL SCOPED — recorded because a negative must carry its measurement

Both invariants name their own vacuity hazard **and pre-register a control**:

| | hazard named | cure | pre-registered control |
|---|---|---|---|
| FAIRNESS | "selected" read as "steps" makes it near-trivial (E-7) | "steps" = **EXECUTES ≥1 instruction** | E-5: a concrete N-task config whose run **is** infinite |
| | the never-yielding task (E-6) | antecedent stated out loud; *"travels no further"* | — |
| ISOLATION | unconstrained channel set makes it **vacuous** (E-4) | channel set **fixed and syntactic**, declared once | a mutant where two partitions **overlap** must make isolation FALSE |
| | by-construction partitions make it near-tautological | disjointness **a proved row, never a definition** | — |

**And both are BUILT — I expected neither and had to correct myself twice:**
```
ISOLATION  Certs/Executive.lean — cert_task_isolation · cert_step_frame ·
           cert_isolation_needs_disjointness (the vacuity mutant, kernel witness 5→9) ·
           witness_task_isolation_inhabited (the inhabitance control)
FAIRNESS   HDL/ExecutiveX2.lean — exec_forever · halt_mutant_stalls ·
           halt_mutant_not_neverStalls · execStep_cur · cur_runSys
```

## 2 · ⛔ FINDING 1 — THE DESIGN CLAIMS MEMORY; THE CERTIFICATE COVERS REGISTERS

```
DESIGN  slice-b-design-v1.md:98
        "ISOLATION: task i's REGISTERS-AND-MEMORY partition is untouched by task j's
         steps (j ≠ i) except through declared channels"

CERT    Certs/All.lean:112-114 — its own words
        "Its scope limits are the point: REGISTERS ONLY (nothing about memory, the trap
         flag, or pc), ONE STEP, partitions GIVEN NOT DERIVED, and NO LIVENESS. Since M2
         the machine has real load/store, so memory isolation is not merely unproved
         here — IT IS NOT ADDRESSED."
```
⚠️ **NEITHER DOCUMENT IS DISHONEST.** A design states a target; a certificate states what
is proved today, and this one states its limits better than most published work does.
⇒ ***THE GAP IS THAT NOTHING JOINS THEM.*** **"The executive's isolation is certified" is
TRUE of registers and will be READ as covering E2** — and the row's own trigger is the
moment that sentence enters a paper. **This is the finding, and it is about travel.**

## 3 · ⛔⛔ FINDING 2 — THE PROVED FAIRNESS AND THE NEEDED FAIRNESS ARE DIFFERENT CLASSES

```
DESIGN E2   fairness is COOPERATIVE — "every task YIELDS infinitely often";
            "(The preemptive form is v2)"
BUILT X2    ExecutiveX2.lean — "this is the PREEMPTIVE form. It does NOT refine to X4's
            compiled executive, WHICH IS COOPERATIVE and re-acquires the yield antecedent"
```
⇒ ***THE DESIGN DEFERS PREEMPTIVE FAIRNESS TO v2. THE BUILT ARTIFACT IS THE PREEMPTIVE
ONE, AND IT SAYS IT DOES NOT REFINE TO THE COOPERATIVE CASE v1 ACTUALLY NEEDS.***
**Each file states its own class correctly and in its own fence. Read together, E2's v1
fairness invariant is NOT discharged by the fairness that exists.**
*I am not calling this an error — X2's fence says exactly this, unprompted, in its own
header ("restated so it cannot be quoted away"). I am recording that the join is missing.*

## 4 · WHAT I RECOMMEND, AND TO WHOM

**These are compiler's / math's files, not mine. I am reporting, not amending.**
1. **E2 should carry a STATUS column per invariant** — *proved / proved-for-a-narrower-object / stated-only* — because a reader takes "THE TWO INVARIANTS" as a matched pair and they are not matched in evidentiary status.
2. **The isolation row should name its object: REGISTERS, ONE STEP.** The cert already does; the design does not, and the design is what travels.
3. **The fairness row should say which class is built.** X2 (preemptive) exists; E2's v1 (cooperative) does not, and X2 declines to refine to it.

## 5 · SCOPE OF THIS AUDIT — what I did NOT do
- I did not read the Lean proofs; I read their **statements and their own scope notes**.
- I did not audit B1/B2/E1/E3/E4 — the row named **E2(b)**.
- I did not check whether Slice-B text has already entered the story or a paper; **if it has, the row's own rule makes this P1 and finding 1 is the one that bites.**
- **I did not confirm, before publishing, that the files I read were the LIVE ones.**
  I confirmed it *afterwards*, prompted by compiler's own near-miss at 21:20 (its first
  read of `writesInstr` was a `Scratch*` file that stopped at BEQ). Both objects here are
  live by import — `Certs/Executive.lean` ← `Certs/All.lean:8`, `HDL/ExecutiveX2.lean` ←
  `SaltWorks.lean:142` — so the audit stands.
  ⚠️ **But `SaltWorks/HDL/ScratchX2life8.lean` exists, is imported by nothing, and carries
  the SAME fence.** Had I read it instead, Finding 2 would have been identical and *I would
  never have learned I read the wrong file.* ***A scratch twin that AGREES is more dangerous
  than one that disagrees*** — compiler's disagreed, and that is what saved it.
  ⇒ **The discriminator is REACHABILITY FROM THE ROOT, never the filename.** `Scratch*` is a
  convention, and a convention is a promise rather than a check.
