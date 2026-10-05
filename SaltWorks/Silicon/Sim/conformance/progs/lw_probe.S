// lw_probe.S — the LW data path, read at the PINS. Three distinct words; each load's
// destination is stored straight back out so the host sees what the register received.
#include "riscv_test.h"
RVTEST_CODE_BEGIN
  la   x20, out
  la   x21, dat
  lw   x5, 0(x21)  ; sw x5, 0(x20)    // r0  first LW: expects dat[0]
  lw   x6, 4(x21)  ; sw x6, 4(x20)    // r1  expects dat[1]
  lw   x7, 8(x21)  ; sw x7, 8(x20)    // r2  expects dat[2]
  lw   x8, 8(x21)  ; sw x8, 12(x20)   // r3  the SAME address again (a double-LW workaround?)
  lw   x9, 0(x21)  ; sw x9, 16(x20)   // r4  expects dat[0]
  addi x10, x0, 77 ; sw x10, 20(x20)  // r5  control: a non-load writeback through the same SW path
  li a0, 1; la a1, tohost; sw a0, 0(a1)
1: j 1b
RVTEST_CODE_END
RVTEST_DATA_BEGIN
dat: .word 0x11111111, 0x22222222, 0x33333333
out: .fill 8, 4, 0
RVTEST_DATA_END
