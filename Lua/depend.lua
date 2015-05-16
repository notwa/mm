_require = _require or require
return function(path)
    if package and package.loaded and package.loaded[path] then
        -- TODO: check if file is more recent using luanet hacks
        package.loaded[path] = nil
    end
    -- TODO: pcall?
    return _require(path)
end
