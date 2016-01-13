local print = rawget(_G, 'dprint') or print

-- hack to avoid N64 logo spitting errors
local stupid = addrs.actor_counts[0].addr - 0x8

-- creating an object every time is a bit slow, so
-- using a template to offset from will do for now.
local actor_t = Actor(0)

local suffix = oot and " oot" or ""
local actor_names  = require("data.actor names"..suffix)

local ActorLister = Class()
function ActorLister:init(input_handler, debug_mode)
    self.before = 0
    self.wait = 0
    self.focus_at = 2
    self.focus_ai = 0
    self.seen_once = {}
    self.seen_strs = {}
    self.seen_strs_sorted = {}
    self.input = input_handler
    self.debug_mode = debug_mode
end

function ActorLister:wipe()
    if #self.seen_strs_sorted > 0 then
        print()
        print("# actors wiped #")
        print()
    end
    self.seen_once = {}
    self.seen_strs = {}
    self.seen_strs_sorted = {}
end

function ActorLister:run(now)
    local game_counts = nil
    local seen = {}
    local cursor, target

    local ctrl, pressed = self.input:update()

    if pressed.left  then self.focus_ai = self.focus_ai - 1 end
    if pressed.right then self.focus_ai = self.focus_ai + 1 end
    if pressed.down then
        -- follow Link again
        self.focus_at = 2
        self.focus_ai = 0
    end

    if R4(stupid) ~= 0 then
        T_BR(0, 0, "red", "stupid")
        return
    end

    local any, actors_by_type, new_counts = collect_actors()

    if not any then
        self:wipe()
    else
        while self.focus_ai < 0 do
            self.focus_at = (self.focus_at - 1) % 12
            self.focus_ai = new_counts[self.focus_at] - 1
        end
        while self.focus_ai >= new_counts[self.focus_at] do
            self.focus_at = (self.focus_at + 1) % 12
            self.focus_ai = 0
        end
        cursor = deref(addrs.z_cursor_actor())
        target = deref(addrs.z_target_actor())
    end

    local focus_link = self.focus_at == 2 and self.focus_ai == 0
    if self.debug_mode then focus_link = false end
    local needs_update = false

    for at, actors in pairs(actors_by_type) do
      for ai, addr in pairs(actors) do -- FIXME: sorry for this pseudo-indent
        local var = R2(addr + actor_t.var.addr)
        local hp  = R1(addr + actor_t.hp.addr)
        local num = R2(addr + actor_t.num.addr)
        local name = actor_names[num]
        local fa = addr + actor_t.flags.addr
        local flags = R4(fa)

        local focus_this = at == self.focus_at and ai == self.focus_ai

        seen[num] = true

        if not name then
            name = "NEW"
            actor_names[num] = name
            print(("\t[0x%03X]=\"NEW\","):format(num))
        end

        if not self.seen_once[num] then
            self.seen_once[num] = now
            needs_update = true
            local str
            if name:sub(1,1) == "?" then
                str = ("%s (%03X)"):format(name, num)
            else
                str = ("%s"):format(name)
            end
            self.seen_strs[num] = str
            print(str)
        end

        local focal = false
        if not self.debug_mode then
            focal = focal or (focus_this and not focus_link)
            focal = focal or (focus_link and addr == target)
        else
            if target then
                focal = addr == target
            else
                focal = focus_this
            end
        end
        if focal then
            local actor = {
                name = name,
                addr = addr,
                ai = ai,
                type_count = new_counts[at],

                at = at,
                var = var,
                flags = flags,
                hp = hp,
                num = num,
            }
            focus(actor, pressed.up) -- FIXME: global
        end

        if focus_this then
            W4(addrs.camera_target.addr, addr)
            W1(addrs.camera_target.addr, 0x80)
        end

        -- make all actors z-targetable
        if not (focus_this and focus_link) then
            flags = bit.bor(flags, 0x00000001)
            W4(fa, flags)
        end
      end
    end

    if needs_update then
        self.seen_strs_sorted = sort_by_key(self.seen_strs)
    end

    if focus_link and not target then
        for i, t in ipairs(self.seen_strs_sorted) do
            local color = 'white'
            if self.seen_once[t.k] and now - 60 <= self.seen_once[t.k] then
                color = 'lime'
            end
            if not seen[t.k] then
                color = 'orange'
            end
            T_TL(0, i - 1, color, t.v)
        end
    end

    T_BR(0, 0, nil, "unique:%3i", #self.seen_strs_sorted)

    if any then
        local z = target or cursor
        if z then
            local num = R2(z)
            T_TR(0, 0, nil, self.seen_strs[num])
        end
    end
end

-- TODO: abstract to wrapper class or something
function ActorLister:runwrap(now)
    if now < self.before then self.wait = 2 end
    self.before = now
    if self.wait > 0 then
        -- prevent script from lagging reversing
        self.wait = self.wait - 1
        if self.wait == 0 then self:wipe() end
    else
        self:run(now)
    end
end

return ActorLister
