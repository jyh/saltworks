// MUTANT element — the routing bug the compiler seat found on 8/6 10:52,
// restored deliberately. Same ports, same latches; only the output logic is
// the pre-fix form that cannot tell an idle port from a 0 destination bit.
// Used ONLY as control 2: if the checker cannot fail this, it cannot see
// routing errors at all and arm A's pass means nothing.

module bitserial_switch (
    input  wire clk,
    input  wire rst_n,
    input  wire act_stb,
    input  wire sel_stb,
    input  wire in0,
    input  wire in1,
    output wire out0,
    output wire out1
);

    reg act0, act1, sel0, sel1;

    always @(posedge clk) begin
        if (!rst_n) begin
            act0 <= 1'b0; act1 <= 1'b0; sel0 <= 1'b0; sel1 <= 1'b0;
        end else begin
            if (act_stb) begin act0 <= in0; act1 <= in1; end
            if (sel_stb) begin sel0 <= in0; sel1 <= in1; end
        end
    end

    // THE BUG: activity is never consulted, so an idle port whose stale sel is
    // 0 still claims out0, and an active packet on in1 bound for out0 is
    // silently dropped.
    assign out0 = (sel0 == 1'b0) ? in0 : in1;
    assign out1 = (sel1 == 1'b1) ? in1 : in0;

endmodule
