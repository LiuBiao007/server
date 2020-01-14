local sharedata 	= require "skynet.sharedata"
local redis 		= require "skynet.db.redis"
local colock		= require "base.colock"
local uniqueService = require "services.uniqueService"
local assert 		= assert
local type   		= type
local string 		= string
local table_pack    = table.pack
local table_unpack  = table.unpack
require "ext.math"
require "ext.io"
require "ext.string"
require "ext.os"
require "ext.table"	
require "const.logConf"
require "const.activityConst"

local skynet 		= require "skynet"
local trigger		= require "base.trigger"
local object 	 	= require "objects.object"

PLAYER_STATE_INIT 	 = 0
PLAYER_STATE_LOADING = 1
PLAYER_STATE_INGAME  = 2

local serviceObject  = class("serviceObject", object)

function serviceObject:init(maxQuene, ...)

	serviceObject.__father.init(self)

	if type(maxQuene) == "number" and maxQuene > 0 then

		self.maxQuene = maxQuene
	end	
	__cnf 		  = sharedata.query("cnf")
	errorcode 	  = sharedata.query("errorcode")
	gameconst 	  = sharedata.query("gameconst")
	commonconst   = sharedata.query("commonconst")
	xmls          = sharedata.query("XMLCONFIG")
	dbField		  = sharedata.query("dbField")
	extra_db	  = sharedata.query("extra_db")
	checklen_db	  = sharedata.query("checklen_db")

	self:initEnv()
	if type(self.initChild) == "function" then
		self:initChild(...)
	end	

	self.dbField = dbField

	self.__Lock  = true

	--assert(not SERVICE_OBJECT, string.format("SERVICE_OBJECT [%s] just can be init once.", self.__classname))
	--SERVICE_OBJECT = self
	return self
end

--关闭服务锁 默认打开
function serviceObject:closeLock()

	self.__Lock = false
end	

function serviceObject:initEnv()

	redisdb = redis.connect(__cnf.redis)
	assert(type(redisdb) == "table")

	self.redisdb = redisdb


	self.canSync = true

	self:syncToRedis()
end	

function serviceObject:notifyAll()
	trigger.notify("monitorJson")
	trigger.notifyAndReset("syncToRedis")
end	

function serviceObject:closeSyncToRedis()

	self.canSync = false
end	

function serviceObject:syncToRedis()

	skynet.fork(function ()

		while self.canSync do

			skynet.sleep(__cnf.debug and 300 or 50)
			self:notifyAll()
		end	
	end)
end	

--数据进行初步的初始化， 特殊初始化可在此基础上再赋值修改
function serviceObject:createDbInitData(dbname)

	local fields = assert(self.dbField[dbname], string.format("error dbname %s.", dbname))
	local r = {}
	for field, fieldType in pairs(fields) do

		if fieldType == 'S' then
			r[field] = ""
		elseif fieldType == 'D' then
			r[field] = os.getCurTime()
		elseif fieldType == 'I' then
			r[field] = 0
		elseif fieldType == 'J' then
			r[field] = {}
		else	
			error(string.format("error dbname %s field %s fieldType %s.",
				dbname, field, fieldType))
		end	
	end	

	return r
end	

function serviceObject:shut()

	self:notifyAll()
	self.canSync = false
	if SERVICE_OBJECT.serviceName then
		mylog.info(" 		 %s 服务退出系统.", SERVICE_OBJECT.serviceName)
	end	
	return true
end	

function serviceObject:send(service, cmd, ...)

	local s = assert(uniqueService(service), string.format("error service %s.", service))
	skynet.send(s, "lua", cmd, ...)
end

function serviceObject:call(service, cmd, ...)

	local s = assert(uniqueService(service), string.format("error service %s.", service))
	return skynet.call(s, "lua", cmd, ...)
end

function serviceObject:do_cmd(session, source, cmd, ...)

	assert(type(session) == "number" and session >= 0, string.format("error session %s.", session))
	assert(type(cmd) == "string", string.format("error cmd %s class %s.", 
		cmd, self.__classname))

	if self.maxQuene and skynet.mqlen() >= self.maxQuene then

		mylog.warn("class [%s] service [%08X] mqlen overload [%s].", self.__classname, skynet.self(), skynet.mqlen())
		self.maxQuene = self.maxQuene * 2
	end

	if type(self.do_cmd_rewrite) == "function" then

		return self:do_cmd_rewrite(session, source, cmd, ...)
	else

		assert(type(self[cmd]) == "function", string.format("error cmd %s in class %s.",
			cmd, self.__classname))
		if self.__Lock then
			local function docmd(cmd, ...)

				local f = self[cmd]
				assert(type(f) == "function", string.format("error cmd type:%s.", cmd))
				return self.safeLock(f, cmd, self, ...)
			end	

			if session == 0 then

				docmd(cmd, ...)
			else
				
				return docmd(cmd, ...)
			end		
		else

		    if session == 0 then 

		        self[cmd](self, ...)
		        return nil
		    else
		        
		        local r = table_pack(self[cmd](self, ...))
		        assert(#r > 0, string.format("class [%s] cmd [%s] may not resposed.", self.__classname, cmd))
		        return table_unpack(r)
		    end 
		end	
	end	
end

return serviceObject	
