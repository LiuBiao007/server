local mylog  = mylog
local object = require "objects.object"
local proxyPlayer = class("proxyPlayer", object)

function proxyPlayer:init(serviceName, playerId, agent)

	proxyPlayer.__father.init(self)
	self.serviceName 	= serviceName
	self.id 			= playerId
	self.playerId 		= playerId
	self.agent 			= agent
	self.fullDataInRedis = false
	self.inGame 		= false --
	self.time 			= nil--退出时间
	self.remove         = nil
	self.state 			= PLAYER_STATE_LOADING
	return self
end

function proxyPlayer:setInGame(bool)

	self.inGame = bool
	if bool == true then
		self.remove = nil
	end	
end	

function proxyPlayer:isInGame()
	return self.inGame
end	

function proxyPlayer:inRemove()
	return self.remove
end	

function proxyPlayer:setRemove(bool)

	self.remove = bool
end	

function proxyPlayer:setFullDataInRedis(state)

	self.fullDataInRedis = state
end	

function proxyPlayer:getRedisState()

	return self.fullDataInRedis
end	

function proxyPlayer:onEnterGame(...)

	mylog.info(" playerId %s 进入 %s.", self.playerId, self.serviceName)
end	

function proxyPlayer:onOutGame(...)

	mylog.info(" playerId %s 离开 %s.", self.playerId, self.serviceName)
end	

function proxyPlayer:onLoadGame(serviceName)

	if serviceName then self.serviceName = serviceName end
	mylog.debug(" playerId %s 装载 %s.", self.playerId, self.serviceName)
end	

return proxyPlayer
