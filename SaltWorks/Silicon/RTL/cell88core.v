`default_nettype none

module cell88core (
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
    output wire o5,
    output wire o6
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
  wire n41;
  wire n42;
  wire n43;
  wire n44;
  wire n45;
  wire n46;

  sky130_fd_sc_hd__inv_1 g7 (.A(i0), .Y(n7));
  sky130_fd_sc_hd__and2_1 g8 (.A(i2), .B(n7), .X(n8));
  sky130_fd_sc_hd__and2_1 g9 (.A(i3), .B(n7), .X(n9));
  sky130_fd_sc_hd__and2_1 g10 (.A(i4), .B(n7), .X(n10));
  sky130_fd_sc_hd__inv_1 g11 (.A(n8), .Y(n11));
  sky130_fd_sc_hd__inv_1 g12 (.A(n9), .Y(n12));
  sky130_fd_sc_hd__inv_1 g13 (.A(n10), .Y(n13));
  sky130_fd_sc_hd__and2_1 g14 (.A(n12), .B(n13), .X(n14));
  sky130_fd_sc_hd__and2_1 g15 (.A(n11), .B(n14), .X(n15));
  sky130_fd_sc_hd__and2_1 g16 (.A(n8), .B(n14), .X(n16));
  sky130_fd_sc_hd__and2_1 g17 (.A(n9), .B(n13), .X(n17));
  sky130_fd_sc_hd__and2_1 g18 (.A(n11), .B(n17), .X(n18));
  sky130_fd_sc_hd__and2_1 g19 (.A(n8), .B(n17), .X(n19));
  sky130_fd_sc_hd__and2_1 g20 (.A(n12), .B(n10), .X(n20));
  sky130_fd_sc_hd__and2_1 g21 (.A(n11), .B(n20), .X(n21));
  sky130_fd_sc_hd__and2_1 g22 (.A(n8), .B(n20), .X(n22));
  sky130_fd_sc_hd__and2_1 g23 (.A(n16), .B(i5), .X(n23));
  sky130_fd_sc_hd__or2_1 g24 (.A(n18), .B(n19), .X(n24));
  sky130_fd_sc_hd__and2_1 g25 (.A(n24), .B(i1), .X(n25));
  sky130_fd_sc_hd__and2_1 g26 (.A(n21), .B(i6), .X(n26));
  sky130_fd_sc_hd__and2_1 g27 (.A(n22), .B(i5), .X(n27));
  sky130_fd_sc_hd__or2_1 g28 (.A(n23), .B(n25), .X(n28));
  sky130_fd_sc_hd__or2_1 g29 (.A(n28), .B(n26), .X(n29));
  sky130_fd_sc_hd__or2_1 g30 (.A(n29), .B(n27), .X(n30));
  sky130_fd_sc_hd__inv_1 g31 (.A(n16), .Y(n31));
  sky130_fd_sc_hd__and2_1 g32 (.A(n16), .B(i1), .X(n32));
  sky130_fd_sc_hd__and2_1 g33 (.A(n31), .B(i6), .X(n33));
  sky130_fd_sc_hd__or2_1 g34 (.A(n32), .B(n33), .X(n34));
  sky130_fd_sc_hd__inv_1 g35 (.A(n34), .Y(n35));
  sky130_fd_sc_hd__and2_1 g36 (.A(n30), .B(n35), .X(n36));
  sky130_fd_sc_hd__and2_1 g37 (.A(n30), .B(n34), .X(n37));
  sky130_fd_sc_hd__and2_1 g38 (.A(n15), .B(i1), .X(n38));
  sky130_fd_sc_hd__or2_1 g39 (.A(n38), .B(n18), .X(n39));
  sky130_fd_sc_hd__or2_1 g40 (.A(n21), .B(n22), .X(n40));
  sky130_fd_sc_hd__or2_1 g41 (.A(n39), .B(n40), .X(n41));
  sky130_fd_sc_hd__or2_1 g42 (.A(n16), .B(n18), .X(n42));
  sky130_fd_sc_hd__or2_1 g43 (.A(n19), .B(n40), .X(n43));
  sky130_fd_sc_hd__and2_1 g44 (.A(i6), .B(n7), .X(n44));
  sky130_fd_sc_hd__and2_1 g45 (.A(n44), .B(n31), .X(n45));
  sky130_fd_sc_hd__or2_1 g46 (.A(n32), .B(n45), .X(n46));
  assign o0 = n36;
  assign o1 = n37;
  assign o2 = n41;
  assign o3 = n42;
  assign o4 = n43;
  assign o5 = i1;
  assign o6 = n46;
endmodule

`default_nettype wire
