def try_scene(f):
    f.seek(0)
    while True:
        command = f.read(8)
        if len(command) == 0:
            return False
        if command[2:4] != b'\x00\x00':
            return False
        if command[0] > 0x1e:
            return False
        if command[4] != 0x02 and command[4] != 0x00:
            if command[0] not in (0x05, 0x10, 0x11, 0x12):
                return False
        if command == b'\x14\x00\x00\x00\x00\x00\x00\x00':
            return True

def try_room(f):
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
        if command[4] != 0x03 and command[4] != 0x00:
            if command[0] not in (0x05, 0x10, 0x11, 0x12):
                return False
        if command == b'\x14\x00\x00\x00\x00\x00\x00\x00':
            return True

def detect_format(f, fn=None):
    if try_scene(f):
        return 'scene'
    if try_room(f):
        return 'room'

    return None
