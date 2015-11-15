if oot then return Menu{
    Screen{
        Text("Progress Menu #1/1"),
        Text("Unimplemented for OoT."),
        Text("Sorry! Try again later."),
        Text(""),
        Back(),
    },
} end

local first_cycle = Callbacks()
function first_cycle:on()
    addrs.warp_begin(0x14)
    addrs.warp_destination(0xC000)
    addrs.transformation(3) -- deku
    addrs.day(0)
    addrs.days_elapsed(0)
    addrs.time(0x3FD2) -- default time
    addrs.day_night(1)
    addrs.time_speed(0)
    addrs.intro_completed(0)
    addrs.have_tatl(1)
    addrs.sot_count(0)
    -- remove ocarina so time passes at first-cycle speed, among other things.
    -- if really you need your ocarina, just put it on a C button beforehand.
    addrs.inventory.ocarina(0xFF)

    -- happy mask salesman talking at door
    scene_flag_reset(0x63, 1, 0)
    -- bombers ladder balloon
    scene_flag_reset(0x29, 1, 1)

    -- other things to consider resetting:
    -- skull kid stuff
    -- deed trading quest entirely
    -- bombers stuff (they don't let you do it twice)
    -- ability to learn song of healing + get deku mask <--
    -- "oh no! the great fairy!"

    -- moon's tear has landed
    event_flag_reset(74, 5)
    event_flag_reset(74, 7)
    -- moon's tear acquired
    event_flag_reset(74, 6)
    -- skullkid jumped off clock tower thru telescope
    event_flag_reset(12, 2)
    -- clock town fairy acquired
    event_flag_reset(8, 7)
    -- deku merchant has landed)
    event_flag_reset(73, 2)
    -- Talked to Town Scrub once as Deku
    event_flag_reset(86, 2)
    -- similar to above?
    event_flag_reset(17, 5)
    -- Obtained Land Title Deed
    event_flag_reset(17, 7)
    -- Tatl talks about clock tower entrance
    event_flag_reset(79, 4)
    -- Clock Tower is open?
    event_flag_reset( 8, 6)
    -- Tatl telling Link to hurry at Clock Tower
    event_flag_reset(88, 5)
end

return Menu{
    Screen{
        Text("Progress Menu #1/1"),
        Oneshot("Setup First Cycle", first_cycle),
        Text(""),
        Back(),
    },
}
