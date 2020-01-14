local component = {}

function component.addComponent(target, obj, ...)

	assert(target.class, string.format("target must be instance."))
	assert(obj.__classname, string.format("obj must be class."))
	local coms = target.__components
	if not coms then
		coms = {}
		target.__components = coms
	end	

	local name = obj.__classname
	assert(not coms[name], string.format("name [%s] has be in components.", name))
	coms[name] = obj:new(target, ...)
	return coms[name]
end

--name can be string or class
function component.getComponent(target, name)
	
	assert(target.class, string.format("target must be instance."))	
	if type(name) == 'table' then
		name = name.__classname
	end	

	if not target.__components then return nil end
	return target.__components[name]
end

--name can be class or string name or instance
function component.removeComponent(target, name)

	assert(target.class, string.format("target must be instance."))
	if type(name) == 'table' then

		--class
		if name.__classname then
			name = name.__classname
		else--instance
			local meta = getmetatable(name)
			if meta then

				local t = rawget(meta, "__index")
				if t then

					name = rawget(t, "__classname")
				end	
			end	
		end	
	end	

	if not name then return false end
	if not target.__components[name] then return false end
	target.__components[name] = nil
	return true
end	

return component