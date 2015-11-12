require = require "depend"
require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "messages"
require "flag manager"

local warp_menu = require "warp menu"

-- TODO: make OoT versions for most of these menus

local dummy = Callbacks()

local function Setter(t)
    local cb = Callbacks()
    function cb:on()
        for addr, value in pairs(t) do
            addr(value)
        end
    end
    cb.hold = cb.on
    return cb
end

local passives = {}

Passive = Class(Callbacks)
function Passive:init(...)
    Callbacks.init(self, ...)
    table.insert(passives, self)
end
function Passive:tick()
    if self.state then self:tick_on() end
end
function Passive:tick_on()
end

local levitate = Passive()
function levitate:tick_on()
    if bit.band(addrs.buttons(), 0x20) > 0 then
        self:hold()
    end
end
function levitate:hold()
    addrs.link_actor.y_vel(10)
end

local supersonic = Passive()
function supersonic:tick_on()
    if bit.band(addrs.buttons(), 0x8000) > 0 then
        self:hold()
    end
end
function supersonic:hold()
    addrs.link_actor.lin_vel(20)
end

local infinite_items = Passive()
function infinite_items:tick_on()
    for k, v in pairs(addrs.quantities) do
        v(69)
    end
end

local everything = Callbacks()
function everything:on()
    dofile("oneshot.lua")
end

local escape_cutscene = Callbacks()
function escape_cutscene:on()
    addrs.cutscene_status_2(3)
end

local playas_child = Passive()
function playas_child:tick_on()
    addrs.age_modifier_global(1)
end
local playas_adult = Passive()
function playas_adult:tick_on()
    addrs.age_modifier_global(0)
end

local PassiveResetMask = Class(Passive)
function PassiveResetMask:on()
    Passive.on(self)
    addrs.mask_worn(0)
end

local playas_human = PassiveResetMask()
function playas_human:tick_on()
    addrs.transformation(4)
end
local playas_deku = PassiveResetMask()
function playas_deku:tick_on()
    addrs.transformation(3)
end
local playas_goron = PassiveResetMask()
function playas_goron:tick_on()
    addrs.transformation(1)
end
local playas_zora = PassiveResetMask()
function playas_zora:tick_on()
    addrs.transformation(2)
end
local playas_fd = PassiveResetMask()
function playas_fd:tick_on()
    addrs.transformation(0)
end

local soft_reset = Callbacks()
function soft_reset:on()
    addrs.warp_begin(0x14)
    addrs.warp_destination(0x1C00)
    AL(0x3F48, 2)(0xFFFA) -- doesn't quite work
end

local pos = {}
local save_pos = Callbacks()
function save_pos:on()
    local la = addrs.link_actor
    pos.x = la.x()
    pos.y = la.y()
    pos.z = la.z()
    pos.a = la.angle()
    -- also save ISG for glitch testers ;)
    pos.isg = la.sword_active()
end
local load_pos = Callbacks()
function load_pos:on()
    local la = addrs.link_actor
    la.x(pos.x)
    la.y(pos.y)
    la.z(pos.z)
    -- also set xyz copies so collision detection doesn't interfere
    la.x_copy(pos.x)
    la.y_copy(pos.y)
    la.z_copy(pos.z)
    la.angle(pos.a)
    la.sword_active(pos.isg)
end

local reload_scene = Callbacks()
function reload_scene:on()
    local ev = addrs.exit_value()
    addrs.warp_begin(0x14)
    addrs.warp_destination(ev)
end

local saved_scene = nil
local save_scene = Callbacks()
function save_scene:on()
    saved_scene = addrs.exit_value()
end
local load_scene = Callbacks()
function load_scene:on()
    if saved_scene == nil then return end
    addrs.warp_begin(0x14)
    addrs.warp_destination(saved_scene)
end

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

local playas_group = {}
local playas_mm_group = {}
local playas_menu = oot and Menu{
    Screen{
        Text("Play as..."),
        Radio("Default", playas_group, dummy),
        Radio("Child Link", playas_group, playas_child),
        Radio("Adult Link", playas_group, playas_adult),
        Text(""),
        Oneshot("Reload Scene", reload_scene),
        Back(),
    },
} or Menu{
    Screen{
        Text("Play as..."),
        Radio("Default", playas_mm_group, dummy),
        Radio("Human Link", playas_mm_group, playas_human),
        Radio("Deku Link", playas_mm_group, playas_deku),
        Radio("Goron Link", playas_mm_group, playas_goron),
        Radio("Zora Link", playas_mm_group, playas_zora),
        Radio("Fierce Deity", playas_mm_group, playas_fd),
        Text(""),
        Oneshot("Reload Scene", reload_scene),
        Back(),
    },
}

local progress_menu = Menu{
    Screen{
        Text("Progress Menu #1/1"),
        Oneshot("Setup First Cycle", first_cycle),
        Text(""),
        Back(),
    },
}

local function gen_set_day(x)
    local cb = Callbacks()
    function cb:on()
        addrs.day(x)
        addrs.days_elapsed(x)
    end
    return cb
end

local function gen_set_time(x)
    local cb = Callbacks()
    function cb:on()
        addrs.time(x)
    end
    return cb
end

local time_menu = Menu{
    Screen{
        Text("Day/Time Menu #1/1"),
        Oneshot("Set Day to 0", Setter{[addrs.day]=0, [addrs.days_elapsed]=0}),
        Oneshot("Set Day to 1", Setter{[addrs.day]=1, [addrs.days_elapsed]=1}),
        Oneshot("Set Day to 2", Setter{[addrs.day]=2, [addrs.days_elapsed]=2}),
        Oneshot("Set Day to 3", Setter{[addrs.day]=3, [addrs.days_elapsed]=3}),
        Oneshot("Set Day to 4", Setter{[addrs.day]=4, [addrs.days_elapsed]=4}),
        Oneshot("Set Time to 06:00", Setter{[addrs.time]=0x4000}),
        Oneshot("Set Time to 12:00", Setter{[addrs.time]=0x8000}),
        Oneshot("Set Time to 18:00", Setter{[addrs.time]=0xC000}),
        Oneshot("Set Time to 00:00", Setter{[addrs.time]=0x0000}),
        Text(""),
        Oneshot("Time flow: Fast",        Setter{[addrs.time_speed]=2}),
        Oneshot("Time flow: Normal",      Setter{[addrs.time_speed]=0}),
        Oneshot("Time flow: Slow (iSoT)", Setter{[addrs.time_speed]=-2}),
        Oneshot("Time flow: Stopped",     Setter{[addrs.time_speed]=-3}),
        Oneshot("Time flow: Backwards",   Setter{[addrs.time_speed]=-5}),
        -- TODO: make version-agnostic
        Oneshot("Disable time flow (Scene)", Setter{[A(0x382502, 2)]=0}),
        --Oneshot("Stop time glitch", stop_time),
        Text(""),
        Back(),
    },
}

local main_menu = Menu{
    -- TODO: seperator item that's just a few underscores with half height
    Screen{
        Text("Main Menu #1/2"),
        --Toggle("L to Levitate", levitate),
        Toggle("A to Run Fast", supersonic),
        Hold("Levitate", levitate),
        Toggle("Infinite Items", infinite_items),
        Text(""),
        Oneshot("100% Items", everything),
        LinkTo("Set Progress...", progress_menu),
        Text(""),
        Oneshot("Escape Cutscene", escape_cutscene),
        Text(""),
        LinkTo("Play as...", playas_menu),
        Oneshot("Kill Link", Setter{[addrs.hearts]=0}),
        Text(""),
        Back(),
    },
    Screen{
        Text("Main Menu #2/2"),
        LinkTo("Warp to...", warp_menu),
        LinkTo("Set Day/Time...", time_menu),
        Text(""),
        --Flags("some flags"),
        Oneshot("Store Position", save_pos),
        Oneshot("Restore Position", load_pos),
        Text(""),
        Oneshot("Reload Scene", reload_scene),
        Oneshot("Store Scene", save_scene),
        Oneshot("Restore Scene", load_scene),
        -- TODO: can probably save/load position+scene using void out mechanics
        Text(""),
        Oneshot("Soft Reset (Warp to Title)", soft_reset),
        Text(""),
        Back(),
    },
}

local input = InputHandler{
    enter = "P1 L",
    up    = "P1 DPad U",
    down  = "P1 DPad D",
    left  = "P1 DPad L",
    right = "P1 DPad R",
}

local handle = MenuHandler(main_menu, T_TL)

while mm or oot do
    local ctrl, pressed = input:update()
    handle:update(ctrl, pressed)

    for i, passive in ipairs(passives) do
        passive:tick()
    end

    emu.frameadvance()
end
