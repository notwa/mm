textdata:
    .word 0, 0, 0, 0, 0
simple_text:
    // a0: xxxxyyyy
    // a1: rrggbbaa
    // a2: printf formatting string
    // a3: first argument for format string (optional)
    // TODO: support more than 4 args
    push    4, 1, s0, s1, ra

    la      s0, textdata

    sw      a0, 32(sp)
    sw      a1, 36(sp)
    sw      a2, 40(sp)
    sw      a3, 44(sp)

    li      t0, @TxtPrinter
    sw      t0, 0(s0) // printer
    sw      r0, 4(s0) // dlist end
    sh      r0, 8(s0) // x
    sh      r0, 10(s0) // y
    li      t0, 0xC
    sw      t0, 12(s0) // unknown
    sw      r0, 16(s0) // color

    li      t0, @global_context
    lw      s1, 0(t0)
    lw      t2, @dlist_offset(s1)

    mov     a0, s0
    mov     a1, t2
    jal     @DoTxtStruct
    nop

    lbu     a1, 36(sp)
    lbu     a2, 37(sp)
    lbu     a3, 38(sp)
    lbu     t1, 39(sp)
    sw      t1, 0x10(sp)
    jal     @SetTextRGBA
    mov     a0, s0

    lh      a1, 32(sp)
    lh      a2, 34(sp)
    jal     @SetTextXY
    mov     a0, s0

    lw      a1, 40(sp)
    lw      a2, 44(sp)
    jal     @SetTextString
    mov     a0, s0

    mov     a0, s0
    jal     @UpdateTxtStruct
    nop

    sw      v0, @dlist_offset(s1)

    jpop    4, 1, s0, s1, ra

