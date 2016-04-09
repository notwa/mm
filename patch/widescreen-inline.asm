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

start:
    push    4, 1, s0, s1, s2, s3, s4, s5, ra

; time for dlist misuse
    li      t0, @dlists
    lw      t0, 0x04(t0) ; HUD display list start
    cl      t2 ; iteration count

-:
    bgei    t2, 0x1000, finish ; give up after a while
    addiu   t2, t2, 1
    lw      t1, (t0) ; load a command
    li      t9, 0xDF000000
    beq     t1, t9, finish ; stop if we're at the end of the display list
    li      t9, 0xDC080008
    beq     t1, t9, screen_dim ; check if these are screen dimensions
    li      t9, 0xFF000000
    and     t3, t1, t9
    li      t9, 0xE4000000
    beq     t3, t9, texscale ; check if this is a 2D texture
    addiu   t0, t0, 8 ; next command
    b       -
    nop

texscale:
; get the coordinate and scale data
    andi    s1, t1, 0xFFF ; get bottom right y
    srl     t3, t1, 12
    andi    s0, t3, 0xFFF ; get bottom right x
    lw      t1, -4(t0) ; load second word of E4 command
    andi    s3, t1, 0xFFF ; get top right y
    srl     t3, t1, 12
    andi    s2, t3, 0xFFF ; get top right x
    lw      t1, 0xC(t0) ; load second word of F1 command
                         ; (last word of E4 command chain)
    andi    s5, t1, 0xFFFF ; get y scale
    srl     t3, t1, 16
    andi    s4, t3, 0xFFFF ; get x scale

; scale coordinates
    jal     scale_xy
    mov     a0, s0
    mov     s0, v0
    jal     scale_xy
    mov     a0, s2
    mov     s2, v0

; scale pixel steps
    jal     scale_step
    mov     a0, s4
    mov     s4, v0

; reconstruct commands
    li      t9, 0xE4000000
    sll     t3, s0, 12
    or      t1, t9, s1
    or      t1, t1, t3
    sw      t1, -8(t0)
;
    lw      t1, -4(t0)
    srl     t1, t1, 24 ; clear the lower 3 bytes
    sll     t1, t1, 24
    sll     t3, s2, 12
    or      t1, t3, s3
    or      t1, t1, t3
    sw      t1, -4(t0)
;
    sll     t1, s4, 16
    or      t1, t1, s5
    sw      t1, 0xC(t0)
    b       -
    addiu   t0, t0, 0x10 ; next two commands

screen_dim: ; handle screen dimensions for A Button, beating heart, map icons
    lw      t1, 4(t0)
    lw      t4, 0(t1)
    li      t9, 0x005A005A ; probably the A button, we want it to be 0x0044
    beq     t4, t9, abutt
    li      t9, 0x028001E0 ; general screen stuff
    ; FIXME: this causes the "jiggling" effect.
    ;        we need to be more picky about which structs we modify.
    beq     t4, t9, general
    nop
    sw      t4, debug
    b       next
    nop
abutt:
    li      t9, 0x0044005A
    sw      t9, 0(t1)
    li      t9, 0x0312007E ; FIXME: clips left side of button
    sw      t9, 8(t1)
    b       next
    nop
general:
    li      t9, 0x01E001E0
    b       next
    sw      t9, 0(t1)
next:
    b       -
    addiu   t0, t0, 8 ; next command

finish:
    jpop    4, 1, s0, s1, s2, s3, s4, s5, ra

.align 4
    .word 0xDEADBEEF
debug:
    .word 0
    .word 0
    .word 0xDEADBEEF

scale_xy:
    li      at, 0x3F400000 ; 0.75f
    mtc1    a0, f30 ; note: we blindly assume f30 is fine to overwrite here
    mtc1    at, f31 ; likewise
    cvt.s.w f30, f30
    mul.s   f30, f30, f31
    nop
    trunc.w.s f31, f30
    mfc1    v0, f31
    ; TODO: add before truncation? (proper rounding etc.)
    addiu   v0, v0, 0xA0 ; round((((240 * 16 / 9. - 320) / 2.) * 0.75) * 4)
    jr
    andi    v0, v0, 0xFFF

scale_step:
    li      at, 0x3FAAAAAB ; 1.3333334f
    mtc1    a0, f30 ; note: we blindly assume f30 is fine to overwrite here
    mtc1    at, f31 ; likewise
    cvt.s.w f30, f30
    mul.s   f30, f30, f31
    nop
    trunc.w.s f31, f30
    mfc1    v0, f31
    jr
    andi    v0, v0, 0xFFFF

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
