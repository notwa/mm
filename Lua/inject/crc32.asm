crc32:
    // this is a re-implementation of the C code
    // available at https://gist.github.com/notwa/5689243
    // a0: pointer to input data
    // a1: input data length
    // a2: existing crc value (use 0xFFFFFFFF for initialization)
    // v0: new crc value (bitwise NOT it when you're finished cycling)
    mov     v0, a2
    la      t9, crc32_constants
-:
    lbu     t0, (a0) // *ptr
    // first nybble
    //crc = (crc >> 4) ^ crc32_tbl[(crc & 0xf) ^ (*ptr & 0xf)];
    andi    t2, v0, 0xF
    andi    t3, t0, 0xF
    srl     t1, v0, 4
    xor     t4, t2, t3
    sll     t5, t4, 2 // offset = index*sizeof(word)
    addu    t6, t5, t9
    lw      t7, (t6)
    xor     v0, t1, t7
    // second nybble
    //crc = (crc >> 4) ^ crc32_tbl[(crc & 0xf) ^ (*(ptr++) >> 4)];
    andi    t2, v0, 0xF
    srl     t3, t0, 4
    srl     t1, v0, 4
    xor     t4, t2, t3
    sll     t5, t4, 2 // offset = index*sizeof(word)
    addu    t6, t5, t9
    lw      t7, (t6)
    xor     v0, t1, t7
    // iterate or return
    subi    a1, a1, 1 // cnt--
    bnez    a1, -
    addi    a0, a0, 1 // ptr++
    jr
    nop

crc32_constants: // ethernet standard (0x04C11DB7 as the crc divisor)
    .word   0x00000000, 0x1DB71064, 0x3B6E20C8, 0x26D930AC
    .word   0x76DC4190, 0x6B6B51F4, 0x4DB26158, 0x5005713C
    .word   0xEDB88320, 0xF00F9344, 0xD6D6A3E8, 0xCB61B38C
    .word   0x9B64C2B0, 0x86D3D2D4, 0xA00AE278, 0xBDBDF21C
