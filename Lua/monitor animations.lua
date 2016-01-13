require "lib.setup"
require "boilerplate"
require "addrs"
require "serialize"

local anim_addr = addrs.link_actor.animation_id.addr
local fn = mm and 'data/_anims_seen.lua' or 'data/_anims_seen_oot.lua'
local anims_seen = deserialize(fn) or {}

while mm or oot do
    local anim_id = mainmemory.read_u16_be(anim_addr)
    local actor_loaded = mainmemory.read_u8(anim_addr - 2) == 4
    local hexid = ('%04X'):format(anim_id)
    local frame = emu.framecount()
    if actor_loaded then
        gui.text(2, 4, hexid, nil, 'white', "bottomleft")
        if not anims_seen[anim_id] then
            anims_seen[anim_id] = true
            print(frame, hexid)
            serialize(fn, anims_seen)
        end
    end
    emu.frameadvance()
end
