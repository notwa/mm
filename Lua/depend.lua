_require = _require or require

local function dumbdepend(path)
    if package and package.loaded and package.loaded[path] then
        package.loaded[path] = nil
    end
    -- TODO: pcall?
    return _require(path)
end

if luanet == nil then _require "luanet" end
if luanet == nil then
    print('depend: luanet is missing. no smart depend for you!')
    return dumbdepend
end

if true then
    -- gfgsdgfdfgsfgdfgdsgggsdgsddfsgdfgs luanet corrupts memory or something
    return dumbdepend
end

local NET = luanet.import_type
local File = NET('System.IO.File')
local Directory = NET('System.IO.Directory')

local here = Directory.GetCurrentDirectory()
local cd = Directory.SetCurrentDirectory

local function getmodtime(path)
    local dt = File.GetLastWriteTime(path)
    if dt == nil or dt == 0 then return end
    return dt:ToFileTimeUtc()
end

local function isdir(path)
    local ok, attr = pcall(function() return File.GetAttributes(path) end)
    if not ok then return false end
    attr = tostring(attr)
    return not not attr:find("Directory")
end

package.depended = package.depended or {}
package.times = package.times or {}
local packages = package.depended
local times = package.times

local function depend(require_path)
    -- require, but with reloading based on last modified date
    -- also always relative to THIS file's current directory
    -- WARNING: not fully compatible with require path syntax

    local path = require_path:gsub('%.', '/')
    --print()
    --print('DEPEND', path)

    if not pcall(function() cd(here) end) then
        print('depend: failed to set current directory:', here)
        return
    end

    local t
    local function try(path)
        if isdir(path) then return end
        t = getmodtime(path)
        if t == nil or t == 0 then return end
        return path
    end

    local id = path:gsub('[.][^.]+$', '') -- remove extension
    local ext_path = try(id) or try(id..'.lua') or try(id..'.luac')
    local needs_update = t == nil or times[id] == nil or t > times[id]

    --if not ext_path then print('no path :c') end
    --if not needs_update then print('no update required') end

    if ext_path and needs_update then
        --print('requiring', ext_path)
        times[id] = t
        packages[require_path] = dumbdepend(path)
    end

    return packages[require_path]
end

return depend
