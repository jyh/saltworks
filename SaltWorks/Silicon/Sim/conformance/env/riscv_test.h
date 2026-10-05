// riscv_test.h — a MINIMAL bare environment for riscv-tests rv32ui on core32.
// core32 has no CSRs, no traps, no ECALL: so this env has none either.
//   PASS  -> sw 1 to tohost
//   FAIL  -> sw (TESTNUM<<1)|1 to tohost          (riscv-tests' own convention)
// The bench halts on the first store whose ADDRESS (read at the pins) is tohost.
#ifndef _ENV_CORE32_H
#define _ENV_CORE32_H
#define RVTEST_RV64U .text
#define RVTEST_RV32U .text
#define TESTNUM gp
#define RVTEST_CODE_BEGIN .text; .align 2; .globl _start; _start: ;
#define RVTEST_CODE_END   1: j 1b;
#define RVTEST_PASS  li a0, 1; la a1, tohost; sw a0, 0(a1); 1: j 1b;
#define RVTEST_FAIL  slli a0, TESTNUM, 1; ori a0, a0, 1; la a1, tohost; sw a0, 0(a1); 1: j 1b;
#define RVTEST_DATA_BEGIN .data; .align 4; .globl tohost; tohost: .word 0; .align 4;
#define RVTEST_DATA_END
#define EXTRA_DATA
#endif
