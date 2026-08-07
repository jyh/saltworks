`default_nettype none

module ce_c (
    input  wire i0,
    input  wire i1,
    input  wire i2,
    input  wire i3,
    input  wire i4,
    input  wire i5,
    input  wire i6,
    output wire o0,
    output wire o1,
    output wire o2,
    output wire o3,
    output wire o4,
    output wire o5
);
  wire n7;
  wire n8;
  wire n9;
  wire n10;
  wire n11;
  wire n12;
  wire n13;
  wire n14;
  wire n15;
  wire n16;
  wire n17;
  wire n18;
  wire n19;
  wire n20;
  wire n21;
  wire n22;
  wire n23;
  wire n24;
  wire n25;
  wire n26;
  wire n27;
  wire n28;
  wire n29;
  wire n30;
  wire n31;
  wire n32;
  wire n33;
  wire n34;
  wire n35;
  wire n36;
  wire n37;
  wire n38;
  wire n39;
  wire n40;

  sky130_fd_sc_hd__inv_1 g7 (.A(i0), .Y(n7));
  sky130_fd_sc_hd__and2_1 g8 (.A(i3), .B(n7), .X(n8));
  sky130_fd_sc_hd__inv_1 g9 (.A(n8), .Y(n9));
  sky130_fd_sc_hd__and2_1 g10 (.A(i5), .B(n7), .X(n10));
  sky130_fd_sc_hd__inv_1 g11 (.A(n10), .Y(n11));
  sky130_fd_sc_hd__and2_1 g12 (.A(i6), .B(n7), .X(n12));
  sky130_fd_sc_hd__xor2_1 g13 (.A(i1), .B(i2), .X(n13));
  sky130_fd_sc_hd__inv_1 g14 (.A(i1), .Y(n14));
  sky130_fd_sc_hd__inv_1 g15 (.A(i2), .Y(n15));
  sky130_fd_sc_hd__and2_1 g16 (.A(n14), .B(i2), .X(n16));
  sky130_fd_sc_hd__and2_1 g17 (.A(i1), .B(n15), .X(n17));
  sky130_fd_sc_hd__and2_1 g18 (.A(n11), .B(n13), .X(n18));
  sky130_fd_sc_hd__and2_1 g19 (.A(n18), .B(n16), .X(n19));
  sky130_fd_sc_hd__and2_1 g20 (.A(n10), .B(n12), .X(n20));
  sky130_fd_sc_hd__and2_1 g21 (.A(n20), .B(n13), .X(n21));
  sky130_fd_sc_hd__and2_1 g22 (.A(n21), .B(n17), .X(n22));
  sky130_fd_sc_hd__or2_1 g23 (.A(n19), .B(n22), .X(n23));
  sky130_fd_sc_hd__and2_1 g24 (.A(n8), .B(i4), .X(n24));
  sky130_fd_sc_hd__and2_1 g25 (.A(n9), .B(n23), .X(n25));
  sky130_fd_sc_hd__or2_1 g26 (.A(n24), .B(n25), .X(n26));
  sky130_fd_sc_hd__inv_1 g27 (.A(n26), .Y(n27));
  sky130_fd_sc_hd__and2_1 g28 (.A(n27), .B(i1), .X(n28));
  sky130_fd_sc_hd__and2_1 g29 (.A(n26), .B(i2), .X(n29));
  sky130_fd_sc_hd__or2_1 g30 (.A(n28), .B(n29), .X(n30));
  sky130_fd_sc_hd__and2_1 g31 (.A(n27), .B(i2), .X(n31));
  sky130_fd_sc_hd__and2_1 g32 (.A(n26), .B(i1), .X(n32));
  sky130_fd_sc_hd__or2_1 g33 (.A(n31), .B(n32), .X(n33));
  sky130_fd_sc_hd__or2_1 g34 (.A(n18), .B(n21), .X(n34));
  sky130_fd_sc_hd__or2_1 g35 (.A(n8), .B(n34), .X(n35));
  sky130_fd_sc_hd__and2_1 g36 (.A(i1), .B(i2), .X(n36));
  sky130_fd_sc_hd__and2_1 g37 (.A(n11), .B(n36), .X(n37));
  sky130_fd_sc_hd__and2_1 g38 (.A(n10), .B(n12), .X(n38));
  sky130_fd_sc_hd__or2_1 g39 (.A(n37), .B(n38), .X(n39));
  sky130_fd_sc_hd__inv_1 g40 (.A(n10), .Y(n40));
  assign o0 = n30;
  assign o1 = n33;
  assign o2 = n35;
  assign o3 = n26;
  assign o4 = n40;
  assign o5 = n39;
endmodule

`default_nettype wire
