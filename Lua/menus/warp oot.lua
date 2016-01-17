local ins = table.insert
local entrance_names = require "data.entrance names oot"
local maxscene = #entrance_names

local per_page = 16
local pagecount = math.ceil((maxscene + 1)/per_page)

local scenes_pages = {}
for si=0, maxscene do
    local i = si
    local page = math.floor(si/per_page) + 1

    if si % per_page == 0 then
        scenes_pages[page] = {}
        local s = ("Warp to Scene #%i/%i"):format(page, pagecount)
        ins(scenes_pages[page], Text(s))
    end

    local entrance_items = {}
    local entrances = entrance_names[i]
    local scene_name = entrances.name

    ins(entrance_items, Text( ("Warp to %s"):format(scene_name) ))

    for j=0,24 do
        local e = entrances[j]
        local ename = "n/a"
        local edest = 0
        if e == nil then
            if j ~= 0 then break end
            ename = "n/a"
            edest = 0
        else
            ename = e[1]
            edest = e[2]
            if ename == nil then
                if j ~= 0 then break end
                ename = "n/a"
                edest = 0
            end
        end
        local callback = function()
            addrs.warp_destination(edest)
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
end

local menu = Menu{}
for i, v in ipairs(scenes_pages) do
    ins(v, Text(""))
    ins(v, Back())
    ins(menu.screens, Screen(v))
end

return menu
