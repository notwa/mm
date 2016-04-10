.include "common.asm"

[starting_exit]: 0x9F87C
[default_save]: 0x120DD8

; 0x8016A2C8 -> 0xC4808
; 0x8016A2C8 - 0xC4808 = 0x800A5AC0
; 0x8016AC0C - 0x8016A2C8 = 0x944

.org 0xCEDE0 ; 0x801748A0
    ; this appears to be the main game loop function
    ; we can "make room" for some injected code
    ; by taking advantage of it never returning under normal circumstances.
    ; we'll cut out pushing RA, S1-S8 stuff on stack.
    ; props to CloudMax for doing this in OoT first.
    addiu   sp, sp, 0xFCC0 ; original code
    ; push removed here
    li      s0, 0x801BD910 ; original code
    ; pushes removed here
    ; 6 instructions to work with
    li      a1, @vstart         ; 2
    li      a2, @size           ; 2
    jal     @DMARomToRam        ; 1
    li      a0, @start          ; 1 (just make sure @start can be a LUI!)

.org 0xC4808 ; 0x8016A2C8
    j       dma_hook            ; 1
    nop                         ; 1

.org 0x9F9A4 ; JR of starting_exit's function
    j       load_hook ; tail call

.org 0x80710
    j       tunic_color_hook
    lhu     t1, 0x1DB0(t1); original code

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
