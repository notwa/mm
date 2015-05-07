-- gui.addmessage sucks so we're doing this our way

function T(x, y, color, pos, s, ...)
    if #{...} > 0 then
        s = s:format(...)
    end
    gui.text(10*x + 2, 16*y + 4, s, nil, color or "white", pos or "bottomright")
end

function T_BR(x, y, color, ...) T(x, y, color, "bottomright", ...) end
function T_BL(x, y, color, ...) T(x, y, color, "bottomleft",  ...) end
function T_TL(x, y, color, ...) T(x, y, color, "topleft",     ...) end
function T_TR(x, y, color, ...) T(x, y, color, "topright",    ...) end

messages = {}
__messages_then = 0

function message(text, frames)
    local now = emu.framecount()
    frames = frames or 60
    local when = now + frames
    table.insert(messages, {text=text, when=when})
end

function draw_messages()
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
        T_BL(0, i - 1, nil, t.text)
    end

    messages = okay
    __messages_then = now
end
