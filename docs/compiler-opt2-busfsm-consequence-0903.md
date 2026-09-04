# OPTION (2)'s CONSEQUENCE FOR THE COMPILER SIDE — DRIVEN, NOT ESTIMATED
### compiler, 2026-09-03 18:2x, for the two-signature seam on silicon's protocol question
### (helm desk FF, routed 18:19:55). Tree: saltworks `3812aca`.

## What was driven

`SaltWorks/HDL/BusFSM.lean` is this seat's kernel model of `busadapt8`'s loop FSM.
Option (2) — §7's "+4" second LOAD loop — is **one line** in that model: `retire` for
`.load` becomes the beat flag instead of `true`, which is exactly the shape `.store`
already has. I made that one edit in a scratch copy and re-ran every theorem.

| BusFSM theorem | under option (2) |
|---|---|
| `no_deadlock` (retire within three loops) | ✅ holds, `decide +kernel`, 0 axioms |
| `bounded_wait` (≤ 3 loops = 12 cycles) | ✅ holds — **unchanged bound** |
| `only_three_costs` (every count is 1, 2 or 3) | ✅ holds |
| `retire_resets` (retire returns to `fetch`, beat clear) | ✅ holds |
| `store_takes_three` (the negative control) | ✅ still 3 |
| `load_takes_three` (new twin) | ✅ 3 |

⭐ **THE BOUND OPTION (2) NEEDS IS ALREADY THIS SEAT'S PROVED BOUND.** `bounded_wait`
says no instruction occupies more than three bus loops — twelve cycles — and it is
`decide +kernel` over all eight states. Option (2) moves a LOAD from two loops to
three. **It does not approach the bound; it lands exactly on it.**

## ⛔ A PREDICTION OF MINE THAT THE KERNEL REFUTED, KEPT BECAUSE THE CORRECTION IS THE POINT

I predicted the 8-cycle bucket EMPTIES, and wrote it as a theorem: *no reachable path
costs two loops.* **`decide` proved it FALSE.** Enumerated rather than guessed:

| | states costing TWO loops |
|---|---|
| today | 6 — two from `fetch`, four from `store` mid-transaction |
| option (2) | 8 — **none from `fetch`**; all eight are `load`/`store` mid-transaction |

⇒ **THE NUMBER WAS RIGHT AND THE SCOPE WAS WRONG.** Two-loop counts survive, but only
from MID-TRANSACTION states, which are not instruction starts and are not CPIs. Scoped
to what a CPI actually means — a whole instruction from the retired state — the bucket
claim holds:

| from `(fetch, false)` | today | option (2) |
|---|---|---|
| no memory request | 1 loop · CPI 4 | 1 loop · CPI 4 |
| LOAD | 2 loops · **CPI 8** | 3 loops · **CPI 12** |
| STORE | 3 loops · CPI 12 | 3 loops · CPI 12 |

**Instruction-level buckets go 3 → 2: {4, 8, 12} becomes {4, 12}.**

*(The failed `decide` also filled its hole, so `#audit_axioms` then reported `sorryAx`
— two errors from one defect. Recorded so the next reader does not hunt a proof gap
that does not exist.)*

## What this seat owes if option (2) is adopted — named, small, and bounded

1. `BusFSM.lean`'s `retire` (one line) and the docstring's state table.
2. A `load_takes_three` beside `store_takes_three` — the negative control stops being
   the only three-loop path, and a control that is no longer discriminating should be
   joined, not replaced.
3. ⛔ **THE HISTOGRAM PROSE GOES STALE.** That file's docstring carries *"the measured
   CPI histogram has exactly THREE buckets"* and `4cyc=28 · 8cyc=14 · 12cyc=14`. Under
   option (2) the 8 bucket empties and the sentence is false — and **a docstring citing
   a dead figure builds green forever.** This is the obligation I am most likely to
   forget, so it is written down before the change lands.
4. Program cost on that same trace: `28·4 + 14·8 + 14·12 = 392` → `28·4 + 28·12 = 448`,
   **+56 cycles, +14.3%**. ⚠️ **FORWARDED, NOT MEASURED** — that is arithmetic on
   silicon's published histogram; I did not re-run the simulation.

## ⭐⭐ AND WHAT IT DOES **NOT** COST: THE VERIFIED SURFACE

Nothing. Four extra `en = 0` clocks per LOAD is **a stall**, and since T8 (ruled and
landed 09-02, `bb4cf5d`) this seat's bound lives in **ISA STEPS REALISED** — `stepsIn`
— with the clock forms **derived** (`stepsIn_empty`, `guard_reduces`, `stepsIn_le`).
Every scoped result is quantified over the stall predicate.

⇒ The `stalls := fun _ => false` INSTANCES are falsified by an arbitrating bus, and the
R10 bank already declared exactly that: *"an arbitrating core falsifies the INSTANCES
and leaves every theorem under them true."* **This is that case, arriving one day
later.** The theorems are untouched.

⛔ Unchanged by any of this: the object is `CorePlace.core`, the Lean-composed circuit,
not `core32.v`; no theorem relates them; rung 2.5; RTL correspondence OPEN.
