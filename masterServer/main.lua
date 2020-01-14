local skynet 		= require "skynet"
local cluster 		= require "cluster"
local newService 	= require "services.newService"
local uniqueService = require "services.uniqueService"
local game 			= require "game"

skynet.init(function ()

	game.init()
end)

skynet.start(function ()

	uniqueService("guid.guidd")
	uniqueService("commonService.timerd")

	cluster.register("masterService", uniqueService("commonService.masterService"))
	cluster.open "masterserver"

	game.exit()
end)
