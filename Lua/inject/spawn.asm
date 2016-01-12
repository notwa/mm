[button_L]: 0x0020
[button_D_right]: 0x0100
[button_D_left]: 0x0200
[button_D_down]: 0x0400
[button_D_up]: 0x0800
[button_any]: 0x0F20

[hold_delay_amount]: 3

    push    4, s0, s1, s2, ra
    li      t0, @link_save
    li      t1, @global_context
    lhu     s2, @buttons_offset(t1)
    lhu     s0, anum
    lw      s1, hold_delay
    andi    t4, s2, @button_any
    bnez    t4, +
    addi    s1, s1, 1
    li      s1, 0
+:
    beqi    s1, 1, +
    nop
    subi    t4, s1, @hold_delay_amount
    bltz    t4, return
    nop
+:
    mov     a0, s0
    jal     dpad_control
    mov     a1, s2
    mov     s0, v0

    subi    t4, s0, 1
    bgez    t4, +
    nop
    li      s0, @max_actor_no
+:
    subi    t4, s0, @max_actor_no
    blez    t4, +
    nop
    li      s0, 1
+:
    sh      s0, anum
    andi    t3, s2, @button_L
    beqz    t3, return
    nop
    mov     a0, s0
    lhu     a1, avar
    bal     simple_spawn
    nop
return:
    sw      s1, hold_delay
// render actor number
    li      a0, 0x0001001C // xy
    li      a1, 0x88CCFFFF // rgba
    la      a2, fmt
    mov     a3, s0
    jal     simple_text
    nop
// render actor variable
    li      a0, 0x0006001C // xy
    li      a1, 0xFFCC88FF // rgba
    la      a2, fmt
    lhu     a3, avar
    jal     simple_text
    nop
    jpop    4, s0, s1, s2, ra

anum:
    .word 0
avar:
    .word 0

fmt:
    .byte 0x25,0x30,0x34,0x58,0x00 // %04X
.align

.include "dpad control.asm"
.include "simple spawn.asm"
.include "simple text.asm"

hold_delay:
    .word 0

.org @object_index
    // we have space for 22 instructions (on debug, 23 on 1.0?)
    push    4, ra, 1
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
    // NOTE: this allows object 0002 to load in places it's not meant to.
    // this can mess up door graphics (among other things?)
    jal     @object_spawn
    nop
    //subiu   v0, r0, -1 // original code
+:
    jpop    4, ra, 1
