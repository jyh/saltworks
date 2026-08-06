// The bit-serial 2x2 banyan switch element (the ACTUAL tapeout target).
// Packets are bit streams, address first, MSB first. At the stage that
// consumes address bit m, the routing latch is set from that bit and then
// holds for the rest of the frame; data streams through transparently.
module bitserial_switch (
    input  wire clk,
    input  wire rst_n,
    input  wire frame,      // high during the address bit of this stage
    input  wire in0,
    input  wire in1,
    output wire out0,
    output wire out1
);
    reg sel0, sel1;
    always @(posedge clk) begin
        if (!rst_n) begin
            sel0 <= 1'b0;
            sel1 <= 1'b0;
        end else if (frame) begin
            sel0 <= in0;    // input 0's destination bit
            sel1 <= in1;    // input 1's destination bit
        end
    end
    // straight when sel says so, crossed otherwise
    assign out0 = (sel0 == 1'b0) ? in0 : in1;
    assign out1 = (sel1 == 1'b1) ? in1 : in0;
endmodule
