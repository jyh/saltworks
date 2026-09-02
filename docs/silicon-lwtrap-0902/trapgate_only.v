// trapgate_only.v — the gate's OWN logic, priced standalone: an upper bound on what the gate
// adds to core32, independent of abc's whole-netlist restructuring (which moves hundreds of
// cells on a 4,400-cell design and swamps a ~40-cell delta in either direction).
module trapgate_only(input [31:0] alu_y, input is_load_w, input we_rest, output reg_we);
    wire ld_trap = is_load_w & ((alu_y >= 32'd32) | (alu_y[1:0] != 2'b00));
    assign reg_we = we_rest | (is_load_w & ~ld_trap);
endmodule
