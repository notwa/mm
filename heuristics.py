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
    # actors are just object files really,
    # so anything we can detect with
    # would just detect code or inconsistent data.
    # maybe there's some common-looking function between them.
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
