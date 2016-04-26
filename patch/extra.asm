    .word   0xDEADBEEF
whatever: ; debugging stuff
    .word   0

.include "common.asm"

hash:
tunic_color:
    .word   0xFFFFFFFF

old_exit:
    .half   0
new_exit:
    .half   0
.align

rng_seed:
    .word   0

.include "entrances.asm"
.include "crc32.asm"

dma_hook:
    push    4, 1, ra
    jal     setup_hook
    nop
    pop     4, 1, ra
    addiu   sp, 0xFF58 ; original code
    j       0x8016A2D0 ; return to scene setup function
    sw      s1, 0x30(sp) ; original code

set_scene_flag:
    ; a0: scene number
    ; a1: scene word (0-4)
    ; a2: bit to set (0-31)
    ; v0: new scene flag word
    li      t0, @link_save
    addiu   t1, t0, @scene_flags_ingame
    li      t2, @scene_record_size
    multu   a0, t2
    mflo    t2
    addu    t3, t1, t2
    sll     t4, a1, 2 ; t4 = a1*sizeof(word)
    addu    t3, t4
    lw      v0, (t3) ; load scene flag word
    li      t6, 1
    sllv    t6, a2
    or      v0, t6 ; set flag
    jr
    sw      v0, (t3) ; write it back

get_event_flag:
    ; a0: event flag offset
    ; a1: byte offset
    ; a2: bit to set (0-7)
    ; v0: 1 if set, else 0
    li      t0, @link_save
    addu    t1, t0, a0
    addu    t2, t1, a1
    lb      v0, (t2)
    li      t6, 1
    sllv    t6, a2
    and     v0, t6
    beqz    v0, +
    cl      v0
    li      v0, 1
+:
    jr
    nop

set_event_flag:
    ; a0: event flag offset
    ; a1: byte offset
    ; a2: bit to set (0-7)
    ; v0: new event flag value
    li      t0, @link_save
    addu    t1, t0, a0
    addu    t2, t1, a1
    lb      v0, (t2)
    li      t6, 1
    sllv    t6, a2
    or      v0, t6
    jr
    sb      v0, (t2)

tunic_color_hook:
    ; copypasta from CloudMax's old hack
    ; registers available for use without blowing up: at, t3, t4, a0
    lw      t3, @link_object_ptr
    lui     t4, 0x0001
    sub     t3, t3, t4 ; t3 -= 0x10000
    lw      t4, tunic_color
    sw      t4, 0xF184(t3)
    sw      t4, 0xEFFC(t3)
    sw      t4, 0xECB4(t3)
    sw      t4, 0xEB2C(t3)
    sw      t4, 0xE8F4(t3)
    sw      t4, 0xE47C(t3)
    sw      t4, 0xDE74(t3)
    sw      t4, 0xDDB4(t3)
    sw      t4, 0xDBDC(t3)
    sw      t4, 0xD6D4(t3)
    sw      t4, 0xD1AC(t3)
    j       0x801261D8
    lhu     v0, 0xF6DC(v0) ; original code

load_hook:
    push    4, s0, s1, ra, 1
    li      s0, @link_save
    lb      t0, @has_completed_intro(s0)
    bnez    t0, +
    li      t0, 1
    ; first time setup
    sb      t0, @has_completed_intro(s0)
    sb      t0, @have_tatl(s0)
    li      a0, 0x001A ; deku intro area
    li      a1, 2
    jal     set_scene_flag
    li      a2, 2 ; "Hey, you! C'mon! Press Z and talk to me!"
    li      a0, 0x0063 ; inside clock tower
    li      a1, 1 ; second word
    jal     set_scene_flag
    li      a2, 0 ; first bit ("You've met with a terrible fate")
    li      a0, @week_event_reg
    li      a1, 31
    jal     set_event_flag
    li      a2, 2 ; Tatl reminding you about the four directions
    li      a0, @week_event_reg
    li      a1, 93
    jal     set_event_flag
    li      a2, 3 ; woken turtle once (shortens cutscene)
    li      a0, @week_event_reg
    li      a1, 53
    jal     set_event_flag
    li      a2, 6 ; taken turtle once (skips pirates getting wrekt)
+:
    addi    a0, s0, @player_name
    li      a2, 0xFFFFFFFF
    jal     crc32
    li      a1, 8
    not     v0, v0
    sw      v0, hash
    sw      v0, rng_seed
    jal     shuffle_all
    nop
    jpop    4, s0, s1, ra, 1

prng:
    ; just a reimplementation of the PRNG the game uses.
    ; it's from Numerical Recipes in C, by the way.
    ; random = random*0x19660D + 0x3C6EF35F;
    lw      t0, rng_seed
    li      t1, 0x19660D
    multu   t0, t1
    li      t2, 0x3C6EF35F
    mflo    t3
    addu    v0, t3, t2
    sw      v0, rng_seed
    jr
    nop

randint:
    ; v0 = random integer from 0 to a0; a0 >= 0
    push    4, s0, ra
    jal     prng
    addi    s0, a0, 1
    divu    v0, s0
    mfhi    v0
    jpop    4, s0, ra

shuffle_all:
    push    4, s0, s1, s2, ra
    ; https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_.22inside-out.22_algorithm
    li      s0, 0
    li      s1, @entries
    la      s2, shuffles
-:
    jal     randint
    mov     a0, s0
    ; s0 is i, v0 is j
    sll     t0, s0, 2 ; 1<<2 == 2*sizeof(half)
    sll     t1, v0, 2 ; likewise
    addu    t0, s2, t0 ; [i]
    addu    t1, s2, t1 ; [j]
    ; a[i] = a[j]
    lhu     t3, 2(t1)
    sh      t3, 2(t0)
    ; a[j] = source[i]
    lhu     t4, 0(t0)
    sh      t4, 2(t1)
    ; iterate
    addi    s0, 1
    bne     s0, s1, -
    nop
+:
    jpop    4, s0, s1, s2, ra

shuffle_get:
    ; a0: exit value
    ; v0: shuffled exit value
    push    4, ra, 1
    mov     v0, a0
    li      t0, @entries
    li      t1, 0
    la      t3, shuffles
    mov     t4, t3
-:
    lhu     t5, (t4)
    beq     a0, t5, +
    nop
    addi    t1, t1, 1
    beq     t1, t0, +return
    nop
    b       -
    addi    t4, t4, 4 ; 2*sizeof(halfword)
+:
    lhu     v0, 2(t4)
+return:
    jpop    4, ra, 1

unset_alt_scene:
    andi    t9, a0, 0x01FF
    andi    t0, a0, 0xFE00
    ; use poisoned swamp
    li      at, 0x0C00
    bne     t0, at, +
    li      at, 0x8400
    addu    a0, t9, at
+:
    ; use frozen mountain
    li      at, 0x8A00
    bne     t0, at, +
    li      at, 0x9400
    addu    s0, t9, at
+:
    li      at, 0xAE00
    bne     t0, at, +
    li      at, 0x9A00
    addu    s0, t9, at
+:
    li      at, 0xB600
    bne     t0, at, +
    li      at, 0xB400
    addu    s0, t9, at
+:
    jr
    mov     v0, a0

set_alt_scene:
    push    4, s0, ra
    mov     s0, a0
    ; use clean swamp when odolwa is beaten
    li      a0, @week_event_reg
    li      a1, 20
    jal     get_event_flag
    li      a2, 1
    beqz    v0, +
    nop
    andi    t9, s0, 0x01FF
    andi    t0, s0, 0xFE00
    ; can't actually use bnei here because unsignedness, oops
    li      at, 0x8400
    bne     t0, at, +
    li      at, 0x0C00
    addu    s0, t9, at
+:
    ; use unfrozen mountain when goht is beaten
    li      a0, @week_event_reg
    li      a1, 33
    jal     get_event_flag
    li      a2, 7
    beqz    v0, +return
    nop
    andi    t9, s0, 0x01FF
    andi    t0, s0, 0xFE00
    li      at, 0x9400
    bne     t0, at, +
    li      at, 0x8A00
    addu    s0, t9, at
+:
    li      at, 0x9A00
    bne     t0, at, +
    li      at, 0xAE00
    addu    s0, t9, at
+:
    li      at, 0xB400
    bne     t0, at, +
    li      at, 0xB600
    addu    s0, t9, at
+:
+return:
    mov     v0, s0
    jpop    4, s0, ra

shuffle_exit:
    push    4, s0, ra
    sh      a0, old_exit
    li      t0, @link_save
    lw      t1, @voidout_type(t0)
    ; if this was a death warp, don't use coordinates for respawning
    li      at, -6
    bne     t1, at, +
    nop
    cl      t1
    sw      t1, @voidout_type(t0)
+:
    ; same for walking between areas in ikana castle
    li      at, -2
    bne     t1, at, +
    nop
    cl      t1
    sw      t1, @voidout_type(t0)
+:
    ; if this was a void out, don't shuffle
    bnez    t1, +
    mov     s0, a0
    ; if this is a cutscene, don't shuffle
    lh      t2, @exit_mod_setter(t0)
    bnei    t2, 0xFFEF, +
    nop
    ; implicitly passes a0
    jal     unset_alt_scene
    nop
    jal     shuffle_get
    mov     a0, v0
    jal     set_alt_scene
    mov     a0, v0
    mov     s0, v0
    sh      v0, new_exit
    ; set woodfall temple as raised after beating odolwa
    ; otherwise the swamp won't be cleansed
    li      at, 0x8601
    bne     s0, at, +
    li      a1, 20
    li      a0, @week_event_reg
    jal     set_event_flag
    li      a2, 0
+:
    mov     v0, s0
    jpop    4, s0, ra

setup_hook:
    push    4, a0, ra
    lw      a0, @link_save
    jal     shuffle_exit
    andi    a0, 0xFFFF
    sw      v0, @link_save
    jpop    4, a0, ra

.word 0xDEADBEEF
