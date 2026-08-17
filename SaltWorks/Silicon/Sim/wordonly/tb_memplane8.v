`timescale 1ns/1ps
// tb_memplane8.v — ③'s PLANE, END TO END. Does a word actually make the round trip?
//
//   iverilog -g2005 -o /tmp/tb tb_memplane8.v ../../RTL/memplane8.v \
//       ../../RTL/core32.v ../../RTL/dmem_addr8.v ../../RTL/dmem8.v && /tmp/tb
//
// The plane elaborating proves only that the ports line up. This runs a four
// instruction program out of a testbench-hosted instruction memory and asks
// whether the store reached `dmem8`'s array and the load came back through
// `dmem_addr8`'s word_index into the regfile.
//
//   ADDI x1, x0, 4      base address = byte 4  -> word_index 1
//   ADDI x2, x0, 42     datum
//   SW   x2, 0(x1)      store
//   LW   x3, 0(x1)      load it back
//
// ⭐ THE ARMS THAT MATTER ARE THE SEAM ONES, not the round trip: `dmem_req` and
// `dmem_we` must carry the KERNEL's isLW/isSW, because that is what `DriveMap`
// assumes and what makes F4 door 1 true of this plane rather than of a hypothesis.
module tb;
  reg clk = 0, rst_n = 0;
  reg  [31:0] imem [0:7];
  wire [31:0] imem_addr, dmem_addr;
  wire        dmem_trap, dmem_mis, dmem_oor;
  reg  [31:0] instr;

  memplane8 dut(.clk(clk), .rst_n(rst_n), .instr(instr), .imem_addr(imem_addr),
                .dmem_addr(dmem_addr), .dmem_trap(dmem_trap),
                .dmem_misaligned(dmem_mis), .dmem_out_of_range(dmem_oor));

  always #5 clk = ~clk;
  always @(*) instr = imem[imem_addr[4:2]];

  integer fails = 0;
  task chk; input [511:0] nm; input cond;
    begin if (cond !== 1'b1) begin $display("  FAIL  %0s", nm); fails = fails+1; end
          else $display("  pass  %0s", nm); end
  endtask

  initial begin
    // ADDI x1, x0, 4
    imem[0] = {12'd4,  5'd0, 3'b000, 5'd1, 7'b0010011};
    // ADDI x2, x0, 42
    imem[1] = {12'd42, 5'd0, 3'b000, 5'd2, 7'b0010011};
    // SW x2, 0(x1)     imm[11:5]=0, rs2=2, rs1=1, f3=010, imm[4:0]=0
    imem[2] = {7'd0, 5'd2, 5'd1, 3'b010, 5'd0, 7'b0100011};
    // LW x3, 0(x1)
    imem[3] = {12'd0, 5'd1, 3'b010, 5'd3, 7'b0000011};
    imem[4] = 32'h00000013; imem[5] = 32'h00000013;
    imem[6] = 32'h00000013; imem[7] = 32'h00000013;

    rst_n = 0; @(posedge clk); #1; rst_n = 1;

    @(negedge clk); // ADDI x1
    @(negedge clk); // ADDI x2
    chk("x1 = 4 after ADDI",  dut.u_core.regs[1] === 32'd4);

    @(negedge clk); // SW  -- strobes must be the KERNEL's, and the write must land
    chk("SW  dmem_req = 1",              dut.c_dmem_req === 1'b1);
    chk("SW  dmem_we  = 1",              dut.c_dmem_we  === 1'b1);
    chk("SW  we_out   = 1 (unsuppressed)", dut.a_we_out === 1'b1);
    chk("SW  word_index = 1 (byte 4)",   dut.a_word_index === 3'd1);
    chk("SW  no trap",                   dmem_trap === 1'b0);

    @(negedge clk); // LW
    chk("stored word reached dmem8[1]",  dut.u_mem.mem[1] === 32'd42);
    chk("LW  dmem_req = 1",              dut.c_dmem_req === 1'b1);
    chk("LW  dmem_we  = 0 (a load is not a store)", dut.c_dmem_we === 1'b0);
    chk("LW  we_out   = 0",              dut.a_we_out === 1'b0);
    chk("LW  rdata is the stored word",  dut.m_rdata === 32'd42);

    @(negedge clk);
    chk("x3 = 42, the round trip closed", dut.u_core.regs[3] === 32'd42);

    if (fails == 0) $display("ALL PASS");
    else            $display("FAILURES PRESENT: %0d", fails);
    $finish;
  end
endmodule
