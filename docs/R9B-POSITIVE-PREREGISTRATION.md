# R9b — THE POSITIVE HALF, PRE-REGISTERED BEFORE ANY LEAN

**Seat:** compiler. **Branch:** `compiler/r9b-positive-reduction`, off master `8def1ce`.
**Written:** 2026-09-02 07:29:21 PDT. **Authority:** the Captain's 09/02 07:06 SHIP-EARLY ruling
(*"we don't wait to ship, we should ship as early as possible"*), on the same standing law that
carried R9b's negative half — start under your best reading of the ratified sentence, and state
the assumption in the branch's first commit.

⛔ **THIS FILE IS WRITTEN TO LOSE CHEAPLY.** Every claim names what dies if it is wrong. A
pre-registration that cannot lose is not one. It is committed BEFORE the Lean exists, so the
order is checkable in `git log` and not on my word.

---

## §1 · WHAT I AM ASSUMING ABOUT R10, AND HOW MUCH OF IT I NEED

R10's text is DRAFTED, not ratified: `docs/R10-SITTING-TABLE-0902.md` §B.1 (silicon,
`2710f8b`, amended `4339b02` to cite landed objects). I am building on **R10-3 as drafted**:
the flagship claim is made over the clocks whose presented word cannot touch memory, and the
exclusion is written INTO the predicate, Bool-valued, as `CycleRealisesStepOrStallsOn`.

⭐ **THE ASSUMPTION IS NARROWER THAN IT LOOKS, AND THAT IS DELIBERATE.** Everything in §3 is
quantified over `scope`, `nextW` and `pad`. **If the sitting picks a different scope predicate,
§3's theorems INSTANTIATE at it rather than dying.** What I would lose is only §4's
`memFreeB`-specific instances — three lines — not the reduction.

⛔ **WHAT WOULD ACTUALLY KILL THIS FILE:** the sitting ratifying a scope written at the CONSUMER
rather than in the predicate. That shape was measured this morning and reported not to work
(`ScopeShapeDifferential`, `86f7efd`; the consumer's `h` is universal over `ins` and
`core_refutes_every_stall_arm` instantiates it at the witness upstream of any `hmf`) — but
"measured not to work" is my reading of a draft, and the sitting may still write it. **Then §3
is sound and useless, and I will say so in those words.**

---

## §2 · THE OBJECT, STATED EXACTLY, SO THERE IS NO ROOM TO CLAIM MORE LATER

```
THE POSITIVE HALF :=
  CycleRealisesStepOrStallsOn memFreeScope (cycOfCirc core nextW pad) seenWord (fun _ => false)
      where  memFreeScope ins := memFreeB (seenWord ins)
```
**Why the stall set is empty and not free.** Under R10-2 the stall declaration is `¬ retire`.
`core` is single-cycle: every cycle retires, so `¬ retire` is empty. The empty stall set is the
core's OWN declaration, not a convenience — and `R9IdentityBridge`'s date index says exactly
this (*"today's core32 is single-cycle — no stalled cycle exists in the RTL"*). ⛔ **A LATER CORE
WITH ARBITRATION MAKES THIS INSTANTIATION FALSE AND THE THEOREMS BELOW STILL TRUE**, because
they are quantified over `stalls`; what changes is which instance you may cite.

---

## §3 · THE PRE-REGISTERED CLAIMS — STRUCTURAL, AND SCOPE-GENERIC BY CONSTRUCTION

**PASS BAR for every claim: a kernel-checked theorem, `saltbuild EXIT=0` on the root, clean
`#audit_axioms` (no `sorryAx`), landcheck armed-then-clear, and the module wired into
`SaltWorks.lean`. A green `grep` is not a pass and never has been at this seat.**

### 3.1 — CLAIM P1 · THE SCOPED FORWARD BRIDGE
```
C4SpecOn scope c  →  CycleRealisesStepOrStallsOn scope (cycOfCirc c nextW pad) seenWord (fun _ => false)
    where  C4SpecOn scope c := ∀ ins, scope ins = true → sem c ins = encD (stepT (decQ ins) (seenWord ins))
```
The scoped mirror of the landed `cycleRealisesStep_of_C4Spec` (`Stack/Program.lean:2306`).
**PREDICTION: mechanical — the existing proof carries the extra hypothesis and nothing else.**
*If it is NOT mechanical, that is the interesting outcome and I want it: it would mean the
bridge quietly uses the universality of its antecedent, and R10-3's whole shape would need
re-examination before the sitting rather than after.*

### 3.2 — CLAIM P2 · THE SCOPED FIELDWISE DECOMPOSITION
```
core.outs.length = stWidth   (LANDED, core_outs_length — scope-independent)
∀ r, scoped RegField core r
scoped PcField core
        ⇒  C4SpecOn memFreeScope core
```
The scoped mirror of `c4Spec_of_fieldwise`.

### 3.3 — CLAIM P3 · THE REDUCTION, WHICH IS THE DELIVERABLE
```
scoped RegDatapathOK  →  scoped PcField core  →  THE POSITIVE HALF
```
⭐ **THIS IS THE SENTENCE THE SITTING SHOULD HEAR, AND IT IS A MEASUREMENT OF THE WORK RATHER
THAN THE WORK:** *R9b's positive half is `RegDatapathOK` and `PcField` restricted to memory-free
words, and nothing else stands between them and it.* That is the scoped twin of
`c4Spec_core_of_datapath_and_pc`, whose own docstring already says the honest thing about its
unscoped parent — **"the two are not small; this is a restructuring, not progress on the
datapath"** — and that sentence applies here verbatim.

### 3.4 — CLAIM P4 · NON-VACUITY, WITHOUT WHICH P3 IS DECORATION
`memFreeScope insI = true`, so the scoped obligations quantify over a non-empty set that
contains a REAL landed instruction environment. *Already kernel-checked as
`memFreeB_seenWord_insI_true` (`50cbae2`); restated here as a claim of THIS file because a
control cited but not carried is not a control.*

---

## §4 · MUST-BREAK CONTROLS. A claim with no failing arm is not tested.

```
C1  AT scope := fun _ => true, P1 MUST GIVE BACK the landed unscoped bridge. If it does not,
    my scoped bridge is not a weakening of the tree's and P1 is about an object of my own
    invention.
C2  THE SCOPE MUST BE LOAD-BEARING IN P3: the UNSCOPED RegDatapathOK is REFUTED on master
    (regDatapathOK_is_false_at_the_LANDED_witness), so a P3 that did not use its scope
    hypothesis would prove a false thing. I will state the refutation BESIDE P3 so the two
    are read together.
C3  THE SCOPED OBLIGATIONS MUST NOT BE SILENTLY DISCHARGED. If `scoped RegDatapathOK` turns
    out to follow from something already landed, that is a RESULT and not a bonus — it would
    mean the positive half is nearly closed and I would owe the sitting that sentence
    immediately, not at the end of the file.
```

---

## §5 · WHAT I AM **NOT** CLAIMING, SAID NOW RATHER THAN DISCOVERED AT THE SITTING

⛔ **I am NOT proving `scoped RegDatapathOK` or `scoped PcField`.** Those ARE the datapath and
the pc path — the ALU/decode/select chain and the `pcAdd` organ — and they are the substance of
the rung, not its plumbing. **A reduction is not an inhabitation, and I will not let a green
build read as one.**

⛔ **I am NOT re-dating any rung.** §14's table is the helm's, and R9b dates with R10's close.

⛔ **I am NOT touching `issuance_markers.sh`** (live trial, n<20, to ~09/07).

⛔ **`C4SpecD core` STAYS REFUTED under every scope** — a WIDTH argument with no witness and no
instruction in it. R10-3's scope does nothing for the D form, and nobody may carry "open, not
false" from the non-D flagship to it.

## §6 · DISPOSITION
Green ⇒ land on master and post the reduction as the sitting's input. Red ⇒ abandon and post the
negative, which under the standing law is an equally acceptable outcome — and in this file's case
a MORE useful one, because a bridge that cannot be scoped would be a defect in R10-3's shape
found BEFORE ratification rather than after.
