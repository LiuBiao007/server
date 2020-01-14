local skynet 	= require "skynet"
local object 	= require "objects.object"
local outline 	= require "ext.outline"
local player 	= require "player.proxyPlayer"

local playerMan = class("proxyPlayerMan", object)

function playerMan:init(serviceName)

	self.serviceName = serviceName
	self.players 	 = {}
	self.playerIds   = {}
	return self	
end	

function playerMan:addPlayer(player)

	assert(not self.players[player.id], string.format("error addPlayer playerId:%s.", player.id))
	self.players[player.id] = player
	self.playerIds[player.id] = true
end	

function playerMan:decPlayer(playerId)

	assert(self.players[playerId], string.format("error decPlayer playerId:%s.", playerId))
	self.players[playerId] = nil
	self.playerIds[playerId] = nil
end

function playerMan:getPlayerById(playerId)

	return self.players[playerId]
end	
--发送消息给agent, 如果outfunc为function则执行不在线逻辑
function playerMan:sendEvent(playerId, cmd, ...)

	if SERVICE_OBJECT and type(SERVICE_OBJECT.proxyService) == "number" then

		local agent = skynet.call(SERVICE_OBJECT.proxyService, "lua", "isPlayerLoadOrInGame", playerId)
		if agent then
			skynet.send(agent, "lua", cmd, ...)
		else
			return outline:new(playerId, self)
		end	
	else

		local player = self:getPlayerById(playerId)
		if player and (player.state == PLAYER_STATE_LOADING or player.state == PLAYER_STATE_INGAME) then

			skynet.send(player.agent, "lua", cmd, ...)
		else

			return outline:new(playerId, self)
		end	
	end 
end

--广播
function playerMan:broadcast(cmd, ...)

	if SERVICE_OBJECT and type(SERVICE_OBJECT.proxyService) == "number" then

		skynet.send(SERVICE_OBJECT.proxyService, "lua", "proxyBroadcast", cmd, ...)
	else
		for playerId, player in pairs(self.players) do

			if player.agent then

				self:sendEvent(playerId, cmd, ...)
			end	
		end	
	end	
end	

function playerMan:createPlayer(...)

	local player = player:new(self.serviceName, ...)
	self:addPlayer(player)
	return player
end

function playerMan:isFullData(playerId)

	if SERVICE_OBJECT and type(SERVICE_OBJECT.proxyService) == "number" then

		return skynet.call(SERVICE_OBJECT.proxyService, "lua", "isProxyFullData", playerId)
	else	
		local player = self:getPlayerById(playerId)
		if player and player:getRedisState() then
			return true
		end	
		return false
	end	
end	

function playerMan:getPlayerIds()
	return self.playerIds
end	
return playerMan