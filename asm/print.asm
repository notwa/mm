// translates calls to 800021F8
// to copy strings to memory instead
// for Lua to later pick up on

    jr
    nop
/*
[global_context]: 0x80212020

// offset from first pointer in global context
[dlist_offset]: 0x2B0

[SetTextRGBA]:      0x800FB3AC
[SetTextXY]:        0x800FB41C
[SetTextString]:    0x800FBCB4
[TxtPrinter]:       0x800FBB60
[InitTxtStruct]:    0x800FBB8C ; unused here; we set it up inline
[DoTxtStruct]:      0x800FBC1C
[UpdateTxtStruct]:  0x800FBC64
    push    4, 1, ra
// draw the debug text
    li      a0, 0x00010001 // xy
    li      a1, 0x88CCFFFF // rgba
    la      a2, fmt
    la      a3, buffer
    jal     simple_text
    nop
// reset buffer position
    la      t0, buffer
    sw      t0, buffer_pos
// and set the string to null
    sb      r0, 0(t0)
    ret     4, 1, ra

fmt:
    .asciiz "%s"
.align

.include "simple text.asm"
*/

// keep track of where we are in the buffer
.org 0x807006F8
buffer_pos:
    .word buffer

buffer_lock:
    .word 0

//.align 4
buffer:
    .skip 0x3000

// force a crash-like thing that dumps a ton of (RDP?) info:
//.org 0x800C5E78
//    li t8, 0x29a

// overwrite (not hook) the debug printing function
.org 0x800021B0
    // a0: unknown
    // a1: char *msg
    // a2: size_t len
    li      t0, 1
    sw      t0, buffer_lock
    lw      t0, buffer_pos
copy_loop:
    lb      t1, 0(a1)
    sb      t1, 0(t0)
    addi    t0, t0, 1
    addi    a1, a1, 1
    subi    a2, a2, 1
    bne     a2, r0, copy_loop
    sb      r0, 0(t0) // null terminate
    sw      t0, buffer_pos
    sw      r0, buffer_lock
    jr
    nop
