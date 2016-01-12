local JoyWrapper = Class()
function JoyWrapper:init(handler, threshold)
    self.handler = handler
    self.old_ctrl = {}
    self.threshold = threshold or 80
end

function JoyWrapper:update(inputs)
    local j = inputs or joypad.getimmediate()
    local jj = joypad.get()
    local jx = jj['P1 X Axis']
    local jy = jj['P1 Y Axis']
    j["P1 Joy R"] = jx >=  self.threshold or jj['P1 A Right']
    j["P1 Joy L"] = jx <= -self.threshold or jj['P1 A Left']
    j["P1 Joy U"] = jy >=  self.threshold or jj['P1 A Up']
    j["P1 Joy D"] = jy <= -self.threshold or jj['P1 A Down']
    return self.handler:update(j)
end

return JoyWrapper
