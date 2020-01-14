local handler = {}

local function constructHandler(protos)

	for name, func in pairs(protos) do
		assert(not handler[name], string.format("error name %s", name))
		handler[name] = func
	end	
end	



return handler