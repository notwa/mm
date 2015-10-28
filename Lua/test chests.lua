-- go to a grotto with a red rupee chest, stand in front of it and run this script

local hash = gameinfo.getromhash()
local versions = {
    ['D6133ACE5AFAA0882CF214CF88DABA39E266C078'] = "US10",
    ['5FB2301AACBF85278AF30DCA3E4194AD48599E36'] = "JP10",
}
local version = versions[hash]

local index = 0
local fn = 'lua chest test'

local start, ours, text
if version == 'US10' then
    start = 0x779884 -- the get item table
    ours  = 0x779896 -- the chest we're standing in front of
    text  = 0x3FCE10 -- ascii text buffer
elseif version == 'JP10' then
    start = 0x7797E4 -- the get item table
    ours  = 0x7797F6 -- the chest we're standing in front of
    text  = 0x3FD660 -- no such thing in JP but we need something
end

function draw_index()
    gui.text(304, 8, ("%03i"):format(index), nil, nil, 'bottomleft')
end

function advance()
    draw_index()
    emu.frameadvance()
    draw_index()
    emu.frameadvance()
    draw_index()
    emu.frameadvance()
end

function read_ascii(addr, len)
    local begin = addr
    local bytes = mainmemory.readbyterange(begin, len)
    local str = ""

    -- pairs() won't give us the bytes in order
    -- so we'll set up a table we can use ipairs() on
    local ordered_bytes = {}
    for a, v in pairs(bytes) do
        ordered_bytes[tonumber(a, 16) + 1] = v
    end

    local seq = false
    for i, v in ipairs(ordered_bytes) do
        local c = tonumber(v, 16)
        if c == 9 or c == 10 or c == 13 or (c >= 32 and c < 127) then
            str = str..string.char(c)
            seq = false
        elseif seq == false then
            str = str..' '
            seq = true
        end
    end
    return str
end

client.unpause()
savestate.save(fn)
for off=index*6, 185*6, 6 do
    index = index + 1
    for i=0, 5 do
        local byte = mainmemory.readbyte(start + off + i)
        mainmemory.writebyte(ours + i, byte)
    end
    joypad.set({A=true}, 1)
    advance()
    joypad.set({A=false}, 1)

    local good = false
    for i=1, 9*20 do
        if version == 'JP10' and (index >= 85 and index <= 88) then
            break -- crashes
        end
        advance()
        if mainmemory.readbyte(text + 0xA) == 0xFF then
            if version == 'US10' then
                local begin = text + 0xC
                print(off/6 + 1, read_ascii(begin, 0x100))
                good = true
            else
                for _=1, 40 do
                    advance()
                end
            end
            break
        end
    end
    if not good then
        print(off/6 + 1, '[error]')
    end
    savestate.load(fn)
end
client.pause()
