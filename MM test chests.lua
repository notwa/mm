-- go to a grotto with a red rupee chest, stand in front of it and run this script
-- US 1.0 of course

local start = 0x779884 -- the get item table
local ours  = 0x779896 -- the chest we're standing in front of
local text  = 0x3FCE10 -- ascii text buffer

function advance()
    emu.frameadvance()
    emu.frameadvance()
    emu.frameadvance()
end

local fn = 'lua chest test'
savestate.save(fn)
client.unpause()
for off=0, 185*6, 6 do
    for i=0, 5 do
        local byte = mainmemory.readbyte(start + off + i)
        mainmemory.writebyte(ours + i, byte)
    end
    gui.addmessage(("%02X"):format(mainmemory.readbyte(start + off)))
    joypad.set({A=true}, 1)
    advance()
    joypad.set({A=false}, 1)
    local good = false
    for i=1, 9*20 do
        advance()
        if mainmemory.readbyte(text + 0xA) == 0xFF then
            local begin = text + 0xC
            local bytes = mainmemory.readbyterange(begin, 0x100)
            local str = ""

            -- pairs() won't give us the bytes in order
            -- so we'll set up a table we can use ipairs() on
            local ordered_bytes = {}
            for a, v in pairs(bytes) do
                ordered_bytes[tonumber(a, 16) - begin + 1] = v
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

            print(off/6 + 1, str)

            good = true
            break
        end
    end
    if not good then
        print(off/6 + 1, '[error]')
    end
    savestate.load(fn)
end
client.pause()
