# E1 — I WAS WRONG ABOUT `#audit_axioms`, AND THE README CARRIES MY ERROR

### 2026-08-06, SILICON seat, Mac Mini. Run: `../saltbuild.sh ScratchSILICON.lean`
### (queued 70 min on the fleet lock; `saltbuild EXIT=1`, which is the expected
### result for a file of deliberately-broken theorems — read the TEXT).

## The claim under test — mine

At 14:04 I reported, and the EVIDENCE seat landed in the campaign README's
axiom-posture section at 14:30 (e3ea8f1), that:

> `#audit_axioms` printed a cheerful `✓ [0 axioms]` for two theorems that had
> **NOT ELABORATED** (heartbeat timeout). The audit is blind to elaboration
> failure — only `saltbuild EXIT=1` caught it. **A green tick from
> `#audit_axioms` is not evidence the theorem exists.**

Evidence called it *"a simpler and more total failure than wrong-file,
mis-parsed-port or mis-modelled-cell"* and put it **first** in that section,
upgrading the campaign's headline caveat from *"this claim is narrower than it
sounds"* to *"this claim can be printed about nothing at all."*

**What made me re-test it:** `AuditAxioms.lean` resolves every name with
`realizeGlobalConstWithInfos`, which **throws on an unknown name**, and it carries
a `#guard_msgs` self-test pinning exactly that behaviour. So the mechanism I had
asserted — the audit ticking a name that is not in the environment — cannot
happen. A claim whose stated mechanism is impossible is a claim that has not been
established, however plausible its conclusion.

## The experiment

Six theorems, each broken a different way, each followed by its own audit line;
one control that must tick.

| # | how it is broken | what `#audit_axioms` did |
|---|---|---|
| e1 | heartbeat timeout inside a **tactic** block | `error: Unknown constant \`e1_heartbeat\`` |
| e2 | explicit `sorry` | `error: … depends on non-whitelisted axiom(s): sorryAx` |
| e3 | `maxRecDepth` exceeded under `decide +kernel` | `error: Unknown constant \`e3_recdepth\`` |
| e4 | tactic type mismatch (wrong term) | `error: … depends on non-whitelisted axiom(s): sorryAx` |
| e5 | heartbeat timeout in **term** elaboration | `error: Unknown constant \`e5_term\`` |
| **e6** | **nothing — a real `decide +kernel`** | **`✓ e6_ok [0 axioms]`** |

## The verdict: THE INSTRUMENT IS SOUND, AND MY CLAIM IS REFUTED

**`#audit_axioms` did not print a tick for a single broken theorem.** There are
exactly two ways a failed proof leaves the environment, and the audit catches
both:

- **elaboration aborts** → the declaration is never added → the audit's name
  resolution throws `Unknown constant`. A hard error, not a tick.
- **elaboration recovers** → the declaration is added with a `sorryAx` proof →
  `collectAxioms` reports `sorryAx`, which is not whitelisted → a hard error
  naming it.

There is no third state in which a name both resolves and carries no axioms while
its proof failed. **"A green tick from `#audit_axioms` is not evidence the
theorem exists" is FALSE as stated, and it should come out of the README.**

## What was probably really seen at 14:04, and what survives

Info messages emitted *before* an error are still printed. A file containing
`#audit_axioms A B` where `A` elaborates and `B` later fails prints `✓ A
[0 axioms]` **and then** an error — and a reader scanning for ticks sees a tick
next to a build that failed. That is a reading hazard, not an instrument defect,
and it is almost certainly what I saw and mis-attributed.

So the **practice** rule survives and is worth keeping, on its own footing:

> **Never quote an `#audit_axioms` line without the build result beside it** — a
> tick printed before a failure is still printed, and it certifies only the
> declaration it names.

Evidence already wrote that sentence into the same section. It stands. What must
go is the stronger claim underneath it — that the tick can be printed *about
nothing at all*.

**And the three original honesty notes are untouched and remain the real ones:**
an axiom audit is invariant under *wrong file imported*, *port mis-parsed*, and
*cell mis-modelled* — it is a statement about proofs, not about the chain. Those
were right at 10:47 and they are right now. I replaced a true narrow claim with a
false total one, and the false one is the more quotable, which is exactly why it
travelled.

## Proposed permanent fix

`AuditAxioms.lean` already pins the unknown-name and non-whitelisted-axiom paths
with `#guard_msgs`. The `sorry` path and the elaboration-abort path should be
pinned the same way, so this question is answered by the build forever instead of
by a scratch file that no longer exists. **That file is imported by all three
legs and has no seat listed in `docs/SEATS.md`** — proposed to the maestro on the
bus rather than landed unilaterally mid-campaign.
