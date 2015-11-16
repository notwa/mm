require = require "depend"
require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "menu input handlers"
require "messages"
require "flag manager"

-- TODO: make OoT versions for most of these menus

--[[ control schemes:
normal:         (alt_input = false; eat_input = false)
    L opens the menu
    L selects menu items
    D-Pad navigates up/down items and left/right through pages
alternate:      (alt_input = true;  eat_input = false)
    L+R opens/closes the menu
    L goes back a menu (or closes)
    R selects menu items
    L+Z hides the menu without closing (FIXME: interferes with back button)
    D-Pad navigates
greedy:         (alt_input = false; eat_input = true)
    L opens/closes the menu
    while the menu is open, the game receives no inputs
    D-Pad/Joystick/C-Buttons navigate through items and pages
    A select menu items
    B/R go back a menu (or closes)
    Z hides the menu without closing
    TODO: joystick, a/b button etc
greedy alt:     (alt_input = true;  eat_input = true)
    same as greedy but pauses the game while in menu
    (enables run_while_paused)
--]]

local run_while_paused = true
local alt_input = true
local eat_input = true

local fn = oot and 'cm oot save.lua' or 'cm mm save.lua'
local saved = deserialize(fn) or {}
local function save()
    serialize(fn, saved)
end

function Setter(t)
    return function()
        for func, value in pairs(t) do
            func(value)
        end
    end
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
    if bit.band(addrs.buttons(), 0x800) > 0 then
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

local any_item = Passive()
function any_item:tick_on()
    addrs.buttons_enabled(0)
end

local function soft_reset()
    if oot then
        -- FIXME: Link voids out on title screen.
        -- need to load title screen save?
        addrs.warp_begin(0x14)
        addrs.warp_destination(0x00CD)
        addrs.fade_type(0x0B)
        addrs.entrance_mod_setter(0xFFF3)
    else
        addrs.warp_begin(0x14)
        addrs.warp_destination(0x1C00)
        addrs.fade_type(0x0B)
        addrs.entrance_mod_setter(0xFFFA)
    end
end

local function save_pos()
    local la = addrs.link_actor
    saved.pos = {}
    local pos = saved.pos
    pos.x = la.x()
    pos.y = la.y()
    pos.z = la.z()
    pos.a = la.angle()
    -- also save ISG for glitch testers ;)
    pos.isg = la.sword_active()
    save()
end
local function load_pos()
    local la = addrs.link_actor
    local pos = saved.pos
    if pos == nil then return end
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

local function reload_scene()
    local ev = addrs.exit_value()
    addrs.warp_begin(0x14)
    addrs.warp_destination(ev)
end

local function save_scene()
    saved.scene = addrs.exit_value()
    save()
end
local function load_scene()
    if saved.scene == nil then return end
    addrs.warp_begin(0x14)
    addrs.warp_destination(saved.scene)
end

local function save_scene_pos()
    saved.scenepos = {}
    local sp = saved.scenepos
    sp.scene = addrs.exit_value()
    local la = addrs.link_actor
    sp.x = la.x()
    sp.y = la.y()
    sp.z = la.z()
    sp.a = la.angle()
    --sp.room = la.room_number()
    save()
end
local function load_scene_pos()
    local sp = saved.scenepos
    if sp == nil then return end
    addrs.warp_begin(0x14)
    addrs.warp_destination(sp.scene)
    local fade = fades_killed and 0x0B or 0x01
    addrs.fade_type(fade)
    local vt = oot and 1 or -4 -- TODO: check if there's a better type for OoT
    addrs.voidout_type(vt)
    addrs.voidout_x(sp.x)
    addrs.voidout_y(sp.y)
    addrs.voidout_z(sp.z)
    addrs.voidout_angle(sp.a)
    addrs.voidout_var(0x0BFF) -- puts camera behind link instead of at entrance
    --voidout_room_number(sp.room)
end

local function kill_fades()
    local et = addrs.entrance_table
    if et == nil then return end
    local et_size = 1244

    local new_fade = 0x0B -- instant
    local fades = new_fade*0x80 + new_fade

    for i=0, et_size*4 - 1, 4 do
        local a = et.addr + i
        if R1(a) ~= 0x80 then -- don't mess up the pointers
            -- the lower word works like this:
            -- mmIIIIIIIOOOOOOO
            -- m = mode; I = fade in; O = fade out (probably).
            local mode = bit.band(R2(a+2), 0xC000)
            W2(a+2, mode + fades)
        end
    end

    fades_killed = true
end

local function timestop()
    -- doesn't set it up quite like the glitch, but this is the main effect
    set(timestop, 4) -- normally -1
end

local time_menu = oot and Menu{
    Screen{
        Text("Time Menu #1/1"),
        Oneshot("Set Time to 06:00", Setter{[addrs.time]=0x4000}),
        Oneshot("Set Time to 12:00", Setter{[addrs.time]=0x8000}),
        Oneshot("Set Time to 18:00", Setter{[addrs.time]=0xC000}),
        Oneshot("Set Time to 00:00", Setter{[addrs.time]=0x0000}),
        Text(""),
        Back(),
    },
} or Menu{
    Screen{
        Text("Day/Time Menu #1/1"),
        Oneshot("Set Day to Zeroth", Setter{[addrs.day]=0, [addrs.days_elapsed]=0}),
        Oneshot("Set Day to First",  Setter{[addrs.day]=1, [addrs.days_elapsed]=1}),
        Oneshot("Set Day to Second", Setter{[addrs.day]=2, [addrs.days_elapsed]=2}),
        Oneshot("Set Day to Final",  Setter{[addrs.day]=3, [addrs.days_elapsed]=3}),
        Oneshot("Set Day to New",    Setter{[addrs.day]=4, [addrs.days_elapsed]=4}),
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
        Oneshot("Disable time flow (Scene)", Setter{[addrs.scene_time_speed]=0}),
        Oneshot("Timestop glitch", timestop),
        Text(""),
        Back(),
    },
}

local warp_menu = require "menus.warp"
local progress_menu = require "menus.progress"
local playas_menu = require "menus.playas"

local main_menu = Menu{
    Screen{
        Text("Main Menu #1/2"),
        Toggle("D-Up to Levitate", levitate),
        Toggle("A to Run Fast", supersonic),
        Toggle("Infinite Items", infinite_items),
        Toggle("Use Any Item", any_item),
        Text(""),
        Oneshot("Have Everything", Setter{[dofile]="oneshot.lua"}),
        LinkTo("Set Progress...", progress_menu),
        Text(""),
        Oneshot("Escape Cutscene", Setter{[addrs.cutscene_status_2]=3}),
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
        Oneshot("Store Position", save_pos),
        Oneshot("Restore Position", load_pos),
        Text(""),
        Oneshot("Reload Scene", reload_scene),
        Oneshot("Store Scene", save_scene),
        Oneshot("Restore Scene", load_scene),
        Text(""),
        Oneshot("Store Scene & Position", save_scene_pos),
        Oneshot("Restore Scene & Position", load_scene_pos),
        Text(""),
        Oneshot("Kill Transitions", kill_fades),
        Text(""),
        Oneshot("Soft Reset (Warp to Title)", soft_reset),
        Text(""),
        Back(),
    },
}

local input = InputHandler()
input = JoyWrapper(input)

local handle = MenuHandler(main_menu, T_TL)

while mm or oot do
    local ctrl, pressed = input:update()

    if eat_input then
        local old_menu = handle.menu
        handle_eat_input(handle, ctrl, pressed)
        if alt_input and handle.menu ~= old_menu then
            run_while_paused = true
            if handle.menu then client.pause() else client.unpause() end
        end
    elseif alt_input then
        handle_alt_input(handle, ctrl, pressed)
    else
        for _, v in ipairs{'left', 'right', 'up', 'down'} do
            ctrl[v] = ctrl['d_'..v]
            pressed[v] = pressed['d_'..v]
        end
        ctrl.enter = ctrl.L
        pressed.enter = pressed.L
        handle:update(ctrl, pressed)
    end

    for i, passive in ipairs(passives) do
        passive:tick()
    end

    if run_while_paused then
        emu.yield()
        gui.cleartext()
    else
        emu.frameadvance()
    end
end
