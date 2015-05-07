require "boilerplate"
require "addrs.init"
require "classes"
require "menu classes"
require "messages"

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

local everything = Callbacks()
function everything:on()
    dofile("oneshot.lua")
end

local self_destruct = Callbacks()
function self_destruct:on()
    addrs.hearts(0)
end

local main_menu = Menu{
    Screen{
        Text("hey"),
        Toggle("L to Levitate", levitate),
        Hold("Levitate", levitate),
        Oneshot("100%", everything),
        Back(),
    },
    Screen{
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

local menu = nil

while mm or oot do
    local ctrl, pressed = input:update()

    local delay = false
    if not menu and pressed.enter then
        delay = true
        menu = main_menu
        menu:focus()
    end

    if menu and not delay then
        local old = menu
        menu = menu:navigate(ctrl, pressed)
        if menu ~= old then
            old:unfocus()
            if menu then menu:focus() end
        end
    end
    if menu then menu:draw(T_TL, 0) end

    for i, passive in ipairs(passives) do
        passive:tick()
    end

    emu.frameadvance()
end
