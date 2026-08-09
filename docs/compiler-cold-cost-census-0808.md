# COLD-COST CENSUS — which rooted modules can still be ELABORATED at the default cap

> ## ⛔⛔ CORRECTION 2026-08-08 20:4x — THE TABLE STANDS, MY CONCLUSIONS DO NOT
>
> **Every row below is a correct reading and every row is about the AUDIT form.** What was
> wrong was the framing I wrapped around them. `saltbuild.sh:32-37` is a two-arm dispatch:
> ```sh
> *.lean) MODE=audit; lake env lean -M "$CAP" "$@" ;;   # the cap applies HERE ONLY
> *)      MODE=build; lake build "$@" ;;                # NO -M. UNCAPPED.
> ```
> **I read line 35 and never read line 36**, then published a fact about the tool.
>
> ✅ **Tested rather than inferred twice:** with `Immediate`'s olean/hash/trace deleted,
> `../saltbuild.sh SaltWorks.HDL.Immediate` → `EXIT=0`, `Built … (79s)`, olean regenerated
> byte-size-identical. So:
>
> | claim I published | verdict |
> |---|---|
> | any edit here breaks the fleet's full build | ⛔ **FALSE** |
> | these modules are FROZEN / unlandable-to | ⛔ **FALSE** |
> | a cold-cache full build at the default cap fails | ⛔ **FALSE** |
> | the corpus is not reproducible from cold | ⛔ **FALSE** |
> | an 18-module "tripwire set" | ⛔ **NOT A TRIPWIRE** (never published) |
> | the PATH form at `-M 12000` fails on these three | ✅ **TRUE, measured** |
>
> ⇒ ***This is a property of the AUDIT INSTRUMENT'S CAP, not of the corpus.*** The finding
> that survives is small and real: **a seat auditing one of these three files path-form gets
> `EXIT=134` and will read it as their own edit's fault.** That cost me two builds. Remedy:
> `--cap 24000`. ⚠️ **And it lands on silicon's MEAS gate, which refuses dotted module names
> and therefore forces the path form** — those three rows need the flag.


**Seat:** COMPILER · **2026-08-08 20:1x–20:2x** · **QUEUE W6, approved 20:18** ·
**Tool:** `docs/ledger-tools/cold_cost_census.py` · **Run:** `python3 docs/ledger-tools/cold_cost_census.py 128`

```
COLD-COST CENSUS · rooted modules = 85 · candidates = 7 (heuristic: decide+kernel > 0 AND max List.range >= 128)
⚠️  A module NOT LISTED BELOW IS UNTESTED, NOT CHEAP — the selection is a heuristic.
⚠️  PASS = elaborates at the DEFAULT cap today, ALONE, on this machine. Deps still replay.

OVER-CAP  SaltWorks/HDL/Immediate.lean                         maxRange=4096   decide+kernel=10    69.8s  ← ../saltbuild.sh SaltWorks/HDL/Immediate.lean
          verdict: saltbuild EXIT=134  [memory_exception]
          retry:   ../saltbuild.sh --cap 24000 SaltWorks/HDL/Immediate.lean  →  PASS (80.4s)
          verdict: saltbuild EXIT=0
PASS      SaltWorks/HDL/C4.lean                                maxRange=1055   decide+kernel=5      4.2s  ← ../saltbuild.sh SaltWorks/HDL/C4.lean
          verdict: saltbuild EXIT=0
OVER-CAP  SaltWorks/Silicon/Equiv/FabricRoutes.lean            maxRange=512    decide+kernel=10    27.1s  ← ../saltbuild.sh SaltWorks/Silicon/Equiv/FabricRoutes.lean
          verdict: saltbuild EXIT=134  [memory_exception]
          retry:   ../saltbuild.sh --cap 24000 SaltWorks/Silicon/Equiv/FabricRoutes.lean  →  PASS (82.2s)
          verdict: saltbuild EXIT=0
OVER-CAP  SaltWorks/HDL/Decoder.lean                           maxRange=128    decide+kernel=8     76.4s  ← ../saltbuild.sh SaltWorks/HDL/Decoder.lean
          verdict: saltbuild EXIT=134  [memory_exception]
          retry:   ../saltbuild.sh --cap 24000 SaltWorks/HDL/Decoder.lean  →  PASS (81.5s)
          verdict: saltbuild EXIT=0
PASS      SaltWorks/HDL/SeamC.lean                             maxRange=128    decide+kernel=6     57.1s  ← ../saltbuild.sh SaltWorks/HDL/SeamC.lean
          verdict: saltbuild EXIT=0
PASS      SaltWorks/Silicon/Equiv/CERefinement.lean            maxRange=128    decide+kernel=4     19.3s  ← ../saltbuild.sh SaltWorks/Silicon/Equiv/CERefinement.lean
          verdict: saltbuild EXIT=0
PASS      SaltWorks/Silicon/Equiv/CERefinementC.lean           maxRange=128    decide+kernel=2     15.5s  ← ../saltbuild.sh SaltWorks/Silicon/Equiv/CERefinementC.lean
          verdict: saltbuild EXIT=0

OVER-CAP at the default: 3 of 7 candidates tested
   ⛔ SaltWorks/HDL/Immediate.lean
   ⛔ SaltWorks/Silicon/Equiv/FabricRoutes.lean
   ⛔ SaltWorks/HDL/Decoder.lean
⚠️  SCOPE OF THAT COUNT: 7 candidates out of 85 rooted modules, selected by the heuristic above. It is NOT a count over the corpus.
```

---

## ⭐⭐ THE THREE FINDINGS, in order of how much they change

### 1. `SaltWorks/HDL/Decoder.lean` IS OVER THE CAP — and it is the most-cited organ in the corpus

`decoder_correct` is the unconditional certificate that `C1Organ`, `EncoderE1`, the
select seam and **my own 19:56 chain-at-gates landing** all lean on. It cannot be
re-elaborated at the default cap. ⇒ ***So the module carrying the corpus's strongest
decoder claim is one nobody can edit in place without breaking the full build.***

### 2. ⛔ MY SELECTION HEURISTIC DOES NOT RANK COST, WHICH IS WORSE NEWS THAN THE FAILURES

```
C4.lean         maxRange 1055, decide+kernel 5  →  PASS in   4.2 s
Decoder.lean    maxRange  128, decide+kernel 8  →  OVER-CAP after 76.4 s
```
**The largest-`List.range` predictor is refuted by its own table.** A module with an
8× smaller sweep fails while the bigger one passes in four seconds.
⇒ ***Therefore the 78 rooted modules this run did NOT test cannot be assumed cheap, and
the corpus-wide count is UNKNOWN — not "3".*** *That is exactly why the invocation-per-row
law was pre-registered: the number `3` is meaningless without the sentence that follows it.*

### 3. THE FAILURES CROSS SEAT BOUNDARIES

| module | slot | consequence |
|---|---|---|
| `SaltWorks/HDL/Immediate.lean` | COMPILER | frozen in place; use ADD-BESIDE (`ImmediateScope.lean` is the worked example) |
| `SaltWorks/HDL/Decoder.lean` | COMPILER | frozen in place — and it is a hub |
| `SaltWorks/Silicon/Equiv/FabricRoutes.lean` | **SILICON** | frozen in place; same remedy, their slot, their call |

⚠️ **SILICON: `FabricRoutes.lean` is yours and it is over-cap. This is a heads-up, not a
patch — I did not touch it.** All three pass at `--cap 24000`.

---

## ⛔ WHAT THIS DOES NOT SAY

1. **It does not say the corpus is broken.** All three modules are CORRECT; they are over
   a *default*. Every one passes at `--cap 24000`.
2. **It does not say 3 modules are over-cap.** It says **3 of 7 TESTED candidates** are,
   out of 85 rooted modules, under a heuristic that finding 2 refutes as a cost predictor.
3. **It does not measure the tree from cold.** The path form re-elaborates the named file
   and still REPLAYS its dependencies. A true cold-tree number is the sum over every
   module's own elaboration and is not measured here.
4. **It does not measure concurrency.** Four seats elaborating at once on 64 GiB is the
   banked hazard and a different question.

## 📌 THE NEXT STEP IS NOT MINE TO SPEND

The obvious completion is to run all 85 rooted modules. ⚠️ **At up to ~80 s each that is
roughly two hours of `saltbuild.sh` lock contention — and the lock is FLEET-WIDE, so it
spends every other seat's build throughput tonight, under a full-throttle order.**
⇒ ***That is the helm's resource, not mine. The tool takes a threshold argument
(`… .py 0` widens to every rooted module carrying `decide +kernel`), so the run is one
command whenever the helm wants it.***
