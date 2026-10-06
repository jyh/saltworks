// lw_shape.sv — desk AAJ: top for the LW-SHAPE proof. The property and its invariants live in
// wrapper.sv under `AAJ_LW_SHAPE` (they need the taps); this file only supplies RVFI and reset.
`define RISCV_FORMAL
`define RISCV_FORMAL_NRET 1
`define RISCV_FORMAL_XLEN 32
`define RISCV_FORMAL_ILEN 32
`define RISCV_FORMAL_ALIGNED_MEM
`define AAJ_LW_SHAPE
`include "rvfi_macros.vh"

module lw_shape (input clock, input reset);
	`RVFI_WIRES
	always @* assume (reset == $initstate);
	rvfi_wrapper wrapper (.clock(clock), .reset(reset), `RVFI_CONN);
endmodule
