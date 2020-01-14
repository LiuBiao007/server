local colock = require "base.colock"
local mylog	 = require "base.mylog"
local conn = class("conn")

function conn:init(userid, serverid, fd, agent)

	self.colock = colock:new()
	self.userid = userid
	self.serverid = serverid
	self.agent = agent
	self.state = PLAYER_STATE_INIT
	self.fd = fd
	self.key = string.format("user:%s serverid:%s fd:%s agent:%s",
		userid, serverid, fd, agent)
end	

function conn:getKey()

	return self.key
end	

function conn:lock(name)

	self.colock:lock(name)
end	

function conn:setInGame(playerId)

	self.state = PLAYER_STATE_INGAME
	self.playerId = playerId
	mylog.debug("%s enterGame [playerId:%s].", self.key, playerId)
end	

function conn:waitEnterGame()
	mylog.debug("%s waitEnterGame.", self.key)
end	

function conn:isInGame()

	return self.state == PLAYER_STATE_INGAME
end	

function conn:unlock()

	self.colock:unlock()
end	

function conn:clear()

	self.colock:clear()
	self.userid = nil
	self.serverid = nil
	self.fd = nil
	mylog.debug("%s clear.", self.key)
end	

return conn
