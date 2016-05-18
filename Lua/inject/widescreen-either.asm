start:
    push    4, 1, ra

; time for dlist misuse
; TODO: check if the game has even loaded yet
    li      t0, @dlists
    jal     adjust_dlist
    lw      a0, 4(t0) ; HUD display list start

    ret     4, 1, ra

adjust_dlist:
    ; args: pointer to start of dlist
    push    4, s0, s1, s2, s3, s4, s5, s6, s7, s8, ra
    cl      s7 ; iteration count
    mov     s8, a0

-:
    bgei    s7, 0x1000, +return ; give up after a while
    addiu   s7, s7, 1
    lw      t1, 0(s8) ; load a command
    li      t9, 0xDF000000
    beq     t1, t9, +return ; stop if we're at the end of the display list
    li      t9, 0xDE010000
    beq     t1, t9, +return ; jumps count as ends too
    li      t9, 0xDC080008
    beq     t1, t9, screen_dim ; check if these are screen dimensions
    li      t9, 0xFF000000
    and     t3, t1, t9
    li      t9, 0xE4000000
    beq     t3, t9, texscale ; check if this is a 2D texture
    li      t9, 0xED000000
    beq     t3, t9, setscissor ; check if... yeah
    li      t9, 0xDE000000
    beq     t3, t9, recurse ; check if this is a "call" and recurse into it
    nop
next:
    b       -
    addiu   s8, s8, 8 ; next command

; FIXME:
; don't recurse into the pause menu background
; jiggle jiggle
recurse:
    lw      a0, 4(s8)
    li      t9, 0xFF000000
    and     t3, a0, t9
    li      t9, 0x80000000
    ; only follow this if it's a pointer (not a bank offset!)
    bne     t3, t9, next
    nop
    sw      a0, debug
    call    adjust_dlist, a0
    b       next
    nop

texscale:
    addiu   s8, s8, 8 ; next command
; get the coordinate and scale data
    andi    s1, t1, 0xFFF ; get bottom right y
    srl     t3, t1, 12
    andi    s0, t3, 0xFFF ; get bottom right x
    lw      t1, -4(s8) ; load second word of E4 command
    andi    s3, t1, 0xFFF ; get top right y
    srl     t3, t1, 12
    andi    s2, t3, 0xFFF ; get top right x
    lw      t1, 0xC(s8) ; load second word of F1 command
                         ; (last word of E4 command chain)
    andi    s5, t1, 0xFFFF ; get y scale
    srl     t3, t1, 16
    andi    s4, t3, 0xFFFF ; get x scale

; scale coordinates
    call    scale_xy, s0
    mov     s0, v0
    call    scale_xy, s2
    mov     s2, v0

; scale pixel steps
    call    scale_step, s4
    mov     s4, v0

; reconstruct commands
    li      t9, 0xE4000000
    sll     t3, s0, 12
    or      t1, t9, s1
    or      t1, t1, t3
    sw      t1, -8(s8)
;
    lw      t1, -4(s8)
    srl     t1, t1, 24 ; clear the lower 3 bytes
    sll     t1, t1, 24
    sll     t3, s2, 12
    or      t1, t3, s3
    or      t1, t1, t3
    sw      t1, -4(s8)
;
    sll     t1, s4, 16
    or      t1, t1, s5
    sw      t1, 0xC(s8)
    b       -
    addiu   s8, s8, 0x10 ; next two commands

screen_dim: ; handle screen dimensions for A Button, beating heart, map icons
    lw      t1, 4(s8)
    lw      t4, 0(t1)
    li      t9, 0x005A005A ; probably the A button, we want it to be 0x0044
    beq     t4, t9, abutt
    li      t9, 0x028001E0 ; general screen stuff
    ; FIXME: this causes the "jiggling" effect.
    ;        we need to be more picky about which structs we modify.
    beq     t4, t9, general
    nop
;   sw      t4, debug
    b       next
    nop
abutt:
    li      t9, 0x0044005A
    sw      t9, 0(t1)
    li      t9, 0x0312007E
    sw      t9, 8(t1)
    b       next
    nop
general:
    li      t9, 0x01E001E0
    b       next
    sw      t9, 0(t1)

setscissor:
    lw      t1, 0(s8)
    lw      t3, 4(s8)
; change setscissor of A Button
;       from ED2E8024 0039C0D8
;        to  ED2B8024 0036C0D8
; TODO: just calculate this dynamically
    li      t9, 0xED2E8024
    bne     t1, t9, next
    li      t9, 0xED2B8024
    sw      t9, 0(s8)
    li      t9, 0x0039C0D8
    b       next
    sw      t9, 4(s8)

;8008A8F8 sets up a button/text matrix?
; call at 8008B684 sets up matrix/viewport for A button
; 80168938 end of HUD dlist
;802114C4
;80167FB0

+return:
    ret     4, s0, s1, s2, s3, s4, s5, s6, s7, s8, ra

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
