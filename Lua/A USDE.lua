local link = 0x1EEE80
local global = 0x3E63B0
local actor = 0x3FF680

function AL(a, s) return A(link+a, s) end
function AG(a, s) return A(global+a, s) end
function AA(a, s) return A(actor+a, s) end

local common = dofile("A common.lua")

return merge(common, {
})
