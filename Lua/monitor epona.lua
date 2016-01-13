require "lib.setup"
require "boilerplate"
require "addrs"
require "messages"
require "actors"

local actor_names = require "data.actor names"

local epona_addr = 0
while true do
    local nearest = {}
    local offset = 0x800000

    for at, ai, addr in iter_actors() do
        local actor_number = R2(addr)
        local name = actor_names[actor_number] or "[error]"
        local size = R4(addr - 0xC) -- read linked list data above the actor
        if actor_number == 0x00D then
            epona_addr = addr
        end

        if epona_addr then
            local diff = addr - epona_addr
            if diff >= 0 and diff < offset then
                offset = diff
                nearest.name = name
                nearest.addr = addr
                nearest.at = at
                nearest.ai = ai
                nearest.size = size
            end
        end
    end

    if nearest.addr then
        local color = offset <= nearest.size and 'white' or 'yellow'
        T_BR(0, 4, 'white', 'Epona: %06X', epona_addr)
        T_BR(0, 3, 'white', '%s: %06X', nearest.name, nearest.addr)
        T_BR(0, 2, color, 'Offset: %06X', offset)
        T_BR(0, 1, color, 'Size: %06X', nearest.size)
        T_BR(0, 0, 'white', 'Type, Index: %2i, %2i', nearest.at, nearest.ai)
    else
        T_BR(0, 0, 'yellow', 'Epona not found')
        epona_addr = nil
    end

    emu.frameadvance()
end
