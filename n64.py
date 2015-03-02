# Based on uCON64's N64 checksum algorithm by Andreas Sterbenz

from zlib import crc32

MAX32 = 0xFFFFFFFF

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

def ROL(i, b):
    return ((i << b) | (i >> (32 - b))) & MAX32

def R4(b):
    return b[0]*0x1000000 + b[1]*0x10000 + b[2]*0x100 + b[3]

def crc(f, bootcode=6105):
    seed = crc_seeds[bootcode]
    t1 = t2 = t3 = t4 = t5 = t6 = seed

    if bootcode == 6105:
        f.seek(0x0710 + 0x40)
        lookup = f.read(0x100)

    f.seek(0x1000)
    for i in range(0x1000, 0x101000, 4):
        d = R4(f.read(4))

        if ((t6 + d) & MAX32) < t6:
            t4 += 1
            t4 &= MAX32

        t6 += d
        t6 &= MAX32

        t3 ^= d

        b = d & 0x1F
        r = (d << b) | (d >> (32 - b))
        r &= MAX32

        t5 += r
        t5 &= MAX32

        if t2 > d:
            t2 ^= r
        else:
            t2 ^= t6 ^ d

        if bootcode == 6105:
            o = i & 0xFF
            temp = R4(lookup[o:o + 4])
        else:
            temp = t5
        t1 += temp ^ d
        t1 &= MAX32

    if bootcode == 6103:
        crc1 = (t6 ^ t4) + t3
        crc2 = (t5 ^ t2) + t1
    elif bootcode == 6106:
        crc1 = t6*t4 + t3
        crc2 = t5*t2 + t1
    else:
        crc1 = t6 ^ t4 ^ t3
        crc2 = t5 ^ t2 ^ t1
    return crc1 & MAX32, crc2 & MAX32

def bootcode_version(f):
    f.seek(0x40)
    return bootcode_crcs[crc32(f.read(0x1000 - 0x40)) & MAX32]
