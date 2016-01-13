-- for lazy people.
-- populate the global namespace with all available classes,
-- excluding menu/interface classes.

require "boilerplate"

local classes = {
    "Monitor",
    "ByteMonitor",
    "FlagMonitor",
    "SceneFlagMonitor",
    "ActorLister",
    "InputHandler",
    "JoyWrapper",
}

for _, class in ipairs(classes) do
    rawset(_G, class, require("classes."..class))
end
