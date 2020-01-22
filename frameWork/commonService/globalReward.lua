local skynet        = require "skynet"
local tool          = require "util.tool"
local db            = require "coredb.query"
local businessObject = require "objects.businessObject"
local globalReward   = class("globalReward", businessObject)

require "skynet.manager"
local string_format = string.format
local globalRewards         = {} -- 全服补偿奖励
local levelsByplayerId      = {} -- 玩家等级映射
local playerRewardRecords   = {} -- 已补偿Id为键对应已领取玩家ID
local serverIdByPlayerId    = {} -- playerId对应服务器ID
local platformIdByPlayerId  = {} -- playerId对应平台ID

local function checkTime(timeStr)
    -- 2014-07-02_17:30:00
    local year, month, day, hour, min, sec = string.match(timeStr, "(%d+)-(%d+)-(%d+)_(%d+):(%d+):(%d+)")
    year, month, day, hour, min, sec = tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(min), tonumber(sec)
    if not year or year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
        return errorcode.globalReward_time_error  -- 年月日不正确
    end

    if hour < 0 or hour >= 24 or min < 0 or min >= 60 or sec < 0 or sec >= 60 then
        return errorcode.globalReward_time_error  -- 时分秒不正确
    end

    return 0, os.stringToDateTime(string_format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec))
end

local function decodeServerIds(str)
    local serverIds = {}
    local arr = string.split(str, ";")
    for _, str2 in ipairs(arr) do
        local arr2 = string.split(str2, "-")
        for _, id in ipairs(arr2) do
            serverIds[tonumber(id)] = true
        end
    end

    return serverIds
end

function globalReward:insertGlobalReward(params)

    if type(params) ~= "table" or #params ~= 9 then
        return errorcode.param_error
    end

    local id = tonumber(params[1])
    if globalRewards[id] then
        return errorcode.globalReward_id_error
    end

    local err
    local limitLevel = tonumber(params[2] or 1)
    if limitLevel < 1 then
        limitLevel =  1
    end

    local serverIdsStr = params[3] or ""
    local serverIds = decodeServerIds(serverIdsStr)

    local startTime
    local endTime
    err, startTime = checkTime(params[4])
    if err ~= 0 then
        return err
    end

    err, endTime = checkTime(params[5])
    if err ~= 0 then
        return err
    end

    if endTime < startTime then
        return errorcode.globalReward_time_error
    end

    local platformIdsStr = params[6] or ""
    local platformIds = decodeServerIds(platformIdsStr)

    local title = params[7]
    if type(title) ~= "string" or #title <= 0 or #title > 64 then
        return errorcode.globalReward_title_error
    end

    local content = params[8]
    if type(content) ~= "string" or #content <= 0 or #content > 1024 then
        return errorcode.globalReward_content_error
    end

    local attaches = params[9]
    if type(attaches) ~= "string" or #attaches <= 0 then
        return errorcode.globalReward_attaches_error
    end

    err = tool.checkMailAttaches(attaches, errorcode, gameconst, xmls)
    if err ~= 0 then
        return err
    end

    local r = {
        id          = id,
        serverIds   = serverIds,
        serverIdsStr= serverIdsStr,
        limitLevel  = limitLevel,
        startTime   = startTime,
        endTime     = endTime,
        title       = title,
        content     = content,
        attaches    = attaches,
        platformIds = platformIds,
        platformIdsStr = platformIdsStr,
    }
    db:name('globalreward'):data(r):insert()

    playerRewardRecords[id] = {}
    globalRewards[id] = r
    
    local now = os.getCurTime()
    if now >= startTime and now < endTime then
        skynet.send(skynet.self(), "lua", "onlineSendMails", id)
    end

    return 0
end

local function sendReward(playerId, info, level, now)
    local id = info.id
    if level >= info.limitLevel and now >= info.startTime and now < info.endTime then
        if playerRewardRecords[id] and not playerRewardRecords[id][playerId] then

            if info.serverIdsStr == "" or info.serverIds[serverIdByPlayerId[playerId]] then

                if info.platformIdsStr == "" or info.platformIds[platformIdByPlayerId[playerId]] then

                    playerRewardRecords[id][playerId] = true
                    local recordId = guidMan.createGuid(gameconst.serialtype.playerRewardRecord_guid)
                    local r = {id = recordId, playerId = playerId, rewardId = id, sendTime = os.dateTimeToString(now)}
                    db:name('playerrewardrecord'):data(r):insert()
                    self:sendBonusesMail(playerId, info.title,  info.content, info.attaches, gameconst.mailSourceType.system)
                end
            end
        end
    end
end

function globalReward:onlineSendMails(id)
    local info = globalRewards[id]
    if info then
        local now = os.getCurTime()
        for playerId, _ in pairs(online2agent) do
            local level = levelsByplayerId[playerId] or 1

            sendReward(playerId, info, level, now)
        end
    end
end

function globalReward:deleteGlobalReward(params)
    if type(params) ~= "table" or #params ~= 1 then
        return errorcode.param_error
    end

    local id = tonumber(params[1])
    if not globalRewards[id] then
        return errorcode.globalReward_id_not_exist
    end

    db:name('globalreward'):where('id', id):delete()
    db:name('playerrewardrecord'):where('id', id):delete()

    globalRewards[id] = nil
    playerRewardRecords[id] = nil

    return 0
end

local function sendRewards(playerId)
    local now = os.getCurTime()
    local level = levelsByplayerId[playerId] or 1

    for id, info in pairs(globalRewards) do
        sendReward(playerId, info, level, now)
    end
end

local function loadAll()

    local now = os.getCurTime()
    local results = db:name('globalreward'):select()
    for _, result in ipairs(results or {}) do
        local id = tonumber(result.id)
        local endTime = os.stringToDateTime(result.endTime)

        if now >= endTime then
            db:name('playerrewardrecord'):where('rewardId', id):delete()
            db:name('globalreward'):where('id', id):delete()
        else
            local err = tool.checkMailAttaches(result.attaches, errorcode, gameconst, xmls)
            assert(err == 0, string_format("globalReward id:%d attaches:%s error!", id, attaches or -1))

            playerRewardRecords[id] = {}
            globalRewards[id] = {
                id          = id,
                serverIdsStr= result.serverIds,
                serverIds   = decodeServerIds(result.serverIds or ""),
                limitLevel  = tonumber(result.limitLevel),
                startTime   = os.stringToDateTime(result.startTime),
                endTime     = endTime,
                title       = result.title,
                content     = result.content,
                attaches    = result.attaches,
                platformIds = decodeServerIds(result.platformIds or ""),
                platformIdsStr = result.platformIds,
            }
        end
    end

    results = db:name('playerrewardrecord'):select()
    for _, result in ipairs(results or {}) do
        local playerId = result.playerId
        local rewardId = tonumber(result.rewardId)

        assert(playerRewardRecords[rewardId], string_format("rewardId:%d reward not exist!", rewardId))
        playerRewardRecords[rewardId][playerId] = true
    end

    skynet.fork(function()
        while true do
            local now = os.getCurTime()
            for id, info in pairs(globalRewards) do
                if now > info.endTime then
                    db:name('playerrewardrecord'):where('rewardId', id):delete()
                    db:name('globalreward'):where('id', id):delete()
                    globalRewards[id] = nil
                    playerRewardRecords[id] = nil
                    break
                end
            end

            skynet.sleep(6000) -- 一分钟
        end 
    end)
end

function globalReward:init()

    self:closeTrigger()
    globalReward.__father.init(self, "全服补偿.")
    loadAll()
end   

return globalReward

