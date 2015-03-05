require "boilerplate"
local addrs = require "addrs"

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

function get_next_actor(a)
    return bit.band(R4(a + 0x12C), 0x7FFFFFFF)
end

function T(x, y, s, color, pos)
    color = color or "white"
    pos = pos or "bottomright"
    gui.text(10*x + 2, 16*y + 4, s, nil, color, pos)
end

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

    if pressed.left then
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
        T(0, 11 - i, ("#%2i: %2i"):format(i, count), "white", "bottomleft")
        any = any + count
    end

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

        local actor = get_first_actor(actor_type)
        T(0, 2, ('type:  %02X'):format(actor_type))
        T(0, 1, ('index: %02X'):format(actor_index))
        T(0, 0, ('count: %02X'):format(actor_count))
        if actor_index > 0 then
            for i = 0, actor_index do
                actor = get_next_actor(actor)
                if actor == 0 then
                    T(0, 3, "no actor found", "yellow")
                    break
                end
            end
        end
        if actor ~= 0 then
            addrs.camera_target(0x80000000 + actor)
        end
    end

    old_ctrl = ctrl
    emu.yield()
end
