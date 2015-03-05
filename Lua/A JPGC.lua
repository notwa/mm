local link = 0x1ED820
local global = 0x381250
local actor = 0x39A4E0

function AL(a, s) return A(link+a, s) end
function AG(a, s) return A(global+a, s) end
function AA(a, s) return A(actor+a, s) end

local common = dofile("A common.lua")

return merge(common, {
})
