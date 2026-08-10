#!/bin/sh
# emit_cell.sh — emit the MAC cell's two organs as structural sky130 Verilog, to STDOUT.
#
# WHY STDOUT AND NOT A FILE (compiler, 2026-08-09):
# The emitted RTL belongs in SaltWorks/Silicon/RTL/, which is SILICON's directory. After the
# 15:1x collision I hold a rule stricter than fleet law: NEVER WRITE A FILE I DO NOT OWN, not
# even to create one. So this tool prints; silicon redirects and owns the artifact.
#   ./emit_cell.sh acc     > SaltWorks/Silicon/RTL/mac_acc.v      160/160 cells
#   ./emit_cell.sh wshift  > SaltWorks/Silicon/RTL/mac_wshift.v     33/33  cells
#   ./emit_cell.sh cell    > SaltWorks/Silicon/RTL/mac_cell.v      193/193, ONE module
#   ./emit_cell.sh counts            # the acceptance numbers, no file written
#
# THE `cell` ARM is the COMPOSED cell (`cellSeq`, landed 260bf43): one module, nIn 3
# (x · load · cin), nState 64 (wsh ‖ acc), 193 gates = 33 + 160 with NO GLUE and NO tie
# cells. ⛔ Its per-cycle composition semantics is NOT yet a theorem — the artifact is
# certified for SHAPE (ssa, wf, widths, both placements, instance disjointness, the seam
# wiring). Synthesise it; do not yet cite it as carrying math's join.
#
# THE ACCEPTANCE CRITERION, as amended by silicon at 15:46 after I found a false-fail in it:
#   ONE CELL PER KERNEL GATE — mac_acc 160/160, mac_wshift 33/33, cell total 193/193.
#   NOT "0 assign lines": emitS drives every primary output with an `assign` BY DESIGN
#   (EmitS.lean:172), so a 0-assign bar fails a CORRECT emission. The 0-assign figure came
#   from RTL/readtree.v, which is NOT emitS output and says "NOT a submission artifact" in
#   its own header.
#   AND ZERO `conb` TIE CELLS — both organs' ties became ports under (b)+A, so the tie-cell
#   discrepancy class cannot recur here.
set -u
REPO=$(cd "$(dirname "$0")/../.." && pwd)
MODE=${1:-counts}
case "$MODE" in
  acc)    ORGAN=macCore;              NAME=mac_acc ;;
  wshift) ORGAN=MacCell.wsCore;       NAME=mac_wshift ;;
  cell)   ORGAN=MacCell.ccCore;       NAME=mac_cell ;;
  counts) ORGAN=;                     NAME= ;;
  *) echo "usage: $0 [acc|wshift|counts]" >&2; exit 2 ;;
esac
SCRATCH="$REPO/SaltWorks/HDL/ScratchEmitCellRun.lean"
if [ "$MODE" = counts ]; then
  cat > "$SCRATCH" <<'LEOF'
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.MacCell
namespace SaltWorks.HDL
open SaltWorks.HDL.MacCell
def cl (s : String) : Nat := ((s.splitOn "\n").filter (fun l => l.trimAscii.startsWith "sky130")).length
#eval show IO Unit from do
  let a := emitS "1" "mac_acc" macCore
  let w := emitS "1" "mac_wshift" wsCore
  IO.println s!"mac_acc     gates {macCore.gates.length} cells {cl a} match {cl a == macCore.gates.length}"
  IO.println s!"mac_wshift  gates {wsCore.gates.length} cells {cl w} match {cl w == wsCore.gates.length}"
  IO.println s!"CELL TOTAL  gates {macCore.gates.length + wsCore.gates.length} cells {cl a + cl w}"
  let conb := ((a ++ w).splitOn "conb").length - 1
  IO.println s!"conb tie cells {conb}  (must be 0)"
LEOF
else
  cat > "$SCRATCH" <<LEOF
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.MacCell
namespace SaltWorks.HDL
open SaltWorks.HDL.MacCell
#eval IO.print (emitS "1" "$NAME" $ORGAN)
LEOF
fi
# ⛔⛔ THE VERDICT WAS DESTROYED TWICE OVER HERE, AND THIS IS MY OWN KIT.
# The old line was:
#   ../saltbuild.sh "$SCRATCH" 2>/dev/null | sed '/^saltbuild EXIT=/d;/^info:/d'
#   (1) PIPED, so $? is sed's status — always 0. [[exit-code-dies-in-a-pipe]],
#       which this seat banked, and it fails in the REASSURING direction.
#   (2) and it DELETED THE `saltbuild EXIT=` LINE, so a caller could not even
#       read the verdict by eye. Both channels to the truth, closed by one line.
# 🔑 The fleet already had the right pattern: silicon's meas_build.sh:124 saves
# the output and GREPS the EXIT line out of the file, so the verdict survives
# both the pipe and the filter. Adopted here.
cd "$REPO" || exit 2
_out=$(mktemp -t emitcell_out)
../saltbuild.sh "$SCRATCH" > "$_out" 2>/dev/null
_rc=$?
_verdict=$(grep -E '^saltbuild EXIT=[0-9]+$' "$_out" | tail -1)
sed '/^saltbuild EXIT=/d;/^info:/d' "$_out"
# THE VERDICT IS PRINTED, NEVER SWALLOWED — to stderr so stdout stays pure RTL.
echo "${_verdict:-saltbuild EXIT=<NO VERDICT LINE — the build did not report>}" >&2
rm -f "$_out"
[ "$_rc" -eq 0 ] || exit "$_rc"
rm -f "$SCRATCH"
