// RV32I MEMORY INTERFACE — load extract/extend, store alignment, byte enables.
// Boundaries named so the census can separate the three sub-blocks.
// NOT a submission artifact.
module memif(addr, funct3, mem_we, rs2, rdata_raw, load_out, wdata_mem, be);
    input  [1:0]  addr;        // byte offset within the word
    input  [2:0]  funct3;      // 000 B, 001 H, 010 W, 100 BU, 101 HU
    input         mem_we;
    input  [31:0] rs2;         // store data, register-aligned
    input  [31:0] rdata_raw;   // the raw 32-bit word from memory
    output [31:0] load_out;    // extracted + extended
    output [31:0] wdata_mem;   // aligned store data
    output [3:0]  be;          // byte enables

    // ---- LOAD: select a lane out of the word, then extend ----------------
    (* keep *) wire [7:0]  lane_b;
    (* keep *) wire [15:0] lane_h;

    assign lane_b = (addr == 2'd0) ? rdata_raw[7:0]   :
                    (addr == 2'd1) ? rdata_raw[15:8]  :
                    (addr == 2'd2) ? rdata_raw[23:16] : rdata_raw[31:24];
    assign lane_h = addr[1] ? rdata_raw[31:16] : rdata_raw[15:0];

    assign load_out = (funct3 == 3'b000) ? {{24{lane_b[7]}},  lane_b} :
                      (funct3 == 3'b100) ? {24'b0,            lane_b} :
                      (funct3 == 3'b001) ? {{16{lane_h[15]}}, lane_h} :
                      (funct3 == 3'b101) ? {16'b0,            lane_h} :
                                           rdata_raw;

    // ---- STORE: replicate the datum into the addressed lane --------------
    assign wdata_mem = (funct3 == 3'b000) ? {4{rs2[7:0]}} :
                       (funct3 == 3'b001) ? {2{rs2[15:0]}} : rs2;

    // ---- BYTE ENABLES: a pure decode ------------------------------------
    assign be = ~mem_we ? 4'b0000 :
                (funct3 == 3'b000) ? (4'b0001 << addr) :
                (funct3 == 3'b001) ? (addr[1] ? 4'b1100 : 4'b0011) : 4'b1111;
endmodule
