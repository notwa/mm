local ins = table.insert
local entrance_names = require "data.entrance names"
local scene_id_to_entrance_id = require "data.scene to entrance"

local function make_exit_value(s, e, c)
    return bit.lshift(s, 9) + bit.lshift(e, 4) + c
end

local per_page = 16

local function fill_entrances(entrance_items, entrances, si)
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
end

local scenes_pages = {}
if entrance_names.custom_order then
    local lut = {}
    for si=0x00,0x7F do
        local i = scene_id_to_entrance_id[si]
        if i ~= nil then
            local e = entrance_names[i]
            if e.name ~= nil then
                --print(e.name, ("%04X"):format(si * 0x200))
                lut[e.name] = {si=si, i=i}
            end
        end
    end

    local page = 1
    scenes_pages[page] = {}
    for i, v in ipairs(entrance_names.custom_order) do
        if v == "\n" then
            page = page + 1
            scenes_pages[page] = {}
        elseif lut[v] ~= nil then
            local entrance_items = {}
            local entrances = entrance_names[lut[v].i]
            local scene_name = entrances.name

            ins(entrance_items, Text( ("Warp to %s"):format(scene_name) ))
            fill_entrances(entrance_items, entrances, lut[v].si)
            local entrance_menu = Menu{Screen(entrance_items)}
            ins(scenes_pages[page], LinkTo(scene_name, entrance_menu))
        else
            ins(scenes_pages[page], Text(v))
        end
    end

    for i=1,page do
        local s = ("Warp to Scene #%i/%i"):format(i, page)
        ins(scenes_pages[i], 1, Text(s))
        ins(scenes_pages[i], Text(""))
        ins(scenes_pages[i], Back())
    end

else
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
        fill_entrances(entrance_items, entrances, si)
        local entrance_menu = Menu{Screen(entrance_items)}
        ins(scenes_pages[page], LinkTo(scene_name, entrance_menu))

        if si % per_page == per_page - 1 then
            ins(scenes_pages[page], Text(""))
            ins(scenes_pages[page], Back())
        end
    end
end

local screens = {}
for i, v in ipairs(scenes_pages) do
    ins(screens, Screen(v))
end

return Menu(screens)
