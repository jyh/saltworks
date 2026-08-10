// tt_um_saltworks_ndf — DRAFT v2 (maestro's hand, 01:3x; v1 reconciled to
// the REAL landed interfaces under the Captain's blanket). COMPILER OWNS
// THE LANDING: adopt, correct, move to SaltWorks/Silicon/RTL/. Nothing
// cites this draft.
//
// v2 CHANGES vs v1: cell module is the REAL `mac_cell_signed_shell`
// (ports clk,i0,i1,i2,clr,en_acc,en_wsh,o0..o31 — read from the artifact);
// SER-SEAM replaced by REAL `ser_organ` instances (clk,load,d0..d31,o0 —
// per compiler's 01:29 landing note); emit-frame HEADER GENERATION added
// (the port-organ function inlined for the fixed schedule); scalar port
// expansion written out via generate-free explicit wiring notes.
//
// ONE DECISION TAKEN UNDER THE BLANKET, compiler may override at adoption:
// y (cell2's output) emits as ONE int8 frame at F18 (F19-F21 idle) under
// the same compile-time range guarantee that covers h0/h1 — because
// ser_organ shifts EVERY load-low cycle (no shift-enable port), a 4-frame
// 32-bit emission would lose 24 bits into header windows. The full-width
// edge emission needs a shift-enable or per-frame reloads: v1.1, priced
// at the owner's choice. Council doc updated separately.
//
// SCOPE unchanged: a layout of this measures area/timing/DRC/LVS/antenna;
// bench-functional correctness is V10's fixtures + the bench. No initial
// anywhere; counters realign at sof/rst_n (power-gating law).

`default_nettype none

module tt_um_saltworks_ndf (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  // ---- D6 pin map (frozen, R5) ----
  wire       sof          = uio_in[6];
  wire       edge_in_dat  = uio_in[2];
  wire [1:0] phase_o;
  wire       edge_out_dat, valid;
  assign uio_oe  = 8'b1011_0011;
  assign uio_out = {valid, 1'b0, valid, edge_out_dat,
                    1'b0, 1'b0, phase_o[1], phase_o[0]};
  wire _unused = &{ena, uio_in[7], uio_in[5:3], uio_in[1:0], 1'b0};

  // ---- the core (R4: demonstrates on its own bus) ----
  slicea16bma core (
    .clk(clk), .rst_n(rst_n),
    .instr_byte(ui_in), .addr_byte(uo_out), .phase_o(phase_o)
  );

  // ---- the fabric; port indices frozen (D6) ----
  wire [7:0] fab_in, fab_out;
  wire [3:0] cnt_o;
  banyan_fabric #(.PAYLOAD(8)) fab (
    .clk(clk), .rst_n(rst_n), .sof(sof),
    .din(fab_in), .dout(fab_out), .cnt_o(cnt_o), .valid(valid)
  );
  assign fab_in[4] = edge_in_dat;
  assign fab_in[6] = 1'b0;              // CPU client: stubbed (R4)
  assign fab_in[7] = 1'b0;              // spare: idle fixed point
  assign edge_out_dat = fab_out[5];
  wire _unused2 = &{fab_out[3], fab_out[4], fab_out[6], fab_out[7], 1'b0};

  // ---- sequencer: cycle-in-frame + frame index (council table) ----
  reg [3:0] cyc;  reg [4:0] frm;
  wire frame_end = (cyc == 4'd13);
  always @(posedge clk) begin
    if (!rst_n || sof) begin cyc <= 4'd0; frm <= 5'd0; end
    else begin
      cyc <= frame_end ? 4'd0 : cyc + 4'd1;
      if (frame_end && frm != 5'd22) frm <= frm + 5'd1;
    end
  end
  wire payload  = (cyc >= 4'd6);
  wire sign_cyc = (cyc == 4'd13);

  // frame roles (docs/ndf-council-example-221.md)
  wire ld_f0 = (frm==5'd0)||(frm==5'd3)||(frm==5'd8);
  wire ld_f1 = (frm==5'd1)||(frm==5'd4)||(frm==5'd9);
  wire ld_f2 = (frm==5'd2)||(frm==5'd5)||(frm==5'd14);
  wire st_f0 = (frm==5'd6)||(frm==5'd11);
  wire st_f1 = (frm==5'd7)||(frm==5'd12);
  wire st_f2 = (frm==5'd13)||(frm==5'd17);

  // 24-cycle sign-extension countdowns (canonical 32-cycle load, D4f)
  reg [4:0] ext0, ext1, ext2;
  always @(posedge clk) begin
    if (!rst_n || sof) begin ext0<=5'd0; ext1<=5'd0; ext2<=5'd0; end
    else begin
      if (ld_f0 && frame_end) ext0 <= 5'd24; else if (ext0!=0) ext0 <= ext0-5'd1;
      if (ld_f1 && frame_end) ext1 <= 5'd24; else if (ext1!=0) ext1 <= ext1-5'd1;
      if (ld_f2 && frame_end) ext2 <= 5'd24; else if (ext2!=0) ext2 <= ext2-5'd1;
    end
  end
  reg sh0, sh1, sh2;   // sign-hold (D4h: sender sends 8 bits once)
  always @(posedge clk) begin
    if (ld_f0 && sign_cyc) sh0 <= fab_out[0];
    if (ld_f1 && sign_cyc) sh1 <= fab_out[1];
    if (ld_f2 && sign_cyc) sh2 <= fab_out[2];
  end

  // bias local cycles (x=1, one cycle, zero packets)
  wire bias0 = (frm==5'd2) && (cyc==4'd11);
  wire bias1 = (frm==5'd3) && (cyc==4'd11);
  wire bias2 = (frm==5'd4) && (cyc==4'd11);

  // per-cell drive
  wire x0 = bias0 ? 1'b1 : (ld_f0 && payload) ? fab_out[0]
          : (ext0!=0) ? sh0 : (st_f0 && payload) ? fab_out[0] : 1'b0;
  wire x1 = bias1 ? 1'b1 : (ld_f1 && payload) ? fab_out[1]
          : (ext1!=0) ? sh1 : (st_f1 && payload) ? fab_out[1] : 1'b0;
  wire x2 = bias2 ? 1'b1 : (ld_f2 && payload) ? fab_out[2]
          : (ext2!=0) ? sh2 : (st_f2 && payload) ? fab_out[2] : 1'b0;
  wire load0 = (ld_f0 && payload) || (ext0!=0);
  wire load1 = (ld_f1 && payload) || (ext1!=0);
  wire load2 = (ld_f2 && payload) || (ext2!=0);
  wire sgn0  = st_f0 && sign_cyc;
  wire sgn1  = st_f1 && sign_cyc;
  wire sgn2  = st_f2 && sign_cyc;
  wire en_w0 = load0 || (st_f0 && payload) || bias0;
  wire en_w1 = load1 || (st_f1 && payload) || bias1;
  wire en_w2 = load2 || (st_f2 && payload) || bias2;
  wire en_a0 = (st_f0 && payload) || bias0;
  wire en_a1 = (st_f1 && payload) || bias1;
  wire en_a2 = (st_f2 && payload) || bias2;
  wire clr   = (frm==5'd0) && (cyc==4'd0);

  // ---- four ratified cells (REAL module + ports; k=4 forced) ----
  // COMPILER: the 32 acc taps per cell are o0..o31 — expand the
  // .o0(accN[0]) .. .o31(accN[31]) lists at adoption (mechanical;
  // elided here only to keep the draft reviewable).
  wire [31:0] acc0, acc1, acc2;
  mac_cell_signed_shell cell0 (.clk(clk), .clr(clr), .en_acc(en_a0),
    .en_wsh(en_w0), .i0(x0), .i1(load0), .i2(sgn0) /* , .o0(acc0[0]) … .o31(acc0[31]) */);
  mac_cell_signed_shell cell1 (.clk(clk), .clr(clr), .en_acc(en_a1),
    .en_wsh(en_w1), .i0(x1), .i1(load1), .i2(sgn1) /* , o->acc1 */);
  mac_cell_signed_shell cell2 (.clk(clk), .clr(clr), .en_acc(en_a2),
    .en_wsh(en_w2), .i0(x2), .i1(load2), .i2(sgn2) /* , o->acc2 */);
  mac_cell_signed_shell cell3 (.clk(clk), .clr(clr), .en_acc(1'b0),
    .en_wsh(1'b0), .i0(1'b0), .i1(1'b0), .i2(1'b0) /* idle, cleared */);

  // ---- activation: CE-vs-0 at the signed order = ReLU ----
  // h = (acc[31]==1'b0) ? acc : 0  — int8 range guaranteed per-network
  // (the compile-time obligation, R-block). Wired as the SER's D input.
  wire [31:0] h0 = acc0[31] ? 32'd0 : acc0;
  wire [31:0] h1 = acc1[31] ? 32'd0 : acc1;
  wire [31:0] h2 = acc2[31] ? 32'd0 : acc2;
  // COMPILER NOTE: the certified CE organ is the kernel form of this
  // compare; if you want the emitted ce organ placed instead of the
  // behavioural mux above, swap at adoption — area is small either way,
  // and the kernel-vs-hand boundary for the ACTIVATION belongs to you.

  // ---- SER organs + emit-frame headers (port-organ inlined) ----
  // ser_organ: clk · load · d0..d31 · o0 (LSB-first, shifts when !load)
  wire ser_ld0 = (frm==5'd12) && frame_end;   // latch h0 at F12 end
  wire ser_ld1 = (frm==5'd13) && frame_end;   // wait — h1 ACT is F13; latch F13 end? council: c1 ACT@F13 -> emit F17. Latch at F16 end keeps it fresh; either is correct (acc holds). ADOPTION CALL.
  wire ser_ld2 = (frm==5'd17) && frame_end;   // latch y at F17 end
  wire ser_o0, ser_o1, ser_o2;
  ser_organ ser0 (.clk(clk), .load(ser_ld0) /* , .d0(h0[0]) … .d31(h0[31]) */, .o0(ser_o0));
  ser_organ ser1 (.clk(clk), .load(ser_ld1) /* , d<-h1 */, .o0(ser_o1));
  ser_organ ser2 (.clk(clk), .load(ser_ld2) /* , d<-h2 */, .o0(ser_o2));

  // header generation for emit frames: [ACT,a2,ACT,a1,ACT,a0] then payload.
  // dests: h0,h1 -> port 2 (010) · y -> port 5 (101). MSB-first (D4h).
  function hdr_bit; input [2:0] dest; input [3:0] c;
    hdr_bit = (c==4'd0||c==4'd2||c==4'd4) ? 1'b1
            : (c==4'd1) ? dest[2] : (c==4'd3) ? dest[1] : dest[0];
  endfunction
  wire em_f0 = (frm==5'd13);                  // cell0 transmits h0
  wire em_f1 = (frm==5'd17);                  // cell1 transmits h1
  wire em_f2 = (frm==5'd18);                  // cell2 transmits y (int8, one frame — see header note)
  assign fab_in[0] = em_f0 ? (payload ? ser_o0 : hdr_bit(3'd2, cyc)) : 1'b0;
  assign fab_in[1] = em_f1 ? (payload ? ser_o1 : hdr_bit(3'd2, cyc)) : 1'b0;
  assign fab_in[2] = em_f2 ? (payload ? ser_o2 : hdr_bit(3'd5, cyc)) : 1'b0;
  assign fab_in[3] = 1'b0;                    // cell 3 idle
  wire _unused3 = &{h0[31:8], h1[31:8], h2[31:8], acc2[0], 1'b0};

endmodule

`default_nettype wire
