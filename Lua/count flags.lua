require "lib.setup"
require "boilerplate"
require "addrs"

-- precalculate hamming weights of bytes
local hamming_weight = {}
for i = 0, 255 do
    local w = 0
    for b = 0, 7 do
        w = w + bit.band(bit.rshift(i, b), 1)
    end
    hamming_weight[i] = w
end

local function hamming_of(addr, size)
    local weight = 0
    local bytes = mainmemory.readbyterange(addr, size)
    for k,v in pairs(bytes) do
        if v ~= 0 then
            weight = weight + hamming_weight[tonumber(v, 16)]
        end
    end
    return weight
end

local function hamming_of_A(a)
    return hamming_of(a.addr, a.type)
end

print("###")
local current = 0
for i = 1, 5 do
    local addr = addrs['current_scene_flags_'..tostring(i)].addr
    current = current + hamming_of(addr, 4)
end
local ingame = hamming_of_A(addrs.scene_flags_ingame)
local save   = hamming_of_A(addrs.scene_flags_save)
print("current", current)
print("ingame ", ingame)
print("save   ", save)
