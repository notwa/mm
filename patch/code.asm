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

[starting_exit]: 0x9F87C
[default_save]: 0x120DD8

.org @starting_exit
    li      t8, 0xD800 ; modified code
    li      t4, 0xD800 ; modified code

.org @default_save
    .ascii  "\0\0\0\0\0\0" ; ZELDA3
    .half   1 ; SoT count
    .ascii  ">>>>>>>>" ; player name
    .half   0x30 ; hearts
    .half   0x30 ; max hearts
    .byte   1 ; magic level
    .byte   0x30 ; magic amount
    .half   0 ; rupees
    .word   0 ; navi timer
    .byte   1 ; has normal magic
    .byte   0 ; has double magic
    .half   0 ; double defense
    .half   0xFF00 ; unknown
    .half   0x0000 ; owls hit
    .word   0xFF000008 ; unknown
    .word   0x4DFFFFFF ; human buttons
    .word   0x4DFFFFFF ; goron buttons
    .word   0x4DFFFFFF ; zora buttons
    .word   0xFDFFFFFF ; deku buttons
    .word   0x00FFFFFF ; equipped slots
    .word   0xFFFFFFFF ; unknown
    .word   0xFFFFFFFF ; unknown
    .word   0xFFFFFFFF ; unknown
    .half   0x0011 ; tunic & boots
    .half   0 ; unknown
    ; inventory items
    .byte   0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF ; ocarina, nothing else
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    ; mask items
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x32 ; deku mask, nothing else
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    ; item quantities
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    ;
    .word   0 ; upgrades
    .word   0x00003000 ; quest status (set song of time and song of healing)
