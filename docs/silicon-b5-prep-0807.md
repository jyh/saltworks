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

## 5. What this does NOT say

* It does **not** say the revision is ready. Two gates are open, and the `test`
  fix does not close the other one.
* It does **not** re-price area or tiles. The 2×2 headroom claim is inherited
  from `info.yaml`; **what I measured is that `precheck` passes**, which is the
  question KB4 actually asked.
* It does **not** certify the testbench. `gl_test` green says the bench passes at
  gate level **on the cases it runs** — I have not audited its coverage, and a
  passing bench is not a proof. The kernel proof is the proof.
