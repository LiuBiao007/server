local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
require "skynet.manager"
local XMLParser     = require "base.parser"
local newService 	= require "services.newService"
local uniqueService = require "services.uniqueService"
local cnf           = require "config.config"
local errorcode     = require "errorcode"
local gameconst     = require "gameconst"
local commonconst   = require "commonconst"
local mylog         = require "base.mylog"

require "ext.math"
require "ext.io"
require "ext.string"
require "ext.os"
require "const.activityConst"
require "class.import"


local game = {}

local function initGameSql()

    local path = "./const/testgame.sql"
    local toPath = "./const/dbField.lua"

    local __n = 0
    local string_format = string.format
    local lastTableName
    local lastPrikey
    local data_struct   = {}
    local extra_db      = {}
    local checklen_db   = {}
    local tofile = io.open(toPath, "w+")
    tofile:write("--该文件由程序自动生成, 请勿改动！\n\n")
    tofile:write("return {\n")

    for line in io.lines(path) do

        local tableName = line:match("DROP TABLE IF EXISTS %`(.-)%`;")
        if tableName then 
            if tableName:find("[A-Z]") then
                error(string.format("tableName %s contain upper word.", tableName))
            end    
            data_struct[tableName]  = {} 
            extra_db[tableName]     = {}
            checklen_db[tableName]  = {}
            lastTableName = tableName
            tofile:write(string_format("    %s = {\n", lastTableName))
        end

        local field, filedType = line:match("%`(.-)%`%s+(.-)%s+NOT NULL")
        local isJson = line:match("#%s*JSON%s*#")
        if field and filedType then
            
            if isJson then

                assert(filedType:find("varchar") or filedType:find("text"), 
                    string.format("error field %s filedType %s.", field, filedType))
              
                local len = filedType:match("varchar%((.-)%)")
                if len then
        
                    checklen_db[lastTableName][field] = tonumber(len)
                end    
                data_struct[lastTableName][field] = 'J'
                tofile:write(string_format("        %s = 'J',\n", field))
            elseif filedType:find("int") then

                data_struct[lastTableName][field] = 'I' 
                tofile:write(string_format("        %s = 'I',\n", field))
            elseif filedType:find("datetime") then

                data_struct[lastTableName][field] = 'D' 
                tofile:write(string_format("        %s = 'D',\n", field))                
            else   

                local len = filedType:match(".*char%((.-)%)")
                if len then
             
                    checklen_db[lastTableName][field] = tonumber(len)
                end   
                data_struct[lastTableName][field] = 'S' 
                tofile:write(string_format("        %s = 'S',\n", field))
            end
            __n = __n + 1
        end     

		local prikey,_  = line:match("%`(.-)%`(.-)PRIMARY%s*KEY")
		if not prikey then
		
        	prikey = line:match("PRIMARY%s*KEY%s*%(%`(.-)%`%)")
		end	

		if prikey and lastTableName then

            lastPrikey = prikey
			extra_db[lastTableName].__prikey = prikey
			tofile:write(string_format("        __prikey = %s,\n", prikey))
		end	

        if line:find("ENGINE%s*=%s*InnoDB") then

            extra_db[lastTableName].__n = __n
            tofile:write(string_format("        __n = %s,\n", __n))
            tofile:write("  },\n")
            assert(lastPrikey, string.format("table %s miss prikey.", lastTableName))
            lastPrikey = nil
            __n = 0
        end    
    end    

    tofile:write("}\n")
    tofile:close()
  
    sharedata.new("dbField",     data_struct)
    sharedata.new("extra_db",    extra_db)
    sharedata.new("checklen_db", checklen_db)
end	

local function initShare()

    local xml = require "const.xmlCnf"
	    -- xml数据解析  
    local xmls = XMLParser("../common/xmls/", xml)
    sharedata.new("XMLCONFIG", xmls)

    sharedata.new("cnf",cnf)
    sharedata.new("errorcode", errorcode)
    sharedata.new("gameconst", gameconst)
    sharedata.new("commonconst", commonconst)    
end	

local function initRedis()

    local redis   = require "skynet.db.redis"
    local redisdb = redis.connect(cnf.redis)
    redisdb:flushdb()
    if cnf.connectMaster then
        redisdb:hset("serconf", "connectMaster", 1)
    else
        redisdb:hset("serconf", "connectMaster", 0)
    end 
    redisdb:disconnect()
end    

function game.init()

    initRedis()
	initGameSql()
	initShare()

    uniqueService("commonService.logManager")
end

require "ext.table"
function game.run(func)

    uniqueService("conn.sproto")
    uniqueService("player.userCenter")
	uniqueService("conn.connMan", cnf.watchdog)
    uniqueService("mail.mailCenter")
	uniqueService("guid.guidd")
    uniqueService("commonService.monitor")
    uniqueService("commonService.timerd")
    uniqueService("commonService.admin")
    
    skynet.newservice("debug_console", "0.0.0.0", cnf.debug_port)
    if cnf.webport then
        uniqueService("websocket.ws", cnf.webport)
    end    
    skynet.uniqueservice("webcurl")

    game.runActivity()

    uniqueService("player.masterProxyMan")
    func()
    uniqueService("commonService.globalReward")
end

function game.runActivity()

    for id, item in pairs(ACTIVITY_CONFIG) do

        if item.type == ACTIVITYTYPE_UNIQUE then

            uniqueService(string.format("activity.%s", item.name), id)
        end 
    end 
end    

function game.exit()

    mylog.info("    Server start ok.")
    skynet.exit()
end	

return game