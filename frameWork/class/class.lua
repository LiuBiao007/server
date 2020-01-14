local assert 		= assert
local type   		= type
local string 		= string
local setmetatable 	= setmetatable

local function new(t, ...)

	local obj = {}
	setmetatable(obj, {__index = t})
	obj.class = t
	obj:init(...)
	return obj
end	

class = function (name, father)
	
	assert(type(name) == "string", string.format("error class name %s.", name))	
	local t
	t = {
		__classname = name,
		new = function (t, ...)
			return new(t, ...)
		end
	}

	if type(father) == 'table' then

		assert(type(father.__classname) == 'string', string.format("error father name %s.", father.__classname))
		t.__father = father
		setmetatable(t, {__index = father})
	end	

	if not t.init then
		t.init = function () end
	end	

	return t
end
