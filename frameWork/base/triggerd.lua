local skynet 		= require "skynet"
local serviceObject = require "objects.serviceObject"
local trigger 		= {}
local triggerd 		= class("triggerd", serviceObject)

local push 			= table.insert
function triggerd:add(name, service)

	assert(type(name) 	 == "string", string.format("error name: %s.", name))
	assert(type(service) == "number", string.format("error service: %s.", service))
	if not trigger[name] then
		trigger[name] = {}
	end	
	trigger[name][service] = true
end	

local function checkCall(name, service)

	assert(type(name) == "string", string.format("error name: %s.", name))
	if not trigger[name] then return end
	assert(not trigger[name][service], 
	string.format("service %08X name %s can not notify in self service, please use base.subject instead of.",
		service, name))
end	

function triggerd:send(name, service, ...)

	checkCall(name, service)

	for service, _ in pairs(trigger[name] or {}) do
		pcall(skynet.send, service, "lua", name, ...)
	end	
end	

function triggerd:call(name, service, ...)

	checkCall(name, service)
	
	for service, _ in pairs(trigger[name] or {}) do
		local ok = pcall(skynet.call, service, "lua", name, ...)
		if not ok then 
			mylog.warn("error trigger call %s service %s.", name, service) 
			return nil
		end
	end	
	return true
end	

function triggerd:onServiceExit(service)

	assert(service)
	for name, item in pairs(trigger) do

		if item[service] then item[service] = nil end
	end	
	return true
end	

function triggerd:callResult(name, service, ...)

	checkCall(name, service)
	
	local result = {}
	for service, _ in pairs(trigger[name] or {}) do
		local ok, key, data = pcall(skynet.call, service, "lua", name, ...)
		if not ok then 
			mylog.warn("error trigger call %s service %s.", name, service) 
			return nil
		end

		assert(type(key) == "string" and data, string.format("error name %s service %08X.",
			name, service))
		if not result[key] then result[key] = {} end
		push(result[key], data)
	end	
	return result	
end	

function triggerd:dec(name, service)

	assert(type(name) == "string", string.format("error name: %s.", name))
	assert(type(service) == "number", string.format("error service: %s.", service))
	if not trigger[name] then return end
	trigger[name][service] = nil
end	

return triggerd