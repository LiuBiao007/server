local skynet     = require "skynet"
local sharedata  = require "skynet.sharedata"
local mylog 	 = require "base.mylog"
local subject    = require "base.subject"
local saveRedis	 = require "redis.saveRedis"
local redisHeader = require "redis.redisHeader"
local trigger	 = require "base.trigger"
local object 	 = require "objects.object"
local cjson 	 = require "cjson"

local jsonCount  = 0
local fieldObject = class("fieldObject", object)

local assert		= assert
local next 			= next
local type 			= type
local string 		= string
local rawget 		= rawget
local rawset 		= rawset
local error  		= error
local pairs			= pairs
local getmetatable 	= getmetatable
local push   		= table.insert
local table_copy	= table.copy

local _checkcount 	= 100--单个服务内最大的数据库json数量
function fieldObject:init(dbname, switchMonitorJson)

	rawset(self, "__data_changed", false)
	assert(type(dbname) == "string", string.format("dbname [%s] type error.", dbname))
	assert(dbField[dbname], string.format("error dbname %s.", dbname))	

	self.collector 			= {}
	self.dbname 			= dbname
	self.dbField 			= dbField[dbname]
	self.writeRedisError 	= subject:new()
	self.writeRedisSuccess 	= subject:new()
	self.monitorSimple		= subject:new()
	self:createObjects()
	--自动检测json 表数据是否改动, 默认关闭
	self.switchMonitorJson = switchMonitorJson and false or true
	return self
end	

--数据库装载数据时调用
function fieldObject:load(data, t)

	return self:new():attach(data, true, t)
end	
--创建新的数据对象时调用
function fieldObject:create(data, t)

	return self:new():attach(data, false, t)
end	

local function compareTable(t1, t2)

	local ty1 = type(t1)
	local ty2 = type(t2)

	if ty1 ~= ty2 then 
		return false 
	end

	if ty1 ~= 'table' and ty2 ~= 'table' then 
		return t1 == t2 
	end

	for k1, v1 in pairs(t1) do

	    local v2 = t2[k1]
	    if v2 == nil or not compareTable(v1, v2) then 
	    	return false 
	    end
	end

	for k2, v2 in pairs(t2) do

	    local v1 = t1[k2]
	    if v1 == nil or not compareTable(v1, v2) then 
	    	return false 
	    end
	end

	return true
end

function fieldObject:monitorJson()

	local json = self.__json__
	if not next(json) then return end
	for k, v in pairs(json) do

		local cur = self[k]
		if not compareTable(cur, v) then

			json[k] = table_copy(cur)
			self[k] = cur
		end	
	end	
end	 

--初始化数据库数据
function fieldObject:attach(data, isLoad, t)
		
	assert(type(data) == "table", string.format("data type %s error.", data))
	assert(not getmetatable(data))

	local n = 0
	for k, v in pairs(data) do

		assert(not rawget(self, k), string.format("class [%s] key [%s] must be in metatable.", self.__classname, k))
		local _type = self.dbField[k]
		if _type then
		
			if _type == 'I' then

				assert(type(v) == "number", string.format("self.dbname %s key %s type error [I].", self.dbname, k))
			elseif _type == 'D' then

				assert(type(v) == "number", string.format("self.dbname %s key %s type error [D].", self.dbname, k))		
			elseif _type == 'S' then

				assert(type(v) == "string", string.format("self.dbname %s key %s type error [S].", self.dbname, k))		
			elseif _type == 'J' then

				assert(type(v) == "table" and not getmetatable(v),
					string.format("self.dbname %s key %s type error [J].", self.dbname, k))

				if self.switchMonitorJson then

					if not self.__json__ then self.__json__ = {} end
					self.__json__[k] = table.copy(v)	
					jsonCount = jsonCount + 1

					if jsonCount and jsonCount > _checkcount then
						mylog.warn("json count over max.")
						_checkcount = _checkcount + 10
					end						
				end	
			end	
			n = n + 1
		end	
	end	

	assert(n == extra_db[self.dbname].__n, string.format("init data must be full data [%s:%s].", n, extra_db[self.dbname].__n))

	if self.__json__ and next(self.__json__) then

		trigger.add("monitorJson", self, self.monitorJson)
	end	

	local father_meta = getmetatable(self.__father)
	if not father_meta.__newindex then

		father_meta.__newindex = function (_, k, v)
			error(string.format("class %s k %s v %s do not modify father.",
				self.__classname, k, v))
		end
	end	

	local old_meta = getmetatable(self)
	assert(old_meta.__index)

	self.__rawdata 	= {}
	local newfunction = function (self, k)

		local myindex = old_meta.__index
		if myindex[k] then return myindex[k] end
		return self.__rawdata[k]
	end

	local meta = {

		__index = newfunction
		,

		__newindex = function (self, k, v)

			assert(k ~= "__rawdata", "error key __rawdata.")
			if not self.dbField[k] then 	

				rawset(self, k, v)
				return 
			end

			if type(v) ~= "string" and type(v) ~= "number" and type(v) ~= "table" then
				error(string.format("dbname %s k %s v %s.", self.dbname, k, v))
			end	

			if rawget(self, "__obj_delete") then return end

			if type(v) == "string" or type(v) == "number" then
				local old = self.__rawdata[k]
				if old and old == v then return end
			end	

			self.__rawdata[k] = v

			if rawget(self, "writeStep") then return end
			self.collector[k] = v		

			if not rawget(self, "__data_changed") then
				trigger.add("syncToRedis", self, self.monitor)	
			end
			
			rawset(self, "__data_changed", true)	
			self.monitorSimple:notify(k, v)
		end
		,
		__gc = function (self)

			trigger.dec("syncToRedis", self, self.monitor)
			self:shut()
		end
		,
	}

	setmetatable(self, meta)

	if isLoad then

		rawset(self, "writeStep", true)
	else
		--create player
		if self.dbname == 'player' then
			PLAYERID = data.guid
		end	
	end	
	
	self:setData(data)
	self:hsetall(data)

	if isLoad then
		rawset(self, "writeStep", false)
	end

	if type(t) == "table" then
		self:setData(t)
	end	

	if type(self.initGameData) == "function" then
		self:initGameData()
	end
	
	return self
end	

function fieldObject:createObjects()

	self.saveRedis   = saveRedis:new(self.dbname, self)
	self.redisHeader = redisHeader:new(self.dbname) 
end	

function fieldObject:monitor(...)

	--skynet.fork(function () 

		--while true do

			--skynet.sleep(1)
			self:writeToRedis(...)
		--end	
	--end)
end	

function fieldObject:writeToRedis(...)

	if rawget(self, "__obj_delete") then 
		return 
	end

	if rawget(self, "__data_changed") == false then
		return
	end	

	if rawget(self, "__data_changed") then

		local c = self.collector
		self.collector = {}
		rawset(self, "__data_changed", nil)
		local ok, msg = xpcall(self.writeToRedisEx, debug.traceback, self, c, ...)

		if not ok then

			mylog.warn("error write to redis [%s], reason: %s.", self.dbname, string.dump(msg))
			self.writeRedisError:notify(self.dbname, c)
		else
			
			self.writeRedisSuccess:notify(self.dbname, c)
			--mylog.debug("dbname [%s] write redis success.", self.dbname)
		end	
	end	
end	

function fieldObject:getHeader()

	local prikey = self.redisHeader:getPriKey()
	local v = assert(self[prikey], string.format("error dbname:%s prikey:%s v:%s.", self.dbname, prikey, self[prikey]))
	local header = self.redisHeader:getHeader(v)
	return header
end	

function fieldObject:writeToRedisEx(c)

	if not next(c) then return end
	local header = self:getHeader()
	self.saveRedis:save(header, c)
end	

function fieldObject:hsetall(c)

	if not next(c) then return end
	local header = self:getHeader()	
	self.saveRedis:hsetall(header, c)	
end	

function fieldObject:delete()

	rawset(self, "__obj_delete", true)
	rawset(self, "__data_changed", false)
	trigger.dec("monitorJson", self)
	local header = self:getHeader()
	self.saveRedis:delete(header)
	self = nil
end

function fieldObject:shut()

	if rawget(self, "__data_changed") == false then return end
	rawset(self, "__data_changed", true)
	self:writeToRedis()
end	
--如果在下发数据的时候可能会改变数据库字段或者赋值， 请调用此结果
--避免产生无用的SQL
function fieldObject:copyFields()

	local result = {}
	for k, v in pairs(self.dbField) do
		result[k] = self[k]
	end	
	return result
end	
return fieldObject
