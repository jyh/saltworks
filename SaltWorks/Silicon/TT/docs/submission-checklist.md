# TTSKY26c SUBMISSION CHECKLIST — what is prepared, what is owed, what JYH clicks

### Status as of 2026-08-06 16:2x PDT, SILICON seat. Deadline **2026-09-07
### 13:00 PDT** (20:00 UTC — no human-readable TT page states the time).
### Internal target: **submit a real revision by Aug 31.** A revision can be
### replaced any number of times before the deadline, so there is no cost to
### submitting early and every cost to submitting late.

## A. Prepared by the fleet — no account, no card

| # | Item | State |
|---|---|---|
| P1 | `src/project.v` — the fabric in TT's fixed port list, `default_nettype none`, unused-input sink, every output assigned | ✅ |
| P2 | `info.yaml` — 24 pinout keys, `clock_hz` as an **int**, `top_module` prefixed `tt_um_`, explicit `source_files` | ✅ **validated, 5/5 checks, and the validator self-tests with 10 negative controls** |
| P3 | `docs/info.md` — How it works / How to test fully rewritten; carries the honest fence (only 4,096 of 40,320 full-load permutations route; the sorter is on neither the chip nor in Lean) | ✅ |
| P4 | `test/` — a real cocotb bench | ✅ **RTL: 3/3, 255/255.** ✅ **GATE LEVEL: 3/3, 255/255 against real sky130 cells** (`test/gl_local.sh`) — unpowered, pre-P&R; the powered post-layout form is still CI's (C.3) |
| P5 | `src/config.json` — `CLOCK_PERIOD` 20 ns, `PL_TARGET_DENSITY_PCT` 60, and nothing that `user_config.json` would silently override | ✅ |
| P6 | Apache-2.0 headers in every file we authored | ✅ (the `LICENSE` file itself comes from the template) |
| P7 | **Local dry run: LibreLane 3.0.5 + precheck** | ⛔ **BLOCKED — LibreLane is not installed on the Mini.** yosys, iverilog and a sky130 PDK now are |
| P8 | **Pin `tools-ref` to a SHA** in `.github/workflows/gds.yaml` | ⛔ **OWED, and newly urgent — see C.1** |

## B. The human's clicks — JYH only, in order

| # | Action | Where | Blocking |
|---|---|---|---|
| H1 | ~~Buy the tiles~~ ✅ **DONE 2026-08-06 — 4 tiles (2×2), €280** | — | closed |
| H2 | Create the repo from the template: **"Use this template" → "Create a new repository"** | `github.com/TinyTapeout/ttsky-verilog-template` | yes |
| H3 | **Enable Actions** — Actions tab → "enable actions" | the new repo | yes |
| H4 | **Enable Pages** — Settings → Pages → Source: **GitHub Actions** | the new repo | yes (else `viewer` fails) |
| H5 | Sign in with **GitHub OAuth** (the only login method) | `app.tinytapeout.com/projects/create` | yes |
| H6 | "Create a new project" → paste the repo URL → "Create Project" | same | yes |
| H7 | **Pay by card** (Stripe) — this accepts the Terms | same | yes |
| H8 | ⚠️ **PRESS "Submit a new revision".** *Paying is NOT submitting* — the classic miss | same | **yes** |

Once H2 exists, `./assemble.sh <clone-of-the-new-repo>` drops everything in A
into place; `./validate.py` checks it; nothing else is hand-copied.

## C. Open items that change what gets submitted

### C.1 `tools-ref` is a FLOATING branch, and it moved today

`.github/workflows/gds.yaml` pins only `TinyTapeout/tt-gds-action@ttsky26c`; it
does **not** pass `tools-ref`, which therefore defaults to `tt-support-tools`
**`main`** — observed at `8bca34a`, committed **2026-08-06**, i.e. it moved on the
day we were reading it. **Two CI runs days apart are not comparable**, and the
netlist we prove things about is produced by whatever `main` said that morning.

⇒ Pin it, record the SHA beside the equivalence proof, and compare
`commit_id.json` across any two runs **before** reading anything else from them.

### C.2 ⚠️ THREE PDK REVISIONS ARE IN PLAY AND OURS IS A FOURTH QUESTION

| revision | role |
|---|---|
| `0536d02d…` | TT **precheck** only (evidence's 10:52 correction — it was published as "the revision to match" in four places and is not) |
| `8afc8346…` | TT **hardening** — the netlist/GDS revision, i.e. the one that builds the bytes we intend to prove about |
| `c6d73a35…` | what **`Flow/synth.sh` pins**, and therefore what the local `banyan_fabric_nl.v` under proof was built against |

**Our local artifact is built against a revision that is neither of TT's.** For
the local dev loop that is harmless — the netlist is untrusted by construction and
a bad one fails the equivalence check rather than producing a false theorem. It
stops being harmless the moment a **cell model** written against one revision is
used to certify a netlist built by another. ⇒ Before D5 closes: verify the ~30
`sky130_fd_sc_hd` cell models are revision-invariant, or re-pin `synth.sh` to
`8afc8346…` and re-derive. **Not yet checked — stated, not assumed.**

### C.3 Gate level — now exercised locally, but not in the form that ships

`gl_test` is a job inside the `gds` workflow, so a gate-level failure reddens
`gds`, which is **blocking for submission**.

✅ **Run, and green: 3/3 tests, 255/255 scenarios against real `sky130_fd_sc_hd`
standard cells** — `test/gl_local.sh`, with the shipped `tb.v` unmodified. That
retires the risk that the bench simply does not work against gates (X-propagation
from uninitialised flops, a reset that never takes, a cell model that disagrees
with the RTL).

⚠️ **What it is not**, stated so a green line here is not read as more than it is:
the local netlist is **unpowered** (so `-DGL_TEST` is deliberately not passed) and
**pre-place-and-route** — functional models at unit delay. It says nothing about
setup and **nothing at all about hold**, which is the residual risk. The shuttle
builds *powered* netlists and CI runs the powered, post-P&R form.

⇒ The first CI run remains the first test of the **powered post-layout** path.
Schedule it early enough that a surprise there is cheap.

### C.4 The public-repo ruling is the gate on everything in B

Apache-2.0 and publication are contractually **mandatory**; the maestro
recommended YES at 09:13 and the Captain's ruling is owed. Until then H2 cannot
happen — and neither can the two `(* keep *)` CI arms, which need nothing but a
repo and ten minutes of Actions.

## D. What a green submission will and will not mean

A green `gds` + `precheck` + `gl_test` means the design hardens, passes DRC and
behaves at gate level. **It does not mean the fabricated netlist is equivalent to
the Lean specification** — that is a separate obligation, against the same
artifact (`tt_submission/tt_um_saltworks_banyan.v`), and it is the whole point of
the leg. Do not let a green CI badge stand in for the certificate.
