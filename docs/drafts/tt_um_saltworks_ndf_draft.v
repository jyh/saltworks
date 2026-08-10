// tt_um_saltworks_ndf — DRAFT (maestro's hand, 01:2x, under the Captain's
// 01:1x blanket: author-anywhere, LAND-AT-OWNER. COMPILER OWNS THE LANDING:
// adopt, correct, move to SaltWorks/Silicon/RTL/, and the real file is yours.
// Nothing cites this draft; it exists to save the critical path an hour.
//
// SPEC SOURCES (all frozen): pin map v1.1 D6 (Captain-confirmed R5) ·
// frame sync D4(h) · the 2-2-1 timetable docs/ndf-council-example-221.md ·
// shell ports ASSUMED per R6 (clear_acc, en_wsh, en_acc after clk) — L2's
// real port names govern at adoption; L1 (clk,i0..i2,o0..o31) noted below.
//
// SCOPE, stated so no run over-claims (silicon's clause rides): a layout of
// this composition measures area/timing/DRC/LVS/antenna. Functional demo
// correctness arrives with L2 (enables/clear) + SER; the fence holds it.
//
// SER SEAM: the serializer organ is compiler's ③, unbuilt at draft time.
// Cell TX lines carry the all-zero IDLE frame until it lands — a REAL
// design state (idle is a fixed point of claim-gated OR), labeled here.
// Replace the three lines marked SER-SEAM when the organ exists.
//
// POWER-GATING LAW: no `initial`, every register reloaded at its own
// strobe; the frame/sequence counters realign at sof (or rst_n).

`default_nettype none

module tt_um_saltworks_ndf (
    input  wire [7:0] ui_in,    // instr_byte -> core (memory bus, R5/D6)
    output wire [7:0] uo_out,   // addr_byte <- core
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  // ---- D6 pin map (frozen; oe verified bit-by-bit twice) ----
  wire       sof          = uio_in[6];
  wire       edge_in_dat  = uio_in[2];
  wire       edge_in_vld  = uio_in[3];
  wire [1:0] phase_o;
  wire       edge_out_dat, edge_out_vld, valid;
  assign uio_oe  = 8'b1011_0011;
  assign uio_out = {valid, 1'b0, edge_out_vld, edge_out_dat,
                    1'b0, 1'b0, phase_o[1], phase_o[0]};
  wire _unused = &{ena, uio_in[7], uio_in[5:4], uio_in[1:0], 1'b0};

  // ---- the core, as-is (Option A / R4: demonstrates on its own bus) ----
  slicea16bma core (
    .clk(clk), .rst_n(rst_n),
    .instr_byte(ui_in), .addr_byte(uo_out), .phase_o(phase_o)
  );

  // ---- the fabric (routing half; batcher_c placed as compute organ
  //      by the flow, no runtime wiring in the minimal demo) ----
  // Port indices FROZEN (D6): 0-3 cells · 4 edge-in · 5 edge-out ·
  // 6 CPU-stub (idle) · 7 spare (idle). Actives = the 0-5 prefix.
  wire [7:0] fab_in, fab_out;
  wire [3:0] cnt_o;
  banyan_fabric #(.PAYLOAD(8)) fab (
    .clk(clk), .rst_n(rst_n), .sof(sof),
    .din(fab_in), .dout(fab_out), .cnt_o(cnt_o), .valid(valid)
  );
  assign fab_in[4] = edge_in_dat;   // edge-in speaks frames directly
  assign fab_in[6] = 1'b0;          // CPU client: stubbed idle (R4)
  assign fab_in[7] = 1'b0;          // spare: idle fixed point
  assign edge_out_dat = fab_out[5];
  assign edge_out_vld = valid;      // payload-window flag (D6)
  wire _unused2 = &{edge_in_vld, fab_out[6], fab_out[7], 1'b0};

  // ---- the 2-2-1 sequencer (hand RTL per D2(b); the council table
  //      made literal: 22 frames x 14 cycles; NO handshakes) ----
  // cyc = cycle-in-frame 0..13 (own counter, sof/rst-aligned per §5);
  // frm = frame index 0..21, saturates at 22 (done) until next sof.
  reg [3:0] cyc;
  reg [4:0] frm;
  wire frame_end = (cyc == 4'd13);
  always @(posedge clk) begin
    if (!rst_n || sof) begin cyc <= 4'd0; frm <= 5'd0; end
    else begin
      cyc <= frame_end ? 4'd0 : cyc + 4'd1;
      if (frame_end && frm != 5'd22) frm <= frm + 5'd1;
    end
  end
  wire payload = (cyc >= 4'd6);              // frame cycles 6..13
  wire sign_cyc = (cyc == 4'd13);            // MSB arrives last (D4h)

  // Per-frame roles, straight from ndf-council-example-221.md:
  //  load frames per cell: c0:{0,3,8} c1:{1,4,9} c2:{2,5,14}
  //  stream frames:        c0:{6,11}  c1:{7,12}  c2:{13,17}
  //  bias x=1 local cycle: c0@F2c11   c1@F3c11   c2@F4c11
  //  ACTIVATE:             c0@F12     c1@F13     c2@F18  (strobe class)
  //  load spans 32 cycles: payload(8) + 24 extension (sign-hold below)
  reg [23:0] ext;   // per-cell extension countdown would be 3x5b; kept
                    // flat here — COMPILER: reshape at adoption if uglier
                    // than your idiom. ext[4:0]xN encoding noted inline.
  // -- simplest correct form: one 5-bit down-counter per cell --
  reg [4:0] ext0, ext1, ext2;
  wire ld_f0 = (frm==5'd0)||(frm==5'd3)||(frm==5'd8);
  wire ld_f1 = (frm==5'd1)||(frm==5'd4)||(frm==5'd9);
  wire ld_f2 = (frm==5'd2)||(frm==5'd5)||(frm==5'd14);
  wire st_f0 = (frm==5'd6)||(frm==5'd11);
  wire st_f1 = (frm==5'd7)||(frm==5'd12);
  wire st_f2 = (frm==5'd13)||(frm==5'd17);
  always @(posedge clk) begin
    if (!rst_n || sof) begin ext0<=5'd0; ext1<=5'd0; ext2<=5'd0; end
    else begin
      if (ld_f0 && frame_end) ext0 <= 5'd24; else if (ext0!=0) ext0 <= ext0-5'd1;
      if (ld_f1 && frame_end) ext1 <= 5'd24; else if (ext1!=0) ext1 <= ext1-5'd1;
      if (ld_f2 && frame_end) ext2 <= 5'd24; else if (ext2!=0) ext2 <= ext2-5'd1;
    end
  end

  // sign-hold: capture the last payload bit of a load frame (the value
  // MSB = the int8 sign) and replay it through the 24 extension cycles
  // (D4h: "the sender sends 8 bits ONCE"). One flop per cell.
  reg sh0, sh1, sh2;
  always @(posedge clk) begin
    if (ld_f0 && sign_cyc) sh0 <= fab_out[0];
    if (ld_f1 && sign_cyc) sh1 <= fab_out[1];
    if (ld_f2 && sign_cyc) sh2 <= fab_out[2];
  end

  // per-cell drive: x from fabric during payload of its frames, from
  // the sign-hold during extension; load high through load window +
  // extension; sign strobe on stream MSB cycles; bias x=1 local cycle.
  wire bias0 = (frm==5'd2)  && (cyc==4'd11);
  wire bias1 = (frm==5'd3)  && (cyc==4'd11);
  wire bias2 = (frm==5'd4)  && (cyc==4'd11);
  wire x0 = bias0 ? 1'b1 : (ld_f0 && payload) ? fab_out[0]
          : (ext0!=0) ? sh0 : (st_f0 && payload) ? fab_out[0] : 1'b0;
  wire x1 = bias1 ? 1'b1 : (ld_f1 && payload) ? fab_out[1]
          : (ext1!=0) ? sh1 : (st_f1 && payload) ? fab_out[1] : 1'b0;
  wire x2 = bias2 ? 1'b1 : (ld_f2 && payload) ? fab_out[2]
          : (ext2!=0) ? sh2 : (st_f2 && payload) ? fab_out[2] : 1'b0;
  wire load0 = (ld_f0 && payload) || (ext0!=0);
  wire load1 = (ld_f1 && payload) || (ext1!=0);
  wire load2 = (ld_f2 && payload) || (ext2!=0);
  wire sgn0  = st_f0 && sign_cyc;   // harmless on h>=0 inputs (D4h)
  wire sgn1  = st_f1 && sign_cyc;
  wire sgn2  = st_f2 && sign_cyc;
  // shell strobes (L2 ports, R6): enables + clear
  wire en_w0 = load0 || (st_f0 && payload) || bias0;
  wire en_w1 = load1 || (st_f1 && payload) || bias1;
  wire en_w2 = load2 || (st_f2 && payload) || bias2;
  wire en_a0 = (st_f0 && payload) || bias0;
  wire en_a1 = (st_f1 && payload) || bias1;
  wire en_a2 = (st_f2 && payload) || bias2;
  wire clr   = (frm==5'd0) && (cyc==4'd0);   // global acc clear, F0c0

  // ---- four cells (k=4 forced; cell 3 idle in the 2-2-1 demo:
  //      clocked, cleared, never enabled — real state, zero schedule) ----
  // L2 interface ASSUMED: (clk, clear_acc, en_wsh, en_acc, i0=x, i1=load,
  // i2=sign, o0..o31). If landing on L1 (no shell ports), compiler drops
  // the four strobe connections and the layout is L1-scoped (labeled).
  wire [31:0] acc0, acc1, acc2, acc3;
  mac_cell_signed_seq cell0 (.clk(clk), /*L2:*/ /*.clear_acc(clr), .en_wsh(en_w0), .en_acc(en_a0),*/
    .i0(x0), .i1(load0), .i2(sgn0)
    /* o0..o31 -> acc0 : expand at adoption; emitSeq ports are scalar */);
  mac_cell_signed_seq cell1 (.clk(clk),
    .i0(x1), .i1(load1), .i2(sgn1));
  mac_cell_signed_seq cell2 (.clk(clk),
    .i0(x2), .i1(load2), .i2(sgn2));
  mac_cell_signed_seq cell3 (.clk(clk),
    .i0(1'b0), .i1(1'b0), .i2(1'b0));
  // COMPILER NOTE: scalar o0..o95 port expansion is mechanical and yours
  // at adoption (o0..o31 = acc read; o32..o95 feed the L1-internal flops
  // already — only acc taps are wired up here). acc0..acc3 feed SER.

  // ---- SER-SEAM (compiler's ③; ABSENT at draft time) ----
  // ser_ndf ser0 (.clk, .load(act0), .word(acc0), .out(fab_in[0]), ...);
  assign fab_in[0] = 1'b0;   // SER-SEAM: idle until the organ lands
  assign fab_in[1] = 1'b0;   // SER-SEAM
  assign fab_in[2] = 1'b0;   // SER-SEAM
  assign fab_in[3] = 1'b0;   // cell 3: idle in the 2-2-1 demo

endmodule

`default_nettype wire
