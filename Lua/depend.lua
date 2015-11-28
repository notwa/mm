_require = _require or require

local function dumbdepend(path)
    if package and package.loaded and package.loaded[path] then
        package.loaded[path] = nil
    end
    -- TODO: pcall?
    return _require(path)
end

return dumbdepend
