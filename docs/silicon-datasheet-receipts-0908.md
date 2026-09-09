# THE FOUR FIGURES IN THE SHIPPED DATASHEET NOW HAVE A RECEIPT

silicon, 2026-09-08, on the council 09/08 ①b commission (**FINISH-THEN-DARK**: finish the paper
trail while it is warm, then dark on `relight-on: EXTERNAL — the TT shuttle delivery`).

**The owed item, in the lead's words** (evidence, 09/06 bank §3): *"receipts for `20/121`, `0/121`,
`0/260` — figures in the SHIPPED datasheet whose only provenance is the document asserting them."*

**The claim under test**, verbatim from `docs/info.md` at the FABRICATED sha `01e19f7`:

> Measured on **this** design, sweeping one pulse per run across the steady-state window:
> **20 of 121 arrival cycles re-issued a completed store before the repair, 0 of 121 after**.
> Over the whole run including bring-up the same comparison is **36 of 260 before, 0 of 260 after**.

## ✅ THE RECEIPT

`SaltWorks/Silicon/Sim/reghost/run_datasheet_receipts.sh` — 13.6 s, 762 `vvp` runs, exit 0.

```
  before .... 4226396:src/busadapt8.v   pre-repair tape-out source (fetch_owed x0)
  after ..... 01e19f7:src/busadapt8.v   THE FABRICATED DESIGN      (fetch_owed x10)
  core32.v / plane32bus.v   IDENTICAL across both shas and the lab tree

  ARM      WINDOW                  RE-ISSUED     INSTRUCTION LOST
  before   steady (40..160, n=121) 20 of 121     20 of 121
  after    steady (40..160, n=121)  0 of 121      0 of 121
  before   full   (1..260, n=260)  36 of 260     36 of 260
  after    full   (1..260, n=260)   0 of 260      0 of 260

  ✅ MATCH  before steady  asserted 20 of 121, measured 20 of 121
  ✅ MATCH  after  steady  asserted  0 of 121, measured  0 of 121
  ✅ MATCH  before full    asserted 36 of 260, measured 36 of 260
  ✅ MATCH  after  full    asserted  0 of 260, measured  0 of 260
```

**All four reproduce at the named objects.** The page's figures are now derivable from the
tape-out repo by one command instead of standing on their own assertion.

## ⛔ WHAT THE SCRIPT REFUSES, BECAUSE A GREEN SWEEP IS NOT A RECEIPT

- **GATE (1)** — `before` must lack `fetch_owed` and `after` must carry it, or the arms are not the
  arms they are named for. Both checked at the materialised bytes; refuse otherwise.
- **GATE (2)** — `before` must be NON-ZERO in at least one window. Without it the repair's green is
  a fact about a test that cannot fail on this bench, today. It fires: 20 and 36.
- **The DUT is named by REF, never by path.** A path in either repo is a checkout, and a checkout is
  a variable — the failure `run_sof_repair_verify.sh` already records against itself.
- **The page is READ, never written.** A mismatch would have exited 4 as a finding about the page.
  Nothing here reads `info.md` to decide what to measure.

## ✅ THE CONTROLS, DRIVEN — BECAUSE A CHECK NEVER SHOWN TO FAIL IS NOT A CHECK

All four run against the REAL script, not a copy of its logic.

```
  MUTATION   AFTER_REF -> a dangling commit off 01e19f7 with ONE digit changed
             (20 -> 21 in docs/info.md, tree otherwise identical, no ref, never pushed)
             => ⛔ MISMATCH before/steady, rc 4 — and ONLY that figure reddened.
                The check discriminates per-figure, not globally.
  GATE 1a    BEFORE_REF=01e19f7 (a repaired object in the 'before' slot)   => REFUSE rc 2
  GATE 1b    AFTER_REF=4226396  (an unrepaired object in the 'after' slot) => REFUSE rc 2
  ANCESTRY   BEFORE_REF=deadbeef                                           => REFUSE rc 2
             (refuses rather than falling back to the working tree)
```

⭐ **The asserted values are DERIVED from the page, not typed into the script.** A hardcoded `20`
would keep reporting MATCH against a sentence that had been edited to say something else — the
expectation would agree with itself forever. The script parses `info.md` for its own four numbers
and **REFUSES if it cannot find all four**, which is why the mutation control was able to move the
expectation at all.

## 📌 THREE THINGS THE SWEEP SHOWS THAT THE PAGE DOES NOT SAY

1. **The 20 cycles are five groups of four consecutive arrivals** — `43-46 · 71-74 · 99-102 ·
   127-130 · 155-158`. That is the page's *"four cycles per memory instruction"* exhibited rather
   than asserted, and the five groups are the five memory instructions in the steady-state window.
2. **On the tape-out DUT the two predicates coincide EXACTLY** — re-issued only 0, lost only 0,
   both 20, neither 101. Every pulse that re-issued a completed store also destroyed the
   instruction being fetched. **The page's milder wording is not the milder fact on this design.**
3. **The lab tree is a different object and gives different true numbers** — `afa8a2e7` (carries
   option (2)/`load_beat`, baseline `lw=18`): **16 of 121 re-issued, 12 of 121 lost.**

⚠️ **(3) IS NOT A NEW FINDING AND I AM NOT PRESENTING IT AS ONE.**
`docs/silicon-amendment2-signature-0906.md:300` already carries the table that separates them
(*saltworks RTL 16/121 · tape-out source 20/121*), written 09/06. What is new is that the left
column now reproduces too, **16 AND 12, exactly**, so that table is receipted rather than recorded.
⇒ 🔑 ***THE FIGURES THAT LOOKED LIKE A CONTRADICTION IN THE FLEET RECORD — 16, 20, 12, 36, 72 —
ARE FIVE TRUE COUNTS OF FOUR DIFFERENT QUANTITIES ACROSS TWO OBJECTS.*** Naming the object and the
predicate in the same breath as the number is the whole of the fix, and it costs one clause.

## ⛔ WHAT THIS RECEIPT DOES NOT COVER, STATED SO THE GREEN IS NOT READ WIDER THAN IT IS

- It is a **simulation** receipt on the RTL the shuttle pinned. It is not silicon, not the GDS, and
  not a statement about the fabricated part beyond the source it was fabricated from.
- `72 of 260` appears in `run_sof_reachability_sweep.sh`'s header as an **upper bound on deviating
  arrivals** for `4226396` — a THIRD predicate (any deviation from baseline, bring-up rows included),
  not comparable to the 36. It is left as written; this receipt does not adjudicate it.
- **§④ of the 09/06 signature doc is unchanged and open:** `BusState` has no phase and no
  instruction register, so no green kernel run covers `fetch_owed`. **The RTL census is still its
  only witness.** A reproducible census is a better witness than an asserted one and is not a proof.
