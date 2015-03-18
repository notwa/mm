require "boilerplate"
require "addrs"

-- bizhawk lua has some nasty memory leaks at the moment,
-- so instead of creating an object every time,
-- using a template to offset from will do for now.
local actor_t = Actor(0)

local oot = version:sub(1, 2) == "O "
local al_next = addrs.actor_count_1.addr - addrs.actor_count_0.addr

local actor_names, damage_names
if oot then
    actor_names = require "actor names oot"
    damage_names = require "damage names oot"
else
    actor_names = require "actor names"
    damage_names = require "damage names"
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
        if not counts then return nil end
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

local ctrl
local pressed = {}
local old_ctrl = {}
function update_input()
    local j = joypad.getimmediate()

    ctrl = {
        enter = j["P1 L"],
        up    = j["P1 DPad U"],
        down  = j["P1 DPad D"],
        left  = j["P1 DPad L"],
        right = j["P1 DPad R"],
    }

    for k, v in pairs(ctrl) do
        pressed[k] = ctrl[k] and not old_ctrl[k]
    end

    old_ctrl = ctrl
end

local seen = {}
local seen_strs = {}
local seen_strs_sorted = {}
local last_any = 0

local focus_at = 2
local focus_ai = 0

-- hack to avoid N64 logo spitting errors
local stupid = addrs.actor_count_0.addr - 0x8

while true do
    local any = 0
    local game_count = 0
    local counts = nil

    update_input()

    if pressed.left then
        focus_ai = focus_ai - 1
    end
    if pressed.right then
        focus_ai = focus_ai + 1
    end
    if pressed.down then
        -- follow Link again
        focus_at = 2
        focus_ai = 0
    end

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
    else
        while focus_ai < 0 do
            focus_at = (focus_at - 1) % 12
            focus_ai = counts[focus_at] - 1
        end
        while focus_ai >= counts[focus_at] do
            focus_at = (focus_at + 1) % 12
            focus_ai = 0
        end
    end

    local focus_link = focus_at == 2 and focus_ai == 0

    local needs_update = false
    for at, ai, addr in iter_actors(counts) do
        local num = R2(addr + actor_t.num.addr)
        local name = actor_names[num]

        if not name then
            name = "NEW"
            actor_names[num] = name
            print(("\t[0x%03X]=\"NEW\","):format(num))
        end

        if not seen[num] then
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

        local focus_this = at == focus_at and ai == focus_ai

        if focus_this and not focus_link then
            T_BL(0, 2, ('type:  %02X'):format(at))
            T_BL(0, 1, ('index: %02X'):format(ai))
            T_BL(0, 0, ('count: %02X'):format(counts[at]))

            local var = R2(addr + actor_t.var.addr)
            local hp  = R1(addr + actor_t.hp.addr)
            T_BL(0, 3, ('80%06X'):format(addr))
            T_BL(0, 5, ('No.:  %03X'):format(num), 'cyan')
            T_BL(0, 4, ('Var: %04X'):format(var))
            T_BL(0, 6, ('HP:  %02X'):format(hp))

            local color = name:sub(1,1) == "?" and "red" or "orange"
            T_BL(0, 7, name, color)

            local dmg = pmask(R4(addr + actor_t.damage_table.addr))
            if dmg > 0 then
                for i = 0, 31 do
                    local name = damage_names[i]
                    local str = ('%9s: %02X'):format(name, R1(dmg + i))
                    local pos = 'topleft'
                    if i >= 16 then i = i - 16; pos = 'topright' end
                    T(0, i, str, nil, pos)
                end
            end

            if pressed.up then
                console.clear()
                s = ("%04X\t%02X\t%02X"):format(num, at, hp)
                if dmg > 0 then
                    for i = 0, 31 do
                        s = s..("\t%02X"):format(R1(dmg + i))
                    end
                end
                print(s)
            end
        end

        if focus_this then
            W1(addrs.camera_target.addr, 0x80)
            W3(addrs.camera_target.addr + 1, addr)
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

    if focus_link then
        for i, t in ipairs(seen_strs_sorted) do
            T_TL(0, i - 1, t.v)
        end
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
