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
return oot and Menu{
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
