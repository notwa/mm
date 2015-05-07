require "boilerplate"
require "addrs.init"
require "classes"
require "messages"

ByteMonitor = Class(Monitor)

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

local unk = ByteMonitor('unk', AL(0xF6, 0x37A))
unk:load('data/_unk.lua')
while mm do
    unk:diff()
    unk:save()
    draw_messages()
    emu.frameadvance()
end
