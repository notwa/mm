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
            if oot then
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
                printf('%s  @%i', str, now)
                message(str, 180)
            end
        end
    end
end

if mm then
    local weg = FlagMonitor('weg', addrs.week_event_reg)
    local inf = FlagMonitor('inf', addrs.event_inf)
    local mmb = FlagMonitor('mmb', addrs.mask_mask_bit)
    weg:load('data/_weg.lua')
    inf:load('data/_inf.lua')
    while mm do
        weg:diff()
        inf:diff()
        mmb:diff()
        weg:save()
        inf:save()
        draw_messages()
        emu.frameadvance()
    end
elseif oot then
    local eci = FlagMonitor('eci', AL(0xED4, 0x1C))
    local igi = FlagMonitor('igi', AL(0xEF0,  0x8))
    local it_ = FlagMonitor('it ', AL(0xEF8, 0x3C))
    local ei_ = FlagMonitor('ei ', AL(0x13FA, 0x8))
    eci:load('data/_eci.lua')
    igi:load('data/_igi.lua')
    it_:load('data/_it.lua')
    ei_:load('data/_ei.lua')
    eci.oot = true
    igi.oot = true
    it_.oot = true
    ei_.oot = true
    while oot do
        eci:diff()
        igi:diff()
        it_:diff()
        ei_:diff()
        eci:save()
        igi:save()
        it_:save()
        ei_:save()
        draw_messages()
        emu.frameadvance()
    end
end
