/* FIXTURE for instrument_selftest.sh — C-V1 (port list vs vector declaration).
 *
 * Deliberately NOT in Flow/: import_sweep.py and cell_coverage.py both scan
 * Flow/*.v non-recursively, and a fixture landing there would move the 46-netlist
 * denominator that two pre-registered bars are stated against.
 *
 * UNFAULTED this module is scalar-clean and imports with `--inputs a,b`.
 * The self-test's fault WIDENS a port to a vector without widening the caller's
 * port list — which is the realistic form of the hazard C-V1 exists for: an RTL
 * port grows, a hand-recorded port list in reimport.sh does not, and before C-V1
 * that combination produced a datum with a silently narrowed input space, RC=0,
 * readback GREEN.
 */
module vecbase(a, b, y);
  input a;
  wire a;
  input b;
  wire b;
  output y;
  wire y;
  sky130_fd_sc_hd__and2_1 g0 (
    .A(a),
    .B(b),
    .X(y)
  );
endmodule
