local skynet         = require "skynet"
local serviceTrigger = require "base.serviceTrigger"
local uniqueService  = require "services.uniqueService"
local timer 		 = require "commonService.timer"
local uniqueActivity = require "afw.uniqueActivity"
local masterActivity = class("masterActivity", uniqueActivity)

function masterActivity:runOk()
	mylog.info(" 跨服活动【%s】[id:%s] 启动成功.", self.name, self.id)
end	

function masterActivity:sendEventToServer(playerId, cmd, param)
    
	local service = uniqueService("commonService.masterService")
	self:send("commonService.masterService", "sendEventToServer", playerId, cmd, param)     
end

function masterActivity:onActivityStateChangedEx(activityState)

	activityState.resetTime = timer.time()
	self:sendEventToServer(activityState.playerId, "activityStateChanged", 
		self:getSendData(activityState))   
end	

function masterActivity:onActivityStateRemoveChangedEx(r)

	self:sendEventToServer(r.playerId, "activityStateRemoveChanged", r) 
end	

function masterActivity:onActivityOpenStateChanged()

	self:sendEventToServer(nil, "activityOpenState", 
	  	self:getActivityOpenState())   	
end

function masterActivity:onActivityGlobalStateChanged(activityGlobalState)

	activityGlobalState.data = activityGlobalState.data
	if not self.__globalkey then return end
	assert(not self.isPlayerUnique, string.format("player activity do not need globalstate %s.", self.id))
	self:sendEventToServer(nil, "activityGlobalStateChanged", self:getSendGlobalData())   
end

return masterActivity