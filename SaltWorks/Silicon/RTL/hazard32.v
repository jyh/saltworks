// PIPELINE HAZARD UNIT — forwarding network + load-use stall + flush.
// ⛔ C3 is SINGLE-CYCLE and has none of this. Measured to PRICE pipelining.
// NOT a submission artifact.
module hazard32(rs1_ex, rs2_ex, rd_mem, rd_wb, regwe_mem, regwe_wb, memread_mem,
                rd_ex, branch_taken,
                rf_val1, rf_val2, mem_result, wb_result,
                op1, op2, stall, flush, fwd1, fwd2);
    input  [4:0]  rs1_ex, rs2_ex, rd_mem, rd_wb, rd_ex;
    input         regwe_mem, regwe_wb, memread_mem, branch_taken;
    input  [31:0] rf_val1, rf_val2, mem_result, wb_result;
    output [31:0] op1, op2;
    output        stall, flush;
    output [1:0]  fwd1, fwd2;

    // ---- forwarding control: FIVE-BIT equalities -------------------------
    (* keep *) wire m1, m2, w1, w2;
    assign m1 = regwe_mem & (rd_mem != 5'd0) & (rd_mem == rs1_ex);
    assign m2 = regwe_mem & (rd_mem != 5'd0) & (rd_mem == rs2_ex);
    assign w1 = regwe_wb  & (rd_wb  != 5'd0) & (rd_wb  == rs1_ex);
    assign w2 = regwe_wb  & (rd_wb  != 5'd0) & (rd_wb  == rs2_ex);

    assign fwd1 = m1 ? 2'd1 : w1 ? 2'd2 : 2'd0;
    assign fwd2 = m2 ? 2'd1 : w2 ? 2'd2 : 2'd0;

    // ---- the forwarding muxes: THREE sources per bit ---------------------
    assign op1 = m1 ? mem_result : w1 ? wb_result : rf_val1;
    assign op2 = m2 ? mem_result : w2 ? wb_result : rf_val2;

    // ---- load-use stall and control-hazard flush -------------------------
    assign stall = memread_mem & (rd_mem != 5'd0) &
                   ((rd_mem == rs1_ex) | (rd_mem == rs2_ex));
    assign flush = branch_taken;
endmodule
