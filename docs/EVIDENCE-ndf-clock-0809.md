# THE NDF CLOCK — T0, baseline, and the cost table actualized

**EVIDENCE seat probe, council ruling #7 (2026-08-09 11:27).**
*Assignment, verbatim: "the claim fence is armed and the NDF CLOCK STARTS AT THIS
RULING: baseline token/day readings TODAY; the story doc's cost table is yours to
actualize at each gate."*

---

## ⏱️ T0 — STAMPED AT THE RULING, NOT RECONSTRUCTED

```
NDF T0 = 2026-08-09 11:27:29 PDT
```
*Captured by `date` in the same command that wrote this record. **NDF spend at T0
is ZERO BY CONSTRUCTION** — that is what starting a clock means, and it is the
one figure that can never be recovered if the stamp is taken later.*

## 📊 BASELINE TOKEN/DAY — MEASURED, output only

**Instrument:** `docs/ledger-tools/token_meter.py`, all five seat roots,
deduplicated by requestId. **Frozen rule, `measurement-preregistration.md` §1:
*cache is always its own column and never enters a headline number.*** Every
figure below is OUTPUT tokens.

```
DAY          requests    OUTPUT tokens
2026-08-05         24           22,571   (T0 of the triple campaign, 22:00 only)
2026-08-06      9,223        5,029,793
2026-08-07      7,246        5,984,890
2026-08-08      9,949        8,320,577   ← the overnight full-throttle day
2026-08-09      2,374        2,030,002   (partial: to 11:27)
CAMPAIGN       28,816       21,387,833
```

⇒ **BASELINE RATE, stated as a range rather than a mean, because three points
with a trend is not an average:** *5.0M → 6.0M → 8.3M output tokens/day across
8/6–8/8, **rising**. The 8/8 figure includes the Captain's 40% overnight
full-throttle grant and is the high-water mark, not the norm.*

⚠️ **I AM NOT PROJECTING A SEPTEMBER TOTAL FROM THIS.** *Three days, a rising
trend, one of them explicitly abnormal, and a scope (NDF) that did not exist
until today. **A projection needs a measured slope over the thing being
projected**, and the NDF has produced zero days of its own. The first honest NDF
rate reading is available 2026-08-10.*

## 💰 THE COST TABLE — ACTUALIZED, AND THE PLACEHOLDER IS OFF BY ~19×

`midnight-to-silicon-story.md:93-97` carries:

```
| item        | placeholder | actual (evidence-fenced, TBD)            |
| design      | ~2 days     | dream 08-09 03:00 → package same morning |
| tokens      | ~20M        | evidence seat owns the measured figure   |
| fabrication | ~$500 (TT)  | actual invoice when submitted            |
```

⛔ ***THE `~20M` PLACEHOLDER MATCHES THE WHOLE TRIPLE CAMPAIGN (21.4M), NOT THE
STORY THIS TABLE SITS IN.*** *The story scopes itself in its own adjacent row —
**"dream 08-09 03:00 → package same morning"** — and I measured exactly that
window:*

```
DREAM WINDOW   first request 2026-08-09 03:06 · last 11:27 (the ruling)
               1,423 requests
               OUTPUT: 1,136,516 tokens        ← the story-consistent figure
CAMPAIGN       OUTPUT: 21,387,833 tokens       ← what ~20M actually matches
RATIO          18.8×
```

🔑 ***So actualizing `~20M` with the campaign total would attribute FOUR DAYS OF
RISC-V, HDL AND PROOF WORK to a story about one morning's dream.*** *Not by
anyone's dishonesty — by a placeholder and a measurement meeting at the wrong
scope, which is the most ordinary way a wrong number gets published.*

### ✅ THE ROW AS I WOULD WRITE IT

```
| tokens | ~20M | 1.14M output (dream 03:06 → ruling 11:27, 1,423 requests,
|        |      | measured by token_meter.py over 5 seat roots, cache excluded).
|        |      | NOT the campaign's 21.4M — that window is 4 days and 3 other
|        |      | projects wide. NDF spend from T0 is separate and starts at 0.
```

📌 **AND THE SCOPE MUST TRAVEL WITH THE NUMBER, because this table has THREE
defensible windows and they differ by 19×:**

```
(a) the dream → the ruling      1.14M   the story's own framing
(b) NDF from T0 forward         0 → …   the September build's true cost
(c) the whole triple campaign   21.4M   everything, including the RISC-V stack
```
***Whichever the Captain wants, it must be NAMED in the cell. A bare "1.14M" in a
cost table is the same defect as a bare "~20M" — a number whose window a reader
must guess.*** I recommend **(b) for the September cost question** and **(a) for
the story**, and they are different rows, not competing answers.

## 🔁 THE GATE DUTY

*The ruling says the table is mine to actualize **at each gate**. So:*
- **Every gate: re-run and re-date.** These figures rot within hours — the 8/9
  row grew while this document was being written.
- **Report OUTPUT and state that cache is excluded** — cache read is 9.67 G and
  quoting it would inflate the story by ~450×.
- **NDF-from-T0 is the only figure that answers "what did the NDF cost".**
  Everything else answers a different question, and answering the wrong one
  confidently is the failure this seat exists to prevent.
