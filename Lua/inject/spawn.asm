[actor_spawn]: 0x800BAE14

[global_context]: 0x803E6B20
[buttons_offset]: 0x14
[actor_spawn_offset]: 0x1CA0

[button_mask]: 0x0020
[actor_to_spawn]: 0x0009

        push    4, ra
        li      t0, @global_context
        lhu     t2, @buttons_offset(t0)
        andi    t2, t2, @button_mask
        beq     t2, r0, return
        nop
        li      a0, @actor_to_spawn
        bal     simple_spawn
        nop
return:
        jpop    4, ra

simple_spawn: // args: a0 (actor to spawn)
        push    4, 9, ra
        mov     a2, a0
        li      a1, @global_context
        addi    a0, a1, @actor_spawn_offset
        cl      a3 // unknown
        mtc1    r0, F4 // X position?
        mtc1    r0, F8 // Y position?
        mtc1    r0, F16 // Z position?
        // load up the rest of the args
        sw      r0, 0x10(sp) // unknown
        sw      r0, 0x14(sp) // X, Y rotations?
        sw      r0, 0x18(sp) // Z rotation?
        sw      r0, 0x1C(sp) // unknown
        sw      r0, 0x20(sp) // unknown
        sw      r0, 0x24(sp) // object number?
        li      t0, 0x0000007F
        sw      t0, 0x28(sp) // unknown
        li      t0, 0x000003FF
        sw      t0, 0x2C(sp) // unknown
        sw      r0, 0x30(sp) // unknown
        // and finally..
        jal     @actor_spawn
        nop
        jpop    4, 9, ra
