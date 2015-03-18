A = require "boilerplate"

local link = 0x11A5D0
local global = 0x1C84A0
local actor = 0x1DAA30

function AL(a, s) return A(link+a, s) end
function AG(a, s) return A(global+a, s) end
function AA(a, s) return A(actor+a, s) end

function merge(t1, t2)
    for k, v in pairs(t1) do
        t2[k] = v
    end
    return t2
end

function Actor(addr)
    local function AA(a, s) return A(addr+a, s) end
    return {
        num             = AA(0x0, 2),
        type            = AA(0x2, 1),
        room_number     = AA(0x3, 1),
        flags           = AA(0x4, 4),
        x_copy          = AA(0x8, 'f'),
        y_copy          = AA(0xC, 'f'),
        z_copy          = AA(0x10, 'f'),
        x_rot_init      = AA(0x14, 2),
        y_rot_init      = AA(0x16, 2),
        z_rot_init      = AA(0x18, 2),
        var             = AA(0x1C, 2),
        x               = AA(0x24, 'f'),
        y               = AA(0x28, 'f'),
        z               = AA(0x2C, 'f'),
        --x_rot_init      = AA(0x30, 2),
        --y_rot_init      = AA(0x32, 2),
        --z_rot_init      = AA(0x34, 2),
        --x_rot_init      = AA(0x44, 2),
        --y_rot_init      = AA(0x46, 2),
        --z_rot_init      = AA(0x48, 2),
        angle_old       = AA(0x4A, 2), -- TODO: verify
        x_scale         = AA(0x50, 'f'),
        y_scale         = AA(0x54, 'f'),
        z_scale         = AA(0x58, 'f'),
        x_vel           = AA(0x5C, 'f'),
        y_vel           = AA(0x60, 'f'),
        z_vel           = AA(0x64, 'f'),
        --lin_vel_old     = AA(0x70, 'f'),
        --ground_y        = AA(0x88, 'f'),
        damage_table    = AA(0x98, 4),
        hp              = AA(0xAF, 1),
        --angle           = AA(0xBA, 2),
        --foot_left_x     = AA(0xD4, 'f'),
        --foot_left_y     = AA(0xD8, 'f'),
        --foot_left_z     = AA(0xDC, 'f'),
        --foot_right_x    = AA(0xE0, 'f'),
        --foot_right_y    = AA(0xE4, 'f'),
        --foot_right_z    = AA(0xE8, 'f'),
        --camera_rel_x    = AA(0xEC, 'f'),
        --camera_rel_y    = AA(0xF0, 'f'),
        --camera_rel_z    = AA(0xF4, 'f'),
        --unknown_z       = AA(0xF8, 'f'),
        --x_old           = AA(0x108, 'f'),
        --y_old           = AA(0x10C, 'f'),
        --z_old           = AA(0x108, 'f'),
        prev            = AA(0x120, 4),
        next            = AA(0x124, 4),
    }
end

local common = {
    exit_value          = AL(0x02, 2),
    age_modifier        = AL(0x04, 4),
    --cutscene_status     = AL(0x0A, 2),
    time                = AL(0x0C, 2),
    day_night           = AL(0x10, 4),
    --time_speed          = AL(0x14, 4),
    ZELDA3              = AL(0x1C, 6), -- actually ZELDAZ in OoT
    death_count         = AL(0x22, 2),
    name                = AL(0x24, 8),
    max_hearts          = AL(0x2E, 2),
    hearts              = AL(0x30, 2),
    --has_magic           = AL(0x38, 1), -- ?
    magic               = AL(0x33, 1),
    rupees              = AL(0x34, 2),
    --has_normal_magic    = AL(0x40, 1),
    --has_double_magic    = AL(0x41, 1),
    equip_tunic_boots   = AL(0x70, 1),
    equip_sword_shield  = AL(0x71, 1),
    inventory_items     = AL(0x74, 24),
    inventory_counts    = AL(0x8C, 24),
    --magic_beans_avail   = AL(0x9B, 1),
    --tunic_boots         = AL(0x9C, 1), -- FIXME
    --sword_shield        = AL(0x9C, 1), -- FIXME
    deku_upgrades       = AL(0xA1, 1),
    wallet_size         = AL(0xA2, 1), -- also bullet bag & dive meter in OoT
    quiver_bag          = AL(0xA3, 1), -- also strength in OoT
    --quest_items         = AL(0xBC, 4),
    --items_wft           = AL(0xC0, 1),
    --keys_wft            = AL(0xCA, 1),
    --doubled_hearts      = AL(0xD3, 1), -- set to 20 by the game
    --strange_string      = AL(0xDE, 6),
    --scene_flags_save    = AL(0x470, 0x960),
    --slulltula_count_wf  = AL(0xEC0, 2),
    --archery             = AL(0xF00, 1),
    --disable_c_buttons   = AL(0xF4A, 1), -- 8
    --sword_disable_c     = AL(0xF52, 1), -- 32
    --map_visited         = AL(0xF5E, 2),
    --map_visible         = AL(0xF62, 2),

    inventory = {
        b_button        = AL(0x68, 1),
        c_left_item     = AL(0x69, 1),
        c_down_item     = AL(0x6A, 1),
        c_right_item    = AL(0x6B, 1),
        c_left_slot     = AL(0x6C, 1),
        c_down_slot     = AL(0x6D, 1),
        c_right_slot    = AL(0x6E, 1),
        b_button_slot   = AL(0x6F, 1), -- unused?

        deku_stick      = AL(0x74, 1),
        deku_nut        = AL(0x75, 1),
        bombs           = AL(0x76, 1),
        bow             = AL(0x77, 1),
        fire_arrows     = AL(0x78, 1),
        dins_fire       = AL(0x79, 1),
        slingshot       = AL(0x7A, 1),
        ocarina         = AL(0x7B, 1),
        bombchu         = AL(0x7C, 1),
        hookshot        = AL(0x7D, 1),
        ice_arrows      = AL(0x7E, 1),
        farores_wind    = AL(0x7F, 1),
        boomerang       = AL(0x80, 1),
        lens_of_truth   = AL(0x81, 1),
        magic_beans     = AL(0x82, 1),
        hammer          = AL(0x83, 1),
        light_arrows    = AL(0x84, 1),
        nayrus_love     = AL(0x85, 1),
        bottle_1        = AL(0x85, 1),
        bottle_2        = AL(0x86, 1),
        bottle_3        = AL(0x87, 1),
        bottle_4        = AL(0x88, 1),
        trade_1         = AL(0x89, 1),
        trade_2         = AL(0x8A, 1),
    },
    quantities = {
        arrows          = AL(0xA1, 1), -- FIXME
        bombs           = AL(0xA6, 1),
        bombchu         = AL(0xA7, 1),
        sticks          = AL(0xA8, 1),
        nuts            = AL(0xA9, 1),
        beans           = AL(0xAA, 1),
        kegs            = AL(0xAC, 1),
    },

    camera_target       = AG(0x270, 4),
    actor_count         = AG(0x1C2C, 1),
    actor_count_0       = AG(0x1C30, 4),
    actor_first_0       = AG(0x1C34, 4),
    actor_count_1       = AG(0x1C38, 4),
    actor_first_1       = AG(0x1C3C, 4),
    actor_count_2       = AG(0x1C40, 4),
    actor_first_2       = AG(0x1C44, 4),
    actor_count_3       = AG(0x1C48, 4),
    actor_first_3       = AG(0x1C4C, 4),
    actor_count_4       = AG(0x1C50, 4),
    actor_first_4       = AG(0x1C54, 4),
    actor_count_5       = AG(0x1C58, 4),
    actor_first_5       = AG(0x1C5C, 4),
    actor_count_6       = AG(0x1C60, 4),
    actor_first_6       = AG(0x1C64, 4),
    actor_count_7       = AG(0x1C68, 4),
    actor_first_7       = AG(0x1C6C, 4),
    actor_count_8       = AG(0x1C70, 4),
    actor_first_8       = AG(0x1C74, 4),
    actor_count_9       = AG(0x1C78, 4),
    actor_first_9       = AG(0x1C7C, 4),
    actor_count_10      = AG(0x1C80, 4),
    actor_first_10      = AG(0x1C84, 4),
    actor_count_11      = AG(0x1C88, 4),
    actor_first_11      = AG(0x1C8C, 4),
    z_cursor_actor      = AG(0x1CC8, 4),
    z_target_actor      = AG(0x1CCC, 4),
}

return merge(common, {
    
})
