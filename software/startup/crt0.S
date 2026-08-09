.section .text
.globl _start

_start:
    lui  sp, 0x1            # sp = 0x1000 (top of 4KB DMEM)
    addi sp, sp, -16        # sp = 0xFF0 (small offset for safety)
    jal  x0, main

halt:
    jal  x0, halt
