// Behavioral models of the six sky130_fd_sc_hd cells the emitted
// structural RTL instantiates. TEST-ONLY — these are not part of the
// submission's source_files; the real cells come from the PDK in
// hardening. Port names follow the vendor library (note inv_1 drives
// Y where the two-input gates drive X — the asymmetry is real).
`default_nettype none

module sky130_fd_sc_hd__and2_1 (input wire A, input wire B, output wire X);
  assign X = A & B;
endmodule

module sky130_fd_sc_hd__or2_1 (input wire A, input wire B, output wire X);
  assign X = A | B;
endmodule

module sky130_fd_sc_hd__xor2_1 (input wire A, input wire B, output wire X);
  assign X = A ^ B;
endmodule

module sky130_fd_sc_hd__inv_1 (input wire A, output wire Y);
  assign Y = ~A;
endmodule

module sky130_fd_sc_hd__mux2_1 (input wire A0, input wire A1, input wire S, output wire X);
  assign X = S ? A1 : A0;
endmodule

module sky130_fd_sc_hd__dfxtp_2 (input wire D, input wire CLK, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule

`default_nettype wire
