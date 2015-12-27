require = require "depend"
require "boilerplate"

local buffer = 0x700070

local vfc = A(0x168960, 4)

while true do
    local pos = buffer
    local str = ''
    while true do
        local b = R1(pos)
        pos = pos + 1
        if b == 0 then
            break
        end
        if b < 0x80 then
            str = str..string.char(b)
        else
            str = str..'?'
        end
    end
    print(str)
    local old = vfc()
    for i=1,30 do
        emu.frameadvance()
        local new = vfc()
        if new ~= old then break end
    end
    console.clear() -- delete this if you want
end
