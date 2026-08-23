#!/bin/bash
# fig4_classify.sh — the CORRECTED Figure-4 classifier.
#
# Usage:  fig4_classify.sh <flattened-gate-level-netlist.v>  > classes.tsv
#
# ⛔ WHY THIS EXISTS RATHER THAN A FLAG ON fig4_join.sh: `fig4_join.sh` REPRODUCES
# the 2026-08-12 join exactly, bit for bit, and that fidelity is the only control
# the reconstruction has (see its header). A tool that silently improved on its
# original could no longer be checked against it. So the CORRECTION lives here, as
# a separate, named instrument, and the two can be diffed against each other.
#
# ⛔ WHAT WAS WRONG WITH THE ORIGINAL, MEASURED 2026-08-22 (full population, both
# dies): it classified by CELL TYPE, and `dlygate4sd3_1` / `clkdlybuf4s25_1` merely
# SOUND clock-ish — OpenROAD uses them as general-purpose delay elements for hold
# fixing and fanout repair. On `_ndf` that put 1,286 data-path repair cells (22.4%
# of logic) into a class captioned "clock distribution". THE CELL TYPE IS THE NAME;
# THE INSTANCE NAME AND THE CONNECTIVITY ARE THE STRUCTURE.
#
# ✅ THE CORRECTION IS STRUCTURAL, NOT A RENAME: a cell is clock distribution IFF
# its input is driven by a clock net. Measured separation is total on both dies —
#     _ndf   hold*   0/757   fanout*   0/447   |  clkbuf_leaf*  79/79   clkload* 42/42
#     _c32   hold* 0/1267   fanout*   0/874   |  clkbuf_leaf* 115/115  clkload* 74/74
#
# ⚠️ THE CLOCK ROOT IS THE ONE EXCEPTION AND IT IS HANDLED EXPLICITLY: `clkbuf_0_clk`
# takes the PRIMARY CLOCK PORT (`clk`), not a `clknet_*`, so a naive "input is a
# clknet" test files the root of the clock tree as data-path repair. Exactly ONE
# such cell exists on each die. ⛔ MY OWN PUBLISHED `_ndf` FIGURE OF 132 OMITTED IT
# AND IS CORRECTED TO 133 — a defect found by building this script, not by review.
#
# ⚠️ AND THE TEST MUST BE RESTRICTED TO THE CLOCK-TYPED CLASS FIRST: a FLOP's first
# port is `.CLK`, so "input is a clock net" alone counts every sequential cell as
# clock distribution (1,681 of them on `_c32`). A flop is a clock SINK, not the
# tree. Restrict, then test.
#
# CLASS NAME RATIFIED AT COUNCIL 2026-08-23 (the Captain's words): the off-clock
# timing-repair class is "hold & fanout buffering". ⚠️ It is DOMINATED by hold and
# fanout but is not only those (slew/cap/wire repair ride along) — the caption
# should disclose the composition rather than let the name over-claim.
set -u
NL="${1:?usage: fig4_classify.sh <flattened gate-level netlist>}"
[ -f "$NL" ] || { echo "fig4_classify: no such netlist: $NL" >&2; exit 2; }

printf 'instance\tcell_type\tgroup\tfunction_color\tprovenance_color\n'
grep '^ *sky130_fd_sc_hd__' "$NL" | awk '
{
  type = $1; sub(/^sky130_fd_sc_hd__/, "", type)
  name = $2; sub(/^\\/, "", name)

  # first connected net — the driver of this cell`s first port. Trailing ")" and
  # any escape backslash are stripped so the clknet_ test is on the NET NAME.
  net = ""
  if (match($0, /\(\.[A-Z]+\(([^),]*)/)) {
    net = substr($0, RSTART, RLENGTH)
    sub(/^\(\.[A-Z]+\(/, "", net)
    sub(/^\\/, "", net)
  }

  if (type ~ /^(decap|fill|tapvpwrvgnd|diode)/) next     # physical: not drawn

  group = ""
  if (name ~ /^(cell|ser)[0-9]\./) { group = name; sub(/\..*$/, "", group) }

  clocktyped = (type ~ /^(dlygate|clkdlybuf|clkbuf|clkinv)/)
  # STRUCTURAL: on the clock tree iff driven by a clock net, PLUS the root, which
  # is driven by the primary clock port instead.
  onclock = (net ~ /^clknet_/) || (name ~ /^clkbuf_0_/)

  if      (group ~ /^cell/)        { fc = "mac_island_" group;    pc = "kernel_emitted" }
  else if (group ~ /^ser/)         { fc = "serializer_" group;    pc = "kernel_emitted" }
  else if (clocktyped && onclock)  { fc = "clock_tree";           pc = "tool_inserted_cts" }
  else if (clocktyped)             { fc = "hold_fanout_buffering";pc = "tool_inserted_timing_repair" }
  else if (type ~ /^(s?e?df[a-z]|s?e?dl[rx][a-z]|lpflow_inputisolatch)/)
                                   { fc = "fabric_sequential";    pc = "agent_written" }
  else if (type ~ /^mux/)          { fc = "fabric_mux";           pc = "agent_written" }
  else if (type ~ /^conb/)         { fc = "tie";                  pc = "agent_written" }
  # NON-clock-typed repair buffers: inserted by the resizer for slew/cap/wire/
  # fanout, so they are TOOL-authored and belong in legend class (5), not in the
  # fabric mass they are physically mixed into.
  else if (name ~ /^(load_slew|wire|max_cap|input)/)
                                   { fc = "drive_strengthening";  pc = "tool_inserted_timing_repair" }
  else if (name ~ /^(hold|fanout)/){ fc = "drive_strengthening";  pc = "tool_inserted_timing_repair" }
  else                             { fc = "fabric_combinational"; pc = "agent_written" }

  printf "%s\t%s\t%s\t%s\t%s\n", name, type, group, fc, pc
}'
