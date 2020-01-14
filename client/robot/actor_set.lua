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

end

--控制如何发送协议 如何选择发送的参数
function handler:send()	

	self:sendbefore()

		local send = self:getSend()
		local command = brain_send[self.cmd]
		assert(command, string.format("error cmd [%s] in brain_send", self.cmd))
		command(self, send)

	self:sendafter()
end
--判断该操作是不是完全结束 比如人物升级升到最大等级后是完全结束 返回true/false
function handler:IsOver()

	local command = brain_isover[self.cmd]
	--assert(command, string.format("error over cmd %s", self.cmd))
	if not command then return false end--默认返回不结束
	return command(self)
end	
return handler