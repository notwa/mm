; oot debug rom
; mess with display lists
; game note: #2 jumps to #3 which jumps to #1 which calls pieces of #2
;            what a mess

[ctxt]: 0x80212020
[dlists]: 0x80168930

[DMARomToRam]: 0x80000BFC

[vstart]: 0x035D0000
[start]: 0x80700000
[size]: 0x10000

/*
.org 0x18F30
; add an entry to the end of dmatable to hold our extra code
; this actually just crashes the game so don't bother
; (no debug filename associated with it = bad pointer dereference? maybe?)
    .word @vstart    ; virtual start
    .word 0x035E0000 ; virtual end (@vstart + @size)
    .word @vstart    ; physical start (should be same as virtual start)
    .word 0          ; physical end (should be 0 for uncompressed)
*/

.org 0xB3D9E4 ; 0x800C6844
    ; this appears to be the main game loop function
    ; we can "make room" for some injected code
    ; by taking advantage of it never returning under normal circumstances.
    ; we'll cut out pushing RA, S1-S8 stuff on stack.
    ; props to CloudMax for coming up with this.
    addiu   sp, sp, 0xFC60 ; original code
    ; push removed here
    li      s0, 0x8011F830 ; original code
    ; pushes removed here
    ; 9 instructions to work with?
    ; dma args are backwards compared to MM?
    li      a1, @start
    li      a2, @size
    jal     @DMARomToRam
    li      a0, @vstart
    lui     a0 0x8014 ; original code
    cl      a1
    cl      a2
    nop
    nop
    nop
    nop
    nop

[original]: 0x800C6AC4
[inject_from]: 0xB3D458 ; 0x800C62B8
[inject_to]: 0x80700000

.org @inject_from
    jal     @inject_to

.org @inject_to
    sw      ra, -4(sp)
    sw      a0,  0(sp)
    sw      a1,  4(sp)
    sw      a2,  8(sp)
    sw      a3, 12(sp)
    bal     start
    subi    sp, sp, 24
    lw      ra, 20(sp)
    lw      a0, 24(sp)
    lw      a1, 28(sp)
    lw      a2, 32(sp)
    lw      a3, 36(sp)
    j       @original
    addi    sp, sp, 24

.include "widescreen-either.asm"

; set up screen dimensions to render widescreen.
[res2_L]: 0
[res2_T]: 30
[res2_R]: 320
[res2_B]: 210
.org 0xB21D30 ; 0x800AAB90
    li      t3, @res2_B ; 240B00D2
    li      t4, @res2_T ; 240C001E
.org 0xB21D48 ; 0x800AABA8
    li      t1, @res2_R ; 24090140
    li      t2, @res2_L ; 240A0000
