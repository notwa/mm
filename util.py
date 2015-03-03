import os
import struct, array

R1 = lambda data: struct.unpack('>B', data)[0]
R2 = lambda data: struct.unpack('>H', data)[0]
R4 = lambda data: struct.unpack('>I', data)[0]
W1 = lambda data: struct.pack('>B', data)
W2 = lambda data: struct.pack('>H', data)
W4 = lambda data: struct.pack('>I', data)

def dump_as(b, fn, size=None):
    with open(fn, 'w+b') as f:
        if size:
            f.write(bytearray(size))
            f.seek(0)
        f.write(b)

def swap_order(f, size='H'):
    f.seek(0)
    a = array.array(size, f.read())
    a.byteswap()
    f.seek(0)
    f.write(a.tobytes())

class SubDir:
    def __init__(self, d):
        self.d = d
    def __enter__(self):
        self.cwd = os.getcwd()
        try:
            os.mkdir(self.d)
        except FileExistsError:
            pass
        os.chdir(self.d)
    def __exit__(self, type_, value, traceback):
        os.chdir(self.cwd)
