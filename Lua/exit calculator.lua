require = require "depend"
require "boilerplate"
require "addrs.init"

local scene_names = require "data.scene names"
local entrance_names = require "data.entrance names"

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

function calc_dump(a)
    if type(a) ~= "number" then
        print('[crash]')
        return
    end
    if is_ptr(R4(a)) then
        a = deref(R4(a))
    end
    local scene_id = mirror(R1(a))
    local entrance = R1(a + 1)
    local t = entrance_names[scene_id]
    if t == nil then
        print("err")
        return
    end
    print(scene_names[scene_id])
    print(t[entrance])
end

function calc(exit)
    console.clear()
    local scene = bit.rshift(exit, 9)
    local entrance = bit.band(bit.rshift(exit, 4), 0x1F)
    local offset = bit.band(exit, 0xF)
    printf("%i, %i, %i", scene, entrance, offset)

    local sd = sdata(scene)
    local first_entrance = deref(sd[2])
    print("# Scene:")
    calc_dump(first_entrance)

    if not first_entrance then return end

    local orig_entrance = first_entrance + entrance*4
    local entr_before_offset = deref(R4(orig_entrance))
    print("# Scene + Entrance:")
    calc_dump(entr_before_offset)

    if not entr_before_offset then return end

    local final_entrance = entr_before_offset + offset*4
    print("# Scene + Entrance + Offset:")
    calc_dump(final_entrance)

    -- TODO: read until \x00
    --print('internal name:')
    --print(asciize(mainmemory.readbyterange(deref(sd[3]), 8)))
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
