local skynet = require "skynet"
local mylog = require "base.mylog"
local requests = {}

local errorcode = errorcode
--player user global
function requests.addIngot(args)

	local ingot = args.ingot
	if type(ingot) ~= "number" then
		return {errorcode = errorcode.param_error}
	end	

	--player:addIngot(ingot)
--	ingot = 88
ingot = 77
print("test addingot ", ingot)
	player.ingot = player.ingot + ingot

	return {errorcode = 0}
end	

function requests.addGoldCoin(args)

	local goldCoin = args.goldCoin
	if type(goldCoin) ~= "number" then
		return {errorcode = errorcode.param_error}
	end	


	--player:addGoldCoin(goldCoin)
	player.goldCoin = player.goldCoin + goldCoin

	return {errorcode = 0}
end	

function requests.removeinst(args)

	local instId = args.instId
	if type(instId) ~= "string" then
		return {errorcode = errorcode.param_error}
	end	

	local player = player
	--不可删除穿戴物品	
	local inst = player:getInstById(instId)
	if not inst then
		return {errorcode = errorcode.item_not_exist}
	end	

	player:destroyInst(inst)

	return {errorcode = 0, instId = instId}
end	

function requests.removeitem(args)

	local protoId = args.protoId
	local count = args.count
	if type(protoId) ~= "number" or type(count) ~= "number" then
		return {errorcode = errorcode.param_error}
	end	

	local player = player
	local proto = player.itemMan:getProtoById(protoId)
	if proto == nil then
		return {errorcode = errorcode.param_error}
	end		

	local hascount = player:getItemCountByProto(proto).count

	if hascount < count then
		return {errorcode = errorcode.item_num_no_enough}
	end

	local itemRemoves = player:removeItems({{proto,count}})	
	return {errorcode = 0, itemRemoves = itemRemoves}
end						   

function requests.additem(args)

	local protoId = args.protoId
	local count = args.count

	if type(protoId) ~= "number" or type(count) ~= "number" then
		return {errorcode = errorcode.param_error}
	end	
	local player = player

	local proto = player.itemMan:getProtoById(protoId)
	if proto == nil then
		return {errorcode = errorcode.param_error}
	end	

	local isFull, err11 = player:isSpaceFull({{proto,count}})
	if isFull then
		return {errorcode = err11}
	end	

	local itemInserts = player:insertItems({{proto,count}})
	return {errorcode = 0,itemInserts = itemInserts}
end	

local timer = require "commonService.timer"
function requests.debugtime(args)

    local current =  timer.getCurrent()	

    local hour = args.hour
    local min  = args.min
    local sec  = args.sec
    if hour < 0 then hour = current.hour end
    if min < 0 then min = current.min end
    if sec < 0 then sec = current.sec end
    if not day or day < 0 then day = current.day end

    local t = {hour = hour, min = min, sec = sec, day = day}
    timer.changetime(t)
    return {errorcode = 0}
end
--调用个人活动示例
function requests.playeractivity(args)

	local a = args.a or 0
	local b = args.b or 0
	local c = args.c or "zzz"

	return player:atcall(ACTIVITYID_DEMO1, "demokick", a, b, c)
end	
--普通独立活动
function requests.uniqueactivity(args)

	local a = args.a or 1
	local b = args.b or 1
	local c = args.c or "aaa"
	return player:atcall(ACTIVITYID_DEMO2, "gkick", a, b, c)
end	
--运营活动
function requests.dkick(args)

	local activityId = args.activityId
	local a = args.a
	local b = args.b
	local c = args.c

	return player:atcall(activityId, "dkick", a, b, c)
end	

--跨服活动
function requests.mkick(args)
	
	local a = args.a
	local b = args.b
	local c = args.c

	return player:atcall(ACTIVITYID_DEMO4, "mkick", a, b, c)
end	
return requests