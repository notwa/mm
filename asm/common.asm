[vstart]: 0x02EE7040 ; VROM address of our "extra" file
[start]: 0x80780000 ; RAM address of the "extra" file after DMA hook
[size]: 0x5A800 ; this is the most we can store in this region of RAM

[DMARomToRam]: 0x80080C90

[link_save]: 0x801EF670
 [has_completed_intro]: 0x5
 [have_tatl]: 0x22
 [player_name]: 0x2C
 [scene_flags]: 0x470
 [week_event_reg]: 0xEF8
 [voidout_type]: 0x3CB0
 [voidout_exit]: 0x3CC4
 [exit_mod_setter]: 0x3F4A
 [scene_flags_ingame]: 0x3F68

[global_context]: 0x803E6B20 ; FIXME: don't hardcode

[link_actor]: 0x803FFDB0 ; FIXME: don't hardcode
[link_object_ptr]: 0x803FFFF4 ; actually just an offset of link_actor?
;[link_object_ptr]: 0x244

[scene_record_size]: 0x14

[starting_exit]: 0xD800
