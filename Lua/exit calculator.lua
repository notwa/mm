require = require "depend"
require "boilerplate"
require "addrs.init"

local scene_names = require "data.scene names"
local entrance_names = require "data.entrance names"

local open = io.open

function sdata(i)
    local a = addrs.scene_table.addr + i*4*3
    -- entrance count, entrance table (ptr), name (ptr)
    return {R4(a), R4(a + 4), R4(a + 8)}
end

function mirror(scene_id)
    if scene_id > 0x80 then
        return 0x100 - scene_id
    end
    return scene_id
end

function calc_dump(a, writer)
    if type(a) ~= "number" then
        writer('[crash]')
        return
    end
    a = deref(R4(a)) or a
    local scene_id = mirror(R1(a))
    local entrance = R1(a + 1)
    local t = entrance_names[scene_id]
    if t == nil then
        writer("err")
        return
    end
    writer(scene_names[scene_id])
    if t[entrance] then
        writer(t[entrance])
    else
        writer("[unknown entrance]")
    end
end

function split_exit(exit)
    return bit.rshift(exit, 9), bit.band(bit.rshift(exit, 4), 0x1F), bit.band(exit, 0xF)
end

function calc(exit)
    console.clear()
    local scene, entrance, offset = split_exit(exit)
    printf("%i, %i, %i", scene, entrance, offset)

    local sd = sdata(scene)
    local first_entrance = deref(sd[2])
    print("# Scene:")
    calc_dump(first_entrance, print)

    if not first_entrance then return end

    local orig_entrance = first_entrance + entrance*4
    local entr_before_offset = deref(R4(orig_entrance))
    print("# Scene + Entrance:")
    calc_dump(entr_before_offset, print)

    if not entr_before_offset then return end

    local final_entrance = entr_before_offset + offset*4
    print("# Scene + Entrance + Offset:")
    calc_dump(final_entrance, print)

    -- TODO: read until \x00
    --print('internal name:')
    --print(asciize(mainmemory.readbyterange(deref(sd[3]), 8)))
end

function dump_all_exits(fn)
    local f = open(fn or 'data/_exits.csv', 'w')
    if f == nil then
        print("couldn't open file for writing")
        return
    end
    f:write('ID,Scene,Entrance,Offset,Original Scene,(entrance),Scene + Entrance,(entrance),Scene + Entrance + Offset,(entrance)\n')
    for i = 0, 0xFFFF do
        local fail = function()
            f:write(('"0x%04X"'):format(i))
            f:write(',,,,,,,,,\n')
        end
        for _ = 1, 1 do -- "continue" hack
            local scene, entrance, offset = split_exit(i)

            local sd = sdata(scene)
            local first_entrance = deref(sd[2])
            if not first_entrance then fail(); break end
            local orig_entrance = first_entrance + entrance*4
            local entr_before_offset = deref(R4(orig_entrance))
            if not entr_before_offset then fail(); break end
            local final_entrance = entr_before_offset + offset*4

            f:write(('"0x%04X",%i,%i,%i'):format(i, scene, entrance, offset))
            local writer = function(...)
                return f:write(',"') and f:write(...) and f:write('"')
            end
            calc_dump(orig_entrance, writer)
            calc_dump(entr_before_offset, writer)
            calc_dump(final_entrance, writer)
            f:write("\n")
        end
    end
    f:close()
end

local old_value = -1
while true do
    local exit_value = addrs.exit_value()
    if exit_value and exit_value ~= old_value then
        console.clear()
        calc(exit_value)
    end
    old_value = exit_value
    emu.frameadvance()
end
