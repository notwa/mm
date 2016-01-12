simple_spawn:
    // a0: actor number
    // a1: actor variable
    push    4, 9, ra
    mov     a2, a0
    mov     t4, a1
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

    sw      t4, 0x24(sp) // actor variable

    li      t9, 0x0000007F
    sw      t9, 0x28(sp) // unknown
    li      t9, 0x000003FF
    sw      t9, 0x2C(sp) // spawn time? (probably MM only)
    li      t9, 0x00000000
    sw      t9, 0x30(sp) // unknown
    jal     @actor_spawn
    nop
    jpop    4, 9, ra
