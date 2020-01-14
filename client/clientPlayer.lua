local gameconst = require "const.gameconst"
local errorcode = require "errorcode"
local mylog 	= require "base.mylog"
local container = require "container"
local player 	= class("player")

function player:init(info, rxmls)

	self.itemMan   = {}
	self.rxmls     = rxmls
	local playerId = info.base.guid
	for k, v in pairs(info.base) do
		self[k] = v
	end	
	for k, v in pairs(info.finalvalues) do
		self[k] = v
	end	

	self.bags = {}
	self:addBag("itemBag", gameconst.container.item_container)
	self:enterGame(info)
end	

function player:addBag(name, type)

	self[name] = container:new(type)
	assert(not self.bags[type], string.format("error type %s name %s.", type, name))
	self.bags[type] = self[name]
end	

function player:getContainerByType(type)

	return assert(self.bags[type], string.format("error getBagByType %s.", type))
end	

function player:enterGame(info)

	local containers = gameconst.container
	local items = info.items
	for _,item in pairs(items) do
	
		if item.container == containers.item_container then
			self.itemBag:attachItem(item)	
		else
			assert(false)	
		end	
	end	

	-- 运营活动数据
	self.dynamicActivityParams = {}
	for _, dynamicParams in ipairs(info.dynamicActivityParams or {}) do
		self.dynamicActivityParams[dynamicParams.id] = dynamicParams
	end

	-- 活动全局数据
	self.activityGlobalStates = {}
	for _, activityGlobalState in ipairs(info.activityGlobalStates or {}) do
		self.activityGlobalStates[activityGlobalState.id] = activityGlobalState
	end

	-- 活动开启状态数据
	self.activityOpenStates = {}
	for _, activityOpenState in ipairs(info.activityOpenStates or {}) do
		self.activityOpenStates[activityOpenState.id] = activityOpenState
	end

	-- 玩家参与的活动数据
	self.activityStates = {}
	self.activityStatesByActivityId = {}
	for _, activityState in ipairs(info.activityStates or {}) do
		self.activityStates[activityState.id] = activityState
		self.activityStatesByActivityId[activityState.activityId] = activityState	
	end

	self:dumpInfo(info)
end	

function player:dumpInfo(info)

	local mailCount = 0
	self.mails = info.mails
	self.items = info.items
	print(string.format("mails = %s", string.dump(self.mails)))
	print(string.format("items = %s", string.dump(self.items)))
	print("邮件数量 ", mailCount)
	print(string.format("guid = %s name =%s",self.guid , self.name ))

    print("activityStates 数据:")
    print(string.format("%s", string.dump(info.activityStates)))

    print("dynamicActivityParams 数据:")
    print(string.format("%s", string.dump(info.dynamicActivityParams)))

    print("activityOpenStates 数据:")
    print(string.format("%s", string.dump(info.activityOpenStates)))

    print("activityGlobalStates 数据:")
    print(string.format("%s", string.dump(info.activityGlobalStates)))
end	

function player:getclientitem(itemid)

	for _,bag in pairs(self.bags) do
		local item = bag:getItemById(itemid)
		if item then return item end
	end	
	return nil
end	

function player:getclientbag(item)

	local container = item.container
	assert(type(container) == "number")
	local bag = self:getContainerByType(container)
	return bag
end	


return player
