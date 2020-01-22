local skynet            = require "skynet"
local mylog             = require "base.mylog"

local tools = {}
function tools.addExp(obj,exp,data,extra)
	
    local l,e = "level","exp"
    if extra then
        l = extra.level
        e = extra.exp
    end    
	local maxLevel = data.maxLevel
	assert(maxLevel)
	if obj[l] >= maxLevel then return end
	assert(exp > 0)
	local level = obj[l]
	local exp = exp
	obj[e] = obj[e]  + exp
	for i = obj[l],maxLevel - 1 do 
		if obj[e] >= data[i + 1][e] then
			obj[e] = obj[e] - data[i + 1][e]
			level = level + 1
		end
	end
	obj[l] = level
	--assert(obj[l] <= maxLevel)
	if obj[l] == maxLevel then obj[e] = 0 end
end

function tools.getProtoById(protoId, xmls)
--[[

卡牌14000001
物品15000001

]]
    if type(protoId) ~= "number" then return nil end

    if protoId >= 14000001 and protoId <= 14999999 then
        return xmls.hero.protos[protoId]
    elseif protoId >= 15000001 and protoId <= 15999999 then
        return xmls.items[protoId]
    elseif protoId >= 13000001 and protoId <= 13999999 then 
        return xmls.soulmate.protos[protoId]    
    else
        return nil
    end 
end  

function tools.checkCostsStr(data, errorcode, gameconst, xmls)

    local arr = string.split(data, ";")
    if #arr <= 0 then
        return errorcode.cost_string_empty
    end

    for _, str in ipairs(arr) do
        local item = string.split(str, ",")
        if #item <= 0 then
            return errorcode.cost_string_empty
        end

        local _type = tonumber(item[1])
        if not _type or _type < gameconst.costType.min or _type > gameconst.costType.max then
            return errorcode.cost_type_error
        end

        if _type == gameconst.costType.item then
            if #item ~= 3 then return errorcode.cost_size_error end

            local protoId = tonumber(item[2])
            if not protoId then
                return errorcode.cost_proto_not_exist
            end

            local proto = tools.getProtoById(protoId, xmls)
            if not proto then return errorcode.cost_proto_not_exist end
        else
            if #item ~= 2 then return errorcode.cost_size_error end
        end
    end

    return 0
end

function tools.checkBonusesString(data, errorcode, gameconst, xmls)

    local arr = string.split(data, ":")
    if #arr ~= 3 then
        return errorcode.bonus_string_error
    end

    local items = string.split(arr[3], ";")
    if #items <= 0 then return errorcode.bonus_string_empty end

    for _, itemStr in ipairs(items) do
        local itemArr = string.split(itemStr, ",")

        local _type = tools.tonumber(itemArr[1])
        if _type < gameconst.bonusType.min or _type > gameconst.bonusType.max then
            return errorcode.bonus_type_error
        end

        if _type == gameconst.bonusType.item then
            if #itemArr ~= 5 then return errorcode.bonus_size_error end

            local protoId = tools.tonumber(itemArr[2])
            local proto = tools.getProtoById(protoId, xmls)
            if not proto then return errorcode.bonus_proto_not_exist end
        else
            if #itemArr ~= 4 then return errorcode.bonus_size_error end
        end
    end

    return 0
end

-- 组合成奖励结构字符串(独立计算且概率为10000)
function tools.encodeBonusesStr(data)
    if type(data) ~= "table" or #data <= 0 then
        return nil
    end

    local items = {}
    local values = {}
    for _, info in ipairs(data) do
        local _type = info[1]
        if _type == 1 then
            local count = info[3]
            local protoId = info[2]
            if items[protoId] then
                items[protoId] = items[protoId] + count
            else
                items[protoId] = count
            end
        else
            local point = info[2]
            if values[_type] then
                values[_type] = values[_type] + point
            else
                values[_type] = point
            end
        end
    end

    local str = "2:1:"
    for protoId, count in pairs(items) do
        str = str .. "1," .. protoId .. "," .. count .. ",10000,0;"
    end

    for _type, point in pairs(values) do
        str = str .. _type .. "," .. point .. ",10000,0;"
    end

    return string.sub(str, 1, #str - 1)
end

function tools.joinBonusesStr(arr)
    if type(arr) ~= "table" or #arr <= 0 then
        return nil
    end

    local head
    local str = ""
    for i, s in ipairs(arr) do
        local a = string.split(s, ":")

        if a[1] and a[1] == "1" then
            if not head then
                head = '1:1:'
            end

            if head ~= '1:1:' then
                mylog.warn("bonusesArr:%s error!", tools.dump(arr))
            end

            if a[3] and a[3] ~= "" then
                str = string.format("%s%s;", str, a[3])
            end
        elseif a[1] and a[1] == "2" then
            if not head then
                head = '2:1:'
            end

            if head ~= '2:1:' then
                mylog.warn("bonusesArr:%s error!", tools.dump(arr))
            end

            if a[3] and a[3] ~= "" then
                str = string.format("%s%s;", str, a[3])
            end
        else
            mylog.warn("bonusesStr:%s error!", s)
        end
    end

    if #str < 1 then
        return nil
    end

    return string.format("%s%s", head, string.sub(str, 1, #str - 1))
end

function tools.tonumber(num)
    return assert(tonumber(num))
end    

function tools.checkMailAttaches(bonusesStr, errorcode, gameconst, xmls)
    local arr = string.split(bonusesStr, ":")
    if #arr ~= 3 then
        return errorcode.bonus_string_error
    end

    if tools.tonumber(arr[1]) ~= gameconst.dropType.aloneRate then
        return errorcode.bonus_drop_must_aloneRate
    end

    if tools.tonumber(arr[2]) ~= 1 then
        return errorcode.bonus_round_must_once
    end

    local items = string.split(arr[3], ";")
    if #items <= 0 then return errorcode.bonus_string_empty end

    for _, itemStr in ipairs(items) do
        local itemArr = string.split(itemStr, ",")

        local _type = tools.tonumber(itemArr[1])
        if _type < gameconst.bonusType.min or _type > gameconst.bonusType.max then
            return errorcode.bonus_type_error
        end

        local rate = 0
        if _type == gameconst.bonusType.item then
            if #itemArr ~= 5 then return errorcode.bonus_size_error end

            rate = tools.tonumber(itemArr[4])
            local count = tools.tonumber(itemArr[3])
            local maxCount = tools.tonumber(itemArr[5])
            local protoId = tools.tonumber(itemArr[2])
            local proto = tools.getProtoById(protoId, xmls)
            if not proto then return errorcode.bonus_proto_not_exist end
        else
            rate = tools.tonumber(itemArr[3])
            local maxCount = tools.tonumber(itemArr[4])
            if #itemArr ~= 4 then return errorcode.bonus_size_error end
        end

        if rate < 10000 then
            return errorcode.bonus_rate_must_drop
        end
    end

    return 0
end

function tools.getDelayForbidTime(hour)

    local newSec
    if hour > 0 then
        newSec = os.time() + math.floor(hour * 60 * 60)
    else
        newSec = os.time() - 10
    end    

    return newSec
end    

function tools.hash2Arr_one(hash)
    local arr = {}
    for key, _ in pairs(hash or {}) do
        table.insert(arr, key)
    end
    
    return arr
end

function tools.join_hash_one(hash)
    local arr = {}
    for key, _ in pairs(hash or {}) do
        table.insert(arr, key)
    end
    
    return table.concat(arr, ",")
end

function string.split_str_one(str)
    local hash = {}
    local arr = string.split(str, ",")
    for _, value in ipairs(arr) do
        hash[tonumber(value)] = true
    end
    
    return hash
end

function tools.join_hash_two(hash)
    local arr = {}
    for key, value in pairs(hash or {}) do
        table.insert(arr, string.format("%s,%s", tostring(key), tostring(value)))
    end
    
    return table.concat(arr, ";")
end

function string.split_str_two(str)
    local hash = {}
    local arr = string.split(str, ";")
    for _, str2 in ipairs(arr) do
        local arr2 = string.split(str2, ",")
        assert(#arr2 == 2)
        hash[tonumber(arr2[1])] = tonumber(arr2[2])
    end
    
    return hash
end

return tools
