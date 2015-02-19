local A = require "boilerplate"

local link = 0x1EF670 -- "ZELDA3" - 0x24
local function AL(a, s) return A(link+a, s) end
local US_10 = {
    link                = A(link, 0x4000), -- what gets copied to save files (mostly)
    area_mod            = AL(0x02, 2),
    cutscene_status     = AL(0x0A, 2), -- TODO: RE
    time                = AL(0x0C, 2),
    time_speed          = AL(0x16, 2),
    day                 = AL(0x1B, 1),
    transformation      = AL(0x20, 1), -- fierce deity, goron, zora, deku, normal
    zeroth_day          = AL(0x23, 1), -- mayor's warp effect
    sot_count           = AL(0x2A, 2),
    name                = AL(0x2C, 8),
    max_hearts          = AL(0x34, 2),
    hearts              = AL(0x36, 2),
    magic_1             = AL(0x39, 1), -- set to 0x60?
    rupees              = AL(0x3A, 2),
    magic_2             = AL(0x40, 2), -- set to 0x101?
    owls_hit            = AL(0x46, 2), -- bitfield
    sword_shield        = AL(0x6D, 1), -- mixed
    inventory_items     = AL(0x70, 24),
    inventory_masks     = AL(0x88, 24),
    inventory_counts    = AL(0xA0, 24), -- number of arrows, bombs, etc.
    wallet_flags        = AL(0xBA, 1), -- needs testing, 0xEF = max?
    quiver_bag          = AL(0xBB, 1), -- mixed
    status_items        = AL(0xBD, 3), -- bitfield
    scene_flags_save    = AL(0x470, 0x960),
    area_map            = AL(0xEB2, 1), -- bitfield 0x80
    banked_rupees       = AL(0xEDE, 2), -- max 9999 before messed up text
    archery             = AL(0xF00, 1), -- bitfield 0x01
    chateau_romani      = AL(0xF06, 1), -- bitfield 0x08
    disable_c_buttons   = AL(0xF4A, 1), -- bitfield 0x08
    sword_disable_c     = AL(0xF52, 1), -- bitfield 0x20, TODO: RE
    map_visited         = AL(0xF5E, 2), -- bitfield, for pause menu map
    map_visible         = AL(0xF62, 2), -- bitfield, for pause menu map
    checksum            = AL(0x100A, 2), -- only relevant for save files
    disable_pause       = AL(0x100D, 1), -- bitfield 0x80
    hookshot_ba         = AL(0x100E, 1), -- set to 0x80 for endless day
    disable_c_buttons_2 = AL(0x100F, 1), -- bitfield 0x10, also hides hearts/magic
    disable_items       = AL(0x1010, 1), -- bitfield 0x02, dims B/C buttons
    rock_sirloin        = AL(0x1014, 1), -- maybe other flags? TODO: RE
    sword_disabler      = AL(0x1015, 1), -- TODO: RE
    bubble_timer        = AL(0x1016, 2),
    rupee_accumulator   = AL(0x1018, 2),
    spring_water_timers = AL(0x1020, 0xC0),
    spring_water_time_1 = AL(0x1020, 0x20),
    spring_water_time_2 = AL(0x1040, 0x20),
    spring_water_time_3 = AL(0x1060, 0x20),
    spring_water_time_4 = AL(0x1080, 0x20),
    spring_water_time_5 = AL(0x10A0, 0x20),
    spring_water_time_6 = AL(0x10C0, 0x20),
    pictograph_picture  = AL(0x10E0, 0x2BC0),
    -- first non-pictograph byte: 0x1F3310 (link+0x3CA0)
    title_screen_mod    = AL(0x3CA8, 4), --[[
        nonzero: the HUD is hidden and you can't pause.
        1: no other effects occur. this is used for the title screen.
        2: it takes you to the file select menu.
        3: certain areas load a different scene setup.
        4: it loads the title screen from the start.
        4+: same effect as three?
    --]]
    entrance_mod        = AL(0x3CAC, 4), -- gets added to area mod, can play cutscenes
    timer_crap          = AL(0x3DD0, 4), -- TODO: RE
    timer_x             = AL(0x3EFA, 2),
    timer_y             = AL(0x3F08, 2),
    buttons_enabled     = AL(0x3F18, 4), -- C and A button booleans
    magic_modifier      = AL(0x3F28, 4), -- TODO: RE
    magic_max           = AL(0x3F2E, 2),
    weird_a_graphic     = AL(0x3F42, 1),
    target_style        = AL(0x3F45, 1), -- 0 for switch, 1 for target
    music_mod           = AL(0x3F46, 2),
    entrance_mod_setter = AL(0x3F4A, 2), -- sets entrance mod. -10 = 0
    insta_crash         = AL(0x3F4C, 1), -- TODO: RE
    transition_mod      = AL(0x3F55, 2), -- does it even work?
    suns_song_effect    = AL(0x3F58, 2),
    health_mod          = AL(0x3F5A, 2), -- heals you
    screen_scale_enable = AL(0x3F60, 1),
    screen_scale        = AL(0x3F64, 'f'),
    scene_flags_ingame  = AL(0x3F68, 0x960),
    -- last link byte (probably): 0x1F3670

    inventory = {
        b_button        = AL(0x4C, 1),

        ocarina         = AL(0x70, 1),
        bow             = AL(0x71, 1),
        fire_arrows     = AL(0x72, 1),
        ice_arrows      = AL(0x73, 1),
        light_arrows    = AL(0x74, 1),
        event_1         = AL(0x75, 1),
        bombs           = AL(0x76, 1),
        bombchu         = AL(0x77, 1),
        deku_stick      = AL(0x78, 1),
        deku_nut        = AL(0x79, 1),
        magic_beans     = AL(0x7A, 1),
        event_2         = AL(0x7B, 1),
        powder_keg      = AL(0x7C, 1),
        pictograph      = AL(0x7D, 1),
        lens_of_truth   = AL(0x7E, 1),
        hookshot        = AL(0x7F, 1),
        fairy_sword     = AL(0x80, 1),
        event_3         = AL(0x81, 1),
        bottle_1        = AL(0x82, 1),
        bottle_2        = AL(0x83, 1),
        bottle_3        = AL(0x84, 1),
        bottle_4        = AL(0x85, 1),
        bottle_5        = AL(0x86, 1),
        bottle_6        = AL(0x87, 1),
    },
    masks = {
        postman         = AL(0x88, 1),
        all_night       = AL(0x89, 1),
        blast           = AL(0x8A, 1),
        stone           = AL(0x8B, 1),
        great_fairy     = AL(0x8C, 1),
        deku            = AL(0x8D, 1),
        keaton          = AL(0x8E, 1),
        bremen          = AL(0x8F, 1),
        bunny           = AL(0x90, 1),
        don_gero        = AL(0x91, 1),
        scents          = AL(0x92, 1),
        goron           = AL(0x93, 1),
        romani          = AL(0x94, 1),
        troupe_leader   = AL(0x95, 1),
        kafei           = AL(0x96, 1),
        couples         = AL(0x97, 1),
        truth           = AL(0x98, 1),
        zora            = AL(0x99, 1),
        kamaro          = AL(0x9A, 1),
        gibdo           = AL(0x9B, 1),
        garos           = AL(0x9C, 1),
        captains        = AL(0x9D, 1),
        giants          = AL(0x9E, 1),
        fierce_deity    = AL(0x9F, 1),
    },
    counts = {
        arrows          = AL(0xA1, 1),
        bombs           = AL(0xA6, 1),
        bombchu         = AL(0xA7, 1),
        sticks          = AL(0xA8, 1),
        nuts            = AL(0xA9, 1),
        beans           = AL(0xAA, 1),
        kegs            = AL(0xAC, 1),
    },

    random              = A(0x097530, 4),
    visibility          = A(0x166118, 2), -- wtf does this even do?
    bomb_counter        = A(0x1AF10E, 1), -- used for limiting number of bombs active
    stored_epona        = A(0x1BDA9F, 1), -- takes effect on load (REQUIRES EPONA'S SONG)
    stored_song         = A(0x1C6A7D, 1),
    buttons_3           = A(0x1FB870, 2), -- used for turbo cheat
    buttons_4           = A(0x1FB876, 2), -- used for turbo cheat
    buttons_1           = A(0x3E6B3A, 1), -- some buttons
    buttons_2           = A(0x3E6B3B, 1), -- some more buttons
    framerate_limiter   = A(0x3E6BC2, 1), -- 1 = 60fps, 2 = 30fps, 3 = 20fps, etc.
    bomb_counter_2      = A(0x3E87F7, 1), -- or maybe this, can't remember
    text_open           = A(0x3FD33B, 1),
    text_status         = A(0x3FD34A, 1),
    room_number         = A(0x3FF200, 1),
    actor_disable       = A(0x3FF366, 2), -- set to -10 and load
    warp_begin          = A(0x3FF395, 1), -- set to nonzero to begin warping
    screen_dim          = A(0x3FF397, 1), -- B)
    warp_destination    = A(0x3FF39A, 2),
    link_scale_x        = A(0x3FFE08, 2), -- need to confirm this is x
    link_scale_y        = A(0x3FFE0C, 2), -- need to confirm this is y
    link_scale_z        = A(0x3FFE10, 2), -- need to confirm this is z
    z_vel               = A(0x3FFE18, 'f'),
    quick_draw          = A(0x3FFEF8, 1), -- item in link's hand
    linear_vel          = A(0x400880, 'f'),
    infinite_sword      = A(0x40088B, 1),
}

local hash = gameinfo.getromhash()
local versions = {
    ['D6133ACE5AFAA0882CF214CF88DABA39E266C078'] = US_10,
}
local addrs = versions[hash]

return addrs
