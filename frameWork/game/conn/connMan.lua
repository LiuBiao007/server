local skynet 		= require "skynet"
local socket		= require "skynet.socket"
--local cluster 		= require "skynet.cluster"
local mylog 		= require "base.mylog"
local protoloader   = require "base.protoloader"
local serviceObject = require "objects.serviceObject"
local serviceTrigger = require "base.serviceTrigger"
local newService 	= require "services.newService"
local conn 			= require "conn.conn"

local string_format	= string.format
local push			= table.insert
local connMan = class("connMan", serviceObject)

local centerCount   = 1
local playerCount 	= 0
local connCount		= 0
local canLogin 		= true
local agentPool     = {}
local agentPoolCenter = {}
local agent_count
local host, send_request

function connMan:init(maxQuene, param)

	local maxQuene = maxQuene or 512
	connMan.__father.init(self, maxQuene)
	self:initProtocol()
	--self:connectLoginServer()
	self.connsByFd = {}
	self.waitco	   = {}
	self.conns     = {}
	self.createAgentCount = 0
	self.maxclient = param.maxclient
	if not __cnf.debug then  
		centerCount = 16
	end

	assert(type(self.maxclient) == "number" and self.maxclient > 5000)
	self.gate = skynet.newservice("gate")
	skynet.call(self.gate, "lua", "open", param)
	
	--关闭消息锁
	self:closeLock()
	--关闭redis写入
	self:closeSyncToRedis()
	return self
end	

function connMan:initTriggers()

	serviceTrigger.add("onPlayerStateEnter")	
end	

function connMan:initProtocol(...)

	agent_count = __cnf.agent_count
	assert(agent_count > 0)
	for i = 1, agent_count do
		push(agentPool, newService("player.user"))
	end	
	self.createAgentCount = agent_count
	host,send_request = protoloader.load(protoloader.game_c2s)
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
	}	

	skynet.fork(function ()

		while canLogin do

			skynet.sleep(10)
			self:checkCreateAgent()
		end	
	end)
end	

function connMan:shut()

	canLogin = false
	connMan.__father.shut(self)
	self:closeConn()
	return true
end	

function connMan:getAllAgent()

	local r = {}
	for fd, conn in pairs(self.connsByFd) do
		if conn.agent then
			push(r, conn.agent)
		end	
	end	
	for _, agent in pairs(agentPool) do
		push(r, agent)
	end	
	return r
end	

function connMan:closeConn()

	mylog.info("当前在线玩家:%s 登陆玩家:%s.", playerCount, connCount)
	for fd, conn in pairs(self.connsByFd) do
		self:stopRecvMsg(conn)
	end	
	for fd, conn in pairs(self.connsByFd) do
		self:kickConnection(conn)
	end	
end	

function connMan:connectLoginServer()

	local clogin = cluster.query("loginmaster", "clogin")
	assert(clogin)
	cloginproxy = cluster.proxy("loginmaster", clogin)
	-- 发送服务器配置给登录服
	local hok, err = pcall(skynet.call, cloginproxy, "lua", "syncServerInfo", cnf.serverId, cnf.serverName, cnf.openTime)
	if not hok then
		mylog.warn(" 与登陆服务器同步服务器信息错误")
	end

	skynet.fork(function () 
		local needReConnect = false
		while true do

			if not canLogin then break end
			local ok, clogin = pcall(cluster.query, "loginmaster", "clogin")
			if not ok then
				mylog.warn(" 与登陆服务器断开连接!!!")
				needReConnect = true
			else			
				if needReConnect then
					local cok
					cok, cloginproxy = pcall(cluster.proxy,"loginmaster", clogin)
					if cok then		
						needReConnect = false		
						mylog.info(" 与登陆服务器重新连接成功.")	
					end
				end	
				pcall(skynet.call, cloginproxy, "lua", "heartbeat")
			end	
			skynet.sleep(1000)
		end	
	end)
end	

function connMan:onServiceStarted()

	for i = 1, centerCount do
		local p = newService("conn.agentPool", self.gate, skynet.self())
		push(agentPoolCenter, p)
	end		
end	

function connMan:addAgent(agent)

	assert(agent)
	push(agentPool, agent)
	if self.createco then

		assert(type(self.waitdiff) == "number")
		self.waitdiff = self.waitdiff - 1
		if self.waitdiff <= 0 then
			self.waitdiff = nil
			skynet.wakeup(self.createco)
			self.createco = nil
		end	
	end	
	mylog.info("addAgent success, now agent count:[%s].", #agentPool)
end	
	
function connMan:createAgent(count)

	for i = 1, count do

		skynet.send(agentPoolCenter[i], "lua", "createAgent")
	end 
	self.createAgentCount = self.createAgentCount + count
end

function connMan:checkCreateAgent()

	local diff = agent_count - #agentPool
	if diff > 0 and self.createAgentCount < self.maxclient then
		
		self:createAgent(diff)
		if not self.createco then

			self.createco = coroutine.running()
			self.waitdiff = diff
			skynet.wait(self.createco)
		end	
	end	
end	

function connMan:kick(fd)

	skynet.call(self.gate, "lua", "kick", fd)
end	

function connMan:socket(cmd, ...)

	return self[cmd](self, ...)
end	

function connMan:open(fd, addr)

	if not canLogin then return self:kick(fd) end

	skynet.call(self.gate, "lua", "accept", fd)
	mylog.info("new client from %s, fd %s accept success.", addr, fd)
end

function connMan:close(fd)	

	self:processError(fd)
	mylog.info("fd %s close.", fd)
end	

function connMan:checkToken(userid, serverid, token, fd)

	if type(token) ~= "string" then
		self:kick(fd)
		mylog.info("%d 剔除非法fd(3).", fd)
		return false
	else

		local ok, bool = pcall(skynet.call, cloginproxy, "lua", "verifySession", userid, token)
		if not ok then
			self:kick(fd)
			mylog.info("%d 剔除非法fd(4) 登陆服务器故障.", fd)		
			return 	false
		else
			if not bool then
				self:kick(fd)
				mylog.info("%d 剔除非法fd(5).", fd)		
				return 	false
			end	
		end	
	end	
	return true
end	

local function genConn(userid, serverid)

	return string_format("%s:%s", userid, serverid)
end	

function connMan:unregisterConn(conn)

	local key = genConn(conn.userid, conn.serverid)
	assert(self.conns[key], string.format("unregisterConn error, key:%s.", key))	
	assert(self.connsByFd[conn.fd], string.format("unregisterConn fd error, fd:%s.", conn.fd))	

	self.conns[key] = nil
	self.connsByFd[conn.fd] = nil
	conn:clear()
end	

function connMan:registerConn(conn)

	local key = genConn(conn.userid, conn.serverid)
	assert(not self.conns[key], string.format("registerConn error, key:%s.", key))	
	assert(not self.connsByFd[conn.fd], string.format("registerConn fd error, fd:%s.", conn.fd))
	self.conns[key] = conn
	self.connsByFd[conn.fd] = conn
	connCount = connCount + 1
end	

function connMan:getConnByFd(fd)

	return self.connsByFd[fd]
end

function connMan:getConn(userid, serverid)

	local key = genConn(userid, serverid)
	return self.conns[key]
end	

function connMan:writeResponse(fd, p)

	local package = string.pack(">s2", p)
	socket.write(fd, package)	
end	

function connMan:waiting(conn)

	assert(not self.waitco[conn.fd], string.format("error fd %s exist.", conn.fd))
	local co = coroutine.running()
	self.waitco[conn.fd] = {co = co, conn = conn}
	skynet.wait(co)
end

function connMan:tryFinishWaitco(conn)

	local c = self.waitco[conn.fd]
	if c then

		self.waitco[conn.fd] = nil
		skynet.wakeup(c.co)
		mylog.info("fd %s co has be finish.", conn.fd)
	end	
end	

function connMan:stopRecvMsg(conn)

	if conn.agent then
		skynet.send(conn.agent, "lua", "closeLogin")
	end	
end	

function connMan:kickConnection(conn)

	self:unregisterConn(conn)

	connCount   = connCount   - 1

	if conn:isInGame() then
		playerCount = playerCount - 1
	end
	if connCount   < 0 	then connCount 	 = 0 end
	if playerCount < 0 	then playerCount = 0 end
	mylog.info(" %s outGame.", conn:getKey())
	mylog.info(" onlineCount [%s].", playerCount)

	self:kick(conn.fd)
	skynet.send(conn.agent, "lua", "disconnect")
	self:tryFinishWaitco(conn)
	conn = nil
end	

function connMan:processError(fd)

	local conn = self:getConnByFd(fd)
	if conn then
		self:kickConnection(conn)
	end	
end	

function connMan:waitEnterGame(conn)

	conn:waitEnterGame()
	self:waiting(conn)
end	

function connMan:onPlayerStateEnter(playerId, fd)

	local conn = self:getConnByFd(fd)
	self:tryFinishWaitco(conn)
	conn:setInGame(playerId)
	playerCount = playerCount + 1
	mylog.info(" onlineCount [%s].", playerCount)
end	

function connMan:takeAgent()

	local agent = table.remove(agentPool)
	if not agent then
		agent = newService("player.user")
		self.createAgentCount = self.createAgentCount + 1
	end

	local agentcount = #agentPool
	mylog.notice("take agent now, left count is %d" , agentcount)

	return agent
end	

function connMan:createConn(userid, serverid, fd, msg, sz)

	local agent = self:takeAgent()
	--注册connection
	local conn = conn:new(userid, serverid, fd, agent)
	self:registerConn(conn)

	local ok,ret = pcall(skynet.call, agent, "lua", "start", {
						gate 	= self.gate,
						fd 		= fd,
						cloginproxy = cloginproxy,
						connMan = skynet.self()})--agent可能因为网络错误 提前退出

	--double check, prevent fd from unexpectedly exiting early
	if not self:getConnByFd(fd) then

		mylog.info("%s unexpectedly exit.", fd)
		return false
	end	

	if ok then

		if not ret then

			self:unregisterConn(conn)
			mylog.info("fd %d agent %08X 提前退出.",fd, agent)
			return false
		else	

			mylog.info("%d 认证成功.", fd)	
			skynet.redirect(agent, 0, "client", 0, msg, sz)
			self:waitEnterGame(conn)
			return true
		end
	else

		self:unregisterConn(conn)
		mylog.info("fd %d agent %08X 可能退出.",fd, agent)
		return false
	end	
end	

function connMan:auth(fd, name, args, response, msg, sz)

	if name ~= "entergame" and name ~= "createcharcter" then
		self:kick(fd)
		mylog.info("%d 剔除非法fd(2) name = %s.", fd, name)
		return 
	end	

	if not canLogin then
		self:kick(fd)
		mylog.info("%d 剔除非法fd(6).", fd)	
		return			
	end

	local userid, serverid, token = args.userid, args.serverid, args.token
	if not userid or not serverid or not token then
		self:kick(fd)
		mylog.info("%d 剔除非法fd(7).", fd)	
		return			
	end

	--	
	--if not self:checkToken(userid, serverid, token, fd) then return end
	local conn = self:getConn(userid, serverid)
	if conn then

		if conn.fd == fd then

			self:writeResponse(fd, {errorcode = errorcode.user_login_ing})
			mylog.info("userid %s serverid %s fd %s send protocol repeat.", 
				userid, serverid, fd)
			return
		else

			local function readyEnter()
				--顶号
				self:kickConnection(conn)
				self:createConn(userid, serverid, fd, msg, sz)
			end	

			conn:lock(genConn(userid, serverid))
			xpcall(readyEnter, debug.traceback)
			conn:unlock()
			
			return
		end	
	end	

	self:createConn(userid, serverid, fd, msg, sz)
end	

function connMan:data(fd, msg)

	mylog.info("%d 开始认证.", fd)
	local size = #msg
	local ok, type, name, args, response = pcall(host.dispatch, host, msg, size)
	if not ok then
		self:kick(fd)
		mylog.info("%d 剔除非法fd(1).", fd)
	else	
		self:auth(fd, name, args, response, msg, sz)
	end
end

function connMan:error(fd, msg)

	self:processError(fd)
	mylog.info("fd %s error.", fd)
end	

function connMan:disconnect(fd)

	self:processError(fd)
	mylog.info("fd %s disconnect.", fd)
end	
	
return connMan
