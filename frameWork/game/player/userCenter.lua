local serviceObject = require "objects.serviceObject"
local db            = require "coredb.query"
local sharedata     = require "skynet.sharedata"

local userCenter = class("userCenter", serviceObject)


local function genUserKey(userid, serverid)

	return string.format("%s:%s", userid, serverid)
end	

local name2data     = {}
local user2data     = {}
local player2data   = {}
local playerId2forbid = {}
--初始化userid serverid player
function userCenter:initData()

    local gameconst         = gameconst
    local fields            = gameconst.simplePlayer
    local ret               = db:name('player'):field(fields):select()
    for _, v in pairs(ret) do

        self:registUser(v)
    end	
end	

function userCenter:init()

    userCenter.__father.init(self, 100)
    self:initData()
    self:closeSyncToRedis()
end    

function userCenter:registUser(v)

    local ukey = genUserKey(v.userid, v.serverid)
    assert(not user2data[ukey], string.format("error ukey %s.", ukey))
    user2data[ukey] = v
    
    local pkey = v.guid
    assert(not player2data[pkey], string.format("error pkey %s.", pkey))
    player2data[pkey] = v
    playerId2forbid[pkey] = v.forbidTime

    local name = assert(v.name)
    assert(not name2data[name], string.format("error name %s.", name))
    name2data[name] = v

    redisdb:set("playerName:" .. name, pkey)
end    

function userCenter:setForbidTime(playerId, time)
    playerId2forbid[playerId] = time
end 

function userCenter:modify(playerId, key, value)

    local player = player2data[playerId]
    if player then

        player[key] = value
    end    
end    

function userCenter:getPlayerById(playerId)

    return player2data[playerId]
end    

function userCenter:checkUserExist(userid, serverid)

	local v = user2data[genUserKey(userid, serverid)]
    if v then 
        return v.guid, v.forbidTime
    end
    return false 
end	

function userCenter:getPlayerIdByUserAndServerId(userid, serverid)

    return  user2data[genUserKey(userid, serverid)]
end    

function userCenter:checkPlayerExist(playerId)

	return player2data[playerId] and true or false
end	

function userCenter:checkNameExist(name)

    return name2data[name] and true or false
end    

function userCenter:getPlayerByName(name)
    return name2data[name]
end    

function userCenter:getPlayerIdByName(name)

    local s = name2data[name]
    if s then return s.guid end
    return nil
end    
--后台模糊查询
function userCenter:getPlayerIdsByName(name)
    
    local playerIds = {}
    local header = "playerName:*" .. name .. "*"
    local playerNames = redisdb:keys(header)
    for k, v in ipairs(playerNames or {}) do 
        table.insert(playerIds, redisdb:get(v))
    end
    
    return playerIds
end    
return userCenter