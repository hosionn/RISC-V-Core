# A full-width store of 1 to 0xf000 passes; any other value fails.
.macro PASS
    lui  x5, 0xf
    addi x6, x0, 1
    sd   x6, 0(x5)
1:  jal  x0, 1b
.endm

.macro FAIL
    lui  x5, 0xf
    addi x6, x0, 2
    sd   x6, 0(x5)
1:  jal  x0, 1b
.endm
