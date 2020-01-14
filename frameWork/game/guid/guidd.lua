local serviceObject 	= require "objects.serviceObject"
local db 				= require "coredb.query"
local guidObj    		= require "guid.guid"
local guidd 			= class("guidd", serviceObject)

local tonumber 			= tonumber
function guidd:init(...)

	guidd.__father.init(self, ...)
	self:loadSerials()
	return self
end	

function guidd:loadSerials()

	local serials =  db:name('serials'):where('id', 0):find() 
    self.guidObj = guidObj:load(serials)
end	

function guidd:createGuid(type)

	local key = gameconst.serialtype2str[type]
	assert(key, string.format("createGuid error type:%s.", type))
	local value = self.guidObj[key]
	self.guidObj[key] = value + 1
	local serverid = __cnf.serverId
	local platform = __cnf.platform

	return string.format("%08X%04X%04X%08X", serverid, platform,type,value)
end	

function guidd:reverseGuid(guid)

	assert(type(guid) == "string")
	local function transto(str)
		
		return tonumber("0X" .. str)
	end
	
	local serverId = string.sub(guid,1,8)
	local platform = string.sub(guid,9,12)
	local type 	   = string.sub(guid,13,16)
	local serial   = string.sub(guid,17,24)
	
	return {
		type 		= transto(type),
		serverId 	= transto(serverId),
		platform 	= transto(platform),
		serial 		= transto(serial),
	}
end	

function guidd:reverseGuidType(guid)

	assert(type(guid) == "string")
	return self:reverseGuid(guid).type
end	

function guidd:reverseId(guid)

	assert(type(guid) == "string")
	return self:reverseGuid(guid).serial	
end	

function guidd:reverserServerId(guid)

	assert(type(guid) == "string")
	return self:reverseGuid(guid).serverId	
end	

return guidd
