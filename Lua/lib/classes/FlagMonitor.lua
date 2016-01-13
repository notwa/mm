local printf = rawget(_G, 'dprintf') or printf

local Monitor = require "classes.Monitor"
local FlagMonitor = Class(Monitor)

function FlagMonitor:init(name, a, ignore)
    Monitor.init(self, name, a)
    self.ignore = ignore or {}
end

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
            local curious = self.modified[ib] == "curious"
            if not self.modified[ib] or curious then
                self.modified[ib] = true
                self.dirty = true
                if not curious then
                    str = str..' (NEW!)'
                else
                    str = str..' (!!!)'
                end
            end
            if not self.ignore[str] then
                printf('%s  @%i', str, now)
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

function FlagMonitor:wipe()
    for i = self.begin, self.begin+self.len-1 do
        W1(i, 0)
    end
end

function FlagMonitor:set_unknowns()
    self.save = function() end -- no clutter
    local mod = self.modified_backup
    if not mod then
        mod = {}
        for i, v in pairs(self.modified) do
            mod[i] = v
        end
        self.modified_backup = mod
    end
    for i = 0, self.len-1 do
        local v = R1(self.begin + i)
        for which = 0, 7 do
            local ib = i*8 + which
            if not mod[ib] and bit.band(v, 2^which) == 0 then
                v = v + 2^which
            end
        end
        --printf("%04X = %02X", self.begin + i, sum)
        W1(self.begin + i, v)
    end
end

return FlagMonitor
