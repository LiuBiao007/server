local assert 	 = assert
local string     = string

local redisHeader = class("redisHeader")

function redisHeader:init(dbname, ...)

	assert(type(dbField) == "table", "error dbField.")
	assert(type(dbname)  == "string", "error dbname")

	self.dbname   = dbname
	self.dbField = assert(dbField[dbname], string.format("error dbname %s.", dbname))
	assert(type(extra_db[dbname].__prikey) == "string", string.format("dbname [%s] miss prikey.", self.dbname))
	self.prikey = extra_db[dbname].__prikey
	return self
end

function redisHeader:getHeader(key)

	assert(type(key) == "string" or type(key) == "number", string.format("error key %s.", key))
	return string.format("%s:%s:%s", self.dbname, self.prikey, key)
end	

function redisHeader:getPriKey()

	return assert(self.prikey)
end	

function redisHeader:getRedisSet(key)

	if not key then
		return string.format("set:%s", self.dbname)
	else
		return string.format("set:%s:%s", self.dbname, key)
	end	
end	

return redisHeader