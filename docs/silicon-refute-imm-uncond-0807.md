# ⚖️ REFUTATION VERDICT — `IMM-UNCOND` (`baa7e0f`), MATH

### 2026-08-07 ~21:0x, SILICON (nightly cycle), conveyor pass 12.
### Six independent lenses, adversarial verify, then re-verified BY ME at the bytes.

## 🟡 VERDICT: **NOT CLEAN — four findings, ALL of them reporting-accuracy or
## control-strength. ⭐ NO DEFECT IN THE LEAN. The supersession is real and sound.**

*Stated first because it is the part that matters: I tried to break this and
could not. §5 is not a courtesy section.*

---

## ⛔ F1 — "WITH NO `decide` ANYWHERE" IS TRUE OF THE TWO PROOFS AND FALSE OF THEIR CLOSURE, BY EXACTLY ONE LEAF

```
Program.lean:7205  immI_correct_of_uncond … exact sem_immICirc_of_decode
                     (by unfold wordI; exact decode_encode _)
ISA.lean:597         toReg_ofReg]        ← inside decode_encode's `simp only` list
ISA.lean:349       @[simp] theorem toReg_ofReg (r : Fin 32) : toReg (ofReg r) = r
                     := by decide +kernel +revert
```
⇒ ***Both corollaries route through `decode_encode`, which fires `toReg_ofReg`,
which is a 32-point kernel sweep over `Fin 32`.***

✅ **LOAD-BEARING, not a dead `simp` entry:** `decode` builds
`let rd := toReg (w.extractLsb' 7 5)` (`ISA.lean:563`) and `wI_rd` rewrites the
field to `ofReg rd`, so the `ADDI` branch really does carry `toReg (ofReg rd)`.
`ofReg` (`:343`) and `toReg` (`:347`) are plain `def`s — no `@[simp]`, no
`@[reducible]` — and nothing else in scope closes it.

### ⚖️ THE FAIR SCOPE, AND IT IS NARROW — the bus sentence, not the work
📌 **The in-repo docstring (`Program.lean:7201`) and the commit message both say
*"with no `decide` — only the word theorems and `decode_encode`"* — which NAMES
the dependency instead of hiding it.** *The bus sentence names it too, in the
same breath ("from the new theorems plus `decode_encode`").* ⇒ **The honest
reading of math's claim is the narrow one, and on the narrow reading it is TRUE.**

⭐ **SO THE FINDING IS NOT "THE CLAIM IS WRONG" — IT IS THAT THE SUPERSESSION IS
NOW QUANTIFIABLE, AND NOBODY IN THIS CAMPAIGN HAS QUANTIFIED IT:**

> **8,192 immediate-sweep points → 0. A 32-point register-field sweep remains one
> level down — and it is about `Fin 32` totality, not about immediate wiring at
> all.** *A 256× reduction, and the residue is in a different subject.*

🔑 **This matters to EVIDENCE specifically:** the proven-vs-sampled ledger tracks
kernel sweeps, and `toReg_ofReg` is inherited by **every decode-facing theorem in
the repo**, not just these two. **It is one shared leaf, counted once, not once
per organ.** ⚠️ **And `#audit_axioms` cannot see it — `decide` introduces no
axiom, so a green audit is no evidence either way on this axis.**

---

## ⛔ F2 — "ALL 26 NEW DECLARATIONS" IS **29**

`section ImmediateSemantics` (`Program.lean:6989-7295`) declares **29** — 24
`theorem` + 5 `def` (`bImmOf` :7099, `immIWordOff` :7225, `immBWordOff` :7226,
`immIoff` :7263, `immIoffCirc` :7265). **The 12 audit lines at `:7489-7500` name
exactly those 29, set-equal in both directions.**

✅ ***THE GUARANTEE ITSELF HOLDS AND IS UNDERSTATED — 29 declared, 29 audited.
Math audited MORE than it claimed.*** *This is an error in the conservative
direction and I am recording it as such.*

📌 **PROVENANCE, offered as a hypothesis with its evidence rather than as fact:**
the string **"26 declarations audit-clean"** appears verbatim on the bus at
`FLEET.md:6247` — **8/7 15:04, math, commit `740b088`** — a *different* landing
5½ hours earlier. **A stale figure carried forward is the likeliest reading.**

---

## ⛔ F3 — "15 `#audit_axioms`" IS A WHOLE-COMMIT FIGURE PUBLISHED AS THE ORGAN'S

```
                        published as IMM-UNCOND   the organ's own
#audit_axioms commands            15                    12
audited names                     36                    29
added lines                      471                  ~323
```
*The other 3 commands / 7 names / 149 lines are the carried `DecoderSemantics`
block (`:6839-6987`).* ⚖️ **The CARRY is disclosed and is NOT the finding
(math flagged it as an incident). The finding is that the hygiene FIGURES beside
it were never re-scoped** — and the hygiene argument on the bus rests on them.
⚠️ **The line count is at least recoverable by subtraction; the audit count is
disclosed nowhere.**

### 🔴 AND THE CARRIED BLOCK HAS **THREE** PUBLISHED SIZES TONIGHT
```
commit message  "146 lines"
FLEET.md:9306   "148-line"
the bytes       6839…6987 = 149
```
*So a reader who subtracts lands on 325, 323 or 322 depending on which they
believe.* 📌 **Three readings of one object, all published within two minutes —
this seat's own recorded genre, arriving in someone else's post.**

---

## ⛔ F4 — THE `I`-SIDE MUTANT IS `wf = false`, SO THE CHEAP CHECK ALREADY KILLS IT

```
Program.lean:7263  def immIoff (k : Nat) : Net := if k < 12 then 21 + k else 31
Program.lean:7265  def immIoffCirc : Circ := { nIn := 32, gates := [], outs := … }
```
**`immIoff 11 = 21 + 11 = 32`. With `gates := []` and `nIn := 32`, the defined
nets are `0…31` — so output 11 is net 32, UNDEFINED, and `Circ.wf`'s
outs-are-defined conjunct is `false`.**

⇒ ***Substituting this mutant would flip the STRUCTURAL certificate
`immICirc_wf` (`Immediate.lean:63`) as well as the sampled one — so it does not
exercise the danger the block's own header names*** (`Immediate.lean:22-25`: a
mis-wiring that *"every structural measurement reports as perfect"*).

⚖️ **THREE THINGS KEEP THIS SMALL, and all three are in math's favour:**
* **The landing asserts nothing false.** `:7268` claims only that
  `sem_immICirc_word` refutes it — **true**, and it does so via output 0 on
  `addi x1,x0,1`, not via the out-of-range net.
* **`git grep "wf = false"` over `*.lean` is EMPTY** — no `wf` check actually
  runs on any mutant, so nothing in the repo is double-counting this control.
* ⭐ **The `B` side does NOT have this weakness.** `immBshiftedCirc` is
  well-formed, and `immBshiftedCirc_fails_the_theorem` (`:7280`) refutes it
  against a proposition **that did not exist before this commit**. *That control
  is strong, and it is the one guarding the bug the freeze actually shipped.*

📌 **A control that would exercise the named danger must read a bit in the
`rd`/`rs1` fields (7-19), which `wordI v` pins. None exists on the `I` side.**

---

## ✅ 5. WHAT THIS COMMIT DOES WELL — specifically, and I tried hard to break it

* ⭐ **THE SUPERSESSION IS GENUINE AND CORRECTLY NAMED.** `immI_correct_of_uncond`
  / `immB_correct_of_uncond` state `immI_OK = true` / `immB_OK = true`
  **verbatim** the existing certificates — same constants, no shadowing
  (one definition each). *Not a lookalike, not a weakening.* **The 8,192 kernel
  points really do become corollaries.**
* ⭐ **UNCONDITIONAL MEANS UNCONDITIONAL.** The word theorems take `(w : BitVec 32)`
  and **no hypothesis**; `sem_immICirc`/`sem_immBCirc` are stated at **arbitrary
  `E : Env`** — the shape `RegField`'s `∀ ins` can consume.
* ⭐ **NOT CIRCULAR — and this was the lens I expected to bite.** `bImmOf`
  (`:7099`) is character-identical to `decode`'s own B-reassembly
  (`ISA.lean:579-581`), **`ISA.lean` is untouched by this commit**, and
  `bImm_of_decode` discharges it against `decode`'s body. *The spec-facing
  conclusions mention `imm.signExtend 32` and `bOffset imm` — `ISA.step`'s own
  notions — not `bImmOf`.*
* ⭐ **CLAIM D IS PROVED, NOT EYEBALLED.** The off-family theorems quantify over
  **all `v : Nat`** — including `v ≥ 4096` where `BitVec.ofNat 12` wraps —
  through `encode_injective`; the lone `by decide` closes `(31 : Fin 32) = 1`,
  a field carrying no `v`.
* ⭐ **MY ADVERSARIAL CONSTRUCTION FAILED.** The best wrong circuit I could build
  — a net-≥32 leak passing every word-shaped theorem *and* the old 4096-point
  sweep — is killed by the arbitrary-`E` lemmas plus `sem_immBCirc_ignores_net32`
  (`:7073`). ***Those lemmas are doing real work, not bookkeeping.***
* **Audit coverage complete in both directions; 0 `sorry`, 0 `native_decide`.**

## 6. ⛔ NEEDS A BUILD — NOT RUN (another seat holds the lock)
1. **F1's proof-term receipt:** a scratch module *outside the repo* importing
   `SaltWorks.HDL.ISA`, printing `decode_encode`'s `getUsedConstants`, then
   `../saltbuild.sh`. *My verdict rests on the source-level argument, which is
   airtight given nothing in scope reduces `toReg (ofReg r)` for variable `r`.*
2. **F4's kernel receipt:** `example : immIoffCirc.wf = false := by decide +kernel`.
   *The arithmetic already settles it; the build only converts it to a receipt.*
3. **The two figures I cannot verify by reading — "≤3 axioms each" and
   "0 warnings":** `../saltbuild.sh SaltWorks.Stack.Program`, **checking the
   module reports `Built`, not `Replayed`.** *Both are whole-module readings that
   also certify the carried decoder section — wider than claimed, i.e. safe.*

## 7. Excluded on purpose
The `DecoderSemantics` carry itself (disclosed) and `core`'s absence (known).
**F3 is not the carry — it is that the published figures were never re-scoped.**
