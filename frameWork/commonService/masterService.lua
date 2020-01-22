local skynet		 = require "skynet"
local redis 		 = require "skynet.db.redis"
local uniqueService  = require "services.uniqueService"
local businessObject = require "objects.businessObject"
local serviceTrigger = require "base.serviceTrigger"
local masterService  = class("masterService", businessObject)

local isClose 			= false
local closeResponse 	= {cmd = "shutDownMaster"}
local serverId2event 	= {}
local serverco2data 	= {}
local serverQueueEvent 	= {}
local globalServerIds 	= {}
local allServerIds 		= {}

function masterService:init()

    masterService.__father.init(self, "跨服服务")

    self:closeLock()
    self:closeSyncToRedis()
    
    self.delayresponse = {}
    self.response2time = {}
    self.dindex 	   = 0    
    self.activities    = {}
    --self:runActivity()
    skynet.fork(self.runActivity, self)

    self:listenShut()
end	

function masterService:listenShut()

	local function watch(self)

		local w = redis.watch(__cnf.redis)
		w:subscribe("onmonitorclose")
		while true do

			local s = w:message()
			if s and s == "1" then
				self:shut()
				break	
			end		
			skynet.sleep(100)
		end	
	end		
	skynet.fork(watch, self)	
end	

function masterService:runActivity()

    for id, item in pairs(ACTIVITY_CONFIG) do

        if item.type == ACTIVITYTYPE_MASTER then

            local service = uniqueService(string.format("activity.%s", item.name), id)
        	self.activities[id] = service
        end 
    end 	
end	

function masterService:mcall(cmd, playerId, activityId, ...)

	if activityId then

		if type(activityId) == "number" then
			local service = self.activities[activityId]
			if not service then
				mylog.warn("error mcall activityId %s.", activityId)
				return {errorcode = errorcode.master_server_cmd_error}
			end	
			return skynet.call(service, "lua", cmd, playerId, ...)
		elseif type(activityId) == "string" then
			
			local service = uniqueService(activityId)
			return skynet.call(service, "lua", cmd, playerId, ...)
		else
			error(string.format("error activityId %s.", activityId))
		end	
	else
		
		local f = assert(self[cmd], string.format("error cmd %s.", cmd))
		return self[cmd](self, playerId, ...)
	end	
end

function masterService:scall(cmd, playerId, ...)

	local serverId = self:getServerId(playerId)

	self.dindex = self.dindex + 1
	self.delayresponse[self.dindex] = skynet.response()
	self.response2time[self.dindex] = os.getCurTime()

	local param = {cmd = "__delaycall", 
			data = {subcmd = cmd, playerId = playerId, index = self.dindex}}
	self:recvEvent(param, serverId)
end

function masterService:sendEventToServer(playerId, cmd, param)
	
	local serverId = self:getServerId(playerId)
	self:recvEvent({cmd = cmd, data = param}, serverId)
end

function masterService:recvEvent(data, serverId)

	local function insertQueueEvent(serverId, data)

		if not serverQueueEvent[serverId] then
			serverQueueEvent[serverId] = {}
		end	
		table.insert(serverQueueEvent[serverId], data)
	end	
	
	local function insertEvent(serverId)

		local co = serverId2event[serverId]
		if co then
			serverco2data[co] = data
			serverId2event[serverId] = nil
			skynet.wakeup(co)		
		else
			insertQueueEvent(serverId, data)
		end
	end	

	if serverId then
		insertEvent(serverId)
	else
		for serverId, _ in pairs(globalServerIds) do

			insertEvent(serverId)
		end		
	end	
end

function masterService:getServerId(playerId)

	if not playerId then return nil end
	local serverId = guidMan.reverserServerId(playerId)
	return allServerIds[serverId]
end	

--回应__delaycall responseScall的消息
function masterService:responseScall(param)

	local index = param.index
	local response = self.delayresponse[index]
	if response then
		response(true, param)
	end	

	self.delayresponse[index] = nil
	self.response2time[index] = nil
	return true
end	

function masterService:heartbeat()
	return true
end	
--重连后的数据补发 比如活动状态等等
function masterService:serverReconnect(playerIds)

	local results = {}
	for playerId, _ in pairs(playerIds or {}) do

		local r = serviceTrigger.callResult("onLoadGameData", playerId)
		results[playerId] = r
	end	

	return results
end	

local function dropWaitCoroutine(serverId)

	local co = serverId2event[serverId]
	if co then
		serverId2event[serverId] = nil
		serverco2data[co] = "drop_co"
		skynet.wakeup(co)
	end	
end	

local function wake_all()
	
	for serverId, co in pairs(serverId2event) do
		serverId2event[serverId] = nil
		serverco2data[co] = {cmd = "ignore"}
		skynet.wakeup(co)
	end		
end	

function masterService:eventLoop(serverId)

   	mylog.info("master server recv serverId %s", serverId)
    if isClose then return closeResponse end
    globalServerIds[serverId] = true
    if serverQueueEvent[serverId] and #serverQueueEvent[serverId] > 0 then
    	return table.remove(serverQueueEvent[serverId], 1)
    end	
    if not serverId2event[serverId] then
    	
		local co = coroutine.running()
	    serverId2event[serverId] = co
	    skynet.wait(co)
	    local data = serverco2data[co]
	    serverco2data[co] = nil
	    if data ~= "drop_co" then
	   		return data   
	   	end	
    else
       	mylog.info("master ingore serverId = %s.......", serverId)
       	dropWaitCoroutine(serverId)
       	self:eventLoop(serverId)
    end
end

function masterService:syncServerId(serverId, mergeServerIds)

	if type(mergeServerIds) == "table" then
		local min, max = mergeServerIds[1], mergeServerIds[2]
		if min and max then
			if type(min) == "table" and type(max) == "table" then
				local m, n = min[1], min[2]
				for i = m, n do allServerIds[i] = serverId end
				m, n = max[1], max[2]
				for i = m, n do allServerIds[i] = serverId end
			else
				for i = min, max do
					allServerIds[i] = serverId
				end				
			end	

		end	
	end	
	allServerIds[serverId] = serverId
	return true
end	

function masterService:closeConnWithMaster(serverId)

	mylog.info("closeConnWithMaster serverId [%s]", serverId)
	dropWaitCoroutine(serverId)
	return true
end	

function masterService:shut()

	mylog.info("跨服开始关闭.")
	isClose = true

	for serverId, co in pairs(serverId2event) do
		serverco2data[co] = closeResponse
		skynet.wakeup(co)
	end
	serverId2event = {}	

	for activityId, service in pairs(self.activities) do

		local name = ACTIVITY_CONFIG[activityId].name
		mylog.info(" %s 跨服活动准备关闭.", name)
		skynet.call(service, "lua", "shut")
		mylog.info(" %s 跨服活动关闭完成.", name)
	end	
	
	SERVICE_OBJECT:call("db.dbMan", "shut")
	mylog.info("跨服完成关闭.")
	redisdb:publish("masterCLose", 1)
	redisdb:set("masterCLose", 1)
	skynet.timeout(150, function ()

		mylog.info("	程序自己退出.")
		redisdb:set("masterCLose", 1)
		os.exit()
	end)

	return nil
end	

function masterService:do_cmd_rewrite(session, source, cmd, ...)

	if type(self[cmd]) ~= "function" then
		mylog.warn("cmd %s is not function.", cmd)
		wake_all()
		return {errorcode = errorcode.master_server_cmd_error}
	end	
	if cmd == "scall" or session == 0 then
		self[cmd](self, ...)
	else
		return self[cmd](self, ...)
	end	
end

return masterService
