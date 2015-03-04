# decoder ripped from: http://www.amnoid.de/gc/yaz0.txt

ctypedef unsigned long ulong
ctypedef unsigned char uchar

cdef ulong get_size(uchar *comp):
    return comp[4]*0x1000000 + comp[5]*0x10000 + comp[6]*0x100 + comp[7]

cdef void _decode(uchar *comp, uchar *uncomp):
    cdef:
        ulong src = 16 # skip header
        ulong dst = 0
        uchar valid = 0 # bit count
        uchar curr = 0 # code byte

        ulong size = get_size(comp)

        uchar byte1, byte2
        ulong dist, copy, i, n

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

def decode(comp):
    size = get_size(comp)
    uncomp = bytearray(size)
    _decode(comp, uncomp)
    return uncomp
