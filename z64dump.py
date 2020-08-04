#!/usr/bin/env python3

from hashlib import sha1
from io import BytesIO
import argparse
import os
import os.path
import sys
import zlib

from heuristics import detect_format
from util import *

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

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

# shoutouts to spinout182
# assume first entry is makerom (0x1060), and second entry begins from makerom
dma_sig = b"\x00\x00\x00\x00\x00\x00\x10\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x60"
dma_sig_ique = b"\x00\x00\x00\x00\x00\x00\x10\x50\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x50"

# hacky
heresay = os.path.split(sys.argv[0])[0]
oot_filenames_src = os.path.join(heresay, "fn O US10.txt")
oot_filenames_1_2_src = os.path.join(heresay, "fn O US12.txt")
mm_filenames_src = os.path.join(heresay, "fn M US10.txt")

oot_gc_debug = (
    'cfecfdc58d650e71a200c81f033de4e6d617a9f6',
    '50bebedad9e0f10746a52b07239e47fa6c284d03',
    'cee6bc3c2a634b41728f2af8da54d9bf8cc14099',
    'f5fbcebf1e00397effb83163fc97e463a815cce9',
)

oot_n64_ntsc = (
    # NTSC 1.0 (U) and (J)
    'ad69c91157f6705e8ab06c79fe08aad47bb57ba7',
    'c892bbda3993e66bd0d56a10ecd30b1ee612210f',
    # NTSC 1.1 (U) and (J)
    'd3ecb253776cd847a5aa63d859d8c89a2f37b364',
    'dbfc81f655187dc6fefd93fa6798face770d579d',
)

oot_n64_ntsc_1_2 = (
    # NTSC 1.2 (U) and (J)
    '41b3bdc48d98c48529219919015a1af22f5057c2',
    'fa5f5942b27480d60243c2d52c0e93e26b9e6b86',
)

mm_n64_u = (
    'd6133ace5afaa0882cf214cf88daba39e266c078',
)

def dump_wrap(data, fn, size):
    try:
        kind = detect_format(BytesIO(data), fn)
    except Exception as e:
        lament(fn, e)
        kind = None
    if kind is not None:
        fn += '.' + kind
    dump_as(data, fn, size)

def inflate(compressed):
    # love you zoinkity
    decomp = zlib.decompressobj(-zlib.MAX_WBITS)
    data = bytearray()
    data.extend(decomp.decompress(compressed))
    while decomp.unconsumed_tail:
        data.extend(decomp.decompress(decomp.unconsumed_tail))
    data.extend(decomp.flush())
    return data

def deflate_headerless(data):
    wbits = -15  # disable header/trailer by negating windowBits
    zobj = zlib.compressobj(wbits=wbits)
    compressed = zobj.compress(data) + zobj.flush()
    return compressed

def z_dump_file(f, i=0, name=None, decompress=True):
    vs = R4(f.read(4)) # virtual start
    ve = R4(f.read(4)) # virtual end
    ps = R4(f.read(4)) # physical start
    pe = R4(f.read(4)) # physical end
    here = f.tell()

    dump = decompress and dump_wrap or dump_as

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
            if decompress:
                data = Yaz0.decode(compressed)
                dump(data, fn, size)
            else:
                dump(compressed, fn+'.Yaz0', len(compressed))
        else:
            if decompress:
                data = inflate(compressed)
                if data is None or len(data) == 0:
                    lament('unknown compression; skipping:', fn)
                    lament(compressed[:4])
                else:
                    dump(data, fn, size)
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
        for sig in (dma_sig, dma_sig_ique):
            if data == sig[:16]:
                rest = sig[16:]
                if f.read(len(rest)) == rest:
                    return f.tell() - len(rest) - 16
                else:
                    f.seek(len(rest), 1)

def z_dump(f, names=None, decompress=True):
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
            if z_dump_file(f, i, n, decompress):
                i += 1
            else:
                lament("ran out of filenames")
                break
    while z_dump_file(f, i, None, decompress):
        i += 1
    if names and i > len(names):
        lament("extraneous filenames")

def dump_rom(fn, decompress=True):
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
        if romhash in oot_gc_debug:
            # OoT debug rom filenames
            f.seek(0xBE80)
            names = f.read(0x6490).split(b'\x00')
            names = [str(n, 'utf-8') for n in names if n != b'']
        elif romhash in mm_n64_u:
            # filenames inferred from log files
            with open(mm_filenames_src) as f2:
                names = f2.readlines()
        elif romhash in oot_n64_ntsc:
            # filenames inferred from debug rom
            with open(oot_filenames_src) as f2:
                names = f2.readlines()
        elif romhash in oot_n64_ntsc_1_2:
            # filenames inferred from debug rom
            with open(oot_filenames_1_2_src) as f2:
                names = f2.readlines()
        with SubDir(romhash):
            f.seek(0)
            if names is not None:
                names = [n.strip() for n in names]
            z_dump(f, names, decompress)

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
    assert len(dma) > 2
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
    assert f.tell() <= (pe or ve)

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

def create_rom(d, compression=None, nocomplist=None, keep_inplace=False):
    root, _, files = next(os.walk(d))
    files.sort()

    if nocomplist is None:
        nocomplist = []

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

            if i <= 2 or keep_inplace:
                # makerom, boot, dmadata need to be exactly where they were.
                start_v = vs
                start_p = start_v
            else:
                start_v = align(start_v)
                start_p = align(start_p)
                if compression and unempty and i not in nocomplist:
                    lament('Comp…: {}'.format(fn))
                    if compression == 'yaz':
                        data = Yaz0.encode(data)
                    elif compression == 'zlib':
                        data = deflate_headerless(data)
                    else:
                        raise Exception("unsupported compression: " + compression)
                    size_p = len(data)
                    lament("Ratio: {:3.0%}".format(size_p / size_v))
                    compressed = True

            if unempty:
                ps = start_p
                if compressed:
                    pe = align(start_p + size_p)
                    if compression == 'yaz':
                        ve = vs + int.from_bytes(data[4:8], 'big')
                    else:
                        ve = vs + size_v
                else:
                    pe = 0
                    ve = vs + size_v
            else:
                ps = 0xFFFFFFFF
                pe = 0xFFFFFFFF
                ve = vs

            assert start_v <= rom_size
            assert start_v + size_v <= rom_size
            assert vs < rom_size
            assert ve <= rom_size

            # TODO: do we really want to do any of this?
            # i'm not sure how picky the game is with the dmatable.
            #ve = align(ve)
            #print(fn)
            assert vs % 0x10 == 0
            assert ve % 0x10 == 0

            if unempty:
                f.seek(start_p)
                f.write(data)

            dma.append([vs, ve, ps, pe])

            start_v += size_v
            start_p += size_p

        z_write_dma(f, dma)
        fix_rom(f)

class StoreIntList(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, **kwargs):
        super().__init__(option_strings, dest, **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        ints = getattr(namespace, self.dest, None)
        if ints is None:
            ints = []

        # TODO: iterate over a pretty lenient regexp matcher.
        for v in values.split(','):
            if v == '':
                continue
            n = int(v)
            ints.append(n)

        setattr(namespace, self.dest, ints)

def run(args):
    parser = argparse.ArgumentParser(
        description="z64dump: construct and deconstruct Zelda N64 ROMs")

    parser.add_argument(
        'path', metavar='ROM or folder', nargs='+',
        help="ROM to deconstruct, or folder to construct")
    parser.add_argument(
        '-f', '--fix', action='store_true',
        help="only update CIC checksums")
    parser.add_argument(
        '-D', '--no-decompress', action='store_true',
        help="(deconstruction) do not decompress files")
    parser.add_argument(
        '-C', '--no-compress', action='store_const', const=None, dest='compression',
        help="(construction) do not compress files")
    parser.add_argument(
        '-y', '--yaz', action='store_const', const='yaz', dest='compression',
        help="(construction) use yaz (Yaz0) compression")
    parser.add_argument(
        '-z', '--zlib', action='store_const', const='zlib', dest='compression',
        help="(construction) use deflate (zlib) compression")
    parser.add_argument(
        '-s', '--skip', default=None, action=StoreIntList,
        help="skip compression for the given comma-delimited file indices")

    a = parser.parse_args(args)

    for path in a.path:
        if a.fix:
            if os.path.isdir(path):
                lament("only ROM files are fixable:", path)
            else:
                with open(path, 'r+b') as f:
                    fix_rom(f)
            continue

        # directories are technically files, so check this first:
        if os.path.isdir(path):
            keep_inplace = a.compression == None
            create_rom(path, a.compression, a.skip, keep_inplace)
        elif os.path.isfile(path):
            dump_rom(path, not a.no_decompress)
        else:
            lament('no-op:', path)

if __name__ == '__main__':
    try:
        ret = run(sys.argv[1:])
        sys.exit(ret)
    except KeyboardInterrupt:
        sys.exit(1)
