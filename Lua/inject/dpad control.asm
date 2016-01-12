dpad_control:
    // a0: number you want to control
    // a1: button state
    // v0: number after modifications
    la      t1, dpad_values
    srl     t0, a1, 8
    andi    t0, t0, 0xF
    add     t0, t0, t1
    lb      t0, 0(t0)
    jr
    add     v0, a0, t0

dpad_values:
    // use table of values for branchless operation
    .byte 0,    1,    -1,   0
    .byte -10,  -9,   -11,  -10
    .byte +10,  +11,  +9,   +10
    .byte 0,    1,    -1,   0
.align
