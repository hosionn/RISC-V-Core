.include "test_macros.inc"
.section .text
.globl _start
_start:
    lui  x7, 0x2           # RAM test area at 0x2000
    addi x8, x0, -1
    sb   x8, 0(x7)
    lb   x9, 0(x7)
    bne  x9, x8, fail
    lbu  x9, 0(x7)
    addi x10, x0, 255
    bne  x9, x10, fail

    sh   x8, 2(x7)
    lh   x9, 2(x7)
    bne  x9, x8, fail
    lhu  x9, 2(x7)
    lui  x10, 0x10
    addi x10, x10, -1
    bne  x9, x10, fail

    sw   x8, 4(x7)
    lw   x9, 4(x7)
    bne  x9, x8, fail
    lwu  x9, 4(x7)
    srli x10, x8, 32
    bne  x9, x10, fail

    sd   x8, 8(x7)
    ld   x9, 8(x7)
    bne  x9, x8, fail
    addi x11, x0, 42
    sd   x11, 16(x7)
    ld   x12, 16(x7)
    bne  x11, x12, fail
    PASS
fail:
    FAIL
