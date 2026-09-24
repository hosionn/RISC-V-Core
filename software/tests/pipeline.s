.include "test_macros.inc"
.section .text
.globl _start
_start:
    # Consecutive ALU RAW dependencies: EX/MEM takes priority over MEM/WB.
    addi x7, x0, 1
    addi x7, x7, 2
    add  x8, x7, x7
    addi x9, x0, 6
    bne  x8, x9, fail

    # At ID, x20 is written in WB on the same edge. x21 also needs forwarding.
    addi x20, x0, 9
    addi x21, x0, 1
    addi x22, x0, 2
    add  x23, x20, x21
    addi x24, x0, 10
    bne  x23, x24, fail

    # Load-use, load-to-store-data and load-to-branch dependencies.
    lui  x10, 0x2
    sd   x8, 0(x10)
    ld   x11, 0(x10)
    add  x12, x11, x8
    addi x9, x0, 12
    bne  x12, x9, fail
    ld   x13, 0(x10)
    sd   x13, 8(x10)
    ld   x14, 8(x10)
    beq  x14, x8, taken
    jal  x0, fail
taken:
    # The instruction following a taken branch must be flushed.
    beq  x12, x9, 1f
    jal  x0, fail
1:
    PASS
fail:
    FAIL
