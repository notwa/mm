package.path = package.path..";./?/init.lua"

local assemble = require "lips"

local function inject(patch, target)
    local f = io.open(target, 'r+b')

    local function write(pos, line)
        assert(#line == 2, "that ain't const")
        -- TODO: write hex dump format of written bytes
        --print(("%08X"):format(pos), line)
        f:seek('set', pos)
        f:write(string.char(tonumber(line, 16)))
    end

    -- offset assembly labels so they work properly, and assemble!
    assemble(patch, write, {unsafe=true, offset=0})

    f:close()
end

inject(arg[1], arg[2])
