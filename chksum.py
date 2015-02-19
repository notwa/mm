#!/bin/python
# fixes the checksums in a Majora's Mask US 1.0 savefile for Bizhawk
# note: copies are ignored and overwritten, so don't bother editing them.

import sys
import struct

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)
chunkize = lambda a, n: (a[i:i+n] for i in range(0, len(a), n))

# seems redundant, but it's a lot less error-prone
pack_u8 = lambda data: struct.pack('>B', data)
pack_u16 = lambda data: struct.pack('>H', data)
unpack_u8 = lambda data: struct.unpack('>B', data)[0]
unpack_u16 = lambda data: struct.unpack('>H', data)[0]

save_1 = 0x20800
save_2 = 0x24800
owl_1  = 0x28800
owl_2  = 0x30800
save_1_copy = 0x22800
save_2_copy = 0x26800
owl_1_copy  = 0x2C800
owl_2_copy  = 0x34800

def calc_sum(data):
    chksum = 0
    for b in chunkize(data, 1):
        chksum += unpack_u8(b)
        chksum &= 0xFFFF
    return chksum

def fix_sum(f, addr, owl=False):
    sum_pos = 0x100A
    f.seek(addr)
    data = f.read(0x2000)
    chksum = calc_sum(data[:sum_pos])

    if owl and data != b'\x00'*0x2000:
        chksum += 0x24 # don't know why
        chksum &= 0xFFFF

    f.seek(addr + sum_pos)
    old_chksum = unpack_u16(f.read(2))
    f.seek(addr + sum_pos)
    f.write(pack_u16(chksum))
    lament('{:04X} -> {:04X}'.format(old_chksum, chksum))

def copy_save(f, addr, addr2):
    sum_pos = 0x100A
    f.seek(addr)
    data = f.read(0x2000)
    f.seek(addr2)
    f.write(data)

def delete_save(f, addr):
    f.seek(addr)
    f.write(b'\x00'*0x2000)

def swap_endian(f):
    f.seek(0)
    data = f.read()
    f.seek(0)
    for s in chunkize(data, 4):
        f.write(s[::-1])

def run(args):
    args = args[1:]
    if len(args) == 0:
        lament("TODO: convert stdin to stdout")
        return 0
    for fn in args:
        with open(fn, 'r+b') as f:
            # dumb way to determine byte order
            endian = 'big'
            f.seek(0x10000)
            if f.read(4) != b'\x03\x00\x03\x00':
                endian = 'little'

            if endian == 'little':
                swap_endian(f)

            copy_save(f, save_1, save_1_copy)
            copy_save(f, save_2, save_2_copy)
            copy_save(f, owl_1, owl_1_copy)
            copy_save(f, owl_2, owl_2_copy)
            fix_sum(f, save_1)
            fix_sum(f, save_2)
            fix_sum(f, owl_1, owl=True)
            fix_sum(f, owl_2, owl=True)

            if endian == 'little':
                swap_endian(f)
    return 0

if __name__ == '__main__':
    ret = 0
    try:
        ret = run(sys.argv)
    except KeyboardInterrupt:
        sys.exit(1)
    sys.exit(ret)
