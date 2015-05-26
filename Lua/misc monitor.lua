require "boilerplate"
require "addrs.init"
require "classes"
require "messages"

local unk = ByteMonitor('unk', AL(0xF6, 0x37A))
unk:load('data/_unk.lua')
while mm do
    unk:diff()
    unk:save()
    draw_messages()
    emu.frameadvance()
end
