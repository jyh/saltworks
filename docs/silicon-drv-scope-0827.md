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
