require "boilerplate"
local addrs = require "addrs"
local actor_names = require "actor names"

-- bizhawk lua has some nasty memory leaks at the moment,
-- so instead of creating an object every time,
-- using a template to offset from will do for now.
local actor_t = Actor(0)

function get_actor_count(i)
    return R4(addrs.actor_count_0.addr + i*0xC)
end

function get_first_actor(i)
    return bit.band(R4(addrs.actor_first_0.addr + i*0xC), 0x7FFFFFFF)
end

function get_next_actor(addr)
    return bit.band(R4(addr + actor_t.next.addr), 0x7FFFFFFF)
end

function T(x, y, s, color, pos)
    color = color or "white"
    pos = pos or "bottomright"
    gui.text(10*x + 2, 16*y + 4, s, nil, color, pos)
end

local seen = {}
local seen_strs = {}
local seen_strs_sorted = {}
local last_any = 0

while true do
    local any = 0
    for i = 0, 11 do
        local count = get_actor_count(i)
        T(0, 13 - i, ("#%2i: %2i"):format(i, count), nil, "bottomright")
        any = any + count
    end
    T(0, 1, ("sum:%3i"):format(any), nil, "bottomright")

    if any == 0 then
        seen = {}
        seen_strs = {}
        seen_strs_sorted = {}
        if last_any ~= any then
            print()
            print("# actors wiped #")
            print()
        end
    end

    local seen_new = false

    local actor_type = 2
    local actor_index = 0
    local once = false
    local i = 0
    while any > 0 and last_any ~= any do
        if once and actor_type == 2 and actor_index == 0 then break end
        actor_index = actor_index + 1

        local actor_count = get_actor_count(actor_type)
        while actor_index >= actor_count do
            actor_type = (actor_type + 1) % 12
            actor_count = get_actor_count(actor_type)
            actor_index = 0
        end

        local addr = get_first_actor(actor_type)
        if actor_index > 0 then
            for i = 0, actor_index - 1 do
                addr = get_next_actor(addr)
                if addr == 0 then
                    T(0, 3, "no actor found", "yellow")
                    break
                end
            end
        end
        --T(0, 0, ("%02i:%02i"):format(actor_type, actor_index))
        --print(("%02i:%02i"):format(actor_type, actor_index))

        if addr ~= 0 then
            --local num = R2(addr + actor_t.num.addr)
            local num = R2(addr)
            local name = actor_names[num]


            if num > 0x300 then
                print(("BAD %06X %04X (%2i:%2i)"):format(addr, num, actor_type, actor_index))
                actor_names[num] = "BAD"
            elseif not seen[num] then
                seen[num] = true
                seen_new = true
                local str
                if name:sub(1,1) == "?" then
                    str = ("%s (%03X)"):format(name, num)
                else
                    str = ("%s"):format(name)
                end
                seen_strs[num] = str
                print(str)
            end

            if name == nil and num < 0x300 then
                actor_names[num] = "NEW"
                print(("\t[0x%03X]=\"NEW\","):format(num))

                local dmg = bit.band(addr + actor_t.damage_table.addr, 0x7FFFFFFF)
                if dmg == 0 then
                    print("(no damage table)")
                else
                    local hp = R1(addr + actor_t.hp.addr)
                    s = ("%04X\t%02X\t%02X"):format(num, actor_type, hp)
                    for i = 0, 31 do
                        s = s..("\t%02X"):format(R1(dmg + i))
                    end
                    print(s)
                end
            end
        end

        i = i + 1
        once = true
    end

    last_any = any

    function sort_by_key(t)
        local sorted = {}
        local i = 1
        for k, v in pairs(seen_strs) do
            sorted[i] = {k=k, v=v}
            i = i + 1
        end
        table.sort(sorted, function(a, b) return a.k < b.k end)
        return sorted
    end

    if seen_new then
        seen_strs_sorted = sort_by_key(seen_strs)
    end
    for i, t in ipairs(seen_strs_sorted) do
        T(0, i - 1, t.v, nil, "topleft")
    end

    T(0, 0, ("unique:%3i"):format(#seen_strs_sorted), nil, "bottomright")

    local cursor = bit.band(addrs.z_cursor_actor(), 0x7FFFFFFF)
    local target = bit.band(addrs.z_target_actor(), 0x7FFFFFFF)
    local z = target or cursor
    if z then
        local num = R2(z)
        T(0, 0, seen_strs[num], nil, "topright")
    end

    emu.yield()
end
