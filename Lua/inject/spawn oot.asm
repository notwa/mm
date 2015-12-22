[actor_spawn]: 0x80025110
[object_spawn]: 0x800812F0
[max_actor_no]: 0x1D6

[global_context]: 0x801C84A0
[buttons_offset]: 0x14
[actor_spawn_offset]: 0x1C24
[object_spawn_offset]: 0x117A4

[link_actor]: 0x801DAA30
[actor_x]: 0x24
[actor_y]: 0x28
[actor_z]: 0x2C
[actor_horiz_angle]: 0x46

[link_save]: 0x8011A5D0
[rupees_offset]: 0x34
[upgrades_offset]: 0xA0
[upgrades_2_offset]: 0xA2

.include "spawn.asm"

actor_object_table:
.include "actor object table oot.asm"

load_object:
// args: a0 (actor number)
// returns v0 (0 if ok, 1 on error)
        push    4, s0, ra
        li      v0, 1
        la      t0, actor_object_table
        sll     t1, a0, 1
        addu    t0, t0, t1
        lhu     s0, 0(t0) // object number
        beq     s0, r0, load_object_return
        nop
        bal     is_object_loaded
        mov     a0, s0
        bne     v0, r0, load_object_return
        cl      v0
        li      t8, @global_context
        li      t9, @object_spawn_offset
        add     a0, t8, t9
        mov     a1, s0
        jal     @object_spawn
        nop
load_object_return:
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
is_object_loaded_loop:
        lh      t2, 12(t0) // item's object number
        beq     a0, t2, is_object_loaded_return
        subi    t1, t1, 1 // TODO: double check there's no off-by-one error
        addi    t0, t0, 68
        bne     t1, r0, is_object_loaded_loop
        nop
        cl      v0
is_object_loaded_return:
        jpop    4
