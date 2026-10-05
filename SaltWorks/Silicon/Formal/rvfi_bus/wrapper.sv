// wrapper.sv — riscv-formal RVFI for the FABRICATED core32 AT THE BUS LEVEL (desk AAJ, 2026-10-05).
//
// DUT: plane32bus = core32 + busadapt8 at tt-neural-dataflow-fabric 01e19f7, with read-only TAPS added
// by tap.py (proved equivalent to the fabricated plane on every original output by run_aaj.sh).
//
// WHAT COMES FROM WHERE — the point of a BUS-level check is that the memory side of every retirement
// is read at the PINS, the way a host sees it, never from the adapter's internal registers:
//   PINS   rvfi_insn · rvfi_pc_rdata          the word and address of the last FETCH loop
//          rvfi_mem_addr · rvfi_mem_rdata      the LOAD loop's address bytes out / data bytes in
//          rvfi_mem_addr · rvfi_mem_wdata      the STORE address loop's bytes / data loop's bytes out
//   TAPS   rvfi_rs1/rs2_addr+rdata · rvfi_rd_addr+wdata · rvfi_pc_wdata   (the register file and the
//          next pc are not on any pin; the taps read existing nets of core32)
//   DUT    rvfi_valid = retire (the core's commit enable, a plane output)
// The host is UNCONSTRAINED: ui_in is an arbitrary byte every cycle. `sof` is held low (scope).
//
// TRAPS: core32 has none. RV32I requires an exception for a misaligned jump/branch target, and with
// RISCV_FORMAL_ALIGNED_MEM for a misaligned LW/SW. rvfi_trap is driven 1 exactly when the CORE's own
// next pc or the PINS' memory address is misaligned, so riscv-formal checks only `spec_trap == trap`
// on those retirements: a core that misaligns where the spec does not (or vice versa) still FAILS;
// what is NOT checked is the register/memory effect of a retirement that RV32I says must trap.

module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);
	(* keep *) `rvformal_rand_reg [7:0] ui_in;     // the host: any byte, any cycle

	(* keep *) wire [7:0]  uo;
	(* keep *) wire [1:0]  ph;
	(* keep *) wire        retire;
	(* keep *) wire [31:0] t_instr, t_rf1, t_rf2, t_pc_next, t_wb_val;
	(* keep *) wire        t_reg_we;
	(* keep *) wire [31:0] t_rdata_r, t_instr_r;     // adapter taps: used ONLY by the LW-shape
	(* keep *) wire [1:0]  t_phase, t_kind;          // induction invariants below, never by RVFI
	(* keep *) wire        t_store_beat;

	plane32bus dut (
		.clk(clock), .rst_n(!reset), .sof(1'b0),
		.instr_byte(ui_in), .addr_byte(uo), .phase_o(ph), .retire(retire),
		.t_instr(t_instr), .t_rf1(t_rf1), .t_rf2(t_rf2), .t_pc_next(t_pc_next),
		.t_wb_val(t_wb_val), .t_reg_we(t_reg_we),
		.t_rdata_r(t_rdata_r), .t_instr_r(t_instr_r), .t_phase(t_phase), .t_kind(t_kind),
		.t_store_beat(t_store_beat));

	// ---- the host's view of the bus, from pins only ---------------------------------------------
	localparam [1:0] T_FETCH = 2'b01, T_LOAD = 2'b10, T_STORE = 2'b11;
	reg  [1:0]  mph;                 // the host's own phase counter (datasheet: "keeps its own")
	reg  [1:0]  kind_l;              // loop TYPE as reported on uio_out[1:0] at phase 0
	reg  [23:0] ab, db;              // bytes 0..2 out (uo_out) and in (ui_in) of this loop
	reg         st_data;             // 1 = this STORE loop is the data beat
	reg  [31:0] f_insn, f_pc, s_addr;
	reg  [63:0] order;

	wire [1:0]  kind = (mph == 2'd0) ? ph : kind_l;
	wire [31:0] aw   = {uo, ab};     // valid at mph == 3: the loop's 4 bytes out
	wire [31:0] dw   = {ui_in, db};  // valid at mph == 3: the loop's 4 bytes in

	always @(posedge clock) begin
		if (reset) begin
			mph <= 2'd0; st_data <= 1'b0; order <= 64'd0;
			f_insn <= 32'd0; f_pc <= 32'd0; s_addr <= 32'd0;  // reset so the invariants below are exact
		end else begin
			mph <= mph + 2'd1;
			if (mph == 2'd0) kind_l <= ph;
			case (mph)
				2'd0: begin ab[7:0]   <= uo; db[7:0]   <= ui_in; end
				2'd1: begin ab[15:8]  <= uo; db[15:8]  <= ui_in; end
				2'd2: begin ab[23:16] <= uo; db[23:16] <= ui_in; end
				2'd3: begin
					if (kind == T_FETCH) begin f_insn <= dw; f_pc <= aw; end
					if (kind == T_STORE && !st_data) s_addr <= aw;
					st_data <= (kind == T_STORE) && !st_data;
				end
			endcase
			if (rvfi_valid) order <= order + 64'd1;
		end
	end

	// ---- RVFI -----------------------------------------------------------------------------------
	wire        in_fetch = (kind == T_FETCH);
	wire        is_ld    = (kind == T_LOAD);
	wire        is_st    = (kind == T_STORE) && st_data;
	wire [4:0]  rd       = t_instr[11:7];
	wire        rd_w     = t_reg_we && (rd != 5'd0);
	wire [31:0] maddr    = is_ld ? aw : s_addr;

	assign rvfi_valid     = !reset && retire;
	assign rvfi_order     = order;
	assign rvfi_insn      = in_fetch ? dw : f_insn;
	assign rvfi_pc_rdata  = in_fetch ? aw : f_pc;
	assign rvfi_pc_wdata  = t_pc_next;
	assign rvfi_trap      = (t_pc_next[1:0] != 2'b00) || ((is_ld || is_st) && maddr[1:0] != 2'b00);
	assign rvfi_halt      = 1'b0;
	assign rvfi_intr      = 1'b0;
	assign rvfi_mode      = 2'd3;
	assign rvfi_ixl       = 2'd1;
	assign rvfi_rs1_addr  = t_instr[19:15];
	assign rvfi_rs2_addr  = t_instr[24:20];
	assign rvfi_rs1_rdata = t_rf1;
	assign rvfi_rs2_rdata = t_rf2;
	assign rvfi_rd_addr   = rd_w ? rd : 5'd0;
	assign rvfi_rd_wdata  = rd_w ? t_wb_val : 32'd0;
	assign rvfi_mem_addr  = (is_ld || is_st) ? maddr : 32'd0;
	assign rvfi_mem_rmask = is_ld ? 4'hf : 4'h0;
	assign rvfi_mem_wmask = is_st ? 4'hf : 4'h0;
	assign rvfi_mem_rdata = is_ld ? dw : 32'd0;
	assign rvfi_mem_wdata = is_st ? aw : 32'd0;

	// ---- SCOPE: the trace before the checked retirement is TRAP-FREE --------------------------------
	// RV32I traps on a misaligned target; core32 has no trap and runs on with a misaligned pc, so every
	// retirement after one is outside RV32I. `seen_trap` covers EARLIER retirements only (it is a
	// register), so the checked retirement's own trap stays free and `spec_trap == trap` still bites.
	reg seen_trap;
	always @(posedge clock) seen_trap <= reset ? 1'b0 : (seen_trap || (rvfi_valid && rvfi_trap));
	always @* if (!reset) assume (!seen_trap);

`ifdef AAJ_LW_SHAPE
	// ---- desk AAJ: the EXACT SHAPE of LW, unbounded (lw_shape.sh) -----------------------------------
	// SHAPE: every LW retirement (rd != x0) writes the word the host returned on the pins in the
	// PREVIOUS load loop, 0 if none since reset. The `inv_*` asserts tie the host's pin-built view to
	// the adapter's own registers; they are what lets k-induction close, and each is itself PROVED.
	reg [31:0] prev_ld;
	always @(posedge clock)
		if (reset) prev_ld <= 32'd0;
		else if (rvfi_valid && rvfi_mem_rmask == 4'hf) prev_ld <= rvfi_mem_rdata;
	wire is_lw = (rvfi_insn[6:0] == 7'b0000011) && (rvfi_insn[14:12] == 3'b010);
	reg  past_reset;
	always @(posedge clock) past_reset <= reset ? 1'b0 : 1'b1;
	always @* if (!reset && past_reset) begin
		inv_phase: assert (mph == t_phase);
		inv_kind:  assert (kind == t_kind);
		inv_beat:  assert (st_data == t_store_beat);
		inv_insn:  assert (f_insn == t_instr_r);
		inv_ld:    assert (prev_ld == t_rdata_r);
	end
	always @* if (!reset && rvfi_valid && is_lw && rvfi_insn[11:7] != 5'd0) begin
		shape: assert (rvfi_rd_wdata == prev_ld);
`ifdef LW_SHAPE_MUTANT
		mutant: assert (rvfi_rd_wdata == rvfi_mem_rdata);   // the RV32I claim — MUST FAIL on the fab
`endif
	end
	always @* if (!reset) witness: cover (rvfi_valid && is_lw && rvfi_insn[11:7] != 5'd0
	                                      && prev_ld != rvfi_mem_rdata && prev_ld != 32'd0);
`endif

	// ---- the bus protocol itself, as the datasheet states it: PHASE NUMBER at phases 1..3 -------
	always @* if (!reset && mph != 2'd0) assert (ph == mph);
endmodule
