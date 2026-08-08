# README / DATASHEET — THE PREPARED BLOCKS, ready to paste

### 2026-08-07 ~17:1x, SILICON. The maestro ratified the firewall halt and ruled:
### **ship our own render alone, cite Figure 6 IN WORDS with a full citation and
### an invitation to the original.** These are those blocks.

⛔ **READ THIS FIRST — WHAT MUST *NOT* CHANGE YET.** The revision branch's
`project.v` is a **declared KB4 hardening probe**: the Batcher's act/data
vectors do not match the banyan's interleaved frame, `bo[15:8]` (the sorter's
activity outputs) go to `_unused`, and the bench drives **already sorted and
concentrated** stimuli. ⇒ ***The identity claims — the title, "this chip is the
proved half", "the Batcher is not on this chip" — STAY AS THEY ARE until B4's
silicon half closes.*** **Blocks ① and ③ below are true today. Block ② is true
today. None of them assert composition.**

---

## ① THE HERITAGE BLOCK — words only, no figure reproduced

*Drop into `README.md` after the opening paragraph, and into `docs/info.md`
under "How it works".*

> ### The 1990 silicon
>
> This is not a new architecture. In 1990 Bellcore built it, and measured it.
>
> **W. S. Marcus and J. J. Hickey, "A CMOS Batcher and banyan chip set for
> B-ISDN," *1990 IEEE International Solid-State Circuits Conference, Digest of
> Technical Papers*, pp. 32–33 (session WPM 2.4), DOI
> [`10.1109/ISSCC.1990.110116`](https://doi.org/10.1109/ISSCC.1990.110116)** —
> with the journal version as **"A CMOS Batcher and Banyan chip set for B-ISDN
> packet switching," *IEEE Journal of Solid-State Circuits* **25**(6):1426–1432,
> December 1990, DOI [`10.1109/4.62170`](https://doi.org/10.1109/4.62170)**.
>
> That chip set was **measured at 170 Mb/s per bit-serial link**, against a
> 155.52 Mb/s SONET STS-3c requirement, for **5.44 Gb/s aggregate across 32
> channels**. It was **1.2 µm CMOS**, a single 5 V supply, about **1.5 W**, in an
> **84-pin LCC**.
>
> The switching elements are US Patent **5,130,976**, "Batcher and Banyan
> Switching Elements" (J. J. Hickey and W. S. Marcus, filed 1991-02-12, granted
> 1992-07-14). The network architecture is US Patent **4,910,730**,
> "Batcher-banyan network" (C. M. Day Jr. and J. N. Giacopelli, filed
> 1988-03-14, granted 1990-03-20).
>
> **The ISSCC paper's Figure 6 is a micrograph of the Batcher die**, and it is
> worth looking up: the architecture is legible directly off the silicon — an
> input column, then the switch-element fabric as countable vertical cell-column
> stripes separated by wiring channels, then a latch column, a mux, and an output
> column, inside a pad ring. **We reproduce no part of it here; go and read the
> paper.**

### ⚠️ THREE CITATION FENCES — carry these with the block

1. **Never cite US 4,910,730 for numbers.** It contains **no process node and no
   155 Mb/s figure** — only a background "100 megabits/sec" goal. Architecture
   citation only.
2. **"1 µm at 155 Mbit" is two chips merged.** **1.2 µm** is the chip set above.
   **1 µm** is a different part: J. J. Hickey (solo), "A 50 MIP ATM Cell
   Processor for B-ISDN," *IEEE CICC 1992*, Xplore doc `5727353` — 1 µm,
   **622 Mbit/s** (STS-12c), 50 MHz instruction rate.
3. **`papers-bellcore-arc/BIBLIOGRAPHY.md` still carries a `MAY BE TRUNCATED`
   warning on the ISSCC author list.** The bus retired that on 8/6 18:37 — the
   list is confirmed **complete** (Marcus & Hickey). **The file is stale, not the
   fact.**

📌 **The PDFs on the shelf are IEEE Xplore downloads stamped
`Authorized licensed use limited to: GOOGLE … Restrictions apply.`** *Reading
them to verify numbers is clean internal use. **Publishing any image or extended
quotation from them is not**, and the right to reuse Figure 6 — which plausibly
exists, because JYH is an author — is the Captain's to invoke, by a personal-lane
route, never by cropping the file on this disk.*

---

## ② THE SPEED TABLE — the revision's datasheet currently carries the FLOOR's
## numbers, and they are wrong for this tile

⛔ **`docs/info.md` on `revision-bb1-composed` says "89 Mbit/s per link (102
typical)" and "zero setup violations, zero hold violations".** *Those are `main`'s
figures.* **Measured on the composed tile (run `31226766476`, post-PnR signoff
STA, `55-openroad-stapostpnr/summary.rpt`):**

> ## Speed — three different numbers, and they are not interchangeable
>
> | | rate | what it is |
> |---|---|---|
> | **the logic** | **42.6 Mbit/s per link** (61.1 typical, 75.1 fast) | post-place-and-route signoff STA at the slow corner `ss_100C_1v60`. The fabric is bit-serial, so MHz *is* Mbit/s per link |
> | **this chip** | **25 Mbit/s per link** | what `info.yaml` requests — a **pad** limit, not a core limit: TinyTapeout's output pad tops out near 33 MHz, and a bit-serial fabric toggles every output every cycle |
> | the harness | shared | the demo rate is set by the pinout and the board, not by the fabric |
>
> Signoff across all nine corners: **hold is clean everywhere** — worst hold slack
> **+0.11 ns**, zero hold violations. Hold is the number worth quoting, because
> lowering a clock fixes setup and does nothing for hold: a design can be "run
> slower" out of a setup problem and never out of a hold one.
>
> Setup carries **24 violations at the slow corner against the 20 ns hardening
> constraint** — a 50 MHz the design does not claim. At the **25 MHz this chip
> declares**, the slow corner closes with about **16.5 ns of margin**.

📌 **The 33 MHz pad figure is INHERITED from the existing datasheet, not
re-measured by me.** *It is consistent with what I did measure — the logic runs
42.6 MHz at the slow corner, above the pad — so the pad is the binding limit and
25 MHz is a pad-driven choice with the logic comfortably clear of it.*

---

## ③ THE DIE BLOCK — our render alone

*Drop into `docs/info.md` after "How it works", with the `gds_render` image.*

> ### What the die looks like, and what it does not show
>
> The 1990 Batcher die is **legible**: Figure 6 of the ISSCC paper cited above
> shows an input column, countable cell-column stripes for the fabric, a latch
> column, a mux, and an output column. You can read the architecture off the
> photograph.
>
> **Ours you cannot**, and the honest reason is not one thing but two. The logic
> is auto-placed by an open-source flow that has no notion of "column" — and it
> is placed at about **15 % density** on a tile bought with headroom, so the
> placer had no pressure to organise anything at all. What you see is a wedge of
> standard-cell rows in the upper part of the die and a large field of tap and
> decap filler below it. Cell rows are visible; architectural columns are not.
>
> We tried to get the columns back and did not. OpenROAD honours placement fences
> through DEF `REGIONS`/`GROUPS`, but a TinyTapeout submitter cannot inject a DEF
> — the flow writes its own `FP_DEF_TEMPLATE` last, and it wins. Placement
> obstructions *were* accepted without complaint and simply did not produce
> columns.
>
> **The 1990 die is readable because a person placed every column, on a die that
> was full. This one is a jumble because a tool placed it, sparsely, with no
> reason to do otherwise. What you can read off this die instead is a proof.**

---

## What these blocks do NOT do

* They do **not** claim the tile composes. Block ① is heritage, ② is timing,
  ③ is a picture. **None asserts that the Batcher sorts for the banyan**, because
  on this branch it does not.
* They do **not** touch `main`. The floor's README stays as it is.
* The f_max figures are **signoff STA, not silicon**; the 1990 figures are
  **measured on fabricated parts**. *Any comparison must keep that asymmetry
  visible — we are putting our simulation next to their measurement.*
