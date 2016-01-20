require "lib.setup"
require "boilerplate"
require "addrs"
require "serialize"

local entrance_names = require "data.entrance names"

local fn = mm and 'data/_exits_seen.lua' or 'data/_exits_seen_oot.lua'
local exits_seen = deserialize(fn) or {}

-- one-way entrances
-- 2C00 going to top of clock tower (usually)

-- one-way exits
-- 5010 thrown out of deku palace
-- 8490 down ikana waterfall
-- 3440 into castle from above
-- 3450 into trap fall from above castle blah

-- TODO: get peeking into/out of shop
-- TODO: get blue warp in deku race
-- TODO: is getting thrown out after sonata different?
-- TODO: get graveyard stuff

-- TODO: mark more one-way stuff (remember: it's anything that isn't paired!)

while true do
    local exit_id = addrs.warp_destination()
    local exit_hex = ('%04X'):format(exit_id)
    local frame = emu.framecount()
    if not exits_seen[exit_hex] then
        exits_seen[exit_hex] = true
        print(frame, exit_hex)
        serialize(fn, exits_seen)
    end
    emu.frameadvance()
end
