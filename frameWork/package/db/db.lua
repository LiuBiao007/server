local skynet		    = require "skynet"
local mysql 		    = require "skynet.db.mysql" 
local serviceObject     = require "objects.serviceObject"
local query             = require "coredb.query"
local savedb            = require "db.savedb"
local srd               = require "redis.saveRedis"
local serviceTrigger    = require "base.serviceTrigger"
local dbo               = class("db", serviceObject)

require "db.logsql"
local string_format     = string.format
local table_unpack      = table.unpack
local push			    = table.insert
local odate			    = os.date
local mylog             = mylog
local tostring          = tostring
local db

function dbo:init(_, isLogDb)

    dbo.__father.init(self)

	local conf 
    if isLogDb then

        conf = table.copy(__cnf.logdb)
    else

        conf = table.copy(__cnf.db)
    end    
    self.isLogDb = isLogDb
    
    local function on_connect(db)
    	db:query("set charset utf8");
    end

  	if not conf.max_packet_size then
  		 conf.max_packet_size = 1024 * 1024
  	end

  	if not conf.on_connect then
  		conf.on_connect = on_connect
  	end

	db = mysql.connect(conf)	

    skynet.fork(function () 

        while true do
            db:query("select 1;")
            skynet.sleep(300)
        end    
    end)  

    self:closeSyncToRedis()
end	

function dbo:execute(sql)

    if __cnf.debugSql and not self.isLogDb then
        mylog.info(tostring(sql))
    end  
  	local ret = db:query(sql)
  	if ret.badresult then

        mylog.info("[SQL] %s",sql)
        skynet.trace()
  		error(ret.err)
  	end

  	return ret
end

function dbo:saveCache(playerId, c, n)

    for key, mode in pairs(c) do

        local ok, msg = pcall(self.saveCacheEx, self, key, mode)
        if not ok then mylog.warn(string.dump(msg)) end
    end 
    serviceTrigger.send("saveCacheOk", playerId, n)
end  

function dbo:saveCacheEx(key, mode)
 
    local dbname, prikey, id = key:match("([^:]+):([^:]+):([^:]+)")
    local sql
    if mode == "delete" then

        sql = query:name(dbname):where(prikey, id):fetchSql():delete()
    else
        
        local data = srd:new(dbname):rawgetall(key)
        if next(data) then  
            sql = savedb:new(dbname):fetchSql(data)
        end    
    end  

    if sql then

        self:execute(sql)
    end  
end 

function dbo:executeLog(bigtype,guid,userid,platform,serverid,name,current_cmd,...)

    local dataarr,strarr = ...
    if not dataarr then dataarr = {} end
    if not strarr  then strarr  = {} end

    local params = {}
    for i = 1, 6 do
        push(params, dataarr[i] or -1)
    end 
    for i = 1, 3 do
        push(params, strarr[i] or "")
    end 
    
    local t 		= odate("*t")
    local month 	= t.month < 10 and "0" .. t.month or t.month
    local day   	= t.day < 10 and "0" .. t.day or t.day
    local dbname 	= string_format("t_audit_%s_%s%s%s", bigtype, t.year, month, day) 

    local sql 		= string_format(LOGSQL, dbname, dbname, guid, userid, platform, 
    								serverid, name, os.getTime(), bigtype, current_cmd or "" 
    								, table_unpack(params))

    self:execute(sql)
end    

return dbo
