`timescale 1ns/1ps
// A0 · V10 fixtures for the 2-2-1 — ARTIFACT HALF (silicon).
// Six single-source routes on the EMITTED fabric.
// ⛔ TWO HARNESS DEFECTS FIXED HERE, both mine, both untested assumptions:
//   (1) I sampled a SECOND frame "because the payload arrives a frame later".
//       IT DOES NOT — it arrives in the same frame's payload window, and the
//       second pass OVERWROTE the correct capture with zeros. 6/6 false FAILs.
//   (2) I keyed the schedule on my own loop index; `sof` leaves cnt at 1 on the
//       first driven edge, so the frame was off by one. Now the stimulus is
//       keyed on the fabric's OWN cnt_o — self-aligning, no assumption.
module tb;
  reg clk=0, rst_n=0, sof=0; reg [7:0] din=0; wire [7:0] dout;
  wire [3:0] cnt_o; wire valid;
  banyan_fabric #(.PAYLOAD(8)) fab (.clk(clk),.rst_n(rst_n),.sof(sof),
    .din(din),.dout(dout),.cnt_o(cnt_o),.valid(valid));
  always #5 clk = ~clk;
  integer pass=0, fail=0;

  task run_route(input integer src, input integer dst, input [7:0] payload);
    integer i; reg [7:0] got; reg ok;
    begin
      rst_n=0; din=0; @(posedge clk); rst_n=1; sof=1; @(posedge clk); sof=0;
      got = 0;
      for (i=0; i<14; i=i+1) begin
        din = 0;
        case (cnt_o)                        // ← keyed on the FABRIC's counter
          0,2,4: din[src] = 1'b1;
          1:     din[src] = (dst>>2)&1'b1;
          3:     din[src] = (dst>>1)&1'b1;
          5:     din[src] = (dst>>0)&1'b1;
          default: if (cnt_o>=6) din[src] = payload[cnt_o-6];
        endcase
        @(posedge clk); #1;
        if (cnt_o>=7 || cnt_o==0) begin      // capture the payload window
          if (cnt_o==0) got[7] = dout[dst]; else got[cnt_o-7] = dout[dst];
        end
      end
      ok = (got == payload);
      if (ok) pass=pass+1; else fail=fail+1;
      $display("  src%0d -> dst%0d   want %b   got %b   %s",
               src, dst, payload, got, ok?"PASS":"FAIL");
    end
  endtask


  task check_wrong_line(input integer src, input integer dst, input integer watch,
                        input [7:0] payload);
    integer i; reg [7:0] got;
    begin
      rst_n=0; din=0; @(posedge clk); rst_n=1; sof=1; @(posedge clk); sof=0; got=0;
      for (i=0;i<14;i=i+1) begin
        din=0;
        case (cnt_o) 0,2,4: din[src]=1'b1; 1: din[src]=(dst>>2)&1'b1;
          3: din[src]=(dst>>1)&1'b1; 5: din[src]=(dst>>0)&1'b1;
          default: if (cnt_o>=6) din[src]=payload[cnt_o-6]; endcase
        @(posedge clk); #1;
        if (cnt_o>=7) got[cnt_o-7]=dout[watch]; else if (cnt_o==0) got[7]=dout[watch];
      end
      if (got==payload) pass=pass+1; else fail=fail+1;
      $display("    watch WRONG line %0d: got %b  %s", watch, got,
               (got==payload)?"⛔ PASSED (bad)":"caught ✅");
    end
  endtask
  task check_wrong_dest(input integer src, input integer dst, input integer watch,
                        input [7:0] payload);
    begin check_wrong_line(src, dst, watch, payload); end
  endtask

  initial begin
    $display("A0 · 2-2-1 V10 FIXTURES — ARTIFACT HALF, six single-source routes");
    run_route(4,0,8'b10110001); run_route(4,1,8'b01001110);
    run_route(4,2,8'b11010010); run_route(0,2,8'b00111100);
    run_route(1,2,8'b10101010); run_route(2,5,8'b01010101);
    $display("  ==> PASS %0d / FAIL %0d", pass, fail);
    // NEGATIVE CONTROLS — a check only ever run on passing input has not been
    // shown to discriminate, and this harness produced 6/6 FALSE fails an hour ago.
    $display("  NEGATIVE CONTROLS (each MUST fail):");
    begin : neg
      integer p0, f0;
      p0 = pass; f0 = fail;
      check_wrong_line(4, 0, 3, 8'b10110001);   // right route, WRONG line watched
      check_wrong_dest(4, 0, 1, 8'b10110001);   // addressed dst0, watch dst1
      if (fail == f0 + 2 && pass == p0)
        $display("  ==> CONTROLS OK: both mutants caught. The harness DISCRIMINATES.");
      else
        $display("  ==> ⛔ CONTROLS FAILED — do not trust the 6/6 above.");
    end
    $finish;
  end
endmodule
