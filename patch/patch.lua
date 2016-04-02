package.path = package.path..";./?/init.lua"

local assemble = require "lips"

local function inject(patch, target, offset)
    offset = offset or 0

    local f = io.open(target, 'r+b')

    local function write(pos, line)
        assert(#line == 2, "that ain't const")
        -- TODO: write hex dump format of written bytes
        if pos >= offset then
            pos = pos - offset
        end
        if pos >= 1024*1024*1024 then
            print("you probably don't want to do this:")
            print(("%08X"):format(pos), line)
            return
        end
        f:seek('set', pos)
        f:write(string.char(tonumber(line, 16)))
    end

    -- offset assembly labels so they work properly, and assemble!
    assemble(patch, write, {unsafe=true, offset=offset})

    f:close()
end

local offset = arg[3]
if offset then
    if offset:sub(2) == '0x' then
        offset = tonumber(offset, 16)
    else
        offset = tonumber(offset)
    end
end
inject(arg[1], arg[2], offset)
