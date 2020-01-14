local skynet		= require "skynet"
local fieldObject 	= require "objects.fieldObject"

local activityGlobalState = class("activityGlobalState", fieldObject)

function activityGlobalState:init()

	activityGlobalState.__father.init(self, 'activityglobalstates')	
end

function activityGlobalState:packet(key)

	local r = self:copyFields()
	local p = {}
	p[key] = r.data
	r.data = p
	return r
end	

return activityGlobalState	
