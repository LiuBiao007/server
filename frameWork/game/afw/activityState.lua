local skynet		= require "skynet"
local fieldObject 	= require "objects.fieldObject"

local activityState = class("activityState", fieldObject)

function activityState:init()

	activityState.__father.init(self, 'activitystates')	
end

function activityState:packet(key)

	local r = self:copyFields()
	local p = {}
	p[key] = r.data
	r.data = p
	return r
end	

return activityState	
