local protoloader   = require "base.protoloader"
local serviceObject = require "objects.serviceObject"
local mylog			= require "base.mylog"
local sproto 		= class("sproto", serviceObject)

function sproto:init()

	protoloader.save()
	mylog.info("sproto service start.")
end

function sproto:shut()

	mylog.info("sproto service shut.")
end	

return sproto
