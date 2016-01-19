[link_save]: 0x801EF670
[has_completed_intro]: 0x5
[have_tatl]: 0x22
[player_name]: 0x2C
[scene_flags]: 0x470
[scene_record_size]: 0x14
[week_event_reg]: 0xEF8
[scene_flags_ingame]: 0x3F68

[global_context]: 0x803E6B20

[link_actor]: 0x803FFDB0

[starting_exit]: 0x8014533C
[default_save]: 0x801C6898

[link_object_ptr]: 0x803FFFF4

/*
    push    4, ra
    li      a0, 0x0063 // inside clock tower
    li      a1, 1 // second word
    li      a2, 0 // first bit ("You've met with a terrible fate")
    jal     set_scene_flag
    nop
    jpop    4, ra
*/
    jr
    nop

/* TODO:
short term:
    actually begin shuffling entrances/exits

long term:
    skip giants cutscenes; give oath when any mask is acquired
*/

    .word   0xDEADBEEF
// debugging stuff
whatever:
    .word 0
// end of debugging stuff
    .word   0xDEADBEEF

hash:
tunic_color:
    .word   0xFFFFFFFF

.include "crc32.asm"

set_scene_flag:
    // a0: scene number
    // a1: scene word (0-4)
    // a2: bit to set (0-31)
    // v0: new scene flag word
    li      t0, @link_save
    addiu   t1, t0, @scene_flags_ingame
    li      t2, @scene_record_size
    multu   a0, t2
    mflo    t2
    addu    t3, t1, t2
    sll     t4, a1, 2 // t4 = a1*sizeof(word)
    addu    t3, t3, t4
    lw      v0, (t3) // load scene flag word
    li      t6, 1
    sllv    t6, t6, a2
    or      v0, v0, t6 // set flag
    jr
    sw      v0, (t3) // write it back

set_event_flag:
    // a0: event flag offset
    // a1: byte offset
    // a2: bit to set (0-7)
    // v0: new event flag value
    li      t0, @link_save
    addu    t1, t0, a0
    addu    t2, t1, a1
    lb      v0, (t2)
    li      t6, 1
    sllv    t6, t6, a2
    or      v0, v0, t6
    jr
    sb      v0, (t2)

tunic_color_hook:
    // copypasta from CloudMax's old hack
    // registers available for use without blowing up: at, t3, t4, a0
    lw      t3, @link_object_ptr
    lui     t4, 0x0001
    sub     t3, t3, t4 // t3 -= 0x10000
    lw      t4, tunic_color
    sw      t4, 0xF184(t3)
    sw      t4, 0xEFFC(t3)
    sw      t4, 0xECB4(t3)
    sw      t4, 0xEB2C(t3)
    sw      t4, 0xE8F4(t3)
    sw      t4, 0xE47C(t3)
    sw      t4, 0xDE74(t3)
    sw      t4, 0xDDB4(t3)
    sw      t4, 0xDBDC(t3)
    sw      t4, 0xD6D4(t3)
    sw      t4, 0xD1AC(t3)
    j       tunic_color_hook_return
    lhu     v0, 0xF6DC(v0) // original code

load_hook:
    push    4, s0, s1, ra
    li      s0, @link_save
    lb      t0, @has_completed_intro(s0)
    bnez    t0, +
    li      t0, 1
    // first time setup
    sb      t0, @has_completed_intro(s0)
    sb      t0, @have_tatl(s0)
    li      a0, 0x0063 // inside clock tower
    li      a1, 1 // second word
    li      a2, 0 // first bit ("You've met with a terrible fate")
    jal     set_scene_flag
    nop
    li      a0, @week_event_reg
    li      a1, 31
    li      a2, 2 // Tatl reminding you about the four directions
    jal     set_event_flag
    nop
+:
    addi    a0, s0, @player_name
    li      a2, 0xFFFFFFFF
    jal     crc32
    li      a1, 8
    not     v0, v0
    sw      v0, hash
    jpop    4, s0, s1, ra

.org @starting_exit
    li      t8, 0xD800
    li      t4, 0xD800

.org 0x80145464 // JR of starting_exit's function
    j       load_hook // tail call

.org @default_save
    .ascii  "\0\0\0\0\0\0" // ZELDA3
    .half   0 // SoT count
    .ascii  ">>>>>>>>" // player name
    .half   0x30 // hearts
    .half   0x30 // max hearts
    .byte   1 // magic level
    .byte   0x30 // magic amount
    .half   0 // rupees
    .word   0 // navi timer
    .byte   1 // has normal magic
    .byte   0 // has double magic
    .half   0 // double defense
    .half   0xFF00 // unknown
    .half   0x0000 // owls hit
    .word   0xFF000008 // unknown
    .word   0x4DFFFFFF // human buttons
    .word   0x4DFFFFFF // goron buttons
    .word   0x4DFFFFFF // zora buttons
    .word   0xFDFFFFFF // deku buttons
    .word   0x00FFFFFF // equipped slots
    .word   0xFFFFFFFF // unknown
    .word   0xFFFFFFFF // unknown
    .word   0xFFFFFFFF // unknown
    .half   0x0011 // tunic & boots
    .half   0 // unknown
    // inventory items
    .byte   0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF // ocarina, nothing else
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    // mask items
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x32 // deku mask, nothing else
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    .byte   0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    // item quantities
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    .byte   0, 0, 0, 0, 0, 0
    //
    .word   0 // upgrades
    .word   0x00003000 // quest status (set song of time and song of healing)

.org 0x801261D0
    j       tunic_color_hook
    lhu     t1, 0x1DB0(t1)// original code
tunic_color_hook_return:
