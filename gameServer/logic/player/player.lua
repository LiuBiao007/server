local skynet		= require "skynet"
local uniqueService = require "services.uniqueService"
local basePlayer 	= require "player.basePlayer"
local subject 		= require "base.subject"
local tools         = require "util.tool"
local xmls			= xmls
local player 		= class("player", basePlayer)

local gameconst		= gameconst
local errorcode     = errorcode
local floor 		= math.floor
local push			= table.insert
function player:init()

	user = SERVICE_OBJECT
	assert(user, "user serviceObject must be init first.")
	player.__father.init(self, "player")
	self.user   = user
	user.player = self
	self.monitorSimple:attach(self.submitModifySimple, self)

	return self
end	

local simplekeys
function player:submitModifySimple(key, value)

	if not simplekeys then
		simplekeys = {}
		for _, v in pairs(gameconst.simplePlayer or {}) do
			simplekeys[v] = true
		end	
	end	
	if simplekeys and simplekeys[key] then

		self:send("player.userCenter", "modify", self.id, key, value)
	end	
end	
--初始化模块管理器 addModules
function player:initModulesEx()

	--self.heroMan	  = self:addModules("hero.heroMan")
end	
--初始化背包 addBagModules
function player:initBagsEx(ct, root, param, defaultCap)

	--普通背包用commonBag

	--原型必须唯一的背包用uniqueBag
	param.type = ct.hero_container; param.maxCount = root.heroContainerCap or defaultCap
	self.heroBag	  = self:addBagModules("bag.uniqueBag", param)
end	

--关联模块
function player:linkModulesEx()

	--self.itemMan.heroMan = self.heroMan
	for _, bag in pairs(self.bags) do
		bag.itemMan = assert(self.itemMan)
	end	
end	
--初始化非数据库数据
function player:initNonDataEx()

end	
--初始化观察者
function player:initSubjectsEx()

end	
local i = 1
--角色创建成功hook: 
function player:onCreatePlayerEx(serverName, uniqueData)

	self.onEnterGame:notify(self, uniqueData)
	--test give yourself some items when character created.??
	local items = {}
	--local protoIds = {15000001}
	local protoIds = {15000001, 15000002, 15000003, 15000004, 15000005}
	for _, protoId in pairs(protoIds) do

		local proto = self.itemMan:getProtoById(protoId)
		assert(proto, tostring(protoId))
		push(items, {proto, 1})
	end	


	local r = self:isSpaceFull(items)
	if not r then
		print(self:insertItems(items))
	end	
	i = 1+1
	local t = string.rep(tostring(i), 30)

	self:sendBonusesMail(t, t, "2:1:1,15000005,1,10000,0", 1)

	--
	--data.blackList  = {a = 1, v = 2, c = {d = 1, m = 555, z = {hello = "world", j = 333}}}
	--data.guideStates = {a = 3, v = 5, kk = {hhlo = 1, lo = "kaka", kaka = {hei = "wwwll", ll = 123}}}
	--[[
	local c = assert(self.blackList.c)
	local kaka = assert(self.guideStates.kk.kaka)
	skynet.fork(function ()
		while true do
			skynet.sleep(100)
			c.z.hello = c.z.hello .. "m"
			c.z.j = c.z.j + 10
			kaka.hei = kaka.hei .. "wocao"
			kaka.ll = kaka.ll - 1
			self.blackList.a = self.blackList.a + 100
			print("========>>>>>>>> player xiugai blackList", string.dump(self.blackList))
		end	
	end)]]
	--	
	--do login acheivement ??--achievement_login_days
end	
--角色数据装载成功hook
function player:onLoadPlayerDataEx(uniqueData)

	self.onEnterGame:notify(self, uniqueData)
	--achievement_login_days??
end	

function player:updateFinalValues()

end	
--序列化角色数据给客户端
function player:sendEnterData(player, result)
	
	--serilize database data	
	result.base = player
	result.finalvalues = {
		force = self.force,
		wit = self.wit,
		politics = self.politics,
		charm = self.charm,
		power = self.power,
	}

	--add other data
	--eg. data.childCount = self:getChildCount()
end

function player:getSendStruct()
	
	return
	{

		activityStates 			= {},
		dynamicActivityParams 	= {},
		activityOpenStates 		= {},
		activityGlobalStates 	= {},
		factionActivityStates 	= {}
	}
end

function player:forbidUserLogin(hour)

	local date = tools.getDelayForbidTime(hour)
	self.forbidTime = date
	if hour > 0 then
		self.user:kickSelf()
	end	
end	
--奖励结构
function player:attachBonuses(bonus, bonusesResult)

	local bonusType = gameconst.bonusType
	local type1 = bonus.type
	if type1 == bonusType.ingot then 		-- 元宝
		self:addIngot(bonus.point)
		bonusesResult.ingot = bonus.point

	elseif type1 == bonusType.goldCoin then 	-- 金币
		self:addGoldCoin(bonus.point)
		bonusesResult.goldCoin = bonus.point										
	else
		mylog.warn("impossible %s", type1)
	end
end	
--消耗结构检测
function player:checkCostsEx(type1, costType, point)

	if type1 == costType.ingot then
		if self.ingot < point then
			return errorcode.ingot_not_enough
		end
	elseif type1 == costType.goldCoin then	
		if self.goldCoin < point then
			return errorcode.silverCoin_not_enough
		end	
	else
		mylog.warn("impossible %s", type1)
		return errorcode.data_error
	end
end	
--消耗结构
function player:costsEx(type1, costType, costResult, point)

	if type1 == costType.ingot then 		-- 元宝
		self:addIngot(-point)
		costResult.ingot = point
	elseif type1 == costType.goldCoin then 		-- 金币
		self:addGoldCoin(-point)
		costResult.goldCoin = point
	else
		mylog.warn("impossible %s", type1)			
	end		
end	

---------------------------------------------NEW API ADD-----------------------
function player:payIngot(ingot, money, chargeType, chargegold, serverOrder, platform, serverid)

	self.current_cmd = 'payIngot'
	self.__platform = platform
	self:addIngot(ingot)
	self:addVipExp(money)
	self:addTotalPayIngot(money)
	self.payMoney:notify(player.id, money, ingot, chargeType, chargegold)
	self:sendEvent("payIngotSuccess", {money = money, ingot = ingot})
	self.logMan:log(LOG_OP_BIGTYPE_PAY,{money, chargegold, ingot, player.chargeNum},{serverOrder})
	mylog.info('[PAY] playerid %s 充值金额 %s 充值获得元宝 %s 充值类型:%s 赠送黄金:%s', player.id, money, ingot, chargeType, chargegold)
end	

return player

