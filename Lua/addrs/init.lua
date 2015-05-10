-- deprecated
local hash = gameinfo.getromhash()
local Game = require "addrs.addrs"
local game = Game(hash)
version = game.version
oot = game.oot
mm = game.mm
addrs = game
return game
