# THE RISC-V CORE — THE ACCOUNT

### Commissioned by the Captain 2026-08-09 13:2x ("let's do it!") in the
### `bb-switch-account.md` pattern: compiler's kernel half beside
### silicon's priced half, one joint reading, one citation target.
### STATUS: SKELETON (maestro) — seats fill their halves at their seams.
### THE DISCIPLINE (the BB account's, inherited): every count is
### MEASURED from the artifact (#eval, synthesis report, signoff log) —
### never transcribed from a plan or a memory; every number NAMES ITS
### INSTRUMENT and its window; a one-witness column is struck, not
### defended. The [[the-order-invariant]] and the r/k/K letter
### convention (QUEUE 13:0x) bind all prose.
### GATE: the §1 row table's FINAL numbers await assembly rows 15–16
### (instance work, in flight) — the account states a COMPLETE
### assembly or marks itself interim.

**What this document is for:** (1) the deferred TT submission's fact
sheet — ruling #7's "complete, verified, ready for tapeout" made
checkable; (2) the NDF's control-plane reference (design package §3
cites HERE); (3) the writeup's hardware chapter seed.

---

## 1. THE KERNEL HALF — compiler's slot

<!-- COMPILER FILLS. Sources: CoreOffsets.lean (measured dimensions),
     CorePlace.lean (placements, port maps, instOK), the organ modules
     (sem_* certificates), the mutation-control runs. -->

### 1.1 The organ inventory (sixteen rows)

| row | organ | gates | state bits | offset | port map | sem_* certificate | instOK | controls run |
|---|---|---|---|---|---|---|---|---|
| 0 | tie cells | | | | | | | |
| … | | | | | | | | |

### 1.2 Totals and state

<!-- total gates · total flops (regfile 480 + PC 31 + …) · nets -->

### 1.3 The theorem inventory

<!-- which certificate covers which organ; the composition machinery
     (instOK / inst_compose); what remains for the single-cycle
     refinement; axioms audit summary -->

## 2. THE PRICED HALF — silicon's slot

<!-- SILICON FILLS. Sources: the 3×2 real-die signoff artifacts, the
     synthesis reports, the DRV/slew history (state what was refuted
     and struck, per your own ledger). -->

### 2.1 The 3×2 signoff facts

<!-- DRC · LVS · timing at 9 corners w/ margins · utilization ·
     wirelength/slew posture -->

### 2.2 Area by organ

<!-- the independent axis; measured, with the flow named -->

### 2.3 The pin protocol

<!-- the 18-pin multiplexed bus (8a+8d+2phase), fabricated-grade;
     CLOCK_PERIOD=40 rule; RP2040 counterpart (harness, outside the
     verified surface) -->

## 3. THE JOINT READING — maestro, after both halves land

<!-- the kernel-object ↔ silicon-object correspondence, stated once:
     what the RTL twin is, what emitS changes, what the refinement
     theorem will add when W5-asm closes -->

## 4. THE FENCES — evidence's pass

> ### ⏳ STATUS: **CRITERIA PRE-REGISTERED, PASS NOT YET RUN** (evidence, 2026-08-09 13:2x)
>
> **The pass runs LAST, by commission — it needs §1 and §2 filled. But the BAR
> is published NOW, before either half is written, for one reason: a criterion
> published after the work is a rationalisation, and a criterion published
> before it is a standard the filler can simply MEET.** *If this section does its
> job, its own verdict is boring.*

### 4.1 What each number must carry — the four-part test

A figure passes if it answers all four. Any figure missing one is **struck, not
defended** (the skeleton's own discipline, inherited from the BB account).

```
INSTRUMENT   which tool produced it?  (#eval · synthesis report · signoff log ·
             build tick count · shasum).  "I counted" is not an instrument.
WINDOW       over WHAT, at WHAT MOMENT?  A commit sha, a run, a date. A number
             whose scope a reader must guess is unciteable.
DENOMINATOR  what was EXCLUDED?  A miss is visible; an exclusion is not. State
             what the count refused to count.
WITNESSES    how many independent readings, BY WHOM?  A one-witness column is
             struck. Two readings by the same author are ONE claim.
```

### 4.2 The three failure modes this pass exists to catch

*Named in advance so nobody has to be surprised by the verdict:*

1. **A TOKEN COUNT WHERE A COMMAND COUNT IS MEANT.** *Live example from this
   fleet today: `grep -c '#audit_axioms'` = 38, `grep -c '^#audit_axioms'` = 36,
   build ticks = 36. The two extras were prose ABOUT the instrument.* **In a
   document that describes its own instruments, grepping the instrument's name
   hits the description. Anchor positionally.**
2. **A STATUS WORD USED AS A MEASUREMENT.** *`landed`, `covered`, `green`,
   `done`. These assert facts about our own work — the class no outside reader
   can check and every inside reader assumes someone else verified.* **A status
   word is a CITATION: it carries a sha or an owed-marker, or it is struck.**
3. **A GREEN OVER THE WRONG SCOPE.** *`EXIT=0` never asked the question
   `#audit_axioms` asks; a module absent from the build graph builds green by
   not being built.* **State what the green covered, not that it was green.**

### 4.3 What this pass will NOT do

- **It will not re-derive the numbers.** *That is compiler's and silicon's work
  and re-doing it would produce a second author's agreement, which is worth
  less than one measured claim with its instrument named.*
- **It will not widen a regex to hunt claim-words.** *Measured last night: that
  hunt returns the documentation of the hazard, 399 hits, overwhelmingly prose.*
- **It will not strike a number for being UNSOURCED-PENDING.** *"I cannot find
  the source" and "there is no source" are different findings, and only the
  second justifies a strike. A correct record was deleted on that confusion this
  morning; the prescription is marking, never deletion.*

### 4.4 The gate on citation

**Until this section carries a dated PASS verdict, `core-account.md` is not a
citation target.** *The skeleton says the account "states a COMPLETE assembly or
marks itself interim" — so does this fence: an interim account may be cited
WITH its interim marker, and never without it.*
