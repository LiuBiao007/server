local sends = require "sends"
require "const.activityConst"
--机器人处理事件 比如收到好友的请求时候， 可以同意或者拒绝
local handler = {}


activityEvent_Map = {
	
}


function handler.doEvent_Activity(player, args)
	local activityState = args.activityState
	local func = activityEvent_Map[activityState.activityId]
	if func then
		func(player, activityState)
	end
end	

function handler.doEvent_faction_factionapplyadd(player, args)

	local robot = player.robot
	if robot then
		if math.random(100) >= 50 then
			robot.actors[1104]:send()--同意
		else
			robot.actors[1105]:send()--拒绝
		end	
	end	
end

local events_map = {
	activityStateChanged = handler.doEvent_Activity,--活动状态变化
	factionapplyadd = handler.doEvent_faction_factionapplyadd,
}

function handler.listenEvent(name, player, args)

	local func = events_map[name]
	if func then
		func(player, args)
	end	
end	
return handler
