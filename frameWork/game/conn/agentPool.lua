local skynet		= require "skynet"
local newService 	= require "services.newService"
local serviceObject = require "objects.serviceObject"
local object	 	= require "objects.object"
local agentPool  	= class("agentPool", serviceObject)

function agentPool:init(_, gate, connMan)

	assert(gate)
	assert(connMan)
	self.gate = gate	
	self.connMan = connMan	
end

function agentPool:createAgent()

	local agent = newService("player.user")
	skynet.send(self.connMan, "lua", "addAgent", agent)
end	

return agentPool	

