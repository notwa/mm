local function scene_flag_get_bb(scene, word, bit_)
    local byte = scene*0x14 + word*4 + math.floor(3 - bit_/8)
    byte = byte + addrs.scene_flags_ingame.addr
    local bitmask = bit.lshift(1, bit_ % 8)
    return byte, bitmask
end

local function scene_flag_get(scene, word, bit_)
    local byte, bitmask = scene_flag_get_bb(scene, word, bit_)
    return bit.band(R1(byte), bitmask) ~= 0
end
-- TODO: check if current scene is scene id
-- if it is, adjust scene_flag_current_x so it doesn't overwrite ingame flags
local function scene_flag_reset(scene, word, bit_)
    local byte, bitmask = scene_flag_get_bb(scene, word, bit_)
    W1(byte, bit.band(R1(byte), 0xFF - bitmask))
end
local function scene_flag_set(scene, word, bit_)
    local byte, bitmask = scene_flag_get_bb(scene, word, bit_)
    W1(byte, bit.bor(R1(byte), bitmask))
end

local function event_flag_get_bb(byte, bit_)
    byte = byte + addrs.week_event_reg.addr
    local bitmask = bit.lshift(1, bit_ % 8)
    return byte, bitmask
end

local function event_flag_get(byte, bit_)
    local byte, bitmask = event_flag_get_bb(byte, bit_)
    return bit.band(R1(byte), bitmask) ~= 0
end
local function event_flag_reset(byte, bit_)
    local byte, bitmask = event_flag_get_bb(byte, bit_)
    W1(byte, bit.band(R1(byte), 0xFF - bitmask))
end
local function event_flag_set(byte, bit_)
    local byte, bitmask = event_flag_get_bb(byte, bit_)
    W1(byte, bit.bor(R1(byte), bitmask))
end

return globalize{
    scene_flag_get_bb = scene_flag_get_bb,
    scene_flag_get = scene_flag_get,
    scene_flag_reset = scene_flag_reset,
    scene_flag_set = scene_flag_set,
    event_flag_get_bb = event_flag_get_bb,
    event_flag_get = event_flag_get,
    event_flag_reset = event_flag_reset,
    event_flag_set = event_flag_set,
}
