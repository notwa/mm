require "boilerplate"
require "addrs.init"

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

ShortMonitor = Class()
function ShortMonitor:init(name, a)
    self.name = name
    self.begin = a.addr
    self.len = a.type
    self.once = false
    self.old_bytes = {}

    local modified = {}
    for i=0, self.len/2 do
        modified[i] = false
    end
    self.modified = modified
end

function ShortMonitor:diff()
    local bytes = mainmemory.readbyterange(self.begin, self.len)
    local old_bytes = self.old_bytes
    if self.once then
        for k, v in pairs(bytes) do
            local i = tonumber(k) - self.begin
            local x = tonumber(v)
            local x1 = tonumber(old_bytes[k])
            if x ~= x1 then
                self:mark(i, x, x1)
            end
        end
    end
    self.old_bytes = bytes
    self.once = true
end

function ShortMonitor:mark(i, x, x1)
    local ih = math.floor(i/2)
    if self.modified[ih] == false then
        self.modified[ih] = true
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
        local vs = mod and '[variable]' or ('%04X'):format(value)
        local s = ('%2X\t%2i\t%i\t%s\n'):format(block, page+1, row+1, vs)
        buff = buff..s
    end
    print(buff)
end

-- 2 bytes each, 16 values per page, 6 pages per block, 29 blocks
-- = 5568 bytes (0x15C0)
me = ShortMonitor('me', A(0x210A24, 0x15C0))

while true do
    me:diff()
    emu.frameadvance()
end
