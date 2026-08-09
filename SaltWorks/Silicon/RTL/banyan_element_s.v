`default_nettype none

module banyan_element_s (
    input  wire i0,
    input  wire i1,
    input  wire i2,
    input  wire i3,
    input  wire i4,
    input  wire i5,
    output wire o0,
    output wire o1
);
  wire n6;
  wire n7;
  wire n8;
  wire n9;
  wire n10;
  wire n11;

  sky130_fd_sc_hd__and2_1 g6 (.A(i0), .B(i4), .X(n6));
  sky130_fd_sc_hd__and2_1 g7 (.A(i1), .B(i5), .X(n7));
  sky130_fd_sc_hd__or2_1 g8 (.A(n6), .B(n7), .X(n8));
  sky130_fd_sc_hd__and2_1 g9 (.A(i2), .B(i4), .X(n9));
  sky130_fd_sc_hd__and2_1 g10 (.A(i3), .B(i5), .X(n10));
  sky130_fd_sc_hd__or2_1 g11 (.A(n9), .B(n10), .X(n11));
  assign o0 = n8;
  assign o1 = n11;
endmodule

`default_nettype wire
