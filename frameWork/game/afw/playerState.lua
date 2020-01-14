local skynet		= require "skynet"
local fieldObject 	= require "objects.fieldObject"

local playerState = class("playerState", fieldObject)

function playerState:init()

	playerState.__father.init(self, 'playerstates', true)	
end

function playerState:packet(key)

	local r = self:copyFields()
	local p = {}
	p[key] = r.data
	r.data = p
	return r
end	

return playerState	
