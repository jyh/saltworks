OUTPUT_ARCH("riscv")
ENTRY(_start)
SECTIONS {
  . = 0x0;
  .text : { *(.text*) }
  . = ALIGN(16);
  .data : { *(.data*) *(.sdata*) *(.rodata*) }
  .bss  : { *(.bss*) *(.sbss*) }
  _end = .;
}
