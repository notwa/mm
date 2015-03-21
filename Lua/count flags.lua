require "addrs.init"

-- precalculate hamming weights of bytes
hamming_weight = {}
for i = 0, 255 do
    local w = 0
    for b = 0, 7 do
        w = w + bit.band(bit.rshift(i, b), 1)
    end
    hamming_weight[i] = w
end

function hamming_of(addr, size)
    weight = 0
    bytes = mainmemory.readbyterange(addr, size)
    for k,v in pairs(bytes) do
        if v ~= 0 then
            weight = weight + hamming_weight[tonumber(v, 16)]
        end
    end
    return weight
end

print("###")
local current = 0
for i = 1, 5 do
    local addr = addrs['current_scene_flags_'..tostring(i)].addr
    current = current + hamming_of(addr, 4)
end
local ingame = hamming_of(addrs.scene_flags_ingame.addr, 0x960)
local save   = hamming_of(addrs.scene_flags_save.addr,   0x960)
print("current", current)
print("ingame ", ingame)
print("save   ", save)
