#!/bin/bash
# fig4_join.sh — THE STRUCTURAL JOIN, REBUILT AS CODE.
#
# ⛔ WHY THIS FILE EXISTS, AND IT IS THIS SEAT'S OWN BANKED DEFECT CHARGED TO
# ITSELF: the 2026-08-12 Figure-4 join landed its OUTPUT
# (SaltWorks/Silicon/Flow/fig4_cell_coloring.tsv) and its METHOD DOC
# (docs/silicon-figure4-structural-join-0812.md) in commit 8a169e9 — AND NO CODE.
# The join ran in a session scratchpad, which is session-scoped and died with the
# session. Ten days later the helm commissioned "re-run the EXISTING join" and
# there was no existing join to run: only an output and a prose description.
# ⇒ A RESULT WITHOUT ITS PRODUCER IS NOT REPRODUCIBLE, IT IS ONLY QUOTABLE.
# The method doc was good enough to rebuild from, which is the only reason this
# was cheap. That is luck, not a process.
#
# Usage:  fig4_join.sh <flattened-gate-level-netlist.v>   > coloring.tsv
#
# ⭐ THE CONTROL THAT LICENSES THIS RECONSTRUCTION, and it is RUN rather than
# asserted here: `fig4_join_selftest.sh <netlist>` (beside this file) verifies the
# input's sha256, reproduces the committed TSV row-by-row, AND proves the
# comparison can go red. A rebuilt instrument that has not been shown to reproduce
# the artifact it replaces is A GUESS WEARING THE ORIGINAL'S NAME.
#
# ⛔⛔ KNOWN DEFECT, INHERITED DELIBERATELY — READ BEFORE USING THE OUTPUT.
# THIS SCRIPT REPRODUCES THE 0812 JOIN FAITHFULLY, AND THE 0812 JOIN IS WRONG
# ABOUT `clock_tree`. Measured 2026-08-22, full population, total separation:
#     called clock_tree            1,418   (24.8% of logic)
#       on a clock net (clknet_*)    132   ( 2.3%)  <- genuine clock distribution
#       NOT on a clock net         1,286   (22.4%)  <- hold-fix + max-fanout, DATA paths
#     hold*    0 of 757 on a clock net · fanout*   0 of 447
#     clkbuf_leaf* 79 of 79       · clkload*  42 of 42     <- positive controls
# 486 of the 757 `hold*` cells take their input straight off `\core.rf` — they are
# hold-violation fixes on DATA paths, not clock distribution.
# 🔑 THE MECHANISM, AND IT INVERTS THIS JOIN'S OWN STATED RULE: it classifies by
# CELL TYPE, and `dlygate4sd3_1`/`clkdlybuf4s25_1` merely have clock-ish names —
# OpenROAD uses them as GENERAL-PURPOSE DELAY ELEMENTS for hold and fanout repair.
# The 0812 doc says "provenance uses structure, not names"; HERE THE CELL TYPE IS
# THE NAME AND THE INSTANCE NAME IS THE STRUCTURE. A true reading of the wrong
# object. (5 cells called core_combinational do sit on a clock net — same pass,
# opposite sign.)
# ⚖️ THE DEFECT IS NOT FIXED HERE ON PURPOSE: fidelity to 8a169e9's output is the
# only control this reconstruction has, and a tool that silently improves on its
# original cannot be checked against it. The corrected classifier is a SEPARATE,
# NAMED change — and because the defect is in the CLASSIFIER it propagates into
# ANY die, so a regenerated Figure 4 would look fresh and carry the identical
# error. Fixing it is a PRECONDITION of the die choice, not an alternative to it.
#
# ⛔ CRLF, AND IT COST ME A SILENT ZERO WHILE I WAS BUILDING THIS: the committed
# fig4_cell_coloring.tsv has \r\n line endings, so its LAST field carries a
# trailing \r. `awk -F'\t' '$5=="tool_inserted_drive"'` matches NOTHING while
# `grep -c tool_inserted_drive` returns 40 — and, worse, `print $5 | uniq -c`
# prints a PERFECTLY CORRECT-LOOKING distribution, because \r only moves the
# cursor. THE SAME FIELD READ TWO WAYS GAVE A RIGHT ANSWER AND A SILENT ZERO.
# This script emits \n and the selftest strips \r before comparing; neither is
# optional.
set -u
NL="${1:?usage: fig4_join.sh <flattened gate-level netlist>}"
[ -f "$NL" ] || { echo "fig4_join: no such netlist: $NL" >&2; exit 2; }

# The netlist is FLATTENED to one module. An instance line is
#     <sky130 cell type> <instance name> (.PORT(net), ...
# so field 1 is the type and field 2 is the name. Attribution is by HIERARCHICAL
# PREFIX on the NAME (\cell0. …), never by leaf identifier — the standing rule
# from the cell3 episode, where a name-join would have painted a kernel-emitted
# MAC cell as hand RTL.
#
# ⚠️ PHYSICAL cells (decap/fill/tap/antenna/diode) are EXCLUDED, not colored:
# Figure 4 is the LOGIC-VISIBLE view. They are ~89% of instances and coloring
# them would drown the figure the join exists to explain.
printf 'instance\tcell_type\tgroup\tfunction_color\tprovenance_color\n'
grep '^ *sky130_fd_sc_hd__' "$NL" | awk '
{
  type = $1; sub(/^sky130_fd_sc_hd__/, "", type)
  # Verilog escapes a hierarchical identifier with a leading backslash. It is
  # ESCAPING SYNTAX, not part of the name, and the committed TSV strips it.
  raw = $2
  name = raw; sub(/^\\/, "", name)

  # physical/filler — excluded from the logic-visible view
  if (type ~ /^(decap|fill|tapvpwrvgnd|diode)/) next

  # group: the surviving hierarchical prefix, the ONLY naming evidence
  group = ""
  # ⛔ TESTED ON THE STRIPPED NAME, NOT THE RAW ONE. The first version of this
  # tested `name` for a leading backslash AFTER stripping it — so every named
  # cell fell through to anonymous/agent_written and 1,443 cells were silently
  # mispainted. Caught only by the diff against the committed output; the census
  # totals alone would NOT have caught it, since the totals were computed by a
  # different query that still carried the backslash.
  if (name ~ /^(cell|ser)[0-9]\./) {
    group = name
    sub(/\..*$/, "", group)
  }

  # FUNCTION — what it does. Structure first, names only where they survived.
  if      (group ~ /^cell/)                              fc = "mac_island_" group
  else if (group ~ /^ser/)                               fc = "serializer_" group
  else if (type ~ /^(dlygate|clkdlybuf|clkbuf|clkinv)/)  fc = "clock_tree"
  else if (type ~ /^(s?e?df[a-z]|s?e?dl[rx][a-z]|lpflow_inputisolatch)/) fc = "core_sequential"
  else if (type ~ /^mux/)                                fc = "core_mux"
  else if (type ~ /^conb/)                               fc = "tie"
  else                                                   fc = "core_combinational"

  # PROVENANCE — who wrote it. These cells are tool-inserted and authored by
  # nobody, which is a category as distinct from agent-written as from
  # kernel-emitted. ⛔ BUT SEE THE DEFECT BLOCK AT THE TOP: "tool_inserted_cts"
  # is the RIGHT answer to "who wrote it" and the WRONG answer to "what is it",
  # because 85% of that class is timing repair, not clock tree.
  # ⚠️ THE DRIVE RULE IS NARROWER THAN IT LOOKS, and it is reproduced here as the
  # 0812 join actually behaved rather than as its doc reads: only buf_4 repair
  # buffers count. The 12 `load_slew* buf_2` and 3 `wire*` cells the original
  # left as agent_written are REPRODUCED, not silently corrected — a
  # reconstruction that improves its original cannot be checked against it.
  if      (group != "")                                        pc = "kernel_emitted"
  else if (fc == "clock_tree")                                 pc = "tool_inserted_cts"
  else if (name ~ /^(load_slew|wire)/ && type == "buf_4")      pc = "tool_inserted_drive"
  else                                                         pc = "agent_written"

  printf "%s\t%s\t%s\t%s\t%s\n", name, type, group, fc, pc
}'
