local InputHandler = Class()
function InputHandler:init(binds)
    self.binds = binds or {
        A = "P1 A",
        B = "P1 B",
        L = "P1 L",
        R = "P1 R",
        Z = "P1 Z",
        d_up    = "P1 DPad U",
        d_down  = "P1 DPad D",
        d_left  = "P1 DPad L",
        d_right = "P1 DPad R",
        j_up    = "P1 Joy U",
        j_down  = "P1 Joy D",
        j_left  = "P1 Joy L",
        j_right = "P1 Joy R",
        c_up    = "P1 C Up",
        c_down  = "P1 C Down",
        c_left  = "P1 C Left",
        c_right = "P1 C Right",
        start   = "P1 Start",
    }
    self.old_ctrl = {}
end

function InputHandler:update(inputs)
    local ctrl = {}
    local pressed = {}
    local j = inputs or joypad.getimmediate()
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
