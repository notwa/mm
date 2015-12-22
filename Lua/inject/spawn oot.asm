[actor_spawn]: 0x80025110
[object_spawn]: 0x800812F0
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

.include "spawn.asm"

actor_object_table:
.include "actor object table oot.asm"
