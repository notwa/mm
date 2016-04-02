.include "common.asm"

[starting_exit]: 0x9F87C
[default_save]: 0x120DD8

; 0x8016A2C8 -> 0xC4808
; 0x8016A2C8 - 0xC4808 = 0x800A5AC0

; 0x8016AC0C - 0x8016A2C8 = 0x944

.org 0xC4808
    ; if we've already loaded once, don't load again
    lbu     t0, @start          ; 2
    bnez    t0, +               ; 1
    nop                         ; 1
    push    4, a0, a1, a2, ra   ; 5
    li      a0, @start          ; 1
    li      a1, @vstart         ; 2
    li      a2, @size           ; 2
    jal     @DMARomToRam        ; 1
    nop                         ; 1
    pop     4, a0, a1, a2, ra   ; 5
+:
    j       @dma_hook           ; 1
    nop                         ; 1
; total overwriten instructions: 23
; the original function is in setup.asm,
; and is moved into our extra file.
; we have (0x944 / 4 - 23) = 570 words of space here, should we need it.
    .word    0xDEADBEEF

.org 0x9F9A4 ; JR of starting_exit's function
    j       @load_hook ; tail call

.org 0x80710
    j       @tunic_color_hook
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
