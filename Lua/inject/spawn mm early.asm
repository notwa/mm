[actor_spawn]: 0x800BC98C
[object_spawn]: 0x80130D50
[max_actor_no]: 0x2B1

[global_context]: 0x803E6CF0
[buttons_offset]: 0x14
[actor_spawn_offset]: 0x1CA0
[object_spawn_offset]: 0x17D68

[link_actor]: 0x803FFFA0
[actor_x]: 0x24
[actor_y]: 0x28
[actor_z]: 0x2C
[actor_horiz_angle]: 0x32

[link_save]: 0x801EF460
[rupees_offset]: 0x3A
[upgrades_offset]: 0xB8
[upgrades_2_offset]: 0xBA

.include "spawn.asm"

actor_object_table:
.include "actor object table mm.asm"
