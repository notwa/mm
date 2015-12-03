-- version-agnostic addresses
function Actor(addr)
    local function AA(a, s) return A(addr+a, s) end
    return {
        num             = AA(0x0, 2),
        type            = AA(0x2, 1),
        room_number     = AA(0x3, 1), -- verify
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
        x_rot_init_2    = AA(0x30, 2), -- z-target facing angle?
        y_rot_init_2    = AA(0x32, 2), -- link's head Y rot (lerped FPS angle)
        z_rot_init_2    = AA(0x34, 2),
        fps_vert_angle  = AA(0x44, 2),
        fps_horiz_angle = AA(0x46, 2),
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
        angle           = AA(0xB6, 2),
        prev            = AA(0x120, 4),
        next            = AA(0x124, 4),
    }
end

return {
    exit_value          = AL(0x02, 2),
    age_modifier        = AL(0x04, 4),
    cutscene_status     = AL(0x0A, 2), -- "cutscene number" 0xFFFx
    time                = AL(0x0C, 2),
    day_night           = AL(0x10, 4),
    ZELDA3              = AL(0x1C, 6), -- actually ZELDAZ in OoT
    death_count         = AL(0x22, 2),
    name                = AL(0x24, 8),
    max_hearts          = AL(0x2E, 2),
    hearts              = AL(0x30, 2),
    magic_level         = AL(0x32, 1),
    magic               = AL(0x33, 1),
    rupees              = AL(0x34, 2),
    navi_timer          = AL(0x38, 2),
    has_normal_magic    = AL(0x3A, 1),
    has_double_magic    = AL(0x3C, 1),
    --AL(0x67, 1), something to do with saving?
    equip_tunic_boots   = AL(0x70, 1),
    equip_sword_shield  = AL(0x71, 1),
    inventory_items     = AL(0x74, 24),
    inventory_quantities= AL(0x8C, 24),
    --magic_beans_avail   = AL(0x9B, 1),
    tunic_boots         = AL(0x9C, 1),
    sword_shield        = AL(0x9D, 1),
    upgrades            = AL(0xA0, 4),
    quest_items         = AL(0xA4, 4),
    doubled_hearts      = AL(0xCF, 1), -- set to 20 by the game
    scene_flags_save    = AL(0xD4, 0xB0C), -- 0x1C each

    inventory = {
        b_button_item   = AL(0x68, 1),
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
        bottle_1        = AL(0x86, 1),
        bottle_2        = AL(0x87, 1),
        bottle_3        = AL(0x88, 1),
        bottle_4        = AL(0x89, 1),
        trade_1         = AL(0x8A, 1),
        trade_2         = AL(0x8B, 1),
    },
    quantities = {
        sticks          = AL(0x8C, 1),
        nuts            = AL(0x8D, 1),
        bombs           = AL(0x8E, 1),
        arrows          = AL(0x8F, 1),
        seeds           = AL(0x92, 1),
        bombchu         = AL(0x94, 1),
        beans           = AL(0x9A, 1),
    },

    event_chk_inf       = AL(0xED4, 0x1C),
    item_get_inf        = AL(0xEF0,  0x8),
    inf_table           = AL(0xEF8, 0x3C),
    checksum            = AL(0x1352, 2),
    voidout_type        = AL(0x1364, 4),
    voidout_x           = AL(0x1368, 'f'),
    voidout_y           = AL(0x136C, 'f'),
    voidout_z           = AL(0x1370, 'f'),
    voidout_angle       = AL(0x1374, 2),
    voidout_var         = AL(0x1376, 2),
    voidout_entrance    = AL(0x1378, 2),
    voidout_room_number = AL(0x137A, 2),
    buttons_enabled     = AL(0x13E2, 4), -- lol unaligned access
    event_inf           = AL(0x13FA, 0x8),
    target_style        = AL(0x140C, 1),
    magic_max           = AL(0x13F4, 2),
    entrance_mod_setter = AL(0x1412, 2),

    buttons             = AG(0x14, 2),
    scene_number        = AG(0xA4, 2),
    camera_target       = AG(0x270, 4),

    actor_count         = AG(0x1C2C, 1),
    actor_counts = {
        [0]=AG(0x1C30, 4),
        AG(0x1C38, 4),
        AG(0x1C40, 4),
        AG(0x1C48, 4),
        AG(0x1C50, 4),
        AG(0x1C58, 4),
        AG(0x1C60, 4),
        AG(0x1C68, 4),
        AG(0x1C70, 4),
        AG(0x1C78, 4),
        AG(0x1C80, 4),
        AG(0x1C88, 4),
    },
    actor_firsts = {
        [0]=AG(0x1C34, 4),
        AG(0x1C3C, 4),
        AG(0x1C44, 4),
        AG(0x1C4C, 4),
        AG(0x1C54, 4),
        AG(0x1C5C, 4),
        AG(0x1C64, 4),
        AG(0x1C6C, 4),
        AG(0x1C74, 4),
        AG(0x1C7C, 4),
        AG(0x1C84, 4),
        AG(0x1C8C, 4),
    },

    z_cursor_actor      = AG(0x1CC8, 4),
    z_target_actor      = AG(0x1CCC, 4),
    current_scene_flags_2 = AG(0x1D28, 4), -- switch flags
    current_scene_flags_5 = AG(0x1D2C, 4), -- temp switch flags (not saved)
    current_scene_flags_1 = AG(0x1D38, 4), -- chest flags
    current_scene_flags_3 = AG(0x1D3C, 4), -- room clear flags
    current_scene_flags_4 = AG(0x1D44, 4), -- collectible flags
    cutscene_pointer    = AG(0x1D68, 4),
    cutscene_status_2   = AG(0x1D6C, 1), -- needs a rename
    -- somewhere around here should be visited room flags?

    room_number         = AG(0x11CBC, 1),
    room_pointer        = AG(0x11CC8, 4),
    age_modifier_global = AG(0x11DE8, 1),
    warp_begin          = AG(0x11E15, 1),
    warp_destination    = AG(0x11E18, 4),
    fade_type           = AG(0x11E1F, 1), -- TODO: verify

    link_actor = setmetatable({
        item_in_hand    = AA(0x142, 1),
        animation_id    = AA(0x1AE, 2),
        --link_flags      = AA(0xA6C, 0xC),
        lin_vel         = AA(0x828, 'f'),
        movement_angle  = AA(0x82C, 2),
        sword_active    = AA(0x833, 1),
    }, {__index = Actor(AA(0,0).addr)}),
}
