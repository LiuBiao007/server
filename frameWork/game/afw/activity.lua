local skynet	= require "skynet"
local subject 	= require "base.subject"

local timer 	= require "commonService.timer"

local unique 	= ...
local activity	

if unique then

	local businessObject = require "objects.businessObject"
	activity 			 = class("activity", businessObject)
else

	local object    	 = require "objects.object"
	activity 			 = class("activity", object)
end	

function activity:init(id)

	if unique then
		activity.__father.init(self, "unkown")
	else	
		activity.__father.init(self)
	end

	local id = tonumber(id)
	self.node 	= self:getNode(id)
	self.id 	= id
	self.name 	= self.node.name
	self.type 	= self.node.type
	self.needLevel = self.node.needLevel

	self.serviceName = self.name
	self.guidMan 	 = guidMan
	assert(type(self.type) == "number")
    self.subjectActivityStateChanged 		= subject:new()
    self.subjectActivityOpenStateChanged 	= subject:new()
    self.subjectActivityGlobalStateChanged 	= subject:new()
    self.subjectActivityStateRemoveChanged 	= subject:new()

   	self.subjectActivityStateChanged:attach(self.onActivityStateChanged, self)
    self.subjectActivityOpenStateChanged:attach(self.onActivityOpenStateChanged, self)
    self.subjectActivityGlobalStateChanged:attach(self.onActivityGlobalStateChanged, self)
    self.subjectActivityStateRemoveChanged:attach(self.onActivityStateRemoveChanged, self)   

    self:onCreate() 
end	

function activity:getNode(id)

	return xmls.activity[id]
end	

function activity:isExpired(time1, time2)
	return os.getSameDayEndTime(time1, 0) ~= os.getSameDayEndTime(time2, 0)
end
--每天0点重置定时器 activityState or activityGlobalState or factionState
function activity:zeroTimer(state)

	--return function ()

		skynet.fork(function ()

			while true do

				local curTime = math.floor(timer.time())
				if self:isExpired(curTime, state.resetTime) then
					state.resetTime = curTime
					self:onResetState(state)
				else	

					local current = timer.getCurrent()
					timer.submit({day = current.day + 1, hour = 0, min = 0, sec = 0})
					state.resetTime = math.floor(timer.time())
					self:onResetState(state)		
				end	
			end	
		end)		
	--end
end	
--用于每天什么时间开启或者结束什么操作
--state:activityState or activityGlobalState or factionState
--func:回调函数 eg.self.onActivityStart
--time:启动时间 "08:00" "08:00:00" 每天8点
function activity:dayTimer(state, func, time, ...)

	local hour, min, sec
	if time:match("(%d+):(%d+)") then
		hour, min = time:match("(%d+):(%d+)")
		sec = 0
	elseif time:match("(%d+):(%d+):(%d+)") then
		hour, min, sec = time:match("(%d+):(%d+):(%d+)")
	else
		error(string.format("error time %s.", time))
	end	
	local current = timer.getCurrent()

	local nt = {
		year 	= current.year,
		month 	= current.month,
		day  	= current.day,
		hour 	= hour,
		min 	= min,
		sec 	= sec,
	}

	time = os.time(nt)

	local param = {...}
	skynet.fork(function ()

		while true do

			local curTime = math.floor(timer.time())
			if curTime > time and state.resetTime < time then
				state.resetTime = curTime
				func(self, state, table.unpack(param))	
				state.data = state.data	
			else	

				local current = timer.getCurrent()
				local day
				if curTime > time then
					day = current.day + 1
				else
					day = current.day
				end	
				timer.submit({day = day, hour = hour, min = min, sec = sec})
				state.resetTime = math.floor(timer.time())
				func(self, state, table.unpack(param))	
				state.data = state.data			
			end	
		end	
	end)
end
--周活动定时器 待实现
function activity:weekTimer()

end	
--月活动定时器 待实现
function activity:monthTimer()

end	

function activity:onActivityStateChanged(activityState)

	activityState.data = activityState.data
	self:onActivityStateChangedEx(activityState)
end

function activity:getSendData(activityState)
	
	return activityState:packet(self.__statekey)
end

function activity:getSendGlobalData()
	
	assert(self.__globalkey, "set __globalkey first.")
	return self.activityGlobalState:packet(self.__globalkey)
end

--进游戏就必须创建activityState的
function activity:onEnterGame(player)

	if not ACTIVITY_CONFIG[self.id] then return end
	local needCreate = ACTIVITY_CONFIG[self.id].create
	if needCreate then
		local activityState = self:checkAndNewState(player.id)
		self:onEnterGameEx(activityState)
	else
		if type(self.loadActiveData) == "function" then
			self:loadActiveData(player.id)
		end	
	end	
end

function activity:removeActivityState(activityState)

	self:detachState(activityState)
	activityState:delete()
	self.subjectActivityStateRemoveChanged:notify(activityState)
end	

function activity:onActivityOpenStateChanged()

	self.playerMan:broadcast("sendEvent", {}, 'activityOpenState', self:getActivityOpenState())
end

function activity:onActivityGlobalStateChanged(activityGlobalState)

	activityGlobalState.data = activityGlobalState.data
	if not self.__globalkey then return end
	assert(not self.isPlayerUnique, string.format("player activity do not need globalstate %s.", self.id))
	self.playerMan:broadcast("sendEvent", {}, "activityGlobalStateChanged", {activityGlobalState = self:getSendGlobalData()})
end

function activity:onActivityStateRemoveChanged(activityState)

	local r = {id = activityState.id, activityId = activityState.activityId, playerId = activityState.playerId}
	self:onActivityStateRemoveChangedEx(r)		
end

function activity:newActivityState()

	error("implete in child.")
end	

function activity:checkAndNewState(playerId)

	local activityState = self:getActivityStateByPlayerId(playerId)
	if not activityState then
		activityState = self:newActivityState(playerId, os.getCurTime())
	end	
	return activityState
end	

function activity:initStateData(data)
	--do nothing
end	

function activity:getActivityOpenState()

    return {
        id          = self.id,
        isOpened    = self:isOpened(),
    }
end	

function activity:isOpened()

	return true
end	

function activity:getActivityStateByPlayerId(playerId)
    
    error("implete in child.")
end

function activity:getStateData(activityState)

    return activityState.data
end



return activity
