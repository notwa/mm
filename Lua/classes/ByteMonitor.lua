local Monitor = require "classes.Monitor"
local ByteMonitor = Class(Monitor)

function ByteMonitor:mark(i, x, x1)
    local now = emu.framecount()
    local str = ('%02i=%02X (%s)'):format(i, x, self.name)
    if not self.modified[i] then
        self.modified[i] = {}
    end
    if not self.modified[i][x] then
        self.modified[i][x] = true
        self.dirty = true
        str = str..' (NEW!)'
    end
    printf('%s  @%i', str, now)
    message(str, 180)
end

return ByteMonitor
