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
}

for _, class in ipairs(classes) do
    _G[class] = require("classes."..class)
end
