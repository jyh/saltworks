# SHIPPING, STAGED — EVERYTHING TRUE BEFORE THE REMOTE EXISTS

**silicon, 2026-08-18 21:1x. Ordered: stage the push so that when the repo exists,
shipping is ONE VERIFIED ACTION and not an evening's assembly.**

⛔ **NOTHING HERE NEEDS THE REMOTE, AND NOTHING HERE CLAIMS TIMING OR FIT.** The bypass
remains RATIFIED AND TIMING-UNJUDGED until TT's CI rules. This is the staging, the
receipts obtainable without a remote, and one judgment I was asked for.

## 1 · THE RECEIPT THAT WAS NOT AVAILABLE THIS MORNING

`TT/validate.py --tree` CRASHED at 09:0x on a missing `docs/info.md`. The tree is now
complete, so it runs — and it is the offline pre-flight for every gate checkable
without an EDA toolchain:

```
5/5 checks pass
self-test — each mutation caught by its own check, and ONLY its own:
  manifest         clock_hz as a float · a missing pinout key · a wildcard in
                   source_files · top_module without the tt_um_ prefix
  docs             the unedited template placeholder
  sources-in-sync  Makefile out of sync with the manifest
  rtl              an `initial` block in src/ · tb.v left on tt_um_example
  config           a key user_config.json overrides · a duplicated REAL key ·
                   FP_SIZING deleted from below the DO-NOT-CHANGE banner
OK — checks pass, and all 11 negative controls were caught by their own check.
```
⭐ **A GREEN WITH ELEVEN DRIVEN MUTATIONS IS A DIFFERENT OBJECT FROM A GREEN.** It says
the checks have teeth, not merely that they ran.

## 2 · A CORRECTION I OWE ON MY OWN 18:3x CLAIM

*I said my `manifest_check` third arm made info.yaml's "nothing checks that they agree"
comment "no longer true". **That was wrong on attribution, and the comment was never
wrong.*** `validate.py:155 check_sources_in_sync` ALREADY compared `source_files`
against `PROJECT_SOURCES`; and the comment says nothing in **TT's FLOW** checks it,
which remains TRUE, because validate.py is ours and not TT's.

⇒ **MY ARM IS EARLIER COVERAGE, NOT FIRST COVERAGE.** *It runs with no assembled tree
and gates `assemble.sh` before a copy happens, which validate.py cannot do. A real
claim, and a smaller one than I made.*
📌 *I read "nothing checks that they agree" as "nothing at all". The BB project's
Makefile spells out the other half — "`../validate.py` does" — and TTNDF's info.yaml
carries only the first clause. **A partial quotation of my own tree, believed.***

## 3 · THE MANIFEST — DERIVED BY `find`, NEVER TYPED

Exactly what `assemble.sh` produces, and therefore exactly what gets pushed:

```
README.md
docs/info.md
info.yaml
src/banyan_fabric.v
src/bitserial_switch.v
src/busadapt8.v
src/config.json
src/core32.v
src/mac_cell_signed_shell.v
src/plane32bus.v
src/ser_organ.v
src/tt_um_saltworks_ndf_c32.v
test/Makefile
test/requirements.txt
test/tb.v
test/test.py
```

⚠️ **WHAT IS NOT IN THAT LIST AND MUST NOT BE HAND-WRITTEN:**
`.github/workflows/`, `.devcontainer/`, `.vscode/`, `LICENSE`. Those come from
TinyTapeout's template repo VERBATIM. **CREATE THE REPO FROM THE TEMPLATE FIRST, THEN
RUN `assemble.sh` OVER IT** — the order matters, and reversing it is how the workflows
end up subtly wrong.

## 4 · THE ONE COMMAND SEQUENCE

```sh
# 0. THE REPO: created FROM TinyTapeout's ttsky26c template, and PUBLIC.
#    §C.4 — the gds workflow's viewer job deploys to Pages; a PRIVATE repo returns
#    422, which reddens the WHOLE gds action, and TT will not accept a red one.
#    THE CAPTAIN'S HAND. Nothing below substitutes for it.

# 1. every gate that does not need the remote — all must pass first
cd ~/projects/claude/saltworks
./docs/silicon-tools/elabcheck.sh tt_um_saltworks_ndf_c32 tt_um_saltworks_ndf
./docs/silicon-tools/manifest_check.sh SaltWorks/Silicon/TTNDF/info.yaml
./docs/silicon-tools/compose_check.sh tt_um_saltworks_ndf_c32 \
      plane32bus core32 busadapt8 banyan_fabric mac_cell_signed_shell ser_organ
./docs/silicon-tools/seqstat.sh busadapt8 plane32bus tt_um_saltworks_ndf_c32
./docs/silicon-tools/areacite.sh tt_um_saltworks_ndf_c32      # figure WITH its sha

# 2. assemble INTO the template clone. Refuses if the manifest disagrees with the
#    closure; exits 3 if the tree is incomplete — a wrong tree cannot reach the remote.
./SaltWorks/Silicon/TTNDF/assemble.sh <template-clone>

# 3. the offline pre-flight, with its own 11 mutations
python3 SaltWorks/Silicon/TT/validate.py --tree <template-clone>

# 4. only now: commit and push in the clone. Then CI, in the ORDER of §6.
```

## 5 · THE RECEIPT SHAPE, PRE-DECLARED

*So the first verdict lands in a form the fleet already reads, and nobody decides
afterwards what would have counted.*

```
RUN      which workflow · which commit sha · which tools-ref sha
         (C.1: tools-ref is a FLOATING branch. Pin it and record it, or two runs
          are not comparable at all.)
TIMING   the STA number at CLOCK_PERIOD 55 ns, quoted WITH the sha.
         A 55 ns FAILURE REVERTS THE BYPASS AND IS REPORTED AS A FINDING.
         Pre-agreed at 449992b. No renegotiation.
FIT      placed/routed or not, and the utilization LibreLane reports.
         NOT my 33.51% — that is summed cell area over the die box and is NOT a
         utilization. Different measurements; never compared as percentages.
GL TEST  pass/fail per assertion. A RED HERE IS PRESUMED TO BE MY BENCH, NOT THE
         DESIGN, until shown otherwise: test/ is MARKED UNRUN and no assertion of
         it has ever executed.
AREA     quoted only through areacite.sh, so it carries its sha.
```

## 6 · THE JUDGMENT I WAS ASKED FOR — TWO RUNS, IN THIS ORDER

**The first run is being asked three questions and they do not all belong together.**

```
(a) TIMING referee for the bypass     both come from the HARDEN step (LibreLane STA
(b) FIT signoff for _c32              plus place/route). THEY CANNOT BE SEPARATED,
                                      and should not be: one hardening, both
                                      properties of it.
(c) first elaboration by the tool     the `test` workflow — a DIFFERENT workflow,
    that actually matters             and per the checklist it has NO PDK.
```

⇒ **RUN THE `test` WORKFLOW FIRST, ALONE. THEN `gds`.** The reason is specific, not
tidiness:

⛔ **`gl_test` LIVES INSIDE `gds.yaml`, AND IT RUNS MY UNRUN ASSERTIONS.** If one is
wrong — and none has ever executed — it reddens the WHOLE gds action, and TT will not
accept a project whose gds action is failing. ***SO A BUG IN MY BENCH WOULD PRESENT AS
A SUBMISSION-BLOCKING DESIGN FAILURE, AND THE TIMING AND FIT VERDICTS THAT WERE
ACTUALLY ORDERED WOULD ARRIVE CONTAMINATED BY IT — OR NOT ARRIVE AT ALL.***

⇒ The `test` workflow is cheap, needs no PDK, and converts my four unrun assertions
into receipts IN ISOLATION. **Spend that run first: it is the difference between
"assertion 3 is wrong" and "the shuttle candidate is red".**

📌 **IF ONLY ONE RUN IS POSSIBLE**, run `gds` and read any `gl_test` failure under the
presumption above — but that presumption has to be stated BEFORE the number arrives,
which is what this section is.

## 7 · WHAT IS STILL NOT TRUE

- **No timing, no fit, no layout receipt.** The bypass is RATIFIED AND TIMING-UNJUDGED.
- **`test/` is MARKED UNRUN.** `test.py` parses; `tb.v` elaborates; no assertion has run.
- **The repo does not exist.** §4 step 0 is the Captain's hand alone.
- **Criterion (c) is open**, and compiler's read says `decQ` cannot help: a
  wrong-operand store satisfies `ObservesRetire`.
