local skynet		= require "skynet"
local fieldObject 	= require "objects.fieldObject"

local factionState = class("factionState", fieldObject)

function factionState:init()

	factionState.__father.init(self, 'factionstate')	
end

return factionState	
