Monitor = Class()
function Monitor:init(name, a)
    self.name = name
    self.begin = a.addr
    self.len = a.type
    self.once = false
    self.old_bytes = {}
end

function Monitor:diff()
    -- bizhawk has an off-by-one bug where this returns length + 1 bytes
    local bytes = mainmemory.readbyterange(self.begin, self.len-1)
    local old_bytes = self.old_bytes
    if self.once then
        for k, v in pairs(bytes) do
            local i = tonumber(k) - self.begin
            local x = tonumber(v)
            local x1 = tonumber(old_bytes[k])
            if x ~= x1 then
                self:mark(i, x, x1)
            end
        end
    end
    self.old_bytes = bytes
    self.once = true
end

