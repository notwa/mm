require = require "depend"
require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "messages"

local dummy = Callbacks()

local passives = {}

Passive = Class(Callbacks)
function Passive:init(...)
    Callbacks.init(self, ...)
    table.insert(passives, self)
end
function Passive:tick()
end

local levitate = Passive()
function levitate:tick()
    if self.state then
        if bit.band(addrs.buttons(), 0x20) > 0 then
            self:hold()
        end
    end
end
function levitate:hold()
    addrs.link_actor.y_vel(10)
end

local supersonic = Passive()
function supersonic:tick()
    if self.state then
        if bit.band(addrs.buttons(), 0x8000) > 0 then
            self:hold()
        end
    end
end
function supersonic:hold()
    addrs.link_actor.lin_vel(20)
end

local everything = Callbacks()
function everything:on()
    dofile("oneshot.lua")
end

local self_destruct = Callbacks()
function self_destruct:on()
    addrs.hearts(0)
end

local playas_child = Passive()
function playas_child:tick()
    if self.state then
        addrs.age_modifier_global(1)
    end
end
local playas_adult = Passive()
function playas_adult:tick()
    if self.state then
        addrs.age_modifier_global(0)
    end
end

local playas_human = Callbacks()
function playas_human:on()
    addrs.mask_worn(0)
    addrs.transformation(4)
end
local playas_deku = Callbacks()
function playas_deku:on()
    addrs.mask_worn(0)
    addrs.transformation(3)
end
local playas_goron = Callbacks()
function playas_goron:on()
    addrs.mask_worn(0)
    addrs.transformation(1)
end
local playas_zora = Callbacks()
function playas_zora:on()
    addrs.mask_worn(0)
    addrs.transformation(2)
end
local playas_fd = Callbacks()
function playas_fd:on()
    addrs.mask_worn(0)
    addrs.transformation(0)
end

local playas_group = {}

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
        Oneshot("Human Link", playas_human),
        Oneshot("Deku Link", playas_deku),
        Oneshot("Goron Link", playas_goron),
        Oneshot("Zora Link", playas_zora),
        Oneshot("Fierce Deity", playas_fd),
        Back(),
    },
}

local main_menu = Menu{
    Screen{
        Text("Main Menu #1/2"),
        Toggle("L to Levitate", levitate),
        Toggle("A to Run Fast", supersonic),
        Hold("Levitate", levitate),
        Oneshot("100%", everything),
        LinkTo("Play as", playas_menu),
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
