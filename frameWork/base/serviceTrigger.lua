local skynet = require "skynet"
local uniqueService = require "services.uniqueService"
local serviceTrigger = {}

local serviced
function getService()

	if not serviced then
		serviced = uniqueService("base.triggerd")
	end
	return serviced	
end	

function serviceTrigger.add(name)

	assert(type(SERVICE_OBJECT[name]) == "function", 
		string.format("add function:[%s] in class:[%s] first.", name, SERVICE_OBJECT.__classname))
	skynet.send(getService(), "lua", "add", name, skynet.self())
end	

function serviceTrigger.dec(name)

	skynet.send(getService(), "lua", "dec", name, skynet.self())
end

function serviceTrigger.send(name, ...)

	skynet.send(getService(), "lua", "send", name, skynet.self(), ...)
end	

function serviceTrigger.call(name, ...)

	return skynet.call(getService(), "lua", "call", name, skynet.self(), ...)
end	

function serviceTrigger.callResult(name, ...)
	return skynet.call(getService(), "lua", "callResult", name, skynet.self(), ...)
end	

function serviceTrigger.onServiceExit()

	if not __cnf.isMaster then
		local m = uniqueService("commonService.monitor")
		skynet.send(m, "lua", "businessEnd", skynet.self(), SERVICE_OBJECT.serviceName)
		return skynet.call(getService(), "lua", "onServiceExit", skynet.self())
	end
	return true	
end	

return serviceTrigger