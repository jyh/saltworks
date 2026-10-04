// sra_probe.S — (A): the shift family on one operand pair, every result stored, read at the PINS.
// The EXPECTED values are not written here: run.sh computes them from RV32I's definition.
#include "riscv_test.h"
RVTEST_CODE_BEGIN
  li   x1, -16            // 0xfffffff0
  li   x3, 2
  li   x10, 31
  li   x13, 0x80000000
  li   x7, 15
  la   x20, out
  srai x2, x1, 2   ; sw x2,  0(x20)   // r0  SRAI -16,2
  sra  x4, x1, x3  ; sw x4,  4(x20)   // r1  SRA  -16,2
  srli x5, x1, 2   ; sw x5,  8(x20)   // r2  SRLI -16,2      control: logical
  srl  x6, x1, x3  ; sw x6, 12(x20)   // r3  SRL  -16,2      control: logical
  srai x8, x7, 1   ; sw x8, 16(x20)   // r4  SRAI 15,1       control: positive operand
  srai x9, x1, 31  ; sw x9, 20(x20)   // r5  SRAI -16,31
  sra  x11, x1, x10; sw x11, 24(x20)  // r6  SRA  -16,31
  srai x12, x1, 0  ; sw x12, 28(x20)  // r7  SRAI -16,0      control: shamt 0
  srai x14, x13, 4 ; sw x14, 32(x20)  // r8  SRAI 0x80000000,4
  sub  x15, x0, x3 ; sw x15, 36(x20)  // r9  SUB 0-2         control: funct7 decode on OP
  addi x16, x0, -1024; sw x16, 40(x20) // r10 ADDI imm[10]=1  control: funct7-shaped bit on OP-IMM
  li a0, 1; la a1, tohost; sw a0, 0(a1)
1: j 1b
RVTEST_CODE_END
RVTEST_DATA_BEGIN
out: .fill 16, 4, 0
RVTEST_DATA_END
