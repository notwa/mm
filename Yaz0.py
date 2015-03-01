# decoder ripped from: http://www.amnoid.de/gc/yaz0.txt
# encoder ripped from:
# https://bitbucket.org/ottehr/z64-fm/src/9fdc704ca42ff15c8e01b1566d4692d986920c6a/yaz0.c

def decode(comp):
    src = 16 # skip header
    dst = 0
    valid = 0 # bit count
    curr = 0 # code byte

    assert(comp[:4] == b'Yaz0')
    assert(comp[8:12] == b'\x00\x00\x00\x00')
    assert(comp[12:16] == b'\x00\x00\x00\x00')

    # we could use struct but eh we only need it once
    size = comp[4]*0x1000000 + comp[5]*0x10000 + comp[6]*0x100 + comp[7]
    uncomp = bytearray(size)

    while dst < size:
        if not valid:
            curr = comp[src]
            src += 1
            valid = 8

        if curr & 0x80:
            uncomp[dst] = comp[src]
            dst += 1
            src += 1
        else:
            byte1 = comp[src]
            byte2 = comp[src + 1]
            src += 2

            dist = ((byte1 & 0xF) << 8) | byte2
            copy = dst - (dist + 1)
            assert(copy >= 0)

            n = byte1 >> 4
            if n:
                n += 2
            else:
                n = comp[src] + 0x12
                src += 1

            for i in range(n):
                uncomp[dst] = uncomp[copy]
                copy += 1
                dst += 1

        curr <<= 1
        valid -= 1

    return uncomp

def encode(uncomp):
    raise Exception('Yaz0_encode: unimplemented')
