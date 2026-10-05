#!/bin/sh
# build.sh <src.S> <outdir> — assemble+link for core32 (rv32i, base 0) and emit a byte hex + tohost.
set -eu
src=$1; out=$2; HERE=$(cd "$(dirname "$0")" && pwd); RT=${RVTESTS:-}
n=$(basename "$src" .S); mkdir -p "$out"
riscv64-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -static -T "$HERE/env/link.ld" \
  -I "$HERE/env" ${RT:+-I "$RT/isa/macros/scalar"} -o "$out/$n.elf" "$src"
riscv64-elf-objcopy -O verilog --verilog-data-width=1 "$out/$n.elf" "$out/$n.hex"
riscv64-elf-nm "$out/$n.elf" | awk '$3=="tohost"{print $1}' > "$out/$n.tohost"
[ -s "$out/$n.tohost" ] || { echo "⛔ no tohost symbol in $n"; exit 2; }
