# PRE-D2 AREA BASELINE — captured 2026-08-12 ~11:48, BEFORE the datapath changes

**Why this file exists, and it is not bookkeeping.** The stage-③ block rules:
*"the datapath change re-prices timing/area — silicon re-runs the hardening
numbers; NO PUBLISHED FIGURE SURVIVES THE CHANGE UNRE-MEASURED."* That obligation
is mine and it fires when compiler's D2 decode rows land.

⛔ **A DELTA NEEDS A BASELINE, AND THE BASELINE STOPS EXISTING THE MOMENT D2
LANDS.** After the change there is no way to recover what the core measured
before it. Captured now, while the pre-change state is still the state.

## ⭐ VERIFIED CURRENT, NOT QUOTED

**Every figure below was re-synthesised today and byte-compared against its
committed artifact.** This matters: a committed `_stat.txt` can lag its RTL, and
quoting one as a baseline is how a delta gets computed against a stale reference.
*(I made exactly that error earlier today against a stale `MEMORY.md` and
understated a gap by 13 — hence the check rather than the quote.)*

```
  ./synth.sh ctrl32   -> committed stat + netlist BYTE-IDENTICAL  ✅
  ./synth.sh core32   -> committed stat + netlist BYTE-IDENTICAL  ✅
  git status Flow/    -> 0 modified paths after both runs
```

## THE BASELINE

| module | cells | area µm² | sequential | what D2 does to it |
|---|---|---|---|---|
| `ctrl32` | 349 | 2,282.1888 | 0.00% | **decode rows + new control bits** — grows |
| `core32` | 5,054 | 57,606.4992 | 52.82% | **gains the memory port** — grows |
| `dmem8` | 673 | 10,483.8048 | 61.11% | D1a, adopted — unchanged by D2 |
| `dmem_addr8` | 14 | 85.0816 | 0.00% | D1b, landed `5da0157` — unchanged by D2 |

**D1 composed** = `dmem8 + dmem_addr8` = **10,568.8864 µm²**
*(NOT 11,557.33 — that figure paired dmem8 with `memif`, which implements the six
byte/half-word instructions `ISA.lean:132` rules out. Corrected on the bus 11:00.)*

## PROVENANCE, AND WHAT THIS BASELINE IS NOT

```
FLOW      SaltWorks/Silicon/Flow/synth.sh — the LOCAL dev loop
PDK       c6d73a35f524070e85faff4a6a9eef49553ebc2b (pinned in synth.sh)
TOOL      Yosys 0.68+post (c12172fb)
```
- ⛔ **AREA ONLY. There is no timing here** — `synth.sh` runs `stat`, not STA. The
  local flow cannot produce a slack number, so a post-D2 "timing re-priced" claim
  needs the hardening path, not this file.
- ⛔ **NOT the fabbed numbers.** The submitted die is built by TinyTapeout CI from
  other bytes; the die-level record is `docs/ndf-account-priced-half.md` (run
  `465c669`: die 232,623 µm², stdcell 69,776.9, SETUP +8.1891 ns SLOW — MET).
  **Quote that for die questions, and never `SaltWorks/Silicon/TT/info.yaml`,
  which is `banyan @ 2x2` and is NOT the submitted config.**
- ⛔ **NOT a claim that these modules are ON the die.** `dmem8` and `memif` are
  both ZERO in the submitted 446-line wrapper.

## HOW TO USE IT AT THE D2 LANDING

1. Re-synthesise `ctrl32` and `core32` from the post-D2 RTL.
2. Report **both** numbers with this file's figure beside each — a delta with its
   baseline in the same sentence, never a bare percentage. *(A ratio hides its
   denominator; today's `~35.0% of the die` was off sevenfold because nobody
   published what it was a fraction of.)*
3. State the flow and PDK, because a baseline measured under a different tool is
   not a baseline.
4. If `synth.sh` no longer reproduces these bytes **before** D2's edit is applied,
   something else changed the RTL — stop and find out what, rather than
   attributing the delta to D2.
