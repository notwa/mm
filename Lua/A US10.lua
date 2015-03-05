local link = 0x1EF670
local global = 0x3E6B20
local actor = 0x3FFDB0

function AL(a, s) return A(link+a, s) end
function AG(a, s) return A(global+a, s) end
function AA(a, s) return A(actor+a, s) end

local common = dofile("A common.lua")

return merge(common, {
    checksum            = AL(0x100A, 2),
    disable_pause       = AL(0x100D, 1),
    hookshot_ba         = AL(0x100E, 1),
    disable_c_buttons_2 = AL(0x100F, 1),
    disable_items       = AL(0x1010, 1),
    rock_sirloin        = AL(0x1014, 1),
    sword_disabler      = AL(0x1015, 1),
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
    title_screen_mod    = AL(0x3CA8, 4),
    entrance_mod        = AL(0x3CAC, 4),
    timer_crap          = AL(0x3DD0, 4),
    timer_x             = AL(0x3EFA, 2),
    timer_y             = AL(0x3F08, 2),
    buttons_enabled     = AL(0x3F18, 4),
    magic_modifier      = AL(0x3F28, 4),
    magic_max           = AL(0x3F2E, 2),
    weird_a_graphic     = AL(0x3F42, 1),
    target_style        = AL(0x3F45, 1),
    music_mod           = AL(0x3F46, 2),
    entrance_mod_setter = AL(0x3F4A, 2),
    title_screen_thing  = AL(0x3F4C, 1),
    transition_mod      = AL(0x3F55, 2),
    suns_song_effect    = AL(0x3F58, 2),
    health_mod          = AL(0x3F5A, 2),
    screen_scale_enable = AL(0x3F60, 1),
    screen_scale        = AL(0x3F64, 'f'),
    scene_flags_ingame  = AL(0x3F68, 0x960),

    random              = A(0x097530, 4),
    visibility          = A(0x166118, 2),
    stored_epona        = A(0x1BDA9F, 1),
    stored_song         = A(0x1C6A7D, 1),
    buttons_3           = A(0x1FB870, 2),
    buttons_4           = A(0x1FB876, 2),

    text_open           = A(0x3FD33B, 1),
    text_status         = A(0x3FD34A, 1),
    room_number         = A(0x3FF200, 1),
    room_ptr            = A(0x3FF20C, 4),
    actor_disable       = A(0x3FF366, 2),
    warp_begin          = A(0x3FF395, 1),
    screen_dim          = A(0x3FF397, 1),
    warp_destination    = A(0x3FF39A, 2),
})
