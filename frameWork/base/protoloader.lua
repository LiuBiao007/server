local sprotoloader = require "sprotoloader"
local gameproto = require "protos.parser"
local loader = {}

loader.game_c2s = 1
loader.game_s2c = 2

function loader.save()
	sprotoloader.save(gameproto.c2s, loader.game_c2s)
	sprotoloader.save(gameproto.s2c, loader.game_s2c)
end	

function loader.load(idx)
	local host = sprotoloader.load(idx):host "package"
	local response = host:attach(sprotoloader.load(idx + 1))
	return host, response
end	

return loader
