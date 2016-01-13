require "lib.setup"
require "boilerplate"
require "addrs"
require "messages"
require "classes"
require "actors"

local suffix = oot and " oot" or ""
local damage_names = require("data.damage names"..suffix)

-- creating an object every time is a bit slow, so
-- using a template to offset from will do for now.
local actor_t = Actor(0)

-- for figuring out actor variables
local debug_mode = false

local debug_watch = mm and {
    {'room_number', '%02X'},
    --{'x_rot_init', '%04X'},
    --{'y_rot_init', '%04X'},
    --{'z_rot_init', '%04X'},
    --{'unk_1A', '%02X'},
    {'unk_1E', '%02X'},
    {'unk_20', '%08X'},
    {'unk_22', '%04X'},
    --{'unnamed_x_rot', '%04X'},
    --{'unnamed_y_rot', '%04X'},
    --{'unnamed_z_rot', '%04X'},
    {'unk_36', '%04X'},
    {'unk_38', '%02X'},
    {'x', '%9.3f'},
    {'y', '%9.3f'},
    {'z', '%9.3f'},
    {'lin_vel_old', '%9.3f'},
    {'unk_54', '%9.3f'},
    {'unk_74', '%9.3f'},
    {'unk_78', '%9.3f'},
} or {}

local function longbinary(x)
    return ('%032s'):format(bizstring.binary(x))
end

local function focus(actor, dump)
    local color = actor.name:sub(1,1) == "?" and "red" or "orange"
    local flags = longbinary(actor.flags)
    local y = debug_mode and #debug_watch + 9 or 9
    local write = function(color, fmt, ...)
        T_BL(0, y, color, fmt, ...)
        y = y - 1
        return y + 1
    end

    write(nil,    'Hi: %s', flags:sub(1,16))
    write(nil,    'Lo: %s', flags:sub(17,32))
    write(color, actor.name)
    write(nil,    'HP:  %02X', actor.hp)
    write('cyan', 'No.: %03X', actor.num)
    write(nil,    'Var: %04X', actor.var)
    write(nil,    '80%06X', actor.addr)
    write(nil, 'type:  %3i', actor.at)
    write(nil, 'index: %3i', actor.ai)
    write(nil, 'count: %3i', actor.type_count)

    if debug_mode then
        local a = Actor(actor.addr)

        for i, t in ipairs(debug_watch) do
            write(nil, '%12s: '..t[2], t[1], a[t[1]]())
        end

        if dump then
            a.unk_38(math.random(0, 0xFF))
            --print(R1(actor.addr + 0x1E))
            --W1(actor.addr + actor_t.unk_1E.addr, 0xFF)
        end
        --a.x_old(a.x())
        --a.y_old(a.y())
        --a.z_old(a.z())

        return -- skip damage table crap
    end

    local dmg = deref(R4(actor.addr + actor_t.damage_table.addr))
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

    if dump then
        console.clear()
        local s = ("%04X\t%02X\t%02X"):format(actor.num, actor.at, actor.hp)
        if dmg then
            for i = 0, 31 do
                s = s..("\t%02X"):format(R1(dmg + i))
            end
        end
        print(s)
    end
end

local input_handler = InputHandler{
    enter = "P1 L",
    up    = "P1 DPad U",
    down  = "P1 DPad D",
    left  = "P1 DPad L",
    right = "P1 DPad R",
}

globalize{
    focus = focus,
}

local al = ActorLister(input_handler, debug_mode)
event.onexit(function() al = nil end, 'actor cleanup')
event.onloadstate(function() if al then al:wipe() end end, 'actor wipe')
while oot or mm do
    local now = emu.framecount()
    al:runwrap(now)
    print_deferred()
    emu.frameadvance()
end
