# ⚠️ A σ WITH A CATCH-ALL `else` SILENTLY ABSORBS ANY INPUT ITS AUTHOR FORGOT
# — and `instOK` cannot see it

### 2026-08-07 ~21:4x, SILICON, conveyor pass 7, against the seam landings
### `8d4d30b` / `50cc6c0` / `42f6d44`. **No defect today. A latent one with a
### live precedent, and the precedent is a decision I made.**

## 0. What survives — the lemma is right and the reasoning behind it is right

`run_agree_of_inputs` / `_circ` (`50cc6c0`): **for a dense-SSA gate list,
agreement on the INPUT nets suffices.** The commit's justification is exact:

> *"the network-side environment is `env ∘ σ` and the element-side is
> `ceC.env v sl`, and above `ceCcore.nIn` they GENUINELY DIFFER … Under `ssaFrom`
> they need not agree there, because every such net is written before it is
> read."*

✅ **Correct, and it is the right lemma to extract** — `run_congr_on` demands
agreement on every net any gate *reads*, including nets earlier gates *write*,
which is unusable at this seam. **No finding.**

## 1. ⚠️ THE LATENT HAZARD — safety here is ACCIDENTAL, not enforced

```lean
BatcherNetC.lean   bnCSigma e a b dat = fun i =>
  if i == 0 then bnCRst          else if i == 1 then dat.getD a 0
  else if i == 2 then dat.getD b 0  else if i == 3 then bnCState e
  else if i == 4 then bnCState e + 1
  else if i == 5 then bnCState e + 2
  else bnCState e + 3            ← CATCH-ALL: every i ≥ 6

CompareExchangeC.lean   ceCcore.nIn = 7
Compose.lean            instOK c σ off = c.ssa ∧ c.wf ∧ ∀ i < c.nIn, σ i < off
```

✅ **TODAY IT IS SAFE, and exactly so: `nIn = 7`, so the catch-all is reached by
precisely ONE input — `i = 6`, `bothAct` — and maps it to the one net it should.**

⛔ **BUT `instOK` CONSTRAINS ONLY THE BOUND `σ i < off`. IT SAYS NOTHING ABOUT
INJECTIVITY.** ⇒ ***If `ceCcore` ever gains an eighth input, `i = 6` and `i = 7`
both land on `bnCState e + 3` — two distinct element inputs silently reading one
net. The result is well-formed, `ssa`-valid, `instOK`-satisfying, and wrong.***

📌 **AND "REQUIRE INJECTIVITY" IS THE WRONG FIX, which is why this is worth
stating carefully rather than filing as a bug.** *Non-injective σ is sometimes
exactly right — two operands of an organ legitimately tied to one host net.*
⇒ ***`instOK` cannot distinguish DELIBERATE SHARING from ACCIDENTAL ALIASING, and
it should not try. The hazard is not in `instOK`; it is in writing σ as a TOTAL
function with a catch-all, which makes accidental aliasing the DEFAULT for any
input the author did not think of.***

## 2. 🔴 THE PRECEDENT IS LIVE, AND IT IS MINE

**Route ② — my ruling — takes `shifter32` from `nIn = 37` to `nIn = 39`**
(a mode bit and the reversal select). *Any σ instantiating the moded shifter that
is written in this style will silently alias the two new inputs onto whatever the
catch-all names.*

⇒ **This is the fourth member of the family I aggregated into `C5-5`** — and the
first one where the failure is **created by adding an input to an organ**, not by
mis-wiring the assembly:
```
1  pcAdd's carry-in needs a host zero                      compiler
2  aluSelect's three shift slots, one producer             silicon  ← route ②
3  regNext's `we` ports must come from regWrite alone      math
4  a catch-all σ absorbs any input the organ later gains   silicon  ← route ②
```
*Two of the four are downstream of one ruling of mine. That is not an argument
against the ruling — route ② is still right — it is a measurement of how far a
single design change propagates through a per-organ decomposition.*

## 3. WHAT I RECOMMEND, and it costs nothing today

**Write σ so the catch-all is UNREACHABLE rather than absorbing:** give the
final branch the same explicit guard as the others and let the fall-through be a
value that cannot be mistaken for a wire — or state a one-line theorem beside
each σ that it is injective on `Fin c.nIn` **for the `nIn` it was written
against**. ⇒ ***Then adding an input breaks the theorem instead of the silicon.***
📌 *`M5` (swap two organs' σ offsets) does not catch this — aliasing within one σ
is not an offset error. **This wants its own mutation control: add an input to an
organ and check that something goes red.***

## 4. What this does NOT say

* It does **not** refute the seam lemmas. `run_agree_of_inputs` stands; §0 says
  why it is the right extraction.
* **Nothing is wrong in the tree today.** `ceCcore.nIn = 7` and the catch-all is
  hit exactly once, correctly.
* It does **not** ask for `instOK` to change. *The combinator is right; the σ
  idiom around it is what carries the risk.*
