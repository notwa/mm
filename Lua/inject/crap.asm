// bomb tornado
// originally written by RainingChain in Lua
// rewritten in assembly by notwa

[global_context]: 0x803E6B20
[link_actor]: 0x803FFDB0

[actorlist_offset]: 0x1CB0
[actorlist_dead_space]: 0x4

[actor_x]: 0x24
[actor_y]: 0x28
[actor_z]: 0x2C
[actor_prev]: 0x128
[actor_next]: 0x12C
[actor_bomb_timer]: 0x1F1

[at_bomb]: 0x0009

[rotate_amount]: 0x3E567750 // pi/15

// F12 = input (single), F0 = output (single), F4 = output (double)
[sinf]: 0x80088350
[cosf]: 0x80091F40

main:
        push    4, s1, s3, s4, ra
        // s1: current actor ptr
        // s3: current actor type ptr
        // s4: current actor type index
        li      t0, @global_context
        addi    s3, t0, @actorlist_offset
        li      s4, 0

// update rotations
        la      t0, rotations
        li      t2, @rotate_amount
        li      t9, 0
rotate_loop:
        lw      t1, 0(t0)
        mtc1    t1, F0
        mtc1    t2, F1
        add.s   F0, F0, F1
        mfc1    t1, F0
        sw      t1, 0(t0)
        addi    t0, t0, 4
        addi    t9, t9, 1
        li      at, 6
        bne     t9, at, rotate_loop
        nop
        la      t0, rotations
        sw      t0, current_rotation

typeloop:
        addi    s3, s3, 4 // skip over count
        lw      s1, 0(s3)

        beq     s1, r0, continue
listloop:
        mov     a0, s1
        bal     process_actor
        lw      s1, @actor_next(s1)
        bne     s1, r0, listloop
        nop

continue:
        addi    s3, s3, 4
        addi    s4, s4, 1
        li      t0, 12
        bne     s4, t0, typeloop
        addi    s3, s3, @actorlist_dead_space

        jpop    4, s1, s3, s4, ra

process_actor: // args: a0. returns nothing.
        // TODO: ignore bomb explosions, they share the same type
        push    4, s0, s1, ra
        // s0: result of sin
        // s1: result of cos
        lh      t0, 0(a0)
        subiu   t0, t0, @at_bomb
        bne     t0, r0, process_actor_return
        nop
        li      t0, 0x45
        sb      t0, @actor_bomb_timer(a0)

        lw      t5, current_rotation
        lw      t5, 0(t5)
        jal     @sinf
        mtc1    t5, F12
        mfc1    s0, F0

        lw      t5, current_rotation
        lw      t5, 0(t5)
        jal     @cosf
        mtc1    t5, F12
        mfc1    s1, F0

        li      t1, @link_actor
        lw      t2, @actor_x(t1)
        lw      t3, @actor_y(t1)
        lw      t4, @actor_z(t1)

        li      t0, 0x42960000 // 75
        mtc1    t0, F2

        // process X
        mtc1    s0, F0
        mtc1    t2, F1
        mul.s   F0, F0, F2
        add.s   F0, F0, F1
        mfc1    t2, F0

        // process Z
        mtc1    s1, F0
        mtc1    t4, F1
        mul.s   F0, F0, F2
        add.s   F0, F0, F1
        mfc1    t4, F0

        sw      t2, @actor_x(a0)
        sw      t3, @actor_y(a0)
        sw      t4, @actor_z(a0)

        lw      t5, current_rotation
        addi    t5, t5, 4
        sw      t5, current_rotation

process_actor_return:
        jpop    4, s0, s1, ra

rotations:
        .word 0x00000000 // pi*0/6
        .word 0x40060a92 // pi*4/6
        .word 0x40860a92 // pi*8/6
        .word 0x40c90fdb // pi*12/6
        .word 0x41060a92 // pi*16/6
        .word 0x41278d36 // pi*20/6

current_rotation:
        .word 0
