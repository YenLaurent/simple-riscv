# RV32I Full Instruction Test
# Self-checking: on pass, x30 increments and stores to DMEM[x28].
# On fail, x30 is stored raw and loops forever.
#
# Register map:
#   x20 = DMEM scratch address 0x200
#   x28 = test result pointer (0x100+)
#   x30 = pass counter

.section .text
.globl test_main

test_main:
    addi x28, x0, 0x100     # result storage @ DMEM[0x100]
    addi x20, x0, 0x200     # scratch buffer @ DMEM[0x200]
    addi x30, x0, 0

    # ====================================================
    # G1: I-type ALU immediate (addi, slti, sltiu, xori, ori, andi)
    # ====================================================

    addi x1, x0, 42         # addi +
    addi x2, x0, 42
    beq  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -10        # addi -
    addi x2, x0, -10
    beq  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 999        # addi to x0 must stay 0
    addi x0, x0, 999
    beq  x0, x0, 1f         # x0 == x0 always
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 5          # slti: 5 < 10
    slti x3, x1, 10
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -2         # slti: -2 < 5
    slti x3, x1, 5
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 5          # slti: 5 < -2
    slti x3, x1, -2
    beq  x3, x0, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -1         # sltiu: -1(0xFFFFFFFF) < 1 = 0 (unsigned)
    sltiu x3, x1, 1
    beq  x3, x0, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 1          # sltiu: 1 < -1(0xFFFFFFFF) = 1
    sltiu x3, x1, -1
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x7A0      # xori
    xori x3, x1, 0x0A5
    addi x4, x0, 0x705
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x300      # ori
    ori  x3, x1, 0x0C0
    addi x4, x0, 0x3C0
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x3FF      # andi
    andi x3, x1, 0x0F0
    addi x4, x0, 0x0F0
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G2: I-type shifts (slli, srli, srai)
    # ====================================================

    addi x1, x0, 3          # slli: 3 << 4 = 48
    slli x3, x1, 4
    addi x4, x0, 48
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    lui  x1, 0x80000        # srli: 0x80000000 >> 4 = 0x08000000
    srli x3, x1, 4
    lui  x4, 0x08000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    lui  x1, 0x80000        # srai: 0x80000000 >>> 4 = 0xF8000000
    srai x3, x1, 4
    lui  x4, 0xF8000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G3: R-type add/sub
    # ====================================================

    addi x1, x0, 100        # add
    addi x2, x0, 233
    add  x3, x1, x2
    addi x4, x0, 333
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 100        # sub +
    addi x2, x0, 67
    sub  x3, x1, x2
    addi x4, x0, 33
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 10         # sub negative
    addi x2, x0, 30
    sub  x3, x1, x2
    addi x4, x0, -20
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G4: R-type (sll, srl, sra, slt, sltu, xor, or, and)
    # ====================================================

    addi x1, x0, 1          # sll
    addi x2, x0, 10
    sll  x3, x1, x2
    addi x4, x0, 1024
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    lui  x1, 0x80000        # srl
    addi x2, x0, 4
    srl  x3, x1, x2
    lui  x4, 0x08000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    lui  x1, 0x80000        # sra
    addi x2, x0, 4
    sra  x3, x1, x2
    lui  x4, 0xF8000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # slt
    addi x2, x0, 3
    slt  x3, x1, x2
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # sltu: 0xFFFFFFFB < 3 as unsigned? No → 0
    addi x2, x0, 3
    sltu x3, x1, x2
    beq  x3, x0, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x7A0       # xor
    addi x2, x0, 0x0A5
    xor  x3, x1, x2
    addi x4, x0, 0x705
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x300      # or
    addi x2, x0, 0x0C0
    or   x3, x1, x2
    addi x4, x0, 0x3C0
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 0x3FF      # and
    addi x2, x0, 0x0F0
    and  x3, x1, x2
    addi x4, x0, 0x0F0
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G5: U-type (lui, auipc)
    # ====================================================

    lui  x1, 0x12345        # lui
    lui  x2, 0x12345
    beq  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    auipc x1, 0x10          # auipc: two back-to-back → delta=4
    auipc x2, 0x10
    sub  x3, x2, x1
    addi x4, x0, 4
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G6: Store + Load (sw/sh/sb, lw/lh/lb/lhu/lbu)
    # ====================================================

    addi x20, x0, 0x200     # reset scratch pointer

    addi x1, x0, 0x5AA      # sw + lw
    sw   x1, 0(x20)
    lw   x3, 0(x20)
    beq  x1, x3, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -1         # sh + lh (sign-extend: 0xFFFF → 0xFFFFFFFF)
    sh   x1, 0(x20)
    lh   x3, 0(x20)
    beq  x1, x3, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -1         # sh + lhu (zero-extend: 0xFFFF → 0x0000FFFF)
    sh   x1, 0(x20)
    lhu  x3, 0(x20)
    lui  x4, 0x00010
    addi x4, x4, -1         # x4 = 0xFFFF
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -1         # sb + lb (sign-extend: 0xFF → 0xFFFFFFFF)
    sb   x1, 0(x20)
    lb   x3, 0(x20)
    beq  x1, x3, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -1         # sb + lbu (zero-extend: 0xFF → 0x000000FF)
    sb   x1, 0(x20)
    lbu  x3, 0(x20)
    addi x4, x0, 0xFF
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x20, x0, 0x200     # sh at offset 2
    addi x1, x0, 0
    sw   x1, 0(x20)         # clear
    addi x1, x0, 0x7AB
    sh   x1, 2(x20)         # store halfword at byte offset 2
    lw   x3, 0(x20)         # read whole word
    lui  x4, 0x7AB0         # expected: 0x7AB0 << 12 = 0x07AB0000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x20, x0, 0x200     # sb at offset 3
    addi x1, x0, 0
    sw   x1, 0(x20)
    addi x1, x0, 0x5C
    sb   x1, 3(x20)
    lw   x3, 0(x20)
    lui  x4, 0x5C000        # expected: sb 0x5C at offset 3 → 0x5C000000
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G7: Branch (beq, bne, blt, bge, bltu, bgeu) — taken + not-taken
    # ====================================================

    addi x1, x0, 42         # beq taken
    addi x2, x0, 42
    beq  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 42         # beq not taken
    addi x2, x0, 99
    beq  x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 42         # bne taken
    addi x2, x0, 99
    bne  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 77         # bne not taken
    addi x2, x0, 77
    bne  x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # blt taken (-5 < 3)
    addi x2, x0, 3
    blt  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 10         # blt not taken (10 < -3 is false)
    addi x2, x0, -3
    blt  x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 5          # bge taken (5 >= -1)
    addi x2, x0, -1
    bge  x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # bge not taken (-5 >= 3 is false)
    addi x2, x0, 3
    bge  x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 3          # bltu taken (3 < 0xFFFFFFFB as unsigned)
    addi x2, x0, -5
    bltu x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # bltu not taken (0xFFFFFFFB < 3 is false)
    addi x2, x0, 3
    bltu x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, -5         # bgeu taken (0xFFFFFFFB >= 3)
    addi x2, x0, 3
    bgeu x1, x2, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    addi x1, x0, 3          # bgeu not taken (3 >= 0xFFFFFFFB is false)
    addi x2, x0, -5
    bgeu x1, x2, fail
    addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # G8: Jump (jal, jalr)
    # ====================================================

    jal  x5, 1f             # jal: x5 = return address, jump forward
    jal  x0, fail
1:  sltu x3, x0, x5          # x5 = return address, must be non-zero (0 < x5)
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    auipc x21, 0            # jalr: x21 = PC
    addi  x21, x21, 16       # point to jalr_target (4 instr ahead = 16 bytes)
    jalr  x6, x21, 0         # x6 = PC+4, jump to x21
    jal   x0, fail
jalr_target:
    auipc x7, 0              # x7 = PC (after jalr)
    sub  x3, x7, x6          # x7 - x6 = small positive
    sltiu x3, x3, 100        # difference < 100?
    addi x4, x0, 1
    beq  x3, x4, 1f
    jal  x0, fail
1:  addi x30, x30, 1
    sw   x30, 0(x28)
    addi x28, x28, 4

    # ====================================================
    # SUCCESS
    # ====================================================
success:
    addi x1, x0, 0x600
    sw   x1, 0(x28)         # store SUCCESS marker 0x00000600
    jal  x0, success

fail:
    sw   x30, 0(x28)         # store failure counter
    jal  x0, fail
