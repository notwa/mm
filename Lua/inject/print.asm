// translates calls to 800021F8
// to copy strings to memory instead
// for Lua to later pick up on

// reset buffer position in our per-frame hook
    la      t0, buffer
    sw      t0, buffer_pos
// and set the string to null
    sb      r0, 0(t0)
    jr
    nop

// keep track of where we are in the buffer
buffer_pos:
    .word 0

// we'll just let this overflow
.align 8
buffer:
    .word 0

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
