local serviceTrigger = require "base.serviceTrigger"
local uniqueService  = require "services.uniqueService"
local proxy 		 = class("serviceProxy")

local push 			 = table.insert
function proxy:init(player)

	self.player = assert(player)
	player.onSendPlayerData:attach(self.sendEnterData, self)
	player.onOutGame:attach(self.onPlayerOutGame, self)
	player.onEnterGame:attach(self.onEnterGame, self)
	player.payMoney:attach(self.onPayMoney, self)
	return self
end	

function proxy:onPayMoney(...)

	serviceTrigger.send("onPayMoney", ...)
end	

--分类整理其他服务的数据
function proxy:onEnterGame(player, uniqueData)

	local masterData = player:call("player.masterProxyMan", "mcall", "serverReconnect", {[player.id] = true})
	if type(masterData) == "table" then

		if not masterData.errorcode then 
			for _, data in pairs(masterData) do

				for key, item in pairs(data) do

					if not uniqueData[key] then uniqueData[key] = {} end

					for _, child in pairs(item) do
						push(uniqueData[key], child)
					end
				end	
			end	
		end	
	end	

	--全局活动
	self.sendData = {} 
	if uniqueData.activity then

		self.sendData.activity = {}
		local activity = self.sendData.activity
		local activityStates = {}
		local activityGlobalStates = {}
		local dynamicActivityParams = {}
		local activityOpenStates = {}
		activity.activityStates = activityStates
		activity.activityGlobalStates = activityGlobalStates
		activity.dynamicActivityParams = dynamicActivityParams
		activity.activityOpenStates = activityOpenStates
		for _, data  in pairs(uniqueData.activity) do

			local activityState = data.activityState
			if activityState then

				activityStates[activityState.activityId] = activityState
			end	
			local activityGlobalState = data.activityGlobalState
			if activityGlobalState then
				activityGlobalStates[activityGlobalState.activityId] = activityGlobalState
			end	
			local dynamicActivityParam = data.dynamicActivityParam
			if dynamicActivityParam then
				dynamicActivityParams[dynamicActivityParam.id] = dynamicActivityParam
			end	
			local activityOpenState = data.activityOpenState
			if activityOpenState then
				activityOpenStates[activityOpenState.id] = activityOpenState
			end				
		end	
	end	

	--联盟 联盟活动 以及其他服务数据整理
	self:onEnterGameEx(uniqueData)
end	

function proxy:onPlayerOutGame(param)

	local player = assert(param.player)
	serviceTrigger.send("onPlayerStateOut", player.id)
end	

--下发存放的数据
function proxy:sendEnterData(player, result)
	
	local sendData = self.sendData.activity
	if sendData and sendData.activityStates then

		for activityId, activityState in pairs(sendData.activityStates) do
			result.activityStates[activityId] = activityState
		end
	end

	if sendData and sendData.activityGlobalStates then

		for activityId, activityGlobalState in pairs(sendData.activityGlobalStates) do
			result.activityGlobalStates[activityId] = activityGlobalState
		end
	end

	if sendData and sendData.dynamicActivityParams then

		for activityId, dynamicActivityParam in pairs(sendData.dynamicActivityParams) do
			result.dynamicActivityParams[activityId] = dynamicActivityParam
		end		
	end

	if sendData and sendData.activityOpenStates then

		for activityId, activityOpenState in pairs(sendData.activityOpenStates) do
			result.activityOpenStates[activityId] = activityOpenState
		end		
	end	

		--[[

	result.factionActivityStates = getdata(self.factionActivityStates)

	]]
	--联盟 联盟活动 以及其他服务数据下发
	self:sendEnterDataEx(player, result)

	self.sendData = nil--gc
end

return proxy