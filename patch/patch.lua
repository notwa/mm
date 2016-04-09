package.path = package.path..";./?/init.lua"

local assemble = require "lips"

local function inject(patch, target, offset, erom, eram)
    offset = offset or 0

    local f = io.open(target, 'r+b')
    if not f then
        print("file not found:", target)
        return
    end

    local function write(pos, line)
        assert(#line == 2, "that ain't const")
        if erom and eram and pos >= eram then
            pos = pos - eram + erom
        elseif pos >= offset then
            pos = pos - offset
        end
        if pos >= 1024*1024*1024 then
            print("you probably don't want to do this:")
            print(("%08X"):format(pos), line)
            return
        end
        f:seek('set', pos)

        -- TODO: write hex dump format of written bytes
        print(("%08X    %s"):format(pos, line))

        f:write(string.char(tonumber(line, 16)))
    end

    -- offset assembly labels so they work properly, and assemble!
    assemble(patch, write, {unsafe=true, offset=offset})

    f:close()
end

local function parsenum(s)
    if s:sub(2) == '0x' then
        s = tonumber(s, 16)
    else
        s = tonumber(s)
    end
    return s
end

local offset = arg[3]
local extra_rom = arg[4]
local extra_ram = arg[5]
if offset then offset = parsenum(offset) end
if extra_rom then extra_rom = parsenum(extra_rom) end
if extra_ram then extra_ram = parsenum(extra_ram) end
inject(arg[1], arg[2], offset, extra_rom, extra_ram)
