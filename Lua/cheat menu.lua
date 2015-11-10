require = require "depend"
require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "messages"

local warp_menu = require "warp menu"

local dummy = Callbacks()

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

local everything = Callbacks()
function everything:on()
    dofile("oneshot.lua")
end

local escape_cutscene = Callbacks()
function escape_cutscene:on()
    addrs.cutscene_status_2(3)
end

local self_destruct = Callbacks()
function self_destruct:on()
    addrs.hearts(0)
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

local playas_group = {}
local playas_mm_group = {}

local playas_menu = oot and Menu{
    Screen{
        Text("Play as..."),
        Radio("Default", playas_group, dummy),
        Radio("Child Link", playas_group, playas_child),
        Radio("Adult Link", playas_group, playas_adult),
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
        Back(),
    },
}


local main_menu = Menu{
    Screen{
        Text("Main Menu #1/2"),
        --Toggle("L to Levitate", levitate),
        Toggle("A to Run Fast", supersonic),
        Hold("Levitate", levitate),
        Oneshot("100%", everything),
        Oneshot("Escape Cutscene", escape_cutscene),
        LinkTo("Play as...", playas_menu),
        LinkTo("Warp to...", warp_menu),
        Back(),
    },
    Screen{
        Text("Main Menu #2/2"),
        Oneshot("Kill Link", self_destruct),
        Flags("some flags"),
        Text("k"),
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
