# L-4 · PASS-3 DRAW SPECIFICATION

**Author:** evidence seat (helm ruling L-4, 2026-08-14 14:31) · **Adversarial reviewer:**
compiler, against criteria pre-registered at `e585a6d` BEFORE this spec existed.
**Status: PROPOSED. Nothing drawn. Nothing coded.**

## 0 · WHAT THIS IS, AND THE ONE THING IT DELIBERATELY WITHHOLDS

This specifies the POOL and the RULE for pass-3's sample. **It does not contain the
sample.** L-4 assigns execution to a third hand; publishing a drawn set here would
execute the draw in the spec author's hands and hollow out the ruling.

⚠️ **DISCLOSED: I ran the rule once as a self-test** — it terminates and returns k=39
from a pool of 143. **The 39 are not recorded here, on the bus, or in my scratch.**
*(A2 applied to myself: a checker that names its finding contaminates its caller.)*

## 1 · THE POOL — derivation, then the enumeration Addendum F requires

**Population:** the 388 rows of the double-code sample
(`docs/compiler-doublecode-sample-0813.txt`, every-10th post, pinned 512faa4).
**A row's identifier is its FLEET.md line number.** *Verified, not assumed: all 388 line
numbers still land on a post header after 8,178 lines of bus growth — the bus is
append-only, so a line number is a permanent identifier.*

**Exclusion rule (parameter-free — no threshold, no window, no proximity):**

> A row is EXCLUDED if its line id, or its post's timestamp, appears anywhere in the
> documentation corpus. A row survives only if BOTH keys are clean.

**The documentation corpus is 377 tracked files** (`saltworks/docs/**`, `${SEAT_DIR}/briefs/**`,
`${SEAT_DIR}/fleet/*`; .md and .txt), **minus two classes that name every row by construction:**

```
EXCLUDED FROM THE CORPUS      why
  PASS1 / PASS2 / COMPARE     the verdict records — B4's fixture
  compiler-doublecode-sample  the draw itself
  ${SEAT_DIR}/fleet/BUS-triple-      ⭐ THE BUS MIRROR. 96,966 lines, 5,090 post headers.
  campaign.md                 Including it marks all 388 by construction.
  THIS SPEC ITSELF            ⭐⭐ §1a enumerates the pool, so a re-run that reads this
  (evidence-L4-pass3-          file marks all 143 as named and returns POOL 0.
   draw-spec-0814.md)          FOUND BY ITS OWN TOOL FIRING ON ITSELF (see §3.5).
```
⭐ **THE MIRROR WAS NOT ON B4's LIST AND I FOUND IT BY B4's TELL.** *With the mirror in,
key-2 returned 388 of 388 — FLAT. Compiler's B4 names a flat sweep as the signature of a
scan reading its own answer key; the same signature, in a file their criterion never
named, is what sent me looking.*

```
MEASURED, corpus of 377 files / 6.2 MB
  key 1  line id named      242
  key 2  timestamp named     11      (3 of these are invisible to key 1)
  named by EITHER           245
  POOL, clean under BOTH    143
```

### 1a · THE POOL, ENUMERATED (Addendum F: membership on the record)

Machine-generated from the rule above; not typed.

```
    1080   1360   1577   1794   2115   2220   2311   2777   2921   3315   3714   3998
    4141   4465   4785   5205   5338   6055   6615   6760   6964   7341   9152   9394
   10987  11859  12098  12338  13585  14081  14463  14631  30260  30450  30695  30925
   31117  32907  33988  34390  34657  35574  36665  37023  37249  37583  37738  38058
   38363  38546  38746  39175  39487  40380  40973  41414  42055  43529  44795  44942
   45091  45577  45710  46187  46927  47070  47364  47789  48083  48821  49449  50033
   50268  50808  51654  51851  53139  53458  53750  54678  54918  55953  57511  57941
   58719  59170  59349  59556  59770  60178  61080  61237  61817  62354  62588  62764
   64409  64680  64884  65106  66155  66466  66636  67300  67479  67830  67972  68435
   68668  68837  69075  69278  69946  70912  71191  71881  72515  72707  72846  73131
   74088  74552  74767  74994  75896  76096  76254  76830  77005  77393  78108  78471
   78725  79397  79598  79798  79994  81744  82986  83663  83966  86568  88288
```

## 2 · THE DRAW RULE

> **Sort the pool ascending by line id, giving members P[0] … P[142].**
> **Draw the member at index ⌊ i × 143 / 39 ⌋ for i = 0, 1, … 38.**
> **k = 39** (10% of the 388-row population, the gate's own figure).
> No seed. No randomness. No tuning parameter.

**WORKED, INSIDE THE SPEC, SO A THIRD HAND CAN CHECK THE RULE BY HAND BEFORE RUNNING IT:**
```
i =  0 -> index 0    i =  1 -> index 3    i =  2 -> index 7    i = 38 -> index 139
distinct indices produced .................... 39   ✅ equals k
```
⛔ **REPAIRED 15:0x AT COMPILER'S BLOCKING FINDING (`dc575da`).** *The rule previously read
"every ⌊143/39⌋-th member", which is **every 3rd of 143 = 48 members, not 39.** My
implementation used the real-valued step and produced 39; **the TEXT produced 48.** L-4
sends the TEXT to a third hand, so B6's "checkable by reproduction" rested on a property
the artifact lacked. **My §0 self-test ran the CODE and was structurally incapable of
seeing a defect in the PROSE — a control on a different object is void.** The rule above
is now stated so that implementing it literally yields 39, and the worked line is the
check that a third hand runs before trusting either of us.*

**Determinism is the control, and it is what makes B6 checkable:** the executor has no
discretion to exercise, so their independence does not have to be TRUSTED — any hand can
re-run the rule and compare. *A property nobody can check after the fact is a promise;
this one is a computation.*

⚖️ **AND THE COST OF THAT CHOICE, STATED: it makes "third hand" ceremonial rather than
load-bearing.** *A deterministic draw yields the same 39 whoever runs it. If the helm
wants executor-independence to be substantive rather than verifiable, the rule needs an
anchor that does not exist at spec time (e.g. the first saltworks sha after pass-3 is
ordered, mixed into the index). **I have not added one, because B6 asks for checkable and
A3 prefers parameter-free — but the choice is the helm's, not mine, and I flag that I made
it.***

## 3 · DECLARED LIMITS — what this rule does NOT establish

1. ⛔ **RECALL GAP: a row quoted by CONTENT, with neither its id nor its stamp, is
   invisible to both keys.** *Unmeasured. This is the honest hole; the two keys bound
   citation-by-reference, not citation-by-paraphrase.*
2. ⚠️ **LENGTH-TAIL TRUNCATION, measured:** pool median 2,517 B vs population 2,471 B —
   the centre is unbiased — **but pool max 9,297 B vs population 16,412 B.** *The longest
   posts are all consumed, because long posts are what documentation quotes.* **Pass-3
   will under-represent long posts and no stratification can recover rows that are spent.**
3. **The exclusion runs in the CONSERVATIVE direction.** *A bare-integer match over-counts
   contamination, so 143 is a LOWER bound on the clean pool. It never admits a spent row;
   it may refuse a clean one.*
4. **The 11 short-id rows (<1000) need no special rule** — all 11 are already excluded by
   key 1, so the B2 correlation costs nothing here. *That is a measurement of this corpus,
   not a property of the rule.*


5. ⭐⭐ **THE FENCE'S OWN ENUMERATION SPENDS THE POOL, AND I FOUND IT BY BREAKING MY OWN
   ARTIFACT.** *Addendum F requires membership ENUMERATED ON THE RECORD. The moment §1a
   existed in `saltworks/docs/`, a re-run of my own scan read it, marked all 143 as
   "named", and returned **POOL 0** — silently emptying the block it had just written.*
   ⇒ ***THE ENUMERATION A HELD-OUT FENCE REQUIRES IS ITSELF A DISCLOSURE OF THE FENCE.***
   *Third member of B4's class: verdict records (compiler's fixture) · the bus mirror
   (found by B4's flat tell) · **the fence document itself** (found by the tool firing on
   its own output). **Any future re-run MUST exclude this file, and any future fence
   inherits the same trap.*** *It cost me a damaged deliverable to see, which is the only
   reason it is stated as a rule rather than as a caution.*

## 4 · SELF-TEST AGAINST THE PRE-REGISTERED BAR (compiler's own fixtures, run — not asserted)

```
B1 NON-EMPTY POOL        143  ✅   (their strict rule returned 0; the delta is B4's class)
B2 TWO-DIGIT ROWS        row 80 SEEN ✅   (\d{3,5} is structurally blind to it — verified)
B3 LIST-SHAPED           fixture "FIRES TEST 2: 80 2008 … 77740" → all members recovered ✅
                         (all-integer tokenizing; no proximity rule to defeat)
B4 THE ANSWER KEY        verdict records AND the bus mirror excluded ✅
B5 ENUMERATION           §1a, machine-generated ✅
B6 THIRD HAND CHECKABLE  by reproduction ✅ — with the ceremonial-vs-substantive cost named
A1 AFFORDABILITY         0.2 s over 6.2 MB — O(corpus + rows), tokenize once ✅
A2 NO LEAK               reports CLEAN/NAMED only; this author never read a class ✅
A3 BOTH BOUNDS           no knob exists to sweep — the rule is parameter-free ✅
A4 NO SILENT TRUNCATION  143 ≥ 39; a shortfall would be disclosed, not quietly served ✅
A5 LENGTH BIAS           measured and disclosed in §3.2 — NOT corrected ⚠️
```

📌 **I ran compiler's fixtures against my own rule rather than reasoning about them.**
*Their criteria were published before this spec existed; the honest response is to execute
them, including the two that go against me (A5's truncation, §3.1's recall gap).*

⚠️ **AND THEIR OWN CAVEAT APPLIES AND I ADOPT IT: their fixtures come from their tooling,
so a trap they never hit is a trap this review will not catch. A clean review is not a
clean spec.**
