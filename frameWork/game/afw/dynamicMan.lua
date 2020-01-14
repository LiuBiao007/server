local skynet         = require "skynet"
local db			 = require "coredb.query"
local cjson			 = require "cjson"
local json           = require "ext.json"
local newService 	 = require "services.newService"
local dynamicMan     = class("dynamicMan")

function dynamicMan:init()

	self.activities = {}
	--self:loadDynamicActivities()
    skynet.fork(self.loadDynamicActivities, self)
end	

function dynamicMan:loadDynamicActivities()


    local function createTime(time)

        local cur = os.date("*t", time)
        cur.wday  = nil
        cur.isdst = nil
        cur.yday  = nil
        return cur
    end    

    local isLoad = 1
	local datas = db:name("dynamicactivityparams"):select()
    for _, param in ipairs(datas) do

        param.timerStart = createTime(param.startTime)
        param.timerEnd   = createTime(param.endTime)
        local err, result = self:newDynamicService(param, isLoad)
        if err ~= 0 then
            mylog.warn("impossible activityId:%s  clasz:%s errorcode:%s errDesc:%s", param.id, param.clasz, err, result or "")
        end
    end	
end	

function dynamicMan:attachActivity(id, service)

	assert(not self.activities[id], string.format("dynamic id %s repeated.", id))
	self.activities[id] = service
end	

function dynamicMan:detachActivity(id)

	local s = self.activities[id]
	assert(s, string.format("error dynamic id %s.", id))
	self.activities[id] = nil
	--to do
	skynet.send(s, "lua", "removeDynamicActivity")
end	

function dynamicMan:getDynamicActivityById(id)

	return self.activities[id]
end	

function dynamicMan:removeDynamicId(id)

    self.activities[id] = nil
end    

function dynamicMan:newDynamicService(param, isLoad)

	local cnf = assert(ACTIVITY_CONFIG[param.clasz], string.format("error clasz %s.", param.clasz))
	param.type = ACTIVITYTYPE_DYNAMIC

	local s = newService(string.format("activity.%s", cnf.name), json.encode(param), skynet.self())
	local err, result = skynet.call(s, "lua", "startDynamic", isLoad) 
    if err ~= 0 then return err, result end
    self:attachActivity(param.id, s)
    return 0, ""
end	

local timer = require "commonService.timer"
function dynamicMan:dynamicActivityInsert(params)

    local errorcode = errorcode
    if #params ~= 13 then
        return errorcode.param_error
    end

    local param = {
        id                = tonumber(params[1]),
        name              = params[2],
        icon              = params[3],
        desc              = params[4],
        detail            = params[5],
        needLevel         = tonumber(params[6]),
        sortIndex         = tonumber(params[7]),
        startTime         = params[8],
        endTime           = params[9],
        segmentsPerWeek   = params[10],
        segmentsPerDay    = params[11],
        clasz             = tonumber(params[12]),
        data              = params[13],
        state             = DYNAMICACTIVITYSTATE_HIDDEN,
        updateTime        = os.getCurTime(),
    }

    if param.id < ACTIVITYID_DYNAMICBEG or param.id > ACTIVITYID_DYNAMICEND then
        return errorcode.activity_error_id  -- ID必须在有效范围之内
    end

    if self:getDynamicActivityById(param.id) then
        return errorcode.activity_id_used  -- ID已经被使用
    end

    if string.len(param.name) < 1 or string.len(param.name) > 32 then
        return errorcode.activity_size32_error  -- 名称长度必须在1到32之间
    end

    if string.len(param.desc) < 1 or string.len(param.desc) > 4000 then
        return errorcode.activity_size4000_error  -- 描述长度必须在1到4000之间
    end

    if string.len(param.detail) < 1 or string.len(param.detail) > 4000 then
        return errorcode.activity_size4000_error  -- 详述长度必须在1到4000之间
    end

    local times = {"startTime", "endTime"}
    for _, key in pairs(times) do
        local timeStr = param[key]
        -- 2014-07-02&nbsp;17:30:00
        local year, month, day, hour, min, sec = string.match(timeStr, "(%d+)-(%d+)-(%d+)&nbsp;(%d+):(%d+):(%d+)")
        year, month, day, hour, min, sec = tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(min), tonumber(sec)
        if not year or year < 2000 or year > 2100 or month < 1 or month > 12 or day < 1 or day > 31 then
            return errorcode.activity_year_month_day_error  -- 年月日不正确
        end
    
        if hour < 0 or hour >= 24 or min < 0 or min >= 60 or sec < 0 or sec >= 60 then
            return errorcode.activity_hour_min_sec_error  -- 时分秒不正确
        end
    
        param[key] = os.stringToDateTime(string.format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec))
    	
    	local t = {
    		year = year,
    		month = month,
    		day = day,
    		hour = hour,
    		min = min,
    		sec = sec
    	}
    	if key == "startTime" then
    		param.timerStart = t
    	else
    		param.timerEnd = t
    	end	
    end

    if param.endTime < param.startTime then
        return errorcode.activity_start_dayu_end  -- 开始时间不能晚于结束时间
    end

    if timer.time() >= param.startTime then

        mylog.info("%s:%s", timer.debugtime(), os.dateTimeToString(param.startTime))
    	return errorcode.startTime_error
    end	
    
    local weekStart, weekEnd = string.match(param.segmentsPerWeek, "([1-7])-([1-7])")
    weekStart, weekEnd = tonumber(weekStart), tonumber(weekEnd)

    if not weekStart then
        return errorcode.activity_week_format_error  -- 每周时间段格式不正确
    end

    if weekStart > weekEnd then
        return errorcode.activity_week_start_dayu_end  -- 每周时间段中起始时间不能高于结束时间
    end
    param.segmentsPerWeek = {weekStart, weekEnd}

    local startHour, startMin, endHour, endMin = string.match(param.segmentsPerDay, "(%d+):(%d+)-(%d+):(%d+)")
    startHour, startMin, endHour, endMin = tonumber(startHour), tonumber(startMin), tonumber(endHour), tonumber(endMin)
    if not startHour then
        return errorcode.activity_day_format_error  -- 每天时间段格式不正确
    end

    if startHour < 0 or startHour > 23 or startMin < 0 or startMin > 59 or endHour < 0 or endHour > 23 or endMin < 0 or endMin > 59 then
        return errorcode.activity_day_value_error  -- 每天时间段数值不正确
    end

    local begin = startHour * 60 + startMin
    local endEx = endHour * 60 + endMin
    if begin > endEx then
        return errorcode.activity_day_start_dayu_end  -- 每天时间段中起始时间不能高于结束时间
    end
    param.segmentsPerDay = {{startHour, startMin}, {endHour, endMin}}

    local ok, data = pcall(cjson.decode, param.data)
    if not ok then
        return errorcode.activity_json_error, "json decode error!"  -- data json 数据错误
    end
    param.data = data

    local err, errDesc = self:insertDynamicActivity(param)
    if err ~= 0 then
        return err, errDesc  -- data json 数据错误
    end

    local activity = self:getDynamicActivityById(param.id)
    if activity then
        return 0
    end

    return errorcode.unknown_error       -- 未知错误
end

function dynamicMan:insertDynamicActivity(param)

    local err, result = self:newDynamicService(param)
    if err ~= 0 then
        mylog.warn("impossible activityId:%s  clasz:%s errorcode:%s errDesc:%s", param.id, param.clasz, err, result or "")
    end	

    return err, "", result
end	

function dynamicMan:dynamicActivityRemove(params)
    if #params ~= 1 then
        return errorcode.param_error
    end

    local activityId = tonumber(params[1])
    local activity = self:getDynamicActivityById(activityId)
    if not activity then
        return errorcode.activity_not_exist  -- 活动不存在
    end
    self:detachActivity(activityId)

    return 0
end

function dynamicMan:dynamicActivityQueryAll(params)
    local dynamicActivityParams = {}
    for activityId, activity in pairs(self.activities) do
        result = skynet.call(activity, "lua", "getParam")
        if result then
            table.insert(dynamicActivityParams, result)
        end
    end

    local results = cjson.encode(dynamicActivityParams)

    return 0, results
end

function dynamicMan:dynamicActivitySortIndex(params)
    local dataStr = params[1] or {}
    if #dataStr <= 0 then
        return errorcode.param_error
    end

    local changes = {}
    for _, str in ipairs(dataStr:split(";")) do
        local info = str:split(",")
        if #info ~= 2 then
            return errorcode.param_error, "params format error"
        end

        local activityId = tonumber(info[1])
        local index = tonumber(info[2])

        local activity = self:getDynamicActivityById(activityId)
        if not activity then
            return errorcode.activity_not_exist, string.format("%d not exist", activityId)  -- 活动不存在
        end

        changes[activityId] = index
    end

    for activityId, index in pairs(changes) do
        local activity = self:getDynamicActivityById(activityId)
        skynet.call(activity, "lua", "setDynamicActivitySortIndex", index)
    end

    return 0, ""
end

return dynamicMan
