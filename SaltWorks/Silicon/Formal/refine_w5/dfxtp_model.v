// The one sequential cell the fabricated design uses, as a plain edge flop. The gold RTL
// instantiates it structurally (mac_cell_signed_shell.v, ser_organ.v); its liberty function is
// IQ' = D on the rising CLK edge, Q = IQ. Read with -overwrite after the liberty.
module sky130_fd_sc_hd__dfxtp_2(input CLK, input D, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule
