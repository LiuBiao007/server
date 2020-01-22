local skynet 		= require "skynet"
local subject		= require "base.subject"
local component		= require "class.component"
local fieldObject 	= require "objects.fieldObject"
local uniqueService = require "services.uniqueService"
local errorcode 	= errorcode
local gameconst 	= gameconst
local push 			= table.insert

--在此接口中添加你要过滤的物品规则
local function ItemFilter(item)

	return true
end	

local basePlayer = class("basePlayer", fieldObject)

function basePlayer:init(...)

	basePlayer.__father.init(self, ...)
	self.onOutGame   			= subject:new()
	self.onEnterGame 			= subject:new()
	self.onPlayerCreate 		= subject:new()
	self.onSendPlayerData		= subject:new()
	self.loadGameDataSuccess 	= subject:new()

	self.payMoney				= subject:new()
	self.unreadMails 			= 0

	return self
end	

function basePlayer:getBagContainerByProto(proto)
	
	assert(type(proto) == "table", "proto type is not table")
	local ptype = proto.type
	assert(ptype ~= nil, "proto type is nil")

	return self:getContainerByType(ptype)
end

function basePlayer:getContainerByType(ptype)

	local bag = self.bags[ptype]
	assert(bag ~= nil, ptype .. " bag is not exist")
	return bag
end	

function basePlayer:insertItems(items,forceBinding)

	local itemsHash = {}
	for _, info in ipairs(items) do
		local protoId = info[1].id
		local itemInfo = itemsHash[protoId]
		if itemInfo then
			itemInfo[2] = itemInfo[2] + info[2]
		else
			itemsHash[protoId] = info
		end
	end

	local bags = self.bags
	local insertBags = {}
	for bagtype, bag in pairs(bags) do
		insertBags[bagtype] = {}
	end

	for _,item in pairs(itemsHash) do
		
		local proto = item[1]
		local bag = self:getBagContainerByProto(proto)
		local bagtype = bag.type
		push(insertBags[bagtype], item)
	end

	local results = {}

	for _,bag in pairs(bags or {}) do
		
		local bagtype = bag.type
		local inserts = insertBags[bagtype]
		local r = bag:insertItems(inserts, forceBinding)
		for _,insert in pairs(r) do
			push(results, insert)
		end
	end

	return self.itemMan:serializeInsert(results)	
end	

function basePlayer:checkItemsCount(items,filter)

	local hasBindingItem = false
	for _,item in pairs(items) do

		local proto,count = item[1],item[2]
		local results = self:getItemCountByProto(proto,1,filter)
		if results.hasBindItem then hasBindingItem = true end
		if results.count < count then
			return false, proto
		end	
	end	
	return true, hasBindingItem
end	

function basePlayer:isSpaceFull(inserts, removes, forceBinding)
	
	local removeBags = {}
	local insertBags = {}
	for type,_ in pairs(self.bags) do

		removeBags[type] = {}
		insertBags[type] = {}
	end	

	local checkBags = {}
	local removes = removes or {}
	for _,item in pairs(removes) do

		local proto = item[1]
		local container = self:getBagContainerByProto(proto)
		push(removeBags[container.type], item)
		checkBags[container.type] = true
	end	

	for _,item in pairs(inserts or {}) do

		local proto = item[1]
		local container = self:getBagContainerByProto(proto)
		push(insertBags[container.type], item)
		checkBags[container.type] = true
	end	

	--local r = true
	for _type, _ in pairs(checkBags) do

		local container = self.bags[_type]
		local removes = removeBags[_type]
		local inserts = insertBags[_type]
		local r = container:isSpaceFull(removes, inserts, forceBinding)
		if r == true then
			return r, errorcode[gameconst.containerErr[_type]] or errorcode.space_no_enough
		end		
	end	

	return false	
end

function basePlayer:removeItems(items,filter)

	local removeBags = {}
	for type,_ in pairs(self.bags) do
		removeBags[type] = {}
	end	
	
	for _,item in pairs(items or {}) do

		local proto = item[1]
		local container = self:getBagContainerByProto(proto)
		push(removeBags[container.type],item)
	end	
	
	local defaultFilter = ItemFilter
	if filter then
		assert(type(filter) == "function")
		defaultFilter = filter
	end	

	local results = {}
	for _,container in pairs(self.bags) do

		local removes = removeBags[container.type]
		local r = container:removeItems(removes,defaultFilter)
		for _,item in pairs(r) do
			push(results,item)
		end	
	end	

	return self.itemMan:serializeRemove(results) 
end

--将实例插入背包
function basePlayer:insertInsts(items,forceBinding)
	
	local insertBags = {}
	for type, _ in pairs(self.bags) do

		insertBags[type] = {}
	end	
	
	for _,item in pairs(items) do

		local proto = item.proto
		local container = self:getBagContainerByProto(proto)
		push(insertBags[container.type], item)
	end	
	
	local results = {}
	for _,container in pairs(self.bags) do

		local inserts = insertBags[container.type]
		local r = container:insertItemInsts(inserts, forceBinding)
		for _,item in pairs(r) do
			push(results, item)
		end	
	end	

	return results
end
--销毁物品实例
function basePlayer:destroyInst(item)
	
	local container = self:getBagContainerByProto(item.proto)
	container:destroyItem(item)
end

function basePlayer:getInstById(instId)

	for _,container in pairs(self.bags) do

		local inst = container:getItemById(instId)
		if inst then return inst end
	end
	return nil	
end

--filter穿一个函数进来，用来过滤你想要的物品
function basePlayer:getItemCountByProto(proto,binding,filter)

	if not binding then binding = 1 end
	local defaultFilter = ItemFilter
	if filter then 
		assert(type(filter) == "function", "filter is not function.")
		defaultFilter = filter
	end	
	local container = self:getBagContainerByProto(proto)
	return container:getItemCountByProtoId(proto.id, binding,defaultFilter)
end

function basePlayer:sendUnreadMailsEvent(count)
	
	self.unreadMails = self.unreadMails + count
	if self.unreadMails < 0 then self.unreadMails = 0 end
	self:sendEvent("unreadmailchanged", {unreadMails = self.unreadMails})
end

function basePlayer:sendBonusesEx(bonuses)
	if bonuses then

		bonuses = self.itemMan:decodeBonuses(bonuses)
        local err = self.itemMan:checkTakeBonuses(bonuses)
        if err ~= 0 then
            return
        end
        local bonusesResult = self.itemMan:takeBonuses(bonuses)
		-- 通知玩家插入数据
		self:sendEvent("itemInserts", {itemInserts = bonusesResult.inserts})
	end	
end

function basePlayer:sendBonusesMail(title, content, bonuses, type)
	
	local s = uniqueService("mail.mailCenter")	
	skynet.send(s, "lua", "sendSystemMailEx", type, "system", 
        self.id, title, content, bonuses)	
end

function basePlayer:initModules()

	self.mailMan      = self:addModules("mail.mailMan")
	self.logMan	 	  = self:addModules("log.logMan")
	self.proxy 		  = self:addModules("player.proxy")
	self.itemMan	  = self:addModules("itemMan.itemMan")

	if type(self.initModulesEx) == "function" then

		self:initModulesEx()
	end	

	--活动
	self.activities = {}
	for id, item in pairs(ACTIVITY_CONFIG) do

		if item.type == ACTIVITYTYPE_PLAYER then

			assert(not self.activities[id], string.format("activity id %s repeated.", id))
			self.activities[id] = self:addModules(string.format("activity.%s", item.name),
				item.statekey, id)
		end	
	end		
end	

function basePlayer:initBags()

	--背包 只有 commonBag 和 uniqueBag 对外开放继承
	local defaultCap  = 500
	local ct = gameconst.container
	local root = {}--xmls.player.root
	local param = {itemMan = self.itemMan, player = self}

	--普通背包用commonBag
	param.type = assert(ct.item_container); param.maxCount = root.itemContainerCap or defaultCap
	self.itemBag	  = self:addBagModules("bag.commonBag", param)
	if type(self.initBagsEx) == "function" then

		self:initBagsEx(ct, root, param, defaultCap)
	end	
end	

function basePlayer:addBagModules(module, ...)

	local m = self:addModules(module, ...)
	assert(not self.bags[m.type], string.format("error bag type %s repeat.", m.type))
	self.bags[m.type] = m
	return m
end	

function basePlayer:addModules(module, ...)

	local _module = require(module)
	return component.addComponent(self, _module, ...)
end	

function basePlayer:linkModules()

	if type(self.linkModulesEx) == "function" then

		self:linkModulesEx()
	end	
end	

function basePlayer:initNonData()

	self.id   = self.guid
	self.bags = {}

	if type(self.initNonDataEx) == "function" then

		self:initNonDataEx()
	end	
end	

function basePlayer:initGameData()

	--初始化观察者对象		
	self:initSubjects()
	--初始化非数据库数据
	self:initNonData()
	--加载模块
	self:initModules()
	--初始化背包
	self:initBags()
	--关联模块
	self:linkModules()
end	

function basePlayer:initSubjects()

	self.onUpdateFinalValues = subject:new()
	self.onResetPlayerData   = subject:new()
	self.onUpdatePlayerData  = subject:new()

	self.onPlayerCreate:attach(self.onCreatePlayer, self)
	self.onSendPlayerData:attach(self.sendEnterData, self)

	if type(self.initSubjectsEx) == "function" then
		self:initSubjectsEx()
	end	
end	

function basePlayer:onCreatePlayer(_, serverName, uniqueData)

	self.welcome = 1
	self:handData()
	self:updateFinalValues()	
	self.state = PLAYER_STATE_INGAME
	SERVICE_OBJECT.state = PLAYER_STATE_INGAME
	self.serverName = serverName
	self.logMan:log(LOG_OP_BIGTYPE_CREATECHAR)

	if type(self.onCreatePlayerEx) == "function" then
		self:onCreatePlayerEx(serverName, uniqueData)
	end	
end	

function basePlayer:onLoadPlayerData(uniqueData)

	if self.welcome == 1 then self.welcome = 0 end
	self:handData()
	self:updateFinalValues()	

	if type(self.onLoadPlayerDataEx) == "function" then
		self:onLoadPlayerDataEx(uniqueData)
	end	
end	

function basePlayer:canSendEvent()
	
	return self.state and self.state == PLAYER_STATE_INGAME and self.user
end

function basePlayer:sendEvent(cmd, param)
	
	if self:canSendEvent() then
		self.user:sendEvent(cmd, param)
	end
end

local local_service
function basePlayer:call(service, cmd, ...)
	--for speed
	if not local_service then
		local_service = SERVICE_OBJECT
	end	
	return local_service:call(service, cmd, ...)
end	

function basePlayer:send(service, cmd, ...)

	if not local_service then
		local_service = SERVICE_OBJECT
	end	
	local_service:send(service, cmd, ...)
end

function basePlayer:atcall(activityId, cmd, ...)

	if not local_service then
		local_service = SERVICE_OBJECT
	end	
	local cnf = ACTIVITY_CONFIG[activityId]
	if cnf then

		local activity = self.activities[activityId]
		if activity then--本地服务

			assert(type(activity[cmd]) == "function", 
				string.format("local activityId %s cmd %s not exit.", activityId, cmd))
			return activity[cmd](activity, cmd, ...)
		else
			
			if cnf.type == ACTIVITYTYPE_UNIQUE then--全局服务
	
				return local_service:call(string.format("activity.%s", cnf.name), cmd, self.id, ...)
			elseif cnf.type == ACTIVITYTYPE_FACTION then--联盟活动
				
				return local_service:call("faction.factionMan", cmd, activityId, self.id, ...)
			elseif cnf.type == ACTIVITYTYPE_MASTER then

				return local_service:call("player.masterProxyMan", "mcall", cmd, self.id, activityId, ...)
			else
				error(string.format("error activity type %s activityId %s.",
					cnf.type, activityId))
			end	
		end	
	elseif activityId >= ACTIVITYID_DYNAMICBEG and activityId <= ACTIVITYID_DYNAMICEND then	

		local s = local_service:call("commonService.admin", "getActivityById", activityId)
		if not s then
			return {errorcode = errorcode.param_error}
		end	
		return skynet.call(s, "lua", cmd, self.id, ...)		
	else--跨服服务
		
		error(string.format("error activity cnf type %s activityId %s.",
				cnf.type, activityId))		
	end	
end	

function basePlayer:updateFinalValues()

	error("implement in child.")
end	

function basePlayer:handData()
--[[
	self.entergame_time = os.getCurTime()
	self:update()
	skynet.fork(function ()

		while true do
			
			skynet.sleep(100)
			self:update()
		end	
	end)]]
end	

function basePlayer:update(notify)
	
	local day = os.getDay()	
	local now = os.getCurTime()
	--隔天重置的都放到下面执行
	if day ~= self.day then
		
		self.day = day
		self.onResetPlayerData:notify(notify)
	end
	--数据跟随时间变化的关注它
	self.onUpdatePlayerData:notify(now)
end	

function basePlayer:dispathData(data, serverName, uniqueData)

	self.serverName = serverName
	self.loadGameDataSuccess:notify(data, self)
	for _, playerState in pairs(data.playerstates or {}) do

		local activity = assert(self.activities[playerState.activityId], 
			string.format("error activityId %s in load playerState.", playerState.activityId))
		activity:onDataLoaded(playerState, self)
	end	
	self:onLoadPlayerData(uniqueData)
end	

function basePlayer:insertMail(mail)

     self.mailMan:insertMail(mail)
     self:sendEvent("insertMail", {mail = mail})
end

function basePlayer:getRegistUser()

	local r = {}
	local cnf = gameconst.simplePlayer
	for _, key in pairs(cnf) do
		r[key] = assert(self[key], string.format("error key %s.", key))
	end	
	return r
end	
return basePlayer
