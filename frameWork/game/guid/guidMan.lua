local skynet = require "skynet"
local uniqueService = require "services.uniqueService"
local guidMan = {}

local guidd
local function getguidd()

	if not guidd then
		guidd = uniqueService("guid.guidd")
	end	
	return guidd
end	

function guidMan.createGuid(type)

	return skynet.call(getguidd(), "lua", "createGuid", type)
end	

function guidMan.reverseGuid(guid)

	return skynet.call(getguidd(), "lua", "reverseGuid", guid)
end	

function guidMan.reverseGuidType(guid)

	return skynet.call(getguidd(), "lua", "reverseGuidType", guid)
end	

function guidMan.reverseId(guid)

	return skynet.call(getguidd(), "lua", "reverseId", guid)
end	

function guidMan.reverserServerId(guid)

	return skynet.call(getguidd(), "lua", "reverserServerId", guid)
end	

return guidMan