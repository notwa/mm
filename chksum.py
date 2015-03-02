#!/bin/python
# fixes the checksums in a Majora's Mask savefile for Bizhawk
# note: copies are ignored and overwritten, so don't bother editing them.

import sys
from util import R2, W2, swap_order

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

save_1 = 0x20800
save_2 = 0x24800
owl_1  = 0x28800
owl_2  = 0x30800
save_1_copy = 0x22800
save_2_copy = 0x26800
owl_1_copy  = 0x2C800
owl_2_copy  = 0x34800

chksum_offset = 0x100A
save_size = 0x2000
owl_size = 0x4000

MAX16 = 0xFFFF

def calc_sum(data):
    chksum = 0
    for b in data:
        chksum += b
        chksum &= MAX16
    return chksum

def fix_sum(f, addr, owl=False):
    f.seek(addr)
    data = f.read(save_size)
    chksum = calc_sum(data[:chksum_offset])

    if owl and data != b'\x00'*save_size:
        chksum += 0x24 # don't know why
        chksum &= MAX16

    f.seek(addr + chksum_offset)
    old_chksum = R2(f.read(2))
    f.seek(addr + chksum_offset)
    f.write(W2(chksum))
    lament('{:04X} -> {:04X}'.format(old_chksum, chksum))

def copy_save(f, addr, addr2):
    f.seek(addr)
    # TODO: handle owl size properly
    data = f.read(save_size)
    f.seek(addr2)
    f.write(data)

def delete_save(f, addr):
    f.seek(addr)
    # TODO: handle owl size properly
    f.write(b'\x00'*save_size)

def run(args):
    for fn in args:
        with open(fn, 'r+b') as f:
            # dumb way to determine byte order
            endian = 'big'
            f.seek(0x10000)
            if f.read(4) != b'\x03\x00\x03\x00':
                endian = 'little'

            if endian == 'little':
                swap_order(f, 'L')

            fix_sum(f, save_1)
            fix_sum(f, save_2)
            fix_sum(f, owl_1, owl=True)
            fix_sum(f, owl_2, owl=True)
            copy_save(f, save_1, save_1_copy)
            copy_save(f, save_2, save_2_copy)
            copy_save(f, owl_1, owl_1_copy)
            copy_save(f, owl_2, owl_2_copy)

            if endian == 'little':
                swap_order(f, 'L')
    return 0

if __name__ == '__main__':
    try:
        ret = run(sys.argv[1:])
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(1)
