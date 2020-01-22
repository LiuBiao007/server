local skynet        = require "skynet"
local newService    = require "services.newService"
local serviceTrigger = require "base.serviceTrigger"
local serviceObject = require "objects.serviceObject"
local srd           = require "redis.saveRedis"
local proxyPlayerMan = require "player.proxyPlayerMan"
local db            = require "coredb.query"

local push          = table.insert
local table_pack    = table.pack
local table_unpack  = table.unpack
local dbMan = class("dbMan", serviceObject)

local totalSqlCount = 0
local dbs           = {}
local name2db		= {}	--名称对应数据库服务 插入操作必须是同表同服务
local balance       = 0		--负载均衡变量
function dbMan:init(...)

	dbMan.__father.init(self, ...)
	self:createPool()
    self:bgSave()
    self:closeLock()
    self:closeSyncToRedis()
    self.playerMan = proxyPlayerMan:new("存储服务")
	return self
end	

function dbMan:initTriggers()

    serviceTrigger.add("saveCacheOk")
    serviceTrigger.add("onPlayerStateOut")
    serviceTrigger.add("onPlayerFullDataInRedis")
end    

function dbMan:createPool()

	local count = __cnf.db.dbCount or 4
	for i = 1, count do
		local s = newService("db.db")
		push(dbs, s)
	end	
    if __cnf.logdb then
        self.logDb = newService("db.db", 1)
    end    
	mylog.info("[DBMAN] create %s db success.", count)
end	

local function getDb(name)

    local dbscount = #dbs
    assert(dbscount > 1, "dbs count is error")
    
    local function balance_get()
        balance = balance + 1
        if balance > dbscount then
            balance = 1
        end

        local db = dbs[balance]
        assert(db, "db is nil")

        return db
    end    

    if name then

        if name2db[name] then
            return name2db[name]
        else
            local db = balance_get()
            name2db[name] = db
            return db
        end    
    else
        return balance_get()
    end    
end 

function dbMan:executeLog(...)

    skynet.send(self.logDb, "lua", "executeLog", ...)
end    

function dbMan:execute(sql, name, playerId)

    local db
    if playerId then

        local index = self:createIndex(playerId)
        db = dbs[index]
    else
        db = getDb(name)    
    end    
	
	return skynet.call(db, "lua", "execute", sql)
end	

local cache  = {}
function dbMan:modify(playerId, key, mode)

    assert(type(key) == "string" and key:match("([^:]+):([^:]+):([^:]+)"),
        string.format("error key %s.", key))
    assert(type(mode) == "string" and (mode == "update" or mode == "delete"),
        string.format("error key %s mode %s.", key, mode))
    local s = cache[playerId]
    if not s then 
        s = {data = {}, n = 0}
        cache[playerId] = s
    end    

    local data = s.data
    if not data[key] then
        s.n = s.n + 1
        totalSqlCount = totalSqlCount + 1
    end    

    data[key] = mode
end

function dbMan:bgSave()

    local time = __cnf.bgsave or 60
    skynet.fork(function ()
        while true do
            skynet.sleep(time * 100)
            self:save()
        end    
    end)
end    

local serverShut = false
function dbMan:shut()

    serverShut = true
    self:save()
    mylog.info(" (1)关闭dbMan, 当前剩余SQL数量 [%s].", totalSqlCount)
    while totalSqlCount > 0 do

        skynet.sleep(100)
    end   
    self:save() 
    mylog.info(" (2)关闭dbMan, 当前剩余SQL数量 [%s].", totalSqlCount)
    return true
end    

function dbMan:save(playerCache, n)

    local cache = playerCache or cache
    if n and n > 0 then
        mylog.info("    玩家下线预计存储SQL总数: [%s].", n)
    elseif totalSqlCount > 0 then
        mylog.info("    当前预计存储SQL总数: [%s].", totalSqlCount)
    end 

    local indexCount    = {}
    local indexService  = {}
    for playerId, c in pairs(cache) do
        if next(c.data) then
            
            local index, service = self:savePlayer(playerId, c.data, c.n)
            c.data = {}
            if index then
                if not indexCount[index] then 
                    indexCount[index] = c.n
                else
                    indexCount[index] = indexCount[index] + c.n
                end 
                indexService[index] = service
            end    
        end    
    end    

    for index, count in pairs(indexCount) do
        mylog.info("    db[%s] [%08X] 将存储 [%s] 条SQL.", index, indexService[index], count)
    end    
end     

local gindex = 0
function dbMan:createIndex(playerId)

    local index = 1
    --if __cnf.isMaster then

    --    gindex = gindex + 1
     --   index = gindex % #dbs + 1
     --   if gindex >= 2^10 then gindex = 0 end
    --else
        if type(playerId) == "number" then
            index = playerId % #dbs + 1
        else
            assert(type(playerId) == "string" and #playerId == 24, string.format("error playerId %s.", playerId))
            index = guidMan.reverseId(playerId) % #dbs + 1
        end        
    --end    
    
    assert(index <= #dbs and index >= 1, string.format("error playerId %s index %s.", playerId, index))
    return index
end    

function dbMan:savePlayer(playerId, c, n)

    if not c then
        local s = cache[playerId]
        if s and next(s.data) then
            c = s.data
            n = s.n
        end    
    end    

    if not c then return nil end

    local index = self:createIndex(playerId)
    local db = dbs[index]

    skynet.send(db, "lua", "saveCache", playerId, c, n)
    return index, db
end    

function dbMan:onPlayerFullDataInRedis(playerId)

    local player = assert(self.playerMan:getPlayerById(playerId), string.format("error playerId %s.", playerId))
    player:setFullDataInRedis(true)
    return true
end 

function dbMan:onPlayerStateOut(playerId)

    if serverShut then return end
    assert(type(playerId) == "string" and #playerId == 24, string.format("error playerId: %s.", playerId))
    local player = self.playerMan:getPlayerById(playerId)
    assert(player, string.format("player %s has not created.", playerId)) 
    
    if not player:isInGame() then return end    
    local s = cache[playerId]
    local n = 0
    if s and s.n > 0 then 
        n = s.n
    end    
    self:save({[playerId] = s}, n)

    local now = os.getCurTime()
    player:setInGame(false)
    mylog.info(" playerId %s 退出游戏, 数据将在%s分钟后删除.", playerId, __cnf.cacheTime)
    
    skynet.timeout(__cnf.cacheTime * 60 * 100, function ()

        local player = self.playerMan:getPlayerById(playerId)
        if player then

            player.safeLock(self.removePlayerRedisData, playerId .. " remove", self, player)
        end    
    end)
end    
 
function dbMan:removePlayerRedisData(player)

    --double check
    local playerId = player.id
    local s = cache[playerId]
    if s and s.n > 0 then 
        mylog.info("    playerId %s 数据未存储完毕, 取消删除redis数据.", playerId)
        return 
    end

    if player:isInGame() or player:inRemove() then
        return
    end    

    mylog.info(" playerId %s Redis数据开始卸载.", playerId)
    player:setFullDataInRedis(false)
    player:setRemove(true)
    serviceTrigger.call("onPlayerFullDataNotInRedis", playerId)
    --player
    local cnf = gameconst.loadPlayerData
    --player
    local dbname = "player"
    local prikey = extra_db[dbname].__prikey
    local header = string.format("%s:%s:%s", dbname, prikey, playerId)
    self.redisdb:del(header)

    local function getMemberSet(dbname, playerId) 

        return string.format("set:%s:%s", dbname, playerId)
    end  

    --other
    for dbname, _ in pairs(cnf) do

        local sets = getMemberSet(dbname, playerId)
        local ids  = self.redisdb:smembers(sets)
        for _, header in pairs(ids) do

            self.redisdb:del(header)
            self.redisdb:srem(sets, header)
        end    
    end            

     mylog.info(" playerId %s Redis数据卸载完成.", playerId)  
end    

function dbMan:saveCacheOk(playerId, n)

    local s = cache[playerId]
    assert(s, string.format("error playerId %s n %s.", playerId, n))
    s.n = s.n - n
    if s.n <= 0 then cache[playerId] = nil end
    totalSqlCount = totalSqlCount - n
    mylog.info(" 已存储 playerId:%s [%s] 条SQL, 剩余 [%s] 条SQL, 总剩余 [%s] 条SQL.", playerId, n, s.n, totalSqlCount)
end 

function dbMan:loadGameData(playerId, agent, isCreate)

   assert(type(playerId) == "string" and #playerId == 24, string.format("error playerId: %s.", playerId))
    --check full data in redis
    local player = self.playerMan:getPlayerById(playerId)
    if player then
        player:setInGame(true)
    else
        player = self.playerMan:createPlayer(playerId, nil)
        player:setInGame(true)
        --check all sql has been write success.
        local s = cache[playerId]
        if s and s.n > 0 then
            while s.n > 0 do
                skynet.sleep(10)
            end  
        end         
    end    
    
    local r = {}
    --load personal data
    if not isCreate then

        local fullDataInRedis = self.playerMan:isFullData(playerId)
        if fullDataInRedis then

            mylog.info(" playerId %s data load from Redis.", playerId)
            r = self:loadDataFromRedis(playerId)
        else

            r = player.safeLock(self.loadDataFromMysql, playerId .. " loadMysql", self, playerId)
            mylog.info(" playerId %s data load from Mysql.", playerId)
        end   
    end
    
    --load business service data start
    -- ...
    local result = serviceTrigger.callResult("onLoadGameData", playerId)

    --load business service data end    

    return r, result
end    

function dbMan:loadDataFromRedis(playerId)

    local result = {}
    local cnf = gameconst.loadPlayerData
    --player
    local dbname = "player"
    local prikey = extra_db[dbname].__prikey
    local header = string.format("%s:%s:%s", dbname, prikey, playerId)
    local playerdata = srd:new(dbname):hgetall(header)
    result[dbname] = playerdata

    local function getMemberSet(dbname, playerId) 

        return string.format("set:%s:%s", dbname, playerId)
    end    
    --other
    for dbname, _ in pairs(cnf) do

        local sets = getMemberSet(dbname, playerId)
        local ids  = self.redisdb:smembers(sets)
        assert(not result[dbname], string.format("dbname %s repeat.", dbname))
        result[dbname] = {}
        for _, header in pairs(ids) do

            table.insert(result[dbname], srd:new(dbname):hgetall(header))
        end   
    end    

    return result
end

function dbMan:loadDataFromMysql(playerId)

    local result = {}
    local cnf = gameconst.loadPlayerData
    --player
    local playerdata = db:name('player'):where("guid", playerId):find()
    result.player = playerdata

    for dbname, _playerid in pairs(cnf) do

        assert(not result[dbname], string.format("dbname %s repeat.", dbname))
        local r = db:name(dbname):where(_playerid, playerId):select()
        result[dbname] = r
    end    
    
    return result
end    


return dbMan
