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
    bne     t4, r0, +
    addi    s1, s1, 1
    li      s1, 0
+:
    subi    t4, s1, 1
    beq     t4, r0, +
    nop
    subi    t4, s1, @hold_delay_amount
    bltz    t4, return
    nop
+:
    andi    t3, t2, @button_D_up
    beq     t3, r0, +
    nop
    addi    t9, t9, 1
+:
    andi    t3, t2, @button_D_down
    beq     t3, r0, +
    nop
    subi    t9, t9, 1
+:
    andi    t3, t2, @button_D_right
    beq     t3, r0, +
    nop
    addi    t9, t9, 10
+:
    andi    t3, t2, @button_D_left
    beq     t3, r0, +
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
    beq     t3, r0, return
    nop
    mov     a0, t9
    bal     simple_spawn
    nop
return:
    sw      s1, hold_delay
    jpop    4, s1, ra

simple_spawn: // args: a0 (actor to spawn)
    push    4, 9, ra
    jal     load_object
    sw      a0, 56(sp) // keep me updated!
    bne     v0, r0, simple_spawn_return
    lw      a2, 56(sp) // keep me updated!
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
simple_spawn_return:
    jpop    4, 9, ra

hold_delay:
    .word 0

load_object:
// args: a0 (actor number)
// returns v0 (0 if ok, 1 on error)
    push    4, s0, ra
    li      v0, 1
    la      t0, actor_object_table
    sll     t1, a0, 1
    addu    t0, t0, t1
    lhu     s0, 0(t0) // object number
    beq     s0, r0, +
    nop
    bal     is_object_loaded
    mov     a0, s0
    bne     v0, r0, +
    cl      v0
    li      t8, @global_context
    li      t9, @object_spawn_offset
    add     a0, t8, t9
    mov     a1, s0
    jal     @object_spawn
    nop
+:
    jpop    4, s0, ra

/*
we'll be dealing with structs like
typedef struct {
    uint_ptr region_start; // ?
    uint_ptr region_end;   // ?
    byte loaded_count;     // only set in first item
    byte loaded_count_alt; // usually fewer than the above
    uint16 unknown;
    uint16 object_number;
    uint16 padding;
    uint_ptr start;
    uint32 size;
    uint32 unknowns[11]; // more pointers and sizes
} loaded_object; // total size: 68 bytes
*/

is_object_loaded:
// args: a0 (object number)
// returns v0 (1 if loaded, 0 if not)
    push    4
    li      t8, @global_context
    li      t9, @object_spawn_offset
    add     t0, t8, t9 // current item
    lb      t1, 8(t0) // remaining items
    li      v0, 1
-:
    lh      t2, 12(t0) // item's object number
    beq     a0, t2, +
    subi    t1, t1, 1 // TODO: double check there's no off-by-one error
    addi    t0, t0, 68
    bne     t1, r0, -
    nop
    cl      v0
+:
    jpop    4
