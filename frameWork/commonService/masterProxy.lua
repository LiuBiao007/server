local skynet	     = require "skynet"
local cluster		 = require "skynet.cluster"
local businessObject = require "objects.businessObject"
local masterProxy    = class("masterProxy", businessObject)

local proxy
local masterAlive 	 = false
function masterProxy:init()

	masterProxy.__father.init(self, "跨服代理")

    skynet.fork(function () 
	    self:connectMaster()
	    self:eventLoop()
    end)	
end

function masterProxy:needConnectMaster()

	return redisdb:hget("serconf", "connectMaster") == "1"
end	

function masterProxy:setMasterAlive(bool)

	if bool then

		skynet.call(proxy, "lua", "syncServerId", __cnf.serverId, __cnf.mergeServerIds)
		masterAlive = true
	else
		masterAlive = false
	end	
end	

function masterProxy:reconnectMasterBroad()

	local masterData = self:mcall("serverReconnect", self.playerMan:getPlayerIds())
	if not masterData.errorcode then

		for _, data in pairs(masterData) do

			for key, item in pairs(data) do

				for _, child in pairs(item) do
					
					for cmd, p in pairs(child) do
						
						if cmd == "activityState" then
							self:activityStateChanged(p)
						elseif cmd == "activityGlobalState"	then
							self:activityGlobalStateChanged(p)
						elseif cmd == "activityOpenState" then
							self:activityOpenState(p)
						elseif type(self[cmd]) == "function" then
							self[cmd](self, p)
						end	
					end	
				end
			end	
		end			
	end	
	self:reconnectMasterBroadEx()
end
--调用中心服务器的API
function masterProxy:mcall(cmd, playerId, activityId, ...)	

	if not masterAlive then
		return {errorcode = errorcode.master_server_close}
	end	

	return skynet.call(proxy, "lua", "mcall", cmd, playerId, activityId, ...)	
end	
--调用其他服务器的API 例如查询其他服务器的玩家信息
function masterProxy:scall(cmd, playerId, ...)

	if not masterAlive then
		return {errorcode = errorcode.master_server_close}
	end	

	return skynet.call(proxy, "lua", "scall", cmd, playerId, ...)	
end	

function masterProxy:connectMaster()

    if self:needConnectMaster() then

        local ok, master = pcall(cluster.query, "masterserver", "masterService")
        if ok then
            proxy = cluster.proxy("masterserver", master)
            mylog.info("跨服连接成功.")
            self:setMasterAlive(true)
        else
            mylog.info("跨服连接失败.")
            self:setMasterAlive(false)
        end    

        skynet.fork(function () 
	        local needReConnect = false
	        while self:needConnectMaster() do

	            local ok, master = pcall(cluster.query, "masterserver", "masterService")
	            if not ok then
	                mylog.info("与跨服连接断开...")
	                needReConnect = true
	                self:setMasterAlive(false)
	            else            
	                if needReConnect then
	                    local cok
	                    cok, proxy = pcall(cluster.proxy,"masterserver", master)
	                    if cok then     
	                        needReConnect = false       
	                        self:setMasterAlive(true)
	                        self:reconnectMasterBroad()
	                        mylog.info("与跨服连接成功.")   
	                    end
	                end 
	                pcall(skynet.call, proxy, "lua", "heartbeat")
	            end 
	            skynet.sleep(300)
	        end 
    	end)
    end   
end	

function masterProxy:eventDispatch(data)

	if not data then return end
	local cmd = data.cmd
	assert(type(self[cmd]) == "function", string.format("error cmd %s.", cmd))
	self[cmd](self, data.data)
end	

function masterProxy:activityGlobalStateChanged(data)

	self.playerMan:broadcast("sendEvent", "activityGlobalStateChanged", 
		{activityGlobalState = data})
end	

function masterProxy:__delaycall(data)

	local cmd = data.subcmd
	local r = self[cmd](self, data)
	r.index = data.index
	self:scall("responseScall", data.playerId, r)
end	

function masterProxy:activityStateChanged(data)

	self.playerMan:sendEvent(data.playerId, "sendEvent", "activityStateChanged", 
		{activityState = data})
end	

function masterProxy:activityStateRemoveChanged(data)

	self.playerMan:sendEvent(data.playerId, "sendEvent", "activityStateRemoveChanged", 
		data)
end	

function masterProxy:activityOpenState(data)

	self.playerMan:broadcast("sendEvent", "activityOpenState", 
		data)	
end	

function masterProxy:ignore()
	mylog.info("masterProxy ingore...")
end	

function masterProxy:shutDownMaster()

	mylog.info("shutDownMaster...")
	self:setMasterAlive(false)
end	

function masterProxy:sendBonusesMail(data, playerId)

	self:send("mail.mailCenter", "sendSystemMailEx", data.type, "system", 
        playerId or data.playerId, data.title, data.content, data.bonuses)
end	

function masterProxy:eventLoop()

	local function eventCall()

		local ok, _ = pcall(cluster.query, "masterserver", "masterService")
		if ok then
			local ret
			ok, ret = pcall(skynet.call, proxy, "lua", "eventLoop", __cnf.serverId)
			if not ok then
				mylog.info("eventLoop to master fail.")
			else
				local msg
				ok, msg = xpcall(self.eventDispatch, debug.traceback, self, ret)
				if not ok then mylog.info(msg) end
			end	
		else
			skynet.sleep(500)
		end	
	end

	while self:needConnectMaster() do

		if masterAlive then
			eventCall()--event loop
		else
			skynet.sleep(300)--if master shut down, try connect master inter 3s
		end	
	end	
end	

return masterProxy	