local skynet = require "skynet"
local assert = assert
local type   = type
local string = string

function serialize(obj, lvl, isFeed)
    local lua = ""
    local feed1 = isFeed and "{" or "{\n"
    local feed2 = isFeed and "," or ",\n"
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lvl = lvl or 0
        local lvls = ('  '):rep(lvl)
        local lvls2 = ('  '):rep(lvl + 1)
        lua = lua .. feed1
        for k, v in pairs(obj) do
            lua = lua .. lvls2
            lua = lua .. "[" .. serialize(k, lvl + 1) .. "]=" .. serialize(v, lvl + 1) .. feed2
        end
        local metatable = getmetatable(obj)
        if metatable and type(metatable.__index) == "table" then
        for k, v in pairs(metatable.__index) do
            lua = lua .. "[" .. serialize(k, lvl + 1) .. "]=" .. serialize(v, lvl + 1) .. feed2
        end
    end
        lua = lua .. lvls
        lua = lua .. "}"
    elseif t == "nil" then
        return
    elseif t == "function" then
        return      
    else
        error("can not serialize a " .. t .. " type.")
    end
    return lua
end
 
return function (module, ...)

	assert(type(module) == "string", string.format("newservice module %s not found.", module))
	local newParam = {}
	local param = {...}
	if #param > 0 then

		for _, v in ipairs(param) do
			if type(v) == "string" or type(v) == "number" then
				table.insert(newParam, v)
			elseif type(v) == "table" then
				assert(not getmetatable(v))
				table.insert(newParam, serialize(v, 0, true))
			else
				error(string.format("error param type:%s.", type(v)))
			end	
		end	
	end	 

	return skynet.newservice("service", module, 24, table.unpack(newParam))
end
