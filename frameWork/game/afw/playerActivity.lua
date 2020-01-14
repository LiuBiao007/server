local activity 		 = import("afw.activity")
local playerState  	 = require "afw.playerState"
local playerActivity = class("playerActivity", activity)

local push 			= table.insert
function playerActivity:init(player, key, id, ...)

	id = tonumber(id)
	assert(type(player) == "table" and player.__classname == "player")
	assert(type(key) == "string")--下发activityState.data的key 与sproto中的定义保持一致
	self.player = player
	self.isPlayerUnique = true
	playerActivity.__father.init(self, id, ...)
	
	player.onEnterGame:attach(self.onEnterGame, self)

    player.onSendPlayerData:attach(self.sendEnterData, self)	

    self:setStateKey(key)

    mylog.info("	[playerId:%s] 个人活动【%s】加载成功.", self.player.id, self.name)
end

function playerActivity:setStateKey(key)

	self.__statekey = key
end	
	
--子类可重载进一步处理
function playerActivity:onEnterGameEx(activityState)

end	

function playerActivity:onActivityStateChangedEx(activityState)

	self.player:sendEvent("activityStateChanged", {activityState = 
		self:getSendData(activityState)})
end	

function playerActivity:onActivityStateRemoveChangedEx(r)

	self.player:sendEvent("activityStateRemoveChanged", r)
end	

function playerActivity:onDataLoaded(data, player)

	local activityState = playerState:load(data)
	self:attachState(activityState)
end	

function playerActivity:sendEnterData(player, result)

	local activityState = self:getActivityStateByPlayerId(player.id)
	if activityState then

		assert(self.__statekey, "call setStateKey() first.")
		result.activityStates[activityState.activityId] = self:getSendData(activityState)
	end	
	local activityOpenState = self:getActivityOpenState()
	if activityOpenState then
		result.activityOpenStates[activityOpenState.id] = activityOpenState
	end	
end

function playerActivity:newActivityState(playerId, now, initState)

	local activityState = playerState:create({

		id 			= self.guidMan.createGuid(gameconst.serialtype.playerstate_guid),
        activityId 	= self.id,
        playerId 	= playerId,
        state 		= initState or 0,
        data 		= {},		
        resetTime	= now or os.getCurTime(),
	})	

	self:initStateData(activityState.data)
	self:attachState(activityState)
	return activityState
end	

function playerActivity:attachState(activityState)

	assert(not self.activityState, string.format("activity id %s player id %s repeated.", self.id, activityState.playerId))
	self.activityState = activityState
	activityState.activity = self
	self:buildTimer(activityState)
end	

function playerActivity:buildTimer(activityState)
	--0点重置
	self:zeroTimer(activityState)
	self:buildTimerEx(activityState)
end	
--有其他的定时器需求可重载此接口
function playerActivity:buildTimerEx(activityState)

end	

--重置 不用改写resetTime 重置自己的业务数据即可
--时间会自己重置  数据库会自己写入
function playerActivity:onResetState(activityState)
	mylog.info("activityId %s playerId %s onResetState.", activityState.activityId, activityState.playerId)
	--eg.
	--activityState.data = {}
	--self.subjectActivityStateChanged:notify(activityState)
end	

function playerActivity:detachState()

	local activityState = self.activityState
	assert(activityState, string.format("activity id %s state not exist.", self.id))
	self.activityState = nil
end	

function playerActivity:getActivityStateByPlayerId(playerId)
    
	return self.activityState
end

return playerActivity
