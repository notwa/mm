local Monitor = require "classes.Monitor"
local SceneFlagMonitor = Class(Monitor)

function SceneFlagMonitor:mark(i, x, x1)
    if not x1 then return end
    local now = emu.framecount()
    local diff = bit.bxor(x, x1)
    for which = 0, 7 do
        if bit.band(diff, 2^which) ~= 0 then
            local state = bit.band(x, 2^which) ~= 0 and 1 or 0
            local col = (3 - i)*8 + which
            local str = ('%s: %02i=%i'):format(self.name, col, state)
            printf('%s  @%i', str, now)
            message(str, 180)
        end
    end
end

return SceneFlagMonitor
