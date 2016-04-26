.push pc

[DMARomToRam]: 0x80000BFC

[vstart]: 0x035D0000
[start]: 0x80700000
[size]: 0x10000

/*
.org 0x18F30
; add an entry to the end of dmatable to hold our extra code
; this actually just crashes the game so don't bother
; (no debug filename associated with it = bad pointer dereference? maybe?)
    .word @vstart    ; virtual start
    .word 0x035E0000 ; virtual end (@vstart + @size)
    .word @vstart    ; physical start (should be same as virtual start)
    .word 0          ; physical end (should be 0 for uncompressed)
*/

.base 0x7F588E60 ; code file in memory

.org 0xB3D9E4 ; 0x800C6844
    ; this appears to be the main game loop function
    ; we can "make room" for some injected code
    ; by taking advantage of it never returning under normal circumstances.
    ; we'll cut out pushing RA, S1-S8 stuff on stack.
    ; props to CloudMax for coming up with this.
    addiu   sp, sp, 0xFC60 ; original code
    ; push removed here
    li      s0, 0x8011F830 ; original code
    ; pushes removed here
    ; 9 instructions to work with?
    ; dma args are backwards compared to MM?
    li      a1, @start
    li      a2, @size
    jal     @DMARomToRam
    li      a0, @vstart
    lui     a0 0x8014 ; original code
    cl      a1
    cl      a2
    nop
    nop
    nop
    nop
    nop

.pop pc
