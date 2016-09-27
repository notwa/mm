[button_L]: 0x0020
[button_R]: 0x0010
[button_any]: 0x0F20

[min_actor_no]: 0

[hold_delay_amount]: 3

spawn:
    push    4, s0, s1, s2, s3, s4, ra,
    li      t1, @global_context
    lhu     s0, anum
    lw      s1, hold_delay
    lhu     s2, @buttons_offset(t1)
    lhu     s3, avar
    lw      s4, selected
// set selected
//  andi    t2, s2, @button_R
    srl     s4, s2, 4
    andi    s4, 1
// handle hold delay
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
+: // handle dpad
    bnez    s4, +
    mov     a1, s2
    call    dpad_control, s0, a1
    mov     s0, v0
    b       ++
    nop
+:
    call    dpad_control, s3, a1
    andi    s3, v0, 0xFFFF
+: // set min/max on actor number
    subi    t4, s0, @min_actor_no
    bgez    t4, +
    nop
    li      s0, @max_actor_no
+:
    subi    t4, s0, @max_actor_no
    blez    t4, +
    nop
    li      s0, @min_actor_no
+: // spawn
    andi    t3, s2, @button_L
    beqz    t3, return
    nop
    mov     a0, s0
    mov     a1, s3
    bal     simple_spawn
    nop
return:
// render actor number
    call    simple_text, 0x0001001C, 0x88CCFFFF, fmt, s0
// render actor variable
    call    simple_text, 0x0006001C, 0xFFCC88FF, fmt, s3
// done
    sh      s0, anum
    sw      s1, hold_delay
    sh      s3, avar
    sw      s4, selected
    ret     4, s0, s1, s2, s3, s4, ra,

.word 0xDEADBEEF
.word textdata

anum:
    .word 0
avar:
    .word 0
selected:
    .word 0

fmt:
    .asciiz "%04X"
.align

/* old version that didn't account for negative arguments
object_index_hook:
    push    4, 1, ra
    mov     t0, a0
    lbu     t1, 8(a0) // remaining items
    cl      v0
    sll     a1, 0x10
    sra     a1, 0x10
    abs     a1
-:
    lhu     t2, 12(t0) // item's object number
    abs     t2
    beq     a1, t2, +
    subi    t1, 1
    addiu   v0, 1
    bnez    t1, -
    addi    t0, 68
    call    @object_spawn, a0, a1
;   subiu   v0, r0, -1 // original code
+:
    ret     4, 1, ra
*/

; based on game code
object_index_hook:
    // a0: object table
    // a1: object number
    sll     t1, a1, 0x10
    sra     t1, 0x10
    lbu     t3, 8(a0)
    cl      v0
    mov     t2, a0
    blez    t3, +give_up ; interesting: give up if object number read is <= 0
-:
    lh      t0, 12(t2)
    abs     t0
    bne     t0, t1, +
    nop
    jr      ra
    nop
+:
    addiu   v0, 1
    blt     v0, t3, - ; if we still have some left... v0 is number of objects
    addiu   t2, 68
+give_up:
;   ; dump failed object number to ram
;   la      t0, DEBUG
;   lw      t2, (t0)
;   addiu   t2, 1
;   sw      t2, (t0)
;   sll     t1, t2, 2
;   addu    t1, t0
;   sw      a1, (t1)
;   beqi    t2, 2, +
    push    4, s0, s1, 1, ra
    mov     s1, a0
    lbu     s0, 9(s1)
    call    @object_spawn, a0, a1
    sb      s0, 9(s1)
    ret     4, s0, s1, 1, ra
+:
    jr
    li      v0, -1

/*
.word 0xDEADBEEF
DEBUG:
.skip 0x100 0
*/

.include "dpad control.asm"
.include "simple spawn.asm"
.include "simple text.asm"

hold_delay:
    .word 0

.org @object_index
    // a0: object table
    // a1: object number
    // we have space for 22 instructions (on debug, 23 on 1.0?)
    j       object_index_hook
    nop
