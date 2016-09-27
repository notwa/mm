.include "dma O EUDB MQ.asm"

[original]: 0x800C6AC4
[inject_from]: 0xB3D458 ; 0x800C62B8
[inject_to]: 0x80700000

.push pc
.base 0x7F588E60 ; code file in memory

.org @inject_from
    jal     @inject_to

.pop pc

    sw      ra, -4(sp)
    sw      a0,  0(sp)
    sw      a1,  4(sp)
    sw      a2,  8(sp)
    sw      a3, 12(sp)
    bal     spawn
    subi    sp, sp, 24
    lw      ra, 20(sp)
    lw      a0, 24(sp)
    lw      a1, 28(sp)
    lw      a2, 32(sp)
    lw      a3, 36(sp)
    j       @original
    addi    sp, sp, 24

[actor_spawn]: 0x80031F50
[object_spawn]: 0x80097C00
[object_index]: 0xB0F2CC ; 0x8009812C

[max_actor_no]: 0x1D6

[global_context]: 0x80212020
 [buttons_offset]: 0x14
 [actor_spawn_offset]: 0x1C24
 [object_spawn_offset]: 0x117A4

[link_actor]: 0x802245B0
 [actor_x]: 0x24
 [actor_y]: 0x28
 [actor_z]: 0x2C
 [actor_horiz_angle]: 0x46

// offset from first pointer in global context
[dlist_offset]: 0x2B0

[SetTextRGBA]:      0x800FB3AC
[SetTextXY]:        0x800FB41C
[SetTextString]:    0x800FBCB4
[TxtPrinter]:       0x800FBB60
[InitTxtStruct]:    0x800FBB8C // unused here; we set it up inline
[DoTxtStruct]:      0x800FBC1C
[UpdateTxtStruct]:  0x800FBC64

.include "spawn.asm"
