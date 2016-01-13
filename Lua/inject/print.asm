// translates calls to 800021F8
// to copy strings to memory instead
// for Lua to later pick up on

[global_context]: 0x80212020

// offset from first pointer in global context
[dlist_offset]: 0x2C0

[SetTextRGBA]:      0x800FB3AC
[SetTextXY]:        0x800FB41C
[SetTextString]:    0x800FBCB4
[TxtPrinter]:       0x800FBB60
[InitTxtStruct]:    0x800FBB8C // unused here; we set it up inline
[DoTxtStruct]:      0x800FBC1C
[UpdateTxtStruct]:  0x800FBC64

[ObjectSpawn]: 0x80097C00
[ObjectIndex]: 0x8009812C

    push    4, 1, ra
// draw some nonsense text
    li      a0, 0x00010001 // xy
    li      a1, 0x88CCFFFF // rgba
    la      a2, fmt
    la      a3, buffer
    jal     simple_text
    nop
// reset buffer position in our per-frame hook
    la      t0, buffer
    sw      t0, buffer_pos
// and set the string to null
    sb      r0, 0(t0)
    jpop    4, 1, ra

fmt:
    .asciiz "%s"
.align
str:
    .asciiz "hey"
.align

.include "simple text.asm"

ObjectSpawnWrap:
    // keep track of which objects we're spawning
    // TODO: reset count on scene change
    push    4, ra, 1

    // stuff for jump-only hook
    //li      a0, 0x802237C4
    //mov     a1, a3

    //beqi    a1, 2, + // don't bother loading gameplay_field_keep
    lwu     t0, spawn_count
    sll     t2, t0, 1
    la      t1, spawned
    addu    t1, t1, t2
    addiu   t0, t0, 1
    sw      t0, spawn_count
    sh      a1, 0(t1)
    jal     @ObjectSpawn
    nop
+:
    jpop    4, ra, 1
spawn_count:
    .word 0
spawned:
    .halfword 0, 0, 0, 0, 0, 0, 0, 0

// keep track of where we are in the buffer
buffer_pos:
    .word 0

.align 4
buffer:
    .skip 0x3000

// overwrite (not hook) the debug printing function
.org 0x800021B0
    // a0: unknown
    // a1: char *msg
    // a2: size_t len
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
    jr
    nop

// force objects to load

/* jump-only hook
.org 0x80098180
    j       ObjectSpawnWrap
    nop
*/

.org @ObjectIndex
    // we have space for 22 instructions
    push    4, ra, 1
    //sll     a1, a1, 0x10
    //sra     a1, a1, 0x10
    mov     t0, a0
    lbu     t1, 8(a0) // remaining items
    cl      v0
-:
    lh      t2, 12(t0) // item's object number
    // t2 = abs(t2)
    bgez    t2, +
    nop
    subu    t2, r0, t2
+:
    beq     a1, t2, +
    subi    t1, t1, 1
    addiu   v0, v0, 1
    addi    t0, t0, 68
    bnez    t1, -
    nop
    jal     ObjectSpawnWrap
    nop
    //subiu   v0, r0, -1
+:
    jpop    4, ra, 1
    // 19 words
