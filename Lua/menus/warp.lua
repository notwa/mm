local ins = table.insert
local entrance_names = require "data.entrance names"
local scene_id_to_entrance_id = require "data.scene to entrance"

local function make_exit_value(s, e, c)
    return bit.lshift(s, 9) + bit.lshift(e, 4) + c
end

local per_page = 16

local scenes_pages = {}
for si=0x00,0x7F do
    local i = scene_id_to_entrance_id[si]
    local page = math.floor(si/per_page) + 1

    if si % per_page == 0 then
        scenes_pages[page] = {}
        local s = ("Warp to Scene #%i/8"):format(page)
        ins(scenes_pages[page], Text(s))
    end

    local entrance_items = {}
    local entrances = {}
    local scene_name = '[crash]'
    if i ~= nil then
        entrances = entrance_names[i]
        scene_name = entrances.name
    end

    ins(entrance_items, Text( ("Warp to %s"):format(scene_name) ))

    for j=0,32 do
        local ename = entrances[j]
        if ename == nil then
            if j ~= 0 then break end
            ename = "[crash?]"
        end
        local callback = function()
            addrs.warp_destination(make_exit_value(si,j,0))
            addrs.warp_begin(0x14)
        end
        ins(entrance_items, Oneshot(ename, callback))
    end

    ins(entrance_items, Text(""))
    ins(entrance_items, Text("Cutscenes... (TODO)"))
    ins(entrance_items, Text(""))
    ins(entrance_items, Back())
    local entrance_menu = Menu{Screen(entrance_items)}
    ins(scenes_pages[page], LinkTo(scene_name, entrance_menu))

    if si % per_page == per_page - 1 then
        ins(scenes_pages[page], Text(""))
        ins(scenes_pages[page], Back())
    end
end

return Menu{
    Screen(scenes_pages[1]),
    Screen(scenes_pages[2]),
    Screen(scenes_pages[3]),
    Screen(scenes_pages[4]),
    Screen(scenes_pages[5]),
    Screen(scenes_pages[6]),
    Screen(scenes_pages[7]),
    Screen(scenes_pages[8]),
}
