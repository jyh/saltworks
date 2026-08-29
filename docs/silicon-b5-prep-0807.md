# B5 PREP — the resubmission, measured at the repo rather than planned

### 2026-08-07 ~15:30, SILICON. B5 = *"THE REVISION: resubmitted to TTSKY26c
### before Sept 7 close… replaces the floor ONLY when CI is green and B4 is in
### the kernel"* (`bb1-composed-switch-addendum.md:67`).

## VERDICT: **B5 has exactly TWO open gates. One is compiler's seam. The other
## is a RED `test` job that is MINE — and it is a source-list defect, not a
## design defect, which `gl_test` passing on the same commit proves.**

---

## 1. The board, every row measured (not one inherited from a doc)

| gate | state | evidence |
|---|---|---|
| tiles bought (H1) | ✅ **4 tiles, 2×2, €280** | dossier §7.2, closed 8/6 |
| submission repo exists (H2–H8) | ✅ **`jyh/tt-verified-banyan-switch`**, public | `gh repo list` |
| **the FLOOR is safe** | ✅ **`main` ALL GREEN** — `test` · `docs` · `gds` | run 31140274747, 8/7 02:08 UTC |
| revision branch exists | ✅ **`revision-bb1-composed`** | `gh api …/branches` |
| revision `gds` workflow | ✅ **`gds` · `precheck` · `viewer` · `gl_test` ALL GREEN** | run 31214859139, 9m19s |
| revision `test` workflow | ⛔ **RED**, 24 s, 505 elaboration errors | run 31214860446 |
| B4 in the kernel | ⛔ **conditional** on compiler's `hseam` | `ComposedSwitch.lean` |

⭐ **KB4 IS ANSWERED, EMPIRICALLY AND IN OUR FAVOUR.** The kill-check read
*"the revision's gds/precheck must pass with ~2.6× logic — no reason to fail,
**but measured not assumed**."* ⇒ **It is now measured: `precheck` — the blocking
job — is GREEN on the composed design, as are `gds`, `viewer` and `gl_test`.**
*The 2×2 was bought on "12% of one tile is the logic"; the composed design
hardens inside it with the precheck passing.*

## 2. The one red job, diagnosed at the log

```
src/batcher_struct.v:1128: error: Unknown module type: sky130_fd_sc_hd__and2_1
…
505 error(s) during elaboration.
*** These modules were missing:
      sky130_fd_sc_hd__and2_1  referenced 144 times
      sky130_fd_sc_hd__inv_1   referenced 120 times
      sky130_fd_sc_hd__mux2_1  referenced 120 times
      sky130_fd_sc_hd__or2_1    referenced  72 times
      sky130_fd_sc_hd__xor2_1   referenced  48 times      (= 504 instances)
make[1]: *** [sim_build/rtl/sim.vvp] Error 249
```

**`test/Makefile` puts `batcher_struct.v` in `PROJECT_SOURCES`, and the RTL
branch (`ifneq ($(GATES),yes)`) hands it to Icarus with NO cell library.**
`batcher_struct.v` is a 42 KB **structural sky130 netlist** — the 504 cells are
compiler's own count from the 12:5x bus line. ⇒ ***The RTL target is being fed a
GATE netlist. Icarus is right and the source list is wrong.***

🔑 **AND THE PROOF THAT NOTHING IS WRONG WITH THE DESIGN IS ON THE SAME COMMIT:
`gl_test` — the SAME testbench against the POWERED post-layout netlist — PASSES.**
*A design defect would redden both. Only the target that lacks the library is
red.* **This is a configuration defect with a one-line blast radius, sitting on
the critical path of a submission.**

## 3. The fix — and the obvious route is the WRONG one

| | route | verdict |
|---|---|---|
| ① | **Give the RTL target the cell models** — add sky130's `primitives.v` + `sky130_fd_sc_hd.v` to `VERILOG_SOURCES` in the RTL branch, as the `GATES=yes` branch already does | ✅ **CORRECT** |
| ② | Ship a **behavioural** Batcher for the RTL target, keeping the structural one only for `gds` | ⛔ **REJECT** |

⛔ **Route ② is against this repo's whole thesis, and I want the reason recorded
because it is the kind of fix that looks tidy.** The repo's claim is *"the gate
netlist is proved equivalent to its Lean specification."* **Simulating a
DIFFERENT, behavioural file in CI would mean the thing tested is not the thing
fabricated — which is precisely the gap this campaign exists to close.** *It also
doubles the hand-synced surface between `info.yaml:source_files` and
`PROJECT_SOURCES`, which both files warn has no checker.*
⇒ **Route ① makes the "RTL" sim a gate sim in all but name, and that is HONEST:
our source genuinely IS a gate netlist. Synthesis-as-passthrough is the claim,
not an accident.**

## 4. What I am NOT doing, and why

⚠️ **I am not pushing the fix.** The repo is **public**, it is the Captain's live
submission artifact, and the dossier's H-series is explicitly *"JYH only"*.
`test/Makefile` is P4 (Silicon) by the fleet's own allocation, so the FILE is
mine — but the decision in §3 is a claim-level one about what CI simulates, not a
config tweak, and **B5 cannot fire today regardless: B4 is still conditional on
compiler's seam.** ⇒ **There is no urgency that justifies acting unilaterally on
the Captain's submission repo. Maestro sequences it; I build it on the word.**

---

## 4b. ADDENDUM ~16:1x — THE FIX IS LANDED, AND THE PROVENANCE PINS ARE RECORDED

**Maestro's word given; route ① landed on `revision-bb1-composed` (`0b03051`).
`main` untouched at `f14a4fa`.** `test` ✅ 33 s (run `31226212805`), `docs` ✅.

**Verified LOCALLY before the public push** (iverilog 13.0, cocotb 2.0.1 on a
Python 3.13 venv — 3.14 is on this box and cocotb will not run there):

```
without models :  505 error(s) during elaboration   ← byte-identical to CI's
with models    :  EXIT=0, sim.vvp built
full testbench :  TESTS=3 PASS=3 FAIL=0  — 255/255 sorted+concentrated
                  destination sets route correctly
```

### 📌 THE TWO PINS — this is P8's "record it beside the equivalence proof"

| what | value | how it was obtained |
|---|---|---|
| **PDK** | `sky130A` @ **`8afc8346a57fe1ab7934ba5a6056ea8b43078e71`** | read from `pdk.json` **inside the `tt_submission` artifact** of green run `31214859139` — *not remembered*. `FLOW_NAME LibreLane`, `FLOW_VERSION 3.0.5`, `PDK_SOURCE open_pdks`. This is the **hardening** revision, distinct from the precheck-only `0536d02d…` the dossier §6.4 separates. |
| **Flow** | `TinyTapeout/tt-gds-action` @ **`651ea05e19e86a9c26d00307e8081ceb53d328d3`** | `gh api repos/TinyTapeout/tt-gds-action/commits/ttsky26c` → 2026-07-30. **`ttsky26c` is a TAG** (`branches/ttsky26c` 404; `git/ref/tags/ttsky26c` hits), and a tag can be re-pointed. |

⚠️ **AND THE OBLIGATION THAT MAKES PINNING SAFE RATHER THAN MERELY TIDY —
RE-CHECK BOTH BEFORE SUBMITTING.** *Pinning freezes the flow; freezing is only
correct if someone looks again.* **If TinyTapeout moves `ttsky26c` to fix
something the shuttle requires, a pinned repo silently keeps the old flow and can
fail the shuttle's own re-run of `precheck.py` on the submitted `.oas`.** ⇒
**Compare, then re-pin deliberately. Do not drift, and do not freeze blindly.**

> ### ⛔ ANNOTATED FORWARD 2026-08-28 18:1x — NOT REWRITTEN, per the fleet law ruled at 17:27
> *(a record that asserts the PRESENT gets corrected; one that asserts WHAT WAS KNOWN AT A TIME gets
> annotated. The obligation above is live and stands; the mechanism it describes is not ours.)*
>
> **THE OBLIGATION HAD NO INSTRUMENT FOR 21 DAYS. IT HAS ONE NOW:
> `docs/silicon-tools/pincheck.sh` (+ `pins.conf`, `pincheck_selftest.sh` 6/6).**
> **MEASURED 18:0x: both pins as recorded — `ttsky26c` still points at `651ea05e…`, and the
> submitted artifact's `pdk.json` still reads `8afc8346…`.**
>
> ⛔ **AND THE PARAGRAPH ABOVE DESCRIBES THE OPPOSITE RISK FROM THE ONE WE CARRY.** It warns that
> *"a pinned repo silently keeps the old flow"*. **Measured at the object: our submitted workflow
> does NOT pin a sha — it references the TAG**, four times in `.github/workflows/gds.yaml` at commit
> `7d2b2756` (`TinyTapeout/tt-gds-action@ttsky26c`). ⇒ **we do not silently keep the OLD flow; we
> silently take the NEW one.** The sha recorded in §THE TWO PINS is therefore **a dated observation
> of where a movable tag pointed, not an enforcement.**
> ⇒ ***A RECORDED PIN AND AN ENFORCED PIN READ IDENTICALLY IN A DOCUMENT AND BEHAVE OPPOSITELY IN A
> RE-RUN*** — which is exactly why the obligation needed a command rather than a sentence.

The same warning is in `.github/workflows/gds.yaml` itself, where the next
person to touch it will see it.

### ⛔ STILL OPEN, and NOT mine

**The revision's public identity still describes the FLOOR.** `info.yaml`'s title
(*"Verified 8x8 bit-serial banyan switch"*) and description (*"Recreates the
banyan **half**…"*), and `docs/info.md:17` (*"the banyan is the theorem. **This
chip is the proved half.**"*). **The revision is BOTH halves** — `batcher_struct.v`
and `banyan_fabric.v` are both in `src/` and both in `source_files`. That
sentence goes false the moment the revision replaces the floor, and it is what a
gallery reader sees. **P2/P3 — evidence drafts, this seat confirms.**

✅ **One clean check worth recording as a non-finding:** `info.yaml:source_files`
and `test/Makefile:PROJECT_SOURCES` **agree**. Both files warn that nothing
checks their agreement; on this branch they are in sync. *I went looking and
there is nothing there.*

---

## 4c. ADDENDUM ~16:4x — THE CI GATE IS CLOSED, AND A TIMING SURPRISE THAT IS
## REAL BUT NOT A FAILURE TO MEET SPEC

```
revision-bb1-composed   test ✅  docs ✅  gds ✅  precheck ✅  gl_test ✅  viewer ✅
main (the floor)        UNTOUCHED at f14a4fa
```
⇒ **B5's first gate is CLOSED. The second — "B4 is in the kernel" — is
compiler's seam, and it is the only thing left before the Captain's H8 click.**

**P8 landed** (`55fe7f5`): all four `tt-gds-action` refs pinned to
`651ea05e…`, taken *after* the full workflow went green so a red would have one
cause. `ciel-action@v1` deliberately **not** pinned — it installs the PDK for the
test runner, the PDK *version* is already pinned, and it never touches the
submitted artifact.

### ⏱️ THE TIMING FINDING — and the correction inside it

| | floor (`main`) | revision |
|---|---|---|
| `timing__setup_vio__count` | **0** | **24** (all at `ss` corners) |
| `timing__setup__wns` | 0.0 ns | **−3.455 ns** |
| `timing__setup__tns` | 0.0 ns | **−27.34 ns** |
| `design__instance__utilization` | 6.56 % | 15.28 % |
| `design__instance__count__setup_buffer` | — | **111** |

**BB-1 introduced them; the floor is clean at every corner — and `gds` and
`precheck` PASSED anyway, so TT's blocking checks do not gate multi-corner setup
timing.**

⚠️ **BUT THE DESIGN MEETS ITS DECLARED SPEC, and I had the opposite drafted.**
`CLOCK_PERIOD` (hardening constraint, `config_merged.json`) = **20 ns / 50 MHz**;
`clock_hz` (published spec, `info.yaml`) = **25 MHz / 40 ns**. They are
independent. Slow-corner path = `20 + 3.455` = **23.46 ns ≈ 42.6 MHz**, so at the
declared 25 MHz there is **~16.5 ns of margin**. ⇒ *A true reading against the
wrong reference* — the violations are against a frequency we never claim.

📌 **P5 RECOMMENDATION (mine), REVISED: `CLOCK_PERIOD` 20 → 30, not 40.** *40 ns
is exactly the declared period — zero design margin.* **30 ns clears all 24
violations, closes with ~6.5 ns slack at `ss`, keeps ≥10 ns against the published
25 MHz, and stops the flow spending 111 buffers chasing 50 MHz.** Hold is not at
risk either way: hold WS is +0.11…+0.90 ns with **0 violations at every corner**,
and relaxing a *setup* constraint does not tighten hold.
🔴 **It re-hardens the submitted artifact, so it is a RULING, not a tweak — and
it is not blocking: the current state meets spec and passes precheck.** *The Lean
proof is unaffected either way: it is about `batcher_struct.v`, the SOURCE.*

## 5. What this does NOT say

* It does **not** say the revision is ready. Two gates are open, and the `test`
  fix does not close the other one.
* It does **not** re-price area or tiles. The 2×2 headroom claim is inherited
  from `info.yaml`; **what I measured is that `precheck` passes**, which is the
  question KB4 actually asked.
* It does **not** certify the testbench. `gl_test` green says the bench passes at
  gate level **on the cases it runs** — I have not audited its coverage, and a
  passing bench is not a proof. The kernel proof is the proof.
