require "boilerplate"
require "addrs.init"
require "classes"

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
    self.name = name
    self.begin = a.addr
    self.len = a.type
    self.once = false
    self.old_bytes = {}
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
        end
    end
end

local weg = FlagMonitor('weg', addrs.week_event_reg)
local inf = FlagMonitor('inf', addrs.event_inf)
--local mmb = FlagMonitor('mmb', A(0x24405A, 3))
local mmb = FlagMonitor('mmb', A(0x1F3F3A, 3))
while true do
    weg:diff()
    inf:diff()
    mmb:diff()
    emu.frameadvance()
end
