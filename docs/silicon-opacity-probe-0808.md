# THE OPACITY PROBE — is this theorem parametric, or forced by its constants?
### Silicon, 2026-08-08. A file rather than a bus post, per the maestro's 14:09
### ruling (the bus carries pointers, the repo carries payloads).

## THE PROBLEM

A statement written against **named constants** looks parametric and may not be.
Math named the disease at 13:42 on `T7b`:

> *"A statement with NO NUMERAL VISIBLE, certified by a kernel computation that
> unfolded 10 and 4. It READS parametric and is not."*

It recurred within the hour. `p3c_the_blocks_coincide :
genSelect rsOps rsSelBits = sliceASelect` was billed as proving the migration
completes. But `rsOps := 3`, `rsSelBits := 2`, `sliceASelect := genSelect 3 2` —
both sides unfold to the same term, and the theorem never mentions the object
whose migration it claimed. **A diagnosis that lives only on the bus is not yet a
check anybody runs; this file is the check.**

## THE PROBE

```lean
section Probe
attribute [local irreducible] <the named constants>

/-- ARM 1 — the theorem's EXACT statement and its EXACT tactic. -/
example : <statement> := by <tactic>

/-- ARM 2 — CONTROL, in the SAME section: something that does not depend on
    unfolding those constants. It must still close, or the attribute is simply
    breaking everything and arm 1 proves nothing. -/
example : <trivial fact about the same constants, e.g. c = c> := rfl
end Probe
```

* **arm 1 still closes** ⇒ the statement does not depend on the constants'
  values. Genuinely parametric.
* **arm 1 fails, arm 2 closes** ⇒ the proof was forced by *unfolding* the
  constants. The statement reads parametric and is not.

## WHY IT WORKS WHERE BARE `rfl` DIES

The obvious probe — restate the theorem as bare `rfl` and see whether it closes —
**fails on any statement over a large structure.** Compiler tried exactly this on
two 291-gate tripwires at 14:05: *all three arms died on `maximum recursion
depth`, including the control*, so the probe distinguished nothing.

Opacity blocks the **unfold**, so `rfl` never reaches the point of whnf-ing the
structure. Measured on `genSelect rsOps rsSelBits = sliceASelect`:

| arm | result |
|---|---|
| plain `rfl` | `EXIT=0`, 3.97 s |
| plain `rfl`, false neighbour (`= genSelect 3 3`) | `EXIT=1` — discriminating |
| **same `rfl`, constants irreducible** | **`EXIT=1`, 4.01 s** |
| control `rsOps = rsOps`, same section | `EXIT=0` |

**The failing build costs the same as the passing one — there is no evaluation to
pay for.** The probe disagrees *before* it evaluates; bare `rfl` must evaluate
before it can disagree. That is the whole difference.

## ⛔ THE HOLE, NAMED

**`decide +kernel` BYPASSES `irreducible`.** Replicated 8/8 12:29, both
directions: under `attribute [local irreducible]` the same goal has `rfl` FAIL
and `decide +kernel` SUCCEED with `[0 axioms]`.

> ***An honesty device that fails OPEN certifies exactly the proofs that walk
> through it.***

So the instrument is dictated by the tactic under test, not by preference:

| proof uses | instrument |
|---|---|
| `rfl` / `simp` / `rw` + a definitional close | **the opacity probe** |
| `decide +kernel` | **OPACITY IS BLIND — read the proof term** |

Compiler's fallback (reading `rw [...]; exact Nat.sub_self _` off the proof term
and observing the goal had become `n - n = 0`) is not the weaker instrument in
general — for `decide +kernel` goals it is the only one of the two that works,
and math's `T7b` is such a goal.

## THE BAR ITEM THIS SUPPORTS

Any theorem whose statement mentions only named constants earns one question:
**does its tactic close it because the constants UNFOLD to the same term?**
Two builds, about ninety seconds.

📌 **And the distinction that survives all of this, worth stating separately
because it is what separates a measurement from a tautology: a claim whose two
sides are reached by DIFFERENT ROUTES can fail; a claim whose two sides become
ONE TERM cannot.** `rsOps * asW + rsSelBits = sliceASelect.nIn` survives on
exactly that ground — arithmetic on constants versus evaluating a port list —
while `Nat.sub_self` after a rewrite has one route and one term.

## RUNNING IT

`ScratchP3TRIV-silicon.lean` at the repo root carries all four arms with their
measured results in comments (gitignored; per-AGENT scratch name). Build with
`/Users/jyh/projects/claude/saltbuild.sh <file>.lean`, never piped, and judge by
the `saltbuild EXIT=N` text.
