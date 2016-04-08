; oot debug rom
; mess with display lists
; game note: #2 jumps to #3 which jumps to #1 which calls pieces of #2
;            what a mess

[ctxt]: 0x80212020
[dlists]: 0x80168930

    push    4, 1, s0, s1, s2, s3, s4, s5, ra

; time for dlist misuse
    li      t0, @dlists
    lw      t0, 0x04(t0) ; HUD display list start
    cl      t2 ; iteration count

; DEBUG
/*
;; kill an entire display list by ending it immediately
;    li      t9, 0xE9000000
;    sw      t9, 0(t0)
;    sw      r0, 4(t0)
;    li      t9, 0xDF000000
;    sw      t9, 8(t0)
;    sw      r0, 0xC(t0)
;    b       finish ; DEBUG
;    nop

; nop certain command types
    cl      t2 ; iteration count
    cl      t3 ; functions overwritten
[nop_target]: 256
-:
    bgei    t2, 0x1000, + ; give up after a while
    addiu   t2, t2, 1
    bgei    t3, @nop_target, + ; stop after this many commands nop'd
    nop
    lw      t1, (t0) ; load command
    li      t9, 0xDF000000
    beq     t1, t9, + ; stop if we're at the end of the display list
    li      t9, 0xDE000000 ; check if it's a call
;   li      t9, 0xDC080008 ; sets the video resolution and whatnot
    bne     t1, t9, -
    addiu   t0, t0, 8 ; next command
    sw      r0, -8(t0) ; nop the last command
    sw      r0, -4(t0)
    b       -
    addiu   t3, t3, 1
+:
    jpop    4, 1, s0, s1, s2, s3, s4, s5, ra
*/

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
; DEBUG
/*
; nop an entire 2d texture draw command sequence
    sw      r0, -8(t0)
    sw      r0, -4(t0)
    sw      r0, 0(t0)
    sw      r0, 4(t0)
    sw      r0, 8(t0)
    sw      r0, 0xC(t0)
    addiu   t0, t0, 0x10 ; next 2 commands
    b       -
    nop
*/

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
/* NOTES:
1C4164
heart/map matrix DA380007 801BEBA0
a button matrix DA380007 801BF0D0 (thereabouts)
search for DC080008
a button sometimes: 1CFD60?
0342007E 01FF0000
DC080008 801CFD60
*/
    lw      t1, 4(t0)
    lw      t4, 0(t1)
    li      t9, 0x005A005A ; probably the A button, we want it to be 0x0044
    beq     t4, t9, abutt
    li      t9, 0x028001E0 ; general screen stuff
    beq     t4, t9, general
    nop
    sw      t4, debug
;    b       desperate
;    nop
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
;desperate:
;    li      t9, 0x00200020
;    b       next
;    sw      t9, 0(t1)
next:
    b       -
    addiu   t0, t0, 8 ; next command

finish:
    jpop    4, 1, s0, s1, s2, s3, s4, s5, ra
    nop

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
.org 0x800AAB90
    li      t3, @res2_B ; 240B00D2
    li      t4, @res2_T ; 240C001E
.org 0x800AABA8
    li      t1, @res2_R ; 24090140
    li      t2, @res2_L ; 240A0000
