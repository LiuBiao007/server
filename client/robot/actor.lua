local sends = require "sends"
local handler = {}

function handler:new(id, player,param)

	local t = {}
	setmetatable(t, self)
	self.__index = self
	t:initbase(id, player,param)
	return t
end

function handler:initbase(id, player,param)
	assert(id)
	assert(player)
	assert(param.cmd)
	assert(param.rand)
	assert(param.rxmls)
	assert(param.robot)
	self.id = id
	self.player = player
	self.cmd = param.cmd
	self.arr = param.arr
	self.errorcode = param.errorcode
	self.rand = param.rand
	self.rxmls = param.rxmls	
	self.robot = param.robot
	--self.rand = tool.random
end

function handler:getSend()
	return assert(sends[self.cmd])
end

function handler:sendbefore()
	self.robot.actor = self
	--print(string.format("Robot send cmd [%s] itemId = [%d].", self.cmd, self.id))
	--self:sendafter()
end

function handler:sendafter()
	
	local session = self.robot.session
	assert(session ~= 0)
	self.robot.sessions[session] = self
end

function handler:send()	

	self:sendbefore()
		local send = self:getSend()
		send(self.arr)
	self:sendafter()
	--check errorcode 
	if self.type ~= 1 then
		if self.errorcode then
			local needRandom = true
			for err, aid in pairs(self.errorcode) do
				if aid == -1 or aid > 0 then
					needRandom = false
					break
				end	
			end	
			if needRandom then self.robot:startrandom() end
		else
			self.robot:startrandom()
		end	
	end	
end

function handler:IsOver()
	return false
end	
return handler