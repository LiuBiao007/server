local skynet		= require "skynet"
local redis 		= require "skynet.db.redis"
local uniqueService = require "services.uniqueService"
local mylog			= mylog
local serviceObject = require "objects.serviceObject"
local monitor = class("commonService.monitor", serviceObject)

local closing = false
local monitorXml
function monitor:init()

	monitor.__father.init(self, 4)
	self:closeLock()
	self:closeSyncToRedis()
	self.business = {}
	self:initListen()
	monitorXml = uniqueService("commonService.monitorXml")
end	

function monitor:businessStart(service, serviceName)

	self.business[service] = serviceName
end	

function monitor:businessEnd(service, serviceName)

	local serviceName = self.business[service]
	self.business[service] = nil
end	

function monitor:initListen()

	local function watch()

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
	skynet.fork(watch)		
end	

function monitor:shut()

	if closing then return end
	closing = true

	--master proxy
	self:call("player.masterProxyMan", "mcall", "closeConnWithMaster", __cnf.serverId)

	--monitorXml
	if monitorXml then
		skynet.call(monitorXml, "lua", "shut")
	end	

	--ws
	if __cnf.webport then
		skynet.send(skynet.uniqueservice('ws'), "lua", "exit")
	end	

	--connMan
	SERVICE_OBJECT:call("conn.connMan", "shut")

	--dbMan
	SERVICE_OBJECT:call("db.dbMan", "shut")

	--businessService
	for service, serviceName in pairs(self.business) do

		mylog.info("	开始通知 %s 退出系统.", serviceName)
		skynet.call(service, "lua", "shut")
		mylog.info("	结束通知 %s 退出系统.", serviceName)
	end	


	--dbMan
	SERVICE_OBJECT:call("db.dbMan", "shut")

	mylog.info("	存储服务数据保存成功.")
	redisdb:publish("serversafeclose", 1)
	mylog.info("	stop.py开始销毁进程.")		

	--todo python若长时间没关闭则直接kill掉
	skynet.timeout(150, function ()

		mylog.info("	程序自己退出.")
		redisdb:set("serversafeclose", 1)
		os.exit()
	end)
end	

return monitor