require "boilerplate"
local addrs = require "addrs"
local actor_names = require "actor names"

local actor_t = Actor(0) -- lolololol memory leaks

local actor_type = 2
local actor_index = 0

local pressed = {}
local old_ctrl = {}

function get_actor_count(i)
    return R4(addrs.actor_count_0.addr + i*0xC)
end

function get_first_actor(i)
    return bit.band(R4(addrs.actor_first_0.addr + i*0xC), 0x7FFFFFFF)
end

function get_next_actor(addr)
    --return bit.band(Actor(addr).next(), 0x7FFFFFFF)
    return bit.band(R4(addr + actor_t.next.addr), 0x7FFFFFFF)
end

function T(x, y, s, color, pos)
    color = color or "white"
    pos = pos or "bottomright"
    gui.text(10*x + 2, 16*y + 4, s, nil, color, pos)
end

damage_names = {
    [0]="Nut",
    "Stick",
    "Epona",
    "Bomb",
    "(Z)Fins",
    "Bow",
    "Mirror?",
    "Hook",
    "(G)Punch",
    "Sword",
    "(G)Pound",
    "Fire",
    "Ice",
    "Light",
    "(G)Spikes",
    "(D)Spin",
    "(D)Shoot",
    "(D)Dive",
    "(D)Bomb",
    "(Z)Barrier",
    "?",
    "?",
    "Bush",
    "(Z)Karate",
    "M. Spin",
    "(F)Beam",
    "Roll",
    "?",
    "?",
    "?",
    "?",
    "Keg",
}

while true do
    local j = joypad.getimmediate()

    local ctrl = {
        enter = j["P1 L"],
        up    = j["P1 DPad U"],
        down  = j["P1 DPad D"],
        left  = j["P1 DPad L"],
        right = j["P1 DPad R"],
    }

    for k, v in pairs(ctrl) do
        pressed[k] = ctrl[k] and not old_ctrl[k]
    end

    if pressed.left or ctrl.enter then
        actor_index = actor_index - 1
    end
    if pressed.right then
        actor_index = actor_index + 1
    end
    if pressed.down then
        -- follow Link again
        actor_type = 2
        actor_index = 0
    end

    local any = 0
    for i = 0, 11 do
        local count = get_actor_count(i)
        T(0, 12 - i, ("#%2i: %2i"):format(i, count), "white", "bottomleft")
        any = any + count
    end
    T(0, 0, ("sum:%3i"):format(any), "white", "bottomleft")

    local actor_count = get_actor_count(actor_type)
    if any > 0 then
        while actor_index < 0 do
            actor_type = (actor_type - 1) % 12
            actor_count = get_actor_count(actor_type)
            actor_index = actor_count - 1
        end
        while actor_index >= actor_count do
            actor_type = (actor_type + 1) % 12
            actor_count = get_actor_count(actor_type)
            actor_index = 0
        end

        local addr = get_first_actor(actor_type)
        T(0, 2, ('type:  %02X'):format(actor_type))
        T(0, 1, ('index: %02X'):format(actor_index))
        T(0, 0, ('count: %02X'):format(actor_count))
        if actor_index > 0 then
            for i = 0, actor_index - 1 do
                addr = get_next_actor(addr)
                if addr == 0 then
                    T(0, 3, "no actor found", "yellow")
                    break
                end
            end
        end
        if addr ~= 0 then
            --local actor = Actor(addr)
            local num = R2(addr + actor_t.num.addr)
            local var = R2(addr + actor_t.var.addr)
            local hp  = R1(addr + actor_t.hp.addr)
            T(0, 3, ('80%06X'):format(addr))
            T(0, 5, ('No.:  %03X'):format(num), 'cyan')
            T(0, 4, ('Var: %04X'):format(var))
            T(0, 6, ('HP:  %02X'):format(hp))
            local name = actor_names[num]
            if name then
                local color = name == "TODO" and "red" or "orange"
                T(0, 8, name, color)
            else
                actor_names[num] = "TODO"
                print(('\t[0x%03X]="???",'):format(num))
            end
            --T(0, 3, ('Type:  %02X'):format(R1(addr+2)))

            local dmg_t = R4(addr + actor_t.damage_table.addr)
            local dmg = bit.band(dmg_t, 0x7FFFFFFF)
            if dmg == 0 then
                T(0, 7, "no damage table")
            else
                for i = 0, 31 do
                    --T(0, 11 - i/4, ('dmg %02i: %08X'):format(i, R4(dmg + i)))
                    local name = damage_names[i]
                    local str = ('%9s: %02X'):format(name, R1(dmg + i))
                    local pos = 'topleft'
                    if i >= 16 then i = i - 16; pos = 'topright' end
                    T(0, i, str, 'white', pos)
                end

                if pressed.up then
                    console.clear()
                    s = ('%04X\t%02X\t%02X'):format(num, actor_type, hp)
                    for i = 0, 31 do
                        s = s..('\t%02X'):format(R1(dmg + i))
                    end
                    print(s)
                end
            end

            --T(0, 12, ("%08X"):format(addrs.camera_target()), 'white', 'bottomleft')
            -- avoid floating point error by our write small
            W1(addrs.camera_target.addr, 0x80)
            W3(addrs.camera_target.addr + 1, addr)
        end
    end

    old_ctrl = ctrl
    emu.yield()
end
