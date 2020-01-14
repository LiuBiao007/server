local actor = require "robot.actor"
local brain_init = require "robot.brain_init"
local brain_isover = require "robot.brain_isover"
local brain_send = require "robot.brain_send"
local handler = {}
setmetatable(handler,  actor)
handler.__index = handler

function handler:new(id, player,param)

	local t = actor:new(id, player,param)
	setmetatable(t, self)

	t:init(param)
	return t
end	

function handler:init(param)

	self.param = param.param
	local command = brain_init[self.cmd]
	if command then command(self) end
end

function handler:send()	

	self:sendbefore()
		local send = self:getSend()
		local command = brain_send[self.cmd]
		assert(command, string.format("error cmd %s", self.cmd))
		command(self, send)
	self:sendafter()
end

function handler:IsOver()

	local command = brain_isover[self.cmd]
	if command then return command(self) end

	return false
end		
return handler