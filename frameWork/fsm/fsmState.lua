local fsmState = class("fsmState")

local assert   = assert
local type 	   = type
local string   = string
function fsmState:init()

	self.states = {}
end

function fsmState:setState(name, func, obj)

	assert(type(name) == "string" or type(name) == "number", string.format("error name %s", name))
	assert(type(func) == "function", string.format("error func %s", func))
	assert(not self.states[name], string.format("name [%s] has regist.", name))
	assert(name == 'enter' or name == 'exit' or name == 'update')
	self.states[name] = {
		obj  = obj,
		func = func
	}
end	

function fsmState:onExit(...)

	local exit = self.states.exit
	if exit then

		if exit.obj then
			exit.func(exit.obj, ...)
		else	
			exit.func(...)
		end	
	end	
end	

function fsmState:onEnter(...)

	local enter = self.states.enter
	if enter then

		if enter.obj then
			enter.func(enter.obj, ...)
		else	
			enter.func(...)
		end	
	end	
end

function fsmState:onUpdate(...)	

	local update = self.states.update
	if update then

		if update.obj then
			update.func(update.obj, ...)
		else	
			update.func(...)
		end	
	end	
end	

return fsmState

