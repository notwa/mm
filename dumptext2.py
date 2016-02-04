#!/usr/bin/env python3

import sys
import os, os.path
from io import BytesIO
import struct
import re

lament = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)

unpack = lambda fmt, data: struct.unpack(fmt, bytes(data))

extended='°ÀÁÂÄÇÈÉÊËÌÍÎÏÑÒÓÔÖÙÚÛÜßàáâäçèéêëìíîïñòóôöùúûü¡¿ͣ'

def parse_jp_text(f):
    s = ''
    bs = bytearray()
    def arg2():
        return '{:04X}'.format(unpack('>H', f.read(2))[0]).encode('shift-jis')
    lastx = 0
    special = f.read(12) # TODO
    while 1:
        b1 = f.read(1)
        if not b1:
            break
        b2 = f.read(1)
        if not b2:
            break
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

        if x == 0x0020:
            bs += b' ' # doesn't seem to be fullwidth?
        elif x == 0x0500:
            # end mark
            break
        elif x == 0x0009:
#           if verbose:
#               bs += b'[pause??]'
            bs += b'\n\n'
        elif x == 0x000A:
            bs += b'\n'
        elif x == 0x000B:
#           if verbose:
#               bs += b'[pause?]'
            bs += b'\n\n'
        elif x == 0x000C:
            if verbose:
                bs += b'[pause]'
            bs += b'\n\n'
        elif x == 0x001F:
            if verbose:
                bs += b'[spaces '+arg2()+b']'
            else:
                bs += b' '*int(arg2(), 16)
        elif x == 0x0100:
            bs += '[あ?]'.encode('shift-jis')
        elif x == 0x0101:
            if verbose:
                bs += b'[instant on]'
        elif x == 0x0102:
            if verbose:
                bs += b'[instant off]'
        elif x == 0x0103:
            if verbose:
                bs += b'[no skip sound?]'
        elif x == 0x0104:
            if verbose:
                bs += b'[keepalive]'
        elif x == 0x0110:
            if verbose:
                bs += b'[next wait '+arg2()+b']'
            else:
                arg2()
            bs += b'\n\n'
        elif x == 0x0111: # 0x1C
            if verbose:
                bs += b'[end wait '+arg2()+b']'
            else:
                arg2()
        elif x == 0x0112: # 0x1D
            if verbose:
                bs += b'[end wait alt 0112 '+arg2()+b']'
            else:
                arg2()
        elif x == 0x0120:
            bs += b'[sound '+arg2()+b']'
        elif x == 0x0128:
            if verbose:
                bs += b'[wait '+arg2()+b']'
            else:
                arg2()
        elif x == 0x0135: # unique to JP?
            bs += b'[unk 0135]'
        elif x == 0x0201:
            bs += b'[failed song]'
        elif x == 0x0202:
            if verbose:
                bs += b'[two-choice]'
        elif x == 0x0203:
            if verbose:
                bs += b'[three-choice]'
        elif x == 0x0204:
            bs += b'[postman timer]'
        elif x == 0x0208:
            bs += b'[result time?]'
        elif x == 0x020B:
            bs += b'[highscore? 020B]'
        elif x == 0x020C:
            bs += b'[rupee prompt]'
        elif x == 0x020D:
            bs += b'[rupees selected]'
        elif x == 0x020E:
            bs += b'[rupees]'
        elif x == 0x020F:
            bs += b'[hours/minutes remaining]'
        elif x == 0x021C: # X人目
            bs += b'[fairies]'
        elif x == 0x021D: # X匹
            bs += b'[gold skulltulas]'
        elif x == 0x021E:
            bs += b'[score? 021E]'
        elif x == 0x021F:
            bs += b'[score? 021F]'
        elif x == 0x0220:
            bs += b'[doggy prompt]'
        elif x == 0x0221:
            bs += b'[bombers code prompt]'
        elif x == 0x0222:
            bs += b'[item prompt]'
        elif x == 0x0224:
            bs += b'[soar destination]'
        elif x == 0x0225:
            bs += b'[lottery prompt]'
        elif x == 0x0227:
            bs += b'[fairies remaining]'
        elif x == 0x0228:
            bs += b'[fairies remaining]'
        elif x == 0x0229:
            bs += b'[fairies remaining]'
        elif x == 0x022A:
            bs += b'[fairies remaining]'
        elif x == 0x022B:
            bs += b'[witch archery]'
        elif x == 0x022C:
            bs += b'[winning numbers]'
        elif x == 0x022D:
            bs += b'[ticket numbers]'
        elif x == 0x022E:
            bs += b'[item worth]'
        elif x == 0x022F:
            bs += b'[bombers code]'
        elif x == 0x0230:
            if verbose:
                bs += b'[end convo]'
        elif x == 0x0231:
            bs += b'[skull color]'
        elif x == 0x0232:
            bs += b'[skull color]'
        elif x == 0x0233:
            bs += b'[skull color]'
        elif x == 0x0234:
            bs += b'[skull color]'
        elif x == 0x0235:
            bs += b'[skull color]'
        elif x == 0x0236:
            bs += b'[skull color]'
        elif x == 0x0237:
            bs += b'[hours remaining]'
        elif x == 0x0238:
            bs += b'[time until morning]'
        elif x == 0x0240:
            if verbose:
                bs += b'[no skip?]'
        elif x == 0x0306:
            bs += b'[highscore? 0306]'
        elif x == 0x0307:
            bs += b'[epona highscore]'
        elif x == 0x0308:
            bs += b'[highscore? 0308]'
        elif x == 0x0309:
            bs += b'[highscore? 0309]'
        elif x == 0x030A:
            bs += b'[deku highscore]'
        elif x == 0x030B:
            bs += b'[deku highscore]'
        elif x == 0x030C:
            bs += b'[deku highscore]'
        elif x == 0x0310:
            bs += b'[highscore? 0310]'
        elif x == 0x037E:
            bs += b'[unk 037E]'
        elif x1 == 0x20: # 0x00-0x08
            if x2 == 0x00:
                if verbose:
                    bs += b'[white]'
            elif x2 == 0x01:
                if verbose:
                    bs += b'[red]'
            elif x2 == 0x02:
                if verbose:
                    bs += b'[green]'
            elif x2 == 0x03:
                if verbose:
                    bs += b'[dark blue]'
            elif x2 == 0x04:
                if verbose:
                    bs += b'[yellow]'
            elif x2 == 0x05:
                if verbose:
                    bs += b'[light blue]'
            elif x2 == 0x06:
                if verbose:
                    bs += b'[pink]'
            elif x2 == 0x07:
                if verbose:
                    bs += b'[silver]'
            elif x2 == 0x08:
                if verbose:
                    bs += b'[orange]'
            else:
                raise Exception('unknown color')
        elif x == 0x839F:
            bs += b'[A]'
        elif x == 0x83A0:
            bs += b'[B]'
        elif x == 0x83A1:
            bs += b'[C]'
        elif x == 0x83A2:
            bs += b'[L]'
        elif x == 0x83A3:
            bs += b'[R]'
        elif x == 0x83A4:
            bs += b'[Z]'
        elif x == 0x83A5:
            bs += b'[C Up]'
        elif x == 0x83A6:
            bs += b'[C Down]'
        elif x == 0x83A7:
            bs += b'[C Left]'
        elif x == 0x83A8:
            bs += b'[C Right]'
        elif x == 0x83A9:
            bs += b'[Triangle]'
        elif x == 0x83AA:
            bs += b'[Control Stick]'
        elif x == 0x83AB:
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
            lament()
            lament(bs.decode('shift-jis'))
            lament('unknown {:04X}'.format(x))
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
    special = f.read(11) # TODO
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
        if b'\x7F' <= b1 <= b'\xAF':
            bs += extended[x - 0x7F].encode('utf-8')
            continue
        elif x == 0x00:
            if verbose:
                bs += b'[white]'
        elif x == 0x01:
            if verbose:
                bs += b'[red]'
        elif x == 0x02:
            if verbose:
                bs += b'[green]'
        elif x == 0x03:
            if verbose:
                bs += b'[dark blue]'
        elif x == 0x04:
            if verbose:
                bs += b'[yellow]'
        elif x == 0x05:
            if verbose:
                bs += b'[light blue]'
        elif x == 0x06:
            if verbose:
                bs += b'[pink]'
        elif x == 0x07:
            if verbose:
                bs += b'[silver]'
        elif x == 0x08:
            if verbose:
                bs += b'[orange]'
        elif x == 0x0A:
            if verbose:
                bs += b'[spaces? '+arg()+b']'
            else:
                arg()
        elif x == 0x0B:
            bs += b'[record?]'
        elif x == 0x0C:
            bs += b'[fairies]'
        elif x == 0x0D:
            bs += b'[gold skulltulas]'
        elif x == 0x10:
            if verbose:
                bs += b'[pause]'
            bs += b'\n\n'
        elif x == 0x11:
            bs += b'\n'
        elif x == 0x12:
            bs += b'\n\n'
        elif x == 0x13:
            bs += b'\n'
        elif x == 0x15:
            if verbose:
                bs += b'[no skip?]'
        elif x == 0x17:
            if verbose:
                bs += b'[instant on]'
        elif x == 0x18:
            if verbose:
                bs += b'[instant off]'
        elif x == 0x19:
            if verbose:
                bs += b'[no skip sound?]'
        elif x == 0x1A:
            if verbose:
                bs += b'[keepalive]'
        elif x == 0x1B:
            if verbose:
                bs += b'[next wait '+arg()+arg()+b']'
            else:
                arg()
                arg()
            bs += b'\n\n'
        elif x == 0x1C:
            if verbose:
                bs += b'[end wait '+arg()+arg()+b']'
            else:
                arg()
                arg()
        elif x == 0x1D:
            if verbose:
                bs += b'[end wait alt '+arg()+arg()+b']'
            else:
                arg()
                arg()
        elif x == 0x1E:
            bs += b'[sound '+arg()+arg()+b']'
        elif x == 0x1F:
            if verbose:
                bs += b'[wait '+arg()+arg()+b']'
            else:
                arg()
                arg()
        elif x == 0x16:
            bs += b'[Link]'
        elif x == 0xC2:
            if verbose:
                bs += b'[two-choice]'
        elif x == 0xC3:
            if verbose:
                bs += b'[three-choice]'
        elif x == 0xB0:
            bs += b'[A]'
        elif x == 0xB1:
            bs += b'[B]'
        elif x == 0xB2:
            bs += b'[C]'
        elif x == 0xB3:
            bs += b'[L]'
        elif x == 0xB4:
            bs += b'[R]'
        elif x == 0xB5:
            bs += b'[Z]'
        elif x == 0xB6:
            bs += b'[C Up]'
        elif x == 0xB7:
            bs += b'[C Down]'
        elif x == 0xB8:
            bs += b'[C Left]'
        elif x == 0xB9:
            bs += b'[C Right]'
        elif x == 0xBA:
            bs += b'[Triangle]'
        elif x == 0xBB:
            bs += b'[Control Stick]'
        elif x == 0xBF:
            # end marker
            break
        elif x == 0xC1:
            bs += b'[failed song]'
        elif x == 0xC4:
            bs += b'[postman timer]'
        elif x == 0xC8:
            bs += b'[deku score]'
        elif x == 0xCB:
            bs += b'[score]'
        elif x == 0xCC:
            bs += b'[rupee prompt]'
        elif x == 0xCD:
            bs += b'[rupees selected]'
        elif x == 0xCE:
            bs += b'[rupees]'
        elif x == 0xCF:
            bs += b'[hours remaining CF]'
        elif x == 0xD0:
            bs += b'[doggy bet]'
        elif x == 0xD1:
            bs += b'[bombers code prompt]'
        elif x == 0xD2:
            bs += b'[item prompt]'
        elif x == 0xD4:
            bs += b'[soar destination]'
        elif x == 0xD5:
            bs += b'[lottery prompt]'
        elif x == 0xD7:
            bs += b'[fairies remaining]'
        elif x == 0xD8:
            bs += b'[fairies remaining]'
        elif x == 0xD9:
            bs += b'[fairies remaining]'
        elif x == 0xDA:
            bs += b'[fairies remaining]'
        elif x == 0xDB:
            bs += b'[witch archery]'
        elif x == 0xDC:
            bs += b'[winning numbers]'
        elif x == 0xDD:
            bs += b'[ticket numbers]'
        elif x == 0xDE:
            bs += b'[item worth]'
        elif x == 0xDF:
            bs += b'[bombers code]'
        elif x == 0xE0:
            if verbose:
                bs += b'[end convo]'
        elif x == 0xE1:
            bs += b'[skull color]'
        elif x == 0xE2:
            bs += b'[skull color]'
        elif x == 0xE3:
            bs += b'[skull color]'
        elif x == 0xE4:
            bs += b'[skull color]'
        elif x == 0xE5:
            bs += b'[skull color]'
        elif x == 0xE6:
            bs += b'[skull color]'
        elif x == 0xE7:
            bs += b'[hours remaining E7]'
        elif x == 0xE8:
            bs += b'[time until morning]'
        elif x == 0xFA:
            bs += b'[deku highscore]'
        elif x == 0xFB:
            bs += b'[deku highscore]'
        elif x == 0xFC:
            bs += b'[deku highscore]'
        elif x == 0xF6:
            bs += b'[octorok archery highscore]'
        elif x == 0xF9:
            bs += b'[epona highscore]'
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
        text = re.sub('\n\n+', '\n\n', text)
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

# MM (U) 1.0 and (J) 1.0
if len(args) > 1 and (args[1].startswith('v') or args[1].startswith('V')):
    verbose = True
else:
    verbose = False

if args[0] == 'jp':
    dirname = 'dump/mm-JP10-5fb2301aacbf85278af30dca3e4194ad48599e36'
    codefile = dirname+'/0028 V00B5F000'
    jp_start = 0x11A398
    jp_end = 0x123128
    textfile = dirname+'/0026 V00AF9000'
    dumpit(codefile, textfile, 'jp', jp_start, jp_end - jp_start)
elif args[0] == 'en':
    dirname = 'dump/mm-US10-d6133ace5afaa0882cf214cf88daba39e266c078'
    codefile = dirname+'/0031 V00B3C000'
    en_start = 0x1210D8
    en_end = 0x12A048
    textfile = dirname+'/0029 V00AD1000'
    dumpit(codefile, textfile, 'en', en_start, en_end - en_start)
else:
    raise Exception('unknown language to dump')
