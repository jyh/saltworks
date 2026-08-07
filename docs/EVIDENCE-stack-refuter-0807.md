# REFUTING `stack-campaign-v0.md` — the evidence seat's pass

Draft-until-refuted, 8/7 09:07. Four findings, **each measured rather than
argued**, ordered by what they cost if the draft freezes unchanged.

---

## ⛔ 1. R2 IS NOT A "SUSPECTED GATE" — IT IS ANSWERED, AND THE ANSWER KILLS S2 AS WRITTEN

R2 asks *"does `St` support load/store today, or is that C1 completion work
that gates S2? (Suspected gate — census first.)"*

**No census is needed. The answer is in the type**, `SaltWorks/HDL/ISA.lean:72`:

```lean
structure St where
  regs : Vector (BitVec 32) 32
  pc   : BitVec 32
```

**There is no memory field.** And the file's own docstring, twelve lines
down, states the exclusions in terms: *"no loads, no stores, … **no memory
model at all**."*

⇒ **R2 resolves to: CONFIRMED HARD GATE, not suspected.** But the sharper
consequence is not the gate:

⛔⛔ **A SORTING PROGRAM WITH NO MEMORY HAS NOTHING TO SORT.** S2 is *"Batcher
(bitonic) sort in RV32I, assembled via `encode` … → memory image."* With 32
registers, no loads and no stores, **the largest array the machine can hold
is ~30 words, and there is no memory image to assemble INTO.** S2 is not
merely blocked behind C1 — **as written it is unimplementable at any
interesting N**, and the deliverable's own phrase "memory image" names a
thing the state has no representation for.

**Constructive form:** S2's honest v0 is a **register-resident sort of ≤8
words** — which is a real artifact, matches the 8×8 banyan's width, and can
ship while the memory model is built. *That is a smaller claim and a true
one.*

---

## ⛔ 2. THE 13-DAY CLOCK IS WRONG BY 18 DAYS, AND HERE IT DRIVES SEQUENCING

The Sequencing section is headed *"against the 13-day clock."* Computed
against `date` at 09:10 on 8/7: the hard deadline **2026-09-07 13:00 PDT is
31 days 3 h away.**

**This is the third document to carry the number.** It originated in
silicon's 19:12 post last night (a transposition of 31), propagated into the
maestro's 19:16 standing charge, was corrected on the bus at 19:17 and again
at 20:0x — **and has now reappeared in a planning document written this
morning.**

⚠️ **And this instance is worse than the first two, because there it was a
statistic and here it is a CONSTRAINT.** A 13-day plan against a 31-day
runway compresses every sequence in §Sequencing and manufactures precisely
the urgency that argues for skipping checks — on a campaign whose entire
value is that nothing was skipped. **A wrong number in a status line
misinforms; a wrong number in a schedule changes what gets built.**

---

## ⛔ 3. S1's MATHLIB SPEC COLLIDES WITH A MEASURED PROPERTY OF LEG 2

S1 is *"sortedness + permutation … (mathlib's `List.Sorted`/`List.Perm` —
small, standard)."* Small and standard it is. **Free it is not.**

**Measured and recorded:** leg 2 is **MATHLIB-FREE** — a full
`SaltWorks.HDL.*` build is **6 jobs, ~1.5 s**, against **8,581 jobs** for a
Mathlib-importing module. Verified again just now: **zero `import Mathlib`
anywhere under `SaltWorks/HDL/`.** That property was earned *after three OOM
kills* and the campaign record calls it "a resource property, not a nicety:
this seat's iteration no longer competes for the fleet lock."

⇒ **S3(b) proves the PROGRAM — which lives in the HDL leg — against S1's
spec.** If that spec is mathlib's, the import crosses the seam and **leg 2's
6-job iteration dies fleet-wide.**

**Constructive form:** state explicitly which side of the seam the spec
lives on. A `List.Sorted`-flavoured predicate **defined locally over
`BitVec 32`** costs a few lines and keeps the property; mathlib's costs
8,581 jobs per iteration. *The choice is cheap now and expensive after S3
is written against the wrong one.*

---

## ⛔⛔ 4. THE HEADLINE NOUN DEPENDS ON THE ONE CAPABILITY THIS FLEET PROVED IT LACKS

This is this seat's lane and it is the objection I would defend hardest.

The claim is **"(unverified) agent → verified code → …"**, and S2 makes the
provenance load-bearing in terms:

> *"THE AGENT'S AUTHORSHIP IS LOGGED as part of the artifact — 'unverified
> agent' is a claim about provenance, so the provenance is part of the
> deliverable."*

**Correct, and that is the problem.** Yesterday this fleet established, at
the escape codes and at the transcript bytes, that **it cannot reliably
establish the provenance of its own inputs**:

* **ghost text** — client autocomplete, dim SGR-2, delivered as keystrokes,
  **no author at all** (07:43, Captain-witnessed);
* **`tmux send-keys`** — machine transport arriving with
  `origin.kind: human`, `promptSource: typed`, **indistinguishable from a
  hand at the terminal** by any provenance field (ADDENDUM 3 §J);
* **measured:** 82 injections, **26 into one pane in one evening, 22 of them
  bare** — and this seat re-tagged its own ledger yesterday because of it.

⇒ **"An agent wrote this program" is exactly the class of claim that failed.**
And note the asymmetry that makes it dangerous rather than merely awkward:
**the ghost-text incident produced text nobody authored, which a naive
provenance log would have recorded as agent-authored.** *An artifact whose
headline is "an agent wrote it, unverified" cannot rest its provenance on
absence of evidence of a human.*

**Constructive form, and it is buildable today:** agent authorship must be
established **positively** — the authoring agent's own transcript, with its
tool calls and the emitted `List Instr`, **committed as part of the
artifact** and hash-linked to the program it produced. *Provenance by
positive record, never by absence.* This seat's `nudge_detect` can then check
the negative direction as a **floor, never a ceiling**, which is all a
correlation detector can ever be.

---

## ⛔ 5. AND R1 DOES **NOT** SURVIVE — the compiler seat refuted the one line I blessed, within five minutes

This section first read *"S1, S3(a) and **R1** survive unchanged, and R1's
own parenthesis is the best line in the draft."* **R1 does not survive, and
the correction is the compiler seat's.**

R1 says the network is oblivious and its length data-independent — *use
that*. ⇒ ***True of the NETWORK. False of the CODE.*** Verified
independently against `ISA.lean:80-92`, Slice A complete:

```
  ADD · ADDI · XOR · SLT · BEQ
```

A compare-exchange needs a **conditional swap**. Branch-free, that is a
select, and a select needs a mask-AND:

```
  c    = SLT  a b        ->  0 or 1                     available
  mask = ADDI c, -1      ->  0 or all-ones              available
  sel  = mask AND (a^b)  ->  ⛔ NO `AND` IN SLICE A
  AND via ((a+b)-(a^b))/2 ->  ⛔ NO SHIFTS IN SLICE A
```

⇒ **There is no branch-free select in Slice A, so every compare-exchange
must `BEQ`, so the executed instruction count is DATA-DEPENDENT** — even
though the network's *comparator schedule* is not. **R1's fixed-bound
termination argument is therefore unavailable at the code level**, which is
the level S3(b) proves.

**Constructive, and the price is now MEASURED rather than guessed —
the compiler seat corrected it DOWNWARD and my own chain was one step too
long.** I stopped at `mask = ADDI c, -1` and inferred that a *selecting
instruction* was needed. The mask was never the obstacle: it is
constructible two ways from what Slice A already has, verified here —

```
  c    = SLT  a b            0 or 1                       HAVE
  neg1 = ADDI x0, -1         0xFFFFFFFF                   HAVE
  mask = (c XOR neg1) + 1  = −c   → c=1: 0xFFFFFFFF ; c=0: 0x00000000   HAVE
```

⇒ **The missing primitive is exactly ONE: `AND`.** Not six constructors, not
"an ISA change" in the vague sense I implied. So the two options are:

1. state the bound over **comparator stages** with a per-stage worst case —
   **costs a sentence**, changes no code;
2. add **`AND`** to Slice A — **one constructor, one `sem` case, one
   `encode`/`decode` case, one round-trip case** — and the code becomes
   genuinely branch-free, which *restores R1's obliviousness at the code
   level* rather than working around its loss.

**Option 2 is now the interesting one**, and it was not while the price was
unmeasured. *A cost quoted as "an ISA change and a re-proof" reads as
prohibitive; the same cost quoted as "one constructor" reads as an
afternoon.*

📌 **And the process point: I wrote "R1 survives" as the closing line of a
refutation whose whole subject is claims that outrun their evidence.** I
checked `St` in the type, the clock against `date`, and the mathlib property
with `grep` — **and then blessed R1 from the shape of the argument rather
than from the instruction list two files away.** *Four findings measured, one
opinion, and the opinion is the one that was wrong.*

---

## What survives

**S1 and S3(a) survive unchanged.**

**R3's honesty survives too** — *"S5 waits for the ground floor. No
overclaiming mid-campaign."* That sentence is the draft doing the thing this
campaign is for.

⇒ **Not a kill. Three corrections and one re-scoping**, all cheap now and
none cheap after the freeze.
