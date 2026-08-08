// The 8x8 bit-serial banyan fabric — D4, the tapeout target.
//
// Twelve `bitserial_switch` elements in three stages, plus a frame counter that
// generates the per-stage strobes. Everything about the frame is specified in
// docs/silicon-frame-protocol-0806.md; this is that document in Verilog.
//
// FRAME (protocol v1, option C):
//     cycle 0  ACT   cycle 1  a2      <- stage 0 consumes the MSB
//     cycle 2  ACT   cycle 3  a1      <- stage 1
//     cycle 4  ACT   cycle 5  a0      <- stage 2
//     cycle 6+ payload, streamed transparently
//
// The activity bit is REPEATED once per stage because an interior stage can only
// latch a ROUTED activity bit, and upstream has not decided at cycle 0. That is
// the whole reason the header is 2k rather than k+1 cycles.
//
// TOPOLOGY: at stage s, lines i and i XOR 2^(k-1-s) pair up; output 0 of the
// element goes to the lower line, output 1 to the upper. So stage 0 resolves
// destination bit 2, stage 1 bit 1, stage 2 bit 0 — the descending index of
// `SaltWorks.Banyan.line`, which is why the first stage reads the MSB.
//
// The data path is COMBINATIONAL end to end: a bit presented at cycle t leaves
// at cycle t, through three levels of two-way muxing. Outputs are meaningless
// before cycle 2k = 6; the receiver ignores the header window.

module banyan_fabric #(
    parameter PAYLOAD = 8
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sof,        // start of frame: re-aligns the counter to 0
    input  wire [7:0] din,        // 8 serial inputs
    output wire [7:0] dout,       // 8 serial outputs
    output wire [2:0] cnt_o,      // frame counter, exposed for bring-up
    output wire       valid       // high during the payload window
);
    localparam K     = 3;
    localparam HDR   = 2 * K;               // 6
    localparam FRAME = HDR + PAYLOAD;       // 14

    // ---- frame counter -----------------------------------------------------
    // WIDTH IS DERIVED, NOT LITERAL (silicon, 8/8 13:4x). It was `reg [3:0]`,
    // which holds 0..15, so the wrap test `cnt == FRAME-1` could never match
    // once FRAME-1 > 15: at PAYLOAD >= 11 the counter rolled over at 16 instead
    // of at FRAME and the period silently stopped tracking the header. Measured
    // before the fix — P=8/9/10 gave periods 14/15/16 (correct) and P=11/12/16
    // ALL gave 16. The module advertised a parameter it honoured only to P=10.
    // At the tapeout's PAYLOAD=8, $clog2(14)=4, so this is bit-identical to the
    // literal it replaces: zero netlist change where it ships, correct elsewhere.
    localparam CW = $clog2(FRAME);
    reg [CW-1:0] cnt;
    always @(posedge clk) begin
        if (!rst_n)      cnt <= {CW{1'b0}};
        else if (sof)    cnt <= {CW{1'b0}};
        else if (cnt == FRAME - 1) cnt <= {CW{1'b0}};
        else             cnt <= cnt + 1'b1;
    end
    assign cnt_o = cnt[2:0];
    assign valid = (cnt >= HDR);

    // ---- per-stage strobes -------------------------------------------------
    wire [K-1:0] act_stb, sel_stb;
    genvar s;
    generate
        for (s = 0; s < K; s = s + 1) begin : strobes
            assign act_stb[s] = (cnt == 2 * s);
            assign sel_stb[s] = (cnt == 2 * s + 1);
        end
    endgenerate

    // ---- three stages ------------------------------------------------------
    (* keep *) wire [7:0] w0, w1;   // stage boundaries: KEPT so the flow cannot
                                 // dissolve the abstraction we reason about
    wire [7:0] w2;

    // stage 0: pairs differ in bit 2 -> (0,4) (1,5) (2,6) (3,7)
    bitserial_switch e00 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[0]), .sel_stb(sel_stb[0]),
                          .in0(din[0]), .in1(din[4]), .out0(w0[0]), .out1(w0[4]));
    bitserial_switch e01 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[0]), .sel_stb(sel_stb[0]),
                          .in0(din[1]), .in1(din[5]), .out0(w0[1]), .out1(w0[5]));
    bitserial_switch e02 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[0]), .sel_stb(sel_stb[0]),
                          .in0(din[2]), .in1(din[6]), .out0(w0[2]), .out1(w0[6]));
    bitserial_switch e03 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[0]), .sel_stb(sel_stb[0]),
                          .in0(din[3]), .in1(din[7]), .out0(w0[3]), .out1(w0[7]));

    // stage 1: pairs differ in bit 1 -> (0,2) (1,3) (4,6) (5,7)
    bitserial_switch e10 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[1]), .sel_stb(sel_stb[1]),
                          .in0(w0[0]), .in1(w0[2]), .out0(w1[0]), .out1(w1[2]));
    bitserial_switch e11 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[1]), .sel_stb(sel_stb[1]),
                          .in0(w0[1]), .in1(w0[3]), .out0(w1[1]), .out1(w1[3]));
    bitserial_switch e12 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[1]), .sel_stb(sel_stb[1]),
                          .in0(w0[4]), .in1(w0[6]), .out0(w1[4]), .out1(w1[6]));
    bitserial_switch e13 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[1]), .sel_stb(sel_stb[1]),
                          .in0(w0[5]), .in1(w0[7]), .out0(w1[5]), .out1(w1[7]));

    // stage 2: pairs differ in bit 0 -> (0,1) (2,3) (4,5) (6,7)
    bitserial_switch e20 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[2]), .sel_stb(sel_stb[2]),
                          .in0(w1[0]), .in1(w1[1]), .out0(w2[0]), .out1(w2[1]));
    bitserial_switch e21 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[2]), .sel_stb(sel_stb[2]),
                          .in0(w1[2]), .in1(w1[3]), .out0(w2[2]), .out1(w2[3]));
    bitserial_switch e22 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[2]), .sel_stb(sel_stb[2]),
                          .in0(w1[4]), .in1(w1[5]), .out0(w2[4]), .out1(w2[5]));
    bitserial_switch e23 (.clk(clk), .rst_n(rst_n), .act_stb(act_stb[2]), .sel_stb(sel_stb[2]),
                          .in0(w1[6]), .in1(w1[7]), .out0(w2[6]), .out1(w2[7]));

    assign dout = w2;

endmodule
