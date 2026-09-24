.include "test_macros.inc"
.section .text
.globl _start
_start:
    # Back-to-back register dependencies, then store -> load -> branch.
    addi x7, x0, 1
    addi x7, x7, 2
    add  x8, x7, x7
    sub  x9, x8, x7
    addi x10, x0, 3
    bne  x9, x10, fail

    lui  x11, 0x2
    sd   x9, 0(x11)
    ld   x12, 0(x11)
    add  x13, x12, x9
    addi x14, x0, 6
    bne  x13, x14, fail
    beq  x13, x14, taken
    addi x15, x0, 99
taken:
    # A taken branch must skip the preceding sequential instruction.
    bne  x15, x0, fail
    PASS
fail:
    FAIL
