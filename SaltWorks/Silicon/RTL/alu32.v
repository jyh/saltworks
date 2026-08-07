// RV32I ALU — the ten base ops, with each op's RESULT named and (* keep *)-marked
// so the census can ask what cutting there buys. NOT a submission artifact.
module alu32(a, b, op, y, zero);
    input  [31:0] a;
    input  [31:0] b;
    input  [3:0]  op;
    output [31:0] y;
    output        zero;

    (* keep *) wire [31:0] r_add, r_sub, r_sll, r_srl, r_sra, r_xor, r_or, r_and;
    (* keep *) wire [31:0] r_slt, r_sltu;

    wire [32:0] sub_ext = {1'b0, a} - {1'b0, b};

    assign r_add  = a + b;
    assign r_sub  = a - b;
    assign r_sll  = a << b[4:0];
    assign r_srl  = a >> b[4:0];
    assign r_sra  = $signed(a) >>> b[4:0];
    assign r_xor  = a ^ b;
    assign r_or   = a | b;
    assign r_and  = a & b;
    assign r_slt  = {31'b0, ($signed(a) < $signed(b))};
    assign r_sltu = {31'b0, (a < b)};

    assign y = (op == 4'h0) ? r_add  :
               (op == 4'h8) ? r_sub  :
               (op == 4'h1) ? r_sll  :
               (op == 4'h2) ? r_slt  :
               (op == 4'h3) ? r_sltu :
               (op == 4'h4) ? r_xor  :
               (op == 4'h5) ? r_srl  :
               (op == 4'hd) ? r_sra  :
               (op == 4'h6) ? r_or   : r_and;

    assign zero = (y == 32'b0);
endmodule
