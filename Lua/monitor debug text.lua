-- use with inject.lua on O EUDB MQ
require "lib.setup"
require "boilerplate"

local buffer = 0x700180

local vfc = A(0x168960, 4)

-- $ tail -f oot\ debug.txt | iconv -f euc-jp
local f = io.open('oot debug.txt', 'w+b')

while version == "O EUDB MQ" do
    local pos = buffer
    local str = ''
    local fmt = '%c'
    while true do
        local b = R1(pos)
        pos = pos + 1
        if b == 0 then
            break
        end
        str = str..string.char(b)
    end
    f:write(str)
    f:flush()
    local old = vfc()
    for i=1,30 do
        emu.frameadvance()
        local new = vfc()
        if new ~= old then break end
    end
end

f:close()
