#!/bin/python
# shoutouts to spinout182

import os, os.path
import sys
import struct
import hashlib

import n64
import Yaz0

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

R1 = lambda data: struct.unpack('>B', data)[0]
R2 = lambda data: struct.unpack('>H', data)[0]
R4 = lambda data: struct.unpack('>I', data)[0]
W1 = lambda data: struct.pack('>B', data)
W2 = lambda data: struct.pack('>H', data)
W4 = lambda data: struct.pack('>I', data)

# assume first entry is makerom (0x1060), and second entry begins from makerom
fs_sig = b"\x00\x00\x00\x00\x00\x00\x10\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x60"

def dump_as(b, fn):
    with open(fn, 'w+b') as f:
        f.write(b)

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

def z_find_fs(f):
    while True:
        # assume row alignment
        data = f.read(16)
        if len(data) == 0: # EOF
            break
        if data == fs_sig[:16]:
            rest = fs_sig[16:]
            if f.read(len(rest)) == rest:
                return f.tell() - len(rest) - 16
            else:
                f.seek(len(rest), 1)

def z_dump(f):
    f.seek(0x1060) # skip header when finding fs
    addr = z_find_fs(f)
    if addr == None:
        raise Exception("couldn't find file offset table")

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

        if data[:4] != b'\x80\x37\x12\x40':
            # TODO: check if it's a .n64 (2 byte swap) and convert
            lament('not a .z64:', fn)
            return

        outdir = hashlib.sha1(data).hexdigest()
        del data

        # TODO: a `with` would be suitable here for handling cwd
        try:
            os.mkdir(outdir)
        except FileExistsError:
            pass
        os.chdir(outdir)

        f.seek(0)
        z_dump(f)

def z_read_file(path, fn=None):
    if fn == None:
        # TODO: infer from path
        return False
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

def create_rom(d):
    walker = os.walk(d)
    root, _, files = next(walker)
    del walker

    rom_size = 64*1024*1024
    with open(d+'.z64', 'w+b') as f:
        fs = []
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

            fs.append([vs, ve, ps, pe])

        # fix filesystem
        fs.sort(key=lambda vf: vf[0]) # sort by vs
        assert(len(fs) > 2)
        fs_entry = fs[2] # assumption
        vs, ve, ps, pe = fs_entry
        fs_size = ve - vs
        f.seek(ps)
        f.write(bytearray(fs_size))
        f.seek(ps)
        for vf in fs:
            vs, ve, ps, pe = vf
            #lament('{:08X} {:08X} {:08X} {:08X}'.format(vs, ve, ps, pe))
            f.write(W4(vs))
            f.write(W4(ve))
            f.write(W4(ps))
            f.write(W4(pe))
        assert(f.tell() <= (pe or ve))

        # fix makerom (n64 header)
        # TODO: don't assume bootcode is 6105
        crc1, crc2 = n64.crc(f)
        lament('crcs: {:08X} {:08X}'.format(crc1, crc2))
        f.seek(0x10)
        f.write(W4(crc1))
        f.write(W4(crc2))

def run(args):
    cwd = os.getcwd()
    for path in args:
        if os.path.isdir(path):
            create_rom(path)
        elif os.path.isfile(path):
            dump_rom(path)
        else:
            lament('no-op:', path)
        os.chdir(cwd)

if __name__ == '__main__':
    ret = 0
    try:
        ret = run(sys.argv)
    except KeyboardInterrupt:
        sys.exit(1)
    sys.exit(ret)
