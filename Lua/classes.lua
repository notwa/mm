require "serialize"

Monitor = Class()
function Monitor:init(name, a)
    self.name = name
    self.begin = a.addr
    self.len = a.type
    self.once = false
    self.old_bytes = {}
    self.modified = {}
    self.dirty = false
end

function Monitor:read()
    -- bizhawk has an off-by-one bug where this returns length + 1 bytes
    local raw = mainmemory.readbyterange(self.begin, self.len-1)
    local bytes = {}
    local begin = self.begin
    for k, v in pairs(raw) do
        bytes[k - begin] = v
    end
    return bytes
end

function Monitor:diff()
    local bytes = self:read()
    local old_bytes = self.old_bytes
    if self.once then
        for i, v in pairs(bytes) do
            local x = v
            local x1 = old_bytes[i]
            if x ~= x1 then
                self:mark(i, x, x1)
            end
        end
    end
    self.old_bytes = bytes
    self.once = true
end

function Monitor:load(fn)
    self.modified = deserialize(fn) or {}
    self.dirty = false
    self.fn = fn
end

function Monitor:save(fn)
    if self.dirty then
        serialize(fn or self.fn, self.modified)
        self.dirty = false
    end
end

InputHandler = Class()
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
