local skynet 		 = require "skynet"
local uniqueService  = require "services.uniqueService"
local Player 		 = require "player.player"
local serviceTrigger = require "base.serviceTrigger"
local requests 		 = {}

--user global
function requests.createcharcter(args)

	--------------------------check create----------------------------
	local name 		= args.name
	local sex 		= args.sex
	local userid 	= args.userid
	local serverid 	= args.serverid
	local platform 	= args.platform
	local serverName = args.serverName
	local version 	= args.version
	local icon 		= args.icon

	if type(name) ~= "string"     or type(sex) ~= "number"     or type(serverid) ~= "number"   or 
	   type(platform) ~= "number" or type(userid) ~= "string"  or type(serverName) ~= "string" or 
	   type(icon) ~= "string"     or type(version) ~= "string" or version ~= commonconst.version then
		return {errorcode = errorcode.param_error}
	end	

	if userid:invalid(128) or name:invalid(26) or icon:invalid(20) or serverName:invalid() then
		return {errorcode = errorcode.param_error}
	end		

	if skynet.call(uniqueService("player.userCenter"), "lua", "checkUserExist", userid, serverid) then
		return {errorcode = errorcode.char_is_exist}
	end	

	if skynet.call(uniqueService("player.userCenter"), "lua", "checkNameExist", name) then
		return {errorcode = errorcode.name_has_exist}
	end	

	--------------------------check create----------------------------

	--------------------------init player data------------------------
	local data = SERVICE_OBJECT:getPlayerInitData(args)
	assert(type(data) == "table", "createcharcter init data is empty.")
	---------------------------init player data-----------------------

	player = Player:create(data)

	SERVICE_OBJECT.state = PLAYER_STATE_LOADING
	local playerId = player.guid
	serviceTrigger.call("onPlayerStateLoading", playerId, skynet.self())
	
	local isCreate = true
	local _, uniqueData = player:call("db.dbMan", "loadGameData", playerId, isCreate)

	player.onPlayerCreate:notify(player, serverName, uniqueData)

	player:call("player.userCenter", "registUser", player:getRegistUser())
	serviceTrigger.call("onPlayerFullDataInRedis", playerId, true)

	local result = {errorcode = 0, time = os.getCurTime(), info = player:getSendStruct()}
	player.onSendPlayerData:notify(player, result.info)

	return result
end

function requests.entergame(args)

	---------------------------------entergame check----------------------------------
	local userid 	 = args.userid
	local serverid 	 = args.serverid
	local version 	 = args.version
	local serverName = args.serverName

	if type(version) ~= "string" or version ~= commonconst.version or type(userid) ~= "string" or
	   type(serverid) ~= "number" or type(serverName) ~= "string" or type(serverid) ~= "number" then
	   return {errorcode = errorcode.param_error}
	end   

	local playerId, forbidTime = skynet.call(uniqueService("player.userCenter"), "lua", "checkUserExist", userid, serverid)
	if not playerId then
		return {errorcode = errorcode.user_login_nochar}
	end		

	local now = os.getCurTime()
	if  forbidTime > 0 and os.getClock(forbidTime) - now > 0 then
		return {errorcode = errorcode.user_player_forbit}
	end	
	---------------------------------entergame check----------------------------------

	--call business
	SERVICE_OBJECT.state = PLAYER_STATE_LOADING
	serviceTrigger.call("onPlayerStateLoading", playerId, skynet.self())

	local data, uniqueData = skynet.call(uniqueService("db.dbMan"), "lua", "loadGameData", playerId)
	player = Player:create(data.player)
	player:dispathData(data, serverName, uniqueData)

	serviceTrigger.call("onPlayerFullDataInRedis", playerId, true)

	player.state = PLAYER_STATE_INGAME
	SERVICE_OBJECT.state = PLAYER_STATE_INGAME
	
	local result = {errorcode = 0, time = os.getCurTime(), info = player:getSendStruct()}
	player.onSendPlayerData:notify(player, result.info)

	return result
end
--player global
function requests.outgame(args)

	skynet.timeout(100, function ()

		SERVICE_OBJECT:kickSelf()
	end)
	return {errorcode = 0}
end	

return requests	
