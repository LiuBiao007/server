local skynet         = require "skynet"
local savedb         = require "db.savedb"
local db             = require "coredb.query"
local tools          = require "util.tool"
require "skynet.manager"
local businessObject = require "objects.businessObject"
local recycleNotice  = class("recycleNotice", businessObject)


local itemsExpires = {} -- 记录道具过期时间
local recycleNotices = {} -- 循环公告
local lastCheckTime = os.getCurTime()

function recycleNotice:sendNotice(_type, content, exception)
    if _type < gameconst.recycleNoticeType.min or _type > gameconst.recycleNoticeType.max or type(content) ~= "string" then
        mylog.warn("RecycleNoticeService sendNotice type:%s content:%s error!", _type, content or -1)
    else 
        self.playerMan:broadcast("sendEvent", {}, "insertNotice", {type = _type, content = content})
    end
end

function recycleNotice:sendGameNotice(_type, condition, contentType, exception, ...)
    local noticeInfo = xmls.GameNotice[_type]
    if noticeInfo and noticeInfo.params[condition] then
        local content
        if contentType == 1 then
            content = string.format(noticeInfo.content1, ...)
        else
            content = string.format(noticeInfo.content2, ...)
        end

        self:sendNotice(gameconst.recycleNoticeType.game, content, exception)
    end
end

local function checkTime(timeStr)
    -- 2014-07-02_17:30:00
    local year, month, day, hour, min, sec = string.match(timeStr, "(%d+)-(%d+)-(%d+)_(%d+):(%d+):(%d+)")
    year, month, day, hour, min, sec = tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(min), tonumber(sec)
    if not year or year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
        return errorcode.recycleNotice_time_error  -- 年月日不正确
    end

    if hour < 0 or hour >= 24 or min < 0 or min >= 60 or sec < 0 or sec >= 60 then
        return errorcode.recycleNotice_time_error  -- 时分秒不正确
    end

    return 0, os.stringToDateTime(string.format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec))
end

function recycleNotice:insertNotice(params)

    if type(params) ~= "table" or #params < 5 then
        return errorcode.param_error
    end

    local id = tonumber(params[1] or 0)
    if id <= 0 or recycleNotices[id] then
        return errorcode.recycleNotice_id_error
    end

    local err
    local startTime
    local endTime
    err, startTime = checkTime(params[2])
    if err ~= 0 then
        return err
    end

    err, endTime = checkTime(params[3])
    if err ~= 0 then
        return err
    end

    if endTime < startTime then
        return errorcode.recycleNotice_time_error
    end

    local interval = tonumber(params[4] or 0)
    if interval <= 0 or (endTime - startTime) < interval then
        return errorcode.recycleNotice_interval_error
    end

    local content = params[5]
    if type(content) ~= "string" or #content > 1024 then
        return errorcode.recycleNotice_content_error
    end

    local param = {
        id          = id,
        type        = _type,
        startTime   = startTime,
        endTime     = endTime,
        interval    = interval,
        content     = content,
    }
    savedb:new("recyclenotice"):save(param, 0)

    recycleNotices[id] = param

    return 0
end

function recycleNotice:deleteNotice(params)

    if type(params) ~= "table" or #params < 1 then
        return errorcode.param_error
    end

    local id = tonumber(params[1] or 0)
    if id <= 0 or not recycleNotices[id] then
        return errorcode.recycleNotice_id_not_exist
    end

    db:name("recyclenotice"):where('id', id):delete()
    recycleNotices[id] = nil

    return 0
end

function recycleNotice:getAllNotice()
    local results = {}
    for _, info in pairs(recycleNotices or {}) do
        if info.type == gameconst.recycleNoticeType.admin then
            table.insert(results, info)
        end
    end
    
    return 0, "", results
end

function recycleNotice:forbidUserLogin(params)

    if type(params) ~= "table" or #params < 2 then
        return errorcode.param_error
    end

    local playerId = params[1]
    if not playerId or not params[2] then
        return errorcode.param_error
    end

    local hour = tonumber(params[2])
    local simplePlayer = self:getPlayerInfoById(playerId)
    if not simplePlayer then
        return errorcode.user_login_nochar
    end

    local date = tools.getDelayForbidTime(hour)
    local o = self.playerMan:sendEvent(playerId, "forbidUserLogin", hour)
    if o then   
        o:name("player"):pk(playerId):rawset({forbidTime = date})
    end    

    self:send("player.userCenter", "setForbidTime", playerId, date)

    return 0
end

function recycleNotice:getOnlineCount(params)
    return 0, "", {onlineCount = self:call("conn.connMan", "getOnlineCount") or 0)}
end

local function getSimplePlayerInfo(p)
    return {
        userid              = p.userid,
        guid                = p.guid,
        name                = p.name,
        level               = p.level,
        serverid            = p.serverid,
    }
end

function recycleNotice:getPlayerInfoByName(params)
    if type(params) ~= "table" or #params < 1 then
        return errorcode.param_error
    end

    local playerName = params[1]
    if not playerName then
        return errorcode.param_error
    end

    local s = self:getPlayerByName(playerName)
    if not s then
        return errorcode.user_login_nochar
    end

    return 0, "", getSimplePlayerInfo(s)
end

--根据名字模糊查询
function recycleNotice:getPlayersInfoByName(params)
    if type(params) ~= "table" or #params < 1 then
        return errorcode.param_error
    end

    local playerName = params[1]
    if not playerName then
        return errorcode.param_error
    end

    local playerIds =self:getPlayerIdsByName(playerName)
    if #playerIds <= 0 then
        return errorcode.user_login_nochar
    end

    local results = {}
    for k, v in ipairs(playerIds) do
        local simplePlayer = self:getPlayerInfoById(v)
        table.insert(results, getSimplePlayerInfo(simplePlayer))
    end

    return 0, "", results
end

function recycleNotice:getPlayerInfoByUidAndSid(params)
    if type(params) ~= "table" or #params < 2 then
        return errorcode.param_error
    end

    local userId = params[1]
    if not userId then
        return errorcode.param_error
    end

    local serverId = params[2]
    if not serverId then
        return errorcode.param_error
    end

    local playerId = self:getPlayerIdByUserAndServerId(userId, serverId)
    if not playerId then
        return errorcode.user_login_nochar
    end

    local simplePlayer = self:getPlayerInfoById(playerId)
    if not simplePlayer then
        return errorcode.user_login_nochar
    end

    return 0, "", getSimplePlayerInfo(simplePlayer)
end

function recycleNotice:getPlayerInfoById(params)
    if type(params) ~= "table" or #params < 1 then
        return errorcode.param_error
    end

    local playerId = params[1]
    if not playerId then
        return errorcode.param_error
    end


    local simplePlayer = recycleNotice.__father:getPlayerInfoById(playerId)
    if not simplePlayer then
        return errorcode.user_login_nochar
    end

    return 0, "", getSimplePlayerInfo(simplePlayer)
end

local function processExpireNotices()
    local now = os.getCurTime()
    db:name("recyclenotice"):where("endTime", "<=", os.dateTimeToString(now))

    local results = db:name("recyclenotice"):select()
    for _, result in ipairs(results or {}) do
        local id = tonumber(result.id)

        recycleNotices[id] = result
    end
end

local function processTimeLimitItems()
    local now = os.getCurTime()
    for protoId, proto in pairs(xmls.items) do
        if type(protoId) == "number" and protoId >= 15000001 and protoId <= 15999999 then
            if proto.expires > now then -- 未过期道具
                itemsExpires[proto.expires] = true
            end
        end
    end
end

local function update()
    while true do
        local now = os.getCurTime()
        for id, info in pairs(recycleNotices) do
            if now >= info.endTime then
                recycleNotices[info.id] = nil
                db:name("recyclenotice"):where("id", info.id):delete()
            elseif now >= info.startTime and ((now - info.startTime) % info.interval) == 0 then
                self:sendNotice(info.type, info.content, {})
            end
        end

        skynet.sleep(100)
    end 
end

function recycleNotice:init()

    self:closeTrigger()
    recycleNotice.__father.init(self, "通知服务.")

    -- 限时道具
    processTimeLimitItems()
    -- 清除过期公告
    processExpireNotices()
    -- 循环处理
    skynet.fork(update)    
end  

return recycleNotice