[actor_spawn]: 0x800BAE14
[object_spawn]: 0x8012F2E0
[object_index]: 0x8012F608
[max_actor_no]: 0x2B1

[global_context]: 0x803E6B20
[buttons_offset]: 0x14
[actor_spawn_offset]: 0x1CA0
[object_spawn_offset]: 0x17D88

[link_actor]: 0x803FFDB0
[actor_x]: 0x24
[actor_y]: 0x28
[actor_z]: 0x2C
[actor_horiz_angle]: 0x32

[link_save]: 0x801EF670
[rupees_offset]: 0x3A
[upgrades_offset]: 0xB8
[upgrades_2_offset]: 0xBA

[dlist_offset]: 0x2B0

[SetTextRGBA]:      0x800859BC
[SetTextXY]:        0x80085A2C
[SetTextString]:    0x800860D8
[TxtPrinter]:       0x80085FE4
[InitTxtStruct]:    0x80086010 // unused here; we set it up inline
[DoTxtStruct]:      0x8008606C
[UpdateTxtStruct]:  0x800860A0

.include "spawn.asm"

[whatever]: 0x807D0000 // stupid hack since i can't store/restore PC (not yet!)
.org @whatever
    push    5, ra
    lhu     t0, 0(a1)
    andi    t0, t0, 0x07FF
    bnei    t0, 0x0C5, + // skip if not title screen actor
    nop
    jal     0x800BB2D0 // original code
    nop
+:
    jpop    5, ra

.org 0x800B9430 // part of scene actor loading routine
    jal     @whatever

.org 0x8012FC18 // scene command 0x0B (objects)
    // don't load any objects manually,
    // since spawn.asm handles that automatically
    jr
    nop
