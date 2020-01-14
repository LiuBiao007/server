local skynet 		= require "skynet"
local uniqueService = require "services.uniqueService"
local timer 		= {}

local timerd
local function getTimerd()

	if not timerd then
		timerd = uniqueService("commonService.timerd")
	end	
	return assert(timerd)
end	
-- { month=, day=, wday=, hour= , min= }
function timer.submit(ti)

    assert(ti)
    return skynet.call(getTimerd(), "lua", "timerd", ti)
end

function timer.changetime(ti)

	local tmp = table.copy(ti)
    tmp.changetime = true
    return skynet.call(getTimerd(), "lua", "timerd", tmp)
end

-- curtime
function timer.time()

    local difftime = skynet.call(getTimerd(), "lua", "timerd")
    return os.getCurTime() + difftime
end

function timer.debugtime()

	return os.dateTimeToString(timer.time())
end	

function timer.getCurrent()

    local ct = math.floor(timer.time())
    local current = os.date("*t", ct)
    return current
end	

--高效0点重置接口, 避免CPU空转和大量临时对象产生与GC
--每天只会运行一次此接口
function timer.loopZero(obj, func, timerKey)

	assert(type(timerKey) == "string" and type(obj[timerKey]) == "number", 
		string.format("error timerKey %s.", timerKey))
	assert(type(func) == "function")

	local function isExpired(time1, time2)
		return os.getSameDayEndTime(time1, 0) ~= os.getSameDayEndTime(time2, 0)
	end	

	skynet.fork(function ()

		while true do

			local curTime = math.floor(timer.time())
			if isExpired(curTime, obj[timerKey]) then
				obj[timerKey] = curTime
				func(obj)
			else	

				local current = timer.getCurrent()
				timer.submit({day = current.day + 1, hour = 0, min = 0, sec = 0})
				obj[timerKey] = math.floor(timer.time())
				func(obj)				
			end	
		end	
	end)
end

function timer.createTimer(obj, func, timerKey, interval, ...)

	local curTime = math.floor(timer.time())
	if curTime - obj[timerKey] >= interval then
		
		func(obj, ...)
		obj[timerKey] = curTime
	else
		
		local nextTime = obj[timerKey] + interval
		local n = os.date("*t", nextTime)
		n.wday = nil
		timer.submit(n)
		func(obj, ...)
		obj[timerKey] = math.floor(timer.time())
	end	
end	

--高效定时器接口, 避免CPU空转和大量临时对象产生与GC
--比如可用于 每隔20分钟恢复一点体力
function timer.loopTimer(obj, func, timerKey, interval, ...)

	assert(type(timerKey) == "string" and type(obj[timerKey]) == "number", 
		string.format("error timerKey %s.", timerKey))
	assert(type(func) == "function")
	assert(type(interval) == "number" and interval > 0)
	local param = {...}
	skynet.fork(function ()

		while true do

			timer.createTimer(obj, func, timerKey, interval, table.unpack(param))
		end	
	end)	
end

--一次性定时器接口 可用于删除过期邮件等
function timer.onceTimer(obj, func, timerKey, interval, ...)

	assert(type(timerKey) == "string" and type(obj[timerKey]) == "number", 
		string.format("error timerKey %s %s.", timerKey, obj[timerKey]))
	assert(type(func) == "function")
	assert(type(interval) == "number" and interval > 0)
	local param = {...}
	skynet.fork(function (...)
		timer.createTimer(obj, func, timerKey, interval, table.unpack(param))
	end)
end	
return timer