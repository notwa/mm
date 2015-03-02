#!/bin/python
# shoutouts to spinout182

import sys
import os, os.path
from io import BytesIO
from hashlib import sha1

from util import *
import n64
import Yaz0

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

# assume first entry is makerom (0x1060), and second entry begins from makerom
dma_sig = b"\x00\x00\x00\x00\x00\x00\x10\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x60"

def z_dump_file(f, prefix=None):
    vs = R4(f.read(4)) # virtual start
    ve = R4(f.read(4)) # virtual end
    ps = R4(f.read(4)) # physical start
    pe = R4(f.read(4)) # physical end
    here = f.tell()

    if vs == ve == ps == pe == 0:
        return False

    fn = 'V{:08X}-{:08X},P{:08X}-{:08X}'.format(vs, ve, ps, pe)
    if prefix is not None:
        fn = str(prefix) + fn

    size = ve - vs

    if ps == 0xFFFFFFFF or pe == 0xFFFFFFFF:
        #lament('file does not exist')
        dump_as(b'', fn)
    elif pe == 0:
        #lament('file is uncompressed')
        pe = ps + size
        f.seek(ps)
        data = f.read(pe - ps)
        dump_as(data, fn)
    else:
        #lament('file is compressed')
        f.seek(ps)
        compressed = f.read(pe - ps)
        if compressed[:4] == b'Yaz0':
            data = Yaz0.decode(compressed)
            dump_as(data, fn)
        else:
            lament('unknown compression; skipping:', fn)
            lament(compressed[:4])

    f.seek(here)
    return True, fn, vs, ve, ps, pe

def z_find_dma(f):
    while True:
        # assume row alignment
        data = f.read(16)
        if len(data) == 0: # EOF
            break
        if data == dma_sig[:16]:
            rest = dma_sig[16:]
            if f.read(len(rest)) == rest:
                return f.tell() - len(rest) - 16
            else:
                f.seek(len(rest), 1)

def z_dump(f):
    f.seek(0x1060) # skip header when finding dma
    addr = z_find_dma(f)
    if addr == None:
        lament("couldn't find file offset table")
        return

    f.seek(addr - 0x30)
    build = f.read(0x30).strip(b'\x00').replace(b'\x00', b'\n')
    lament(str(build, 'utf-8'))

    f.seek(addr)
    i = 0
    while z_dump_file(f, '{:05} '.format(i)):
        i += 1

def dump_rom(fn):
    with open(fn, 'rb') as f:
        data = f.read()

    with BytesIO(data) as f:
        start = f.read(4)
        if start == b'\x37\x80\x40\x12':
            swap_order(f)
        elif start != b'\x80\x37\x12\x40':
            lament('not a .z64:', fn)
            return

        f.seek(0)
        outdir = sha1(f.read()).hexdigest()

        with SubDir(outdir):
            f.seek(0)
            z_dump(f)

def z_read_file(path, fn=None):
    if fn == None:
        fn = os.path.basename(path)

    if len(fn) < 37:
        return False

    fn = str(fn[-37:])

    if fn[0] != 'V' or fn[9] != '-' or fn[18:20] != ',P' or fn[28] != '-':
        return False

    try:
        vs = int(fn[ 1: 9], 16)
        ve = int(fn[10:18], 16)
        ps = int(fn[20:28], 16)
        pe = int(fn[29:37], 16)
    except ValueError:
        return False

    with open(path, 'rb') as f:
        data = f.read()

    return True, data, vs, ve, ps, pe

def z_write_dma(f, dma):
    dma.sort(key=lambda vf: vf[0]) # sort by vs
    assert(len(dma) > 2)
    dma_entry = dma[2] # assumption
    vs, ve, ps, pe = dma_entry

    # initialize with zeros
    dma_size = ve - vs
    f.seek(ps)
    f.write(bytearray(dma_size))

    f.seek(ps)
    for vf in dma:
        vs, ve, ps, pe = vf
        #lament('{:08X} {:08X} {:08X} {:08X}'.format(vs, ve, ps, pe))
        f.write(W4(vs))
        f.write(W4(ve))
        f.write(W4(ps))
        f.write(W4(pe))
    assert(f.tell() <= (pe or ve))

def fix_rom(f):
    bootcode = n64.bootcode_version(f)
    lament('bootcode:', bootcode)
    crc1, crc2 = n64.crc(f, bootcode)
    lament('crcs: {:08X} {:08X}'.format(crc1, crc2))
    f.seek(0x10)
    f.write(W4(crc1))
    f.write(W4(crc2))

def create_rom(d):
    root, _, files = next(os.walk(d))

    rom_size = 64*1024*1024
    with open(d+'.z64', 'w+b') as f:
        dma = []

        # initialize with zeros
        f.write(bytearray(rom_size))
        f.seek(0)

        for fn in files:
            path = os.path.join(root, fn)
            success, data, vs, ve, ps, pe = z_read_file(path, fn)
            if not success:
                lament('skipping:', fn)
                continue

            assert(vs < rom_size)
            assert(ve <= rom_size)
            if ps == 0xFFFFFFFF or pe == 0xFFFFFFFF:
                ps = 0xFFFFFFFF
                pe = 0xFFFFFFFF
            else:
                ps = vs
                pe = 0
                f.seek(vs)
                f.write(data)

            dma.append([vs, ve, ps, pe])

        z_write_dma(f, dma)
        fix_rom(f)

def run(args):
    for path in args:
        # directories are technically files, so check this first
        if os.path.isdir(path):
            create_rom(path)
        elif os.path.isfile(path):
            dump_rom(path)
        else:
            lament('no-op:', path)

if __name__ == '__main__':
    try:
        ret = run(sys.argv[1:])
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(1)
