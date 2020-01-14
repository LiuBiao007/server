local skynet 	 = require "skynet"
local newService = require "services.newService"
require "skynet.manager"

local error		= error
local string	= string
local assert  	= assert
local type		= type
local tostring	= tostring
local pcall		= pcall
local coroutine	= coroutine
local table 	= table

local services 	 = {}
local function request(module, new, ...)

	local ok, handle = pcall(new, module, ...)
	local s = services[module]
	assert(type(s) == "table")
	if ok then

		services[module] = handle
	else
		services[module] = tostring(handle)
	end	

	for _, v in pairs(s) do
		skynet.wakeup(v.co)
	end	

	if ok then 
		return handle
	else
		error(tostring(handle))
	end	
end

local function waitfor(new, module, ...)

	assert(type(new) == "function")
	local s = services[module]
	if type(s) == "number" then
		return s
	end	

	if s == nil then

		s = {}
		services[module] = s
	else
		assert(type(s) == "string", string.format("error module %s.", module))
		error(s)
	end	

	local co = coroutine.running()
	assert(type(s) == "table")
	if s.launch == nil then

		s.launch = {
			co = co
		}
		return request(module, new, ...)
	else
		
		push(s, {co = co})
	end	

	skynet.wait()

	local s = services[module]
	if type(s) == "string" then
		error(s)
	end	
	assert(type(s) == "number")
	return s
end	

skynet.start(function ()

	skynet.dispatch("lua", function (_, _, module, ...)

		assert(type(module) == "string", string.format("error module %s.", module))
		skynet.retpack(waitfor(newService, module, ...))
	end)
	assert(not skynet.localname(".uniqueservice"), ".uniqueservice has started already.")
	skynet.register(".uniqueservice")
end)