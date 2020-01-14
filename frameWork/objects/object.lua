local colock = require "base.colock"
local object = class("object")

function object:init()

	self.colock = colock:new()
	local function pcall_ret(name, ok, ...)

		self.colock:unlock()	
		assert(ok, (...))
		return ...
	end	

	self.safeLock = function (f, name, ...)

		name = name or self.__classname	
		self.colock:lock(name)
		return pcall_ret(name, xpcall(f, debug.traceback, ...))
	end

	return self
end	

function object:setData(data)

	assert(type(data) == "table", string.format("data %s.", data))
	assert(not getmetatable(data), string.format("error data %s.", data.__classname))
	for k, v in pairs(data) do
		self[k] = v
	end	
	return self
end

function object:onServiceStarted()

	mylog.debug("##########father onServiceStarted##############")
end

function object:_gc_()

	collectgarbage "collect"
end	

return object	
