#!/bin/bash
# emit_seq.sh — PRINT the clocked emission of a Seq. R6/R8, the night council.
#
#   sh docs/hdl-tools/emit_seq.sh            # the signed cell, L1 (no shell)
#   sh docs/hdl-tools/emit_seq.sh > path.v   # caller decides where it lands
#
# PRINTS, NEVER WRITES — the .v files live in SaltWorks/Silicon/RTL/ and that is
# SILICON's slot. This script hands you bytes; you own the file you put them in.
#
# L1 = V7's exact object: core + one dfxtp_2 per state bit + feedback. NO shell
# (no CLEAR, no en_wsh/en_acc) — that is L2, emitted separately with its own
# counted criterion. Do not read L1 as the ratified cell.
#
# DRIVES (R2, and both are PDK facts): combinational at _1 (the owned TT-CI
# green); flops at _2 because dfxtp_1 is on the pinned sky130A no_synth.cells.
#
# V7 ACCEPTANCE, checkable on the OUTPUT of this script and not on its source:
#   grep -c 'dfxtp'              == nState              (64 for scellSeq)
#   grep -cE 'sky130_fd_sc_hd__' == gates + nState      (289)
#   grep -c 'conb'               == the Circ's .const   (0)
#   grep -c '^  assign'          == outs.length         (96)
#   grep -c 'initial'            == 0                   (the power-gating law)
#   grep -c 'dfxtp_1'            == 0                   (R2)
set -e
cd "$(dirname "$0")/../.."
SCRATCH=$(mktemp -t emitseq).lean
cat > "$SCRATCH" <<'LEAN'
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.MacCell
open SaltWorks.HDL SaltWorks.HDL.MacCell
#eval IO.print (emitSeq "1" "2" "mac_cell_signed_seq" scellSeq)
LEAN
# through the fleet wrapper: it holds the build lock and records the run
../saltbuild.sh "$SCRATCH" | sed '/^saltbuild EXIT=/d'
rm -f "$SCRATCH"
