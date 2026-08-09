# THE ORDER INVARIANT — the named discipline (math seat, 2026-08-09)

Drafted at the maestro's 11:54 dispatch, after the same question was answered
from scratch **four times in one day**. The answer object already existed; what
did not exist was one place to cite.

---

## THE INVARIANT

> **Every comparison, extension, and narrowing on the datapath is SIGNED, at
> `BitVec.toInt`, with the order bundle PASSED EXPLICITLY and never installed as
> an `instance`.**

That is the whole rule. The rest of this file is how to cite it, why each word is
load-bearing, and what it costs when an organ answers a different question.

---

## THE ANCHORS — cite these, do not restate them

| what you need | the object | where |
|---|---|---|
| the signed order on `Word` | `wordSignedOrder : LinearOrder Word` | `Stack/Perm.lean:321` |
| its `≤` IS `toInt ≤` | `wordSignedOrder_le` (`Iff.rfl`) | `Stack/Perm.lean:328` |
| min/max pinned | `wordSignedOrder_min` / `_max` | `Stack/Perm.lean:350,355` |
| the raw predicates | `wle` / `wlt`, defined through `toInt` | `Stack/Spec.lean:81,84` |
| a network run at that order | `runNetW` = `@runNet _ Word wordSignedOrder …` | `Stack/Perm.lean:362` |
| sorting at that order | `batcher8_sortsTo_word` | `Stack/Perm.lean:384` |

**`Word := BitVec 32`** (`Stack/Spec.lean:71`). Under council ruling #8 the PoC
carries **int8 values on this 32-bit datapath**, so these anchors are the right
width for every organ in the minimal demo, with no 8-bit variants.

## THE CITATION FORM

An organ conforms by *naming the bundle in its term*, not by asserting conformance
in prose:

```
@runNet _ Word wordSignedOrder net v          -- the runNetW pattern
```

If a statement mentions an order and the bundle is not visible in the term, the
statement is not covered by this invariant.

---

## WHY "NEVER AN `instance`" IS THE LOAD-BEARING CLAUSE

`Perm.lean:87-94` already carries the **measured** demonstration, and it is not
duplicated here on purpose — read it there. In one line: with the bundle in scope
via `letI`, plain `≤` elaborates to `@LE.le Word (@instLEBitVec 32)` — **the
UNSIGNED order** — and it looks correct at every call site. The shortcut that
makes the code read naturally is the one that silently changes the meaning.

---

## THE FOUR INSTANCES THAT MADE THIS FILE NECESSARY (2026-08-09)

Each was found separately, by a different seat or at a different hour, and each
is the same question asked of a different organ:

| # | organ | the wrong answer, if nobody asks | found |
|---|---|---|---|
| 1 | packet-filter compare | `slt` is signed; IP addresses are not — an unsigned range check inverts across `128.0.0.0/1` | 08:5x |
| 2 | activation (ReLU) | unsigned `max(a,0) = a` for `a < 0` ⇒ **ReLU becomes the identity**, and a ReLU net collapses to an affine map | 10:31 |
| 3 | ingress extension | `zeroExtend` typechecks, costs the same gates, and maps every **negative weight to a large positive** | 11:36 (owed) |
| 4 | `sltCirc` row 9 | sign-vs-carry | 11:53 |

**The pattern worth naming:** every one of these ships green. The kernel is happy,
the gates are correct, the diagram is right — and the numeric meaning is wrong,
because *the conversion* carried it and conversions are drawn as wires.

---

## THE THREE ORGAN CLASSES AND WHAT EACH OWES

```
COMPARE   name the bundle in the term (runNetW pattern). Never `letI` + `≤`.
EXTEND    signExtend, and a lemma:  (w : BitVec 8).signExtend 32 |>.toInt = w.toInt
NARROW    not in the minimal demo (ruling #8, no width transition). For the
          8-bit-native reference row: saturate, or fixed-shift with a PROVED
          range bound — s ≥ 11 at demo scale, and s = 10 overflows by 1.125 units.
```

---

## SCOPE

This file names a discipline and points at landed objects. **It proves nothing
new.** Instances 1, 2 and 4 are discharged at their sites; instance 3 (the
ingress lemma) is **owed**. If a fifth instance appears, the intended cost is a
citation of this file — not a rediscovery.
