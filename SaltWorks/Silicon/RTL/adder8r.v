// C3 PROBE ARM B — RTL CONTROL: identical function and ports to adder8s,
// written behaviourally. The ONLY difference between the arms is INPUT FORM.
module adder8r(a, b, cin, sum, cout);
    input  [7:0] a;
    input  [7:0] b;
    input        cin;
    output [7:0] sum;
    output       cout;
    wire [8:0] carry;
    assign carry[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : slice
            assign sum[i]     = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | ((a[i] ^ b[i]) & carry[i]);
        end
    endgenerate
    assign cout = carry[8];
endmodule
