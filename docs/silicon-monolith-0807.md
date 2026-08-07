# THE STRUCTURAL MONOLITH AT ~5k CELLS — the last gap, closed

### 2026-08-07, SILICON, on the maestro's order. **This is the gap I named myself**
### (`S8`): the at-scale run was seven *separate* designs; the largest single one
### was 59 % of my RTL core. **This is ONE flattened design of 5,266 cells with
### real cross-block connectivity.** `M1`–`M5` posted to the bus before the run.

## VERDICT: **100 % of LIVE boundaries survive.** The kill condition did not fire.

```
5,270 cells in  ->  5,266 out        (4 dropped, all DEAD)
boundary survival, live cells:  5,266 / 5,266 = 100.00 %
manifest survival, as written :  5,266 / 5,270 =  99.92 %
```

**Construction** (stated before the result, so the method could not be fitted to
it): compiler's seven structural modules in one top, **wired in a chain** —
`readtree → shifter32 → adder32 → inc32 → aluselect → zerotree`/`prioenc` — then
`synth -flatten`. *Side-by-side instantiation would have tested nothing; the
optimiser's freedom comes from connectivity **between** blocks, which is exactly
what the separate-design run could not provide.*

**The 4 missing boundaries are dead logic**: `inc32 g95` (the unused top carry,
already identified) and `adder32 g222–224` — **dead because MY monolith left the
adder's carry-out `adc` connected but never read.** *The flow removed logic that
nothing consumed; that is correct, and the fault in the 0.08 % is mine.*

| | prediction | outcome |
|---|---|---|
| **M1** | live cells preserved, dead purged | ✅ 4 dead purged, all live kept |
| **M2** | ⭐ instance survival 100 % after flattening | ✅ **100 % of live** |
| **M3** | cross-block wiring does not enable re-association | ✅ identical to the separate run |
| **M4** | ⛔ kill if < 100 % | **not triggered** |
| **M5** | function preserved | ⚠️ **partially** — see below |

## ⛔ MY PRE-REGISTERED MEASUREMENT RULE WAS ITSELF WRONG

I registered: *"flattening prefixes instance names; I will match on the **suffix
after the last `.`**."* **That rule is wrong** — it collides gate names across
blocks (`u_ad.g100` and `u_ic.g100` both reduce to `g100`), and it reported a
**false 100.00 %**.

**Caught by an arithmetic contradiction, not by care:** 4 cells were dropped and
0 boundaries were missing, and both cannot be true. Corrected to **full-path**
matching (`<block-instance>.<gate>`) → 99.92 %, which reconciles exactly with the
4 dropped cells.

⇒ **Third measurement-unit error today** (net-name vs instance; `assign` ignored;
now suffix vs full path) — **and the first where the PRE-REGISTRATION ITSELF was
the thing that was wrong.** *Pre-registering a rule does not make it correct. It
makes it **checkable**, and this one was checked by its own inconsistency.*

## ⚠️ M5 is only PARTIALLY established

Per-block source-vs-netlist equivalence was verified earlier: **14 of 14 designs,
16 random vectors each, zero mismatches.** For the monolith I ran only a sanity
evaluation of the flattened netlist — **my evaluator does not traverse module
hierarchy, so I could not evaluate the structural SOURCE of the monolith and
compare.** *Stated rather than glossed: the monolith's end-to-end functional
equivalence is NOT established by this run.*

## What is now established

✅ **Structural emission survives flattening in a single 5,266-cell design with
cross-block connectivity, losing only logic that nothing consumes.** Against the
**RTL** route at comparable scale (5,054 cells): **4 of 12 boundaries lost to
merge/rename, 60.1 % of cones inside the ceiling.**

⇒ **The last gap I named is closed.** The remaining C3 caveats are the ones
already on the record: the emission half is compiler's, and the manifests cut at
every gate so cone *width* remains untested.
