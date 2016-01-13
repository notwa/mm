-- gui.addmessage sucks so we're doing this our way

local function T(x, y, color, pos, s, ...)
    if #{...} > 0 then
        s = s:format(...)
    end
    gui.text(10*x + 2, 16*y + 4, s, color or "white", nil, pos or "bottomright")
end

local function T_BR(x, y, color, ...) T(x, y, color, "bottomright", ...) end
local function T_BL(x, y, color, ...) T(x, y, color, "bottomleft",  ...) end
local function T_TL(x, y, color, ...) T(x, y, color, "topleft",     ...) end
local function T_TR(x, y, color, ...) T(x, y, color, "topright",    ...) end

local messages = {}
local __messages_then = 0

local function message(text, frames)
    local now = emu.framecount()
    frames = frames or 60
    local when = now + frames
    table.insert(messages, {text=text, when=when})
end

local function draw_messages()
    local now = emu.framecount()
    if now == __messages_then then
        -- already drawn this frame
        return
    end
    if now ~= __messages_then + 1 then
        -- nonlinearity in time, probably a savestate
        messages = {}
    end

    local okay = {}
    for i, t in ipairs(messages) do
        if now < t.when then
            table.insert(okay, t)
        end
    end
    for i, t in ipairs(okay) do
        T_BL(0, #okay - i, nil, t.text)
    end

    messages = okay
    __messages_then = now
end

local __dprinted = {}

local function dprint(...) -- defer print
    -- helps with lag from printing directly to Bizhawk's console
    table.insert(__dprinted, {...})
end

local function dprintf(fmt, ...)
    table.insert(__dprinted, fmt:format(...))
end

local function print_deferred()
    local buff = ''
    for i, t in ipairs(__dprinted) do
        if type(t) == 'string' then
            buff = buff..t..'\n'
        elseif type(t) == 'table' then
            local s = ''
            for j, v in ipairs(t) do
                s = s..tostring(v)
                if j ~= #t then s = s..'\t' end
            end
            buff = buff..s..'\n'
        end
    end
    if #buff > 0 then
        print(buff:sub(1, #buff - 1))
    end
    __dprinted = {}
end

return globalize{
    T = T,
    T_BR = T_BR,
    T_BL = T_BL,
    T_TL = T_TL,
    T_TR = T_TR,
    dprint = dprint,
    dprintf = dprintf,
    print_deferred = print_deferred,
    message = message,
    draw_messages = draw_messages,
}
