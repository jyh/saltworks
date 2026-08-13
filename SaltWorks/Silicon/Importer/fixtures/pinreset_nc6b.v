module pinreset_fx(clk, rst_n, d0, d1, q0, q1);
  input clk;
  input rst_n;
  input d0;
  input d1;
  output q0;
  output q1;
  wire w0;
  wire n0;
  wire s0;
  wire s1;
  sky130_fd_sc_hd__inv_1 _00_ (.A(d0), .Y(n0));
  sky130_fd_sc_hd__and2_1 _01_ (.A(n0), .B(d1), .X(w0));
  sky130_fd_sc_hd__dfrtp_1 _02_ (.CLK(clk), .D(w0), .Q(s0), .RESET_B(rst_n));
  sky130_fd_sc_hd__dfrtp_1 _03_ (.CLK(clk), .D(d1), .Q(s1), .RESET_B(rst_n));
  // sky130_fd_sc_hd__dfrtp_1 _99_ (.CLK(clk), .D(d0), .Q(zz), .RESET_B(rst_n));
  sky130_fd_sc_hd__buf_1 _04_ (.A(s0), .X(q0));
  sky130_fd_sc_hd__buf_1 _05_ (.A(s1), .X(q1));
endmodule
