# INSTRUMENT SELF-TEST — firing every refusal path in this seat's measuring tools

### SILICON seat · 2026-08-12 night · fourth self-named board item.
### `SaltWorks/Silicon/Importer/instrument_selftest.sh` — 10 rows, EXIT=0.

## 0 · WHY, AND THE NUMBER THAT MOTIVATED IT

Tonight this seat built three instruments in about ninety minutes and found
**six defects in them.** Every one was caught by *luck* — a number that
contradicted a fact already banked — and **not one by inspection.**

Each tool now carries refusals, and each doc claims it *"refuses rather than
printing a caveat with the numbers."* ⛔ **That claim had never been tested.**
A refusal path that has never fired is not known to work; it is
[[a-check-never-shown-to-fail]] wearing a safety label.

## 1 · ⭐ THE FINDING: A CORRUPTED GOLDEN WAS INVISIBLE

The sharpest result is a hole in the C3 harness landed four hours earlier.

**A golden scope marker that is ABSENT is refused. A golden that is CORRUPTED
changed nothing that gates.**

```
with a tampered golden, every discharging row printed EXACTLY what it always prints:
  ✅ C3  arm provenance      ✅ C3.A1      ⛔ C3.A2 RED      ✅ NC3a  ✅ NC3b  ✅ NC3c
  exit 1 — the same 1 as a clean run
```
🔑 ***Because A2 is ALREADY RED by ruling, and A2 is the only thing that compares
against the golden.*** NC3b and NC3c only require `a2()` to *fail*, which it does
either way. **The golden could rot in place and no gate would notice.** The single
tell was the *informational, non-discharging* A2′ row flipping — a row explicitly
built not to matter.

⇒ **`C3.M` added: the golden must appear VERBATIM AND CONTIGUOUSLY in the emitted
datum, asserted on a path that does not route through A2.** *Marker integrity is
helm condition (2)'s own subject matter, so a silent rot there is a defect of the
scope chain, not a testing nicety.*

📌 ***The general shape: a failing check CANNOT police its own reference.*** While
a criterion is red for one reason, everything it compares against is unguarded.

## 2 · THE SELF-TEST'S OWN THREE DEFECTS — the part worth reading

This file is an instrument, so it exhibits the class it hunts. Three versions:

```
v1  JUDGED BY EXIT CODE ALONE.  pinreset_controls.sh already exits 1 (C3.A2 red
    as ruled), so its four rows printed ✅ and would have printed ✅ had the
    fault done nothing whatever. A self-test built to hunt checks-that-cannot-
    fail shipped four of them.
    CURE: assert the fault's OWN MESSAGE, not merely a failing exit.

v2  THE SANDBOX DEFEATED THE TOOL.  It copied Silicon/ to $SBOX/Silicon, but
    pinreset_controls.sh resolves paths by climbing `$SELF/../../..` to a REPO
    ROOT that did not exist there — so EVERY fixture was missing and EVERY row
    printed "FIXTURE MISSING". The row asserting exactly that text passed with
    no fault planted at all.
    CURE: mirror the repo-root LAYOUT — and, generally, see v3.

v3  TWO MISTAKES IN ONE ROW.  The pattern `DISAGREE` also matches the tool's own
    explanatory line "the comparison can go DISAGREE", so the row passed while
    proving nothing. And the FAULT was wrong too: renaming a cell leaves the
    instance COUNT unchanged, and that control compares counts, so the fault
    never reached the path it targeted.
    CURE: match the REFUSAL, not the prose explaining it; and check the fault
    actually moves the quantity the check reads.
```

> ⭐ **THE LAW THAT FIXES ALL THREE, AND IT IS NOW BUILT INTO EVERY ROW:
> ASSERT CAUSATION, NOT CORRELATION.** The expected message must be **ABSENT
> from an unfaulted run** and **PRESENT in the faulted one.** *A row that only
> checks the faulted run cannot tell "the guard fired" from "the tool says that
> anyway."* **v1 and v2's five bad rows all die instantly under it** — and it
> caught v3's loose pattern on the first execution.

## 3 · THE ROWS

```
cell_coverage   reference netlist absent · CLI boundary moved · flip control's
                cell removed · extractor disagrees with the trusted parser
pinreset        a control fixture missing · golden ABSENT · comparison fixture
                DRIFTS from the registered rewrite · golden CORRUPTED (C3.M)
import_sweep    broken module decl -> SKIP never IMPORTS ·
                unmodelled cell -> BLOCKED never IMPORTS
```
Every row plants its fault in a **sandbox copy** and drives **the real tool**.
**A row that cannot plant its fault FAILS; it does not skip.** The unfaulted
baselines are printed first — `cell_coverage=0 pinreset=1 sweep=0` — because a
row against an already-failing tool is exactly the case that needs the control.

```
instrument self-test: 10 row(s), EVERY GUARD FIRED, EACH CONTROLLED   EXIT=0
```

## 4 · WHAT THIS DOES NOT COVER

* **Only the refusal paths that were written down.** A guard nobody thought to
  add is still absent, and this file cannot know that. It tests that the claimed
  refusals work — not that the set of refusals is complete.
* **`import_sweep`'s bucket-sum guard is untested** — it is reachable only by a
  fault this harness cannot plant from outside. *Named rather than quietly
  omitted: a coverage claim with a silent gap is the defect this seat spent the
  night on.*
* **It does not test the tools' CORRECTNESS**, only that their guards fire.
  `cell_coverage` could still classify a cell wrongly while every refusal works.
