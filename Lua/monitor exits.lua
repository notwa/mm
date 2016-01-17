require "lib.setup"
require "boilerplate"
require "addrs"

local entrance_names = require "data.entrance names"

local open = io.open

local function sdata(i)
    local a = addrs.scene_table.addr + i*4*3
    -- entrance count, entrance table (ptr), name (ptr)
    return {R4(a), R4(a + 4), R4(a + 8)}
end

local function mirror(scene_id)
    if scene_id > 0x80 then
        return 0x100 - scene_id
    end
    return scene_id
end

local function calc_dump(a, writer)
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
    writer(t.name)
    if t[entrance] then
        writer(t[entrance])
    else
        writer("[unknown entrance]")
    end
end

local function split_exit(exit)
    return bit.rshift(exit, 9), bit.band(bit.rshift(exit, 4), 0x1F), bit.band(exit, 0xF)
end

local function calc(exit)
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

local function dump_all_exits(fn)
    local f = open(fn or 'data/_exits.csv', 'w')
    if f == nil then
        print("couldn't open file for writing")
        return
    end
    f:write('ID,Scene,Entrance,Offset,Scene + Entrance + Offset,(entrance),Scene + Entrance,(entrance),Original Scene,(entrance)\n')
    for i = 0, 0xFFFF do
        local scene, entrance, offset = split_exit(i)
        f:write(('0x%04X,%i,%i,%i'):format(i, scene, entrance, offset))
        local fail = function()
            f:write(',,,,,,\n')
        end
        for _ = 1, 1 do -- "continue" hack
            local sd = sdata(scene)
            local first_entrance = deref(sd[2])
            if not first_entrance then fail(); break end
            local orig_entrance = first_entrance + entrance*4
            local entr_before_offset = deref(R4(orig_entrance))
            if not entr_before_offset then fail(); break end
            local final_entrance = entr_before_offset + offset*4

            local writer = function(...)
                return f:write(',"') and f:write(...) and f:write('"')
            end
            calc_dump(final_entrance, writer)
            calc_dump(entr_before_offset, writer)
            calc_dump(first_entrance, writer)
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
