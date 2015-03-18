require "boilerplate"
local addrs = require "addrs"

-- bizhawk lua has some nasty memory leaks at the moment,
-- so instead of creating an object every time,
-- using a template to offset from will do for now.
local actor_t = Actor(0)

local oot = version:sub(1, 2) == "O "
local al_next = addrs.actor_count_1.addr - addrs.actor_count_0.addr

local actor_names
if oot then
    actor_names = require "actor names oot"
else
    actor_names = require "actor names"
end

function T(x, y, s, color, pos)
    color = color or "white"
    pos = pos or "bottomright"
    gui.text(10*x + 2, 16*y + 4, s, nil, color, pos)
end

function T_BR(x, y, s, color) T(x, y, s, color, "bottomright") end
function T_BL(x, y, s, color) T(x, y, s, color, "bottomleft") end
function T_TL(x, y, s, color) T(x, y, s, color, "topleft") end
function T_TR(x, y, s, color) T(x, y, s, color, "topright") end

function pmask(p)
    return bit.band(p, 0x7FFFFFFF)
end

function get_actor_count(i)
    return R4(addrs.actor_count_0.addr + i*al_next)
end

function get_first_actor(i)
    return pmask(R4(addrs.actor_first_0.addr + i*al_next))
end

function get_next_actor(addr)
    return pmask(R4(addr + actor_t.next.addr))
end

function count_actors()
    local counts = {}
    for i = 0, 11 do
        counts[i] = get_actor_count(i)
    end
    return counts
end

function iter_actors(counts)
    local at, ai = 0, 0
    local once = false
    local addr
    return function()
        if once then ai = ai + 1 end
        once = true

        while ai >= counts[at] do
            ai = 0
            at = at + 1
            if at >= 12 then return nil end
        end

        if ai == 0 then
            addr = get_first_actor(at)
        else
            addr = get_next_actor(addr)
            if addr == 0 then
                T_TR(0, 0, "no actor found", "yellow")
                return nil
            end
        end

        return at, ai, addr
    end
end

local seen = {}
local seen_strs = {}
local seen_strs_sorted = {}
local last_any = 0

-- hack to avoid N64 logo spitting errors
local stupid = addrs.actor_count_0.addr - 0x8

while true do
    local any = 0
    local game_count = 0
    local counts = nil

    if R4(stupid) ~= 0 then
        T_BR(0, 14, "stupid", "red")
        any = 0
    else
        counts = count_actors()
        for i = 0, 11 do
            any = any + counts[i]
            T_BR(0, 13 - i, ("#%2i: %2i"):format(i, counts[i]))
        end
        T_BR(0, 1, ("sum:%3i"):format(any))

        if addrs.actor_count then
            game_count = R1(addrs.actor_count.addr)
            if game_count ~= any then
                T_BR(8, 1, "mismatch!", "red")
            end
        end
    end

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

    local needs_update = false
    local at = 2
    local ai = 0
    local j = 0
    for at, ai, addr in iter_actors(counts) do
        --T(0, 0, ("%02i:%02i"):format(at, ai))
        --print(("%02i:%02i"):format(at, ai))
        --local num = R2(addr + actor_t.num.addr)
        local num = R2(addr)
        local name = actor_names[num]

        if name == nil and num < 0x300 then
            name = "NEW"
            actor_names[num] = name
            print(("\t[0x%03X]=\"NEW\","):format(num))

            if actor_t.damage_table and actor_t.hp then
                local dmg = pmask(addr + actor_t.damage_table.addr)
                if dmg == 0 then
                    print("(no damage table)")
                else
                    local hp = R1(addr + actor_t.hp.addr)
                    s = ("%04X\t%02X\t%02X"):format(num, at, hp)
                    for i = 0, 31 do
                        s = s..("\t%02X"):format(R1(dmg + i))
                    end
                    print(s)
                end
            end
        end

        if num > 0x300 then
            print(("BAD %06X %04X (%2i:%2i)"):format(addr, num, at, ai))
            actor_names[num] = "BAD"
        elseif not seen[num] then
            seen[num] = true
            needs_update = true
            local str
            if name:sub(1,1) == "?" then
                str = ("%s (%03X)"):format(name, num)
            else
                str = ("%s"):format(name)
            end
            seen_strs[num] = str
            print(str)
        end

        j = j + 1
        if j > 255 then
            print("something went terribly wrong")
            do return end
        end
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

    if needs_update then
        seen_strs_sorted = sort_by_key(seen_strs)
    end
    for i, t in ipairs(seen_strs_sorted) do
        T_TL(0, i - 1, t.v)
    end

    T_BR(0, 0, ("unique:%3i"):format(#seen_strs_sorted))

    if any > 0 then
        local cursor = pmask(addrs.z_cursor_actor())
        local target = pmask(addrs.z_target_actor())
        local z = target or cursor
        if z then
            local num = R2(z)
            T_TR(0, 0, seen_strs[num])
        end
    end

    emu.frameadvance()
end
