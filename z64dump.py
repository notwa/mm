#!/usr/bin/env python3

import sys
import os, os.path
from io import BytesIO
from hashlib import sha1

# check for cython
try:
    import pyximport
except ImportError:
    fast = False
else:
    pyximport.install()
    fast = True

if fast:
    import Yaz0_fast as Yaz0
    import n64_fast as n64
else:
    import Yaz0
    import n64

from util import *
from heuristics import detect_format

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

# shoutouts to spinout182
# assume first entry is makerom (0x1060), and second entry begins from makerom
dma_sig = b"\x00\x00\x00\x00\x00\x00\x10\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x60"

def dump_wrap(data, fn, size):
    kind = detect_format(BytesIO(data), fn)
    if kind is not None:
        fn += '.' + kind
    dump_as(data, fn, size)

def z_dump_file(f, i=0, name=None, uncompress=True):
    vs = R4(f.read(4)) # virtual start
    ve = R4(f.read(4)) # virtual end
    ps = R4(f.read(4)) # physical start
    pe = R4(f.read(4)) # physical end
    here = f.tell()

    dump = uncompress and dump_wrap or dump_as

    if vs == ve == ps == pe == 0:
        return False

    # ve inferred from filesize, and we're making pe be 0
    # ps can just be the end of the last file
    fn = '{:04} V{:08X}'.format(i, vs)
    if name is not None and name is not '':
        fn = fn + ' ' + str(name)

    size = ve - vs

    if ps == 0xFFFFFFFF or pe == 0xFFFFFFFF:
        #lament('file does not exist')
        dump_as(b'', fn, 0)
    elif pe == 0:
        #lament('file is uncompressed')
        pe = ps + size
        f.seek(ps)
        data = f.read(pe - ps)
        dump(data, fn, size)
    else:
        #lament('file is compressed')
        f.seek(ps)
        compressed = f.read(pe - ps)
        if compressed[:4] == b'Yaz0':
            if uncompress:
                data = Yaz0.decode(compressed)
                dump(data, fn, size)
            else:
                dump(compressed, fn+'.Yaz0', len(compressed))
        else:
            if uncompress:
                lament('unknown compression; skipping:', fn)
                lament(compressed[:4])
            else:
                lament('unknown compression:', fn)
                dump(compressed, fn, len(compressed))

    f.seek(here)
    return True

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

def z_dump(f, names=None, uncompress=True):
    f.seek(0x1060) # skip header when finding dmatable
    addr = z_find_dma(f)
    if addr == None:
        lament("couldn't find file offset table")
        return

    f.seek(addr - 0x30)
    build = f.read(0x30).strip(b'\x00').replace(b'\x00', b'\n')
    lament(str(build, 'utf-8'))

    f.seek(addr)
    i = 0
    if names:
        for n in names:
            if z_dump_file(f, i, n, uncompress):
                i += 1
            else:
                lament("ran out of filenames")
                break
    while z_dump_file(f, i, None, uncompress):
        i += 1
    if names and i > len(names):
        lament("extraneous filenames")

def dump_rom(fn, uncompress=True):
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
        romhash = sha1(f.read()).hexdigest()

        names = None
        if romhash == '50bebedad9e0f10746a52b07239e47fa6c284d03':
            # OoT debug rom filenames
            f.seek(0xBE80)
            names = f.read(0x6490).split(b'\x00')
            names = [str(n, 'utf-8') for n in names if n != b'']
        if romhash in (
                       # NTSC 1.0 (U) and (J)
                       'ad69c91157f6705e8ab06c79fe08aad47bb57ba7',
                       'c892bbda3993e66bd0d56a10ecd30b1ee612210f',
                       # NTSC 1.1 (U) and (J)
                       'd3ecb253776cd847a5aa63d859d8c89a2f37b364',
                       'dbfc81f655187dc6fefd93fa6798face770d579d',
                       # NTSC 1.2 (U) and (J)
                       '41b3bdc48d98c48529219919015a1af22f5057c2',
                       'fa5f5942b27480d60243c2d52c0e93e26b9e6b86',
                      ):
            # filenames inferred from debug rom
            with open('fn O US10.txt') as f2:
                names = f2.readlines()
            names = [n.strip() for n in names]
        with SubDir(romhash):
            f.seek(0)
            z_dump(f, names, uncompress)

def z_read_file(path, fn=None):
    if fn == None:
        fn = os.path.basename(path)

    if len(fn) < 14:
        return False, None, None

    fn = str(fn[:14])

    if fn[4:6] != ' V':
        return False, None, None

    try:
        vs = int(fn[ 6: 14], 16)
    except ValueError:
        return False, None, None

    with open(path, 'rb') as f:
        data = f.read()

    return True, data, vs

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

def align(x):
    return (x + 15) // 16 * 16

def create_rom(d, compress=False):
    root, _, files = next(os.walk(d))
    files.sort()

    rom_size = 64*1024*1024
    with open(d+'.z64', 'w+b') as f:
        dma = []

        # initialize with zeros
        f.write(bytearray(rom_size))
        f.seek(0)

        start_v = 0
        start_p = 0

        for i, fn in enumerate(files):
            path = os.path.join(root, fn)
            success, data, vs = z_read_file(path, fn)
            if not success:
                lament('skipping:', fn)
                continue

            size_v = len(data)
            size_p = size_v
            unempty = size_v > 0
            compressed = size_v >= 4 and data[:4] == b'Yaz0'

            if i <= 2:
                # makerom, boot, dmadata need to be exactly where they were
                start_v = vs
                start_p = start_v
            else:
                start_v = align(start_v)
                start_p = align(start_p)
                if compress and unempty:
                    lament('Comp…: {}'.format(fn))
                    data = Yaz0.encode(data)
                    size_p = len(data)
                    lament("Ratio: {:3}%".format(int(size_p / size_v * 100)))
                    compressed = True

            if unempty:
                ps = start_p
                if compressed:
                    pe = align(start_p + size_p)
                    ve = vs + int.from_bytes(data[4:8], 'big')
                else:
                    pe = 0
                    ve = vs + size_v
            else:
                ps = 0xFFFFFFFF
                pe = 0xFFFFFFFF
                ve = vs

            assert(start_v <= rom_size)
            assert(start_v + size_v <= rom_size)
            assert(vs < rom_size)
            assert(ve <= rom_size)

            if unempty:
                f.seek(start_p)
                f.write(data)

            dma.append([vs, ve, ps, pe])

            start_v += size_v
            start_p += size_p

        z_write_dma(f, dma)
        fix_rom(f)

def run(args):
    compress = False
    fix = False
    for path in args:
        if path == '-c':
            compress = not compress
            continue
        if path == '-f':
            fix = not fix
            continue
        if fix:
            with open(path, 'r+b') as f:
                fix_rom(f)
            continue
        # directories are technically files, so check this first
        if os.path.isdir(path):
            create_rom(path, compress)
        elif os.path.isfile(path):
            dump_rom(path, not compress)
        else:
            lament('no-op:', path)

if __name__ == '__main__':
    try:
        ret = run(sys.argv[1:])
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(1)
