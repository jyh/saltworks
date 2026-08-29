# The nine hardening runs of 2026-08-27 — the CONFIGS, so the results are reproducible
silicon. Every figure this seat published today came out of one of these files. They were
`/tmp`-resident all day and the results docs described them **in prose** — *"regenerate from this
paragraph"*. ⛔ **That is this seat's own banked defect** (`output-without-producer-is-only-quotable`:
*durable ✅ delivered ✅ **reproducible ❌** — and the third has NO OBSERVABLE until someone re-runs
it*). **The cure I banked is "commit the producer as CODE", so here it is.**

## The two designs, and they are NOT the same object
```
config-3x2-*.json    slicea16bma, STANDALONE, 3x2 die 508.76x225.76, CLOCK_PERIOD 40
                     The DRV DIAGNOSIS object. Captain's word: "byte-wide -ma on its own 3x2".
config-ndf-*.json    tt_um_saltworks_ndf_c32, 6x2 die 1030.40x225.76, CLOCK_PERIOD 55
                     THE PAID CHIP — the top actually on the shuttle (info.yaml @ 7d2b275).
```
⛔ **`Flow/librelane/ndf_6x2_config.json` names `tt_um_saltworks_ndf` — the SUPERSEDED top. Do not
reach for it.** Its filename is still true (it names the TILE, which did not change), which is
exactly why it is dangerous.

## ⚖️ THESE CONFIGS ARE NOW A GATE, NOT ONLY A RECORD (2026-08-28 17:4x)

`docs/silicon-tools/treatcheck.py` reads the pair `config-ndf-base.json` + `config-<arm>.json` as
the arm's **DECLARED TREATMENT**, and requires the *resolved* difference against the submitted
chip's `resolved.json` to be **EXACTLY that key set** — refusing on **EXTRA** (contamination: a key
that differs in what RAN and was never declared — the met5-vs-met4 defect `resolved_diff.py`
records, which came back with 2.13 ns MORE slack than the chip it claimed to reproduce) and on
**MISSING** (the treatment never happened, and the arm is the baseline wearing its name).
⇒ ***`resolved_diff.py` ASKS "ANY DIFFERENCE?" AND A TREATMENT ARM CAN NEVER PASS IT, WHICH IS HOW
ITS STATUS ENDED UP PRINTED AND NEVER CONSUMED. `treatcheck.py` ASKS "EXACTLY THE DECLARED
DIFFERENCE?", AND THAT QUESTION HAS A REACHABLE YES.*** `harden_run.sh` now exits with the worse of
{DRV gate, treatment gate}, and "could not measure" never renders as "passed".
📌 **Driven on these very files (`--selftest`, 10/10):** ①d · ②a · ②b each pass against their own
declaration on 411-key resolved sets, and the two failure arms are REAL runs mismatched on purpose
— **2a's declaration against 1d's actual run** is what a silently-unapplied CTS treatment looks
like here, and 1d's declaration against 2a's run is what contamination looks like.

### 📐 AND THE THIRD GATE, WHICH IS ABOUT THE CHIP AND NOT ABOUT A RUN (2026-08-28 17:5x)

`docs/silicon-tools/rtlmatch.py <submitted-src> <repo-rtl>` answers **"is what we would submit today
the same design as what is on the shuttle?"** — a question that is answerable until **2026-09-07
13:00 PDT** and unanswerable after it, because a revision can be replaced any number of times before
the deadline and never after. **MEASURED 17:5x: 10/10 code-identical.** Nine are byte-identical and
`busadapt8.v` differs ONLY in a struck-and-answered comment block (08/26) ⇒ **no revision is owed on
this account, which is a finding and not an absence of one.**
⛔ **The risk in that tool is its comment stripper — one that eats too much reports IDENTICAL for
free, in the flattering direction — so the mutation control is built IN, per file, and the gate
returns "cannot measure" rather than a verdict if a planted code change ever survives stripping
unseen.** ⚠️ *My first control was itself defective and caught me: the mutation landed on `assign
c_instr`, whose first occurrence in that file is inside a COMMENT QUOTING THE CODE, so the stripper
removed the mutation and the check reported identical for a file I had just changed.* ⇒ ***A
MUTATION CONTROL IS ONLY A CONTROL IF THE MUTATION SURVIVES THE PIPELINE — assert that it CHANGED
THE COMPARED TEXT, not merely that you applied it.***

## The runs
```
config-3x2-baseline  reproduces the 08/09 figures exactly: fanout 39 · slew 2019 · cap 51
config-3x2-sstt      RSZ_CORNERS ss+tt                     slew 475  but hold collapses to 15ps
config-3x2-all9      RSZ_CORNERS all nine                  hold restored, slew back to 1680
config-3x2-1c        ss+tt corners + margins 0.25/0.15
config-3x2-1d        ss+tt corners + margins 0.45/0.30     ⭐ dominates baseline on every metric
config-ndf-base      the SUBMITTED config verbatim         ⭐ reproduces TT's signoff BIT-EXACTLY
config-ndf-1d        + RSZ_CORNERS(4) + margins 0.45/0.30  fanout 117->111, slew 3317->857
config-ndf-2a        + CTS_SINK_CLUSTERING_SIZE 10         ⭐ fanout ->1   RECOMMENDED with 1d
config-ndf-2b        + CTS_SINK_CLUSTERING_SIZE 8          fanout ->2 AND hold regresses
```

## ⛔ TOOLCHAIN — THE TWO FAMILIES USE DIFFERENT PDKs AND ARE NOT PDK-COMPARABLE
```
image  ghcr.io/librelane/librelane:3.0.5  @ sha256:ecabd075d0ddf6a2bd1cd4a32109c7dbb861ec007f7e4e423a9a081f8d23b8e2   BOTH
PDK    3x2 family  c6d73a35f524070e85faff4a6a9eef49553ebc2b
       NDF family  8afc8346a57fe1ab7934ba5a6056ea8b43078e71   ← TT's OWN PDK, deliberately
```
The NDF family was switched to TT's PDK so `ndf-base` is a genuine REPRODUCTION of the submitted
signoff rather than merely a baseline. **The cost, stated: NDF runs are not comparable to the 3x2
runs.** They are internally controlled and comparable to the paid chip, which is worth more.

## How to re-run
```
WORKDIR=<tree with ndf_rtl/ or rtl/ and the 6x2 DEF>  TTREF=<submitted resolved.json>  \
  sh ../silicon-tools/harden_run.sh <tag>          # tag = the config suffix
```
⭐ **THE GATE IS CONFIGURATION IDENTITY, NOT METRIC PROXIMITY:** `resolved_diff.py` must return
**EMPTY** against the submitted `resolved.json` for `ndf-base`, and **exactly the treatment keys**
for an arm. *A config you wrote is a hypothesis; the `resolved.json` is what ran* — run 1 of
`ndf-base` sat inside ±5% on all three DRV counts while the routing layer, the power-grid pitch and
the IO geometry were all wrong.
