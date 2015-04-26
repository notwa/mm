require "boilerplate"

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

function poop(x, x1, i, name)
    local now = emu.framecount()
    local diff = bit.bxor(x, x1)
    for which = 0, 7 do
        if bit.band(diff, 2^which) ~= 0 then
            local state = bit.band(x, 2^which) ~= 0 and 1 or 0
            local str = ('%02i,%i=%i (%s)'):format(i, which, state, name)
            if not ignore[str] then
                printf('%s  @%i', str, now)
                gui.addmessage(str)
            end
        end
    end
end

FlagMonitor = Class()

function FlagMonitor:init(name, begin, len)
    self.name = name
    self.begin = begin
    self.len = len
    self.once = false
    self.old_bytes = {}
end

function FlagMonitor:diff()
    local bytes = mainmemory.readbyterange(self.begin, self.len)
    local old_bytes = self.old_bytes
    if self.once then
        for k, v in pairs(bytes) do
            local i = tonumber(k) - self.begin
            local x = tonumber(v)
            local x1 = tonumber(old_bytes[k])
            if x ~= x1 then
                poop(x, x1, i, self.name)
            end
        end
    end
    self.old_bytes = bytes
    self.once = true
end

-- US 1.0 addresses for the time being
local weg = FlagMonitor('weg', 0x1F0568, 100) -- week_event_reg
local inf = FlagMonitor('inf', 0x1F067C, 8)   -- event_inf
local mmb = FlagMonitor('mmb', 0x1F3F3A, 8)   -- mask_mask_bit (bad address?)
while true do
    weg:diff()
    inf:diff()
    mmb:diff()
    emu.frameadvance()
end
