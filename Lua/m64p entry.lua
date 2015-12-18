print()
package.path = package.path..';./mm/Lua/?.lua'
require = require "depend"
require "boilerplate"

local function once()
    require "addrs.init"
    print(m64p.rom.settings.MD5, version)
end

--[[
80000000 to 80800000    RDRAM
90000000 to 92000000    probably ROM
A0000000 to A0800000    RDRAM mirror?
A3F00000 to A4000000    RDRAM registers
A4000000 to A4900000?
B0000000 to B2000000    ROM mirror?
--]]

local oldbutts = 0
local function main()
    local butts = addrs.buttons()
    if butts & 0x0020 > oldbutts & 0x0020 then -- L button
        local ok, err = pcall(dofile, 'mm/Lua/inject.lua')
        if not ok then print(err) end
    end
    oldbutts = butts
end

local vi_count = 0
--local lastvf = 0
local function vi_callback()
    vi_count = vi_count + 1
    if vi_count == 1 then
        once()
    end
    if vi_count <= 1 then
        return
    end
    --local vf = addrs.visual_frame()
    --if vf > lastvf then
    if true then
        local ok, err = pcall(main)
        if not ok then
            print(err)
            m64p:unregisterCallback('vi', vi_callback)
            return
        end
    end
    --lastvf = vf
end
m64p:registerCallback('vi', vi_callback)
