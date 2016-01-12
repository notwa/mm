local hash
if bizstring then
    hash = gameinfo.getromhash() 
else
    hash = m64p.rom.settings.MD5
end
local Game = require "addrs.addrs"
local game = Game(hash)
version = game.version
oot = game.oot
mm = game.mm
addrs = game
return game
