// BB-1 — bit-serial COMPARE-EXCHANGE element for the Batcher stage.
// Two frames stream in MSB-first on the destination field; the element decides
// which is larger during the address window and holds that decision for the
// payload. Same frame shape as bitserial_switch (act/addr interleaved, then
// payload). NOT a submission artifact — measured to price BB-1's area.
module cmpex(clk, rst_n, addr_win, in0, in1, act0, act1, out0, out1);
    input  clk, rst_n, addr_win;    // addr_win high during the 3 address bits
    input  in0, in1;                // the two serial lines
    input  act0, act1;              // activity bits
    output out0, out1;

    reg decided, swap;

    // during the address window: first differing bit decides order
    wire diff   = in0 ^ in1;
    wire take   = addr_win & ~decided & diff;
    wire newsw  = in1 & ~in0;       // in1 < in0  => swap so smaller goes low

    always @(posedge clk)
        if (!rst_n) begin decided <= 1'b0; swap <= 1'b0; end
        else if (take) begin decided <= 1'b1; swap <= newsw; end
        else if (!addr_win) begin decided <= 1'b0; end

    // inactive lines sort LAST: an idle line must never win the low port
    wire s = swap | (~act0 & act1);
    assign out0 = s ? in1 : in0;
    assign out1 = s ? in0 : in1;
endmodule
