[actor_spawn]: 0x80025110
[object_spawn]: 0x800812F0
[object_index]: 0x80081628
[max_actor_no]: 0x1D6

[global_context]: 0x801C84A0
[buttons_offset]: 0x14
[actor_spawn_offset]: 0x1C24
[object_spawn_offset]: 0x117A4

[link_actor]: 0x801DAA30
[actor_x]: 0x24
[actor_y]: 0x28
[actor_z]: 0x2C
[actor_horiz_angle]: 0x46

[link_save]: 0x8011A5D0
[rupees_offset]: 0x34
[upgrades_offset]: 0xA0
[upgrades_2_offset]: 0xA2

[dlist_offset]: 0x2B0

[SetTextRGBA]:      0x800CBE58
[SetTextXY]:        0x800CBEC8
[SetTextString]:    0x800CC588
[TxtPrinter]:       0x800CC480
[InitTxtStruct]:    0x800CC4AC ; unused here; we set it up inline
[DoTxtStruct]:      0x800CC508
[UpdateTxtStruct]:  0x800CC550

.include "spawn.asm"
