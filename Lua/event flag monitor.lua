require "boilerplate"
require "addrs.init"
require "classes"
require "messages"

local ignore = {
    -- every time a scene (un)loads
    ['92,7=0 (weg)'] = true,
    ['92,7=1 (weg)'] = true,
    -- night transition available
    ['05,2=0 (inf)'] = true,
    ['05,2=1 (inf)'] = true,
    -- daily postman crap
    ['27,6=0 (weg)'] = true,
    ['27,7=0 (weg)'] = true,
    ['28,0=0 (weg)'] = true,
    ['28,1=0 (weg)'] = true,
    ['28,2=0 (weg)'] = true,
    ['27,6=1 (weg)'] = true,
    ['27,7=1 (weg)'] = true,
    ['28,0=1 (weg)'] = true,
    ['28,1=1 (weg)'] = true,
    ['28,2=1 (weg)'] = true,
}

FlagMonitor = Class(Monitor)

function FlagMonitor:mark(i, x, x1)
    local now = emu.framecount()
    local diff = bit.bxor(x, x1)
    for which = 0, 7 do
        if bit.band(diff, 2^which) ~= 0 then
            local state = bit.band(x, 2^which) ~= 0 and 1 or 0
            local str
            if self.oot then
                local row = math.floor(i/2)
                local col = which + (1 - (i % 2))*8
                str = ('%02i,%X=%i (%s)'):format(row, col, state, self.name)
            else
                str = ('%02i,%i=%i (%s)'):format(i, which, state, self.name)
            end
            local ib = i*8 + which
            if not self.modified[ib] then
                self.modified[ib] = true
                self.dirty = true
                str = str..' (NEW!)'
            end
            if not ignore[str] then
                dprintf('%s  @%i', str, now)
                message(str, 180)
            end
        end
    end
end

function FlagMonitor:dump(current)
    local t = current and self:read() or self.modified

    local size = self.oot and 16 or 8
    local rows = math.floor(self.len/size*8)

    local buff = self.name..'\n'

    buff = buff..'  \t'
    for col = size-1, 0, -1 do
        buff = buff..('%X'):format(col)
        if col % 4 == 0 then buff = buff..' ' end
    end

    for row = 0, rows-1 do
        s = ('%02i\t'):format(row)
        for col = size-1, 0, -1 do
            local B, b = row, col
            if size == 16 then
                B = row*2 + (col < 8 and 1 or 0)
                b = col % 8
            end
            local ib = B*8 + b
            local v
            if current then v = bit.band(t[B], 2^b) > 0 else v = t[ib] end
            s = s..(v and '1' or '0')
            if col % 4 == 0 then s = s..' ' end
        end
        buff = buff..'\n'..s
    end

    return buff
end

if mm then
    weg = FlagMonitor('weg', addrs.week_event_reg)
    inf = FlagMonitor('inf', addrs.event_inf)
    --mmb = FlagMonitor('mmb', addrs.mask_mask_bit) -- 100% known, no point
    weg:load('data/_weg.lua')
    inf:load('data/_inf.lua')
    fms = {weg, inf}
elseif oot then
    eci = FlagMonitor('eci', AL(0xED4, 0x1C))
    igi = FlagMonitor('igi', AL(0xEF0,  0x8))
    it_ = FlagMonitor('it ', AL(0xEF8, 0x3C))
    ei_ = FlagMonitor('ei ', AL(0x13FA, 0x8))
    eci:load('data/_eci.lua')
    igi:load('data/_igi.lua')
    it_:load('data/_it.lua')
    ei_:load('data/_ei.lua')
    fms = {eci, igi, it_, ei_}
    for i, fm in ipairs(fms) do fm.oot = true end
end

while mm or oot do
    for i, fm in ipairs(fms) do
        fm:diff()
        fm:save()
    end
    print_deferred()
    draw_messages()
    emu.frameadvance()
end
