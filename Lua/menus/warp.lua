if not mm then
    return Menu{
        Screen{
            Text("Sorry, no warping for you!"),
            Back(),
        },
    }
end

local scene_names = require "data.scene names"
local entrance_names = require "data.entrance names"
local ins = table.insert

-- we should really figure this out in code,
-- but hardcoding will do for now.
local scene_id_to_entrance_id = {
    [0]=0x12,
    0x0B,
    0x0A,
    0x10,
    0x11,
    0x0C,
    0x00,
    0x0D,
    nil,
    nil,
    0x07,
    nil,
    nil,
    nil,
    0x08,
    nil,
    0x13,
    0x14,
    0x15,
    0x16,
    0x17,
    0x18,
    0x19,
    0x1A,
    0x1B,
    0x1C,
    0x1D,
    0x1E,
    0x1F,
    0x20,
    0x21,
    0x22,
    0x23,
    0x24,
    0x25,
    0x26,
    0x27,
    0x28,
    0x29,
    0x2A,
    0x2B,
    0x2C,
    0x2D,
    0x2E,
    0x2F,
    0x30,
    nil,
    0x32,
    0x33,
    0x34,
    0x35,
    nil,
    0x37,
    0x38,
    0x39,
    nil,
    0x3B,
    0x3C,
    0x3D,
    0x3E,
    0x3F,
    0x40,
    0x41,
    0x42,
    0x43,
    0x44,
    0x45,
    0x46,
    0x47,
    0x48,
    0x49,
    0x4A,
    0x4B,
    0x4C,
    0x4D,
    0x4E,
    0x4F,
    0x50,
    0x51,
    0x52,
    0x53,
    0x54,
    0x55,
    0x56,
    0x57,
    0x58,
    0x59,
    0x5A,
    0x5B,
    0x5C,
    0x5D,
    0x5E,
    0x5F,
    0x60,
    0x61,
    0x62,
    0x63,
    0x64,
    0x65,
    0x66,
    0x67,
    0x68,
    0x69,
    0x6A,
    0x6B,
    0x6C,
    0x6D,
    0x6E,
    0x6F,
    0x70,
}

local function make_exit_value(s, e, c)
    return bit.lshift(s, 9) + bit.lshift(e, 4) + c
end

local scenes_pages = {}
for si=0x00,0x7F do
    local i = scene_id_to_entrance_id[si]
    local page = math.floor(si/16) + 1

    if si % 16 == 0 then
        scenes_pages[page] = {}
        local s = ("Warp to Scene #%i/8"):format(page)
        ins(scenes_pages[page], Text(s))
    end

    local entrance_items = {}
    local entrances = {}
    local scene_name = '[crash]'
    if i ~= nil then
        entrances = entrance_names[i]
        scene_name = scene_names[i]
    end

    ins(entrance_items, Text( ("Warp to %s"):format(scene_name) ))

    for j=0,32 do
        local ename = entrances[j]
        if ename == nil then
            if j ~= 0 then break end
            ename = "[crash?]"
        end
        local callback = Callbacks()
        function callback:on()
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

    if si % 16 == 15 then
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
