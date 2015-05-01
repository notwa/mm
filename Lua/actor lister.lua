require "boilerplate"
require "addrs.init"

-- check for errors in the actor linked lists
local validate = true

-- bizhawk lua has some nasty memory leaks at the moment,
-- so instead of creating an object every time,
-- using a template to offset from will do for now.
local actor_t = Actor(0)

local suffix = oot and " oot" or ""
local actor_names  = require("data.actor names"..suffix)
local damage_names = require("data.damage names"..suffix)

function sort_by_key(t)
    local sorted = {}
    local i = 1
    for k, v in pairs(t) do
        sorted[i] = {k=k, v=v}
        i = i + 1
    end
    table.sort(sorted, function(a, b) return a.k < b.k end)
    return sorted
end

function T(x, y, color, pos, fmt, ...)
    gui.text(10*x + 2, 16*y + 4, fmt:format(...), nil, color or "white", pos or "bottomright")
end

function T_BR(x, y, color, ...) T(x, y, color, "bottomright", ...) end
function T_BL(x, y, color, ...) T(x, y, color, "bottomleft",  ...) end
function T_TL(x, y, color, ...) T(x, y, color, "topleft",     ...) end
function T_TR(x, y, color, ...) T(x, y, color, "topright",    ...) end

function get_actor_count(i)
    return R4(addrs.actor_counts[i].addr)
end

function get_first_actor(i)
    return deref(R4(addrs.actor_firsts[i].addr))
end

function get_next_actor(addr)
    return deref(R4(addr + actor_t.next.addr))
end

function get_prev_actor(addr)
    return deref(R4(addr + actor_t.prev.addr))
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
    local addr

    local y = 1
    local complain = function(s)
        s = s..(" (%2i:%3i)"):format(at, ai)
        T_TR(0, y, "yellow", s)
        y = y + 1
    end

    local iterate
    iterate = function()
        if ai == 0 then
            addr = get_first_actor(at)
            if validate and addr and get_prev_actor(addr) then
                complain("item before first")
            end
        else
            local prev = addr
            addr = get_next_actor(addr)
            if validate then
                if addr and prev ~= get_prev_actor(addr) then
                    complain("previous mismatch")
                end
            end
        end

        if not addr then
            if validate then
                if ai < counts[at] then
                    -- known case: romani ranch on first/third night
                    complain("list ended early")
                elseif ai > counts[at] then
                    complain("list ended late")
                end
            end

            ai = 0
            at = at + 1
            if at == 12 then return nil end
            return iterate()
        else
            local temp = ai
            ai = ai + 1
            return at, temp, addr
        end
    end

    return iterate
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

local focus_at = 2
local focus_ai = 0

-- hack to avoid N64 logo spitting errors
local stupid = addrs.actor_counts[0].addr - 0x8

local seen_once = {}
local seen_strs = {}
local seen_strs_sorted = {}

local before = 0
local wait = 0

function wipe()
    if #seen_strs_sorted > 0 then
        print()
        print("# actors wiped #")
        print()
    end
    seen_once = {}
    seen_strs = {}
    seen_strs_sorted = {}
end

local function run(now)
    local game_counts = nil
    local seen = {}
    local cursor, target

    update_input()

    if pressed.left  then focus_ai = focus_ai - 1 end
    if pressed.right then focus_ai = focus_ai + 1 end
    if pressed.down then
        -- follow Link again
        focus_at = 2
        focus_ai = 0
    end

    if R4(stupid) ~= 0 then
        T_BR(0, 0, "red", "stupid")
        return
    end

    game_counts = count_actors()
    local any = 0
    for i = 0, 11 do
        any = any + game_counts[i]
        T_BR(0, 13 - i, nil, "#%2i: %2i", i, game_counts[i])
    end
    T_BR(0, 1, nil, "sum:%3i", any)

    local actors_by_type = {[0]={},{},{},{},{},{},{},{},{},{},{},{}} -- 12
    local new_counts = {[0]=0,0,0,0,0,0,0,0,0,0,0,0} -- 12
    if any > 0 then
        any = 0
        for at, ai, addr in iter_actors(game_counts) do
            actors_by_type[at][ai] = addr
            new_counts[at] = new_counts[at] + 1
            any = any + 1
        end
    end

    if any == 0 then
        wipe()
    else
        while focus_ai < 0 do
            focus_at = (focus_at - 1) % 12
            focus_ai = new_counts[focus_at] - 1
        end
        while focus_ai >= new_counts[focus_at] do
            focus_at = (focus_at + 1) % 12
            focus_ai = 0
        end
        cursor = deref(addrs.z_cursor_actor())
        target = deref(addrs.z_target_actor())
    end

    local focus_link = focus_at == 2 and focus_ai == 0
    local needs_update = false

    for at, actors in pairs(actors_by_type) do
      for ai, addr in pairs(actors) do -- FIXME: sorry for this pseudo-indent
        local num = R2(addr + actor_t.num.addr)
        local name = actor_names[num]
        local focus_this = at == focus_at and ai == focus_ai

        seen[num] = true

        if not name then
            name = "NEW"
            actor_names[num] = name
            print(("\t[0x%03X]=\"NEW\","):format(num))
        end

        if not seen_once[num] then
            seen_once[num] = now
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

        if (focus_this and not focus_link) or addr == target then
            T_BL(0, 2, nil, 'type:  %3i', at)
            T_BL(0, 1, nil, 'index: %3i', ai)
            T_BL(0, 0, nil, 'count: %3i', new_counts[at])

            local var = R2(addr + actor_t.var.addr)
            local hp  = R1(addr + actor_t.hp.addr)
            T_BL(0, 3, nil,    '80%06X', addr)
            T_BL(0, 5, 'cyan', 'No.:  %03X', num)
            T_BL(0, 4, nil,    'Var: %04X', var)
            T_BL(0, 6, nil,    'HP:  %02X', hp)

            local color = name:sub(1,1) == "?" and "red" or "orange"
            T_BL(0, 7, color, name)

            local dmg = deref(R4(addr + actor_t.damage_table.addr))
            if dmg then
                for i = 0, 31 do
                    local name = damage_names[i]
                    local str = ('%9s: %02X'):format(name, R1(dmg + i))

                    if i >= 16 then
                        T_TR(0, i - 16, nil, str)
                    else
                        T_TL(0, i, nil, str)
                    end
                end
            end

            if pressed.up then
                console.clear()
                s = ("%04X\t%02X\t%02X"):format(num, at, hp)
                if dmg then
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
    end

    if needs_update then
        seen_strs_sorted = sort_by_key(seen_strs)
    end

    if focus_link and not target then
        for i, t in ipairs(seen_strs_sorted) do
            local color = 'white'
            if seen_once[t.k] and now - 60 <= seen_once[t.k] then
                color = 'lime'
            end
            if not seen[t.k] then
                color = 'orange'
            end
            T_TL(0, i - 1, color, t.v)
        end
    end

    T_BR(0, 0, nil, "unique:%3i", #seen_strs_sorted)

    if any > 0 then
        local z = target or cursor
        if z then
            local num = R2(z)
            T_TR(0, 0, nil, seen_strs[num])
        end
    end
end

local function runwrap(now)
    if now < before then wait = 2 end
    before = now
    if wait > 0 then
        -- prevent script from lagging reversing
        wait = wait - 1
        if wait == 0 then wipe() end
    else
        run(now)
    end
end

event.onloadstate(wipe, 'actor wipe')
while oot or mm do
    local now = emu.framecount()
    runwrap(now)
    emu.frameadvance()
end
