local skynet 		= require "skynet" 
local socket		= require "skynet.socket"
local push			= table.insert
local uniqueService = require "services.uniqueService"
local serviceObject = require "objects.serviceObject"
local protoloader	= require "base.protoloader"
local serviceTrigger = require "base.serviceTrigger"
local user 			= class("user", serviceObject)

local lockCount = 0

function user:init(maxQuene, ...)

	maxQuene = maxQuene or 32
	user.__father.init(self, maxQuene, ...)
	self:installAllCmd()
	self:registerProtocol()
	self.canLogin = true
end

function user:registerProtocol()

	skynet.register_protocol {

		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, size) 
			return self.host:dispatch(msg, size)
		end,
		dispatch = function (_, _, type, name, ...)
			if type == "REQUEST" then				
				local ret = self.safeLock(self.doRequest, name, self, name, ...)
				if ret then
					self:send_package(ret, name, ...)
				else
					mylog.info("%s", string.dump(ret))	
				end			
			end
		end
	}
end	

function user:installAllCmd()

	self.requests = {}
	self.testRequests = {}
	local handler_path_cmd = "ls ./lualib/handler"
	local list = io.popen(handler_path_cmd):read("*all")
	list:gsub("(%a+)_handler.lua", function (name)
		local handler = require("handler." .. string.trim(name) .. "_handler")
		if name:match("test") then
			self:addRequets(self.testRequests, handler)
		end	
		self:addRequets(self.requests, handler)
	end)	
end	

function user:addRequets(requests, handler)

	for requestName, func in pairs(handler) do

		assert(type(requestName) == "string")
		assert(type(func) == "function")
		assert(not requests[requestName], string.format("function %s repeated.", requestName))
		requests[requestName] = func
	end	
end	
--获取角色创建时的初始化数据
local number = 10000000
function user:getPlayerInitData(args)

	number = number + 1
	local iconKey = sex == 1 and "maleIcon" or "femaleIcon"
	local headicon = "11"--xmls.player.official_level[1][iconKey]
	local propertyMax = 10--xmls.player.official_level[1].propertyMax
	local now = os.getCurTime()
	local data = self:createDbInitData('player')
	data.guid 		= guidMan.createGuid(gameconst.serialtype.player_guid)
	data.userid 	= args.userid
	data.platform 	= args.platform
	data.serverid 	= args.serverid
	data.name 		= args.name
	data.sex 		= args.sex
	data.number 	= number
	return data
end	

function user:checkBefore(name, response)

	--状态检测
	if name == "entergame" or name == "createcharcter" then

		if self.state == PLAYER_STATE_INGAME then
			return false, response({errorcode = errorcode.user_state_error_noentry})
		end	
	else	

		if self.state ~= PLAYER_STATE_INGAME then
			return false, response({errorcode = errorcode.user_state_error_noentry})
		end	
	end	

	return true
end	

function user:checkAfter(name, r, args)

	if name == "entergame" or name == "createcharcter" then
		
		if r.errorcode == 0 then

			assert(player)
			player.entergame_time = os.getCurTime()
			serviceTrigger.send("onPlayerStateEnter", player.id, self.fd)
		end	
		if name == "entergame" then
			if self.player then
				mylog.info("playerId [%s] %s %s.", player.id, name, string.serialize(args,0,true))
			else
				mylog.info("entergame %s", string.serialize(args,0,true))
			end	
		end
	end	
	return true
end	

local traceback = debug.traceback
function user:doRequest(name, args, response)

	assert(self.gate and self.fd)
	if not self.canLogin then
		skynet.call(self.gate, "lua", "kick", self.fd)
	end	

	if self.testRequests[name] and not __cnf.debug then
		return response({errorcode = errorcode.unknown_error})
	end	

	local f = assert(self.requests[name], string.format("error client cmd: %s.", name))
	args = args or {}

	if self.exiting ~= nil then return end

	if __cnf.profile then 
		profile.start()
	end	

	if name == "outgame" then
		mylog.info("playerId [%s] %s.", self.player.id, name)
	end	

	local playerId = 0
	if self.player then 
		playerId = self.player.id  
		self.player.current_cmd = name --记录当前执行的cmd
	end
	if name ~= "entergame" then
		mylog.info("playerId [%s] %s %s.", playerId, name, string.serialize(args,0,true))
	end	

	local ok, r = self:checkBefore(name, response)
	if not ok then return r end

	local r = f(args)

	if __cnf.profile then 
		local time = profile.stop()
		local p = ti[name]
		if p == nil then
		    p = { n = 0, ti = 0 }
		    ti[name] = p
		end
		p.n = p.n + 1
		p.ti = p.ti + time
	end	

	assert(response, string.format("error response name [%s].", name))

	if not self:checkAfter(name, r, args) then return end

	return response(r)
end	

function user:send_bigheader(name, index, len)

	local p = self.send_request("bigdata_header", {name = name, index = index, len = len})
	local package = string.pack(">s2", p)
	socket.write(self.fd, package)
end

function user:send_bigcontent(index, data)
	local p = self.send_request("bigdata_content", {index = index, data = data})
	local package = string.pack(">s2", p)
	socket.write(self.fd, package)	
end

local bigdata_index = 0
function user:send_package(p, name, ...)
	
	local client_fd = self.fd									
	local maxSize = 32768
	local len = #p
	if len <= maxSize then
		local package = string.pack(">s2", p)
		socket.write(client_fd, package)		
	else	--切包

		bigdata_index = bigdata_index + 1
		if bigdata_index > 2^30 then bigdata_index = 1 end
		self:send_bigheader(name, bigdata_index, len)
		local newMax = 10240
		local i = 0
		while len > 0 do

			local _start = 1 + newMax * i
			local _end = newMax  * (i + 1)
			local ss = p:sub(_start,_end)
			len = len - newMax
			i = i + 1
			self:send_bigcontent(bigdata_index, ss)		
		end
	end
end

function user:initConn(conf)

	self.gate 				= assert(conf.gate)
	self.fd 				= assert(conf.fd)
	self.connMan 			= assert(conf.connMan)
	local host,send_request = protoloader.load(protoloader.game_c2s)
	self.host = host
	self.send_request 		= send_request
	self.state 				= PLAYER_STATE_INIT
	self.cloginproxy		= cloginproxy
	skynet.fork(function ()
		while true do

			skynet.sleep(500)
			self:sendEvent("heartbeat")	
		end
	end)
end	

function user:sendEvent(cmd, param)
	if self.state and self.state == PLAYER_STATE_INGAME then
		self:send_package(self.send_request(cmd, param))
	end	
end

function user:waitSeconds(seconds)

	if type(seconds) == "number" and seconds > 0 then
		
		local ref = 1
		while self.colock:getCount() > 1 do

			skynet.sleep(100)
			ref = ref + 1
			if ref >= seconds then
				break
			end	
		end			
	end	
end	

function user:destroy()

	if self.exiting then
		return
	end	

	self.canLogin = false
	self.exiting  = true

	if not self.fd then
		return
	end	

	local seconds = 10
	self:waitSeconds(seconds)

	local player = self.player
	if player then
	
		--save redis data
		user.__father.shut(self)
		player.current_cmd = "outGame"
		player.onOutGame:notify({player = player, agent = skynet.self()})
		user.__father.shut(self)
	end	

	--skynet.exit()
end	

function user:start(conf)

	self:initConn(conf)
	--fd may error before
	local ok, msg = pcall(skynet.call, self.gate, "lua", "forward", self.fd)
	assert(ok, msg)
	
	return true
end	

function user:kickSelf()

	self.canLogin = false
	skynet.send(self.connMan, "lua", "disconnect", self.fd)
end	

function user:closeLogin()
	self.canLogin = false
end	

function user:disconnect()

	mylog.debug("service %08X disconnect.", skynet.self())
	self.canLogin = false
	self:destroy()
end	

function user:shut()

	mylog.debug("service %08X shut.", skynet.self())
	self.canLogin = false
	self:destroy()
end	

function user:checkUserExist(userid, serverid)

	local c = uniqueService("player.userCenter")
	return skynet.call(c, "lua", "checkUserExist", userid, serverid)
end	

function user:traceMsg(...)

	--print("11          user recv ", ...)
end	

function user:do_cmd_rewrite(session, source, cmd, ...)

	local function getConnMan()

		return self.connMan or uniqueService("conn.connMan")
	end	

	local function docmd(cmd, ...)

		local isPlayerCmd
		local f = self[cmd]
		if not f and player then 
			f = player[cmd]
			isPlayerCmd = true 
		end

		assert(type(f) == "function", string.format("error cmd type:%s.", cmd))

		return self.safeLock(f, cmd, isPlayerCmd and player or self, ...)
	end	

	if self.state == PLAYER_STATE_LOADING then

		if session == 0 then

			docmd(cmd, ...)
		else
			mylog.warn("user in loading state, do not call it.[cmd:%s].", cmd)
		end	
	elseif self.state == PLAYER_STATE_INGAME then

		return docmd(cmd, ...)
	elseif source == getConnMan() then
		
		return docmd(cmd, ...)	
	else
		mylog.warn("recv cmd %s in state %s.", cmd, self.state)	
	end	
end

return user	

