local handler = {}
local gameconst = require "const.gameconst"

local energyInst
local physicalInst
local isInit = false
local function init(actor)
	-- if isInit then return end

	local energyProto = actor.player.rxmls.items.energyProto
	local physicalProto = actor.player.rxmls.items.physicalProto

	local items = actor.player.itembag:getItems()
	for _, item in pairs(items) do
		if item.protoId == energyProto.id then
			energyInst = item
		elseif item.protoId == physicalProto.id then
			physicalInst = item
		end
	end

	-- isInit = true
end

local function getItemByProtoId(actor, protoId)
	local items = actor.player.itembag:getItems()
	for _, item in pairs(items) do
		if item.protoId == protoId then
			return item.id
		end
	end
end

function handler.useItem(actor, send)
	local instId = getItemByProtoId(actor, actor.param)

	send({instId or 11111, 1})
end

function handler.openChest(actor, send)
	local itemsCnf = actor.player.rxmls.items
	local gameconst = actor.player.gameconst

	local params = {actor.player.guid, 1, 1}
	local items = actor.player.itembag:getItems()
	for _, item in pairs(items) do
		local proto = itemsCnf[item.protoId]
		if proto.subType == gameconst.itemtype.fixedChest or 
		   proto.subType == gameconst.itemtype.randomChest then
		   params = {item.id, item.count > 100 and 100 or item.count, 1}
		elseif proto.subType == gameconst.itemtype.chooseChest then
			params = {item.id, item.count > 100 and 100 or item.count, 2}
		end
	end

	send(params)
end

function handler.markItem(actor, send)
	local arr = {}
	local items = actor.player.awakebag:getItems()
	for _, item in pairs(items) do
		table.insert(arr, item.protoId)
	end

	local protoId = #arr > 0 and arr[math.random(#arr)] or 1111

	send({protoId})
end

function handler.deleteMark(actor, send)
	local arr = {}
	local items = actor.player.awakebag:getItems()
	for _, item in pairs(items) do
		table.insert(arr, item.protoId)
	end

	local protoId = #arr > 0 and arr[math.random(#arr)] or 1111

	send({protoId})
end

function handler.mergehero(actor, send)
	local arr = {}
	local itemsCnf = actor.player.rxmls.items
	local items = actor.player.heropiecebag:getItems()
	for _, item in pairs(items) do
		local proto = itemsCnf[item.protoId]
		table.insert(arr, {item.id, proto.extra.number})
	end

	local params = #arr > 0 and arr[math.random(#arr)] or {actor.player.guid, 1}

	send(params)
end

function handler.equipCompound(actor, send)
	local arr = {}
	local items = actor.player.equippiecebag:getItems()
	for _, item in pairs(items) do
		table.insert(arr, item.id)
	end

	local id = #arr > 0 and arr[math.random(#arr)] or actor.player.guid

	send({id, 1})
end

return handler