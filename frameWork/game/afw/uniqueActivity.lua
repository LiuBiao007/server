local activity 		 = import("afw.activity", true)
local activityState  = require "afw.activityState"
local globalState 	 = require "afw.activityGlobalState"
local db			 = require "coredb.query"
local timer 		 = require "commonService.timer"
local serviceTrigger = require "base.serviceTrigger"
local outline 		 = require "ext.outline"
local uniqueActivity = class("uniqueActivity", activity)

function uniqueActivity:init(_, id)

    self.activityStates = {}
    self.activityStatesByPlayerId = {}
    id = assert(tonumber(id), string.format("error id %s.", id))

	self:buildKeys(id)

	uniqueActivity.__father.init(self, id)

	self:runOk()
end	

function uniqueActivity:initTriggersEx()

	serviceTrigger.add("onLoadGameData")
end	

function uniqueActivity:buildKeys(id)
	self.__globalkey 	= ACTIVITY_CONFIG[id].globalkey
	self.__statekey 	= ACTIVITY_CONFIG[id].statekey
end	

function uniqueActivity:runOk()
	mylog.info(" 全局活动【%s】启动成功.", self.name)
end	

function uniqueActivity:onCreate()

	if self.__globalkey then
		local data = db:name("activityglobalstates"):where("activityId", self.id):find()
		if data then
			self.activityGlobalState = globalState:load(data)
		else
			self.activityGlobalState = self:newActivityGlobalState()
		end	

		self:zeroTimer(self.activityGlobalState)
	end	

	self:loadActiveActivityStates()

	self:onCreateEx()
end	

function uniqueActivity:loadAllActivityStates()

	return db:name("activitystates"):where("activityId", self.id):select()
end	

function uniqueActivity:onActivityStateChangedEx(activityState)

	activityState.resetTime = timer.time()
	self.playerMan:sendEvent(activityState.playerId, "sendEvent", "activityStateChanged", 
		{activityState = self:getSendData(activityState)})
end	

function uniqueActivity:onActivityStateRemoveChangedEx(r)

	self.playerMan:sendEvent(r.playerId, "sendEvent", "activityStateRemoveChanged", r)
end	

function uniqueActivity:onLoadGameData(playerId)

	local key = "activity"
	local r = {}
	if self.__globalkey then

		r.activityGlobalState = self:getSendGlobalData()
	end	

	local activityState = self:getActivityStateByPlayerId(playerId)
	if activityState then
		r.activityState = self:getSendData(activityState)
	end	

	r.activityOpenState = self:getActivityOpenState()

	if self.type == ACTIVITYTYPE_DYNAMIC then
		r.dynamicActivityParam = self:getParam()
	end	

	return key, r
end	

function uniqueActivity:loadActiveActivityStates()
	
	self.idhash = {}
	--
	local ids = db:name('activitystates'):field({"id", "playerId"}):where("activityId", self.id):select()
	for _, item in pairs(ids) do

		assert(not self.idhash[item.playerId], 
			string.format("error activityId %s id %s playerId %s.", self.id, item.id, item.playerId))
		self.idhash[item.playerId] = item.id
	end	

	--只加载活跃的数据
	local activeDay = __cnf.activeDay or 3
	local exp = string.format(" >= date_sub(curdate(),interval %d day)", activeDay)
	local data = db:name("activitystates"):where("resetTime", "EXP", exp):where("activityId", self.id):select()
	for _, item in pairs(data) do
		
		local activityState = activityState:load(item)
		self:attachState(activityState)
	end	
end	

function uniqueActivity:newActivityState(playerId, now, initState)

	local activityState = activityState:create({

		id 			= self.guidMan.createGuid(gameconst.serialtype.activitystates_guid),
        activity 	= self,
        activityId 	= self.id,
        playerId 	= playerId,
        state 		= initState or 0,
        data 		= {},		
        resetTime	= now or os.getCurTime(),
	})	

	self:initStateData(activityState.data)
	self:attachState(activityState)
	self.idhash[activityState.playerId] = activityState.id
	return activityState
end	

function uniqueActivity:attachState(activityState)

    assert(not self.activityStates[activityState.id], string.format("attachState playerId %s activityId %s", activityState.playerId, activityState.activityId))
    assert(not self.activityStatesByPlayerId[activityState.playerId], string.format("attachState playerId %s activityId %s", activityState.playerId, activityState.activityId))

    activityState.activity = self
    self.activityStates[activityState.id] = activityState
    self.activityStatesByPlayerId[activityState.playerId] = activityState
end	

function uniqueActivity:detachState(activityState)

	assert(self.activityStates[activityState.id], string.format("detachState playerId %s activityId %s", activityState.playerId, activityState.activityId))
	assert(self.activityStatesByPlayerId[activityState.playerId], string.format("detachState playerId %s activityId %s", activityState.playerId, activityState.activityId))

    self.activityStates[activityState.id] = nil
    self.activityStatesByPlayerId[activityState.playerId] = nil
end	

function uniqueActivity:onOutGame(playerId)

	local activityState = self.activityStatesByPlayerId[playerId]
	if activityState then

		self:detachState(activityState)
	end	
end	

function uniqueActivity:getActivityStateByPlayerId(playerId)
   
    local state = self.activityStatesByPlayerId[playerId]
    if not state then

    	local id = self.idhash[playerId]
    	if id then
    		local data = outline:new(playerId, self.playerMan):name("activitystates"):pk(id):get()
    		if data then
				state = activityState:load(data)
				self:attachState(state)
    		end	
    	end	
    end	
    return state
end

function uniqueActivity:loadActiveData(playerId)
	self:getActivityStateByPlayerId(playerId)
end	

function uniqueActivity:newActivityGlobalState(state)
   	
    local id =  self.guidMan.createGuid(gameconst.serialtype.activityglobalstates_guid) 
	local data = {
        id          = id,
        activity    = self,
        activityId  = self.id,
        data        = {},
        resetTime   = os.getCurTime(),
        state       = state or 0,
    }    

    local activityGlobalState =globalState:create(data)
    self:initGlobalData(activityGlobalState)

    return activityGlobalState
end

--全局活动重置接口 重置自己的活动数据即可
function uniqueActivity:onResetState(activityGlobalState)

end	

function uniqueActivity:onCreateEx()
	
end	

function uniqueActivity:initGlobalData(activityGlobalState)

end	

return uniqueActivity
