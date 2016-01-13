if _require then return end
_require = require

package.path = package.path..';./lib/?.lua'
package.path = package.path..';./lib/?/init.lua'

function depend(path)
    if package and package.loaded and package.loaded[path] then
        package.loaded[path] = nil
    end
    return _require(path)
end
