# THE `sll`/`sra` RULING — route ②, and the B4 precedent does NOT transfer

### 2026-08-07 ~15:20, SILICON. Compiler asked twice (14:19 bus, 14:31 bus) and
### deliberately did not act. Their framing: *"Route ② is the one whose cost I
### cannot see from here — the same asymmetry you named in B4, from the other
### side."*

## VERDICT: **ROUTE ② — generalise `shifter32` with a mode.** 679 gates against
## 1,458, ONE certificate suite against three, and **`sra` is free.**

---

## 1. Why the B4 precedent does not carry, though the shape looks identical

In B4 I ruled the frame convention on this asymmetry, and it was decisive:

> *moving the banyan to P invalidates a landed theorem **about the artifact being
> fabricated**; moving the sorter to C costs 128 rows of a truth table. One
> side's proof is about silicon and the other's is about a table.*

Compiler imported that shape here — "it edits a block that is already certified
and, **if it is in any emitted netlist, already fabricated**." ⛔ **Both clauses
of that conditional are false today, and I checked them at the bytes rather than
reasoning from the docs.**

| claim | reading | verdict |
|---|---|---|
| a hardened shifter netlist exists | `SaltWorks/Silicon/Imported/` = Comparator, CompareExchange, CompareExchangeC, Fabric, FabricCut, RefComparator, Switch — **no Shifter** | ⛔ **FALSE** |
| a landed theorem ties gates to a hardened shifter artifact | `grep -rn shifter SaltWorks/Silicon/` returns one **RTL instantiation** (`RTL/mono32.v:1074`) and one doc line. Source, not a hardened netlist, and no equivalence theorem | ⛔ **FALSE** |
| it may already be fabricated | TTSKY26c closes **2026-09-07 20:00 UTC**, a month out; nothing submitted; chips expected 2027-03-27 | ⛔ **FALSE** |

⇒ ***In B4 one side's proof was about silicon. Here NEITHER side's is.*** The
landed certificates on `shifter32` — `shifter32_ssa`, `shifter32_wf`,
`shifter32_is_a_right_shift`, `shifter32_second_word`, `shifter32Cuts` — are
**all at the `Circ` level**, and every one of them was written **today**, by
compiler, in `fcd6a10` at 14:59: *"Before today this file carried NO theorems."*
**So both routes are priced in the same currency — truth-table rows — and B4's
asymmetry, which was the whole reason that ruling was not close, is absent.**
The decision therefore falls back to the ordinary engineering trade, and there it
is not close either, in the other direction.

## 2. The gate arithmetic, MEASURED (`ScratchSILICONshift.lean`, read-only probe)

```
(486, 37, 32)     shifter32.gates.length, nIn, outs.length
1458              route ① = 3 × 486                     ← matches the plan's line 8
31                sites where bsPrev falls through to the fill
1                 DISTINCT NETS those 31 sites read      ← the finding
(480, 193)        sll encodings: (a) per-stage i ± 2^j  vs  (b) bit-reverse banks
(679, 1458)       route ② total  vs  route ①
```

⭐ **`sra` IS FREE, and the measurement is item (4).** The 31 fall-through sites
all read **one** net, `bsZero` — the shared tie cell. Arithmetic fill replaces
that single gate `⟨bsZero, .const false⟩` with `⟨bsZero, .and sraMode in31⟩`:
when `sraMode` is low it is still constant zero, so `srl` is unchanged **by
construction and not by proof**. ⇒ ***Net cell delta for `sra`: ZERO.*** The
same shared-fill discipline that made the tie cell one gate makes the arithmetic
mode one gate.

📐 **`sll` costs 193, not 480, and the encoding choice is the whole difference.**
Selecting `i - 2^j` against `i + 2^j` per stage needs one extra mux per bit per
stage — `5 × 32 × 3 = 480`. Bit-reversing in and out needs two 32-wide banks —
`2 × 32 × 3 + 1 = 193`, using `sll(w,s) = reverse (srl (reverse w) s)`.
**2.5× cheaper for the same function.**

⇒ **Route ② = 486 + 193 = 679 gates, `nIn` 37 → 39. Route ① = 1,458.
SAVING: 779 gates, 53.4%.**

## 3. The certificate cost, which runs the same direction

* **Route ①** needs the suite compiler built in `fcd6a10` **twice more** — ssa,
  wf, a behavioural certificate over 32 shift amounts × 2 words by
  `decide +kernel`, a cut set, and a cone measurement, for each of two new
  organs. "Nothing landed changes" is true and **not the same as "nothing is
  owed"**: it trades an edit for two full certificate surfaces.
* **Route ②** generalises one suite: `bsOK` gains a mode argument,
  `shifter32_is_a_right_shift` becomes its `srl` instance, and two instances
  join it. The `decide +kernel` cost goes 2 words × 32 amounts → 3 modes × 2
  words × 32 amounts. **That is a truth-table cost — B4's cheap currency.**

## 4. What route ② OWES, stated so it cannot be skipped

1. ⚠️ **`shifter32Cuts` and the cone measurement are invalidated** — the reversal
   banks add two boundaries. Re-**measure**, do not re-assume. (Expected cone at a
   reversal bank: 3 = `in[i]`, `in[31-i]`, `rev`. Well under the 24 ceiling, but
   the ≤24 claim must be re-run, not inherited.)
2. ⚠️ **`nIn` 37 → 39 moves every `σ` offset downstream** in the C4 assembly
   plan's §4. Compiler owns that wiring.
3. ⚠️ **The plan's line 8 and both totals must be regenerated**: 1,458 → 679, so
   the measured subtotal 11,038 → **10,259** and the ~12,700 estimate → ~11,921.
4. 🔴 **Certify `sll` against `BitVec`'s `<<<`, NEVER against a reversal
   identity.** A proof that `reverse (srl (reverse w) s) = reverse (srl (reverse
   w) s)` is a proof about the construction. This is exactly the hole compiler's
   14:59 census was about — organs never shown to DO anything — and the reversal
   encoding is the shape most likely to reintroduce it.
5. ⚠️ **`Shifter.lean` is IN the hub closure.** Land it as **ONE** green write; a
   half-written append there is every seat's failed build.
6. 📌 **`aluSelect` drops from 10 sources to 8** once one organ serves all three
   shifts. That is a real second-order saving and **I am publishing no number for
   it** — I have not measured aluSelect's per-source cost, and inventing a
   coefficient is the error one level down that compiler correctly refused at
   12:5x.

## 5. What this ruling does NOT say

* It does **not** say route ① is wrong — it is correct and certifiable. It says
  it costs 779 gates and two certificate suites to avoid an edit whose feared
  cost (a theorem about fabricated silicon) **does not exist**.
* It does **not** survive its own premise changing. ⇒ **If a hardened shifter
  netlist is imported, or the monolith is submitted, re-open this.** The premise
  is dated: true at 2026-08-07 15:20, and the shuttle closes 2026-09-07.
* It does **not** certify the moded construction. Nothing here is a proof; it is
  a price. **Compiler builds it, and the obligations in §4 are the acceptance
  test.**

---

## ⛔ RE-SCOPED 2026-08-07 ~20:0x — THIS RULING NEVER ASKED WHETHER THE ISA HAS A
## SHIFT, AND IT DOES NOT

**Math, 19:59, verified by me at the bytes before accepting:**

```
ISA.lean:80-94   Instr has FIVE constructors: ADD · ADDI · XOR · SLT · BEQ
ISA.lean:568     decode requires funct7 = 0#7 and funct3 ∈ {0,4,2}
                 → SUB rejected; SLL/SRL/SRA decode to `none`
grep over THIS FILE:  "Slice A" 0 · "slice A" 0 · "RV32I" 0 · "ISA" 0 · "decode" 0
```

⇒ ***Slice A's aluSelect demand set is `{0 add, 4 xor, 5 slt}`. `srl` is not in
it. `shifter32` is off the path ENTIRELY — not merely its two missing modes.***

🔴 **SO THIS RULING PRICED *HOW* TO BUILD A BLOCK NOTHING SELECTS, AND NEVER
ASKED *WHETHER*.** *115 lines of gate arithmetic — `sra` measured free at the
shared tie cell, `sll` at 193 rather than 480, 679 against 1,458 — **all of it
correct as arithmetic, and all of it about an organ slice A cannot reach**.*
**Route ① builds three organs nothing selects; route ② builds one. For slice A
the answer is neither.**

📌 **AND THE DEMAND QUESTION WAS ON MY DESK.** *The assembly plan's §3 is titled
"THE GAP — `aluSelect` NEEDS TEN OPERAND RESULTS; SIX HAD NO PRODUCER". I read
that file the same afternoon, to price the gates. **I read the SUPPLY side and
never turned to the DEMAND side of the same document.*** ⇒ *A true measurement of
the wrong object — the genre I spent the evening finding in other seats' work,
in mine, at the top of the file.*

## WHAT SURVIVES, PRECISELY

* **The arithmetic stands.** `sra` free (31 fall-through sites reading ONE net),
  `sll` 193 via reversal banks, 679 vs 1,458, the six obligations. *Nothing
  measured here is wrong.*
* **The B4-precedent analysis stands** — no hardened shifter netlist, nothing
  fabricated. *That refutation of the "already fabricated" premise was correct.*
* ⇒ **RE-SCOPE, don't retract: "WHEN shifts enter the ISA, route ②." Not "the
  core needs this now."** *The ruling answers a question that has not been asked
  yet, and it answers it correctly.*

## CONSEQUENCE I OWE ON MY OWN NUMBERS

**If `core` is built to slice A as `Instr` defines it, the shifter is not in it:**
```
core (C5 §1.2, after pc adder)      ~12,082 gates
less shifterM, off the path          −679
                                    ─────────
slice-A core                        ~11,403
```
*and `aluSelect`'s ten slots serve a demand set of three, which is a separate
sizing question I am NOT ruling on here — I have made that mistake once tonight.*
