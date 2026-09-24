.include "test_macros.inc"
.section .text
.globl _start
_start:
    addi x7, x0, 7
    addi x8, x0, 5
    add  x9, x7, x8
    addi x10, x0, 12
    bne  x9, x10, fail
    sub  x9, x7, x8
    addi x10, x0, 2
    bne  x9, x10, fail

    slli x9, x8, 3
    addi x10, x0, 40
    bne  x9, x10, fail
    srli x9, x9, 2
    addi x10, x0, 10
    bne  x9, x10, fail
    addi x11, x0, -16
    srai x9, x11, 2
    addi x10, x0, -4
    bne  x9, x10, fail

    and  x9, x7, x8
    bne  x9, x8, fail
    or   x9, x7, x8
    bne  x9, x7, fail
    xor  x9, x7, x8
    addi x10, x0, 2
    bne  x9, x10, fail
    xori x9, x7, 2
    bne  x9, x8, fail
    ori  x9, x8, 2
    bne  x9, x7, fail
    andi x9, x7, 6
    addi x10, x0, 6
    bne  x9, x10, fail

    addi x11, x0, -1
    addi x12, x0, 1
    slt  x9, x11, x12
    bne  x9, x12, fail
    sltu x9, x11, x12
    bne  x9, x0, fail
    slti x9, x11, 0
    bne  x9, x12, fail
    sltiu x9, x7, -1
    bne  x9, x12, fail

    sll  x9, x8, x7
    addi x10, x0, 640
    bne  x9, x10, fail
    srl  x9, x10, x8
    addi x13, x0, 20
    bne  x9, x13, fail
    sra  x9, x11, x12
    bne  x9, x11, fail

    addiw x9, x11, 1
    bne   x9, x0, fail
    slliw x9, x11, 1
    addi  x10, x0, -2
    bne   x9, x10, fail
    srliw x9, x11, 1
    slli  x10, x12, 31
    addi  x10, x10, -1
    bne   x9, x10, fail
    sraiw x9, x11, 1
    bne   x9, x11, fail
    addw  x9, x11, x11
    addi  x10, x0, -2
    bne   x9, x10, fail
    subw  x9, x11, x11
    bne   x9, x0, fail
    sllw  x9, x11, x12
    bne   x9, x10, fail
    srlw  x9, x11, x12
    slli  x10, x12, 31
    addi  x10, x10, -1
    bne   x9, x10, fail
    sraw  x9, x11, x12
    bne   x9, x11, fail

    lui  x9, 0x80000
    slli x10, x11, 31
    bne  x9, x10, fail
    fence
    PASS
fail:
    FAIL
