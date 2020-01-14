local assert  = assert
local type	  = type
local string  = string
local push    = table.insert

local trigger = {}
local objects = {}
function trigger.add(name, obj, func)

	assert(type(name) == "string", string.format("name type [%s] error.", name))
	assert(type(obj) == "table")
	assert(type(func) == "function")
	if not objects[name] then
		objects[name] = {}
	end	
	objects[name][obj] = func
end

function trigger.dec(name, obj)

	assert(type(name) == "string", string.format("name type [%s] error.", name))
	assert(type(obj) == "table")
	if not objects[name] then return end
	objects[name][obj] = nil
end

function trigger.notify(name, ...)

	assert(type(name) == "string", string.format("name type [%s] error.", name))
	local objs = objects[name]
	if not objs then return end
	for obj, func in pairs(objs) do
		func(obj, ...)
	end	
end	

function trigger.notifyAndReset(name, ...)

	assert(type(name) == "string", string.format("name type [%s] error.", name))
	local objs = objects[name]
	if not objs then return end
	objects[name] = {}
	for obj, func in pairs(objs) do
		func(obj, ...)
	end		
end	

return trigger
