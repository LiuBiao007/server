local skynet 		= require "skynet"
local newService 	= require "services.newService"
local uniqueService = require "services.uniqueService"
local game 			= require "game"

skynet.init(function ()

	game.init()
end)

skynet.start(function ()


	game.run(function ()
		--启动其他的业务服务
	end)

	game.exit()
end)

