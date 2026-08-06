# D1 — THE PINNED FLOW (Silicon seat, leg 3)
### 2026-08-06. Every version below was read off the running tool or the
### artifact itself on this machine today. Nothing here is quoted from memory.

## 0. What D1 was, and what it actually is now

The freeze's D1 reads: *"LibreLane up via Nix; the comparator cell through the
flow; hardware.log of versions pinned in docs/."*

The refuter pass (`docs/silicon-refuter-0806.md`) changed two things about it:

1. **LibreLane via Nix is blocked on a human action.** `nix` is not installed
   here and installing it needs `sudo`. `docker` is absent too.
2. **It is also no longer the spine.** The netlist that gets fabricated is built
   by TinyTapeout's CI, not by our local run — so a local LibreLane is a
   convenience for iteration, not the artifact under proof. And LibreLane's
   two-year-old cross-OS determinism bug (#522) means the final pass must run on
   Linux regardless.

So D1 split. The half that does not need `sudo` is **done and reproducible**;
the half that does is stated below as a blocked item with a recommendation.

## 1. Installed and pinned, here, now

| component | version / pin | how obtained | sudo? |
|---|---|---|---|
| macOS | 26.5.2, arm64 (18 cores, 64 GB) | — | — |
| Lean toolchain | `leanprover/lean4:v4.32.0-rc1` | `lean-toolchain` (repo) | no |
| mathlib | `v4.32.0-rc1` | `lakefile.toml` (repo) | no |
| yosys | **0.68+post**, git `c12172fbae8af5e20f6fb52e3d4e92d56ed587b6`, arm64 native | `brew install yosys` | no |
| sky130A PDK | **`c6d73a35f524070e85faff4a6a9eef49553ebc2b`** | `volare enable --pdk sky130 <sha>` (pip, user-local, 2.1 GB) | no |
| Liberty corner | `sky130_fd_sc_hd__tt_025C_1v80.lib` (typical, 25 °C, 1.80 V) | in the PDK above | no |

`volare` itself is pip-installed into a throwaway venv; it is a fetcher, not a
dependency of anything we ship.

## 2. The pins we do NOT control — TT's CI builds the fabricated netlist

From the evidence seat's URL-tagged dossier (`docs/tinytapeout-dossier.md` §6),
cross-checked here against the PDK:

| what | pin | note |
|---|---|---|
| LibreLane (TT CI `gds` job) | **`3.0.5`** | our local flow must match to have any hope of reproducing |
| **PDK the netlist is HARDENED against** | **`8afc8346a57fe1ab7934ba5a6056ea8b43078e71`** | ✅ **this is the one that matters** |
| PDK (TT user *precheck* only) | `0536d02d875c8f67dd7cca3902ac457e62f20005` | GDS/DRC checks in a Nix shell — **not** the hardening PDK |
| PDK (shuttle `BUILDING.md`) | `6d4d11780c40b20ee63cc98e645307a9bf2b2ab8` | **stale** |
| PDK we fetched locally | `c6d73a35f524070e85faff4a6a9eef49553ebc2b` | volare's newest; a fourth value |
| `tt-support-tools` | **unpinned — defaults to a moving `main`** | no `ttsky26c` tag exists; `main` moved on 8/6 while the shuttle pins its submodule at 7-29 |

⚠️ **CORRECTION (recorded, because the wrong pin was published first).** An
earlier version of this table — and a fleet-bus post — named `0536d02d…` as the
PDK to re-pin to. That is the **precheck-only** revision. The netlist and GDS are
hardened against **`8afc8346…`**. Four sky130A revisions are in play; getting
this wrong would have pinned the local flow to a PDK that never touches the
fabricated artifact. See `docs/silicon-refuter-0806-addendum.md` §0.

**Two actions this table forces, and they are D1 exit criteria, not D5 items:**

- **Re-pin the local PDK to `8afc8346…`** before any number is published, and
  fix `Flow/synth.sh`'s hard-coded default. The measurements already taken are
  about Liberty functions and cell counts, which do not move between open_pdks
  builds, so they stand; anything timing- or area-sensitive must be re-run.
- **Pin `tools-ref` to a commit SHA** in the TT workflow `with:` block, and
  record that SHA next to the proof. A moving `main` under a reproducibility
  claim is not a reproducibility claim.

## 3. Done: the comparator (and the switch) through real sky130 synthesis

Reproduce:

```bash
SaltWorks/Silicon/Flow/synth.sh comparator
SaltWorks/Silicon/Flow/synth.sh bitserial_switch
```

Sources in `SaltWorks/Silicon/RTL/`, outputs (netlist + cell histogram) in
`SaltWorks/Silicon/Flow/`. Both committed so a reader can diff their own run.

| design | cells | distinct types | area |
|---|---|---|---|
| `comparator` — 8-bit unsigned min/max, 16 input bits | 36 | 12 | 272.76 µm² |
| `bitserial_switch` — the 2×2 bit-serial element | 18 | 6 | 172.67 µm² |

(The switch element grew from 8 cells / 95.09 µm² when the **activity bit** was
added to fix the routing bug — see `RTL/bitserial_switch.v`. Two flops and the
activity-gating logic; `nand3_1` joins the cell set. Worth the doubling: without
it the element cannot distinguish an idle port from destination-bit-0.)

Extrapolated to the tapeout target: an 8×8 bit-serial banyan is 3 stages × 4
elements = **12 elements ≈ 216 cells ≈ 2,072 µm²**, against a 1×1 TT tile of
161.00 × 111.52 µm ≈ 17,955 µm² — **about 12 % of one tile**, and 4 tiles (2×2)
are bought. The freeze's "1299 gates vs 1000/tile, 2 tiles" reasoning was
measuring the *word-parallel* fabric and does not apply.

⚠️ But note what real submissions measure: **4,220 / 4,645 / 5,344 cell
instances each**, because TT pads every tile — so the *file* the importer must
eat is ~4–5 k instances and ~18 k lines regardless of how small our logic is.
Area is not a design constraint here; the pin count, the **33 MHz output-pad
ceiling**, and **hold** (not setup) are.

The cell set is the union of both designs — **13 distinct cells out of the 428
in `sky130_fd_sc_hd`** (measured: `extract_liberty.py --all | grep -c 'in=('`),
not the ~30 budgeted. That is 3 % of the library, and it is the number that makes
"a trusted cell-model set reviewable in an afternoon" credible. Their exact
Boolean functions are extracted mechanically from the PDK's own Liberty by
`SaltWorks/Silicon/Cells/extract_liberty.py` — the provenance we want for a
*trusted* set: derived from the vendor's machine-readable spec, not hand-guessed.

```
mux2_1     in=(A0,A1,S)     X = (A0&!S) | (A1&S)
o2bb2ai_1  in=(A1_N,A2_N,B1,B2)  Y = (!B1&!B2) | (A1_N&A2_N)
dfxtp_1    in=(CLK,D)       Q = IQ   [FF IQ,IQ_N: next_state=D clocked_on=CLK]
```

⚠️ **The cell set is a property of the flow configuration, not of our design.**
`abc` selected two `lpflow_*` power-isolation cells (`lpflow_inputiso1p_1`,
`lpflow_isobufsrc_1`) as ordinary datapath logic with `SLEEP` driven by real
data. LibreLane's sky130 flow normally excludes those. So this 13-cell set must
**not** be frozen as the trusted set — it will be re-derived against the TT-CI
configuration, with an explicit don't-use list so the set is small *by
construction rather than by luck*.

## 4. Blocked, with a recommendation

**Blocked:** local LibreLane → P&R → GDSII → a genuine *post-route, powered*
netlist. Needs `nix`, which needs one `sudo` from JYH.

**Recommendation: do not spend the day on it.** The final pass must run on Linux
anyway (#522), and the artifact under proof is TT CI's `tt_submission/<top>.v`.
The higher-value path is a pinned Linux runner reproducing `librelane==3.0.5` +
PDK `0536d02d…`. A local macOS LibreLane buys only iteration speed.

**Consequence for D2 — and this exit criterion is now DISCHARGED.** Nine genuine
powered post-P&R netlists were obtained from the public TT shuttle repos, three
of them built by `librelane 3.0.5` for TTSKY26c itself. The provenance is pinned
to a line of code: `tt-support-tools/project.py:575-611` copies
`runs/wokwi/final/pnl/<top>.pnl.v` → `tt_submission/<top>.v`. So the freeze's
`final/nl/<design>.logical_nl.v` is wrong in **both** directory and suffix —
`nl` is the *unpowered* netlist.

⚠️ **And the post-synthesis grammar did NOT carry over.** Measured across 14 real
files: `assign` statements in **every** one (18–22 each); escaped identifiers in
13 of 14, up to **1,573** each, embedding `.`/`[`/`]`; constants delivered by
`conb_1` **tie cells**; instances **omit** unconnected pins rather than writing
`.PIN()`. The escaped-identifier case is a **soundness** hazard, not a parse
failure: `\cnt[0] ` terminates on whitespace and is an *atomic scalar net*, so a
parser that strips the backslash and reads `[0]` as a bit-select aliases distinct
nets onto one. Full corrections in `docs/silicon-refuter-0806-addendum.md`.
