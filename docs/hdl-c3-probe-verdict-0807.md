# C3 — THE FREEZE VERDICT

*Assembled 2026-08-07 from three probe reports plus a first-hand read of the committed repo (`saltworks` @ `32218ca`, plus working-tree edits to `EmitS.lean`). **No Lean or lake was run** (fleet law 1), so every Lean-side claim below is read from source, not from a build.*

---

## ⛔ READ THIS BEFORE THE VERDICT: THE RULING'S FALLBACK DOES NOT EXIST

The ruling assumed **(B) algebraic per-cone proofs** is a safe fallback. **It is not — at the CPU shape it is not slow, it is unavailable**, and that was already measured in this repo before the probe fired:

| the cone | inputs | route (B) status |
|---|---:|---|
| bit-serial switch element | 6 | ✅ 64 bits/net |
| comparator (D3, landed) | 16 | ✅ ~1.9 MB, ~3 s |
| **flattened banyan TT top, no cut** | **36** | ❌ 8.6 GB/net, past the ceiling |
| **RV32I regfile read cones (64 of 1056)** | **36** | ❌ |
| **RV32I read tree, RTL + `(* keep *)` (1 of 1312)** | **29** | ❌ |
| **32-bit adder, cut at all 33 carries** | **62** | ❌ |

The kernel ceiling is **measured, not extrapolated** (`Certs.lean:47-70`): `Nat.pow` is GMP-accelerated to exponent `1 <<< 24` **inclusive** — `2^16777216 % 3` by `decide +kernel` = **0.59 s, EXIT=0**; `(1<<<24)+2` = **57.07 s, EXIT=1, `maximum recursion depth`**; `1<<<25` = **56.95 s, EXIT=1**. A slice of `n` input bits needs the mask `2^(2^n) − 1`, so **`n = 25` is exactly the first measured-dead width** — there is a datum at the failure, not an inference. The other route is worse: pointwise `decide +kernel` runs at **~10⁴ gate-evaluations/second** measured, so one 36-input cone is `2^36 = 6.87×10^10` configurations — **≥ 80 days for a single-gate cone**, and it materialises the reduction (a <60-line probe reached 30 GB).

⇒ **If (A) had failed, the campaign would have had no method for the RV32I read path or the ALU carry chain — not a slower one, none.** The council must record that the ruling's safety structure was wrong. (A) and (B) are **not alternatives**: (A) is the emission discipline that puts cones under the ceiling, and (B) is the proof method that then closes. That reframing is the substance of this verdict.

---

## 1. (A) PASSTHROUGH — **PASS**

**PASS: 45,792 structurally-emitted cells across five sizes came back instance-exact (same name, same cell type, same every-pin→net map) — 24,320 of 24,320 at the largest — with abc logging `Extracted 0 gates and 0 wires` in every invocation, while the identical flow with `read_liberty`'s `-lib` flag removed returned 0 of 224.**

Every arm, all three agents plus the in-repo silicon half:

| arm | in → out | instance-exact | source |
|---|---|---|---|
| 5 committed mapped netlists, re-fed (idempotence) | 3049 → 3033 | **3033 / 3033**, 0 retyped, 0 rewired | probe 1 |
| — the 16 removed | all `clkinv_1`, all fanout 0 (stripped `(* keep *)` taps) | not logic loss | probe 1 |
| hand-written structural ripple adder, 6b / 32b | 32 → 32, 162 → 162 | **32/32, 162/162**, 162 singleton colour classes | probe 2 |
| `emitS`-faithful array multipliers 8/16/32/48/64 | 352, 1472, 6016, 13632, **24320** | **all exact**, multiset identical, 2.00 s at 24k | refuter |
| hostile design (1500 dup gates, fanout-800 hub, 4000-cell inverter chain, AND-with-1) | 10999 → 10999 | **10999 / 10999** | refuter |
| **TT CI run `31182129057`, fabricated artifact** | **49 → 49** logic cells | **names, drive strengths and counts preserved** | silicon, in-repo |
| **negative control** — liberty read *without* `-lib` | comparator 36→37, adder32 224→208 | **0/36, 0/224**; 178 retyped; abc `Extracted 691 gates` | probe 1 |

**The R2 defeat flips.** Behavioural adder32: `carry[12]` returns with fanin 68 cells, depth 9, support 25 primary bits, **depends on `carry[11]` = False** (abc re-derived lookahead — silicon's R2 reproduced exactly by two independent tools). Structural adder32: fanin 97 cells, depth 37, **depends on `carry[11]` = True**. Both SAT-equivalent (`5354 variables, 13699 clauses … SUCCESS!`). On the *fabricated* 8-bit artifact the same thing: **17 cones, median 3, MAX 3, 100 % ≤ 24**, against the RTL control's **max 62 with zero carry nets surviving**.

**Two conditions on the PASS, both measured:**

1. **The whole result rests on one line**: `read_liberty -lib $LIB` before `read_verilog`, i.e. the stdcell library read as **blackbox**. Remove it and the flow re-derives everything (0/36, 0/224 above). That is what `SYNTH_STRUCTURAL=1` does in `Flow/synth.sh:~95` and what LibreLane synthesis does — an assumption backed by measurement, not a theorem. It is the single thing that would void (A).
2. **PASS is about the LOGIC, not about a name diff.** Under a `tt_um_*` wrapper — the only configuration TinyTapeout uses — the raw one-for-one instance check returns **0 of 1472**, because `synth -flatten` prefixes every core instance (`gN` → `core.gN`). **This is confirmed independently by the committed repo**, which is why it is not a scratch-probe artefact: `FabricCut.lean:569` lists `fabric.cnt[0]`, and `keep-experiment-0806.md:28` records the boundary nets as `\fabric.w0[0]`…`\fabric.w1[7]`. The structure *is* preserved (1464/1464 after normalization) — the *diff* is not a diff. See §2, and §4's scoping.

---

## 2. WHAT THE COMPILER SEAT MUST BUILD — WORK ORDER

**Current state of the artifact C3 would freeze on** (`SaltWorks/HDL/EmitS.lean`, read at working tree after `32218ca`): `cellOf`, `sNet`, `instName`, `emitCell`, `dummyDecl`, `emitS`, `manifest`, and — landed at `811fe37` — the mux peephole `opAt`/`readCount`/`MuxSite`/`muxAt`/`emitSMux`/`muxCount`. **13 `#audit_axioms` lines were added in the working tree; the file still contains ZERO theorems.**

**W0 — PUT IT INSIDE THE FENCE (blocking, ~1 line).** `lakefile.toml` has `defaultTargets = ["SaltWorks"]`, and `SaltWorks.lean` (27 lines, MAESTRO-OWNED) **does not import `SaltWorks.HDL.EmitS`.** The default target never elaborates the file, so **its 13 new `#audit_axioms` commands never run** — this is exactly the "72 audit sites outside the fence" defect (`097b41e`) recurring on the newest file. `import owed` per the hub's own convention.

**W1 — EMIT FROM THE NORMALIZED CIRCUIT, NOT THE RAW ONE.** `emitS`'s `sNet`/`instName` are canonical only under `Circ.ssa`; `emitS` today accepts any `Circ`. And the flow's `opt_clean -purge` **reaps dead cells** — measured 3 → 2 on a `Circ` with one unread gate, 16 `clkinv_1` on the real artifacts, and **8 good `xor2_1` cells (g1430…g1465) under the wrapper**, where liveness was decided by *how the parent wired the outputs*. `Circ.wf` permits dead gates. The fix already exists and is proved: emit from `normalize (opt c)` — `opt` (`Opt.lean:121`), `opt_wf` (`Renumber.lean:680`), `normalize_ssa` (`:317`), `normalize_sem` (`:497`), `emitPipeline'` (`:726`), `emitPipeline'_sem` (`:732`).

**W2 — THE Op → CELL MAP.** As committed, five cells; all five have proved models (`inv`, `or2`, `xor2`, `conb_HI`/`conb_LO`; **`and2` reaches `and2_1` only through `expansion_for`'s drive-strip rule**, which is a *survey* — 428 cells, 127 multi-drive base names, 0 differing functions — in the trusted base, not a theorem). ⚠️ **Correction to the brief: there are not 61 proved cell models.** `grep -c "theorem .*_liberty" Sky130.lean` = **44 theorems over 43 cells** (61 is the number of *lines mentioning* `_liberty`); the muster already corrected this at `58e68a8`, and the tie cell is why (it owes two).

**W3 — DRIVE STRENGTH: the two agents and the CI disagree; pick with eyes open.** `cellOf` hardcodes `_1`. Verified by me on this machine at the pinned PDK `c6d73a35…`: `libs.tech/openlane/sky130_fd_sc_hd/no_synth.cells` has **199 entries and contains `and2_1`, `inv_1`, `or2_1`, `xor2_1` — four of emitS's five.** `conb_1` is **not** on it (it is OpenLane's own `SYNTH_TIEHI_PORT`/`SYNTH_TIELO_PORT`); **`mux2_1` is not on it either**, so the peephole cell is safe.
* **Reading 1 (probe 1 E5, refuter A10):** against a liberty reduced by that list (185 of 428 blocks removed), `_1` **hard-errors before synthesis** — `ERROR: Module '\sky130_fd_sc_hd__or2_1' … is not part of the design`, rc=1. Re-emit at `_2`: rc=0, `Extracted 0 gates`, **6016/6016 and 24320/24320 exact**. ⇒ pin `_2`.
* **Reading 2 (silicon, in-repo):** TT CI run `31182129057` ran **green on all four jobs with `_1` cells, preserved exactly, no resizing**. ⇒ `_1` is the only drive with a real-path green.
* These cannot both describe the same operation: deleting cell blocks from a liberty is a stronger edit than LibreLane's exclusion list, which constrains what abc may *choose*, not what a designer may *instantiate*. **Do not resolve it by argument** — §5 names the measurement.

**W4 — THE TIE CELL, AND A ONE-TO-ONE BREAK THAT IS OURS, NOT THE FLOW'S (new; derived from the committed tables).** `conb_1` has no inputs and two outputs; `emitCell` parks the unused polarity on a per-instance dummy `u_gN`. But the importer's `EXPAND["conb"]` (`import_netlist.py:154`) is **two ops** — `const True` **and** `const False` — and `build`/`expand_driver` (`:488`, `:528`) emits **all** ops of an expansion. `emitN` maps one `Op.const b` to **one** `Silicon.Gate.const b` (`EmitN.lean:78-84`). ⇒ **k `const` gates in the `Circ` → k `conb_1` cells → ≥ 2k `const` gates on re-import.** A structural equality against `emitN c` fails on *any* circuit containing a constant **before the flow does anything at all.** Choose one and write it down: (a) the importer drops the unused tie output (trusted-base change), (b) the Lean-side image mirrors the cell rather than the `Op`, or (c) constants are folded out before emission (`opt` is DCE only — it does not fold). Note also the flow adds its **own** tie cells: **+17 `conb_1`** on the 49-cell TT artifact, none of them in the manifest.

**W5 — THE PEEPHOLE PAYS IN SILICON AND CHARGES IN GATES (new; arithmetic from the committed numbers).** `emitSMux` deliberately does **not** consume the `not` — correctly, because the read tree shares **5 inverters across 992 muxes** (`992×3 + 5 = 2981`, exactly the committed cell count). Emission collapses 2981 → **992 cells / 11,171 µm²**, boundaries 128/128, max cone 11 unchanged. But the importer expands **each** `mux2_1` into **four** primitives (`not S · and A0 ¬S · and A1 S · or`, `import_netlist.py:123`), so the returned netlist imports as **992 × 4 = 3968 gates against the `Circ`'s 2981 — +987, i.e. +33.1 %**, and the 987 are the shared inverter duplicated 992-fold. **Values still agree and cone inputs stay 11, so the per-cone route is untouched; the one-for-one structural diff is dead a second time.**

**W6 — THE NEW PROOF OBLIGATION, STATED EXACTLY.** `Silicon.Gate` derives `DecidableEq` (`BitSliced.lean:64-72`), so the target obligation is well-formed today:

> per design, one `theorem : importedNetlist = emitN (normalize (opt c)) := by decide +kernel`, cost **linear in gates**, no `2^n`, no memory law — against (B)'s `2^inputs` bits per net.

What does **not** exist and must be built or explicitly trusted: the normalization from the returned netlist into that numbering. **Measured cost of omitting each stage** (refuter A5): hierarchy-prefix strip → 1472/1472 becomes **0/1472**; joint alias-class quotient → **3/3 becomes 0/3** on a perfectly-preserved 3-cell design; port-binding rename → **279 of 1464** read as rewired; dead-cell allowance → **8 good cells** read as FAIL. Add **W4** (tie cell) and **W5** (mux expansion) and it is a **six-stage** pipeline, not a diff. If it lands in `import_netlist.py` it joins the **trusted** base beside the drive-strip rule, and the only guard against a wrong normalization is `readback.py --check` — a **random-vector** simulation against vendor Liberty (negative controls: 2 of 3 mutations caught; port-order swap **not** caught). That is a check, not a proof.

**W7 — WHAT (A) IS ACTUALLY FOR, and it is not W6.** The measured payoff is cone size: adder **62 → 3**, RV32I read path **36 (RTL) / 29 (RTL+`keep`) → 11**, 0 % → **100 % ≤ 24**. That closes with machinery already landed and audited (`BitSliced.reflect`, `eq_of_sliced_eq`, `AdderSlice`, `SwitchRefinement`) and needs **none** of W6's six stages. **Build the per-cone route first; treat W6 as the later, stronger option.**

**W8 — INTEGRATION COST, already measured, needs a council decision.** TT's `test` job (RTL simulation) **FAILS** on structural input — `src/project.v:49: error: Unknown module type: sky130_fd_sc_hd__xor2_1` — because it compiles sources with no PDK models. `gl_test` **passes** (45 vectors, post-layout, the stronger check). Option (A) collapses the RTL/GL distinction: either give the `test` job the PDK models or drop it as meaningless.

**W9 — SCOPE, narrowed by the measurement that landed while this was being written** (`32218ca`): the **writeback path needs nothing.** RV32I 4:1 result select + write decode + 31×32 flops in **plain RTL**: 1984 cones, median 6, **MAX 6, 100 % ≤ 24**, 183 logic cells / 922 µm² (3.0 %; the flops are 97 %). Against the read path's 1508 cells / 15,222 µm² / max 36 — **8.2× cells, 16.5× area**. The rule: **a read SELECTS one of 31 and its cone grows with the file; a write ENABLES one of 31 and its cone does not.** ⇒ **structural emission is required exactly where a select fans in past 24 — the read path and the carry chain — and nowhere else.**

---

## 3. IS (B) ACTUALLY A FALLBACK? — **NO, NOT AT THE CPU SHAPE. IT IS THE PROOF METHOD, NOT THE FALLBACK.**

* **(B) is sufficient for what ships.** Switch element max **6**, comparator max **16**, fabric with `keep`-cut **77 cones, max 16, 100 %** (+10 cells, +37.5 µm², **+1.78 %**). D3/D4 are landed on it. Monolithic fabric certification is dead by **9 PB** (8 inputs + 12×4 state = 56 bits), which is the whole argument for decomposition and is unaffected by C3.
* **(B) is insufficient for the CPU, by 5 to 38 bits.** RV32I regfile: **1056 cones, max 36, 93.9 % ≤ 24**, failure perfectly uniform — **all 64 read cones at exactly 36 = raddr(5) + 31 registers**. ALU adder: **max 65 monolithic (33.3 % ≤ 24)**, and **62 even when cut at all 33 `(* keep *)` carry nets (67.2 %)**.
* **RTL restructuring does not rescue it, and fails in the instructive way.** Two-level tree + 8 `keep`-marked boundaries, all 8 surviving: **36 → 29, and one cone of 1312 stays over** — `rdata1[30]`, 29 leaves, mixing **one** group output with **~26 raw registers**. The optimiser kept the named nets and **routed around three of the four of them for that bit**. R2's law in a subtler and worse form: *partial* dependency preservation, where the census looks nearly right. **99.9 % is not 100 %; one 29-input cone is as fatal as a hundred.**
* **The general figure is 86.8 %** over 1,626 cones in nine real TT netlists, worst cone **226 inputs / 325 gates**. The ~13 % tail is wide trees, which need a structural argument in any case.
* **The counterweight (A) earns on the trusted base**, and it is in-repo as well as in the probes: flattening took the banyan from **6 cell types per element to 21**; the refuter's behavioural mul32 used **36 distinct cell types, 18 of them with no model in `Sky130.lean`**, each a hand-transcribed trusted model plus an `EXPAND` entry, and `import_netlist.py:513` hard-stops on the first one. (A) uses **5–6 types, all modelled.** **The trusted cell set grows with the optimiser's freedom, not with design size** — that is an argument for (A) about the *trusted base*, independent of the flow.

⇒ **There is exactly one measured route to a per-cone-certifiable RV32I read path, and it is (A).** Naming that plainly is the most important line in this document.

---

## 4. RECOMMENDATION — **FREEZE C3 ON (A)**, with the prize restated

Freeze on **(A) structural gate-level emission**, on these terms:

1. **(A) is the emission discipline, not a replacement for the proof.** What it buys is **cone size** — 62 → 3, 36 → 11, 0 % → 100 % ≤ 24 — which is what makes (B)'s landed, audited per-cone machinery close. The `EmitS.lean` headline that per-cone equivalence "becomes bookkeeping" is **REFUTED and should be struck from the file before it is cited**: 0/1472 raw under the real `tt_um_*` shape, 1464/1464 only after **six** normalizations (four measured by the refuter, two — the tie cell and the mux expansion — derivable from the committed tables), none of which exists in the repository or is proved anywhere.
2. **Scope it (W9):** structural emission for select-shaped cones — read path, carry chain. Writeback, decode and the flop fabric stay ordinary RTL, measured max cone 6.
3. **Price, both readings:** **+16 %** area on the structure that matters (RV32I read path with the `mux2_1` peephole: 52,130 vs 45,011 µm², **1.15 vs 0.99 tiles** — against a baseline that cannot be verified at all), rising to **1.19–1.25×** on multipliers, **+35 %/+67 %** on adders in the primitive basis, and **+97 %** only for adder32 forced to `_2` drives. The +16 % figure is the one measured on the target.
4. **Do NOT freeze the manifest as an exact diff.** Freeze it as an **expectation with a stated normalization**, and require each normalization stage to be either proved in Lean or listed in the trusted base with the survey that justifies it — the way the drive-strip rule was.
5. **RV32E is on the table and is not ours to take**: max cone **19, 100 % ≤ 24 with no cut and no tree, 0.48 tiles**. Recorded, per silicon, as the Captain's call, because changing the target to make the proof easier is the move this campaign should be most suspicious of.

*Not "do not freeze": the do-not-freeze option would leave the campaign with (B) alone, and §3 shows (B) alone does not reach RV32I. The residual measurements below are work orders, not blockers — none of them can turn the passthrough finding around, and one of them (W3) has a safe answer in each direction.*

---

## 5. STILL UNVERIFIED — including everything resting on one run

1. **The entire real path is ONE run.** TT CI `31182129057`, **49 logic cells**, four jobs green. It is the only structural datum from a fabricating flow, its artifact is **not in this repo** (`TT/src/project.v` is the banyan wrapper, not the structural adder), and I could not check it. Every "it survives to silicon" claim traces to it.
2. **W3's contradiction is unresolved.** `no_synth.cells` (199 entries, verified by me at the pinned PDK) lists four of emitS's five cells; two agents measured a hard rc=1 against a liberty reduced by it; TT CI ran **green at `_1`**. **The one measurement that settles it:** one LibreLane/TT-CI run of a structural design at `_2` drives, plus reading how LibreLane applies `SYNTH_EXCLUSION_CELL_LIST` (blackbox declaration vs. abc's choice set). **LibreLane 3.0.5 is not installed on this machine** (`Flow/librelane/` holds only a `config.json` its own README marks SUPERSEDED), so neither agent could run it, and neither could I.
3. **Silicon's "names preserved exactly" vs. the refuter's "0 of 1472".** In-repo evidence (`fabric.cnt[0]`, `\fabric.w0[0]`) says flatten *does* prefix instance names under a wrapper, which favours the refuter's mechanism. Whether silicon compared basenames or full names on the CI artifact is not recorded. **Both readings stand until the CI netlist is read.**
4. **Scale gap of 500×.** Largest real-path structural design: **49 cells**. Largest local structural design: **24,320 cells** — but yosys-only. The RV32I read tree (992 mux cells / 2981 primitive) has **never been through LibreLane**, and TT CI's step-7 "Unmapped Yosys instances" checker has never run on a structural netlist at any size.
5. **Every local number is a synthesis-stage number.** No OpenROAD binary on this machine: no placement, CTS, resizing, or antenna repair measured. The CI artifact shows what that stage adds — **+16 `clkdlybuf4s25_1` hold cells, +17 `conb_1`, a clock tree, 20,498 physical cells against 49 logic cells** — all logically identity or constant, all modelled, but the importer must discard the overwhelming majority **by cell identity**. The refuter's A7 measured that (A) and (B) arrive at P&R **equally** mis-sized (both 100 % minimum drive), so resizer churn is a common exposure, not (A)'s differential cost — that result strengthens (A) and was reported against its author's own prediction.
6. **PDK pin mismatch.** All three probes and `synth.sh` use `c6d73a35…`; `synth.sh`'s own header records that the **fabricated** netlist is built at `0536d02d…`. The passthrough measured locally and the passthrough measured on CI are not at the same PDK revision.
7. **The W6 cost model is unmeasured.** `decide +kernel` on a ~6,000-gate structural equality is *predicted* linear and cheap. Nobody has run it — and per fleet law 1, I could not.
8. **`EmitS.lean` is a moving target and still carries zero theorems.** It changed twice while this verdict was being written (peephole at `811fe37`; 13 `#audit_axioms` added in the working tree, uncommitted). It is still **absent from `SaltWorks.lean`**, so those audit commands are not elaborated by the default target — the fence gap of `097b41e`, reopened.
9. **Probe 1's idempotence arm is the weakest evidence in the set** and should not be quoted as the headline: feeding the flow its own output tests the flow on netlists the flow chose. The load-bearing arms are the ones fed **emitter-shaped** input (probe 2's 162/162 with singleton colour classes, the refuter's 24,320/24,320, and the CI run).
10. **The brief's own "61 proved `_liberty` cell models" is not a count of anything** — it is **44 theorems over 43 cells** (`58e68a8`), and of emitS's five, `and2_1` is covered only via the drive-strip survey.
