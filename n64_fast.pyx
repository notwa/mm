# Based on uCON64's N64 checksum algorithm by Andreas Sterbenz

from libc.stdint cimport uint32_t, uint8_t
# ulong must be 32 bits since we expect them to overflow as such
ctypedef uint32_t ulong
ctypedef uint8_t uchar

from zlib import crc32

crc_seeds = {
    6101: 0xF8CA4DDC,
    6102: 0xF8CA4DDC,
    6103: 0xA3886759,
    6105: 0xDF26F436,
    6106: 0x1FEA617A,
}

bootcode_crcs = {
    0x6170A4A1: 6101,
    0x90BB6CB5: 6102,
    0x0B050EE0: 6103,
    0x98BC2C86: 6105,
    0xACC8580A: 6106,
}

cdef ulong ROL(ulong i, ulong b):
    return (i << b) | (i >> (32 - b))

cdef ulong R4(uchar *b):
    return b[0]*0x1000000 + b[1]*0x10000 + b[2]*0x100 + b[3]

cdef object _crc(uchar *data, ulong bootcode, uchar *lookup):
    cdef:
        ulong seed = crc_seeds[bootcode]
        ulong t1, t2, t3, t4, t5, t6
        ulong i, d, b, r, o
        ulong crc1, crc2

    t1 = t2 = t3 = t4 = t5 = t6 = seed

    for i in range(0x1000, 0x101000, 4):
        d = R4(data + i)

        if t6 + d < t6:
            t4 += 1

        t6 += d

        t3 ^= d

        r = ROL(d, d & 0x1F)

        t5 += r

        if t2 > d:
            t2 ^= r
        else:
            t2 ^= t6 ^ d

        if bootcode == 6105:
            o = i & 0xFF
            t1 += R4(lookup + o)^ d
        else:
            t1 += t5

    if bootcode == 6103:
        crc1 = (t6 ^ t4) + t3
        crc2 = (t5 ^ t2) + t1
    elif bootcode == 6106:
        crc1 = t6*t4 + t3
        crc2 = t5*t2 + t1
    else:
        crc1 = t6 ^ t4 ^ t3
        crc2 = t5 ^ t2 ^ t1
    return crc1, crc2

def crc(f, bootcode=6105):
    f.seek(0)
    data = f.read()
    lookup = data[0x750:0x850]
    return _crc(data, bootcode, lookup)

def bootcode_version(f):
    f.seek(0x40)
    return bootcode_crcs[crc32(f.read(0x1000 - 0x40)) & 0xFFFFFFFF]
