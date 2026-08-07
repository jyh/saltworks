# THE CONCURRENCY MEASUREMENT — ordered by JYH at close of board, 2026-08-06

### Method PRE-REGISTERED in `docs/hdl-muster-0806.md` §4 before any run.
### 6 agents: 3 arms (N = 1/2/4), an INDEPENDENT sampler sharing no code with
### the arms, an adversarial refuter attacking the extrapolation, and a ruling.

> **THE MECHANISM IS CONFIRMED AND THE ALARMING NUMBER IS DEAD** — the same
> shape as the previous night's cap-rule pass, and the second time in twelve
> hours that a claim of mine survived in mechanism and died in consequence.
>
> **What I said at close of board:** *"4 × 20 GB = 80 GB of licence on a 64 GiB
> machine."* **True as a licence.** ⛔ **But the worst REALIZABLE peak on today's
> repo graph is 20,347,224,064 B, and its four members are LIGHT modules** —
> saltworks contains exactly **one** heavy module, `FabricRoutes`, and it is
> **alone whenever it is heavy** (94% of the makespan; the other 25 modules have
> finished before it crosses 5 GB). *80 GB is a property of the toolchain, not of
> anything in this repo.*
>
> **AND THE CORRECTION I PRE-REGISTERED AT 05:57 WAS OWED AND IS BIGGER THAN I
> GUESSED.** I wrote, before the result: *"sum-of-RSS double-counts shared pages
> — if I post 4 × 5.4 GiB unqualified I will have published a true reading of an
> adjacent object."* Measured: sum-of-RSS **22,436,855,808** B against
> sum-of-phys_footprint **21,208,688,680** B, with the machine releasing
> **21,092,007,936** B on exit — RSS overstates by **6.38%** on the synthetic
> workload. ⚠️ **On a real mathlib-loading module it is ~47%, not 6%**
> (`FabricRoutes`: RSS 14,829,387,776 B, footprint ~10.07 GB, of which
> 5,046,586,572 B is mapped-file resident shared across every concurrent lean).

## ⚠️ A HOLE IN THE FLEET LOCK, FOUND ON THE WAY — not part of the question asked

The refuter established that in every trace the machine-wide total stayed at the
4-slot figure **because the fleet lock held**. But:

**`lake env lean` — the AUDIT path, the one where `argv[0]` is a bare `lean` —
DOES NOT TAKE THE LOCK.** A 4-slot build (22,434,283,520 B) concurrent with an
unlocked `FabricRoutes` audit (14,829,387,776 B) is **37,263,671,296 B**.

***That combination has never been observed and nothing measured here prevents
it.*** Every seat runs audits. This is reported, not fixed — `saltbuild.sh` is
maestro-owned.

---

# RULING — the per-process `-M` cap and the per-machine guarantee

## 1. THE SCALING LAW

**Peak resident SUM scales one-for-one with concurrent lean process count: 5,608,800,256 B at N=1, 11,217,403,904 B at N=2, 22,434,283,520 B at N=4 — 1.00000x / 1.99996x / 3.99984x, linear to within 0.004%.**

Those three figures come from **one instrument, one package, one workload, one sampler** (the arm-4 seat's sweep: `saltbuild-t1.sh`, `saltbuild-t2.sh`, stock wrapper), which is the only apples-to-apples series in the experiment. I re-derived all three from the raw traces myself rather than take the headlines:

| N | trace | peak SUM (B) | peak conc | samples n>1 | per-proc peak (B) | live window |
|---|---|---|---|---|---|---|
| 1 | `samples.t1.jsonl` | 5,608,800,256 | 1 | 0 (by construction) | 5,608,800,256 | 158.8 s |
| 2 | `samples.t2.jsonl` | 11,217,403,904 | 2 | 324 | 5,608,800,256 | 77.6 s |
| 4 | `samples.run2.jsonl` | 22,434,283,520 | 4 | 172 | 5,608,685,568 | 41.5 s |
| 4 | `samples.run1.jsonl` | 22,434,037,760 | 4 | 173 | 5,608,636,416 | 42.4 s |

Independent corroboration, different agents, different mechanisms, no shared code:
- N=1: arm-1 seat, `ps`-based sampler, 5,608,685,568 B — agrees with t1 to **0.002%**.
- N=2: arm-2 seat reached concurrency 2 by **narrowing the import DAG to width 2 with the thread cap left at 4**, and got 11,217,960,960 B over 274 concurrent samples — agrees with the thread-capped t2 to **0.005%**. This kills the confound arm 1 flagged: it does not matter whether concurrency 2 comes from the graph or from `LEAN_NUM_THREADS`; the number is the same, so peak-sum scaling is **process-count** scaling, not thread-count scaling.
- N=4: the independent-sampler crosscheck (libproc syscalls, `proc_pidpath`, 137 ms, no `ps`, no argv[0]) got 22,436,855,808 B — agrees with the incumbent to **0.0126%**, i.e. 1 part in 8,000.

**No arm is VOID.** The one that looks it is not: the N=1 anchor reports zero samples with >1 lean live, but that window is empty *by construction* (the independent variable forced it empty), not by undersampling — 666 of 670 samples had a lean live in t1, 1,124 of 1,146 in arm 1. The pre-registered VOID rule targets undersampling (the 2-sample failure); it does not condemn an empty window that the arm's own definition creates. Two independent N=1 runs agree to 0.002%.

Mechanism, confirmed three ways: `LEAN_NUM_THREADS` sizes **Lake's own task pool** (Lake is a Lean program linked against `libleanshared.dylib`, which is the only binary containing the string), and that pool is what caps concurrent lean **child processes**. The live `lake` process's thread count tracked the setting exactly — 6 threads at `=1`, 8 at `=2`, 11–12 at `=4`. The machine has 14 logical cores, so a core-derived pool would have reached 14, not 4. `lake -j`/`--jobs` **does not exist** in Lake 4.32.0-rc1 (three agents got `unknown short option '-j'` through the real wrapper); the only knob is the wrapper's hard-coded line 22, and both sub-4 arms required a one-line-diff copy of `saltbuild.sh` (fleet lock path unchanged).

## 2. THE SHARED-PAGE CORRECTION

**Every sum-of-RSS figure above is an UPPER BOUND. It is not the machine's cost.** At the same instant as the 4-slot peak, three estimates of the same quantity:

| estimate | bytes |
|---|---|
| sum of RSS | 22,436,855,808 |
| sum of `ri_phys_footprint` | 21,208,688,680 |
| anonymous memory the machine actually released when the 4 processes exited | 21,092,007,936 |

**Corrected 4-slot figure: 21,208,688,680 B**, machine-verified to 0.55%. RSS overstates by **1,344,847,872 B (6.38%)**; correction factor **0.94006**. The excess is 308,094,496 B per process of clean file-backed pages — the lean binary and mmapped `.olean`s — counted four times and paid for once.

**On real workloads the correction is roughly 8x larger, and this must not be lost.** The calibrated `decide +kernel` workload is nearly pure anonymous heap (5.49% shared) — the best case for RSS. The real heavy module, `SaltWorks/Silicon/Equiv/FabricRoutes.lean`, measured independently by two agents:

- peak RSS 14,829,387,776 B; phys_footprint **10,093,173,145 B** (refute seat) / **10,066,533,184 B** (crosscheck seat) — two measurements agreeing to 0.26%; ratio **1.47x**
- of which **5,046,586,572 B is mapped-file resident** (mathlib `.olean` + text) — shared across every concurrent lean, charged once by the kernel

So for a mathlib-loading build, sum-of-RSS overstates the machine by roughly **47%**, not 6%. Corroborating that these pages are reclaimable rather than owed: during the 4-slot run the OS evicted 2,273,689,600 B of file cache and swapped out **0** pages.

Rule to adopt: **for comparing arms, quote sum-of-RSS; for any claim about what this machine can survive, quote sum-of-phys_footprint.** Never publish a sum-of-RSS number as "machine footprint" without the 0.94 correction, and never at all for a mathlib workload.

## 3. WHAT IT LICENSES, AND WHAT IT DOES NOT

**The sentence to adopt, verbatim:**

> Lean's `-M` cap is enforced per process, and `LEAN_NUM_THREADS` sizes Lake's job pool, so N concurrent lean processes hold N independent `-M` budgets. Measured on this machine with an identical workload and one instrument, peak resident sum scaled 1.00 / 2.00 / 4.00 at N = 1 / 2 / 4 (5,608,800,256 / 11,217,403,904 / 22,434,283,520 B; sum-of-RSS, an upper bound — corrected to 21,208,688,680 B of physical footprint at N=4). The per-module memory guarantee is real; **the per-machine guarantee does not exist**: at the fleet's default `-M 20000` and 4 slots the standing licence is 83,886,080,000 B against 68,719,476,736 B of RAM, 1.22x, with no arbiter anywhere in the toolchain.

**The overclaim nobody may write: "a saltworks build can use 80 GB."** Three measured reasons:

1. **Observed is 25% of licence.** The 4-slot peak was 22,434,283,520 B RSS / ~21.2 GB footprint. Nothing ever approached its own `-M`.
2. **The real DAG will not co-schedule four heavy modules today.** All 26 saltworks modules were measured individually and replayed through a simulation of Lake's 4-slot greedy scheduler over 4,002 ready-queue orderings. The worst *realizable* peak is **20,347,224,064 B** of RSS (**15,139,759,717 B** modelled physical) — and its four members are `facade` + `comparatorequiv` + `switchref` + `dense`, **not** four heavy modules. The timing-free bound (four mutually independent modules each at its own peak, durations ignored) is 32,279,281,664 B RSS / 18,070,319,921 B physical — an arithmetic ceiling no schedule reached.
3. **The repo contains exactly one heavy module, and it is alone whenever it is heavy.** `FabricRoutes` peaks at 14,829,387,776 B and runs 337.83 s of a 358 s makespan (94%). I verified the mechanism directly from its trace: it first crosses 5 GB at **t+217.9 s** and 10 GB at **t+250.8 s**, while the other 25 modules total **125.7 s** of work across 3 remaining slots. They are all finished before it gets heavy. Second-heaviest is `comparatorequiv` at 6,000,525,312 B for 9.27 s.

**So: the practical hazard on today's graph is smaller than the arithmetic, and that must be said in the same breath as the licence.** The 4x scaling is a property of the toolchain; 80 GB is a property of nothing that exists in this repo.

**Where the agents disagreed on the DAG, both readings:** the refute seat reported max antichain 8. Recomputing from that seat's own `DEPS` table I get **14** (`adderslice, certs, columns, comparator, emitv, fabric, fabriccut, facade, isa, refcomparator, selfrouting, seq, sky130, switch`), or **5** if restricted to the eleven modules above 5 GB. One of us is wrong and it is unresolved — but every reading exceeds 4, so the conclusion is identical: **the DAG does not serialize; the 4-slot cap binds, not the graph.** What saves the machine today is timing (one long slow ramp), not width.

## 4. THE REMEDY

**Recommended: keep the parallelism, cut the licence — set `LEAN_NUM_THREADS=3` and `-M 16384` (MiB).**

The number is chosen so the licence becomes a promise the machine can honour: 16,384 MiB = 17,179,869,184 B = **exactly RAM/4**, so 4 slots would be exactly 100% of RAM and 3 slots is **51,539,607,552 B = 75.0% of RAM**, leaving 17,179,869,184 B for the OS, the file cache and the other seats. This is the first configuration in this experiment in which `slots x -M` is not larger than the machine.

Why not the alternatives:

- **Cut threads alone (4 to 2).** Measured cost on the synthetic width-8 graph: live window 41.5 s to 77.6 s (+87%); to 1 slot, 158.8 s (+283%). It halves the licence but leaves it at 41,943,040,000 B while paying real time. Rejected as the sole remedy.
- **Cut `-M` alone to RAM/threads = 16384 at 4 slots.** Licence lands at exactly 68,719,476,736 B — 100% of RAM, zero headroom, and the fleet runs five seats. Not a margin.
- **Accept and document.** Defensible *today* on the evidence in §3, and it is what the numbers say the risk currently is. But it is one heavy module away from being wrong, and the change below is nearly free.

**Why 3 slots costs almost nothing on the real repo, unlike on the synthetic:** saltworks' makespan is 358 s of which 337.83 s is a single serial module. The remaining 125.7 s of work spread over 2 vs 3 co-slots overlaps `FabricRoutes` either way; the makespan delta is single-digit seconds. The 87% penalty measured above is a property of the artificial 8-identical-heavy-modules package, not of this repo.

**Adopt only after one verification, and this is a real gate, not a formality:** `-M` meters Lean's *allocator*, not RSS, and nobody measured `FabricRoutes`' allocator high-water. Its RSS peak is 14,829,387,776 B — only 2,350,481,408 B under the proposed 17,179,869,184 B cap. Run `FabricRoutes` once at `-M 16384` and check for the two known cap strings before landing the change. If it trips, the cap goes up and the slot count goes down to keep `slots x -M <= 0.75 x RAM`.

## 5. STILL UNVERIFIED

- **The unit of `-M`.** `lean --help` says "in megabytes". Arm 2 computed the licence as 80,000,000,000 B (decimal MB); the crosscheck as 83,886,080,000 B (MiB). Nobody measured which. Both exceed 68,719,476,736 B of RAM (1.16x / 1.22x), so the conclusion survives, but the published number should not be stated without this caveat.
- **No process has ever approached its cap.** The largest single lean observed anywhere is 14,829,387,776 B against a 20,000 licence. The failure mode the claim describes — two or more processes each legitimately near 20 GB — has never been produced on this machine. **No OOM, no swap, no page-out event was ever observed** (swapouts 0 to 0 in every arm). The hazard is structural, not demonstrated.
- **`FabricRoutes`' allocator high-water is unmeasured.** Only RSS (14,829,387,776 B) and footprint (~10.07–10.09 GB) are known. §4's number rests on this gap.
- **The DAG result is a simulation, not a build.** No real 4-slot full-repo saltworks build was ever run and sampled. The 4,002 schedules replay per-module traces measured **in isolation**; allocator interference, page-cache contention and scheduler jitter between genuinely concurrent leans are not modelled. One agent, one script, one hand-transcribed `DEPS` table that I did not re-verify against the actual `import` lines — and whose width figure already disagrees with my recomputation (8 vs 14).
- **The physical-footprint correction rests on one agent's one measurement.** 21,092,007_936 B of released anonymous memory over a single 0.855 s exit window, and the 0.94006 factor derived from it. Nobody re-measured it.
- **Cross-seat addition was never tested, and one path around the lock is known to exist.** In every trace the fleet lock held: foreign lean RSS peaked at 11,217,731,584 B only while my build sat queued, and was **0 at every peak sample**, so machine-wide lean never exceeded 22,434,283,520 B. But `lake env lean` (the audit path — the one where argv[0] is bare `lean`) **does not take the lock**. A 4-slot build (22,434,283,520 B) concurrent with an unlocked `FabricRoutes` audit (14,829,387,776 B) would be 37,263,671,296 B. That combination has never been observed and nothing measured here prevents it.
- **One synthetic workload underpins the entire scaling law.** `decide +kernel` on `List.range 400000` is the best case for RSS fidelity (5.49% shared) and likely the worst case for representativeness (real modules: 32% shared). The 1/2/4 linearity has never been reproduced on a mathlib-loading workload.
- **The 3-slot wall-time argument in §4 is my inference** from the 337.83 s critical path and 125.7 s of remaining work — not a measured build.

Files (all absolute): `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/conc/arm4/` (the 1/2/4 sweep: `samples.t1.jsonl`, `samples.t2.jsonl`, `samples.run1.jsonl`, `samples.run2.jsonl`, `analyze.py`, `saltbuild-t1.sh`, `saltbuild-t2.sh`); `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/conc/arm1/`; `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/arm2/`; `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/indep/` (libproc crosscheck); `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/refute/` (26 per-module traces + `sim.py`); my re-run of the simulation at `/private/tmp/claude-501/-Users-jyh-projects-claude-saltworks/82d1ba91-8bfa-4615-887f-2a8ddf63bbc8/scratchpad/sim.rerun.txt`. I ran no builds, wrote nothing under `salt/**` or `saltworks/**`, touched no shared `.lake/build`, made no commit.
