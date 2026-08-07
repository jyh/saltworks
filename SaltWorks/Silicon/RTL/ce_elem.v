// BB-1 / B1 — the compare-exchange element in RTL, transcribed from compiler's
// `ceCore` (CompareExchange.lean, d762dbc) EQUATION BY EQUATION so the gate
// netlist can be refined against their word-level spec.
// Net numbering in their file: 0=rst 1=act0 2=act1 3=in0 4=in1 5=decided 6=swap.
module ce_elem(clk, rst, act0, act1, in0, in1, out0, out1, oact0, oact1);
    input  clk, rst, act0, act1, in0, in1;
    output out0, out1, oact0, oact1;

    reg decided, swap;

    wire d        = decided & ~rst;        // g8
    wire actDiff  = act0 ^ act1;           // g10
    wire idleSw   = act1 & ~act0;          // g12
    wire bothAct  = act0 & act1;           // g13
    wire addrSw   = in0 & ~in1;            // g15
    wire newSw    = idleSw | (bothAct & addrSw);          // g17
    wire sw       = (d & swap) | (~d & newSw);            // g20
    wire addrDiff = in0 ^ in1;             // g34
    wire dec_n    = d | (actDiff | (bothAct & addrDiff)); // g37

    assign out0  = sw ? in1  : in0;        // g24
    assign out1  = sw ? in0  : in1;        // g27
    assign oact0 = sw ? act1 : act0;       // g30
    assign oact1 = sw ? act0 : act1;       // g33

    always @(posedge clk) begin
        decided <= dec_n;
        swap    <= sw;
    end
endmodule
