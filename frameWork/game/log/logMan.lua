local skynet 		= require "skynet"
local sharedata 	= require "sharedata"
local uniqueService = require "services.uniqueService"

local logMan 		= class("logMan")

function logMan:init(player, ...)

	local _t = type(player)
	assert(_t == "string" or _t == "table", string.format("error t %s", _t))
	if _t == "string" then

		local current_cmd, platform,serverid = ...
		assert(current_cmd)
	
		local playerId = player
		player = skynet.call("player.userCenter", "lua", "getPlayerById", playerId)
		assert(player, string.format("error playerId %s.", playerId))
		player.current_cmd = current_cmd
		player.__platform = platform
		if serverid then player.__serverid = serverid end
		mylog.info("outline log playerId = %s platform = %s", player, platform)
	else

		player.onOutGame:attach(self.onPlayerOutGame, self)	
	end	
	self.player = player
end	

function logMan:onPlayerOutGame(param)

	local player = param.player
	assert(player)
	if player.entergame_time then
		self:log(LOG_OP_BIGTYPE_LOGOUT,{math.floor(os.getCurTime() - player.entergame_time)})
	end	
end	

--... 为data 和 str的数组
function logMan:log(bigtype, ...)

	local p = self.player
	local platform = p.__platform
	if not platform then platform = p.platform end
	local serverid = p.serverid 
	if not serverid then serverid = p.__serverid end

	skynet.send(uniqueService("db.dbMan"), "lua", "executeLog", bigtype,p.guid,p.userid,platform,serverid,p.name,p.current_cmd or '',...)
end

return logMan	