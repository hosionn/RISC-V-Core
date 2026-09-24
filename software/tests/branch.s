.include "test_macros.inc"
.section .text
.globl _start
_start:
    addi x7, x0, 5
    addi x8, x0, 5
    addi x9, x0, -1
    bne  x7, x8, fail
    beq  x7, x8, 1f
    jal  x0, fail
1:
    beq  x7, x9, fail
    bne  x7, x9, 2f
    jal  x0, fail
2:
    blt  x9, x7, 3f
    jal  x0, fail
3:
    bge  x9, x7, fail
    bge  x7, x9, 4f
    jal  x0, fail
4:
    bltu x9, x7, fail
    bgeu x9, x7, 5f
    jal  x0, fail
5:
    bltu x7, x9, 6f
    jal  x0, fail
6:
    auipc x10, 0
    addi  x10, x10, 12
    jal   x1, jal_target
    jal   x0, fail
jal_target:
    bne   x1, x10, fail

    # The target is P+16; JALR clears bit 0 of (target+1).
    auipc x11, 0
    addi  x11, x11, 16
    jalr  x1, 1(x11)
    jal   x0, fail
jalr_target:
    addi  x12, x11, -4
    bne   x1, x12, fail
    PASS
fail:
    FAIL
