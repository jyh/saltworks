# §6-R3 CLASS-DETERMINACY AUDIT — PRE-REGISTRATION

**Seat:** compiler · **Written 2026-08-14, BEFORE any drawn row was opened.**
The commit timestamp is the pre-registration; nothing below may be edited after
the first row is read. Amendments, if any, land as a **separate** commit that
says what changed and why.

## 1. THE QUESTION B-3 ACTUALLY ASKS

> *"Not side-determinacy."* — not which coder wins, but whether the codebook's
> class tests **mechanically decide** a class on a row it has never seen.

**Benchmark to beat, from the file itself:** the refuter measured DRAFT 1 at
**5/20 mechanically decided** on unnamed rows, against DRAFT 1's own claimed
**90.3%**. *That gap is the thing being re-measured.*

## 2. POOL — MEASURED, NOT QUOTED

```
disputed rows (pass1 ≠ pass2) ............... 278   file: 278        ✅ exact
named anywhere in the ratified file ......... 158   file: "~158"     ✅ exact
⇒ FREE POOL .................................. 120   file: "~120"     ✅ exact
```
Absence is tested **word-bounded** (`(?<!\d)N(?!\d)`). A naive substring test
matches `9` inside `1905` and `39087`; it was run first, fabricated a false
positive, and was replaced before any figure was derived.

## 3. DRAW — **LENGTH-STRATIFIED**, and here is why

My §6-R1 probe used a uniform every-14th draw and it **missed the entire upper
tail**: draw max 4,782 B against pool max 16,411 B, with 20 posts holding 18.5%
of pool bytes longer than anything sampled. The rate it produced was biased in
the flattering direction. **That defect is fixed here by construction, not by
care:** sort the 120 by body length, cut into 30 equal strata, take the
lowest-line-number member of each.

```
            min   median    max     mean
draw(30)    217    2,494   5,548   2,510
pool(120)   217    2,524   9,296   2,627
draw max reaches 60% of pool max   (R-1's uniform draw reached 29%)
mean gap −4.5%                     (R-1's was −10.8%)
```
**THE 30 (fixed; re-selection is forbidden and the file records it if it happens):**
```
 7483 ·  8869 · 10759 · 11449 · 12530 · 29685 · 33588 · 35928 · 38216 · 39254
42611 · 44228 · 46464 · 47634 · 49178 · 52049 · 52323 · 55149 · 55532 · 57709
61392 · 69485 · 70753 · 71730 · 73876 · 81979 · 82239 · 82566 · 86063 · 87122
```
Absence from the ratified file **re-verified for all 30** (B-3's requirement).
Total to read: **75,290 B**.

## 4. THE DECISION PROCEDURE, FIXED IN ADVANCE

Apply the codebook's class tests in its **precedence order**:
`(1) type-traps → (2) misattributed → (3) stale-citations → (4) wrong-scope`.

Per row, exactly one of:

- **MECHANICALLY DECIDED** — I can (a) name the test that fires, **and** (b)
  quote the span of the row that fires it, **and** (c) no test of higher or equal
  precedence also fires. *All three, or it is not decided.*
- **NOT DECIDED** — a judgement call is required, or two tests fire at equal
  precedence, or no test fires at all. **The reason is recorded per row.**

**CONTESTED** is recorded independently of the above: a row is contested if I can
construct a defensible argument for a second class. Per B-4's condition (2), the
contested count ships **beside** the verdict count. No single number ships alone.

## 5. ⭐ PRE-REGISTERED EXPECTATION — falsifiable, and stated before the evidence

**I expect 40–70% mechanically decided (12–21 of 30).**

*Reasoning, so the prediction can be judged and not just scored:* §1.x carries an
explicit **precedence order**, which is a determinacy mechanism §2.2's gate
lacks — so I expect it to beat DRAFT 1's 25% clearly. But my §6-R1 probe measured
70% of gate calls contested by hand, and nothing suggests class calls are
categorically easier, so I do not expect anything near 90.3%.

```
< 40%   I am wrong, and the precedence order is not doing the work I credit it with
> 70%   I am wrong in the other direction, and my R-1 pessimism did not transfer
```
**If the result lands inside 40–70% that is a CONFIRMED prediction; if outside,
I say so in the same post and do not re-describe the band.**

## 6. WHAT THIS RUN DOES **NOT** CLAIM

- It is **not** criterion-dependent as far as I can tell: R-3 exercises the §1.x
  **class** tests, not §2.2's EXCLUDED gate, so pack item 8 should not move it.
  *Stated as my reading, not a ruling — and if a drawn row turns out to hinge on
  the gate, that row is recorded as gate-dependent rather than silently scored.*
- It says nothing about **which coder was right** on any row. Side-determinacy is
  explicitly out of scope per B-3's first line.
- N=30 is B-3's floor, not a large sample. **A proportion from 30 rows carries a
  ±~9 point standard error and the report will say so** rather than printing a
  bare percentage.
