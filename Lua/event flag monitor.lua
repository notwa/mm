require "boilerplate"
require "addrs.init"
require "classes"
require "serialize"

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
function FlagMonitor:init(name, a)
    Monitor.init(self, name, a)
    self.seen = {}
    self.dirty = false
end

function FlagMonitor:mark(i, x, x1)
    local now = emu.framecount()
    local diff = bit.bxor(x, x1)
    for which = 0, 7 do
        if bit.band(diff, 2^which) ~= 0 then
            local state = bit.band(x, 2^which) ~= 0 and 1 or 0
            local str = ('%02i,%i=%i (%s)'):format(i, which, state, self.name)
            if not ignore[str] then
                printf('%s  @%i', str, now)
                gui.addmessage(str)
            end
            local ib = i*8 + which
            if not self.seen[ib] then
                self.seen[ib] = true
                self.dirty = true
            end
        end
    end
end

function FlagMonitor:load(fn)
    self.seen = deserialize(fn) or {}
    self.dirty = false
    self.fn = fn
end

function FlagMonitor:save(fn)
    if self.dirty then
        serialize(fn or self.fn, self.seen)
        self.dirty = false
    end
end

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
    emu.frameadvance()
end
