local table = table
local type = type
local subject = {}

function subject:new(o)

	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function subject:attach(o, obj)
	
	if self.observers == nil then
		self.observers = {}
	end
	
	if not obj then
		table.insert(self.observers, o)
	else
		table.insert(self.observers, {o = o, obj = obj})
	end	
end

function subject:detach(o, obj, ...)

	if self.observers == nil then
		return
	end	
	
	for k,v in pairs(self.observers) do

		if not obj then
			if v == o then
				table.remove(self.observers, k)
				break
			end
		else
			if v.o == o and v.obj == obj then
				table.remove(self.observers, k)
				break
			end	
		end	
	end
end

function subject:notify(...)
	
	if self.observers == nil then
		return
	end

	for k,v in pairs(self.observers) do
		if type(v) == "function" then
			v(...)
		else
			v.o(v.obj, ...)
		end
	end
end

return subject
