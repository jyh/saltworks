# slicea16bma at the REAL 3×2 die — council ruling #1, 2026-08-09

**The Captain's word (08:35, ruling #1):** *"we will want this layout no matter
what, even if we decide not to submit it, so let's approve and make it real."*

This is the **true tile-fit run** that every free-floorplan verdict deferred to:
`FP_SIZING: absolute` at the actual 3×2 tile geometry, not `FP_CORE_UTIL` sizing.

## THE INVOCATION — banked with the numbers, not after them

```sh
# config: /tmp/tilefit3x2/config.json (committed below as the 3x2 config)
docker run --rm -v /tmp/tilefit3x2:/work -v /tmp/silicon_pdk:/pdkroot \
  ghcr.io/librelane/librelane:3.0.5 \
  librelane --pdk-root /pdkroot/volare/sky130/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b \
  /work/config.json
```
- RTL: `SaltWorks/Silicon/RTL/slicea16bma.v`, sha256 `c9644c605300…`
- run dir: `RUN_2026-08-09_15-50-58` (container clock, UTC)
- **CONTROLLED:** the config differs from the 2×2 tile-fit run by **one line**,
  `DIE_AREA`. Every other knob identical (density 80, `MAX_FANOUT_CONSTRAINT` 10,
  `GRT_ALLOW_CONGESTION` 1, PDK pin, clock 40 ns). *Any difference in the result
  is therefore the die size.*
- ⚠️ **The GDS (8.9 MB) is NOT committed** — no precedent in this repo and it is
  DERIVABLE. The invocation above plus the pinned PDK/image reproduces it.

## RESULT — signed off, against the bar pre-registered at 08:46

| metric | free floorplan | **3×2 REAL DIE** | verdict |
|---|---|---|---|
| die / core area (µm²) | 80,985 / 71,486 | **114,858 / 101,535** | fits, absolute |
| stdcell area (µm²) | 45,205.9 | **45,337.2** | +0.3% |
| utilization | 63.2% | **44.65%** | — |
| DRC (route · magic) | 0 · 0 | **0 · 0** | ✅ PASS |
| LVS (all 7 counters) | 0 | **0** | ✅ PASS |
| antenna nets / pins | — | **0 / 0** | ✅ PASS |
| setup wns · hold wns | 0 · 0 | **0 · 0** | ✅ MET, 9 corners |
| worst slack @ `ss_100C_1v60` | +16.914 ns | **+14.819 ns** | ✅ met (−2.10) |
| max-slew viol. ss/max · tt | 1,678 · 637 | **2,019 · 854** | ⛔ **FAIL, WORSE** |
| routed wirelength | 159,680 | **172,703** | **+8.2%** |

**TILE FIT: PASSES on every criterion. DRV: FAILS.** *The bar said "slew 0 at
typical"; typical is 854. Scored a FAIL, not a partial, because that is what the
bar says — and the bar was published before the run.*

## THE PRE-REGISTERED DISCRIMINATOR RESOLVED

Two mechanisms predicted **opposite signs**, written down at 08:53 while the
answer was unknown:

- *wire-length driven* → more room, longer routes, slew **worse or flat**
- *congestion/repair driven* → more room to buffer, slew **better**

🔑 **THE WIRE-LENGTH BRANCH, confirmed by an INDEPENDENT counter:**
`route__wirelength` 159,680 → 172,703 (**+8.2%**), and −2.10 ns of slack is what
8% more wire costs. *A second instrument agreeing — not a story that fits.*

⚠️ **Why the pre-registration earned its keep:** routing violations fell
3,208 → 141 → 2 during this run. *"The real die improved routing" is TRUE and
completely IRRELEVANT to slew* — and it would have been the comfortable headline.

## WHAT IT MEANS FOR THE DRV ITEM

**The design occupies 44.65% of a 3×2 core.** Cells spread, wires lengthen, slew
degrades. ⇒ **The lever is PLACEMENT COMPACTNESS, not the transition/fanout
constraints** — `MAX_FANOUT_CONSTRAINT` was already measured non-causal (a
bit-identical control run, and `max_fanout_violation__count` was 11 against 1,678
slew: the counter separating the modes had answered it in advance).

🔑 **THE TILE QUESTION IS ONE AXIS, NOT TWO.** *The 2×2's routing FIGHT and the
3×2's SLEW problem are the same variable from both ends:*

```
smaller die  ->  harder routing, SHORTER wires, better slew
bigger die   ->  free routing,   LONGER wires,  worse slew
```

⇒ **No tile is comfortable on both counts. This is a choice of which failure to
prefer, not a defect to be fixed.** *Next step (S3): a compactness run at the same
fixed 3×2 die with core margins tightened, so the design clusters — same
one-variable discipline.*

---

## THE 2×2, RUN TO A PRE-REGISTERED CAP (2026-08-09 09:03–10:34)

**Same one-variable discipline: the config differs from the 3×2 by ONE line,
`DIE_AREA [0,0,334.88,225.76]`. Everything else identical.**

| | 3×2 REAL DIE | 2×2 REAL DIE |
|---|---|---|
| wall clock | ~8 min, **Flow complete** | **90 min, stopped at the cap** |
| final stage | signoff + GDS | `DetailedRouting` — never left it |
| routing floor | 0 DRC | **10 violations, 168 iterations** |
| signoff | DRC 0 · LVS clean · timing met, 9 corners | **none — no metrics, no GDS** |

**Full routing trajectory** (51 distinct successive values):
```
0 -> 1707 -> 3223 -> 4836 -> 6236 -> 6541 -> 6487 -> 5767 -> 5342 -> 4921 -> 5052 -> 4850 -> 4709 -> 4462 -> 3796 -> 3276 -> 2616 -> 1899 -> 1778 -> 1482 -> 1381 -> 1147 -> 1134 -> 1046 -> 929 -> 784 -> 763 -> 716 -> 667 -> 553 -> 552 -> 485 -> 473 -> 278 -> 277 -> 264 -> 255 -> 241 -> 236 -> 216 -> 128 -> 73 -> 67 -> 66 -> 27 -> 25 -> 23 -> 21 -> 15 -> 12 -> 10
```

### ⚖️ VERDICT: **MARGINAL. Not refused, not proven.**

*The 2×2 was never shown impossible — 10 violations is close, and this trajectory
broke a long plateau once already (21 → 10), so "stuck" is not "converged". But it
did not close in **eleven times** the wall clock the 3×2 needed.*

### ⛔ WHAT THIS CORRECTS

**On 2026-08-08 I stopped a 2×2 run at 66 minutes and published "REFUSED".** That
verdict was overclaimed and was withdrawn on 08-09. This run reached 10 at ~35 min
and sat there for 168 iterations.
🔑 ***So the INSTINCT (it is at its floor) was right and the VERDICT (impossible)
was wrong — and only a run to a pre-registered cap can separate those two.***

### 🔑 THE STOP WAS MECHANICAL, NOT A JUDGEMENT

The 90-minute cap ran in a background watcher that stopped the container whether or
not anyone was watching the clock. **The failure being corrected was precisely a
stop made by a tired judgement in the moment; a pre-registered rule that depends on
the author noticing the time is not pre-registered.**

### DECISION-RELEVANT

**The 3×2 is a routable tile. The 2×2 is a research project.** *Its remaining 10
violations are worth an afternoon only if the tile arithmetic says otherwise.*
