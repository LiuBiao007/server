local uniqueService	= require "services.uniqueService"
local skynet		= require "skynet"
local assert		= assert
local string_format = string.format
local type 			= type
local table_insert  = table.insert
local table_unpack  = table.unpack

local redisHeader   = require "redis.redisHeader"
local fieldCheck	= require "redis.fieldCheck"
local saveRedis     = class("saveRedis", fieldCheck)

local public_set = "__public_set"
local all_player_header = "player_header"

--公共数据不需要set 私人数据需要set， 装载时根据set进行数据装载
function saveRedis:init(dbname, fieldObj, ...)

	assert(type(dbname) == "string", "error dbname")
	self.redisdb = redisdb
	self.name  = dbname
	self.redisHeader = redisHeader:new(dbname)
	if fieldObj then
		self.fieldObj = fieldObj

		local sets
		if self.name ~= 'player' then

			if gameconst.loadPlayerData and gameconst.loadPlayerData[self.name] then

				local playerId = assert(player.guid, string.format("dbname %s saveRedis error.", self.name))
				sets = self.redisHeader:getRedisSet(playerId)
				self.sets = assert(sets)
			end		
		end		
	end	

	return self
end

local function gethash(ret)

    if #ret > 0 then

        local r = {}
        local count = #ret / 2
        for i = 1, count do
            r[ret[2*i - 1]] = ret[2*i]
        end
        return r     
    end
    return nil
end 

--dbMan装载fullDataInRedis的时候使用
function saveRedis:hgetall(header)

	local data = self:rawgetall(header)
	return self:checkField(data)
end	

function saveRedis:hgetdata(header, ...)

	assert(select("#", ...) > 0)
	local data = gethash(self.redisdb:hmget(header, ...))
	return self:checkField(data)
end	

function saveRedis:rawgetall(header)

	assert(self.name, "error name")
	assert(self.redisdb, "error redisdb")
	local data = gethash(self.redisdb:hgetall(header))
	return data
end	

--存储对象的完整数据
function saveRedis:hsetall(header, obj)

	self:rawhsetall(header, obj)
	if self.name ~= "player" then
		if type(self.sets) == "string" then
			self.redisdb:sadd(self.sets, header)
		else
			self.redisdb:sadd(public_set, header)	
		end	
	else
		self.redisdb:sadd(all_player_header, header)
	end	
end	

function saveRedis:rawhsetall(header, obj)

	assert(self.name, "error name")
	assert(self.redisdb, "error redisdb")

	local r = self.redisdb:hmset(header, self:checkSetField(obj))
	assert(r:upper() == "OK", string_format("redis '%s' header '%s' hsetall error", self.name, header))
end	

local function getSaveId(playerId)

	if playerId then return playerId end
	local id = 0
	if PLAYERID then
		id = PLAYERID
	elseif player then
		id = player.guid
	end 	
	return id
end	

function saveRedis:save(header, obj, playerId)

	self:hsetall(header, obj)
	local dbMan = uniqueService("db.dbMan")
	skynet.send(dbMan, "lua", "modify", getSaveId(playerId), header, "update")
end

function saveRedis:rawsave(header, obj, playerId)
	
	local r = {}	
	for k, v in pairs(obj) do
		table_insert(r, k)
		table_insert(r, v)
	end	
	self.redisdb:hmset(header, table_unpack(r))
	local dbMan = uniqueService("db.dbMan")
	skynet.send(dbMan, "lua", "modify", getSaveId(playerId), header, "update")	
end

function saveRedis:delete(header, playerId)

	if self.name ~= "player" then
		if type(self.sets) == "string" then
	    	self.redisdb:srem(self.sets, header)
	    else
	    	self.redisdb:srem(public_set, header)	
	    end	
	else
		self.redisdb:srem(player_header, header)
	end    

    self.redisdb:del(header)
     local dbMan = uniqueService("db.dbMan")
    skynet.send(dbMan, "lua", "modify", getSaveId(playerId), header, "delete")
end	
return saveRedis 