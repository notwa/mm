dpad_control:
    // a0: number you want to control
    // a1: button state
    // v0: number after modifications
    la      t1, dpad_values
    srl     t0, a1, 8
    andi    t0, 0xF
    add     t0, t1
    lb      t0, 0(t0)
    jr
    add     v0, a0, t0

dpad_values:
    // use table of values for branchless operation
    .byte 0,    1,    -1,   0
    .byte -16,  -4,   -64,  -16
    .byte +16,  +64,  +4,   +16
    .byte 0,    1,    -1,   0
.align
