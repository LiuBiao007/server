local skynet 		= require "skynet"
local fieldObject 	= require "objects.fieldObject"

local guid 			= class("guid", fieldObject)

function guid:init()

	guid.__father.init(self, 'serials')	

	self.writeRedisError:attach(self.writeError, self)
	self.writeRedisSuccess:attach(self.writeSuccess, self)

	return self
end	

function guid:writeError(dbname, data)

	mylog.warn("[GUID] writeError dbname:%s data:%s", dbname, string.serialize(data, 0, true))
end

function guid:writeSuccess(dbname, data)

	mylog.debug("[GUID] writeSuccess dbname:%s data:%s", dbname, string.serialize(data, 0, true))
end	

return guid