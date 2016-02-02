from util import *

def try_makerom(f):
    f.seek(0)
    if f.read(12) == b'\x80\x37\x12\x40\x00\x00\x00\x0f\x80\x00\x04\x00':
        return True
    return False

def try_dmadata(f):
    f.seek(0)
    if f.read(20) == b"\x00\x00\x00\x00\x00\x00\x10\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x60":
        return True
    return False

def try_actor(f):
    f.seek(-4, 2)
    section_size = R4(f.read(4))
    file_size = f.tell()
    if section_size > 0x4000 or section_size == 0:
        # assume this section isn't larger than 16KiB
        # (that's 4 times larger than the largest one in OoT)
        return False
    f.seek(-section_size, 2)
    section_start = f.tell()
    data_offset = R4(f.read(4))
    data_size = R4(f.read(4))
    misc_size = R4(f.read(4))
    if section_start == data_offset + data_size + misc_size:
        return True
    return False

def try_scene_or_room(f, bank=2):
    # note: doesn't detect syotes_room_0 because it's missing a header
    f.seek(0)
    while True:
        command = f.read(8)
        if len(command) == 0:
            return False
        if command[2:4] != b'\x00\x00':
            return False
        if command[0] > 0x1e:
            return False
        if command[4] != bank and command[4] != 0x00:
            if command[0] not in (0x05, 0x10, 0x11, 0x12):
                return False
        if command == b'\x14\x00\x00\x00\x00\x00\x00\x00':
            return True

def detect_format(f, fn=None):
    if try_makerom(f):
        return None
    if try_dmadata(f):
        return None
    if try_actor(f):
        return 'actor'
    if try_scene_or_room(f, 2):
        return 'scene'
    if try_scene_or_room(f, 3):
        return 'room'

    return None
