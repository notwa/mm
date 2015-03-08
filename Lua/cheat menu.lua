require "boilerplate"
local addrs = require "addrs"

local close = {text="close", type="close"}

local menu = {
    {
        close,
        {text="hey"},
        {text="L to levitate", type="toggle", id="levitate"},
        {text="levitate", type="hold", call_id="levitate"},
        {text="everything", type="oneshot", call_id="everything"},
        active = 1,
    },
    {
        close,
        {text="kill link", type="oneshot", call_id="kill"},
        {text="some flags", type="control"}, -- how to handle this?
        -- i guess with a function like update_text
        -- and self_render and handle_input basically
        -- or call_id="submenu" options={yada yada} 
        {text="k"},
        active = 1,
    },
    active = 1,
}

local active_menu = nil

local menu_state = {
    levitate = false,
}

local menu_calls = {
    levitate = function(item, state)
        addrs.z_vel(16)
    end,
    kill = function(item, state)
        addrs.hearts(0)
    end,
    set = function(item, state)
        A(item.addr, item.type)(item.value)
    end,
    everything = function(item, state)
        dofile("oneshot.lua")
    end,
}

function T(x, y, s, color)
    color = color or "white"
    gui.text(10*x + 2, 16*y + 4, s, nil, color, "bottomright")
end

function draw_row(row, row_number, is_active)
    local color = is_active and "cyan" or "white"
    if row.type == "toggle" then
        T(4, row_number, row.text, color)
        T(0, row_number, "[ ]", "yellow")
        if menu_state[row.id] then
            T(1, row_number, "x", "cyan")
        end
    else
        T(0, row_number, row.text, color)
    end
end

function run_row(row, hold)
    local rt = row.type
    if rt == "hold" then
        if row.call_id then
            menu_calls[row.call_id](row, menu_state)
        end
        if row.id then
            menu_state[row.id] = true -- TODO: set to false later
        end
    end

    if hold then return end

    if rt == "toggle" then
        menu_state[row.id] = not menu_state[row.id]
        if row.call_id then
            menu_calls[row.call_id](row, menu_state)
        end
    elseif rt == "close" then
        active_menu = nil
    elseif rt == "oneshot" then
        menu_calls[row.call_id](row, menu_state)
    end
end

function run_mainmenu(ctrl, pressed)
    local active_submenu = menu.active
    if pressed.left then
        active_submenu = active_submenu - 1
    end
    if pressed.right then
        active_submenu = active_submenu + 1
    end
    active_submenu = (active_submenu - 1) % #menu + 1
    menu.active = active_submenu

    local submenu = menu[active_submenu]

    local active_row = submenu.active
    if pressed.down then
        active_row = active_row - 1
    end
    if pressed.up then
        active_row = active_row + 1
    end
    active_row = (active_row - 1) % #submenu + 1
    submenu.active = active_row

    local row = submenu[active_row]

    if pressed.enter then
        run_row(row)
    elseif ctrl.enter then
        run_row(row, true)
    end

    T(0, 0, ("menu %02i/%02i"):format(active_submenu, #menu), "yellow")
    for i, row in ipairs(submenu) do
        draw_row(row, i, i == active_row)
    end
end

local pressed = {}
local old_ctrl = {}
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

    gui.clearGraphics()

    if pressed.enter and not active_menu then
        active_menu = menu
        pressed.enter = false
    end

    if active_menu == menu then
        run_mainmenu(ctrl, pressed)
    end

    old_ctrl = ctrl
    emu.yield()
end
