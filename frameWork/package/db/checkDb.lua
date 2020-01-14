local assert		= assert
local string_format = string.format
local type 			= type
local json			= require "ext.json"

local checkDb = class("checkDb")
function checkDb:init(name)

	self.__name = assert(name, string_format("error name %s.", name))	
	return self
end	

function checkDb:checkField(data)

	local r = {}
	local fields = assert(dbField[self.__name], string_format("error save dbname %s", self.__name))
	for field, fieldType in pairs(fields) do
		if fieldType == 'D' and not tostring(data[field]):find("-") then	
			r[field] = os.dateTimeToString(assert(tonumber(data[field]), string.format("error dbname %s field %s", self.__name, field)))			
		else
			r[field] = data[field]
		end	
	end	

	assert(next(r), string_format("%s result is empty.", self.__name))
	return r
end	

function checkDb:checkLoad(data)

	local r = {}
	local fields = assert(dbField[self.__name], string_format("error save dbname %s", self.__name))
	for key, value  in pairs(data) do

		local fieldType = fields[key]
		assert(fieldType, string_format("error load data dbname %s key %s.", self.__name, key))
		if fieldType == 'D' then	
			r[key] = tonumber(os.stringToDateTime(value))
		elseif fieldType == 'J' then
			r[key] = json.decode(value)
		else
			r[key] = value
		end			
	end	

	assert(next(r), string_format("%s result is empty.", self.__name))
	return r
end	


return checkDb
