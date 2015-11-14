require = require "depend"
require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "messages"
require "flag manager"

-- TODO: make OoT versions for most of these menus

local run_while_paused = true
local fn = 'cheat menu.save.lua'
local saved = deserialize('cheat menu.save.lua') or {}
local function save()
    serialize(fn, saved)
end

dummy = Callbacks()

function Setter(t)
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

local soft_reset = Callbacks()
function soft_reset:on()
    addrs.warp_begin(0x14)
    addrs.warp_destination(0x1C00)
    addrs.fade_type(0x0B)
    addrs.entrance_mod_setter(0xFFFA)
end

local save_pos = Callbacks()
function save_pos:on()
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
local load_pos = Callbacks()
function load_pos:on()
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

reload_scene = Callbacks()
function reload_scene:on()
    local ev = addrs.exit_value()
    addrs.warp_begin(0x14)
    addrs.warp_destination(ev)
end

local save_scene = Callbacks()
function save_scene:on()
    saved.scene = addrs.exit_value()
    save()
end
local load_scene = Callbacks()
function load_scene:on()
    if saved.scene == nil then return end
    addrs.warp_begin(0x14)
    addrs.warp_destination(saved.scene)
end

local save_scene_pos = Callbacks()
function save_scene_pos:on()
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
local load_scene_pos = Callbacks()
function load_scene_pos:on()
    local sp = saved.scenepos
    if sp == nil then return end
    addrs.warp_begin(0x14)
    addrs.warp_destination(sp.scene)
    local fade = fades_killed and 0x0B or 0x01
    addrs.fade_type(fade)
    -- TODO: add these to address list
    -- probably the same struct for both MM and OoT
    AL(0x3CB0, 4)(-4) -- void out type: reload area
    AL(0x3CB4, 'f')(sp.x)
    AL(0x3CB8, 'f')(sp.y)
    AL(0x3CBC, 'f')(sp.z)
    AL(0x3CC0, 2)(sp.a)
    AL(0x3CC2, 2)(0x0BFF) -- puts camera behind link instead of at entrance
    --AL(0x3CC6, 2)(sp.room)
end

local kill_fades = Callbacks()
function kill_fades:on()
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

local time_menu = Menu{
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
        -- TODO: make version-agnostic
        Oneshot("Disable time flow (Scene)", Setter{[A(0x382502, 2)]=0}),
        --Oneshot("Stop time glitch", stop_time),
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

    if run_while_paused then
        emu.yield()
        gui.cleartext()
    else
        emu.frameadvance()
    end
end
