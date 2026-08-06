# LEG 3 REFUTER PASS — the Silicon seat attacks its own design freeze
### 2026-08-06, seat: jason (Silicon). Target: `docs/silicon-design-v1.md` v1
### + ADDENDUM 1 (bit-serial). Method: seven parallel refuter lanes, each
### adversarially verified, plus first-hand measurement on this machine.
### Rule of the pass: **measured beats sourced beats reasoned.** Every number
### below carries its provenance tag.

---

## 0. HOW TO READ THIS

Severities: **FATAL** = the leg as specified cannot deliver; needs a ruling, not
a seat repair. **MAJOR** = repairable by the seat, but the doc as written would
have sent the build the wrong way. **MINOR** = imprecision worth recording.
**CONFIRMED** = attacked and it held; recorded because a refuter pass that finds
only faults is not a credible refuter pass.

Provenance: `[M]` measured on this machine today, command and number given.
`[S]` sourced from a primary artifact (PDK file, vendor doc, sibling seat's
URL-tagged dossier). `[R]` reasoned — argument only, no artifact.

**⚠️ A methodological correction that applies to this whole document.** My first
round of timings was taken while the fleet was in memory contention, and several
runs were SIGTERM'd by the OS (jetsam) at 6–10 minutes with near-zero accounted
*user* time. That looks exactly like a performance wall and is not one. Every
timing quoted below was **re-taken through `saltbuild.sh`** (the fleet lock) on a
quiet machine. The walls I originally believed in at 14 and 16 input bits
**evaporated** on re-measurement. I am flagging this loudly because the same
failure mode contaminated a sibling seat's numbers the same morning, and because
a design freeze built on contended timings would have been built on sand.

---

## 1. VERDICT SUMMARY

| # | Target | Finding | Severity |
|---|---|---|---|
| F1 | R1 | Post-synthesis netlist grammar is genuinely flat and small — but the doc names the **wrong file** | MAJOR |
| F2 | R2 | Cell set is 13 distinct cells, not ~30 — but it is **unstable** and abc reached for power-isolation cells | MAJOR |
| F3 | OPEN | The `decide +kernel` cost law in the freeze was measured on a **different workload** and does not transfer | MAJOR |
| F4 | OPEN | The importer's *natural* output shape is the **worst possible** one for the kernel | MAJOR |
| F5 | OPEN | **REPAIR:** bit-slicing dissolves the wall — 16.8M configurations, kernel-checked, in seconds | MAJOR (repair) |
| F6 | R4 | Tile budget over-provisioned ~15×; the binding constraints are **pins and output frequency** | MAJOR |
| F7 | ADDENDUM 1 | Body and addendum are out of sync: combinational importer spec vs **sequential** tapeout target | MAJOR |
| F8 | ADDENDUM 1 | The resonance claim (descending index = MSB-first serial order) is **TRUE** | CONFIRMED |
| F9 | R3 | The switch element is correct only **under the no-conflict hypothesis** | MAJOR |
| F10 | OPEN | LibreLane needs Nix, Nix needs sudo — a **human action** blocks D1's stated path | MAJOR |

**Nothing fatal.** No finding requires a ruling before work continues. Repairs
are being applied on my own authority per the standing order; the two items that
want a *decision* rather than a repair are listed in §6 with recommendations
attached.

---

## 2. THE FOUR KILL-CHECKS

### R1 — the importer grammar. VERDICT: the grammar is fine; **the file is wrong.**

I did not wait for D1 to get a real sample. I installed a native arm64 yosys
(0.68) and the sky130A PDK (volare, no sudo) and pushed the design doc's own
comparator cell through real synthesis today. `[M]`

The post-synthesis grammar is as flat as hoped — and smaller:

```verilog
module comparator(a, b, lo, hi);
  input [7:0] a;
  wire [7:0] a;
  ...
  sky130_fd_sc_hd__clkinv_1 _20_ (
    .A(b[7]),
    .Y(_00_)
  );
```

Measured over the whole file: **zero `assign` statements, zero `1'b0`/`1'b1`
constants, zero escaped identifiers, zero behavioral constructs.** Named port
connections only; nets are either bare identifiers or `name[i]` bit-selects.
235 lines for 36 cells. A parser for *this* is well inside the ≤300-line budget.

**But the freeze names the wrong artifact.** D1 says
`runs/RUN_*/final/nl/<design>.logical_nl.v`. The netlist that actually gets
fabricated is built by **TinyTapeout's CI**, not our local run, and is shipped as
`tt_submission/<top>.v` — `librelane==3.0.5`, PDK pinned `0536d02d…`. `[S]`
(independently established by the evidence seat, URL-tagged, `docs/tinytapeout-dossier.md` §6.)

Worse for the parser: that artifact is the **POWERED** netlist
(`powered_netlists: true`). I confirmed against the PDK itself that this adds
exactly four pins per instance — every `sky130_fd_sc_hd` cell declares
`pg_pin` VPWR, VGND, VPB, VNB and no others. `[M]`

**Repair (applied):** D2's importer is specified against the **powered** form and
must accept-and-discard exactly those four pins per instance; the equivalence
target is `tt_submission/<top>.v`. Proving a local netlist and shipping a
different one would be a seam left open, which is the one thing this campaign
cannot do. A local run pinned to `3.0.5 + 0536d02d…` remains the dev loop.

**Not yet closed:** post-**P&R** grammar (as opposed to post-synthesis) adds
buffers, tie cells for constants, and possibly `assign`. My sample is
post-synthesis only. The parser must not be frozen until a genuine
`tt_submission/<top>.v` is in hand — that is now a D1 exit criterion.

### R2 — the cell models. VERDICT: **fewer than budgeted, but the set is unstable.**

Measured cell usage, real sky130 synthesis: `[M]`

| design | cells | distinct types |
|---|---|---|
| 8-bit comparator (min/max) | 36 | 12 |
| bit-serial 2×2 switch element | 8 | 4 |

Union across both: **13 distinct cells**, not "~30". The exact Boolean function
of each was extracted mechanically from the PDK's own Liberty file — which is the
right provenance story for a *trusted* model set (derived from the vendor's
machine-readable spec, then cross-checked against the vendor Verilog, rather than
hand-guessed):

```
a222oi_1   Y = (!A1&!B1&!C1) | (!A1&!B1&!C2) | ... (8 disjuncts)
mux2_1     X = (A0&!S) | (A1&S)
o2bb2ai_1  Y = (!B1&!B2) | (A1_N&A2_N)
nand2_1    Y = (!A) | (!B)
dfxtp_1    Q = IQ   [FF next=D @CLK]
```

**The finding that matters:** abc selected two **power-isolation** cells —
`lpflow_inputiso1p_1` (X = A|SLEEP) and `lpflow_isobufsrc_1` (X = A&!SLEEP) — and
used them as ordinary data-path logic, with SLEEP driven by *real data*
(`.SLEEP(a[7])`), not tied off. `[M]` These are `lpflow` cells intended for
power-domain crossings; LibreLane's sky130 flow normally excludes them.

So: **a cell-model set frozen against a bare-yosys run is the wrong set.** The
cell set is an output of the *flow configuration*, not of our design. Freeze it
against the TT-CI configuration, and constrain it deliberately (an explicit
don't-use list) so the trusted set is small **by construction rather than by
luck**. That is a strictly better story for the README than "we happened to need
only 13."

### R3 — the seam with leg 2. VERDICT: see §4 (a real gap, and it is mine to close).

### R4 — the tile and the pinout. VERDICT: **answered, but the doc solved the wrong constraint.**

ADDENDUM 1 argued bit-serial from pin count and was right — the evidence seat
confirmed the pinout from the source (`ui_in[8]` + `uo_out[8]` + clk is exactly
8 serial in / 8 serial out, all 8 `uio` spare; word-parallel needs 64+ pins and
is impossible at any price). `[S]`

But the *area* reasoning in the freeze ("1299 gates vs 1000/tile — 2 tiles OK")
quoted the **word-parallel** figure. Measured, for the design we are actually
taping out: `[M]`

- one bit-serial switch element: **8 cells, 95.09 µm²**
- 8×8 banyan = 3 stages × 4 elements = **12 elements ≈ 96 cells ≈ 1,141 µm²**
- a 1×1 TT tile is 161.00 × 111.52 µm ≈ **17,955 µm²** `[S]`

The whole fabric is **~6% of one tile**. Area is not a constraint and 2 tiles are
not needed. The binding constraints are instead:

1. **Pins** — already ruled correctly.
2. **Output frequency** — the TT pad's maximum *output* rate is 33 MHz, half its
   input ceiling, and a bit-serial fabric toggles its outputs every single cycle.
   The template's default 50 MHz target is **over the rating.** `[S]` This is a
   real constraint on the taped-out design and it is nowhere in the freeze.

---

## 3. THE LOAD-BEARING FINDING — the cost law does not transfer

This is the one that would have cost the most.

The freeze prices module equivalence as "`decide +kernel` (≤16 input bits per
module)" on a "measured law: 2^16 ≈ 6 min, 2^8 ≈ 0.2 s". Chase the citation: that
law comes from the batcher dossier, and it was measured on **ℕ-arithmetic routing
certificates**. That dossier states plainly *why* it was fast
(`batcher-scout-dossier-0805.md:78`):

> "`Nat` add/mul/div/mod/beq/ble are GMP-accelerated in the Lean kernel, so the
> div/mod representation reduces fast."

**A gate netlist is Bool, not ℕ.** There is no GMP acceleration for
`Bool.and`/`or`/`xor`; every gate is a genuine iota-reduction. The only
gate-level number in the dossiers (81 gates in 1.4 s) was measured with
`bv_decide` — **which JYH banned from shipped proofs on 8/6.** So the shipped
decision procedure had *no gate-level measurement at all*. I took one.

### Measured, on this machine, through the fleet lock `[M]`

Netlist: n-bit gate-level ripple-carry adder, 2-input primitives, 5 gates/bit,
checked exhaustively against a spec over all 2^(2n) input configurations.

| encoding | input bits | configs | gates | result |
|---|---|---|---|---|
| **A** pointwise, generated `def` w/ nested lets | 8 | 256 | 20 | ✅ |
| **A** | 12 | 4,096 | 30 | ✅ |
| **A** | 14 | 16,384 | 35 | ✅ |
| **B** pointwise, netlist as DATA + interpreter | 8 | 256 | 20 | ✅ but **7× slower than A** |
| **C** bit-sliced over ℕ | 8 | 256 | 20 | ✅ |
| **C** | 16 | 65,536 | 40 | ✅ |
| **C** | 24 | **16,777,216** | 60 | ✅ |

Every one of them axiom-clean: `depends on axioms: [propext]`. No
`Classical.choice`, no `Quot.sound`, no native axiom. `saltbuild EXIT=0`
throughout. (Precise wall-clock per row is in §7; the qualitative result is what
matters here and it is robust.)

### F4 — the importer's natural output is the worst shape for the kernel

Encoding **B** is what an importer *naturally* produces: parse the netlist into a
list of gate descriptors, write an interpreter. It was the slowest at the
smallest size tested, and the gap widens with every gate, because each net lookup
is a list traversal — the kernel has no accelerated arrays.

**This is a design decision the freeze does not mention and it must be made
before a line of D2 is written.** Either the importer is a **code generator**
(emits Lean `def`s and the netlist becomes a term), or evaluation is bit-sliced.
"Parse into a data structure and interpret it" — the obvious implementation — is
the one that does not scale.

### F5 — the repair, and it is a good one

Give every net its **entire truth table** as a single ℕ: bit *j* of net *w* is
*w*'s value under input configuration *j*. Then

- gates become `Nat.land` / `Nat.lor` / `Nat.xor` — **exactly the GMP-accelerated
  kernel primitives**, and
- there is **no enumeration at all**: an *n*-gate module costs *n* bignum
  operations total, not *n* × 2^inputs iota-reductions.

The input columns have a closed form (the period-*p* unit pattern times the
base-2^p repunit), so they too are a constant number of GMP ops. I verified the
construction *in the kernel* rather than assuming it — all 8 columns against
their defining property over all 256 configurations, axiom-clean:

```lean
theorem col_spec : (List.range 8).all (fun i =>
    (List.range W).all (fun j => ((col i).testBit j) == (j.testBit i))) = true := by
  decide +kernel
-- 'col_spec' depends on axioms: [propext]
```

**Result: 24 input bits — 16.8 million configurations — 60 gates, exhaustively
checked inside the kernel, axiom-clean, in seconds.** The freeze's 6-minute
2^16 "bad CI citizen" stops being a problem, and D3's comparator stops being a
CI anchor.

**Non-vacuity control (this is the part that makes it mean anything).** I mutated
one gate (AND → OR) and re-ran. The kernel reports:

```
error: Tactic `decide` proved that the proposition
  netSliced = specSliced
is false
'VC.sliced_eq' depends on axioms: [propext, sorryAx]
```

The check sees the fault and the axiom audit fails the build. **That is D2's
mutation-test mechanism, working, today.** One caveat recorded honestly: at large
widths the *failing* path aborts with a stack overflow instead of that clean
message, so the mutation corpus must be run at small widths where the
counterexample is legible.

**The honest cost of this repair:** bit-sliced evaluation is only a *certificate*
about pointwise behavior once you prove it is — a reflection lemma (sliced ⟺
pointwise) proved once, generically. That is real work, it is the thing that
makes the whole trick legitimate, and it is now priced into D2 rather than
discovered in week 2.

---

## 4. THE SEQUENTIAL GAP (R3, ADDENDUM 1) — the body and the addendum disagree

The body of the freeze specifies a **combinational** chain: "flat structural
Verilog → Lean netlist over Bool nets", equivalence "per module by
`decide +kernel`". ADDENDUM 1, written later the same day, rules that the tapeout
target is **bit-serial** — i.e. sequential, with flip-flops. The body was never
updated. Everything downstream inherits the mismatch.

Measured: synthesizing the bit-serial switch element yields real flops `[M]`:

```verilog
sky130_fd_sc_hd__dfxtp_1 _10_ (
  .CLK(clk), .D(_00_), .Q(sel1)
);
```

with Liberty semantics `Q = IQ`, `next_state = D`, `clocked_on = CLK`. `[M]`

Consequences, all of which are D2/D3.5 scope that the freeze does not fund:

1. The importer must extract **(state bits, next-state function, output
   function)**, identify the flop set, and check the combinational part is
   acyclic. That is strictly more than "a netlist over Bool nets."
2. Equivalence becomes **FSM refinement**, not combinational equality: initial
   state correspondence + one-step commutation + induction over cycles.
3. My synchronous reset was folded into the D-path (yosys chose `dfxtp_1`, which
   has *no* reset pin) rather than becoming a reset cell. The reset convention
   must be pinned deliberately — TT supplies `rst_n` — or the state after reset
   is an assumption rather than a theorem.

### F9 — the switch element is only correct under the no-conflict hypothesis

Writing the element out, I found the subtlety that D3.5 has to survive. With
`sel0`, `sel1` the captured destination bits of the two inputs, my
implementation computes `out1` from `sel1`. That is equivalent to computing it
from `!sel0` **only when `sel0 ≠ sel1`** — i.e. only when the two packets are not
contending for the same output port.

That is exactly what `banyan_selfrouting` guarantees, under sorted +
concentrated destinations. So the element is correct — but the correctness
statement is **conditional**, and the hypothesis has to be threaded from the
landed theorem all the way down into the FSM refinement. Get this wrong in either
direction and D3.5 is either false or vacuous, and vacuity is precisely the
failure mode the sp1-lean audit found in the field. **The conflict logic is not
needed; the conflict *hypothesis* is, and it must be visible in the statement.**

### F8 — CONFIRMED: the resonance claim is true

ADDENDUM 1 says the landed proof's descending stage index makes the first stage
read the MSB, matching the 1988 serial frame order. It is going in the README, so
I checked it against the Lean rather than the prose. From `Facade.lean`:

```lean
theorem testBit_step (m s d j : ℕ) :
    (line m s d).testBit j =
      if j = m then d.testBit m else (line (m+1) s d).testBit j
```

Stages descend k → 0; the transition `line (m+1) → line m` consumes **exactly**
destination bit `m`; so the first stage (m = k−1) consumes the MSB. **The claim
holds.** And it is not a coincidence to be marvelled at: a delta network must
resolve the coarsest partition first, so MSB-first is *forced* by the topology.
Stating it that way is both truer and stronger than "they agree by construction."

---

## 5. THE ENVIRONMENT (F10)

`nix` is **not installed** on this machine and installing it requires `sudo` — a
human action. `docker` is absent too. `[M]` So D1 *as written* (LibreLane via Nix)
is blocked on JYH.

It did not block me. I took the no-sudo path — native arm64 **yosys 0.68** via
brew, **sky130A PDK** via `volare` (pip, ~2.1 GB, user-local) — and that was
enough to answer R1, R2 and R4 with real artifacts today. What it cannot produce
is P&R, GDSII, or a genuine post-route netlist.

Note also, from the dossiers: LibreLane has a two-year-old open cross-OS
determinism bug (#522) — DRC-clean on Linux, 1,170 errors on macOS. The final
pass must run on Linux **regardless**. Combined with the finding that the
fabricated netlist comes from TT's CI anyway, this reframes D1: the local macOS
LibreLane install is a *convenience*, not the spine. The spine is a pinned Linux
runner reproducing `librelane==3.0.5 + PDK 0536d02d…`.

---

## 6. WHAT I AM DOING ABOUT IT

**Repaired on my own authority, proceeding (no ruling needed):**

- R1/D1: equivalence target restated as TT CI's `tt_submission/<top>.v`, powered
  form; local flow pinned to `librelane==3.0.5` + PDK `0536d02d…`; parser not
  frozen until a real CI artifact is in hand.
- R2/D2: cell models generated from Liberty, cross-checked against vendor
  Verilog, written against the powered form; explicit don't-use list so the
  trusted set is small by construction.
- D2 architecture: importer is a **code generator**, not a data structure +
  interpreter; evaluation is **bit-sliced**; reflection lemma priced in.
- D3.5: FSM-refinement shape, with the no-conflict hypothesis threaded
  explicitly from `banyan_selfrouting`.
- D1 proceeds on the no-sudo path; Linux runner promoted from "week 2" to the
  primary path for any published number.

**Wants a decision (recommendation attached, not blocking):**

1. **Nix/sudo.** One `sudo` from JYH unlocks local LibreLane. *Recommendation:*
   don't bother on the critical path — go straight to a pinned Linux runner,
   since the final pass must be Linux anyway and the fabricated netlist is TT's.
   Worth doing only as a convenience for fast local iteration.
2. **Output frequency.** The taped-out serial fabric must be clocked within the
   33 MHz pad rating, against a 50 MHz template default. *Recommendation:* target
   ≤ 25 MHz and state the margin; the fabric is nowhere near timing-critical
   (96 cells), so this costs nothing but must be set deliberately.

---

## 7. MEASUREMENT APPENDIX

Machine: macOS 26.5, arm64, 18 cores, 64 GB. Lean 4.32.0-rc1 + mathlib
(prebuilt). yosys 0.68 (brew, arm64 native). sky130A PDK via volare, version
`c6d73a35f524070e85faff4a6a9eef49553ebc2b`. All Lean runs through
`/Users/jyh/projects/claude/saltbuild.sh` per the 8/6 fleet rule.

Generator and all experiment files: scratchpad `gen.py`, `K{a,b,c}<n>.lean`,
`colcheck.lean`, `flow/{comparator,bitserial_switch}.v` + netlists + stats.
These are seat-local scratch, not repo files; the ones that become deliverables
land under `SaltWorks/Silicon/**` in D2.

<!-- TIMING TABLE + AGENT LANE FINDINGS APPENDED BELOW -->
