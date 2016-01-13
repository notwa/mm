-- check for errors in the actor linked lists
local validate = false

-- creating an object every time is a bit slow, so
-- using a template to offset from will do for now.
local actor_t = Actor(0)

local function sort_by_key(t)
    local sorted = {}
    local i = 1
    for k, v in pairs(t) do
        sorted[i] = {k=k, v=v}
        i = i + 1
    end
    table.sort(sorted, function(a, b) return a.k < b.k end)
    return sorted
end

local function get_actor_count(i)
    return R4(addrs.actor_counts[i].addr)
end

local function get_first_actor(i)
    return deref(R4(addrs.actor_firsts[i].addr))
end

local function get_next_actor(addr)
    return deref(R4(addr + actor_t.next.addr))
end

local function get_prev_actor(addr)
    return deref(R4(addr + actor_t.prev.addr))
end

local function count_actors()
    local counts = {}
    for i = 0, 11 do
        counts[i] = get_actor_count(i)
    end
    return counts
end

local function iter_actors(counts)
    local at, ai = 0, 0
    local addr

    local y = 1
    local complain = function(s)
        s = s..(" (%2i:%3i)"):format(at, ai)
        T_TR(0, y, "yellow", s)
        y = y + 1
    end

    local iterate
    iterate = function()
        if ai == 0 then
            addr = get_first_actor(at)
            if validate and addr and get_prev_actor(addr) then
                complain("item before first")
            end
        else
            local prev = addr
            addr = get_next_actor(addr)
            if validate then
                if addr and prev ~= get_prev_actor(addr) then
                    complain("previous mismatch")
                end
            end
        end

        if not addr then
            if validate then
                if ai < counts[at] then
                    -- known case: romani ranch on first/third night
                    complain("list ended early")
                elseif ai > counts[at] then
                    complain("list ended late")
                end
            end

            ai = 0
            at = at + 1
            if at == 12 then return nil end
            return iterate()
        else
            local temp = ai
            ai = ai + 1
            return at, temp, addr
        end
    end

    return iterate
end

local function collect_actors()
    local game_counts = count_actors()
    local any = 0
    for i = 0, 11 do
        any = any + game_counts[i]
        --FIXME: T_BR(0, 13 - i, nil, "#%2i: %2i", i, game_counts[i])
    end
    --FIXME: T_BR(0, 1, nil, "sum:%3i", any)

    local actors_by_type = {[0]={},{},{},{},{},{},{},{},{},{},{},{}} -- 12
    local new_counts = {[0]=0,0,0,0,0,0,0,0,0,0,0,0} -- 12
    if any > 0 then
        any = 0
        for at, ai, addr in iter_actors(game_counts) do
            actors_by_type[at][ai] = addr
            new_counts[at] = new_counts[at] + 1
            any = any + 1
        end
    end
    return any > 0, actors_by_type, new_counts
end

return globalize{
    sort_by_key = sort_by_key,
    get_actor_count = get_actor_count,
    get_first_actor = get_first_actor,
    get_next_actor = get_next_actor,
    get_prev_actor = get_prev_actor,
    count_actors = count_actors,
    iter_actors = iter_actors,
    collect_actors = collect_actors,
}
