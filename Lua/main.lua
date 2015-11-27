print('')
require "boilerplate"

local function once()
    require "addrs.init"
    print(m64p.rom.settings.MD5)
end

local function main()
    addrs.hearts(16*1.5)
end

local vi_count = 0
local function vi_callback()
    vi_count = vi_count + 1
    if vi_count == 1 then
        once()
    end
    local ok, err = pcall(main)
    if not ok then
        print(err)
        m64p:unregisterCallback('vi', vi_callback)
        return
    end
end
m64p:registerCallback('vi', vi_callback)
