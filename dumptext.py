#!/usr/bin/env python3

import sys
import os, os.path
from io import BytesIO
import struct

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

unpack = lambda fmt, data: struct.unpack(fmt, bytes(data))

extended='‾ÀÎÂÄÇÈÉÊËÏÔÖÙÛÜßàáâäçèéêëïôöùûü'

def parse_jp_text(f):
    s = ''
    bs = bytearray()
    def arg2():
        return '{:04X}'.format(unpack('>H', f.read(2))[0]).encode('shift-jis')
    lastx = 0
    while 1:
        b1 = f.read(1)
        if not b1:
            break
        if b'\x20' <= b1 <= b'\x7F':
            # ascii
            if b1 == b'"':
                bs += b'""'
            else:
                bs += b1
            continue
        if b'\xA1' <= b1 <= b'\xDF':
            # single-byte half-width katakana
            bs += b1
            continue

        b2 = f.read(1)
        if not b2:
            raise Exception('unexpected EOF')
        x1 = ord(b1)
        x2 = ord(b2)
        x = x1*0x100 + x2
        odd = x1 % 2

        xs = bytes('{:04X}'.format(x), 'shift-jis')

        # shift-jis
        shifty1 = (0x81 <= x1 <= 0x9F and x1 != 0x85 and x1 != 0x86) or 0xE0 <= x1 <= 0xEF
        shifty2e = 0x9F <= x2 <= 0xFC
        shifty2o = 0x40 <= x2 <= 0x9E
        try:
            (b1 + b2).decode('shift-jis')
            shifty = True
        except:
            shifty = False

        if x == 0x000A:
            bs += b'\n'
        elif x == 0x8170:
            # end marker
            break
        elif x == 0x81A5: # 0x04
            if verbose:
                bs += b'[pause]'
            bs += b'\n\n'
        elif x == 0x000B: # 0x05
            if verbose:
                bs += b'[color '+arg2()[2:]+b']'
            else:
                arg2()
        elif x == 0x86C7: # 0x06
            if verbose:
                bs += b'[spaces '+arg2()+b']'
            else:
                arg2()
        elif x == 0x81CB: # 0x07
            bs += b'[goto '+arg2()+b']'
        elif x == 0x8189: # 0x08
            if verbose:
                bs += b'[instant on]'
        elif x == 0x818A: # 0x09
            if verbose:
                bs += b'[instant off]'
        elif x == 0x86C8: # 0x0A
            # shop-related? keeps dialog open?
            if verbose:
                bs += b'[keepalive]'
        elif x == 0x819F: # 0x0B
            if verbose:
                bs += b'[event start]'
        elif x == 0x81A3: # 0x0C
            if verbose:
                bs += b'[wait '+arg2()+b']'
            else:
                arg2()
            bs += b'\n\n'
        elif x == 0x819E: # 0x0E
            if verbose:
                bs += b'[fade wait '+arg2()+b']'
            else:
                arg2()
        elif x == 0x874F: # 0x0F
            bs += b'[Link]'
        elif x == 0x81F0: # 0x10
            if verbose:
                bs += b'[Ocarina]'
        elif x == 0x81F3: # 0x12
            bs += b'[sound '+arg2()+b']'
        elif x == 0x819A: # 0x13
            bs += b'[Item Icon '+arg2()[2:]+b']'
        elif x == 0x86C9: # 0x14
            if verbose:
                bs += b'[speed '+xs+b' '+arg2()+b']'
            else:
                arg2()
        elif x == 0x86B3: # 0x15
            bs += b'[background '+arg2()+arg2()+b']'
        elif x == 0x8791: # 0x16
            bs += b'[Marathon Time]'
        elif x == 0x8792: # 0x17
            bs += b'[Race Time]'
        elif x == 0x879B: # 0x18
            bs += b'[Points]'
        elif x == 0x86A3: # 0x19
            bs += b'[Gold Skulltulas]'
        elif x == 0x8199: # 0x1A
            if verbose:
                bs += b'[no skip]'
        elif x == 0x81BC: # 0x1B
            if verbose:
                bs += b'[two-choice]'
        elif x == 0x81B8: # 0x1C
            if verbose:
                bs += b'[three-choice]'
        elif x == 0x86A4: # 0x1D
            bs += b'[weight]'
        elif x == 0x869F: # 0x1E
            a = arg2()
            if a == b'0000':
                bs += b'[Horseback Archery Score]'
            elif a == b'0001':
                bs += b'[Poe Points]'
            elif a == b'0002':
                bs += b'[Largest Fish]'
            elif a == b'0003':
                bs += b'[Horse Race Time]'
            elif a == b'0004':
                bs += b'[Marathon Time]'
            elif a == b'0006':
                bs += b'[Dampe Race time]'
            else:
                bs += b'[time '+a+b']'
        elif x == 0x81A1: # 0x1F
            bs += b'[World Time]'
        elif x == 0x839F: # 0x9F
            bs += b'[A]'
        elif x == 0x83A0: # 0xA0
            bs += b'[B]'
        elif x == 0x83A1: # 0xA1
            bs += b'[C]'
        elif x == 0x83A2: # 0xA2
            bs += b'[L]'
        elif x == 0x83A3: # 0xA3
            bs += b'[R]'
        elif x == 0x83A4: # 0xA4
            bs += b'[Z]'
        elif x == 0x83A5: # 0xA5
            bs += b'[C Up]'
        elif x == 0x83A6: # 0xA6
            bs += b'[C Down]'
        elif x == 0x83A7: # 0xA7
            bs += b'[C Left]'
        elif x == 0x83A8: # 0xA8
            bs += b'[C Right]'
        elif x == 0x83A9: # 0xA9
            bs += b'[Triangle]'
        elif x == 0x83AA: # 0xAA
            bs += b'[Control Stick]'
        elif x == 0x83AB: # 0xAB
            bs += b'[DPad]'
        elif x == 0x0000:
            lament(bs)
            lament('{:04X}'.format(lastx))
            raise Exception('unexpected 0000')
        elif shifty1 and shifty2o:
            if not shifty:
                lament('CRAP {:02X}{:02X}'.format(x1, x2))
                raise Exception('not actually shifty')
            bs += b1
            bs += b2
        elif shifty1 and shifty2e:
            if not shifty:
                lament('CRAP {:02X}{:02X}'.format(x1, x2))
                raise Exception('not actually shifty')
            bs += b1
            bs += b2
        elif shifty:
            # last resort...
            lament('SJS {:02X}{:02X}'.format(x1, x2))
            lament('{:04X}'.format(lastx))
            raise Exception('looks shifty')
            bs += b1
            bs += b2
        else:
            lament(bs)
            lament('unknown {:02X}{:02X}'.format(x1, x2))
            raise Exception('unknown character')
        lastx = x

    s = bs.decode('shift-jis')
    return s

def parse_en_text(f):
    s = ''
    bs = bytearray()
    def arg():
        return '{:02X}'.format(ord(f.read(1))).encode('utf-8')
    lastx = 0
    while 1:
        b1 = f.read(1)
        if not b1:
            break
        x = ord(b1)
        if b'\x20' <= b1 <= b'\x7E':
            # ascii
            if b1 == b'"':
                bs += b'""'
            else:
                bs += b1
            continue
        if b'\x7F' <= b1 <= b'\x9E':
            bs += extended[x - 0x7F].encode('utf-8')
            continue
        elif x == 0x01:
            bs += b'\n'
        elif x == 0x02:
            # end marker
            break
        elif x == 0x04:
            if verbose:
                bs += b'[pause]'
            bs += b'\n\n'
        elif x == 0x05:
            if verbose:
                bs += b'[color '+arg()+b']'
            else:
                arg()
        elif x == 0x06:
            if verbose:
                bs += b'[spaces '+arg()+b']'
            else:
                arg()
        elif x == 0x07:
            bs += b'[goto '+arg()+arg()+b']'
        elif x == 0x08:
            if verbose:
                bs += b'[instant on]'
        elif x == 0x09:
            if verbose:
                bs += b'[instant off]'
        elif x == 0x0A:
            # shop-related? keeps dialog open?
            if verbose:
                bs += b'[keepalive]'
        elif x == 0x0B:
            if verbose:
                bs += b'[event start]'
        elif x == 0x0C:
            if verbose:
                bs += b'[wait '+arg()+b']'
            else:
                arg()
            bs += b'\n\n'
        elif x == 0x0E:
            if verbose:
                bs += b'[fade wait '+arg()+b']'
            else:
                arg()
        elif x == 0x0F:
            bs += b'[Link]'
        elif x == 0x10:
            bs += b'[Ocarina]'
        elif x == 0x12:
            bs += b'[sound '+arg()+arg()+b']'
        elif x == 0x13:
            bs += b'[Item Icon '+arg()+b']'
        elif x == 0x14:
            if verbose:
                bs += b'[speed '+arg()+b']'
            else:
                arg()
        elif x == 0x15:
            bs += b'[background '+arg()+arg()+arg()+b']'
        elif x == 0x16:
            bs += b'[Marathon Time]'
        elif x == 0x17:
            bs += b'[Race Time]'
        elif x == 0x18:
            bs += b'[Points]'
        elif x == 0x19:
            bs += b'[Gold Skulltulas]'
        elif x == 0x1A:
            if verbose:
                bs += b'[no skip]'
        elif x == 0x1B:
            if verbose:
                bs += b'[two-choice]'
        elif x == 0x1C:
            if verbose:
                bs += b'[three-choice]'
        elif x == 0x1D:
            bs += b'[weight]'
        elif x == 0x1E:
            a = arg()
            if a == b'00':
                bs += b'[Horseback Archery Score]'
            elif a == b'01':
                bs += b'[Poe Points]'
            elif a == b'02':
                bs += b'[Largest Fish]'
            elif a == b'03':
                bs += b'[Horse Race Time]'
            elif a == b'04':
                bs += b'[Marathon Time]'
            elif a == b'06':
                bs += b'[Dampe Race time]'
            else:
                bs += b'[time '+a+b']'
        elif x == 0x1F:
            bs += b'[World Time]'
        elif x == 0x9F:
            bs += b'[A]'
        elif x == 0xA0:
            bs += b'[B]'
        elif x == 0xA1:
            bs += b'[C]'
        elif x == 0xA2:
            bs += b'[L]'
        elif x == 0xA3:
            bs += b'[R]'
        elif x == 0xA4:
            bs += b'[Z]'
        elif x == 0xA5:
            bs += b'[C Up]'
        elif x == 0xA6:
            bs += b'[C Down]'
        elif x == 0xA7:
            bs += b'[C Left]'
        elif x == 0xA8:
            bs += b'[C Right]'
        elif x == 0xA9:
            bs += b'[Triangle]'
        elif x == 0xAA:
            bs += b'[Control Stick]'
        elif x == 0xAB:
            bs += b'[DPad]'
        elif x == 0x00:
            lament(bs)
            lament('{:02X}'.format(lastx))
            raise Exception('unexpected 00')
        else:
            lament(bs)
            lament('unknown {:02X}'.format(x))
            raise Exception('unknown character')
        lastx = x

    s = bs.decode('utf-8')
    return s

def dump_text(parser, msgtable, msgs):
    if not isinstance(msgtable, BytesIO):
        msgtable = BytesIO(msgtable)
    if not isinstance(msgs, BytesIO):
        msgs = BytesIO(msgs)
    msgtable_end = msgtable.seek(0, 2)
    msgs_end = msgs.seek(0, 2)
    msgtable.seek(0)
    msgs.seek(0)
    lastid = 0
    for i in range(msgtable_end//8):
        msgid, = unpack('>H', msgtable.read(2))
        if msgid >= 0xFFFC:
            break
        if msgid != lastid + 1:
            print('"",""')
        xy = msgtable.read(1)
        unused = msgtable.read(1)
        bank = msgtable.read(1)
        offset, = unpack('>L', b'\x00'+msgtable.read(3))
        msgs.seek(offset)
        text = parser(msgs)
        #print('{:04} {:04X} {:06X}'.format(i, msgid, offset))
        print('"${:04X}","{}"'.format(msgid, text))
        lastid = msgid

def dumpit(codefile, textfile, language, table_offset, table_size):
    if os.path.exists(codefile) and os.path.exists(textfile):
        with open(codefile, 'rb') as f:
            f.seek(table_offset)
            msgtable = f.read(table_size)
        with open(textfile, 'rb') as f:
            msgs = f.read()
        if language == 'jp':
            dump_text(parse_jp_text, msgtable, msgs)
        elif language == 'en':
            dump_text(parse_en_text, msgtable, msgs)
        else:
            raise Exception('unsupported')
        return True
    else:
        return False

import sys
args = sys.argv[1:]

# OoT NTSC 1.0
dirname = 'ad69c91157f6705e8ab06c79fe08aad47bb57ba7'
codefile = dirname+'/0027 V00A87000 code'
jp_start = 0xF98AC
en_start = 0xFD9EC
en_end = 0x101D94

if len(args) > 1 and (args[1].startswith('v') or args[1].startswith('V')):
    verbose = True
else:
    verbose = False

if args[0] == 'jp':
    textfile = dirname+'/0019 V008EB000 jpn_message_data_static'
    dumpit(codefile, textfile, 'jp', jp_start, en_start - jp_start)
elif args[0] == 'en':
    textfile = dirname+'/0022 V0092D000 nes_message_data_static'
    dumpit(codefile, textfile, 'en', en_start, en_end - en_start)
else:
    raise Exception('unknown language to dump')
