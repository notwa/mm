local function handle_alt_input(handle, ctrl, pressed)
    for _, v in ipairs{'left', 'right', 'up', 'down'} do
        ctrl[v] = ctrl['d_'..v]
        pressed[v] = pressed['d_'..v]
    end
    pressed.enter = false
    ctrl.enter = false
    local open_close = ctrl.L and ctrl.R and (pressed.L or pressed.R)
    local hide = ctrl.L and ctrl.Z and (pressed.L or pressed.Z)
    if open_close then
        if handle.menu then -- if menu is open
            handle:navigate('close')
        else
            pressed.enter = true
            ctrl.enter = true
        end
    else
        if hide then
            handle:navigate('hide')
        elseif pressed.L then
            handle:navigate('back')
        elseif handle.menu then
            pressed.enter = pressed.R
            ctrl.enter = ctrl.R
        end
    end
    handle:update(ctrl, pressed)
end

local function handle_eat_input(handle, ctrl, pressed)
    for _, v in ipairs{'left', 'right', 'up', 'down'} do
        ctrl[v] = ctrl['d_'..v] or ctrl['j_'..v] or ctrl['c_'..v]
        pressed[v] = pressed['d_'..v] or pressed['j_'..v] or pressed['c_'..v]
    end
    if not handle.menu then
        pressed.enter = pressed.L
    else
        if pressed.L then
            handle:navigate('close')
        elseif pressed.Z then
            handle:navigate('hide')
        elseif pressed.R or pressed.B then
            handle:navigate('back')
        else
            pressed.enter = pressed.A or pressed.L
            ctrl.enter = ctrl.A
        end

        joypad.set({}, 1)
        joypad.setanalog({["X Axis"]=false, ["Y Axis"]=false}, 1)
    end
    handle:update(ctrl, pressed)
end

return globalize{
    handle_eat_input = handle_eat_input,
    handle_alt_input = handle_alt_input,
}
