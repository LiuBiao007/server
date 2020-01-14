local sprotoparser 	= require "sprotoparser"
local table 		= table
local push			= table.insert
local sort			= table.sort
local concat        = table.concat
local string_gsub 	= string.gsub
local proto 		= {}
local types 		= [[
	.package {
		type 0 : integer
		session 1: integer
	}
]]

local c2s 			= [[]]
local s2c 			= [[]]

local effect_types = {types}
local effect_c2s = {}
local effect_s2c = {}
local function constructdata(data)

	if data.types then
		push(effect_types, data.types)
	end

	if data.c2s then
		push(effect_c2s, data.c2s)
	end

	if data.s2c then
		push(effect_s2c, data.s2c)
	end	
end	

local protoFiles = {}
local list = io.popen("ls ../common/protos"):read("*all")
list:gsub("(.-).lua", function (name)
	if name:find("[p|P]roto") then

		push(protoFiles, name)
	end	
end)

sort(protoFiles)

local function trim(s, char)

    return string_gsub(s, "^%s*(.-)%s*$", "%1")
end

for _, name in pairs(protoFiles) do

	local f = require("protos" .. "." .. trim(name))
	constructdata(f)	
end	

types 	= concat(effect_types, "")
c2s 	= concat(effect_c2s, "")
s2c 	= concat(effect_s2c, "")

local i = 0
c2s = c2s:gsub("%%d", function (m) 
	
	i = i + 1
	return i
end)

s2c = s2c:gsub("%%d", function (m) 
	
	i = i + 1
	return i
end)

proto.c2s = sprotoparser.parse(types .. c2s)
proto.s2c = sprotoparser.parse(types .. s2c)

return proto

