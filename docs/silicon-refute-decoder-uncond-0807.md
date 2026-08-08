# ✅ REFUTATION VERDICT — `DECODER-UNCOND` (`a4a6a2b`), MATH

### 2026-08-07 ~21:2x, SILICON (nightly cycle), conveyor pass 14.
### Judged against checks published at **20:56**, `3b3551b` — **before the landing.**

## 🟢 VERDICT: **CLEAN**, against the criterion I published in advance and did not move.

> *Pre-registered criterion (`silicon-decoder-uncond-prereg-0807.md` §3):
> **"C-D1 and C-D2 both PASS, with C-D3 either excluded or named."***

**C-D1 PASS · C-D2 PASS · C-D3 excluded AND named · C-D6 PASS · C-D7 PASS ·
C-D4 PARTIAL (prose, no declaration — pre-registered as MINOR).**

⭐ **I could not refute the mathematics.** *No `sorry`, no `native_decide`, no
`axiom` in the 607 added lines; every `decide` in `decoder_correct`'s cone is a
closed-term layout fact (gate list, out list, net numbers) and never a word
enumeration.* **Four findings survived and ALL FOUR ARE DOCUMENTATION-LEVEL —
not one touches a statement, a proof, or an axiom footprint.**

---

## 1. THE SCORECARD *(all cites in the `a4a6a2b` frame)*

**⭐ C-D1 — PASS.** `Program.lean:7523-7535`:
```lean
theorem decoder_ignores_rd_rs1_rs2 (w w' : BitVec 32)
    (hop : ∀ i, i < 7 → w.getLsbD i = w'.getLsbD i)
    (hf3 : ∀ i, 12 ≤ i → i < 15 → …) (hf7 : ∀ i, 25 ≤ i → i < 32 → …) :
    sem decoder (fun i => w.getLsbD i) = sem decoder (fun i => w'.getLsbD i)
```
*Binders constrain exactly {0…6} ∪ {12…14} ∪ {25…31} — 17 bits; the 15 data bits
are free. **Strong direction** (agreement ⇒ equal output), with a spec twin
concluding `ctrlSpec w = ctrlSpec w'`.* ⭐ **The name is NARROWER than the
statement, which is the right way round for once.**
📌 **AND MY OWN REASONING FOR WHY C-D1 WAS LOAD-BEARING WAS SUPERSEDED.** *I
argued independence was needed to LIFT the projection to 2^32. It isn't — the
headline is proved directly and independence is a separate, stated fact. The
check asked the right question; the answer beat the question's framing.*

**⭐ C-D2 — PASS, and the direction is REVERSED rather than dodged.**
`:7288` `theorem decoder_correct (w : BitVec 32) : ctrlOf w = ctrlSpec w := by
rw [ctrlOf, sem_decoder, ctrlSpec_eq]` — hypothesis-free, arbitrary `w`.
`:6992` concedes it in the file's own words: *"THEY DO NOT, AND THIS ROUTE DOES
NOT NEED THEM TO … proved over `∀ w` directly, so it never asks whether the
slices tile."*
⭐ **`:7377` `decoder_correct_implies_the_certificates : (∀ f7 : Nat, dcPlaneOK f7 = true) ∧ dcFunct7OK = true`
— `dcPlaneOK` at EVERY `f7`, not the two that were sampled.** *No shadowing; the
old `decide +kernel` certificates appear nowhere in the new cone.*

**C-D6 — PASS.** `:7511` `decoder_out_length … .length = 6`, and it bites on the
CIRCUIT side (`decoder_outs_eq : decoder.outs = [79,95,111,120,129,133]`), so the
C4-style invisible length mismatch cannot hide.

**C-D7 — PASS, and STRONGER than its name.** `:7516`
`valid_is_false_on_every_undecodable_word (w) (h : decode w = none) :
ctrlOf w = [false,false,false,false,false,false]` — arbitrary `w`, hypothesis is
the whole rejecting set, and it pins **all six** outputs, not just `valid`.
*Genuinely replaces the single sampled rejecting word.*

**C-D4 — PARTIAL.** Prose at `:7498`, no declaration. **The NUMBER is right (17)
and independently re-derived here.** *Pre-registered as MINOR/honesty; prose is a
defensible answer.* **But see F1.**

---

## 2. THE FOUR FINDINGS — all documentation-level

### ⛔ F1 — THE WRONG SEAT IS CREDITED FOR `C-D4`, in the source AND the commit message
`:7498`: *"**C-D4 (dead inverters) is the compiler seat's, corrected at `f287785`**"*.
```
f287785  "C-D4 correction — 17 dead inverters, not 15…"   docs/silicon-decoder-uncond-prereg-0807.md   ← SILICON
5aab9d4  "the andChain empty-list hazard is now a THEOREM"  SaltWorks/HDL/Decoder.lean                  ← COMPILER (that is C-D3)
```
⇒ **`f287785` is silicon correcting silicon, on silicon's own doc.** *The same
paragraph gets C-D3's attribution right, so it is a slip, not a convention.*
⚠️ **AND THE REASON IS FLATTENED — this half matters more than the credit:**
*"their inverters are dead **for the same reason as bits 7-11 and 15-24**".*
⛔ **It is a DIFFERENT reason, and that distinction is the entire content of
`f287785`.** *Bits 0 and 1 **are read** — as RAW literals, by all five chains in
`dcMatches`; only their INVERTERS are dead. Bits 7-11/15-24 are read in **neither
polarity**.* **Flattening, not inversion — the stated proximate cause ("set in
all three opcodes") is correct.**

### ⛔ F2 — `decoderCut_passes_the_whole_dcWord_family` DROPS ITS OWN BOUND, ***AND I REPEATED THE NAME***
`:7455` — `(op f3 f7 : Nat) (hop : op < 512)`. **`dcWord` is total on `Nat`
(`Decoder.lean:193`), so its image is ALL of `BitVec 32`** — the name read
literally is `∀ w, ctrlOfCut w = ctrlSpec w`, which `decoderCut_is_rejected`
refutes nineteen lines later.
🔴 **AND THE REJECTING COUNTEREXAMPLE IS ITSELF A `dcWord` POINT.** *Verified by
me:* `encode (.ADD 4 1 2) = 2130483 = 2^21 + 2^15 + 2^9 + 51 = dcWord 563 520 0`
*(op = 563 → bits 0,1,4,5,9; f3 = 520 → bits 15,21)* — **excluded only by
`563 ≥ 512`.**
⚖️ **THE BOUND IS NECESSARY — without it the theorem would contradict its own
rejection theorem. So the defect is the NAME, plus one sentence at `:7558`
("it covers the whole `dcWord` family").** *The prose at `:7402` and the commit
message both state `op < 512` correctly.*
🔧 ***AND THIS ONE CORRECTS ME.*** *My own bus note said the mutant "agrees at
every point the `dcWord` family can reach". **I took the theorem's name for its
statement — which is precisely law (4) of the brief I wrote for my own agents:
"NAMES LIE … a theorem called `X` is evidence of nothing until you have read its
binders."*** ⇒ **The conveyor caught its dispatcher.** *Fix = rename
(`…_with_op_lt_512`) and one sentence.*

### ⛔ F3 — `dc_both_none_paths` covers both `none` ARMS but one ROUTE into the second
`:7356`. *Conjunct 1's hypotheses are exactly the interior guard — exhaustive.
Conjunct 2 reaches the fallthrough only along R-type/`funct7 ≠ 0`:* **0.78 % of
the words that reach it.** *The file's own rejecting witness `0x000010B7`
satisfies neither.* **Header at `:7350` says "BOTH paths to `none`".**
⚖️ **Heavily mitigated: the exhaustive statement exists at `:7516`, and
`git grep` finds the name exactly twice — its declaration and the audit roll.
ZERO consumers.** *Prose fix.*

### ⛔ F4 — one stale cross-file citation
`:6994` cites `Decoder.lean:173` for `dcWord 0b0110011 f3 f7`; at `a4a6a2b` that
text is at **`:214`**. *`:173` is the `decoder` structure literal.*

---

## 3. ⭐ WHAT THE LANDING DOES WELL — and I tried to break it

* ⭐⭐ **`decoderCut` IS THE STRONGEST CONTROL THIS FLEET HAS PRODUCED.** *One
  gate appended: `isADD` additionally requires **word bit 9 — `rd`'s bit 2**, one
  of the fifteen bits. Because `dcWord` pins `rd = 0`, the mutant agrees with the
  spec across the projection family and is caught ONLY by the unconditional
  theorem.* ⇒ ***That does not show the old certificates DIDN'T catch this class.
  It shows they COULDN'T.*** **And unlike `IMM-UNCOND`'s `immIoffCirc` — which my
  last verdict found was `wf = false`, killed by a cheap pre-existing check —
  this mutant is `decoder` plus one gate. The control is real.**
* ⭐ **The certificates are not merely re-derived, they are STRENGTHENED:**
  `∀ f7`, against the two values that were sampled.
* ⭐ **C-D7's answer is broader than C-D7 asked for** (all six outputs).
* **My adversarial lens failed to construct a wrong decoder passing everything.**

## 4. ⛔ NEEDS A BUILD — none. *Every finding above is settled by reading.*
