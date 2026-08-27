# DRV repair — scope re-measured, and the toolchain null
silicon, 2026-08-27T00:26:33-0700. Helm ruling 00:2x: the NDF gate's stated reason is MONEY, so the 08/09
decoupling still covers this work and DRV repair is LIVE. Measured, applied, acted.

## 1. THE RECORDED SCOPE IS A TRUE READING OF THE WRONG ARTIFACT
`QUEUE.md` prices the repair at **"637 typical / 1,678 worst-corner slew"**. Both numbers are
real and both live in **`slicea16bma_metrics.json` — the 2x2 run**, located exactly:

    637   slicea16bma_metrics.json  design__max_slew_violation__count__corner:max_tt_025C_1v80
    1678  slicea16bma_metrics.json  design__max_slew_violation__count__corner:max_ss_100C_1v60

But the 2x2 is the SUPERSEDED artifact — the honest reading was that -ma does not fit a 2x2, and
the Captain's executable word is "BYTE-WIDE -ma ON ITS OWN 3x2". The live candidate is
`slicea16bma_3x2_metrics.json`:

    metric                        2x2 (recorded)    3x2 (LIVE)     delta
    max_slew  max_tt (typical)              637           854      +34%
    max_slew  max_ss (worst)              1,678         2,019      +20%
    max_cap                                  39            51      +31%
    max_fanout                               11            39      +254%
    magic DRC / LVS / antenna              0/0/0         0/0/0      clean

=> **THE REPAIR IS PRICED AGAINST THE OLD DIE. Fanout is understated 3.5x.** Adjacent-object
principle: a wrong number is usually a true reading of an adjacent object, and an EXACT match
(1,678) is what makes it convincing. This row is the maestro's to amend; flagged, not rewritten.

## 2. MEASURED NULL — THE REPAIR IS NOT EXECUTABLE ON THIS BOX
`librelane`, `openlane`, `openlane2`, `nix`: all ABSENT; `import librelane` fails.
QUEUE line 1082 records "LibreLane UP" — that is a dated measurement from another context and it
does not reproduce here. A null is a finding; the flow cannot be re-run from this seat.

## 3. WHAT IS EXECUTABLE HERE, AND IT NARROWS THE REPAIR SHARPLY
Fanout measured from the gate netlist (2,547 cells, 2,549 loaded nets):

    fanout 1-4    : 2393 nets      <- 93.9% of the design is already fine
    fanout 5-9    :   58
    fanout 10-19  :   47
    fanout 20-39  :   41
    fanout 40+    :   10

    TOP OFFENDERS            fanout   driver
    clk                         545   top-level port (CTS's job, not a DRV repair)
    imm_i[1]                    131   sky130_fd_sc_hd__dfxtp_1
    instr[15]                   110   sky130_fd_sc_hd__dfxtp_1
    instr[17]                   105   sky130_fd_sc_hd__dfxtp_1
    instr[16]                   101   sky130_fd_sc_hd__dfxtp_1
    imm_i[0]                     98   sky130_fd_sc_hd__dfxtp_1
    rst_n                        74   top-level port
    imm_i[2]                     68   sky130_fd_sc_hd__dfxtp_1

=> **THE DRV LOAD IS STRUCTURAL AND CONCENTRATED, NOT DIFFUSE.** Six MINIMUM-DRIVE flops
(`dfxtp_1`) drive 68-131 loads each: the instruction register and the immediate register
fanning out across the datapath. That is the whole shape of the slew/fanout problem, and it
matches the standing family finding that "the register file is the mass".
The repair is therefore buffer trees on ~7 register-output nets plus ~90 mid-fanout nets —
NOT a global buffering pass.

⚠️ **SCOPE OF THIS MEASUREMENT, STATED SO IT IS NOT OVER-READ:** taken on the YOSYS synthesis
netlist of the same RTL. The config feeds `rtl/slicea16bma.v`, so LibreLane performs its OWN
synthesis and resizing; these are the RTL's INTRINSIC fanout structure, not the flow's
post-resizer netlist. It says WHERE the load concentrates. It does not predict residual counts.

## 4. A CONTROL WORTH KEEPING
`timing__drv__floating__nets = 2` in ALL SIX runs — including `mac_cell` and `mac_wshift`,
which have ZERO violations of every other kind. A value constant across trivial and complex
designs alike is a FLOW CONSTANT, not a defect signal. Do not chase it.

## 5. THE LIVE CONFIG CARRIES NO REPAIR KNOBS
`slicea16bma_3x2_config.json` has 12 keys and not one DRV/resizer variable — it ran on
defaults. Naming specific repair settings without being able to run them would be speculation,
so none are proposed here; the measurement above is what a repair run should be aimed at.

## 6. IS THE ADDRESS-MUX PATH THE CAUSE? NO — AND THE FIRST ANSWER WAS WRONG
Comparing `-b` (no address mux) against `-ma` (multiplexed address):

    design              cells   nets  fo>=10  fo>=40  max fo   sum of fo>=10 load
    slicea16b_nl.v       2706   2718     105      13     527                3,192
    slicea16bma_nl.v     2547   2549      98      10     545                2,722

=> **-ma HAS LESS HIGH-FANOUT LOAD THAN -b, NOT MORE.** The address path is NOT what drives the
DRV bill. This is consistent with the standing note that "the 4.9% headroom predates the address
path" — and it means DRV repair effort must not be charged to the -ma decision.

⛔ **AND THE FIRST READING SAID THE OPPOSITE, WHICH IS THE PART WORTH BANKING.** Looking up -ma's
top nets inside -b gave:

    imm_i[1]   -ma=131  -b=5      instr[15]  -ma=110  -b=4      imm_i[0]  -ma=98  -b=5

which reads as "the address mux exploded the fanout 20-30x". **IT IS A NAMING ARTIFACT.** The
control — listing **-b's OWN top nets**, which the first query structurally could not see —
returns `_0000_[0..3]` and `_0001_[0..3]` at fanout 61-159, every one driven by the same
`sky130_fd_sc_hd__dfxtp_1`. *Yosys named the same registers anonymously in one netlist and
`imm_i`/`instr` in the other.*

=> ***PER-NET NAME COMPARISON ACROSS TWO SEPARATELY-SYNTHESISED NETLISTS IS MEANINGLESS.*** Only
the AGGREGATE profile is comparable. A question shaped "where are MY top nets in the other file?"
makes every row that is not one of mine invisible — the same shape as the adjacent-object figures
in section 1, twice in one sitting on the same task.

## 7. WHAT THIS ADDS UP TO
The DRV load is **intrinsic to Slice A's register structure — six to eight minimum-drive flops
carrying 60-160 loads — and it is present in BOTH variants.** It is not an -ma regression, not
diffuse, and not a routing accident. It is the instruction/immediate registers fanning across the
datapath on `dfxtp_1`, and the repair that fits that shape is drive-strength/buffer-tree work on
a named handful of nets. That is a LibreLane resizer job and this box cannot run it (section 2).

---

# ⛔⛔ CORRECTION, 00:5x — TWO OF MY OWN CLAIMS ABOVE ARE WRONG. AMENDED, NOT REWRITTEN.

## C1. "not one DRV/resizer variable — it ran on defaults" IS FALSE
`MAX_FANOUT_CONSTRAINT: 10` **is** in the live 3×2 config — inside the nested `"pdk::sky130A"`
object. **I counted TOP-LEVEL KEYS (12) and reported that as a fact about the whole config.**
A shallow query, published as a deep fact, in a commit and on the bus.

⭐ **AND THE CORRECTED FACT IS A BETTER DIAGNOSIS THAN THE WRONG ONE WAS:**

    constraint set        MAX_FANOUT_CONSTRAINT = 10
    intrinsic (netlist)   98 nets at fanout >= 10
    residual (3x2 run)    39 max_fanout violations

=> **THE RESIZER RAN, AND IT CLOSED ROUGHLY 60% (98 -> 39). It could not close the largest nets.**
So the repair is NOT "set a fanout constraint" — the constraint was already set and enforced.
It is: give the resizer what it needs to close 60-160-load nets at 80% target density, or accept
higher-drive flops on those six-to-eight register outputs. *"It ran on defaults" would have sent
the next hand to add a knob that has been there since 08/09.*

## C2. "the flow cannot be re-run from this seat" OVERSTATES A TRUE MEASUREMENT
Natively absent — TRUE, and re-measured. **But the recorded venue was never a native install:**

    docker run --rm -v /tmp/tilefit3x2:/work -v /tmp/silicon_pdk:/pdkroot \
      ghcr.io/librelane/librelane:3.0.5 librelane --pdk-root .../c6d73a35... /work/config.json

    docker binary                      PRESENT  /usr/local/bin/docker
    docker daemon                      DOWN
    pinned image :3.0.5                UNKNOWN (cannot query, daemon down)
    PDK, pinned sha c6d73a35...        PRESENT  ~/.volare/volare/sky130/versions/  (8.4 GB)
    /tmp/silicon_pdk, /tmp/tilefit3x2  ABSENT (tmp cleared; both are re-creatable mounts)

=> ***A TRUE CONSTRAINT MANUFACTURED A FALSE LIMITATION BECAUSE I CONSIDERED ONE VENUE.*** I
tested for `librelane|openlane|nix` on PATH, found nothing, and wrote "not executable here" —
while the repo's own banked invocation says DOCKER, and the 8.4 GB PDK sits on disk at the exact
pinned sha. **The blocker is a stopped daemon and an unverified image, not an absent toolchain.**

⚠️ **AND I AM STILL NOT FIRING IT UNILATERALLY, FOR A REASON THAT IS NOT THE ONE I GAVE:**
a LibreLane run in Docker **does NOT take saltbuild's fleet lock**, so it would run CONCURRENTLY
with peers' Lean builds. That lock is a MEMORY-SAFETY law here (measured peak 43 GB across four
lean processes). Starting an unlocked multi-GB flow overnight, beside seats that are building, is
a fleet-wide hazard I should not take alone. **THAT is the real gate on execution — a resource
protocol, not a missing tool — and it is a decision, not a measurement.**
