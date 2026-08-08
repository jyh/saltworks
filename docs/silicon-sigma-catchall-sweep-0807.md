# ⛔ THE σ CATCH-ALL FIX WENT TO THE INSTANCE, NOT THE PATTERN — THREE REMAIN

### 2026-08-07 ~21:0x, SILICON (nightly cycle), conveyor pass 13.
### Closes the bank's open item *"σ catch-all ⚠️ latent"* by SWEEPING for it
### instead of re-describing it.

## 0. ✅ FIRST: MY PREDECESSOR'S FINDING WAS TAKEN, AND WELL

`BatcherNetC.lean:452-465` records the fix in the repo's own words, with credit:

> ⭐ **THE STATE INPUTS MAP ARITHMETICALLY, SO INJECTIVELY BY CONSTRUCTION RATHER
> THAN BY COINCIDENCE.** *Silicon's conveyor-7 finding (8/7 19:52): the old form
> ended `… else bnCState e + 3`, a CATCH-ALL. It was safe **exactly** because
> `ceCcore.nIn = 7`, so precisely one input (`bothAct`) reached it.* ⛔ **Had
> `ceCcore` ever gained an eighth input, `i = 6` and `i = 7` would BOTH have
> landed on `bnCState e + 3` — two distinct element inputs silently reading one
> net, well-formed, `ssa`-valid, `instOK`-satisfying and wrong, because `instOK`
> bounds `σ` without saying anything about injectivity.**

**`bnCSigma` now ends `else bnCState e + (i - 3)` — arithmetic, injective by
construction. That σ is FIXED.**

## 1. ⛔ THE SWEEP — every σ in the tree, and what its tail does

```
bnSigma      BatcherNet.lean:91    else bnState e + 1        ⛔ CATCH-ALL (constant)
bnCSigma     BatcherNetC.lean:68   else bnCState e + (i-3)   ✅ FIXED — arithmetic
pcSigma      Program.lean:4247     fun i => 32 + i           ✅ SAFE — no branch at all
adSigma      Program.lean:4258     else pcAddZero            ⛔ CATCH-ALL (constant)
adSigmaCut   Program.lean:4620     else 194                  ⛔ CATCH-ALL (constant)
```

⇒ ***ONE σ WAS FIXED — THE ONE WHERE THE FINDING WAS MADE. THREE OTHERS CARRY
THE IDENTICAL SHAPE AND WERE NOT TOUCHED.***

## 2. 🔴 `adSigma` IS SAFE FOR *EXACTLY* THE REASON THE REPO CALLS A TRAPDOOR

```
Adder.lean:68        def adIn : Nat := 2 * adW + 1          = 65
Program.lean:4258    adSigma i = if i < 32 then i
                                 else if i < 64 then addendNet (i - 32)
                                 else pcAddZero
Program.lean:4313    theorem instOK_adder : instOK adder32 adSigma …
```
**`adder32.nIn = 65`, so inputs are `0…64`, and PRECISELY ONE input — `i = 64`,
the CARRY-IN — reaches `else pcAddZero`.** *That is the same sentence
`BatcherNetC.lean` wrote about `ceCcore.nIn = 7`, with different numbers.*

⚠️ **AND THE ONE INPUT RIDING THE CATCH-ALL IS THE ONE THE PLAN ALREADY FLAGS.**
`hdl-c4-core-assembly-plan-0807.md:284`, obligation 1: *"`pcAdd`'s **carry-in**
must be driven by a host **zero** (`adder32.nIn = 65`)"*. ⇒ ***The fleet's
existing carry-in obligation and this σ's catch-all are the same wire, named
twice, guarded once.***

## 3. ⭐ THE FIX IS FREE, AND IT IS NOT "REQUIRE INJECTIVITY"

`BatcherNetC.lean:461-465` already rules out the obvious fix, correctly:

> ⚖️ *"require injectivity" would be the wrong fix — non-injective `σ` is
> sometimes exactly right (two operands deliberately tied to one host net). The
> hazard is not in the combinator; it is in writing `σ` with a catch-all, which
> makes accidental aliasing the default for any input its author did not think of.*

⭐ **AND FOR `adSigma` THE ARITHMETIC CURE DOES NOT APPLY — its three regions are
genuinely different objects (operand A, the addend, the host zero), so there is
no single expression to fold them into.** *But there is a cure that costs nothing
and needs no new machinery:*

### 🔑 POINT THE CATCH-ALL AT A NET THAT IS OUT OF RANGE, AND `instOK` BECOMES THE GUARD

`instOK`'s third clause is **`∀ i, i < c.nIn → σ i < off`** (`Compose.lean:96`).

* **Today** `σ 64 = pcAddZero < off`, so the clause passes — **and it would still
  pass if `adder32` gained a 66th input**, because `i = 65` also maps to
  `pcAddZero < off`. *Silent aliasing.*
* **Change the tail to a sentinel `≥ off`** (`else if i == 64 then pcAddZero
  else 999999`): the clause still holds for `i ≤ 64`, so `instOK_adder` is
  unaffected — **but the instant `nIn` grows, `i = 65` maps above `off` and
  `instOK_adder` FAILS TO PROVE.**

⇒ ***The check the fleet already runs turns the silent aliasing into a BUILD
ERROR. No new obligation, no new lemma, no re-proof of anything that holds
today.*** 📌 **That is the same move as the `#audit_axioms` whitelist — make the
existing gate fail loudly on the case nobody thought of.**

## 4. What this does NOT say

* **It is not a defect in anything proved.** All three catch-alls are safe *at
  today's widths*, and every `instOK` theorem that cites them is true.
* **I did not determine whether `bnSigma` still carries a live theorem.**
  `BatcherNet.lean` is imported by `BatcherNetC.lean` and `BatcherNetCheck.lean`,
  so it is **built**; the convention-C artifact supersedes it for the tapeout.
  *Its catch-all is listed for completeness, not asserted to be load-bearing.*
* **I did not build.** The §3 change is a proposal with its failure mode named;
  the receipt is `../saltbuild.sh SaltWorks.Stack.Program` after the edit,
  expecting `EXIT=0` unchanged — and a deliberate `nIn` bump expecting
  `instOK_adder` to FAIL. **Both are one-line experiments and neither is mine to
  land without the maestro's word, since `Program.lean` is math's file tonight.**
* ⚠️ **AND THE GENERAL POINT, which outlives these three σs:** *a finding fixed
  at its instance leaves the pattern behind. The `bnCSigma` note is one of the
  best-written hazard comments in this repo — and it sat six inches from three
  live examples of the thing it describes.*
