require "boilerplate"
require "addrs.init"
require "classes"
require "serialize"

local blocknames = {
    'R ', 'RS', 'RO', 'RP',
    'RQ', 'RM', 'RY', 'RD',
    'RU', 'RI', 'RZ', 'RC',
    'RN', 'RK', 'RX', 'Rc',
    'Rs', 'Ri', 'RW', 'RA',
    'RV', 'RH', 'RG', 'Rm',
    'Rn', 'RB', 'Rd', 'Rk',
    'Rb',
}

function butts(ih)
    local block = math.floor(ih/16/6)
    local ir = ih - block*16*6
    local page = math.floor(ir/16)
    local row = ir - page*16
    return block, page, row
end

ShortMonitor = Class(Monitor)
function ShortMonitor:init(name, a)
    self.name = name
    self.begin = a.addr
    self.len = a.type
    self.once = false
    self.old_bytes = {}

    self.modified = {}
    self.dirty = false
end

function ShortMonitor:mark(i, x, x1)
    local ih = math.floor(i/2)
    if not self.modified[ih] then
        self.modified[ih] = true
        self.dirty = true
        local block, page, row = butts(ih)
        printf('%2s Page %1i Row %3i', blocknames[block+1], page+1, row+1)
    end
end

function ShortMonitor:dump()
    local buff = ''
    for i=0, self.len/2 - 1 do
        local ih = i
        local block, page, row = butts(ih)
        local mod = self.modified[ih]
        local value = R2(self.begin + ih)
        local vs = mod and 'n/a' or ('%04X'):format(value)
        local name = ('%s%02i'):format(blocknames[block+1], page*16 + row)
        local s = ('%s\t%i\t%i\t%s\n'):format(name, page+1, row+1, vs)
        buff = buff..s
    end
    print(buff)
end

-- 2 bytes each, 16 values per page, 6 pages per block, 29 blocks
-- = 5568 bytes (0x15C0)
me = ShortMonitor('me', A(0x210A24, 0x15C0))

me.modified = deserialize('_ootmemod.lua') or {}

while version == "O EUDB MQ" do
    me:diff()
    if me.dirty then
        serialize(me.modified, ('_ootmemod.lua'))
        me.dirty = false
    end
    emu.frameadvance()
end
