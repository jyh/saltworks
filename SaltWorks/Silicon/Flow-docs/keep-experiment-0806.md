# `(* keep *)` — THE A/B, RUN. And three corrections to the readout it was going to be read with.

### 2026-08-06, SILICON seat, Mac Mini. Design pre-registered by the EVIDENCE
### seat in `docs/EVIDENCE-ttci-keep-experiment.md` (ruling 4a) **before** this
### ran; the outcome table there is binding on the reading. This document
### reports the run, and reports that **none of its four rows is what a correct
### instrument returns** — the readout needed fixing first.

## What was run

Two arms differing by **exactly one line** of one file — the attribute, nothing
else (`diff` verified, 1 line):

| Arm | `RTL/banyan_fabric.v:63` |
|---|---|
| **A** (treatment) | `(* keep *) wire [7:0] w0, w1;` |
| **B** (control) | `wire [7:0] w0, w1;` |

Both hardened **`tt_um_saltworks_banyan`** — the TT top module, not the fabric —
which is confound 5.1 of the pre-registration, honoured. Real sky130 cells
(PDK `c6d73a35…`, fetched onto the Mini today), flattened and `splitnets`-split
the way LibreLane does.

## The result

| arm | boundary nets | vector decl `wire [7:0] w0;` | cells | area µm² |
|---|---|---|---|---|
| **A** | **16** (`\fabric.w0[0]` … `\fabric.w1[7]`), each driven by a real cell | **0** | 268 | 2143.31 |
| **B** | **0** — no trace, 0 mentions anywhere | 0 | 258 | 2105.77 |

Cost of the attribute: **+10 cells, +37.5 µm², +1.78 %** — consistent with the
1.7 % measured at 12:44.

### The cone census — the primary readout

| arm | cut set | cones | median in | **max in** | **≤ 24** |
|---|---|---|---|---|---|
| A | default (flops + outputs) | 61 | 12 | 36 | 86.9 % |
| B | default | 61 | 12 | 36 | **86.9 %** |
| **A** | **+ the kept boundaries** | 77 | 7 | **16** | **100.0 %** |
| B | + the kept boundaries *(requested; the nets do not exist)* | 61 | 12 | 36 | 86.9 % |

**`(* keep *)` takes the flattened TT top module to 100 % per-cone
certifiability, max 16 inputs — inside the 24-bit kernel ceiling with room.
Without it the cut is not merely worse, it is unavailable.**

---

## ⛔ THREE CORRECTIONS TO THE PRE-REGISTERED READOUT

Each was found by running the instrument, and each would have produced a wrong
verdict from a correct experiment.

### 1. The primary readout is treatment-INSENSITIVE as specified

Readout #1 is *"the cone census over `tt_submission/<top>.v`"*. Run as written —
`cones.py` with its default cut set — it returns **86.9 % in both arms**. The
census cannot see the attribute, because rooting cones only at flop D-pins and
primary outputs never cuts at the boundaries whether they survived or not.

The census answers *"how big are the cones this netlist happens to have"*. The
question is *"how small can the cones we certify be"*, and a proof may cut at any
net that **still exists** — which is the whole point of keeping it.

⇒ `cones.py` now takes **`--cut REGEX`**. The primary readout is the census
**cut at the kept boundaries**; the default census is the baseline, not the
verdict. Two numbers, and the pre-registration must name which one it means.

*This is the day's shape once more, on my own instrument: it answered a narrower
question than the one that mattered, and it answered it correctly.*

### 2. Readout #2 would report ABSENT in the arm where the boundaries SURVIVED

Readout #2 is *"declared nets matching `w0`/`w1`"*, and the local evidence for it
is `banyan_fabric_nl.v:261-262`, which literally reads `wire [7:0] w0;`.

**That declaration does not exist in the CI-shaped netlist — in EITHER arm.**
LibreLane runs `splitnets`, which our local flow does not; `splitnets` propagates
`keep` onto each bit (`splitnets.cc:72-74`) and then **deletes the parent vector**
(`splitnets.cc:246-249`). Flattening also prefixes the name with its instance
path. So the surviving nets are spelled:

```verilog
  wire \fabric.w0[0] ;   …   wire \fabric.w1[7] ;
```

A grep for `wire [7:0] w0` returns **0 for the treatment arm**. Combined with a
census that reads 86.9 % in both arms (correction 1), the pre-registered table
lands on row **(b) — "CI strips it", the expensive outcome** — when the truth is
row (a). **Two instruments, both individually reasonable, agreeing on a false
verdict.**

⇒ The grep is `\\fabric\.w[01]\[[0-7]\]`, and it must confirm each net is
**driven by a cell output pin**, not merely declared.

### 3. Our local flow cannot run this experiment at all

`synth.sh` does not flatten. Unflattened, `w0`/`w1` are inter-instance
connections and must exist regardless of any attribute — and indeed **arms A and
B come out byte-identical**. That is pre-registered row **(c), VOID as an
attribute test**, and it is a property of the flow, not of the design.

Any A/B on a non-flattening flow is void. Fixed: `synth.sh` now flattens.

---

## ⚠️ AND A DEFECT IN THE ARTIFACT'S PROVENANCE, FOUND ON THE WAY

`synth.sh` is headed *"sky130 synthesis, reproducible"*. It read `$RTL/$TOP.v`
and nothing else, so:

```
ERROR: Module `\bitserial_switch' referenced in module `\banyan_fabric'
       in cell `\e23' is not part of the design.
```

**The script could not produce the netlist the equivalence proof is taken
against.** `banyan_fabric_nl.v` is the artifact D3.5/D4 and every cone number
rest on, and it had no reproducible provenance from the repo.

Repaired — dependency closure plus `-flatten` — and **verified: the repaired
script reproduces the committed `banyan_fabric_nl.v` BYTE-FOR-BYTE.** Not
`$RTL/*.v`, because reading an unrelated module advances yosys's anonymous-net
counter and shifts every `_NNN_` name; the closure keeps the artifact byte-stable.

---

## The mechanism, from the source (LibreLane 3.0.5 / Yosys)

Read at pinned refs and adversarially re-verified; each survived a refutation
pass.

- `opt_clean`, **including `-purge`**, refuses to delete keep wires — the keep
  branch is evaluated *before* the purge branch (`passes/opt/opt_clean/wires.cc`).
- **`abc` marks a keep wire as a subject-graph port** (`abc.cc:2432-2434`), so it
  is a hard boundary of the mapped cone. **`keep` preserves the CUT, not merely
  the NAME** — which is why correction 1's number moves at all.
- `flatten` has no keep logic; it renames with the instance path and carries the
  attributes across.
- **Nothing in LibreLane 3.0.5 unsets `keep`** — no `setattr -unset keep`, no
  `attrmap -remove keep`. `write_verilog -noattr` strips the *attribute*, not the
  *wire*.

---

# ✅ THE CI ARMS RAN. RULING 4a CLOSES **YES**, ON THE FABRICATED ARTIFACT.

### 2026-08-06 18:3x. Repo `jyh/tt-verified-banyan-switch`, arms `f9a8ca0` (keep)
### and `0861169` (control), pushed four minutes apart, differing by ONE line.

**① Tooling equality, checked before anything else as the design requires:**
`pdk.json` **byte-identical** · `resolved.json` **zero differing keys** ·
`commit_id.json` differs only in `commit` and `workflow_url`, i.e. in *which arm
it is*. Confound 5.2 is clear — the arms differ by the attribute and nothing else.

**③ PRIMARY READOUT — cone census over `tt_submission/tt_um_saltworks_banyan.v`:**

| arm | cut set | cones | median in | max in | ≤ 24 |
|---|---|---|---|---|---|
| A `(* keep *)` | default | 64 | 12 | 36 | 87.5 % |
| B control | default | 64 | 12 | 36 | 87.5 % |
| **A `(* keep *)`** | **at the boundaries** | 80 | 7 | **21** | **100.0 %** |
| B control | requested; the nets do not exist | 64 | 12 | 36 | 87.5 % |

**② MECHANISM:** arm A carries **16 boundary bit-nets, all 16 driven by a real
cell output**; arm B carries **0**.

⇒ **Pre-registered row (a).** Max cone input **36 → 21** — three bits inside the
measured 24-bit kernel ceiling — **on the netlist TinyTapeout will fabricate**,
not on a local proxy.

### The local proxy predicted the CI result

Local (yosys 0.68, TT top, flattened+split): 86.9 % → **100 %**, max 36 → 16.
CI (librelane 3.0.5): 87.5 % → **100 %**, max 36 → 21. Same verdict, same
direction, same shape; the local method was sound and its absolute numbers were
not the CI's — which is exactly what it was labelled as.

### And correction 2 was load-bearing

`wire [7:0] w0` appears in **NEITHER** CI arm — vector-decls 0 and 0. Readout ②
as originally pre-registered would have reported the **treatment** arm ABSENT,
and with the default census reading 87.5 % in both arms, the table lands on **row
(b), "CI strips it — the expensive outcome"**, when the truth is row (a). Two
individually reasonable instruments agreeing on the exact opposite of the truth,
and the correction was made before either arm was fired.

### Gates, for the record

**Precheck PASS · GL test PASS** (the 255-scenario bench against the **powered**
post-layout netlist) **· docs PASS · RTL test PASS.** The only red is `viewer`,
which deploys to GitHub Pages and cannot run while the repo is private on this
plan — a plan limit, not a design fault.

---

## What is NOT established

- ⚠️ **This is not the CI artifact.** Local yosys **0.68+post**; CI runs
  LibreLane 3.0.5, whose yosys is **0.62 `[INF]`** — inferred through
  `flake.lock` → nix-eda, and nobody has inspected the actual container image.
  The mechanism claims were checked stable across yosys 0.44/0.62/0.68, but a
  version is a version.
- ⚠️ **The sky130A PDK config layer is unchecked** — open_pdks is not readable at
  the obvious paths, so PDK-level `SYNTH_*` overrides remain `[?]` for a sky130
  run specifically.
- **`tt-support-tools` is pinned to a FLOATING `main`** in `gds.yaml` (no
  `tools-ref`), which moved today. Both CI arms must pin it identically and their
  `commit_id.json` must be compared before anything else is read.
- The two real CI arms are **still owed**, and they are blocked on the public
  TT-repo ruling. What this run establishes is the mechanism and, more usefully,
  **what to measure when they do run** — which was going to be measured wrong.
