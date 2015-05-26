local InputHandler = Class()
function InputHandler:init(binds)
    self.binds = binds
    self.old_ctrl = {}
end

function InputHandler:update()
    local ctrl = {}
    local pressed = {}
    local j = joypad.getimmediate()
    for k, v in pairs(self.binds) do
        ctrl[k] = j[v]
    end
    for k, v in pairs(ctrl) do
        pressed[k] = ctrl[k] and not self.old_ctrl[k]
    end
    self.old_ctrl = ctrl
    return ctrl, pressed
end

return InputHandler
