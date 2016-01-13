if _require then return end
_require = require

package.path = package.path..';./lib/?.lua'
package.path = package.path..';./lib/?/init.lua'

require "strict"

local function depend(path)
    if package and package.loaded and package.loaded[path] then
        package.loaded[path] = nil
    end
    return _require(path)
end

local function globalize(t)
    for k, v in pairs(t) do
        rawset(_G, k, v)
    end
end

return globalize{
    depend = depend,
    globalize = globalize,
}
