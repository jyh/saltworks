// workaround_probe.S — the datasheet erratum's SOFTWARE WORKAROUNDS, measured at the PINS on the
// fabricated design (desk AAL, 2026-10-05). Every result is stored straight back out.
//   SRA rd,x,n  ==>  srli s,x,31 ; sub s,x0,s ; xor t,x,s ; srl t,t,n ; xor rd,t,s
//   SRAI rd,x,k ==>  the same with srli t,t,k     (uses only SRL/SRLI/SUB/XOR, all conforming)
//   LW           ==>  issue it twice, rd != base, no other LOAD between the two
#include "riscv_test.h"
#define SRA_W(rd,x,n)  srli x28,x,31; sub x28,x0,x28; xor x29,x,x28; srl  x29,x29,n; xor rd,x29,x28
#define SRAI_W(rd,x,k) srli x28,x,31; sub x28,x0,x28; xor x29,x,x28; srli x29,x29,k; xor rd,x29,x28
RVTEST_CODE_BEGIN
  la   x20, out
  la   x21, dat
  // ---- LW: the doubled form, FIRST load after reset included -----------------------------
  lw x5, 0(x21) ; lw x5, 0(x21) ; sw x5, 0(x20)       // r0  dat[0]
  lw x6, 4(x21) ; lw x6, 4(x21) ; sw x6, 4(x20)       // r1  dat[1]
  lw x7, 8(x21) ; sw x0, 64(x20) ; lw x7, 8(x21) ; sw x7, 8(x20)   // r2  dat[2], a STORE between the pair
  lw x8, 0(x21) ; lw x8, 0(x21) ; sw x8, 12(x20)      // r3  dat[0] again after a different address
  // ---- SRA / SRAI by the five-instruction sequence ----------------------------------------
  li x10, -16 ; li x11, 2  ; SRA_W(x12,x10,x11) ; sw x12, 16(x20)   // r4  fffffffc
  li x11, 31  ; SRA_W(x12,x10,x11) ; sw x12, 20(x20)                // r5  ffffffff
  li x11, 0   ; SRA_W(x12,x10,x11) ; sw x12, 24(x20)                // r6  fffffff0
  li x10, 0x80000000 ; li x11, 4 ; SRA_W(x12,x10,x11) ; sw x12, 28(x20)  // r7 f8000000
  li x10, 15  ; li x11, 1  ; SRA_W(x12,x10,x11) ; sw x12, 32(x20)   // r8  00000007
  li x10, 0x7fffffff ; li x11, 31 ; SRA_W(x12,x10,x11) ; sw x12, 36(x20) // r9 00000000
  li x10, -16 ; SRAI_W(x12,x10,2)  ; sw x12, 40(x20)                // r10 fffffffc
  SRAI_W(x12,x10,31) ; sw x12, 44(x20)                              // r11 ffffffff
  li x10, 0x80000000 ; SRAI_W(x12,x10,4) ; sw x12, 48(x20)          // r12 f8000000
  li x10, 0x12345678 ; SRAI_W(x12,x10,8) ; sw x12, 52(x20)          // r13 00123456
  li x10, 0x87654321 ; SRAI_W(x12,x10,8) ; sw x12, 56(x20)          // r14 ff876543
  li a0, 1; la a1, tohost; sw a0, 0(a1)
1: j 1b
RVTEST_CODE_END
RVTEST_DATA_BEGIN
dat: .word 0x11111111, 0x22222222, 0x33333333
out: .fill 17, 4, 0
RVTEST_DATA_END
