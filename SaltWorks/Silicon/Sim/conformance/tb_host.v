`timescale 1ns/1ps
`default_nettype none
// tb_host — a HOST for the fabricated top tt_um_saltworks_ndf_c32, the same bench for RTL and the
// signed-off gate-level netlist (-DGL_TEST). silicon, 2026-10-04, STEP 0 (helm route @75,145,900).
//
// WHAT IT READS, AND FROM WHERE — the whole claim of this bench is in these lines:
//   RESULTS   only at the PINS: every store is reassembled from uo_out over its two loops
//             (address loop, then data loop), typed by uio_out[1:0] at phase 0. Nothing about
//             a result is read from inside the design.
//   PHASE     the host keeps its OWN phase counter from reset and CHECKS it against the pins at
//             phases 1..3 (uio_out[1:0] == phase there). Any disagreement is counted and voids the run.
//   ADDRESS   +addr=pins (default): the host serves byte k at phase k from the address's LOW BYTE,
//             seen on uo_out at phase 0 and latched — so the image must fit in 256 B. Pins only.
//             +addr=net : the host takes the FULL address from the named keep-nets pc_q / alu_y
//             (they survive by name in the GL netlist). Needed for images > 256 B. That is the
//             ONLY internal read, it decides WHICH word is served, and it never touches a result.
//   HALT      the first store whose pin-read address equals +tohost=<hex>. Or +cycles cap (TIMEOUT).
// The host is COMBINATIONAL (in-phase), the assumption the datasheet's own §7 names.
module tb;
  reg clk = 0, rst_n = 0, ena = 1;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in = 8'h00;           // sof (uio_in[6]) held LOW for the whole run
  wire [7:0] uo_out, uio_out, uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1, VGND = 1'b0;
`endif
  tt_um_saltworks_ndf_c32 user_project (
`ifdef GL_TEST
    .VPWR(VPWR), .VGND(VGND),
`endif
    .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe),
    .ena(ena), .clk(clk), .rst_n(rst_n));

  integer HALF = 50;                    // 100 ns cycle: unit-delay GL settles well inside it
  always #(HALF) clk = ~clk;

  localparam T_IDLE=2'b00, T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;
  reg [7:0] mem [0:65535];
  reg [31:0] tohost; integer maxcyc; reg netaddr;
  reg [8*256:1] hexfile;

  // ---- host phase, kept by the HOST ---------------------------------------------------
  reg [1:0] hp;
  always @(posedge clk) hp <= !rst_n ? 2'd0 : hp + 2'd1;
  wire [1:0] typ_now = uio_out[1:0];
  reg  [1:0] typ_r; reg [7:0] a0_r;
  // Latched at the posedge that ENDS phase 0 (pre-edge values), NOT at a negedge: after reset the
  // first phase 0 is only the half-cycle between release and the first posedge, and a negedge
  // latch raced the release and served X for bytes 1..3 of the very first fetch (driven, 10-04).
  always @(posedge clk) if (rst_n && hp == 2'd0) begin typ_r <= typ_now; a0_r <= uo_out; end
  wire [1:0] typ = (hp == 2'd0) ? typ_now : typ_r;
  wire [7:0] a0  = (hp == 2'd0) ? uo_out  : a0_r;

`ifdef GL_TEST
  `include "glnames.vh"
  wire [31:0] pcq = `PC_Q;  wire [31:0] aluy = `ALU_Y;
`else
  wire [31:0] pcq = user_project.core.u_core.pc_q;  wire [31:0] aluy = user_project.core.u_core.alu_y;
`endif
  wire [31:0] addr = netaddr ? ((typ == T_FETCH) ? pcq : aluy) : {24'h0, a0};
  wire [15:0] wa = {addr[15:2], 2'b00};
  wire [31:0] word = {mem[wa+3], mem[wa+2], mem[wa+1], mem[wa]};
  wire [31:0] serve = (typ == T_FETCH || typ == T_LOAD) ? word : 32'h0;
  always @(*) case (hp)
    2'd0: ui_in = serve[7:0];   2'd1: ui_in = serve[15:8];
    2'd2: ui_in = serve[23:16]; default: ui_in = serve[31:24];
  endcase

  // ---- stores, read at the PINS -------------------------------------------------------
  reg [31:0] sa, sd; reg sbeat; integer nst = 0, nfetch = 0, nload = 0, phase_bad = 0, cyc = 0;
  reg halted; reg [31:0] haltval;
  always @(negedge clk) if (rst_n) begin
    cyc = cyc + 1;
    if (hp != 2'd0 && uio_out[1:0] !== hp) phase_bad = phase_bad + 1;
    if (hp == 2'd0 && typ_now == T_FETCH) nfetch = nfetch + 1;
    if (hp == 2'd0 && typ_now == T_LOAD)  nload  = nload + 1;
    if (typ == T_STORE) begin
      if (!sbeat) begin
        case (hp) 2'd0: sa[7:0]<=uo_out; 2'd1: sa[15:8]<=uo_out; 2'd2: sa[23:16]<=uo_out;
                  2'd3: begin sa[31:24]<=uo_out; sbeat<=1'b1; end endcase
      end else begin
        case (hp) 2'd0: sd[7:0]<=uo_out; 2'd1: sd[15:8]<=uo_out; 2'd2: sd[23:16]<=uo_out;
          2'd3: begin
            sbeat <= 1'b0; nst = nst + 1;
            $display("ST %08h %08h", sa, {uo_out, sd[23:0]});
            {mem[sa[15:0]+3], mem[sa[15:0]+2], mem[sa[15:0]+1], mem[sa[15:0]]} = {uo_out, sd[23:0]};
            if (sa == tohost) begin halted = 1; haltval = {uo_out, sd[23:0]}; end
          end endcase
      end
    end
  end

`ifdef TRACE
  // RTL-only debug trace (never used for a verdict): every retiring edge.
  always @(posedge clk) if (rst_n && user_project.core.retire)
    $display("TR cyc=%0d pc=%08h instr=%08h rd=%0d wb=%08h", cyc, user_project.core.u_core.pc_q,
             user_project.core.u_core.instr, user_project.core.u_core.rd, user_project.core.u_core.wb_val);
`endif
  integer i;
  initial begin
    for (i = 0; i < 65536; i = i + 1) mem[i] = 8'hAA;   // non-zero background: a control, not decoration
    if (!$value$plusargs("hex=%s", hexfile)) begin $display("NO +hex"); $finish; end
    $readmemh(hexfile, mem);
    if (!$value$plusargs("tohost=%h", tohost)) tohost = 32'hFFFFFFFF;
    if (!$value$plusargs("cycles=%d", maxcyc)) maxcyc = 200000;
    netaddr = $test$plusargs("addrnet");
    sbeat = 0; halted = 0; sa = 0; sd = 0;
    repeat (4) @(negedge clk); rst_n = 1;
    while (!halted && cyc < maxcyc) @(negedge clk);
    $display("SUMMARY halted=%0d haltval=%08h cycles=%0d stores=%0d fetch_loops=%0d load_loops=%0d phase_mismatch=%0d addr=%s",
             halted, halted ? haltval : 32'h0, cyc, nst, nfetch, nload, phase_bad, netaddr ? "net" : "pins");
    $finish;
  end
endmodule
`default_nettype wire
