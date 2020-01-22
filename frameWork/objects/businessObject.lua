local skynet			= require "skynet"
local serviceObject 	= require "objects.serviceObject"
local proxyPlayerMan 	= require "player.proxyPlayerMan"
local proxyPlayer 		= require "player.proxyPlayer"
local uniqueService 	= require "services.uniqueService"
local serviceTrigger 	= require "base.serviceTrigger"
local object 			= class("businessObject", serviceObject)

function object:init(serviceName, ...)

	self.serviceName = serviceName
	object.__father.init(self, ...)
	self.playerMan = proxyPlayerMan:new(self.serviceName)
	playerMan = self.playerMan
	return self
end	

function object:closeTrigger()

	self.forbidTrigger = true
end	

function object:initTriggers()

	if self.forbidTrigger then return end
	serviceTrigger.add("onPlayerStateLoading")
	serviceTrigger.add("onPlayerFullDataInRedis")
	serviceTrigger.add("onPlayerStateEnter")	
	serviceTrigger.add("onPlayerStateOut")
	serviceTrigger.add("onPlayerFullDataNotInRedis")
	if type(self.initTriggersEx) == "function" then
		self:initTriggersEx()
	end	

	if not __cnf.isMaster then
		local m = uniqueService("commonService.monitor")
		skynet.send(m, "lua", "businessStart", skynet.self(), self.serviceName)
	end	
end	

function object:onPlayerStateLoading(playerId, agent, ...)

	local player = self.playerMan:createPlayer(playerId, agent, ...)
	player:onLoadGame(self.serviceName)
	if type(SERVICE_OBJECT.onEnterGame) == "function" then
		SERVICE_OBJECT:onEnterGame(player)
	end	
	return true
end

function object:onPlayerFullDataInRedis(playerId)

	local player = self.playerMan:getPlayerById(playerId)
	if player then
		player:setFullDataInRedis(true)
	end	
	return true
end	

function object:onPlayerFullDataNotInRedis(playerId)
	local player = self.playerMan:getPlayerById(playerId)
	if player then
		player:setFullDataInRedis(false)
	end
	return true
end	

function object:onPlayerStateEnter(playerId, ...)

	local player = assert(self.playerMan:getPlayerById(playerId), string.format("error playerId %s.", playerId))
	player.state = PLAYER_STATE_INGAME
	player:onEnterGame()
	return true
end	

function object:onPlayerStateOut(playerId, ...)

	local player = self.playerMan:getPlayerById(playerId)
	if not player then return false end
	self.playerMan:decPlayer(playerId)
	player:onOutGame()
	if type(SERVICE_OBJECT.onOutGame) == "function" then
		SERVICE_OBJECT:onOutGame(playerId)
	end	
	return true
end	

function object:getPlayerInfoById(playerId)

	local s = uniqueService("player.userCenter")
	return skynet.call(s, "lua", "getPlayerById", playerId)
end	

function object:checkPlayerExist(playerId)
	local s = uniqueService("player.userCenter")
	return skynet.call(s, "lua", "checkPlayerExist", playerId)
end

function object:sendBonusesMail(playerId, title, content, bonuses, type)
	
	local s = uniqueService("mail.mailCenter")	
	skynet.send(s, "lua", "sendSystemMailEx", type, "system", 
        playerId, title, content, bonuses)	
end

function object:getPlayerIdByName(name)

	return self:call("user.userCenter", "getPlayerIdByName", name)
end	

function object:getPlayerIdsByName(name)

	return self:call("user.userCenter", "getPlayerIdsByName", name) 
end	

function object:getPlayerByName(name)

	return self:call("user.userCenter", "getPlayerByName", name) 
end	

function object:getPlayerIdByUserAndServerId(userid, serverid)

	return self:call("user.userCenter", "getPlayerIdByUserAndServerId", userid, serverid) 
end	
return object