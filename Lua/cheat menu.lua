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
        local inv = addrs.inventory
        local masks = addrs.masks
        local counts = addrs.counts
        --addrs.target_style  (1)
        --addrs.buttons_enabled   (0)
        --addrs.infinite_sword(1)
        addrs.zeroth_day    (1)
        addrs.sot_count     (0)
        addrs.bubble_timer  (0)
        --
        addrs.sword_shield  (0x23)
        addrs.quiver_bag    (0x1B)
        addrs.hearts        (16*20)
        addrs.max_hearts    (16*20)
        addrs.owls_hit      (0xFFFF)
        addrs.map_visible   (0xFFFF)
        addrs.map_visited   (0xFFFF)
        addrs.rupees        (0xFFFF)
        addrs.magic_1       (0x60)  -- fixme
        addrs.magic_2       (0x101) -- fixme
        addrs.status_items  (0xFFFFFF)
        inv.b_button        (0x4F)
        inv.ocarina         (0x00)
        inv.bow             (0x01)
        inv.fire_arrows     (0x02)
        inv.ice_arrows      (0x03)
        inv.light_arrows    (0x04)
        inv.bombs           (0x06)
        inv.bombchu         (0x07)
        inv.deku_stick      (0x08)
        inv.deku_nut        (0x09)
        inv.magic_beans     (0x0A)
        inv.powder_keg      (0x0C)
        inv.pictograph      (0x0D)
        inv.lens_of_truth   (0x0E)
        inv.hookshot        (0x0F)
        inv.fairy_sword     (0x10)
        inv.bottle_1        (0x12)
        inv.bottle_2        (0x1B)
        inv.bottle_3        (0x1A)
        inv.bottle_4        (0x18)
        inv.bottle_5        (0x16)
        inv.bottle_6        (0x25)
        --addrs.event_1       (0x05)
        --addrs.event_2       (0x0B)
        --addrs.event_3       (0x11)
        masks.postman       (0x3E)
        masks.all_night     (0x38)
        masks.blast         (0x47)
        masks.stone         (0x45)
        masks.great_fairy   (0x40)
        masks.deku          (0x32)
        masks.keaton        (0x3A)
        masks.bremen        (0x46)
        masks.bunny         (0x39)
        masks.don_gero      (0x42)
        masks.scents        (0x48)
        masks.goron         (0x33)
        masks.romani        (0x3C)
        masks.troupe_leader (0x3D)
        masks.kafei         (0x37)
        masks.couples       (0x3F)
        masks.truth         (0x36)
        masks.zora          (0x34)
        masks.kamaro        (0x43)
        masks.gibdo         (0x41)
        masks.garos         (0x3B)
        masks.captains      (0x44)
        masks.giants        (0x49)
        masks.fierce_deity  (0x35)
        counts.arrows       (69)
        counts.bombs        (69)
        counts.bombchu      (69)
        counts.sticks       (69)
        counts.nuts         (69)
        counts.beans        (69)
        counts.kegs         (69)
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
