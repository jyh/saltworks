# TTSKY26c SUBMISSION CHECKLIST — what is prepared, what is owed, what JYH clicks

### Status as of 2026-08-06 16:2x PDT, SILICON seat. Deadline **2026-09-07
### 13:00 PDT** (20:00 UTC — no human-readable TT page states the time).
### Internal target: **submit a real revision by Aug 31.** A revision can be
### replaced any number of times before the deadline, so there is no cost to
### submitting early and every cost to submitting late.

> ⛔⛔ **SCOPE AND STALENESS BANNER — ADDED 2026-08-19, READ BEFORE ACTING ON ANY ROW.**
> **THIS DOCUMENT'S SUBJECT IS `jyh/tt-verified-banyan-switch`** (named in §C.4) — the
> BANYAN submission. **It is NOT the `_c32` neural-dataflow submission**, which lives in a
> SEPARATE public repo, `jyh/tt-neural-dataflow-fabric`, with its own project entry.
> ⛔ **§C.4's "the repo must go public" blocker WAS DISCHARGED FOR THE NDF REPO ON 08-10**
> — it was public, and fully green, for nine days while briefs still quoted this row as a
> live blocker. **A seat lost four hours on 08-19 obeying it.** The row is not wrong; it is
> *dated*, and it is *about the other repo*.
> ⇒ ***A CHECKLIST IS A PLAN, NOT A STATE.*** Every row here asserts a status as of the date
> in its header. Before acting on one, **re-derive it from the machine** — `gh repo view`,
> `gh run list` — and treat this file as the record of what was *intended*, never of what
> *is*. The rows that stop work (blockers) are the ones to re-derive first, because a false
> blocker produces no activity to inspect and so is never noticed.

## A. Prepared by the fleet — no account, no card

| # | Item | State |
|---|---|---|
| P1 | `src/project.v` — the fabric in TT's fixed port list, `default_nettype none`, unused-input sink, every output assigned | ✅ |
| P2 | `info.yaml` — 24 pinout keys, `clock_hz` as an **int**, `top_module` prefixed `tt_um_`, explicit `source_files` | ✅ **validated, 5/5 checks, and the validator self-tests with 10 negative controls** |
| P3 | `docs/info.md` — How it works / How to test fully rewritten; carries the honest fence (only 4,096 of 40,320 full-load permutations route; the sorter is on neither the chip nor in Lean) | ✅ |
| P4 | `test/` — a real cocotb bench | ✅ **RTL: 3/3, 255/255.** ✅ **GATE LEVEL: 3/3, 255/255 against real sky130 cells** (`test/gl_local.sh`) — unpowered, pre-P&R; the powered post-layout form is still CI's (C.3) |
| P5 | `src/config.json` — `CLOCK_PERIOD` 20 ns, `PL_TARGET_DENSITY_PCT` 60, and nothing that `user_config.json` would silently override | ✅ |
| P6 | Apache-2.0 headers in every file we authored | ✅ (the `LICENSE` file itself comes from the template) |
| P7 | **Dry run: LibreLane 3.0.5 + precheck** | ✅ **DONE IN TT's OWN CI, which is better than local:** the design hardens, **Precheck PASSES**, and **GL test PASSES against the powered post-layout netlist** |
| P8 | **Pin `tools-ref` to a SHA** in `.github/workflows/gds.yaml` | ✅ **SATISFIED-BY-RECORDING — helm ruling 2026-08-19 12:10:14, superseding the ⛔ OWED below.** **DO NOT PIN.** *Reason, in the helm's terms: the shuttle hardens with TT's own server-side action version regardless, so a local sha pin **cannot bind the referee** and buys only template divergence — and `.github/` shipping byte-verbatim is itself a submission property. The reproducibility instrument is a **per-run receipt of the RESOLVED sha**, not a pin.* **Standing duty this creates: resolve and record `ttsky26c` immediately before each submission act** (`gh api repos/TinyTapeout/tt-gds-action/git/ref/tags/ttsky26c --jq .object.sha`) — it is a **movable tag** and Actions resolves it at run time, so a stale flow would otherwise arrive silently. Recorded 2026-08-19: `651ea05e19e86a9c26d00307e8081ceb53d328d3`, **re-checked and UNMOVED** since first pinned. *Reversible at a word if TT's flow proves otherwise.* — *original entry, kept because its observation is still true and is the reason a pin looked necessary:* ⛔ OWED — see C.1. Two runs four minutes apart came out identical (`pdk.json` byte-identical, `resolved.json` zero differing keys), which is luck, not pinning |

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
used to certify a netlist built by another.

✅ **CHECKED, AND IT CLOSES — both revisions installed and compared file by file.**

| | |
|---|---|
| files differing across the whole PDK | **4,868** — the revisions are genuinely distinct |
| of those, inside `sky130_fd_sc_hd` | **893** |
| …in `mag/`, `maglef/`, `gds/`, `spice/` | **893 — all of them** |
| …in `lib/` or `verilog/` | **0** |

The liberty corner we synthesize against (`sky130_fd_sc_hd__tt_025C_1v80.lib`)
and the behavioural models the gate-level sim executes (`sky130_fd_sc_hd.v`,
`primitives.v`) are **byte-identical between the two revisions**, and every
`function` / `next_state` for our **13 modelled cells** matches.

⇒ **The precheck-vs-hardening distinction does not reach our cell models.** It is
real, and it lives entirely in layout and extraction views — which matter for DRC,
LVS and GDS, and not for the logical chain. `synth.sh` may stay pinned where it
is. *Established between these two revisions only; a third would need the same
check, which is now one command.*

**Also corrected here:** the freeze's estimate of "~30 cell models" is **13** —
`clkinv_1 nand2_1 and2_0 a22oi_1 a31oi_1 a222oi_1 o22ai_1 o2bb2ai_1 mux2_1
mux2i_1 lpflow_inputiso1p_1 lpflow_isobufsrc_1 dfxtp_1`.

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

### C.4 ⚠️ THE REPO MUST GO PUBLIC FOR THE GDS ACTION TO GO GREEN

Ruled GO by the Captain (8/6): create now, **private until CI green, then flip
public**. Repo: **`jyh/tt-verified-banyan-switch`**, H2 done.

**That sequencing turns out to be circular, and it is the one live blocker.** The
`gds` workflow's fourth job is `viewer`, which deploys to **GitHub Pages** —
and `POST /repos/…/pages` returns:

```
422  Your current plan does not support GitHub Pages for this repository.
```

because the repository is **private**. `viewer` lives inside `gds.yaml`, so its
failure reddens the whole GDS action, and TT's rule is *"a project can't be
submitted to a shuttle if its GDS action is failing."*

⇒ **CI cannot go fully green while the repo is private, so "private until green"
cannot be satisfied.** Every substantive gate — harden, precheck, gl_test, docs,
RTL test — has already passed. **The resolution is one bit: make the repo public
(Pages works on public repos at any plan), or upgrade the plan.** It is the
Captain's, not this seat's.

## D. What a green submission will and will not mean

A green `gds` + `precheck` + `gl_test` means the design hardens, passes DRC and
behaves at gate level. **It does not mean the fabricated netlist is equivalent to
the Lean specification** — that is a separate obligation, against the same
artifact (`tt_submission/tt_um_saltworks_banyan.v`), and it is the whole point of
the leg. Do not let a green CI badge stand in for the certificate.
