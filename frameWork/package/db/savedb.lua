local db 			= require "coredb.query"
local skynet		= require "skynet"
local assert		= assert
local string_format = string.format
local type 			= type
local uniqueService = require "services.uniqueService"

local checkDb		= require "db.checkDb"
local savedb = class("savedb", checkDb)
--db数据库保存的安全操作对应
--针对的是replace全数据保存的封装
function savedb:init(name)

	savedb.__father.init(self, name)
	return self
end	

--全数据保存操作
function savedb:save(data, playerId)

	local r = self:checkField(data)
	return db:name(self.__name):setPlayerId(playerId):data(r):insert()
end	

function savedb:rawsave(data, prikey, prikeyvalue, playerId)

	return db:name(self.__name):setPlayerId(playerId):data(data):where(prikey, prikeyvalue):update()
end	

--部分必须原生sql的直接执行
function savedb:save_sql(sql)

    local dbconnection = uniqueService("db.dbMan")
    return skynet.call(dbconnection, "lua",  "execute", sql, self.__name)
end	

--不执行 获取插入数据的sql语句
function savedb:fetchSql(data)

	local r = self:checkField(data)
	return db:name(self.__name):data(r):fetchSql():insert()
end	

function savedb:fetchDeleteSql(key, id)

	return db:name(self.__name):where(key, id):fetchSql():delete()
end	
return savedb 