local Monitor = require "classes.Monitor"
local ByteMonitor = Class(Monitor)

local printf = rawget(_G, 'dprintf') or printf

function ByteMonitor:mark(i, x, x1)
    if self.ignore and self:ignore(i) then return end
    local now = emu.framecount()
    local str = ('%04X=%02X (%s)'):format(i, x, self.name)
    if self.byvalue then
        if not self.modified[i] then
            self.modified[i] = {}
        end
        if not self.modified[i][x] then
            self.modified[i][x] = true
            self.dirty = true
            str = str..' (NEW!)'
        end
    else
        if not self.modified[i] then
            self.modified[i] = true
            self.dirty = true
            str = str..' (NEW!)'
        end
    end
    printf('%s  @%i', str, now)
    message(str, 180)
end

return ByteMonitor
