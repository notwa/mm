; oot debug rom
; mess with display lists
; game note: #2 jumps to #3 which jumps to #1 which calls pieces of #2
;            what a mess

[ctxt]: 0x80212020
[dlists]: 0x80168930

[original]: 0x800C6AC4
[inject_from]: 0xB3D458 ; 0x800C62B8
[inject_to]: 0x80700000

; set up screen dimensions to render widescreen.
[res2_L]: 0
[res2_T]: 30
[res2_R]: 320
[res2_B]: 210

.include "dma O EUDB MQ.asm"

.push pc
.base 0x7F588E60 ; code file in memory

.org @inject_from
    jal     @inject_to

.org 0xB21D30 ; 0x800AAB90
    li      t3, @res2_B ; 240B00D2
    li      t4, @res2_T ; 240C001E
.org 0xB21D48 ; 0x800AABA8
    li      t1, @res2_R ; 24090140
    li      t2, @res2_L ; 240A0000

.pop pc
    sw      ra, -4(sp)
    sw      a0,  0(sp)
    sw      a1,  4(sp)
    sw      a2,  8(sp)
    sw      a3, 12(sp)
    bal     start
    subi    sp, sp, 24
    lw      ra, 20(sp)
    lw      a0, 24(sp)
    lw      a1, 28(sp)
    lw      a2, 32(sp)
    lw      a3, 36(sp)
    j       @original
    addi    sp, sp, 24

.include "widescreen-either.asm"
