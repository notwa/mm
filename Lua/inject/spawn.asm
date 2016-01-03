[button_L]: 0x0020
[button_D_right]: 0x0100
[button_D_left]: 0x0200
[button_D_down]: 0x0400
[button_D_up]: 0x0800
[button_any]: 0x0F20

[hold_delay_amount]: 3

    push    4, s1, ra
    li      t0, @link_save
    li      t1, @global_context
// give max rupee upgrade (set bit 13, clear bit 12 of lower halfword)
    lhu     t2, @upgrades_2_offset(t0)
    ori     t2, t2, 0x2000
    andi    t2, t2, 0xEFFF
    sh      t2, @upgrades_2_offset(t0)
//
    lhu     t2, @buttons_offset(t1)
    lhu     t9, @rupees_offset(t0)
    lw      s1, hold_delay
    andi    t4, t2, @button_any
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
    andi    t3, t2, @button_D_right
    beqz    t3, +
    nop
    addi    t9, t9, 1
+:
    andi    t3, t2, @button_D_left
    beqz    t3, +
    nop
    subi    t9, t9, 1
+:
    andi    t3, t2, @button_D_up
    beqz    t3, +
    nop
    addi    t9, t9, 10
+:
    andi    t3, t2, @button_D_down
    beqz    t3, +
    nop
    subi    t9, t9, 10
+:
    subi    t4, t9, 1
    bgez    t4, +
    nop
    li      t9, @max_actor_no
+:
    subi    t4, t9, @max_actor_no
    blez    t4, +
    nop
    li      t9, 1
+:
    sh      t9, @rupees_offset(t0)
    andi    t3, t2, @button_L
    beqz    t3, return
    nop
    mov     a0, t9
    bal     simple_spawn
    nop
return:
    sw      s1, hold_delay
    jpop    4, s1, ra

simple_spawn: // args: a0 (actor to spawn)
    push    4, 9, ra
    mov     a2, a0
    li      a1, @global_context
    addi    a0, a1, @actor_spawn_offset
    li      t0, @link_actor
    lw      t1, @actor_x(t0)
    lw      t2, @actor_y(t0)
    lw      t3, @actor_z(t0)
    mov     a3, t1 // X position
    sw      t2, 0x10(sp) // Y position
    sw      t3, 0x14(sp) // Z position

    li      t9, 0x0
    sw      t9, 0x18(sp) // rotation?
    lhu     t7, @actor_horiz_angle(t0)
    sw      t7, 0x1C(sp) // horizontal rotation
    li      t9, 0x0
    sw      t9, 0x20(sp) // rotation?

//  lhu     t7, @actor_horiz_angle(t0)
    li      t7, 0
    sw      t7, 0x24(sp) // actor variable

    li      t9, 0x0000007F
    sw      t9, 0x28(sp) // unknown
    li      t9, 0x000003FF
    sw      t9, 0x2C(sp) // unknown
    li      t9, 0x00000000
    sw      t9, 0x30(sp) // unknown
    jal     @actor_spawn
    nop
    jpop    4, 9, ra

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
