local US_10 = 0x3FFD40
local EU_DBG = 0x461C1A

local versions = {
    ['D6133ACE5AFAA0882CF214CF88DABA39E266C078'] = US_10,
    ['B38B71D2961DFFB523020A67F4807A4B704E347A'] = EU_DBG,
}

local hash = gameinfo.getromhash()
local anim_addr = versions[hash]

local anims_seen = {}

while true do
    local anim_id = mainmemory.read_u16_be(anim_addr)
    local actor_loaded = mainmemory.read_u8(anim_addr - 2) == 4
    local hexid = ('%04X'):format(anim_id)
    local frame = emu.framecount()
    if actor_loaded then
        gui.text(2, 4, hexid, nil, 'white', "bottomleft")
        if not anims_seen[anim_id] then
            anims_seen[anim_id] = true
            print(frame, hexid)
        end
    end
    emu.yield()
end
